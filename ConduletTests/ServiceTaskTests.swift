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
                            case ConduletError.statusCode(404):
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
                        
                        if let requestMethod = request.httpMethod, requestMethod == method.description {
                            if let stream = request.httpBodyStream, let length = request.allHTTPHeaderFields?["Content-Length"] {
                                
                                let size = Int(length)!
                                let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
                                defer {
                                    buffer.deallocate()
                                }
                                
                                stream.open()
                                stream.read(buffer, maxLength: size)
                                stream.close()
                                
                                let data = Data(bytes: buffer, count: size)
                                
                                do {
                                    let decoded = try Google_Protobuf_SourceContext(jsonUTF8Data: data)
                                    if decoded == message {
                                        return Mockingjay.uri(uri)(request)
                                    }
                                    return false
                                } catch {
                                    print(error)
                                }
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
                        .body { (message: inout Google_Protobuf_SourceContext) in
                            message.fileName = "Test"
                        }
                        .proto{ (message: Google_Protobuf_SourceContext, response) in
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
            }
            
            it("can send and receive Codable objects") {
                
                func testDecodable(_ method: HTTPMethod, uri: String, object: Test) -> (_ request: URLRequest) -> Bool {
                    return { (request:URLRequest) in
                        
                        if let requestMethod = request.httpMethod, requestMethod == method.description {
                            if let stream = request.httpBodyStream, let length = request.allHTTPHeaderFields?["Content-Length"] {
                                
                                let size = Int(length)!
                                let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
                                defer {
                                    buffer.deallocate()
                                }
                                
                                stream.open()
                                stream.read(buffer, maxLength: size)
                                stream.close()
                                
                                let data = Data(bytes: buffer, count: size)
                                
                                do {
                                    let decoded = try JSONDecoder().decode(Test.self, from: data)
                                    if decoded.data == object.data {
                                        return Mockingjay.uri(uri)(request)
                                    }
                                    return false
                                } catch {
                                    print(error)
                                }
                            }
                        }
                        
                        return false
                    }
                }
                
                let test = Test(data: "Test")
                let data = try! JSONEncoder().encode(test)
                
                self.stub(testDecodable(.post, uri: "test.test", object: test), jsonData(data))
                
                waitUntil { (done) in
                    
                    ServiceTask()
                        .url("test.test")
                        .method(.POST)
                        .body(codable: test)
                        .codable { (object: Test, response) in
                            if object.data == "Test" {
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
            }

            it("can perform request with multipart form data") {

                func testMultipart(_ method: HTTPMethod, uri: String) -> (_ request: URLRequest) -> Bool {
                    return { (request:URLRequest) in

                        if let requestMethod = request.httpMethod, requestMethod == method.description {
                            if let stream = request.httpBodyStream, let length = request.allHTTPHeaderFields?["Content-Length"] {

                                let size = Int(length)!
                                let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
                                defer {
                                    buffer.deallocate()
                                }

                                stream.open()
                                stream.read(buffer, maxLength: size)
                                stream.close()

                                let data = Data(bytes: buffer, count: size)

                                guard let text = String(data: data, encoding: .utf8) else {
                                    return false
                                }

                                guard text == "--TEST\r\nContent-Disposition: form-data; name=\"Test\"\r\n\r\nValue\r\n--TEST--\r\n" else {
                                    return false
                                }

                                print("multipart: \n\(text)")

                                return Mockingjay.uri(uri)(request)

                            }
                        }

                        return false
                    }
                }

                self.stub(testMultipart(.post, uri: "test.multipart"), json(["test": "ok"]))

                waitUntil { (done) in

                    var data = ServiceTask.MultipartFormData()

                    data.boundary = "TEST"
                    data.appendMediaItem(.parameter(name: "Test", value: "Value"))

                    ServiceTask()
                        .endpoint(.POST, "test.multipart")
                        .body(multipart: data)
                        .content { (content, response) in
                            done()
                        }
                        .error { (error, response) in
                            fail("\(error)")
                        }
                        .perform()

                }
            }
        }
    }
    
}
