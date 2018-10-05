//
//  ServiceTask+Error.swift
//  Condulet
//
//  Created by Natan Zalkin on 05/10/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

import Foundation


extension ServiceTask {
    
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
    
}
