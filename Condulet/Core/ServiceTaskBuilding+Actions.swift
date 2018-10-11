//
//  ServiceTask+Perform.swift
//  Condulet
//
//  Created by Natan Zalkin on 01/10/2018.
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


public extension ServiceTaskBuilding {
    
    /// Perform data task
    @discardableResult public func perform() -> Task {
        task.perform(action: .perform)
        return task
    }
    
    /// Perform download task. If destination name not specified, temporary filename will be generated
    ///
    /// - Parameter destination: The destination where file should be saved. When not specified, file will be downloaded and saved to temp folder and should be manually removed
    @discardableResult public func download(to destination: URL? = nil, with resumeData: Data? = nil) -> Task {
        let url = destination ?? FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("tmp")
        task.perform(action: .download(destination: url, resumeData: resumeData))
        return task
    }
    
    /// Perform upload task. This is similar to perform but uses URLSessionUploadTask which could run in background.
    @discardableResult public func upload() -> Task {
        task.perform(action: .upload)
        return task
    }
    
}
