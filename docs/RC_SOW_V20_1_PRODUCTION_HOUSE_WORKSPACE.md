# RC SOW v20.1 — Production House Workspace

## House-first organization

The durable unit of work is the **House Code**. Each house code opens its own workspace/div and every production record remains attached to that house.

### Pinned at the top
- Completion
- Payment

### Technical & Scope
- Beneficiary & Scope input
- Custom Roof Drawing
- BOQ
- Document Checklist

### Delivery & Crew
- Work Plan
- Site Visits
- Daily Site Log
- Material Request
- Consumables
- House Inventory

### Quality & Evidence
- Monitoring Checklist
- Evidence / photos / files
- Work Logs
- Activity / audit history

Every compact tile opens a real input form or working module.

## Active Houses UI

Active-house cards now support:
- evidence/photo preview
- house code
- beneficiary
- community / parish
- phase and progress
- evidence count
- crew count and crew chips
- roof area
- quick Scope / Control / Crew actions

## Notifications

There are two notification paths.

### Automatic production notifications
Every house-linked activity recorded through the production state creates an alert, including:
- new house/control record
- Scope / BOQ / Work Plan / other form saves and submissions
- document checklist changes
- monitoring changes
- evidence additions
- production/work-log increments
- projection status changes
- inventory reconciliation
- inventory/operational transfers
- completion submitted/approved
- payment submitted/approved/paid
- production issues and their resolution

Automatic audiences are derived from the house:
- the house crew
- its parish
- Regional Supervisors
- Construction Specialists
- assigned individual crew members
- Accounts for payment/finance-relevant events

The alert stores the house code, lifecycle phase, record status and progress percentage and tapping it opens the correct House Workspace.

### Management notification composer
Authorized management roles can target any combination of:
- specific individuals
- house crews
- one or more parishes
- Regional Supervisors
- Construction Specialists
- Accounts
- all operational users

It supports meetings, site visits, deadlines, approvals, material alerts and operational announcements, with optional scheduling and optional house context.

## Map
The operational map is linked to beneficiary/house GPS. Only records with usable GPS coordinates receive pins. Selecting a pin selects the house and opens its House Workspace.

## More / Settings
More is a compact tile menu. Settings opens as a sleek quick-settings bottom sheet with deeper settings available when required.

## Production hardening
- main.dart boots `AppState.production()`, not seeded fixtures.
- no demo houses, fake crews, fake emails, hard-coded transfer locations or fake work logs appear on a fresh install.
- fresh Scope begins with Create House or Import Legacy.
- transfer locations derive from live house/inventory locations.
- new houses have no fake crew assignment.
- offline image analysis cannot fabricate a rectangular roof.
- arbitrary/concave roof area uses the actual editable polygon shape.
- OAuth query/custom-scheme callback returns through session bootstrap.
- v20 sharded test strategy retained and APK + AAB + Web release builds are required.

## Legacy templates
Recovered blank/public operational templates are included under `reference_templates/`. Historic beneficiary/payment data is deliberately not bundled.
