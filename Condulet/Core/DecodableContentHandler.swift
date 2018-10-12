//
//  DecodableContentHandler.swift
//  Condulet
//
//  Created by Natan Zalkin on 30/09/2018.
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


/// A handler that expects and parse response with object conforming Decodable protocol. Completion block returns instance of the object on success
public class DecodableContentHandler<T: Decodable>: DataContentHandler {
    
    public var decoder = JSONDecoder()
    public var completion: ((T, URLResponse) -> Void)?
    
    public init(completion: ((T, URLResponse) -> Void)? = nil) {
        self.completion = completion
    }
    
    public override func handle(data: Data, response: URLResponse) throws {
        
        guard response.mimeType == "application/json" else {
            throw ServiceTaskError.invalidResponseContent
        }
        
        let object = try decoder.decode(T.self, from: data)
        
        completion?(object, response)
    }
    
}
