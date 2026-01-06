//
//  PracticeView.swift
//  GammarTeacher
//
//  Created by Renjun Li on 2025/12/18.
//

import SwiftUI
import SwiftData

struct PracticeView: View {
    @State private var viewModel = QuizViewModel()
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("modelPath") var storedModelPath: String = ""
    var wordsToPractice: [WordItem]
    
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()
            topBar
            answerView
        }
        .onAppear {
            initializeSession()
        }
    }
    
    @ViewBuilder
    fileprivate func progressView() -> some View {
        if viewModel.sessionTotalCount > 0 && viewModel.currentState != .idle {
            Text("\(viewModel.currentProgressIndex) / \(viewModel.sessionTotalCount)")
                .font(.system(.title3, design: .monospaced))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
        }
    }
    
    @ViewBuilder
    fileprivate func speakingbtn() -> some View {
        Button(action: {
            SoundManager.shared.speak(viewModel.currentWord?.spelling ?? "")
        }) {
            Image(systemName: "speaker.wave.2.circle.fill")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .keyboardShortcut("s", modifiers: .command)
        .help("Cmd+S to Speak")
    }
    
    @ViewBuilder
    fileprivate func deleteBtn() -> some View {
        Button(action: {
            viewModel.deleteCurrentWord()
        }) {
            Image(systemName: "trash")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
        }
    }
    
    var topBar: some View {
        VStack {
            HStack {
                progressView()
                Spacer()
                if viewModel.currentState != .idle {
                    speakingbtn()
                    deleteBtn()
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
            Spacer()
        }
    }
    
    func wordInfoView(_ word: WordItem) -> some View {
        VStack(spacing: 16) {
            if let explanation = word.aiExplanation, !explanation.isEmpty {
                Text(explanation)
                    .font(.system(size: 38, weight: .medium, design: .serif))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            } else if viewModel.isGeneratingAI {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("AI Analyzing...")
                        .font(.title3)
                        .foregroundStyle(.tertiary)
                }
            }
            
            Text(word.chineseDefinition)
                .font(.system(size: 42, weight: .bold))
                .multilineTextAlignment(.center)
            if let example = word.aiExampleSentence, !example.isEmpty {
                Text(example)
                    .font(.system(size: 36, weight: .regular, design: .serif))
                    .italic()
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
        }
        .padding(.horizontal)
        .onTapGesture {
            SoundManager.shared.speak(word.spelling)
        }
        
    }
    
    func inputView(_ word: WordItem) -> some View {
        VStack(spacing: 20) {
            if viewModel.currentState == .punishment || viewModel.currentState == .grading {
                Text(word.spelling)
                    .font(.system(size:58, weight: .bold, design: .serif))
                    .foregroundStyle(viewModel.currentState == .punishment ? .red : .green)
                    .tracking(3)
                    .transition(.opacity.combined(with: .scale))
            } else {
                Text(" ")
                    .font(.system(size: 48))
            }
            if viewModel.currentState == .grading {
                HStack(spacing: 16) {
                    SRSButton(title: "Again", shortcut: "1", color: .red) {
                        viewModel.applyGrading(.again)
                        isInputFocused = true
                    }
                    SRSButton(title: "Hard", shortcut: "2", color: .orange) {
                        viewModel.applyGrading(.hard)
                        isInputFocused = true
                    }
                    SRSButton(title: "Good", shortcut: "3", color: .blue) {
                        viewModel.applyGrading(.good)
                        isInputFocused = true
                    }
                    SRSButton(title: "Easy", shortcut: "4", color: .green) {
                        viewModel.applyGrading(.easy)
                        isInputFocused = true}
                }
                .padding(.top, 10)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                ZStack(alignment: .bottom) {
                    TextField("", text: $viewModel.userInput)
                        .font(.system(size: 70, weight: .bold, design: .serif))
                        .multilineTextAlignment(.center)
                        .textFieldStyle(.plain)
                        .focused($isInputFocused)
                        .foregroundStyle(viewModel.currentState == .punishment ? .red : .primary)
                        .onSubmit { viewModel.submitAnswer() }
                    
                    Rectangle()
                        .frame(height: 4)
                        .foregroundStyle(borderColor)
                        .cornerRadius(2)
                }
                .frame(maxWidth: 500)
            }
        }
    }
    
    func punishmentView() -> some View {
        Text("Punishment: \(viewModel.punishmentCount) / \(viewModel.requiredRepetitions)")
            .font(.headline)
            .foregroundStyle(.red.opacity(0.8))
            .padding(8)
            .background(.red.opacity(0.1))
            .cornerRadius(8)
    }
    
    func idleView() -> some View {
        VStack(spacing: 30) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green.gradient)
                .symbolEffect(.bounce, value: viewModel.feedbackMessage)
            
            Text(viewModel.feedbackMessage.isEmpty ? "Ready to Review?" : "Session Complete!")
                .font(.system(size: 40, weight: .bold))
            
            if viewModel.feedbackMessage == "All due words reviewed!" {
                Text("Great job! Come back later.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            
            Button(action: {
                if viewModel.currentState == .idle && viewModel.feedbackMessage.isEmpty {
                    viewModel.startSession(context: modelContext)
                    isInputFocused = true
                } else {
                    dismiss()
                }
            }) {
                Text(viewModel.currentState == .idle && viewModel.feedbackMessage.isEmpty ? "Start Session" : "Back to List")
                    .font(.title2)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
        }
    }
    
    var answerView: some View {
        VStack {
            if let word = viewModel.currentWord {
                VStack(spacing: 40) {
                    wordInfoView(word)
                    inputView(word)
                    if viewModel.currentState == .punishment {
                        punishmentView()
                    }
                }
                .frame(maxWidth: 800, maxHeight: 1000)
            } else {
              idleView()
            }
        }
        
    }
    
    private func initializeSession() {
        if !storedModelPath.isEmpty {
            Task {
                await viewModel.loadModel(path: storedModelPath)
                viewModel.startSession(context: modelContext)
                isInputFocused = true
            }
        } else {
            viewModel.startSession(context: modelContext)
            isInputFocused = true
        }
    }
    
    var borderColor: Color {
        switch viewModel.currentState {
        case .punishment: return .red
        case .grading: return .green
        default: return .secondary.opacity(0.3)
        }
    }
}
