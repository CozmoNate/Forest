//
//  URLSerializationTests.swift
//  ConduletTests
//
//  Created by Natan Zalkin on 01/10/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

import Quick
import Nimble
import Mockingjay
import SwiftProtobuf

@testable import Condulet

class URLSerializationTests: QuickSpec {
    
    override func spec() {
        
        describe("URLSerialization") {
            
            it("can serialize dictionary and deserialize it back") {
                
                let dictionary = ["key": "value", "key2": "value2"]
                
                let data = try! URLSerialization.data(with: dictionary)
                let decoded = try! URLSerialization.dictionary(with: data)
                
                expect(decoded).to(equal(dictionary))
            }
        }
    }
}
