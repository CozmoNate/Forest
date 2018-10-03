//
//  RetrofitTask.swift
//  ConduletTests
//
//  Created by Natan Zalkin on 01/10/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

import Foundation


/// Implement retrofitter that can override requests and intercept task responses
public protocol TaskRetrofitting {

    /// Change request after it is configured by the task and before it will send
    func configure(request: inout URLRequest) throws

    /// Return true if you want to handle response.
    /// Interepting response cause all running tasks to cancel and rewind reconfiguring their requests after response is handled by retrofitter
    func shouldIntercept(response: URLResponse) -> Bool

    /// Handle intercepted response. You must call completion block upon finish.
    /// Return error if you want to fail runing tasks, otherwise tasks will rewind.
    func handle(response: URLResponse, completion: @escaping (Error?) -> Void)

}


/// Use RetrofitTask to make authenticated requests using OAuth or similar protocols
open class RetrofitTask: ServiceTask {

    /// All tasks that is performed already but not received response yet
    public static var runningTasks: Set<RetrofitTask> = Set()
    
    /// Serial queue to sync between perform->response operations
    public static var syncQueue: DispatchQueue = DispatchQueue(label: "RetrofitTask.SerialQueue")

    /// Retrofitter of the task
    public var retrofitter: TaskRetrofitting?

    public init(
        retrofitter: TaskRetrofitting? = nil,
        session: URLSession = URLSession.shared,
        endpoint: URLComponents = URLComponents(),
        method: ServiceTask.Method? = nil,
        headers: [String: String] = [:],
        body: Data? = nil,
        contentHandler: ServiceTaskResponseHandling? = nil,
        errorHandler: ServiceTaskErrorHandling? = nil,
        responseQueue: OperationQueue = OperationQueue.main) {

        self.retrofitter = retrofitter

        super.init(session: session, endpoint: endpoint, method: method, headers: headers, body: body, contentHandler: contentHandler, errorHandler: errorHandler, responseQueue: responseQueue)
    }
    
    open override func makeRequest() throws -> URLRequest {

        var request = try super.makeRequest()

        try retrofitter?.configure(request: &request)

        return request
    }
    
    open override func perform(task: URLSessionTask, action: ServiceTask.Action, signature: UUID) {
        RetrofitTask.syncQueue.async {

            // Add to running tasks list
            RetrofitTask.runningTasks.insert(self)

            super.perform(task: task, action: action, signature: signature)
        }
    }

    open override func handleResponse(_ signature: UUID, _ content: ServiceTask.Content?, _ response: URLResponse?, _ error: Error?) {
        RetrofitTask.syncQueue.async {

            // Should intercept response?
            if let response = response, let retrofitter = self.retrofitter, retrofitter.shouldIntercept(response: response) {

                // Pause task activities
                RetrofitTask.syncQueue.suspend()

                // Cancel all running tasks
                RetrofitTask.runningTasks.forEach { $0.cancel() }

                retrofitter.handle(response: response) { (error) in

                    if let error = error {
                        RetrofitTask.runningTasks.forEach { $0.handleResponse(error, response) }
                    }
                    else {
                        // Reshcedule all cancelled tasks
                        RetrofitTask.runningTasks.forEach { $0.rewind() }
                    }

                    // Resume task activities
                    RetrofitTask.syncQueue.resume()
                }

                return
            }

            // Remove from running tasks list
            RetrofitTask.runningTasks.remove(self)

            // Handle response
            super.handleResponse(signature, content, response, error)
        }
    }

}
