//
//  ServiceTaskErrorHandling.swift
//  Condulet
//
//  Created by Natan Zalkin on 30/09/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

import Foundation


/// A handler for ServiceTask content response
public protocol ServiceTaskErrorHandling {
    
    func handle(error: Error, response: URLResponse?)
    
}
