//
//  TextContentHandler.swift
//  Condulet
//
//  Created by Natan Zalkin on 30/09/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

import Foundation


/// A handler that expects and parse response with plain text content. Completion block returns string object on success
open class TextContentHandler: ServiceTaskResponseHandling {
    
    public var completion: ((String, URLResponse) -> Void)?
    
    public init(completion: ((String, URLResponse) -> Void)? = nil) {
        self.completion = completion
    }
    
    public func handle(content: ServiceTask.Content?, response: URLResponse) throws {
        
        guard let content = content, response.mimeType == "text/plain" else {
            throw ConduletError.invalidContent
        }
        
        switch content {
        case let .data(data):
            guard let string = String(data: data, encoding: .utf8) else {
                throw ConduletError.decodingFailure
            }
            completion?(string, response)
        default:
            throw ConduletError.invalidContent
        }
    }
    
}
