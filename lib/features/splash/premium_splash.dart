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
  late final HouseRepairGame game;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    game = HouseRepairGame(reduceMotion: widget.reduceMotion);
    timer = Timer(
      Duration(milliseconds: widget.reduceMotion ? 550 : 3300),
      widget.onComplete,
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    game.pauseEngine();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          GameWidget(game: game),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 64),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'RC SOW',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: RcColors.brand,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'BUILDING BACK SAFER',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: RcColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hope • Safety • Recovery',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.blueGrey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HouseRepairGame extends FlameGame {
  HouseRepairGame({required this.reduceMotion});
  final bool reduceMotion;
  double elapsed = 0;

  double stage(double start, double end) =>
      ((elapsed - start) / (end - start)).clamp(0.0, 1.0).toDouble();

  @override
  void update(double dt) {
    super.update(dt);
    elapsed = (elapsed + dt).clamp(0.0, reduceMotion ? .7 : 3.2).toDouble();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final w = size.x;
    final h = size.y;
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFEAF4FF), Color(0xFFFFF1F2), Color(0xFFF4F7FB)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bg);

    final shake = reduceMotion
        ? 0.0
        : (stage(2.0, 2.45) *
              (1 - stage(2.45, 2.75)) *
              math.sin(elapsed * 52) *
              5.0);
    canvas.save();
    canvas.translate(shake, 0);
    final center = Offset(w * .5, h * .44);
    final houseW = math.min(w * .62, 360.0);
    final houseH = houseW * .52;
    final left = center.dx - houseW / 2;
    final right = center.dx + houseW / 2;
    final wallTop = center.dy;
    final bottom = wallTop + houseH;
    final ridge = Offset(center.dx, wallTop - houseH * .58);

    // Ground shadow and house body create a simple pseudo-3D volume.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, bottom + 18),
        width: houseW * .92,
        height: 35,
      ),
      Paint()..color = const Color(0x22000000),
    );
    final body = Path()
      ..moveTo(left, wallTop)
      ..lineTo(right, wallTop)
      ..lineTo(right - 18, bottom)
      ..lineTo(left + 18, bottom)
      ..close();
    canvas.drawPath(body, Paint()..color = Colors.white);
    canvas.drawPath(
      body,
      Paint()
        ..color = RcColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final damage = 1 - stage(.25, 1.25);
    final roof = Paint()
      ..color = RcColors.brandDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final repair = stage(.35, 1.8);
    final lEnd = Offset.lerp(
      Offset(left - 16, wallTop + 8 * damage),
      ridge,
      Curves.easeOutCubic.transform(repair.clamp(0.0, 1.0).toDouble()),
    )!;
    final rEnd = Offset.lerp(
      Offset(right + 16, wallTop + 8 * damage),
      ridge,
      Curves.easeOutCubic.transform(
        ((repair - .32) / .68).clamp(0.0, 1.0).toDouble(),
      ),
    )!;
    canvas.drawLine(Offset(left - 16, wallTop), lEnd, roof);
    canvas.drawLine(Offset(right + 16, wallTop), rEnd, roof);

    if (repair > .25) {
      final batten = Paint()
        ..color = RcColors.success
        ..strokeWidth = 2.5;
      for (var i = 0; i < 6; i++) {
        final f = (i + 1) / 7;
        final p1 = Offset.lerp(Offset(left - 10, wallTop), ridge, f)!;
        final p2 = Offset.lerp(Offset(right + 10, wallTop), ridge, f)!;
        canvas.drawLine(p1, p2, batten);
      }
    }

    // Door and proud face after repair.
    canvas.drawRect(
      Rect.fromLTWH(center.dx - 24, bottom - 64, 48, 64),
      Paint()..color = const Color(0xFFE7ECF2),
    );
    if (stage(2.35, 2.9) > 0) {
      final face = Paint()
        ..color = RcColors.ink
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawCircle(Offset(center.dx - 16, wallTop + 55), 3, face);
      canvas.drawCircle(Offset(center.dx + 16, wallTop + 55), 3, face);
      final smile = Path()
        ..moveTo(center.dx - 18, wallTop + 72)
        ..quadraticBezierTo(
          center.dx,
          wallTop + 86,
          center.dx + 18,
          wallTop + 72,
        );
      canvas.drawPath(smile, face..style = PaintingStyle.stroke);
    }

    // Hammer repair choreography.
    final hammerStage = stage(1.05, 2.25);
    if (!reduceMotion && hammerStage > 0 && hammerStage < 1) {
      canvas.save();
      final hx = ridge.dx + 58;
      final hy = ridge.dy + 12;
      canvas.translate(hx, hy);
      canvas.rotate(-.75 + math.sin(elapsed * 15) * .34);
      final hp = Paint()
        ..color = RcColors.ink
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset.zero, const Offset(0, 46), hp);
      canvas.drawLine(const Offset(-18, 0), const Offset(18, 0), hp);
      canvas.restore();
    }

    // Smoke / dust particles during repair.
    if (!reduceMotion && elapsed > .5 && elapsed < 2.35) {
      final p = Paint()..color = Colors.blueGrey.withValues(alpha: .18);
      for (var i = 0; i < 8; i++) {
        final y = wallTop - 20 - ((elapsed * 35 + i * 13) % 75);
        final x = center.dx + math.sin(elapsed * 2 + i) * (40 + i * 4);
        canvas.drawCircle(Offset(x, y), 5 + (i % 3) * 2, p);
      }
    }

    // Final roof shine.
    final shine = stage(2.55, 3.05);
    if (shine > 0) {
      final sx = left - 30 + (houseW + 60) * shine;
      final sp = Paint()
        ..color = Colors.white.withValues(alpha: .75)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(sx, ridge.dy + 10),
        Offset(sx + 35, wallTop - 3),
        sp,
      );
    }
    canvas.restore();
  }
}
