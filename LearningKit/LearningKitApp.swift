//
//  GammarTeacherApp.swift
//  GammarTeacher
//
//  Created by Renjun Li on 2025/12/15.
//

import SwiftUI
import SwiftData

@main
struct LearningKitApp: App {
    let container: ModelContainer
    
    init() {
        do {
            let schema = Schema([WordItem.self, SessionRecord.self])
            let config = ModelConfiguration(
                "LearningKit",
                schema: schema,
                url: LearningKitApp.storeURL,
                cloudKitDatabase: .none
            )
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            AppLogger.shared.error("SwiftData open failed: \(error). Attempting recovery...")
            container = LearningKitApp.attemptRecovery()
        }
    }
    
    static var storeURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("LearningKit", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent("LearningKit.store")
    }
    
    private static func attemptRecovery() -> ModelContainer {
        let storeURL = Self.storeURL
        let fm = FileManager.default
        
        for suffix in ["-wal", "-shm"] {
            let fileURL = URL(fileURLWithPath: storeURL.path + suffix)
            try? fm.removeItem(at: fileURL)
        }
        AppLogger.shared.warn("Removed WAL/SHM, retrying with main store file...")
        
        do {
            let schema = Schema([WordItem.self, SessionRecord.self])
            let config = ModelConfiguration(
                "LearningKit",
                schema: schema,
                url: storeURL,
                cloudKitDatabase: .none
            )
            let recovered = try ModelContainer(for: schema, configurations: [config])
            AppLogger.shared.info("Recovery succeeded — data preserved.")
            return recovered
        } catch {
            AppLogger.shared.error("WAL cleanup didn't help: \(error)")
        }
        
        let backupURL = storeURL.deletingLastPathComponent()
            .appendingPathComponent("LearningKit-backup-\(Int(Date.now.timeIntervalSince1970)).store")
        try? fm.copyItem(at: storeURL, to: backupURL)
        AppLogger.shared.warn("Old DB backed up to: \(backupURL.path)")
        
        for suffix in ["", "-wal", "-shm"] {
            try? fm.removeItem(at: URL(fileURLWithPath: storeURL.path + suffix))
        }
        
        do {
            let schema = Schema([WordItem.self, SessionRecord.self])
            let config = ModelConfiguration(
                "LearningKit",
                schema: schema,
                url: storeURL,
                cloudKitDatabase: .none
            )
            let fresh = try ModelContainer(for: schema, configurations: [config])
            AppLogger.shared.info("Created fresh database.")
            return fresh
        } catch {
            fatalError("Failed to create ModelContainer after all recovery attempts: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
