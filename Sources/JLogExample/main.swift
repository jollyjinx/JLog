//
//  main.swift
//

import ArgumentParser
import Foundation
import JLog

struct JLogExample: ParsableCommand
{
    @Flag(name: .shortAndLong, help: "optional debug output")
    var debug: Int

    mutating func run() throws
    {
        if debug > 0
        {
            JLog.loglevel = debug > 1 ? .trace : .debug
        }

        JLog.notice("notice")
        JLog.info("info")
        JLog.warning("warning")
        JLog.error("error")
        JLog.debug("debug")
        JLog.trace("tracing")
    }
}

JLogExample.main()
