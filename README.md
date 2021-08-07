# JLog

Jollys simple logger for swift. 

It logs to ~/Library/Logs/<name>/<name>.log as well as STDERR 
It does logrotation
Loglevel can be changed.
It uses [swift-log](https://github.com/apple/swift-log) as well as [swift-log-format-and-pipe](https://github.com/Adorkable/swift-log-format-and-pipe) 


Example Usage:
```
Import Foundation
import JLog

JLog.notice("This is a notice")
JLog.debug("Hello Logging World")
```

For commandline utilities output looks like:

2021-08-07T19:17:12+02:00 ▶ debug ▶ /Users/jolly/Documents/GitHub/sma2mqtt/Sources/sma2mqtt/main.swift:182 ▶ channelRead(context:data:) ▶ 2021-08-07 17:17:12 +0000 Data: 608 from: [IPv4]10.112.16.195/10.112.16.195:46056 
2021-08-07T19:17:12+02:00 ▶ debug ▶ /Users/jolly/Documents/GitHub/sma2mqtt/Sources/sma2mqtt/SMA.swift:240 ▶ init(fromBinary:) ▶ Decoding SMAMulticastPacket
.
.
.

