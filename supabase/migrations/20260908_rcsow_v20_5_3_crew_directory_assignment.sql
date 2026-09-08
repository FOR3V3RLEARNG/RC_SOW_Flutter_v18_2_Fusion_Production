-- RC SOW v20.5.3
-- Email-first crew authorization + assignment compatibility.

begin;

create or replace function public.can_manage_crew()
returns boolean
language sql
stable
security definer
set search_path to 'public'
as $$
  select coalesce(
    p.approved = true
    and p.active = true
    and (
      p.role in (
        'Admin',
        'Regional Supervisor',
        'Construction Specialist',
        'Construction Engineer',
        'Site Supervisor'
      )
      or coalesce((p.privileges->>'manageCrew')::boolean,false)
    ),
    false
  )
  from public.profiles p
  where p.user_id = auth.uid();
$$;

grant execute on function public.can_manage_crew() to authenticated;

update public.profiles
set privileges =
    coalesce(privileges, '{}'::jsonb) ||
    jsonb_build_object('manageCrew', true)
where approved = true
  and active = true
  and role in (
    'Admin',
    'Regional Supervisor',
    'Construction Specialist',
    'Construction Engineer',
    'Site Supervisor'
  )
  and coalesce((privileges->>'manageCrew')::boolean,false) = false;

create or replace function public.list_crew_directory(
  p_parish text default null
)
returns table(
  user_id uuid,
  email text,
  full_name text,
  role text,
  parish text,
  approved boolean,
  active boolean,
  account_status text
)
language plpgsql
stable
security definer
set search_path to 'public'
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;
  if not public.can_manage_crew() then
    raise exception 'Crew-management privilege required';
  end if;
  if p_parish is not null
     and trim(p_parish) <> ''
     and not public.can_access_parish(trim(p_parish)) then
    raise exception 'Parish access denied';
  end if;

  return query
  with candidates as (
    select
      p.user_id,
      lower(p.email) as email,
      coalesce(nullif(trim(p.full_name),''), p.email) as full_name,
      p.role,
      coalesce(p.parish,'') as parish,
      p.approved,
      p.active,
      case
        when p.approved and p.active then 'Active account'
        else 'Profile pending'
      end as account_status,
      1 as priority
    from public.profiles p
    where p.role in ('Carpenter','Worker','Apprentice')

    union all

    select
      p.user_id,
      lower(a.email) as email,
      coalesce(
        nullif(trim(p.full_name),''),
        nullif(trim(a.label),''),
        a.email
      ) as full_name,
      a.role,
      coalesce(a.parish,'') as parish,
      coalesce(p.approved,false) as approved,
      a.active and coalesce(p.active,true) as active,
      case
        when p.user_id is null then 'Authorized • not signed in'
        else 'Authorized account'
      end as account_status,
      2 as priority
    from public.approval_accounts a
    left join public.profiles p
      on lower(p.email)=lower(a.email)
    where a.active=true
      and a.role in ('Carpenter','Worker','Apprentice')
  ),
  ranked as (
    select distinct on (c.email)
      c.user_id,
      c.email,
      c.full_name,
      c.role,
      c.parish,
      c.approved,
      c.active,
      c.account_status
    from candidates c
    where c.active=true
      and (
        p_parish is null or
        trim(p_parish)='' or
        c.parish=trim(p_parish)
      )
      and (
        public.can_view_all_parishes() or
        c.parish=public.current_parish()
      )
    order by c.email,c.priority desc
  )
  select
    r.user_id,
    r.email,
    r.full_name,
    r.role,
    r.parish,
    r.approved,
    r.active,
    r.account_status
  from ranked r
  order by r.parish,r.role,r.full_name,r.email;
end;
$$;

grant execute on function public.list_crew_directory(text)
to authenticated;

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
declare
  v_email text := lower(trim(coalesce(p_email,'')));
  v_user_id uuid := p_user_id;
  v_profile public.profiles%rowtype;
  v_authorized public.approval_accounts%rowtype;
begin
  if not public.can_manage_crew() then
    raise exception 'Crew-management privilege required';
  end if;
  if p_role not in ('Carpenter','Worker','Apprentice') then
    raise exception 'Invalid crew role';
  end if;
  if v_email='' or position('@' in v_email)=0 then
    raise exception 'Valid crew email required';
  end if;
  if not public.can_access_parish(p_parish) then
    raise exception 'Parish access denied';
  end if;

  select *
  into v_profile
  from public.profiles
  where lower(email)=v_email
  limit 1;

  select *
  into v_authorized
  from public.approval_accounts
  where lower(email)=v_email
    and active=true
  limit 1;

  if v_profile.user_id is null and v_authorized.id is null then
    raise exception 'Crew member must first be authorized by email';
  end if;

  if v_profile.user_id is not null then
    if v_profile.role not in ('Carpenter','Worker','Apprentice') then
      raise exception 'User profile is not a crew role';
    end if;
    if v_profile.role <> p_role then
      raise exception 'Crew role does not match user profile';
    end if;
    if coalesce(v_profile.parish,'') <> p_parish then
      raise exception 'Crew parish does not match house parish';
    end if;
    v_user_id := v_profile.user_id;
  else
    if v_authorized.role <> p_role then
      raise exception 'Crew role does not match authorization';
    end if;
    if coalesce(v_authorized.parish,'') <> p_parish then
      raise exception 'Crew parish does not match house parish';
    end if;
    v_user_id := null;
  end if;

  insert into public.house_crew_assignments(
    house_code,
    parish,
    user_id,
    email,
    member_name,
    role,
    active,
    assigned_by,
    updated_at
  )
  values(
    upper(trim(p_house_code)),
    p_parish,
    v_user_id,
    v_email,
    nullif(trim(coalesce(p_member_name,'')),''),
    p_role,
    p_active,
    auth.uid(),
    now()
  )
  on conflict(house_code,email) do update set
    parish=excluded.parish,
    user_id=excluded.user_id,
    member_name=excluded.member_name,
    role=excluded.role,
    active=excluded.active,
    assigned_by=auth.uid(),
    updated_at=now();

  insert into public.audit_log(
    user_id,
    user_email,
    action,
    entity_type,
    entity_id,
    parish,
    details
  )
  values(
    auth.uid(),
    public.current_email(),
    'crew.assignment',
    'house',
    upper(trim(p_house_code)),
    p_parish,
    jsonb_build_object(
      'email',v_email,
      'role',p_role,
      'active',p_active,
      'linked_user_id',v_user_id
    )
  );

  return jsonb_build_object(
    'ok',true,
    'email',v_email,
    'user_id',v_user_id,
    'active',p_active
  );
end;
$$;

grant execute on function public.assign_house_crew(
  text,text,uuid,text,text,text,boolean
) to authenticated;

create or replace function public.manage_authorized_account(
  p_email text,
  p_label text,
  p_role text,
  p_parish text default null,
  p_active boolean default true,
  p_notify_on_issue boolean default true
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_row public.approval_accounts%rowtype;
  v_parish text;
begin
  if not public.has_privilege('manageUsers') then
    raise exception 'User management privilege required';
  end if;
  if p_role not in (
    'Admin',
    'Regional Supervisor',
    'Construction Specialist',
    'Construction Engineer',
    'Site Supervisor',
    'Technical Admin',
    'Community Admin',
    'Carpenter',
    'Worker',
    'Apprentice'
  ) then
    raise exception 'Invalid role';
  end if;
  if p_email is null or position('@' in p_email)=0 then
    raise exception 'Valid email required';
  end if;

  v_parish := case
    when p_role in (
      'Admin',
      'Regional Supervisor',
      'Construction Specialist',
      'Construction Engineer'
    ) then 'All Parishes'
    else nullif(trim(coalesce(p_parish,'')),'')
  end;

  if v_parish is null then
    raise exception 'Parish required for this role';
  end if;

  insert into public.approval_accounts(
    label,
    email,
    role,
    parish,
    active,
    notify_on_issue,
    updated_by,
    updated_at
  )
  values(
    coalesce(nullif(trim(p_label),''),lower(trim(p_email))),
    lower(trim(p_email)),
    p_role,
    v_parish,
    coalesce(p_active,true),
    coalesce(p_notify_on_issue,true),
    auth.uid(),
    now()
  )
  on conflict(email) do update set
    label=excluded.label,
    role=excluded.role,
    parish=excluded.parish,
    active=excluded.active,
    notify_on_issue=excluded.notify_on_issue,
    updated_by=auth.uid(),
    updated_at=now()
  returning * into v_row;

  update public.profiles
  set role=p_role,
      parish=v_parish,
      approved=case when p_active then true else approved end,
      active=coalesce(p_active,true),
      registration_status=
          case when p_active then 'approved' else registration_status end,
      privileges=public.default_privileges(p_role),
      updated_at=now()
  where lower(email)=lower(trim(p_email));

  insert into public.audit_log(
    user_id,
    user_email,
    action,
    entity_type,
    entity_id,
    parish,
    details
  )
  values(
    auth.uid(),
    public.current_email(),
    'authorized_account.upsert',
    'approval_account',
    v_row.id::text,
    v_parish,
    jsonb_build_object(
      'email',v_row.email,
      'role',v_row.role,
      'active',v_row.active
    )
  );

  return to_jsonb(v_row);
end;
$$;

grant execute on function public.manage_authorized_account(
  text,text,text,text,boolean,boolean
) to authenticated;

drop policy if exists house_crew_assignments_select
on public.house_crew_assignments;

create policy house_crew_assignments_select
on public.house_crew_assignments
for select to authenticated
using (
  public.can_view_all_parishes()
  or (
    public.can_manage_crew()
    and public.can_access_parish(parish)
  )
  or user_id=auth.uid()
  or lower(email)=lower(public.current_email())
  or (
    public.can_access_parish(parish)
    and not public.is_crew_role(public.current_role())
  )
);

drop policy if exists house_crew_assignments_write
on public.house_crew_assignments;

create policy house_crew_assignments_write
on public.house_crew_assignments
for all to authenticated
using (
  public.can_manage_crew()
  and public.can_access_parish(parish)
)
with check (
  public.can_manage_crew()
  and public.can_access_parish(parish)
);

commit;
