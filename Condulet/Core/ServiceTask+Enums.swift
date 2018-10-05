//
//  ServiceTask+Method.swift
//  Condulet
//
//  Created by Natan Zalkin on 30/09/2018.
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


public extension ServiceTask {
    
    /// An HTTP method. Can be extended to add custom or new methods
    public struct Method: RawRepresentable {
        
        public typealias RawValue = String
        
        public let rawValue: RawValue
        
        public init(rawValue: RawValue) {
            self.rawValue = rawValue
        }
        
        /// HTTP Request method "GET"
        public static let GET = ServiceTask.Method(rawValue: "GET")
        
        /// HTTP Request method "HEAD"
        public static let HEAD = ServiceTask.Method(rawValue: "HEAD")
        
        /// HTTP Request method "POST"
        public static let POST = ServiceTask.Method(rawValue: "POST")
        
        /// HTTP Request method "PUT"
        public static let PUT = ServiceTask.Method(rawValue: "PUT")
        
        /// HTTP Request method "DELETE"
        public static let DELETE = ServiceTask.Method(rawValue: "DELETE")
        
        /// HTTP Request method "CONNECT"
        public static let CONNECT = ServiceTask.Method(rawValue: "CONNECT")
        
        /// HTTP Request method "OPTIONS"
        public static let OPTIONS = ServiceTask.Method(rawValue: "OPTIONS")
        
        /// HTTP Request method "TRACE"
        public static let TRACE = ServiceTask.Method(rawValue: "TRACE")
        
        /// HTTP Request method "PATCH"
        public static let PATCH = ServiceTask.Method(rawValue: "PATCH")   
    }
    
    /// Action performed with ServiceTask
    /// - perform: Perform task
    /// - download: Download file and save to specified filename
    /// - upload: Upload specified content
    public enum Action: CustomStringConvertible {
        
        case perform
        case download(destination: URL, resumeData: Data?)
        case upload
        
        public var description: String {
            switch self {
            case .perform:
                return "Perform"
            case .download:
                return "Download"
            case .upload:
                return "Upload"
            }
        }
    }
    
    public enum Body {
        
        case none
        case data(Data)
        case file(URL)
        case multipart(MultipartFormData)
        
        init(_ data: Data?) {
            if let data = data {
                self = .data(data)
            }
            else {
                self = .none
            }
        }
        
        init(_ url: URL?) {
            if let url = url {
                self = .file(url)
            }
            else {
                self = .none
            }
        }
    }
    
    /// Content type of the response received
    public enum Content {
        
        case data(Data)
        case file(URL)
        //case stream(InputStream)
        
        init?(_ data: Data?) {
            guard let data = data else {
                return nil
            }
            self = .data(data)
        }
        
        init?(_ url: URL?) {
            guard let url = url else {
                return nil
            }
            self = .file(url)
        }
    }
    
}
