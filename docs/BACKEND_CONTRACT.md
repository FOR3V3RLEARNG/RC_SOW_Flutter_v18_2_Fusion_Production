# Production Backend Contract

The UI depends on one durable operational object: `house`. Every form, evidence item, material movement, transfer, crew assignment, briefing, approval, payment, work log, notification and activity event must carry `house_id` (except explicitly system-wide team/community and policy events).

## Required adapters

1. **Authentication** — Google OAuth through the organization-owned Supabase project; role is loaded from `profiles`, never trusted from a client picker.
2. **Repository** — houses and operational records with optimistic local writes, conflict versions and a durable sync queue.
3. **Evidence storage** — private bucket, signed access, classification, capture metadata and house relation.
4. **Realtime** — scoped house changes, notifications, messages and presence.
5. **Exports** — server-side PDF/XLSX generation with template version and immutable output reference.
6. **Gmail** — least-privilege OAuth; send/read access only for authorized roles and explicit user actions.
7. **Maps** — organization-approved tiles/geocoding; GPS access only after field-user consent.
8. **Approvals** — append-only decisions with actor, role, timestamp, source version and reason; transfer, close-out and finance states must not be advanced by a client-only flag.
9. **Configuration** — Control tile preferences may be user-scoped, while transfer, incentive, routing, storage and payout policies remain administrator-owned and versioned.

## Client write sequence

1. Validate locally.
2. Save an immutable local draft operation.
3. Show `Saved on device`.
4. Submit with record version/idempotency key.
5. On success, mark `Synced` and append server activity.
6. On conflict, preserve both versions and open explicit conflict resolution.
7. On connectivity failure, retain the operation and expose Retry.

## Security rules

- Never ship a service-role key in Flutter.
- RLS derives access from `auth.uid()` and server-owned profile assignments.
- Users see houses only in assigned parishes or explicit house assignments.
- Admin/all-parish access is a server-owned privilege.
- Evidence storage is private.
- Normal users never receive raw database exceptions.
- Every approval, permission change and export is auditable.

The migration is a starter contract, not an instruction to modify a live database without review and backup.
