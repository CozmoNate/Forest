//
//  ServiceTask+Perform.swift
//  Condulet
//
//  Created by Natan Zalkin on 01/10/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

import Foundation


public extension ServiceTask {

    /// Set URLSession instance to use when creating URLSessionTask instance
    @discardableResult
    public func session(_ session: URLSession) -> Self {
        self.session = session
        return self
    }
    
    /// Perform data task
    @discardableResult
    public func perform() -> Self {
        perform(action: .perform)
        return self
    }
    
    /// Perform download task. If destination name not specified, temporary filename will be generated
    ///
    /// - Parameter destination: The destination where file should be saved. When not specified, file will be downloaded and saved to temp folder and should be manually removed
    @discardableResult
    public func download(to destination: URL? = nil) -> Self {
        let url = destination ?? FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("tmp")
        perform(action: .download(url))
        return self
    }
    
    /// Perform upload task. This is similar to perform but uses URLSessionUploadTask which could run in background
    @discardableResult
    public func upload() -> Self {
        perform(action: .upload)
        return self
    }
    
}
