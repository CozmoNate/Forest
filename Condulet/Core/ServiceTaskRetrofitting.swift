//
//  ServiceTaskInterception.swift
//  Condulet
//
//  Created by Natan Zalkin on 05/10/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

import Foundation


/// Retrofitter class allows to modify default behaviour of ServiceTask without subclassing
public protocol ServiceTaskRetrofitting {

    /// Modify request before assigning it to URLSessionTask. Throwing error will cause the task to fail with provided error
    func serviceTask(_ task: ServiceTask, modify request: inout URLRequest) throws

    /// Intercept response handler. Throw error to fail task and pass error to error handler and invoke error interception method.
    /// Return true to indicate that response is intercepted and no further handling should be peformed by ServiceTask when returned from this method.
    func serviceTask(_ task: ServiceTask, intercept content: ServiceTaskContent, response: URLResponse) throws -> Bool

    /// Intercept error handler. Throwing error will fail the task and pass error to error handler. You can use "throw" to map errors
    /// Return true to indicate that error is intercepted and no further handling should be peformed by ServiceTask when returned from this method.
    func serviceTask(_ task: ServiceTask, intercept error: Error, response: URLResponse?) throws -> Bool

}
