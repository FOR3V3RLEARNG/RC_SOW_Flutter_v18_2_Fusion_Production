# RC SOW v20.4.1 — Production Readiness Status

## Completed source hardening

- Central role/product registry for scalable dashboards and module visibility.
- v18.2 spacious design-token contract and CI checks for restrained functional icon sizes.
- Role-aware Dashboard, Control and Community behavior.
- Admin governance quick actions and tab-targeted Admin Control Centre.
- Admin-configurable all-parish privilege support while Site Supervisor remains parish-first by default.
- Dynamic Admin Form Studio and custom production record support.
- Versioned Supabase production migration packaged with crew roles, attendance, assignments, custom forms, storage security and extended event types.
- Private beneficiary-source design; Shelter assessment files are excluded from distributable assets.
- GitHub Green Gate and Production Factory workflows included.
- Fusion v20.4.1 bug-fix regression guards added to the production contract checker.
- Loading/error/empty states hardened across operational data surfaces.
- GitHub workflow writer race removed.
- Static production checks pass locally.

## Release sequence

1. Push the exact v20.4.1 source revision to GitHub.
2. Require both GitHub workflows to pass Flutter 3.44.7 formatting, analyze and tests.
3. Require release APK, split APK and AAB artifacts from Production Factory.
4. Only after client CI is green, apply `supabase/migrations/20260906_rcsow_v20_3_production_operations.sql` to production Supabase.
5. Run Supabase security/performance advisors and resolve release-blocking findings.
6. Smoke-test real role accounts: Admin, Regional Supervisor, Construction Specialist/Engineer, Site Supervisor, Technical/Community Admin, Carpenter, Worker and Apprentice.
7. Validate phone/tablet layouts, large text, dark/light, reduced motion, loading/error/permission states.

Do not call this release certified until steps 1–5 are complete for the same Git commit.
