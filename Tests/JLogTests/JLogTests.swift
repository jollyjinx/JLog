    import XCTest

    @testable import Logging
    @testable import JLog

    final class JLogTests: XCTestCase {
        func testExample()
        {
            for level in JLog.Level.allCases
            {
                JLog.loglevel = level
                print("level now set to:\(level)")

                JLog.info("notice")
                JLog.info("info")
                JLog.warning("warning")
                JLog.error("error")
                JLog.debug("debug")
                JLog.trace("tracing")
            }

            XCTAssert(true)
        }
    }
