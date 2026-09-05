# Gemini Master Build Prompt — RC SOW v20.0.0

Open and repair/build the **existing RC SOW Connected Flutter v20.0.0 source in this directory**.

Use `GEMINI.md` as binding project instructions. Start by reading the required project docs and build workflow, then inspect the repository status. The prior publication context is branch `rc-sow-connected-v20.0.0`, commit `d848a24`, and failed Green Gate run `33842027327`; if GitHub logs are accessible, inspect that run and identify the exact failing job and step.

Do **not** regenerate the application, remove features, weaken tests, or bypass security. Preserve the 60-route connected workflow, Material 3 Expressive UI, Supabase boundary, roof drafting engine, inventory/transfers, team/community, finance/approvals, messaging, work logs, projections, live map, admin and accessibility features.

Proceed through diagnosis → surgical repair → deterministic verification. Do not stop after merely proposing a plan. Make the required source changes, then execute the Green Gate:

```bash
flutter create --platforms=android,web --project-name=rc_sow_connected --org=org.jamaicaredcross .
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter build web --release
flutter build apk --release
```

If the operator asks for Android App Bundle, also run:

```bash
flutter build appbundle --release
```

If Flutter cannot run on the current host, still complete all safe source-level diagnosis/repair available, validate structure, and prepare the repository so the existing GitHub Green Gate can perform the native build. Clearly distinguish source validation from a real compiled artifact.

Do not embed secrets. Do not change the Android identity or Supabase production boundary unless the source itself proves a mismatch that must be repaired.

Finish with a concise build report containing root cause, changed files, commands/results, artifact paths, remaining external blockers, and a suggested commit message.
