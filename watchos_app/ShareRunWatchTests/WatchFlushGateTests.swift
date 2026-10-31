import XCTest

@testable import ShareRunWatch

/// Overlapping flush. A Mac target compiles this against the watch module.
/// On Linux, `flush_gate_linux_check.swift` runs the same lock with `swiftc`.
final class WatchFlushGateTests: XCTestCase {
    func testSecondBeginIsRejectedUntilEnd() {
        var gate = WatchFlushGate()
        XCTAssertTrue(gate.tryBegin())
        XCTAssertFalse(gate.tryBegin())
        gate.end()
        XCTAssertTrue(gate.tryBegin())
    }
}
