//
//  FormDataBuilder.swift
//  Forest
//
//  Created by Natan Zalkin on 09/10/2018.
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


/// Use FormDataBoundary to create multipart/form-data encoded content
public struct FormDataBuilder {

    /// The name of the boundary
    public let boundary: String

    /// The value to be used for HTTP request "Content-Type" header field
    public let contentType: String

    /// The content body parts
    public var parts: [FormDataPart]

    public init(boundary: String = UUID().uuidString, parts: [FormDataPart] = []) {
        self.boundary = boundary
        self.parts = parts
        contentType = "multipart/form-data; boundary=\(boundary)"
    }

    /// Append form data part
    public mutating func append(_ part: FormDataPart) {
        parts.append(part)
    }

    /// Translate boundary parts to chunks enclosing with apropriate boundary separators. 
    public func translate() -> [FormDataChunk] {

        var chunks = [FormDataChunk]()

        parts.forEach {
            chunks += makePartSeparator()
            chunks += $0.chunks
        }

        chunks += makeBoundaryClosure()

        return chunks
    }

    /// Calculates the resulting data size in bytes of all data parts including encoding overhead
    public func calculateContentSize() -> UInt64 {
        let chunks = translate()
        return FormDataBuilder.size(of: chunks)
    }

    /// Generate form data content and write to provided OutputStream instance
    ///
    /// - Parameters:
    ///   - stream: The stream that will be used to write data
    ///   - buffer: The size of the memory buffer in bytes used to transfer data from input sources to output stream
    public func encode(to stream: OutputStream, bufferSize: Int = 1_000_000) throws {
        let chunks = translate()
        try FormDataBuilder.write(chunks: chunks, to: stream, bufferSize: bufferSize)
    }

    /// Generate form data content in memory
    ///
    /// - Parameter buffer: The size in bytes of a memory buffer to be used to transfer data from part source to memory while encoding content. Default value is 1Mb
    /// - Returns: Returns an instance of a Data object with encoded boundary content ready to use as a body for URLRequest
    public func encode(bufferSize: Int = 1_000_000) throws -> Data {
        let chunks = translate()
        return try FormDataBuilder.writeToMemory(chunks: chunks, bufferSize: bufferSize)
    }

    /// Generate form data content and write to file
    ///
    /// - Parameters:
    ///   - file: The URL to the file the boundary content will be written to.
    ///   - append: true if newly written data should be appended to any existing file contents, otherwise false.
    ///   - buffer: The size in bytes of a memory buffer to be used to transfer data from part source to file while encoding content. Default value is 1Mb
    public func encode(to file: URL, append: Bool = false, bufferSize: Int = 1_000_000) throws {
        let chunks = translate()
        return try FormDataBuilder.write(chunks: chunks, to: file, bufferSize: bufferSize)
    }
}

public extension FormDataBuilder {

    /// Calculates the size in bytes of all chunks
    static func size(of chunks: [FormDataChunk]) -> UInt64 {

        let size = chunks.reduce(0, { (result, chunk) -> UInt64 in
            switch chunk {
            case .source(_, let size):
                return result + UInt64(size)
            default:
                let bytes = try? chunk.getBytes().count
                return result + UInt64(bytes ?? 0)
            }
        })

        return size
    }

    /// Write form data content to provided OutputStream instance
    ///
    /// - Parameters:
    ///   - chunks: The form data chunks representing form data
    ///   - stream: The stream that will be used to write data
    ///   - buffer: The size of the memory buffer in bytes used to transfer data from input sources to output stream
    static func write(chunks: [FormDataChunk], to stream: OutputStream, bufferSize: Int = 1_000_000) throws {

        stream.open()
        defer {
            stream.close()
        }

        try chunks.forEach {
            try $0.write(to: stream, bufferSize: bufferSize)
        }
    }

    /// Generate form data content in memory
    ///
    /// - Parameters:
    ///   - chunks: The form data chunks representing form data
    ///   - buffer: The size in bytes of a memory buffer to be used to transfer data from part source to memory while encoding content. Default value is 1Mb
    /// - Returns: Returns an instance of a Data object with encoded boundary content ready to use as a body for URLRequest
    static func writeToMemory(chunks: [FormDataChunk], bufferSize: Int = 1_000_000) throws -> Data {

        let memoryStream = OutputStream.toMemory()

        try write(chunks: chunks, to: memoryStream, bufferSize: bufferSize)

        guard let data = memoryStream.property(forKey: .dataWrittenToMemoryStreamKey) as? Data else {
            throw FormDataError.outputOperationFailure
        }

        return data
    }

    /// Generate form data content and write to file
    ///
    /// - Parameters:
    ///   - chunks: The form data chunks representing form data
    ///   - file: The URL to the file the boundary content will be written to.
    ///   - append: true if newly written data should be appended to any existing file contents, otherwise false.
    ///   - buffer: The size in bytes of a memory buffer to be used to transfer data from part source to file while encoding content. Default value is 1Mb
    static func write(chunks: [FormDataChunk], to file: URL, append: Bool = false, bufferSize: Int = 1_000_000) throws {

        guard let fileStream = OutputStream(url: file, append: append) else {
            throw FormDataError.fileIsNotWriteable(file)
        }

        try write(chunks: chunks, to: fileStream, bufferSize: bufferSize)
    }
}

public extension FormDataBuilder {

    func makePartSeparator() -> [FormDataChunk] {
        return [.separator(boundary: boundary), .lineBreak]
    }

    func makeBoundaryClosure() -> [FormDataChunk] {
        return [.closure(boundary: boundary), .lineBreak]
    }
}
