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
    
    func readData(from stream: InputStream) -> Data {
        
        var data = Data()
        
        stream.open()
        while stream.hasBytesAvailable {
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 100000)
            defer {
                buffer.deallocate()
            }
            let result = stream.read(buffer, maxLength: 100000)
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
                    
                    ServiceTask()
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
            
            it("can cancel request") {
                
                self.stub(http(.get, uri: "test.cancel"), delay: 2, http(200))
                
                var canceled = false
                
                waitUntil(timeout: 5) { (done) in
                    
                    let task = ServiceTask()
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
                    
                    ServiceTask()
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
                    
                    ServiceTask()
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
                    
                    ServiceTask()
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
                    
                    ServiceTask()
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
                
                func testProto(_ method: HTTPMethod, uri: String, message: Google_Protobuf_SourceContext) -> (_ request: URLRequest) -> Bool {
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
                    
                    ServiceTask()
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
                    
                    ServiceTask()
                        .url("test.test")
                        .method(.POST)
                        .body(codable: test)
                        .codable { (object: Test, response) in
                            expect(object.data).to(equal("Test"))
                            done()
                        }
                        .error { (error, response) in
                            fail("\(error)")
                        }
                        .perform()
                }
            }

            it("can perform request with multipart form data") {

                func testMultipartData() -> (_ request: URLRequest) -> Response {
                    return { (request:URLRequest) in
                        if let stream = request.httpBodyStream {
                            
                            let data = self.readData(from: stream)
                            let result = String(data: data, encoding: .utf8)
                            
                            expect(result).to(equal("--TEST\r\nContent-Disposition: form-data; name=\"Param\"\r\n\r\nValue\r\n--TEST\r\nContent-Disposition: form-data; name=\"Data\"\r\nContent-Type: data\r\n\r\nTest\r\n--TEST\r\nContent-Disposition: form-data; name=\"File\"; filename=\"filename\"\r\nContent-Type: file\r\n\r\nTest\r\n--TEST\r\nContent-Disposition: form-data; name=\"URL\"; filename=\"filename\"\r\nContent-Type: url\r\n\r\nTest\r\n--TEST--\r\n"))
                            
                            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)
                            return Mockingjay.Response.success(response!, .content(Data()))
                        }
                        
                        return Mockingjay.Response.failure(NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "No multipart stream!"]))
                    }
                }

                self.stub(http(.post, uri: "test.multipart"), testMultipartData())

                waitUntil { (done) in

                    var multipartData = MultipartFormData()

                    multipartData.boundary = "TEST"
                    
                    let testFileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("test")
                    
                    try? "Test".data(using: .utf8)!.write(to: testFileURL)
                    
                    do {
                        try multipartData.appendMediaItem(.parameter(name: "Param", value: "Value"))
                        try multipartData.appendMediaItem(.data(name: "Data", mimeType: "data", data: "Test".data(using: .utf8)!))
                        try multipartData.appendMediaItem(.file(name: "File", fileName: "filename", mimeType: "file", data: "Test".data(using: .utf8)!))
                        try multipartData.appendMediaItem(.url(name: "URL", fileName: "filename", mimeType: "url", url: testFileURL))
                    }
                    catch {
                        fail("\(error)")
                    }
                    
                    multipartData.generateContentData { (result) in
                        
                        switch result {
                        case .success(let encoded):
                            ServiceTask()
                                .endpoint(.POST, "test.multipart")
                                .multipart(boundary: multipartData.boundary, content: .data(encoded))
                                .content { (content, response) in
                                    done()
                                }
                                .error { (error, response) in
                                    fail("\(error)")
                                }
                                .perform()
                        case .failure(let error):
                            fail("\(error)")
                        }
                        
                        try? FileManager.default.removeItem(at: testFileURL)
                    }

                }
            }
        }
    }
    
}
