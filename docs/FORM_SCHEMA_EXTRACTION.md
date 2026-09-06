# RC SOW — Operational Form Extraction Map

This map records the structures extracted from the supplied production forms and workbooks. The Flutter `Add Record` forms should follow these structures instead of generic record dialogs.

## Workplan-Blank.xlsx

### Sheet: Workplan
- Parish
- Village
- Beneficiary code
- Crew role: C / W / A
- Staff code
- Starting date
- Estimated ending date
- Square per house
- Days demolishing roof
- Days extension
- Agreement date / place
- Site Supervisor sign-off
- JRC sign-off

### Sheet: Sheet1
- House code
- Starting date
- Estimated ending date
- Square per house
- Crew role: C / W / A
- Staff names
- Days demolishing roof
- Days extension
- Materials request
- Consumable request
- Agreement date/place
- Site Supervisor / JRC sign-off

## SOW_Excel_Template_Blank.xlsx

### Sheet: SOW Template
- GPS
- Cluster
- Date
- Parish / Cluster
- Name
- Beneficiary Code
- A Square
- Type of structure: Wood / RCC / Block
- Repairs needed
- Type of roof: Pitched / Gable / Hipped
- Type of gable: Wood / Concrete
- Existing rafter size: 2x6 / 2x4
- Existing ceiling: T1-11
- Pitched/gabled/main/total roof area calculations

## Control of works-Blank.xlsx

### Work Plan and Project Overview
- House number
- Starting date
- Estimated Ending date
- Square per house
- C / W / A crew rows
- Staff Name
- Demolishing Roof Payment
- Days Extension
- Materials request
- Consumable request
- Agreement date/place
- Site Supervisor
- Carpenter
- Regional Site Supervisor

### Site Visits
- Date of visit
- Visit / Call
- Technical Team Participants
- Estimated % Completion
- Status
- # of Work Days
- Issues / comments
- Days Active

### Daily Site Log
- Date
- Site
- Workers Present
- Work Done
- Estimated advance
- Materials Needed
- Issues / Delays
- Photos Taken
- Technical Team

### Document Checklist
- House Number
- BOQ
- Scope
- Workplan
- Time extension
- Notice of completion
- Monitoring Check List
- KOBO

### Material request
- Date Request
- Parish
- Cluster
- Carpenter Name
- Supervisor Name
- Item lines: Description / Quantity / Price / Location / Request Date / Date Need / Date received
- Received by Site Supervisor
- Date
- Signature

### Consumables form
- Date Request
- Parish
- Cluster
- Carpenter Name
- Supervisor Name
- Item lines: Description / Quantity / Price / Location / Request Date / Date Need / Date received
- Received by Site Supervisor
- Date
- Signature

### COM
- IN / OUT
- FROM / TO
- Date
- Material catalog fields: Item / Size / Length / Unit
- BOQ Quantity
- Delivered quantities
- Additional quantities
- Leftovers
- Total
- Acceptance / delivery signatures

The workbook contains the roofing material catalog used by the inventory form, including ridge beam, rafters/collars, battens/wall plate, blocking board, fascia board, plywood T1-11, zinc, ridge cap, flashing/verge, screws, straps, bolts and galvanized nails.

## Monitoring Checklist Roof Repair.docx

The digital form follows the source sequence:
1. Wall Plate
2. Roof Angle
3. Rafters
4. Battens
5. Plywood / T1-11
6. Zinc
7. Others: overhang, bracing, collars, veranda and gutters

Each technical section retains monitoring date / evidence-photo behavior.

## Notice of Completion.docx

- Operation / Programme Name
- Parish
- Community
- Beneficiary Code
- GPS Coordinates
- Start Date of Works
- End Date of Works
- Total Number of Working Days
- Extension Requested
- Additional Days
- Date of Completion
- Final Inspection Date
- Beneficiary acknowledgement and signature
- Supervisor / Red Cross representative sign-off

## Payment Request Form

- Project Name
- Parish
- Cluster
- House No.
- Supervisor
- Pay Period
- Roof Size
- Rate per square
- Demolition Rate
- Roofing Amount
- Demolition Cost
- Additional Work
- Total Labour Cost
- 46% / 31% / 23% team allocation
- Site Supervisor approval
- Regional Supervisor approval
- Construction Specialist approval

RC SOW adds attendance reconciliation before final payable allocation while preserving these source-form fields and approval roles.

## Shelter Roof Repair Assessment

Workbook sheets:
- Shelter Roof Repair Assessment
- Selected
- BOQs

The assessment contains a very wide operational/beneficiary dataset. RC SOW treats the source workbook as protected data, not an APK asset. The importer preserves the original row payload server-side and exposes only authorized operational autofill fields in normal forms.

Safe operational mapping includes:
- Parish
- Community
- Street/location context
- GPS point and latitude/longitude
- beneficiary/household name fields needed for operational identification
- operational contact fields where role-authorized
- roof/structure assessment fields required by Scope and Control

Sensitive source fields that are not required for a workflow should not be duplicated into ordinary UI records.
