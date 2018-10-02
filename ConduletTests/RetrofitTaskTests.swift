//
//  RetrofitTaskTests.swift
//  ConduletTests
//
//  Created by Zalkin, Natan on 02/10/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

import Quick
import Nimble
import Mockingjay
import SwiftProtobuf

@testable import Condulet

class RetrofitTaskTests: QuickSpec, TaskRetrofitting {

    var shouldIntercept: Bool = false
    var interceptHandler: (() -> Error?)?

    var isConfiguredRequest: Bool = false
    var isRequestedIntercept: Bool = false

    func configure(request: inout URLRequest) throws {
        isConfiguredRequest = true
    }

    func shouldIntercept(response: URLResponse) -> Bool {
        isRequestedIntercept = true
        return shouldIntercept
    }

    func handle(response: URLResponse, completion: @escaping (Error?) -> Void) {
        completion(interceptHandler?())
    }


    struct Test: Codable {

        let data: String
    }

    override func spec() {

        describe("RetrofitTask") {

            afterEach {
                self.removeAllStubs()
            }

            it("can perform request") {

                self.stub(http(.get, uri: "test.test"), json(["test": "ok"]))

                waitUntil { (done) in

                    RetrofitTask()
                        .endpoint(.GET, "test.test")
                        .data { (data, response) in
                            done()
                        }
                        .error { (error, response) in
                            fail("\(error)")
                        }
                        .perform()

                }
            }

            it("can cancel request") {

                self.stub(http(.get, uri: "test.cancel"), delay: 2, http(200))

                var canceled = false

                waitUntil(timeout: 5) { (done) in

                    let task = RetrofitTask()
                        .endpoint(.GET, "test.cancel")
                        .response { (content, response) in
                            if canceled {
                                done()
                            }
                            else {
                                fail("Response received!")
                            }
                        }
                        .error { (error, response) in
                            fail("Error received: \(error)")
                        }
                        .perform()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        if task.cancel() {
                            canceled = true
                            task.rewind()
                        }
                        else {
                            fail("Task is failed to cancel!")
                        }
                    }
                }
            }

            context("Retrofitting") {

                afterEach {
                    self.isConfiguredRequest = false
                    self.isRequestedIntercept = false
                    self.interceptHandler = nil
                    self.removeAllStubs()
                }

                it("use retrofitter") {

                    self.stub(http(.get, uri: "test.test"), json(["test": "ok"]))

                    waitUntil { (done) in

                        RetrofitTask(retrofitter: self)
                            .endpoint(.GET, "test.test")
                            .data { (data, response) in
                                expect(self.isConfiguredRequest).to(beTrue())
                                expect(self.isRequestedIntercept).to(beTrue())
                                done()
                            }
                            .error { (error, response) in
                                fail("\(error)")
                            }
                            .perform()
                    }
                }

                it("intercept response") {

                    self.stub(http(.get, uri: "test.test"), json(["test": "ok"]))

                    self.shouldIntercept = true

                    var isResponseIntercepted = false

                    self.interceptHandler = { [weak self] () -> Error? in
                        isResponseIntercepted = true
                        self?.shouldIntercept = false
                        return nil
                    }

                    waitUntil(timeout: 5) { (done) in

                        RetrofitTask(retrofitter: self)
                            .endpoint(.GET, "test.test")
                            .data { (data, response) in
                                expect(isResponseIntercepted).to(beTrue())
                                done()
                            }
                            .error { (error, response) in
                                fail("\(error)")
                            }
                            .perform()
                    }
                 }

            }
        }
    }
}
