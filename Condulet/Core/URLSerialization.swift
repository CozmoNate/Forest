//
//  URLSerialization.swift
//  Condulet
//
//  Created by Natan Zalkin on 29/09/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

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
