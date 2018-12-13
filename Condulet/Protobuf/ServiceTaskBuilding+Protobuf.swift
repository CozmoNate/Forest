//
//  ServiceTaskBuilding+Protobuf.swift
//  Condulet
//
//  Created by Natan Zalkin on 30/09/2018.
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
import SwiftProtobuf


public extension ServiceTaskBuilding {
    
    /// Send body with protobuf messsage
    @discardableResult
    public func body<T: Message>(proto message: T) -> Self {
        contentType(value: "application/x-www-form-urlencoded")
        task.headers["grpc-metadata-content-type"] = "application/grpc"
        task.body = ServiceTaskContent(try? message.jsonUTF8Data())
        return self
    }
    
    /// Send body with protobuf messsage. This method creates an instance of the type specified and passes it to configuration block
    @discardableResult
    public func body<T: Message>(proto configure: (inout T) -> Void) -> Self {
        contentType(value: "application/x-www-form-urlencoded")
        task.headers["grpc-metadata-content-type"] = "application/grpc"
        var message = T()
        configure(&message)
        task.body = ServiceTaskContent(try? message.jsonUTF8Data())
        return self
    }

    /// Send body with protobuf messsage. This method creates an instance of the type specified and passes it to configuration block
    @discardableResult
    public func body<T: Message>(proto type: T.Type, configure: (inout T) -> Void) -> Self {
        contentType(value: "application/x-www-form-urlencoded")
        task.headers["grpc-metadata-content-type"] = "application/grpc"
        var message = T()
        configure(&message)
        task.body = ServiceTaskContent(try? message.jsonUTF8Data())
        return self
    }

    /// Handle protobuf message response. If received response of other type task will fail with ServiceTaskError.invalidResponse
    @discardableResult
    public func proto<T: Message>(ignoreUnknownFields: Bool = true, _ handler: @escaping (T, URLResponse) -> Void) -> Self {
        task.responseHandler = ProtobufContentHandler(ignoreUnknownFields: ignoreUnknownFields) { [queue = responseQueue] (message: T, response) in
            queue.addOperation {
                handler(message, response)
            }
        }
        return self
    }

    /// Handle protobuf message response. If received response of other type task will fail with ServiceTaskError.invalidResponse
    @discardableResult
    public func proto<T: Message>(ignoreUnknownFields: Bool = true, _ type: T.Type, handler: @escaping (T, URLResponse) -> Void) -> Self {
        task.responseHandler = ProtobufContentHandler { [queue = responseQueue] (message: T, response) in
            queue.addOperation {
                handler(message, response)
            }
        }
        return self
    }

    /// Handle protobuf message response. If received response of other type task will fail with ServiceTaskError.invalidResponse
    @discardableResult
    public func response<T: Message>(proto type: T.Type, ignoreUnknownFields: Bool = true, handler: @escaping (ServiceTaskResponse<T>) -> Void) -> Self {
        proto(ignoreUnknownFields: ignoreUnknownFields) { (message, response) in
            handler(ServiceTaskResponse.success(message))
        }
        error { (error, response) in
            handler(ServiceTaskResponse.failure(error))
        }
        return self
    }

    /// Handle protobuf message response. If received response of other type task will fail with ServiceTaskError.invalidResponse
    @discardableResult
    public func response<T: Message>(ignoreUnknownProtoFields: Bool = true, handler: @escaping (ServiceTaskResponse<T>) -> Void) -> Self {
        proto(ignoreUnknownFields: ignoreUnknownProtoFields) { (message, response) in
            handler(ServiceTaskResponse.success(message))
        }
        error { (error, response) in
            handler(ServiceTaskResponse.failure(error))
        }
        return self
    }
}
