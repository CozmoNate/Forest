//
//  ServiceTask+Body.swift
//  Condulet
//
//  Created by Natan Zalkin on 05/10/2018.
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


public extension ServiceTask {
    
    /// Set HTTP request body
    @discardableResult
    public func body(mimeType: String? = nil, data: Data) -> Self {
        contentType = mimeType
        body = Content(data)
        return self
    }
    
    /// Set HTTP request body, load data from file
    @discardableResult
    public func body(url: URL) -> Self {
        contentType = mimeTypeForFileAtURL(url)
        body = Content(url)
        return self
    }
    
    /// Set HTTP request body
    @discardableResult
    public func body(text: String) -> Self {
        contentType = "text/plain"
        body = Content(text.data(using: .utf8))
        return self
    }
    
    /// Set HTTP request body
    @discardableResult
    public func body(json: [AnyHashable: Any]) -> Self {
        contentType = "application/json"
        body = Content(try? JSONSerialization.data(withJSONObject: json, options: []))
        return self
    }
    
    /// Set HTTP request body
    @discardableResult
    public func body(json: [Any]) -> Self {
        contentType = "application/json"
        body = Content(try? JSONSerialization.data(withJSONObject: json, options: []))
        return self
    }
    
    /// Set HTTP request body
    @discardableResult
    public func body(urlencoded: [String: String]) -> Self {
        contentType = "application/x-www-form-urlencoded"
        body = Content(try? URLSerialization.data(with: urlencoded))
        return self
    }
    
    private static let jsonEncoder = JSONEncoder()
    
    /// Set HTTP request body
    @discardableResult
    public func body<T: Encodable>(codable: T) -> Self {
        contentType = "application/json"
        body = Content(try? JSONEncoder().encode(codable))
        return self
    }

    /// Set HTTP request body as multipart form data
    @discardableResult
    public func multipart(boundary: String, content: Content) -> Self {
        contentType = "multipart/form-data; boundary=\(boundary)"
        body = content
        return self
    }
}
