-- RC SOW v20.5 Live Tracker Connected Operations
begin;

update storage.buckets
set
  public = false,
  file_size_limit = greatest(coalesce(file_size_limit, 0), 31457280),
  allowed_mime_types = array[
    'image/jpeg',
    'image/png',
    'image/webp',
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'text/csv'
  ]
where id = 'evidence';

commit;
