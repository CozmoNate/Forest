//
//  ServiceTaskError.swift
//  Condulet
//
//  Created by Natan Zalkin on 01/10/2018.
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


public enum ServiceTaskError: Error {
    
    /// You shoud provide endpoint information
    case invalidEndpoint
    
    /// You must specify default session for task
    case noSessionSpecified
    
    /// You must specify HTTP method for action
    case noMethodSpecified
    
    /// You must specify task perform action
    case noActionSpecified
    
    /// Data required
    case noDataProvided
    
    /// No data provided for request
    case noRequestBody
    
    /// No implementation is provided
    case notImplemented
    
    /// Task is already executed
    case alreadyRunning
    
    /// Received unsupported response
    case invalidResponse
    
    /// Received unsupported content
    case invalidContent
    
    /// Response handler failed to decode content received
    case decodingFailure
    
    /// Failed to encode request body
    case encodingFailure
    
    /// Download destination is invalid
    case invalidDestination
    
}
