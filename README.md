# JLog

Jollys simple logger for swift. 

It logs to ~/Library/Logs/<name>/<name>.log as well as STDERR 
It does logrotation
Loglevel can be changed.
It uses [swift-log](https://github.com/apple/swift-log) as well as [swift-log-format-and-pipe](https://github.com/Adorkable/swift-log-format-and-pipe) 


Example progam in Sources/JLogExample uses [ArgumentParser](https://github.com/apple/swift-argument-parser):

```
import Foundation
import ArgumentParser
import JLog

struct JLogExample: ParsableCommand
{
    @Flag(name: .shortAndLong, help: "optional debug output")
    var debug: Int

    mutating func run() throws
    {
        if debug > 0
        {
            JLog.loglevel =  debug > 1 ? .trace : .debug
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
```

For commandline utilities output looks like:

```
tin>swift 'build' -c release                                                                                                                                                           [0/0] Build complete!

tin>./.build/release/JLogExample
2021-08-07T19:59:11+02:00 ▶ warning ▶ /Users/jolly/Documents/GitHub/JLog/Sources/JLogExample/main.swift:19 ▶ run() ▶ warning
2021-08-07T19:59:11+02:00 ▶ error ▶ /Users/jolly/Documents/GitHub/JLog/Sources/JLogExample/main.swift:20 ▶ run() ▶ error

tin>./.build/release/JLogExample -d
2021-08-07T19:59:23+02:00 ▶ notice ▶ /Users/jolly/Documents/GitHub/JLog/Sources/JLogExample/main.swift:17 ▶ run() ▶ notice
2021-08-07T19:59:23+02:00 ▶ info ▶ /Users/jolly/Documents/GitHub/JLog/Sources/JLogExample/main.swift:18 ▶ run() ▶ info
2021-08-07T19:59:23+02:00 ▶ warning ▶ /Users/jolly/Documents/GitHub/JLog/Sources/JLogExample/main.swift:19 ▶ run() ▶ warning
2021-08-07T19:59:23+02:00 ▶ error ▶ /Users/jolly/Documents/GitHub/JLog/Sources/JLogExample/main.swift:20 ▶ run() ▶ error
2021-08-07T19:59:23+02:00 ▶ debug ▶ /Users/jolly/Documents/GitHub/JLog/Sources/JLogExample/main.swift:21 ▶ run() ▶ debug

tin>./.build/release/JLogExample -dd
2021-08-07T19:59:36+02:00 ▶ notice ▶ /Users/jolly/Documents/GitHub/JLog/Sources/JLogExample/main.swift:17 ▶ run() ▶ notice
2021-08-07T19:59:36+02:00 ▶ info ▶ /Users/jolly/Documents/GitHub/JLog/Sources/JLogExample/main.swift:18 ▶ run() ▶ info
2021-08-07T19:59:36+02:00 ▶ warning ▶ /Users/jolly/Documents/GitHub/JLog/Sources/JLogExample/main.swift:19 ▶ run() ▶ warning
2021-08-07T19:59:36+02:00 ▶ error ▶ /Users/jolly/Documents/GitHub/JLog/Sources/JLogExample/main.swift:20 ▶ run() ▶ error
2021-08-07T19:59:36+02:00 ▶ debug ▶ /Users/jolly/Documents/GitHub/JLog/Sources/JLogExample/main.swift:21 ▶ run() ▶ debug
2021-08-07T19:59:36+02:00 ▶ trace ▶ /Users/jolly/Documents/GitHub/JLog/Sources/JLogExample/main.swift:22 ▶ run() ▶ tracing
```
