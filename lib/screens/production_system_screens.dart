import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/production_models.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

class ScopeImportScreen extends StatefulWidget {
  const ScopeImportScreen({this.seedDocument, super.key});

  final RoofDrawingDocument? seedDocument;

  @override
  State<ScopeImportScreen> createState() => _ScopeImportScreenState();
}

class _ScopeImportScreenState extends State<ScopeImportScreen> {
  int _mode = 0;
  PlatformFile? _file;
  Uint8List? _bytes;
  AiRoofSuggestion? _suggestion;
  LegacyImportBatch? _batch;
  bool _busy = false;
  String? _error;

  Future<void> _pick({required bool image}) async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: image
            ? <String>['jpg', 'jpeg', 'png', 'webp', 'pdf']
            : <String>['csv', 'json', 'xlsx', 'xls', 'pdf'],
      );
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _file = file;
        _bytes = bytes;
        _suggestion = null;
        _batch = null;
        _error = null;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = 'The file picker could not open: $error');
    }
  }

  Future<void> _analyzeImage() async {
    final file = _file;
    final bytes = _bytes;
    if (file == null || bytes == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await AppScope.of(context).analyzeRoofImage(
        fileName: file.name,
        bytes: bytes,
      );
      if (!mounted) return;
      setState(() => _suggestion = result);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Image analysis failed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _previewLegacy() async {
    final file = _file;
    final bytes = _bytes;
    if (file == null || bytes == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final batch = await AppScope.of(context).previewLegacyImport(
        fileName: file.name,
        bytes: bytes,
      );
      if (!mounted) return;
      setState(() => _batch = batch);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Import preview failed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _acceptSuggestion() {
    final suggestion = _suggestion;
    if (suggestion == null) return;
    Navigator.pop(context, suggestion);
  }

  Future<void> _commitImport() async {
    final batch = _batch;
    if (batch == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AppScope.of(context).commitLegacyImport(batch);
      if (!mounted) return;
      setState(() {});
      showSavedMessage(context, submitted: true);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: RcAppBar(title: const Text('Drawing & Legacy Import')),
      body: Column(
        children: <Widget>[
          const RcSyncBanner(),
          if (_busy) const LinearProgressIndicator(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
              children: <Widget>[
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1080),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        RcPageHeading(
                          eyebrow: 'Scope / Safe Import Review',
                          title: '${state.selectedHouseCode} • Bring field work in',
                          description:
                              'Turn a photographed sketch into an editable roof proposal, or map a legacy Kobo, Excel, CSV or JSON file. Nothing enters the verified record until you review it.',
                        ),
                        const SizedBox(height: 18),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SegmentedButton<int>(
                            segments: const <ButtonSegment<int>>[
                              ButtonSegment<int>(
                                value: 0,
                                icon: Icon(Icons.auto_awesome_outlined),
                                label: Text('PHOTO / AI'),
                              ),
                              ButtonSegment<int>(
                                value: 1,
                                icon: Icon(Icons.table_view_outlined),
                                label: Text('LEGACY FILE'),
                              ),
                            ],
                            selected: <int>{_mode},
                            onSelectionChanged: (value) => setState(() {
                              _mode = value.first;
                              _file = null;
                              _bytes = null;
                              _suggestion = null;
                              _batch = null;
                              _error = null;
                            }),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_error != null) ...<Widget>[
                          _MessagePanel(
                            icon: Icons.error_outline,
                            title: 'Action needs attention',
                            message: _error!,
                            tone: RcColors.warningSoft,
                            foreground: RcColors.warning,
                          ),
                          const SizedBox(height: 14),
                        ],
                        if (_mode == 0)
                          _ImageImportFlow(
                            file: _file,
                            bytes: _bytes,
                            suggestion: _suggestion,
                            busy: _busy,
                            onPick: () => _pick(image: true),
                            onAnalyze: _analyzeImage,
                            onAccept: _acceptSuggestion,
                          )
                        else
                          _LegacyImportFlow(
                            file: _file,
                            batch: _batch,
                            busy: _busy,
                            onPick: () => _pick(image: false),
                            onPreview: _previewLegacy,
                            onMappingChanged: () => setState(() {}),
                            onCommit: _commitImport,
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

class _ImageImportFlow extends StatelessWidget {
  const _ImageImportFlow({
    required this.file,
    required this.bytes,
    required this.suggestion,
    required this.busy,
    required this.onPick,
    required this.onAnalyze,
    required this.onAccept,
  });

  final PlatformFile? file;
  final Uint8List? bytes;
  final AiRoofSuggestion? suggestion;
  final bool busy;
  final VoidCallback onPick;
  final VoidCallback onAnalyze;
  final VoidCallback onAccept;

  bool get _canShowImage {
    final extension = file?.extension?.toLowerCase();
    return bytes != null &&
        <String>{'jpg', 'jpeg', 'png', 'webp'}.contains(extension);
  }

  @override
  Widget build(BuildContext context) {
    final result = suggestion;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _MessagePanel(
          icon: Icons.verified_user_outlined,
          title: 'Human verification is required',
          message:
              'AI proposes geometry and measurements only. Check the sketch, drag every uncertain node, and verify dimensions on site before submitting.',
          tone: RcColors.infoSoft,
          foreground: RcColors.info,
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const RcSectionHeader(
                  title: '1. Select the source',
                  subtitle:
                      'Use a clear overhead sketch, drawing export or PDF page.',
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: busy ? null : onPick,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('CHOOSE IMAGE OR PDF'),
                ),
                if (file != null) ...<Widget>[
                  const SizedBox(height: 12),
                  ListTile(
                    tileColor:
                        Theme.of(context).colorScheme.surfaceContainerLow,
                    leading: const Icon(Icons.description_outlined),
                    title: Text(file!.name),
                    subtitle: const Text('Stored on device until accepted'),
                    trailing: const RcStatusChip(
                      label: 'SELECTED',
                      tone: RcStatusTone.info,
                      compact: true,
                    ),
                  ),
                  if (_canShowImage) ...<Widget>[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 310),
                        child: Image.memory(
                          bytes!,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => const SizedBox(
                            height: 180,
                            child: Center(
                              child: Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: busy ? null : onAnalyze,
                    icon: const Icon(Icons.auto_fix_high_outlined),
                    label: const Text('CREATE EDITABLE PROPOSAL'),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (result != null) ...<Widget>[
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final preview = Card(
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  height: 340,
                  child: CustomPaint(
                    painter: _ImportRoofPainter(
                      document: result.document,
                      colorScheme: Theme.of(context).colorScheme,
                    ),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: RcStatusChip(
                          label:
                              '${(result.overallConfidence * 100).round()}% OVERALL CONFIDENCE',
                          tone: result.overallConfidence < .7
                              ? RcStatusTone.warning
                              : RcStatusTone.info,
                        ),
                      ),
                    ),
                  ),
                ),
              );
              final review = Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      RcSectionHeader(
                        title: '2. Review measurements',
                        subtitle: result.engineLabel,
                      ),
                      const SizedBox(height: 12),
                      for (final item in result.measurements)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: item.confidence < .7
                                ? RcColors.warningSoft
                                : RcColors.successSoft,
                            child: Icon(
                              item.confidence < .7
                                  ? Icons.priority_high
                                  : Icons.check,
                              color: item.confidence < .7
                                  ? RcColors.warning
                                  : RcColors.success,
                            ),
                          ),
                          title: Text(item.label),
                          subtitle: Text(
                            '${(item.confidence * 100).round()}% confidence',
                          ),
                          trailing: Text(
                            '${item.value.toStringAsFixed(1)} ${item.unit}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        onPressed: onAccept,
                        icon: const Icon(Icons.edit_road_outlined),
                        label: const Text('ACCEPT INTO DRAWING STUDIO'),
                      ),
                    ],
                  ),
                ),
              );
              if (constraints.maxWidth >= 820) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(child: preview),
                    const SizedBox(width: 14),
                    SizedBox(width: 380, child: review),
                  ],
                );
              }
              return Column(
                children: <Widget>[
                  preview,
                  const SizedBox(height: 14),
                  review,
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}

class _LegacyImportFlow extends StatelessWidget {
  const _LegacyImportFlow({
    required this.file,
    required this.batch,
    required this.busy,
    required this.onPick,
    required this.onPreview,
    required this.onMappingChanged,
    required this.onCommit,
  });

  final PlatformFile? file;
  final LegacyImportBatch? batch;
  final bool busy;
  final VoidCallback onPick;
  final VoidCallback onPreview;
  final VoidCallback onMappingChanged;
  final VoidCallback onCommit;

  @override
  Widget build(BuildContext context) {
    final current = batch;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _MessagePanel(
          icon: Icons.shield_outlined,
          title: 'Review before production',
          message:
              'Duplicate houses, missing parish values and unmapped identity fields remain blocked. Imports are staged and auditable.',
          tone: RcColors.sunshineSoft,
          foreground: RcColors.sunshine,
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const RcSectionHeader(
                  title: '1. Choose a legacy file',
                  subtitle: 'CSV and JSON parse locally; XLSX/PDF use the secure connected parser.',
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: busy ? null : onPick,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('CHOOSE KOBO / EXCEL / CSV FILE'),
                ),
                if (file != null) ...<Widget>[
                  const SizedBox(height: 12),
                  ListTile(
                    tileColor:
                        Theme.of(context).colorScheme.surfaceContainerLow,
                    leading: const Icon(Icons.table_view_outlined),
                    title: Text(file!.name),
                    subtitle: const Text('Ready to inspect column names'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: busy ? null : onPreview,
                    icon: const Icon(Icons.manage_search_outlined),
                    label: const Text('BUILD MAPPING PREVIEW'),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (current != null) ...<Widget>[
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  RcSectionHeader(
                    title: '2. Map fields',
                    subtitle:
                        '${current.rowCount} rows • ${current.mappedFields}/${current.mappings.length} fields mapped',
                    trailing: RcStatusChip(
                      label: current.status.label.toUpperCase(),
                      tone: current.canImport
                          ? RcStatusTone.success
                          : RcStatusTone.warning,
                    ),
                  ),
                  if (current.warnings.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 12),
                    for (final warning in current.warnings)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Icon(
                              Icons.warning_amber_rounded,
                              size: 18,
                              color: RcColors.warning,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(warning)),
                          ],
                        ),
                      ),
                  ],
                  const SizedBox(height: 12),
                  for (final mapping in current.mappings) ...<Widget>[
                    _MappingRow(
                      mapping: mapping,
                      onChanged: (value) {
                        mapping.sourceColumn = value;
                        mapping.confidence = value.isEmpty ? 0 : .88;
                        onMappingChanged();
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                  FilledButton.icon(
                    onPressed:
                        busy || !current.canImport ? null : onCommit,
                    icon: const Icon(Icons.publish_outlined),
                    label: Text(
                      current.status == LegacyImportStatus.imported ||
                              current.status == LegacyImportStatus.queued
                          ? current.status.label.toUpperCase()
                          : 'IMPORT REVIEWED RECORDS',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MappingRow extends StatelessWidget {
  const _MappingRow({required this.mapping, required this.onChanged});

  final ImportFieldMapping mapping;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  mapping.systemField,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (mapping.required)
                const RcStatusChip(
                  label: 'REQUIRED',
                  tone: RcStatusTone.brand,
                  compact: true,
                ),
            ],
          ),
          const SizedBox(height: 9),
          TextFormField(
            initialValue: mapping.sourceColumn,
            decoration: const InputDecoration(
              labelText: 'Source column',
              hintText: 'Enter exact column heading',
              prefixIcon: Icon(Icons.compare_arrows),
            ),
            onChanged: onChanged,
          ),
          const SizedBox(height: 7),
          Text(
            'Sample: ${mapping.sampleValue}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class WorkProjectionScreen extends StatefulWidget {
  const WorkProjectionScreen({super.key});

  @override
  State<WorkProjectionScreen> createState() => _WorkProjectionScreenState();
}

class _WorkProjectionScreenState extends State<WorkProjectionScreen> {
  final _milestone = TextEditingController(text: 'Roof installation complete');
  final _hours = TextEditingController(text: '96');
  final _materials = TextEditingController(text: '14 ft zinc sheets; ridge cap');
  final _risks = TextEditingController();
  DateTime _weekStarting = DateUtils.dateOnly(DateTime.now());
  String? _houseCode;
  int _crewNeeded = 3;

  @override
  void dispose() {
    _milestone.dispose();
    _hours.dispose();
    _materials.dispose();
    _risks.dispose();
    super.dispose();
  }

  Future<void> _pickWeek() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _weekStarting,
      firstDate: DateTime(2025),
      lastDate: DateTime(2035),
      helpText: 'SELECT WEEK START',
    );
    if (selected != null && mounted) {
      setState(() => _weekStarting = selected);
    }
  }

  void _save({bool submit = false}) {
    final state = AppScope.of(context);
    final houseCode = _houseCode ?? state.selectedHouseCode;
    if (_milestone.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add the week milestone first.')),
      );
      return;
    }
    state.addWorkProjection(
      weekStarting: _weekStarting,
      houseCode: houseCode,
      milestone: _milestone.text.trim(),
      estimatedHours: double.tryParse(_hours.text) ?? 0,
      crewNeeded: _crewNeeded,
      materialNeeds: _materials.text.trim(),
      risks: _risks.text.trim(),
      submit: submit,
    );
    showSavedMessage(context, submitted: submit);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    _houseCode ??= state.selectedHouseCode;
    return Scaffold(
      appBar: RcAppBar(title: const Text('Work Projection Log')),
      body: Column(
        children: <Widget>[
          const RcSyncBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
              children: <Widget>[
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        RcPageHeading(
                          eyebrow: 'Plan / Weekly Production',
                          title: 'Work projection log',
                          description:
                              'Plan the milestone, crew time, materials and risks for every active house, then compare estimated hours with actual delivery.',
                          action: RcStatusChip(
                            label: '${state.atRiskProjections} AT RISK',
                            icon: Icons.warning_amber_rounded,
                            tone: state.atRiskProjections > 0
                                ? RcStatusTone.warning
                                : RcStatusTone.success,
                          ),
                        ),
                        const SizedBox(height: 18),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final form = _ProjectionForm(
                              state: state,
                              houseCode: _houseCode!,
                              weekStarting: _weekStarting,
                              milestone: _milestone,
                              hours: _hours,
                              materials: _materials,
                              risks: _risks,
                              crewNeeded: _crewNeeded,
                              onHouse: (value) =>
                                  setState(() => _houseCode = value),
                              onWeek: _pickWeek,
                              onCrew: (value) =>
                                  setState(() => _crewNeeded = value),
                              onSave: () => _save(),
                              onSubmit: () => _save(submit: true),
                            );
                            final pulse = _ProjectionPulse(state: state);
                            if (constraints.maxWidth >= 840) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Expanded(flex: 3, child: form),
                                  const SizedBox(width: 14),
                                  Expanded(flex: 2, child: pulse),
                                ],
                              );
                            }
                            return Column(
                              children: <Widget>[
                                pulse,
                                const SizedBox(height: 14),
                                form,
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        const RcSectionHeader(
                          title: 'House projections',
                          subtitle: 'Estimated versus actual production for the selected operating week.',
                        ),
                        const SizedBox(height: 10),
                        for (final projection in state.workProjections) ...<Widget>[
                          _ProjectionCard(projection: projection),
                          const SizedBox(height: 10),
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
    );
  }
}

class _ProjectionForm extends StatelessWidget {
  const _ProjectionForm({
    required this.state,
    required this.houseCode,
    required this.weekStarting,
    required this.milestone,
    required this.hours,
    required this.materials,
    required this.risks,
    required this.crewNeeded,
    required this.onHouse,
    required this.onWeek,
    required this.onCrew,
    required this.onSave,
    required this.onSubmit,
  });

  final AppState state;
  final String houseCode;
  final DateTime weekStarting;
  final TextEditingController milestone;
  final TextEditingController hours;
  final TextEditingController materials;
  final TextEditingController risks;
  final int crewNeeded;
  final ValueChanged<String> onHouse;
  final VoidCallback onWeek;
  final ValueChanged<int> onCrew;
  final VoidCallback onSave;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const RcSectionHeader(
              title: 'Plan one house',
              subtitle: 'A compact input system for the week ahead.',
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: houseCode,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'House / cluster',
                prefixIcon: Icon(Icons.holiday_village_outlined),
              ),
              items: state.houses
                  .map(
                    (house) => DropdownMenuItem<String>(
                      value: house.code,
                      child: Text(
                        '${house.code} • ${house.cluster}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) onHouse(value);
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onWeek,
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text('WEEK STARTING ${_shortDate(weekStarting)}'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: milestone,
              decoration: const InputDecoration(
                labelText: 'Target milestone',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: hours,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Estimated crew hours',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Crew needed'),
                    child: Row(
                      children: <Widget>[
                        IconButton(
                          tooltip: 'Remove crew member',
                          onPressed: crewNeeded <= 1
                              ? null
                              : () => onCrew(crewNeeded - 1),
                          icon: const Icon(Icons.remove),
                        ),
                        Expanded(
                          child: Text(
                            '$crewNeeded',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Add crew member',
                          onPressed: crewNeeded >= 12
                              ? null
                              : () => onCrew(crewNeeded + 1),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: materials,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Materials and equipment needed',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: risks,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Risks, dependencies or support needed',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.end,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('SAVE DRAFT'),
                ),
                FilledButton.icon(
                  onPressed: onSubmit,
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('SUBMIT WEEK'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectionPulse extends StatelessWidget {
  const _ProjectionPulse({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ratio = state.projectedHours <= 0
        ? 0.0
        : (state.recordedProjectionHours / state.projectedHours)
            .clamp(0, 1)
            .toDouble();
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: dark
            ? Color.alphaBlend(RcColors.plum.withOpacity(.22), colorScheme.surface)
            : RcColors.plumSoft,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(34),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(34),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.insights_outlined,
            color: dark ? const Color(0xFFE5BED8) : RcColors.plum,
          ),
          const SizedBox(height: 18),
          Text('WEEKLY CAPACITY', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(
            '${state.projectedHours.toStringAsFixed(0)} planned hours',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: dark ? const Color(0xFFE5BED8) : RcColors.plum,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '${state.recordedProjectionHours.toStringAsFixed(0)} hours recorded',
          ),
          const SizedBox(height: 18),
          LinearProgressIndicator(value: ratio, minHeight: 10),
          const SizedBox(height: 12),
          Text(
            '${(ratio * 100).round()}% of projected effort logged',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ProjectionCard extends StatelessWidget {
  const _ProjectionCard({required this.projection});

  final WorkProjection projection;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final atRisk = projection.status == ProjectionStatus.atRisk;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                CircleAvatar(
                  backgroundColor:
                      atRisk ? RcColors.warningSoft : RcColors.infoSoft,
                  child: Icon(
                    atRisk ? Icons.priority_high : Icons.flag_outlined,
                    color: atRisk ? RcColors.warning : RcColors.info,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${projection.houseCode} • ${projection.milestone}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${projection.cluster} • week ${_shortDate(projection.weekStarting)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                RcStatusChip(
                  label: projection.status.label.toUpperCase(),
                  tone: atRisk
                      ? RcStatusTone.warning
                      : projection.status == ProjectionStatus.complete ||
                              projection.status == ProjectionStatus.approved
                          ? RcStatusTone.success
                          : RcStatusTone.info,
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: 15),
            LinearProgressIndicator(
              value: projection.completionRatio.clamp(0, 1).toDouble(),
              minHeight: 9,
              color: atRisk ? RcColors.warning : RcColors.success,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: <Widget>[
                Text(
                  '${projection.estimatedHours.toStringAsFixed(0)} h estimated',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text('${projection.actualHours.toStringAsFixed(0)} h actual'),
                Text('${projection.crewNeeded} crew'),
              ],
            ),
            if (projection.materialNeeds.isNotEmpty) ...<Widget>[
              const SizedBox(height: 9),
              Text('Materials: ${projection.materialNeeds}'),
            ],
            if (projection.risks.isNotEmpty) ...<Widget>[
              const SizedBox(height: 5),
              Text(
                'Risk: ${projection.risks}',
                style: const TextStyle(
                  color: RcColors.warning,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                TextButton.icon(
                  onPressed: () => _recordActual(context, state),
                  icon: const Icon(Icons.timer_outlined),
                  label: const Text('RECORD ACTUAL'),
                ),
                if (projection.status == ProjectionStatus.submitted ||
                    projection.status == ProjectionStatus.atRisk)
                  TextButton.icon(
                    onPressed: () => state.approveProjection(projection.id),
                    icon: const Icon(Icons.approval_outlined),
                    label: const Text('APPROVE'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _recordActual(BuildContext context, AppState state) async {
    final controller = TextEditingController(
      text: projection.actualHours.toStringAsFixed(1),
    );
    final value = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${projection.houseCode} actual hours'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Hours recorded'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              double.tryParse(controller.text),
            ),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null) state.updateProjectionActual(projection.id, value);
  }
}

class InventoryTransferScreen extends StatefulWidget {
  const InventoryTransferScreen({super.key});

  @override
  State<InventoryTransferScreen> createState() =>
      _InventoryTransferScreenState();
}

class _InventoryTransferScreenState extends State<InventoryTransferScreen> {
  final _quantity = TextEditingController(text: '12');
  String? _sourceId;
  String? _destinationId;

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  List<StockLedgerItem> _destinations(AppState state, String sourceId) {
    final source = state.stockLedger.firstWhere((item) => item.id == sourceId);
    return state.stockLedger
        .where(
          (item) =>
              item.id != source.id && item.materialCode == source.materialCode,
        )
        .toList();
  }

  void _initialize(AppState state) {
    if (_sourceId != null) return;
    final candidate = state.stockLedger.firstWhere(
      (item) => _destinations(state, item.id).isNotEmpty,
    );
    _sourceId = candidate.id;
    _destinationId = _destinations(state, candidate.id).first.id;
  }

  void _transfer() {
    final sourceId = _sourceId;
    final destinationId = _destinationId;
    if (sourceId == null || destinationId == null) return;
    final state = AppScope.of(context);
    final success = state.transferStock(
      sourceId: sourceId,
      destinationId: destinationId,
      quantity: double.tryParse(_quantity.text) ?? 0,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Stock movement recorded at both locations.'
              : 'Transfer blocked. Check the material and available balance.',
        ),
      ),
    );
    if (success) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    _initialize(state);
    final source = state.stockLedger.firstWhere((item) => item.id == _sourceId);
    final destinations = _destinations(state, source.id);
    return Scaffold(
      appBar: RcAppBar(title: const Text('Inventory Transfer')),
      body: Column(
        children: <Widget>[
          const RcSyncBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
              children: <Widget>[
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const RcPageHeading(
                          eyebrow: 'Logistics / Controlled Movement',
                          title: 'Move stock between levels',
                          description:
                              'Transfer the same catalog item from parish depot to cluster store or house allocation with an auditable balance on both sides.',
                        ),
                        const SizedBox(height: 18),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                DropdownButtonFormField<String>(
                                  value: source.id,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'From inventory location',
                                    prefixIcon:
                                        Icon(Icons.warehouse_outlined),
                                  ),
                                  items: state.stockLedger
                                      .where(
                                        (item) => _destinations(state, item.id)
                                            .isNotEmpty,
                                      )
                                      .map(
                                        (item) => DropdownMenuItem<String>(
                                          value: item.id,
                                          child: Text(
                                            '${item.scopeLabel} • ${item.name} • ${item.onHand.toStringAsFixed(0)} ${item.unit}',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    final next = _destinations(state, value);
                                    setState(() {
                                      _sourceId = value;
                                      _destinationId =
                                          next.isEmpty ? null : next.first.id;
                                    });
                                  },
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  value: destinations.any(
                                    (item) => item.id == _destinationId,
                                  )
                                      ? _destinationId
                                      : null,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'To inventory location',
                                    prefixIcon:
                                        Icon(Icons.location_city_outlined),
                                  ),
                                  items: destinations
                                      .map(
                                        (item) => DropdownMenuItem<String>(
                                          value: item.id,
                                          child: Text(
                                            '${item.tier.label} • ${item.scopeLabel} • ${item.onHand.toStringAsFixed(0)} ${item.unit}',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) =>
                                      setState(() => _destinationId = value),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _quantity,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Quantity (${source.unit})',
                                    prefixIcon:
                                        const Icon(Icons.numbers_outlined),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                _MessagePanel(
                                  icon: Icons.inventory_2_outlined,
                                  title: '${source.name} available',
                                  message:
                                      '${source.onHand.toStringAsFixed(0)} ${source.unit} at ${source.location}. Minimum retained stock is ${source.minimumStock.toStringAsFixed(0)}.',
                                  tone: source.health == InventoryHealth.healthy
                                      ? RcColors.successSoft
                                      : RcColors.warningSoft,
                                  foreground:
                                      source.health == InventoryHealth.healthy
                                          ? RcColors.success
                                          : RcColors.warning,
                                ),
                                const SizedBox(height: 15),
                                FilledButton.icon(
                                  onPressed:
                                      _destinationId == null ? null : _transfer,
                                  icon: const Icon(Icons.swap_horiz_outlined),
                                  label: const Text('RECORD STOCK TRANSFER'),
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
          ),
        ],
      ),
    );
  }
}

class SyncMonitorScreen extends StatelessWidget {
  const SyncMonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final events = state.activities.take(8).toList();
    return Scaffold(
      appBar: RcAppBar(title: const Text('Sync Monitor')),
      body: Column(
        children: <Widget>[
          const RcSyncBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
              children: <Widget>[
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1050),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        RcPageHeading(
                          eyebrow: 'Offline First / Data Health',
                          title: 'Synchronization monitor',
                          description:
                              'See what is safe on this device, what is waiting for Supabase, and which operational records need conflict review.',
                          action: FilledButton.tonalIcon(
                            onPressed: state.retrySync,
                            icon: const Icon(Icons.sync),
                            label: const Text('RETRY NOW'),
                          ),
                        ),
                        const SizedBox(height: 18),
                        RcResponsiveGrid(
                          minItemWidth: 160,
                          childAspectRatio: 1.05,
                          children: <Widget>[
                            RcMetricTile(
                              label: 'Device queue',
                              value: '${state.queuedChanges}',
                              icon: Icons.phone_android_outlined,
                              color: RcColors.warning,
                            ),
                            RcMetricTile(
                              label: 'Backend',
                              value: state.remoteConnected ? 'Live' : 'Local',
                              icon: Icons.cloud_outlined,
                              color: state.remoteConnected
                                  ? RcColors.success
                                  : RcColors.info,
                            ),
                            RcMetricTile(
                              label: 'Import batches',
                              value: '${state.importBatches.length}',
                              icon: Icons.upload_file_outlined,
                              color: RcColors.plum,
                            ),
                            RcMetricTile(
                              label: 'Unsynced stock lines',
                              value:
                                  '${state.stockLedger.where((item) => !item.liveSynced).length}',
                              icon: Icons.inventory_2_outlined,
                              color: RcColors.brand,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _MessagePanel(
                          icon: state.remoteConnected
                              ? Icons.cloud_done_outlined
                              : Icons.phonelink_lock_outlined,
                          title: state.backendConnectionLabel,
                          message: state.offline
                              ? 'Field mode is offline. Changes stay on this device and will retry when connectivity returns.'
                              : state.remoteConnected
                                  ? 'Secure Supabase sync is available. Row-level access still limits records by assigned parish and house.'
                                  : 'The app is using its field repository. Add Supabase build-time values to enable secure remote synchronization.',
                          tone: state.offline
                              ? RcColors.warningSoft
                              : RcColors.infoSoft,
                          foreground:
                              state.offline ? RcColors.warning : RcColors.info,
                        ),
                        const SizedBox(height: 22),
                        const RcSectionHeader(
                          title: 'Recent sync-worthy events',
                          subtitle: 'Newest operational changes appear first.',
                        ),
                        const SizedBox(height: 10),
                        Card(
                          child: Column(
                            children: events
                                .map(
                                  (event) => ListTile(
                                    leading: CircleAvatar(
                                      child: Icon(event.icon, size: 19),
                                    ),
                                    title: Text(
                                      '${event.houseCode} • ${event.title}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    subtitle: Text(event.detail),
                                    trailing: Icon(
                                      state.offline
                                          ? Icons.schedule_outlined
                                          : Icons.cloud_done_outlined,
                                      color: state.offline
                                          ? RcColors.warning
                                          : RcColors.success,
                                    ),
                                  ),
                                )
                                .toList(),
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

class ProductionBoardScreen extends StatefulWidget {
  const ProductionBoardScreen({super.key});

  @override
  State<ProductionBoardScreen> createState() => _ProductionBoardScreenState();
}

class _ProductionBoardScreenState extends State<ProductionBoardScreen> {
  String _window = 'Today';

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final openIssues = state.productionIssues
        .where((issue) => !issue.resolved)
        .toList();
    return Scaffold(
      appBar: RcAppBar(title: const Text('Production Command Board')),
      body: Column(
        children: <Widget>[
          const RcSyncBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 44),
              children: <Widget>[
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        RcPageHeading(
                          eyebrow: '${state.selectedParish} / Production Overview',
                          title: 'Everything that needs attention',
                          description:
                              'A calm command view for a busy operator: work due, blockers, people, materials, approvals and next actions in one place.',
                          action: RcStatusChip(
                            label: '${openIssues.length} OPEN ISSUES',
                            icon: Icons.crisis_alert_outlined,
                            tone: openIssues.isEmpty
                                ? RcStatusTone.success
                                : RcStatusTone.warning,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SegmentedButton<String>(
                            segments: const <ButtonSegment<String>>[
                              ButtonSegment<String>(
                                value: 'Today',
                                label: Text('TODAY'),
                              ),
                              ButtonSegment<String>(
                                value: 'This week',
                                label: Text('THIS WEEK'),
                              ),
                              ButtonSegment<String>(
                                value: 'All',
                                label: Text('ALL PRODUCTION'),
                              ),
                            ],
                            selected: <String>{_window},
                            onSelectionChanged: (value) =>
                                setState(() => _window = value.first),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _ProductionHero(state: state, window: _window),
                        const SizedBox(height: 18),
                        RcResponsiveGrid(
                          minItemWidth: 160,
                          childAspectRatio: 1.05,
                          children: <Widget>[
                            RcMetricTile(
                              label: 'Active houses',
                              value: '${state.activeHouses}',
                              icon: Icons.home_work_outlined,
                              color: RcColors.brand,
                              onTap: () => Navigator.pushNamed(
                                context,
                                RcRoutes.houses,
                              ),
                            ),
                            RcMetricTile(
                              label: 'Weekly hours',
                              value: state.projectedHours.toStringAsFixed(0),
                              icon: Icons.calendar_view_week_outlined,
                              color: RcColors.plum,
                              onTap: () => Navigator.pushNamed(
                                context,
                                RcRoutes.workProjections,
                              ),
                            ),
                            RcMetricTile(
                              label: 'Low stock lines',
                              value:
                                  '${state.stockLedger.where((item) => item.health != InventoryHealth.healthy).length}',
                              icon: Icons.inventory_2_outlined,
                              color: RcColors.warning,
                              onTap: () => Navigator.pushNamed(
                                context,
                                RcRoutes.inventory,
                              ),
                            ),
                            RcMetricTile(
                              label: 'Approvals ready',
                              value:
                                  '${state.closeOutReady + state.paymentsPending}',
                              icon: Icons.approval_outlined,
                              color: RcColors.success,
                              onTap: () => Navigator.pushNamed(
                                context,
                                RcRoutes.approvalQueue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const RcSectionHeader(
                          title: 'Fast production actions',
                          subtitle: 'The four inputs used most often in daily control.',
                        ),
                        const SizedBox(height: 10),
                        RcResponsiveGrid(
                          minItemWidth: 235,
                          childAspectRatio: 1.7,
                          children: <Widget>[
                            _ActionCard(
                              title: 'Control of work',
                              subtitle: 'Progress, crew, materials and blockers',
                              icon: Icons.edit_note_outlined,
                              color: RcColors.brand,
                              route: RcRoutes.workLogs,
                            ),
                            _ActionCard(
                              title: 'Weekly projection',
                              subtitle: 'Milestone, capacity and risk',
                              icon: Icons.trending_up_outlined,
                              color: RcColors.plum,
                              route: RcRoutes.workProjections,
                            ),
                            _ActionCard(
                              title: 'Move inventory',
                              subtitle: 'Parish → cluster → house',
                              icon: Icons.swap_horiz_outlined,
                              color: RcColors.info,
                              route: RcRoutes.inventoryTransfer,
                            ),
                            _ActionCard(
                              title: 'Draw a roof',
                              subtitle: 'Touch drafting and image proposal',
                              icon: Icons.architecture_outlined,
                              color: RcColors.mint,
                              route: RcRoutes.scopeRoof,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        RcSectionHeader(
                          title: 'Blockers requiring ownership',
                          subtitle: 'Resolve or reassign before the due time.',
                          trailing: TextButton(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              RcRoutes.messages,
                            ),
                            child: const Text('MESSAGE TEAM'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (openIssues.isEmpty)
                          const Card(
                            child: ListTile(
                              leading: Icon(
                                Icons.task_alt,
                                color: RcColors.success,
                              ),
                              title: Text('No open production blockers'),
                              subtitle: Text(
                                'The current command window is clear.',
                              ),
                            ),
                          )
                        else
                          for (final issue in openIssues) ...<Widget>[
                            _IssueCard(issue: issue),
                            const SizedBox(height: 10),
                          ],
                        const SizedBox(height: 24),
                        const RcSectionHeader(
                          title: 'Next house milestones',
                          subtitle: 'Weekly promises that need active follow-through.',
                        ),
                        const SizedBox(height: 10),
                        for (final projection
                            in state.workProjections.take(4)) ...<Widget>[
                          _ProjectionCard(projection: projection),
                          const SizedBox(height: 10),
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
    );
  }
}

class _ProductionHero extends StatelessWidget {
  const _ProductionHero({required this.state, required this.window});

  final AppState state;
  final String window;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            dark
                ? Color.alphaBlend(
                    RcColors.brand.withOpacity(.24),
                    colorScheme.surface,
                  )
                : const Color(0xFFFFE8E5),
            dark
                ? Color.alphaBlend(
                    RcColors.sunshine.withOpacity(.18),
                    colorScheme.surface,
                  )
                : const Color(0xFFFFF1D6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(36),
          topRight: Radius.circular(22),
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final summary = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                window.toUpperCase(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: dark ? colorScheme.primary : RcColors.brandStrong,
                      letterSpacing: 1.1,
                    ),
              ),
              const SizedBox(height: 7),
              Text(
                '${state.attentionHouses} houses need a decision',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Start with blockers, confirm materials, then protect the week’s promised milestones.',
              ),
            ],
          );
          final action = FilledButton.icon(
            onPressed: () => Navigator.pushNamed(context, RcRoutes.workLogs),
            icon: const Icon(Icons.playlist_add_check_circle_outlined),
            label: const Text('LOG TODAY’S WORK'),
          );
          if (constraints.maxWidth >= 700) {
            return Row(
              children: <Widget>[
                Expanded(child: summary),
                const SizedBox(width: 20),
                action,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              summary,
              const SizedBox(height: 18),
              action,
            ],
          );
        },
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(.13),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward),
            ],
          ),
        ),
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  const _IssueCard({required this.issue});

  final ProductionIssue issue;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final critical = issue.severity == ProductionIssueSeverity.critical;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CircleAvatar(
              backgroundColor:
                  critical ? RcColors.brandSoft : RcColors.warningSoft,
              child: Icon(
                critical ? Icons.crisis_alert : Icons.warning_amber_rounded,
                color: critical ? RcColors.brand : RcColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${issue.houseCode} • ${issue.title}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text('Owner: ${issue.owner} • due ${_shortDate(issue.dueAt)}'),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 8,
                    children: <Widget>[
                      TextButton(
                        onPressed: () {
                          state.selectHouse(issue.houseCode);
                          Navigator.pushNamed(context, RcRoutes.houseCommand);
                        },
                        child: const Text('OPEN HOUSE'),
                      ),
                      TextButton.icon(
                        onPressed: () => state.resolveProductionIssue(issue.id),
                        icon: const Icon(Icons.task_alt_outlined),
                        label: const Text('RESOLVE'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({
    required this.icon,
    required this.title,
    required this.message,
    required this.tone,
    required this.foreground,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color tone;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(14),
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: foreground),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: foreground,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: TextStyle(color: foreground.withOpacity(.92)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportRoofPainter extends CustomPainter {
  const _ImportRoofPainter({
    required this.document,
    required this.colorScheme,
  });

  final RoofDrawingDocument document;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = colorScheme.outlineVariant.withOpacity(.35)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 22) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += 22) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final points = document.selectedSection.nodes.map((node) {
      return Offset(
        node.x / 850 * size.width,
        node.y / 650 * size.height,
      );
    }).toList();
    if (points.length < 3) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()..color = colorScheme.primaryContainer.withOpacity(.65),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = colorScheme.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    final nodePaint = Paint()..color = colorScheme.primary;
    for (final point in points) {
      canvas.drawCircle(point, 7, nodePaint);
      canvas.drawCircle(
        point,
        3,
        Paint()..color = colorScheme.onPrimary,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ImportRoofPainter oldDelegate) =>
      oldDelegate.document != document || oldDelegate.colorScheme != colorScheme;
}

String _shortDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
