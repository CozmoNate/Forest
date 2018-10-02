//
//  ServiceTask+Perform.swift
//  Condulet
//
//  Created by Natan Zalkin on 01/10/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

import Foundation


public extension ServiceTask {

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
    
    /// Perform upload data task
    @discardableResult
    public func upload(from data: Data) -> Self {
        perform(action: .upload(.data(data)))
        return self
    }
    
    /// Perform upload file task
    @discardableResult
    public func upload(from url: URL) -> Self {
        perform(action: .upload(.file(url)))
        return self
    }
    
}
