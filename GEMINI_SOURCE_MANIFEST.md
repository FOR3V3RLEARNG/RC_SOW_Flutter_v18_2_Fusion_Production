# RC SOW v20.0.0 — Gemini Source Manifest

This archive is the **existing RC SOW Connected Flutter v20.0.0 production source** augmented with Gemini CLI engineering context and launch helpers.

## Base source

- Original package: `RC_SOW_v20.0.0_Termux_Push_Kit.zip`
- Inner production source: `RC_SOW_Connected_Flutter_v20.0.0_Material3_Production_Source.zip`
- Release version in `pubspec.yaml`: `20.0.0+2000`
- Branch context: `rc-sow-connected-v20.0.0`
- Commit context: `d848a24`
- Failed Green Gate run context: `33842027327`

## Gemini additions

- `GEMINI.md` — binding project engineering context automatically loaded by Gemini CLI
- `GEMINI_BUILD_MASTER_PROMPT.md` — one-command implementation/build prompt
- `GEMINI_BUILD_RUNBOOK.md` — interactive, headless and Termux usage
- `.geminiignore` — excludes credentials and generated build output from Gemini context
- `tool/start_gemini_build.sh` — recommended interactive launch
- `tool/start_gemini_build_headless.sh` — autonomous launch for controlled/versioned workspaces

## Existing production content retained

- Flutter application under `lib/`
- test suite under `test/`
- GitHub Actions Green Gate under `.github/workflows/`
- Supabase schema/functions under `supabase/`
- product/backend/route verification docs under `docs/`
- 163 retained Stitch/design reference directories under `design_reference/`
- existing bootstrap/verification tooling under `tool/`

## Validation performed during packaging

- archive/source structure present
- 34 Dart source/test files retained
- pubspec, app entrypoint, Green Gate workflow and v20 Supabase migration present
- Gemini context/prompt/runbook/launch scripts present
- final ZIP integrity tested with `unzip -t`
- SHA-256 generated for final archive

A real Flutter analyzer/test/APK/web/AAB result is not claimed by this packaging environment because Flutter/Dart are not installed here. Gemini or GitHub Actions must run the native Green Gate on a compatible toolchain.
