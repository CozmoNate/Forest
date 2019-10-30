//
//  ServiceTaskRetrofitterTests.swift
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

class ServiceTaskRetrofitterTests: QuickSpec, ServiceTaskRetrofitting {

    enum Errors: Error {
        case test
    }

    var requestHandler: ((ServiceTask, inout URLRequest) throws -> Bool)?
    var responseHandler: ((ServiceTask) throws -> Bool)?
    var errorHandler: ((ServiceTask) throws -> Bool)?

    var shouldFailRequest = false
    var shouldFailResponse = false


    func shouldIntercept(request: inout URLRequest, for task: ServiceTask, with action: ServiceTaskAction) throws -> Bool {
        if shouldFailRequest { throw Errors.test }
        return try requestHandler?(task, &request) ?? false
    }

    func shouldIntercept(content: ServiceTaskContent, response: URLResponse, for task: ServiceTask) throws -> Bool {
        if shouldFailResponse { throw Errors.test }
        return try responseHandler?(task) ?? false
    }

    func shouldIntercept(error: Error, response: URLResponse?, for task: ServiceTask) throws -> Bool {
        return try errorHandler?(task) ?? false
    }

    override func spec() {

        describe("ServiceTaskRetrofitter") {

            afterEach {
                self.shouldFailRequest = false
                self.shouldFailResponse = false
                self.requestHandler = nil
                self.responseHandler = nil
                self.errorHandler = nil
                self.removeAllStubs()
            }

            it("can intercept request") {

                self.stub(http(.get, uri: "test.intercept.request"), json(["test": "ok"]))

                waitUntil { (done) in

                    self.requestHandler = { (task, request) in
                        request.url = URL(string: "test.intercept.request")
                        try task.sendRequest(request)
                        return true
                    }

                    ServiceTask(retrofitter: self)
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

                self.stub(http(.get, uri: "test.fail.request"), json(["test": "ok"]))
                self.shouldFailRequest = true

                waitUntil { (done) in

                    ServiceTask(retrofitter: self)
                        .endpoint(.GET, "test.fail.request")
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

                // No stub will fail

                waitUntil { (done) in

                    self.errorHandler = { (task) in
                        throw Errors.test
                    }

                    ServiceTask(retrofitter: self)
                        .endpoint(.GET, "test.failed")
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

                self.stub(http(.get, uri: "test.intercept.response"), json(["test": "ok"]))

                waitUntil { (done) in

                    self.responseHandler = { (task) in
                        throw Errors.test
                    }

                    ServiceTask(retrofitter: self)
                        .endpoint(.GET, "test.intercept.response")
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
