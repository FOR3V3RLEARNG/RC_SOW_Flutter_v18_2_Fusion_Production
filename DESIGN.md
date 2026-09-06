# RC SOW v20.4 — v18.2 Spacious Design Contract

RC SOW v20.4 keeps the recognizable v18.2 field UI while allowing production capabilities to grow behind registries, role policies and configurable forms.

## Non-negotiable visual rules

- Material 3 remains the usability foundation.
- Default phone horizontal page padding: **16dp**.
- Default grouped-surface padding: **16dp**.
- Default section rhythm: **20dp** with **12dp** card gaps.
- Routine functional icons: **18–20dp**; prominent functional icons should not exceed **22–24dp**.
- Touch targets remain at least **44dp** even when icons are visually small.
- Use whitespace and hierarchy instead of oversized icons or crowded cards.
- No KPI wall: role dashboards surface only information relevant to that role.
- Alternative Design DNA presets change color/shape/tone, not information architecture or spacing density.
- Production chain remains visually lightweight and spatially continuous: Scope → Plan → Delivery → Quality → Close-out → Finance.
- More remains a pullout command surface so secondary features do not crowd primary navigation.

## Role dashboard contract

- **Admin:** governance-first quick actions (Users, Beneficiary Sources, Templates, Form Studio) plus national production chain and alerts.
- **Regional Supervisor / Construction Specialist / Construction Engineer:** all-parish production efficiency, schedules, attendance, evidence, close-out and finance.
- **Site Supervisor:** parish-first production by default. Admin may explicitly grant `viewAllParishes` without changing the role.
- **Technical Admin / Community Admin:** authorized input surfaces and active houses for assigned parish; Community is read-only with suggestion/event requests.
- **Carpenter / Worker / Apprentice:** assigned houses, attendance, evidence, material/consumable requests and field logs only.

## Scalability rules

1. New production forms belong in `record_schemas.dart` or Admin Form Studio, never hand-built duplicate screens.
2. Role-visible modules/metrics/actions belong in `product_registry.dart`.
3. Shared dimensions belong in `design_tokens.dart`; do not hard-code screen-specific density.
4. New backend capability ships as a versioned Supabase migration with RLS/RPC tests and a matching client method.
5. Beneficiary source workbooks stay private and are never embedded into the APK.
6. Every visible button must have an action, permission state, loading state and result feedback.
7. GitHub Green Gate and Production Factory are required before merge/release.
