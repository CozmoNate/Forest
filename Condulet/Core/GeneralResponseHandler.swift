//  GeneralResponseHandler.swift
//  Condulet
//
//  Created by Natan Zalkin on 12/10/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

/*
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


/// General response handler. Pass any non-HTTP response. In case of HTTP response pass only response with "valid" status code (200...299)
open class GeneralResponseHandler: ServiceTaskResponseHandling {
    
    open func handle(content: ServiceTaskContent, response: URLResponse) throws {
        
        // Pass any non-HTTP response
        if let response = response as? HTTPURLResponse {
            
            // In case of HTTP response, pass only response with valid status code
            guard 200...299 ~= response.statusCode else {
                throw ServiceTaskError.statusCode(response.statusCode)
            }
        }
    }
}
