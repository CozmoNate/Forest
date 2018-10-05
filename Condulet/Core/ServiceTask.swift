//
//  ServiceTask.swift
//  Joto
//
//  Created by Natan Zalkin on 28/09/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

/*
 *
 * Copyright (c) 2018 Natan Zalkin
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 */

import Foundation


public extension Notification.Name {

    public enum Condulet {

        /// Posted when a ServiceTask is performed. The notification `object` contains an instance of ServiceTask.
        public static let TaskPerformed = Notification.Name(rawValue: "Condulet.TaskPerformed")

        /// Posted when a ServiceTask is received response. The notification `object` contains an instance of ServiceTask.
        public static let TaskCompleted = Notification.Name(rawValue: "Condulet.TaskCompleted")
    }

}

/// URLSessionTask wrapping class allowing to build, send, cancel and rewind network requests. Built for subclassing
open class ServiceTask: CustomStringConvertible, CustomDebugStringConvertible, Hashable {
    
    // MARK: - CustomStringConvertible
    
    open var description: String {
        
        let description = "<\(String(describing: type(of: self))) #\(hashValue)>"
        
        var parameters = ""
        
        if let method = method {
            parameters += "\(method.rawValue)"
        }
        
        if let url = url.string, !url.isEmpty {
            parameters += " (\(url))"
        }
        
        guard !parameters.isEmpty else {
            return description
        }
        
        return "\(description) [\(action?.description ?? "Unexecuted")] \(parameters)"
    }

    // MARK: - CustomDebugStringConvertible

    public var debugDescription: String {
        return description
    }
    
    // MARK: - Hashable
    
    public var hashValue: Int = UUID().hashValue // Every task is unique
    
    // MARK: - Equatable
    
    public static func == (lhs: ServiceTask, rhs: ServiceTask) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }

    // MARK: - Interceptor

    public var interceptor: ServiceTaskInterception?
    
    // MARK: - Configuration properties

    /// A URLSession instance used to create URLSessionTask
    public var session: URLSession?
    /// A URLComponents instance describing service endpoint
    public var url: URLComponents
    /// A HTTP method used for request
    public var method: Method?
    /// HTTP headers added to request
    public var headers: [String: String]
    /// HTTP body data
    public var body: Body
    /// Service response handler
    public var responseHandler: ServiceTaskResponseHandling?
    /// Failure handler
    public var errorHandler: ServiceTaskErrorHandling?
    // The queue will be used to dispatch response
    public var responseQueue: OperationQueue
    
    // MARK: - Properties

    /// Last action performed
    public var action: Action?
    /// Signature is used to determine if response from URLSessionTask still relevant and should be handled
    public var signature: UUID?
    /// The underlying URLSessionTask that has been performed
    public var underlayingTask: URLSessionTask?
    /// The content received with the last response
    public var content: Content?

    /// Easy access to 'Content-Type' HTTP headers entry
    public var contentType: String? {
        get { return headers["Content-Type"] }
        set { headers["Content-Type"] = newValue }
    }

    open var isRunning: Bool {
        return signature != nil
    }

    // MARK: - Lifecycle
    
    /// Creates the instance of ServiceTask
    public init(
        session: URLSession = URLSession.shared,
        endpoint: URLComponents = URLComponents(),
        method: ServiceTask.Method? = nil,
        headers: [String: String] = [:],
        body: Body = .none,
        contentHandler: ServiceTaskResponseHandling? = nil,
        errorHandler: ServiceTaskErrorHandling? = nil,
        responseQueue: OperationQueue = OperationQueue.main,
        interceptor: ServiceTaskInterception? = nil) {
        
        self.session = session
        self.url = endpoint
        self.method = method
        self.headers = headers
        self.body = body
        self.responseHandler = contentHandler
        self.errorHandler = errorHandler
        self.responseQueue = responseQueue
        self.interceptor = interceptor
    }
    
    // MARK: - Builder
    
    /// Produces a request built from ServiceTask parameters. When have invalid parameters an error will be thrown.
    open func makeRequest() throws -> URLRequest {
        
        guard let url = url.url else {
            throw ConduletError.invalidEndpoint
        }
        
        guard let method = method else {
            throw ConduletError.noMethodSpecified
        }

        var request = URLRequest(url: url)
        
        request.allHTTPHeaderFields = headers
        request.httpMethod = method.rawValue
        
        return request
    }

    /// Fills request HTTP body with the data
    open func prepareBody(for request: inout URLRequest) throws {
        
        switch body {
        case .none:
            request.httpBody = nil
        case .data(let data):
            request.httpBody = data
        case .file(let url):
            request.httpBody = try Data(contentsOf: url)
        case .multipart(let data):
            request.httpBody = try data.generateBodyData()
        }
    }

    /// Produces data task
    open func prepareDataTask(for request: inout URLRequest, with signature: UUID) throws -> URLSessionDataTask {

        guard let session = session else {
            throw ConduletError.noSessionSpecified
        }

        return session.dataTask(with: request) { (data, response, error) in
            self.dispatchResponse(signature, Content(data), response, error)
        }
    }

    /// Produces download task
    open func prepareDownloadTask(for request: inout URLRequest, with signature: UUID, destination: URL, resume data: Data?) throws -> URLSessionDownloadTask {

        guard let session = session else {
            throw ConduletError.noSessionSpecified
        }

        let completion = { (url: URL?, response: URLResponse?, error: Error?) -> Void in
            if let url = url {
                do {
                    try FileManager.default.moveItem(at: url, to: destination)
                    self.dispatchResponse(signature, Content(destination), response, error)
                }
                catch {
                    self.dispatchResponse(signature, nil, response, ConduletError.invalidDestination)
                }
            }
            else {
                self.dispatchResponse(signature, nil, response, error)
            }
        }
        if let data = data {
            return session.downloadTask(withResumeData: data, completionHandler: completion)
        }
        else {
            return session.downloadTask(with: request, completionHandler: completion)
        }
    }

    /// Produces upload task
    open func prepareUploadTask(for request: inout URLRequest, with signature: UUID) throws -> URLSessionUploadTask {

        guard let session = session else {
            throw ConduletError.noSessionSpecified
        }

        switch body {
        case .none:
            throw ConduletError.noRequestBody
        case .data(let data):
            return session.uploadTask(with: request, from: data) { (data, response, error) in
                self.dispatchResponse(signature, Content(data), response, error)
            }
        case .file(let url):
            return session.uploadTask(with: request, fromFile: url) { (data, response, error) in
                self.dispatchResponse(signature, Content(data), response, error)
            }
        case .multipart(let data):
            return session.uploadTask(with: request, from: try data.generateBodyData()) { (data, response, error) in
                self.dispatchResponse(signature, Content(data), response, error)
            }
        }
    }
    
    // MARK: - Actions
    
    /// Perform task with action.
    open func perform(action: Action) {
        
        do {
            
            guard !isRunning else {
                throw ConduletError.alreadyRunning
            }

            self.action = action

            var request = try makeRequest()
            let signature = UUID()
            
            let task: URLSessionTask

            switch action {
            // Perform
            case .perform:
                try prepareBody(for: &request)
                try interceptor?.serviceTask(self, modify: &request)
                task = try prepareDataTask(for: &request, with: signature)
            // Download
            case .download(let path, let data):
                try prepareBody(for: &request)
                try interceptor?.serviceTask(self, modify: &request)
                task = try prepareDownloadTask(for: &request, with: signature, destination: path, resume: data)
            // Upload
            case .upload:
                try interceptor?.serviceTask(self, modify: &request)
                // Upload tasks ignore request body, so handle body type manually
                task = try prepareUploadTask(for: &request, with: signature)
            }
            
            perform(task: task, with: signature)
            
        } catch {
            handleError(error)
        }
    }
    
    /// Cancels running task. Captured response blocks and handlers will never be called until task will be performed again or rewound.
    /// Optionally resume data can be produced on cancel in case of download task, otherwise completion will be called with nil data
    @discardableResult
    open func cancel(byProducingResumeData resumeDataHandler: ((Data?) -> Void)? = nil) -> Bool {

        guard isRunning else {
            return false
        }

        // Invalidate URLSessionTask completion handler
        signature = nil

        // Cancel with resume data
        if let resumeDataHandler = resumeDataHandler {
            if let downloadTask = underlayingTask as? URLSessionDownloadTask {
                downloadTask.cancel(byProducingResumeData: resumeDataHandler)
                return true
            }
            else {
                resumeDataHandler(nil)
            }
        }

        underlayingTask?.cancel()

        return true
    }
    
    /// Rewind task with lastest action performed. If action is not specified task will fail with 'noActionPerformed' error.
    open func rewind() {
        
        if let action = action {
            perform(action: action)
        }
        else {
            handleError(ConduletError.noActionPerformed)
        }
    }
    
    // MARK: - URLSessionTask backing
    
    /// Sign and perform URLSessionTask
    open func perform(task: URLSessionTask, with signature: UUID) {
        
        self.underlayingTask = task
        self.signature = signature
        
        task.resume()
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name.Condulet.TaskPerformed, object: self)
        }
    }
    
    /// Dispatch response received from URLSessionTask, decide how response will be handled
    open func dispatchResponse(_ signature: UUID, _ content: Content?, _ response: URLResponse?, _ error: Error?) {
        
        // When the response signature is differs from stored signature, that means we got response from abandoned requests and should ignore it
        guard self.signature == signature else {
            return // Response is no longer relevant
        }
        
        self.signature = nil
        self.content = content
        
        do {

            if let error = error {
                guard !(interceptor?.serviceTask(self, intercept: error) ?? false) else {
                    return
                }
                throw error
            }

            guard !(try interceptor?.serviceTask(self, intercept: response) ?? false) else {
                return
            }

            try handleResponse(response)

            guard !(try interceptor?.serviceTask(self, intercept: content) ?? false) else {
                return
            }

            try handleContent(content, response)
            
        } catch {
            
            handleError(error, underlayingTask?.response)
        }
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name.Condulet.TaskCompleted, object: self)
        }
    }
    
    // MARK: - Response handling
    
    open func handleResponse(_ response: URLResponse?) throws {

        // Pass any non-HTTP response or no reponse
        if let response = response as? HTTPURLResponse {
            
            // In case of HTTP response, pass only response with valid status code
            guard 200..<300 ~= response.statusCode else {
                throw ConduletError.statusCode(response.statusCode)
            }
        }
    }

    /// Handle content response.
    open func handleContent(_ content: Content?, _ response: URLResponse?) throws {

        guard let response = response else {
            throw ConduletError.invalidResponse
        }
        
        guard let handler = responseHandler else {
            throw ConduletError.noResponseHandler
        }
        
        // Run response handler
        try handler.handle(content: content, response: response)
    }
    
    /// Handle any error. Response parameter can store service response if received.
    open func handleError(_ error: Error, _ response: URLResponse? = nil) {
        
        // Run error handler
        errorHandler?.handle(error: error, response: response)
    }
    
}
