# RC SOW v18.3.1 — Fusion Production Bug Audit

Target baseline: GitHub `main` at or after commit `67025ce3cba7092b4319f3d969b96dfc59303b1a`.

## Repaired functional regressions

- Restored real record creation for Work Plan, Document Checklist, Monitoring Checklist, Site Visits, Daily Site Log, Material Request, Consumables, Inventory, Notice of Completion, Payment Submission and Control of Work.
- Replaced free-text parish entry in production forms with role-aware Jamaica parish dropdowns.
- Added per-module document template download/share and production PDF/Excel export actions.
- Restored system/light/dark appearance and preserved Material 3 / minimal SaaS design profiles.
- Centralized Google OAuth callback through `SupabaseConfig.oauthRedirectUri`.
- Made the message drawer interactive: open a message, mark it read and reply without leaving the drawer.
- Filtered the Users Online surface to actual online-presence records and restored direct-message actions from the popup.
- Added an in-app Gmail inbox/detail/compose experience with reconnect handling.
- Hardened Admin user-management actions with error feedback and busy-state protection.
- Expanded Scope with Shelter Assessment beneficiary lookup, 14-parish selection policy, roof-plan/elevation drawing, wall stretches, drain indicators, digital signature, PDF/print/share and Excel export.
- Corrected File Picker v12 save-file calls and Excel/PDF dependency compatibility using `excel_plus`.

## CI hardening

- Green Gate remains the only workflow allowed to push canonical Dart formatting repairs.
- Production Factory formats only its isolated runner and never pushes, removing the previous two-workflow Git race.
- Added v18.3.1 source-contract checks for messaging, presence, Gmail, templates, exports, Scope, theme handling and real Control-of-Works module creation.
- Release artifact names now use v18.3.1.

## Backend alignment

The source includes an additive/idempotent Supabase alignment migration for document-template policies, beneficiary-directory scope, user-management authorization and all v18.3 production event visibility rules. The live Supabase project was audited and already contains the hardened equivalents; the migration is retained so source control documents the production contract.

## Evidence boundary

Local checks cover source structure, YAML, import targets and Fusion production contracts. Flutter/Dart compilation, analyzer, tests, Android builds and release artifacts remain authoritative only after the GitHub Green Gate and Production Factory pass.
