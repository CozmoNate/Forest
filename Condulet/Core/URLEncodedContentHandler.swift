//
//  URLEncodedContentHandler.swift
//  Condulet
//
//  Created by Natan Zalkin on 29/09/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

import Foundation


/// A handler that expects and parse response with URL-encoded content. Completion block returns dictionary object on success
open class URLEncodedContentHandler: ServiceTaskContentHandling {
    
    public var completion: (([String: String], URLResponse) -> Void)?
    
    public init(completion: (([String: String], URLResponse) -> Void)? = nil) {
        self.completion = completion
    }
    
    public func handle(content: ServiceTask.Content, response: URLResponse) throws {
        
        guard response.mimeType == "application/x-www-form-urlencoded" else {
            throw ConduletError.invalidContent
        }
        
        switch content {
        case let .data(data):
            let object = try URLSerialization.dictionary(with: data)
            completion?(object, response)
        default:
            throw ConduletError.invalidContent
        }
    }
    
}
