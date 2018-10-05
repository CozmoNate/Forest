//
//  MimeType.swift
//  Condulet
//
//  Created by Natan Zalkin on 05/10/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

import Foundation
import CoreServices


func mimeTypeFromPathExtension(_ pathExtension: String) -> String? {
    guard let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as CFString, kUTTagClassFilenameExtension)?.takeRetainedValue() else {
        return nil
    }
    guard let mime = UTTypeCopyPreferredTagWithClass(uti as CFString, kUTTagClassMIMEType)?.takeRetainedValue() else {
        return nil
    }
    return mime as String
}

func contentTypeForURL(_ url: URL) -> String {
    return mimeTypeFromPathExtension(url.pathExtension) ?? "application/octet-stream"
}
