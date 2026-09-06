import 'dart:convert';
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

class ScopeScreen extends StatefulWidget {
  const ScopeScreen({super.key, required this.state});
  final AppState state;

  @override
  State<ScopeScreen> createState() => _ScopeScreenState();
}

class _ScopeScreenState extends State<ScopeScreen> with SingleTickerProviderStateMixin {
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
  final signatures = <String, Uint8List>{};
  BeneficiaryRecord? selectedBeneficiary;

  UserProfile get profile => widget.state.profile!;

  @override
  void initState() {
    super.initState();
    parish = profile.canViewAllParishes ? 'Hanover' : profile.parish;
    tabs = TabController(length: 4, vsync: this);
    tabs.addListener(() { if (mounted && !tabs.indexIsChanging) setState(() {}); });
  }

  @override
  void dispose() {
    tabs.dispose();
    for (final c in [house, beneficiary, cluster, gps, width, length, wallHeight, pitch, repairNotes]) { c.dispose(); }
    super.dispose();
  }

  double _d(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;
  RoofMeasurements get measurements => RoofMeasurements(widthFt: _d(width), lengthFt: _d(length), wallHeightFt: _d(wallHeight), pitchRisePer12: _d(pitch));

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: RcPageHeading(
          eyebrow: 'Assessment & Scope',
          title: 'Scope of Work',
          subtitle: 'Protected Shelter beneficiary autofill, a blank technical canvas, editable geometry, official beneficiary roof printout, signatures and export.',
          trailing: IconButton.filledTonal(tooltip: 'IA Shelter beneficiary autofill', onPressed: _chooseBeneficiary, icon: const Icon(Icons.auto_awesome_outlined)),
        ),
      ),
      Padding(padding: const EdgeInsets.fromLTRB(16, 2, 16, 8), child: _ScopeProgress(index: tabs.index)),
      TabBar(controller: tabs, isScrollable: true, tabs: const [Tab(text: 'House Info'), Tab(text: 'Roof Canvas'), Tab(text: 'Beneficiary Print'), Tab(text: 'Files & Export')]),
      Expanded(child: TabBarView(controller: tabs, children: [_houseInfo(), _roofCanvas(), _printout(), _files()])),
    ]);
  }

  Widget _houseInfo() {
    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 110), children: [
      RcExpressiveSurface(
        shape: RcSurfaceShape.offset,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [Expanded(child: Text('Beneficiary & assessment', style: Theme.of(context).textTheme.titleLarge)), FilledButton.tonalIcon(onPressed: _chooseBeneficiary, icon: const Icon(Icons.auto_awesome_outlined), label: const Text('IA Autofill'))]),
          const SizedBox(height: 12),
          TextField(controller: house, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'House / Beneficiary Code')),
          const SizedBox(height: 10),
          TextField(controller: beneficiary, decoration: const InputDecoration(labelText: 'Beneficiary name')),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(initialValue: RcApp.parishes.contains(parish) ? parish : null, decoration: const InputDecoration(labelText: 'Parish'), items: (profile.canViewAllParishes ? RcApp.parishes : [profile.parish]).map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (v) => setState(() => parish = v!)),
          const SizedBox(height: 10),
          TextField(controller: cluster, decoration: const InputDecoration(labelText: 'Community / Cluster')),
          const SizedBox(height: 10),
          TextField(controller: gps, decoration: const InputDecoration(labelText: 'GPS / GIS reference')),
        ]),
      ),
      const SizedBox(height: 14),
      RcExpressiveSurface(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('SOW technical inputs', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(initialValue: structureType, decoration: const InputDecoration(labelText: 'Type of structure'), items: const ['Wood', 'RCC', 'Block'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (v) => setState(() => structureType = v!)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(initialValue: roofType, decoration: const InputDecoration(labelText: 'Roof type'), items: const ['Pitched', 'Gable', 'Hip', 'Shed', 'Intersecting', 'Custom'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (v) => setState(() => roofType = v!)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(initialValue: gableType, decoration: const InputDecoration(labelText: 'Type of gable'), items: const ['Wood', 'Concrete', 'Not applicable'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (v) => setState(() => gableType = v!)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(initialValue: rafterSize, decoration: const InputDecoration(labelText: 'Existing rafter size'), items: const ['2x6', '2x4', '3x6', 'Other'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (v) => setState(() => rafterSize = v!)),
          SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, title: const Text('Existing ceiling T1-11'), value: t111Ceiling, onChanged: (v) => setState(() => t111Ceiling = v)),
          TextField(controller: repairNotes, minLines: 3, maxLines: 6, decoration: const InputDecoration(labelText: 'Repairs needed / technical notes')),
        ]),
      ),
      const SizedBox(height: 14),
      Wrap(spacing: 10, runSpacing: 10, children: [
        OutlinedButton.icon(onPressed: () => _persistScope('Draft'), icon: const Icon(Icons.save_outlined), label: const Text('Save Draft')),
        FilledButton.icon(onPressed: () => _persistScope('Pending Regional Approval'), icon: const Icon(Icons.send_outlined), label: const Text('Submit for Approval')),
      ]),
    ]);
  }

  Widget _roofCanvas() {
    final theme = Theme.of(context);
    return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 110), children: [
      RcExpressiveSurface(
        shape: RcSurfaceShape.hero,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Blank Roof Drawing Canvas', style: theme.textTheme.titleLarge), const SizedBox(height: 3), const Text('No preset geometry. Draw the actual house/roof, then add dimensions and drainage direction.')]))]),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<RoofDrawTool>(
              segments: RoofDrawTool.values.map((tool) => ButtonSegment(value: tool, icon: Icon(tool.icon), label: Text(tool.label))).toList(),
              selected: {drawTool},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => drawTool = s.first),
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            IconButton.filledTonal(tooltip: 'Undo', onPressed: strokes.isEmpty ? null : _undo, icon: const Icon(Icons.undo)),
            const SizedBox(width: 6),
            IconButton.filledTonal(tooltip: 'Redo', onPressed: redo.isEmpty ? null : _redo, icon: const Icon(Icons.redo)),
            const SizedBox(width: 6),
            IconButton.filledTonal(tooltip: 'Clear canvas', onPressed: strokes.isEmpty ? null : _clearCanvas, icon: const Icon(Icons.delete_sweep_outlined)),
            const Spacer(),
            RcStatusPill(label: roofType.toUpperCase(), icon: Icons.roofing_outlined, color: theme.colorScheme.primary),
          ]),
          const SizedBox(height: 10),
          AspectRatio(
            aspectRatio: 1.25,
            child: Container(
              decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: theme.colorScheme.outlineVariant)),
              clipBehavior: Clip.antiAlias,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (d) => setState(() => current = [d.localPosition]),
                onPanUpdate: (d) => setState(() {
                  if (drawTool == RoofDrawTool.freehand) {
                    current.add(d.localPosition);
                  } else if (current.isEmpty) {
                    current = [d.localPosition];
                  } else if (current.length == 1) {
                    current.add(d.localPosition);
                  } else {
                    current[current.length - 1] = d.localPosition;
                  }
                }),
                onPanEnd: (_) => _finishStroke(),
                child: CustomPaint(
                  painter: RoofCanvasPainter(strokes: strokes, current: current, currentTool: drawTool, showGrid: widget.state.showGrid),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('Tip: Wall/Ridge/Hip/Valley tools create straight technical segments. Drain draws an arrow. Freehand follows your finger. Tap a segment below to edit its measurement label.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ]),
      ),
      const SizedBox(height: 14),
      _geometryInputs(),
      if (strokes.isNotEmpty) ...[
        const SizedBox(height: 14),
        RcExpressiveSurface(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Wall stretches & measured elements', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            ...strokes.asMap().entries.map((entry) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(entry.value.tool.icon),
                  title: Text('${entry.value.tool.label} ${entry.key + 1}'),
                  subtitle: Text(entry.value.measurement.isEmpty ? 'No measurement label' : entry.value.measurement),
                  trailing: IconButton(onPressed: () => setState(() => strokes.removeAt(entry.key)), icon: const Icon(Icons.delete_outline)),
                  onTap: () => _editMeasurement(entry.value),
                )),
          ]),
        ),
      ],
    ]);
  }

  Widget _geometryInputs() {
    return RcExpressiveSurface(
      shape: RcSurfaceShape.offset,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Geometry & measurement', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Wrap(spacing: 10, runSpacing: 10, children: [
          _number(width, 'Main width (ft)'),
          _number(length, 'Main length (ft)'),
          _number(wallHeight, 'Wall height (ft)'),
          _number(pitch, 'Pitch rise / 12'),
        ]),
        const SizedBox(height: 10),
        if (_d(width) > 0 && _d(wallHeight) > 0)
          Wrap(spacing: 8, runSpacing: 8, children: [
            RcStatusPill(label: 'RIDGE RISE ${measurements.ridgeRiseFt.toStringAsFixed(2)} FT', color: RcColors.blue),
            RcStatusPill(label: 'RIDGE HEIGHT ${measurements.ridgeHeightFt.toStringAsFixed(2)} FT', color: RcColors.success),
            RcStatusPill(label: 'RAFTER ${measurements.rafterLengthFt.toStringAsFixed(2)} FT', color: RcColors.purple),
          ]),
      ]),
    );
  }

  Widget _number(TextEditingController controller, String label) => SizedBox(width: 180, child: TextField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: label), onChanged: (_) => setState(() {})));

  Widget _printout() {
    final theme = Theme.of(context);
    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 110), children: [
      RcExpressiveSurface(
        shape: RcSurfaceShape.hero,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Center(child: Text('BENEFICIARY ROOF AGREEMENT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
          const SizedBox(height: 8),
          Text('The diagram below is the official finished roof-style template the beneficiary is expected to receive. It is intentionally separate from the assessment drawing canvas.', textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
          const SizedBox(height: 14),
          const AspectRatio(aspectRatio: 1.65, child: CustomPaint(painter: StandardRoofPainter(), child: SizedBox.expand())),
          const SizedBox(height: 14),
          _line('House Code', house.text),
          _line('Beneficiary', beneficiary.text),
          _line('Parish', parish),
          _line('Community', cluster.text),
          _line('Finished Roof Style', roofType),
          const Divider(height: 28),
          ...['Beneficiary', 'Carpenter', 'Site Supervisor', 'Regional Supervisor', 'Construction Specialist'].map((role) => _signatureRow(role)),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: _printBeneficiaryPdf, icon: const Icon(Icons.picture_as_pdf_outlined), label: const Text('Print / Share Beneficiary PDF')),
        ]),
      ),
    ]);
  }

  Widget _signatureRow(String role) {
    final signed = signatures.containsKey(role);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(signed ? Icons.draw_rounded : Icons.pending_actions_outlined),
      title: Text('$role signature'),
      subtitle: Text(signed ? 'Signed in this session' : 'Sign now or request required signature'),
      trailing: PopupMenuButton<String>(
        onSelected: (action) async {
          if (action == 'sign') {
            final bytes = await RcSignaturePad.capture(context, title: '$role signature');
            if (bytes != null && mounted) setState(() => signatures[role] = bytes);
          } else {
            if (house.text.trim().isEmpty) { _snack('Enter or choose a house first.'); return; }
            await widget.state.repository.requestSignature(profile: profile, houseCode: house.text.trim().toUpperCase(), parish: parish, recordType: 'beneficiaryPrintout', recordId: 'beneficiary-${house.text.trim().toUpperCase()}', signerRole: role);
            _snack('Signature action sent to $role.');
          }
        },
        itemBuilder: (_) => const [PopupMenuItem(value: 'sign', child: Text('Sign now')), PopupMenuItem(value: 'request', child: Text('Request signature'))],
      ),
    );
  }

  Widget _files() {
    final data = _scopeData('Draft');
    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 110), children: [
      RcExpressiveSurface(
        shape: RcSurfaceShape.offset,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Scope files & export', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('Export the current structured Scope to PDF or Excel, then share by Android share sheet/email. Approved source templates remain available to Admin in Templates.'),
          const SizedBox(height: 14),
          FilledButton.tonalIcon(onPressed: () => RcExportService.shareRecordPdf(title: 'RC_SOW_Scope_${house.text}', data: data), icon: const Icon(Icons.picture_as_pdf_outlined), label: const Text('Share Scope PDF')),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: () => RcExportService.shareRecordXlsx(title: 'RC_SOW_Scope_${house.text}', data: data), icon: const Icon(Icons.table_view_outlined), label: const Text('Share Scope Excel')),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: () => _persistScope('Draft'), icon: const Icon(Icons.cloud_done_outlined), label: const Text('Save Scope to house record')),
        ]),
      ),
    ]);
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
            child: Column(children: [
              Text('IA • Shelter Roof Assessment', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              TextField(controller: search, autofocus: true, decoration: InputDecoration(labelText: 'House code or beneficiary', suffixIcon: IconButton(onPressed: () async { results = await widget.state.repository.searchBeneficiaries(profile, query: search.text.trim(), limit: 100); if (context.mounted) setSheetState(() {}); }, icon: const Icon(Icons.search))), onSubmitted: (_) async { results = await widget.state.repository.searchBeneficiaries(profile, query: search.text.trim(), limit: 100); if (context.mounted) setSheetState(() {}); }),
              const SizedBox(height: 8),
              Expanded(child: results.isEmpty ? const Center(child: Text('Search protected assessment data.')) : ListView.builder(itemCount: results.length, itemBuilder: (_, i) { final b = results[i]; return ListTile(title: Text('${b.houseCode} • ${b.beneficiaryName}'), subtitle: Text('${b.parish} • ${b.cluster}'), onTap: () => Navigator.pop(sheetContext, b)); })),
            ]),
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
      if (selected.wallHeight != null) wallHeight.text = '${selected.wallHeight}';
      if (selected.roofType != null && selected.roofType!.isNotEmpty) roofType = selected.roofType!;
    });
  }

  Future<void> _finishStroke() async {
    if (current.length < 2) { setState(() => current = []); return; }
    final stroke = RoofStroke(tool: drawTool, points: List.of(current));
    setState(() { strokes.add(stroke); current = []; redo.clear(); });
    if (drawTool != RoofDrawTool.freehand && drawTool != RoofDrawTool.drain) await _editMeasurement(stroke);
  }

  Future<void> _editMeasurement(RoofStroke stroke) async {
    final controller = TextEditingController(text: stroke.measurement);
    final result = await showDialog<String>(context: context, builder: (context) => AlertDialog(title: Text('${stroke.tool.label} measurement'), content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'Length / label', hintText: 'e.g. 12 ft 6 in')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Skip')), FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Apply'))]));
    controller.dispose();
    if (result != null && mounted) setState(() => stroke.measurement = result);
  }

  void _undo() => setState(() { if (strokes.isNotEmpty) redo.add(strokes.removeLast()); });
  void _redo() => setState(() { if (redo.isNotEmpty) strokes.add(redo.removeLast()); });
  void _clearCanvas() => setState(() { redo.addAll(strokes.reversed); strokes.clear(); current = []; });

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
        'beneficiarySource': selectedBeneficiary == null ? null : 'Shelter Roof Repair Assessment',
      };

  Future<void> _persistScope(String status) async {
    if (house.text.trim().isEmpty || parish.trim().isEmpty) { _snack('House Code and Parish are required.'); return; }
    try {
      await widget.state.repository.submitControlEvent(profile: profile, eventType: 'scope', houseCode: house.text.trim().toUpperCase(), parish: parish, item: _scopeData(status));
      _snack(status == 'Draft' ? 'Scope draft saved.' : 'Scope submitted for approval.');
    } catch (_) {
      _snack('Scope could not be saved. Check connectivity and access permissions.');
    }
  }

  Future<void> _printBeneficiaryPdf() async {
    final doc = pw.Document();
    doc.addPage(pw.Page(pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.all(34), build: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Center(child: pw.Text('JAMAICA RED CROSS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14))),
      pw.Center(child: pw.Text('BENEFICIARY ROOF AGREEMENT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18))),
      pw.SizedBox(height: 16),
      pw.Text('House Code: ${house.text}'), pw.Text('Beneficiary: ${beneficiary.text}'), pw.Text('Parish: $parish'), pw.Text('Community: ${cluster.text}'),
      pw.SizedBox(height: 14),
      pw.Text('Official Finished Roof Style: $roofType', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 10),
      _pdfStandardRoof(),
      pw.SizedBox(height: 16),
      for (final role in ['Beneficiary', 'Carpenter', 'Site Supervisor', 'Regional Supervisor', 'Construction Specialist']) ...[
        pw.Text('$role Signature', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        if (signatures[role] != null) pw.Image(pw.MemoryImage(signatures[role]!), height: 48) else pw.SizedBox(height: 38),
        pw.Divider(),
      ],
    ])));
    await Printing.sharePdf(bytes: await doc.save(), filename: 'RC_SOW_Beneficiary_${house.text.trim()}.pdf');
  }

  pw.Widget _pdfStandardRoof() => pw.Container(
        height: 165,
        child: pw.SvgImage(
          svg: '''<svg xmlns="http://www.w3.org/2000/svg" width="600" height="210" viewBox="0 0 600 210">
<rect x="110" y="100" width="380" height="75" fill="none" stroke="#101828" stroke-width="4"/>
<path d="M95 105 L300 35 L505 105" fill="none" stroke="#C91F2C" stroke-width="6"/>
<line x1="95" y1="113" x2="505" y2="113" stroke="#12805C" stroke-width="3"/>
<line x1="130" y1="113" x2="300" y2="43" stroke="#12805C" stroke-width="2"/>
<line x1="180" y1="113" x2="300" y2="43" stroke="#12805C" stroke-width="2"/>
<line x1="230" y1="113" x2="300" y2="43" stroke="#12805C" stroke-width="2"/>
<line x1="370" y1="113" x2="300" y2="43" stroke="#12805C" stroke-width="2"/>
<line x1="420" y1="113" x2="300" y2="43" stroke="#12805C" stroke-width="2"/>
<line x1="470" y1="113" x2="300" y2="43" stroke="#12805C" stroke-width="2"/>
<text x="300" y="200" text-anchor="middle" font-size="18" font-weight="700" fill="#C91F2C">JRC STANDARD FINISHED ROOF STYLE</text>
</svg>''',
        ),
      );

  Widget _line(String key, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [SizedBox(width: 135, child: Text(key, style: const TextStyle(fontWeight: FontWeight.w800))), Expanded(child: Text(value.isEmpty ? '—' : value))]));
  void _snack(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class _ScopeProgress extends StatelessWidget {
  const _ScopeProgress({required this.index});
  final int index;
  @override
  Widget build(BuildContext context) {
    const labels = ['House', 'Canvas', 'Print', 'Files'];
    final theme = Theme.of(context);
    return Semantics(
      label: 'Scope step ${index + 1} of ${labels.length}: ${labels[index]}',
      child: Row(children: [for (var i = 0; i < labels.length; i++) ...[
        Expanded(child: AnimatedContainer(duration: const Duration(milliseconds: 220), height: 38, decoration: BoxDecoration(color: i <= index ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(i == index ? 18 : 12)), child: Center(child: Text(labels[i], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: i <= index ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant))))),
        if (i != labels.length - 1) const SizedBox(width: 6),
      ]]),
    );
  }
}

class RoofCanvasPainter extends CustomPainter {
  RoofCanvasPainter({required this.strokes, required this.current, required this.currentTool, required this.showGrid});
  final List<RoofStroke> strokes;
  final List<Offset> current;
  final RoofDrawTool currentTool;
  final bool showGrid;

  @override
  void paint(Canvas canvas, Size size) {
    if (showGrid) {
      final grid = Paint()..color = RcColors.line.withValues(alpha: .7)..strokeWidth = .6;
      for (double x = 0; x < size.width; x += 20) canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
      for (double y = 0; y < size.height; y += 20) canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    for (final stroke in strokes) _drawStroke(canvas, stroke, size);
    if (current.length >= 2) _drawStroke(canvas, RoofStroke(tool: currentTool, points: current), size, preview: true);
  }

  void _drawStroke(Canvas canvas, RoofStroke stroke, Size size, {bool preview = false}) {
    final color = switch (stroke.tool) {
      RoofDrawTool.wall => RcColors.ink,
      RoofDrawTool.ridge => RcColors.brand,
      RoofDrawTool.hip => RcColors.purple,
      RoofDrawTool.valley => RcColors.blue,
      RoofDrawTool.drain => const Color(0xFF078D91),
      RoofDrawTool.freehand => RcColors.text,
      RoofDrawTool.select => RcColors.muted,
    };
    final paint = Paint()..color = preview ? color.withValues(alpha: .55) : color..strokeWidth = stroke.tool == RoofDrawTool.wall ? 3 : 2.3..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..style = PaintingStyle.stroke;
    if (stroke.points.length < 2) return;
    if (stroke.tool == RoofDrawTool.freehand) {
      final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (final p in stroke.points.skip(1)) path.lineTo(p.dx, p.dy);
      canvas.drawPath(path, paint);
    } else {
      final start = stroke.points.first;
      final end = stroke.points.last;
      canvas.drawLine(start, end, paint);
      if (stroke.tool == RoofDrawTool.drain) _arrow(canvas, start, end, paint);
      if (stroke.measurement.isNotEmpty) {
        final tp = TextPainter(text: TextSpan(text: stroke.measurement, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900, backgroundColor: Colors.white.withValues(alpha: .82))), textDirection: TextDirection.ltr)..layout();
        tp.paint(canvas, Offset((start.dx + end.dx) / 2 - tp.width / 2, (start.dy + end.dy) / 2 - tp.height - 4));
      }
    }
  }

  void _arrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    const length = 12.0;
    canvas.drawLine(end, Offset(end.dx - length * math.cos(angle - .5), end.dy - length * math.sin(angle - .5)), paint);
    canvas.drawLine(end, Offset(end.dx - length * math.cos(angle + .5), end.dy - length * math.sin(angle + .5)), paint);
  }

  @override
  bool shouldRepaint(covariant RoofCanvasPainter oldDelegate) => true;
}

class StandardRoofPainter extends CustomPainter {
  const StandardRoofPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()..color = RcColors.ink..strokeWidth = 2.6..style = PaintingStyle.stroke;
    final red = Paint()..color = RcColors.brand..strokeWidth = 3..style = PaintingStyle.stroke;
    final green = Paint()..color = RcColors.success..strokeWidth = 1.5;
    final left = size.width * .15, right = size.width * .85, wallTop = size.height * .58, bottom = size.height * .84, ridge = Offset(size.width * .5, size.height * .2);
    canvas.drawRect(Rect.fromLTRB(left, wallTop, right, bottom), line);
    canvas.drawLine(Offset(left - 10, wallTop), ridge, red);
    canvas.drawLine(ridge, Offset(right + 10, wallTop), red);
    canvas.drawLine(Offset(left - 10, wallTop + 8), Offset(right + 10, wallTop + 8), green);
    for (double x = left; x <= right; x += 22) canvas.drawLine(Offset(x, wallTop + 8), Offset(size.width * .5 + (x - size.width * .5) * .55, ridge.dy + 8), green);
    final tp = TextPainter(text: const TextSpan(text: 'JRC STANDARD FINISHED ROOF STYLE', style: TextStyle(color: RcColors.brand, fontSize: 11, fontWeight: FontWeight.w900)), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(size.width / 2 - tp.width / 2, size.height - 22));
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
