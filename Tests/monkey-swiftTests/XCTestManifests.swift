import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(monkey_swiftTests.allTests),
    ]
}
#endif