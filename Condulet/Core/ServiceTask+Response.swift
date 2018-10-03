//
//  ServiceTask+Response.swift
//  Condulet
//
//  Created by Natan Zalkin on 29/09/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

import Foundation


public extension ServiceTask {
    
    /// Set response handler
    @discardableResult
    public func response(_ handler: ServiceTaskResponseHandling) -> Self {
        responseHandler = handler
        return self
    }
    
    /// Handle response with block
    @discardableResult
    public func response(_ handler: @escaping (ServiceTask.Content, URLResponse) -> Void) -> Self {
        responseHandler = ResponseHandler { [unowned queue = responseQueue] (content, response) in
            queue.addOperation {
                handler(content, response)
            }
        }
        return self
    }
    
    /// Set error handler
    @discardableResult
    public func error(_ handler: ServiceTaskErrorHandling) -> Self {
        errorHandler = handler
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

    /// Handle data response
    @discardableResult
    public func data(_ handler: @escaping (Data, URLResponse) -> Void) -> Self {
        responseHandler = ResponseHandler { [unowned queue = responseQueue] (content, response) in
            switch content {
            case let .data(data):
                queue.addOperation {
                    handler(data, response)
                }
            default:
                throw ConduletError.invalidResponse
            }
        }
        return self
    }
    
    /// Handle data response
    @discardableResult
    public func result(data handler: @escaping (Data, URLResponse) -> Void) -> Self {
        return data(handler)
    }
    
    /// Handle file response
    @discardableResult
    public func file(_ handler: @escaping (URL, URLResponse) -> Void) -> Self {
        responseHandler = ResponseHandler { [unowned queue = responseQueue] (content, response) in
            switch content {
            case let .file(url):
                queue.addOperation {
                    handler(url, response)
                }
            default:
                throw ConduletError.invalidResponse
            }
        }
        return self
    }
    
    /// Handle file response
    @discardableResult
    public func result(file handler: @escaping (URL, URLResponse) -> Void) -> Self {
        return file(handler)
    }

    /// Handle text response
    @discardableResult
    public func text(_ handler: @escaping (String, URLResponse) -> Void) -> Self {
        responseHandler = TextContentHandler { [unowned queue = responseQueue] (string, response) in
            queue.addOperation {
                handler(string, response)
            }
        }
        return self
    }

    /// Handle text response
    @discardableResult
    public func result(text handler: @escaping (String, URLResponse) -> Void) -> Self {
        return text(handler)
    }
    
    /// Handle json response
    @discardableResult
    public func json(_ handler: @escaping (Any, URLResponse) -> Void) -> Self {
        responseHandler = JSONContentHandler { [unowned queue = responseQueue] (object, response) in
            queue.addOperation {
                handler(object, response)
            }
        }
        return self
    }

    /// Handle json response
    @discardableResult
    public func result(json handler: @escaping (Any, URLResponse) -> Void) -> Self {
        return json(handler)
    }
    
    /// Handle url-encoded response
    @discardableResult
    public func urlencoded(_ handler: @escaping ([String: String], URLResponse) -> Void) -> Self {
        responseHandler = URLEncodedContentHandler { [unowned queue = responseQueue] (dictionary, response) in
            queue.addOperation {
                handler(dictionary, response)
            }
        }
        return self
    }

    /// Handle url-encoded response
    @discardableResult
    public func result(urlencoded handler: @escaping ([String: String], URLResponse) -> Void) -> Self {
        return urlencoded(handler)
    }
    
    /// Handle json response with serialized Decodable object of type
    @discardableResult
    public func codable<T: Decodable>(_ handler: @escaping (T, URLResponse) -> Void) -> Self {
        responseHandler = DecodableContentHandler { [unowned queue = responseQueue] (object: T, response) in
            queue.addOperation {
                handler(object, response)
            }
        }
        return self
    }

    /// Handle json response with serialized Decodable object of type
    @discardableResult
    public func result<T: Decodable>(codable handler: @escaping (T, URLResponse) -> Void) -> Self {
        return codable(handler)
    }
    
}
