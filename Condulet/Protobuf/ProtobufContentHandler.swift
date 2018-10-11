//
//  ProtobufContentHandler.swift
//  Condulet
//
//  Created by Natan Zalkin on 29/09/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

/*
 *
 * Copyright (c) 2018 Natan Zalkin
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 */

import Foundation
import SwiftProtobuf


/// A handler that expects and parse response with protobuf message. Completion block returns deserialized message of expected type on success
open class ProtobufContentHandler<T: Message>: ServiceTaskResponseHandling {
    
    public var completion: ((T, URLResponse) -> Void)?
    
    public init(completion: ((T, URLResponse) -> Void)? = nil) {
        self.completion = completion
    }
    
    public func handle(content: ServiceTaskContent?, response: URLResponse) throws {
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServiceTaskError.invalidResponse
        }
        
        guard let content = content, httpResponse.mimeType == "application/json" else {
            throw ServiceTaskError.invalidResponseContent
        }
        
        guard let metadataContentType = httpResponse.allHeaderFields["grpc-metadata-content-type"] as? String else {
            throw ServiceTaskError.invalidResponseContent
        }
        
        guard metadataContentType == "application/grpc" else {
            throw ServiceTaskError.invalidResponseContent
        }
        
        switch content {
        case let .data(data):
            let message = try T(jsonUTF8Data: data)
            completion?(message, response)
        default:
            throw ServiceTaskError.invalidResponseContent
        }
    }
}
