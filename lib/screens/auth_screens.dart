import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

class RcSplashScreen extends StatefulWidget {
  const RcSplashScreen({super.key});

  @override
  State<RcSplashScreen> createState() => _RcSplashScreenState();
}

class _RcSplashScreenState extends State<RcSplashScreen> {
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer ??= Timer(
      Duration(milliseconds: AppScope.of(context).reducedMotion ? 500 : 1700),
      _continue,
    );
  }

  void _continue() {
    if (mounted) Navigator.pushReplacementNamed(context, RcRoutes.login);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = AppScope.of(context).reducedMotion;
    return Scaffold(
      body: InkWell(
        onTap: _continue,
        child: Center(
          child: TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: reducedMotion ? 250 : 1200),
            tween: Tween<double>(begin: reducedMotion ? .8 : 0, end: 1),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.scale(scale: .9 + (.1 * value), child: child),
              );
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const SizedBox(
                      width: 260,
                      height: 220,
                      child: CustomPaint(painter: _HopeHousePainter()),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Red Cross Scope of Work',
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'BUILDING BACK SAFER',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            letterSpacing: 2,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Hope • Safety • Recovery',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HopeHousePainter extends CustomPainter {
  const _HopeHousePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * .56);
    final rainbow = <Color>[
      const Color(0xFFE13A3E),
      const Color(0xFFF29B38),
      const Color(0xFFF5CC55),
      const Color(0xFF65A96D),
      const Color(0xFF4E8FC7),
    ];
    for (var i = 0; i < rainbow.length; i++) {
      final paint = Paint()
        ..color = rainbow[i].withOpacity(.48)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;
      final inset = 13.0 * i;
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy + 28),
          width: size.width - 22 - inset,
          height: size.height * 1.05 - inset,
        ),
        math.pi,
        math.pi,
        false,
        paint,
      );
    }
    final fill = Paint()..color = Colors.white;
    final outline = Paint()
      ..color = RcColors.brandStrong
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final house = Path()
      ..moveTo(size.width * .25, size.height * .51)
      ..lineTo(size.width * .5, size.height * .28)
      ..lineTo(size.width * .75, size.height * .51)
      ..lineTo(size.width * .75, size.height * .82)
      ..lineTo(size.width * .25, size.height * .82)
      ..close();
    canvas.drawPath(house, fill);
    canvas.drawPath(house, outline);
    final red = Paint()..color = RcColors.brand;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width * .5, size.height * .52),
        width: 55,
        height: 17,
      ),
      red,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width * .5, size.height * .52),
        width: 17,
        height: 55,
      ),
      red,
    );
    final smile = Paint()
      ..color = RcColors.brandStrong
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * .5, size.height * .67),
        width: 60,
        height: 34,
      ),
      .1,
      math.pi - .2,
      false,
      smile,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(
    text: 'andre.brown@redcross.org',
  );
  String _role = 'Site Supervisor';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _signIn() {
    AppScope.of(context).login(selectedRole: _role);
    Navigator.pushNamedAndRemoveUntil(context, RcRoutes.home, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 470),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: RcBrand(),
                  ),
                  const SizedBox(height: 38),
                  Text(
                    'Welcome back',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 9),
                  Text(
                    'Sign in to continue the verified evidence chain for every house.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const <String>[AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Work email',
                      prefixIcon: Icon(Icons.alternate_email),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: _role,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Operational role',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    items: const <String>[
                      'Site Supervisor',
                      'Regional Site Supervisor',
                      'Construction Specialist',
                      'Technical Admin',
                      'Community Admin',
                      'Admin',
                    ]
                        .map(
                          (role) => DropdownMenuItem<String>(
                            value: role,
                            child: Text(
                              role,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _role = value ?? _role),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _signIn,
                    icon: const Icon(Icons.login),
                    label: const Text('SIGN IN SECURELY'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _signIn,
                    icon: const Icon(Icons.g_mobiledata, size: 25),
                    label: const Text('CONTINUE WITH GOOGLE'),
                  ),
                  const SizedBox(height: 22),
                  Card(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Icon(
                            Icons.shield_outlined,
                            color: RcColors.success,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Role and parish access are enforced throughout the connected workflow.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
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
