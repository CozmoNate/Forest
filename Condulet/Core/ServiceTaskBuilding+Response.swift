//
//  ServiceTaskBuilding+Response.swift
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


// MARK: - Error handlers

public extension ServiceTaskBuilding {

    /// Set error handler
    @discardableResult
    public func error(_ handler: ServiceTaskErrorHandling) -> Self {
        task.errorHandler = handler
        return self
    }
    
    /// Handle error with block
    @discardableResult
    public func error(_ handler: @escaping (Error, URLResponse?) -> Void) -> Self {
        task.errorHandler = BlockErrorHandler { [queue = responseQueue] (error, response) in
            queue.addOperation {
                handler(error, response)
            }
        }
        return self
    }

}

// MARK: - Response handlers expecting specific type of response data

public extension ServiceTaskBuilding {
    
    /// Set response handler
    @discardableResult
    public func response(_ handler: ServiceTaskResponseHandling) -> Self {
        task.responseHandler = handler
        return self
    }

    /// Handle HTTP status response
    @discardableResult
    public func success(_ handler: @escaping (Int) -> Void) -> Self {
        task.responseHandler = BlockResponseHandler { [queue = responseQueue] (content, response) in
            
            guard let response = response as? HTTPURLResponse else {
                throw ServiceTaskError.invalidResponse
            }
            
            queue.addOperation {
                handler(response.statusCode)
            }
        }
        return self
    }
    
    /// Handle response with block
    @discardableResult
    public func content(_ handler: @escaping (ServiceTaskContent, URLResponse) -> Void) -> Self {
        task.responseHandler = BlockResponseHandler { [queue = responseQueue] (content, response) in
            queue.addOperation {
                handler(content, response)
            }
        }
        return self
    }
    
    /// Handle file response for tasks performed via Download action. Returned file should be removed manually after use. When received response of other type task will fail with ServiceTaskError.invalidResponse
    @discardableResult
    public func file(_ handler: @escaping (URL, URLResponse) -> Void) -> Self {
        task.responseHandler = BlockResponseHandler { [queue = responseQueue] (content, response) in
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
    
    /// Handle data response. When task is performed via Download action, received file content will be handled as data response
    @discardableResult
    public func data(_ handler: @escaping (Data, URLResponse) -> Void) -> Self {
        task.responseHandler = BlockResponseHandler { [queue = responseQueue] (content, response) in
            switch content {
            case .data(let data):
                queue.addOperation {
                    handler(data, response)
                }
            case .file(let url):
                let data = try Data(contentsOf: url, options: Data.ReadingOptions.mappedIfSafe)
                try? FileManager.default.removeItem(at: url)
                queue.addOperation {
                    handler(data, response)
                }
            }
        }
        return self
    }


    /// Handle text response. When received response of other type task will fail with ServiceTaskError.invalidResponse
    @discardableResult
    public func text(_ handler: @escaping (String, URLResponse) -> Void) -> Self {
        task.responseHandler = TextContentHandler { [queue = responseQueue] (string, response) in
            queue.addOperation {
                handler(string, response)
            }
        }
        return self
    }

    /// Handle json response. When received response of other type task will fail with ServiceTaskError.invalidResponse
    @discardableResult
    public func json(_ handler: @escaping (Any, URLResponse) -> Void) -> Self {
        task.responseHandler = JSONContentHandler { [queue = responseQueue] (object, response) in
            queue.addOperation {
                handler(object, response)
            }
        }
        return self
    }
    
    /// Handle json dictionary response. When received response of other type task will fail with ServiceTaskError.invalidResponse
    @discardableResult
    public func array(_ handler: @escaping ([Any], URLResponse) -> Void) -> Self {
        task.responseHandler = JSONContentHandler { [queue = responseQueue] (object, response) in
            guard let array = object as? [Any] else {
                throw ServiceTaskError.invalidResponseData
            }
            queue.addOperation {
                handler(array, response)
            }
        }
        return self
    }
    
    /// Handle json dictionary response. When received response of other type task will fail with ServiceTaskError.invalidResponse
    @discardableResult
    public func dictionary(_ handler: @escaping ([AnyHashable: Any], URLResponse) -> Void) -> Self {
        task.responseHandler = JSONContentHandler { [queue = responseQueue] (object, response) in
            guard let dictionary = object as? [AnyHashable: Any] else {
                throw ServiceTaskError.invalidResponseData
            }
            queue.addOperation {
                handler(dictionary, response)
            }
        }
        return self
    }
    
    /// Handle url-encoded response. When received response of other type task will fail with ServiceTaskError.invalidResponse
    @discardableResult
    public func urlencoded(_ handler: @escaping ([String: String], URLResponse) -> Void) -> Self {
        task.responseHandler = URLEncodedContentHandler { [queue = responseQueue] (dictionary, response) in
            queue.addOperation {
                handler(dictionary, response)
            }
        }
        return self
    }
    
    /// Handle json response with serialized Decodable object of infered type. When received response of other type task will fail with ServiceTaskError.invalidResponse
    @discardableResult
    public func codable<T: Decodable>(_ handler: @escaping (T, URLResponse) -> Void) -> Self {
        task.responseHandler = DecodableContentHandler { [queue = responseQueue] (object: T, response) in
            queue.addOperation {
                handler(object, response)
            }
        }
        return self
    }

    /// Handle json response with serialized Decodable object of infered type. When received response of other type task will fail with ServiceTaskError.invalidResponse
    @discardableResult
    public func codable<T: Decodable>(_ type: T.Type, handler: @escaping (T, URLResponse) -> Void) -> Self {
        task.responseHandler = DecodableContentHandler { [queue = responseQueue] (object: T, response) in
            queue.addOperation {
                handler(object, response)
            }
        }
        return self
    }

}

// MARK: - Encapsulated response handlers

public enum ServiceTaskResponse<T> {
    
    case success(T)
    case failure(Error)
}

public extension ServiceTaskBuilding {

    /// Handle HTTP status response with block
    @discardableResult
    public func response(success handler: @escaping (ServiceTaskResponse<Int>) -> Void) -> Self {
        success { (status) in
            handler(ServiceTaskResponse.success(status))
        }
        error { (error, response) in
            handler(ServiceTaskResponse.failure(error))
        }
        return self
    }
    
    /// Handle response with block
    @discardableResult
    public func response(content handler: @escaping (ServiceTaskResponse<ServiceTaskContent>) -> Void) -> Self {
        content { (content, response) in
            handler(ServiceTaskResponse.success(content))
        }
        error { (error, response) in
            handler(ServiceTaskResponse.failure(error))
        }
        return self
    }
    
    /// Handle file response for tasks performed via Download action. Returned file should be removed manually after use. When received response of other type task will fail with ServiceTaskError.invalidResponse
    @discardableResult
    public func response(file handler: @escaping (ServiceTaskResponse<URL>) -> Void) -> Self {
        file { (url, response) in
            handler(ServiceTaskResponse.success(url))
        }
        error { (error, response) in
            handler(ServiceTaskResponse.failure(error))
        }
        return self
    }


    /// Handle data response. When task is performed via Download action, received file content will be handled as data response
    @discardableResult
    public func response(data handler: @escaping (ServiceTaskResponse<Data>) -> Void) -> Self {
        data { (data, response) in
            handler(ServiceTaskResponse.success(data))
        }
        error { (error, response) in
            handler(ServiceTaskResponse.failure(error))
        }
        return self
    }
    
    /// Handle text response. When received response of other type task will fail with ServiceTaskError.invalidResponse
    @discardableResult
    public func response(text handler: @escaping (ServiceTaskResponse<String>) -> Void) -> Self {
        text { (string, response) in
            handler(ServiceTaskResponse.success(string))
        }
        error { (error, response) in
            handler(ServiceTaskResponse.failure(error))
        }
        return self
    }

    /// Handle json response. When received response of other type task will fail with ServiceTaskError.invalidResponse
    @discardableResult
    public func response(json handler: @escaping (ServiceTaskResponse<Any>) -> Void) -> Self {
        json { (object, response) in
            handler(ServiceTaskResponse.success(object))
        }
        error { (error, response) in
            handler(ServiceTaskResponse.failure(error))
        }
        return self
    }

    /// Handle array json response. When received response of other type task will fail with ServiceTaskError.invalidResponse
    @discardableResult
    public func response(array handler: @escaping (ServiceTaskResponse<[Any]>) -> Void) -> Self {
        array { (object, response) in
            handler(ServiceTaskResponse.success(object))
        }
        error { (error, response) in
            handler(ServiceTaskResponse.failure(error))
        }
        return self
    }
    
    /// Handle dictionary json response. When received response of other type task will fail with ServiceTaskError.invalidResponse
    @discardableResult
    public func response(dictionary handler: @escaping (ServiceTaskResponse<[AnyHashable: Any]>) -> Void) -> Self {
        dictionary { (object, response) in
            handler(ServiceTaskResponse.success(object))
        }
        error { (error, response) in
            handler(ServiceTaskResponse.failure(error))
        }
        return self
    }
    
    /// Handle url-encoded response. When received response of other type task will fail with ServiceTaskError.invalidResponse
    @discardableResult
    public func response(urlencoded handler: @escaping (ServiceTaskResponse<[String: String]>) -> Void) -> Self {
        urlencoded { (dictionary, response) in
            handler(ServiceTaskResponse.success(dictionary))
        }
        error { (error, response) in
            handler(ServiceTaskResponse.failure(error))
        }
        return self
    }

    /// Handle json response with serialized Decodable object of infered type. When received response of other type task will fail with ServiceTaskError.invalidResponse
    @discardableResult
    public func response<T: Decodable>(codable type: T.Type, handler: @escaping (ServiceTaskResponse<T>) -> Void) -> Self {
        codable { (object, response) in
            handler(ServiceTaskResponse.success(object))
        }
        error { (error, response) in
            handler(ServiceTaskResponse.failure(error))
        }
        return self
    }

    /// Handle json response with serialized Decodable object of infered type. When received response of other type task will fail with ServiceTaskError.invalidResponse
    @discardableResult
    public func response<T: Decodable>(codable handler: @escaping (ServiceTaskResponse<T>) -> Void) -> Self {
        codable { (object, response) in
            handler(ServiceTaskResponse.success(object))
        }
        error { (error, response) in
            handler(ServiceTaskResponse.failure(error))
        }
        return self
    }

}
