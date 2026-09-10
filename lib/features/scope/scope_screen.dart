import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/app_constants.dart';
import '../../core/beneficiary_agreement.dart';
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
  RoofStroke({
    required this.tool,
    required this.points,
    this.measurement = '',
    this.templateGenerated = false,
  });

  final RoofDrawTool tool;
  final List<Offset> points;
  String measurement;
  final bool templateGenerated;

  Map<String, dynamic> toMap() => {
    'tool': tool.name,
    'measurement': measurement,
    'templateGenerated': templateGenerated,
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

class _ScopeHousePhoto {
  const _ScopeHousePhoto({required this.path, required this.bytes});

  final String path;
  final Uint8List bytes;
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
  final GlobalKey _roofCanvasKey = GlobalKey();
  List<Offset> current = [];
  int? _freehandPointerId;
  int? selectedStrokeIndex;
  _CanvasDragMode? _dragMode;
  Offset? _dragAnchor;
  Offset? _dragSegmentStart;
  Offset? _dragSegmentEnd;
  List<_CanvasEndpointBinding> _dragBindings = [];
  final signatures = <String, Uint8List>{};
  final ImagePicker _housePhotoPicker = ImagePicker();
  final List<_ScopeHousePhoto> housePhotos = [];
  int? houseCoverPhotoIndex;

  static const double _canvasSnapRadius = 16;
  static const double _canvasHitRadius = 22;
  static const double _canvasMinSegment = 8;
  static const double _canvasGrid = 20;
  BeneficiaryRecord? selectedBeneficiary;
  String agreementTitle = kDefaultBeneficiaryAgreementTitle;
  String agreementTemplate = kDefaultBeneficiaryAgreementText;
  String agreementVersion = 'Default';
  String agreementSourceFile = 'Built-in default';
  bool includeTechnicalDraftInBeneficiaryPdf = false;

  UserProfile get profile => widget.state.profile!;

  @override
  void initState() {
    super.initState();
    parish = profile.canViewAllParishes ? 'Hanover' : profile.parish;
    tabs = TabController(length: 4, vsync: this);
    tabs.addListener(() {
      if (mounted && !tabs.indexIsChanging) setState(() {});
    });
    _loadBeneficiaryAgreement();
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
        _housePhotosCard(),
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

  Widget _housePhotosCard() {
    final theme = Theme.of(context);
    return RcExpressiveSurface(
      shape: RcSurfaceShape.offset,
      tone: Color.alphaBlend(
        theme.colorScheme.secondary.withValues(alpha: .07),
        theme.colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              RcIconWell(
                icon: Icons.add_a_photo_outlined,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('House Photos', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text(
                      'Capture house condition photos for this Scope. Choose one photo as the active house display image.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => _pickHousePhoto(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Take Photo'),
              ),
              OutlinedButton.icon(
                onPressed: () => _pickHousePhoto(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Add From Device'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (housePhotos.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: const Row(
                children: [
                  Icon(Icons.image_not_supported_outlined),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No house photos yet. The first photo captured automatically becomes the display photo.',
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 148,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: housePhotos.length,
                separatorBuilder: (_, _) => const SizedBox(width: 9),
                itemBuilder: (context, index) {
                  final photo = housePhotos[index];
                  final isCover = houseCoverPhotoIndex == index;
                  return SizedBox(
                    width: 132,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _setHouseCoverPhoto(index),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: isCover
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isCover
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant,
                            width: isCover ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Image.memory(
                                      photo.bytes,
                                      fit: BoxFit.cover,
                                      gaplessPlayback: true,
                                    ),
                                  ),
                                  if (isCover)
                                    Positioned(
                                      top: 6,
                                      left: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          'DISPLAY',
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: theme.colorScheme.onPrimary,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ),
                                  Positioned(
                                    top: 3,
                                    right: 3,
                                    child: IconButton.filledTonal(
                                      tooltip: 'Remove photo',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => _removeHousePhoto(index),
                                      icon: const Icon(Icons.close_rounded, size: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isCover ? 'Active house cover' : 'Tap to set display',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickHousePhoto(ImageSource source) async {
    final code = house.text.trim().toUpperCase();
    if (code.isEmpty) {
      _snack('Enter or select a House Code before taking house photos.');
      return;
    }

    try {
      final picked = await _housePhotoPicker.pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 2200,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) {
        _snack('The selected image was empty.');
        return;
      }

      final rawExtension = picked.name.contains('.')
          ? picked.name.split('.').last.toLowerCase()
          : 'jpg';
      final extension = const {'jpg', 'jpeg', 'png', 'webp'}.contains(rawExtension)
          ? rawExtension
          : 'jpg';

      final path = await widget.state.repository.uploadEvidence(
        parish: parish,
        houseCode: code,
        recordType: 'scopeHouse',
        fieldKey: 'house-photo',
        bytes: bytes,
        extension: extension,
      );

      final becomesCover = houseCoverPhotoIndex == null;
      setState(() {
        housePhotos.add(_ScopeHousePhoto(path: path, bytes: bytes));
        if (becomesCover) {
          houseCoverPhotoIndex = housePhotos.length - 1;
        }
      });

      final active = await _syncHouseCoverPhoto();
      if (!mounted) return;
      _snack(
        becomesCover
            ? active
                ? 'House photo saved and set as the active house display photo.'
                : 'House photo saved to Scope and selected as its display photo.'
            : 'House photo saved. Tap it to make it the display photo.',
      );
    } catch (error) {
      if (!mounted) return;
      _snack('House photo could not be saved: $error');
    }
  }

  Future<void> _setHouseCoverPhoto(int index) async {
    if (index < 0 || index >= housePhotos.length) return;
    setState(() => houseCoverPhotoIndex = index);
    final active = await _syncHouseCoverPhoto();
    if (!mounted) return;
    _snack(
      active
          ? 'Active house display photo updated.'
          : 'Display photo selected for this Scope.',
    );
  }

  Future<void> _removeHousePhoto(int index) async {
    if (index < 0 || index >= housePhotos.length) return;

    setState(() {
      housePhotos.removeAt(index);
      final currentCover = houseCoverPhotoIndex;
      if (housePhotos.isEmpty) {
        houseCoverPhotoIndex = null;
      } else if (currentCover == null || currentCover == index) {
        houseCoverPhotoIndex = 0;
      } else if (currentCover > index) {
        houseCoverPhotoIndex = currentCover - 1;
      }
    });

    await _syncHouseCoverPhoto();
  }

  String? get _houseCoverPhotoPath {
    final index = houseCoverPhotoIndex;
    if (index == null || index < 0 || index >= housePhotos.length) return null;
    return housePhotos[index].path;
  }

  Future<bool> _syncHouseCoverPhoto() async {
    final code = house.text.trim().toUpperCase();
    if (code.isEmpty) return false;

    try {
      return await widget.state.repository.setHouseDisplayPhoto(
        profile: profile,
        houseCode: code,
        parish: parish,
        displayPhotoPath: _houseCoverPhotoPath,
        photoPaths: housePhotos.map((photo) => photo.path).toList(),
      );
    } catch (_) {
      return false;
    }
  }

  Widget _roofCanvas() {
    final theme = Theme.of(context);
    return ListView(
      physics: drawTool == RoofDrawTool.freehand
          ? const NeverScrollableScrollPhysics()
          : null,
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
                    _freehandPointerId = null;
                    current = [];
                    selectedStrokeIndex = null;
                    _clearSelectionDrag();
                  }),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.roofing_rounded,
                    size: 19,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Roof layout • tap to auto-place',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: const [
                  'Gable',
                  'Hip',
                  'Shed',
                  'Intersecting',
                  'Pitched',
                  'Custom',
                ].map((type) {
                  final selected =
                      roofType.toLowerCase() == type.toLowerCase();
                  return ChoiceChip(
                    selected: selected,
                    avatar: Icon(
                      _roofPresetIcon(type),
                      size: 18,
                    ),
                    label: Text(type),
                    onSelected: (_) => _applyRoofPreset(type),
                  );
                }).toList(),
              ),
              const SizedBox(height: 6),
              Text(
                roofType == 'Custom'
                    ? 'Custom mode keeps your existing geometry. Use the drawing tools and Select to build or adjust it.'
                    : 'The selected roof type places a starting roof outline, ridge/hip/valley lines and drainage fall arrows. Then use Select to drag any point or segment.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
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
              AspectRatio(
                aspectRatio: 1.25,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: drawTool == RoofDrawTool.freehand
                        ? _beginFreehandPointer
                        : null,
                    onPointerMove: drawTool == RoofDrawTool.freehand
                        ? _updateFreehandPointer
                        : null,
                    onPointerUp: drawTool == RoofDrawTool.freehand
                        ? _endFreehandPointer
                        : null,
                    onPointerCancel: drawTool == RoofDrawTool.freehand
                        ? _cancelFreehandPointer
                        : null,
                    child: GestureDetector(
                      key: _roofCanvasKey,
                      behavior: HitTestBehavior.opaque,
                      onTapUp: drawTool == RoofDrawTool.freehand
                          ? null
                          : drawTool == RoofDrawTool.select
                          ? (details) => _selectAt(details.localPosition)
                          : (details) =>
                                _placeTechnicalPoint(details.localPosition),
                      onPanStart: drawTool == RoofDrawTool.select
                          ? (details) =>
                                _beginSelectDrag(details.localPosition)
                          : null,
                      onPanUpdate: drawTool == RoofDrawTool.select
                          ? (details) =>
                                _updateSelectDrag(details.localPosition)
                          : null,
                      onPanEnd: drawTool == RoofDrawTool.select
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
              ),
              const SizedBox(height: 8),
              Text(
                'Connected drafting mode: tap a roof layout such as Gable to auto-place a starting ridge and drainage fall. Auto geometry stays editable. Use Select to drag a corner or whole segment; attached ridge/hip/valley/drain endpoints move with connected vertices so joints stay closed.',
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
    if (value.contains('shed') || value.contains('mono')) return 'Shed';
    if (value.contains('intersect')) return 'Intersecting';
    if (value.contains('custom')) return 'Custom';
    if (value.contains('gable')) return 'Gable';
    if (value.contains('pitch')) return 'Pitched';
    return 'Gable';
  }

  Future<void> _loadBeneficiaryAgreement() async {
    final config = await widget.state.repository.beneficiaryAgreementConfig();
    if (!mounted || config.isEmpty) return;

    setState(() {
      agreementTitle = '${config['title'] ?? kDefaultBeneficiaryAgreementTitle}'
          .trim();
      agreementTemplate =
          '${config['body'] ?? kDefaultBeneficiaryAgreementText}'.trim();
      agreementVersion = '${config['version'] ?? 'Default'}'.trim();
      agreementSourceFile = '${config['sourceFileName'] ?? 'Admin managed'}'
          .trim();
    });
  }

  String get _beneficiaryAgreementText => renderBeneficiaryAgreementTemplate(
    agreementTemplate.isEmpty
        ? kDefaultBeneficiaryAgreementText
        : agreementTemplate,
    houseCode: house.text.trim().toUpperCase(),
    beneficiary: beneficiary.text.trim(),
    parish: parish,
    community: cluster.text.trim(),
    roofType: _agreementRoofStyle,
    repairs: repairNotes.text.trim(),
  );

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
                      agreementTitle,
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
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        RcStatusPill(
                          label: 'AGREEMENT ${agreementVersion.toUpperCase()}',
                          color: RcColors.blue,
                        ),
                        RcStatusPill(
                          label: agreementSourceFile == 'Built-in default'
                              ? 'DEFAULT'
                              : 'ADMIN MANAGED',
                          color: RcColors.success,
                        ),
                      ],
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
              RcExpressiveSurface(
                shape: RcSurfaceShape.offset,
                tone: Color.alphaBlend(
                  theme.colorScheme.primary.withValues(alpha: .07),
                  theme.colorScheme.surface,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        RcIconWell(
                          icon: Icons.architecture_rounded,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Technical Architectural Draft',
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Plan, elevation and calculated framing geometry for the beneficiary record.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Add technical draft to Beneficiary printout',
                      ),
                      subtitle: const Text(
                        'Optional. When off, the technical drawing stays available in this Beneficiary tab but is not added to the PDF.',
                      ),
                      value: includeTechnicalDraftInBeneficiaryPdf,
                      onChanged: (value) => setState(
                        () => includeTechnicalDraftInBeneficiaryPdf = value,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                      label: const Text('Open Technical Architectural Draft'),
                    ),
                    const SizedBox(height: 12),
                    AspectRatio(
                      aspectRatio: 1.25,
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: CustomPaint(
                          painter: TechnicalRoofPainter(
                            roofType: style,
                            measurements: measurements,
                            foreground: theme.colorScheme.onSurface,
                            accent: theme.colorScheme.primary,
                            grid: theme.colorScheme.outlineVariant,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      includeTechnicalDraftInBeneficiaryPdf
                          ? 'Included in the next Beneficiary PDF.'
                          : 'Preview only — not currently included in the Beneficiary PDF.',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: includeTechnicalDraftInBeneficiaryPdf
                            ? RcColors.success
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Icon(
                    Icons.roofing_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Beneficiary Roof Concept • $style',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                'Simple beneficiary-facing roof concept. The optional Technical Architectural Draft above contains the plan, elevation and measured geometry.',
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

  IconData _roofPresetIcon(String type) {
    return switch (type.toLowerCase()) {
      'gable' => Icons.roofing_rounded,
      'hip' => Icons.change_history_rounded,
      'shed' => Icons.signal_cellular_alt_rounded,
      'intersecting' => Icons.call_split_rounded,
      'pitched' => Icons.keyboard_double_arrow_up_rounded,
      _ => Icons.polyline_rounded,
    };
  }

  Size? _renderedRoofCanvasSize() {
    final renderObject =
        _roofCanvasKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    return renderObject.size;
  }

  Rect _roofTemplateRect(Size size) {
    final manualWallPoints = <Offset>[];
    for (final stroke in strokes) {
      if (stroke.templateGenerated ||
          stroke.tool != RoofDrawTool.wall ||
          stroke.points.length < 2) {
        continue;
      }
      manualWallPoints.add(stroke.points.first);
      manualWallPoints.add(stroke.points.last);
    }

    if (manualWallPoints.length >= 2) {
      final minX = manualWallPoints
          .map((point) => point.dx)
          .reduce(math.min);
      final maxX = manualWallPoints
          .map((point) => point.dx)
          .reduce(math.max);
      final minY = manualWallPoints
          .map((point) => point.dy)
          .reduce(math.min);
      final maxY = manualWallPoints
          .map((point) => point.dy)
          .reduce(math.max);

      if (maxX - minX >= 80 && maxY - minY >= 60) {
        return Rect.fromLTRB(minX, minY, maxX, maxY);
      }
    }

    final horizontalInset = math.max(28.0, size.width * .12);
    final verticalInset = math.max(24.0, size.height * .15);

    return Rect.fromLTRB(
      horizontalInset,
      verticalInset,
      math.max(horizontalInset + 120, size.width - horizontalInset),
      math.max(verticalInset + 90, size.height - verticalInset),
    );
  }

  RoofStroke _autoRoofStroke(
    RoofDrawTool tool,
    Offset start,
    Offset end,
    String label,
  ) {
    return RoofStroke(
      tool: tool,
      points: [_gridSnap(start), _gridSnap(end)],
      measurement: label,
      templateGenerated: true,
    );
  }

  List<RoofStroke> _autoOutline(Rect rect) => [
    _autoRoofStroke(
      RoofDrawTool.wall,
      rect.topLeft,
      rect.topRight,
      'Auto roof edge',
    ),
    _autoRoofStroke(
      RoofDrawTool.wall,
      rect.topRight,
      rect.bottomRight,
      'Auto roof edge',
    ),
    _autoRoofStroke(
      RoofDrawTool.wall,
      rect.bottomRight,
      rect.bottomLeft,
      'Auto roof edge',
    ),
    _autoRoofStroke(
      RoofDrawTool.wall,
      rect.bottomLeft,
      rect.topLeft,
      'Auto roof edge',
    ),
  ];

  void _applyRoofPreset(String type) {
    final canvasSize = _renderedRoofCanvasSize();

    if (type == 'Custom') {
      setState(() {
        roofType = type;
        drawTool = RoofDrawTool.select;
        current = [];
        selectedStrokeIndex = null;
        _clearSelectionDrag();
      });
      return;
    }

    if (canvasSize == null ||
        canvasSize.width < 120 ||
        canvasSize.height < 90) {
      setState(() => roofType = type);
      _snack('Open the Roof Canvas fully, then tap $type again.');
      return;
    }

    final rect = _roofTemplateRect(canvasSize);
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    final w = rect.width;
    final h = rect.height;
    final generated = <RoofStroke>[];

    final hasManualWall = strokes.any(
      (stroke) =>
          !stroke.templateGenerated &&
          stroke.tool == RoofDrawTool.wall &&
          stroke.points.length >= 2,
    );

    if (!hasManualWall) {
      generated.addAll(_autoOutline(rect));
    }

    if (type == 'Gable' || type == 'Pitched') {
      final ridgeStart = Offset(rect.left + w * .18, cy);
      final ridgeEnd = Offset(rect.right - w * .18, cy);

      generated.add(
        _autoRoofStroke(
          RoofDrawTool.ridge,
          ridgeStart,
          ridgeEnd,
          type == 'Gable' ? 'Gable ridge' : 'Main ridge',
        ),
      );

      for (final x in [
        rect.left + w * .32,
        rect.left + w * .68,
      ]) {
        generated.add(
          _autoRoofStroke(
            RoofDrawTool.drain,
            Offset(x, cy),
            Offset(x, rect.top),
            'Drainage fall',
          ),
        );
        generated.add(
          _autoRoofStroke(
            RoofDrawTool.drain,
            Offset(x, cy),
            Offset(x, rect.bottom),
            'Drainage fall',
          ),
        );
      }
    } else if (type == 'Hip') {
      final ridgeStart = Offset(rect.left + w * .34, cy);
      final ridgeEnd = Offset(rect.right - w * .34, cy);

      generated.add(
        _autoRoofStroke(
          RoofDrawTool.ridge,
          ridgeStart,
          ridgeEnd,
          'Hip roof ridge',
        ),
      );
      generated.addAll([
        _autoRoofStroke(
          RoofDrawTool.hip,
          ridgeStart,
          rect.topLeft,
          'Hip',
        ),
        _autoRoofStroke(
          RoofDrawTool.hip,
          ridgeStart,
          rect.bottomLeft,
          'Hip',
        ),
        _autoRoofStroke(
          RoofDrawTool.hip,
          ridgeEnd,
          rect.topRight,
          'Hip',
        ),
        _autoRoofStroke(
          RoofDrawTool.hip,
          ridgeEnd,
          rect.bottomRight,
          'Hip',
        ),
      ]);

      generated.addAll([
        _autoRoofStroke(
          RoofDrawTool.drain,
          Offset(cx, cy),
          Offset(cx, rect.top),
          'Drainage fall',
        ),
        _autoRoofStroke(
          RoofDrawTool.drain,
          Offset(cx, cy),
          Offset(cx, rect.bottom),
          'Drainage fall',
        ),
        _autoRoofStroke(
          RoofDrawTool.drain,
          ridgeStart,
          Offset(rect.left, cy),
          'Drainage fall',
        ),
        _autoRoofStroke(
          RoofDrawTool.drain,
          ridgeEnd,
          Offset(rect.right, cy),
          'Drainage fall',
        ),
      ]);
    } else if (type == 'Shed') {
      final highLeft = Offset(rect.left, rect.top + h * .18);
      final highRight = Offset(rect.right, rect.top + h * .18);
      final lowY = rect.bottom - h * .10;

      generated.add(
        _autoRoofStroke(
          RoofDrawTool.ridge,
          highLeft,
          highRight,
          'High roof line',
        ),
      );

      for (final x in [
        rect.left + w * .22,
        rect.left + w * .50,
        rect.left + w * .78,
      ]) {
        generated.add(
          _autoRoofStroke(
            RoofDrawTool.drain,
            Offset(x, rect.top + h * .18),
            Offset(x, lowY),
            'Fall to low eave',
          ),
        );
      }
    } else if (type == 'Intersecting') {
      final mainStart = Offset(rect.left + w * .16, cy);
      final mainEnd = Offset(rect.right - w * .16, cy);
      final crossX = rect.left + w * .58;
      final crossTop = Offset(crossX, rect.top + h * .12);
      final crossBottom = Offset(crossX, rect.bottom - h * .12);
      final junction = Offset(crossX, cy);

      generated.addAll([
        _autoRoofStroke(
          RoofDrawTool.ridge,
          mainStart,
          mainEnd,
          'Main ridge',
        ),
        _autoRoofStroke(
          RoofDrawTool.ridge,
          crossTop,
          crossBottom,
          'Cross ridge',
        ),
        _autoRoofStroke(
          RoofDrawTool.valley,
          junction,
          Offset(rect.left + w * .42, rect.top),
          'Valley',
        ),
        _autoRoofStroke(
          RoofDrawTool.valley,
          junction,
          Offset(rect.left + w * .42, rect.bottom),
          'Valley',
        ),
        _autoRoofStroke(
          RoofDrawTool.drain,
          Offset(rect.left + w * .28, cy),
          Offset(rect.left + w * .28, rect.top),
          'Drainage fall',
        ),
        _autoRoofStroke(
          RoofDrawTool.drain,
          Offset(rect.left + w * .28, cy),
          Offset(rect.left + w * .28, rect.bottom),
          'Drainage fall',
        ),
        _autoRoofStroke(
          RoofDrawTool.drain,
          junction,
          Offset(rect.right, cy),
          'Drainage fall',
        ),
      ]);
    }

    setState(() {
      roofType = type;

      // Remove only the previous auto layout. Manual lines and freehand work
      // remain untouched.
      strokes.removeWhere((stroke) => stroke.templateGenerated);
      strokes.addAll(generated);

      drawTool = RoofDrawTool.select;
      current = [];
      redo.clear();

      final firstRidge = strokes.indexWhere(
        (stroke) =>
            stroke.templateGenerated &&
            stroke.tool == RoofDrawTool.ridge,
      );
      selectedStrokeIndex = firstRidge < 0 ? null : firstRidge;
      _clearSelectionDrag();
    });

    _snack(
      '$type roof layout placed. Ridge and drainage are selected/editable — use Select to drag points or segments.',
    );
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

  void _beginFreehandPointer(PointerDownEvent event) {
    if (drawTool != RoofDrawTool.freehand ||
        _freehandPointerId != null ||
        !mounted) {
      return;
    }

    setState(() {
      _freehandPointerId = event.pointer;
      current = [event.localPosition];
      selectedStrokeIndex = null;
      redo.clear();
      _clearSelectionDrag();
    });
  }

  void _updateFreehandPointer(PointerMoveEvent event) {
    if (drawTool != RoofDrawTool.freehand ||
        _freehandPointerId != event.pointer ||
        current.isEmpty ||
        !mounted) {
      return;
    }

    final point = event.localPosition;
    if ((point - current.last).distance < 1.25) return;
    setState(() => current.add(point));
  }

  void _endFreehandPointer(PointerUpEvent event) {
    if (_freehandPointerId != event.pointer || !mounted) return;
    _commitFreehandStroke();
  }

  void _cancelFreehandPointer(PointerCancelEvent event) {
    if (_freehandPointerId != event.pointer || !mounted) return;
    _commitFreehandStroke();
  }

  void _commitFreehandStroke() {
    final points = List<Offset>.of(current);

    setState(() {
      _freehandPointerId = null;
      current = [];

      if (points.length >= 2) {
        strokes.add(
          RoofStroke(
            tool: RoofDrawTool.freehand,
            points: points,
          ),
        );
        selectedStrokeIndex = strokes.length - 1;
        redo.clear();
      }
    });
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
    'housePhotoPaths': housePhotos.map((photo) => photo.path).toList(),
    'displayPhotoPath': _houseCoverPhotoPath,
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
      if (_houseCoverPhotoPath != null) {
        await _syncHouseCoverPhoto();
      }
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
              agreementTitle,
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
          pw.SizedBox(height: 5),
          pw.Center(
            child: pw.Text(
              'Agreement version: $agreementVersion • Source: $agreementSourceFile',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
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
          if (includeTechnicalDraftInBeneficiaryPdf) ...[
            pw.Text(
              'TECHNICAL ARCHITECTURAL ROOF DRAFT • ${style.toUpperCase()}',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 11,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Optional technical plan/elevation record generated from the current Scope measurements. Verify all field dimensions before construction.',
              style: const pw.TextStyle(fontSize: 8.5),
            ),
            pw.SizedBox(height: 7),
            _pdfAgreementRoof(style),
            pw.SizedBox(height: 7),
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(
                color: PdfColors.grey400,
                width: .6,
              ),
              cellPadding: const pw.EdgeInsets.all(5),
              data: [
                ['Width', '${measurements.widthFt.toStringAsFixed(2)} ft'],
                ['Length', '${measurements.lengthFt.toStringAsFixed(2)} ft'],
                [
                  'Wall height',
                  '${measurements.wallHeightFt.toStringAsFixed(2)} ft',
                ],
                [
                  'Rise wall plate → ridge',
                  '${measurements.ridgeRiseFt.toStringAsFixed(2)} ft',
                ],
                [
                  'Ridge height',
                  '${measurements.ridgeHeightFt.toStringAsFixed(2)} ft',
                ],
                [
                  'Common rafter',
                  '${measurements.rafterLengthFt.toStringAsFixed(2)} ft',
                ],
                [
                  'Pitch',
                  '${measurements.pitchRisePer12.toStringAsFixed(2)} / 12',
                ],
              ],
            ),
            pw.SizedBox(height: 12),
          ],
          pw.Text(
            'BENEFICIARY ROOF CONCEPT • ${style.toUpperCase()}',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Simple beneficiary-facing roof concept. The optional technical draft is printed separately with the current measured geometry.',
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

    if (normalized == 'shed') {
      return '''<svg xmlns="http://www.w3.org/2000/svg" width="680" height="245" viewBox="0 0 680 245">
<rect width="680" height="245" fill="#F7FAFF"/>
<text x="30" y="27" font-size="15" font-weight="700" fill="#175CD3">SHED / MONO-PITCH ROOF - REPRESENTATIVE CONCEPT</text>
<polygon points="110,168 290,196 570,118 390,92" fill="#EEF4FF" stroke="#101828" stroke-width="3"/>
<line x1="390" y1="92" x2="570" y2="118" stroke="#C91F2C" stroke-width="5"/>
<line x1="110" y1="168" x2="290" y2="196" stroke="#12805C" stroke-width="4"/>
<line x1="150" y1="174" x2="430" y2="98" stroke="#667085" stroke-width="2"/>
<line x1="195" y1="181" x2="475" y2="105" stroke="#667085" stroke-width="2"/>
<line x1="240" y1="188" x2="520" y2="111" stroke="#667085" stroke-width="2"/>
<text x="440" y="82" font-size="10" font-weight="700" fill="#C91F2C">HIGH EAVE</text>
<text x="120" y="215" font-size="10" font-weight="700" fill="#12805C">LOW EAVE / FASCIA</text>
<text x="300" y="144" font-size="10" font-weight="700" fill="#667085">RAFTERS / FALL</text>
</svg>''';
    }

    if (normalized == 'intersecting') {
      return '''<svg xmlns="http://www.w3.org/2000/svg" width="680" height="245" viewBox="0 0 680 245">
<rect width="680" height="245" fill="#F7FAFF"/>
<text x="30" y="27" font-size="15" font-weight="700" fill="#175CD3">INTERSECTING ROOF - REPRESENTATIVE CONCEPT</text>
<polygon points="90,170 290,202 590,140 390,110" fill="#EEF4FF" stroke="#101828" stroke-width="3"/>
<line x1="190" y1="118" x2="450" y2="70" stroke="#C91F2C" stroke-width="5"/>
<line x1="325" y1="150" x2="495" y2="118" stroke="#C91F2C" stroke-width="5"/>
<line x1="325" y1="150" x2="245" y2="132" stroke="#175CD3" stroke-width="4"/>
<line x1="325" y1="150" x2="395" y2="108" stroke="#175CD3" stroke-width="4"/>
<line x1="90" y1="170" x2="290" y2="202" stroke="#12805C" stroke-width="4"/>
<line x1="290" y1="202" x2="590" y2="140" stroke="#12805C" stroke-width="4"/>
<text x="260" y="80" font-size="10" font-weight="700" fill="#C91F2C">MAIN RIDGE</text>
<text x="455" y="107" font-size="10" font-weight="700" fill="#C91F2C">CROSS RIDGE</text>
<text x="290" y="170" font-size="10" font-weight="700" fill="#175CD3">VALLEYS</text>
</svg>''';
    }

    if (normalized == 'custom') {
      return '''<svg xmlns="http://www.w3.org/2000/svg" width="680" height="245" viewBox="0 0 680 245">
<rect width="680" height="245" fill="#F7FAFF"/>
<text x="30" y="27" font-size="15" font-weight="700" fill="#175CD3">CUSTOM / COMPLEX ROOF - REPRESENTATIVE CONCEPT</text>
<polygon points="105,170 250,198 335,176 455,194 575,145 485,116 398,132 285,104" fill="#EEF4FF" stroke="#101828" stroke-width="3"/>
<line x1="210" y1="124" x2="410" y2="86" stroke="#C91F2C" stroke-width="5"/>
<line x1="335" y1="176" x2="398" y2="132" stroke="#175CD3" stroke-width="4"/>
<text x="205" y="74" font-size="10" font-weight="700" fill="#C91F2C">REPRESENTATIVE RIDGE</text>
<text x="350" y="162" font-size="10" font-weight="700" fill="#175CD3">JUNCTION / VALLEY</text>
<text x="185" y="225" font-size="10" fill="#344054">Final geometry follows the approved technical Scope drawing.</text>
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
    final outline = Paint()
      ..color = RcColors.ink
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final ridgePaint = Paint()
      ..color = RcColors.brand
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final eavePaint = Paint()
      ..color = RcColors.success
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final framePaint = Paint()
      ..color = RcColors.muted
      ..strokeWidth = 1.25
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final valleyPaint = Paint()
      ..color = RcColors.blue
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final fill = Paint()
      ..color = RcColors.blue.withValues(alpha: .06)
      ..style = PaintingStyle.fill;

    final normalized = roofStyle.toLowerCase();
    if (normalized == 'hip') {
      _hip(canvas, size, outline, ridgePaint, eavePaint, framePaint, fill);
    } else if (normalized == 'shed') {
      _shed(canvas, size, outline, ridgePaint, eavePaint, framePaint, fill);
    } else if (normalized == 'intersecting') {
      _intersecting(
        canvas,
        size,
        outline,
        ridgePaint,
        eavePaint,
        framePaint,
        valleyPaint,
        fill,
      );
    } else if (normalized == 'custom') {
      _custom(canvas, size, outline, ridgePaint, valleyPaint, fill);
    } else {
      _gable(canvas, size, outline, ridgePaint, eavePaint, framePaint, fill);
    }

    _label(
      canvas,
      '$roofStyle • BENEFICIARY ROOF CONCEPT',
      Offset(size.width * .26, size.height * .91),
      color: RcColors.blue,
      fontSize: 10,
    );
  }

  void _gable(
    Canvas canvas,
    Size size,
    Paint outline,
    Paint ridge,
    Paint eave,
    Paint frame,
    Paint fill,
  ) {
    final fl = Offset(size.width * .14, size.height * .67);
    final fr = Offset(size.width * .42, size.height * .76);
    final bl = Offset(size.width * .57, size.height * .50);
    final br = Offset(size.width * .86, size.height * .58);
    final rf = Offset(size.width * .31, size.height * .40);
    final rb = Offset(size.width * .67, size.height * .25);

    final roof = Path()
      ..moveTo(fl.dx, fl.dy)
      ..lineTo(fr.dx, fr.dy)
      ..lineTo(br.dx, br.dy)
      ..lineTo(bl.dx, bl.dy)
      ..close();
    canvas.drawPath(roof, fill);
    canvas.drawPath(roof, outline);
    canvas.drawLine(fl, rf, outline);
    canvas.drawLine(fr, rf, outline);
    canvas.drawLine(bl, rb, outline);
    canvas.drawLine(br, rb, outline);
    canvas.drawLine(rf, rb, ridge);
    canvas.drawLine(fl, fr, eave);
    canvas.drawLine(bl, br, eave);

    for (final t in const [.25, .50, .75]) {
      final rp = Offset.lerp(rf, rb, t)!;
      canvas.drawLine(Offset.lerp(fl, bl, t)!, rp, frame);
      canvas.drawLine(Offset.lerp(fr, br, t)!, rp, frame);
    }

    _label(canvas, 'RIDGE LINE', Offset(size.width * .48, size.height * .20));
    _label(canvas, 'RAFTERS', Offset(size.width * .67, size.height * .42));
    _label(
      canvas,
      'FASCIA / EAVE',
      Offset(size.width * .14, size.height * .79),
    );
  }

  void _hip(
    Canvas canvas,
    Size size,
    Paint outline,
    Paint ridge,
    Paint eave,
    Paint frame,
    Paint fill,
  ) {
    final fl = Offset(size.width * .13, size.height * .67);
    final fr = Offset(size.width * .42, size.height * .77);
    final br = Offset(size.width * .86, size.height * .58);
    final bl = Offset(size.width * .57, size.height * .49);
    final r1 = Offset(size.width * .38, size.height * .39);
    final r2 = Offset(size.width * .65, size.height * .29);

    final roof = Path()
      ..moveTo(fl.dx, fl.dy)
      ..lineTo(fr.dx, fr.dy)
      ..lineTo(br.dx, br.dy)
      ..lineTo(bl.dx, bl.dy)
      ..close();
    canvas.drawPath(roof, fill);
    canvas.drawPath(roof, outline);
    canvas.drawLine(r1, r2, ridge);
    canvas.drawLine(r1, fl, outline);
    canvas.drawLine(r1, fr, outline);
    canvas.drawLine(r2, bl, outline);
    canvas.drawLine(r2, br, outline);
    canvas.drawLine(fl, fr, eave);
    canvas.drawLine(fr, br, eave);
    canvas.drawLine(br, bl, eave);
    canvas.drawLine(bl, fl, eave);

    for (final t in const [.32, .66]) {
      final rp = Offset.lerp(r1, r2, t)!;
      canvas.drawLine(Offset.lerp(fl, bl, t)!, rp, frame);
      canvas.drawLine(Offset.lerp(fr, br, t)!, rp, frame);
    }

    _label(canvas, 'RIDGE', Offset(size.width * .48, size.height * .23));
    _label(canvas, 'HIP RAFTERS', Offset(size.width * .69, size.height * .36));
    _label(
      canvas,
      'FASCIA / EAVES',
      Offset(size.width * .14, size.height * .80),
    );
  }

  void _shed(
    Canvas canvas,
    Size size,
    Paint outline,
    Paint ridge,
    Paint eave,
    Paint frame,
    Paint fill,
  ) {
    final low1 = Offset(size.width * .14, size.height * .67);
    final low2 = Offset(size.width * .42, size.height * .76);
    final high1 = Offset(size.width * .57, size.height * .37);
    final high2 = Offset(size.width * .86, size.height * .45);

    final roof = Path()
      ..moveTo(low1.dx, low1.dy)
      ..lineTo(low2.dx, low2.dy)
      ..lineTo(high2.dx, high2.dy)
      ..lineTo(high1.dx, high1.dy)
      ..close();
    canvas.drawPath(roof, fill);
    canvas.drawPath(roof, outline);
    canvas.drawLine(high1, high2, ridge);
    canvas.drawLine(low1, low2, eave);

    for (final t in const [.18, .38, .58, .78]) {
      canvas.drawLine(
        Offset.lerp(low1, low2, t)!,
        Offset.lerp(high1, high2, t)!,
        frame,
      );
    }

    _label(canvas, 'HIGH EAVE', Offset(size.width * .61, size.height * .29));
    _label(
      canvas,
      'RAFTERS / FALL',
      Offset(size.width * .46, size.height * .52),
    );
    _label(
      canvas,
      'LOW EAVE / FASCIA',
      Offset(size.width * .14, size.height * .80),
    );
  }

  void _intersecting(
    Canvas canvas,
    Size size,
    Paint outline,
    Paint ridge,
    Paint eave,
    Paint frame,
    Paint valley,
    Paint fill,
  ) {
    final a = Offset(size.width * .12, size.height * .67);
    final b = Offset(size.width * .40, size.height * .77);
    final c = Offset(size.width * .87, size.height * .58);
    final d = Offset(size.width * .58, size.height * .49);

    final roof = Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy)
      ..lineTo(c.dx, c.dy)
      ..lineTo(d.dx, d.dy)
      ..close();
    canvas.drawPath(roof, fill);
    canvas.drawPath(roof, outline);

    final main1 = Offset(size.width * .29, size.height * .39);
    final main2 = Offset(size.width * .67, size.height * .25);
    final cross1 = Offset(size.width * .47, size.height * .52);
    final cross2 = Offset(size.width * .75, size.height * .41);
    canvas.drawLine(main1, main2, ridge);
    canvas.drawLine(cross1, cross2, ridge);
    canvas.drawLine(
      cross1,
      Offset(size.width * .38, size.height * .46),
      valley,
    );
    canvas.drawLine(
      cross1,
      Offset(size.width * .57, size.height * .42),
      valley,
    );
    canvas.drawLine(a, b, eave);
    canvas.drawLine(b, c, eave);
    canvas.drawLine(c, d, eave);
    canvas.drawLine(d, a, eave);
    canvas.drawLine(a, main1, frame);
    canvas.drawLine(b, main1, frame);
    canvas.drawLine(c, cross2, frame);
    canvas.drawLine(d, main2, frame);

    _label(canvas, 'MAIN RIDGE', Offset(size.width * .42, size.height * .19));
    _label(canvas, 'CROSS RIDGE', Offset(size.width * .68, size.height * .34));
    _label(canvas, 'VALLEYS', Offset(size.width * .42, size.height * .55));
  }

  void _custom(
    Canvas canvas,
    Size size,
    Paint outline,
    Paint ridge,
    Paint valley,
    Paint fill,
  ) {
    final path = Path()
      ..moveTo(size.width * .14, size.height * .67)
      ..lineTo(size.width * .35, size.height * .77)
      ..lineTo(size.width * .48, size.height * .69)
      ..lineTo(size.width * .66, size.height * .76)
      ..lineTo(size.width * .86, size.height * .56)
      ..lineTo(size.width * .70, size.height * .47)
      ..lineTo(size.width * .57, size.height * .53)
      ..lineTo(size.width * .40, size.height * .42)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, outline);
    canvas.drawLine(
      Offset(size.width * .30, size.height * .48),
      Offset(size.width * .64, size.height * .31),
      ridge,
    );
    canvas.drawLine(
      Offset(size.width * .48, size.height * .69),
      Offset(size.width * .57, size.height * .53),
      valley,
    );
    _label(
      canvas,
      'CUSTOM / COMPLEX ROOF',
      Offset(size.width * .34, size.height * .21),
    );
    _label(
      canvas,
      'Final geometry follows approved Scope',
      Offset(size.width * .27, size.height * .82),
      color: RcColors.muted,
      fontSize: 9,
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
    )..layout(maxWidth: 240);
    tp.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant BeneficiaryAgreementRoofPainter oldDelegate) =>
      oldDelegate.roofStyle != roofStyle;
}
