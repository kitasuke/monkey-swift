import XCTest

import monkey_swiftTests

var tests = [XCTestCaseEntry]()
tests += monkey_swiftTests.allTests()
XCTMain(tests)