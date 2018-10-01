//
//  ServiceTask.swift
//  Joto
//
//  Created by Natan Zalkin on 28/09/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

import Foundation


public extension Notification.Name {
    
    public enum Condulet {
        
        /// Posted when a ServiceTask is performed. The notification `object` contains the instance of URLSessionTask started.
        public static let TaskPerformed = Notification.Name(rawValue: "Condulet.TaskPerformed")
        
        /// Posted when a ServiceTask is received response. The notification `object` contains the instance of URLSessionTask completed.
        public static let TaskCompleted = Notification.Name(rawValue: "Condulet.TaskCompleted")
        
    }
    
}

/// URLSessionTask wrapping class allowing to build, send, cancel and rewind network requests. Built for subclassing
open class ServiceTask: CustomStringConvertible, CustomDebugStringConvertible, Hashable {
    
    // MARK: - CustomStringConvertible
    
    public var description: String {
        
        let description = "<\(String(describing: type(of: self))) #\(hashValue)>"
        
        var parameters = ""
        
        if let method = method {
            parameters += "\(method.rawValue)"
        }
        
        if let url = endpoint.string, !url.isEmpty {
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
    
    // MARK: - Configuration properties
    
    /// A URLSession instance used to create URLSessionTask
    public var session: URLSession?
    /// A URLComponents instance describing service endpoint
    public var endpoint: URLComponents
    /// A HTTP method used for request
    public var method: Method?
    /// HTTP headers added to request
    public var headers: [String: String]
    /// HTTP body data
    public var body: Data?
    /// Service response handler
    public var responseHandler: ServiceTaskContentHandling?
    /// Failure handler
    public var errorHandler: ServiceTaskErrorHandling?
    
    // MARK: - Properties
    
    /// The action of the task performed.
    public var action: Action?
    /// Signature is used to determine if response from URLSessionTask still relevant and should be handled
    public var signature: UUID?
    /// The underlying task running
    public var task: URLSessionTask?

    /// Easy access to 'Content-Type' HTTP headers entry
    public var contentType: String? {
        get { return headers["Content-Type"] }
        set { headers["Content-Type"] = newValue }
    }

    public var inRunning: Bool {
        return task?.state == .running || task?.state == .suspended
    }

    // MARK: - Lifecycle
    
    /// Creates the instance of ServiceTask
    public init(session: URLSession = URLSession.shared, endpoint: URLComponents = URLComponents(), method: ServiceTask.Method? = nil, headers: [String: String] = [:], body: Data? = nil, responseHandler: ServiceTaskContentHandling? = nil, errorHandler: ServiceTaskErrorHandling? = nil) {
        
        self.session = session
        self.endpoint = endpoint
        self.method = method
        self.headers = headers
        self.body = body
        self.responseHandler = responseHandler
        self.errorHandler = errorHandler
    }
    
    deinit {
        print("Disposed: \(self)")
    }
    // MARK: - Builder
    
    /// Produces a request built from ServiceTask parameters. When have invalid parameters an error will be thrown. Override in subclass to change default implementation
    public func makeRequest() throws -> URLRequest {
        
        guard let url = endpoint.url else {
            throw ConduletError.invalidEndpoint
        }
        
        guard let method = method else {
            throw ConduletError.noMethodSpecified
        }

        var request = URLRequest(url: url)
        
        request.allHTTPHeaderFields = headers
        request.httpMethod = method.rawValue
        
        // Prepare body
        request.httpBody = body
        
        return request
    }
    
    // MARK: - Actions
    
    /// Associate provided task instance, signature and action with the ServiceTask instance. Override in subclass to change default implementation
    public func perform(task: URLSessionTask, action: Action, signature: UUID) {
        
        self.task = task
        self.action = action
        self.signature = signature
        
        task.resume()
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name.Condulet.TaskPerformed, object: task)
        }
    }
    
    /// Perform task with action. Override in subclass to change default implementation
    public func perform(action: Action) {
        
        do {
            
            guard !inRunning else {
                throw ConduletError.alreadyRunning
            }
            
            guard let session = session else {
                throw ConduletError.noSessionSpecified
            }
            
            let request = try makeRequest()
            
            let signature = UUID()
            let task: URLSessionTask
            
            switch action {
            case .perform:
                task = session.dataTask(with: request) { (data, response, error) in
                    self.handleResponse(signature, Content(data), response, error)
                }
            case .download:
                task = session.downloadTask(with: request) { (url, response, error) in
                    self.handleResponse(signature, Content(url), response, error)
                }
            case .upload(let content):
                switch content {
                case .data(let data):
                    task = session.uploadTask(with: request, from: data) { (data, response, error) in
                        self.handleResponse(signature, Content(data), response, error)
                    }
                case .file(let url):
                    task = session.uploadTask(with: request, fromFile: url) { (data, response, error) in
                        self.handleResponse(signature, Content(data), response, error)
                    }
                }
            }
            
            perform(task: task, action: .perform, signature: signature)
            
        } catch {
            handleResponse(error, nil)
        }
    }
    
    /// Invalidates running task, returns true when task is actually canceled. Captured response blocks and handlers will never be called until task will be performed again or rewound. Override in subclass to change default implementation
    @discardableResult
    public func cancel() -> Bool {
        
        guard inRunning else {
            return false
        }
        
        // Invalidate URLSessionTask completion handler
        signature = nil
        
        // Cancel task
        task?.cancel()
        
        return true
    }
    
    /// Rewind task with lastest action performed. If action is not specified task will fail with 'noActionPerformed' error. Override in subclass to change default implementation
    public func rewind() {
        
        do {
            
            guard let action = action else {
                throw ConduletError.noActionPerformed
            }
            
            perform(action: action)
            
        } catch {
            handleResponse(error, nil)
        }
    }
    
    // MARK: - Handlers
    
    /// Handle general response, this method is called first on response received. Override in subclass to change default implementation
    public func handleResponse(_ signature: UUID, _ content: Content?, _ response: URLResponse?, _ error: Error?) {
        
        // When the response signature is differs from stored signature, that means we got response from abandoned requests and should ignore it
        guard self.signature == signature else {
            return // Response is no longer relevant
        }
        
        self.signature = nil
        
        if let task = task {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name.Condulet.TaskCompleted, object: task)
            }
        }
        
        do {
            
            if let error = error {
                throw error
            }
            
            guard let response = response else {
                throw ConduletError.invalidResponse
            }
            
            try handleResponse(response)
            
            guard let content = content else {
                throw ConduletError.invalidResponse
            }
            
            try handleResponse(content, response)
            
        } catch {
            handleResponse(error, response)
        }
    }
    
    /// Handle URLResponse received. This handler is called before starting to parse any data received. Override in subclass to change default implementation
    public func handleResponse(_ response: URLResponse) throws {
        
        // Pass any non-HTTP response
        guard let response = response as? HTTPURLResponse else {
            return
        }
        
        // In case of HTTP response, pass only response with valid status code
        guard 200..<300 ~= response.statusCode else {
            throw ConduletError.statusCode(response.statusCode)
        }
        
    }
    
    /// Handle content response. Override in subclass to change default implementation
    public func handleResponse(_ content: Content, _ response: URLResponse) throws {
        
        guard let handler = responseHandler else {
            throw ConduletError.noResponseHandler
        }
        
        // Run response handler
        try handler.handle(content: content, response: response)
    }
    
    /// Handle any error. Response parameter can store service response if received. Override in subclass to change default implementation
    public func handleResponse(_ error: Error, _ response: URLResponse?) {
        
        // Run error handler
        errorHandler?.handle(error: error, response: response)
    }
    
}
