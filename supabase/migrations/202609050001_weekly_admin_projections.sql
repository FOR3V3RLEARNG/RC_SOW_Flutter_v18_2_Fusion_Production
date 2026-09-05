-- RC SOW weekly administrative work projection files.
-- One file per authenticated person per week.
-- Role visibility is enforced in RLS.

create table if not exists public.weekly_admin_projections (
  id uuid primary key default gen_random_uuid(),
  week_starting date not null,
  owner_id uuid not null references public.profiles(id) on delete cascade,
  owner_name text not null,
  position text not null,
  parish text not null,
  cluster text not null default '',
  daily_plan jsonb not null default '[]'::jsonb,
  signature_strokes jsonb not null default '[]'::jsonb,
  status text not null default 'draft'
    check (status in ('draft', 'submitted')),
  submitted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (owner_id, week_starting)
);

alter table public.weekly_admin_projections enable row level security;

drop policy if exists weekly_admin_projection_select
  on public.weekly_admin_projections;
drop policy if exists weekly_admin_projection_insert
  on public.weekly_admin_projections;
drop policy if exists weekly_admin_projection_update
  on public.weekly_admin_projections;
drop policy if exists weekly_admin_projection_delete
  on public.weekly_admin_projections;

-- Admin / Construction Specialist / Regional Supervisor:
--   all staff, all parishes.
-- Site Supervisor:
--   all staff files in assigned parish.
-- Technical Admin / Community Admin:
--   owner only.
create policy weekly_admin_projection_select
on public.weekly_admin_projections
for select
to authenticated
using (
  exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.active
      and (
        owner_id = auth.uid()
        or p.role in (
          'admin',
          'regional_supervisor',
          'construction_specialist'
        )
        or (
          p.role = 'site_supervisor'
          and parish = any(p.assigned_parishes)
        )
      )
  )
);

create policy weekly_admin_projection_insert
on public.weekly_admin_projections
for insert
to authenticated
with check (
  owner_id = auth.uid()
  and private.is_active_member()
  and private.can_access_parish(parish)
);

-- Reviewers can read another person’s file but cannot edit it.
create policy weekly_admin_projection_update
on public.weekly_admin_projections
for update
to authenticated
using (
  owner_id = auth.uid()
  and private.is_active_member()
  and status = 'draft'
)
with check (
  owner_id = auth.uid()
  and private.is_active_member()
  and private.can_access_parish(parish)
);

create policy weekly_admin_projection_delete
on public.weekly_admin_projections
for delete
to authenticated
using (
  owner_id = auth.uid()
  and status = 'draft'
  and private.is_active_member()
);

create index if not exists weekly_admin_projection_week_idx
  on public.weekly_admin_projections(
    week_starting,
    parish,
    owner_name
  );

create index if not exists weekly_admin_projection_owner_idx
  on public.weekly_admin_projections(
    owner_id,
    week_starting desc
  );
