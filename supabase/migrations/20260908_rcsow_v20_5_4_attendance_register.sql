-- RC SOW v20.5.4
-- Dual-mode attendance: crew self GPS + supervisor house register.

begin;

create or replace function public.can_verify_attendance()
returns boolean
language sql
stable
security definer
set search_path to 'public'
as $$
  select coalesce(
    p.approved=true
    and p.active=true
    and (
      p.role in (
        'Admin',
        'Regional Supervisor',
        'Construction Specialist',
        'Construction Engineer',
        'Site Supervisor'
      )
      or coalesce((p.privileges->>'verifyAttendance')::boolean,false)
    ),
    false
  )
  from public.profiles p
  where p.user_id=auth.uid();
$$;

grant execute on function public.can_verify_attendance() to authenticated;

update public.profiles
set privileges =
  coalesce(privileges,'{}'::jsonb) ||
  jsonb_build_object('verifyAttendance',true)
where approved=true
  and active=true
  and role in (
    'Admin',
    'Regional Supervisor',
    'Construction Specialist',
    'Construction Engineer',
    'Site Supervisor'
  )
  and coalesce((privileges->>'verifyAttendance')::boolean,false)=false;

alter table public.crew_attendance
  alter column user_id drop not null;

alter table public.crew_attendance
  drop constraint if exists crew_attendance_user_id_fkey;

alter table public.crew_attendance
  add constraint crew_attendance_user_id_fkey
  foreign key(user_id)
  references auth.users(id)
  on delete set null;

alter table public.crew_attendance
  add column if not exists recorded_by uuid
    references auth.users(id) on delete set null,
  add column if not exists recorded_by_email text,
  add column if not exists recording_mode text
    not null default 'self_gps';

create unique index if not exists
  crew_attendance_house_email_date_uidx
on public.crew_attendance(
  house_code,
  lower(member_email),
  work_date
);

create or replace function public.upsert_crew_attendance(
  p_house_code text,
  p_work_date date,
  p_status text default 'Present',
  p_clock_action text default 'sign_in',
  p_note text default null,
  p_evidence_path text default null,
  p_latitude double precision default null,
  p_longitude double precision default null,
  p_accuracy_m double precision default null,
  p_location_status text default null
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
  select * into v_profile
  from public.profiles
  where user_id=auth.uid()
    and approved=true
    and active=true;

  if not found then
    raise exception 'Approved active account required';
  end if;
  if not public.is_crew_role(v_profile.role) then
    raise exception 'Crew account required for self attendance';
  end if;
  if not public.crew_can_access_house(p_house_code) then
    raise exception 'House is not assigned to this crew member';
  end if;
  if p_status not in ('Present','Half day','Absent','Excused') then
    raise exception 'Invalid attendance status';
  end if;
  if p_clock_action not in ('sign_in','sign_out') then
    raise exception 'Invalid clock action';
  end if;

  select coalesce(a.parish,e.parish,v_profile.parish)
  into v_parish
  from (select 1) x
  left join public.house_crew_assignments a
    on a.active=true
   and upper(a.house_code)=upper(trim(p_house_code))
   and (
     a.user_id=auth.uid()
     or lower(a.email)=lower(v_profile.email)
   )
  left join lateral (
    select parish
    from public.app_events
    where event_type='house'
      and upper(house_code)=upper(trim(p_house_code))
    order by updated_at desc
    limit 1
  ) e on true
  limit 1;

  select * into v_row
  from public.crew_attendance
  where upper(house_code)=upper(trim(p_house_code))
    and lower(member_email)=lower(v_profile.email)
    and work_date=p_work_date
  for update;

  if found then
    update public.crew_attendance
    set user_id=auth.uid(),
        parish=coalesce(v_parish,v_profile.parish),
        member_email=v_profile.email,
        member_name=coalesce(
          nullif(v_profile.full_name,''),
          split_part(v_profile.email,'@',1)
        ),
        member_role=v_profile.role,
        status=p_status,
        clock_in=case
          when p_clock_action='sign_in'
            then coalesce(clock_in,now())
          else clock_in
        end,
        clock_out=case
          when p_clock_action='sign_out'
            then now()
          else clock_out
        end,
        note=coalesce(p_note,note),
        evidence_path=coalesce(p_evidence_path,evidence_path),
        self_signed=true,
        recorded_by=auth.uid(),
        recorded_by_email=v_profile.email,
        recording_mode='self_gps',
        clock_in_latitude=case
          when p_clock_action='sign_in'
            then coalesce(clock_in_latitude,p_latitude)
          else clock_in_latitude
        end,
        clock_in_longitude=case
          when p_clock_action='sign_in'
            then coalesce(clock_in_longitude,p_longitude)
          else clock_in_longitude
        end,
        clock_out_latitude=case
          when p_clock_action='sign_out'
            then p_latitude
          else clock_out_latitude
        end,
        clock_out_longitude=case
          when p_clock_action='sign_out'
            then p_longitude
          else clock_out_longitude
        end,
        location_accuracy_m=
          coalesce(p_accuracy_m,location_accuracy_m),
        location_status=
          coalesce(p_location_status,location_status),
        updated_at=now()
    where id=v_row.id
    returning * into v_row;
  else
    insert into public.crew_attendance(
      house_code,parish,user_id,member_email,member_name,
      member_role,work_date,status,clock_in,clock_out,note,
      evidence_path,self_signed,recorded_by,recorded_by_email,
      recording_mode,updated_at,clock_in_latitude,
      clock_in_longitude,clock_out_latitude,clock_out_longitude,
      location_accuracy_m,location_status
    )
    values(
      upper(trim(p_house_code)),
      coalesce(v_parish,v_profile.parish),
      auth.uid(),
      v_profile.email,
      coalesce(
        nullif(v_profile.full_name,''),
        split_part(v_profile.email,'@',1)
      ),
      v_profile.role,
      p_work_date,
      p_status,
      case when p_clock_action='sign_in' then now() else null end,
      case when p_clock_action='sign_out' then now() else null end,
      p_note,
      p_evidence_path,
      true,
      auth.uid(),
      v_profile.email,
      'self_gps',
      now(),
      case when p_clock_action='sign_in' then p_latitude else null end,
      case when p_clock_action='sign_in' then p_longitude else null end,
      case when p_clock_action='sign_out' then p_latitude else null end,
      case when p_clock_action='sign_out' then p_longitude else null end,
      p_accuracy_m,
      p_location_status
    )
    returning * into v_row;
  end if;

  insert into public.audit_log(
    user_id,user_email,action,entity_type,
    entity_id,parish,details
  )
  values(
    auth.uid(),
    v_profile.email,
    'attendance.'||p_clock_action,
    'crew_attendance',
    v_row.id::text,
    v_row.parish,
    jsonb_build_object(
      'houseCode',v_row.house_code,
      'workDate',v_row.work_date,
      'status',v_row.status,
      'latitude',p_latitude,
      'longitude',p_longitude,
      'accuracyM',p_accuracy_m,
      'locationStatus',p_location_status,
      'recordingMode','self_gps'
    )
  );

  return to_jsonb(v_row);
end;
$$;

create or replace function public.record_crew_attendance(
  p_house_code text,
  p_member_email text,
  p_work_date date,
  p_status text default 'Present',
  p_clock_action text default 'status_only',
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_assignment public.house_crew_assignments%rowtype;
  v_profile public.profiles%rowtype;
  v_row public.crew_attendance%rowtype;
  v_email text := lower(trim(coalesce(p_member_email,'')));
begin
  if not public.can_verify_attendance() then
    raise exception 'Attendance management privilege required';
  end if;
  if p_status not in ('Present','Half day','Absent','Excused') then
    raise exception 'Invalid attendance status';
  end if;
  if p_clock_action not in ('status_only','sign_in','sign_out') then
    raise exception 'Invalid clock action';
  end if;
  if v_email='' or position('@' in v_email)=0 then
    raise exception 'Valid crew email required';
  end if;

  select * into v_assignment
  from public.house_crew_assignments
  where active=true
    and upper(house_code)=upper(trim(p_house_code))
    and lower(email)=v_email
  order by updated_at desc
  limit 1;

  if not found then
    raise exception 'Crew member is not actively assigned to this house';
  end if;
  if not public.can_access_parish(v_assignment.parish) then
    raise exception 'Parish access denied';
  end if;

  select * into v_profile
  from public.profiles
  where lower(email)=v_email
  limit 1;

  select * into v_row
  from public.crew_attendance
  where upper(house_code)=upper(trim(p_house_code))
    and lower(member_email)=v_email
    and work_date=p_work_date
  for update;

  if found then
    update public.crew_attendance
    set user_id=coalesce(v_profile.user_id,user_id),
        parish=v_assignment.parish,
        member_email=v_email,
        member_name=coalesce(
          nullif(v_assignment.member_name,''),
          nullif(v_profile.full_name,''),
          split_part(v_email,'@',1)
        ),
        member_role=v_assignment.role,
        status=p_status,
        clock_in=case
          when p_clock_action='sign_in'
            then coalesce(clock_in,now())
          else clock_in
        end,
        clock_out=case
          when p_clock_action='sign_out'
            then now()
          else clock_out
        end,
        note=coalesce(p_note,note),
        self_signed=false,
        verified=true,
        verified_by=auth.uid(),
        verified_at=now(),
        recorded_by=auth.uid(),
        recorded_by_email=public.current_email(),
        recording_mode='supervisor_register',
        location_status=case
          when p_clock_action='status_only'
            then location_status
          else 'supervisor_recorded'
        end,
        updated_at=now()
    where id=v_row.id
    returning * into v_row;
  else
    insert into public.crew_attendance(
      house_code,parish,user_id,member_email,member_name,
      member_role,work_date,status,clock_in,clock_out,note,
      self_signed,verified,verified_by,verified_at,recorded_by,
      recorded_by_email,recording_mode,location_status,updated_at
    )
    values(
      upper(trim(p_house_code)),
      v_assignment.parish,
      v_profile.user_id,
      v_email,
      coalesce(
        nullif(v_assignment.member_name,''),
        nullif(v_profile.full_name,''),
        split_part(v_email,'@',1)
      ),
      v_assignment.role,
      p_work_date,
      p_status,
      case when p_clock_action='sign_in' then now() else null end,
      case when p_clock_action='sign_out' then now() else null end,
      p_note,
      false,
      true,
      auth.uid(),
      now(),
      auth.uid(),
      public.current_email(),
      'supervisor_register',
      case
        when p_clock_action='status_only'
          then 'not_required'
        else 'supervisor_recorded'
      end,
      now()
    )
    returning * into v_row;
  end if;

  insert into public.audit_log(
    user_id,user_email,action,entity_type,
    entity_id,parish,details
  )
  values(
    auth.uid(),
    public.current_email(),
    'attendance.supervisor_'||p_clock_action,
    'crew_attendance',
    v_row.id::text,
    v_row.parish,
    jsonb_build_object(
      'houseCode',v_row.house_code,
      'memberEmail',v_row.member_email,
      'workDate',v_row.work_date,
      'status',v_row.status,
      'recordingMode','supervisor_register',
      'verified',true
    )
  );

  return to_jsonb(v_row);
end;
$$;

create or replace function public.verify_crew_attendance(
  p_attendance_id uuid,
  p_verified boolean,
  p_status text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_row public.crew_attendance%rowtype;
begin
  if not public.can_verify_attendance() then
    raise exception 'Attendance verification privilege required';
  end if;

  select * into v_row
  from public.crew_attendance
  where id=p_attendance_id
  for update;

  if not found then
    raise exception 'Attendance row not found';
  end if;
  if not public.can_access_parish(v_row.parish) then
    raise exception 'Parish access denied';
  end if;
  if p_status is not null
     and p_status not in ('Present','Half day','Absent','Excused') then
    raise exception 'Invalid attendance status';
  end if;

  update public.crew_attendance
  set status=coalesce(p_status,status),
      verified=p_verified,
      verified_by=case when p_verified then auth.uid() else null end,
      verified_at=case when p_verified then now() else null end,
      updated_at=now()
  where id=p_attendance_id
  returning * into v_row;

  return to_jsonb(v_row);
end;
$$;

grant execute on function public.upsert_crew_attendance(
  text,date,text,text,text,text,
  double precision,double precision,double precision,text
) to authenticated;

grant execute on function public.record_crew_attendance(
  text,text,date,text,text,text
) to authenticated;

grant execute on function public.verify_crew_attendance(
  uuid,boolean,text
) to authenticated;

drop policy if exists crew_attendance_select
on public.crew_attendance;

create policy crew_attendance_select
on public.crew_attendance
for select to authenticated
using (
  user_id=auth.uid()
  or lower(member_email)=lower(public.current_email())
  or (
    public.can_verify_attendance()
    and public.can_access_parish(parish)
  )
  or (
    not public.is_crew_role(public.current_role())
    and public.can_access_parish(parish)
  )
);

drop policy if exists crew_attendance_insert
on public.crew_attendance;

create policy crew_attendance_insert
on public.crew_attendance
for insert to authenticated
with check (
  (
    user_id=auth.uid()
    and public.has_privilege('editOwnAttendance')
    and public.crew_can_access_house(house_code)
  )
  or (
    public.can_verify_attendance()
    and public.can_access_parish(parish)
  )
);

drop policy if exists crew_attendance_update
on public.crew_attendance;

create policy crew_attendance_update
on public.crew_attendance
for update to authenticated
using (
  (
    user_id=auth.uid()
    and public.has_privilege('editOwnAttendance')
    and verified=false
  )
  or (
    public.can_verify_attendance()
    and public.can_access_parish(parish)
  )
)
with check (
  (
    user_id=auth.uid()
    and public.has_privilege('editOwnAttendance')
    and public.crew_can_access_house(house_code)
  )
  or (
    public.can_verify_attendance()
    and public.can_access_parish(parish)
  )
);

commit;
