//
//  DecodableContentHandler.swift
//  Condulet
//
//  Created by Natan Zalkin on 30/09/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

import Foundation


/// A handler that expects and parse response with object conforming Decodable protocol. Completion block returns instance of the object on success
open class DecodableContentHandler<T: Decodable>: ServiceTaskContentHandling {
    
    public var decoder = JSONDecoder()
    public var completion: ((T, URLResponse) -> Void)?
    
    public init(completion: ((T, URLResponse) -> Void)? = nil) {
        self.completion = completion
    }
    
    public func handle(content: ServiceTask.Content, response: URLResponse) throws {
        
        guard response.mimeType == "application/json" else {
            throw ConduletError.invalidContent
        }
        
        switch content {
        case let .data(data):
            let object = try decoder.decode(T.self, from: data)
            completion?(object, response)
        default:
            throw ConduletError.invalidContent
        }
    }
    
}
