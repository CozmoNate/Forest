//
//  FormDataChunk.swift
//  Condulet
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


public enum FormDataChunk {

    case separator(boundary: String)
    case contentDisposition(name: String)
    case contentType(value: String)
    case contentEncoding(value: String)
    case header(name: String, value: String)
    case parameter(semicolon: Bool, name: String, value: String?)
    case string(String)
    case source(InputStream, size: Int)
    case lineBreak
    case closure(boundary: String)
    
    public func write(to stream: OutputStream, bufferSize: Int = 1_000_000) throws {
        switch self {
        case .separator(let boundary):
            try stream.write("--\(boundary)")
        case .contentDisposition(let name):
            try stream.write("Content-Disposition: form-data; name=\"\(name)\"")
        case .contentType(let value):
            try stream.write("Content-Type: \(value)")
        case .contentEncoding(let value):
            try stream.write("Content-Transfer-Encoding: \(value)")
        case .header(let name, let value):
            try stream.write("\(name): \(value)")
        case .parameter(let semicolon, let name, let value):
            try stream.write((semicolon ? "; " : "") + name + (value != nil ? "=\(value!)" : ""))
        case .string(let string):
            try stream.write(string)
        case .source(let input, let size):
            try transfer(from: input, to: stream, bufferSize: size < bufferSize ? size : bufferSize)
        case .lineBreak:
            try stream.write("\r\n")
        case .closure(let boundary):
            try stream.write("--\(boundary)--")
        }
    }
    
    private func transfer(from input: InputStream, to output: OutputStream, bufferSize: Int) throws {

        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer {
            buffer.deallocate()
        }

        input.open()
        defer {
            input.close()
        }
        
        while input.hasBytesAvailable {
            let readResult = input.read(buffer, maxLength: bufferSize)
            guard readResult > 0 else {
                if readResult < 0 {
                    throw input.streamError ?? FormDataError.outputOperationFailure
                }
                return
            }
            let writeResult = output.write(buffer, maxLength: readResult)
            if writeResult != readResult {
                throw output.streamError ?? FormDataError.outputOperationFailure
            }
        }
    }
}

fileprivate extension OutputStream {

    @discardableResult
    func write(_ string: String) throws -> Int {
        guard hasSpaceAvailable else {
            throw FormDataError.noOutputSpace
        }
        let data = [UInt8](string.utf8)
        let result = write(data, maxLength: data.count)
        if result < 0 {
            throw streamError ?? FormDataError.outputOperationFailure
        }
        return result
    }

    @discardableResult
    func write(_ data: Data) throws -> Int {
        guard hasSpaceAvailable else {
            throw FormDataError.noOutputSpace
        }
        let result = data.withUnsafeBytes({ write($0, maxLength: data.count) })
        if result < 0 {
            throw streamError ?? FormDataError.outputOperationFailure
        }
        return result
    }
}
