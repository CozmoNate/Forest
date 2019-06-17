//
//  ServiceTaskPerformable+Actions.swift
//  Condulet
//
//  Created by Natan Zalkin on 17/06/2019.
//  Copyright © 2019 Natan Zalkin. All rights reserved.
//

/*
 * Copyright (c) 2019 Zalkin, Natan
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


public extension ServiceTaskPerformable {

    /// Perform data task
    @discardableResult
    func perform() -> Self {
        perform(action: .perform)
        return self
    }

    /// Perform download task. If destination name not specified, temporary filename will be generated
    ///
    /// - Parameter destination: The destination where file should be saved. When not specified, file will be downloaded and saved to temp folder and should be manually removed
    @discardableResult
    func download(to destination: URL? = nil, with resumeData: Data? = nil) -> Self {
        let url = destination ?? FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("tmp")
        perform(action: .download(destination: url, resumeData: resumeData))
        return self
    }

    /// Use upload task to upload data directly from file
    @discardableResult
    func upload() -> Self {
        perform(action: .upload)
        return self
    }

}
