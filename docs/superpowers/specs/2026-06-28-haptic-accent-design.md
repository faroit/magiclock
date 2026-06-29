# Haptic Accent Design

## Goal

Magiclock should make the first beat in a 4/4 bar feel more prominent while preserving normal beat haptics.

## Constraint

AppKit's public `NSHapticFeedbackPerformer` API does not expose numeric force or intensity. It only supports feedback patterns and timing. Magiclock therefore simulates accent intensity with pattern choice and a short double pulse.

## Behavior

- Normal beats continue to use a single `levelChange` tap.
- Downbeats are detected every four beats.
- A `Downbeat Accent` menu controls the simulated accent:
  - `Off`: downbeats feel the same as normal beats.
  - `Light`: downbeats use a different single haptic pattern.
  - `Strong`: downbeats use a short double pulse.
- Ableton Link uses a 4-beat quantum so the downbeat aligns to Link's bar phase.
- MIDI Clock counts quarter-note beats from reset/start and accents every fourth beat.

## Verification

`MagiclockCoreTestRunner` verifies beat-boundary detection and downbeat classification.
