import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class RcSignaturePad extends StatefulWidget {
  const RcSignaturePad({super.key, this.title = 'Digital signature'});
  final String title;

  static Future<Uint8List?> capture(BuildContext context, {String title = 'Digital signature'}) {
    return showModalBottomSheet<Uint8List>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: .72,
        child: RcSignaturePad(title: title),
      ),
    );
  }

  @override
  State<RcSignaturePad> createState() => _RcSignaturePadState();
}

class _RcSignaturePadState extends State<RcSignaturePad> {
  final key = GlobalKey();
  final strokes = <List<Offset>>[];

  void add(Offset point) {
    setState(() {
      if (strokes.isEmpty || strokes.last.isEmpty) strokes.add(<Offset>[]);
      strokes.last.add(point);
    });
  }

  Future<void> done() async {
    if (strokes.every((stroke) => stroke.isEmpty)) return;
    final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 2.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (!mounted) return;
    Navigator.pop(context, bytes?.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 5),
          Text(
            'Sign with a finger or stylus. The signature is saved with signer, role and timestamp when the record is submitted.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: RepaintBoundary(
              key: key,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                clipBehavior: Clip.antiAlias,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (details) => setState(() => strokes.add([details.localPosition])),
                  onPanUpdate: (details) => add(details.localPosition),
                  onPanEnd: (_) => setState(() => strokes.add(<Offset>[])),
                  child: CustomPaint(
                    painter: _SignaturePainter(strokes),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(strokes.clear),
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: const Text('Clear'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: done,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Use signature'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter(this.strokes);
  final List<List<Offset>> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF101828)
      ..strokeWidth = 2.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
