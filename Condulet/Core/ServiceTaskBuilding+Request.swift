//
//  ServiceTaskBuilding+Request.swift
//  Condulet
//
//  Created by Natan Zalkin on 28/09/2018.
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
    
    /// Set URLSession instance to use when creating URLSessionTask instance
    @discardableResult
    public func session(_ session: URLSession) -> Self {
        task.session = session
        return self
    }
    
    /// Set HTTP method for request
    @discardableResult
    public func method(_ method: HTTPMethod) -> Self {
        task.method = method
        return self
    }
    
    /// Set HTTP method for request
    @discardableResult
    public func method(_ method: String) -> Self {
        task.method = HTTPMethod(rawValue: method)
        return self
    }
    
    /// Define service API url
    @discardableResult
    public func url(_ string: String) -> Self {
        if let endpoint = URLComponents(string: string) {
            task.url = endpoint
        }
        return self
    }
    
    /// Define service API url
    @discardableResult
    public func url(_ url: URL) -> Self {
        if let endpoint = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            task.url = endpoint
        }
        return self
    }
    
    /// Define url as components
    @discardableResult
    public func components(_ components: URLComponents) -> Self {
        task.url = components
        return self
    }
    
    /// Define service API url and method
    @discardableResult
    public func endpoint(_ method: HTTPMethod, _ string: String) -> Self {
        if let endpoint = URLComponents(string: string) {
            task.url = endpoint
        }
        task.method = method
        return self
    }
    
    /// Define service API url and method
    @discardableResult
    public func endpoint(_ method: HTTPMethod, _ url: URL) -> Self {
        if let endpoint = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            task.url = endpoint
        }
        task.method = method
        return self
    }

    /// Define service API url and method
    @discardableResult
    public func endpoint(_ method: String, _ string: String) -> Self {
        if let endpoint = URLComponents(string: string) {
            task.url = endpoint
        }
        task.method = HTTPMethod(rawValue: method)
        return self
    }

    /// Define service API url and method
    @discardableResult
    public func endpoint(_ method: String, _ url: URL) -> Self {
        if let endpoint = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            task.url = endpoint
        }
        task.method = HTTPMethod(rawValue: method)
        return self
    }
    
    /// Set endpoint sheme
    @discardableResult
    public func scheme(_ scheme: String) -> Self {
        task.url.scheme = scheme
        return self
    }
    
    /// Set endpoint host
    @discardableResult
    public func host(_ host: String) -> Self {
        task.url.host = host
        return self
    }
    
    /// Set endpoint user
    @discardableResult
    public func user(_ user: String) -> Self {
        task.url.user = user
        return self
    }
    
    /// Set endpoint password
    @discardableResult
    public func password(_ password: String) -> Self {
        task.url.password = password
        return self
    }
    
    /// Set endpoint port
    @discardableResult
    public func port(_ port: Int) -> Self {
        task.url.port = port
        return self
    }
    
    /// Set endpoint relative path
    @discardableResult
    public func path(_ path: String) -> Self {
        task.url.path = path
        return self
    }
    
    /// Set endpoint fragment
    @discardableResult
    public func fragment(_ fragment: String) -> Self {
        task.url.fragment = fragment
        return self
    }
    
    /// Set endpoint query parameters
    @discardableResult
    public func query(_ query: String) -> Self {
        task.url.query = query
        return self
    }
    
    /// Set endpoint query parameters
    @discardableResult
    public func query(_ query: [String: String]) -> Self {
        task.url.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        return self
    }
    
    /// Set endpoint query parameters
    @discardableResult
    public func query(_ query: [URLQueryItem]) -> Self {
        task.url.queryItems = query
        return self
    }
    
    /// Append HTTP headers to request. When 'merge' flag is true new headers will be merged with the existing by overriding old keys. Default 'merge' flag value is true. Set 'merge' parameter to false to replace existing headers. 
    @discardableResult
    public func headers(_ headers: [String: String], merge: Bool = true) -> Self {
        if merge {
            // Append by overriding existing key with new one in case of collision
            task.headers.merge(headers, uniquingKeysWith: { return $1 })
        }
        else {
            task.headers = headers
        }
        return self
    }

    /// Set 'Content-Type' HTTP header value
    @discardableResult
    public func contentType(value: String) -> Self {
        task.headers["Content-Type"] = value
        return self
    }

}
