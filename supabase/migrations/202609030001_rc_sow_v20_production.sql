-- RC SOW v20 connected production layer.
-- Apply after 202608290001_rc_sow_core.sql. Review in a staging project first.

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
grant usage on schema private to authenticated;

-- Remove the v19 public helper boundary before replacing its policies.
drop policy if exists profiles_read_self_or_admin on public.profiles;
drop policy if exists houses_scoped_read on public.houses;
drop policy if exists houses_scoped_insert on public.houses;
drop policy if exists houses_scoped_update on public.houses;
drop policy if exists records_scoped_all on public.operational_records;
drop policy if exists evidence_scoped_all on public.evidence;
drop policy if exists inventory_scoped_all on public.inventory_items;
drop policy if exists work_logs_owner_and_house on public.work_logs;
drop policy if exists activity_scoped_read on public.activity_events;
drop policy if exists activity_owner_insert on public.activity_events;
drop policy if exists notifications_recipient on public.notifications;
drop policy if exists messages_participants on public.messages;

drop function if exists public.can_access_house(uuid);
drop function if exists public.is_active_admin();

create or replace function private.is_active_member()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.active
  );
$$;

create or replace function private.is_active_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.role in ('admin', 'regional_supervisor', 'construction_specialist')
      and p.active
  );
$$;

create or replace function private.can_access_parish(target_parish text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.active
      and (
        p.role in ('admin', 'regional_supervisor', 'construction_specialist')
        or target_parish = any(p.assigned_parishes)
      )
  );
$$;

create or replace function private.can_access_house(target_house uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.houses h
    join public.profiles p on p.id = auth.uid() and p.active
    where h.id = target_house
      and (
        p.role in ('admin', 'regional_supervisor', 'construction_specialist')
        or h.parish = any(p.assigned_parishes)
        or h.created_by = auth.uid()
        or h.assigned_supervisor = auth.uid()
      )
  );
$$;

revoke all on function private.is_active_member() from public, anon;
revoke all on function private.is_active_admin() from public, anon;
revoke all on function private.can_access_parish(text) from public, anon;
revoke all on function private.can_access_house(uuid) from public, anon;
grant execute on function private.is_active_member() to authenticated;
grant execute on function private.is_active_admin() to authenticated;
grant execute on function private.can_access_parish(text) to authenticated;
grant execute on function private.can_access_house(uuid) to authenticated;

-- A new OAuth user receives an inactive profile. Authorization is assigned by
-- an approved administrator; client-supplied metadata never selects a role.
create or replace function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (
    id,
    full_name,
    role,
    assigned_parishes,
    active
  ) values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data ->> 'full_name', ''), new.email, 'RC SOW user'),
    'site_supervisor',
    '{}',
    false
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_rc_sow on auth.users;
create trigger on_auth_user_created_rc_sow
  after insert on auth.users
  for each row execute procedure private.handle_new_user();

alter table public.work_logs
  add column if not exists progress_percent numeric(5,2) not null default 0
    check (progress_percent between 0 and 100),
  add column if not exists crew_present jsonb not null default '[]'::jsonb,
  add column if not exists materials_used text not null default '',
  add column if not exists blocker text not null default '',
  add column if not exists next_action text not null default '';

create table if not exists public.stock_ledger (
  id uuid primary key default gen_random_uuid(),
  material_code text not null,
  material_name text not null,
  unit text not null,
  tier text not null check (tier in ('parish', 'cluster', 'house')),
  parish text not null,
  cluster text,
  house_id uuid references public.houses(id) on delete cascade,
  location text not null,
  storage_zone text not null default '',
  opening numeric not null default 0 check (opening >= 0),
  received numeric not null default 0 check (received >= 0),
  issued numeric not null default 0 check (issued >= 0),
  adjustments numeric not null default 0,
  minimum_stock numeric not null default 0 check (minimum_stock >= 0),
  unit_cost_jmd numeric not null default 0 check (unit_cost_jmd >= 0),
  version bigint not null default 1,
  updated_by uuid not null references public.profiles(id),
  updated_at timestamptz not null default now(),
  constraint stock_ledger_scope_check check (
    (tier = 'parish' and cluster is null and house_id is null)
    or (tier = 'cluster' and cluster is not null and house_id is null)
    or (tier = 'house' and house_id is not null)
  )
);

create unique index if not exists stock_ledger_scope_material_uidx
  on public.stock_ledger (
    material_code,
    tier,
    parish,
    coalesce(cluster, ''),
    coalesce(house_id, '00000000-0000-0000-0000-000000000000'::uuid),
    location
  );

create table if not exists public.inventory_transfers (
  id uuid primary key default gen_random_uuid(),
  source_stock_id uuid not null references public.stock_ledger(id),
  destination_stock_id uuid not null references public.stock_ledger(id),
  house_id uuid references public.houses(id) on delete set null,
  parish text not null,
  material_code text not null,
  quantity numeric not null check (quantity > 0),
  unit text not null,
  status text not null default 'completed'
    check (status in ('draft', 'pending', 'approved', 'completed', 'cancelled')),
  idempotency_key text not null unique,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now()
);

create table if not exists public.work_projections (
  id uuid primary key default gen_random_uuid(),
  house_id uuid not null references public.houses(id) on delete cascade,
  parish text not null,
  cluster text not null,
  week_starting date not null,
  milestone text not null,
  estimated_hours numeric(7,2) not null check (estimated_hours >= 0),
  actual_hours numeric(7,2) not null default 0 check (actual_hours >= 0),
  crew_needed integer not null check (crew_needed between 1 and 50),
  material_needs text not null default '',
  risks text not null default '',
  status text not null default 'draft'
    check (status in ('draft', 'submitted', 'approved', 'at_risk', 'complete')),
  created_by uuid not null references public.profiles(id),
  approved_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.roof_drawings (
  id uuid primary key default gen_random_uuid(),
  house_id uuid not null references public.houses(id) on delete cascade,
  drawing jsonb not null,
  source text not null default 'field_drawing'
    check (source in ('field_drawing', 'image_proposal', 'legacy_import')),
  source_file_name text,
  ai_confidence numeric(5,4) check (ai_confidence between 0 and 1),
  status text not null default 'draft'
    check (status in ('draft', 'review_required', 'verified', 'submitted')),
  verified_by uuid references public.profiles(id),
  version bigint not null default 1,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.legacy_import_batches (
  id uuid primary key default gen_random_uuid(),
  parish text not null,
  file_name text not null,
  storage_path text,
  row_count integer not null default 0 check (row_count >= 0),
  mappings jsonb not null default '[]'::jsonb,
  warnings jsonb not null default '[]'::jsonb,
  staged_payload jsonb not null default '[]'::jsonb,
  status text not null default 'mapping'
    check (status in ('selected', 'mapping', 'ready', 'queued', 'imported', 'failed')),
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  committed_at timestamptz
);

create table if not exists public.sync_operations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  house_id uuid references public.houses(id) on delete cascade,
  idempotency_key text not null unique,
  record_type text not null,
  payload jsonb not null default '{}'::jsonb,
  state text not null default 'queued'
    check (state in ('queued', 'syncing', 'synced', 'conflict', 'failed')),
  retry_count integer not null default 0 check (retry_count >= 0),
  error_summary text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.stock_ledger enable row level security;
alter table public.inventory_transfers enable row level security;
alter table public.work_projections enable row level security;
alter table public.roof_drawings enable row level security;
alter table public.legacy_import_batches enable row level security;
alter table public.sync_operations enable row level security;

create policy profiles_select_scoped
on public.profiles for select to authenticated
using (id = auth.uid() or private.is_active_admin());

create policy houses_select_scoped
on public.houses for select to authenticated
using (private.can_access_house(id));

create policy houses_insert_scoped
on public.houses for insert to authenticated
with check (
  created_by = auth.uid()
  and private.is_active_member()
  and private.can_access_parish(parish)
);

create policy houses_update_scoped
on public.houses for update to authenticated
using (private.can_access_house(id))
with check (private.can_access_house(id));

create policy records_select_scoped
on public.operational_records for select to authenticated
using (private.can_access_house(house_id));
create policy records_insert_scoped
on public.operational_records for insert to authenticated
with check (created_by = auth.uid() and private.can_access_house(house_id));
create policy records_update_scoped
on public.operational_records for update to authenticated
using (private.can_access_house(house_id))
with check (private.can_access_house(house_id));

create policy evidence_select_scoped
on public.evidence for select to authenticated
using (private.can_access_house(house_id));
create policy evidence_insert_scoped
on public.evidence for insert to authenticated
with check (captured_by = auth.uid() and private.can_access_house(house_id));
create policy evidence_update_scoped
on public.evidence for update to authenticated
using (private.can_access_house(house_id))
with check (private.can_access_house(house_id));

create policy inventory_items_select_scoped
on public.inventory_items for select to authenticated
using (
  private.can_access_parish(parish)
  and (house_id is null or private.can_access_house(house_id))
);
create policy inventory_items_write_scoped
on public.inventory_items for all to authenticated
using (
  private.can_access_parish(parish)
  and (house_id is null or private.can_access_house(house_id))
)
with check (
  updated_by = auth.uid()
  and private.can_access_parish(parish)
  and (house_id is null or private.can_access_house(house_id))
);

create policy work_logs_select_scoped
on public.work_logs for select to authenticated
using (
  user_id = auth.uid()
  or (house_id is not null and private.can_access_house(house_id))
  or private.can_access_parish(parish)
);
create policy work_logs_insert_owner
on public.work_logs for insert to authenticated
with check (
  user_id = auth.uid()
  and private.can_access_parish(parish)
  and (house_id is null or private.can_access_house(house_id))
);
create policy work_logs_update_owner
on public.work_logs for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy activity_select_scoped
on public.activity_events for select to authenticated
using (
  actor_id = auth.uid()
  or (house_id is not null and private.can_access_house(house_id))
  or private.is_active_admin()
);
create policy activity_insert_owner
on public.activity_events for insert to authenticated
with check (
  actor_id = auth.uid()
  and (house_id is null or private.can_access_house(house_id))
);

create policy notifications_recipient_scoped
on public.notifications for all to authenticated
using (recipient_id = auth.uid())
with check (recipient_id = auth.uid());

create policy messages_participants_scoped
on public.messages for select to authenticated
using (sender_id = auth.uid() or recipient_id = auth.uid());
create policy messages_sender_insert
on public.messages for insert to authenticated
with check (
  sender_id = auth.uid()
  and (house_id is null or private.can_access_house(house_id))
);
create policy messages_participants_update
on public.messages for update to authenticated
using (sender_id = auth.uid() or recipient_id = auth.uid())
with check (sender_id = auth.uid() or recipient_id = auth.uid());

create policy stock_ledger_select_scoped
on public.stock_ledger for select to authenticated
using (
  private.can_access_parish(parish)
  and (house_id is null or private.can_access_house(house_id))
);
create policy stock_ledger_write_scoped
on public.stock_ledger for all to authenticated
using (
  private.can_access_parish(parish)
  and (house_id is null or private.can_access_house(house_id))
)
with check (
  updated_by = auth.uid()
  and private.can_access_parish(parish)
  and (house_id is null or private.can_access_house(house_id))
);

create policy inventory_transfers_select_scoped
on public.inventory_transfers for select to authenticated
using (
  private.can_access_parish(parish)
  and (house_id is null or private.can_access_house(house_id))
);
create policy inventory_transfers_insert_scoped
on public.inventory_transfers for insert to authenticated
with check (
  created_by = auth.uid()
  and private.can_access_parish(parish)
  and (house_id is null or private.can_access_house(house_id))
);

create policy projections_select_scoped
on public.work_projections for select to authenticated
using (private.can_access_house(house_id));
create policy projections_insert_scoped
on public.work_projections for insert to authenticated
with check (created_by = auth.uid() and private.can_access_house(house_id));
create policy projections_update_scoped
on public.work_projections for update to authenticated
using (private.can_access_house(house_id))
with check (private.can_access_house(house_id));

create policy roof_drawings_select_scoped
on public.roof_drawings for select to authenticated
using (private.can_access_house(house_id));
create policy roof_drawings_insert_scoped
on public.roof_drawings for insert to authenticated
with check (created_by = auth.uid() and private.can_access_house(house_id));
create policy roof_drawings_update_scoped
on public.roof_drawings for update to authenticated
using (private.can_access_house(house_id))
with check (private.can_access_house(house_id));

create policy legacy_imports_owner_select
on public.legacy_import_batches for select to authenticated
using (
  created_by = auth.uid()
  or (private.is_active_admin() and private.can_access_parish(parish))
);
create policy legacy_imports_owner_insert
on public.legacy_import_batches for insert to authenticated
with check (
  created_by = auth.uid()
  and private.can_access_parish(parish)
);
create policy legacy_imports_owner_update
on public.legacy_import_batches for update to authenticated
using (created_by = auth.uid())
with check (created_by = auth.uid());

create policy sync_operations_owner
on public.sync_operations for all to authenticated
using (user_id = auth.uid())
with check (
  user_id = auth.uid()
  and (house_id is null or private.can_access_house(house_id))
);

create index if not exists stock_ledger_parish_tier_idx
  on public.stock_ledger(parish, tier, updated_at desc);
create index if not exists stock_ledger_house_idx
  on public.stock_ledger(house_id, material_code) where house_id is not null;
create index if not exists work_projections_week_idx
  on public.work_projections(parish, week_starting, status);
create index if not exists roof_drawings_house_updated_idx
  on public.roof_drawings(house_id, updated_at desc);
create index if not exists legacy_imports_owner_created_idx
  on public.legacy_import_batches(created_by, created_at desc);
create index if not exists sync_operations_owner_state_idx
  on public.sync_operations(user_id, state, created_at desc);

create or replace function public.rc_sow_upsert_operational_record(
  p_house_code text,
  p_parish text,
  p_record_type text,
  p_status text,
  p_payload jsonb,
  p_idempotency_key text
)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_house_id uuid;
  v_record_id uuid;
begin
  select h.id
  into v_house_id
  from public.houses h
  where h.code = upper(trim(p_house_code))
    and h.parish = p_parish
    and private.can_access_house(h.id);

  if v_house_id is null then
    raise exception 'House is unavailable for the signed-in user'
      using errcode = '42501';
  end if;

  insert into public.operational_records (
    house_id,
    record_type,
    status,
    payload,
    idempotency_key,
    created_by,
    submitted_at
  ) values (
    v_house_id,
    p_record_type,
    p_status,
    coalesce(p_payload, '{}'::jsonb),
    p_idempotency_key,
    auth.uid(),
    case when p_status = 'submitted' then now() else null end
  )
  on conflict (idempotency_key) do update
  set status = excluded.status,
      payload = excluded.payload,
      version = public.operational_records.version + 1,
      submitted_at = coalesce(excluded.submitted_at, public.operational_records.submitted_at),
      updated_at = now()
  returning id into v_record_id;

  return v_record_id;
end;
$$;

create or replace function public.rc_sow_commit_legacy_import(p_import_id text)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  update public.legacy_import_batches
  set status = 'imported',
      committed_at = now()
  where id::text = p_import_id
    and created_by = auth.uid()
    and status in ('mapping', 'ready', 'queued');

  if not found then
    raise exception 'Import batch is unavailable or already committed'
      using errcode = '42501';
  end if;
end;
$$;

revoke all on function public.rc_sow_upsert_operational_record(text, text, text, text, jsonb, text)
  from public, anon;
revoke all on function public.rc_sow_commit_legacy_import(text)
  from public, anon;
grant execute on function public.rc_sow_upsert_operational_record(text, text, text, text, jsonb, text)
  to authenticated;
grant execute on function public.rc_sow_commit_legacy_import(text)
  to authenticated;
