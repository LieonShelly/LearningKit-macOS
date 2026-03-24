# Project Structure

## Architecture
MVVM pattern with Actor-based concurrency for AI tasks.

```
LearningKit/
├── LearningKitApp.swift    # @main entry point, SwiftData ModelContainer setup with recovery logic
├── Core/                   # Business logic and services
│   ├── AppLogger.swift     # Singleton file logger (DispatchQueue-based)
│   ├── GrammarEngine.swift # Actor — grammar correction via local LLM (legacy, not actively used in quiz flow)
│   ├── SRSLogic.swift      # Static SM-2 spaced repetition algorithm
│   ├── SoundManager.swift  # Singleton — NSSound effects + AVSpeechSynthesizer TTS
│   └── WordEngine.swift    # Actor — vocabulary explanation via local LLM (streaming AsyncStream)
├── Model/
│   └── WordItem.swift      # @Model entity — word data + SRS metrics + AI cache fields
├── View/
│   ├── ContentView.swift   # Main dashboard — word list, JSON import, model selection, log export
│   ├── PracticeView.swift  # Core quiz UI — ZStack layered (background, answer area, HUD)
│   ├── SRSButton.swift     # Reusable grading button with hover animation and keyboard shortcut
│   └── GradeButton.swift   # Simple grade button component
├── ViewModel/
│   └── QuizViewModel.swift # @Observable — state machine (idle→questioning→punishment→grading), review queue, AI bridge
└── Importer/
    └── JSONImporter.swift  # @MainActor singleton — JSON vocabulary import with dedup logic
```

## Conventions
- Actors for thread-safe LLM operations (`WordEngine`, `GrammarEngine`)
- Singletons for shared services (`SoundManager.shared`, `AppLogger.shared`, `JSONImporter.shared`)
- `@Observable` (Observation framework) for ViewModels, not `ObservableObject`/`@Published`
- `@Query` for SwiftData fetches in Views
- State machine pattern in QuizViewModel: `idle` → `questioning` → `punishment` / `grading`
- LLM output is streamed via `AsyncStream<String>`, parsed as JSON (`AIWordResponse`), and cached to SwiftData
- Llama 3 chat template format used for prompts (`<|begin_of_text|>`, `<|start_header_id|>`, etc.)
