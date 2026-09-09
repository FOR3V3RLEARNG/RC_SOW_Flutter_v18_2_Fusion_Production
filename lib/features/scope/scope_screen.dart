import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/app_constants.dart';
import '../../core/design_tokens.dart';
import '../../core/rc_components.dart';
import '../../models/app_models.dart';
import '../../services/export_service.dart';
import '../../state/app_state.dart';
import '../shared/signature_pad.dart';
import '../roof/technical_roof_draft.dart';

enum RoofDrawTool { wall, ridge, hip, valley, drain, freehand, select }

extension RoofDrawToolX on RoofDrawTool {
  String get label => switch (this) {
    RoofDrawTool.wall => 'Wall',
    RoofDrawTool.ridge => 'Ridge',
    RoofDrawTool.hip => 'Hip',
    RoofDrawTool.valley => 'Valley',
    RoofDrawTool.drain => 'Drain',
    RoofDrawTool.freehand => 'Freehand',
    RoofDrawTool.select => 'Select',
  };
  IconData get icon => switch (this) {
    RoofDrawTool.wall => Icons.square_foot_outlined,
    RoofDrawTool.ridge => Icons.horizontal_rule,
    RoofDrawTool.hip => Icons.change_history_outlined,
    RoofDrawTool.valley => Icons.call_received_outlined,
    RoofDrawTool.drain => Icons.water_drop_outlined,
    RoofDrawTool.freehand => Icons.gesture,
    RoofDrawTool.select => Icons.ads_click_outlined,
  };
}

class RoofStroke {
  RoofStroke({required this.tool, required this.points, this.measurement = ''});
  final RoofDrawTool tool;
  final List<Offset> points;
  String measurement;

  Map<String, dynamic> toMap() => {
    'tool': tool.name,
    'measurement': measurement,
    'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
  };
}

enum _CanvasDragMode { vertex, segment }

class _CanvasEndpointHit {
  const _CanvasEndpointHit({
    required this.strokeIndex,
    required this.pointIndex,
    required this.point,
  });

  final int strokeIndex;
  final int pointIndex;
  final Offset point;
}

class _CanvasEndpointBinding {
  const _CanvasEndpointBinding({
    required this.strokeIndex,
    required this.pointIndex,
    required this.original,
    required this.group,
  });

  final int strokeIndex;
  final int pointIndex;
  final Offset original;
  final int group;

  String get key => '$strokeIndex:$pointIndex';
}

class ScopeScreen extends StatefulWidget {
  const ScopeScreen({super.key, required this.state});
  final AppState state;

  @override
  State<ScopeScreen> createState() => _ScopeScreenState();
}

class _ScopeScreenState extends State<ScopeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController tabs;
  final house = TextEditingController();
  final beneficiary = TextEditingController();
  final cluster = TextEditingController();
  final gps = TextEditingController();
  final width = TextEditingController();
  final length = TextEditingController();
  final wallHeight = TextEditingController();
  final pitch = TextEditingController(text: '4');
  final repairNotes = TextEditingController();
  String repairPreset = 'Replace damaged roof sheeting';
  static const repairPresets = <String>[
    'Replace damaged roof sheeting',
    'Replace / repair wall plate',
    'Replace rafters',
    'Install / replace collar ties',
    'Replace battens',
    'Install hurricane straps',
    'Repair ridge beam',
    'Install / replace fascia board',
    'Install / replace blocking board',
    'Install flashing',
    'Repair gable',
    'Repair veranda roof',
    'Install / repair gutters',
    'Concrete / ring beam repair',
    'Other / custom repair',
  ];

  String parish = 'Hanover';
  String roofType = 'Gable';
  String structureType = 'Block';
  String gableType = 'Wood';
  String rafterSize = '2x6';
  bool t111Ceiling = false;
  RoofDrawTool drawTool = RoofDrawTool.wall;
  final strokes = <RoofStroke>[];
  final redo = <RoofStroke>[];
  List<Offset> current = [];
  int? selectedStrokeIndex;
  _CanvasDragMode? _dragMode;
  Offset? _dragAnchor;
  Offset? _dragSegmentStart;
  Offset? _dragSegmentEnd;
  List<_CanvasEndpointBinding> _dragBindings = [];
  final signatures = <String, Uint8List>{};

  static const double _canvasSnapRadius = 16;
  static const double _canvasHitRadius = 22;
  static const double _canvasMinSegment = 8;
  static const double _canvasGrid = 20;
  BeneficiaryRecord? selectedBeneficiary;

  UserProfile get profile => widget.state.profile!;

  @override
  void initState() {
    super.initState();
    parish = profile.canViewAllParishes ? 'Hanover' : profile.parish;
    tabs = TabController(length: 4, vsync: this);
    tabs.addListener(() {
      if (mounted && !tabs.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    tabs.dispose();
    for (final c in [
      house,
      beneficiary,
      cluster,
      gps,
      width,
      length,
      wallHeight,
      pitch,
      repairNotes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double _d(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;
  RoofMeasurements get measurements => RoofMeasurements(
    widthFt: _d(width),
    lengthFt: _d(length),
    wallHeightFt: _d(wallHeight),
    pitchRisePer12: _d(pitch),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: RcPageHeading(
            eyebrow: 'Assessment & Scope',
            title: 'Scope of Work',
            subtitle:
                'Protected Shelter beneficiary data, internal technical Scope drafting, and a separate beneficiary repair agreement with representative roof architecture.',
            trailing: IconButton.filledTonal(
              tooltip: 'IA Shelter beneficiary autofill',
              onPressed: _chooseBeneficiary,
              icon: const Icon(Icons.auto_awesome_outlined),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
          child: _ScopeProgress(index: tabs.index, onSelect: tabs.animateTo),
        ),
        TabBar(
          controller: tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: 'House Info'),
            Tab(text: 'Roof Canvas'),
            Tab(text: 'Beneficiary Agreement'),
            Tab(text: 'Files & Export'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: tabs,
            children: [_houseInfo(), _roofCanvas(), _printout(), _files()],
          ),
        ),
      ],
    );
  }

  Widget _houseInfo() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      children: [
        RcExpressiveSurface(
          shape: RcSurfaceShape.offset,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Beneficiary & assessment',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _chooseBeneficiary,
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: const Text('IA Autofill'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: house,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'House / Beneficiary Code',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: beneficiary,
                decoration: const InputDecoration(
                  labelText: 'Beneficiary name',
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: RcApp.parishes.contains(parish) ? parish : null,
                decoration: const InputDecoration(labelText: 'Parish'),
                items:
                    (profile.canViewAllParishes
                            ? RcApp.parishes
                            : [profile.parish])
                        .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                        .toList(),
                onChanged: (v) => setState(() => parish = v!),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: cluster,
                decoration: const InputDecoration(
                  labelText: 'Community / Cluster',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: gps,
                decoration: const InputDecoration(
                  labelText: 'GPS / GIS reference',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        RcExpressiveSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'SOW technical inputs',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: structureType,
                decoration: const InputDecoration(
                  labelText: 'Type of structure',
                ),
                items: const ['Wood', 'RCC', 'Block']
                    .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                    .toList(),
                onChanged: (v) => setState(() => structureType = v!),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: roofType,
                decoration: const InputDecoration(labelText: 'Roof type'),
                items:
                    const [
                          'Pitched',
                          'Gable',
                          'Hip',
                          'Shed',
                          'Intersecting',
                          'Custom',
                        ]
                        .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                        .toList(),
                onChanged: (v) => setState(() => roofType = v!),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: gableType,
                decoration: const InputDecoration(labelText: 'Type of gable'),
                items: const ['Wood', 'Concrete', 'Not applicable']
                    .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                    .toList(),
                onChanged: (v) => setState(() => gableType = v!),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: rafterSize,
                decoration: const InputDecoration(
                  labelText: 'Existing rafter size',
                ),
                items: const ['2x6', '2x4', '3x6', 'Other']
                    .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                    .toList(),
                onChanged: (v) => setState(() => rafterSize = v!),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Existing ceiling T1-11'),
                value: t111Ceiling,
                onChanged: (v) => setState(() => t111Ceiling = v),
              ),
              TextField(
                controller: repairNotes,
                minLines: 4,
                maxLines: 9,
                decoration: const InputDecoration(
                  labelText: 'Repairs To Be Done / Technical Notes',
                  helperText:
                      'Enter technical repair notes and Scope details as required.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: () => _persistScope('Draft'),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Draft'),
            ),
            FilledButton.icon(
              onPressed: () => _persistScope('Pending Regional Approval'),
              icon: const Icon(Icons.send_outlined),
              label: const Text('Submit for Approval'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _roofCanvas() {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      children: [
        RcExpressiveSurface(
          shape: RcSurfaceShape.hero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Blank Roof Drawing Canvas',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'No preset geometry. Draw the actual house/roof, then add dimensions and drainage direction.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<RoofDrawTool>(
                  segments: RoofDrawTool.values
                      .map(
                        (tool) => ButtonSegment(
                          value: tool,
                          icon: Icon(tool.icon),
                          label: Text(tool.label),
                        ),
                      )
                      .toList(),
                  selected: {drawTool},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() {
                    drawTool = s.first;
                    current = [];
                    selectedStrokeIndex = null;
                    _clearSelectionDrag();
                  }),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Undo',
                    onPressed: strokes.isEmpty ? null : _undo,
                    icon: const Icon(Icons.undo),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filledTonal(
                    tooltip: 'Redo',
                    onPressed: redo.isEmpty ? null : _redo,
                    icon: const Icon(Icons.redo),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filledTonal(
                    tooltip: 'Clear canvas',
                    onPressed: strokes.isEmpty ? null : _clearCanvas,
                    icon: const Icon(Icons.delete_sweep_outlined),
                  ),
                  const Spacer(),
                  RcStatusPill(
                    label: roofType.toUpperCase(),
                    icon: Icons.roofing_outlined,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FilledButton.tonalIcon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TechnicalRoofDraftScreen(
                      initialMeasurements: measurements,
                      initialRoofType: roofType,
                    ),
                  ),
                ),
                icon: const Icon(Icons.architecture_outlined),
                label: const Text('Open Stable Technical Roof Draft'),
              ),
              const SizedBox(height: 10),
              AspectRatio(
                aspectRatio: 1.25,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: drawTool == RoofDrawTool.freehand
                        ? null
                        : drawTool == RoofDrawTool.select
                        ? (details) => _selectAt(details.localPosition)
                        : (details) =>
                              _placeTechnicalPoint(details.localPosition),
                    onPanStart: drawTool == RoofDrawTool.freehand
                        ? (details) =>
                              setState(() => current = [details.localPosition])
                        : drawTool == RoofDrawTool.select
                        ? (details) => _beginSelectDrag(details.localPosition)
                        : null,
                    onPanUpdate: drawTool == RoofDrawTool.freehand
                        ? (details) =>
                              setState(() => current.add(details.localPosition))
                        : drawTool == RoofDrawTool.select
                        ? (details) => _updateSelectDrag(details.localPosition)
                        : null,
                    onPanEnd: drawTool == RoofDrawTool.freehand
                        ? (_) => _finishStroke()
                        : drawTool == RoofDrawTool.select
                        ? (_) => _endSelectDrag()
                        : null,
                    child: CustomPaint(
                      painter: RoofCanvasPainter(
                        strokes: strokes,
                        current: current,
                        currentTool: drawTool,
                        selectedStrokeIndex: selectedStrokeIndex,
                        showGrid: widget.state.showGrid,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Connected drafting mode: endpoints snap to the grid and to existing vertices. Wall drawing continues from the last corner automatically. Use Select to drag a corner or a whole segment; every attached wall/ridge/hip/valley endpoint sharing that vertex moves with it, so joints stay closed.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _geometryInputs(),
        if (strokes.isNotEmpty) ...[
          const SizedBox(height: 14),
          RcExpressiveSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wall stretches & measured elements',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                ...strokes.asMap().entries.map(
                  (entry) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(entry.value.tool.icon),
                    title: Text('${entry.value.tool.label} ${entry.key + 1}'),
                    subtitle: Text(
                      entry.value.measurement.isEmpty
                          ? 'No measurement label'
                          : entry.value.measurement,
                    ),
                    trailing: IconButton(
                      onPressed: () => setState(() {
                        strokes.removeAt(entry.key);
                        selectedStrokeIndex = null;
                        current = [];
                        _clearSelectionDrag();
                      }),
                      icon: const Icon(Icons.delete_outline),
                    ),
                    onTap: () => _editMeasurement(entry.value),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _geometryInputs() {
    return RcExpressiveSurface(
      shape: RcSurfaceShape.offset,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Geometry & measurement',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _number(width, 'Main width (ft)'),
              _number(length, 'Main length (ft)'),
              _number(wallHeight, 'Wall height (ft)'),
              _number(pitch, 'Pitch rise / 12'),
            ],
          ),
          const SizedBox(height: 10),
          if (_d(width) > 0 && _d(wallHeight) > 0)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                RcStatusPill(
                  label:
                      'RIDGE RISE ${measurements.ridgeRiseFt.toStringAsFixed(2)} FT',
                  color: RcColors.blue,
                ),
                RcStatusPill(
                  label:
                      'RIDGE HEIGHT ${measurements.ridgeHeightFt.toStringAsFixed(2)} FT',
                  color: RcColors.success,
                ),
                RcStatusPill(
                  label:
                      'RAFTER ${measurements.rafterLengthFt.toStringAsFixed(2)} FT',
                  color: RcColors.purple,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _number(TextEditingController controller, String label) => SizedBox(
    width: 180,
    child: TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
      onChanged: (_) => setState(() {}),
    ),
  );

  String get _agreementRoofStyle {
    final value = roofType.toLowerCase();
    if (value.contains('hip')) return 'Hip';
    if (value.contains('shed') || value.contains('pitch')) return 'Pitched';
    return 'Gable';
  }

  static const String _beneficiaryAgreementText =
      'I acknowledge the repair work described in this agreement and permit '
      'the Jamaica Red Cross and its authorized construction team to carry '
      'out the stated roof repairs. I understand that the roof illustration '
      'is a representative Red Cross construction concept for the selected '
      'roof style. It is not the editable field Scope drawing, a measurement '
      'record, or a substitute for final site decisions made by the '
      'authorized technical team.';

  Widget _printout() {
    final theme = Theme.of(context);
    final style = _agreementRoofStyle;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      children: [
        RcExpressiveSurface(
          shape: RcSurfaceShape.hero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: .52,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.handshake_outlined,
                      size: 34,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'BENEFICIARY REPAIR AGREEMENT',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'A beneficiary-facing agreement. This document is separate from the editable Scope drawing and internal measurement canvas.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _line('House Code', house.text),
              _line('Beneficiary', beneficiary.text),
              _line('Parish', parish),
              _line('Community', cluster.text),
              _line('Roof Concept', style),
              const SizedBox(height: 16),
              RcExpressiveSurface(
                shape: RcSurfaceShape.offset,
                tone: Color.alphaBlend(
                  RcColors.success.withValues(alpha: .10),
                  theme.colorScheme.surface,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        RcIconWell(
                          icon: Icons.home_repair_service_rounded,
                          color: RcColors.success,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Quick Repair Selection',
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Select beneficiary-facing repair items here. They will appear in the Beneficiary Repair Agreement and printed PDF.',
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: repairPreset,
                      decoration: const InputDecoration(
                        labelText: 'Repair item',
                      ),
                      items: repairPresets
                          .map(
                            (repair) => DropdownMenuItem(
                              value: repair,
                              child: Text(repair),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => repairPreset = value!),
                    ),
                    const SizedBox(height: 9),
                    FilledButton.tonalIcon(
                      onPressed: () {
                        final existing = repairNotes.text.trim();
                        final bullet = '• $repairPreset';
                        if (existing
                            .split('\n')
                            .map((line) => line.trim())
                            .contains(bullet)) {
                          _snack('That repair is already listed.');
                          return;
                        }
                        setState(
                          () => repairNotes.text = existing.isEmpty
                              ? bullet
                              : '$existing\n$bullet',
                        );
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add to Beneficiary Agreement'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Repairs To Be Done', style: theme.textTheme.titleLarge),
              const SizedBox(height: 7),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Text(
                  repairNotes.text.trim().isEmpty
                      ? 'Repair items will be inserted here before beneficiary agreement.'
                      : repairNotes.text.trim(),
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Icon(
                    Icons.architecture_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Red Cross Roof Construction Concept • $style',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                'Representative architectural illustration only — not the field Scope canvas and not site measurements.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              AspectRatio(
                aspectRatio: 1.55,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAFF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CustomPaint(
                    painter: BeneficiaryAgreementRoofPainter(roofStyle: style),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Beneficiary acknowledgement',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 7),
              Text(_beneficiaryAgreementText, style: theme.textTheme.bodyLarge),
              const Divider(height: 30),
              ...[
                'Beneficiary',
                'Carpenter',
                'Site Supervisor',
                'Regional Supervisor',
                'Construction Specialist',
              ].map((role) => _signatureRow(role)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _printBeneficiaryPdf,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Print / Share Beneficiary Agreement'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _signatureRow(String role) {
    final signed = signatures.containsKey(role);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        signed ? Icons.draw_rounded : Icons.pending_actions_outlined,
      ),
      title: Text('$role signature'),
      subtitle: Text(
        signed
            ? 'Signed in this session'
            : 'Sign now or request required signature',
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (action) async {
          if (action == 'sign') {
            final bytes = await RcSignaturePad.capture(
              context,
              title: '$role signature',
            );
            if (bytes != null && mounted) {
              setState(() => signatures[role] = bytes);
            }
          } else {
            if (house.text.trim().isEmpty) {
              _snack('Enter or choose a house first.');
              return;
            }
            await widget.state.repository.requestSignature(
              profile: profile,
              houseCode: house.text.trim().toUpperCase(),
              parish: parish,
              recordType: 'beneficiaryPrintout',
              recordId: 'beneficiary-${house.text.trim().toUpperCase()}',
              signerRole: role,
            );
            _snack('Signature action sent to $role.');
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'sign', child: Text('Sign now')),
          PopupMenuItem(value: 'request', child: Text('Request signature')),
        ],
      ),
    );
  }

  Widget _files() {
    final data = _scopeData('Draft');
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      children: [
        RcExpressiveSurface(
          shape: RcSurfaceShape.offset,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Scope files & export',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Export the current structured Scope to PDF or Excel, then share by Android share sheet/email. Approved source templates remain available to Admin in Templates.',
              ),
              const SizedBox(height: 14),
              FilledButton.tonalIcon(
                onPressed: () => RcExportService.shareRecordPdf(
                  title: 'RC_SOW_Scope_${house.text}',
                  data: data,
                ),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Share Scope PDF'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => RcExportService.shareRecordXlsx(
                  title: 'RC_SOW_Scope_${house.text}',
                  data: data,
                ),
                icon: const Icon(Icons.table_view_outlined),
                label: const Text('Share Scope Excel'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _persistScope('Draft'),
                icon: const Icon(Icons.cloud_done_outlined),
                label: const Text('Save Scope to house record'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _chooseBeneficiary() async {
    final search = TextEditingController(text: house.text);
    List<BeneficiaryRecord> results = const [];
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
                Text(
                  'IA • Shelter Roof Assessment',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: search,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'House code or beneficiary',
                    suffixIcon: IconButton(
                      onPressed: () async {
                        results = await widget.state.repository
                            .searchBeneficiaries(
                              profile,
                              query: search.text.trim(),
                              limit: 100,
                            );
                        if (context.mounted) setSheetState(() {});
                      },
                      icon: const Icon(Icons.search),
                    ),
                  ),
                  onSubmitted: (_) async {
                    results = await widget.state.repository.searchBeneficiaries(
                      profile,
                      query: search.text.trim(),
                      limit: 100,
                    );
                    if (context.mounted) setSheetState(() {});
                  },
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: results.isEmpty
                      ? const Center(
                          child: Text('Search protected assessment data.'),
                        )
                      : ListView.builder(
                          itemCount: results.length,
                          itemBuilder: (_, i) {
                            final b = results[i];
                            return ListTile(
                              title: Text(
                                '${b.houseCode} • ${b.beneficiaryName}',
                              ),
                              subtitle: Text('${b.parish} • ${b.cluster}'),
                              onTap: () => Navigator.pop(sheetContext, b),
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
    if (!mounted || selected == null) return;
    setState(() {
      selectedBeneficiary = selected;
      house.text = selected.houseCode;
      beneficiary.text = selected.beneficiaryName;
      parish = selected.parish;
      cluster.text = selected.cluster;
      gps.text = selected.gps;
      if (selected.roofWidth != null) width.text = '${selected.roofWidth}';
      if (selected.roofLength != null) length.text = '${selected.roofLength}';
      if (selected.wallHeight != null) {
        wallHeight.text = '${selected.wallHeight}';
      }
      if (selected.roofType != null && selected.roofType!.isNotEmpty) {
        roofType = selected.roofType!;
      }
    });
  }

  Future<void> _placeTechnicalPoint(Offset point) async {
    if (drawTool == RoofDrawTool.select || drawTool == RoofDrawTool.freehand) {
      return;
    }

    final snapped = _snapPoint(point);

    if (current.isEmpty) {
      setState(() {
        current = [snapped];
        selectedStrokeIndex = null;
        redo.clear();
      });
      return;
    }

    final start = current.first;
    final end = _snapPoint(point);

    if ((end - start).distance < _canvasMinSegment) {
      return;
    }

    final stroke = RoofStroke(tool: drawTool, points: [start, end]);

    setState(() {
      strokes.add(stroke);
      selectedStrokeIndex = strokes.length - 1;
      redo.clear();
      current = drawTool == RoofDrawTool.wall ? [end] : [];
    });

    if (drawTool != RoofDrawTool.drain) {
      await _editMeasurement(stroke);
    }
  }

  bool _isTechnicalSegment(RoofStroke stroke) =>
      stroke.tool != RoofDrawTool.freehand &&
      stroke.tool != RoofDrawTool.select &&
      stroke.points.length >= 2;

  Offset _gridSnap(Offset point) {
    if (!widget.state.showGrid) return point;
    return Offset(
      (point.dx / _canvasGrid).round() * _canvasGrid,
      (point.dy / _canvasGrid).round() * _canvasGrid,
    );
  }

  Offset _snapPoint(
    Offset point, {
    Set<String> excludedEndpoints = const <String>{},
  }) {
    Offset? endpoint;
    var bestDistance = _canvasSnapRadius;

    for (var strokeIndex = 0; strokeIndex < strokes.length; strokeIndex++) {
      final stroke = strokes[strokeIndex];
      if (!_isTechnicalSegment(stroke)) continue;

      final endpointIndices = <int>{0, stroke.points.length - 1};
      for (final pointIndex in endpointIndices) {
        final key = '$strokeIndex:$pointIndex';
        if (excludedEndpoints.contains(key)) continue;

        final candidate = stroke.points[pointIndex];
        final distance = (candidate - point).distance;
        if (distance <= bestDistance) {
          endpoint = candidate;
          bestDistance = distance;
        }
      }
    }

    return endpoint ?? _gridSnap(point);
  }

  _CanvasEndpointHit? _nearestEndpoint(Offset position) {
    _CanvasEndpointHit? hit;
    var bestDistance = _canvasHitRadius;

    for (var strokeIndex = 0; strokeIndex < strokes.length; strokeIndex++) {
      final stroke = strokes[strokeIndex];
      if (!_isTechnicalSegment(stroke)) continue;

      final endpointIndices = <int>{0, stroke.points.length - 1};
      for (final pointIndex in endpointIndices) {
        final candidate = stroke.points[pointIndex];
        final distance = (candidate - position).distance;
        if (distance <= bestDistance) {
          bestDistance = distance;
          hit = _CanvasEndpointHit(
            strokeIndex: strokeIndex,
            pointIndex: pointIndex,
            point: candidate,
          );
        }
      }
    }

    return hit;
  }

  int? _nearestSegment(Offset position) {
    int? hit;
    var bestDistance = _canvasHitRadius;

    for (var i = 0; i < strokes.length; i++) {
      final stroke = strokes[i];
      if (!_isTechnicalSegment(stroke)) continue;

      final distance = _distanceToSegment(
        position,
        stroke.points.first,
        stroke.points.last,
      );

      if (distance <= bestDistance) {
        bestDistance = distance;
        hit = i;
      }
    }

    return hit;
  }

  double _distanceToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final ap = p - a;
    final lengthSquared = ab.dx * ab.dx + ab.dy * ab.dy;
    if (lengthSquared == 0) return ap.distance;

    final t = ((ap.dx * ab.dx + ap.dy * ab.dy) / lengthSquared).clamp(0.0, 1.0);
    final projection = Offset(a.dx + ab.dx * t, a.dy + ab.dy * t);
    return (p - projection).distance;
  }

  List<_CanvasEndpointBinding> _bindingsForVertex(
    Offset vertex, {
    required int group,
  }) {
    final bindings = <_CanvasEndpointBinding>[];

    for (var strokeIndex = 0; strokeIndex < strokes.length; strokeIndex++) {
      final stroke = strokes[strokeIndex];
      if (!_isTechnicalSegment(stroke)) continue;

      final endpointIndices = <int>{0, stroke.points.length - 1};
      for (final pointIndex in endpointIndices) {
        final candidate = stroke.points[pointIndex];
        if ((candidate - vertex).distance <= _canvasSnapRadius) {
          bindings.add(
            _CanvasEndpointBinding(
              strokeIndex: strokeIndex,
              pointIndex: pointIndex,
              original: candidate,
              group: group,
            ),
          );
        }
      }
    }

    return bindings;
  }

  void _selectAt(Offset position) {
    final endpoint = _nearestEndpoint(position);
    final segment = endpoint?.strokeIndex ?? _nearestSegment(position);

    setState(() {
      selectedStrokeIndex = segment;
      current = [];
      _clearSelectionDrag();
    });
  }

  void _beginSelectDrag(Offset position) {
    final endpoint = _nearestEndpoint(position);

    if (endpoint != null) {
      final bindings = _bindingsForVertex(endpoint.point, group: 0);

      setState(() {
        selectedStrokeIndex = endpoint.strokeIndex;
        current = [];
        redo.clear();
        _dragMode = _CanvasDragMode.vertex;
        _dragAnchor = position;
        _dragSegmentStart = endpoint.point;
        _dragSegmentEnd = null;
        _dragBindings = bindings;
      });
      return;
    }

    final segmentIndex = _nearestSegment(position);
    if (segmentIndex == null) {
      setState(() {
        selectedStrokeIndex = null;
        _clearSelectionDrag();
      });
      return;
    }

    final stroke = strokes[segmentIndex];
    final start = stroke.points.first;
    final end = stroke.points.last;

    final bindings = <_CanvasEndpointBinding>[
      ..._bindingsForVertex(start, group: 0),
      ..._bindingsForVertex(end, group: 1),
    ];

    setState(() {
      selectedStrokeIndex = segmentIndex;
      current = [];
      redo.clear();
      _dragMode = _CanvasDragMode.segment;
      _dragAnchor = position;
      _dragSegmentStart = start;
      _dragSegmentEnd = end;
      _dragBindings = bindings;
    });
  }

  void _updateSelectDrag(Offset position) {
    final mode = _dragMode;
    if (mode == null || _dragBindings.isEmpty) return;

    if (mode == _CanvasDragMode.vertex) {
      final excluded = _dragBindings.map((binding) => binding.key).toSet();
      final target = _snapPoint(position, excludedEndpoints: excluded);

      setState(() {
        for (final binding in _dragBindings) {
          if (binding.strokeIndex >= strokes.length) continue;
          final stroke = strokes[binding.strokeIndex];
          if (binding.pointIndex >= stroke.points.length) continue;
          stroke.points[binding.pointIndex] = target;
        }
      });
      return;
    }

    final anchor = _dragAnchor;
    final originalStart = _dragSegmentStart;
    final originalEnd = _dragSegmentEnd;
    if (anchor == null || originalStart == null || originalEnd == null) return;

    final rawDelta = position - anchor;
    final snappedStart = _gridSnap(originalStart + rawDelta);
    final delta = snappedStart - originalStart;
    final movedStart = originalStart + delta;
    final movedEnd = originalEnd + delta;

    setState(() {
      for (final binding in _dragBindings) {
        if (binding.strokeIndex >= strokes.length) continue;
        final stroke = strokes[binding.strokeIndex];
        if (binding.pointIndex >= stroke.points.length) continue;
        stroke.points[binding.pointIndex] = binding.group == 0
            ? movedStart
            : movedEnd;
      }
    });
  }

  void _endSelectDrag() {
    setState(_clearSelectionDrag);
  }

  void _clearSelectionDrag() {
    _dragMode = null;
    _dragAnchor = null;
    _dragSegmentStart = null;
    _dragSegmentEnd = null;
    _dragBindings = [];
  }

  Future<void> _finishStroke() async {
    if (current.length < 2) {
      setState(() => current = []);
      return;
    }
    final stroke = RoofStroke(tool: drawTool, points: List.of(current));
    setState(() {
      strokes.add(stroke);
      current = [];
      redo.clear();
    });
    if (drawTool != RoofDrawTool.freehand && drawTool != RoofDrawTool.drain) {
      await _editMeasurement(stroke);
    }
  }

  Future<void> _editMeasurement(RoofStroke stroke) async {
    final controller = TextEditingController(text: stroke.measurement);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${stroke.tool.label} measurement'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Length / label',
            hintText: 'e.g. 12 ft 6 in',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Skip'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null && mounted) setState(() => stroke.measurement = result);
  }

  void _undo() => setState(() {
    if (strokes.isNotEmpty) redo.add(strokes.removeLast());
    current = [];
    selectedStrokeIndex = null;
    _clearSelectionDrag();
  });
  void _redo() => setState(() {
    if (redo.isNotEmpty) strokes.add(redo.removeLast());
    current = [];
    selectedStrokeIndex = null;
    _clearSelectionDrag();
  });
  void _clearCanvas() => setState(() {
    redo.addAll(strokes.reversed);
    strokes.clear();
    current = [];
    selectedStrokeIndex = null;
    _clearSelectionDrag();
  });

  Map<String, dynamic> _scopeData(String status) => {
    'status': status,
    'houseCode': house.text.trim().toUpperCase(),
    'beneficiaryName': beneficiary.text.trim(),
    'parish': parish,
    'cluster': cluster.text.trim(),
    'gps': gps.text.trim(),
    'structureType': structureType,
    'repairsNeeded': repairNotes.text.trim(),
    'roofType': roofType,
    'gableType': gableType,
    'existingRafterSize': rafterSize,
    'existingCeilingT111': t111Ceiling,
    'widthFt': _d(width),
    'lengthFt': _d(length),
    'wallHeightFt': _d(wallHeight),
    'pitchRisePer12': _d(pitch),
    'ridgeRiseFt': measurements.ridgeRiseFt,
    'ridgeHeightFt': measurements.ridgeHeightFt,
    'rafterLengthFt': measurements.rafterLengthFt,
    'drawing': strokes.map((s) => s.toMap()).toList(),
    'drawingIsCustom': true,
    'beneficiarySource': selectedBeneficiary == null
        ? null
        : 'Shelter Roof Repair Assessment',
  };

  Future<void> _persistScope(String status) async {
    if (house.text.trim().isEmpty || parish.trim().isEmpty) {
      _snack('House Code and Parish are required.');
      return;
    }
    try {
      await widget.state.repository.submitControlEvent(
        profile: profile,
        eventType: 'scope',
        houseCode: house.text.trim().toUpperCase(),
        parish: parish,
        item: _scopeData(status),
      );
      _snack(
        status == 'Draft'
            ? 'Scope draft saved.'
            : 'Scope submitted for approval.',
      );
    } catch (_) {
      _snack(
        'Scope could not be saved. Check connectivity and access permissions.',
      );
    }
  }

  Future<void> _printBeneficiaryPdf() async {
    final style = _agreementRoofStyle;
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => [
          pw.Center(
            child: pw.Text(
              'JAMAICA RED CROSS',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 13,
                color: PdfColors.red900,
              ),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              'BENEFICIARY REPAIR AGREEMENT',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 19),
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Center(
            child: pw.Text(
              'Roof repair acknowledgement and representative construction concept',
              style: const pw.TextStyle(fontSize: 9.5),
            ),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: .7),
            cellPadding: const pw.EdgeInsets.all(6),
            data: [
              ['House Code', house.text.trim()],
              ['Beneficiary', beneficiary.text.trim()],
              ['Parish', parish],
              ['Community', cluster.text.trim()],
              ['Roof Concept', style],
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            'REPAIRS TO BE DONE',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
          ),
          pw.SizedBox(height: 5),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              color: PdfColors.grey100,
            ),
            child: pw.Text(
              repairNotes.text.trim().isEmpty
                  ? 'Repair items to be confirmed before signing.'
                  : repairNotes.text.trim(),
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            'RED CROSS ROOF CONSTRUCTION CONCEPT • ${style.toUpperCase()}',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Representative architectural illustration only. This is not the editable Scope drawing and does not display field measurements.',
            style: const pw.TextStyle(fontSize: 8.5),
          ),
          pw.SizedBox(height: 8),
          _pdfAgreementRoof(style),
          pw.SizedBox(height: 14),
          pw.Text(
            'BENEFICIARY ACKNOWLEDGEMENT',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            _beneficiaryAgreementText,
            style: const pw.TextStyle(fontSize: 9.5),
          ),
          pw.SizedBox(height: 16),
          for (final role in [
            'Beneficiary',
            'Carpenter',
            'Site Supervisor',
            'Regional Supervisor',
            'Construction Specialist',
          ]) ...[
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        role,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      if (signatures[role] != null)
                        pw.Image(pw.MemoryImage(signatures[role]!), height: 38)
                      else
                        pw.SizedBox(height: 32),
                      pw.Container(height: .8, color: PdfColors.grey600),
                    ],
                  ),
                ),
                pw.SizedBox(width: 22),
                pw.SizedBox(
                  width: 125,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(height: 32),
                      pw.Container(height: .8, color: PdfColors.grey600),
                      pw.SizedBox(height: 2),
                      pw.Text('Date', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 12),
          ],
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'RC_SOW_Beneficiary_Agreement_${house.text.trim()}.pdf',
    );
  }

  pw.Widget _pdfAgreementRoof(String style) => pw.Container(
    height: 190,
    child: pw.SvgImage(svg: _beneficiaryRoofSvg(style)),
  );

  String _beneficiaryRoofSvg(String style) {
    final normalized = style.toLowerCase();

    if (normalized == 'hip') {
      return '''<svg xmlns="http://www.w3.org/2000/svg" width="680" height="245" viewBox="0 0 680 245">
<rect width="680" height="245" fill="#F7FAFF"/>
<text x="30" y="27" font-size="15" font-weight="700" fill="#175CD3">HIP ROOF - REPRESENTATIVE ARCHITECTURAL CONCEPT</text>
<polygon points="110,165 260,68 505,102 575,180 310,205" fill="none" stroke="#101828" stroke-width="3"/>
<line x1="260" y1="68" x2="430" y2="92" stroke="#C91F2C" stroke-width="5"/>
<line x1="260" y1="68" x2="110" y2="165" stroke="#6941C6" stroke-width="3"/>
<line x1="260" y1="68" x2="310" y2="205" stroke="#6941C6" stroke-width="3"/>
<line x1="430" y1="92" x2="505" y2="102" stroke="#6941C6" stroke-width="3"/>
<line x1="430" y1="92" x2="575" y2="180" stroke="#6941C6" stroke-width="3"/>
<line x1="110" y1="165" x2="310" y2="205" stroke="#12805C" stroke-width="4"/>
<line x1="505" y1="102" x2="575" y2="180" stroke="#12805C" stroke-width="4"/>
<line x1="310" y1="205" x2="575" y2="180" stroke="#12805C" stroke-width="4"/>
<line x1="190" y1="122" x2="340" y2="185" stroke="#667085" stroke-width="1.5"/>
<line x1="235" y1="93" x2="400" y2="175" stroke="#667085" stroke-width="1.5"/>
<line x1="310" y1="76" x2="455" y2="159" stroke="#667085" stroke-width="1.5"/>
<line x1="375" y1="85" x2="510" y2="145" stroke="#667085" stroke-width="1.5"/>
<text x="322" y="62" font-size="11" font-weight="700" fill="#C91F2C">RIDGE</text>
<text x="115" y="186" font-size="10" font-weight="700" fill="#12805C">FASCIA / EAVE</text>
<text x="490" y="83" font-size="10" font-weight="700" fill="#6941C6">HIP RAFTERS</text>
<text x="250" y="230" font-size="10" fill="#344054">Beneficiary concept only - not field dimensions</text>
</svg>''';
    }

    if (normalized == 'pitched') {
      return '''<svg xmlns="http://www.w3.org/2000/svg" width="680" height="245" viewBox="0 0 680 245">
<rect width="680" height="245" fill="#F7FAFF"/>
<text x="30" y="27" font-size="15" font-weight="700" fill="#175CD3">PITCHED / MONO-PITCH ROOF - REPRESENTATIVE CONCEPT</text>
<rect x="145" y="112" width="370" height="82" fill="none" stroke="#101828" stroke-width="3"/>
<line x1="115" y1="120" x2="535" y2="55" stroke="#C91F2C" stroke-width="6"/>
<line x1="145" y1="124" x2="515" y2="66" stroke="#12805C" stroke-width="4"/>
<line x1="175" y1="119" x2="175" y2="194" stroke="#667085" stroke-width="1.4"/>
<line x1="235" y1="110" x2="235" y2="194" stroke="#667085" stroke-width="1.4"/>
<line x1="295" y1="100" x2="295" y2="194" stroke="#667085" stroke-width="1.4"/>
<line x1="355" y1="91" x2="355" y2="194" stroke="#667085" stroke-width="1.4"/>
<line x1="415" y1="82" x2="415" y2="194" stroke="#667085" stroke-width="1.4"/>
<line x1="475" y1="72" x2="475" y2="194" stroke="#667085" stroke-width="1.4"/>
<text x="450" y="50" font-size="11" font-weight="700" fill="#C91F2C">ROOF COVERING / HIGH EDGE</text>
<text x="150" y="139" font-size="10" font-weight="700" fill="#12805C">WALL PLATE / SUPPORT LINE</text>
<text x="112" y="112" font-size="10" font-weight="700" fill="#101828">FASCIA / LOW EAVE</text>
<text x="248" y="230" font-size="10" fill="#344054">Beneficiary concept only - not field dimensions</text>
</svg>''';
    }

    return '''<svg xmlns="http://www.w3.org/2000/svg" width="680" height="245" viewBox="0 0 680 245">
<rect width="680" height="245" fill="#F7FAFF"/>
<text x="30" y="27" font-size="15" font-weight="700" fill="#175CD3">GABLE ROOF - REPRESENTATIVE ARCHITECTURAL CONCEPT</text>
<rect x="145" y="120" width="390" height="76" fill="none" stroke="#101828" stroke-width="3"/>
<path d="M115 126 L340 52 L565 126" fill="none" stroke="#C91F2C" stroke-width="6"/>
<line x1="132" y1="126" x2="548" y2="126" stroke="#12805C" stroke-width="4"/>
<line x1="340" y1="52" x2="340" y2="126" stroke="#667085" stroke-width="2"/>
<line x1="165" y1="120" x2="340" y2="57" stroke="#667085" stroke-width="1.5"/>
<line x1="215" y1="120" x2="340" y2="57" stroke="#667085" stroke-width="1.5"/>
<line x1="265" y1="120" x2="340" y2="57" stroke="#667085" stroke-width="1.5"/>
<line x1="415" y1="120" x2="340" y2="57" stroke="#667085" stroke-width="1.5"/>
<line x1="465" y1="120" x2="340" y2="57" stroke="#667085" stroke-width="1.5"/>
<line x1="515" y1="120" x2="340" y2="57" stroke="#667085" stroke-width="1.5"/>
<text x="310" y="44" font-size="11" font-weight="700" fill="#C91F2C">RIDGE</text>
<text x="150" y="144" font-size="10" font-weight="700" fill="#12805C">WALL PLATE</text>
<text x="458" y="91" font-size="10" font-weight="700" fill="#667085">RAFTERS</text>
<text x="115" y="116" font-size="10" font-weight="700" fill="#101828">FASCIA / EAVE</text>
<text x="250" y="230" font-size="10" fill="#344054">Beneficiary concept only - not field dimensions</text>
</svg>''';
  }

  Widget _line(String key, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(
          width: 135,
          child: Text(key, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
        Expanded(child: Text(value.isEmpty ? '—' : value)),
      ],
    ),
  );
  void _snack(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

class _ScopeProgress extends StatelessWidget {
  const _ScopeProgress({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;
  @override
  Widget build(BuildContext context) {
    const labels = ['House', 'Canvas', 'Print', 'Files'];
    final theme = Theme.of(context);
    return Semantics(
      label: 'Scope step ${index + 1} of ${labels.length}: ${labels[index]}',
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            Expanded(
              child: Semantics(
                button: true,
                selected: i == index,
                label: 'Open ${labels[i]} tab',
                child: InkWell(
                  borderRadius: BorderRadius.circular(i == index ? 18 : 12),
                  onTap: () => onSelect(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    height: 38,
                    decoration: BoxDecoration(
                      color: i <= index
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(i == index ? 18 : 12),
                      border: Border.all(
                        color: i == index
                            ? theme.colorScheme.primary.withValues(alpha: .30)
                            : theme.colorScheme.outlineVariant.withValues(
                                alpha: .42,
                              ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (i == index) ...[
                          Icon(
                            Icons.touch_app_rounded,
                            size: 13,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            labels[i],
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: i <= index
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (i != labels.length - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class RoofCanvasPainter extends CustomPainter {
  RoofCanvasPainter({
    required this.strokes,
    required this.current,
    required this.currentTool,
    required this.selectedStrokeIndex,
    required this.showGrid,
  });
  final List<RoofStroke> strokes;
  final List<Offset> current;
  final RoofDrawTool currentTool;
  final int? selectedStrokeIndex;
  final bool showGrid;

  @override
  void paint(Canvas canvas, Size size) {
    if (showGrid) {
      final grid = Paint()
        ..color = RcColors.line.withValues(alpha: .7)
        ..strokeWidth = .6;
      for (double x = 0; x < size.width; x += 20) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
      }
      for (double y = 0; y < size.height; y += 20) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
      }
    }
    for (var i = 0; i < strokes.length; i++) {
      _drawStroke(canvas, strokes[i], size, selected: i == selectedStrokeIndex);
    }

    if (current.length == 1) {
      canvas.drawCircle(
        current.first,
        5,
        Paint()
          ..color = RcColors.blue
          ..style = PaintingStyle.fill,
      );
    }

    if (current.length >= 2) {
      _drawStroke(
        canvas,
        RoofStroke(tool: currentTool, points: current),
        size,
        preview: true,
      );
    }
  }

  void _drawStroke(
    Canvas canvas,
    RoofStroke stroke,
    Size size, {
    bool preview = false,
    bool selected = false,
  }) {
    final color = switch (stroke.tool) {
      RoofDrawTool.wall => RcColors.ink,
      RoofDrawTool.ridge => RcColors.brand,
      RoofDrawTool.hip => RcColors.purple,
      RoofDrawTool.valley => RcColors.blue,
      RoofDrawTool.drain => const Color(0xFF078D91),
      RoofDrawTool.freehand => RcColors.text,
      RoofDrawTool.select => RcColors.muted,
    };
    final paint = Paint()
      ..color = preview ? color.withValues(alpha: .55) : color
      ..strokeWidth = selected
          ? (stroke.tool == RoofDrawTool.wall ? 4.8 : 4)
          : (stroke.tool == RoofDrawTool.wall ? 3 : 2.3)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    if (stroke.points.length < 2) return;
    if (stroke.tool == RoofDrawTool.freehand) {
      final path = Path()
        ..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (final p in stroke.points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    } else {
      final start = stroke.points.first;
      final end = stroke.points.last;

      if (selected && !preview) {
        canvas.drawLine(
          start,
          end,
          Paint()
            ..color = RcColors.blue.withValues(alpha: .16)
            ..strokeWidth = paint.strokeWidth + 8
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke,
        );
      }

      canvas.drawLine(start, end, paint);

      if (!preview) {
        final startConnected = _connectionCount(start) > 1;
        final endConnected = _connectionCount(end) > 1;
        _drawNode(canvas, start, color, selected, startConnected);
        _drawNode(canvas, end, color, selected, endConnected);
      }

      if (stroke.tool == RoofDrawTool.drain) _arrow(canvas, start, end, paint);
      if (stroke.measurement.isNotEmpty) {
        final tp = TextPainter(
          text: TextSpan(
            text: stroke.measurement,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              backgroundColor: Colors.white.withValues(alpha: .82),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
          canvas,
          Offset(
            (start.dx + end.dx) / 2 - tp.width / 2,
            (start.dy + end.dy) / 2 - tp.height - 4,
          ),
        );
      }
    }
  }

  int _connectionCount(Offset point) {
    var count = 0;
    for (final stroke in strokes) {
      if (stroke.tool == RoofDrawTool.freehand || stroke.points.length < 2) {
        continue;
      }
      if ((stroke.points.first - point).distance <= 1.5) count++;
      if ((stroke.points.last - point).distance <= 1.5) count++;
    }
    return count;
  }

  void _drawNode(
    Canvas canvas,
    Offset point,
    Color baseColor,
    bool selected,
    bool connected,
  ) {
    final nodeColor = connected ? RcColors.success : baseColor;

    canvas.drawCircle(
      point,
      selected
          ? 5.5
          : connected
          ? 4.2
          : 3.2,
      Paint()
        ..color = nodeColor
        ..style = PaintingStyle.fill,
    );

    canvas.drawCircle(
      point,
      selected
          ? 9
          : connected
          ? 7
          : 5.5,
      Paint()
        ..color = nodeColor.withValues(alpha: .14)
        ..style = PaintingStyle.fill,
    );
  }

  void _arrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    const length = 12.0;
    canvas.drawLine(
      end,
      Offset(
        end.dx - length * math.cos(angle - .5),
        end.dy - length * math.sin(angle - .5),
      ),
      paint,
    );
    canvas.drawLine(
      end,
      Offset(
        end.dx - length * math.cos(angle + .5),
        end.dy - length * math.sin(angle + .5),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant RoofCanvasPainter oldDelegate) => true;
}

class BeneficiaryAgreementRoofPainter extends CustomPainter {
  const BeneficiaryAgreementRoofPainter({required this.roofStyle});

  final String roofStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..color = RcColors.ink
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final primary = Paint()
      ..color = RcColors.brand
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final support = Paint()
      ..color = RcColors.success
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final framing = Paint()
      ..color = RcColors.muted
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final normalized = roofStyle.toLowerCase();

    if (normalized == 'hip') {
      final a = Offset(size.width * .14, size.height * .66);
      final b = Offset(size.width * .38, size.height * .27);
      final c = Offset(size.width * .66, size.height * .36);
      final d = Offset(size.width * .86, size.height * .72);
      final e = Offset(size.width * .44, size.height * .83);
      final shell = Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..lineTo(c.dx, c.dy)
        ..lineTo(d.dx, d.dy)
        ..lineTo(e.dx, e.dy)
        ..close();
      canvas.drawPath(shell, ink);
      canvas.drawLine(b, c, primary);
      canvas.drawLine(b, a, support);
      canvas.drawLine(b, e, support);
      canvas.drawLine(c, d, support);
      for (var i = 1; i <= 4; i++) {
        final t = i / 5;
        canvas.drawLine(Offset.lerp(a, b, t)!, Offset.lerp(e, c, t)!, framing);
      }
      _label(canvas, 'RIDGE', Offset(size.width * .48, size.height * .20));
      _label(
        canvas,
        'HIP RAFTERS',
        Offset(size.width * .68, size.height * .31),
      );
      _label(
        canvas,
        'FASCIA / EAVE',
        Offset(size.width * .14, size.height * .78),
      );
    } else if (normalized == 'pitched') {
      final left = size.width * .18;
      final right = size.width * .82;
      final wallTop = size.height * .54;
      final bottom = size.height * .82;
      canvas.drawRect(Rect.fromLTRB(left, wallTop, right, bottom), ink);
      canvas.drawLine(
        Offset(left - 18, wallTop + 4),
        Offset(right + 18, size.height * .24),
        primary,
      );
      canvas.drawLine(
        Offset(left, wallTop + 10),
        Offset(right, size.height * .28),
        support,
      );
      for (var i = 0; i < 6; i++) {
        final x = left + (right - left) * i / 5;
        final y = wallTop + 10 - (wallTop + 10 - size.height * .28) * i / 5;
        canvas.drawLine(Offset(x, y), Offset(x, bottom), framing);
      }
      _label(
        canvas,
        'HIGH EDGE / ROOF COVERING',
        Offset(size.width * .53, size.height * .16),
      );
      _label(
        canvas,
        'LOW EAVE / FASCIA',
        Offset(size.width * .13, size.height * .47),
      );
    } else {
      final left = size.width * .16;
      final right = size.width * .84;
      final wallTop = size.height * .58;
      final bottom = size.height * .83;
      final ridge = Offset(size.width * .5, size.height * .22);
      canvas.drawRect(Rect.fromLTRB(left, wallTop, right, bottom), ink);
      canvas.drawLine(Offset(left - 14, wallTop), ridge, primary);
      canvas.drawLine(ridge, Offset(right + 14, wallTop), primary);
      canvas.drawLine(
        Offset(left, wallTop + 8),
        Offset(right, wallTop + 8),
        support,
      );
      for (double x = left + 18; x < right - 10; x += 30) {
        canvas.drawLine(
          Offset(x, wallTop + 8),
          Offset(size.width * .5 + (x - size.width * .5) * .45, ridge.dy + 10),
          framing,
        );
      }
      _label(canvas, 'RIDGE', Offset(size.width * .44, size.height * .13));
      _label(canvas, 'RAFTERS', Offset(size.width * .69, size.height * .37));
      _label(canvas, 'WALL PLATE', Offset(size.width * .18, size.height * .62));
    }

    _label(
      canvas,
      '$roofStyle • RED CROSS ROOF CONCEPT',
      Offset(size.width * .28, size.height * .91),
      color: RcColors.blue,
      fontSize: 10.5,
    );
  }

  void _label(
    Canvas canvas,
    String text,
    Offset position, {
    Color color = RcColors.ink,
    double fontSize = 9.5,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 230);
    tp.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant BeneficiaryAgreementRoofPainter oldDelegate) =>
      oldDelegate.roofStyle != roofStyle;
}
