//
//  FormDataPart.swift
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


public struct FormDataPart {

    public let chunks: [FormDataChunk]

    public init(_ chunks: [FormDataChunk]) {
        self.chunks = chunks
    }
}

// MARK: - Part builder

extension FormDataPart {
    
    /// Representation of possible values that "Content-Transfer-Encoding" form data field can get
    public enum Encoding {
        
        case base64
        case quotedPrintable
        case bitWidth8
        case bitWidth7
        case binary
        case token(String)
        
        public var value: String {
            
            switch self {
            case .base64: return "base64"
            case .quotedPrintable: return "quoted-printable"
            case .bitWidth8: return "8bit"
            case .bitWidth7: return "7bit"
            case .binary: return "binary"
            case .token(let token): return "x-\(token)"
            }
        }
    }
    
    /// Create data part with string content
    public static func property(name: String, value: String) -> FormDataPart {
        return FormDataPart([
            .contentDisposition(name: name), .lineBreak,
            .lineBreak,
            .string(value), .lineBreak
            ])
    }

    /// Create binary data part with MIME type using instance of Data as data source
    public static func binary(name: String, mimeType: String, transferEncoding: Encoding? = nil, data: Data) -> FormDataPart {
        return binary(name: name, mimeType: mimeType, transferEncoding: transferEncoding, stream: InputStream(data: data), size: data.count)
    }

    /// Create binary data part with MIME type using local file as a source of data
    public static func binary(name: String, mimeType: String, transferEncoding: Encoding? = nil, url: URL) throws -> FormDataPart {
        guard let size = try getFileSize(at: url), let stream = InputStream(url: url) else {
            throw FormDataError.emptyFileOrNoAccess(url)
        }
        return binary(name: name, mimeType: mimeType, transferEncoding: transferEncoding, stream: stream, size: size)
    }

    /// Create text data part with specific encoding (optional) using string as data source
    public static func text(name: String, encoding: String.Encoding = .utf8, charset: String? = nil, allowLossyConversion: Bool = false, value: String) throws -> FormDataPart {
        guard let encoded = value.data(using: encoding, allowLossyConversion: allowLossyConversion) else {
            throw FormDataError.invalidEncoding
        }
        return text(name: name, encoding: encoding, charset: charset, stream: InputStream(data: encoded), size: encoded.count)
    }
    
    /// Create text data part with specific encoding (optional) using instance of Data as a data source
    public static func text(name: String, encoding: String.Encoding = .utf8, charset: String? = nil, transferEncoding: Encoding? = nil, data: Data) -> FormDataPart {
        return text(name: name, encoding: encoding, charset: charset, transferEncoding: transferEncoding, stream: InputStream(data: data), size: data.count)
    }

    /// Create text data part with specific encoding (optional) using local file as a source of data
    public static func text(name: String, encoding: String.Encoding = .utf8, charset: String? = nil, transferEncoding: Encoding? = nil, url: URL) throws -> FormDataPart {
        guard let size = try getFileSize(at: url), let stream = InputStream(url: url) else {
            throw FormDataError.emptyFileOrNoAccess(url)
        }
        return text(name: name, encoding: encoding, charset: charset, transferEncoding: transferEncoding, stream: stream, size: size)
    }

    /// Create file data part using instance of Data as a data source
    public static func file(name: String, fileName: String, mimeType: String, charset: String? = nil, transferEncoding: Encoding? = nil, data: Data) -> FormDataPart {
        return file(name: name, fileName: fileName, mimeType: mimeType, charset: charset, transferEncoding: transferEncoding, stream: InputStream(data: data), size: data.count)
    }

    /// Create file data part using local file as a source of data
    public static func file(name: String, fileName: String? = nil, mimeType: String? = nil, transferEncoding: Encoding? = nil, url: URL) throws -> FormDataPart {
        guard let size = try getFileSize(at: url), let stream = InputStream(url: url) else {
            throw FormDataError.emptyFileOrNoAccess(url)
        }
        return file(name: name, fileName: fileName ?? url.lastPathComponent , mimeType: mimeType ?? mimeTypeForFileAtURL(url), transferEncoding: transferEncoding, stream: stream, size: size)
    }

    /// Encapsulate another boundary as data part
    public static func boundary(_ boundary: FormDataBuilder) -> FormDataPart {
        return FormDataPart(boundary.translate())
    }
}

// MARK: - Helpers

public extension FormDataPart {

    static func getFileSize(at url: URL) throws -> Int? {
        return try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int
    }

    /// Create binary data part with MIME type using InputStream as data source
    public static func binary(name: String, mimeType: String, transferEncoding: Encoding? = nil, stream: InputStream, size: Int = 0) -> FormDataPart {
        var chunks = [FormDataChunk]()
        chunks += [ .contentDisposition(name: name), .lineBreak]
        chunks += [.contentType(value: mimeType), .lineBreak]
        if let encoding = transferEncoding {
            chunks += [.contentEncoding(value: encoding.value), .lineBreak]
        }
        chunks += [.lineBreak, .source(stream, size: size), .lineBreak]
        return FormDataPart(chunks)
    }
    
    /// Create file data part using InputStream as data source
    public static func file(name: String, fileName: String, mimeType: String, charset: String? = nil, transferEncoding: Encoding? = nil, stream: InputStream, size: Int = 0) -> FormDataPart {
        var chunks = [FormDataChunk]()
        chunks += [.contentDisposition(name: name), .parameter(semicolon: true, name: "filename", value: "\"\(fileName)\""), .lineBreak]
        chunks += [.contentType(value: mimeType)]
        if let charset = charset {
            chunks += [.parameter(semicolon: true, name: "charset", value: charset), .lineBreak]
        }
        else {
            chunks.append(.lineBreak)
        }
        if let encoding = transferEncoding {
            chunks += [.contentEncoding(value: encoding.value), .lineBreak]
        }
        chunks += [.lineBreak, .source(stream, size: size), .lineBreak]
        return FormDataPart(chunks)
    }
    
    /// Create text data part with specific encoding (optional) using InputStream as data source
    public static func text(name: String, encoding: String.Encoding? = nil, charset: String? = nil, transferEncoding: Encoding? = nil, stream: InputStream, size: Int = 0) -> FormDataPart {
        var chunks = [FormDataChunk]()
        chunks += [.contentDisposition(name: name), .lineBreak]
        chunks += [.contentType(value: "text/plain")]
        if let encoding = encoding, let charset = charset ?? stringEncodingToTextEncodingName(encoding) {
            chunks += [.parameter(semicolon: true, name: "charset", value: charset), .lineBreak]
        }
        else {
            chunks.append(.lineBreak)
        }
        if let encoding = transferEncoding {
            chunks += [.contentEncoding(value: encoding.value), .lineBreak]
        }
        chunks += [.lineBreak, .source(stream, size: size), .lineBreak]
        return FormDataPart(chunks)
    }

}
