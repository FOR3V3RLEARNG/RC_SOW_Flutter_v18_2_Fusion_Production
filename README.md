# RC SOW v20.4 Fusion Scalable Production

This source preserves the spacious v18.2 RC SOW UI framework while moving role experience, production modules, forms and update points into scalable registries and Supabase-managed configuration.

See `docs/SCALABLE_ARCHITECTURE.md` and `docs/PRODUCTION_UPDATE_PLAYBOOK.md`.

Premium Material 3 Flutter transformation of **RedCross ScopeWorks v16.0.1 BugChecked**, using the RC SOW Design DNA and the live RC-SOW Supabase backend.

## Fixes applied in this Fusion pass

- centered RC SOW login identity
- house/cross launcher icon and roof-repair `CustomPainter` splash
- Admin Dashboard guarded by both role **and** privilege; non-Admin stale privileges cannot reveal it
- live Supabase `default_privileges()` updated so only Admin receives `viewAdmin=true`
- Regional Supervisor and Construction Specialist keep `viewAllParishes=true` and see houses grouped by parish
- Scope contains **Beneficiary Print Out** as a subtab
- Control of Works contains **Notice of Completion** and **Payment Submission** in an organized close-out section
- all requested Control modules listed beneath Control of Works
- `+ New Control of Work` creates a synchronized `controlData` event
- pending role/parish selection survives sign-in and submits automatically for pending accounts
- Scope Draft and Submit for Approval persist to Supabase `scope` events
- messages open, mark read through `upsert_app_event`, and support compose
- map + live tracker are header mini-actions near notifications
- Active Users is a persistent bottom-right online action
- Settings adds reduced motion, high contrast, haptics, construction grid, snapping and measurement units
- roof math separates **Wall Height**, **Wall Plate → Ridge Rise**, and **Ridge Height from Ground**
- Supabase foreign-key indexes added and `supply_requests_read` RLS auth lookup optimized
- GitHub Green Gate builds **APK + AAB** using `checkout@v6` and `upload-artifact@v6`

## Backend

Project: `RC-SOW` (`gdvhekeupicllxkfctqw`). The mobile app embeds only the public/publishable Supabase client key. RLS and server-side RPC checks remain the security boundary.

The production database migration mirrored in `supabase/migrations/20260819_rcsow_v18_admin_scope_and_fk_indexes.sql` has already been applied through the connected Supabase project.

## Google OAuth

The Flutter app uses the deep-link callback:

`org.jamaicaredcross.rcsowflutter://login-callback`

Add that exact redirect URL to Supabase Auth → URL Configuration if it is not already allowed.

## Build

Push this source to the worker repository. The included workflow will generate Android platform files, apply the OAuth deep-link patch, resolve dependencies, generate icon/splash assets, analyze, test, build release APK + AAB, verify them, and upload both as one GitHub artifact.

Production Play signing should remain in CI secrets; do not commit keystores or `key.properties`.