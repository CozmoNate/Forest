//
//  ServiceTask+Protobuf.swift
//  Condulet
//
//  Created by Natan Zalkin on 30/09/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

import Foundation
import SwiftProtobuf


public extension TaskBuilder {
    
    /// Send body with protobuf messsage
    @discardableResult
    public func body<T: Message>(proto message: T) -> Self {
        task.contentType = "application/x-www-form-urlencoded"
        task.headers["grpc-metadata-content-type"] = "application/grpc"
        task.body = try? message.jsonUTF8Data()
        return self
    }
    
    /// Handle protobuf message response
    @discardableResult
    public func proto<T: Message>(_ handler: @escaping (T, URLResponse) -> Void) -> Self {
        task.responseHandler = ProtobufContentHandler { [unowned queue = responseQueue] (message: T, response) in
            queue.addOperation {
                handler(message, response)
            }
        }
        return self
    }
}
