import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';

class PremiumSplash extends StatefulWidget {
  const PremiumSplash({super.key, required this.onComplete, required this.reduceMotion});
  final VoidCallback onComplete;
  final bool reduceMotion;

  @override
  State<PremiumSplash> createState() => _PremiumSplashState();
}

class _PremiumSplashState extends State<PremiumSplash> with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: Duration(milliseconds: widget.reduceMotion ? 1 : 1550))..forward();
    timer = Timer(Duration(milliseconds: widget.reduceMotion ? 250 : 1750), widget.onComplete);
  }

  @override
  void dispose() {
    timer?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFFFF1F2), RcColors.bg],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, _) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(44),
                      boxShadow: const [BoxShadow(color: Color(0x22101828), blurRadius: 28, offset: Offset(0, 12))],
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(26),
                          child: Image.asset('assets/brand/rc_sow_house_icon.png'),
                        ),
                        CustomPaint(painter: RoofRepairPainter(controller.value)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  const Text('RC SOW', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: RcColors.brand)),
                  const SizedBox(height: 6),
                  const Text('BUILDING BACK SAFER', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.5, color: RcColors.ink)),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: 150,
                    child: LinearProgressIndicator(value: controller.value, minHeight: 4, borderRadius: BorderRadius.circular(999)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RoofRepairPainter extends CustomPainter {
  RoofRepairPainter(this.t);
  final double t;

  double stage(double start, double end) =>
      ((t - start) / (end - start)).clamp(0.0, 1.0).toDouble();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = RcColors.brandDeep
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final center = Offset(size.width / 2, size.height * .55);
    final left = Offset(size.width * .22, size.height * .72);
    final right = Offset(size.width * .78, size.height * .72);
    final ridge = Offset(center.dx, size.height * .34);
    void beam(Offset a, Offset b, double p) => canvas.drawLine(a, Offset.lerp(a, b, Curves.easeOutCubic.transform(p))!, paint);
    beam(left, right, stage(.05, .2));
    beam(left, ridge, stage(.18, .42));
    beam(right, ridge, stage(.35, .58));
    beam(Offset(ridge.dx - 26, ridge.dy), Offset(ridge.dx + 26, ridge.dy), stage(.52, .68));
    beam(Offset(left.dx + 25, left.dy), Offset.lerp(left, ridge, .55)!, stage(.64, .8));
    beam(Offset(right.dx - 25, right.dy), Offset.lerp(right, ridge, .55)!, stage(.72, .9));
    final hammerT = stage(.78, 1);
    if (hammerT > 0) {
      canvas.save();
      canvas.translate(ridge.dx + 38, ridge.dy - 4);
      canvas.rotate(-.7 + math.sin(hammerT * math.pi * 2) * .22);
      final h = Paint()..color = RcColors.ink..strokeWidth = 5..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(0, 0), const Offset(0, 36), h);
      canvas.drawLine(const Offset(-12, 0), const Offset(14, 0), h);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant RoofRepairPainter oldDelegate) => oldDelegate.t != t;
}
