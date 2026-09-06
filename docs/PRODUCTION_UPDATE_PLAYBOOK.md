# RC SOW Production Update Playbook

## Safe update path

Use a feature branch for substantive changes. Keep `main` deployable.

```text
Fusion/source change
→ feature branch
→ GitHub Production Factory
→ review validation logs
→ merge only when green
→ download signed/verified artifacts
```

## Files intended for routine updates

- `lib/core/product_registry.dart` — role experience and module visibility
- `lib/core/record_schemas.dart` — built-in record definitions
- `lib/core/design_tokens.dart` — Design DNA tokens and density contract
- Admin Template Studio / private Supabase `document-templates` bucket — editable source templates (not bundled in the APK)
- Admin Form Studio — custom forms without app rebuild
- Admin Template Manager — replace operational templates without app rebuild
- Admin parish map settings — parish map URLs without app rebuild
- beneficiary source registry — parish-specific protected assessment workbook

## Files requiring stricter review

- `lib/services/rc_sow_repository.dart`
- `supabase/migrations/`
- authentication/deep-link configuration
- role/privilege defaults
- payment/attendance calculations
- storage RLS policies

These changes affect data integrity or access control and must receive Green Gate plus backend security review.

## UI guardrails

Preserve the v18.2 spacious framework:

- page padding: 16dp phone;
- section gaps: about 20dp;
- card padding: 16dp;
- most functional icons: 18–20dp;
- icon-button targets: at least 44dp;
- Material 3 interactive semantics;
- compact metadata, not compact touch targets;
- cards are grouped by workflow rather than filling the screen with KPIs.

Do not ship decorative buttons, demo data, placeholder records or hard-coded beneficiary examples.
