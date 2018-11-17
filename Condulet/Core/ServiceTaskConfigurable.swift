//
//  ServiceTaskConfigurable.swift
//  Condulet
//
//  Created by Natan Zalkin on 24/10/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

/*
 * Copyright (c) 2018 Zalkin, Natan
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


public protocol ServiceTaskConfigurable: AnyObject {

    /// A URLSession instance used to create URLSessionTask
    var session: URLSession? { get set }
    
    /// A URLComponents instance describing service endpoint
    var url: URLComponents { get set }
    
    /// A HTTP method used for request
    var method: HTTPMethod? { get set }
    
    /// HTTP headers added to request
    var headers: [String: String] { get set }
    
    /// HTTP body data
    var body: ServiceTaskContent? { get set }
    
    /// Service response handler
    var responseHandler: ServiceTaskResponseHandling? { get set }
    
    /// Failure handler
    var errorHandler: ServiceTaskErrorHandling? { get set }
    
}
