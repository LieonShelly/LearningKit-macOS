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
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: WordItem.self)
    }
}
