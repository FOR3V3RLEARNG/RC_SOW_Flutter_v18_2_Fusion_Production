import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/rc_components.dart';
import '../../models/app_models.dart';

class TechnicalRoofDraftScreen extends StatefulWidget {
  const TechnicalRoofDraftScreen({
    super.key,
    required this.initialMeasurements,
    required this.initialRoofType,
  });

  final RoofMeasurements initialMeasurements;
  final String initialRoofType;

  @override
  State<TechnicalRoofDraftScreen> createState() =>
      _TechnicalRoofDraftScreenState();
}

class _TechnicalRoofDraftScreenState extends State<TechnicalRoofDraftScreen> {
  late final TextEditingController width;
  late final TextEditingController length;
  late final TextEditingController wallHeight;
  late final TextEditingController pitch;
  late String roofType;

  @override
  void initState() {
    super.initState();
    width = TextEditingController(text: _initial(widget.initialMeasurements.widthFt));
    length = TextEditingController(text: _initial(widget.initialMeasurements.lengthFt));
    wallHeight = TextEditingController(text: _initial(widget.initialMeasurements.wallHeightFt));
    pitch = TextEditingController(
      text: widget.initialMeasurements.pitchRisePer12 == 0
          ? '4'
          : _initial(widget.initialMeasurements.pitchRisePer12),
    );
    roofType = const ['Gable', 'Hip', 'Pitched'].contains(widget.initialRoofType)
        ? widget.initialRoofType
        : 'Gable';
  }

  String _initial(double v) => v == 0 ? '' : v.toStringAsFixed(v % 1 == 0 ? 0 : 2);

  @override
  void dispose() {
    width.dispose();
    length.dispose();
    wallHeight.dispose();
    pitch.dispose();
    super.dispose();
  }

  double _number(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  RoofMeasurements get measurements => RoofMeasurements(
        widthFt: _number(width),
        lengthFt: _number(length),
        wallHeightFt: _number(wallHeight),
        pitchRisePer12: _number(pitch),
      );

  @override
  Widget build(BuildContext context) {
    final m = measurements;
    return Scaffold(
      appBar: AppBar(title: const Text('Technical Roof Draft')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
        children: [
          const RcPageHeading(
            eyebrow: 'Stable technical geometry',
            title: 'Roof Framing Draft & Calculator',
            subtitle:
                'Deterministic wall, wall-plate, ridge, rafter, fascia and blocking geometry for a stable technical drawing.',
          ),
          const SizedBox(height: 14),
          RcExpressiveSurface(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    initialValue: roofType,
                    decoration: const InputDecoration(labelText: 'Roof type'),
                    items: const ['Gable', 'Hip', 'Pitched']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => setState(() => roofType = v!),
                  ),
                ),
                _field(width, 'Width (ft)'),
                _field(length, 'Length (ft)'),
                _field(wallHeight, 'Wall height (ft)'),
                _field(pitch, 'Pitch rise / 12'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          RcExpressiveSurface(
            shape: RcSurfaceShape.hero,
            child: AspectRatio(
              aspectRatio: 1.25,
              child: CustomPaint(
                painter: TechnicalRoofPainter(
                  roofType: roofType,
                  measurements: m,
                  foreground: Theme.of(context).colorScheme.onSurface,
                  accent: Theme.of(context).colorScheme.primary,
                  grid: Theme.of(context).colorScheme.outlineVariant,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          const SizedBox(height: 14),
          RcExpressiveSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Framing calculations', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                _result('Half span / run', m.halfSpanFt, 'ft'),
                _result('Rise wall plate → ridge', m.ridgeRiseFt, 'ft'),
                _result('Ridge height from floor', m.ridgeHeightFt, 'ft'),
                _result('Common rafter length', m.rafterLengthFt, 'ft'),
                _result('Approx. roof plan area', m.widthFt * m.lengthFt, 'sq ft'),
                if (m.lengthFt > 0)
                  _result(
                    'Approx. rafter pairs @ 2 ft',
                    (m.lengthFt / 2).ceilToDouble() + 1,
                    'pairs',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController controller, String label) => SizedBox(
        width: 155,
        child: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label),
          onChanged: (_) => setState(() {}),
        ),
      );

  Widget _result(String label, double value, String unit) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Text(
              '${value.isFinite ? value.toStringAsFixed(2) : '0.00'} $unit',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      );
}

class TechnicalRoofPainter extends CustomPainter {
  TechnicalRoofPainter({
    required this.roofType,
    required this.measurements,
    required this.foreground,
    required this.accent,
    required this.grid,
  });

  final String roofType;
  final RoofMeasurements measurements;
  final Color foreground;
  final Color accent;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = grid.withValues(alpha: .35)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 0.0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final line = Paint()
      ..color = foreground
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final strong = Paint()
      ..color = accent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final plan = Rect.fromLTWH(
      size.width * .1,
      size.height * .08,
      size.width * .8,
      size.height * .36,
    );
    canvas.drawRect(plan, line);
    final ridgeY = plan.center.dy;
    final ridgeStart = Offset(plan.left + plan.width * .18, ridgeY);
    final ridgeEnd = Offset(plan.right - plan.width * .18, ridgeY);
    canvas.drawLine(ridgeStart, ridgeEnd, strong);

    if (roofType == 'Hip') {
      canvas.drawLine(plan.topLeft, ridgeStart, line);
      canvas.drawLine(plan.bottomLeft, ridgeStart, line);
      canvas.drawLine(plan.topRight, ridgeEnd, line);
      canvas.drawLine(plan.bottomRight, ridgeEnd, line);
    }

    for (var x = plan.left + 22; x < plan.right; x += 26) {
      canvas.drawLine(Offset(x, plan.top), Offset(x, ridgeY), line);
      canvas.drawLine(Offset(x, ridgeY), Offset(x, plan.bottom), line);
    }

    _label(canvas, 'PLAN • $roofType', Offset(plan.left, plan.top - 22), accent);
    _label(canvas, 'RIDGE', Offset(plan.center.dx - 22, ridgeY - 22), accent);

    final baseY = size.height * .83;
    final wallTopY = size.height * .64;
    final left = size.width * .18;
    final right = size.width * .82;
    canvas.drawRect(Rect.fromLTRB(left, wallTopY, right, baseY), line);
    final mid = (left + right) / 2;
    final rise = math.max(
      34.0,
      math.min(
        size.height * .16,
        size.height * .07 + measurements.pitchRisePer12 * 2.4,
      ),
    );
    final ridge = Offset(mid, wallTopY - rise);
    canvas.drawLine(Offset(left - 18, wallTopY), ridge, strong);
    canvas.drawLine(ridge, Offset(right + 18, wallTopY), strong);
    canvas.drawLine(Offset(left, wallTopY), Offset(right, wallTopY), line);

    for (var x = left + 18; x < right; x += 30) {
      final t = (x - left) / (right - left);
      final roofY = t <= .5
          ? wallTopY - rise * (t / .5)
          : wallTopY - rise * ((1 - t) / .5);
      canvas.drawLine(Offset(x, wallTopY), Offset(x, roofY), line);
    }

    canvas.drawLine(
      Offset(left - 22, wallTopY + 6),
      Offset(right + 22, wallTopY + 6),
      line,
    );
    _label(canvas, 'WALL PLATE', Offset(left, wallTopY + 10), foreground);
    _label(canvas, 'RIDGE BEAM', Offset(mid - 38, ridge.dy - 20), accent);
    _label(canvas, 'FASCIA / BLOCKING', Offset(right - 105, wallTopY - 26), foreground);
    _label(canvas, 'ELEVATION', Offset(left, size.height * .5), accent);
    if (measurements.ridgeRiseFt > 0) {
      _label(
        canvas,
        'Rise ${measurements.ridgeRiseFt.toStringAsFixed(2)} ft',
        Offset(mid + 8, (ridge.dy + wallTopY) / 2),
        foreground,
      );
    }
  }

  void _label(Canvas canvas, String text, Offset offset, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant TechnicalRoofPainter oldDelegate) =>
      oldDelegate.roofType != roofType ||
      oldDelegate.measurements.widthFt != measurements.widthFt ||
      oldDelegate.measurements.lengthFt != measurements.lengthFt ||
      oldDelegate.measurements.wallHeightFt != measurements.wallHeightFt ||
      oldDelegate.measurements.pitchRisePer12 != measurements.pitchRisePer12 ||
      oldDelegate.foreground != foreground ||
      oldDelegate.accent != accent;
}
