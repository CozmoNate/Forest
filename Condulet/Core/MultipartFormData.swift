//
//  MultipartFormData.swift
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


public enum MultipartFormDataError: Error {
    
    case emptyData
    case emptyFileOrNoAccess(URL)
    case fileIsNotAccessible(URL)
    case fileIsNotWriteable(URL)
    case streamOperationFailure
    case unknown
}

/// This class is used to compose requst body using 'multipart/form-data' encoding
public class MultipartFormData {
    
    /// The name of the boundary
    public var boundary: String
    /// The size in bytes of memory buffer to be used to transfer data from file to output file/data while encoding content. Default value is 1Mb
    public var bufferSize: Int
    /// The list of media items to encode
    public private(set) var mediaItems = [MediaItem]()
    /// Size of the raw multipart data of all items. This size does not include any coding overheads
    public private(set) var contentSize = UInt64(0)
    /// The value to be used for HTTP request "Content-Type" header field
    public var contentType: String {
        return "multipart/form-data; boundary=\(boundary)"
    }
    
    /// Initialize instance of MultipartFormData
    ///
    /// - Parameters:
    ///   - boundary: The name of the boundary
    ///   - bufferSize: The size in bytes of memory buffer to be used to transfer data from file to output file/data while encoding content
    public init(boundary: String = "Condulet.\(NSUUID().uuidString)", bufferSize: Int = 1_000_000) {
        self.boundary = boundary
        self.bufferSize = bufferSize
    }
    
    public func appendMediaItem(_ item: MediaItem) throws {
        
        switch item {
            
        case .parameter(_, let value):
            contentSize += UInt64(value.utf8.count)
        case .data(_, _, let data):
            contentSize += UInt64(data.count)
        case .file(_, _, _, let data):
            guard data.count > 0 else {
                throw MultipartFormDataError.emptyData
            }
            contentSize += UInt64(data.count)
        case .url(_, _, _, let url):
            let size = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? UInt64 ?? 0
            guard size > 0 else {
                throw MultipartFormDataError.emptyFileOrNoAccess(url)
            }
            contentSize += size
        }
        
        mediaItems.append(item)
    }
    
    /// Encode multipart content in memory
    public func encode() throws -> Data {
        
        let memoryStream = OutputStream(toMemory: ())
        
        try encode(to: memoryStream)
        
        guard let data = memoryStream.property(forKey: .dataWrittenToMemoryStreamKey) as? Data else {
            throw MultipartFormDataError.streamOperationFailure
        }
        
        return data
    }
    
    /// Encode and save multipart content into file
    public func encode(to file: URL, append: Bool = false) throws {

        guard let fileStream = OutputStream(url: file, append: append) else {
            throw MultipartFormDataError.fileIsNotWriteable(file)
        }
        
        try encode(to: fileStream)
    }
    
    /// Encode and write multipart content into provided instance of OutputStream
    public func encode(to stream: OutputStream) throws {
        
        stream.open()
        defer {
            stream.close()
        }
        
        try mediaItems.forEach { (item) in
            
            try stream.write("--\(boundary)".appendLineBreak())
            
            switch item {
                
            case .parameter(let name, let value):
                try stream.write("Content-Disposition: form-data; name=\"\(name)\"".appendLineBreak())
                try stream.write(.lineBreakSequence)
                try stream.write("\(value)")
                try stream.write(.lineBreakSequence)
                
            case .data(let name, let mimeType, let data):
                try stream.write("Content-Disposition: form-data; name=\"\(name)\"".appendLineBreak())
                try stream.write("Content-Type: \(mimeType)".appendLineBreak())
                try stream.write(.lineBreakSequence)
                try stream.write(data)
                try stream.write(.lineBreakSequence)
                
            case .file(let name, let fileName, let mimeType, let data):
                try stream.write("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"".appendLineBreak())
                try stream.write("Content-Type: \(mimeType)".appendLineBreak())
                try stream.write(.lineBreakSequence)
                try stream.write(data)
                try stream.write(.lineBreakSequence)
                
            case .url(let name, let fileName, let mimeType, let url):
                try stream.write("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName ?? url.lastPathComponent)\"".appendLineBreak())
                try stream.write("Content-Type: \(mimeType ?? mimeTypeForFileAtURL(url))".appendLineBreak())
                try stream.write(.lineBreakSequence)
                try transfer(from: url, to: stream)
                try stream.write(.lineBreakSequence)
            }
        }
        
        try stream.write("--\(boundary)--".appendLineBreak())
    }
    
    private func transfer(from url: URL, to output: OutputStream) throws {
        guard let input = InputStream(url: url) else {
            throw MultipartFormDataError.fileIsNotAccessible(url)
        }
        input.open()
        defer {
            input.close()
        }
        try transfer(from: input, to: output)
    }
    
    private func transfer(from input: InputStream, to output: OutputStream) throws {
        
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer {
            buffer.deallocate()
        }
        
        while input.hasBytesAvailable {
            let readResult = input.read(buffer, maxLength: bufferSize)
            guard readResult > 0 else {
                if readResult < 0 {
                    throw input.streamError ?? MultipartFormDataError.streamOperationFailure
                }
                return
            }
            let writeResult = output.write(buffer, maxLength: readResult)
            if writeResult != readResult {
                throw output.streamError ?? MultipartFormDataError.streamOperationFailure
            }
        }
    }
    
}

public extension MultipartFormData {
    
    public enum MediaItem {
        
        case parameter(name: String, value: String)
        case data(name: String, mimeType: String, data: Data)
        case file(name: String, fileName: String, mimeType: String, data: Data)
        case url(name: String, fileName: String?, mimeType: String?, url: URL)
    }
    
}

extension OutputStream {
    
    @discardableResult
    func write(_ string: String) throws -> Int {
        let data = [UInt8](string.utf8)
        let result = write(data, maxLength: data.count)
        if result < 0 {
            throw streamError ?? MultipartFormDataError.streamOperationFailure
        }
        return result
    }
    
    @discardableResult
    func write(_ data: Data) throws -> Int {
        let result = data.withUnsafeBytes({ write($0, maxLength: data.count) })
        if result < 0 {
            throw streamError ?? MultipartFormDataError.streamOperationFailure
        }
        return result
    }
}

extension String {
    
    static let lineBreakSequence = "\r\n"
    
    func appendLineBreak() -> String {
        return self + .lineBreakSequence
    }
}
