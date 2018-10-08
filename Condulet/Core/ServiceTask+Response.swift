//
//  ServiceTask+Response.swift
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


// MARK: - Response handlers expecting specific type of response data

public extension ServiceTask {

    /// Set response handler
    @discardableResult
    public func response(_ handler: ServiceTaskResponseHandling) -> Self {
        responseHandler = handler
        return self
    }

    /// Set error handler
    @discardableResult
    public func error(_ handler: ServiceTaskErrorHandling) -> Self {
        errorHandler = handler
        return self
    }

    /// Handle response with block
    @discardableResult
    public func content(_ handler: @escaping (ServiceTask.Content, URLResponse) -> Void) -> Self {
        responseHandler = ResponseHandler { [unowned queue = responseQueue] (content, response) in
            queue.addOperation {
                handler(content, response)
            }
        }
        return self
    }

    /// Handle data response. If received response of other type task will fail with ConduletError.invalidResponse
    @discardableResult
    public func data(_ handler: @escaping (Data, URLResponse) -> Void) -> Self {
        responseHandler = ResponseHandler { [unowned queue = responseQueue] (content, response) in
            switch content {
            case let .data(data):
                queue.addOperation {
                    handler(data, response)
                }
            default:
                throw ServiceTaskError.invalidResponse
            }
        }
        return self
    }
    
    /// Handle file response. If received response of other type task will fail with ConduletError.invalidResponse
    @discardableResult
    public func file(_ handler: @escaping (URL, URLResponse) -> Void) -> Self {
        responseHandler = ResponseHandler { [unowned queue = responseQueue] (content, response) in
            switch content {
            case let .file(url):
                queue.addOperation {
                    handler(url, response)
                }
            default:
                throw ServiceTaskError.invalidResponse
            }
        }
        return self
    }

    /// Handle text response. If received response of other type task will fail with ConduletError.invalidResponse
    @discardableResult
    public func text(_ handler: @escaping (String, URLResponse) -> Void) -> Self {
        responseHandler = TextContentHandler { [unowned queue = responseQueue] (string, response) in
            queue.addOperation {
                handler(string, response)
            }
        }
        return self
    }

    /// Handle json response. If received response of other type task will fail with ConduletError.invalidResponse
    @discardableResult
    public func json(_ handler: @escaping (Any, URLResponse) -> Void) -> Self {
        responseHandler = JSONContentHandler { [unowned queue = responseQueue] (object, response) in
            queue.addOperation {
                handler(object, response)
            }
        }
        return self
    }
    
    /// Handle url-encoded response. If received response of other type task will fail with ConduletError.invalidResponse
    @discardableResult
    public func urlencoded(_ handler: @escaping ([String: String], URLResponse) -> Void) -> Self {
        responseHandler = URLEncodedContentHandler { [unowned queue = responseQueue] (dictionary, response) in
            queue.addOperation {
                handler(dictionary, response)
            }
        }
        return self
    }
    
    /// Handle json response with serialized Decodable object of type. If received response of other type task will fail with ConduletError.invalidResponse
    @discardableResult
    public func codable<T: Decodable>(_ handler: @escaping (T, URLResponse) -> Void) -> Self {
        responseHandler = DecodableContentHandler { [unowned queue = responseQueue] (object: T, response) in
            queue.addOperation {
                handler(object, response)
            }
        }
        return self
    }

    /// Handle json response with serialized Decodable object of type. If received response of other type task will fail with ConduletError.invalidResponse
    @discardableResult
    public func codable<T: Decodable>(_ type: T.Type, handler: @escaping (T, URLResponse) -> Void) -> Self {
        responseHandler = DecodableContentHandler { [unowned queue = responseQueue] (object: T, response) in
            queue.addOperation {
                handler(object, response)
            }
        }
        return self
    }

    /// Handle error with block
    @discardableResult
    public func error(_ handler: @escaping (Error, URLResponse?) -> Void) -> Self {
        errorHandler = ErrorHandler { [unowned queue = responseQueue] (error, response) in
            queue.addOperation {
                handler(error, response)
            }
        }
        return self
    }

}

// MARK: - Encapsulated response handlers

public extension ServiceTask {

    public enum Response<T> {
        case success(T)
        case failure(Error)
    }
}

public extension ServiceTask {

    /// Handle response with block
    @discardableResult
    public func response(content handler: @escaping (Response<ServiceTask.Content>) -> Void) -> Self {
        content { (content, response) in
            handler(Response.success(content))
        }
        error { (error, response) in
            handler(Response.failure(error))
        }
        return self
    }

    /// Handle data response. If received response of other type task will fail with ConduletError.invalidResponse
    @discardableResult
    public func response(data handler: @escaping (Response<Data>) -> Void) -> Self {
        data { (data, response) in
            handler(Response.success(data))
        }
        error { (error, response) in
            handler(Response.failure(error))
        }
        return self
    }

    /// Handle file response. If received response of other type task will fail with ConduletError.invalidResponse
    @discardableResult
    public func response(file handler: @escaping (Response<URL>) -> Void) -> Self {
        file { (url, response) in
            handler(Response.success(url))
        }
        error { (error, response) in
            handler(Response.failure(error))
        }
        return self
    }

    /// Handle text response. If received response of other type task will fail with ConduletError.invalidResponse
    @discardableResult
    public func response(text handler: @escaping (Response<String>) -> Void) -> Self {
        text { (string, response) in
            handler(Response.success(string))
        }
        error { (error, response) in
            handler(Response.failure(error))
        }
        return self
    }

    /// Handle json response. If received response of other type task will fail with ConduletError.invalidResponse
    @discardableResult
    public func response(json handler: @escaping (Response<Any>) -> Void) -> Self {
        json { (object, response) in
            handler(Response.success(object))
        }
        error { (error, response) in
            handler(Response.failure(error))
        }
        return self
    }

    /// Handle url-encoded response. If received response of other type task will fail with ConduletError.invalidResponse
    @discardableResult
    public func response(urlencoded handler: @escaping (Response<[String: String]>) -> Void) -> Self {
        urlencoded { (dictionary, response) in
            handler(Response.success(dictionary))
        }
        error { (error, response) in
            handler(Response.failure(error))
        }
        return self
    }

    /// Handle json response with serialized Decodable object of type. If received response of other type task will fail with ConduletError.invalidResponse
    @discardableResult
    public func response<T: Decodable>(codable type: T.Type, handler: @escaping (Response<T>) -> Void) -> Self {
        codable { (object, response) in
            handler(Response.success(object))
        }
        error { (error, response) in
            handler(Response.failure(error))
        }
        return self
    }

    /// Handle json response with serialized Decodable object of type. If received response of other type task will fail with ConduletError.invalidResponse
    @discardableResult
    public func response<T: Decodable>(codable handler: @escaping (Response<T>) -> Void) -> Self {
        codable { (object, response) in
            handler(Response.success(object))
        }
        error { (error, response) in
            handler(Response.failure(error))
        }
        return self
    }

}
