//
//  AppLogger.swift
//  LearningKit
//

import Foundation

final class AppLogger {
    static let shared = AppLogger()
    
    private let logFileURL: URL
    private let queue = DispatchQueue(label: "com.learningkit.logger", qos: .utility)
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return f
    }()
    
    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("LearningKit", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        logFileURL = dir.appendingPathComponent("LearningKit.log")
    }
    
    func log(_ message: String, level: String = "INFO", file: String = #file, line: Int = #line) {
        let timestamp = dateFormatter.string(from: Date.now)
        let fileName = (file as NSString).lastPathComponent
        let entry = "[\(timestamp)] [\(level)] [\(fileName):\(line)] \(message)\n"
        
        queue.async { [logFileURL] in
            if let data = entry.data(using: .utf8) {
                if FileManager.default.fileExists(atPath: logFileURL.path) {
                    if let handle = try? FileHandle(forWritingTo: logFileURL) {
                        handle.seekToEndOfFile()
                        handle.write(data)
                        handle.closeFile()
                    }
                } else {
                    try? data.write(to: logFileURL, options: .atomic)
                }
            }
        }
        
        #if DEBUG
        print(entry, terminator: "")
        #endif
    }
    
    func info(_ message: String, file: String = #file, line: Int = #line) {
        log(message, level: "INFO", file: file, line: line)
    }
    
    func warn(_ message: String, file: String = #file, line: Int = #line) {
        log(message, level: "WARN", file: file, line: line)
    }
    
    func error(_ message: String, file: String = #file, line: Int = #line) {
        log(message, level: "ERROR", file: file, line: line)
    }
    
    /// 返回日志文件 URL，用于导出
    var fileURL: URL { logFileURL }
    
    /// 读取全部日志内容
    func readAll() -> String {
        (try? String(contentsOf: logFileURL, encoding: .utf8)) ?? "(No logs yet)"
    }
    
    /// 清空日志
    func clear() {
        try? "".write(to: logFileURL, atomically: true, encoding: .utf8)
    }
}
