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
    func importJSON(from url: URL, into modelContext: ModelContext) throws -> (Int, Int) {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let root = try decoder.decode(ImportRoot.self, from: data)
        let items = root.data.itemList
        
        var successCount = 0
        var skipCount = 0
    
        for item in items {
            let spelling = item.word.trimmingCharacters(in: .whitespacesAndNewlines)
            
            let descriptor = FetchDescriptor<WordItem>(
                predicate: #Predicate { $0.spelling == spelling }
            )
            
            if let existingCount = try? modelContext.fetchCount(descriptor), existingCount > 0 {
                skipCount += 1
                continue
            }
            let newWord = WordItem(
                spelling: spelling,
                chineseDefinition: item.trans,
                originalId: item.itemId
            )
            
            modelContext.insert(newWord)
            successCount += 1
        }
        
        try? modelContext.save()
        
        return (successCount, skipCount)
    }
}
