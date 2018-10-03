//
//  ProtobufContentHandler.swift
//  Condulet
//
//  Created by Natan Zalkin on 29/09/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

import Foundation
import SwiftProtobuf


/// A handler that expects and parse response with protobuf message. Completion block returns deserialized message of expected type on success
open class ProtobufContentHandler<T: Message>: ServiceTaskResponseHandling {
    
    public var completion: ((T, URLResponse) -> Void)?
    
    public init(completion: ((T, URLResponse) -> Void)? = nil) {
        self.completion = completion
    }
    
    public func handle(content: ServiceTask.Content?, response: URLResponse) throws {
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ConduletError.invalidResponse
        }
        
        guard let content = content, httpResponse.mimeType == "application/json" else {
            throw ConduletError.invalidContent
        }
        
        guard let metadataContentType = httpResponse.allHeaderFields["grpc-metadata-content-type"] as? String else {
            throw ConduletError.invalidContent
        }
        
        guard metadataContentType == "application/grpc" else {
            throw ConduletError.invalidContent
        }
        
        switch content {
        case let .data(data):
            let message = try T(jsonUTF8Data: data)
            completion?(message, response)
        default:
            throw ConduletError.invalidContent
        }
    }
}
