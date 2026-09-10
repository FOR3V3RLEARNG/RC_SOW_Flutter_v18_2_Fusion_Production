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

class _PremiumSplashState extends State<PremiumSplash>
    with SingleTickerProviderStateMixin {
  late final HouseRepairGame game;
  late final AnimationController intro;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    game = HouseRepairGame(reduceMotion: widget.reduceMotion);
    intro = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.reduceMotion ? 650 : 3800),
    )..forward();
    timer = Timer(
      Duration(milliseconds: widget.reduceMotion ? 720 : 3850),
      widget.onComplete,
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    intro.dispose();
    game.pauseEngine();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1), weight: 11),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 10),
      TweenSequenceItem(tween: ConstantTween(0), weight: 79),
    ]).animate(intro);
    final iconScale = Tween<double>(begin: .88, end: 1.08).animate(
      CurvedAnimation(
        parent: intro,
        curve: const Interval(0, .22, curve: Curves.easeOutBack),
      ),
    );

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          GameWidget(game: game),
          IgnorePointer(
            child: Center(
              child: FadeTransition(
                opacity: iconOpacity,
                child: ScaleTransition(
                  scale: iconScale,
                  child: Container(
                    width: 126,
                    height: 126,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .95),
                      borderRadius: BorderRadius.circular(34),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x26000000),
                          blurRadius: 28,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/brand/rc_sow_house_icon.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 54),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Red Cross Scope of Work',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        height: 1.03,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.7,
                        color: RcColors.brand,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'BUILDING BACK SAFER',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.7,
                        color: RcColors.ink,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Scope • Construction • Recovery',
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
    elapsed = (elapsed + dt).clamp(0.0, reduceMotion ? .8 : 3.75).toDouble();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final w = size.x;
    final h = size.y;
    // SUNNY HORIZON SPLASH V1
    // Bright, positive recovery atmosphere: clear sky, golden horizon,
    // warm sunlight and soft green Jamaican landscape.
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: [0.0, .38, .63, 1.0],
        colors: [
          Color(0xFF66BFF4),
          Color(0xFFBFE8FF),
          Color(0xFFFFE6A7),
          Color(0xFFFFF8E8),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bg);

    final horizonY = h * .56;
    final sunCenter = Offset(w * .78, h * .24);
    final sunRadius = math.min(w, h) * .075;

    final sunGlow = Paint()
      ..shader = const RadialGradient(
        stops: [0.0, .34, 1.0],
        colors: [
          Color(0xFFFFF8C7),
          Color(0xAAFFD86B),
          Color(0x00FFD86B),
        ],
      ).createShader(
        Rect.fromCircle(center: sunCenter, radius: sunRadius * 3.2),
      );
    canvas.drawCircle(sunCenter, sunRadius * 3.2, sunGlow);

    final rayPaint = Paint()
      ..color = const Color(0xFFFFE28A).withValues(alpha: .38)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 14; i++) {
      final angle = i * (math.pi * 2 / 14);
      final start = Offset(
        sunCenter.dx + math.cos(angle) * sunRadius * 1.4,
        sunCenter.dy + math.sin(angle) * sunRadius * 1.4,
      );
      final end = Offset(
        sunCenter.dx + math.cos(angle) * sunRadius * 2.0,
        sunCenter.dy + math.sin(angle) * sunRadius * 2.0,
      );
      canvas.drawLine(start, end, rayPaint);
    }
    canvas.drawCircle(
      sunCenter,
      sunRadius,
      Paint()..color = const Color(0xFFFFD85E),
    );

    final cloud = Paint()..color = Colors.white.withValues(alpha: .68);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * .19, h * .19),
        width: w * .20,
        height: h * .038,
      ),
      cloud,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * .27, h * .175),
        width: w * .13,
        height: h * .032,
      ),
      cloud,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * .58, h * .30),
        width: w * .15,
        height: h * .027,
      ),
      Paint()..color = Colors.white.withValues(alpha: .48),
    );

    final distantHills = Path()
      ..moveTo(0, horizonY + 16)
      ..quadraticBezierTo(w * .18, horizonY - 34, w * .39, horizonY + 5)
      ..quadraticBezierTo(w * .61, horizonY - 24, w * .78, horizonY + 10)
      ..quadraticBezierTo(w * .90, horizonY - 12, w, horizonY + 8)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(distantHills, Paint()..color = const Color(0xFFB9D98C));

    final nearHills = Path()
      ..moveTo(0, h * .70)
      ..quadraticBezierTo(w * .20, h * .63, w * .43, h * .70)
      ..quadraticBezierTo(w * .68, h * .62, w, h * .71)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      nearHills,
      Paint()..color = const Color(0xFFDDEABF).withValues(alpha: .92),
    );

    final center = Offset(w * .5, h * .43);
    final houseW = math.min(w * .68, 390.0);
    final houseH = houseW * .50;
    final left = center.dx - houseW / 2;
    final right = center.dx + houseW / 2;
    final wallTop = center.dy;
    final bottom = wallTop + houseH;
    final ridge = Offset(center.dx, wallTop - houseH * .61);

    final shake = reduceMotion
        ? 0.0
        : math.sin(elapsed * 48) *
              2.3 *
              stage(1.0, 1.5) *
              (1 - stage(2.4, 2.8));
    canvas.save();
    canvas.translate(shake, 0);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, bottom + 20),
        width: houseW * .92,
        height: 38,
      ),
      Paint()..color = const Color(0x22000000),
    );

    final body = Path()
      ..moveTo(left, wallTop)
      ..lineTo(right, wallTop)
      ..lineTo(right - 18, bottom)
      ..lineTo(left + 18, bottom)
      ..close();
    canvas.drawPath(body, Paint()..color = const Color(0xFFFDFEFF));
    canvas.drawPath(
      body,
      Paint()
        ..color = RcColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(center.dx - 23, bottom - 67, 46, 67),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFFDDE4EC),
    );

    final repair = stage(.45, 2.35);
    final exposedAlpha = (1 - stage(1.35, 2.0)).clamp(0.0, 1.0);
    final timber = Paint()
      ..color = const Color(0xFF885B36).withValues(alpha: exposedAlpha)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(left - 14, wallTop), ridge, timber);
    canvas.drawLine(ridge, Offset(right + 14, wallTop), timber);
    for (var i = 1; i < 6; i++) {
      final f = i / 6;
      final y = wallTop - (wallTop - ridge.dy) * f;
      final half = (houseW * .5 + 14) * (1 - f);
      canvas.drawLine(
        Offset(center.dx - half, y),
        Offset(center.dx + half, y),
        timber..strokeWidth = 2.7,
      );
    }

    // New roof sheeting grows across the exposed framing.
    final sheetStage = Curves.easeOutCubic.transform(
      ((repair - .35) / .65).clamp(0.0, 1.0),
    );
    if (sheetStage > 0) {
      final leftEave = Offset(left - 22, wallTop + 4);
      final rightEave = Offset(right + 22, wallTop + 4);
      final leftReveal = Offset.lerp(ridge, leftEave, sheetStage)!;
      final rightReveal = Offset.lerp(ridge, rightEave, sheetStage)!;

      final leftRoof = Path()
        ..moveTo(ridge.dx, ridge.dy)
        ..lineTo(leftReveal.dx, leftReveal.dy)
        ..lineTo(leftEave.dx, leftEave.dy)
        ..lineTo(ridge.dx, ridge.dy)
        ..close();
      final rightRoof = Path()
        ..moveTo(ridge.dx, ridge.dy)
        ..lineTo(rightReveal.dx, rightReveal.dy)
        ..lineTo(rightEave.dx, rightEave.dy)
        ..lineTo(ridge.dx, ridge.dy)
        ..close();

      final sheetPaint = Paint()
        ..shader =
            const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                RcColors.brandDeep,
                RcColors.brand,
                Color(0xFFF0525D),
                RcColors.brandDeep,
              ],
            ).createShader(
              Rect.fromLTRB(left - 24, ridge.dy, right + 24, wallTop + 8),
            );
      canvas.drawPath(leftRoof, sheetPaint);
      canvas.drawPath(rightRoof, sheetPaint);

      final ribs = Paint()
        ..color = const Color(0xFFFFDADD).withValues(alpha: .72)
        ..strokeWidth = 1.5;
      for (var i = 1; i < 9; i++) {
        final f = i / 9;
        final lp = Offset.lerp(ridge, leftEave, f)!;
        final rp = Offset.lerp(ridge, rightEave, f)!;
        canvas.drawLine(lp, Offset(lp.dx + 13, lp.dy + 2), ribs);
        canvas.drawLine(rp, Offset(rp.dx - 13, rp.dy + 2), ribs);
      }
    }

    // Fascia, blocking board, and ridge cap complete the new roof.
    final finishStage = stage(2.05, 2.75);
    if (finishStage > 0) {
      final fascia = Paint()
        ..color = RcColors.brandDeep.withValues(alpha: finishStage)
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.square;
      canvas.drawLine(
        Offset(left - 24, wallTop + 5),
        Offset(center.dx - 2, ridge.dy + 2),
        fascia,
      );
      canvas.drawLine(
        Offset(center.dx + 2, ridge.dy + 2),
        Offset(right + 24, wallTop + 5),
        fascia,
      );

      final block = Paint()
        ..color = const Color(0xFF9C6B43).withValues(alpha: finishStage);
      for (var i = 0; i < 8; i++) {
        final x = left + 20 + i * ((houseW - 40) / 7);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(x, wallTop - 4),
              width: 20,
              height: 12,
            ),
            const Radius.circular(2),
          ),
          block,
        );
      }

      canvas.drawCircle(
        ridge,
        7,
        Paint()..color = const Color(0xFFFFD8DC).withValues(alpha: finishStage),
      );
    }

    // Hammer repair choreography.
    final hammerStage = stage(.95, 2.35);
    if (!reduceMotion && hammerStage > 0 && hammerStage < 1) {
      canvas.save();
      canvas.translate(ridge.dx + 64, ridge.dy + 8);
      canvas.rotate(-.68 + math.sin(elapsed * 15) * .42);
      final hammer = Paint()
        ..color = RcColors.ink
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset.zero, const Offset(0, 48), hammer);
      canvas.drawLine(const Offset(-20, 0), const Offset(20, 0), hammer);
      canvas.restore();
    }

    // Soft warm construction particles keep the repair action visible
    // without darkening the optimistic sunrise scene.
    if (!reduceMotion && elapsed > .62 && elapsed < 2.42) {
      final dustStrength = math.sin(stage(.62, 2.42) * math.pi).clamp(0.0, 1.0);
      for (var i = 0; i < 18; i++) {
        final angle = i * .91 + elapsed * (.22 + (i % 4) * .03);
        final drift = 26 + (i % 6) * 10.0;
        final x =
            center.dx +
            math.sin(angle) * drift +
            math.sin(elapsed * 1.6 + i) * 24;
        final y =
            ridge.dy +
            26 +
            ((i * 23 + elapsed * 38) % (wallTop - ridge.dy + 48));
        final radius = 6.0 + (i % 4) * 2.2;
        final dust = Paint()
          ..color = Color.lerp(
            const Color(0xFFFFDFA1),
            const Color(0xFFFFF3D0),
            (i % 4) / 4,
          )!.withValues(alpha: .07 + .08 * dustStrength);
        canvas.drawCircle(Offset(x, y), radius, dust);
      }
    }

    final shine = stage(2.75, 3.45);
    if (shine > 0) {
      final x = left - 26 + (houseW + 52) * shine;
      final shinePaint = Paint()
        ..color = Colors.white.withValues(alpha: .72)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(x, ridge.dy + 12),
        Offset(x + 34, wallTop - 2),
        shinePaint,
      );
    }

    canvas.restore();
  }
}
