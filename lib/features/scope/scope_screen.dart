import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/design_tokens.dart';
import '../../core/rc_policy.dart';
import '../../models/app_models.dart';
import '../../services/document_service.dart';
import '../../state/app_state.dart';

class ScopeScreen extends StatefulWidget {
  const ScopeScreen({super.key, required this.state});

  final AppState state;

  @override
  State<ScopeScreen> createState() => _ScopeScreenState();
}

class _ScopeScreenState extends State<ScopeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController tabs;
  late final RcDocumentService documents;
  final beneficiarySignatureKey = GlobalKey();
  final beneficiaryRoofKey = GlobalKey();

  String houseCode = '';
  String beneficiary = '';
  late String parish;
  String cluster = '';
  String gps = '';
  double width = 24;
  double length = 30;
  double wallHeight = 9;
  double pitch = 4;
  double overhang = 1;
  String roofType = 'Gable';
  bool saving = false;
  final signaturePoints = <Offset?>[];
  late List<RoofWallSegment> wallSegments;

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 4, vsync: this);
    documents = RcDocumentService(Supabase.instance.client);
    final assigned = widget.state.profile?.parish ?? 'Hanover';
    parish = RcPolicy.parishes.contains(assigned) ? assigned : 'Hanover';
    wallSegments = [
      RoofWallSegment(label: 'Front wall', lengthFt: width),
      RoofWallSegment(label: 'Right wall', lengthFt: length),
      RoofWallSegment(label: 'Rear wall', lengthFt: width),
      RoofWallSegment(label: 'Left wall', lengthFt: length),
    ];
  }

  RoofMeasurements get measurements => RoofMeasurements(
        widthFt: width,
        lengthFt: length,
        wallHeightFt: wallHeight,
        pitchRisePer12: pitch,
        overhangFt: overhang,
      );

  List<String> get allowedParishes {
    final profile = widget.state.profile!;
    if (profile.canViewAllParishes) {
      return RcPolicy.parishes;
    }
    return [profile.parish];
  }

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Scope of Work Data',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'IA Shelter Assessment',
                onPressed: _selectBeneficiary,
                icon: const Icon(Icons.auto_awesome_outlined),
              ),
            ],
          ),
        ),
        TabBar(
          controller: tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: 'House Info'),
            Tab(text: 'Roof Drawing'),
            Tab(text: 'Beneficiary Print Out'),
            Tab(text: 'Files'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: tabs,
            children: [
              _houseInfo(),
              _roofDrawing(),
              _printout(),
              _files(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _houseInfo() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextFormField(
                  key: ValueKey('house-$houseCode'),
                  initialValue: houseCode,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'House Code',
                    suffixIcon: IconButton(
                      tooltip: 'Find Shelter Assessment record',
                      onPressed: _selectBeneficiary,
                      icon: const Icon(Icons.auto_awesome_outlined),
                    ),
                  ),
                  onChanged: (value) => houseCode = value,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: ValueKey('beneficiary-$beneficiary'),
                  initialValue: beneficiary,
                  decoration: const InputDecoration(labelText: 'Beneficiary'),
                  onChanged: (value) => beneficiary = value,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: allowedParishes.contains(parish)
                      ? parish
                      : allowedParishes.first,
                  decoration: const InputDecoration(labelText: 'Parish'),
                  items: allowedParishes
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => parish = value!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: ValueKey('cluster-$cluster'),
                  initialValue: cluster,
                  decoration: const InputDecoration(labelText: 'Cluster / Community'),
                  onChanged: (value) => cluster = value,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: ValueKey('gps-$gps'),
                  initialValue: gps,
                  decoration: const InputDecoration(labelText: 'GPS Coordinates'),
                  onChanged: (value) => gps = value,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: saving ? null : () => _persistScope('Draft'),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Scope Draft'),
            ),
            FilledButton.icon(
              onPressed: saving ? null : () => _persistScope('Submitted'),
              icon: const Icon(Icons.send_outlined),
              label: const Text('Submit for Approval'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _selectBeneficiary() async {
    final selected = await showModalBottomSheet<BeneficiaryRecord>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _BeneficiaryLookup(
        state: widget.state,
      ),
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      houseCode = selected.houseCode;
      beneficiary = selected.name;
      if (allowedParishes.contains(selected.parish)) {
        parish = selected.parish;
      }
      cluster = selected.cluster;
      gps = selected.gps.isNotEmpty
          ? selected.gps
          : [selected.latitude, selected.longitude]
              .whereType<double>()
              .map((value) => value.toStringAsFixed(6))
              .join(', ');
    });
  }

  Future<void> _persistScope(String status) async {
    if (houseCode.trim().isEmpty || parish.trim().isEmpty) {
      _toast('House Code and Parish are required.');
      return;
    }
    setState(() => saving = true);
    try {
      await widget.state.repository.submitScope(
        profile: widget.state.profile!,
        id: 'scope-${houseCode.trim().toUpperCase()}',
        houseCode: houseCode.trim(),
        parish: parish.trim(),
        item: {
          'status': status,
          'houseCode': houseCode.trim(),
          'beneficiary': beneficiary.trim(),
          'parish': parish.trim(),
          'cluster': cluster.trim(),
          'gps': gps.trim(),
          'roofType': roofType,
          'widthFt': width,
          'lengthFt': length,
          'wallHeightFt': wallHeight,
          'pitchRisePer12': pitch,
          'overhangFt': overhang,
          'ridgeRiseFt': measurements.ridgeRiseFt,
          'ridgeHeightFt': measurements.ridgeHeightFt,
          'rafterLengthFt': measurements.rafterLengthFt,
          'roofAreaSqFt': measurements.roofAreaSqFt,
          'wallSegments': wallSegments
              .map(
                (segment) => {
                  'label': segment.label,
                  'lengthFt': segment.lengthFt,
                  'hasDrain': segment.hasDrain,
                },
              )
              .toList(),
          'beneficiarySignatureCaptured': signaturePoints.isNotEmpty,
          'source': 'RC SOW v18.3.1 Fusion',
        },
      );
      _toast(status == 'Draft'
          ? 'Scope draft saved to RC SOW.'
          : 'Scope submitted for approval.');
    } catch (e) {
      _toast('Scope could not be saved: $e');
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Widget _roofDrawing() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Technical Roof Drawing',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: roofType,
                  decoration: const InputDecoration(labelText: 'Roof type'),
                  items: const ['Gable', 'Hip', 'Shed', 'Intersecting']
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => roofType = value!),
                ),
                const SizedBox(height: 14),
                RoofDiagram(
                  type: roofType,
                  measurements: measurements,
                  showGrid: widget.state.showGrid,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _measureField('Building width', width, (value) {
                      width = value;
                      _syncWallDimensions();
                    }),
                    _measureField('Building length', length, (value) {
                      length = value;
                      _syncWallDimensions();
                    }),
                    _measureField('Wall height', wallHeight, (value) => wallHeight = value),
                    _measureField('Pitch rise / 12', pitch, (value) => pitch = value),
                    _measureField('Overhang', overhang, (value) => overhang = value),
                  ],
                ),
                const SizedBox(height: 16),
                _metricsCard(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Wall stretches & roof drains',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                ...List.generate(wallSegments.length, (index) {
                  final segment = wallSegments[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            key: ValueKey('${segment.label}-${segment.lengthFt}'),
                            initialValue: segment.lengthFt.toStringAsFixed(2),
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(labelText: '${segment.label} (ft)'),
                            onChanged: (value) {
                              final number = double.tryParse(value);
                              if (number != null && number > 0) {
                                wallSegments[index] = RoofWallSegment(
                                  label: segment.label,
                                  lengthFt: number,
                                  hasDrain: segment.hasDrain,
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          selected: segment.hasDrain,
                          label: const Text('Drain'),
                          avatar: const Icon(Icons.water_drop_outlined, size: 18),
                          onSelected: (selected) {
                            setState(() {
                              wallSegments[index] = RoofWallSegment(
                                label: segment.label,
                                lengthFt: segment.lengthFt,
                                hasDrain: selected,
                              );
                            });
                          },
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                AspectRatio(
                  aspectRatio: 1.8,
                  child: CustomPaint(
                    painter: RoofPlanPainter(
                      wallSegments: wallSegments,
                      roofType: roofType,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _syncWallDimensions() {
    wallSegments = [
      RoofWallSegment(
        label: 'Front wall',
        lengthFt: width,
        hasDrain: wallSegments[0].hasDrain,
      ),
      RoofWallSegment(
        label: 'Right wall',
        lengthFt: length,
        hasDrain: wallSegments[1].hasDrain,
      ),
      RoofWallSegment(
        label: 'Rear wall',
        lengthFt: width,
        hasDrain: wallSegments[2].hasDrain,
      ),
      RoofWallSegment(
        label: 'Left wall',
        lengthFt: length,
        hasDrain: wallSegments[3].hasDrain,
      ),
    ];
  }

  Widget _measureField(
    String label,
    double value,
    ValueChanged<double> changed,
  ) {
    return SizedBox(
      width: 180,
      child: TextFormField(
        key: ValueKey('$label-$value'),
        initialValue: value.toStringAsFixed(value % 1 == 0 ? 0 : 1),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: '$label (ft)'),
        onChanged: (raw) {
          final number = double.tryParse(raw);
          if (number != null && number > 0) {
            setState(() => changed(number));
          }
        },
      ),
    );
  }

  Widget _metricsCard() {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.secondaryContainer.withValues(alpha: .45),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _metric('Wall height', measurements.wallHeightFt),
            _metric(
              'Wall plate → ridge rise',
              measurements.ridgeRiseFt,
              emphasize: true,
            ),
            _metric('Ridge height from ground', measurements.ridgeHeightFt),
            _metric('Rafter length', measurements.rafterLengthFt),
            _metric('Roof area', measurements.roofAreaSqFt, unit: 'sq ft'),
          ],
        ),
      ),
    );
  }

  Widget _metric(
    String label,
    double value, {
    bool emphasize = false,
    String unit = 'ft',
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: emphasize ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
          Text(
            '${value.toStringAsFixed(2)} $unit',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: emphasize ? RcColors.brand : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _printout() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: Text(
                    'BENEFICIARY PRINT OUT',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 18),
                _printLine('House Code', houseCode),
                _printLine('Name', beneficiary.isEmpty ? '—' : beneficiary),
                _printLine('Parish', parish),
                _printLine('Cluster', cluster.isEmpty ? '—' : cluster),
                _printLine('GPS', gps.isEmpty ? '—' : gps),
                _printLine('Roof Type', roofType),
                _printLine(
                  'Wall Plate → Ridge Rise',
                  '${measurements.ridgeRiseFt.toStringAsFixed(2)} ft',
                ),
                const SizedBox(height: 16),
                Text(
                  'Standard roof layout to be received',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                RepaintBoundary(
                  key: beneficiaryRoofKey,
                  child: ColoredBox(
                    color: Theme.of(context).colorScheme.surface,
                    child: RoofDiagram(
                      type: roofType,
                      measurements: measurements,
                      showGrid: false,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Beneficiary digital signature',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                RepaintBoundary(
                  key: beneficiarySignatureKey,
                  child: SignaturePad(
                    points: signaturePoints,
                    onChanged: (points) {
                      setState(() {
                        signaturePoints
                          ..clear()
                          ..addAll(points);
                      });
                    },
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: signaturePoints.isEmpty
                        ? null
                        : () => setState(signaturePoints.clear),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Clear signature'),
                  ),
                ),
                const Divider(height: 28),
                for (final label in [
                  'Carpenter Signature',
                  'Site Supervisor',
                  'Regional Supervisor',
                  'Construction Specialist',
                ]) ...[
                  const SizedBox(height: 16),
                  Text(label),
                  const Divider(height: 20),
                ],
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _printPdf,
                      icon: const Icon(Icons.print_outlined),
                      label: const Text('Print / PDF'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _exportScope('xlsx-share'),
                      icon: const Icon(Icons.table_view_outlined),
                      label: const Text('Share Excel'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _printLine(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(key, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _files() {
    final template = RcTemplates.forEventType('scope')!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Scope Files', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text(
                  'Use the approved SOW workbook, export the current scope, or share a PDF without leaving RC SOW.',
                ),
                const SizedBox(height: 14),
                FilledButton.tonalIcon(
                  onPressed: () => _templateAction('save', template),
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Download SOW XLSX template'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _templateAction('share', template),
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share SOW template'),
                ),
                const Divider(height: 26),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _exportScope('xlsx-save'),
                      icon: const Icon(Icons.table_view_outlined),
                      label: const Text('Save current Excel'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _exportScope('xlsx-share'),
                      icon: const Icon(Icons.ios_share_outlined),
                      label: const Text('Share current Excel'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _exportScope('pdf-share'),
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Share current PDF'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _templateAction(
    String action,
    RcTemplateDefinition template,
  ) async {
    try {
      if (action == 'save') {
        await documents.saveTemplate(template);
      } else {
        await documents.shareTemplate(template);
      }
      _toast('SOW template ready.');
    } catch (e) {
      _toast('Template action failed: $e');
    }
  }

  Future<void> _exportScope(String action) async {
    if (houseCode.trim().isEmpty) {
      _toast('Enter or select a House Code first.');
      return;
    }
    try {
      if (action.startsWith('xlsx')) {
        final bytes = await documents.scopeXlsx(
          houseCode: houseCode.trim(),
          beneficiary: beneficiary.trim(),
          parish: parish,
          cluster: cluster.trim(),
          roofType: roofType,
          measurements: measurements,
        );
        final fileName = 'RC_SOW_${houseCode.trim().toUpperCase()}_Scope.xlsx';
        const mime =
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
        if (action.endsWith('share')) {
          await documents.shareBytes(
            bytes: bytes,
            fileName: fileName,
            mimeType: mime,
            subject: 'RC SOW Scope — ${houseCode.trim().toUpperCase()}',
          );
        } else {
          await documents.saveBytes(
            bytes: bytes,
            fileName: fileName,
            mimeType: mime,
          );
        }
      } else {
        final bytes = await _buildPdf();
        await documents.shareBytes(
          bytes: bytes,
          fileName: 'RC_SOW_${houseCode.trim().toUpperCase()}_Scope.pdf',
          mimeType: 'application/pdf',
          subject: 'RC SOW Scope — ${houseCode.trim().toUpperCase()}',
        );
      }
      _toast('Scope export prepared.');
    } catch (e) {
      _toast('Scope export failed: $e');
    }
  }

  Future<void> _printPdf() async {
    final bytes = await _buildPdf();
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<Uint8List> _buildPdf() async {
    final roofPng = await _capturePng(beneficiaryRoofKey);
    final signaturePng = signaturePoints.isEmpty
        ? null
        : await _capturePng(beneficiarySignatureKey);
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (_) => [
          pw.Center(
            child: pw.Text(
              'RC SOW — BENEFICIARY PRINT OUT',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text('House Code: $houseCode'),
          pw.Text('Beneficiary: ${beneficiary.isEmpty ? '—' : beneficiary}'),
          pw.Text('Parish: $parish'),
          pw.Text('Cluster: ${cluster.isEmpty ? '—' : cluster}'),
          pw.Text('GPS: ${gps.isEmpty ? '—' : gps}'),
          pw.SizedBox(height: 12),
          pw.Text('Roof type: $roofType'),
          pw.Text('Building width: ${measurements.widthFt.toStringAsFixed(2)} ft'),
          pw.Text('Building length: ${measurements.lengthFt.toStringAsFixed(2)} ft'),
          pw.Text('Wall height: ${measurements.wallHeightFt.toStringAsFixed(2)} ft'),
          pw.Text(
            'Wall plate to ridge rise: ${measurements.ridgeRiseFt.toStringAsFixed(2)} ft',
          ),
          pw.Text(
            'Ridge height from ground: ${measurements.ridgeHeightFt.toStringAsFixed(2)} ft',
          ),
          pw.Text('Rafter length: ${measurements.rafterLengthFt.toStringAsFixed(2)} ft'),
          pw.SizedBox(height: 16),
          pw.Text(
            'Standard roof layout to be received',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          if (roofPng != null) ...[
            pw.SizedBox(height: 8),
            pw.Image(pw.MemoryImage(roofPng), height: 150),
          ],
          pw.SizedBox(height: 20),
          pw.Text(
            'Beneficiary Signature',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          if (signaturePng != null)
            pw.Image(pw.MemoryImage(signaturePng), height: 70)
          else
            pw.SizedBox(height: 55),
          pw.Divider(),
          for (final label in [
            'Carpenter Signature',
            'Site Supervisor',
            'Regional Supervisor',
            'Construction Specialist',
          ]) ...[
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.Text(label),
          ],
        ],
      ),
    );
    return document.save();
  }

  Future<Uint8List?> _capturePng(GlobalKey key) async {
    final context = key.currentContext;
    if (context == null) {
      return null;
    }
    final object = context.findRenderObject();
    if (object is! RenderRepaintBoundary) {
      return null;
    }
    final image = await object.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  void _toast(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _BeneficiaryLookup extends StatefulWidget {
  const _BeneficiaryLookup({required this.state});

  final AppState state;

  @override
  State<_BeneficiaryLookup> createState() => _BeneficiaryLookupState();
}

class _BeneficiaryLookupState extends State<_BeneficiaryLookup> {
  final search = TextEditingController();
  late Future<List<BeneficiaryRecord>> future;

  @override
  void initState() {
    super.initState();
    future = widget.state.repository.beneficiaries(limit: 100);
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void _runSearch() {
    setState(
      () => future = widget.state.repository.beneficiaries(
        query: search.text,
        limit: 100,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          4,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .75,
          child: Column(
            children: [
              Text(
                'IA Shelter Assessment',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              SearchBar(
                controller: search,
                hintText: 'House code, beneficiary or community',
                leading: const Icon(Icons.search),
                trailing: [
                  IconButton(
                    onPressed: _runSearch,
                    icon: const Icon(Icons.arrow_forward),
                  ),
                ],
                onSubmitted: (_) => _runSearch(),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: FutureBuilder<List<BeneficiaryRecord>>(
                  future: future,
                  builder: (context, snapshot) {
                    final records = snapshot.data ?? const <BeneficiaryRecord>[];
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Could not search Shelter Assessment: ${snapshot.error}'),
                      );
                    }
                    if (records.isEmpty) {
                      return const Center(child: Text('No matching beneficiary records.'));
                    }
                    return ListView.builder(
                      itemCount: records.length,
                      itemBuilder: (context, index) {
                        final record = records[index];
                        return ListTile(
                          leading: const Icon(Icons.home_work_outlined),
                          title: Text(
                            '${record.houseCode} • ${record.name}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text('${record.parish} • ${record.cluster}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.pop(context, record),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignaturePad extends StatefulWidget {
  const SignaturePad({
    super.key,
    required this.points,
    required this.onChanged,
  });

  final List<Offset?> points;
  final ValueChanged<List<Offset?>> onChanged;

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  late List<Offset?> points;

  @override
  void initState() {
    super.initState();
    points = List<Offset?>.from(widget.points);
  }

  @override
  void didUpdateWidget(covariant SignaturePad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.points.isEmpty && points.isNotEmpty) {
      points = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (details) => _add(details.localPosition),
        onPanUpdate: (details) => _add(details.localPosition),
        onPanEnd: (_) => _endStroke(),
        child: CustomPaint(
          painter: SignaturePainter(points),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  void _add(Offset point) {
    setState(() => points.add(point));
    widget.onChanged(List<Offset?>.from(points));
  }

  void _endStroke() {
    setState(() => points.add(null));
    widget.onChanged(List<Offset?>.from(points));
  }
}

class SignaturePainter extends CustomPainter {
  SignaturePainter(this.points);

  final List<Offset?> points;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = RcColors.ink
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < points.length - 1; index++) {
      final current = points[index];
      final next = points[index + 1];
      if (current != null && next != null) {
        canvas.drawLine(current, next, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SignaturePainter oldDelegate) => true;
}

class RoofDiagram extends StatelessWidget {
  const RoofDiagram({
    super.key,
    required this.type,
    required this.measurements,
    required this.showGrid,
  });

  final String type;
  final RoofMeasurements measurements;
  final bool showGrid;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.55,
      child: CustomPaint(
        painter: RoofPainter(
          type: type,
          measurements: measurements,
          showGrid: showGrid,
          dark: Theme.of(context).brightness == Brightness.dark,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class RoofPainter extends CustomPainter {
  RoofPainter({
    required this.type,
    required this.measurements,
    required this.showGrid,
    required this.dark,
  });

  final String type;
  final RoofMeasurements measurements;
  final bool showGrid;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final ink = dark ? Colors.white : RcColors.ink;
    final grid = Paint()
      ..color = dark ? const Color(0xFF3F454D) : RcColors.line
      ..strokeWidth = .7;
    if (showGrid) {
      for (double x = 0; x < size.width; x += 20) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
      }
      for (double y = 0; y < size.height; y += 20) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
      }
    }
    final line = Paint()
      ..color = ink
      ..strokeWidth = 2.3
      ..style = PaintingStyle.stroke;
    final dimension = Paint()
      ..color = RcColors.blue
      ..strokeWidth = 1.2;
    final left = size.width * .18;
    final right = size.width * .82;
    final ground = size.height * .78;
    final wallTop = size.height * .55;
    final ridgeY = size.height * .25;
    final center = size.width / 2;
    canvas.drawRect(Rect.fromLTRB(left, wallTop, right, ground), line);
    if (type == 'Shed') {
      canvas.drawLine(Offset(left, wallTop), Offset(right, ridgeY), line);
    } else {
      canvas.drawLine(Offset(left, wallTop), Offset(center, ridgeY), line);
      canvas.drawLine(Offset(center, ridgeY), Offset(right, wallTop), line);
      if (type == 'Hip') {
        canvas.drawLine(
          Offset(left, wallTop),
          Offset(center - 18, ridgeY + 8),
          line,
        );
        canvas.drawLine(
          Offset(right, wallTop),
          Offset(center + 18, ridgeY + 8),
          line,
        );
      }
      if (type == 'Intersecting') {
        canvas.drawLine(
          Offset(center, ridgeY),
          Offset(center + size.width * .16, wallTop + 20),
          line,
        );
      }
    }
    canvas.drawLine(Offset(right + 16, wallTop), Offset(right + 16, ridgeY), dimension);
    canvas.drawLine(Offset(right + 10, wallTop), Offset(right + 22, wallTop), dimension);
    canvas.drawLine(Offset(right + 10, ridgeY), Offset(right + 22, ridgeY), dimension);
    final riseText = TextPainter(
      text: TextSpan(
        text: 'Rise ${measurements.ridgeRiseFt.toStringAsFixed(2)} ft',
        style: const TextStyle(
          color: RcColors.blue,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    riseText.paint(
      canvas,
      Offset(right + 26, (wallTop + ridgeY) / 2 - riseText.height / 2),
    );
    final widthText = TextPainter(
      text: TextSpan(
        text: '${measurements.widthFt.toStringAsFixed(1)} ft',
        style: TextStyle(
          color: ink,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    widthText.paint(canvas, Offset(center - widthText.width / 2, ground + 8));
  }

  @override
  bool shouldRepaint(covariant RoofPainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.measurements != measurements ||
        oldDelegate.showGrid != showGrid ||
        oldDelegate.dark != dark;
  }
}

class RoofPlanPainter extends CustomPainter {
  RoofPlanPainter({required this.wallSegments, required this.roofType});

  final List<RoofWallSegment> wallSegments;
  final String roofType;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      size.width * .15,
      size.height * .18,
      size.width * .7,
      size.height * .64,
    );
    final line = Paint()
      ..color = RcColors.ink
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawRect(rect, line);
    if (roofType == 'Gable' || roofType == 'Hip' || roofType == 'Intersecting') {
      canvas.drawLine(
        Offset(rect.center.dx, rect.top),
        Offset(rect.center.dx, rect.bottom),
        line,
      );
    }
    if (roofType == 'Hip') {
      canvas.drawLine(rect.topLeft, Offset(rect.center.dx, rect.center.dy), line);
      canvas.drawLine(rect.topRight, Offset(rect.center.dx, rect.center.dy), line);
      canvas.drawLine(rect.bottomLeft, Offset(rect.center.dx, rect.center.dy), line);
      canvas.drawLine(rect.bottomRight, Offset(rect.center.dx, rect.center.dy), line);
    }
    final drain = Paint()
      ..color = RcColors.blue
      ..strokeWidth = 5;
    if (wallSegments.length >= 4) {
      if (wallSegments[0].hasDrain) {
        canvas.drawLine(rect.topLeft, rect.topRight, drain);
      }
      if (wallSegments[1].hasDrain) {
        canvas.drawLine(rect.topRight, rect.bottomRight, drain);
      }
      if (wallSegments[2].hasDrain) {
        canvas.drawLine(rect.bottomLeft, rect.bottomRight, drain);
      }
      if (wallSegments[3].hasDrain) {
        canvas.drawLine(rect.topLeft, rect.bottomLeft, drain);
      }
    }
  }

  @override
  bool shouldRepaint(covariant RoofPlanPainter oldDelegate) => true;
}
