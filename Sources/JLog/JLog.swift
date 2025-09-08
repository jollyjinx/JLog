//
//  JLog.swift
//

import Foundation
import Logging
import LoggingFormatAndPipe
import RegexBuilder
import Synchronization

#if os(Linux)
    private let kCFBundleNameKey = "CFBundleName"
#endif

public class JLogLogfile: TextOutputStream
{
    let handle: FileHandle


    public static var logfilePrefix:String
    {
        Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String
        ?? ProcessInfo.processInfo.processName
    }

    public static let logfileExtension = "log"

    public static var logDirectory:URL
    {
        var logDirectoryURL = URL(fileURLWithPath: ".")

        if let macLogDirectory = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first
        {
            logDirectoryURL = macLogDirectory
                    .appendingPathComponent("Logs", isDirectory: true)
                    .appendingPathComponent("\(logfilePrefix)", isDirectory: true)
        }
        return logDirectoryURL
    }

    public static var baseLogfile:URL
    {
        JLogLogfile.logDirectory.appendingPathComponent("\(logfilePrefix)", isDirectory: false)
    }
    public static var logFile:URL
    {
        return baseLogfile.appendingPathExtension(logfileExtension)
    }



    init?()
    {
        JLogLogfile.logrotate(baseLogFile: JLogLogfile.baseLogfile, logExtension: JLogLogfile.logfileExtension)

        do
        {
            try FileManager.default.createDirectory(at: JLogLogfile.logDirectory, withIntermediateDirectories: true,
                                                    attributes: nil)
            FileManager.default.createFile(atPath: JLogLogfile.logFile.path, contents: Data(), attributes: nil)

            handle = try FileHandle(forWritingTo: JLogLogfile.logFile)
            handle.seekToEndOfFile()

            write(
                "************************************************************************************************\n"
            )
            write(
                "************************************************************************************************\n"
            )
        }
        catch
        {
            FileHandle.standardError.write(
                "Can't log to \(JLogLogfile.logFile) \(error)".data(using: .utf8)!)
            return nil
        }
    }

    deinit
    {
        try? handle.close()
    }

    public static var existingLogfiles: [URL]
    {
        guard let enumerator = FileManager.default.enumerator(at:JLogLogfile.logDirectory ,includingPropertiesForKeys: [.isRegularFileKey],options: [.skipsHiddenFiles])
        else { return [] }

        var urls: [URL] = []

        for case let fileURL as URL in enumerator
            where       fileURL.pathExtension == JLogLogfile.logfileExtension
                    &&  fileURL.lastPathComponent.hasPrefix(JLogLogfile.logfilePrefix)
        {
            urls.append(fileURL)
        }
        return urls
    }

    static func logrotate(baseLogFile: URL, logExtension: String)
    {
        func filename(number: Int) -> URL
        {
            number == 0
                ? baseLogFile.appendingPathExtension(logExtension)
                : baseLogFile.appendingPathExtension(String(number))
                .appendingPathExtension(logExtension)
        }
        let fileManager = FileManager.default

        try? fileManager.removeItem(at: filename(number: 9))

        for number in (0 ... 8).reversed()
        {
            if fileManager.fileExists(atPath: filename(number: number).path)
            {
                try? fileManager.moveItem(at: filename(number: number),
                                          to: filename(number: number + 1))
            }
        }
    }

    public func write(_ string: String)
    {
        handle.write(string.data(using: .utf8)!)
        try? handle.synchronize()
    }
}

public class JLog
{
    public typealias Level = Logger.Level

    public static var loglevel: Logger.Level
    {
        get { logger.withLock { $0.logLevel } }
        set {
                switch newValue
                {
                    case .trace: logger.withLock({ $0.logLevel = .trace })
                    case .info: logger.withLock({ $0.logLevel = .info })
                    case .warning: logger.withLock({ $0.logLevel = .warning })
                    case .error: logger.withLock({ $0.logLevel = .error })
                    case .debug: logger.withLock({ $0.logLevel = .debug })
                    case .critical: logger.withLock({ $0.logLevel = .critical })
                    case .notice: logger.withLock({ $0.logLevel = .notice })
                }
            }
    }

    public static let lastPathComponentPattern = Mutex<Regex>(/\/([^\/]+)$/)
    public static let logger = Mutex<LogHandler>(
    {
        var handlers = [LogHandler]()

        let stdErrHandler = LoggingFormatAndPipe.Handler(formatter: BasicFormatter.adorkable,
                                                         pipe: LoggerTextOutputStreamPipe.standardError)
        handlers.append(stdErrHandler)

        if let log = JLogLogfile()
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
        return multiplexLogHandler
    }()
    )

}

public extension JLog
{
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
    static func trace(_ message: @autoclosure () -> Logger.Message = "",
                      metadata: @autoclosure () -> Logger.Metadata? = nil,
                      source: String = "all",
                      file: String = #file, function: String = #function, line: UInt = #line)
    {
        guard  loglevel <= .trace else { return }
        let lastPathComponent: String = lastPathComponentPattern.withLock {

            if let lastPathComponentSubstring = try? $0.firstMatch(in: file)?.1
            {
                return  String(lastPathComponentSubstring)
            }
            return file
        }

        Self.logger.withLock({$0.log(level: .trace, message: message(), metadata: metadata(),
                        source: source, file: lastPathComponent, function: function,
                        line: line)})
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
    static func debug(_ message: @autoclosure () -> Logger.Message = "",
                      metadata: @autoclosure () -> Logger.Metadata? = nil,
                      source: String = "all",
                      file: String = #file, function: String = #function, line: UInt = #line)
    {
        guard loglevel <= .debug else { return }
        let lastPathComponent: String = lastPathComponentPattern.withLock {

            if let lastPathComponentSubstring = try? $0.firstMatch(in: file)?.1
            {
                return  String(lastPathComponentSubstring)
            }
            return file
        }

        logger.withLock({ $0.log(level: .debug, message: message(), metadata: metadata(),
                        source: source, file: lastPathComponent, function: function,
                        line: line) })
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
    static func info(_ message: @autoclosure () -> Logger.Message = "",
                     metadata: @autoclosure () -> Logger.Metadata? = nil,
                     source: String = "all",
                     file: String = #file, function: String = #function, line: UInt = #line)
    {
        guard loglevel <= .info else { return }
        let lastPathComponent: String = lastPathComponentPattern.withLock {

            if let lastPathComponentSubstring = try? $0.firstMatch(in: file)?.1
            {
                return  String(lastPathComponentSubstring)
            }
            return file
        }

        logger.withLock({ $0.log(level: .info, message: message(), metadata: metadata(),
                        source: source, file: lastPathComponent, function: function,
                        line: line)})
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
    static func notice(_ message: @autoclosure () -> Logger.Message = "",
                       metadata: @autoclosure () -> Logger.Metadata? = nil,
                       source: String = "all",
                       file: String = #file, function: String = #function, line: UInt = #line)
    {
        guard loglevel <= .notice else { return }
        let lastPathComponent: String = lastPathComponentPattern.withLock {

            if let lastPathComponentSubstring = try? $0.firstMatch(in: file)?.1
            {
                return  String(lastPathComponentSubstring)
            }
            return file
        }

        logger.withLock({ $0.log(level: .notice, message: message(), metadata: metadata(),
                        source: source, file: lastPathComponent, function: function,
                        line: line)})
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
    static func warning(_ message: @autoclosure () -> Logger.Message = "",
                        metadata: @autoclosure () -> Logger.Metadata? = nil,
                        source: String = "all",
                        file: String = #file, function: String = #function, line: UInt = #line)
    {
        guard loglevel <= .warning else { return }
        let lastPathComponent: String = lastPathComponentPattern.withLock {

            if let lastPathComponentSubstring = try? $0.firstMatch(in: file)?.1
            {
                return  String(lastPathComponentSubstring)
            }
            return file
        }

        logger.withLock({ $0.log(level: .warning, message: message(), metadata: metadata(),
                        source: source, file: lastPathComponent, function: function,
                        line: line)})
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
    static func error(_ message: @autoclosure () -> Logger.Message = "",
                      metadata: @autoclosure () -> Logger.Metadata? = nil,
                      source: String = "all",
                      file: String = #file, function: String = #function, line: UInt = #line)
    {
        guard loglevel <= .error else { return }
        let lastPathComponent: String = lastPathComponentPattern.withLock {

            if let lastPathComponentSubstring = try? $0.firstMatch(in: file)?.1
            {
                return  String(lastPathComponentSubstring)
            }
            return file
        }

        logger.withLock({ $0.log(level: .error, message: message(), metadata: metadata(),
                        source: source, file: lastPathComponent, function: function,
                        line: line)})
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
    static func critical(_ message: @autoclosure () -> Logger.Message = "",
                         metadata: @autoclosure () -> Logger.Metadata? = nil,
                         source: String = "all",
                         file: String = #file, function: String = #function, line: UInt = #line)
    {
        guard loglevel <= .critical else { return }
        let lastPathComponent: String = lastPathComponentPattern.withLock {

            if let lastPathComponentSubstring = try? $0.firstMatch(in: file)?.1
            {
                return  String(lastPathComponentSubstring)
            }
            return file
        }

        logger.withLock({ $0.log(level: .critical, message: message(), metadata: metadata(),
                        source: source, file: lastPathComponent, function: function,
                        line: line)})
    }
}
