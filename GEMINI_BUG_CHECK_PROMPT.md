# RC SOW v20.0.0 — Gemini Bug Check & Repair Pass

Use `GEMINI.md` as binding project instructions and read `GEMINI_BUG_AUDIT_2026-09-04.md` before editing.

Your job is to independently verify and repair the existing RC SOW Connected Flutter v20.0.0 source. Do not regenerate the app, remove routes/features, weaken tests, bypass RLS/auth, or replace real workflows with placeholders.

## Known CI evidence

- repository: `FOR3V3RLEARNG/RC_SOW_Flutter_v18_2_Fusion_Production`
- release branch context: `rc-sow-connected-v20.0.0`
- release commit: `d848a242e8d1eac6e2c6bdb60831faa6706c4d8c`
- failed Green Gate: `33842027327`
- runner: Flutter `3.47.2`
- checkout/setup/pub-get/format/analyze passed
- `flutter analyze`: no issues
- test result before cancellation: 224 passed, 2 failed
- confirmed failures were in `test/navigation_journeys_test.dart`

Two surgical repairs are already staged in this source:
1. `Work logs` navigation now uses the suite's scroll-aware real-hit-target helper.
2. `/admin/templates` uses a compact tonal icon action so the implied mobile back target remains hit-testable.

## Required verification sequence

1. Inspect Git status/diff and verify only intended changes are present.
2. Read the failed test definitions and the corresponding UI implementations.
3. Run targeted tests first:

```bash
flutter test test/navigation_journeys_test.dart
```

4. If targeted tests pass, run:

```bash
dart format lib test
flutter analyze
flutter test
flutter build web --release
flutter build apk --release
```

5. If Android signing/release configuration blocks the APK, report the exact external requirement; do not weaken release settings.
6. If requested, also run `flutter build appbundle --release`.
7. Inspect all warnings/errors. Fix root causes only.
8. Do not delete/skip/ignore tests or relax `WidgetController.hitTestWarningShouldBeFatal`.
9. Do not claim green until every required command exits 0 and expected artifacts exist.

## Secondary audit

After the known failures are resolved, inspect for:
- compact-phone app-bar action collisions
- inaccessible/off-screen controls that tests tap without `ensureVisible`
- navigation routes with missing back behavior
- RenderFlex/overflow risks at 390×844 and large text
- async context use after disposal
- duplicate writes / idempotency regressions
- local/offline state diverging from Supabase state
- unauthorized client-side access or secret leakage
- inconsistent lifecycle/inventory/payment state transitions
- stale callbacks or controls that visually appear enabled but do nothing

## Final report

Return:
- root causes confirmed
- files changed
- targeted test result
- full test result with pass count
- analyze result
- web/APK/AAB build result
- artifact paths
- any unresolved external requirement
- suggested commit message
