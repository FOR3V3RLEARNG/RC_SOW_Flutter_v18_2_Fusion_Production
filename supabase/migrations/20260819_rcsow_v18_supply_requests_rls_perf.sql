-- Mirrors the production RLS performance fix applied by Fusion.
drop policy if exists supply_requests_read on public.supply_requests;
create policy supply_requests_read on public.supply_requests
for select to authenticated
using (
  submitted_by = (select auth.uid())
  or public.can_access_parish(parish)
  or public.has_privilege('reviewControl')
);
