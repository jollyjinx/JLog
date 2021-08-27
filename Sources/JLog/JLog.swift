//
//  JLog.swift
//  Quick i3
//
//  Created by Patrick Stein on 15.11.19.
//  Copyright © 2019 Jinx. All rights reserved.
//

import Foundation
import Logging
import LoggingFormatAndPipe

#if os(Linux)
fileprivate let kCFBundleNameKey = "CFBundleName"
#endif

class LogFile:TextOutputStream
{
    let handle:FileHandle
    let logExtension = "log"

    init?()
    {
        let appname         = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String ?? ProcessInfo.processInfo.processName
        let logDirectoryURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
                                .appendingPathComponent("Logs", isDirectory: true)
                                .appendingPathComponent("\(appname)", isDirectory: true)
        let baseLogfile     = logDirectoryURL
                                .appendingPathComponent("\(appname)", isDirectory: false)
        let logFilename     = baseLogfile
                                .appendingPathExtension(logExtension)

        Self.logrotate(baseLogFile:baseLogfile,logExtension:logExtension)



        do
        {
            try FileManager.default.createDirectory(at: logDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            FileManager.default.createFile(atPath: logFilename.path, contents: Data(), attributes:nil)

            handle = try FileHandle(forWritingTo: logFilename)
            handle.seekToEndOfFile()

            write("************************************************************************************************\n")
            write("************************************************************************************************\n")
        }
        catch
        {
            FileHandle.standardError.write("Can't log to \(logFilename) \(error)".data(using: .utf8)!)
            return nil
        }
    }

    deinit
    {
        try? handle.close()
    }


    class func logrotate(baseLogFile:URL,logExtension:String)
    {
        func filename(number:Int) -> URL { number == 0  ? baseLogFile.appendingPathExtension(logExtension)
                                                        : baseLogFile.appendingPathExtension(String(number)).appendingPathExtension(logExtension)
                                            }
        let fileManager = FileManager.default

        try? fileManager.removeItem(at: filename(number:9) )

        for number in (0...8).reversed()
        {
            if fileManager.fileExists(atPath: filename(number:number).path)
            {
                try? fileManager.moveItem(at: filename(number:number), to: filename(number:number+1))
            }
        }
    }

    func write(_ string: String)
    {
        handle.write(string.data(using: .utf8)!)
        try? handle.synchronize()
    }
}




public class JLog
{
    public typealias Level = Logger.Level

    static var _logger:LogHandler?

    public static var logger:LogHandler     {   get { return _logger ?? createLogger() }
                                                set { _logger = newValue }
                                            }
    public static var loglevel:Level        {   get { return Self.logger.logLevel }
                                                set { Self.logger.logLevel = newValue }
                                            }

    fileprivate static func createLogger() -> LogHandler
    {
        var handlers = [LogHandler]()

        let stdErrHandler = LoggingFormatAndPipe.Handler(formatter: BasicFormatter.adorkable, pipe: LoggerTextOutputStreamPipe.standardError)
        handlers.append(stdErrHandler)

        if let log = LogFile()
        {
            let pipe = LoggerTextOutputStreamPipe(log)
            let handler = LoggingFormatAndPipe.Handler(formatter: BasicFormatter.adorkable, pipe: pipe)

            handlers.append(handler)
        }

        var multiplexLogHandler = MultiplexLogHandler(handlers)
//        LoggingSystem.bootstrap(multiplexLogHandler)
//        var logger = Logger(label: "eu.jinx.Logger")
//        logger.logLevel = .trace
        #if DEBUG
            multiplexLogHandler.logLevel = .debug
        #else
            multiplexLogHandler.logLevel = .warning
        #endif
        _logger = multiplexLogHandler
        return multiplexLogHandler
    }

}











extension JLog {
    /// Log a message passing with the `Logger.Level.trace` log level.
    ///
    /// If `.trace` is at least as severe as the `Logger`'s `logLevel`, it will be logged,
    /// otherwise nothing will happen.
    ///
    /// - parameters:
    ///    - message: The message to be logged. `message` can be used with any string interpolation literal.
    ///    - metadata: One-off metadata to attach to this log message
    ///    - file: The file this log message originates from (there's usually no need to pass it explicitly as it
    ///            defaults to `#file`).
    ///    - function: The function this log message originates from (there's usually no need to pass it explicitly as
    ///                it defaults to `#function`).
    ///    - line: The line this log message originates from (there's usually no need to pass it explicitly as it
    ///            defaults to `#line`).
    @inlinable
    public static func trace(_ message: @autoclosure () -> Logger.Message = "",
                             metadata: @autoclosure () -> Logger.Metadata? = nil,
                             source: String = "all",
                             file: String = #file, function: String = #function, line: UInt = #line) {
        Self.logger.log(level: .trace, message: message(), metadata: metadata(), source:source,  file: file, function: function, line: line)
    }

    /// Log a message passing with the `Logger.Level.debug` log level.
    ///
    /// If `.debug` is at least as severe as the `Logger`'s `logLevel`, it will be logged,
    /// otherwise nothing will happen.
    ///
    /// - parameters:
    ///    - message: The message to be logged. `message` can be used with any string interpolation literal.
    ///    - metadata: One-off metadata to attach to this log message
    ///    - file: The file this log message originates from (there's usually no need to pass it explicitly as it
    ///            defaults to `#file`).
    ///    - function: The function this log message originates from (there's usually no need to pass it explicitly as
    ///                it defaults to `#function`).
    ///    - line: The line this log message originates from (there's usually no need to pass it explicitly as it
    ///            defaults to `#line`).
    @inlinable
    public static func debug(_ message: @autoclosure () -> Logger.Message = "",
                             metadata: @autoclosure () -> Logger.Metadata? = nil,
                             source: String = "all",
                             file: String = #file, function: String = #function, line: UInt = #line) {
        Self.logger.log(level: .debug, message: message(), metadata: metadata(), source:source,  file: file, function: function, line: line)
    }

    /// Log a message passing with the `Logger.Level.info` log level.
    ///
    /// If `.info` is at least as severe as the `Logger`'s `logLevel`, it will be logged,
    /// otherwise nothing will happen.
    ///
    /// - parameters:
    ///    - message: The message to be logged. `message` can be used with any string interpolation literal.
    ///    - metadata: One-off metadata to attach to this log message
    ///    - file: The file this log message originates from (there's usually no need to pass it explicitly as it
    ///            defaults to `#file`).
    ///    - function: The function this log message originates from (there's usually no need to pass it explicitly as
    ///                it defaults to `#function`).
    ///    - line: The line this log message originates from (there's usually no need to pass it explicitly as it
    ///            defaults to `#line`).
    @inlinable
    public static func info(_ message: @autoclosure () -> Logger.Message = "",
                            metadata: @autoclosure () -> Logger.Metadata? = nil,
                             source: String = "all",
                            file: String = #file, function: String = #function, line: UInt = #line) {
        Self.logger.log(level: .info, message: message(), metadata: metadata(), source:source,  file: file, function: function, line: line)
    }

    /// Log a message passing with the `Logger.Level.notice` log level.
    ///
    /// If `.notice` is at least as severe as the `Logger`'s `logLevel`, it will be logged,
    /// otherwise nothing will happen.
    ///
    /// - parameters:
    ///    - message: The message to be logged. `message` can be used with any string interpolation literal.
    ///    - metadata: One-off metadata to attach to this log message
    ///    - file: The file this log message originates from (there's usually no need to pass it explicitly as it
    ///            defaults to `#file`).
    ///    - function: The function this log message originates from (there's usually no need to pass it explicitly as
    ///                it defaults to `#function`).
    ///    - line: The line this log message originates from (there's usually no need to pass it explicitly as it
    ///            defaults to `#line`).
    @inlinable
    public static func notice(_ message: @autoclosure () -> Logger.Message = "",
                              metadata: @autoclosure () -> Logger.Metadata? = nil,
                             source: String = "all",
                              file: String = #file, function: String = #function, line: UInt = #line) {
        Self.logger.log(level: .notice, message: message(), metadata: metadata(), source:source,  file: file, function: function, line: line)
    }

    /// Log a message passing with the `Logger.Level.warning` log level.
    ///
    /// If `.warning` is at least as severe as the `Logger`'s `logLevel`, it will be logged,
    /// otherwise nothing will happen.
    ///
    /// - parameters:
    ///    - message: The message to be logged. `message` can be used with any string interpolation literal.
    ///    - metadata: One-off metadata to attach to this log message
    ///    - file: The file this log message originates from (there's usually no need to pass it explicitly as it
    ///            defaults to `#file`).
    ///    - function: The function this log message originates from (there's usually no need to pass it explicitly as
    ///                it defaults to `#function`).
    ///    - line: The line this log message originates from (there's usually no need to pass it explicitly as it
    ///            defaults to `#line`).
    @inlinable
    public static func warning(_ message: @autoclosure () -> Logger.Message = "",
                               metadata: @autoclosure () -> Logger.Metadata? = nil,
                             source: String = "all",
                               file: String = #file, function: String = #function, line: UInt = #line) {
        Self.logger.log(level: .warning, message: message(), metadata: metadata(), source:source,  file: file, function: function, line: line)
    }

    /// Log a message passing with the `Logger.Level.error` log level.
    ///
    /// If `.error` is at least as severe as the `Logger`'s `logLevel`, it will be logged,
    /// otherwise nothing will happen.
    ///
    /// - parameters:
    ///    - message: The message to be logged. `message` can be used with any string interpolation literal.
    ///    - metadata: One-off metadata to attach to this log message
    ///    - file: The file this log message originates from (there's usually no need to pass it explicitly as it
    ///            defaults to `#file`).
    ///    - function: The function this log message originates from (there's usually no need to pass it explicitly as
    ///                it defaults to `#function`).
    ///    - line: The line this log message originates from (there's usually no need to pass it explicitly as it
    ///            defaults to `#line`).
    @inlinable
    public static func error(_ message: @autoclosure () -> Logger.Message = "",
                             metadata: @autoclosure () -> Logger.Metadata? = nil,
                             source: String = "all",
                             file: String = #file, function: String = #function, line: UInt = #line) {
        Self.logger.log(level: .error, message: message(), metadata: metadata(),  source:source,  file: file, function: function, line: line)
    }

    /// Log a message passing with the `Logger.Level.critical` log level.
    ///
    /// `.critical` messages will always be logged.
    ///
    /// - parameters:
    ///    - message: The message to be logged. `message` can be used with any string interpolation literal.
    ///    - metadata: One-off metadata to attach to this log message
    ///    - file: The file this log message originates from (there's usually no need to pass it explicitly as it
    ///            defaults to `#file`).
    ///    - function: The function this log message originates from (there's usually no need to pass it explicitly as
    ///                it defaults to `#function`).
    ///    - line: The line this log message originates from (there's usually no need to pass it explicitly as it
    ///            defaults to `#line`).
    @inlinable
    public static func critical(_ message: @autoclosure () -> Logger.Message = "",
                                metadata: @autoclosure () -> Logger.Metadata? = nil,
                             source: String = "all",
                                file: String = #file, function: String = #function, line: UInt = #line) {
        Self.logger.log(level: .critical, message: message(), metadata: metadata(),  source:source,  file: file, function: function, line: line)
    }
}
