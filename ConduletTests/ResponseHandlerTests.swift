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
            
            class TestContentHandler: DataContentHandler<Data> {
                
                override func transform(data: Data, response: URLResponse) throws -> Data {
                    return data
                }
            }
            
            it("fails when call to abstract implementation") {
                
                do {
                    let _ = try DataContentHandler<Data>().transform(data: Data(), response: URLResponse(url: URL(string: "test.test")!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil))
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
                    
                    let handler = TestContentHandler { (data, response) in
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

                waitUntil { (done) in

                    let dictionary = ["key": "test"]
                    let data = try! URLEncodedSerialization.data(with: dictionary)

                    let response = URLResponse(url: URL(string: "test.com")!, mimeType: "application/x-www-form-urlencoded", expectedContentLength: data.count, textEncodingName: nil)

                    let handler = URLEncodedContentHandler(completion: { (dictionary, response) in
                        expect(dictionary["key"]).to(equal("test"))
                        done()
                    })

                    try! handler.handle(content: ServiceTaskContent.data(data), response: response)
                }
            }
        }

        describe("TextContentHandler") {

            it("can handle text content") {

                waitUntil { (done) in

                    let string = "test text"
                    let data = string.data(using: String.Encoding.utf16)!

                    let response = URLResponse(url: URL(string: "test.com")!, mimeType: "text/plain", expectedContentLength: data.count, textEncodingName: "utf-16")

                    let handler = TextContentHandler { (text, response) in
                        done()
                    }

                    do {
                        try handler.handle(content: ServiceTaskContent.data(data), response: response)
                    }
                    catch {
                        fail("Failed to handle: \(error)")
                    }
                }
            }
        }
    }
}
