# RC SOW — Design DNA v2

## Product Thesis

RC SOW is not a generic forms app. It is a humanitarian field-operations command system that preserves a trustworthy evidence chain around each house from assessment through scope, planning, delivery, inspection, completion, approval and payment.

The durable operational object is the **house**. Every work plan, site visit, log, checklist, material movement, signature, photo, completion record and payment event must resolve back to a known house, parish, owner, state and history.

Design method:

**Extract → Understand → Preserve → Improve → Systematize → Innovate → Validate.**

The redesign must remain recognizably RC SOW: Red Cross identity, strong red action language, clean light surfaces, rounded operational components, five-area navigation, house-centric workflow and the Control lifecycle.

---

## 1. Existing Identity to Preserve

- RC SOW house/Red Cross mark.
- Institutional red as a meaningful primary action color, not a decorative flood.
- Light neutral canvas with clean white surfaces.
- Strong, bold page titles and uppercase operational eyebrows.
- Rounded cards, status pills, segmented controls, sheets and clear form fields.
- Primary destinations: Dashboard, Scope, Control, Houses, More.
- Control phases: All, Plan, Delivery, Quality, Close-out, Finance.
- Operational modules: Work Plan, Document Checklist, Monitoring Checklist, Site Visits, Daily Site Log, Materials/Inventory, Completion and Payment.

---

## 2. Upgraded Design Personality

### Humanitarian Precision
Professional, dependable and humane.

### Operational Calm
Dense information only where it improves decisions. No visual noise.

### Evidence Confidence
Users should always know whether work is saved, synced, complete and reviewable.

### Field Resilience
Outdoor legibility, one-handed use, large targets, explicit offline behavior and draft recovery.

### Guided Progress
Every workflow surfaces a clear next action.

### Institutional Trust
Restrained motion, clear history, predictable navigation and human-readable errors.

---

## 3. Visual Foundation

### Color Roles

| Token | Purpose |
|---|---|
| Brand Red | Primary action, selected navigation, brand moments |
| Brand Strong | High-priority emphasis, dark red text/icon accents |
| Brand Soft | Context surfaces and selected states |
| Canvas | Low-fatigue app background |
| Surface | Standard white operational containers |
| Surface Secondary | Subtle grouped form/summary surfaces |
| Success | Completed, approved, synced, validated |
| Warning | Pending, incomplete, attention, queued offline |
| Info | Logistics, documents, maps, neutral operational detail |
| Error | Destructive/error only; distinguish from brand red with icon + copy + surface |

### Surface Levels

- **L0 Canvas** — soft neutral background.
- **L1 Standard Surface** — records, modules, forms, activity.
- **L2 Context Surface** — current phase, house summary, warning/readiness panels.
- **L3 Elevated Interactive Surface** — sheets, dialogs, menus and command surfaces.

### Corner Language

- Inputs/controls: 12–16dp.
- Standard records: 18–24dp.
- Operational summaries: 24–32dp.
- Pills: full radius.
- Subtle roof-profile/asymmetric cuts may be used in hero/context surfaces only.

### Spacing

4 / 8 / 12 / 16 / 20 / 24 / 32.

Phone gutter: 16dp. Tablet: 24dp. Large screens: 28–32dp.

### Typography

- Hero/Page: confident, compact, 28–34sp, 800–900 weight.
- Section: 20–24sp, 750–850.
- Module title: 16–18sp, 700–800.
- Body: 14–17sp, readable outdoors.
- Metadata: 12–14sp, never too light.
- Numbers: dedicated emphasis only when operationally meaningful.

---

## 4. App Shell

### Header
Left: RC SOW + context.

Examples:

- `Admin • All Parishes`
- `Site Supervisor • Hanover`
- `H12 • Quality`

Right: map/location, notifications, collaboration and settings. Collapse lower-priority actions into overflow on compact width.

### Bottom Navigation
Retain exactly:

1. Dashboard
2. Scope
3. Control
4. Houses
5. More

The selected destination must be obvious without becoming a novelty floating island. Preserve Android back behavior and safe areas.

### Tablet / Review Mode
Use NavigationRail or a persistent left command dock, plus master/detail panes where useful.

---

## 5. Two Density Modes

### Field Mode
- larger targets
- simpler metadata
- one dominant action
- one-column forms
- obvious local save/sync state
- optimized for 360–430dp Android phones and outdoor use

### Review Mode
- denser records
- 2–3 column dashboard modules
- persistent filters
- master/detail house/record views
- batch review/export for management roles

Same product, same information architecture.

---

## 6. Control of Works — Production Command

### Layer 1 — Identity
Eyebrow: `CONTROL / PRODUCTION`

Title: `Control of Works`

Copy: `Plan, deliver, inspect, close and pay while preserving a complete evidence trail.`

Primary action: `New Control`.

### Layer 2 — Production Pulse
Replace low-information hero space with:

- Active houses
- Need attention
- Ready for close-out
- Payments pending
- Evidence readiness aggregate

### Layer 3 — Lifecycle Rail
Scope → Plan → Delivery → Quality → Close-out → Finance.

Use counts per phase and attention markers. Do not imply all houses are in one stage.

### Layer 4 — Contextual Commands
Completion and Payment become lifecycle summaries with counts and readiness, not plain large buttons.

### Layer 5 — Workflow Modules
Each module card contains:

- phase label
- icon
- module title
- one-line purpose
- open/attention/record count
- last update when useful
- one contextual action (`Add record`, `Review`, `Continue`)

State family: Empty / Active / Attention / Complete / Offline Pending / Restricted.

---

## 7. House Command — Operational Truth

Header example:

`H12`

`Hanover • Cluster A3`

`Production active`

Core areas:

- Lifecycle rail
- Current phase
- Readiness/progress
- Blockers
- Smart Next Action
- Assigned team
- Evidence readiness
- Material state
- Last site visit
- Recent activity
- Documents
- Approval history

### Smart Next Action
Rule-based, explainable and singular:

- Continue roof measurements
- Complete monitoring checklist
- Upload final inspection photo
- Submit Notice of Completion
- Review returned payment

### Evidence Readiness
Show required/complete count and exact missing evidence.

---

## 8. Scope — Guided Technical Workspace

One stepper only:

`01 House → 02 Roof → 03 Print → 04 Files`

States: complete/current/incomplete/error.

### House
Groups:

- Property
- Beneficiary
- Assessment

Use the IA beneficiary lookup beside map/location. Selecting a known house auto-populates beneficiary, parish, community, GPS, contact and existing technical context, while preserving editability.

### Roof
Supported roof types:

- Gable
- Hip
- Shed / Mono
- Intersecting
- Custom

Tools:

- Select
- Wall
- Ridge
- Hip
- Valley
- Measure
- Gutter/Drain
- Text
- Undo/Redo

Measurements:

- width
- length
- wall height
- rise
- pitch
- ridge
- overhang
- individual wall stretches
- drain direction

Use CustomPainter for plan/elevation geometry and measurement overlays. Keep gestures robust: drag handles, snap points, pinch zoom, pan.

### Print
Beneficiary printout includes:

- project identity
- beneficiary/house/parish/community
- scope summary
- standard Red Cross roof diagram
- roof type/key dimensions
- digital signatures

### Files
Show evidence strip, uploaded documents, generated exports and sync state.

---

## 9. Forms Derived from the Operational Workbooks

### Work Plan
Actual source fields are reflected in the form:

- Parish
- Village/Community
- House/Beneficiary code
- Staff code / crew role C-W-A
- Starting date
- Estimated ending date
- Square per house
- Demolition days / payment
- Extension days
- Materials request
- Consumables request
- agreement date/place
- Site Supervisor / JRC / Carpenter / Regional Supervisor sign-off

### Control Workbook — all seven sheets become first-class record types

1. Work Plan and Project Overview
2. Site Visits
3. Daily Site Log
4. Document Checklist
5. Material Request
6. Consumables Form
7. COM / Construction Materials inventory

### Site Visits
Date, visit/call, technical participants, estimated completion %, status, work days, issues/comments and days active.

### Daily Site Log
Date, site/house, workers present, work done, estimated advance, materials needed, issues/delays, photos taken and technical team state.

### Document Checklist
House + BOQ + Scope + Workplan + Time Extension + Notice of Completion + Monitoring Checklist + KOBO.

### Material / Consumable Request
Request date, parish, cluster, carpenter, supervisor, item, quantity, price, location, request date, date needed, date received, receiver/date/signature.

### COM / Inventory
Inventory starts from the actual source catalog, including ridge beam, rafters/collars, battens/wall plate, blocking, fascia, plywood T1-11, zinc sizes, ridge cap, flashing, concrete/wood/zinc screws, hurricane straps, flat/coiled strap, anchors and galvanized nails.

Track BOQ, delivered, additions, leftovers and total by material.

---

## 10. Shelter Assessment Context Model

The Shelter assessment contains 172 source columns. Do not dump all fields into ordinary app forms.

Group them into:

1. Eligibility / consent
2. Location
3. Beneficiary identity/contact
4. Household vulnerability
5. Housing tenure / insurance
6. Livelihood / dependency
7. Foundation
8. Structure
9. Walls
10. Wall plate / belt beam
11. Roof structure
12. Roof material
13. Primary roof geometry
14. Secondary / verandah geometry
15. Third/fourth structures
16. Photos / drawing evidence
17. Total-damage / temporary-shelter eligibility
18. Source/audit metadata

The IA lookup may retrieve the complete protected source payload, but ordinary list views expose only the minimum operational fields.

---

## 11. Monitoring Checklist

Identification block:

- Parish
- Cluster
- GIS Ref
- Beneficiary Name
- Contractor Name
- Site Supervisor
- A Square

Technical sections:

1. Wall Plate
2. Roof Angle
3. Rafters
4. Battens
5. Plywood / T1-11
6. Zinc
7. Other roof elements (overhang, bracing, collars, veranda, gutters)

Each criterion supports Pass / Attention / Fail / N/A + evidence + comment + inspection date.

---

## 12. Completion and Payment

### Completion
Readiness gate with working dates, extension, final inspection, beneficiary acknowledgement, Red Cross representative signature and evidence checklist.

### Payment
Project information, roof size/rate, demolition/additional work, financial summary, 46/31/23 allocation, approval chain and payment status.

Payment states:

Not Ready → Ready → Submitted → Under Review → Approved → Paid

Alternative: Rejected → Revision Required.

---

## 13. Evidence System

Evidence Strip:

`Evidence 4   [photo] [photo] [PDF] [+]`

Evidence types:

- Before
- During
- After
- Delivery
- Defect
- Completion
- Document

Capture flow:

Take photo → preview → retake if needed → classify → description → local save → upload/sync queue.

Each evidence object records source user, timestamp, GPS when appropriate and related house/record.

---

## 14. Offline Confidence

Persistent but calm states:

- `Saved on device`
- `Syncing 2 of 3`
- `3 changes waiting to sync`
- `Couldn't sync 1 record — Retry`
- `All changes synced`

Never make field workers wonder whether their work was saved.

Draft save is distinct from Submit for Approval.

---

## 15. Error and Recovery

Never show raw PostgREST/database exception strings to normal users.

Every error says:

1. What happened
2. Whether data is safe
3. What the user can do next

Example:

`Scope couldn't be submitted.`

`Your draft is safe. Check your connection and try again.`

Actions: `Retry` / `Keep as draft`.

Categories: validation, permission, connectivity, server, conflict, authentication.

---

## 16. Collaboration

### Users Online
Small integrated presence control: `👥 4`.

Tap → vertical/bottom sheet with user name, role, parish and presence.

Tap a user → compact profile popout with Message / Call (if available) / Profile.

### Messages
Messages open as a vertical pull-down/overlay drawer with unread count, sender role, time, preview and priority. Message detail supports reply, forward, read/unread, archive and linked house/record.

---

## 17. Activity and Audit

Reusable traceability thread:

- action
- user
- timestamp
- related record
- approval/sync state

House detail exposes full activity; list cards show only necessary metadata.

---

## 18. Dashboard and Analytics

Role-aware dashboard answers:

- What needs attention today?
- Which houses are moving?
- What is blocked?
- Which approvals are waiting?
- What changed recently?

Production Review mode supports:

- house/parish/cluster/team filters
- lifecycle distribution
- evidence readiness
- site visit throughput
- work-log hours
- material issued/received/leftover
- inventory effectiveness
- completion/payment queues
- saved filters
- export current view

Do not use vanity charts. Every visualization must answer an operational question.

---

## 19. Role-Aware Experience

Navigation remains stable; actions adapt.

- Admin: all-parish command, user/privilege/template/audit controls.
- Regional Supervisor: all-parish review, approvals, exports and alerts.
- Construction Specialist / Engineer: all-parish technical review, monitoring, completion/payment readiness.
- Site Supervisor: field records, Scope, Control, logs, evidence; all-parish only when explicitly granted.
- Technical Admin: cross-parish operational/document support according to privileges.
- Community Admin: beneficiary/document/community workflows within assigned scope.

Do not show permanently inaccessible controls just to fill space.

---

## 20. Splash — Hope / Repair / Pride

The splash remains recognizably RC SOW, but becomes a professional brand moment.

Sequence:

1. soft neutral field appears
2. subtle hope-rainbow arc grows behind the house
3. roof repair lines assemble
4. hammer action finishes the roof
5. short completion shine crosses the repaired house
6. house develops a wider proud smile
7. professional title animates in:

**Red Cross Scope of Work**

8. supporting line:

**BUILDING BACK SAFER**

9. secondary mission line:

**Hope • Safety • Recovery**

Reduced Motion: short fade to repaired-house state and title; no shake/repair sequence.

---

## 21. Motion

- Micro: 120–180ms.
- Standard: 220–320ms.
- Deliberate: 320–450ms.

Use fade, controlled slide, small scale and container continuity. Avoid omnipresent spring/bounce/parallax.

---

## 22. Accessibility / Outdoor Rules

- 48dp minimum targets.
- no critical color-only status.
- readable at large text.
- outdoor contrast.
- focus states distinct from error states.
- screen-reader semantics.
- keyboard-safe forms.
- reduced motion.
- high-contrast mode.
- genuine dark theme.

---

## 23. Required High-Fidelity Screen Set

1. Login / authentication
2. Dashboard
3. Control of Works
4. Control — Plan
5. Control — Delivery
6. Control — Quality
7. Control — Close-out
8. Control — Finance
9. New Control
10. Scope — House
11. Scope — Roof
12. Scope — Print
13. Scope — Files
14. Houses
15. House Command
16. Work Plan
17. Document Checklist
18. Monitoring Checklist
19. Site Visits
20. Site Visit Detail
21. Daily Site Log
22. Inventory Tracker
23. Add Inventory Record
24. Notice of Completion
25. Payment Submission
26. Evidence Viewer
27. Activity History
28. Notifications
29. Users Online
30. Settings
31. Work Logs
32. Production Database / Analytics
33. Admin Users & Privileges
34. Admin Templates
35. Gmail Inbox / Compose

Representative states: normal, empty, loading, offline, sync pending, validation error, server error, permission denied, saved, attention, completed and reduced-motion-safe.

---

## 24. Component-to-Code Map

- RcAppHeader
- RcPageHeading
- RcOperationalHero
- RcProductionPulse
- RcStatusChip
- RcPhaseChip
- RcModuleCard
- RcHouseCard
- RcLifecycleRail
- RcEvidenceReadiness
- RcEvidenceStrip
- RcSyncStatus
- RcSmartNextAction
- RcFormSection
- RcFieldState
- RcActionBar
- RcEmptyState
- RcErrorState
- RcBottomSheet
- RcActivityTimeline
- RcApprovalTimeline
- RcUsersOnlinePanel
- RcMessageDrawer
- RcRoofCanvas
- RcSignaturePad
- RcMetricTile
- RcReviewTable

---

## 25. Priority Model

### P0 Essential
- save/sync confidence
- raw error replacement
- house auto-population
- duplicate-control prevention
- keyboard-safe forms
- role/permission clarity
- evidence readiness
- audit/activity traceability
- consistent status vocabulary
- complete button connectivity

### P1 High Value
- House Command
- Smart Next Action
- all seven Control workbook forms
- work logs
- production review database
- management filters/exports
- collaboration/message drawer
- document template replacement
- material reconciliation

### P2 Premium
- responsive Review Mode
- advanced roof drawing inspector
- PDF/export previews
- production pulse analytics
- saved filters/recent houses
- Gmail embedded workflow

### P3 Experimental
- optional AI log summarization
- optional missing-evidence suggestions
- optional blocker summarization

AI is advisory only and always reviewable.

---

## 26. Seven-Pass Release Critique

Before a screen is approved:

1. Usability — remove confusion.
2. Field readiness — low connectivity, keyboard, outdoor, one hand.
3. Visual hierarchy — operational information dominates.
4. Cohesion — one RC SOW system.
5. Originality — purpose-built, not generic SaaS.
6. Feasibility — Flutter/Material 3 realistic.
7. Trust — save, sync, evidence, approvals and state are unmistakable.

Final test:

**Where am I? Which house? What happened? What needs attention? What next? Is it saved? Is evidence complete? Who changed it? Can it move forward?**

If those answers are not immediately visible, the design is not finished.
