//
//  QuizViewModel.swift
//  GammarTeacher
//
//  Created by Renjun Li on 2025/12/18.
//

import SwiftUI
import SwiftData

@Observable
class QuizViewModel {
    enum SessionState {
        case idle
        case questioning
        case punishment
        case grading
    }
    
    private var reviewQueue: [WordItem] = []
    var context: ModelContext?
    var currentState: SessionState = .idle
    var currentWord: WordItem?
    var userInput: String = ""
    var punishmentCount: Int = 0
    let requiredRepetitions = 3
    var feedbackMessage: String = ""
    var aiOutputText: String = ""
    var isGeneratingAI: Bool = false
    private var engine = WordEngine()
    private var generationTask: Task<Void, Never>?
    
    var sessionTotalCount: Int = 0
    var currentProgressIndex: Int {
        return sessionTotalCount - reviewQueue.count
    }
    
    func startSession(context: ModelContext) {
        self.context = context
        
        do {
            let descriptor = FetchDescriptor<WordItem>()
            let allWords = try context.fetch(descriptor)
            let now = Date.now
            let newwords = allWords.filter { $0.lastReviewDate == nil }
                .sorted(by: {$0.createdTime > $1.createdTime })
            let dueWords = allWords.filter { $0.lastReviewDate != nil && $0.nextReviewDate <= now}
                .sorted(by: { $0.nextReviewDate < $1.nextReviewDate })
            let limit = 300
            var combinedQueue: [WordItem] = []
            combinedQueue.append(contentsOf: newwords)
            if combinedQueue.count < limit {
                let remainingSpace = limit - combinedQueue.count
                let wordsTodd = dueWords.prefix(remainingSpace)
                combinedQueue.append(contentsOf: wordsTodd)
            } else {
                combinedQueue = Array(combinedQueue.prefix(limit))
            }

            self.reviewQueue = combinedQueue
            self.sessionTotalCount = reviewQueue.count
            print("Session started. Due words: \(reviewQueue.count)")
            nextWord()
        } catch {
            print("Fetch failed: \(error)")
        }
    }
    
    func submitAnswer() {
        guard let word = currentWord else { return }
        let input = userInput.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let target = word.spelling.lowercased()
        
        switch currentState {
        case .questioning:
            if input == target {
                SoundManager.shared.playSuccess()
                currentState = .grading
                feedbackMessage = "Correct! Rate difficulty:"
            } else {
                SoundManager.shared.playError()
                enterPunishmentMode()
            }
            
        case .punishment:
            if input == target {
                SoundManager.shared.playSuccess()
                punishmentCount += 1
                userInput = ""
                
                if punishmentCount >= requiredRepetitions {
                    applyGrading(.again)
                }
            } else {
                SoundManager.shared.playError()
            }
            
        default: break
        }
    }
    
    func deleteCurrentWord() {
        if let currentWord {
            context?.delete(currentWord)
            try? context?.save()
        }
        nextWord()
    }
    
    func applyGrading(_ grade: SRSLogic.Grade) {
        guard let word = currentWord, let ctx = context else { return }
        
        let result = SRSLogic.calculate(
            grade: grade,
            currentInterval: word.interval,
            currentEaseFactor: word.easeFactor,
            currentRepetition: word.repetitionCount
        )
        
        word.interval = result.interval
        word.easeFactor = result.easeFactor
        word.repetitionCount = result.repetition
        if result.interval == 0 {
            word.nextReviewDate = Date.now
        } else {
            word.nextReviewDate = Date.now.addingTimeInterval(result.interval * 86400)
        }
        
        word.lastReviewDate = Date.now
        try? ctx.save()
        
        nextWord()
    }
    
    private func enterPunishmentMode() {
        currentState = .punishment
        userInput = ""
        punishmentCount = 0
        feedbackMessage = "Incorrect. Punishment Mode."
    }
    
    func loadModel(path: String) async {
        do {
            try await engine.loadModel(from: path)
            print("Model loaded successfully at \(path)")
        } catch {
            print("Failed to load model: \(error)")
        }
    }
    
    var isModelReady: Bool {
        get async { await engine.isReady }
    }
    
    private func nextWord() {
        generationTask?.cancel()
        
        guard !reviewQueue.isEmpty else {
            currentState = .idle
            feedbackMessage = "All due words reviewed!"
            currentWord = nil
            return
        }
        
        let next = reviewQueue.removeFirst()
        currentWord = next
        currentState = .questioning
        userInput = ""
        feedbackMessage = "Type the English word"
        punishmentCount = 0
        
        aiOutputText = ""
        
        if let cached = next.aiExplanation, !cached.isEmpty {
            aiOutputText = cached
        } else {
            startAIGeneration(for: next)
        }
    }
    
    private func startAIGeneration(for wordItem: WordItem) {
        generationTask = Task {
            isGeneratingAI = true
            
            await MainActor.run {
                aiOutputText = "🤖 AI analyzing..."
            }
            
            let ready = await engine.isReady
            guard ready else {
                await MainActor.run {
                    aiOutputText = ""
                    isGeneratingAI = false
                }
                return
            }
            
            var fullJSONString = ""
        
            for await segment in await engine.explainWord(wordItem.spelling) {
                if Task.isCancelled { return }
                fullJSONString += segment
            }
            

            
            if !Task.isCancelled && !fullJSONString.isEmpty {
                await MainActor.run {
                    let cleanJSON = cleanJSONString(fullJSONString)
                    if let data = cleanJSON.data(using: .utf8),
                       let result = try? JSONDecoder().decode(AIWordResponse.self, from: data) {
                        
                        wordItem.aiExplanation = result.definition
                        wordItem.aiExampleSentence = result.example
                        wordItem.aiSynonym = result.synonym
                        self.aiOutputText = result.definition
                        
                        try? context?.save()
                        
                    } else {
                        print("JSON Decode Failed. Raw output: \(fullJSONString)")
                        self.aiOutputText = "Could not generate structured data."
                    }
                    
                    isGeneratingAI = false
                }
            }
        }
    }
    
    private func cleanJSONString(_ input: String) -> String {
        var text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("```json") {
            text = String(text.dropFirst(7))
        } else if text.hasPrefix("```") {
            text = String(text.dropFirst(3))
        }
        
        if text.hasSuffix("```") {
            text = String(text.dropLast(3))
        }
        
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty && text.last != "}" {
            print("⚠️ JSON format warning: Missing closing brace. Attempting to fix.")
            text += "}"
        }
        
        return text
    }
}

extension String {
    var unescaped: String {
        let mutable = NSMutableString(string: self)
        CFStringTransform(mutable, nil, "Any-Hex/Java" as NSString, true)
        return mutable as String
    }
}
