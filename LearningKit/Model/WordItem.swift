//
//  WordItem.swift
//  GammarTeacher
//
//  Created by Renjun Li on 2025/12/18.
//

import Foundation
import SwiftData

@Model
final class WordItem {
    @Attribute(.unique) var spelling: String
    var createdTime: Date
    var originalId: String?
    var chineseDefinition: String
    var aiExplanation: String?
    var aiExampleSentence: String?
    var aiSynonym: String?
    var nextReviewDate: Date = Date.now
    var lastReviewDate: Date?
    var interval: Double = 0.0
    var easeFactor: Double = 2.5
    var repetitionCount: Int = 0
    var isMastered: Bool = false
    
    init(spelling: String, chineseDefinition: String, originalId: String? = nil, createdTime: Date = .now) {
        self.spelling = spelling
        self.chineseDefinition = chineseDefinition
        self.originalId = originalId
        self.createdTime = createdTime
    }
}
