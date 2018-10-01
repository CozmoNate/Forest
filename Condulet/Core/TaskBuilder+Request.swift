//
//  TaskBuilder+Request.swift
//  Condulet
//
//  Created by Natan Zalkin on 28/09/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

import Foundation


public extension TaskBuilder {
    
    /// Set URLSession instance to use when creating URLSessionTask instance
    @discardableResult
    public func session(_ session: URLSession) -> Self {
        task.session = session
        return self
    }
    
    /// Define service API url
    @discardableResult
    public func url(_ string: String) -> Self {
        if let endpoint = URLComponents(string: string) {
            task.endpoint = endpoint
        }
        return self
    }
    
    /// Define service API url
    @discardableResult
    public func url(_ url: URL) -> Self {
        if let endpoint = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            task.endpoint = endpoint
        }
        return self
    }
    
    /// Define url as components
    @discardableResult
    public func components(_ components: URLComponents) -> Self {
        task.endpoint = components
        return self
    }
    
    /// Define service API url and method
    @discardableResult
    public func endpoint(_ method: ServiceTask.Method, _ string: String) -> Self {
        if let endpoint = URLComponents(string: string) {
            task.endpoint = endpoint
        }
        task.method = method
        return self
    }
    
    /// Define service API url and method
    @discardableResult
    public func endpoint(_ method: ServiceTask.Method, _ url: URL) -> Self {
        if let endpoint = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            task.endpoint = endpoint
        }
        task.method = method
        return self
    }
    
    /// Set endpoint sheme
    @discardableResult
    public func scheme(_ scheme: String) -> Self {
        task.endpoint.scheme = scheme
        return self
    }
    
    /// Set endpoint host
    @discardableResult
    public func host(_ host: String) -> Self {
        task.endpoint.host = host
        return self
    }
    
    /// Set endpoint user
    @discardableResult
    public func user(_ user: String) -> Self {
        task.endpoint.user = user
        return self
    }
    
    /// Set endpoint password
    @discardableResult
    public func password(_ password: String) -> Self {
        task.endpoint.password = password
        return self
    }
    
    /// Set endpoint port
    @discardableResult
    public func port(_ port: Int) -> Self {
        task.endpoint.port = port
        return self
    }
    
    /// Set endpoint relative path
    @discardableResult
    public func path(_ path: String) -> Self {
        task.endpoint.path = path
        return self
    }
    
    /// Set endpoint fragment
    @discardableResult
    public func fragment(_ fragment: String) -> Self {
        task.endpoint.fragment = fragment
        return self
    }
    
    /// Set endpoint query parameters
    @discardableResult
    public func query(_ query: String) -> Self {
        task.endpoint.query = query
        return self
    }
    
    /// Set endpoint query parameters
    @discardableResult
    public func query(_ query: [String: String]) -> Self {
        task.endpoint.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        return self
    }
    
    /// Set endpoint query parameters
    @discardableResult
    public func query(_ query: [URLQueryItem]) -> Self {
        task.endpoint.queryItems = query
        return self
    }
    
    /// Set HTTP method for request
    @discardableResult
    public func method(_ method: ServiceTask.Method) -> Self {
        task.method = method
        return self
    }
    
    /// Set HTTP headers for request. Set 'merge' parameter to false to override headers
    @discardableResult
    public func headers(_ headers: [String: String], merge: Bool = true) -> Self {
        if merge {
            task.headers.merge(headers, uniquingKeysWith: { return $1 })
        }
        else {
            task.headers = headers
        }
        return self
    }
    
    /// Set HTTP request body
    @discardableResult
    public func body(_ data: Data) -> Self {
        task.body = data
        return self
    }
    
    /// Set HTTP request body
    @discardableResult
    public func body(text: String) -> Self {
        task.contentType = "text/plain"
        task.body = text.data(using: .utf8)
        return self
    }
    
    /// Set HTTP request body
    @discardableResult
    public func body(json: [AnyHashable: Any]) -> Self {
        task.contentType = "application/json"
        task.body = try? JSONSerialization.data(withJSONObject: json, options: [])
        return self
    }

    /// Set HTTP request body
    @discardableResult
    public func body(json: [Any]) -> Self {
        task.contentType = "application/json"
        task.body = try? JSONSerialization.data(withJSONObject: json, options: [])
        return self
    }
    
    /// Set HTTP request body
    @discardableResult
    public func body(urlencoded: [String: String]) -> Self {
        task.contentType = "application/x-www-form-urlencoded"
        task.body = try? URLSerialization.data(with: urlencoded)
        return self
    }

    private static let jsonEncoder = JSONEncoder()
    
    /// Set HTTP request body
    @discardableResult
    public func body<T: Encodable>(encodable: T) -> Self {
        task.contentType = "application/json"
        task.body = try? TaskBuilder.jsonEncoder.encode(encodable)
        return self
    }
    
}
