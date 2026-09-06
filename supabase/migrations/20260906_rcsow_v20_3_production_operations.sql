-- RC SOW v20.3 Fusion Production Operations
-- Production-grade role boundaries, workforce attendance, editable forms,
-- beneficiary source control, evidence/signature storage, community workflow,
-- signature requests and expanded app-event contracts.

begin;

-- ---------- Expand legacy constraints for production roles / event families ----------
alter table public.profiles drop constraint if exists profiles_role_check;
alter table public.profiles add constraint profiles_role_check check (
  role is null or role in ('Admin','Regional Supervisor','Construction Specialist','Construction Engineer','Site Supervisor','Technical Admin','Community Admin','Carpenter','Worker','Apprentice')
);
alter table public.profiles drop constraint if exists profiles_requested_role_check;
alter table public.profiles add constraint profiles_requested_role_check check (
  requested_role is null or requested_role in ('Admin','Regional Supervisor','Construction Specialist','Construction Engineer','Site Supervisor','Technical Admin','Community Admin','Carpenter','Worker','Apprentice')
);
alter table public.profiles drop constraint if exists profiles_registration_status_check;
alter table public.profiles add constraint profiles_registration_status_check check (
  registration_status in ('pending','approved','rejected','suspended','blocked')
);
alter table public.approval_accounts drop constraint if exists approval_accounts_role_check;
alter table public.approval_accounts add constraint approval_accounts_role_check check (
  role in ('Admin','Regional Supervisor','Construction Specialist','Construction Engineer','Site Supervisor','Technical Admin','Community Admin','Carpenter','Worker','Apprentice')
);
alter table public.app_events drop constraint if exists app_events_type_check;
alter table public.app_events drop constraint if exists app_events_event_type_nonempty_check;
alter table public.app_events add constraint app_events_event_type_nonempty_check check (
  length(trim(event_type)) between 1 and 80
);

-- ---------- Role / privilege policy ----------
create or replace function public.default_privileges(p_role text)
returns jsonb
language sql
immutable
set search_path to 'public'
as $$
select case p_role
 when 'Admin' then '{"viewAllParishes":true,"editControl":true,"submitScope":true,"approveScope":true,"viewAdmin":true,"manageFolders":true,"manageUsers":true,"exportData":true,"raiseIssues":true,"reviewControl":true,"reviewPayments":true,"approvePayments":true,"approveNotice":true,"managePrivileges":true,"viewAuditLog":true,"messageAllUsers":true,"manageCommunity":true,"manageCrew":true,"verifyAttendance":true,"manageForms":true,"manageBeneficiarySources":true}'::jsonb
 when 'Regional Supervisor' then '{"viewAllParishes":true,"editControl":true,"submitScope":true,"approveScope":true,"viewAdmin":false,"manageFolders":true,"manageUsers":false,"exportData":true,"raiseIssues":true,"reviewControl":true,"reviewPayments":true,"approvePayments":true,"approveNotice":true,"managePrivileges":false,"viewAuditLog":true,"messageAllUsers":true,"manageCommunity":false,"manageCrew":true,"verifyAttendance":true,"manageForms":false,"manageBeneficiarySources":false}'::jsonb
 when 'Construction Specialist' then '{"viewAllParishes":true,"editControl":true,"submitScope":true,"approveScope":true,"viewAdmin":false,"manageFolders":true,"manageUsers":false,"exportData":true,"raiseIssues":true,"reviewControl":true,"reviewPayments":true,"approvePayments":true,"approveNotice":true,"managePrivileges":false,"viewAuditLog":true,"messageAllUsers":true,"manageCommunity":false,"manageCrew":true,"verifyAttendance":true,"manageForms":false,"manageBeneficiarySources":false}'::jsonb
 when 'Construction Engineer' then '{"viewAllParishes":true,"editControl":true,"submitScope":true,"approveScope":true,"viewAdmin":false,"manageFolders":true,"manageUsers":false,"exportData":true,"raiseIssues":true,"reviewControl":true,"reviewPayments":true,"approvePayments":true,"approveNotice":true,"managePrivileges":false,"viewAuditLog":true,"messageAllUsers":true,"manageCommunity":false,"manageCrew":true,"verifyAttendance":true,"manageForms":false,"manageBeneficiarySources":false}'::jsonb
 when 'Site Supervisor' then '{"viewAllParishes":false,"editControl":true,"submitScope":true,"approveScope":false,"viewAdmin":false,"manageFolders":false,"manageUsers":false,"exportData":true,"raiseIssues":true,"reviewControl":true,"reviewPayments":true,"approvePayments":false,"approveNotice":false,"managePrivileges":false,"viewAuditLog":false,"messageAllUsers":false,"manageCommunity":false,"manageCrew":true,"verifyAttendance":true,"manageForms":false,"manageBeneficiarySources":false}'::jsonb
 when 'Technical Admin' then '{"viewAllParishes":false,"editControl":true,"submitScope":true,"approveScope":false,"viewAdmin":false,"manageFolders":false,"manageUsers":false,"exportData":true,"raiseIssues":true,"reviewControl":false,"reviewPayments":false,"approvePayments":false,"approveNotice":false,"managePrivileges":false,"viewAuditLog":false,"messageAllUsers":false,"manageCommunity":false,"manageCrew":false,"verifyAttendance":false,"manageForms":false,"manageBeneficiarySources":false}'::jsonb
 when 'Community Admin' then '{"viewAllParishes":false,"editControl":false,"submitScope":false,"approveScope":false,"viewAdmin":false,"manageFolders":false,"manageUsers":false,"exportData":true,"raiseIssues":true,"reviewControl":false,"reviewPayments":false,"approvePayments":false,"approveNotice":false,"managePrivileges":false,"viewAuditLog":false,"messageAllUsers":false,"manageCommunity":false,"manageCrew":false,"verifyAttendance":false,"manageForms":false,"manageBeneficiarySources":false}'::jsonb
 when 'Carpenter' then '{"viewAllParishes":false,"editControl":false,"submitScope":false,"approveScope":false,"viewAdmin":false,"manageFolders":false,"manageUsers":false,"exportData":false,"raiseIssues":true,"reviewControl":false,"reviewPayments":false,"approvePayments":false,"approveNotice":false,"managePrivileges":false,"viewAuditLog":false,"messageAllUsers":false,"manageCommunity":false,"manageCrew":false,"verifyAttendance":false,"manageForms":false,"manageBeneficiarySources":false,"viewAssignedHouses":true,"editOwnAttendance":true,"submitFieldRequests":true,"uploadEvidence":true}'::jsonb
 when 'Worker' then '{"viewAllParishes":false,"editControl":false,"submitScope":false,"approveScope":false,"viewAdmin":false,"manageFolders":false,"manageUsers":false,"exportData":false,"raiseIssues":true,"reviewControl":false,"reviewPayments":false,"approvePayments":false,"approveNotice":false,"managePrivileges":false,"viewAuditLog":false,"messageAllUsers":false,"manageCommunity":false,"manageCrew":false,"verifyAttendance":false,"manageForms":false,"manageBeneficiarySources":false,"viewAssignedHouses":true,"editOwnAttendance":true,"submitFieldRequests":false,"uploadEvidence":true}'::jsonb
 when 'Apprentice' then '{"viewAllParishes":false,"editControl":false,"submitScope":false,"approveScope":false,"viewAdmin":false,"manageFolders":false,"manageUsers":false,"exportData":false,"raiseIssues":true,"reviewControl":false,"reviewPayments":false,"approvePayments":false,"approveNotice":false,"managePrivileges":false,"viewAuditLog":false,"messageAllUsers":false,"manageCommunity":false,"manageCrew":false,"verifyAttendance":false,"manageForms":false,"manageBeneficiarySources":false,"viewAssignedHouses":true,"editOwnAttendance":true,"submitFieldRequests":false,"uploadEvidence":true}'::jsonb
 else '{}'::jsonb end;
$$;

create or replace function public.is_crew_role(p_role text)
returns boolean language sql immutable set search_path to 'public'
as $$ select coalesce(p_role in ('Carpenter','Worker','Apprentice'),false); $$;

create or replace function public.current_full_name()
returns text language sql stable security definer set search_path to 'public'
as $$ select coalesce(full_name,'') from public.profiles where user_id=auth.uid() and approved=true and active=true; $$;

create or replace function public.can_view_all_parishes()
returns boolean
language sql
stable security definer
set search_path to 'public'
as $$
 select coalesce(
   p.role in ('Admin','Regional Supervisor','Construction Specialist','Construction Engineer')
   or public.has_privilege('viewAllParishes'),
   false
 )
 from public.profiles p
 where p.user_id=auth.uid() and p.approved=true and p.active=true;
$$;

-- ---------- Crew assignment ----------
create table if not exists public.house_crew_assignments(
  id uuid primary key default gen_random_uuid(),
  house_code text not null,
  parish text not null,
  user_id uuid references auth.users(id) on delete cascade,
  email text not null,
  member_name text,
  role text not null check (role in ('Carpenter','Worker','Apprentice')),
  active boolean not null default true,
  assigned_by uuid references auth.users(id) on delete set null,
  assigned_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(house_code,email)
);
create index if not exists house_crew_assignments_user_active_idx on public.house_crew_assignments(user_id,active);
create index if not exists house_crew_assignments_house_active_idx on public.house_crew_assignments(house_code,active);
alter table public.house_crew_assignments enable row level security;

create or replace function public.crew_can_access_house(p_house_code text)
returns boolean
language sql
stable security definer
set search_path to 'public'
as $$
 select case
   when auth.uid() is null then false
   when not public.is_crew_role(public.current_role()) then public.can_access_parish(
     (select parish from public.app_events where event_type='house' and house_code=upper(trim(p_house_code)) order by updated_at desc limit 1)
   )
   else exists(
     select 1 from public.house_crew_assignments a
     where a.active=true and upper(a.house_code)=upper(trim(p_house_code))
       and (a.user_id=auth.uid() or lower(a.email)=lower(public.current_email()))
   ) or exists(
     select 1 from public.app_events e
     where e.event_type='house' and upper(e.house_code)=upper(trim(p_house_code))
       and exists(
         select 1 from jsonb_array_elements_text(coalesce(e.item->'assignedCrew','[]'::jsonb)) m
         where lower(m)=lower(public.current_email()) or lower(m)=lower(public.current_full_name())
       )
   )
 end;
$$;

drop policy if exists house_crew_assignments_select on public.house_crew_assignments;
create policy house_crew_assignments_select on public.house_crew_assignments for select to authenticated
using (
  public.can_view_all_parishes()
  or (public.has_privilege('manageCrew') and public.can_access_parish(parish))
  or user_id=auth.uid()
  or (public.can_access_parish(parish) and not public.is_crew_role(public.current_role()))
);
drop policy if exists house_crew_assignments_write on public.house_crew_assignments;
create policy house_crew_assignments_write on public.house_crew_assignments for all to authenticated
using (public.has_privilege('manageCrew') and public.can_access_parish(parish))
with check (public.has_privilege('manageCrew') and public.can_access_parish(parish));

create or replace function public.assign_house_crew(
  p_house_code text,
  p_parish text,
  p_user_id uuid,
  p_email text,
  p_member_name text,
  p_role text,
  p_active boolean default true
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if not public.has_privilege('manageCrew') then raise exception 'Crew-management privilege required'; end if;
  if p_role not in ('Carpenter','Worker','Apprentice') then raise exception 'Invalid crew role'; end if;
  if not public.can_access_parish(p_parish) then raise exception 'Parish access denied'; end if;
  insert into public.house_crew_assignments(house_code,parish,user_id,email,member_name,role,active,assigned_by,updated_at)
  values(upper(trim(p_house_code)),p_parish,p_user_id,lower(trim(p_email)),nullif(trim(coalesce(p_member_name,'')),''),p_role,p_active,auth.uid(),now())
  on conflict(house_code,email) do update set
    parish=excluded.parish,user_id=excluded.user_id,member_name=excluded.member_name,role=excluded.role,active=excluded.active,assigned_by=auth.uid(),updated_at=now();
  insert into public.audit_log(user_id,user_email,action,entity_type,entity_id,parish,details)
  values(auth.uid(),public.current_email(),'crew.assignment','house',upper(trim(p_house_code)),p_parish,jsonb_build_object('email',lower(trim(p_email)),'role',p_role,'active',p_active));
  return jsonb_build_object('ok',true);
end;
$$;

-- ---------- Attendance ledger ----------
create table if not exists public.crew_attendance(
  id uuid primary key default gen_random_uuid(),
  house_code text not null,
  parish text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  member_email text not null,
  member_name text not null,
  member_role text not null check (member_role in ('Carpenter','Worker','Apprentice')),
  work_date date not null,
  status text not null default 'Present' check (status in ('Present','Half day','Absent','Excused')),
  clock_in timestamptz,
  clock_out timestamptz,
  note text,
  evidence_path text,
  self_signed boolean not null default true,
  verified boolean not null default false,
  verified_by uuid references auth.users(id) on delete set null,
  verified_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(house_code,user_id,work_date)
);
create index if not exists crew_attendance_house_date_idx on public.crew_attendance(house_code,work_date desc);
create index if not exists crew_attendance_user_date_idx on public.crew_attendance(user_id,work_date desc);
alter table public.crew_attendance enable row level security;

drop policy if exists crew_attendance_select on public.crew_attendance;
create policy crew_attendance_select on public.crew_attendance for select to authenticated
using (
  user_id=auth.uid()
  or (public.has_privilege('verifyAttendance') and public.can_access_parish(parish))
  or (not public.is_crew_role(public.current_role()) and public.can_access_parish(parish))
);
drop policy if exists crew_attendance_insert on public.crew_attendance;
create policy crew_attendance_insert on public.crew_attendance for insert to authenticated
with check (
  (user_id=auth.uid() and public.has_privilege('editOwnAttendance') and public.crew_can_access_house(house_code))
  or (public.has_privilege('verifyAttendance') and public.can_access_parish(parish))
);
drop policy if exists crew_attendance_update on public.crew_attendance;
create policy crew_attendance_update on public.crew_attendance for update to authenticated
using (
  (user_id=auth.uid() and public.has_privilege('editOwnAttendance') and verified=false)
  or (public.has_privilege('verifyAttendance') and public.can_access_parish(parish))
)
with check (
  (user_id=auth.uid() and public.has_privilege('editOwnAttendance') and public.crew_can_access_house(house_code))
  or (public.has_privilege('verifyAttendance') and public.can_access_parish(parish))
);

create or replace function public.upsert_crew_attendance(
  p_house_code text,
  p_work_date date,
  p_status text default 'Present',
  p_clock_action text default 'sign_in',
  p_note text default null,
  p_evidence_path text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_profile public.profiles%rowtype;
  v_parish text;
  v_row public.crew_attendance%rowtype;
begin
  select * into v_profile from public.profiles where user_id=auth.uid() and approved=true and active=true;
  if not found then raise exception 'Approved active account required'; end if;
  if not public.is_crew_role(v_profile.role) then raise exception 'Crew account required for self attendance'; end if;
  if not public.crew_can_access_house(p_house_code) then raise exception 'House is not assigned to this crew member'; end if;
  if p_status not in ('Present','Half day','Absent','Excused') then raise exception 'Invalid attendance status'; end if;
  select coalesce(a.parish,e.parish,v_profile.parish) into v_parish
  from (select 1) x
  left join public.house_crew_assignments a on a.active=true and upper(a.house_code)=upper(trim(p_house_code)) and (a.user_id=auth.uid() or lower(a.email)=lower(v_profile.email))
  left join lateral (select parish from public.app_events where event_type='house' and upper(house_code)=upper(trim(p_house_code)) order by updated_at desc limit 1) e on true
  limit 1;
  insert into public.crew_attendance(house_code,parish,user_id,member_email,member_name,member_role,work_date,status,clock_in,clock_out,note,evidence_path,self_signed,updated_at)
  values(
    upper(trim(p_house_code)),coalesce(v_parish,v_profile.parish),auth.uid(),v_profile.email,coalesce(nullif(v_profile.full_name,''),split_part(v_profile.email,'@',1)),v_profile.role,p_work_date,p_status,
    case when p_clock_action='sign_in' then now() else null end,
    case when p_clock_action='sign_out' then now() else null end,
    p_note,p_evidence_path,true,now()
  )
  on conflict(house_code,user_id,work_date) do update set
    status=excluded.status,
    clock_in=case when p_clock_action='sign_in' then coalesce(public.crew_attendance.clock_in,now()) else public.crew_attendance.clock_in end,
    clock_out=case when p_clock_action='sign_out' then now() else public.crew_attendance.clock_out end,
    note=coalesce(excluded.note,public.crew_attendance.note),
    evidence_path=coalesce(excluded.evidence_path,public.crew_attendance.evidence_path),
    updated_at=now()
  returning * into v_row;
  insert into public.audit_log(user_id,user_email,action,entity_type,entity_id,parish,details)
  values(auth.uid(),v_profile.email,'attendance.'||p_clock_action,'crew_attendance',v_row.id::text,v_row.parish,jsonb_build_object('houseCode',v_row.house_code,'workDate',v_row.work_date,'status',v_row.status));
  return to_jsonb(v_row);
end;
$$;

create or replace function public.verify_crew_attendance(p_attendance_id uuid,p_verified boolean,p_status text default null)
returns jsonb
language plpgsql security definer set search_path to 'public'
as $$
declare v_row public.crew_attendance%rowtype;
begin
  if not public.has_privilege('verifyAttendance') then raise exception 'Attendance verification privilege required'; end if;
  select * into v_row from public.crew_attendance where id=p_attendance_id for update;
  if not found then raise exception 'Attendance row not found'; end if;
  if not public.can_access_parish(v_row.parish) then raise exception 'Parish access denied'; end if;
  if p_status is not null and p_status not in ('Present','Half day','Absent','Excused') then raise exception 'Invalid attendance status'; end if;
  update public.crew_attendance set status=coalesce(p_status,status),verified=p_verified,verified_by=case when p_verified then auth.uid() else null end,verified_at=case when p_verified then now() else null end,updated_at=now() where id=p_attendance_id returning * into v_row;
  return to_jsonb(v_row);
end;
$$;

create or replace function public.attendance_payment_summary(p_house_code text,p_start_date date default null,p_end_date date default null)
returns table(member_email text,member_name text,member_role text,verified_days numeric,payable_days numeric,pending_days bigint)
language sql stable security definer set search_path to 'public'
as $$
 select a.member_email,max(a.member_name),max(a.member_role),
        count(*) filter (where a.verified)::numeric,
        sum(case when a.verified and a.status='Present' then 1.0 when a.verified and a.status='Half day' then 0.5 else 0 end)::numeric,
        count(*) filter (where not a.verified)
 from public.crew_attendance a
 where upper(a.house_code)=upper(trim(p_house_code))
   and (p_start_date is null or a.work_date>=p_start_date)
   and (p_end_date is null or a.work_date<=p_end_date)
   and (public.can_view_all_parishes() or public.can_access_parish(a.parish) or a.user_id=auth.uid())
 group by a.member_email
 order by max(a.member_role),max(a.member_name);
$$;

-- ---------- Beneficiary source files and editable forms ----------
create table if not exists public.beneficiary_sources(
  id uuid primary key default gen_random_uuid(),
  parish text not null unique,
  file_name text not null,
  storage_path text not null,
  sheet_name text,
  header_row integer,
  source_column_count integer,
  row_count integer not null default 0,
  active boolean not null default true,
  updated_by uuid references auth.users(id) on delete set null,
  updated_at timestamptz not null default now()
);
alter table public.beneficiary_sources add column if not exists sheet_name text;
alter table public.beneficiary_sources add column if not exists header_row integer;
alter table public.beneficiary_sources add column if not exists source_column_count integer;
alter table public.beneficiary_sources enable row level security;
drop policy if exists beneficiary_sources_read on public.beneficiary_sources;
create policy beneficiary_sources_read on public.beneficiary_sources for select to authenticated
using (public.can_view_all_parishes() or public.can_access_parish(parish));
drop policy if exists beneficiary_sources_write on public.beneficiary_sources;
create policy beneficiary_sources_write on public.beneficiary_sources for all to authenticated
using (public.has_privilege('manageBeneficiarySources') or public.has_privilege('manageUsers'))
with check (public.has_privilege('manageBeneficiarySources') or public.has_privilege('manageUsers'));

create table if not exists public.record_form_templates(
  id uuid primary key default gen_random_uuid(),
  title text not null,
  event_type text not null,
  phase text not null check (phase in ('Plan','Delivery','Quality','Close-out','Finance')),
  fields jsonb not null default '[]'::jsonb,
  active boolean not null default true,
  display_order integer not null default 100,
  updated_by uuid references auth.users(id) on delete set null,
  updated_at timestamptz not null default now()
);
create unique index if not exists record_form_templates_event_type_idx on public.record_form_templates(event_type);
alter table public.record_form_templates enable row level security;
drop policy if exists record_form_templates_read on public.record_form_templates;
create policy record_form_templates_read on public.record_form_templates for select to authenticated using (active=true or public.has_privilege('manageForms') or public.has_privilege('manageUsers'));
drop policy if exists record_form_templates_write on public.record_form_templates;
create policy record_form_templates_write on public.record_form_templates for all to authenticated
using (public.has_privilege('manageForms') or public.has_privilege('manageUsers'))
with check (public.has_privilege('manageForms') or public.has_privilege('manageUsers'));

-- ---------- Server-replaceable source document templates ----------
create table if not exists public.document_templates(
  template_key text primary key,
  display_name text not null,
  file_name text not null,
  mime_type text not null,
  storage_path text not null,
  active boolean not null default true,
  updated_by uuid references auth.users(id) on delete set null,
  updated_at timestamptz not null default now()
);
alter table public.document_templates enable row level security;
drop policy if exists document_templates_read on public.document_templates;
create policy document_templates_read on public.document_templates for select to authenticated using (true);
drop policy if exists document_templates_write on public.document_templates;
create policy document_templates_write on public.document_templates for all to authenticated
using (public.has_privilege('manageFolders') or public.has_privilege('manageUsers'))
with check (public.has_privilege('manageFolders') or public.has_privilege('manageUsers'));

-- ---------- Storage buckets ----------
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values
 ('beneficiary-sources','beneficiary-sources',false,31457280,array['application/vnd.openxmlformats-officedocument.spreadsheetml.sheet','application/vnd.ms-excel']),
 ('document-templates','document-templates',false,20971520,array['application/vnd.openxmlformats-officedocument.spreadsheetml.sheet','application/vnd.openxmlformats-officedocument.wordprocessingml.document','application/pdf']),
 ('evidence','evidence',false,15728640,array['image/jpeg','image/png','image/webp','application/pdf']),
 ('signatures','signatures',false,5242880,array['image/png','image/jpeg'])
on conflict(id) do update set public=false,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;

drop policy if exists rc_sow_beneficiary_sources_read on storage.objects;
create policy rc_sow_beneficiary_sources_read on storage.objects for select to authenticated
using (bucket_id='beneficiary-sources' and (public.can_view_all_parishes() or public.can_access_parish((storage.foldername(name))[1])));
drop policy if exists rc_sow_beneficiary_sources_write on storage.objects;
create policy rc_sow_beneficiary_sources_write on storage.objects for all to authenticated
using (bucket_id='beneficiary-sources' and (public.has_privilege('manageBeneficiarySources') or public.has_privilege('manageUsers')))
with check (bucket_id='beneficiary-sources' and (public.has_privilege('manageBeneficiarySources') or public.has_privilege('manageUsers')));

drop policy if exists rc_sow_document_templates_read on storage.objects;
create policy rc_sow_document_templates_read on storage.objects for select to authenticated
using (bucket_id='document-templates');
drop policy if exists rc_sow_document_templates_insert on storage.objects;
create policy rc_sow_document_templates_insert on storage.objects for insert to authenticated
with check (bucket_id='document-templates' and (public.has_privilege('manageFolders') or public.has_privilege('manageUsers')));
drop policy if exists rc_sow_document_templates_update on storage.objects;
create policy rc_sow_document_templates_update on storage.objects for update to authenticated
using (bucket_id='document-templates' and (public.has_privilege('manageFolders') or public.has_privilege('manageUsers')))
with check (bucket_id='document-templates' and (public.has_privilege('manageFolders') or public.has_privilege('manageUsers')));
drop policy if exists rc_sow_document_templates_delete on storage.objects;
create policy rc_sow_document_templates_delete on storage.objects for delete to authenticated
using (bucket_id='document-templates' and (public.has_privilege('manageFolders') or public.has_privilege('manageUsers')));

drop policy if exists rc_sow_evidence_read on storage.objects;
create policy rc_sow_evidence_read on storage.objects for select to authenticated
using (
 bucket_id='evidence' and (
   public.can_view_all_parishes()
   or (not public.is_crew_role(public.current_role()) and public.can_access_parish((storage.foldername(name))[1]))
   or (public.is_crew_role(public.current_role()) and public.crew_can_access_house((storage.foldername(name))[2]))
 )
);
drop policy if exists rc_sow_evidence_insert on storage.objects;
create policy rc_sow_evidence_insert on storage.objects for insert to authenticated
with check (
 bucket_id='evidence' and (
   ((public.has_privilege('editControl') or public.has_privilege('reviewControl')) and public.can_access_parish((storage.foldername(name))[1]))
   or (public.has_privilege('uploadEvidence') and public.crew_can_access_house((storage.foldername(name))[2]))
 )
);
drop policy if exists rc_sow_evidence_update on storage.objects;
create policy rc_sow_evidence_update on storage.objects for update to authenticated
using (bucket_id='evidence' and ((((public.has_privilege('editControl') or public.has_privilege('reviewControl')) and public.can_access_parish((storage.foldername(name))[1]))) or owner=auth.uid()))
with check (bucket_id='evidence' and ((((public.has_privilege('editControl') or public.has_privilege('reviewControl')) and public.can_access_parish((storage.foldername(name))[1]))) or owner=auth.uid()));

drop policy if exists rc_sow_evidence_delete on storage.objects;
create policy rc_sow_evidence_delete on storage.objects for delete to authenticated
using (bucket_id='evidence' and (public.current_role()='Admin' or (((public.has_privilege('editControl') or public.has_privilege('reviewControl')) and public.can_access_parish((storage.foldername(name))[1]))) or owner=auth.uid()));

drop policy if exists rc_sow_signatures_read on storage.objects;
create policy rc_sow_signatures_read on storage.objects for select to authenticated
using (
 bucket_id='signatures' and (
   public.can_view_all_parishes()
   or (not public.is_crew_role(public.current_role()) and public.can_access_parish((storage.foldername(name))[1]))
   or (public.is_crew_role(public.current_role()) and public.crew_can_access_house((storage.foldername(name))[2]))
 )
);
drop policy if exists rc_sow_signatures_insert on storage.objects;
create policy rc_sow_signatures_insert on storage.objects for insert to authenticated
with check (
 bucket_id='signatures' and exists(select 1 from public.profiles p where p.user_id=auth.uid() and p.approved=true and p.active=true)
 and (
   public.can_view_all_parishes()
   or (not public.is_crew_role(public.current_role()) and public.can_access_parish((storage.foldername(name))[1]))
   or (public.is_crew_role(public.current_role()) and public.crew_can_access_house((storage.foldername(name))[2]))
 )
);
drop policy if exists rc_sow_signatures_update on storage.objects;
create policy rc_sow_signatures_update on storage.objects for update to authenticated
using (bucket_id='signatures' and ((((public.has_privilege('editControl') or public.has_privilege('reviewControl')) and public.can_access_parish((storage.foldername(name))[1]))) or owner=auth.uid()))
with check (bucket_id='signatures' and ((((public.has_privilege('editControl') or public.has_privilege('reviewControl')) and public.can_access_parish((storage.foldername(name))[1]))) or owner=auth.uid()));
drop policy if exists rc_sow_signatures_delete on storage.objects;
create policy rc_sow_signatures_delete on storage.objects for delete to authenticated
using (bucket_id='signatures' and (public.current_role()='Admin' or (((public.has_privilege('editControl') or public.has_privilege('reviewControl')) and public.can_access_parish((storage.foldername(name))[1]))) or owner=auth.uid()));

-- ---------- Registration / access management ----------
create or replace function public.handle_new_auth_user()
returns trigger language plpgsql security definer set search_path to 'public'
as $$
declare
 v_email text:=lower(coalesce(new.email,''));
 a public.approval_accounts%rowtype;
 meta jsonb:=coalesce(new.raw_user_meta_data,'{}'::jsonb);
 v_requested_role text;
 v_requested_parish text;
 v_full_name text;
begin
 select * into a from public.approval_accounts where lower(email)=v_email and active=true limit 1;
 v_full_name:=trim(coalesce(meta->>'full_name',meta->>'name',''));
 v_requested_role:=nullif(trim(coalesce(meta->>'requested_role','')),'');
 if v_requested_role is null and a.id is not null then v_requested_role:=a.role; end if;
 if v_requested_role not in ('Admin','Regional Supervisor','Construction Specialist','Construction Engineer','Site Supervisor','Technical Admin','Community Admin','Carpenter','Worker','Apprentice') then v_requested_role:=null; end if;
 v_requested_parish:=nullif(trim(coalesce(meta->>'requested_parish','')),'');
 if v_requested_role in ('Admin','Regional Supervisor','Construction Specialist','Construction Engineer') then v_requested_parish:='All Parishes'; end if;
 insert into public.profiles(user_id,email,full_name,role,parish,privileges,approved,active,requested_role,requested_parish,registration_status,role_requested_at,updated_at)
 values(new.id,v_email,v_full_name,null,null,'{}'::jsonb,false,true,v_requested_role,v_requested_parish,'pending',case when v_requested_role is not null then now() else null end,now())
 on conflict(user_id) do update set
   email=excluded.email,
   full_name=case when coalesce(public.profiles.full_name,'')='' and excluded.full_name<>'' then excluded.full_name else public.profiles.full_name end,
   requested_role=case when public.profiles.approved then public.profiles.requested_role else coalesce(excluded.requested_role,public.profiles.requested_role) end,
   requested_parish=case when public.profiles.approved then public.profiles.requested_parish else coalesce(excluded.requested_parish,public.profiles.requested_parish) end,
   registration_status=case when public.profiles.approved then public.profiles.registration_status when public.profiles.registration_status in ('blocked','suspended') then public.profiles.registration_status else 'pending' end,
   role=case when public.profiles.approved then public.profiles.role else null end,
   parish=case when public.profiles.approved then public.profiles.parish else null end,
   privileges=case when public.profiles.approved then public.profiles.privileges else '{}'::jsonb end,
   approved=public.profiles.approved,
   active=public.profiles.active,
   updated_at=now();
 return new;
end;
$$;

create or replace function public.request_role_assignment(p_requested_role text,p_requested_parish text default null,p_full_name text default null)
returns table(user_id uuid,email text,full_name text,requested_role text,requested_parish text,registration_status text,approved boolean)
language plpgsql security definer set search_path to 'public'
as $$
declare v_uid uuid:=auth.uid(); v_parish text:=nullif(trim(coalesce(p_requested_parish,'')),''); v_profile public.profiles%rowtype;
begin
 if v_uid is null then raise exception 'Authentication required'; end if;
 if p_requested_role is null or p_requested_role <> all(array['Admin','Regional Supervisor','Construction Specialist','Construction Engineer','Site Supervisor','Technical Admin','Community Admin','Carpenter','Worker','Apprentice']) then raise exception 'Invalid requested role'; end if;
 if p_requested_role=any(array['Admin','Regional Supervisor','Construction Specialist','Construction Engineer']) then
   v_parish:='All Parishes';
 elsif v_parish is null or v_parish <> all(array['Hanover','Westmoreland','St. James','Trelawny','St. Elizabeth','St. Ann','Clarendon','Manchester','St. Catherine','Kingston','St. Andrew','St. Mary','Portland','St. Thomas']) then
   raise exception 'A valid parish is required for this role';
 end if;
 select * into v_profile from public.profiles where profiles.user_id=v_uid;
 if not found then raise exception 'Profile not found'; end if;
 if v_profile.registration_status in ('blocked','suspended') then raise exception 'Account access is restricted'; end if;
 if v_profile.approved then return query select v_profile.user_id,v_profile.email,coalesce(nullif(trim(p_full_name),''),v_profile.full_name),v_profile.role,v_profile.parish,'approved'::text,true; return; end if;
 update public.profiles p set requested_role=p_requested_role,requested_parish=v_parish,full_name=coalesce(nullif(trim(p_full_name),''),p.full_name),registration_status='pending',role_requested_at=now(),updated_at=now() where p.user_id=v_uid returning p.* into v_profile;
 insert into public.audit_log(user_id,user_email,action,entity_type,entity_id,parish,details) values(v_uid,v_profile.email,'registration.role_requested','profile',v_uid::text,v_parish,jsonb_build_object('requestedRole',p_requested_role,'requestedParish',v_parish));
 return query select v_profile.user_id,v_profile.email,v_profile.full_name,v_profile.requested_role,v_profile.requested_parish,v_profile.registration_status,v_profile.approved;
end;
$$;

create or replace function public.approve_registration_request(p_user_id uuid)
returns table(user_id uuid,email text,role text,parish text,approved boolean,registration_status text)
language plpgsql security definer set search_path to 'public'
as $$
declare v_admin public.profiles%rowtype; v_target public.profiles%rowtype; v_parish text;
begin
 select * into v_admin from public.profiles p where p.user_id=auth.uid();
 if not found or not v_admin.approved or not v_admin.active or v_admin.role<>'Admin' or not public.has_privilege('manageUsers') then raise exception 'Admin privilege required'; end if;
 select * into v_target from public.profiles p where p.user_id=p_user_id for update;
 if not found then raise exception 'Registration request not found'; end if;
 if v_target.requested_role is null then raise exception 'No role was requested'; end if;
 v_parish:=case when v_target.requested_role=any(array['Admin','Regional Supervisor','Construction Specialist','Construction Engineer']) then 'All Parishes' else v_target.requested_parish end;
 if v_parish is null then raise exception 'Requested parish is missing'; end if;
 update public.profiles p set role=v_target.requested_role,parish=v_parish,privileges=public.default_privileges(v_target.requested_role),approved=true,active=true,registration_status='approved',approved_by=auth.uid(),approved_at=now(),updated_at=now() where p.user_id=p_user_id returning p.* into v_target;
 insert into public.audit_log(user_id,user_email,action,entity_type,entity_id,parish,details) values(auth.uid(),v_admin.email,'registration.approved','profile',p_user_id::text,v_parish,jsonb_build_object('email',v_target.email,'role',v_target.role,'parish',v_parish));
 return query select v_target.user_id,v_target.email,v_target.role,v_target.parish,v_target.approved,v_target.registration_status;
end;
$$;

create or replace function public.manage_user_access(p_user_id uuid,p_action text,p_role text default null,p_parish text default null,p_privileges jsonb default null)
returns jsonb language plpgsql security definer set search_path to 'public'
as $$
declare v_admin public.profiles%rowtype; v_target public.profiles%rowtype; v_parish text;
begin
 select * into v_admin from public.profiles where user_id=auth.uid();
 if not found or not v_admin.approved or not v_admin.active or v_admin.role<>'Admin' or not public.has_privilege('manageUsers') then raise exception 'Admin user-management privilege required'; end if;
 if p_user_id=auth.uid() and p_action in ('block','suspend') then raise exception 'You cannot restrict your own signed-in account'; end if;
 select * into v_target from public.profiles where user_id=p_user_id for update;
 if not found then raise exception 'User not found'; end if;
 if p_action='suspend' then update public.profiles set approved=false,active=false,registration_status='suspended',updated_at=now() where user_id=p_user_id;
 elsif p_action='block' then update public.profiles set approved=false,active=false,registration_status='blocked',updated_at=now() where user_id=p_user_id;
 elsif p_action='restore' then update public.profiles set approved=true,active=true,registration_status='approved',updated_at=now() where user_id=p_user_id;
 elsif p_action='promote' then
   if p_role is null or p_role <> all(array['Admin','Regional Supervisor','Construction Specialist','Construction Engineer','Site Supervisor','Technical Admin','Community Admin','Carpenter','Worker','Apprentice']) then raise exception 'Invalid role'; end if;
   v_parish:=case when p_role=any(array['Admin','Regional Supervisor','Construction Specialist','Construction Engineer']) then 'All Parishes' else nullif(trim(coalesce(p_parish,'')),'') end;
   if v_parish is null then raise exception 'Parish is required for this role'; end if;
   update public.profiles set role=p_role,parish=v_parish,privileges=public.default_privileges(p_role),approved=true,active=true,registration_status='approved',approved_by=auth.uid(),approved_at=now(),updated_at=now() where user_id=p_user_id;
 elsif p_action='set_privileges' then
   if not public.has_privilege('managePrivileges') then raise exception 'Privilege management required'; end if;
   update public.profiles set privileges=public.default_privileges(coalesce(v_target.role,'')) || coalesce(p_privileges,'{}'::jsonb),updated_at=now() where user_id=p_user_id;
 else raise exception 'Unsupported management action'; end if;
 insert into public.audit_log(user_id,user_email,action,entity_type,entity_id,parish,details) values(auth.uid(),v_admin.email,'user.'||p_action,'profile',p_user_id::text,coalesce(p_parish,v_target.parish),jsonb_build_object('targetEmail',v_target.email,'role',p_role,'privileges',p_privileges));
 return jsonb_build_object('ok',true,'action',p_action,'userId',p_user_id);
end;
$$;

create or replace function public.list_managed_users()
returns table(user_id uuid,email text,full_name text,role text,parish text,approved boolean,active boolean,registration_status text,privileges jsonb,last_seen timestamptz)
language plpgsql security definer set search_path to 'public'
as $$
begin
 if not public.has_privilege('manageUsers') then raise exception 'User management privilege required'; end if;
 return query
 select p.user_id,p.email,coalesce(p.full_name,''),coalesce(p.role,''),coalesce(p.parish,''),p.approved,p.active,p.registration_status,p.privileges,p.last_seen
 from public.profiles p
 order by p.approved desc,p.full_name nulls last,p.email;
end;
$$;

create or replace function public.list_registration_requests()
returns table(user_id uuid,email text,full_name text,requested_role text,requested_parish text,registration_status text,created_at timestamptz,role_requested_at timestamptz)
language plpgsql security definer set search_path to 'public'
as $$
begin
 if not public.has_privilege('manageUsers') then raise exception 'User management privilege required'; end if;
 return query
 select p.user_id,p.email,p.full_name,p.requested_role,p.requested_parish,p.registration_status,p.created_at,p.role_requested_at
 from public.profiles p
 where not p.approved and p.registration_status='pending'
 order by coalesce(p.role_requested_at,p.created_at) desc;
end;
$$;

create or replace function public.reject_registration_request(p_user_id uuid)
returns boolean language plpgsql security definer set search_path to 'public'
as $$
declare v_admin public.profiles%rowtype; v_target public.profiles%rowtype;
begin
 select * into v_admin from public.profiles where user_id=auth.uid();
 if not found or not v_admin.approved or not v_admin.active or not public.has_privilege('manageUsers') then raise exception 'User management privilege required'; end if;
 select * into v_target from public.profiles where user_id=p_user_id;
 if not found then raise exception 'Registration request not found'; end if;
 update public.profiles set role=null,parish=null,privileges='{}'::jsonb,approved=false,active=false,registration_status='rejected',approved_by=auth.uid(),approved_at=now(),updated_at=now() where user_id=p_user_id;
 insert into public.audit_log(user_id,user_email,action,entity_type,entity_id,details)
 values(auth.uid(),v_admin.email,'registration.rejected','profile',p_user_id::text,jsonb_build_object('email',v_target.email,'requestedRole',v_target.requested_role));
 return true;
end;
$$;

create or replace function public.set_parish_live_tracker(p_parish text,p_url text,p_enabled boolean default true)
returns jsonb language plpgsql security definer set search_path to 'public'
as $$
declare v_row public.parish_live_trackers%rowtype;
begin
 if not (public.has_privilege('manageFolders') or public.has_privilege('manageUsers')) then raise exception 'Map administration privilege required'; end if;
 if p_parish is null or trim(p_parish)='' or p_url is null or trim(p_url)='' then raise exception 'Parish and URL are required'; end if;
 insert into public.parish_live_trackers(parish,url,enabled,updated_by,updated_at)
 values(trim(p_parish),trim(p_url),coalesce(p_enabled,true),auth.uid(),now())
 on conflict(parish) do update set url=excluded.url,enabled=excluded.enabled,updated_by=auth.uid(),updated_at=now()
 returning * into v_row;
 return to_jsonb(v_row);
end;
$$;

-- Rebase existing approved accounts onto the expanded defaults while preserving overrides.
update public.profiles set privileges=public.default_privileges(role)||privileges,updated_at=now() where role is not null;

-- ---------- Presence ----------
drop function if exists public.list_active_users();
create function public.list_active_users()
returns table(user_id uuid,email text,full_name text,role text,parish text,privileges jsonb,active boolean,"lastSeen" timestamptz)
language sql stable security definer set search_path to 'public'
as $$
 select p.user_id,p.email,coalesce(p.full_name,''),coalesce(p.role,''),coalesce(p.parish,''),
   case when public.has_privilege('manageUsers') then p.privileges else '{}'::jsonb end,
   (p.approved=true and p.active=true and p.last_seen>now()-interval '3 minutes'),p.last_seen
 from public.profiles p
 where p.approved=true and p.registration_status='approved'
   and (public.can_view_all_parishes() or p.parish=public.current_parish() or p.user_id=auth.uid())
 order by (p.last_seen>now()-interval '3 minutes') desc,p.last_seen desc nulls last
 limit 500;
$$;

-- ---------- Beneficiary import/search ----------
create or replace function public.upsert_beneficiary_directory(p_rows jsonb)
returns integer language plpgsql security definer set search_path to 'public'
as $$
declare v_item jsonb; v_count integer:=0; v_house text; v_parish text; v_lat double precision; v_lon double precision; v_source jsonb;
begin
 if auth.uid() is null then raise exception 'Authentication required'; end if;
 if not (public.can_view_all_parishes() or public.has_privilege('manageBeneficiarySources') or public.has_privilege('manageUsers')) then raise exception 'Beneficiary import privilege required'; end if;
 if jsonb_typeof(p_rows)<>'array' then raise exception 'Rows must be a JSON array'; end if;
 for v_item in select value from jsonb_array_elements(p_rows) loop
   v_house:=upper(trim(coalesce(v_item->>'house_code',''))); v_parish:=nullif(trim(coalesce(v_item->>'parish','')),'');
   if v_house='' or coalesce(v_item->>'beneficiary_name','')='' then continue; end if;
   if v_parish is not null and not public.can_access_parish(v_parish) and not public.can_view_all_parishes() then raise exception 'Parish import access denied'; end if;
   v_lat:=nullif(v_item->>'latitude','')::double precision; v_lon:=nullif(v_item->>'longitude','')::double precision;
   v_source:=coalesce(v_item->'raw',v_item);
   insert into public.beneficiary_directory(house_code,beneficiary_name,parish,cluster,phone,gps,source_name,source_row,source_payload,updated_by,updated_at,beneficiary_number,latitude,longitude,maps_url)
   values(v_house,trim(v_item->>'beneficiary_name'),v_parish,nullif(trim(coalesce(v_item->>'cluster','')),''),nullif(trim(coalesce(v_item->>'phone','')),''),nullif(trim(coalesce(v_item->>'gps','')),''),coalesce(nullif(v_item->>'source_name',''),'Shelter Roof Repair Assessment'),nullif(v_item->>'source_row','')::integer,v_source,auth.uid(),now(),nullif(v_item->>'beneficiary_number',''),v_lat,v_lon,case when v_lat is not null and v_lon is not null then 'https://www.google.com/maps/search/?api=1&query='||v_lat||','||v_lon else null end)
   on conflict(house_code) do update set beneficiary_name=excluded.beneficiary_name,parish=excluded.parish,cluster=excluded.cluster,phone=excluded.phone,gps=excluded.gps,source_name=excluded.source_name,source_row=excluded.source_row,source_payload=excluded.source_payload,updated_by=excluded.updated_by,updated_at=now(),beneficiary_number=coalesce(excluded.beneficiary_number,public.beneficiary_directory.beneficiary_number),latitude=excluded.latitude,longitude=excluded.longitude,maps_url=excluded.maps_url;
   v_count:=v_count+1;
 end loop;
 insert into public.audit_log(user_id,user_email,action,entity_type,details) values(auth.uid(),public.current_email(),'beneficiary.bulk_upsert','beneficiary_directory',jsonb_build_object('rows',v_count));
 return v_count;
end;
$$;

drop function if exists public.search_beneficiaries(text,integer);
create function public.search_beneficiaries(p_query text default '',p_limit integer default 100)
returns table(house_code text,beneficiary_name text,parish text,cluster text,phone text,gps text,latitude double precision,longitude double precision,maps_url text,source_payload jsonb)
language sql stable security definer set search_path to 'public'
as $$
 select b.house_code,b.beneficiary_name,coalesce(b.parish,''),coalesce(b.cluster,''),coalesce(b.phone,''),coalesce(b.gps,''),b.latitude,b.longitude,b.maps_url,b.source_payload
 from public.beneficiary_directory b
 where auth.uid() is not null
   and public.can_access_parish(b.parish)
   and (coalesce(trim(p_query),'')='' or b.house_code ilike '%'||trim(p_query)||'%' or b.beneficiary_name ilike '%'||trim(p_query)||'%' or coalesce(b.cluster,'') ilike '%'||trim(p_query)||'%')
 order by b.house_code limit greatest(1,least(coalesce(p_limit,100),500));
$$;

-- ---------- Expanded event visibility / write contract ----------
create or replace function public.event_visible(p_type text,p_parish text,p_recipients jsonb,p_created_by uuid)
returns boolean language plpgsql stable security definer set search_path to 'public'
as $$
declare v_role text:=public.current_role();
begin
 if auth.uid() is null then return false; end if;
 if p_created_by=auth.uid() then return true; end if;
 if public.recipient_targets_me(p_recipients) then return true; end if;
 if p_type='communityPost' then return p_parish is null or p_parish='' or p_parish='All Parishes' or public.can_view_all_parishes() or p_parish=public.current_parish(); end if;
 if p_type='communitySuggestion' then return v_role='Admin'; end if;
 if p_type='signatureRequest' then return public.can_access_parish(p_parish) and (public.has_privilege('editControl') or public.has_privilege('reviewControl')); end if;
 if public.is_crew_role(v_role) then
   return p_type in ('house','crewAttendance','dailyLog','materialRequest','consumables','workLog','issue','signatureRequest');
 end if;
 if p_type='house' then return public.can_access_parish(p_parish); end if;
 if p_type='scope' then return public.can_access_parish(p_parish) and (public.has_privilege('submitScope') or public.has_privilege('approveScope') or public.has_privilege('viewAdmin')); end if;
 if p_type='controlRequest' then return public.can_access_parish(p_parish) and (public.has_privilege('reviewControl') or public.has_privilege('viewAdmin')); end if;
 if p_type in ('controlData','workPlan','workProjection','constructionSchedule','crewAttendance','workLog','monitoring','siteVisit','dailyLog','documentChecklist','materialRequest','consumables','inventory') then return public.can_access_parish(p_parish) and (public.has_privilege('editControl') or public.has_privilege('reviewControl') or public.has_privilege('viewAdmin')); end if;
 if p_type in ('payment','notice') then return public.can_access_parish(p_parish) and (public.has_privilege('editControl') or public.has_privilege('reviewPayments') or public.has_privilege('approveNotice') or public.has_privilege('viewAdmin')); end if;
 if p_type='privilege' then return public.has_privilege('manageUsers'); end if;
 if p_type='issue' then return public.can_access_parish(p_parish) and public.has_privilege('raiseIssues'); end if;
 if exists(select 1 from public.record_form_templates f where f.event_type=p_type and f.active=true) then
   return public.can_access_parish(p_parish) and (public.has_privilege('editControl') or public.has_privilege('reviewControl') or public.has_privilege('viewAdmin'));
 end if;
 return false;
end;
$$;

create or replace function public.upsert_app_event(p_event jsonb)
returns jsonb language plpgsql security definer set search_path to 'public'
as $$
declare
 v_uid uuid:=auth.uid(); v_email text; v_role text; v_type text:=coalesce(p_event->>'type',p_event->>'event_type',''); v_item jsonb:=coalesce(p_event->'item','{}'::jsonb); v_item_id text; v_parish text; v_house text; v_recipients jsonb; v_existing public.app_events%rowtype; v_status text; v_row public.app_events%rowtype; v_is_crew boolean;
begin
 if v_uid is null then raise exception 'Authentication required'; end if;
 select email,role into v_email,v_role from public.profiles where user_id=v_uid and approved=true and active=true;
 if v_email is null or v_role is null then raise exception 'Account is not approved or active'; end if;
 v_is_crew:=public.is_crew_role(v_role);
 if v_type not in ('house','message','task','issue','scope','controlRequest','controlData','workPlan','workProjection','constructionSchedule','crewAttendance','workLog','monitoring','siteVisit','dailyLog','documentChecklist','materialRequest','consumables','inventory','payment','notice','privilege','communityPost','communitySuggestion','signatureRequest')
    and not exists(select 1 from public.record_form_templates f where f.event_type=v_type and f.active=true) then
   raise exception 'Unsupported event type';
 end if;
 if v_type='message' then v_item:=jsonb_set(v_item,'{fromEmail}',to_jsonb(v_email),true); v_item:=jsonb_set(v_item,'{fromRole}',to_jsonb(v_role),true); end if;
 v_item_id:=coalesce(nullif(v_item->>'id',''),nullif(p_event->>'item_id',''),case when v_type='house' then upper(trim(v_item->>'houseCode')) else null end);
 if coalesce(v_item_id,'')='' then raise exception 'Event item ID is required'; end if;
 v_parish:=coalesce(nullif(v_item#>>'{project,parish}',''),nullif(v_item->>'parish',''),nullif(v_item#>>'{form,parish}',''),nullif(p_event->>'parish',''));
 if v_parish='All Parishes' then v_parish:=null; end if;
 v_house:=coalesce(nullif(v_item->>'houseCode',''),nullif(v_item#>>'{project,houseCode}',''),nullif(v_item#>>'{form,houseCode}',''),nullif(p_event->>'house_code',''));
 if v_house is not null then v_house:=upper(trim(v_house)); end if;
 if v_parish is null and v_house is not null then select parish into v_parish from public.app_events where event_type='house' and upper(house_code)=v_house order by updated_at desc limit 1; end if;
 v_recipients:=coalesce(v_item->'recipients',p_event->'recipients','[]'::jsonb); v_status:=coalesce(v_item->>'status',v_item#>>'{form,status}','');
 if v_is_crew then
   if v_type in ('message','communitySuggestion') then
     null;
   elsif v_type in ('issue','dailyLog','materialRequest','consumables','workLog','signatureRequest','crewAttendance') then
     if v_house is null or not public.crew_can_access_house(v_house) then raise exception 'Assigned house access required'; end if;
   else
     raise exception 'Crew role cannot write this record type';
   end if;
   if v_type in ('materialRequest','consumables') and not public.has_privilege('submitFieldRequests') then raise exception 'Field-request privilege required'; end if;
 end if;
 if v_type='communityPost' and not (v_role='Admin' and public.has_privilege('manageCommunity')) then raise exception 'Admin community-publishing privilege required'; end if;
 if v_type='communitySuggestion' then v_recipients:='[{"type":"role","value":"Admin"}]'::jsonb; end if;
 if v_type='signatureRequest' and not (v_is_crew or public.has_privilege('editControl') or public.has_privilege('reviewControl')) then raise exception 'Signature request privilege required'; end if;
 if v_type='house' then
  if coalesce(v_item->>'stage','') not in ('Not Started','Site Preparation','Demolition','Wall Plate','Rafters / Collars','Battens','Roof Sheeting','Fascia & Blocking','Finishing','Final Inspection','Completed') then raise exception 'Invalid construction phase'; end if;
  v_item:=jsonb_set(v_item,'{progress}',to_jsonb(case v_item->>'stage' when 'Not Started' then 0 when 'Site Preparation' then 5 when 'Demolition' then 15 when 'Wall Plate' then 30 when 'Rafters / Collars' then 45 when 'Battens' then 58 when 'Roof Sheeting' then 72 when 'Fascia & Blocking' then 84 when 'Finishing' then 92 when 'Final Inspection' then 97 when 'Completed' then 100 else 0 end),true);
 end if;
 select * into v_existing from public.app_events where event_type=v_type and item_id=v_item_id;
 if found then
   if v_type='message' and v_existing.created_by<>v_uid then
     if not public.event_visible(v_existing.event_type,v_existing.parish,v_existing.recipients,v_existing.created_by) then raise exception 'Message is not visible'; end if;
     v_item:=jsonb_set(v_existing.item,'{readBy}',coalesce(v_existing.item->'readBy','[]'::jsonb)||to_jsonb(array[v_email]),true); v_parish:=v_existing.parish; v_house:=v_existing.house_code; v_recipients:=v_existing.recipients;
   elsif v_type='task' and v_existing.created_by<>v_uid then
     if not public.event_visible(v_existing.event_type,v_existing.parish,v_existing.recipients,v_existing.created_by) then raise exception 'Task is not visible'; end if;
     v_item:=jsonb_set(v_existing.item,'{completedBy}',coalesce(v_existing.item->'completedBy','[]'::jsonb)||to_jsonb(array[v_email]),true); v_parish:=v_existing.parish; v_house:=v_existing.house_code; v_recipients:=v_existing.recipients;
   else
     if v_existing.created_by<>v_uid and v_is_crew then raise exception 'Crew users may only edit their own records'; end if;
     if v_type='scope' and v_status in ('Approved','Returned') and not public.has_privilege('approveScope') then raise exception 'Scope approval privilege required'; end if;
     if v_type='controlRequest' and v_status in ('Approved','Returned') and not public.has_privilege('reviewControl') then raise exception 'reviewControl privilege required'; end if;
     if v_type='house' and (not public.has_privilege('editControl') or not public.can_access_parish(v_parish)) then raise exception 'House edit not permitted'; end if;
     if not v_is_crew and v_type in ('controlData','workPlan','workProjection','constructionSchedule','crewAttendance','workLog','monitoring','siteVisit','dailyLog','documentChecklist','materialRequest','consumables','inventory','notice','payment') and not (public.has_privilege('editControl') or public.has_privilege('reviewControl')) then raise exception 'Production-control privilege required'; end if;
     if v_type='issue' and not public.has_privilege('raiseIssues') then raise exception 'raiseIssues privilege required'; end if;
     if exists(select 1 from public.record_form_templates f where f.event_type=v_type and f.active=true)
        and not (public.has_privilege('editControl') or public.has_privilege('reviewControl')) then raise exception 'Custom-form production privilege required'; end if;
     update public.app_events set parish=v_parish,house_code=v_house,recipients=v_recipients,item=v_item,updated_at=now() where id=v_existing.id returning * into v_row;
   end if;
   if v_row.id is null then update public.app_events set parish=v_parish,house_code=v_house,recipients=v_recipients,item=v_item,updated_at=now() where id=v_existing.id returning * into v_row; end if;
 else
   if v_parish is not null and not public.can_access_parish(v_parish) and not v_is_crew then raise exception 'Parish access denied'; end if;
   if v_type='scope' and v_status in ('Pending Regional Approval','Submitted') and not public.has_privilege('submitScope') then raise exception 'submitScope privilege is required'; end if;
   if v_type='controlRequest' and v_status<>'Submitted for Review' then raise exception 'Control request must be Submitted for Review'; end if;
   if v_type in ('message','task') and jsonb_array_length(v_recipients)=0 then raise exception 'At least one recipient is required'; end if;
   if not v_is_crew and v_type in ('controlData','workPlan','workProjection','constructionSchedule','crewAttendance','workLog','monitoring','siteVisit','dailyLog','documentChecklist','materialRequest','consumables','inventory','notice','payment') and not (public.has_privilege('editControl') or public.has_privilege('reviewControl')) then raise exception 'Production-control privilege required'; end if;
   if exists(select 1 from public.record_form_templates f where f.event_type=v_type and f.active=true)
      and not (public.has_privilege('editControl') or public.has_privilege('reviewControl')) then raise exception 'Custom-form production privilege required'; end if;
   insert into public.app_events(event_type,item_id,parish,house_code,recipients,item,created_by,created_by_email) values(v_type,v_item_id,v_parish,v_house,v_recipients,v_item,v_uid,v_email) returning * into v_row;
 end if;
 insert into public.audit_log(user_id,user_email,action,entity_type,entity_id,parish,details) values(v_uid,v_email,'event.upsert',v_type,v_item_id,v_parish,jsonb_build_object('status',v_status,'houseCode',v_house));
 return jsonb_build_object('ok',true,'event',jsonb_build_object('type',v_row.event_type,'item',v_row.item,'_serverId',v_row.id,'_serverUpdatedAt',v_row.updated_at));
end;
$$;

create or replace function public.delete_app_event(p_event_type text,p_item_id text)
returns boolean language plpgsql security definer set search_path to 'public'
as $$
declare v_row public.app_events%rowtype;
begin
 if not public.has_privilege('manageUsers') and public.current_role()<>'Admin' then raise exception 'Admin privilege required'; end if;
 select * into v_row from public.app_events where event_type=p_event_type and item_id=p_item_id;
 if not found then return false; end if;
 delete from public.app_events where id=v_row.id;
 insert into public.audit_log(user_id,user_email,action,entity_type,entity_id,parish,details) values(auth.uid(),public.current_email(),'event.delete',p_event_type,p_item_id,v_row.parish,jsonb_build_object('houseCode',v_row.house_code));
 return true;
end;
$$;

-- Replace app-events select policy so new event types respect the new event_visible contract.
drop policy if exists app_events_select on public.app_events;
create policy app_events_select on public.app_events for select to authenticated
using (
  public.event_visible(event_type,parish,recipients,created_by)
  and (
    not public.is_crew_role(public.current_role())
    or event_type in ('message','communityPost','communitySuggestion')
    or (house_code is not null and public.crew_can_access_house(house_code))
  )
);

commit;
