//
//  WordEngine.swift
//  GammarTeacher
//
//  Created by Renjun Li on 2025/12/19.
//

import Foundation
import MLX
import MLXLLM
import MLXLMCommon
import Tokenizers

actor WordEngine {
    
    private var modelContainer: ModelContainer?
    
    var isReady: Bool { modelContainer != nil }
    
    func loadModel(from localPath: String) async throws {
        let modelDirectory = URL(fileURLWithPath: localPath)
        let configuration = ModelConfiguration(directory: modelDirectory)
        let container = try await LLMModelFactory.shared.loadContainer(configuration: configuration) { progress in
        }
        self.modelContainer = container
    }
    
    func explainWord(_ word: String) -> AsyncStream<String> {
        return AsyncStream { continuation in
            Task {
                guard let container = modelContainer else {
                    continuation.finish()
                    return
                }

                let prompt = buildVocabPrompt(word: word)
                
                let parameters = GenerateParameters(maxTokens: 512, temperature: 0.6)
                
                do {
                    let _ = try await container.perform { context in
                        let input = try await context.processor.prepare(input: .init(prompt: prompt))
                        var lastDecodedText = ""
                        
                        return try MLXLMCommon.generate(
                            input: input,
                            parameters: parameters,
                            context: context
                        ) { tokens in
                            if Task.isCancelled { return .stop }
                            let currentText = context.tokenizer.decode(tokens: tokens)
                            
                            let newText: String
                            if currentText.count > lastDecodedText.count {
                                let index = currentText.index(currentText.startIndex, offsetBy: lastDecodedText.count)
                                newText = String(currentText[index...])
                            } else {
                                newText = ""
                            }
                            lastDecodedText = currentText
                            
                            if newText.contains("<|eot_id|>") || newText.contains("<|end_of_text|>") {
                                return .stop
                            }
                            
                            if !newText.isEmpty {
                                continuation.yield(newText)
                            }
                            return .more
                        }
                    }
                } catch {
                    print("❌ Explain error: \(error)")
                }
                continuation.finish()
            }
        }
    }
    
    private func buildVocabPrompt(word: String) -> String {
            // 1. 修改模板：明确展示同义词应该用逗号连接，且包在一个引号内
            let jsonTemplate = """
            {
                "definition": "...",
                "example": "...",
                "synonym": "word1, word2"
            }
            """
            
            // 2. 修改指令：增加针对 Synonym 的格式限制
            let systemMessage = """
            You are a strict data extraction assistant. 
            Output JSON only.
            
            Rules:
            1. Output valid JSON exactly matching the template below.
            2. Keep the "definition" and "example" in simple, readable English.
            3. **CRITICAL**: Do not mention the word "\(word)" itself in the "definition" field. Use "It" or "The word" instead.
            4. **SYNONYM FORMAT**: Provide synonyms as a **single string** separated by commas. Do NOT output a JSON array. 
               - Correct: "synonym": "fast, quick"
               - Wrong: "synonym": "fast", "quick"
               - Wrong: "synonym": ["fast", "quick"]
            5. Format:
            \(jsonTemplate)
            """
            
            return """
            <|begin_of_text|><|start_header_id|>system<|end_header_id|>
            
            \(systemMessage)<|eot_id|><|start_header_id|>user<|end_header_id|>
            
            \(word)<|eot_id|><|start_header_id|>assistant<|end_header_id|>
            """
        }
}

struct AIWordResponse: Codable {
    let definition: String
    let example: String
    let synonym: String
}
