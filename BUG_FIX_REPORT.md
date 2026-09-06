# Fusion Bug Fix Report — RC SOW v20.4.1

## Release objective

Production hardening of the scalable v20.4 Fusion build while preserving the spacious v18.2 RC SOW UI language: restrained icons, clear hierarchy, generous spacing, role-specific dashboards and house-centric workflows.

## Resolved in v20.4.1

1. **Flutter dropdown contract** — `DropdownMenuItem` now uses `value`; invalid `initialValue` usage was removed.
2. **GitHub workflow race** — Production Factory no longer pushes formatter commits; Green Gate is the sole auto-repair writer.
3. **Parish-safe evidence/signatures** — storage paths preserve canonical parish names such as `St. James`, matching RLS folder checks.
4. **Crew/attendance parish isolation** — assignment and attendance writes are restricted by parish access and assigned-house rules.
5. **Evidence/signature RLS hardening** — supervisor review/edit operations require parish access; destructive actions remain constrained.
6. **Audited deletes** — production records delete only through `delete_app_event`; no direct-table fallback remains.
7. **Community governance** — Community Board publishing is Admin-only; other roles remain read-only and submit suggestions/event requests.
8. **Privilege correctness** — Site Supervisor production editing follows the Admin-managed `editControl` privilege rather than a hard-coded role bypass.
9. **Gmail body handling** — Gmail message MIME bodies are decoded in-app; send now validates recipient and message body.
10. **Error-state integrity** — Beneficiaries, Messages, Users Online, Community, Control modules, Production Analytics, House Command, maps and Admin suggestion inbox distinguish loading/error/empty states instead of hiding failures as empty data.
11. **Async context safety** — mounted checks added around awaited dialogs/date pickers where UI state is subsequently mutated.
12. **PDF compatibility** — export uses `TableHelper.fromTextArray` rather than deprecated `Table.fromTextArray`.
13. **Crew assignment safety** — local safe `firstOrNull` helper removes dependency on an unavailable extension.
14. **Runtime placeholder cleanup** — production fallback labels no longer invent beneficiary/parish values.
15. **Role regression coverage** — added tests for Admin-only community publishing, Site Supervisor privilege control, crew schema restrictions and management visibility.
16. **v18.2 UI guardrail** — production contract continues to enforce restrained working icon scale and spacious design tokens.

## Static Fusion validation passed

- Production contract checker
- Workflow YAML parsing
- Shell-script syntax
- Local import existence
- Dart delimiter sanity scan
- Conflict-marker scan
- No disabled production buttons (`onPressed: null` / `onTap: null`)
- No intentional demo/mock/placeholder runtime data markers

## External certification still required

The exact v20.4.1 revision must pass GitHub Flutter 3.44.7 formatting, `flutter analyze`, unit/widget tests, APK and AAB builds before the matching Supabase v20 production migration is applied.
