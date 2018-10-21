//
//  Connectivity.swift
//  Condulet
//
//  Created by Natan Zalkin on 21/10/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

/*
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
import SystemConfiguration


/// Use Reachability calss to listen for reachability changes of specified host.
public class Reachability {
    
    private var reachability: SCNetworkReachability
    private var flags: SCNetworkReachabilityFlags?

    public var changeHandler: ((Reachability) -> Void)?

    public private(set) var isListening = false

    /// The connection to the specified host must be established first.
    var isConnectionRequired: Bool {
        return flags?.isConnectionRequired ?? false
    }

    /// A connection to the specified host can be established automatically without user interaction.
    var isConnectsAutomatically: Bool {
        return flags?.isConnectsAutomatically ?? false
    }

    /// The specified host can be reached using the current network configuration.
    public var isHostReachable: Bool {
        guard let flags = flags else { return false }
        return flags.isNodeReachable && (!flags.isConnectionRequired || flags.isConnectsAutomatically)
    }

    /// Creates an instance of 'Reachability' object associated with specified host
    public init?(host: String, changeHandler: ((Reachability) -> Void)? = nil) {

        guard let reachability = SCNetworkReachabilityCreateWithName(nil, host) else {
            return nil
        }

        self.changeHandler = changeHandler
        self.reachability = reachability
    }
    
    deinit {
        stopListening()
    }

    /// Start listening for reachability changes of the specified host
    public func startListening(queue: DispatchQueue = DispatchQueue.main) -> Bool {
        
        guard !isListening else {
            return false
        }

        guard SCNetworkReachabilitySetDispatchQueue(reachability, queue) else {
            return false
        }

        let reachabilityCallback: SCNetworkReachabilityCallBack? = { (_, flags, info) in
            let selfRef = Unmanaged<Reachability>.fromOpaque(info!).takeUnretainedValue()
            selfRef.flags = flags
            selfRef.changeHandler?(selfRef)
        }

        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        context.info = Unmanaged<Reachability>.passUnretained(self).toOpaque()

        guard SCNetworkReachabilitySetCallback(reachability, reachabilityCallback, &context) else {
            return false
        }

        flags = SCNetworkReachabilityFlags()
        isListening = true

        queue.async {
            self.changeHandler?(self)
        }

        return true
    }

    /// Stop listening for for reachability changes of the specified host
    public func stopListening() {
        
        guard isListening else {
            return
        }

        SCNetworkReachabilitySetCallback(reachability, nil, nil)
        SCNetworkReachabilitySetDispatchQueue(reachability, nil)

        isListening = false
        flags = nil
    }
}

extension SCNetworkReachabilityFlags {

    var isNodeReachable: Bool {
        return contains(.reachable)
    }

    var isConnectionRequired: Bool {
        return contains(.connectionRequired)
    }

    var isConnectsAutomatically: Bool {
        return (contains(.connectionOnDemand) || contains(.connectionOnTraffic)) && !contains(.interventionRequired)
    }
}
