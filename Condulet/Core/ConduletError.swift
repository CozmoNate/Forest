//
//  ConduletError.swift
//  Condulet
//
//  Created by Natan Zalkin on 01/10/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

import Foundation


public enum ConduletError: Error {
    
    /// You shoud provide endpoint information
    case invalidEndpoint
    /// You shoud specify default session for task
    case noSessionSpecified
    /// You shoud specify HTTP method for action
    case noMethodSpecified
    /// The task is not performed yet, so not possible to rewind
    case noActionPerformed
    /// Response does not handled
    case noResponseHandler
    /// Task is already executed
    case alreadyRunning
    /// Task received unsupported response server response
    case invalidResponse
    /// Task received unsupported response content
    case invalidContent
    /// Task response handler have decoding issues
    case decodingFailure
    /// Status code error
    case statusCode(Int)
}
