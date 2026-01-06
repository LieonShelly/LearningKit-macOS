//
//  ContentView 2.swift
//  GammarTeacher
//
//  Created by Renjun Li on 2025/12/18.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ContentView: View {
    @Query(sort: \WordItem.createdTime, order: .reverse) private var words: [WordItem]
    @Environment(\.modelContext) private var modelContext
    @State private var isImporting = false
    @State private var importResult: String = ""
    @State private var showingAlert = false
    @State private var isSelectingModel = false
    @State private var modelPath: String? = UserDefaults.standard.string(forKey: "modelPath")
    
    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading) {
                Text("Total Words: \(words.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                
                List(words) { word in
                    VStack(alignment: .leading) {
                        Text(word.spelling)
                            .font(.headline)
                        Text(word.chineseDefinition.replacingOccurrences(of: "\n", with: " "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 250, ideal: 300)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { isImporting = true }) {
                        Label("Import JSON", systemImage: "square.and.arrow.down")
                    }
                    .fileImporter(
                        isPresented: $isImporting,
                        allowedContentTypes: [.json],
                        allowsMultipleSelection: false
                    ) { result in
                        handleJSONImport(result: result)
                    }
                }
                ToolbarItem {
                    Button(action: clearAllData) {
                        Label("Clear All", systemImage: "trash")
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        PracticeView(wordsToPractice: words)
                    } label: {
                        Label("Start Session", systemImage: "play.fill")
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Button(action: { isSelectingModel = true }) {
                        Label("Select Model", systemImage: "cpu")
                    }
                    .fileImporter(
                        isPresented: $isSelectingModel,
                        allowedContentTypes: [.folder],
                        allowsMultipleSelection: false
                    ) { result in
                        handleModelSelection(result: result)
                    }
                }
            }
        } detail: {
            Text("Select a word to preview detail")
        }
        .alert("Import Status", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(importResult)
        }
    }
    
    private func clearAllData() {
        try? modelContext.delete(model: WordItem.self)
    }
    
    
    private func handleJSONImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            
            do {
                let (added, skipped) = try JSONImporter.shared.importJSON(from: url, into: modelContext)
                importResult = "Success: \(added) added, \(skipped) skipped (duplicates)."
                showingAlert = true
            } catch {
                importResult = "Error: \(error.localizedDescription)"
                showingAlert = true
            }
        case .failure(let error):
            importResult = "Import Failed: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func handleModelSelection(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else { return }
            let path = url.path(percentEncoded: false)
            modelPath = path
            UserDefaults.standard.set(path, forKey: "modelPath")
            url.stopAccessingSecurityScopedResource()
            print("Model path selected: \(path)") // Debug log
        case .failure(let error):
            print(error)
        }
    }
}
