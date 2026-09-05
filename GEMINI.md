# RC SOW v20.0.0 — Gemini Engineering Context

You are the implementation engineer for the existing **RC SOW Connected Flutter v20.0.0** project.

## Primary rule

Work on this source tree in place. **Do not rebuild the app from scratch. Do not replace the architecture with a demo. Do not delete existing workflows, screens, routes, tests, Supabase contracts, design references, or production features just to make a build pass.** Repair root causes while preserving behavior.

## Release identity

- Product: RC SOW — Red Cross Scope of Work field operations platform
- Release: `20.0.0+2000`
- Flutter package: `rc_sow_connected`
- Android organization/package namespace base: `org.jamaicaredcross`
- Current release branch context: `rc-sow-connected-v20.0.0`
- Publication commit context supplied by the operator: `d848a24`
- Most recent Green Gate run context supplied by the operator: `33842027327` (failed)

Treat the source files in this archive as the implementation authority. The branch/commit/run identifiers are diagnostic context only; verify actual local Git metadata before changing anything.

## Product contract to preserve

Preserve all currently connected workflows described in `README.md`, especially:

- authentication, responsive shell, roles/parishes
- Dashboard → Scope → Control → Houses → More
- Scope House → Roof → Print → Files
- beneficiary lookup and auto-fill
- interactive roof drafting and geometry/history engine
- human-reviewed image-to-drawing proposals
- staged legacy import
- lifecycle/House Command/blockers/readiness/Smart Next Action
- work plans, daily logs, site visits, materials/consumables
- monitoring/document checklists
- parish/cluster/house inventory and transfers
- team assignments, community, recognition, awards and promotions
- production/finance/approval/HQ workspaces
- Control customization
- completion/final inspection/payment 46/31/23
- evidence/history/notifications/users online/messages
- work logs and weekly projections
- production board, analytics, live tracker map, settings/accessibility
- admin access, templates and Gmail compose UI
- local-first/offline queue semantics

## Architecture contract

Respect the existing feature boundaries:

- `lib/core/models.dart`
- `lib/core/app_state.dart`
- `lib/core/widgets.dart`
- `lib/core/production_models.dart`
- `lib/core/roof_drawing_controller.dart`
- `lib/services/production_backend.dart`
- `lib/screens/`
- `supabase/`
- `test/`
- `docs/`
- `design_reference/`

Prefer surgical fixes. Reuse the current design system and state model. Do not introduce a new state-management framework unless a demonstrated blocker makes it necessary.

## UI / design contract

Keep the RC SOW v20 Material 3 Expressive design language:

- Red Cross red as purposeful operational accent
- warm/comfortable tonal surfaces
- high field readability and large touch targets
- responsive phone/tablet/desktop layouts
- dark mode
- reduced-motion support
- semantic labels and accessible controls
- status colors paired with text meaning

Use `design_reference/` for parity when changing a screen. Do not blindly copy HTML; translate design intent into maintainable Flutter.

## Backend / security contract

- Never add service-role keys, OAuth client secrets, signing secrets, private keys, database passwords, or API keys to source or logs.
- Preserve RLS and protected server boundaries.
- Gemini/provider secrets must remain outside Flutter source.
- Preserve the local-first repository behavior when live credentials are unavailable.
- Do not weaken authentication or authorization to make tests pass.

## Required engineering sequence

1. Read `README.md`, `docs/VERIFICATION.md`, `docs/BACKEND_CONTRACT.md`, `docs/ROUTE_MATRIX.md`, `.github/workflows/green_gate.yml`, `pubspec.yaml`, and the relevant failing code before edits.
2. Inspect the current Git diff/status and preserve unrelated operator changes.
3. Reproduce the failure locally where the toolchain is available.
4. If GitHub access/logs are available, inspect failed workflow run `33842027327` and identify the exact failing job/step before changing code.
5. Fix the smallest root cause first.
6. Run formatting, analysis, tests, and builds after repairs.
7. Continue repairing until the deterministic gate is green or a genuine external credential/toolchain boundary is reached.
8. Never report success if any required gate failed.

## Deterministic Green Gate

Run, in this order:

```bash
flutter create --platforms=android,web --project-name=rc_sow_connected --org=org.jamaicaredcross .
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter build web --release
flutter build apk --release
```

Also run `bash tool/bootstrap_and_verify.sh` when appropriate and compare behavior with `.github/workflows/green_gate.yml`.

A build is green only when all required commands exit successfully and expected artifacts exist.

Expected artifacts:

- `build/web/`
- `build/app/outputs/flutter-apk/app-release.apk`

If the operator requests AAB, additionally run:

```bash
flutter build appbundle --release
```

and verify:

- `build/app/outputs/bundle/release/app-release.aab`

## Test discipline

Do not skip, disable, loosen, delete, or mark tests ignored just to obtain green CI. Existing tests intentionally cover routes, interactions, state transitions, roof drafting, offline behavior, and user journeys. If a test is wrong because the production contract changed, explain the mismatch and update both implementation and contract documentation coherently.

## Dependency discipline

- Prefer existing dependencies.
- Do not upgrade Flutter/Dart/packages casually while repairing a release build.
- If a dependency/tooling incompatibility is the root cause, make the smallest compatible change and document it.
- Keep `pubspec.lock` coherent with `pubspec.yaml`.

## Final response contract

At completion, report:

1. exact root cause(s)
2. files changed
3. tests/gates run with pass/fail status
4. artifact paths produced
5. unresolved external requirements, if any
6. suggested commit message

Do not claim APK/AAB/web success unless the artifact was actually produced by a successful command.
