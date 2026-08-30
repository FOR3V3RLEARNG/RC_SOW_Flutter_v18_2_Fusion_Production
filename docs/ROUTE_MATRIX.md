# RC SOW Canonical Route Matrix

| Product area | Route | Connected state / next action |
|---|---|---|
| Splash | `/` | Reduced-motion-aware transition to authentication |
| Login | `/login` | Role selection → authenticated shell |
| Dashboard | `/home`, `/dashboard` | Metrics, recent houses, activity and primary destinations |
| Scope — House | `/scope/house` | Beneficiary lookup → shared house record |
| Scope — Roof | `/scope/roof` | Measurements/type → house technical state |
| Scope — Print | `/scope/print` | House summary, roof diagram and signatures |
| Scope — Files | `/scope/files` | Evidence and generated file state |
| Control | `/control` | Lifecycle filters → operational modules |
| Houses | `/houses` | Search/filter → selected House Command |
| House Command | `/house-command` | Lifecycle, blockers, next action and audit |
| New Control | `/control/new` | Duplicate detection → new Scope record |
| Work Plan | `/forms/work-plan` | Draft/submit → Plan lifecycle and audit |
| Document Checklist | `/forms/document-checklist` | Required document readiness |
| Monitoring | `/forms/monitoring` | Pass/Attention/Fail/N/A + comments/evidence |
| Site Visits | `/site-visits` | Visit history → visit editor |
| Site Visit Detail | `/site-visits/detail` | Progress/findings → Delivery state |
| Daily Log | `/forms/daily-log` | Attendance/progress/issues → audit |
| Material Request | `/forms/material-request` | House request → inventory/logistics trail |
| Consumable Request | `/forms/consumable-request` | Request/receipt → delivery trail |
| Inventory | `/inventory` | Live reconciliation → edit record |
| Inventory Edit | `/inventory/add` | Delivered/additions/leftovers → audit |
| Completion | `/completion` | Readiness gate → close-out submission |
| Final Inspection | `/final-inspection` | Technical pass gate → close-out readiness |
| Payment | `/payment` | Readiness, 46/31/23 allocation → finance submission |
| Evidence | `/evidence` | Classified capture → readiness and audit |
| Activity | `/activity` | House traceability thread |
| Notifications | `/notifications` | Read state and linked house navigation |
| Users Online | `/users-online` | Profile → message/call actions |
| Messages | `/messages` | Linked-house conversation and replies |
| Settings | `/settings` | Offline, density, themes, accessibility and logout |
| Work Logs | `/work-logs` | Fast entry → hours and activity |
| Analytics | `/analytics` | Parish filters, operational metrics and export feedback |
| Operational Map | `/map` | House pins → House Command |
| Admin Users | `/admin/users` | Role/parish/status changes → audit |
| Admin Templates | `/admin/templates` | Preview/version/publish commands |
| Gmail | `/gmail` | Inbox → house-linked compose flow |

All declared routes are covered by `test/navigation_contract_test.dart`.

