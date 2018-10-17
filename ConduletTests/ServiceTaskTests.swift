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

class ServiceTaskTests: QuickSpec {
    
    struct Test: Codable {
        
        let data: String
    }
    
    func readData(from stream: InputStream, bufferSize: Int = 1_000_000) -> Data {
        
        var data = Data()
        
        stream.open()
        while stream.hasBytesAvailable {
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            defer {
                buffer.deallocate()
            }
            let result = stream.read(buffer, maxLength: bufferSize)
            if result > 0 {
                data.append(buffer, count: result)
            }
        }
        stream.close()
        
        return data
    }
    
    override func spec() {
        
        describe("ServiceTask") {

            afterEach {
                self.removeAllStubs()
            }
            
            it("can perform request") {
                
                self.stub(http(.get, uri: "test.test"), json(["test": "ok"]))
                
                waitUntil { (done) in
                    
                    ServiceTaskBuilder()
                        .endpoint(.GET, "test.test")
                        .data { (data, response) in
                            done()
                        }
                        .error { (error, response) in
                            fail("\(error)")
                        }
                        .perform()
                    
                }
            }
            
            it("can handle json array response") {
                
                let array: [Any] = [["one": "ok"], ["two": "ok"]]
                
                self.stub(http(.get, uri: "test.test"), json(array))
                
                waitUntil { (done) in
                    
                    ServiceTaskBuilder()
                        .endpoint(.GET, "test.test")
                        .array { (data, response) in
                            expect(data.count).to(equal(2))
                            done()
                        }
                        .error { (error, response) in
                            fail("\(error)")
                        }
                        .perform()
                    
                }
            }
            
            it("can fail json array response") {
                
                let dict: [AnyHashable: Any] = ["test": "ok"]
                
                self.stub(http(.get, uri: "test.test"), json(dict))
                
                waitUntil { (done) in
                    
                    ServiceTaskBuilder()
                        .endpoint(.GET, "test.test")
                        .array { (data, response) in
                            fail("Request should fail!")
                        }
                        .error { (error, response) in
                            expect(error).to(matchError(ServiceTaskError.invalidResponseData))
                            done()
                        }
                        .perform()
                    
                }
            }
            
            it("can handle json dictionary response") {
                
                let dict: [AnyHashable: Any] = ["test": "ok"]
                
                self.stub(http(.get, uri: "test.test"), json(dict))
                
                waitUntil { (done) in
                    
                    ServiceTaskBuilder()
                        .endpoint(.GET, "test.test")
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
                
                self.stub(http(.get, uri: "test.test"), json(array))
                
                waitUntil { (done) in
                    
                    ServiceTaskBuilder()
                        .endpoint(.GET, "test.test")
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
                
                self.stub(http(.get, uri: "test.cancel"), delay: 2, http(200))
                
                var canceled = false
                
                waitUntil(timeout: 5) { (done) in
                    
                    let task = ServiceTaskBuilder()
                        .endpoint(.GET, "test.cancel")
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
                
                self.stub(http(.get, uri: "test.test"), failure(NSError(domain: "test", code: 1, userInfo: nil)))
                
                waitUntil { (done) in
                    
                    ServiceTaskBuilder()
                        .url("test.test")
                        .method(.GET)
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
                        .url("test.test")
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
                
                self.stub(http(.get, uri: "test.test"), json(["data": message]))
                
                waitUntil { (done) in
                    
                    ServiceTaskBuilder()
                        .url("test.test")
                        .method(.GET)
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
                        .url("test.download")
                        .method(.GET)
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

                            let data = self.readData(from: stream)

                            do {
                                let decoded = try Google_Protobuf_SourceContext(jsonUTF8Data: data)
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
                        .url("test.test.com")
                        .method(.PATCH)
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
            }
            
            it("can send and receive Codable objects") {
                
                func testDecodable(object: Codable) -> (_ request: URLRequest) -> Response {
                    return { (request:URLRequest) in
                        
                        if let stream = request.httpBodyStream {
                            
                            let data = self.readData(from: stream)
                            
                            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])
                            return Mockingjay.Response.success(response!, .content(data))
                        }
                        
                        return Mockingjay.Response.failure(NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "No multipart stream!"]))
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
            }

            it("can perform request with multipart form data") {

                let sampleData = "--TEST\r\nContent-Disposition: form-data; name=\"Param\"\r\n\r\nValue\r\n--TEST\r\nContent-Disposition: form-data; name=\"Data URL\"\r\nContent-Type: text/plain\r\n\r\nTest\r\n--TEST\r\nContent-Disposition: form-data; name=\"Data Data\"\r\nContent-Type: data\r\n\r\nTest\r\n--TEST\r\nContent-Disposition: form-data; name=\"File Data\"; filename=\"filename\"\r\nContent-Type: file\r\n\r\nTest\r\n--TEST\r\nContent-Disposition: form-data; name=\"File URL\"; filename=\"filename\"\r\nContent-Type: text/plain\r\n\r\nTest\r\n--TEST\r\nContent-Disposition: form-data; name=\"Text\"\r\nContent-Type: text/plain; charset=us-ascii\r\n\r\nText text test\r\n--TEST\r\nContent-Disposition: form-data; name=\"Text Data\"\r\nContent-Type: text/plain; charset=us-ascii\r\nContent-Transfer-Encoding: binary\r\n\r\nTest text\r\n--TEST\r\nContent-Disposition: form-data; name=\"Text URL\"\r\nContent-Type: text/plain; charset=utf-8\r\n\r\nTest\r\n--TEST--\r\n"

                func testMultipartData() -> (_ request: URLRequest) -> Response {
                    return { (request:URLRequest) in
                        if let stream = request.httpBodyStream {
                            
                            let data = self.readData(from: stream)
                            let result = String(data: data, encoding: .utf8)
                            
                            expect(result).to(equal(sampleData))
                            
                            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)
                            return Mockingjay.Response.success(response!, .content(Data()))
                        }
                        
                        return Mockingjay.Response.failure(NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "No multipart stream!"]))
                    }
                }

                self.stub(http(.post, uri: "test.multipart"), testMultipartData())

                waitUntil { (done) in

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
