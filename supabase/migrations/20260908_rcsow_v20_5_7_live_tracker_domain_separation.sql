begin;

alter table public.parish_live_trackers
  add column if not exists production_house_count integer not null default 0;

create index if not exists app_events_live_tracker_snapshot_idx
  on public.app_events(event_type, parish, updated_at desc)
  where event_type='liveTrackerSnapshot';

comment on column public.parish_live_trackers.production_house_count is
  'House production rows from the separate parish Live Tracker workbook.';

comment on column public.parish_live_trackers.beneficiary_count is
  'Legacy compatibility field. Live Tracker sync keeps this at 0; beneficiary data belongs to the Shelter source.';

commit;

revoke execute on function public.set_parish_live_tracker_source(text,text,text,text,text,text,boolean) from anon;
revoke execute on function public.replace_parish_tracker_inventory(text,jsonb,text) from anon;
revoke execute on function public.mark_parish_tracker_sync(text,text,text,integer,integer,integer,text) from anon;

grant execute on function public.set_parish_live_tracker_source(text,text,text,text,text,text,boolean) to authenticated;
grant execute on function public.replace_parish_tracker_inventory(text,jsonb,text) to authenticated;
grant execute on function public.mark_parish_tracker_sync(text,text,text,integer,integer,integer,text) to authenticated;

create or replace function public.sync_live_tracker_house_count()
returns trigger
language plpgsql
security definer
set search_path='public'
as $$
begin
  if new.event_type='liveTrackerSnapshot' and new.parish is not null then
    update public.parish_live_trackers
    set production_house_count = greatest(
          coalesce((new.item->'counts'->>'houses')::integer,0),
          0
        ),
        updated_at = greatest(updated_at,new.updated_at)
    where parish=new.parish;
  end if;
  return new;
end;
$$;

revoke execute on function public.sync_live_tracker_house_count()
from public, anon, authenticated;

drop trigger if exists trg_sync_live_tracker_house_count on public.app_events;
create trigger trg_sync_live_tracker_house_count
after insert or update of item, parish on public.app_events
for each row
when (new.event_type='liveTrackerSnapshot')
execute function public.sync_live_tracker_house_count();
