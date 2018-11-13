//
//  ResponseHhandlerTests.swift
//  Condulet
//
//  Created by Natan Zalkin on 16/10/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

import Quick
import Nimble
import Mockingjay
import SwiftProtobuf

@testable import Condulet

class ResponseHandlerTests: QuickSpec {

    override func spec() {

        describe("DataContentHandler") {

            it("fails when call to abstract implementation") {
                
                do {
                    let _ = try DataContentHandler().transform(data: Data(), response: URLResponse(url: URL(string: "test.test")!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil))
                }
                catch {
                    expect(error).to(matchError(ServiceTaskError.notImplemented))
                }
            }
            
            it("fails when no data received but a file downloaded") {
                
                waitUntil (timeout: 5) { (done) in
                
                    let body = "Test".data(using: .ascii)!
                    let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("txt")
                    
                    try! body.write(to: file)
                    
                    let handler = DataContentHandler { (data, response) in
                        fail()
                    }
                    
                    do {
                        try handler.handle(content: .file(file), response: URLResponse(url: URL(string: "test.test")!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil))
                    }
                    catch ServiceTaskError.invalidContent {
                        done()
                    }
                    catch {
                        fail("\(error)")
                    }
                }
            }
        }
        
        describe("URLEncodedContentHandler") {

            it("can handle URL-encoded content") {
                let dictionary = ["key": "test"]
                let data = try! URLEncodedSerialization.data(with: dictionary)
                let response = URLResponse(url: URL(string: "test.com")!, mimeType: "application/x-www-form-urlencoded", expectedContentLength: data.count, textEncodingName: nil)
                let handler = URLEncodedContentHandler { (dictionary, response) in
                    expect(dictionary["key"]).to(equal("test"))
                }
                try! handler.handle(content: ServiceTaskContent.data(data), response: response)
            }

            it("fails on invalid content type") {
                let response = URLResponse(url: URL(string: "test.com")!, mimeType: "unknown", expectedContentLength: 0, textEncodingName: nil)
                let handler = URLEncodedContentHandler(completion: nil)
                do {
                    try handler.handle(content: ServiceTaskContent.data(Data()), response: response)
                }
                catch {
                    expect(error).to(matchError(ServiceTaskError.invalidContent))
                }
            }
        }

        describe("DecodableContentHandler") {

            struct TestCodable: Equatable, Codable {
                let value: String
            }

            it("can handle Codable content") {
                let codable = TestCodable(value: "TEZT")
                let data = try! JSONEncoder().encode(codable)
                let response = URLResponse(url: URL(string: "test.com")!, mimeType: "application/json", expectedContentLength: data.count, textEncodingName: nil)
                let handler = DecodableContentHandler { (object, response) in
                    expect(object).to(equal(codable))
                }
                try! handler.handle(content: ServiceTaskContent.data(data), response: response)
            }

            it("fails on invalid content type") {
                let response = URLResponse(url: URL(string: "test.com")!, mimeType: "unknown", expectedContentLength: 0, textEncodingName: nil)
                let handler = DecodableContentHandler<TestCodable>(completion: nil)
                do {
                    try handler.handle(content: ServiceTaskContent.data(Data()), response: response)
                }
                catch {
                    expect(error).to(matchError(ServiceTaskError.invalidContent))
                }
            }
        }

        describe("ProtobufContentHandler") {

            it("can handle Proto message content") {
                var message = Google_Protobuf_StringValue()
                message.value = "TEXT"
                let data = try! message.jsonUTF8Data()
                let response = HTTPURLResponse(url: URL(string: "test.com")!, statusCode: 200, httpVersion: "1.0", headerFields: [
                    "Content-Type": "application/json",
                    "grpc-metadata-content-type": "application/grpc"
                    ])!
                let handler = ProtobufContentHandler { (object, response) in
                    expect(object).to(equal(message))
                }
                try! handler.handle(content: ServiceTaskContent.data(data), response: response)
            }

            it("fails on invalid content type") {
                let response = HTTPURLResponse(url: URL(string: "test.com")!, statusCode: 200, httpVersion: "1.0", headerFields: [
                    "Content-Type": "application/json",
                    "grpc-metadata-content-type": "unknown"
                    ])!
                let handler = ProtobufContentHandler<Google_Protobuf_StringValue>(completion: nil)
                do {
                    try handler.handle(content: ServiceTaskContent.data(Data()), response: response)
                }
                catch {
                    expect(error).to(matchError(ServiceTaskError.invalidContent))
                }
            }
        }

        describe("TextContentHandler") {

            it("can handle text content") {
                let string = "test text"
                let data = string.data(using: String.Encoding.utf16)!
                let response = URLResponse(url: URL(string: "test.com")!, mimeType: "text/plain", expectedContentLength: data.count, textEncodingName: "utf-16")
                let handler = TextContentHandler { (text, response) in
                    expect(text).to(equal(string))
                }
                try! handler.handle(content: ServiceTaskContent.data(data), response: response)
            }

            it("fails on invalid content type") {
                let response = URLResponse(url: URL(string: "test.com")!, mimeType: "unknown", expectedContentLength: 0, textEncodingName: nil)
                let handler = TextContentHandler(completion: nil)
                do {
                    try handler.handle(content: ServiceTaskContent.data(Data()), response: response)
                }
                catch {
                    expect(error).to(matchError(ServiceTaskError.invalidContent))
                }
            }
        }

        describe("JSONContentHandler") {

            it("can handle JSON-encoded content") {
                let dictionary = ["key": "test"]
                let data = try! JSONSerialization.data(withJSONObject: dictionary, options: [])
                let response = URLResponse(url: URL(string: "test.com")!, mimeType: "application/json", expectedContentLength: data.count, textEncodingName: nil)
                let handler = JSONContentHandler { (object, response) in
                    guard let dictionary = object as? [String: String] else {
                        fail("Dictionary response expected")
                        return
                    }
                    expect(dictionary["key"]).to(equal("test"))
                }
                try! handler.handle(content: ServiceTaskContent.data(data), response: response)
            }

            it("fails on invalid content type") {
                let response = URLResponse(url: URL(string: "test.com")!, mimeType: "unknown", expectedContentLength: 0, textEncodingName: nil)
                let handler = JSONContentHandler(completion: nil)
                do {
                    try handler.handle(content: ServiceTaskContent.data(Data()), response: response)
                }
                catch {
                    expect(error).to(matchError(ServiceTaskError.invalidContent))
                }
            }
        }
    }
}
