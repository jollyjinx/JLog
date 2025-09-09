//
//  JLogTests.swift
//

import Foundation
import Testing
@testable import JLog
@testable import Logging

struct JLogTests
{
    @Test
    func testExample()
    {
        for level in JLog.Level.allCases
        {
            JLog.loglevel = level
            print("level now set to:\(level)")

            JLog.notice("notice")
            JLog.info("info")
            JLog.warning("warning")
            JLog.error("error")
            JLog.debug("debug")
            JLog.trace("tracing")
        }
    }


    @Test
    func testLogfilename()
    {
        print("logfilename:\( JLogLogfile.logFile )")
    }

    @Test
    func testLogfilenames()
    {
        print("logfilenames:\( JLogLogfile.existingLogfiles )") 
    }


}
