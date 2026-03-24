# Product: LearningKit

Native macOS vocabulary trainer targeting power users and keyboard-centric learners.

## Core Concept
Combines forced spelling input (keyboard muscle memory), on-device LLM-powered definitions, and SM-2 spaced repetition to create an immersive, privacy-first vocabulary learning experience.

## Key Mechanics
- Users must type the full spelling of each word — no multiple choice
- Wrong answers trigger "punishment mode" (re-type 3x) before moving on
- AI generates structured definitions, example sentences, and synonyms via local LLM (Llama 3 on MLX)
- AI results are cached per word in SwiftData; lazy-loaded on first encounter
- SM-2 algorithm schedules reviews based on user self-grading (Again / Hard / Good / Easy)
- Sessions prioritize unreviewed words first, then overdue reviews, capped at 300 words

## Data Model
- Users import vocabulary from JSON files (e.g. Youdao, Kindle exports)
- All data stored locally in Application Support via SwiftData (no cloud sync)
- Words track: spelling, Chinese definition, AI-generated fields, SRS metrics (interval, ease factor, repetition count, next review date)

## Target Platform
- macOS only (Apple Silicon required for MLX acceleration)
- Keyboard-first interaction; minimal mouse usage during sessions
