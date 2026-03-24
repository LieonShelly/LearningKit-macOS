//
//  SessionRecord.swift
//  LearningKit
//

import Foundation
import SwiftData

/// Persists an unfinished review session so it can be resumed after app restart.
/// Only one active record should exist at a time.
@Model
final class SessionRecord {
    /// Ordered list of word spellings remaining in the queue (JSON-encoded [String])
    var remainingSpellings: String
    /// Total number of words when the session originally started
    var totalCount: Int
    /// Timestamp when the session was created
    var createdAt: Date

    init(remainingSpellings: [String], totalCount: Int) {
        let data = (try? JSONEncoder().encode(remainingSpellings)) ?? Data()
        self.remainingSpellings = String(data: data, encoding: .utf8) ?? "[]"
        self.totalCount = totalCount
        self.createdAt = .now
    }

    /// Decode the remaining spellings array
    func decodedSpellings() -> [String] {
        guard let data = remainingSpellings.data(using: .utf8),
              let list = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return list
    }
}
