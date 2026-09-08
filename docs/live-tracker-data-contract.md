# RC SOW Live Tracker Data Contract

## Shelter / Beneficiary source
- Separate source.
- Populates `beneficiary_directory`.
- GPS points may populate `house_locations`.
- This is the only external-file source used by Field Map.

## Parish Live Tracker source
One external workbook per parish.

Cluster worksheets are detected by a `House ID` or `House Code` column.
Supported production columns include Finished, Started, Project Estimated Start Date,
Materials on Site Not Started, BOQ Sent, BOQ Done, SOW Done, Contract Signed,
House visited and verified to go ahead, Rejected, comments and Link.

A Storage worksheet is parsed separately as dated IN/OUT inventory movements.

The Live Tracker sync API writes only:
- `app_events.event_type = liveTrackerSnapshot`
- `parish_inventory`
- sync metadata on `parish_live_trackers`
- `audit_log`

The Live Tracker sync API MUST NOT write:
- `beneficiary_directory`
- `beneficiary_sources`
- `house_locations`

Provider/API behavior:
- Google Drive / Google Sheets: server-side Google Drive API + RC SOW service account.
- OneDrive / SharePoint: Microsoft Graph when credentials are configured; share-link fallback otherwise.
- Other/direct XLSX URL.
