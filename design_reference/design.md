RC SOW — Stitch Master Prompt
Core instruction
Extract the existing product first, preserve its workflow and recognizable RC SOW identity, then systematically redesign the entire experience. Do not create unrelated concept art.

Operate as a multidisciplinary product/design/field-operations team. Use the supplied RC SOW screenshots, source forms and current product structure as evidence. Follow:

Extract → Understand → Preserve → Improve → Systematize → Innovate → Validate.

RC SOW is a Red Cross-oriented Scope of Work and Production Management system for shelter/roof-repair operations. The house is the durable operational object. Preserve the evidence chain from assessment → scope → plan → delivery → quality → close-out → payment.

Non-negotiable product identity
Preserve:

RC SOW house/Red Cross identity
strong but restrained red action language
light operational surfaces
rounded institutional visual character
Dashboard / Scope / Control / Houses / More navigation
Control phases: All / Plan / Delivery / Quality / Close-out / Finance
field-first workflow
house-centric traceability
Do not create:

fintech clone
generic admin dashboard
neon/sci-fi/glassmorphism concept
Dribbble-only layouts
massive decorative whitespace
novelty navigation that breaks orientation
Design vision
Transform RC SOW from a clean administrative forms app into a premium humanitarian field operations command system combining construction workflow, evidence management, inspection tooling, material logistics, mobile data collection, approvals and operational command — while staying calm and approachable.

Required design principles
Trust: users know records are safe.
Control: users know what happened and what comes next.
Evidence: photos/files/signatures/checklists/approvals are connected.
Progress: house lifecycle is always understandable.
Accountability: status, owner and history are visible.
Field readiness: weak/intermittent/offline connectivity is explicit.
Calmness: enterprise power without enterprise clutter.
Design DNA
Use Material 3 as the usability foundation, then reinterpret through RC SOW’s own Design DNA.

Color semantics:

Brand red: major action / selected state / key brand moment.
Success green: completed / approved / synced.
Attention amber: pending / incomplete / offline queue.
Information blue: documents / maps / logistics / neutral information.
Error red: destructive/error only, differentiated from brand red by context, icon and copy.
Surface hierarchy:

L0 soft neutral canvas
L1 white operational cards/forms
L2 subtly tinted context/readiness/phase surfaces
L3 sheets/dialogs/floating command panels only
Corner system:

12–16 controls
18–24 records/cards
24–32 operational summaries
pill statuses
subtle roof/shelter geometry only where it strengthens identity
Shell
Header: RC SOW + role/parish/house context. Right actions may include map/location, notifications, collaboration and settings. Collapse overflow on compact width.

Bottom navigation remains:

Dashboard
Scope
Control
Houses
More
Selected destination is obvious but not visually dominant.

Density modes
Field Mode: larger targets, fewer metadata, phone/outdoor/one-hand optimized. Review Mode: denser information, tablet/desktop, master/detail, persistent filters and batch review.

Control of Works
Redesign as five information layers:

Page identity + New Control
Production Pulse
Lifecycle/phase rail
Completion/Payment lifecycle commands
Workflow modules
Production Pulse should surface active houses, need attention, ready for close-out, payments pending and evidence readiness — no large low-information hero card.

Lifecycle: Scope → Plan → Delivery → Quality → Close-out → Finance.

Phase filter: All / Plan / Delivery / Quality / Close-out / Finance, with counts only when useful.

Module cards should distinguish Work Plan, Document Checklist, Monitoring Checklist, Site Visits, Daily Site Log, Material Request, Consumables, Inventory, Completion and Payment with phase, state, count, last update and one next action.

House Command
Create a unified operational truth screen for each house.

Show:

house code / parish / cluster
current phase
meaningful readiness/progress
blockers
Smart Next Action
evidence readiness
team
material state
last site visit
recent activity
documents
approvals
Scope
Use one stepper only: 01 House → 02 Roof → 03 Print → 04 Files.

House stage: Property / Beneficiary / Assessment.

Place IA beneficiary lookup next to the map/location control. Selecting a known beneficiary auto-populates house number, name, parish, community, GPS, contact and known roof context, but all permitted fields remain editable.

Roof stage supports Gable, Hip, Shed/Mono, Intersecting and Custom, with technical plan/elevation drawing, editable walls, ridge/hip/valley, measurements, overhang, gutters/drains, snap points and dimension labels.

Print stage: beneficiary printout with Red Cross standard roof diagram and digital signatures.

Files stage: evidence/documents/generated exports and sync state.

Operational forms derived from supplied source workbooks
Use these exact source structures as the foundation of the app record forms.

Work Plan:

parish
village/community
house/beneficiary code
staff code / C-W-A crew roles
start date
estimated end date
square per house
demolition days/payment
extension days
materials request
consumables request
agreement date/place
Site Supervisor / JRC / Carpenter / Regional Supervisor signatures
Control workbook: reflect every sheet as a record type:

Work Plan and Project Overview
Site Visits
Daily Site Log
Document Checklist
Material Request
Consumables Form
COM / Construction Materials
Site Visits fields: Date of visit, Visit/Call, Technical Team Participants, Estimated % Completion, Status, # Work Days, Issues/Comments, Days Active.

Daily Site Log: Date, Site, Workers Present, Work Done, Estimated Advance, Materials Needed, Issues/Delays, Photos Taken, Technical Team.

Document Checklist: House, BOQ, Scope, Workplan, Time Extension, Notice of Completion, Monitoring Checklist, KOBO.

Material/Consumables: request date, parish, cluster, carpenter, supervisor, item, quantity, price, location, request date, date needed, date received, receiver/date/signature.

COM inventory: design a real material reconciliation experience around BOQ / Delivered / Additions / Leftovers / Total and the actual roofing-material catalog.

Shelter assessment
The source assessment contains 172 columns. Do not create a 172-field ordinary form. Group source data into Eligibility, Location, Beneficiary, Household Vulnerability, Housing/Insurance, Livelihood, Foundation, Structure, Walls, Wall Plate, Roof Structure, Roof Material, Primary Roof Geometry, Secondary/Verandah, Third/Fourth Structures, Photos/Drawing Evidence, Total Damage/Temporary Shelter, and Audit Metadata.

Use it primarily as protected auto-fill context and evidence. Ordinary list views expose minimum beneficiary information only.

Monitoring
Create structured Pass / Attention / Fail / N/A inspection sections:

Wall Plate
Roof Angle
Rafters
Battens
Plywood/T1-11
Zinc
Other (overhang, bracing, collars, veranda, gutters)
Identification includes Parish, Cluster, GIS Ref, Beneficiary, Contractor, Site Supervisor and A Square.

Completion / Payment
Completion is a controlled readiness gate: working dates, extension, final inspection, beneficiary acknowledgement/signature, representative sign-off and evidence requirements.

Payment shows readiness and state: Not Ready / Ready / Submitted / Under Review / Approved / Paid / Rejected. Preserve project information, roof size/rate, demolition/additional work, financial summary, 46/31/23 team allocation and approval chain.

Work Logs
Create a dedicated fast-entry Work Logs screen for all operational roles. Supervisors/Admin/authorized management can review logs across people/parishes according to privileges.

Log fields: date/time, user, role, parish, cluster/house, work hours, activity category, detailed work, linked record/evidence and status.

Production Database / Analytics
Create an operational review screen, not a vanity BI dashboard.

Allow management to filter/export by parish, house, cluster, team, lifecycle phase, date and state. Surface house throughput, evidence readiness, work-log hours, site visits, material movements, inventory leftovers, team workload, completion queues and payment queues.

Offline / Save Confidence
Every write resolves to one of: ✓ Saved ☁ Synced ↻ Syncing ! Waiting for connection × Couldn’t sync

Draft save is distinct from Submit for Approval.

Error language
Never expose PostgREST/database exception strings.

Errors state what happened, whether data is safe, and what to do next.

Collaboration
Users Online is a small integrated presence action, not a floating obstruction. Tap it to open a vertical panel/sheet. Tap a user for Message / Call / Profile.

Messages open as an interactive pull-down drawer with unread count, sender role, time, preview and priority. Support reply, forward, read/unread, archive and links to house/record.

Splash
Preserve the RC SOW house identity and create a professional hope/repair sequence:

subtle hope-rainbow arc appears
roof repair lines assemble
hammer finishes the roof
subtle completion shine
house smiles wider / proud repaired state
professional title animates in:
Red Cross Scope of Work

supporting line: BUILDING BACK SAFER

secondary mission line: Hope • Safety • Recovery

Reduced Motion: repaired house + short title fade only.

Required output order
A. Existing Design Extraction B. UX Audit C. Enhanced Product Architecture D. RC SOW Design DNA E. Mobile Design System F. Control of Works G. Scope House → Roof → Print → Files H. New Control I. Inventory Tracker J. House Command K. Evidence System L. Offline / Sync UX M. Error / Recovery System N. Collaboration O. Tablet Review Mode P. Accessibility / High Contrast / Text Scale Q. P0–P3 Functionality Enhancements R. Component Specification S. Final coherent screen family

Required screens
Login; Dashboard; Control All/Plan/Delivery/Quality/Close-out/Finance; New Control; Scope House/Roof/Print/Files; Houses; House Command; Work Plan; Document Checklist; Monitoring Checklist; Site Visits; Site Visit Detail; Daily Site Log; Inventory; Add Inventory; Notice of Completion; Payment; Evidence Viewer; Activity; Notifications; Users Online; Settings; Work Logs; Production Database/Analytics; Admin User Access; Admin Templates; Gmail.

State matrix
For major screens show representative Normal, Empty, Loading, Offline, Sync Pending, Validation Error, Server Error, Permission Denied, Successful Save, Attention, Completed and Reduced Motion states.

Final critique passes
Usability
Field readiness
Visual hierarchy
Cohesion
Originality
Flutter/Material 3 feasibility
Trust
Before finalizing each screen ask:

Where am I?
Which house/parish/phase?
What happened?
What needs attention?
What is the next action?
Is my work saved/synced?
Is evidence complete?
Who changed this?
Can the house move to the next stage?
If those answers are not immediate, revise the design.