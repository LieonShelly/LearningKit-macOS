//
//  GrammarEngine.swift
//  GammarTeacher
//
//  Created by Renjun Li on 2025/12/15.
//

import Foundation
import MLX
import MLXLLM
import MLXLMCommon
import Tokenizers

actor GrammarEngine {
    
    private var modelContainer: ModelContainer?
    
    var isReady: Bool { modelContainer != nil }
    
    func loadModel(from localPath: String) async throws {
        let modelDirectory = URL(fileURLWithPath: localPath)
        let configuration = ModelConfiguration(directory: modelDirectory)
        let container = try await LLMModelFactory.shared.loadContainer(configuration: configuration) { progress in
        }
        self.modelContainer = container
    }
    
    func fixGrammar(for text: String) -> AsyncStream<String> {
        return AsyncStream { continuation in
            Task {
                guard let container = modelContainer else {
                    continuation.finish()
                    return
                }
                
                let prompt = buildLlama3Prompt(userText: text)
                let parameters = GenerateParameters(maxTokens: 100, temperature: 0.2)
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
                    print("Generation completed.")
                    
                } catch {
                    print("❌ Generation error: \(error)")
                }
                
                continuation.finish()
            }
        }
    }
    
    private func buildLlama3Prompt(userText: String) -> String {
        let systemMessage = """
            You are an expert English teacher. 
            First, provide the corrected version of the user's text in **Bold**.
            Second, analyze the mistakes briefly in a bulleted list.
            If the text is already correct, praise the user.
            """
        
        return """
            <|begin_of_text|><|start_header_id|>system<|end_header_id|>
            
            \(systemMessage)<|eot_id|><|start_header_id|>user<|end_header_id|>
            
            \(userText)<|eot_id|><|start_header_id|>assistant<|end_header_id|>
            """
    }
}
