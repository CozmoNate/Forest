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

    /// Send a message inside URL query params
    @discardableResult
    func query<T: Message>(proto message: T) -> Self {
        guard let data = try? message.jsonUTF8Data() else { return self }
        guard let object = try? JSONSerialization.jsonObject(with: data, options: []) else { return self }
        guard let map = object as? [AnyHashable: Any] else { return self }

        func encode(_ map: [AnyHashable: Any], path: String? = nil) -> [URLQueryItem] {
            var items = [URLQueryItem]()
            map.forEach { key, value in
                let path = path.flatMap { "\($0).\(key)" } ?? "\(key)"
                if let map = value as? [AnyHashable: Any] {
                    items.append(contentsOf: encode(map, path: path))
                } else if let values = value as? [Any] {
                    values.enumerated().forEach {
                        items.append(URLQueryItem(name: "\(path)", value: "\($0.element)"))
                    }
                } else {
                    items.append(URLQueryItem(name: path, value: "\(value)"))
                }
            }

            return items
        }

        let items = encode(map)

        return query(items)
    }

    /// Send a message inside URL query params
    @discardableResult
    func query<T: Message>(proto configure: (inout T) -> Void) -> Self {
        var message = T()
        configure(&message)
        return query(proto: message)
    }

    /// Send a message inside URL query params
    @discardableResult
    func query<T: Message>(proto type: T.Type, configure: (inout T) -> Void) -> Self {
        var message = T()
        configure(&message)
        return query(proto: message)
    }

    /// Send body with protobuf messsage
    @discardableResult
    func body<T: Message>(proto message: T) -> Self {
        contentType(value: "application/x-www-form-urlencoded")
        task.headers["grpc-metadata-content-type"] = "application/grpc"
        task.body = ServiceTaskContent(try? message.jsonUTF8Data())
        return self
    }
    
    /// Send body with protobuf messsage. This method creates an instance of the type specified and passes it to configuration block
    @discardableResult
    func body<T: Message>(proto configure: (inout T) -> Void) -> Self {
        var message = T()
        configure(&message)
        return body(proto: message)
    }

    /// Send body with protobuf messsage. This method creates an instance of the type specified and passes it to configuration block
    @discardableResult
    func body<T: Message>(proto type: T.Type, configure: (inout T) -> Void) -> Self {
        var message = T()
        configure(&message)
        return body(proto: message)
    }

    /// Handle protobuf message response. If received response of other type task will fail with ServiceTaskError.invalidResponse
    @discardableResult
    func proto<T: Message>(decodingOptions: JSONDecodingOptions = .default, handler: @escaping (T, URLResponse) -> Void) -> Self {
        task.responseHandler = ProtobufContentHandler(decodingOptions: decodingOptions) { [queue = responseQueue] (message: T, response) in
            queue.addOperation {
                handler(message, response)
            }
        }
        return self
    }

    /// Handle protobuf message response. If received response of other type task will fail with ServiceTaskError.invalidResponse
    @discardableResult
    func proto<T: Message>(type: T.Type, decodingOptions: JSONDecodingOptions = .default, handler: @escaping (T, URLResponse) -> Void) -> Self {
        task.responseHandler = ProtobufContentHandler(decodingOptions: decodingOptions) { [queue = responseQueue] (message: T, response) in
            queue.addOperation {
                handler(message, response)
            }
        }
        return self
    }

    /// Handle protobuf message response. If received response of other type task will fail with ServiceTaskError.invalidResponse
    @discardableResult
    func response<T: Message>(proto type: T.Type, decodingOptions: JSONDecodingOptions = .default, handler: @escaping (ServiceTaskResult<T>) -> Void) -> Self {
        proto(decodingOptions: decodingOptions) { (message, response) in
            handler(.success(message))
        }
        error { (error, response) in
            handler(.failure(error))
        }
        return self
    }

    /// Handle protobuf message response. If received response of other type task will fail with ServiceTaskError.invalidResponse
    @discardableResult
    func response<T: Message>(decodingOptions: JSONDecodingOptions = .default, handler: @escaping (ServiceTaskResult<T>) -> Void) -> Self {
        proto(decodingOptions: decodingOptions) { (message, response) in
            handler(.success(message))
        }
        error { (error, response) in
            handler(.failure(error))
        }
        return self
    }
}
