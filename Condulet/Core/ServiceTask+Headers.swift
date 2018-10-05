//
//  ServiceTask+Headers.swift
//  Condulet
//
//  Created by Natan Zalkin on 05/10/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

import Foundation


extension ServiceTask {
    
    /// Append HTTP headers to request. Set 'merge' parameter to false to override existing headers.
    @discardableResult
    public func headers(_ headers: [String: String], merge: Bool = true) -> Self {
        if merge {
            // Append by overriding existing key with new one in case of collision
            self.headers.merge(headers, uniquingKeysWith: { return $1 })
        }
        else {
            self.headers = headers
        }
        return self
    }
    
}
