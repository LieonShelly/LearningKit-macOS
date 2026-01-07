//
//  SRSLogic.swift
//  GammarTeacher
//
//  Created by Renjun Li on 2025/12/19.
//


import Foundation

class SRSLogic {
    // 用户的评分等级
    enum Grade: Int {
        case again = 1 // 忘记/错误 (完全重来)
        case hard = 2  // 困难 (记得但很吃力)
        case good = 3  // 良好 (正常回忆)
        case easy = 4  // 简单 (秒回)
    }
    
    struct Result {
        let interval: Double // 新的间隔天数
        let easeFactor: Double // 新的难度系数
        let repetition: Int // 连续正确次数
    }
    
    /// 核心 SM-2 算法实现 间隔重复
    /// - Parameters:
    ///   - grade: 用户评分 (1-4)
    ///   - currentInterval: 当前间隔 (天)
    ///   - currentEaseFactor: 当前难度系数 (默认2.5)
    ///   - currentRepetition: 当前连续正确次数
    static func calculate(grade: Grade, currentInterval: Double, currentEaseFactor: Double, currentRepetition: Int) -> Result {
        
        var nextInterval: Double
        var nextEaseFactor: Double
        var nextRepetition: Int
        
        if grade == .again {
            // 如果选了 Again (或者拼写错误)，重置进度
            nextInterval = 0 // 立即或者1天后复习
            nextRepetition = 0
            nextEaseFactor = max(1.3, currentEaseFactor - 0.2) // 稍微降低难度因子
        } else {
            // 拼写正确，根据连续次数计算间隔
            switch currentRepetition {
            case 0:
                nextInterval = 1 // 第一次正确，间隔1天
            case 1:
                nextInterval = 6 // 第二次正确，间隔6天
            default:
                var modifier = 1.0
                if grade == .hard { modifier = 0.85 } // Hard 会让间隔增长慢一点
                if grade == .easy { modifier = 1.3 }  // Easy 会让间隔增长快一点
                
                nextInterval = ceil(currentInterval * currentEaseFactor * modifier)
            }
            
            nextRepetition = currentRepetition + 1
            let q = Double(grade.rawValue + 1) 
            let delta = 0.1 - (5.0 - q) * (0.08 + (5.0 - q) * 0.02)
            nextEaseFactor = max(1.3, currentEaseFactor + delta)
        }
        
        return Result(interval: nextInterval, easeFactor: nextEaseFactor, repetition: nextRepetition)
    }
}
