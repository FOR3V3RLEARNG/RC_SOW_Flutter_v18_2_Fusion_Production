# Fusion Bug Fix Report — RC SOW Flutter v18.2

## Resolved

1. **Admin visibility mismatch — FIXED**
   - Client guard requires `role == Admin` and `viewAdmin == true`.
   - Supabase `default_privileges()` now sets `viewAdmin=false` for Regional Supervisor, Construction Specialist, Technical Admin, Site Supervisor and Community Admin.
   - Existing approved profiles were refreshed from the corrected defaults.

2. **Regional/Construction all-parish requirement — PRESERVED**
   - Both roles retain `viewAllParishes=true`.
   - Active Houses groups results by parish for all-parish roles.

3. **Navigation organization — FIXED**
   - Beneficiary Print Out moved under Scope.
   - Notice of Completion and Payment Submission moved under Control of Works.
   - Map and Live Tracker moved to compact header actions.
   - Admin Dashboard only appears under More for Admin.

4. **Roof measurement ambiguity — FIXED**
   - Wall Height is independent.
   - Wall Plate → Ridge Rise is calculated from span and pitch.
   - Ridge Height from Ground = Wall Height + Rise.
   - Side elevation labels the rise dimension directly.

5. **Messages not opening — FIXED**
   - Message rows open a detail screen.
   - Read acknowledgement is synchronized into `item.readBy` through the existing `upsert_app_event` RPC.
   - Compose is enabled.

6. **Control creation and close-out — FIXED**
   - `+ New Control of Work` is present.
   - Notice and Payment quick-submit flows are present.
   - All requested Control submodules are preserved.

7. **Pending role/parish hand-off — FIXED**
   - Login selections are staged before password or Google sign-in.
   - Pending authenticated profiles automatically submit the saved role/parish request through the existing RPC.

8. **Scope persistence — FIXED**
   - Save Draft and Submit for Approval now write `scope` events to Supabase instead of showing a visual-only snackbar.

9. **Admin prefetch guard — FIXED**
   - Non-admin users no longer invoke the registration-requests RPC before the Admin UI guard is evaluated.

10. **Supabase performance advisor findings — FIXED**
   - Added indexes for approval account updater, parish tracker updater, and supply submitted/approved/received user columns.
   - Optimized the `supply_requests_read` RLS policy so `auth.uid()` is initialized once per statement rather than re-evaluated per row.

## Still requires external console configuration

- Supabase leaked-password protection is an Auth-console setting and could not be enabled through the available database migration API.
- Google OAuth callback URL must be allow-listed in Supabase Auth URL Configuration.
- Production Play signing requires a release keystore supplied through CI secrets.

## Deliberately not changed

Supabase warns that several `SECURITY DEFINER` RPCs are executable by the authenticated role. The reviewed mutation RPCs perform internal Admin/privilege checks. Revoking `authenticated` execute globally would also prevent legitimate Admin calls through PostgREST, so this Fusion fix does not blindly revoke them.
