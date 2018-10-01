//
//  TaskBuilder+Response.swift
//  Condulet
//
//  Created by Natan Zalkin on 29/09/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

import Foundation


public extension TaskBuilder {
    
    /// Set response handler
    @discardableResult
    public func response(_ handler: ServiceTaskContentHandling) -> Self {
        task.responseHandler = handler
        return self
    }
    
    /// Handle response with block
    @discardableResult
    public func response(_ handler: @escaping (ServiceTask.Content, URLResponse) -> Void) -> Self {
        task.responseHandler = ContentHandler { [unowned queue = responseQueue] (content, response) in
            queue.addOperation {
                handler(content, response)
            }
        }
        return self
    }
    
    /// Set error handler
    @discardableResult
    public func error(_ handler: ServiceTaskErrorHandling) -> Self {
        task.errorHandler = handler
        return self
    }
    
    /// Handle error with block
    @discardableResult
    public func error(_ handler: @escaping (Error, URLResponse?) -> Void) -> Self {
        task.errorHandler = ErrorHandler { [unowned queue = responseQueue] (error, response) in
            queue.addOperation {
                handler(error, response)
            }
        }
        return self
    }

    /// Handle data response
    @discardableResult
    public func data(_ handler: @escaping (Data, URLResponse) -> Void) -> Self {
        task.responseHandler = ContentHandler { [unowned queue = responseQueue] (content, response) in
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
    
    /// Handle file response
    @discardableResult
    public func file(_ handler: @escaping (URL, URLResponse) -> Void) -> Self {
        task.responseHandler = ContentHandler { [unowned queue = responseQueue] (content, response) in
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
    
    /// Handle text response
    @discardableResult
    public func text(_ handler: @escaping (String, URLResponse) -> Void) -> Self {
        task.responseHandler = TextContentHandler { [unowned queue = responseQueue] (string, response) in
            queue.addOperation {
                handler(string, response)
            }
        }
        return self
    }
    
    /// Handle json response
    @discardableResult
    public func json(_ handler: @escaping (Any, URLResponse) -> Void) -> Self {
        task.responseHandler = JSONContentHandler { [unowned queue = responseQueue] (object, response) in
            queue.addOperation {
                handler(object, response)
            }
        }
        return self
    }
    
    /// Handle url-encoded response
    @discardableResult
    public func urlencoded(_ handler: @escaping ([String: String], URLResponse) -> Void) -> Self {
        task.responseHandler = URLEncodedContentHandler { [unowned queue = responseQueue] (dictionary, response) in
            queue.addOperation {
                handler(dictionary, response)
            }
        }
        return self
    }
    
    /// Handle json response with serialized Decodable object of type
    @discardableResult
    public func decodable<T: Decodable>(_ handler: @escaping (T, URLResponse) -> Void) -> Self {
        task.responseHandler = DecodableContentHandler { [unowned queue = responseQueue] (object: T, response) in
            queue.addOperation {
                handler(object, response)
            }
        }
        return self
    }
    
}

public extension TaskBuilder {
    
    /// Generic content handler with block
    public class ContentHandler: ServiceTaskContentHandling {
        
        public var handler: ((ServiceTask.Content, URLResponse) throws -> Void)?
        
        /// Create an instance of the handler. NOTE: throwing block will be executed on background thread.
        public init(_ block: ((ServiceTask.Content, URLResponse) throws -> Void)? = nil) {
            handler = block
        }
        
        public func handle(content: ServiceTask.Content, response: URLResponse) throws {
            try self.handler?(content, response)
        }
    }
    
    /// Generic error handler with block
    public class ErrorHandler: ServiceTaskErrorHandling {
        
        public var handler: ((Error, URLResponse?) -> Void)?
        
        /// Create an instance of the handler. NOTE: block will be executed on background thread
        public init(_ block: ((Error, URLResponse?) -> Void)? = nil) {
            handler = block
        }
        
        public func handle(error: Error, response: URLResponse?) {
            self.handler?(error, response)
        }
    }
    
}
