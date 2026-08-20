import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/design_tokens.dart';
import '../../core/rc_components.dart';
import '../../models/app_models.dart';
import '../../state/app_state.dart';

class ScopeScreen extends StatefulWidget {
  const ScopeScreen({super.key, required this.state});
  final AppState state;

  @override
  State<ScopeScreen> createState() => _ScopeScreenState();
}

class _ScopeScreenState extends State<ScopeScreen> with SingleTickerProviderStateMixin {
  late final TabController tabs;
  String houseCode = 'H15';
  String beneficiary = '';
  String parish = 'Hanover';
  String cluster = '';
  double width = 24;
  double length = 30;
  double wallHeight = 9;
  double pitch = 4;
  String roofType = 'Gable';

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 4, vsync: this);
    tabs.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (mounted && !tabs.indexIsChanging) setState(() {});
  }

  RoofMeasurements get measurements => RoofMeasurements(widthFt: width, lengthFt: length, wallHeightFt: wallHeight, pitchRisePer12: pitch);

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: RcPageHeading(
          eyebrow: 'Assessment & scope',
          title: 'Scope of Work Data',
          subtitle: 'Capture the house, verify roof geometry, prepare the beneficiary record and preserve evidence in one guided flow.',
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
        child: _ScopeProgress(index: tabs.index),
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
          children: [houseInfo(), roofDrawing(), printout(), files()],
        ),
      ),
    ]);
  }

  Widget houseInfo() => ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 110), children: [
    Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      TextFormField(initialValue: houseCode, decoration: const InputDecoration(labelText: 'House Code'), onChanged: (v) => houseCode = v),
      const SizedBox(height: 12),
      TextFormField(initialValue: beneficiary, decoration: const InputDecoration(labelText: 'Beneficiary'), onChanged: (v) => beneficiary = v),
      const SizedBox(height: 12),
      TextFormField(initialValue: parish, decoration: const InputDecoration(labelText: 'Parish'), onChanged: (v) => parish = v),
      const SizedBox(height: 12),
      TextFormField(initialValue: cluster, decoration: const InputDecoration(labelText: 'Cluster'), onChanged: (v) => cluster = v),
    ]))),
    const SizedBox(height: 14),
    Wrap(spacing: 10, runSpacing: 10, children: [
      OutlinedButton.icon(
        onPressed: () => _persistScope('Draft'),
        icon: const Icon(Icons.save_outlined),
        label: const Text('Save Scope Draft'),
      ),
      FilledButton.icon(
        onPressed: () => _persistScope('Submitted'),
        icon: const Icon(Icons.send_outlined),
        label: const Text('Submit for Approval'),
      ),
    ]),
  ]);


  Future<void> _persistScope(String status) async {
    if (houseCode.trim().isEmpty || parish.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('House Code and Parish are required.')),
      );
      return;
    }
    try {
      await widget.state.repository.submitControlEvent(
        profile: widget.state.profile!,
        eventType: 'scope',
        houseCode: houseCode.trim(),
        parish: parish.trim(),
        item: {
          'status': status,
          'houseCode': houseCode.trim(),
          'beneficiary': beneficiary.trim(),
          'parish': parish.trim(),
          'cluster': cluster.trim(),
          'roofType': roofType,
          'widthFt': width,
          'lengthFt': length,
          'wallHeightFt': wallHeight,
          'pitchRisePer12': pitch,
          'ridgeRiseFt': measurements.ridgeRiseFt,
          'ridgeHeightFt': measurements.ridgeHeightFt,
          'source': 'Flutter v18.2 Fusion Production',
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(status == 'Draft' ? 'Scope draft saved to RC SOW.' : 'Scope submitted for approval.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scope could not be saved: $e')),
      );
    }
  }

  Widget roofDrawing() => ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 110), children: [
    Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Technical Roof Drawing', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(initialValue: roofType, decoration: const InputDecoration(labelText: 'Roof type'), items: ['Gable', 'Hip', 'Shed', 'Intersecting'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (v) => setState(() => roofType = v!)),
      const SizedBox(height: 14),
      RoofDiagram(type: roofType, m: measurements, showGrid: widget.state.showGrid),
      const SizedBox(height: 14),
      Wrap(spacing: 10, runSpacing: 10, children: [
        measureField('Building width', width, (v) => width = v),
        measureField('Building length', length, (v) => length = v),
        measureField('Wall height', wallHeight, (v) => wallHeight = v),
        measureField('Pitch rise / 12', pitch, (v) => pitch = v),
      ]),
      const SizedBox(height: 16),
      Card(color: RcColors.blueSoft, child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        metric('Wall height', measurements.wallHeightFt),
        metric('Wall plate → ridge rise', measurements.ridgeRiseFt, emphasize: true),
        metric('Ridge height from ground', measurements.ridgeHeightFt),
        metric('Rafter length', measurements.rafterLengthFt),
      ]))),
    ]))),
  ]);

  Widget measureField(String label, double value, ValueChanged<double> changed) => SizedBox(width: 180, child: TextFormField(initialValue: value.toStringAsFixed(value % 1 == 0 ? 0 : 1), keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: '$label (ft)'), onChanged: (v) { final d = double.tryParse(v); if (d != null && d > 0) setState(() => changed(d)); }));

  Widget metric(String label, double value, {bool emphasize = false}) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [Expanded(child: Text(label, style: TextStyle(fontWeight: emphasize ? FontWeight.w900 : FontWeight.w700))), Text('${value.toStringAsFixed(2)} ft', style: TextStyle(fontWeight: FontWeight.w900, color: emphasize ? RcColors.brand : RcColors.ink))]));

  Widget printout() => ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 110), children: [
    Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Center(child: Text('BENEFICIARY PRINT OUT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
      const SizedBox(height: 18),
      printLine('House Code', houseCode),
      printLine('Name', beneficiary.isEmpty ? '—' : beneficiary),
      printLine('Parish', parish),
      printLine('Cluster', cluster.isEmpty ? '—' : cluster),
      printLine('Roof Type', roofType),
      printLine('Wall Plate → Ridge Rise', '${measurements.ridgeRiseFt.toStringAsFixed(2)} ft'),
      const SizedBox(height: 22),
      for (final label in ['Beneficiary Signature', 'Carpenter Signature', 'Site Supervisor', 'Regional Supervisor', 'Construction Specialist']) ...[
        const Divider(height: 28), Text(label, style: const TextStyle(fontSize: 11, color: RcColors.muted)),
      ],
      const SizedBox(height: 20),
      FilledButton.icon(onPressed: printPdf, icon: const Icon(Icons.print_outlined), label: const Text('Print / Export PDF')),
    ]))),
  ]);

  Widget printLine(String k, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [SizedBox(width: 130, child: Text(k, style: const TextStyle(fontWeight: FontWeight.w800))), Expanded(child: Text(v))]));

  Widget files() => ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 110), children: const [
    Card(child: Padding(padding: EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Scope Files', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), SizedBox(height: 8), Text('Photos, signed scope documents, drawings and approved PDFs belong here. Essential field workflow remains usable even when no media is attached.')]))),
  ]);

  Future<void> printPdf() async {
    final doc = pw.Document();
    doc.addPage(pw.Page(pageFormat: PdfPageFormat.a4, build: (_) => pw.Padding(padding: const pw.EdgeInsets.all(30), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Center(child: pw.Text('RC SOW — BENEFICIARY PRINT OUT', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
      pw.SizedBox(height: 24),
      pw.Text('House Code: $houseCode'), pw.Text('Beneficiary: ${beneficiary.isEmpty ? '—' : beneficiary}'), pw.Text('Parish: $parish'), pw.Text('Cluster: ${cluster.isEmpty ? '—' : cluster}'),
      pw.SizedBox(height: 12),
      pw.Text('Roof: $roofType'), pw.Text('Wall height: ${measurements.wallHeightFt.toStringAsFixed(2)} ft'), pw.Text('Wall plate to ridge rise: ${measurements.ridgeRiseFt.toStringAsFixed(2)} ft'), pw.Text('Ridge height from ground: ${measurements.ridgeHeightFt.toStringAsFixed(2)} ft'),
      pw.SizedBox(height: 30),
      for (final label in ['Beneficiary Signature', 'Carpenter Signature', 'Site Supervisor', 'Regional Supervisor', 'Construction Specialist']) ...[pw.Divider(), pw.Text(label), pw.SizedBox(height: 18)],
    ]))));
    await Printing.layoutPdf(onLayout: (_) => doc.save());
  }
}


class _ScopeProgress extends StatelessWidget {
  const _ScopeProgress({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    const labels = ['House', 'Roof', 'Print', 'Files'];
    final theme = Theme.of(context);
    return Semantics(
      label: 'Scope form step ${index + 1} of ${labels.length}: ${labels[index]}',
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: 38,
                decoration: BoxDecoration(
                  color: i <= index
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(i == index ? 18 : 12),
                ),
                child: Center(
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: i <= index
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant,
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

class RoofDiagram extends StatelessWidget {
  const RoofDiagram({super.key, required this.type, required this.m, required this.showGrid});
  final String type;
  final RoofMeasurements m;
  final bool showGrid;

  @override
  Widget build(BuildContext context) => AspectRatio(aspectRatio: 1.55, child: CustomPaint(painter: RoofPainter(type: type, m: m, showGrid: showGrid), child: const SizedBox.expand()));
}

class RoofPainter extends CustomPainter {
  RoofPainter({required this.type, required this.m, required this.showGrid});
  final String type;
  final RoofMeasurements m;
  final bool showGrid;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = RcColors.line..strokeWidth = .7;
    if (showGrid) {
      for (double x = 0; x < size.width; x += 20) { canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid); }
      for (double y = 0; y < size.height; y += 20) { canvas.drawLine(Offset(0, y), Offset(size.width, y), grid); }
    }
    final line = Paint()..color = RcColors.ink..strokeWidth = 2.3..style = PaintingStyle.stroke;
    final dim = Paint()..color = RcColors.blue..strokeWidth = 1.2;
    final left = size.width * .18, right = size.width * .82, ground = size.height * .78, wallTop = size.height * .55, ridgeY = size.height * .25, cx = size.width / 2;
    canvas.drawRect(Rect.fromLTRB(left, wallTop, right, ground), line);
    if (type == 'Shed') {
      canvas.drawLine(Offset(left, wallTop), Offset(right, ridgeY), line);
    } else {
      canvas.drawLine(Offset(left, wallTop), Offset(cx, ridgeY), line);
      canvas.drawLine(Offset(cx, ridgeY), Offset(right, wallTop), line);
      if (type == 'Hip') {
        canvas.drawLine(Offset(left, wallTop), Offset(cx - 18, ridgeY + 8), line);
        canvas.drawLine(Offset(right, wallTop), Offset(cx + 18, ridgeY + 8), line);
      }
      if (type == 'Intersecting') {
        canvas.drawLine(Offset(cx, ridgeY), Offset(cx + size.width * .16, wallTop + 20), line);
      }
    }
    canvas.drawLine(Offset(right + 16, wallTop), Offset(right + 16, ridgeY), dim);
    canvas.drawLine(Offset(right + 10, wallTop), Offset(right + 22, wallTop), dim);
    canvas.drawLine(Offset(right + 10, ridgeY), Offset(right + 22, ridgeY), dim);
    final tp = TextPainter(text: TextSpan(text: 'Rise ${m.ridgeRiseFt.toStringAsFixed(2)} ft', style: const TextStyle(color: RcColors.blue, fontSize: 11, fontWeight: FontWeight.w800)), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(right + 26, (wallTop + ridgeY) / 2 - tp.height / 2));
    final wp = TextPainter(text: TextSpan(text: '${m.widthFt.toStringAsFixed(1)} ft', style: const TextStyle(color: RcColors.ink, fontSize: 11, fontWeight: FontWeight.w800)), textDirection: TextDirection.ltr)..layout();
    wp.paint(canvas, Offset(cx - wp.width / 2, ground + 8));
  }

  @override
  bool shouldRepaint(covariant RoofPainter oldDelegate) => oldDelegate.type != type || oldDelegate.m != m || oldDelegate.showGrid != showGrid;
}
