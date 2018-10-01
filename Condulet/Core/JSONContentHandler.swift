//
//  JSONContentHandler.swift
//  Condulet
//
//  Created by Natan Zalkin on 29/09/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

import Foundation


/// A handler that expects and parse response with JSON content. Completion block returns valid JSON object on success
open class JSONContentHandler: ServiceTaskContentHandling {

    public var completion: ((Any, URLResponse) -> Void)?
    
    public init(completion: ((Any, URLResponse) -> Void)? = nil) {
        self.completion = completion
    }
    
    public func handle(content: ServiceTask.Content, response: URLResponse) throws {
        
        guard response.mimeType == "application/json" else {
            throw ConduletError.invalidContent
        }
        
        switch content {
        case let .data(data):
            let object = try JSONSerialization.jsonObject(with: data, options: [.allowFragments])
            completion?(object, response)
        default:
            throw ConduletError.invalidContent
        }
    }
    
}
