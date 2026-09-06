import 'package:flutter/material.dart';

import 'app_constants.dart';

enum RcFieldKind {
  text,
  number,
  multiline,
  date,
  dropdown,
  checkbox,
  photo,
  signature,
  lineItems,
  percentage,
}

class RcFormFieldDef {
  const RcFormFieldDef({
    required this.key,
    required this.label,
    this.kind = RcFieldKind.text,
    this.required = false,
    this.options = const [],
    this.helper,
    this.defaultValue,
  });

  final String key;
  final String label;
  final RcFieldKind kind;
  final bool required;
  final List<String> options;
  final String? helper;
  final Object? defaultValue;

  Map<String, dynamic> toMap() => {
        'key': key, 'label': label, 'kind': kind.name, 'required': required,
        'options': options, 'helper': helper, 'defaultValue': defaultValue,
      };

  factory RcFormFieldDef.fromMap(Map<String, dynamic> map) => RcFormFieldDef(
        key: '${map['key'] ?? ''}',
        label: '${map['label'] ?? ''}',
        kind: RcFieldKind.values.firstWhere((k) => k.name == map['kind'], orElse: () => RcFieldKind.text),
        required: map['required'] == true,
        options: (map['options'] as List? ?? const []).map((e) => '$e').toList(),
        helper: map['helper']?.toString(),
        defaultValue: map['defaultValue'],
      );
}

class RcRecordSchema {
  const RcRecordSchema({
    required this.id,
    required this.title,
    required this.eventType,
    required this.phase,
    required this.icon,
    required this.fields,
    this.templateAsset,
    this.description = '',
  });

  final String id;
  final String title;
  final String eventType;
  final String phase;
  final IconData icon;
  final List<RcFormFieldDef> fields;
  final String? templateAsset;
  final String description;

  Map<String, dynamic> toMap() => {
        'id': id, 'title': title, 'eventType': eventType, 'phase': phase,
        'iconCodePoint': icon.codePoint, 'fields': fields.map((f) => f.toMap()).toList(),
        'templateAsset': templateAsset, 'description': description,
      };

  factory RcRecordSchema.fromMap(Map<String, dynamic> map) => RcRecordSchema(
        id: '${map['id'] ?? ''}', title: '${map['title'] ?? ''}',
        eventType: '${map['eventType'] ?? map['event_type'] ?? ''}',
        phase: '${map['phase'] ?? 'Other'}',
        icon: IconData((map['iconCodePoint'] as num?)?.toInt() ?? Icons.description_outlined.codePoint, fontFamily: 'MaterialIcons'),
        fields: (map['fields'] as List? ?? const []).whereType<Map>().map((e) => RcFormFieldDef.fromMap(Map<String, dynamic>.from(e))).toList(),
        templateAsset: map['templateAsset']?.toString(),
        description: '${map['description'] ?? ''}',
      );
}

abstract final class RcRecordSchemas {
  static const commonHouseFields = <RcFormFieldDef>[
    RcFormFieldDef(key: 'houseCode', label: 'House number / Beneficiary code', required: true),
    RcFormFieldDef(key: 'beneficiaryName', label: 'Beneficiary name', required: true),
    RcFormFieldDef(key: 'parish', label: 'Parish', kind: RcFieldKind.dropdown, required: true, options: RcApp.parishes),
    RcFormFieldDef(key: 'cluster', label: 'Community / Cluster', required: true),
    RcFormFieldDef(key: 'gps', label: 'GPS / GIS reference'),
  ];

  static const schemas = <RcRecordSchema>[
    RcRecordSchema(
      id: 'work-plan',
      title: 'Work Plan',
      eventType: 'workPlan',
      phase: 'Plan',
      icon: Icons.calendar_month_outlined,
      templateAsset: 'assets/templates/original/Workplan_Blank.xlsx',
      description: 'House sequence, crew assignment, dates, square count and field requests.',
      fields: [
        ...commonHouseFields,
        RcFormFieldDef(key: 'village', label: 'Village'),
        RcFormFieldDef(
          key: 'crewAssignments',
          label: 'Crew assignments',
          kind: RcFieldKind.lineItems,
          required: true,
          helper: 'One line per role: C / W / A • staff code • staff name',
        ),
        RcFormFieldDef(key: 'startingDate', label: 'Starting date', kind: RcFieldKind.date, required: true),
        RcFormFieldDef(key: 'estimatedEndingDate', label: 'Estimated ending date', kind: RcFieldKind.date, required: true),
        RcFormFieldDef(key: 'squarePerHouse', label: 'Square per house', kind: RcFieldKind.number),
        RcFormFieldDef(key: 'daysDemolishingRoof', label: 'Days demolishing roof', kind: RcFieldKind.number),
        RcFormFieldDef(key: 'daysExtension', label: 'Days extension', kind: RcFieldKind.number),
        RcFormFieldDef(key: 'materialsRequest', label: 'Materials request', kind: RcFieldKind.multiline),
        RcFormFieldDef(key: 'consumableRequest', label: 'Consumable request', kind: RcFieldKind.multiline),
        RcFormFieldDef(key: 'agreementDate', label: 'Agreement date', kind: RcFieldKind.date),
        RcFormFieldDef(key: 'agreementPlace', label: 'Agreement place'),
        RcFormFieldDef(key: 'siteSupervisorSignature', label: 'Site Supervisor signature', kind: RcFieldKind.signature),
        RcFormFieldDef(key: 'carpenterSignature', label: 'Carpenter signature', kind: RcFieldKind.signature),
        RcFormFieldDef(key: 'regionalSupervisorSignature', label: 'Regional Site Supervisor signature', kind: RcFieldKind.signature),
        RcFormFieldDef(key: 'jrcSignature', label: 'JRC signature', kind: RcFieldKind.signature),
      ],
    ),
    RcRecordSchema(
      id: 'work-projection',
      title: 'Weekly Work Projection',
      eventType: 'workProjection',
      phase: 'Plan',
      icon: Icons.view_timeline_outlined,
      description: 'Weekly management forecast by parish, house, crew and expected output.',
      fields: [
        RcFormFieldDef(key: 'parish', label: 'Parish', kind: RcFieldKind.dropdown, required: true, options: RcApp.parishes),
        RcFormFieldDef(key: 'weekStarting', label: 'Week starting', kind: RcFieldKind.date, required: true),
        RcFormFieldDef(key: 'projectionLines', label: 'Projection schedule', kind: RcFieldKind.lineItems, required: true, helper: 'House code • crew • target activity • target completion • dependencies'),
        RcFormFieldDef(key: 'risks', label: 'Risks / blockers', kind: RcFieldKind.multiline),
        RcFormFieldDef(key: 'supportNeeded', label: 'Support / decision required', kind: RcFieldKind.multiline),
      ],
    ),
    RcRecordSchema(
      id: 'construction-schedule',
      title: 'Construction Schedule',
      eventType: 'constructionSchedule',
      phase: 'Plan',
      icon: Icons.event_note_outlined,
      description: 'Editable house-by-house construction order managed by the Site Supervisor.',
      fields: [
        RcFormFieldDef(key: 'parish', label: 'Parish', kind: RcFieldKind.dropdown, required: true, options: RcApp.parishes),
        RcFormFieldDef(key: 'scheduleLines', label: 'Construction order', kind: RcFieldKind.lineItems, required: true, helper: 'Order • house code • carpenter • planned start • planned end • current state'),
        RcFormFieldDef(key: 'notes', label: 'Schedule notes', kind: RcFieldKind.multiline),
      ],
    ),
    RcRecordSchema(
      id: 'site-visit',
      title: 'Site Visit',
      eventType: 'siteVisit',
      phase: 'Delivery',
      icon: Icons.location_on_outlined,
      templateAsset: 'assets/templates/original/Control_of_Works_Blank.xlsx',
      fields: [
        ...commonHouseFields,
        RcFormFieldDef(key: 'visitDate', label: 'Date of visit', kind: RcFieldKind.date, required: true),
        RcFormFieldDef(key: 'visitOrCall', label: 'Visit / Call', kind: RcFieldKind.dropdown, options: ['Visit', 'Call']),
        RcFormFieldDef(key: 'technicalTeam', label: 'Technical Team Participants'),
        RcFormFieldDef(key: 'estimatedCompletion', label: 'Estimated % completion', kind: RcFieldKind.percentage),
        RcFormFieldDef(key: 'status', label: 'Status', kind: RcFieldKind.dropdown, options: ['Active', 'On Hold', 'Need Attention', 'Completed']),
        RcFormFieldDef(key: 'workDays', label: '# of Work Days', kind: RcFieldKind.number),
        RcFormFieldDef(key: 'issuesComments', label: 'Issues / comments', kind: RcFieldKind.multiline),
        RcFormFieldDef(key: 'daysActive', label: 'Days Active', kind: RcFieldKind.number),
        RcFormFieldDef(key: 'photos', label: 'Photos', kind: RcFieldKind.photo),
      ],
    ),
    RcRecordSchema(
      id: 'daily-site-log',
      title: 'Daily Site Log',
      eventType: 'dailyLog',
      phase: 'Delivery',
      icon: Icons.menu_book_outlined,
      templateAsset: 'assets/templates/original/Control_of_Works_Blank.xlsx',
      fields: [
        ...commonHouseFields,
        RcFormFieldDef(key: 'date', label: 'Date', kind: RcFieldKind.date, required: true),
        RcFormFieldDef(key: 'workersPresent', label: 'Workers Present', kind: RcFieldKind.multiline),
        RcFormFieldDef(key: 'workDone', label: 'Work Done', kind: RcFieldKind.multiline, required: true),
        RcFormFieldDef(key: 'estimatedAdvance', label: 'Estimated advance %', kind: RcFieldKind.percentage),
        RcFormFieldDef(key: 'materialsNeeded', label: 'Materials Needed', kind: RcFieldKind.multiline),
        RcFormFieldDef(key: 'issuesDelays', label: 'Issues / Delays', kind: RcFieldKind.multiline),
        RcFormFieldDef(key: 'photosTaken', label: 'Photos Taken', kind: RcFieldKind.photo),
        RcFormFieldDef(key: 'technicalTeam', label: 'Technical Team'),
      ],
    ),
    RcRecordSchema(
      id: 'crew-attendance',
      title: 'Crew Daily Attendance',
      eventType: 'crewAttendance',
      phase: 'Delivery',
      icon: Icons.how_to_reg_outlined,
      fields: [
        ...commonHouseFields,
        RcFormFieldDef(key: 'date', label: 'Work date', kind: RcFieldKind.date, required: true),
        RcFormFieldDef(key: 'crewLines', label: 'Crew attendance', kind: RcFieldKind.lineItems, required: true, helper: 'Name • role • Present / Half day / Absent / Excused • signed in time • signed out time'),
        RcFormFieldDef(key: 'verified', label: 'Supervisor verified', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'verificationNote', label: 'Verification note', kind: RcFieldKind.multiline),
      ],
    ),
    RcRecordSchema(
      id: 'material-request',
      title: 'Material Request',
      eventType: 'materialRequest',
      phase: 'Delivery',
      icon: Icons.inventory_2_outlined,
      templateAsset: 'assets/templates/original/Control_of_Works_Blank.xlsx',
      fields: [
        ...commonHouseFields,
        RcFormFieldDef(key: 'dateRequest', label: 'Date Request', kind: RcFieldKind.date, required: true),
        RcFormFieldDef(key: 'carpenterName', label: 'Carpenter Name'),
        RcFormFieldDef(key: 'supervisorName', label: 'Supervisor Name'),
        RcFormFieldDef(key: 'items', label: 'Requested items', kind: RcFieldKind.lineItems, required: true, helper: 'Description • quantity • price • location • request date • date needed • date received'),
        RcFormFieldDef(key: 'dateNeed', label: 'Date Needed', kind: RcFieldKind.date),
        RcFormFieldDef(key: 'dateReceived', label: 'Date Received', kind: RcFieldKind.date),
        RcFormFieldDef(key: 'receivedBySupervisor', label: 'Received by Site Supervisor', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'signature', label: 'Receiving signature', kind: RcFieldKind.signature),
      ],
    ),
    RcRecordSchema(
      id: 'consumables',
      title: 'Consumables Form',
      eventType: 'consumables',
      phase: 'Delivery',
      icon: Icons.handyman_outlined,
      templateAsset: 'assets/templates/original/Control_of_Works_Blank.xlsx',
      fields: [
        ...commonHouseFields,
        RcFormFieldDef(key: 'dateRequest', label: 'Date Request', kind: RcFieldKind.date, required: true),
        RcFormFieldDef(key: 'carpenterName', label: 'Carpenter Name'),
        RcFormFieldDef(key: 'supervisorName', label: 'Supervisor Name'),
        RcFormFieldDef(key: 'items', label: 'Consumable items', kind: RcFieldKind.lineItems, required: true, helper: 'Description • quantity • price • location • request date • date needed • date received'),
        RcFormFieldDef(key: 'dateNeed', label: 'Date Needed', kind: RcFieldKind.date),
        RcFormFieldDef(key: 'dateReceived', label: 'Date Received', kind: RcFieldKind.date),
        RcFormFieldDef(key: 'receivedBySupervisor', label: 'Received by Site Supervisor', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'signature', label: 'Receiving signature', kind: RcFieldKind.signature),
      ],
    ),
    RcRecordSchema(
      id: 'inventory',
      title: 'COM / Inventory',
      eventType: 'inventory',
      phase: 'Delivery',
      icon: Icons.warehouse_outlined,
      templateAsset: 'assets/templates/original/Control_of_Works_Blank.xlsx',
      fields: [
        RcFormFieldDef(key: 'parish', label: 'Parish', kind: RcFieldKind.dropdown, required: true, options: RcApp.parishes),
        RcFormFieldDef(key: 'houseCode', label: 'House number'),
        RcFormFieldDef(key: 'direction', label: 'IN / OUT', kind: RcFieldKind.dropdown, options: ['IN', 'OUT']),
        RcFormFieldDef(key: 'fromTo', label: 'FROM / TO'),
        RcFormFieldDef(key: 'date', label: 'Movement date', kind: RcFieldKind.date),
        RcFormFieldDef(
          key: 'items',
          label: 'COM inventory movement',
          kind: RcFieldKind.lineItems,
          required: true,
          helper: 'Item • size • length • unit • BOQ quantity • delivered • additional quantities • leftovers • total • warehouse/storage',
        ),
        RcFormFieldDef(key: 'jrcAcceptanceSignature', label: 'JRC acceptance of materials', kind: RcFieldKind.signature),
        RcFormFieldDef(key: 'beneficiaryAcceptanceSignature', label: 'Beneficiary acceptance of materials', kind: RcFieldKind.signature),
        RcFormFieldDef(key: 'transportDeliverySignature', label: 'Transport / Store delivery signature', kind: RcFieldKind.signature),
      ],
    ),
    RcRecordSchema(
      id: 'document-checklist',
      title: 'Document Checklist',
      eventType: 'documentChecklist',
      phase: 'Plan',
      icon: Icons.task_alt_outlined,
      templateAsset: 'assets/templates/original/Control_of_Works_Blank.xlsx',
      fields: [
        ...commonHouseFields,
        RcFormFieldDef(key: 'boq', label: 'BOQ', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'scope', label: 'Scope', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'workplan', label: 'Workplan', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'timeExtension', label: 'Time extension', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'noticeCompletion', label: 'Notice of completion', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'monitoringChecklist', label: 'Monitoring Check List', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'kobo', label: 'KOBO', kind: RcFieldKind.checkbox),
      ],
    ),
    RcRecordSchema(
      id: 'monitoring',
      title: 'Monitoring Checklist',
      eventType: 'monitoring',
      phase: 'Quality',
      icon: Icons.fact_check_outlined,
      templateAsset: 'assets/templates/original/Monitoring_Checklist_Roof_Repair.docx',
      description: 'Jamaica Red Cross roof-repair inspection from wall plate through final roof details.',
      fields: [
        ...commonHouseFields,
        RcFormFieldDef(key: 'contractorName', label: 'Contractor Name'),
        RcFormFieldDef(key: 'siteSupervisorName', label: 'Site Supervisor name'),
        RcFormFieldDef(key: 'aSquare', label: 'A SQUARE', kind: RcFieldKind.number),

        RcFormFieldDef(key: 'ringBeamExists', label: '1. Existing reinforced ring beam?', kind: RcFieldKind.dropdown, options: ['Yes', 'No']),
        RcFormFieldDef(key: 'ringBeam6x9', label: 'If no: ring beam made 6 x 9 in', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'stirrupsMax1ft', label: '1/4 in stirrups at maximum 1 ft', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'threadedRod2ft', label: '3/8 in bent threaded rod every 2 ft maximum', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'rafterStrapsThroughRebar', label: 'Rafter straps through rebar — 2 per rafter', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'steelConcreteCover', label: '1/2 in steel has minimum 1 in concrete cover', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'woodVerticalStraps', label: 'Wood wall plate vertical elements fixed with flat straps / nails', kind: RcFieldKind.checkbox),

        RcFormFieldDef(key: 'roofAngleDegrees', label: '2. Roof angle (degrees)', kind: RcFieldKind.number),
        RcFormFieldDef(key: 'roofAngleCompliant', label: 'Roof angle between 25° and 40°', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'roofAngleException', label: 'If not, why?', kind: RcFieldKind.dropdown, options: ['Not a full reconstruction case', 'Other houses/elements interfere', 'Not safe to increase height', 'Other']),
        RcFormFieldDef(key: 'roofAngleExceptionNote', label: 'Roof angle exception note', kind: RcFieldKind.multiline),
        RcFormFieldDef(key: 'roofGeometryRule', label: 'Roof geometry check', kind: RcFieldKind.dropdown, options: ['Gabled', 'Pitched', 'Other']),

        RcFormFieldDef(key: 'rafterSize', label: '3. Rafter size', kind: RcFieldKind.dropdown, options: ['2x4', '2x6', '3x6', 'Other']),
        RcFormFieldDef(key: 'rafterOverhangMax6', label: 'Rafter overhang maximum 6 in', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'rafterScrewsWallRidge', label: 'Two 5 in screws to wall plate and ridge beam', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'rafterSpacingMax2ft', label: 'Rafters every 2 ft maximum', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'rafterNailsEveryHole', label: '1 1/4 in nails in every strap hole', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'rafterHurricaneStraps', label: 'Hurricane strap at every rafter', kind: RcFieldKind.checkbox),

        RcFormFieldDef(key: 'battenSpacing', label: '4. Battens: 2 ft middle / 1 ft top & bottom', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'battenHurricaneStraps', label: 'Hurricane straps at every batten/rafter connection', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'battenOverhang', label: 'Batten overhang between 3 and 6 in', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'battenNailsEveryHole', label: '1 1/4 in nails in every strap hole', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'battenFourInchScrews', label: 'Two 4 in screws from batten to rafter', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'topBottomBatten2x6', label: '2x6 on top and bottom batten', kind: RcFieldKind.checkbox),

        RcFormFieldDef(key: 'plywoodExistingGood', label: '5. More than 50% existing plywood/battens in good condition', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'plywoodScrews6in', label: 'T1-11 screwed to rafters every 6 in', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'plywoodSpacing', label: '1/8 in spacing between T1-11 sheets', kind: RcFieldKind.checkbox),

        RcFormFieldDef(key: 'zincSideOverlap', label: '6. Zinc side overlap of 2 waves', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'zincTopBottomOverlap', label: 'Top/bottom overlap minimum 1 ft and maximum 2 ft', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'zincOverhangMax3', label: 'Zinc overhang maximum 3 in', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'zincScrewPattern', label: '2 1/2 in zinc screws at top/bottom/first 3 side waves/overlaps', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'zincOtherWaveScrew', label: 'One screw on every other wave for remainder', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'flashingScrews6in', label: 'Flashing attached with screw every 6 in', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'lowAngleValleyBend', label: 'Below 15°: top zinc-sheet valleys bent upward', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'ridgeAdhesiveFoil', label: 'Adhesive bituminous foil between ridge zinc sheets', kind: RcFieldKind.checkbox),

        RcFormFieldDef(key: 'bottomOverhangMax1ft', label: '7. Bottom overhang maximum 1 ft', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'topFlashing', label: 'Flashing at top of pitched roof', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'topOverhangMax1ft', label: 'Top overhang maximum 1 ft', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'bracing45', label: 'Brace walls and corners at 45° where possible', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'collarsEveryOtherRafter', label: '2x6 collars in every other rafter', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'collarBolt', label: 'Collars connected with 1/8 x 8 in bolt sandwiching rafter', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'collarsOneThird', label: 'Collars placed at 1/3 of gable height', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'verandaSafe', label: 'Veranda treatment meets safety criteria', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'gutters', label: 'Gutters installed / retained', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'gutterException', label: 'If no gutters, why?', kind: RcFieldKind.multiline),
        RcFormFieldDef(key: 'monitoringDate', label: 'Monitoring date', kind: RcFieldKind.date, required: true),
        RcFormFieldDef(key: 'pictureSent', label: 'Picture sent', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'photos', label: 'Monitoring photos', kind: RcFieldKind.photo),
      ],
    ),
    RcRecordSchema(
      id: 'notice-completion',
      title: 'Notice of Completion',
      eventType: 'notice',
      phase: 'Close-out',
      icon: Icons.verified_outlined,
      templateAsset: 'assets/templates/original/Notice_of_Completion.docx',
      fields: [
        ...commonHouseFields,
        RcFormFieldDef(key: 'operationName', label: 'Operation / Programme Name'),
        RcFormFieldDef(key: 'startDate', label: 'Start Date of Works', kind: RcFieldKind.date),
        RcFormFieldDef(key: 'endDate', label: 'End Date of Works', kind: RcFieldKind.date),
        RcFormFieldDef(key: 'totalWorkingDays', label: 'Total Number of Working Days', kind: RcFieldKind.number),
        RcFormFieldDef(key: 'extensionRequested', label: 'Extension Requested', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'additionalDays', label: 'Additional Days', kind: RcFieldKind.number),
        RcFormFieldDef(key: 'dateCompletion', label: 'Date of Completion', kind: RcFieldKind.date),
        RcFormFieldDef(key: 'finalInspectionDate', label: 'Final Inspection Date', kind: RcFieldKind.date),
        RcFormFieldDef(key: 'beneficiaryAcknowledgement', label: 'Beneficiary acknowledgement', kind: RcFieldKind.checkbox),
        RcFormFieldDef(key: 'beneficiarySignature', label: 'Beneficiary signature', kind: RcFieldKind.signature),
        RcFormFieldDef(key: 'supervisorSignature', label: 'Supervisor / Red Cross Representative signature', kind: RcFieldKind.signature),
      ],
    ),
    RcRecordSchema(
      id: 'payment-request',
      title: 'Payment Request',
      eventType: 'payment',
      phase: 'Finance',
      icon: Icons.payments_outlined,
      templateAsset: 'assets/templates/original/Payment_Request_Form.docx',
      description: 'Payment readiness, attendance reconciliation, 46/31/23 team allocation and approval chain.',
      fields: [
        ...commonHouseFields,
        RcFormFieldDef(key: 'projectName', label: 'Project Name', defaultValue: 'Hurricane Melissa Roof Repair'),
        RcFormFieldDef(key: 'supervisor', label: 'Supervisor'),
        RcFormFieldDef(key: 'payPeriod', label: 'Pay Period'),
        RcFormFieldDef(key: 'roofSize', label: 'Roof Size (squares)', kind: RcFieldKind.number, required: true),
        RcFormFieldDef(key: 'ratePerSquare', label: 'Rate per square (JMD)', kind: RcFieldKind.number, defaultValue: 23000),
        RcFormFieldDef(key: 'demolitionRate', label: 'Demolition Rate / Allowance (JMD)', kind: RcFieldKind.number, defaultValue: 12000),
        RcFormFieldDef(key: 'roofingAmount', label: 'Roofing Amount (JMD)', kind: RcFieldKind.number),
        RcFormFieldDef(key: 'demolitionCost', label: 'Demolition Cost (JMD)', kind: RcFieldKind.number),
        RcFormFieldDef(key: 'additionalWorkDescription', label: 'Additional Work description'),
        RcFormFieldDef(key: 'additionalWork', label: 'Additional Work amount (JMD)', kind: RcFieldKind.number),
        RcFormFieldDef(key: 'totalLabourCost', label: 'Total Labour Cost (JMD)', kind: RcFieldKind.number),
        RcFormFieldDef(key: 'expectedWorkDays', label: 'Expected crew work days', kind: RcFieldKind.number),
        RcFormFieldDef(key: 'attendanceDeductions', label: 'Attendance deductions (JMD)', kind: RcFieldKind.number),
        RcFormFieldDef(key: 'adjustedPayment', label: 'Attendance-adjusted payable (JMD)', kind: RcFieldKind.number),
        RcFormFieldDef(key: 'teamAllocation', label: 'Team Allocation Breakdown', kind: RcFieldKind.lineItems, helper: 'Carpenter 46% • Worker 31% • Apprentice 23% • payable days / expected days • adjusted amount'),
        RcFormFieldDef(key: 'siteSupervisorApproval', label: 'Site Supervisor approval', kind: RcFieldKind.signature),
        RcFormFieldDef(key: 'regionalSupervisorApproval', label: 'Regional Supervisor approval', kind: RcFieldKind.signature),
        RcFormFieldDef(key: 'constructionSpecialistApproval', label: 'Construction Specialist approval', kind: RcFieldKind.signature),
      ],
    ),
  ];

  static RcRecordSchema byEventType(String eventType) => schemas.firstWhere(
        (schema) => schema.eventType == eventType,
        orElse: () => RcRecordSchema(
          id: eventType,
          title: eventType,
          eventType: eventType,
          phase: 'Other',
          icon: Icons.description_outlined,
          fields: commonHouseFields,
        ),
      );
}
