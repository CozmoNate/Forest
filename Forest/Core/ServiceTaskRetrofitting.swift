//
//  ServiceTaskInterception.swift
//  Forest
//
//  Created by Natan Zalkin on 05/10/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

import Foundation


/// Retrofitter class allows to modify default behaviour of ServiceTask without subclassing
public protocol ServiceTaskRetrofitting {

    /// Modify request before assigning it to URLSessionTask. Throw error to fail task and pass error to error handler and invoke error interception method.
    /// Return true to indicate that request is intercepted and no further handling should be peformed by ServiceTask when returned from this method.
    /// When the request being intercepted use sendRequest(_:) method of the task to perform modified request.
    /// When the request being intercepted use handleError(_:_:) method of the task to pass error to error handler.
    func shouldIntercept(request: inout URLRequest, for task: ServiceTask, with action: ServiceTaskAction) throws -> Bool

    /// Intercept response handler. Throw error to fail task and pass error to error handler and invoke error interception method.
    /// Return true to indicate that response is intercepted and no further handling should be peformed by ServiceTask when returned from this method.
    /// When the content being intercepted use handleContent(_:, _:) method of the task to pass content to content handler.
    /// When the content being intercepted use handleError(_:_:) method of the task to pass error to error handler.
    func shouldIntercept(content: ServiceTaskContent, response: URLResponse, for task: ServiceTask) throws -> Bool

    /// Intercept error handler. Throwing error will fail the task and pass error directly to error handler.
    /// Return true to indicate that error is intercepted and no further handling should be peformed by ServiceTask when returned from this method.
    /// When the error being intercepted use handleError(_:_:) method of the task to pass error to error handler.
    func shouldIntercept(error: Error, response: URLResponse?, for task: ServiceTask) throws -> Bool

}
