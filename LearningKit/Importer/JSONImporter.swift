//
//  ImportRoot.swift
//  GammarTeacher
//
//  Created by Renjun Li on 2025/12/18.
//


import Foundation
import SwiftData

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


@MainActor
class JSONImporter {
    static let shared = JSONImporter()
    
    private init() {}
    
    /// 导入 JSON 文件到 SwiftData
    /// 导入 JSON 文件到 SwiftData
    func importJSON(from url: URL, into modelContext: ModelContext) throws -> (Int, Int) {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let root = try decoder.decode(ImportRoot.self, from: data)
        let items = root.data.itemList
        
        var successCount = 0 // 新增的数量
        var updateCount = 0  // 更新（原跳过）的数量
        
        for item in items {
            let spelling = item.word.trimmingCharacters(in: .whitespacesAndNewlines)
            var descriptor = FetchDescriptor<WordItem>(
                predicate: #Predicate { $0.spelling == spelling }
            )
            descriptor.fetchLimit = 1
            let formatter =  DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            let createTime = formatter.date(from: item.createTime ?? "") ?? Date.now
            if let existingWords = try? modelContext.fetch(descriptor),
               let existingWord = existingWords.first {
                existingWord.createdTime = createTime
                updateCount += 1
            } else {
                let newWord = WordItem(
                    spelling: spelling,
                    chineseDefinition: item.trans,
                    originalId: item.itemId,
                    createdTime: createTime
                )
                modelContext.insert(newWord)
                successCount += 1
            }
        }
        try modelContext.save()
        
        return (successCount, updateCount)
    }
}
