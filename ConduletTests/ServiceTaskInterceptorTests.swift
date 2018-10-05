//
//  ServiceTaskInterceptorTests.swift
//  ConduletTests
//
//  Created by Natan Zalkin on 05/10/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

import Quick
import Nimble
import Mockingjay
import SwiftProtobuf

@testable import Condulet

class ServiceTaskInterceptorTests: QuickSpec, ServiceTaskInterception {

    enum Errors: Error {
        case test
    }

    var responseHandler: ((ServiceTask) throws -> Bool)?
    var contentHandler: ((ServiceTask) throws -> Bool)?
    var errorHandler: ((ServiceTask) -> Bool)?

    var shouldFailRequest = false
    var shouldFailResponse = false
    var shouldFailContent = false


    func serviceTask(_ task: ServiceTask, modify request: inout URLRequest) throws {
        request.url = URL(string: "test.modified")
        if shouldFailRequest { throw Errors.test }
    }

    func serviceTask(_ task: ServiceTask, intercept respone: URLResponse?) throws -> Bool {
        if shouldFailResponse { throw Errors.test }
        return try responseHandler?(task) ?? false
    }

    func serviceTask(_ task: ServiceTask, intercept content: ServiceTask.Content?) throws -> Bool {
        if shouldFailContent { throw Errors.test }
        return try contentHandler?(task) ?? false
    }

    func serviceTask(_ task: ServiceTask, intercept error: Error) -> Bool {
        return errorHandler?(task) ?? false
    }

    override func spec() {

        describe("ServiceTaskInterception") {

            afterEach {
                self.shouldFailRequest = false
                self.shouldFailResponse = false
                self.shouldFailContent = false
                self.responseHandler = nil
                self.contentHandler = nil
                self.errorHandler = nil
                self.removeAllStubs()
            }

            it("can modify request") {

                self.stub(http(.get, uri: "test.modified"), json(["test": "ok"]))

                waitUntil { (done) in

                    ServiceTask(interceptor: self)
                        .endpoint(.GET, "test.test")
                        .content { (content, response) in
                            done()
                        }
                        .error { (error, response) in
                            fail("\(error)")
                        }
                        .perform()

                }
            }

            it("can fail request") {

                self.stub(http(.get, uri: "test.modified"), json(["test": "ok"]))
                self.shouldFailRequest = true

                waitUntil { (done) in

                    ServiceTask(interceptor: self)
                        .endpoint(.GET, "test.test")
                        .content { (content, response) in
                            fail("Request should return error!")
                        }
                        .error { (error, response) in
                            switch error {
                            case Errors.test:
                                done()
                            default:
                                fail("Request should return test error!")
                            }
                        }
                        .perform()

                }
            }

            it("can intercept error") {

                self.stub(http(.get, uri: "test.failed"), json(["test": "ok"]))

                waitUntil { (done) in

                    self.errorHandler = { (task) in
                        task.handleError(Errors.test)
                        return true
                    }

                    ServiceTask(interceptor: self)
                        .endpoint(.GET, "test.test")
                        .content { (content, response) in
                            fail("Request should return error!")
                        }
                        .error { (error, response) in
                            switch error {
                            case Errors.test:
                                done()
                            default:
                                fail("Request should return test error!")
                            }
                        }
                        .perform()

                }
            }

            it("can intercept response") {

                self.stub(http(.get, uri: "test.modified"), json(["test": "ok"]))

                waitUntil { (done) in

                    self.responseHandler = { (task) in
                        throw Errors.test
                    }

                    ServiceTask(interceptor: self)
                        .endpoint(.GET, "test.test")
                        .content { (content, response) in
                            fail("Request should return error!")
                        }
                        .error { (error, response) in
                            switch error {
                            case Errors.test:
                                done()
                            default:
                                fail("Request should return test error!")
                            }
                        }
                        .perform()

                }
            }

            it("can intercept content") {

                self.stub(http(.get, uri: "test.modified"), json(["test": "ok"]))

                waitUntil { (done) in

                    self.contentHandler = { (task) in
                        throw Errors.test
                    }

                    ServiceTask(interceptor: self)
                        .endpoint(.GET, "test.test")
                        .content { (content, response) in
                            fail("Request should return error!")
                        }
                        .error { (error, response) in
                            switch error {
                            case Errors.test:
                                done()
                            default:
                                fail("Request should return test error!")
                            }
                        }
                        .perform()

                }
            }
        }
    }
}
