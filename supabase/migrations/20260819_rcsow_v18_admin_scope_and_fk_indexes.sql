-- Applied to RC-SOW production on 2026-08-19 through Fusion bug-fix pass.
-- Keeps all-parish operational visibility for Regional Supervisor / Construction Specialist
-- while restricting Admin Dashboard capability to the Admin role.
create or replace function public.default_privileges(p_role text)
returns jsonb
language sql
immutable
set search_path to 'public'
as $$
select case p_role
 when 'Admin' then '{"viewAllParishes":true,"editControl":true,"submitScope":true,"approveScope":true,"viewAdmin":true,"manageFolders":true,"manageUsers":true,"exportData":true,"raiseIssues":true,"reviewControl":true,"reviewPayments":true,"approvePayments":true,"approveNotice":true,"managePrivileges":true,"viewAuditLog":true,"messageAllUsers":true}'::jsonb
 when 'Regional Supervisor' then '{"viewAllParishes":true,"editControl":true,"submitScope":true,"approveScope":true,"viewAdmin":false,"manageFolders":true,"manageUsers":false,"exportData":true,"raiseIssues":true,"reviewControl":true,"reviewPayments":true,"approvePayments":true,"approveNotice":true,"managePrivileges":false,"viewAuditLog":true,"messageAllUsers":true}'::jsonb
 when 'Construction Specialist' then '{"viewAllParishes":true,"editControl":true,"submitScope":true,"approveScope":true,"viewAdmin":false,"manageFolders":false,"manageUsers":false,"exportData":true,"raiseIssues":true,"reviewControl":true,"reviewPayments":true,"approvePayments":true,"approveNotice":true,"managePrivileges":false,"viewAuditLog":true,"messageAllUsers":true}'::jsonb
 when 'Site Supervisor' then '{"viewAllParishes":false,"editControl":true,"submitScope":true,"approveScope":false,"viewAdmin":false,"manageFolders":false,"manageUsers":false,"exportData":true,"raiseIssues":true,"reviewControl":false,"reviewPayments":false,"approvePayments":false,"approveNotice":false,"managePrivileges":false,"viewAuditLog":false,"messageAllUsers":false}'::jsonb
 when 'Technical Admin' then '{"viewAllParishes":true,"editControl":true,"submitScope":true,"approveScope":false,"viewAdmin":false,"manageFolders":false,"manageUsers":false,"exportData":true,"raiseIssues":true,"reviewControl":false,"reviewPayments":false,"approvePayments":false,"approveNotice":false,"managePrivileges":false,"viewAuditLog":false,"messageAllUsers":false}'::jsonb
 when 'Community Admin' then '{"viewAllParishes":false,"editControl":false,"submitScope":false,"approveScope":false,"viewAdmin":false,"manageFolders":false,"manageUsers":false,"exportData":true,"raiseIssues":true,"reviewControl":false,"reviewPayments":false,"approvePayments":false,"approveNotice":false,"managePrivileges":false,"viewAuditLog":false,"messageAllUsers":false}'::jsonb
 else '{}'::jsonb end;
$$;

update public.profiles
set privileges = public.default_privileges(role), updated_at = now()
where approved = true and role is not null;

create index if not exists approval_accounts_updated_by_idx on public.approval_accounts(updated_by);
create index if not exists parish_live_trackers_updated_by_idx on public.parish_live_trackers(updated_by);
create index if not exists supply_requests_submitted_by_idx on public.supply_requests(submitted_by);
create index if not exists supply_requests_approved_by_idx on public.supply_requests(approved_by);
create index if not exists supply_requests_received_by_idx on public.supply_requests(received_by);
