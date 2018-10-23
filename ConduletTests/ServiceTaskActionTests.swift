//
//  ServiceTaskActionTests.swift
//  Condulet
//
//  Created by Natan Zalkin on 23/10/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

import Quick
import Nimble

@testable import Condulet


class ServiceTaskActionTests: QuickSpec {

    override func spec() {

        describe("ServiceTaskAction") {

            it("have proper description") {

                expect(ServiceTaskAction.upload.description).to(equal("Upload"))
                expect(ServiceTaskAction.download(destination: URL(string: "test")!, resumeData: nil).description).to(equal("Download"))
                expect(ServiceTaskAction.perform.description).to(equal("Perform"))
            }
        }
    }
}

