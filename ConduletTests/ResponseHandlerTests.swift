//
//  ResponseHhandlerTests.swift
//  Condulet
//
//  Created by Zalkin, Natan on 16/10/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

import Quick
import Nimble
import Mockingjay
import SwiftProtobuf

@testable import Condulet

class ResponseHandlerTests: QuickSpec {

    override func spec() {

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
