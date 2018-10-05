//
//  ServiceTask+Body.swift
//  Condulet
//
//  Created by Natan Zalkin on 05/10/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

import Foundation


extension ServiceTask {
    
    /// Set HTTP request body
    @discardableResult
    public func body(mimeType: String? = nil, data: Data) -> Self {
        contentType = mimeType
        body = Body(data)
        return self
    }
    
    /// Set HTTP request body, load data from file
    @discardableResult
    public func body(url: URL) -> Self {
        contentType = contentTypeForURL(url)
        body = Body(url)
        return self
    }
    
    /// Set HTTP request body
    @discardableResult
    public func body(text: String) -> Self {
        contentType = "text/plain"
        body = Body(text.data(using: .utf8))
        return self
    }
    
    /// Set HTTP request body
    @discardableResult
    public func body(json: [AnyHashable: Any]) -> Self {
        contentType = "application/json"
        body = Body(try? JSONSerialization.data(withJSONObject: json, options: []))
        return self
    }
    
    /// Set HTTP request body
    @discardableResult
    public func body(json: [Any]) -> Self {
        contentType = "application/json"
        body = Body(try? JSONSerialization.data(withJSONObject: json, options: []))
        return self
    }
    
    /// Set HTTP request body
    @discardableResult
    public func body(urlencoded: [String: String]) -> Self {
        contentType = "application/x-www-form-urlencoded"
        body = Body(try? URLSerialization.data(with: urlencoded))
        return self
    }
    
    private static let jsonEncoder = JSONEncoder()
    
    /// Set HTTP request body
    @discardableResult
    public func body<T: Encodable>(codable: T) -> Self {
        contentType = "application/json"
        body = Body(try? JSONEncoder().encode(codable))
        return self
    }
    
}
