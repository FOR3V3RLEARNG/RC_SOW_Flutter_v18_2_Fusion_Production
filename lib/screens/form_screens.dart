import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/models.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

class OperationalFormScreen extends StatefulWidget {
  const OperationalFormScreen._({
    required this.title,
    required this.type,
    required this.phase,
    required this.description,
    required this.sections,
    super.key,
  });

  const OperationalFormScreen.workPlan({Key? key})
      : this._(
          key: key,
          title: 'Work Plan',
          type: 'Work Plan',
          phase: LifecyclePhase.plan,
          description:
              'Plan the house sequence, schedule, crew and required operational sign-off.',
          sections: _workPlanSections,
        );

  const OperationalFormScreen.dailyLog({Key? key})
      : this._(
          key: key,
          title: 'Daily Site Log',
          type: 'Daily Site Log',
          phase: LifecyclePhase.delivery,
          description:
              'Capture attendance, completed work, progress, field evidence and delays.',
          sections: _dailyLogSections,
        );

  const OperationalFormScreen.materialRequest({Key? key})
      : this._(
          key: key,
          title: 'Material Request',
          type: 'Material Request',
          phase: LifecyclePhase.delivery,
          description:
              'Request house-level roofing materials against the live parish inventory.',
          sections: _materialSections,
        );

  const OperationalFormScreen.consumableRequest({Key? key})
      : this._(
          key: key,
          title: 'Consumable Request',
          type: 'Consumable Request',
          phase: LifecyclePhase.delivery,
          description:
              'Request tools and consumables with a traceable receiver and delivery date.',
          sections: _consumableSections,
        );

  final String title;
  final String type;
  final LifecyclePhase phase;
  final String description;
  final List<FormSectionSpec> sections;

  @override
  State<OperationalFormScreen> createState() => _OperationalFormScreenState();
}

class _OperationalFormScreenState extends State<OperationalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, String> _values = <String, String>{};
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final state = AppScope.of(context);
    final house = state.selectedHouse;
    _values.addAll(<String, String>{
      'house': house.code,
      'parish': house.parish,
      'cluster': house.cluster,
      'community': house.community,
      'supervisor': 'Andre Brown',
    });
    _values.addAll(
      state.formDrafts['${house.code}:${widget.type}'] ??
          const <String, String>{},
    );
  }

  void _save({required bool submit}) {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Some required fields need attention. Your existing draft is safe.',
          ),
        ),
      );
      return;
    }
    _formKey.currentState!.save();
    final state = AppScope.of(context);
    state.saveForm(
      type: widget.type,
      houseCode: state.selectedHouseCode,
      values: _values,
      submit: submit,
    );
    showSavedMessage(context, submitted: submit);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final house = state.selectedHouse;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: RcStatusChip(
                label: state.offline ? 'ON DEVICE' : 'SYNCED',
                tone:
                    state.offline ? RcStatusTone.warning : RcStatusTone.success,
                compact: true,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          const RcSyncBanner(),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
                children: <Widget>[
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 850),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          RcPageHeading(
                            eyebrow: '${house.code} / ${widget.phase.label}',
                            title: widget.title,
                            description: widget.description,
                            action: RcStatusChip(
                              label: house.phase.label.toUpperCase(),
                              tone: RcStatusTone.info,
                            ),
                          ),
                          const SizedBox(height: 18),
                          for (final section in widget.sections) ...<Widget>[
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Icon(
                                          section.icon,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                        const SizedBox(width: 9),
                                        Expanded(
                                          child: Text(
                                            section.title,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        final useColumns =
                                            constraints.maxWidth >= 650;
                                        final fields = section.fields
                                            .map(
                                              (field) =>
                                                  _buildField(context, field),
                                            )
                                            .toList();
                                        if (!useColumns) {
                                          return Column(
                                            children: <Widget>[
                                              for (var i = 0;
                                                  i < fields.length;
                                                  i++) ...<Widget>[
                                                fields[i],
                                                if (i != fields.length - 1)
                                                  const SizedBox(height: 13),
                                              ],
                                            ],
                                          );
                                        }
                                        return Wrap(
                                          spacing: 13,
                                          runSpacing: 13,
                                          children: fields
                                              .map(
                                                (field) => SizedBox(
                                                  width: (constraints.maxWidth -
                                                          13) /
                                                      2,
                                                  child: field,
                                                ),
                                              )
                                              .toList(),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                          Card(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerLow,
                            child: ListTile(
                              leading: Icon(
                                state.offline
                                    ? Icons.cloud_off_outlined
                                    : Icons.cloud_done_outlined,
                                color: state.offline
                                    ? RcColors.warning
                                    : RcColors.success,
                              ),
                              title: Text(
                                state.offline
                                    ? 'Safe on this device'
                                    : 'Connected evidence trail',
                              ),
                              subtitle: Text(
                                state.offline
                                    ? 'Submission will queue until a connection returns.'
                                    : 'Saving updates the house activity and production state.',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _save(submit: false),
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('SAVE DRAFT'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _save(submit: true),
                      icon: const Icon(Icons.send_outlined),
                      label: const Text('SUBMIT FOR APPROVAL'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(BuildContext context, FormFieldSpec field) {
    final current = _values[field.keyName];
    if (field.options.isNotEmpty) {
      return DropdownButtonFormField<String>(
        value: field.options.contains(current) ? current : null,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: field.label,
          hintText: field.hint,
        ),
        items: field.options
            .map(
              (option) => DropdownMenuItem<String>(
                value: option,
                child: Text(
                  option,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        validator: (value) => field.required && (value == null || value.isEmpty)
            ? '${field.label} is required.'
            : null,
        onChanged: (value) => _values[field.keyName] = value ?? '',
        onSaved: (value) => _values[field.keyName] = value ?? '',
      );
    }
    return TextFormField(
      initialValue: current,
      keyboardType: field.number
          ? const TextInputType.numberWithOptions(decimal: true)
          : field.multiline
              ? TextInputType.multiline
              : TextInputType.text,
      minLines: field.multiline ? 3 : 1,
      maxLines: field.multiline ? 5 : 1,
      decoration: InputDecoration(
        labelText: field.label,
        hintText: field.hint,
        alignLabelWithHint: field.multiline,
      ),
      validator: (value) =>
          field.required && (value == null || value.trim().isEmpty)
              ? '${field.label} is required.'
              : null,
      onSaved: (value) => _values[field.keyName] = value?.trim() ?? '',
    );
  }
}

const List<FormSectionSpec> _workPlanSections = <FormSectionSpec>[
  FormSectionSpec(
    title: 'Identification',
    icon: Icons.location_on_outlined,
    fields: <FormFieldSpec>[
      FormFieldSpec(
        keyName: 'parish',
        label: 'Parish',
        required: true,
        options: <String>[
          'Hanover',
          'St. Elizabeth',
          'Westmoreland',
          'St. James',
        ],
      ),
      FormFieldSpec(
        keyName: 'community',
        label: 'Village / Community',
        required: true,
      ),
      FormFieldSpec(
        keyName: 'house',
        label: 'House / Beneficiary code',
        required: true,
      ),
      FormFieldSpec(keyName: 'cluster', label: 'Cluster', required: true),
    ],
  ),
  FormSectionSpec(
    title: 'Schedule & scope',
    icon: Icons.calendar_month_outlined,
    fields: <FormFieldSpec>[
      FormFieldSpec(
        keyName: 'startDate',
        label: 'Starting date',
        hint: 'YYYY-MM-DD',
        required: true,
      ),
      FormFieldSpec(
        keyName: 'endDate',
        label: 'Estimated ending date',
        hint: 'YYYY-MM-DD',
        required: true,
      ),
      FormFieldSpec(
        keyName: 'square',
        label: 'Square per house',
        number: true,
        required: true,
      ),
      FormFieldSpec(
        keyName: 'demolitionDays',
        label: 'Days demolishing roof',
        number: true,
      ),
      FormFieldSpec(
        keyName: 'demolitionPayment',
        label: 'Demolition payment (JMD)',
        number: true,
      ),
      FormFieldSpec(
        keyName: 'extensionDays',
        label: 'Days extension',
        number: true,
      ),
    ],
  ),
  FormSectionSpec(
    title: 'Team assignment',
    icon: Icons.groups_outlined,
    fields: <FormFieldSpec>[
      FormFieldSpec(keyName: 'staffCode', label: 'Staff code', required: true),
      FormFieldSpec(
        keyName: 'crewRole',
        label: 'Crew role',
        required: true,
        options: <String>['Carpenter (C)', 'Worker (W)', 'Assistant (A)'],
      ),
      FormFieldSpec(keyName: 'staffName', label: 'Staff name', required: true),
      FormFieldSpec(
        keyName: 'supervisor',
        label: 'Site Supervisor',
        required: true,
      ),
      FormFieldSpec(keyName: 'carpenter', label: 'Carpenter Lead'),
      FormFieldSpec(
        keyName: 'regionalSupervisor',
        label: 'Regional Site Supervisor',
      ),
    ],
  ),
  FormSectionSpec(
    title: 'Requests & agreement',
    icon: Icons.assignment_turned_in_outlined,
    fields: <FormFieldSpec>[
      FormFieldSpec(
        keyName: 'materialsRequest',
        label: 'Materials request reference',
      ),
      FormFieldSpec(
        keyName: 'consumablesRequest',
        label: 'Consumables request reference',
      ),
      FormFieldSpec(
        keyName: 'agreementDate',
        label: 'Agreement date',
        hint: 'YYYY-MM-DD',
      ),
      FormFieldSpec(keyName: 'agreementPlace', label: 'Agreement place'),
    ],
  ),
];

const List<FormSectionSpec> _dailyLogSections = <FormSectionSpec>[
  FormSectionSpec(
    title: 'Log identification',
    icon: Icons.today_outlined,
    fields: <FormFieldSpec>[
      FormFieldSpec(
        keyName: 'date',
        label: 'Date',
        hint: 'YYYY-MM-DD',
        required: true,
      ),
      FormFieldSpec(keyName: 'house', label: 'Site / House', required: true),
      FormFieldSpec(
        keyName: 'technicalTeam',
        label: 'Technical team state',
        options: <String>['On site', 'Remote support', 'Not required'],
      ),
      FormFieldSpec(
        keyName: 'workHours',
        label: 'Daily work hours',
        number: true,
        required: true,
      ),
    ],
  ),
  FormSectionSpec(
    title: 'Attendance',
    icon: Icons.groups_outlined,
    fields: <FormFieldSpec>[
      FormFieldSpec(
        keyName: 'workers',
        label: 'Workers present',
        hint: 'Names and crew roles',
        multiline: true,
        required: true,
      ),
      FormFieldSpec(
        keyName: 'photosTaken',
        label: 'Photos taken',
        number: true,
      ),
    ],
  ),
  FormSectionSpec(
    title: 'Work progress',
    icon: Icons.construction_outlined,
    fields: <FormFieldSpec>[
      FormFieldSpec(
        keyName: 'workDone',
        label: 'Work done',
        multiline: true,
        required: true,
      ),
      FormFieldSpec(
        keyName: 'estimatedAdvance',
        label: 'Estimated advance (%)',
        number: true,
        required: true,
      ),
      FormFieldSpec(
        keyName: 'materialsNeeded',
        label: 'Materials needed',
        multiline: true,
      ),
      FormFieldSpec(
        keyName: 'issues',
        label: 'Issues / Delays',
        multiline: true,
      ),
    ],
  ),
];

const List<FormSectionSpec> _materialSections = <FormSectionSpec>[
  FormSectionSpec(
    title: 'Request context',
    icon: Icons.location_on_outlined,
    fields: <FormFieldSpec>[
      FormFieldSpec(
        keyName: 'requestDate',
        label: 'Request date',
        hint: 'YYYY-MM-DD',
        required: true,
      ),
      FormFieldSpec(
        keyName: 'parish',
        label: 'Parish',
        required: true,
        options: <String>[
          'Hanover',
          'St. Elizabeth',
          'Westmoreland',
          'St. James',
        ],
      ),
      FormFieldSpec(keyName: 'cluster', label: 'Cluster', required: true),
      FormFieldSpec(keyName: 'house', label: 'House', required: true),
      FormFieldSpec(
        keyName: 'carpenter',
        label: 'Carpenter name',
        required: true,
      ),
      FormFieldSpec(
        keyName: 'supervisor',
        label: 'Supervisor name',
        required: true,
      ),
    ],
  ),
  FormSectionSpec(
    title: 'Materials',
    icon: Icons.inventory_2_outlined,
    fields: <FormFieldSpec>[
      FormFieldSpec(
        keyName: 'item',
        label: 'Description of item',
        required: true,
        options: <String>[
          'Ridge beam 2×8',
          'Rafters / Collars 2×6',
          'Battens / Wall plate 2×4',
          'Zinc 26 gauge',
          'Ridge cap',
          'Flashing / Verge',
          'Hurricane straps H3',
          'Zinc screws',
        ],
      ),
      FormFieldSpec(
        keyName: 'quantity',
        label: 'Quantity',
        number: true,
        required: true,
      ),
      FormFieldSpec(
        keyName: 'price',
        label: 'Estimated price (JMD)',
        number: true,
      ),
      FormFieldSpec(
        keyName: 'location',
        label: 'Storage / Delivery location',
        required: true,
      ),
      FormFieldSpec(
        keyName: 'dateNeeded',
        label: 'Date needed',
        hint: 'YYYY-MM-DD',
        required: true,
      ),
      FormFieldSpec(
        keyName: 'justification',
        label: 'Operational justification',
        multiline: true,
        required: true,
      ),
    ],
  ),
  FormSectionSpec(
    title: 'Receipt',
    icon: Icons.local_shipping_outlined,
    fields: <FormFieldSpec>[
      FormFieldSpec(
        keyName: 'dateReceived',
        label: 'Date received',
        hint: 'YYYY-MM-DD',
      ),
      FormFieldSpec(
        keyName: 'receivedBy',
        label: 'Received by Site Supervisor',
      ),
      FormFieldSpec(
        keyName: 'receiverSignature',
        label: 'Receiver signature reference',
      ),
    ],
  ),
];

const List<FormSectionSpec> _consumableSections = <FormSectionSpec>[
  FormSectionSpec(
    title: 'Request context',
    icon: Icons.location_on_outlined,
    fields: <FormFieldSpec>[
      FormFieldSpec(
        keyName: 'requestDate',
        label: 'Request date',
        hint: 'YYYY-MM-DD',
        required: true,
      ),
      FormFieldSpec(
        keyName: 'parish',
        label: 'Parish',
        required: true,
        options: <String>[
          'Hanover',
          'St. Elizabeth',
          'Westmoreland',
          'St. James',
        ],
      ),
      FormFieldSpec(keyName: 'cluster', label: 'Cluster', required: true),
      FormFieldSpec(keyName: 'house', label: 'House', required: true),
      FormFieldSpec(
        keyName: 'carpenter',
        label: 'Carpenter name',
        required: true,
      ),
      FormFieldSpec(
        keyName: 'supervisor',
        label: 'Supervisor name',
        required: true,
      ),
    ],
  ),
  FormSectionSpec(
    title: 'Consumables',
    icon: Icons.handyman_outlined,
    fields: <FormFieldSpec>[
      FormFieldSpec(
        keyName: 'item',
        label: 'Description of item',
        required: true,
        options: <String>[
          'Saw blades',
          'Drill bits',
          'Chalk line',
          'Safety gloves',
          'Safety glasses',
          'Tarpaulin',
          'Other',
        ],
      ),
      FormFieldSpec(
        keyName: 'quantity',
        label: 'Quantity',
        number: true,
        required: true,
      ),
      FormFieldSpec(
        keyName: 'price',
        label: 'Estimated price (JMD)',
        number: true,
      ),
      FormFieldSpec(
        keyName: 'location',
        label: 'Storage / Delivery location',
        required: true,
      ),
      FormFieldSpec(
        keyName: 'dateNeeded',
        label: 'Date needed',
        hint: 'YYYY-MM-DD',
        required: true,
      ),
      FormFieldSpec(
        keyName: 'justification',
        label: 'Operational justification',
        multiline: true,
        required: true,
      ),
    ],
  ),
  FormSectionSpec(
    title: 'Receipt',
    icon: Icons.verified_outlined,
    fields: <FormFieldSpec>[
      FormFieldSpec(
        keyName: 'dateReceived',
        label: 'Date received',
        hint: 'YYYY-MM-DD',
      ),
      FormFieldSpec(
        keyName: 'receivedBy',
        label: 'Received by Site Supervisor',
      ),
      FormFieldSpec(
        keyName: 'receiverSignature',
        label: 'Receiver signature reference',
      ),
    ],
  ),
];

class DocumentChecklistScreen extends StatelessWidget {
  const DocumentChecklistScreen({super.key});

  static const documents = <String>[
    'BOQ',
    'Scope',
    'Workplan',
    'Time Extension',
    'Notice of Completion',
    'Monitoring Checklist',
    'KOBO',
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final house = state.selectedHouse;
    final complete = state.completedDocuments[house.code] ?? <String>{};
    return Scaffold(
      appBar: AppBar(title: const Text('Document Checklist')),
      body: Column(
        children: <Widget>[
          const RcSyncBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        RcPageHeading(
                          eyebrow: '${house.code} / Plan',
                          title: 'Document checklist',
                          description:
                              'Required operational records stay connected to the house and approval trail.',
                          action: RcStatusChip(
                            label:
                                '${complete.length}/${documents.length} COMPLETE',
                            tone: complete.length == documents.length
                                ? RcStatusTone.success
                                : RcStatusTone.warning,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Card(
                          child: Column(
                            children: documents.map((document) {
                              final done = complete.contains(document);
                              return CheckboxListTile(
                                value: done,
                                onChanged: (_) =>
                                    state.toggleDocument(house.code, document),
                                title: Text(
                                  document,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  done
                                      ? 'Verified and linked'
                                      : 'Required before lifecycle advance',
                                ),
                                secondary: Icon(
                                  done
                                      ? Icons.description
                                      : Icons.description_outlined,
                                  color: done
                                      ? RcColors.success
                                      : RcColors.warning,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              state.saveForm(
                                type: 'Document Checklist',
                                houseCode: house.code,
                                values: <String, String>{
                                  'complete': complete.join(', '),
                                },
                                submit: true,
                              );
                              showSavedMessage(context, submitted: true);
                            },
                            icon: const Icon(Icons.send_outlined),
                            label: const Text('SUBMIT CHECKLIST'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MonitoringChecklistScreen extends StatelessWidget {
  const MonitoringChecklistScreen({super.key});

  static const criteria = <String>[
    'Wall Plate',
    'Roof Angle',
    'Rafters',
    'Battens',
    'Plywood / T1-11',
    'Zinc',
    'Other roof elements',
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final house = state.selectedHouse;
    final statuses = state.monitoring.putIfAbsent(
      house.code,
      () => <String, String>{for (final item in criteria) item: 'Pending'},
    );
    final completed =
        statuses.values.where((value) => value != 'Pending').length;
    return Scaffold(
      appBar: AppBar(
        title: Text('${house.code} • Monitoring Checklist'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Evidence',
            onPressed: () => Navigator.pushNamed(context, RcRoutes.evidence),
            icon: const Icon(Icons.photo_library_outlined),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          const RcSyncBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
              children: <Widget>[
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        RcPageHeading(
                          eyebrow: '${house.parish} / ${house.cluster}',
                          title: 'Technical monitoring',
                          description:
                              '${house.beneficiary} • ${house.roofArea.toStringAsFixed(0)} sq ft • Site Supervisor Andre Brown',
                          action: RcStatusChip(
                            label: '$completed/${criteria.length} REVIEWED',
                            tone: completed == criteria.length
                                ? RcStatusTone.success
                                : RcStatusTone.warning,
                          ),
                        ),
                        const SizedBox(height: 18),
                        for (var index = 0;
                            index < criteria.length;
                            index++) ...<Widget>[
                          _InspectionCriterionCard(
                            index: index + 1,
                            criterion: criteria[index],
                            value: statuses[criteria[index]] ?? 'Pending',
                            onChanged: (value) => state.setMonitoringStatus(
                              house.code,
                              criteria[index],
                              value,
                            ),
                            onEvidence: () =>
                                Navigator.pushNamed(context, RcRoutes.evidence),
                            onComment: () => _addInspectionComment(
                              context,
                              state,
                              house.code,
                              criteria[index],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(12),
          color: Theme.of(context).colorScheme.surface,
          child: Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => showSavedMessage(context, submitted: false),
                  child: const Text('SAVE DRAFT'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    state.saveForm(
                      type: 'Monitoring Checklist',
                      houseCode: house.code,
                      values: statuses,
                      submit: true,
                    );
                    showSavedMessage(context, submitted: true);
                  },
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('SUBMIT'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addInspectionComment(
    BuildContext context,
    AppState state,
    String houseCode,
    String criterion,
  ) {
    String comment = state.monitoringComments[houseCode]?[criterion] ?? '';
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$criterion comment'),
        content: TextFormField(
          initialValue: comment,
          onChanged: (value) => comment = value,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(
            labelText: 'Inspection comment',
            alignLabelWithHint: true,
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () {
              final value = comment.trim();
              if (value.isEmpty) return;
              state.setMonitoringComment(
                houseCode,
                criterion,
                value,
              );
              Navigator.pop(dialogContext);
              showSavedMessage(context, submitted: false);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }
}

class _InspectionCriterionCard extends StatelessWidget {
  const _InspectionCriterionCard({
    required this.index,
    required this.criterion,
    required this.value,
    required this.onChanged,
    required this.onEvidence,
    required this.onComment,
  });
  final int index;
  final String criterion;
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onEvidence;
  final VoidCallback onComment;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 15,
                  child: Text(
                    '$index',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    criterion,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                RcStatusChip(
                  label: value.toUpperCase(),
                  compact: true,
                  tone: _toneForInspection(value),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SegmentedButton<String>(
              expandedInsets: EdgeInsets.zero,
              segments: const <ButtonSegment<String>>[
                ButtonSegment<String>(
                  value: 'Pass',
                  icon: Icon(Icons.check_circle_outline),
                  label: Text('Pass'),
                ),
                ButtonSegment<String>(
                  value: 'Attention',
                  icon: Icon(Icons.warning_amber),
                  label: Text('Attention'),
                ),
                ButtonSegment<String>(
                  value: 'Fail',
                  icon: Icon(Icons.cancel_outlined),
                  label: Text('Fail'),
                ),
                ButtonSegment<String>(
                  value: 'N/A',
                  icon: Icon(Icons.remove_circle_outline),
                  label: Text('N/A'),
                ),
              ],
              selected: value == 'Pending' ? <String>{} : <String>{value},
              emptySelectionAllowed: true,
              onSelectionChanged: (selection) {
                if (selection.isNotEmpty) onChanged(selection.first);
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEvidence,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: const Text('EVIDENCE'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  onPressed: onComment,
                  tooltip: 'Add comment',
                  icon: const Icon(Icons.comment_outlined),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  RcStatusTone _toneForInspection(String status) {
    return switch (status) {
      'Pass' => RcStatusTone.success,
      'Attention' => RcStatusTone.warning,
      'Fail' => RcStatusTone.error,
      'N/A' => RcStatusTone.info,
      _ => RcStatusTone.neutral,
    };
  }
}
