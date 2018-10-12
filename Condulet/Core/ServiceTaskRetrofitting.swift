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

    /// Intercept response handler.
    /// Return true to indicate that response is intercepted and no further handling should be peformed by ServiceTask when returned from this method.
    /// Throwing error will cause the task to fail with provided error
    func serviceTask(_ task: ServiceTask, intercept content: ServiceTaskContent, response: URLResponse) throws -> Bool

    /// Intercept error handler.
    /// Return true to indicate that error is intercepted and no further handling should be peformed by ServiceTask when returned from this method.
    func serviceTask(_ task: ServiceTask, intercept error: Error, response: URLResponse?) -> Bool

}
