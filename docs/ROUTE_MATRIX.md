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
| Control | `/control` | Configurable lifecycle/priority/custom divisions → 16 operational modules |
| Control Layout | `/control/layout` | Tile visibility/order, division style, density, hero/insights and reset |
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
| Transfer Command | `/transfers` | Personnel/material filters → selected request and status trail |
| New Transfer | `/transfers/new` | Resource, origin, destination, urgency and temporary assignment → approval |
| Transfer Detail | `/transfers/detail` | Approve/decline → in transit → completed; linked house retained |
| Transfer Automation | `/admin/transfers` | Proposal engine, retention buffer, cluster scope and approval queue |
| Team Excellence | `/teams/community` | Shout-outs, events and verified recognition feed |
| Team Performance | `/teams/performance` | Crew quality, safety, efficiency, payout and progression |
| Team Resources | `/teams/resources` | Crew capacity and house assignment → production audit |
| Awards & Incentives | `/admin/awards` | Programme state, Team of the Month and safety policy |
| Promotion Routing | `/teams/promotions` | Qualification review → approve and route to cluster demand |
| Construction Schedule | `/schedule` | House phase/filter/blocker view → advance verified schedule |
| Live Team Briefing | `/briefing/live` | Join/leave, agenda decisions and house-linked notes |
| Production Command | `/management/production` | Unified issues, materials, transfers, teams and schedule |
| Finance Command | `/management/finance` | Submitted → approved → paid, with evidence context |
| HQ Command | `/management/hq` | Production, finance, team, approvals, analytics and reporting |
| Institutional Report | `/management/report` | Connected executive metrics → HQ approval/export feedback |
| Administration Command | `/admin/command` | Features, policies, users, templates and workspace controls |
| Approval Queue | `/management/approvals` | Transfer, close-out and finance decisions in one queue |

All 55 declared routes are covered by the route, render, interaction and real-pointer navigation test suites.
