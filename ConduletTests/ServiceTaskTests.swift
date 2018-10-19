//
//  ServiceTaskTests.swift
//  ConduletTests
//
//  Created by Natan Zalkin on 28/09/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

import Quick
import Nimble
import Mockingjay
import SwiftProtobuf

@testable import Condulet

func compare(_ dict1: [String: String], _ dict2: [String: String]) -> Bool {
    return Set<String>(dict1.keys)
        .union(dict2.keys)
        .reduce(true, { $0 && (dict1[$1] == dict2[$1]) })
}

class ServiceTaskTests: QuickSpec {
    
    struct Test: Codable {
        
        let data: String
    }
    
    func readData(from stream: InputStream, bufferSize: Int = 1_000_000) throws -> Data {
        
        var data = Data()
        
        stream.open()
        while stream.hasBytesAvailable {
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            defer {
                buffer.deallocate()
            }
            let result = stream.read(buffer, maxLength: bufferSize)
            if result < 0 {
                throw stream.streamError ?? NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey : "Stream error: \(result)"])
                
            }
            else if result > 0 {
                data.append(buffer, count: result)
            }
        }
        stream.close()
        
        return data
    }
    
    override func spec() {
    
        func testData(_ method: Mockingjay.HTTPMethod, uri: String, data: Data) -> (_ request: URLRequest) -> Bool {
            return { (request:URLRequest) in
                
                if let requestMethod = request.httpMethod, requestMethod == method.description, let stream = request.httpBodyStream {
                    
                    let read: Data
                    do {
                        read = try self.readData(from: stream)
                    }
                    catch {
                        fail("Read error: \(error)")
                        return false
                    }
                    
                    guard read == data else {
                        fail("Not the same data!")
                        return false
                    }
                    
                    return Mockingjay.uri(uri)(request)
                }
                
                return false
            }
        }
        
        describe("ServiceTask") {

            afterEach {
                self.removeAllStubs()
            }
            
            it("can handle data response") {
                
                let original = "Test".data(using: .utf8)!
                
                self.stub(http(.get, uri: "test.test"), http(download: .content(original)))
                
                waitUntil { (done) in
                    
                    ServiceTaskBuilder()
                        .url("test.test")
                        .method(.GET)
                        .data { (data, response) in
                            expect(original).to(equal(data))
                            done()
                        }
                        .error({ (error, response) in
                            fail(error.localizedDescription)
                        })
                        .perform()
                }
            }
            
            it("can use response handler") {
                
                let original = "Test".data(using: .utf8)!
                
                self.stub(http(.get, uri: "test.test"), http(download: .content(original)))
                
                waitUntil { (done) in
                    
                    ServiceTaskBuilder()
                        .url("test.test")
                        .method(.GET)
                        .response(BlockResponseHandler { (content, response) in
                            switch content {
                            case .data(let data):
                                expect(original).to(equal(data))
                            default:
                                fail("Invalid content!")
                            }
                            done()
                        })
                        .error({ (error, response) in
                            fail(error.localizedDescription)
                        })
                        .perform()
                }
            }
            
            it("can handle text response") {
                
                func test(_ text: String) -> (_ request: URLRequest) -> Response {
                    return { (request:URLRequest) in
                        guard let data = text.data(using: String.Encoding.ascii) else {
                            return .failure(NSError(domain: "test", code: 2, userInfo: [NSLocalizedDescriptionKey : "Failed to encode text to data"]))
                        }
                        return jsonData(data, status: 200, headers: ["Content-Type": "text/plain; charset: ascii"])(request)
                    }
                }
                
                let data = "Test".data(using: .utf8)!
                
                self.stub(testData(.get, uri: "test.test?key=val&key2=val2", data: data), test("test 12345"))
                
                waitUntil { (done) in
                    
                    let task = ServiceTaskBuilder()
                        .endpoint(.GET, "test.test")
                        .query([
                            URLQueryItem(name: "key", value: "val"),
                            URLQueryItem(name: "key2", value: "val2")
                            ])
                        .body(data: data)
                        .headers(["test" : "1", "test2": "2"])
                        .headers(["test2" : "3"], merge: true)
                        .text { (text, response) in
                            expect(text).to(equal("test 12345"))
                            done()
                        }
                        .error { (error, response) in
                            fail("\(error)")
                        }
                        .perform()
                    
                    expect(compare(task.headers, ["test" : "1", "test2": "3"])).to(beTrue())
                    
                }
            }
            
            it("can handle json array response") {
                
                let array: [Any] = [["one": "ok"], ["two": "ok"]]
                
                self.stub(testData(.get, uri: "http://test.test?resource", data: try! JSONSerialization.data(withJSONObject: array, options: [])), json(array))
                
                waitUntil { (done) in
                    
                    let task = ServiceTaskBuilder()
                        .scheme("http")
                        .host("test.test")
                        .method(.GET)
                        .query("resource")
                        .body(json: array)
                        .headers(["initial": "value"])
                        .headers(["replaced": "headers"], merge: false)
                        .array { (data, response) in
                            expect(data.count).to(equal(2))
                            done()
                        }
                        .error { (error, response) in
                            fail("\(error)")
                        }
                        .perform()
                    
                    
                    expect(compare(task.headers, ["replaced": "headers"])).to(beTrue())
                }
            }
            
            it("can fail json array response") {
                
                let dict: [AnyHashable: Any] = ["test": "ok"]
                let body = "test".data(using: String.Encoding.ascii)!
                
                self.stub(testData(.get, uri: "test.test", data: body), json(dict))
                
                waitUntil { (done) in
                    
                    ServiceTaskBuilder()
                        .endpoint(.GET, "test.test")
                        .body(text: "test", encoding: .ascii)
                        .array { (data, response) in
                            fail("Request should fail!")
                        }
                        .error(BlockErrorHandler { (error, response) in
                            expect(error).to(matchError(ServiceTaskError.invalidResponseData))
                            done()
                        })
                        .perform()
                    
                }
            }
            
            it("can handle json dictionary response") {
                
                let dict: [AnyHashable: Any] = ["test": "ok"]
                
                let testFileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("txt")
                let body = "Test".data(using: .utf8)!
                try! body.write(to: testFileURL)
                
                self.stub(testData(.put, uri: "test.test", data: body), json(dict))
                
                waitUntil { (done) in
                    
                    ServiceTaskBuilder()
                        .endpoint(.PUT, "test.test")
                        .body(url: testFileURL)
                        .dictionary { (data, response) in
                            let value = data["test"] as? String
                            expect(value).to(equal("ok"))
                            done()
                        }
                        .error { (error, response) in
                            fail("\(error)")
                        }
                        .perform()
                }
            }
            
            it("can fail json dictionary response") {
                
                let array: [Any] = [["test": "ok"]]
                
                self.stub(http(.get, uri: "http://test.test/path/to/resource"), json(array))
                
                waitUntil { (done) in
                    
                    ServiceTaskBuilder()
                        .endpoint(.GET, "http://test.test")
                        .path("/path/to/resource")
                        .dictionary { (data, response) in
                            fail("Request should fail!")
                        }
                        .error { (error, response) in
                            expect(error).to(matchError(ServiceTaskError.invalidResponseData))
                            done()
                        }
                        .perform()
                    
                }
            }
            
            it("can cancel request") {
                
                let json = ["test": "ok"]
                let body = try! JSONSerialization.data(withJSONObject: json, options: [])
                
                self.stub(testData(.get, uri: "test.cancel", data: body), delay: 2, http(200))
                
                var canceled = false
                
                waitUntil(timeout: 5) { (done) in
                    
                    let task = ServiceTaskBuilder()
                        .endpoint(.GET, "test.cancel")
                        .body(json: json)
                        .content { (content, response) in
                            if canceled {
                                done()
                            }
                            else {
                                fail("Response received!")
                            }
                        }
                        .error { (error, response) in
                            fail("Error received: \(error)")
                        }
                        .perform()
                    
                    if task.cancel() {
                        canceled = true
                        task.rewind()
                    }
                    else {
                        fail("Task is failed to cancel!")
                    }
                }
            }
            
            it("can fail to perform request") {
                
                let dict = ["test": "ok"]
                let body = try! URLEncodedSerialization.data(with: dict)
                
                self.stub(testData(.get, uri: "user:password@test.test", data: body), failure(NSError(domain: "test", code: 1, userInfo: nil)))
                
                waitUntil { (done) in
                    
                    ServiceTaskBuilder()
                        .session(URLSession(configuration: URLSessionConfiguration.default))
                        .url(URL(string: "test.test")!)
                        .method("PATCH")
                        .user("user")
                        .password("password")
                        .body(urlencoded: dict)
                        .data { (data, response) in
                            fail()
                        }
                        .error { (error, response) in
                            done()
                        }
                        .perform()
                }
            }
            
            it("can fail with status code") {
                
                self.stub(http(.get, uri: "test.test"), json(["test": "fail"], status: 404))
                
                waitUntil { (done) in
                    
                    ServiceTaskBuilder()
                        .components(URLComponents(string: "test.test")!)
                        .method(.GET)
                        .data { (data, response) in
                            fail()
                        }
                        .error { (error, response) in
                            switch error {
                            case ServiceTaskError.statusCode(404):
                                done()
                            default:
                                fail()
                            }
                        }
                        .perform()
                }
            }
            
            
            it("can parse JSON response") {
                
                let message = "Post Body"
                
                self.stub(http(.get, uri: "test.test?key=value"), json(["data": message]))
                
                waitUntil { (done) in
                    
                    ServiceTaskBuilder()
                        .endpoint(.GET, URL(string: "test.test")!)
                        .query(["key": "value"])
                        .json { (object, response) in
                            
                            guard let dictionary = object as? [AnyHashable: Any] else {
                                fail("Invalid json data")
                                return
                            }
                            
                            guard let data = dictionary["data"] as? String else {
                                fail("Invalid data format")
                                return
                            }
                            
                            guard data == message else {
                                fail("Invalid data received")
                                return
                            }
                            
                            done()
                        }
                        .error { (error, response) in
                            fail("\(error)")
                        }
                        .perform()
                }
            }
            
            it("can download file") {
                
                let original = Data(count: 20)
                
                self.stub(http(.get, uri: "test.download"), http(200, download: .content(original)))
                
                waitUntil { (done) in
                    
                    ServiceTaskBuilder()
                        .endpoint("GET", "test.download")
                        .file { (url, response) in
                            
                            let data = try! Data(contentsOf: url)
                            
                            // Cleanup
                            try! FileManager.default.removeItem(at: url)
                            
                            if data == original {
                                done()
                            }
                            else {
                                fail("Not the same data!")
                            }
                        }
                        .error { (error, response) in
                            fail("\(error)")
                        }
                        .download()
                }
                
            }
            
            it("can send and receive protobuf messages") {
                
                func testProto(_ method: Mockingjay.HTTPMethod, uri: String, message: Google_Protobuf_SourceContext) -> (_ request: URLRequest) -> Bool {
                    return { (request:URLRequest) in
                        
                        if let requestMethod = request.httpMethod, requestMethod == method.description, let stream = request.httpBodyStream {

                            let read: Data
                            do {
                                read = try self.readData(from: stream)
                            }
                            catch {
                                fail("Read error: \(error)")
                                return false
                            }

                            do {
                                let decoded = try Google_Protobuf_SourceContext(jsonUTF8Data: read)
                                if decoded != message {
                                    fail("messages are different!")
                                }

                                return Mockingjay.uri(uri)(request)
                            } catch {
                                print(error)
                            }
                        }
                        
                        return false
                    }
                }
                
                var message = Google_Protobuf_SourceContext()
                message.fileName = "Test"
                
                self.stub(testProto(.patch, uri: "test.test.com", message: message), json(["file_name": "Test"], headers: ["Content-Type": "application/json", "grpc-metadata-content-type": "application/grpc"]))
                
                waitUntil { (done) in
                    
                    ServiceTaskBuilder()
                        .endpoint("PATCH", URL(string: "test.test.com")!)
                        .body(proto: Google_Protobuf_SourceContext.self) { (message) in
                            message.fileName = "Test"
                        }
                        .response(proto: Google_Protobuf_SourceContext.self) { (response) -> Void in
                            switch response {
                            case .success(let message):
                                if message.fileName == "Test" {
                                    done()
                                }
                                else {
                                    fail()
                                }
                            case .failure(let error):
                                fail("\(error)")
                            }
                        }
                        .perform()
                }
                
                waitUntil { (done) in
                    
                    ServiceTaskBuilder()
                        .endpoint("PATCH", URL(string: "test.test.com")!)
                        .body(proto: Google_Protobuf_SourceContext.self) { (message) in
                            message.fileName = "Test"
                        }
                        .proto(Google_Protobuf_SourceContext.self) { (message, response) -> Void in
                            if message.fileName == "Test" {
                                done()
                            }
                            else {
                                fail()
                            }
                        }
                        .error { (error, response) in
                            fail("\(error)")
                        }
                        .perform()
                }
                
                waitUntil { (done) in
                    
                    ServiceTaskBuilder()
                        .endpoint("PATCH", URL(string: "test.test.com")!)
                        .body { (message: inout Google_Protobuf_SourceContext) in
                            message.fileName = "Test"
                        }
                        .proto { (message: Google_Protobuf_SourceContext, response) in
                            if message.fileName == "Test" {
                                done()
                            }
                            else {
                                fail()
                            }
                        }
                        .error { (error, response) in
                            fail("\(error)")
                        }
                        .perform()
                }
                
                waitUntil { (done) in
                    
                    var message = Google_Protobuf_SourceContext()
                    message.fileName = "Test"
                    
                    ServiceTaskBuilder()
                        .endpoint("PATCH", URL(string: "test.test.com")!)
                        .body(proto: message)
                        .response { (response: ServiceTaskResponse<Google_Protobuf_SourceContext>) -> Void in
                            switch response {
                            case .success(let message):
                                if message.fileName == "Test" {
                                    done()
                                }
                                else {
                                    fail()
                                }
                            case .failure(let error):
                                fail("\(error)")
                            }
                        }
                        .perform()
                }
            }
     
            it("can send and receive Codable objects") {
                
                func testDecodable(object: Codable) -> (_ request: URLRequest) -> Response {
                    return { (request:URLRequest) in
                        
                        if let stream = request.httpBodyStream {
                            
                            let read: Data
                            do {
                                read = try self.readData(from: stream)
                            }
                            catch {
                                return Mockingjay.Response.failure(NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Stream error: \(error)"]))
                            }
                            
                            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])
                            return Mockingjay.Response.success(response!, .content(read))
                        }
                        
                        return Mockingjay.Response.failure(NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "No stream!"]))
                    }
                }
                
                let test = Test(data: "Test")
                
                self.stub(http(.post, uri: "test.test"), testDecodable(object: test))
                
                waitUntil { (done) in
                    
                    ServiceTaskBuilder()
                        .url("test.test")
                        .method(.POST)
                        .body(codable: test)
                        .response { (response: ServiceTaskResponse<Test>) -> Void in
                            switch response {
                            case .success(let object):
                                expect(object.data).to(equal("Test"))
                                done()
                            case .failure(let error):
                                fail("\(error)")
                            }
                        }
                        .perform()
                }
                
                waitUntil { (done) in
                    
                    ServiceTaskBuilder()
                        .url("test.test")
                        .method(.POST)
                        .body(codable: test)
                        .codable { (object: Test, response) in
                            expect(object.data).to(equal("Test"))
                            done()
                        }
                        .error { (error, response) in
                            fail(error.localizedDescription)
                        }
                        .perform()
                }
                
                waitUntil { (done) in
                    
                    ServiceTaskBuilder()
                        .url("test.test")
                        .method(.POST)
                        .body(codable: test)
                        .codable(Test.self) { (object, response) in
                            expect(object.data).to(equal("Test"))
                            done()
                        }
                        .error { (error, response) in
                            fail(error.localizedDescription)
                        }
                        .perform()
                }
            }

            it("can perform request with multipart form data") {

                let sampleData = "--TEST\r\nContent-Disposition: form-data; name=\"Param\"\r\n\r\nValue\r\n--TEST\r\nContent-Disposition: form-data; name=\"Data URL\"\r\nContent-Type: text/plain\r\n\r\nTest\r\n--TEST\r\nContent-Disposition: form-data; name=\"Data Data\"\r\nContent-Type: data\r\n\r\nTest\r\n--TEST\r\nContent-Disposition: form-data; name=\"File Data\"; filename=\"filename\"\r\nContent-Type: file\r\n\r\nTest\r\n--TEST\r\nContent-Disposition: form-data; name=\"File URL\"; filename=\"filename\"\r\nContent-Type: text/plain\r\n\r\nTest\r\n--TEST\r\nContent-Disposition: form-data; name=\"Text\"\r\nContent-Type: text/plain; charset=us-ascii\r\n\r\nText text test\r\n--TEST\r\nContent-Disposition: form-data; name=\"Text Data\"\r\nContent-Type: text/plain; charset=us-ascii\r\nContent-Transfer-Encoding: binary\r\n\r\nTest text\r\n--TEST\r\nContent-Disposition: form-data; name=\"Text URL\"\r\nContent-Type: text/plain; charset=utf-8\r\n\r\nTest\r\n--TEST--\r\n"

                func testMultipartData() -> (_ request: URLRequest) -> Response {
                    return { (request:URLRequest) in
                        if let stream = request.httpBodyStream {
                            
                            let read: Data
                            do {
                                read = try self.readData(from: stream)
                            }
                            catch {
                                return Mockingjay.Response.failure(NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Stream error: \(error)"]))
                            }
                            
                            let result = String(data: read, encoding: .utf8)
                            
                            expect(result).to(equal(sampleData))
                            
                            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)
                            return Mockingjay.Response.success(response!, .content(Data()))
                        }
                        
                        return Mockingjay.Response.failure(NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "No multipart stream!"]))
                    }
                }

                self.stub(http(.post, uri: "test.multipart"), testMultipartData())

                let testFileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("txt")
                try! "Test".data(using: .utf8)!.write(to: testFileURL)
                
                var builder = FormDataBuilder(boundary: "TEST")
                builder.append(.property(name: "Param", value: "Value"))
                builder.append(try! .binary(name: "Data URL", url: testFileURL))
                builder.append(.binary(name: "Data Data", mimeType: "data", data: "Test".data(using: .utf8)!))
                builder.append(.file(name: "File Data", fileName: "filename", mimeType: "file", data: "Test".data(using: .utf8)!))
                builder.append(try! .file(name: "File URL", fileName: "filename", url: testFileURL))
                builder.append(try! .text(name: "Text", encoding: .ascii, value: "Text text test"))
                builder.append(.text(name: "Text Data", encoding: .ascii, transferEncoding: .binary, data: "Test text".data(using: .ascii)!))
                builder.append(try! .text(name: "Text URL", url: testFileURL))
                
                expect(builder.calculateContentSize()).to(equal(840))
                
                let formDataURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("formdata")
                try! builder.encode(to: formDataURL)
                
                try? FileManager.default.removeItem(at: testFileURL)
                
                waitUntil { (done) in
                    
                    ServiceTaskBuilder()
                        .endpoint(.POST, "test.multipart")
                        .body(url: formDataURL, contentType: builder.contentType)
                        .response(status: { (response) in
                            switch response {
                            case .success:
                                break
                            case .failure(let error):
                                fail("Failed to upload form data: \(error)")
                            }
                            try? FileManager.default.removeItem(at: testFileURL)
                            done()
                        })
                        .upload()
                }
            }
        }
    }
    
}
