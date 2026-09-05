# RC SOW v20.0.0 — Gemini/CI Bug Audit — 4 Sep 2026

## Evidence inspected

Repository: `FOR3V3RLEARNG/RC_SOW_Flutter_v18_2_Fusion_Production`
Release branch context: `rc-sow-connected-v20.0.0`
Release commit: `d848a242e8d1eac6e2c6bdb60831faa6706c4d8c`
Failed Green Gate: `33842027327`
Runner Flutter: `3.47.2`

## Confirmed passing before test failure

- checkout
- Flutter setup
- platform scaffolding
- `flutter pub get`
- `dart format lib test`
- `flutter analyze` — **No issues found**

## Confirmed failures

### 1. Dashboard Work logs navigation test

`test/navigation_journeys_test.dart` attempted to tap `Work logs` using a finder restricted to widgets already hit-testable in the current viewport. On the compact 390×844 dashboard the shortcut exists but is below the currently visible scroll position, so the finder resolved to zero hit-testable widgets.

Repair: use the suite's existing `_tapScrollableText` helper, which first calls `ensureVisible`, then verifies and taps the real hit target. This preserves the real-pointer navigation requirement without requiring a scrollable dashboard shortcut to be above the fold.

### 2. Template Management compact app-bar back target

On `/admin/templates`, the app bar combined a long `NEW TEMPLATE` tonal button with the shared global actions. At compact width this consumed enough trailing toolbar space that the automatically implied `BackButton` was not hit-testable.

Repair: replace the wide app-bar text button with `IconButton.filledTonal` using tooltip `New template`. The action remains accessible while leaving compact-toolbar room for the back target.

## CI result that led to the patch

The failed run reported **224 tests passed, 2 failed** before shutdown/cancellation. Web and Android builds were skipped because the test gate did not pass.

## Local deterministic preflight after patch

- shell scripts: syntax pass
- YAML/JSON parsing: pass
- local relative Dart imports: pass
- obvious empty callbacks: none
- obvious embedded secret patterns: none

A new Flutter compile/test result is not claimed from this container because Flutter/Dart are not installed here. Re-run the GitHub Green Gate on Flutter 3.47.2 for authoritative verification.

## Gemini verification instruction

Have Gemini read `GEMINI.md` and this audit, inspect the two changed files, and then run the full deterministic gate. Gemini must not weaken or remove tests to obtain green status.
