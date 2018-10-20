//  DataContentHandler.swift
//  Condulet
//
//  Created by Natan Zalkin on 12/10/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

/*
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


/// Abstract content handler. Subclasses should provide implementation allowing to convert response data to an object of specified type
open class DataContentHandler<T>: ServiceTaskResponseHandling {
    
    public typealias Result = T
    
    private var completion: ((T, URLResponse) throws -> Void)?
    
    /// Create an instance of a handler. NOTE: The block will be executed on a background thread
    public init(completion: ((T, URLResponse) throws -> Void)? = nil) {
        self.completion = completion
    }
    
    open func handle(content: ServiceTaskContent, response: URLResponse) throws {
        
        // Load response data
        let data: Data
        switch content {
        case .data(let body):
            data = body
        case .file(let url):
            defer {
                try? FileManager.default.removeItem(at: url) // Remove temp file
            }
            data = try Data(contentsOf: url, options: .mappedIfSafe)
        }
        
        // Map response data
        let result = try transform(data: data, response: response)
        
        try completion?(result, response)
    }
    
    /// Converts response body to an object of a type
    open func transform(data: Data, response: URLResponse) throws -> Result {
        throw ServiceTaskError.notImplemented // Abstract implementation always fails
    }
    
}
