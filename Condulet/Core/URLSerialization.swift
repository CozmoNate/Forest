//
//  URLSerialization.swift
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


public enum URLSerializationError: Error {
    
    case invalidObject
    case invalidData
    case encodingFailure
    case decodingFailure
    
}

/// A class for converting dictionary to URL-encoded data and decode URL-encoded data into dictionary
open class URLSerialization {
    
    /// Generates URL-encoded data from dictionary
    open class func data(with dictionary: [String: String]) throws -> Data {
        
        var components = URLComponents()
        
        components.queryItems = dictionary.map { URLQueryItem(name: $0, value: $1) }
        
        guard let query = components.query else {
            throw URLSerializationError.invalidObject
        }
        
        let content = query.trimmingCharacters(in: CharacterSet.newlines)
        
        guard let data = content.data(using: .ascii, allowLossyConversion: true) else {
            throw URLSerializationError.encodingFailure
        }
        
        return data
    }
    
    /// Create a dictionary from URL-encoded data
    open class func dictionary(with data: Data) throws -> [String: String] {
        
        var components = URLComponents()
        
        guard let query = String(data: data, encoding: .ascii) else {
            throw URLSerializationError.invalidData
        }
        
        components.query = query
        
        guard let dictionary = components.queryItems?.reduce(into: [String: String](), { $0[$1.name] = $1.value ?? "" }) else {
            throw URLSerializationError.decodingFailure
        }
        
        return dictionary
    }

}
