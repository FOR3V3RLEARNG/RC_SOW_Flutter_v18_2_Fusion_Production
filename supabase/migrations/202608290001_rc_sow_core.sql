-- RC SOW protected core schema starter. Review before applying to production.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  role text not null check (role in ('admin','regional_supervisor','construction_specialist','site_supervisor','technical_admin','community_admin','carpenter_lead')),
  assigned_parishes text[] not null default '{}',
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.houses (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  beneficiary_name text not null,
  parish text not null,
  cluster text not null,
  community text not null,
  lifecycle_phase text not null default 'scope',
  status text not null default 'draft',
  progress numeric(5,4) not null default 0 check (progress between 0 and 1),
  evidence_required integer not null default 6,
  version bigint not null default 1,
  created_by uuid not null references public.profiles(id),
  assigned_supervisor uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.operational_records (
  id uuid primary key default gen_random_uuid(),
  house_id uuid not null references public.houses(id) on delete cascade,
  record_type text not null,
  status text not null default 'draft',
  payload jsonb not null default '{}',
  version bigint not null default 1,
  idempotency_key text not null unique,
  created_by uuid not null references public.profiles(id),
  submitted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.evidence (
  id uuid primary key default gen_random_uuid(),
  house_id uuid not null references public.houses(id) on delete cascade,
  record_id uuid references public.operational_records(id) on delete set null,
  evidence_type text not null,
  storage_path text not null,
  caption text not null default '',
  gps point,
  approved boolean not null default false,
  captured_by uuid not null references public.profiles(id),
  captured_at timestamptz not null default now()
);

create table if not exists public.inventory_items (
  id uuid primary key default gen_random_uuid(),
  house_id uuid references public.houses(id) on delete cascade,
  parish text not null,
  material_name text not null,
  unit text not null,
  boq numeric not null default 0,
  delivered numeric not null default 0,
  additions numeric not null default 0,
  leftovers numeric not null default 0,
  storage_location text not null,
  updated_by uuid not null references public.profiles(id),
  updated_at timestamptz not null default now()
);

create table if not exists public.work_logs (
  id uuid primary key default gen_random_uuid(),
  house_id uuid references public.houses(id) on delete set null,
  user_id uuid not null references public.profiles(id),
  parish text not null,
  category text not null,
  detail text not null,
  hours numeric(5,2) not null check (hours >= 0 and hours <= 24),
  worked_at timestamptz not null,
  created_at timestamptz not null default now()
);

create table if not exists public.activity_events (
  id uuid primary key default gen_random_uuid(),
  house_id uuid references public.houses(id) on delete cascade,
  actor_id uuid not null references public.profiles(id),
  event_type text not null,
  title text not null,
  detail text not null,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now()
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  house_id uuid references public.houses(id) on delete cascade,
  priority text not null default 'info',
  title text not null,
  detail text not null,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles(id),
  recipient_id uuid not null references public.profiles(id),
  house_id uuid references public.houses(id) on delete set null,
  body text not null,
  read_at timestamptz,
  archived_at timestamptz,
  created_at timestamptz not null default now()
);

create or replace function public.can_access_house(target_house uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.houses h
    join public.profiles p on p.id = auth.uid() and p.active
    where h.id = target_house
      and (
        p.role in ('admin','regional_supervisor','construction_specialist')
        or h.parish = any(p.assigned_parishes)
        or h.created_by = auth.uid()
        or h.assigned_supervisor = auth.uid()
      )
  );
$$;

create or replace function public.is_active_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin' and active
  );
$$;

alter table public.profiles enable row level security;
alter table public.houses enable row level security;
alter table public.operational_records enable row level security;
alter table public.evidence enable row level security;
alter table public.inventory_items enable row level security;
alter table public.work_logs enable row level security;
alter table public.activity_events enable row level security;
alter table public.notifications enable row level security;
alter table public.messages enable row level security;

create policy profiles_read_self_or_admin on public.profiles for select
using (id = auth.uid() or public.is_active_admin());

create policy houses_scoped_read on public.houses for select using (public.can_access_house(id));
create policy houses_scoped_insert on public.houses for insert with check (created_by = auth.uid());
create policy houses_scoped_update on public.houses for update using (public.can_access_house(id)) with check (public.can_access_house(id));

create policy records_scoped_all on public.operational_records for all
using (public.can_access_house(house_id))
with check (public.can_access_house(house_id) and created_by = auth.uid());

create policy evidence_scoped_all on public.evidence for all
using (public.can_access_house(house_id))
with check (public.can_access_house(house_id) and captured_by = auth.uid());

create policy inventory_scoped_all on public.inventory_items for all
using (house_id is null or public.can_access_house(house_id))
with check (updated_by = auth.uid() and (house_id is null or public.can_access_house(house_id)));

create policy work_logs_owner_and_house on public.work_logs for all
using (user_id = auth.uid() or (house_id is not null and public.can_access_house(house_id)))
with check (user_id = auth.uid() and (house_id is null or public.can_access_house(house_id)));

create policy activity_scoped_read on public.activity_events for select
using (house_id is null or public.can_access_house(house_id));
create policy activity_owner_insert on public.activity_events for insert
with check (actor_id = auth.uid() and (house_id is null or public.can_access_house(house_id)));

create policy notifications_recipient on public.notifications for all
using (recipient_id = auth.uid())
with check (recipient_id = auth.uid());

create policy messages_participants on public.messages for all
using (sender_id = auth.uid() or recipient_id = auth.uid())
with check (sender_id = auth.uid());

create index if not exists houses_parish_phase_idx on public.houses(parish, lifecycle_phase);
create index if not exists records_house_type_idx on public.operational_records(house_id, record_type);
create index if not exists evidence_house_type_idx on public.evidence(house_id, evidence_type);
create index if not exists activity_house_created_idx on public.activity_events(house_id, created_at desc);
create index if not exists work_logs_user_worked_idx on public.work_logs(user_id, worked_at desc);
