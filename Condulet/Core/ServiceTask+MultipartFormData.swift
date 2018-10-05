//
//  ServiceTask+MultipartFormData.swift
//  Condulet
//
//  Created by Natan Zalkin on 05/10/2018.
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


public extension ServiceTask {
    
    public struct MultipartFormData {

        public var boundary: String

        public var contentType: String {
            return "multipart/form-data; boundary=\(boundary)"
        }

        private let lineBreakSequence = "\r\n"
        private var mediaItems = [MediaItem]()

        public init(boundary: String = "Condulet.\(NSUUID().uuidString)") {
            self.boundary = boundary
        }

        public mutating func appendMediaItem(_ item: MediaItem) {
            mediaItems.append(item)
        }

        public func generateBodyData() throws -> Data {

            var result = Data()

            guard !mediaItems.isEmpty else {
                return result
            }

            try mediaItems.forEach { (item) in

                result.append("--\(boundary)\(lineBreakSequence)")

                switch item {

                case .parameter(let name, let value):
                    result.append("Content-Disposition: form-data; name=\"\(name)\"\(lineBreakSequence)\(lineBreakSequence)")
                    result.append("\(value)\(lineBreakSequence)")

                case .data(let name, let mimeType, let data):
                    result.append("Content-Disposition: form-data; name=\"\(name)\"\(lineBreakSequence)\(lineBreakSequence)")
                    result.append("Content-Type: \(mimeType)\(lineBreakSequence)\(lineBreakSequence)")
                    result.append(data)
                    result.append(lineBreakSequence)

                case .file(let name, let fileName, let mimeType, let data):
                    result.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\(lineBreakSequence)")
                    result.append("Content-Type: \(mimeType)\(lineBreakSequence)\(lineBreakSequence)")
                    result.append(data)
                    result.append(lineBreakSequence)

                case .url(let name, let fileName, let mimeType, let url):
                    result.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName ?? url.lastPathComponent)\"\(lineBreakSequence)")
                    result.append("Content-Type: \(mimeType ?? contentTypeForURL(url))\(lineBreakSequence)\(lineBreakSequence)")
                    result.append(try Data(contentsOf: url))
                    result.append(lineBreakSequence)
                }
            }

            result.append("--\(boundary)--\(lineBreakSequence)")

            return result
        }
    }
}

public extension ServiceTask.MultipartFormData {

    public enum MediaItem {

        case parameter(name: String, value: String)
        case data(name: String, mimeType: String, data: Data)
        case file(name: String, fileName: String, mimeType: String, data: Data)
        case url(name: String, fileName: String?, mimeType: String?, url: URL)
    }

}

extension Data {

    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }

}

