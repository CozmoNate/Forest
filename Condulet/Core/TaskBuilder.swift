//
//  ServiceTaskBuilder.swift
//  Condulet
//
//  Created by Natan Zalkin on 01/10/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

import Foundation


/// Task builder is a helper class allowing to easily to create, configure and perform the task
open class TaskBuilder {
 
    /// The task to configure
    public var task: ServiceTask
 
    /// The queue will be used to handle response
    public var responseQueue: OperationQueue
    
    /// Create new task builder
    ///
    /// - Parameters:
    ///   - task: The task to configure
    ///   - responseQueue: The queue will be used to dispatch response blocks
    public init(task: ServiceTask = ServiceTask(responseHandler: ContentHandler(), errorHandler: ErrorHandler()), responseQueue: OperationQueue = OperationQueue.main) {
        self.task = task
        self.responseQueue = responseQueue
    }
    
    /// Perform data task
    @discardableResult
    public func perform() -> Self {
        task.perform(action: .perform)
        return self
    }
    
    /// Perform download task
    @discardableResult
    public func download() -> Self {
        task.perform(action: .download)
        return self
    }
    
    /// Perform upload data task
    @discardableResult
    public func upload(from data: Data) -> Self {
        task.perform(action: .upload(.data(data)))
        return self
    }
    
    /// Perform upload file task
    @discardableResult
    public func upload(from url: URL) -> Self {
        task.perform(action: .upload(.file(url)))
        return self
    }
}
