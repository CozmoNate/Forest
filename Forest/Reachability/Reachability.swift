//
//  Reachability.swift
//  Forest
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

    public private(set) var isListening = false

    /// The connection to the specified host must be established first.
    var isConnectionRequired: Bool {
        return flags.isConnectionRequired
    }

    /// A connection to the specified host can be established automatically without user interaction.
    var isConnectsAutomatically: Bool {
        return flags.isConnectsAutomatically
    }

    /// The specified host can be reached using the current network configuration.
    public var isHostReachable: Bool {
        return flags.isHostReachable && (!flags.isConnectionRequired || flags.isConnectsAutomatically)
    }

    public var listener: ((Reachability) -> Void)?

    var reachability: SCNetworkReachability
    var flags: SCNetworkReachabilityFlags = []

    /// Creates an instance of 'Reachability' object associated with specified host
    ///
    /// - Parameters:
    ///   - host: The host to be used to determine reachability
    ///   - listener: The block that will be invoked every time reachability changed
    public init?(host: String, listener: ((Reachability) -> Void)? = nil) {

        guard let reachability = SCNetworkReachabilityCreateWithName(nil, host) else {
            return nil
        }

        self.listener = listener
        self.reachability = reachability
    }
    
    deinit {
        stopListening()
    }

    func updateFlags(_ flags: SCNetworkReachabilityFlags) {
        self.flags = flags
        listener?(self)
    }

    /// Start listening for reachability changes. Change handler block will be called once upon successfull start
    ///
    /// - Parameter queue: The queue to dispatch change handler block
    /// - Returns: Returns true when successfully started listening for reachability changes
    @discardableResult
    public func startListening(queue: DispatchQueue = DispatchQueue.main) -> Bool {
        
        if isListening { return true }

        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        context.info = Unmanaged.passUnretained(self).toOpaque()

        guard SCNetworkReachabilitySetCallback(reachability, reachabilityCallback, &context) else {
            return false
        }

        guard SCNetworkReachabilitySetDispatchQueue(reachability, queue) else {
            stopListening()
            return false
        }

        guard SCNetworkReachabilityGetFlags(reachability, &flags) else {
            stopListening()
            return false
        }

        isListening = true

        queue.async {
            self.listener?(self)
        }

        return true
    }

    /// Stop listening for reachability changes of the specified host
    public func stopListening() {
        SCNetworkReachabilitySetCallback(reachability, nil, nil)
        SCNetworkReachabilitySetDispatchQueue(reachability, nil)
        isListening = false
    }

}

func reachabilityCallback(reachability: SCNetworkReachability, flags: SCNetworkReachabilityFlags, info: UnsafeMutableRawPointer?) {
    guard let info = info else { return }
    Unmanaged<Reachability>.fromOpaque(info).takeUnretainedValue().updateFlags(flags)
}

extension SCNetworkReachabilityFlags {

    /// The specified host can be reached using the current network configuration.
    var isHostReachable: Bool {
        return contains(.reachable)
    }

    /// The connection to the specified host must be established first.
    var isConnectionRequired: Bool {
        return contains(.connectionRequired)
    }

    /// A connection to the specified host can be established automatically without user interaction.
    var isConnectsAutomatically: Bool {
        return (contains(.connectionOnDemand) || contains(.connectionOnTraffic)) && !contains(.interventionRequired)
    }
}
