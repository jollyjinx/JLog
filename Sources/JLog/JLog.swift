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


class LogFile:TextOutputStream
{
    let handle:FileHandle

    init?()
    {
        let appname     = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
        let newlogname  = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("\(appname).log")

        Self.logrotate(logfilename: newlogname)

        do
        {
            FileManager.default.createFile(atPath: newlogname.path, contents: Data(), attributes:nil)

            handle = try FileHandle(forWritingTo: newlogname)
            handle.seekToEndOfFile()

            write("************************************************************************************************\n")
            write("************************************************************************************************\n")
        }
        catch
        {
            print("Can't log to \(newlogname) \(error)")
            return nil
        }
    }

    deinit
    {
        try? handle.close()
    }


    class func logrotate(logfilename:URL)
    {
        let fileManager = FileManager.default

        let lastfilename = logfilename.appendingPathExtension("9")
        try? fileManager.removeItem(at: lastfilename)

        for count in (1...8).reversed()
        {
            let currentfilename = logfilename.appendingPathExtension("\(count)")

            if  fileManager.fileExists(atPath: currentfilename.path)
            {
                let movetofilename  = logfilename.appendingPathExtension("\(count+1)")

                try? fileManager.moveItem(at: currentfilename, to: movetofilename)
            }
        }
        try? fileManager.moveItem(at: logfilename, to: logfilename.appendingPathExtension("1"))

    }

    func write(_ string: String)
    {
        handle.write(string.data(using: .utf8)!)
        try? handle.synchronize()
    }
}



public class JLog
{
    static var _logger:LogHandler?

    public static var logger:LogHandler { get { return _logger ?? createLogger() } }

    fileprivate static func createLogger() -> LogHandler
    {
        var handlers = [LogHandler]()

        let stdOutHandler = StreamLogHandler.standardError(label:"eu.jinx.Logger.stderr")
        handlers.append(stdOutHandler)

        if let log = LogFile()
        {
            let pipe = LoggerTextOutputStreamPipe(log)
            let handler = LoggingFormatAndPipe.Handler(formatter: BasicFormatter.adorkable, pipe: pipe)

            handlers.append(handler)
        }

        let multiplexLogHandler = MultiplexLogHandler(handlers)
//        LoggingSystem.bootstrap(multiplexLogHandler)
//        var logger = Logger(label: "eu.jinx.Logger")
//        logger.logLevel = .trace
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
                             file: String = #file, function: String = #function, line: UInt = #line) {
        Self.logger.log(level: .trace, message: message(), metadata: metadata(), file: file, function: function, line: line)
//        Self.logger.log(level: .trace, message: message(), metadata: metadata(), source: nil, file:file, function:function, line:line)
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
                             file: String = #file, function: String = #function, line: UInt = #line) {
        Self.logger.log(level: .debug, message: message(), metadata: metadata(),  file: file, function: function, line: line)
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
                            file: String = #file, function: String = #function, line: UInt = #line) {
        Self.logger.log(level: .info, message: message(), metadata: metadata(), file: file, function: function, line: line)
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
                              file: String = #file, function: String = #function, line: UInt = #line) {
        Self.logger.log(level: .notice, message: message(), metadata: metadata(), file: file, function: function, line: line)
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
                               file: String = #file, function: String = #function, line: UInt = #line) {
        Self.logger.log(level: .warning, message: message(), metadata: metadata(), file: file, function: function, line: line)
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
                             file: String = #file, function: String = #function, line: UInt = #line) {
        Self.logger.log(level: .error, message: message(), metadata: metadata(),  file: file, function: function, line: line)
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
                                file: String = #file, function: String = #function, line: UInt = #line) {
        Self.logger.log(level: .critical, message: message(), metadata: metadata(),  file: file, function: function, line: line)
    }
}
