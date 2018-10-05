//
//  ConduletError.swift
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


public enum ConduletError: Error {
    
    /// You shoud provide endpoint information
    case invalidEndpoint
    /// You shoud specify default session for task
    case noSessionSpecified
    /// You shoud specify HTTP method for action
    case noMethodSpecified
    /// The task is not performed yet, so not possible to rewind
    case noActionPerformed
    /// No data provided for request
    case noRequestBody
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
    /// Download destination is invalid
    case invalidDestination
    /// Status code error
    case statusCode(Int)
}
