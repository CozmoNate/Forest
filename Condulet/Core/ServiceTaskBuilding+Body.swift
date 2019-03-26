//
//  ServiceTaskBuilding+Body.swift
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


public extension ServiceTaskBuilding {

    /// Set HTTP request body
    @discardableResult
    func body(content: ServiceTaskContent, contentType: String? = nil) -> Self {
        if let contentType = contentType {
            self.contentType(value: contentType)
        }
        task.body = content
        return self
    }

    /// Set HTTP request body
    @discardableResult
    func body(data: Data, contentType: String? = nil) -> Self {
        return body(content: .data(data), contentType: contentType)
    }
    
    /// Set HTTP request body, load data from file
    @discardableResult
    func body(url: URL, contentType: String? = nil) -> Self {
        return body(content: .file(url), contentType: contentType ?? mimeTypeForFileAtURL(url))
    }
    
    /// Set HTTP request body
    @discardableResult
    func body(text: String, encoding: String.Encoding = .utf8, allowLossyConversion: Bool = false) -> Self {
        if let charset = CFStringConvertEncodingToIANACharSetName(CFStringEncoding(encoding.rawValue)) as String? {
            contentType(value: "text/plain; charset=\(charset)")
        }
        else {
            contentType(value: "text/plain")
        }
        task.body = ServiceTaskContent(text.data(using: encoding, allowLossyConversion: allowLossyConversion))
        return self
    }
    
    /// Set HTTP request body
    @discardableResult
    func body(json: [AnyHashable: Any]) -> Self {
        contentType(value: "application/json")
        task.body = ServiceTaskContent(try? JSONSerialization.data(withJSONObject: json, options: []))
        return self
    }
    
    /// Set HTTP request body
    @discardableResult
    func body(json: [Any]) -> Self {
        contentType(value: "application/json")
        task.body = ServiceTaskContent(try? JSONSerialization.data(withJSONObject: json, options: []))
        return self
    }
    
    /// Set HTTP request body
    @discardableResult
    func body(urlencoded: [String: String]) -> Self {
        contentType(value: "application/x-www-form-urlencoded")
        task.body = ServiceTaskContent(try? URLEncodedSerialization.data(with: urlencoded))
        return self
    }
    
    /// Set HTTP request body
    @discardableResult
    func body<T: Encodable>(codable: T) -> Self {
        contentType(value: "application/json")
        task.body = ServiceTaskContent(try? JSONEncoder().encode(codable))
        return self
    }
    
}
