//
//  ImportRoot.swift
//  GammarTeacher
//
//  Created by Renjun Li on 2025/12/18.
//


import Foundation
import SwiftData

// 定义与 JSON 文件结构匹配的中间层 Struct (DTO)
struct ImportRoot: Codable {
    let data: ImportDataWrapper
}

struct ImportDataWrapper: Codable {
    let itemList: [ImportItem]
}

struct ImportItem: Codable {
    let itemId: String
    let word: String
    let trans: String
    let usphone: String?
    let ukphone: String?
    let createTime: String?
}

// 导入管理器
@MainActor
class JSONImporter {
    static let shared = JSONImporter()
    
    private init() {}
    
    /// 导入 JSON 文件到 SwiftData
    /// - Parameters:
    ///   - url: JSON 文件路径
    ///   - modelContext: SwiftData 上下文
    /// - Returns: (成功导入数量, 跳过重复数量)
    func importJSON(from url: URL, into modelContext: ModelContext) throws -> (Int, Int) {
        // 1. 读取文件
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        
        // 2. 解析 JSON
        let root = try decoder.decode(ImportRoot.self, from: data)
        let items = root.data.itemList
        
        var successCount = 0
        var skipCount = 0
        
        // 3. 遍历并插入
        for item in items {
            let spelling = item.word.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 检查数据库中是否已存在该单词 (查重)
            let descriptor = FetchDescriptor<WordItem>(
                predicate: #Predicate { $0.spelling == spelling }
            )
            
            if let existingCount = try? modelContext.fetchCount(descriptor), existingCount > 0 {
                skipCount += 1
                continue
            }
            
            // 格式化日期 (JSON中的格式: 2025-12-18T12:10:22.026+0000)
            // 这里简单起见直接用当前时间，或者你可以写个 DateFormatter 解析字符串
            
            // 创建新对象
            let newWord = WordItem(
                spelling: spelling,
                chineseDefinition: item.trans,
                originalId: item.itemId
            )
            
            modelContext.insert(newWord)
            successCount += 1
        }
        
        // 4. 保存更改
        // SwiftData 通常会自动保存，但显式调用更安全
        try? modelContext.save()
        
        return (successCount, skipCount)
    }
}
