-- RC SOW v18.3.1 source/backend alignment.
-- Idempotent hardening migration. Apply after v18.3 management migration.

alter table if exists public.document_templates enable row level security;

drop policy if exists document_templates_authenticated_read on public.document_templates;
drop policy if exists document_templates_read on public.document_templates;
create policy document_templates_read
on public.document_templates
for select
to authenticated
using (true);

drop policy if exists document_templates_write on public.document_templates;
create policy document_templates_write
on public.document_templates
for all
to authenticated
using (
  public.has_privilege('manageFolders')
  or public.has_privilege('manageUsers')
)
with check (
  public.has_privilege('manageFolders')
  or public.has_privilege('manageUsers')
);

drop policy if exists beneficiary_directory_authenticated_read on public.beneficiary_directory;
drop policy if exists beneficiary_directory_select on public.beneficiary_directory;
create policy beneficiary_directory_select
on public.beneficiary_directory
for select
to authenticated
using (
  (select auth.uid()) is not null
  and (
    parish is null
    or parish = ''
    or public.can_access_parish(parish)
    or (select public.can_view_all_parishes())
  )
);

insert into storage.buckets (id, name, public)
values ('document-templates', 'document-templates', false)
on conflict (id) do update set public = excluded.public;

drop policy if exists rc_sow_document_templates_read on storage.objects;
create policy rc_sow_document_templates_read
on storage.objects
for select
to authenticated
using (bucket_id = 'document-templates');

drop policy if exists rc_sow_document_templates_insert on storage.objects;
create policy rc_sow_document_templates_insert
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'document-templates'
  and (
    public.has_privilege('manageFolders')
    or public.has_privilege('manageUsers')
  )
);

drop policy if exists rc_sow_document_templates_update on storage.objects;
create policy rc_sow_document_templates_update
on storage.objects
for update
to authenticated
using (
  bucket_id = 'document-templates'
  and (
    public.has_privilege('manageFolders')
    or public.has_privilege('manageUsers')
  )
)
with check (
  bucket_id = 'document-templates'
  and (
    public.has_privilege('manageFolders')
    or public.has_privilege('manageUsers')
  )
);

drop policy if exists rc_sow_document_templates_delete on storage.objects;
create policy rc_sow_document_templates_delete
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'document-templates'
  and (
    public.has_privilege('manageFolders')
    or public.has_privilege('manageUsers')
  )
);

drop function if exists public.list_managed_users();
create function public.list_managed_users()
returns table (
  user_id uuid,
  email text,
  full_name text,
  role text,
  parish text,
  approved boolean,
  active boolean,
  registration_status text,
  privileges jsonb,
  last_seen timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.has_privilege('manageUsers') then
    raise exception 'User management privilege required';
  end if;

  return query
  select
    p.user_id,
    p.email,
    coalesce(p.full_name, ''),
    coalesce(p.role, ''),
    coalesce(p.parish, ''),
    p.approved,
    p.active,
    p.registration_status,
    p.privileges,
    p.last_seen
  from public.profiles p
  order by p.approved desc, p.full_name nulls last, p.email;
end;
$$;

grant execute on function public.list_managed_users() to authenticated;

drop function if exists public.search_beneficiaries(text, integer);
create function public.search_beneficiaries(
  p_query text default '',
  p_limit integer default 100
)
returns table (
  house_code text,
  beneficiary_name text,
  parish text,
  cluster text,
  phone text,
  gps text,
  latitude double precision,
  longitude double precision,
  maps_url text
)
language sql
stable
security definer
set search_path = public
as $$
  select
    b.house_code,
    b.beneficiary_name,
    coalesce(b.parish, ''),
    coalesce(b.cluster, ''),
    coalesce(b.phone, ''),
    coalesce(b.gps, ''),
    b.latitude,
    b.longitude,
    b.maps_url
  from public.beneficiary_directory b
  where auth.uid() is not null
    and public.can_access_parish(b.parish)
    and (
      coalesce(trim(p_query), '') = ''
      or b.house_code ilike '%' || trim(p_query) || '%'
      or b.beneficiary_name ilike '%' || trim(p_query) || '%'
      or coalesce(b.cluster, '') ilike '%' || trim(p_query) || '%'
    )
  order by b.house_code
  limit greatest(1, least(coalesce(p_limit, 100), 500));
$$;

grant execute on function public.search_beneficiaries(text, integer) to authenticated;

drop function if exists public.manage_user_access(uuid, text, text, text, jsonb);
create function public.manage_user_access(
  p_user_id uuid,
  p_action text,
  p_role text default null,
  p_parish text default null,
  p_privileges jsonb default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_admin public.profiles%rowtype;
  v_target public.profiles%rowtype;
  v_parish text;
begin
  select * into v_admin
  from public.profiles
  where user_id = auth.uid();

  if not found
    or not v_admin.approved
    or not v_admin.active
    or v_admin.role <> 'Admin'
    or not public.has_privilege('manageUsers') then
    raise exception 'Admin user-management privilege required';
  end if;

  if p_user_id = auth.uid() and p_action in ('block', 'suspend') then
    raise exception 'You cannot restrict your own signed-in account';
  end if;

  select * into v_target
  from public.profiles
  where user_id = p_user_id
  for update;

  if not found then
    raise exception 'User not found';
  end if;

  if p_action = 'suspend' then
    update public.profiles
    set approved = false,
        active = false,
        registration_status = 'suspended',
        updated_at = now()
    where user_id = p_user_id;
  elsif p_action = 'block' then
    update public.profiles
    set approved = false,
        active = false,
        registration_status = 'blocked',
        updated_at = now()
    where user_id = p_user_id;
  elsif p_action = 'restore' then
    update public.profiles
    set approved = true,
        active = true,
        registration_status = 'approved',
        updated_at = now()
    where user_id = p_user_id;
  elsif p_action in ('promote', 'update') then
    if p_role is null or p_role <> all(array[
      'Admin',
      'Regional Supervisor',
      'Construction Specialist',
      'Construction Engineer',
      'Site Supervisor',
      'Technical Admin',
      'Community Admin'
    ]) then
      raise exception 'Invalid role';
    end if;

    v_parish := case
      when p_role = any(array[
        'Admin',
        'Regional Supervisor',
        'Construction Specialist',
        'Construction Engineer',
        'Technical Admin'
      ]) then 'All Parishes'
      else nullif(trim(coalesce(p_parish, '')), '')
    end;

    if v_parish is null then
      raise exception 'Parish is required for this role';
    end if;

    if p_action = 'update'
      and p_privileges is not null
      and not public.has_privilege('managePrivileges') then
      raise exception 'Privilege management required';
    end if;

    update public.profiles
    set role = p_role,
        parish = v_parish,
        privileges = case
          when p_action = 'update' and p_privileges is not null
            then p_privileges
          else public.default_privileges(p_role)
        end,
        approved = true,
        active = true,
        registration_status = 'approved',
        approved_by = auth.uid(),
        approved_at = now(),
        updated_at = now()
    where user_id = p_user_id;
  elsif p_action = 'set_privileges' then
    if not public.has_privilege('managePrivileges') then
      raise exception 'Privilege management required';
    end if;

    update public.profiles
    set privileges = coalesce(p_privileges, '{}'::jsonb),
        updated_at = now()
    where user_id = p_user_id;
  else
    raise exception 'Unsupported management action';
  end if;

  insert into public.audit_log(
    user_id,
    user_email,
    action,
    entity_type,
    entity_id,
    parish,
    details
  )
  values (
    auth.uid(),
    v_admin.email,
    'user.' || p_action,
    'profile',
    p_user_id::text,
    coalesce(v_parish, p_parish, v_target.parish),
    jsonb_build_object(
      'targetEmail', v_target.email,
      'role', p_role,
      'privileges', p_privileges
    )
  );

  return jsonb_build_object('ok', true, 'action', p_action, 'userId', p_user_id);
end;
$$;

grant execute on function public.manage_user_access(uuid, text, text, text, jsonb)
to authenticated;

create or replace function public.event_visible(
  p_type text,
  p_parish text,
  p_recipients jsonb,
  p_created_by uuid
)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then return false; end if;
  if p_created_by = auth.uid() then return true; end if;
  if public.recipient_targets_me(p_recipients) then return true; end if;
  if p_type = 'house' then return public.can_access_parish(p_parish); end if;
  if p_type = 'scope' then
    return public.can_access_parish(p_parish)
      and (
        public.has_privilege('submitScope')
        or public.has_privilege('approveScope')
        or public.has_privilege('viewAdmin')
      );
  end if;
  if p_type = 'controlRequest' then
    return public.can_access_parish(p_parish)
      and (
        public.has_privilege('reviewControl')
        or public.has_privilege('viewAdmin')
      );
  end if;
  if p_type in (
    'controlData',
    'workPlan',
    'monitoring',
    'siteVisit',
    'dailyLog',
    'documentChecklist',
    'materialRequest',
    'consumables',
    'inventory'
  ) then
    return public.can_access_parish(p_parish)
      and (
        public.has_privilege('editControl')
        or public.has_privilege('reviewControl')
        or public.has_privilege('viewAdmin')
      );
  end if;
  if p_type in ('payment', 'notice') then
    return public.can_access_parish(p_parish)
      and (
        public.has_privilege('editControl')
        or public.has_privilege('reviewPayments')
        or public.has_privilege('approveNotice')
        or public.has_privilege('viewAdmin')
      );
  end if;
  if p_type = 'privilege' then
    return public.has_privilege('manageUsers');
  end if;
  if p_type = 'issue' then
    return public.can_access_parish(p_parish)
      and public.has_privilege('raiseIssues');
  end if;
  return false;
end;
$$;
