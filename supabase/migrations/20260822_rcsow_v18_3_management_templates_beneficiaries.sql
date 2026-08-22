-- RC SOW v18.3 production management extensions.
-- Apply after the existing v18.x migrations.

alter table if exists public.profiles
  add column if not exists active boolean not null default true;

create table if not exists public.beneficiary_directory (
  house_code text primary key,
  beneficiary_name text not null,
  parish text not null,
  cluster text,
  phone text,
  gps text,
  latitude double precision,
  longitude double precision,
  maps_url text,
  source_name text,
  source_row integer,
  updated_at timestamptz not null default now()
);

alter table public.beneficiary_directory enable row level security;

drop policy if exists beneficiary_directory_authenticated_read on public.beneficiary_directory;
create policy beneficiary_directory_authenticated_read
on public.beneficiary_directory for select
to authenticated
using (true);

create table if not exists public.document_templates (
  template_key text primary key,
  display_name text not null,
  file_name text not null,
  mime_type text not null,
  storage_path text not null,
  active boolean not null default true,
  updated_by uuid,
  updated_at timestamptz not null default now()
);

alter table public.document_templates enable row level security;

drop policy if exists document_templates_authenticated_read on public.document_templates;
create policy document_templates_authenticated_read
on public.document_templates for select
to authenticated
using (active = true);

insert into storage.buckets (id, name, public)
values ('document-templates', 'document-templates', false)
on conflict (id) do nothing;

create or replace function public.list_managed_users()
returns table (
  user_id uuid,
  email text,
  full_name text,
  role text,
  parish text,
  approved boolean,
  active boolean,
  registration_status text,
  privileges jsonb
)
language sql
security definer
set search_path = public
as $$
  select p.user_id, p.email, p.full_name, p.role, p.parish, p.approved,
         coalesce(p.active, true),
         coalesce(r.status, case when p.approved then 'approved' else 'pending' end),
         coalesce(p.privileges, '{}'::jsonb)
  from public.profiles p
  left join public.registration_requests r on r.user_id = p.user_id
  order by lower(coalesce(p.full_name, p.email));
$$;

grant execute on function public.list_managed_users() to authenticated;

create or replace function public.search_beneficiaries(p_query text default '', p_limit integer default 100)
returns setof public.beneficiary_directory
language sql
security definer
set search_path = public
as $$
  select *
  from public.beneficiary_directory
  where coalesce(p_query, '') = ''
     or house_code ilike '%' || p_query || '%'
     or beneficiary_name ilike '%' || p_query || '%'
     or parish ilike '%' || p_query || '%'
     or coalesce(cluster, '') ilike '%' || p_query || '%'
  order by parish, house_code
  limit greatest(1, least(coalesce(p_limit, 100), 500));
$$;

grant execute on function public.search_beneficiaries(text, integer) to authenticated;

create or replace function public.manage_user_access(
  p_user_id uuid,
  p_action text,
  p_role text default null,
  p_parish text default null,
  p_privileges jsonb default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  actor public.profiles;
begin
  select * into actor from public.profiles where user_id = auth.uid();
  if actor.user_id is null or actor.role <> 'Admin' or coalesce((actor.privileges->>'manageUsers')::boolean, false) is not true then
    raise exception 'Admin manageUsers privilege required';
  end if;

  if p_action in ('block', 'suspend') then
    update public.profiles set active = false where user_id = p_user_id;
  elsif p_action = 'restore' then
    update public.profiles set active = true where user_id = p_user_id;
  elsif p_action = 'update' then
    update public.profiles
      set role = coalesce(p_role, role),
          parish = coalesce(p_parish, parish),
          privileges = coalesce(p_privileges, privileges)
    where user_id = p_user_id;
  else
    raise exception 'Unsupported access action: %', p_action;
  end if;
end;
$$;

grant execute on function public.manage_user_access(uuid, text, text, text, jsonb) to authenticated;

create or replace function public.upsert_beneficiary_directory(p_rows jsonb)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  actor public.profiles;
  inserted_count integer;
begin
  select * into actor from public.profiles where user_id = auth.uid();
  if actor.user_id is null or not (
    actor.role = 'Admin'
    or coalesce((actor.privileges->>'viewAllParishes')::boolean, false)
  ) then
    raise exception 'Management privilege required';
  end if;

  insert into public.beneficiary_directory (
    house_code, beneficiary_name, parish, cluster, phone, gps,
    latitude, longitude, maps_url, source_name, source_row, updated_at
  )
  select
    upper(trim(x.house_code)), trim(x.beneficiary_name), trim(x.parish),
    nullif(trim(x.cluster), ''), nullif(trim(x.phone), ''), nullif(trim(x.gps), ''),
    x.latitude, x.longitude, nullif(trim(x.maps_url), ''),
    nullif(trim(x.source_name), ''), x.source_row, now()
  from jsonb_to_recordset(p_rows) as x(
    house_code text, beneficiary_name text, parish text, cluster text,
    phone text, gps text, latitude double precision, longitude double precision,
    maps_url text, source_name text, source_row integer
  )
  on conflict (house_code) do update set
    beneficiary_name = excluded.beneficiary_name,
    parish = excluded.parish,
    cluster = excluded.cluster,
    phone = excluded.phone,
    gps = excluded.gps,
    latitude = excluded.latitude,
    longitude = excluded.longitude,
    maps_url = excluded.maps_url,
    source_name = excluded.source_name,
    source_row = excluded.source_row,
    updated_at = now();

  get diagnostics inserted_count = row_count;
  return inserted_count;
end;
$$;

grant execute on function public.upsert_beneficiary_directory(jsonb) to authenticated;
