//
//  ResponseHhandlerTests.swift
//  Condulet
//
//  Created by Natan Zalkin on 16/10/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

import Quick
import Nimble
import SystemConfiguration

@testable import Condulet

class ReachabilityTests: QuickSpec {

    override func spec() {

        describe("Reachability") {

            it("can receive reachability changes") {
                waitUntil { (done) in

                    var completion: (() -> Void)? = {
                        done()
                    }
                    
                    let reachability = Reachability(host: "apple.com") { (reachability) in
                        expect(reachability.isConnectionRequired).to(beFalse())
                        expect(reachability.isConnectsAutomatically).to(beFalse())
                        expect(reachability.isHostReachable).to(beTrue())
                        reachability.stopListening()
                        expect(reachability.isListening).to(beFalse())
                        completion?()
                        completion = nil // Once is enough
                    }

                    expect(reachability?.startListening()).to(beTrue())
                    expect(reachability?.isListening).to(beTrue())
                }
            }

            it("can update flags") {

                let reachability = Reachability(host: "apple.com")

                reachability?.updateFlags([.transientConnection])

                expect(reachability?.flags).to(equal([.transientConnection]))
            }
        }
    }
}
