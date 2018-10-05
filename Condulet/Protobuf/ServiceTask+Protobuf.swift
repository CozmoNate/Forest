//
//  ServiceTask+Protobuf.swift
//  Condulet
//
//  Created by Natan Zalkin on 30/09/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

import Foundation
import SwiftProtobuf


public extension ServiceTask {
    
    /// Send body with protobuf messsage
    @discardableResult
    public func body<T: Message>(proto message: T) -> Self {
        contentType = "application/x-www-form-urlencoded"
        headers["grpc-metadata-content-type"] = "application/grpc"
        body = Body(try? message.jsonUTF8Data())
        return self
    }
    
    /// Send body with protobuf messsage. This method creates an instance of type specified and passes it to configuration block
    @discardableResult
    public func body<T: Message>(proto configure: (inout T) -> Void) -> Self {
        contentType = "application/x-www-form-urlencoded"
        headers["grpc-metadata-content-type"] = "application/grpc"
        var message = T()
        configure(&message)
        body = Body(try? message.jsonUTF8Data())
        return self
    }
    
    /// Handle protobuf message response. If received response other type task will fail with ConduletError.invalidResponse
    @discardableResult
    public func proto<T: Message>(_ handler: @escaping (T, URLResponse) -> Void) -> Self {
        responseHandler = ProtobufContentHandler { [unowned queue = responseQueue] (message: T, response) in
            queue.addOperation {
                handler(message, response)
            }
        }
        return self
    }

    /// Handle protobuf message response. If received response other type task will fail with ConduletError.invalidResponse
    @discardableResult
    public func response<T: Message>(proto handler: @escaping (T, URLResponse) -> Void) -> Self {
        return proto(handler)
    }
}
