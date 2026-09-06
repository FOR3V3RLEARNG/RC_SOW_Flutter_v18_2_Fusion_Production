import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/design_tokens.dart';
import '../../core/workforce.dart';
import '../../core/record_schemas.dart';
import '../../core/rc_components.dart';
import '../../models/app_models.dart';
import '../../services/export_service.dart';
import '../../state/app_state.dart';
import '../shared/signature_pad.dart';
import '../workforce/crew_assignment_panel.dart';

class RecordFormScreen extends StatefulWidget {
  const RecordFormScreen({
    super.key,
    required this.state,
    required this.schema,
    this.record,
  });

  final AppState state;
  final RcRecordSchema schema;
  final ProductionRecord? record;

  @override
  State<RecordFormScreen> createState() => _RecordFormScreenState();
}

class _RecordFormScreenState extends State<RecordFormScreen> {
  final formKey = GlobalKey<FormState>();
  final values = <String, dynamic>{};
  final controllers = <String, TextEditingController>{};
  final signatures = <String, Uint8List>{};
  final photoBytes = <String, Uint8List>{};
  final photoExtensions = <String, String>{};
  bool busy = false;
  bool paymentCalculating = false;
  BeneficiaryRecord? beneficiary;

  UserProfile get profile => widget.state.profile!;

  @override
  void initState() {
    super.initState();
    values.addAll(widget.record?.item ?? const {});
    for (final field in widget.schema.fields) {
      if (_usesController(field.kind)) {
        final initial = values[field.key] ?? field.defaultValue ?? '';
        controllers[field.key] = TextEditingController(text: '$initial');
      }
      if (field.kind == RcFieldKind.checkbox &&
          !values.containsKey(field.key)) {
        values[field.key] = field.defaultValue == true;
      }
      if (field.kind == RcFieldKind.dropdown &&
          !values.containsKey(field.key)) {
        if (field.key == 'parish' && !profile.canViewAllParishes) {
          values[field.key] = profile.parish;
        } else if (field.options.isNotEmpty && field.defaultValue != null) {
          values[field.key] = field.defaultValue;
        }
      }
    }
  }

  bool _usesController(RcFieldKind kind) => const {
    RcFieldKind.text,
    RcFieldKind.number,
    RcFieldKind.multiline,
    RcFieldKind.lineItems,
    RcFieldKind.percentage,
  }.contains(kind);

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> _collect() {
    final data = <String, dynamic>{...values};
    for (final entry in controllers.entries) {
      data[entry.key] = entry.value.text.trim();
    }
    for (final entry in signatures.entries) {
      data['${entry.key}SignedBy'] = profile.displayName;
      data['${entry.key}SignerRole'] = profile.role;
      data['${entry.key}SignedAt'] = DateTime.now().toUtc().toIso8601String();
    }
    data['title'] = widget.schema.title;
    data['phase'] = widget.schema.phase;
    data['status'] ??= widget.record?.status ?? 'Open';
    data['templateAsset'] = widget.schema.templateAsset;
    if (beneficiary != null) {
      data['beneficiarySource'] = 'Shelter Roof Repair Assessment';
    }
    return data;
  }

  Future<void> _save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    formKey.currentState!.save();
    final currentHouse =
        controllers['houseCode']?.text.trim().toUpperCase() ??
        '${values['houseCode'] ?? widget.record?.houseCode ?? ''}'
            .trim()
            .toUpperCase();
    final parish =
        '${values['parish'] ?? widget.record?.parish ?? profile.parish}'.trim();
    if (currentHouse.isEmpty &&
        widget.schema.eventType != 'inventory' &&
        widget.schema.eventType != 'workProjection' &&
        widget.schema.eventType != 'constructionSchedule') {
      _snack('House number is required.');
      return;
    }
    if (parish.isEmpty) {
      _snack('Parish is required.');
      return;
    }
    final house = currentHouse.isEmpty
        ? 'PARISH-${parish.toUpperCase().replaceAll(' ', '-')}'
        : currentHouse;
    setState(() => busy = true);
    try {
      await _uploadPendingArtifacts(house: house, parish: parish);
      final data = _collect();
      await widget.state.repository.submitControlEvent(
        profile: profile,
        eventType: widget.schema.eventType,
        houseCode: house,
        parish: parish,
        recordId: widget.record?.id,
        item: data,
      );
      await widget.state.feedback(strong: true);
      if (!mounted) return;
      _snack('Saved and synchronized.');
      Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        _snack(
          'Could not save. Your input remains on screen; check connectivity and retry.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _chooseBeneficiary() async {
    final search = TextEditingController(
      text: controllers['houseCode']?.text ?? '',
    );
    List<BeneficiaryRecord> results = const [];
    bool loading = false;
    final selected = await showModalBottomSheet<BeneficiaryRecord>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => FractionallySizedBox(
          heightFactor: .82,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'IA • Shelter beneficiary data',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const Icon(Icons.auto_awesome_outlined),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: search,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'House number or beneficiary name',
                    suffixIcon: IconButton(
                      onPressed: () async {
                        setSheetState(() => loading = true);
                        try {
                          results = await widget.state.repository
                              .searchBeneficiaries(
                                profile,
                                query: search.text.trim(),
                                limit: 100,
                              );
                        } finally {
                          if (context.mounted) {
                            setSheetState(() => loading = false);
                          }
                        }
                      },
                      icon: const Icon(Icons.search),
                    ),
                  ),
                  onSubmitted: (_) async {
                    setSheetState(() => loading = true);
                    try {
                      results = await widget.state.repository
                          .searchBeneficiaries(
                            profile,
                            query: search.text.trim(),
                            limit: 100,
                          );
                    } finally {
                      if (context.mounted) setSheetState(() => loading = false);
                    }
                  },
                ),
                if (loading) const LinearProgressIndicator(),
                const SizedBox(height: 8),
                Expanded(
                  child: results.isEmpty
                      ? const Center(
                          child: Text(
                            'Search protected Shelter assessment data.',
                          ),
                        )
                      : ListView.separated(
                          itemCount: results.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (_, index) {
                            final item = results[index];
                            return ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.home_outlined),
                              ),
                              title: Text(
                                '${item.houseCode} • ${item.beneficiaryName}',
                              ),
                              subtitle: Text(
                                '${item.parish} • ${item.cluster}${item.gps.isEmpty ? '' : ' • ${item.gps}'}',
                              ),
                              onTap: () => Navigator.pop(sheetContext, item),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    search.dispose();
    if (selected == null || !mounted) return;
    setState(() {
      beneficiary = selected;
      _setController('houseCode', selected.houseCode);
      _setController('beneficiaryName', selected.beneficiaryName);
      _setController('cluster', selected.cluster);
      _setController('gps', selected.gps);
      values['parish'] = selected.parish;
      if (selected.roofLength != null) {
        _setController('length', '${selected.roofLength}');
      }
      if (selected.roofWidth != null) {
        _setController('width', '${selected.roofWidth}');
      }
      if (selected.wallHeight != null) {
        _setController('wallHeight', '${selected.wallHeight}');
      }
      if (selected.roofType != null) values['roofType'] = selected.roofType;
    });
  }

  void _setController(String key, String value) {
    final controller = controllers[key];
    if (controller != null) controller.text = value;
    values[key] = value;
  }

  Future<void> _captureSignature(RcFormFieldDef field) async {
    final bytes = await RcSignaturePad.capture(context, title: field.label);
    if (bytes != null && mounted) setState(() => signatures[field.key] = bytes);
  }

  Future<void> _pickPhoto(RcFormFieldDef field) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 82,
      maxWidth: 1800,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final extension = file.name.contains('.')
        ? file.name.split('.').last.toLowerCase()
        : 'jpg';
    if (!mounted) return;
    setState(() {
      photoBytes[field.key] = bytes;
      photoExtensions[field.key] = extension;
      values[field.key] = 'Pending secure upload';
    });
  }

  Future<void> _uploadPendingArtifacts({
    required String house,
    required String parish,
  }) async {
    for (final entry in photoBytes.entries) {
      final path = await widget.state.repository.uploadEvidence(
        parish: parish,
        houseCode: house,
        recordType: widget.schema.eventType,
        fieldKey: entry.key,
        bytes: entry.value,
        extension: photoExtensions[entry.key] ?? 'jpg',
      );
      values[entry.key] = path;
      values['${entry.key}StorageBucket'] = 'evidence';
      values['${entry.key}UploadedAt'] = DateTime.now()
          .toUtc()
          .toIso8601String();
    }
    for (final entry in signatures.entries) {
      final path = await widget.state.repository.uploadSignature(
        parish: parish,
        houseCode: house,
        recordType: widget.schema.eventType,
        fieldKey: entry.key,
        bytes: entry.value,
      );
      values['${entry.key}Path'] = path;
      values['${entry.key}StorageBucket'] = 'signatures';
      values['${entry.key}SignedBy'] = profile.displayName;
      values['${entry.key}SignerRole'] = profile.role;
      values['${entry.key}SignedAt'] = DateTime.now().toUtc().toIso8601String();
    }
  }

  double _number(String key) =>
      double.tryParse(
        controllers[key]?.text.trim().replaceAll(',', '') ??
            '${values[key] ?? ''}',
      ) ??
      0;

  Future<void> _calculatePaymentFromAttendance() async {
    final house = controllers['houseCode']?.text.trim().toUpperCase() ?? '';
    final expectedDays = _number('expectedWorkDays');
    if (house.isEmpty) {
      _snack('Choose a house before reconciling attendance.');
      return;
    }
    if (expectedDays <= 0) {
      _snack('Enter expected crew work days first.');
      return;
    }
    setState(() => paymentCalculating = true);
    try {
      final summary = await widget.state.repository.attendancePaymentSummary(
        houseCode: house,
      );
      if (summary.isEmpty) {
        _snack('No attendance records are available for $house.');
        return;
      }
      final roofingAmount = _number('roofSize') * _number('ratePerSquare');
      final demolitionCost = _number('demolitionCost');
      final additionalWork = _number('additionalWork');
      final gross = roofingAmount + demolitionCost + additionalWork;
      const percentages = <String, double>{
        'Carpenter': RcPaymentRules.carpenterPercent,
        'Worker': RcPaymentRules.workerPercent,
        'Apprentice': RcPaymentRules.apprenticePercent,
      };
      final roleCounts = <String, int>{};
      for (final row in summary) {
        final role = '${row['member_role'] ?? ''}';
        roleCounts[role] = (roleCounts[role] ?? 0) + 1;
      }
      var totalDeduction = 0.0;
      var pending = 0;
      final lines = <String>[];
      for (final row in summary) {
        final role = '${row['member_role'] ?? ''}';
        final member =
            '${row['member_name'] ?? row['member_email'] ?? 'Crew member'}';
        final payable =
            (row['payable_days'] as num?)?.toDouble() ??
            double.tryParse('${row['payable_days'] ?? 0}') ??
            0;
        final pendingDays =
            (row['pending_days'] as num?)?.toInt() ??
            int.tryParse('${row['pending_days'] ?? 0}') ??
            0;
        pending += pendingDays;
        final percent = percentages[role] ?? 0;
        final membersInRole = roleCounts[role] ?? 1;
        final memberGrossShare = gross * percent / membersInRole;
        final missing = expectedDays > payable ? expectedDays - payable : 0.0;
        final deduction = memberGrossShare * (missing / expectedDays);
        final adjusted = memberGrossShare - deduction;
        totalDeduction += deduction;
        lines.add(
          '$role • $member • ${payable.toStringAsFixed(1)}/${expectedDays.toStringAsFixed(1)} payable days • JMD ${adjusted.toStringAsFixed(2)}',
        );
      }
      _setController('roofingAmount', roofingAmount.toStringAsFixed(2));
      _setController('totalLabourCost', gross.toStringAsFixed(2));
      _setController('attendanceDeductions', totalDeduction.toStringAsFixed(2));
      _setController(
        'adjustedPayment',
        (gross - totalDeduction)
            .clamp(0.0, double.infinity)
            .toDouble()
            .toStringAsFixed(2),
      );
      _setController('teamAllocation', lines.join('\n'));
      values['attendanceSummary'] = summary;
      values['attendancePendingDays'] = pending;
      values['status'] = pending > 0 ? 'Not Ready' : 'Ready';
      _snack(
        pending > 0
            ? '$pending attendance entries still require verification. Payment remains Not Ready.'
            : 'Attendance reconciled. Payment is ready for approval review.',
      );
      if (mounted) setState(() {});
    } catch (_) {
      _snack(
        'Attendance reconciliation failed. Verify the workforce backend and retry.',
      );
    } finally {
      if (mounted) setState(() => paymentCalculating = false);
    }
  }

  Future<void> _delete() async {
    final record = widget.record;
    if (record == null || !profile.isAdmin) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete record?'),
        content: const Text(
          'This removes the operational record and is recorded in the audit trail where supported.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.state.repository.deleteProductionRecord(record);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        _snack(
          'Record could not be deleted. Confirm Admin access and backend migration, then retry.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = _collect();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.record == null
              ? 'Add ${widget.schema.title}'
              : widget.schema.title,
        ),
        actions: [
          IconButton(
            tooltip: 'Export PDF',
            onPressed: () => RcExportService.shareRecordPdf(
              title: widget.schema.title,
              data: data,
              signature: signatures.values.firstOrNull,
            ),
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
          IconButton(
            tooltip: 'Export Excel',
            onPressed: () => RcExportService.shareRecordXlsx(
              title: widget.schema.title,
              data: data,
            ),
            icon: const Icon(Icons.table_view_outlined),
          ),
          if (widget.record != null && profile.isAdmin)
            IconButton(
              tooltip: 'Delete record',
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
          children: [
            RcExpressiveSurface(
              shape: RcSurfaceShape.hero,
              tone: theme.colorScheme.primaryContainer.withValues(alpha: .32),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    widget.schema.icon,
                    size: RcIconSize.lg,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.schema.phase.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.schema.description.isEmpty
                              ? 'Structured RC SOW production record.'
                              : widget.schema.description,
                        ),
                        if (widget.schema.templateAsset != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Template-backed record',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'IA beneficiary autofill',
                    onPressed: _chooseBeneficiary,
                    icon: const Icon(Icons.auto_awesome_outlined),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (widget.schema.eventType == 'payment') ...[
              RcExpressiveSurface(
                shape: RcSurfaceShape.offset,
                child: Row(
                  children: [
                    const Icon(Icons.how_to_reg_outlined),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Attendance → payment reconciliation',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Uses verified daily crew attendance to calculate missing-day deductions before the 46 / 31 / 23 payout.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.tonal(
                      onPressed: paymentCalculating
                          ? null
                          : _calculatePaymentFromAttendance,
                      child: Text(
                        paymentCalculating ? 'Calculating…' : 'Calculate',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            ...widget.schema.fields.map(
              (field) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _field(field),
              ),
            ),
            if (widget.schema.eventType == 'constructionSchedule' &&
                profile.hasPrivilege('manageCrew')) ...[
              const SizedBox(height: 2),
              CrewAssignmentPanel(state: widget.state),
              const SizedBox(height: 14),
            ],
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: busy ? null : _save,
              icon: busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_done_outlined),
              label: Text(busy ? 'Saving…' : 'Save record'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(RcFormFieldDef field) {
    final controller = controllers[field.key];
    switch (field.kind) {
      case RcFieldKind.text:
      case RcFieldKind.number:
      case RcFieldKind.multiline:
      case RcFieldKind.lineItems:
      case RcFieldKind.percentage:
        return TextFormField(
          controller: controller,
          keyboardType:
              field.kind == RcFieldKind.number ||
                  field.kind == RcFieldKind.percentage
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.multiline,
          minLines:
              field.kind == RcFieldKind.multiline ||
                  field.kind == RcFieldKind.lineItems
              ? 3
              : 1,
          maxLines:
              field.kind == RcFieldKind.multiline ||
                  field.kind == RcFieldKind.lineItems
              ? 6
              : 1,
          decoration: InputDecoration(
            labelText: field.label,
            helperText: field.helper,
          ),
          validator: field.required
              ? (value) => value == null || value.trim().isEmpty
                    ? '${field.label} is required.'
                    : null
              : null,
        );
      case RcFieldKind.dropdown:
        final options = field.key == 'parish' && !profile.canViewAllParishes
            ? [profile.parish]
            : field.options;
        final current = values[field.key]?.toString();
        return DropdownButtonFormField<String>(
          key: ValueKey('${field.key}:${current ?? ''}'),
          initialValue: options.contains(current) ? current : null,
          decoration: InputDecoration(
            labelText: field.label,
            helperText: field.helper,
          ),
          items: options
              .map(
                (option) =>
                    DropdownMenuItem(value: option, child: Text(option)),
              )
              .toList(),
          onChanged: (value) => setState(() => values[field.key] = value),
          validator: field.required
              ? (value) => value == null || value.isEmpty
                    ? '${field.label} is required.'
                    : null
              : null,
        );
      case RcFieldKind.checkbox:
        return SwitchListTile.adaptive(
          contentPadding: const EdgeInsets.symmetric(horizontal: 6),
          title: Text(field.label),
          subtitle: field.helper == null ? null : Text(field.helper!),
          value: values[field.key] == true,
          onChanged: (value) => setState(() => values[field.key] = value),
        );
      case RcFieldKind.date:
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          title: Text(field.label),
          subtitle: Text('${values[field.key] ?? 'Choose date'}'),
          trailing: const Icon(Icons.calendar_today_outlined),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime(2035),
              initialDate: DateTime.now(),
            );
            if (!mounted) return;
            if (picked != null) {
              setState(
                () => values[field.key] = picked
                    .toIso8601String()
                    .split('T')
                    .first,
              );
            }
          },
        );
      case RcFieldKind.photo:
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          leading: const Icon(Icons.camera_alt_outlined),
          title: Text(field.label),
          subtitle: Text(
            photoBytes.containsKey(field.key)
                ? 'Photo ready for secure upload'
                : values[field.key] == null
                ? 'Capture evidence photo'
                : 'Evidence stored securely',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _pickPhoto(field),
        );
      case RcFieldKind.signature:
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          leading: const Icon(Icons.draw_outlined),
          title: Text(field.label),
          subtitle: Text(
            signatures.containsKey(field.key)
                ? 'Digitally signed in this session'
                : 'Tap to sign or request signature',
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (action) async {
              if (action == 'sign') {
                await _captureSignature(field);
              } else {
                final house =
                    controllers['houseCode']?.text.trim() ??
                    widget.record?.houseCode ??
                    '';
                final parish =
                    '${values['parish'] ?? widget.record?.parish ?? profile.parish}';
                if (house.isEmpty) {
                  _snack('Choose a house before requesting a signature.');
                  return;
                }
                final isBeneficiary = field.label.toLowerCase().contains(
                  'beneficiary',
                );
                final role = isBeneficiary
                    ? 'Beneficiary'
                    : _roleFromSignatureLabel(field.label);
                final recipientRole = isBeneficiary ? 'Site Supervisor' : role;
                await widget.state.repository.requestSignature(
                  profile: profile,
                  houseCode: house,
                  parish: parish,
                  recordType: widget.schema.eventType,
                  recordId:
                      widget.record?.id ??
                      'draft-${widget.schema.eventType}-$house',
                  signerRole: role,
                  recipientRole: recipientRole,
                );
                _snack(
                  isBeneficiary
                      ? 'Beneficiary signature task sent to the Site Supervisor for in-person capture.'
                      : 'Signature request sent to $recipientRole.',
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'sign', child: Text('Sign now')),
              PopupMenuItem(value: 'request', child: Text('Request signature')),
            ],
          ),
          onTap: () => _captureSignature(field),
        );
    }
  }

  String _roleFromSignatureLabel(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('regional')) return 'Regional Supervisor';
    if (lower.contains('construction')) return 'Construction Specialist';
    if (lower.contains('carpenter')) return 'Carpenter';
    if (lower.contains('site supervisor') || lower.contains('supervisor')) {
      return 'Site Supervisor';
    }
    return profile.role;
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
