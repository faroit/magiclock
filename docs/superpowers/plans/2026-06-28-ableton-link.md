# Ableton Link Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Ableton Link as a haptic beat source for Magiclock while keeping MIDI Clock behavior.

**Architecture:** Vendor Ableton Link, expose the needed C++ API through a small C bridge, and keep Link beat scheduling in testable Swift core code. AppDelegate only coordinates menu state, defaults, haptics, and display.

**Tech Stack:** SwiftPM, Swift 5.9, C++17, Ableton Link, AppKit, CoreMIDI, IOKit.

---

### Task 1: Test Link Beat Scheduling

**Files:**
- Create: `Sources/MagiclockCore/LinkBeatScheduler.swift`
- Create: `Tests/MagiclockCoreTests/LinkBeatSchedulerTests.swift`
- Modify: `Package.swift`

- [ ] Add a `MagiclockCore` library target and a `MagiclockCoreTests` test target.
- [ ] Write tests that prove the scheduler ignores the initial sample, triggers once when crossing into a new integer beat, ignores repeated samples in the same beat, and resets while paused.
- [ ] Run `swift run MagiclockCoreTestRunner` and confirm the new tests fail because the scheduler does not exist yet.
- [ ] Implement the scheduler.
- [ ] Run `swift run MagiclockCoreTestRunner` and confirm the scheduler tests pass.

### Task 2: Add Ableton Link Bridge

**Files:**
- Create: `Sources/AbletonLinkBridge/include/AbletonLinkBridge.h`
- Create: `Sources/AbletonLinkBridge/AbletonLinkBridge.cpp`
- Modify: `Package.swift`
- Create: `Vendor/AbletonLink/...`

- [ ] Copy Ableton Link headers, ASIO standalone headers, and license files into `Vendor/AbletonLink`.
- [ ] Add an `AbletonLinkBridge` C++ target with `LINK_PLATFORM_UNIX=1`, `LINK_PLATFORM_MACOSX=1`, and C++17.
- [ ] Implement opaque bridge functions for create, destroy, enable, start/stop sync, peer count, clock micros, session state creation, session capture, tempo, beat, phase, and playing state.
- [ ] Run `swift run MagiclockCoreTestRunner` to verify the bridge compiles and links.

### Task 3: Add Swift Link Clock Service

**Files:**
- Create: `Sources/MagiclockCore/AbletonLinkClock.swift`
- Modify: `Tests/MagiclockCoreTests/LinkBeatSchedulerTests.swift`

- [ ] Wrap bridge pointers in a Swift `AbletonLinkClock` class.
- [ ] Poll Link on a main-run-loop timer.
- [ ] Feed snapshots into `LinkBeatScheduler`.
- [ ] Expose `onBeat` and `onStatusChange` closures.
- [ ] Run `swift run MagiclockCoreTestRunner`.

### Task 4: Wire AppDelegate

**Files:**
- Modify: `magiclock/AppDelegate.swift`
- Modify: `Package.swift`

- [ ] Make the executable depend on `MagiclockCore`.
- [ ] Add `Use Ableton Link` and `Link Peers` menu items.
- [ ] Store Link enablement in user defaults.
- [ ] Start Link polling at launch and apply the saved enablement.
- [ ] Route Link beats to the existing haptic/icon behavior.
- [ ] Ignore MIDI beat haptics when Link is enabled.
- [ ] Display Link BPM when Link mode is active.

### Task 5: Update License and Docs

**Files:**
- Modify: `LICENSE`
- Modify: `README.md`

- [ ] Replace the MIT license text with GPLv2+ project licensing.
- [ ] Document Ableton Link as a supported beat source.
- [ ] Document GPLv2+ Link licensing and vendored source attribution.
- [ ] Run `swift run MagiclockCoreTestRunner` and `swift build`.
