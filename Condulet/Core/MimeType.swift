//
//  MimeType.swift
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
import MobileCoreServices


public func textEncodingNameToStringEncoding(_ textEncodingName: String) -> String.Encoding? {
    let core = CFStringConvertIANACharSetNameToEncoding(textEncodingName as CFString)
    let encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(core))
    return encoding
}

public func stringEncodingToTextEncodingName(_ encoding: String.Encoding) -> String? {
    let code = CFStringConvertNSStringEncodingToEncoding(encoding.rawValue)
    let charset = CFStringConvertEncodingToIANACharSetName(code) as String?
    return charset
}

public func mimeTypeFromPathExtension(_ pathExtension: String) -> String? {
    guard let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as NSString, nil)?.takeRetainedValue() else {
        return nil
    }
    guard let mime = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() else {
        return nil
    }
    return mime as String
}

public func mimeTypeForFileAtURL(_ url: URL) -> String {
    return mimeTypeFromPathExtension(url.pathExtension) ?? "application/octet-stream"
}
