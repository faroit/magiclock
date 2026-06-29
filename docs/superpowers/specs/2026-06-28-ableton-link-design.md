# Ableton Link Support Design

## Goal

Magiclock should be able to drive its haptic beat feedback from an Ableton Link session while preserving the existing MIDI Clock workflow.

## Architecture

Ableton Link is a C++ header-only library. Magiclock is Swift, so the integration uses a small C-compatible C++ bridge target that wraps the Link API needed by the app: enablement, peer count, clock time, app-thread session-state capture, tempo, beat, phase, and start/stop state.

The Swift app owns the user workflow. It keeps MIDI Clock support intact and adds an Ableton Link mode. When Link mode is enabled, MIDI clock ticks no longer trigger haptics; a Link polling service captures the current session state and fires haptics when the Link beat crosses an integer beat boundary.

## Components

- `Vendor/AbletonLink`: vendored GPLv2+ Ableton Link headers, ASIO standalone headers, and license files.
- `Sources/AbletonLinkBridge`: opaque C bridge over `ableton::Link`.
- `Sources/MagiclockCore`: Swift Link timing service and pure beat-crossing scheduler.
- `magiclock/AppDelegate.swift`: menu wiring, user defaults, haptic callback, and source selection between MIDI and Link.

## Behavior

- The menu contains a `Use Ableton Link` checkbox.
- When Link is enabled, Magiclock joins Link discovery and taps on Link beat boundaries.
- `Show BPM` displays the Link session tempo while Link mode is active and the MIDI-estimated BPM otherwise.
- MIDI virtual destination remains available, but MIDI beat haptics are ignored while Link mode is active to avoid double taps.
- Start/stop sync is enabled in the bridge. Link haptics require Link to be enabled and Link transport to be playing, so stop messages pause haptics and the next start resumes them.

## Licensing

Ableton Link is GPLv2+ unless a proprietary license is obtained from Ableton. This Link-enabled Magiclock distribution switches the project license to GPLv2+.

## Verification

- Unit tests cover Link beat-boundary scheduling without requiring a live Link peer.
- `swift run MagiclockCoreTestRunner` verifies the Swift scheduler and the C++ bridge build.
- `swift build` verifies the executable target links with the vendored Link source.
