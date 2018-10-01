//
//  ServiceTask+Method.swift
//  Condulet
//
//  Created by Natan Zalkin on 30/09/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

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
        case download(URL)
        case upload(Content)
        
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
