//
//  ServiceTaskContentHandling.swift
//  Condulet
//
//  Created by Natan Zalkin on 29/09/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

import Foundation


/// A handler for ServiceTask content response
public protocol ServiceTaskContentHandling {
    
    func handle(content: ServiceTask.Content, response: URLResponse) throws
    
}
