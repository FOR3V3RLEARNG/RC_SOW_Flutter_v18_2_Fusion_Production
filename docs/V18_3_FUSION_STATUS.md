# RC SOW v18.3 Fusion Production — Source Candidate

This package contains the v18.3 source integration requested after the green v18.2 production build.

Included in this source candidate:
- interactive RC SOW message center with replies and recipient-aware sends;
- pull-down/end-drawer message surface;
- vertical Users Online popup and click-user-to-message flow;
- administrator user access controls for suspend/block/restore, role, parish and privileges;
- all 14 Jamaica parishes and Construction Engineer role option;
- Design DNA selector: Material 3 Expressive, Forui-inspired Minimal, shadcn-inspired SaaS and Field Dense;
- Flame-based animated house repair splash source;
- uploaded Work Plan, SOW, Control of Works, Monitoring Checklist, Notice of Completion and Payment Request templates bundled as fallbacks;
- remote document template registry/storage contract;
- PDF/Excel/share service layer for production exports;
- Gmail inbox/send service layer using a Google provider token and explicit Gmail scopes;
- beneficiary-directory data model and Supabase migration support;
- corrected event-upsert client contract (`type` + `item.id`) for v18.3 records;
- backend migration source for management, templates and beneficiary directory.

## Important build status

This v18.3 package is a **source candidate**. It has not yet been certified by the Flutter 3.44.7 GitHub Green Gate after the v18.3 changes. The previously verified release is v18.2. Before describing v18.3 as production-ready, run:

1. `dart format --output=none --set-exit-if-changed .`
2. `flutter analyze`
3. `flutter test`
4. `flutter build apk --release`
5. `flutter build appbundle --release`

Resolve any dependency/analyzer/runtime findings before distributing the APK/AAB.
