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
    // MARK: - Core Identity
    // 设置 spelling 为 unique，防止同一个单词重复添加
    @Attribute(.unique) var spelling: String
    var createdTime: Date
    var originalId: String? // 对应 JSON 中的 itemId
    
    // MARK: - Imported Data (Basic Info)
    var chineseDefinition: String // 对应 JSON 中的 trans
    
    // MARK: - AI Context (For Step 4)
    // 这些字段初始为空，等待 AI 填充
    var aiExplanation: String? // AI 生成的简单英文释义
    var aiExampleSentence: String? // AI 生成的例句
    var aiSynonym: String?
    // MARK: - SRS Algorithm Data (For Step 3)
    // 默认值配置为“新单词”状态
    var nextReviewDate: Date = Date.now // 默认当前立即可背
    var lastReviewDate: Date?
    var interval: Double = 0.0 // 当前间隔（天）
    var easeFactor: Double = 2.5 // SM-2 算法默认难度系数
    var repetitionCount: Int = 0 // 连续正确次数
    var isMastered: Bool = false // 是否已完全掌握
    
    // MARK: - Init
    init(spelling: String, chineseDefinition: String, originalId: String? = nil, createdTime: Date = .now) {
        self.spelling = spelling
        self.chineseDefinition = chineseDefinition
        self.originalId = originalId
        self.createdTime = createdTime
    }
}
