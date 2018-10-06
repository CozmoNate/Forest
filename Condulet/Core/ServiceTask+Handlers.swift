//
//  ServiceTask+Handlers.swift
//  Condulet
//
//  Created by Natan Zalkin on 02/10/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

import Foundation


public extension ServiceTask {

    /// Generic content handler with block
    public class ResponseHandler: ServiceTaskResponseHandling {

        public var handler: ((ServiceTask.Content, URLResponse) throws -> Void)?

        /// Create an instance of the handler. NOTE: throwing block will be executed on background thread.
        public init(_ block: ((ServiceTask.Content, URLResponse) throws -> Void)? = nil) {
            handler = block
        }

        public func handle(content: ServiceTask.Content?, response: URLResponse) throws {

            guard let content = content else {
                throw ServiceTaskError.invalidResponseContent
            }

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
