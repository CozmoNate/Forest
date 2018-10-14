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

        /// Posted when a ServiceTask is performed. The notification `object` contains an instance of a ServiceTask.
        public static let TaskPerformed = Notification.Name(rawValue: "Condulet.TaskPerformed")

        /// Posted when a ServiceTask is received response. The notification `object` contains an instance of a ServiceTask.
        public static let TaskCompleted = Notification.Name(rawValue: "Condulet.TaskCompleted")
    }

}

/// URLSessionTask wrapping class allowing to build, send, cancel and rewind network requests.
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
    
    public let hashValue: Int = UUID().hashValue // Every task is unique
    
    // MARK: - Equatable
    
    public static func == (lhs: ServiceTask, rhs: ServiceTask) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }

    // MARK: - ServiceTaskConfigurable

    /// A URLSession instance used to create URLSessionTask
    public var session: URLSession?
    /// A URLComponents instance describing service endpoint
    public var url: URLComponents
    /// A HTTP method used for request
    public var method: HTTPMethod?
    /// HTTP headers added to request
    public var headers: [String: String]
    /// HTTP body data
    public var body: ServiceTaskContent?
    /// Service response handler
    public var responseHandler: ServiceTaskResponseHandling?
    /// Failure handler
    public var errorHandler: ServiceTaskErrorHandling?
    
    // MARK: - ServiceTaskRetrofitting
    
    public var retrofitter: ServiceTaskRetrofitting?

    // MARK: - Lifecycle
    
    /// Last action performed
    public private(set) var action: ServiceTaskAction?
    /// The underlying URLSessionTask that has been performed
    public private(set) var underlayingTask: URLSessionTask?
    /// The content received with the last response
    public private(set) var content: ServiceTaskContent?
    
    /// True when the task is performed but the response still not received
    public var isRunning: Bool {
        return signature != nil
    }
    
    /// Signature is used to determine if response received from URLSessionTask still relevant and should be handled
    private var signature: UUID?
    
    /// Creates the instance of ServiceTask
    public init(
        session: URLSession = URLSession.shared,
        url: URLComponents = URLComponents(),
        method: HTTPMethod? = nil,
        headers: [String: String] = [:],
        body: ServiceTaskContent? = nil,
        responseHandler: ServiceTaskResponseHandling? = nil,
        errorHandler: ServiceTaskErrorHandling? = nil,
        retrofitter: ServiceTaskRetrofitting? = nil) {
        
        self.session = session
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
        self.responseHandler = responseHandler
        self.errorHandler = errorHandler
        self.retrofitter = retrofitter
    }
    
    
    /// Perform task with action.
    public func perform(action: ServiceTaskAction) {
        
        do {
            
            guard !isRunning else {
                throw ServiceTaskError.alreadyRunning
            }
            
            // Save the action to use if will need to rewind
            self.action = action
            
            var request = try makeRequest()
            
            /// Make signature to sign URLSessionTask response block
            let signature = UUID()
            
            switch action {
            case .perform:
                // Data task
                underlayingTask = try makeDataTask(for: &request, with: signature)
            case .download(let path, let data):
                // Download task, will download data to file
                underlayingTask = try makeDownloadTask(for: &request, with: signature, destination: path, resume: data)
            case .upload:
                // Upload task
                underlayingTask = try makeUploadTask(for: &request, with: signature)
            }
            
            // Save the signature to check validity of URLSessionTask response later
            self.signature = signature
            
            // Start task
            underlayingTask?.resume()
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name.Condulet.TaskPerformed, object: self)
            }
            
        } catch {
            handleError(error)
        }
    }
    
    /// Cancels running task. Captured response blocks and handlers will never be called until task will be performed again or rewound.
    /// Optionally resume data can be produced on cancel in case of download task, otherwise completion will be called with nil data
    @discardableResult
    public func cancel(byProducingResumeData resumeDataHandler: ((Data?) -> Void)? = nil) -> Bool {
        
        guard isRunning else {
            return false
        }
        
        // Invalidate response of current URLSessionTask 
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
    
    /// Rewind task with lastest action performed. This will cancel running task. If action is not specified this method will return false, running task will not be canceled and no action will be performed
    @discardableResult
    public func rewind() -> Bool {
        
        guard let action = action else {
            return false
        }
        
        // Invalidate response of current URLSessionTask, if one is running
        signature = nil
        
        // Cancel URLSessionTask, if one is active
        underlayingTask?.cancel()
        
        // Perform new URLSessionTask with actual configuration
        perform(action: action)
        
        return true
    }
    
    // MARK: - URLSessionTask backing
    
    /// Decide how the response from URLSessionTask will be handled
    public func dispatchResponse(_ signature: UUID, _ content: ServiceTaskContent?, _ response: URLResponse?, _ error: Error?) {
        
        // The response signature is differs from stored signature. That means the response is received from from abandoned task and should be ignored
        guard self.signature == signature else {
            return // Response is no longer relevant
        }
        
        // No signature will indicate that task is completed
        self.signature = nil
        
        // Save response content
        self.content = content
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name.Condulet.TaskCompleted, object: self)
        }
        
        do {
            
            if let error = error {
                throw error
            }
            
            guard let content = content, let response = response else {
                throw ServiceTaskError.invalidResponse
            }
            
            guard !(try retrofitter?.serviceTask(self, intercept: content, response: response) ?? false) else {
                return
            }
            
            try handleContent(content, response)
            
        } catch {
            
            guard !(retrofitter?.serviceTask(self, intercept: error, response: response) ?? false) else {
                return
            }
            
            handleError(error, response)
        }
    }
    
    // MARK: - Builder methods
    
    /// Produces a request built from ServiceTask parameters. When have invalid parameters an error will be thrown.
    open func makeRequest() throws -> URLRequest {
        
        guard let url = url.url else {
            throw ServiceTaskError.invalidEndpoint
        }
        
        guard let method = method else {
            throw ServiceTaskError.noMethodSpecified
        }

        var request = URLRequest(url: url)
        
        request.allHTTPHeaderFields = headers
        request.httpMethod = method.rawValue
        
        return request
    }

    /// Fills request HTTP body with the data
    open func prepareBody(for request: inout URLRequest) throws {
        
        guard let body = body else {
            return
        }
        
        switch body {
        case .data(let data):
            request.httpBody = data
        case .file(let url):
            guard let stream = InputStream(url: url) else {
                throw ServiceTaskError.invalidFile
            }
            request.httpBodyStream = stream
        }
    }

    /// Produces data task
    open func makeDataTask(for request: inout URLRequest, with signature: UUID) throws -> URLSessionDataTask {

        guard let session = session else {
            throw ServiceTaskError.noSessionSpecified
        }

        try prepareBody(for: &request)

        try retrofitter?.serviceTask(self, modify: &request)

        return session.dataTask(with: request) { (data, response, error) in
            self.dispatchResponse(signature, ServiceTaskContent(data), response, error)
        }
    }

    /// Produces download task
    open func makeDownloadTask(for request: inout URLRequest, with signature: UUID, destination: URL, resume data: Data?) throws -> URLSessionDownloadTask {

        guard let session = session else {
            throw ServiceTaskError.noSessionSpecified
        }

        let completion = { (url: URL?, response: URLResponse?, error: Error?) -> Void in
            if let url = url {
                do {
                    // Move received file to desired location
                    try FileManager.default.moveItem(at: url, to: destination)
                    self.dispatchResponse(signature, ServiceTaskContent(destination), response, error)
                }
                catch {
                    self.dispatchResponse(signature, nil, response, ServiceTaskError.invalidDestination)
                }
            }
            else {
                self.dispatchResponse(signature, nil, response, error)
            }
        }

        try prepareBody(for: &request)

        try retrofitter?.serviceTask(self, modify: &request)

        if let data = data {
            return session.downloadTask(withResumeData: data, completionHandler: completion)
        }
        else {
            return session.downloadTask(with: request, completionHandler: completion)
        }
    }

    /// Produces upload task
    open func makeUploadTask(for request: inout URLRequest, with signature: UUID) throws -> URLSessionUploadTask {

        guard let session = session else {
            throw ServiceTaskError.noSessionSpecified
        }
        
        guard let body = body else {
            throw ServiceTaskError.noRequestBody
        }

        try retrofitter?.serviceTask(self, modify: &request)

        switch body {
        case .data(let data):
            return session.uploadTask(with: request, from: data) { (data, response, error) in
                self.dispatchResponse(signature, ServiceTaskContent(data), response, error)
            }
        case .file(let url):
            return session.uploadTask(with: request, fromFile: url) { (data, response, error) in
                self.dispatchResponse(signature, ServiceTaskContent(data), response, error)
            }
        }
    }
    
    // MARK: - Response handling methods

    /// Handle response content
    open func handleContent(_ content: ServiceTaskContent, _ response: URLResponse) throws {

        // Run response handler
        try responseHandler?.handle(content: content, response: response)
    }
    
    /// Handle any error
    open func handleError(_ error: Error, _ response: URLResponse? = nil) {
        
        // Run error handler
        errorHandler?.handle(error: error, response: response)
    }
    
}
