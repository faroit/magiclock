# Haptic Accent Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add adjustable simulated downbeat intensity for Magiclock haptics.

**Architecture:** Keep beat classification in `MagiclockCore` and haptic pattern selection in `AppDelegate`. Preserve existing MIDI and Link timing paths.

**Tech Stack:** SwiftPM, Swift, AppKit haptic feedback.

---

### Task 1: Core Beat Events

**Files:**
- Modify: `Sources/MagiclockCore/LinkBeatScheduler.swift`
- Modify: `Tests/MagiclockCoreTestRunner/main.swift`

- [ ] Add a failing test that expects beat 4 to be a downbeat and beat 5 to be regular.
- [ ] Add `BeatKind` and `LinkBeatEvent`.
- [ ] Add `consumeEvent(_:beatsPerBar:)` while preserving the existing boolean `consume(_:)`.
- [ ] Run `swift run MagiclockCoreTestRunner`.

### Task 2: App Haptic Accent

**Files:**
- Modify: `magiclock/AppDelegate.swift`
- Modify: `README.md`

- [ ] Add `Downbeat Accent` menu with `Off`, `Light`, and `Strong`.
- [ ] Persist the selected accent mode in `UserDefaults`.
- [ ] Route Link and MIDI downbeats through the selected accent pattern.
- [ ] Run `swift build` and `swift run MagiclockCoreTestRunner`.
