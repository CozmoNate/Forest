//
//  ServiceTask+Request.swift
//  Condulet
//
//  Created by Natan Zalkin on 28/09/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

import Foundation


public extension ServiceTask {
    
    /// Set URLSession instance to use when creating URLSessionTask instance
    @discardableResult
    public func session(_ session: URLSession) -> Self {
        self.session = session
        return self
    }
    
    /// Define service API url
    @discardableResult
    public func url(_ string: String) -> Self {
        if let endpoint = URLComponents(string: string) {
            self.endpoint = endpoint
        }
        return self
    }
    
    /// Define service API url
    @discardableResult
    public func url(_ url: URL) -> Self {
        if let endpoint = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            self.endpoint = endpoint
        }
        return self
    }
    
    /// Define url as components
    @discardableResult
    public func components(_ components: URLComponents) -> Self {
        self.endpoint = components
        return self
    }
    
    /// Define service API url and method
    @discardableResult
    public func endpoint(_ method: ServiceTask.Method, _ string: String) -> Self {
        if let endpoint = URLComponents(string: string) {
            self.endpoint = endpoint
        }
        self.method = method
        return self
    }
    
    /// Define service API url and method
    @discardableResult
    public func endpoint(_ method: ServiceTask.Method, _ url: URL) -> Self {
        if let endpoint = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            self.endpoint = endpoint
        }
        self.method = method
        return self
    }
    
    /// Set endpoint sheme
    @discardableResult
    public func scheme(_ scheme: String) -> Self {
        endpoint.scheme = scheme
        return self
    }
    
    /// Set endpoint host
    @discardableResult
    public func host(_ host: String) -> Self {
        endpoint.host = host
        return self
    }
    
    /// Set endpoint user
    @discardableResult
    public func user(_ user: String) -> Self {
        endpoint.user = user
        return self
    }
    
    /// Set endpoint password
    @discardableResult
    public func password(_ password: String) -> Self {
        endpoint.password = password
        return self
    }
    
    /// Set endpoint port
    @discardableResult
    public func port(_ port: Int) -> Self {
        endpoint.port = port
        return self
    }
    
    /// Set endpoint relative path
    @discardableResult
    public func path(_ path: String) -> Self {
        endpoint.path = path
        return self
    }
    
    /// Set endpoint fragment
    @discardableResult
    public func fragment(_ fragment: String) -> Self {
        endpoint.fragment = fragment
        return self
    }
    
    /// Set endpoint query parameters
    @discardableResult
    public func query(_ query: String) -> Self {
        endpoint.query = query
        return self
    }
    
    /// Set endpoint query parameters
    @discardableResult
    public func query(_ query: [String: String]) -> Self {
        endpoint.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        return self
    }
    
    /// Set endpoint query parameters
    @discardableResult
    public func query(_ query: [URLQueryItem]) -> Self {
        endpoint.queryItems = query
        return self
    }
    
    /// Set HTTP method for request
    @discardableResult
    public func method(_ method: ServiceTask.Method) -> Self {
        self.method = method
        return self
    }
    
    /// Set HTTP headers for request. Set 'merge' parameter to false to override headers
    @discardableResult
    public func headers(_ headers: [String: String], merge: Bool = true) -> Self {
        if merge {
            self.headers.merge(headers, uniquingKeysWith: { return $1 })
        }
        else {
            self.headers = headers
        }
        return self
    }
    
    /// Set HTTP request body
    @discardableResult
    public func body(_ data: Data) -> Self {
        self.body = data
        return self
    }
    
    /// Set HTTP request body
    @discardableResult
    public func body(text: String) -> Self {
        contentType = "text/plain"
        body = text.data(using: .utf8)
        return self
    }
    
    /// Set HTTP request body
    @discardableResult
    public func body(json: [AnyHashable: Any]) -> Self {
        contentType = "application/json"
        body = try? JSONSerialization.data(withJSONObject: json, options: [])
        return self
    }

    /// Set HTTP request body
    @discardableResult
    public func body(json: [Any]) -> Self {
        contentType = "application/json"
        body = try? JSONSerialization.data(withJSONObject: json, options: [])
        return self
    }
    
    /// Set HTTP request body
    @discardableResult
    public func body(urlencoded: [String: String]) -> Self {
        contentType = "application/x-www-form-urlencoded"
        body = try? URLSerialization.data(with: urlencoded)
        return self
    }

    private static let jsonEncoder = JSONEncoder()
    
    /// Set HTTP request body
    @discardableResult
    public func body<T: Encodable>(codable: T) -> Self {
        contentType = "application/json"
        body = try? JSONEncoder().encode(codable)
        return self
    }
    
}
