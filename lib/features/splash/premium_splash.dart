import 'dart:async';
import 'dart:math' as math;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../../core/design_tokens.dart';

class PremiumSplash extends StatefulWidget {
  const PremiumSplash({
    super.key,
    required this.onComplete,
    required this.reduceMotion,
  });
  final VoidCallback onComplete;
  final bool reduceMotion;
  @override
  State<PremiumSplash> createState() => _PremiumSplashState();
}

class _PremiumSplashState extends State<PremiumSplash> {
  late final _HouseRepairGame game;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    game = _HouseRepairGame(reduceMotion: widget.reduceMotion);
    timer = Timer(
      Duration(milliseconds: widget.reduceMotion ? 900 : 4300),
      widget.onComplete,
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4F7FB),
    body: Stack(
      children: [
        Positioned.fill(child: GameWidget(game: game)),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 54,
          child: Column(
            children: [
              Text(
                'RC SOW',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: RcColors.brand,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Repair • Verify • Deliver',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: RcColors.ink,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _HouseRepairGame extends FlameGame {
  _HouseRepairGame({required this.reduceMotion});
  final bool reduceMotion;
  double t = 0;
  final rnd = math.Random(4);
  @override
  Color backgroundColor() => const Color(0xFFF4F7FB);
  @override
  void update(double dt) {
    super.update(dt);
    t += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final w = size.x, h = size.y;
    if (w <= 0 || h <= 0) return;
    final cx = w / 2, baseY = h * .59;
    final phase = reduceMotion ? 1.0 : (t / 4.0).clamp(0.0, 1.0);
    final shake = phase > .72 && phase < .88
        ? math.sin(t * 52) * 5 * (1 - (phase - .72) / .16)
        : 0.0;
    canvas.save();
    canvas.translate(shake, 0);
    final shadow = Paint()..color = Colors.black.withValues(alpha: .12);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, baseY + 94),
        width: w * .54,
        height: 30,
      ),
      shadow,
    );
    final wall = Paint()..color = Colors.white;
    final edge = Paint()
      ..color = RcColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final house = Rect.fromCenter(
      center: Offset(cx, baseY + 26),
      width: w * .48,
      height: h * .22,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(house, const Radius.circular(10)),
      wall,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(house, const Radius.circular(10)),
      edge,
    );
    final roofProgress = (phase / .58).clamp(0.0, 1.0);
    final left = Offset(house.left - 14, house.top + 3),
        right = Offset(house.right + 14, house.top + 3),
        ridge = Offset(cx, house.top - h * .10);
    final roof = Path()
      ..moveTo(left.dx, left.dy)
      ..lineTo(ridge.dx, ridge.dy)
      ..lineTo(right.dx, right.dy);
    final oldRoof = Paint()
      ..color = const Color(0xFFB8C1CC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(roof, oldRoof);
    final fixedRoof = Paint()
      ..color = RcColors.brand
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;
    final metric = roof.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * roofProgress),
      fixedRoof,
    );
    final door = Rect.fromLTWH(cx - 28, house.bottom - 76, 56, 76);
    canvas.drawRRect(
      RRect.fromRectAndRadius(door, const Radius.circular(8)),
      Paint()..color = const Color(0xFF344054),
    );
    if (!reduceMotion && phase < .72) {
      for (var i = 0; i < 7; i++) {
        final a = t * 1.3 + i;
        final x = cx + math.sin(a * 1.7 + i) * 70;
        final y = house.top - 50 - (i * 13 + t * 18) % 100;
        canvas.drawCircle(
          Offset(x, y),
          8 + i % 3 * 3,
          Paint()..color = Colors.blueGrey.withValues(alpha: .16),
        );
      }
      final hp = math.sin(t * 3) * .5 + .5;
      _hammer(canvas, Offset(cx - 90 + hp * 28, ridge.dy + 12), -.6 + hp * .5);
      _hammer(canvas, Offset(cx + 88 - hp * 22, ridge.dy + 28), .7 - hp * .45);
    }
    if (phase > .82) {
      final shine = (math.sin(t * 8) * .25 + .75) * (phase - .82) / .18;
      final p = Paint()
        ..color = Colors.white.withValues(alpha: shine.clamp(0, 1));
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4;
        canvas.drawLine(
          Offset(ridge.dx + math.cos(a) * 22, ridge.dy + math.sin(a) * 22),
          Offset(ridge.dx + math.cos(a) * 62, ridge.dy + math.sin(a) * 62),
          p..strokeWidth = 3,
        );
      }
      final eye = Paint()..color = RcColors.ink;
      canvas.drawCircle(Offset(cx - 25, house.top + 70), 5, eye);
      canvas.drawCircle(Offset(cx + 25, house.top + 70), 5, eye);
      final smile = Path()
        ..moveTo(cx - 30, house.top + 98)
        ..quadraticBezierTo(cx, house.top + 118, cx + 30, house.top + 98);
      canvas.drawPath(
        smile,
        Paint()
          ..color = RcColors.success
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.restore();
  }

  void _hammer(Canvas canvas, Offset p, double angle) {
    canvas.save();
    canvas.translate(p.dx, p.dy);
    canvas.rotate(angle);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-4, -5, 8, 50),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF8B5E3C),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-25, -13, 50, 18),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFF667085),
    );
    canvas.restore();
  }
}
