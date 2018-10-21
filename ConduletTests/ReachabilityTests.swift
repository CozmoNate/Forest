//
//  ReachabilityTests.swift
//  Condulet
//
//  Created by Zalkin, Natan on 21/10/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

import Quick
import Nimble

@testable import Condulet

class ReachabilityTests: QuickSpec {

    override func spec() {

        describe("Reachability") {

            it("can receive reachability changes") {
                waitUntil { (done) in

                    let reachability = Reachability(host: "no.such.a.host") { (reachability) in
                        expect(reachability.isConnectionRequired).to(beFalse())
                        expect(reachability.isConnectsAutomatically).to(beFalse())
                        expect(reachability.isHostReachable).to(beFalse())
                        reachability.stopListening()
                        expect(reachability.isListening).to(beFalse())
                        done()
                    }

                    expect(reachability?.startListening()).to(beTrue())
                    expect(reachability?.isListening).to(beTrue())
                }
            }
        }
    }
}
