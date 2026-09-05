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
      () => unawaited(_continue()),
    );
  }

  bool _continuing = false;

  Future<void> _continue() async {
    if (!mounted || _continuing) return;
    _continuing = true;
    final state = AppScope.of(context);

    if (!state.authenticated && state.backend.connected) {
      await state.bootstrapSession();
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      state.authenticated ? RcRoutes.home : RcRoutes.login,
    );
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
        onTap: () => unawaited(_continue()),
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

  bool _busy = false;

  Future<void> _signIn() async {
    if (_busy) return;
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid work email.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final entered = await AppScope.of(context).requestSecureEmailSignIn(
        email: email,
        selectedRole: _role,
      );
      if (!mounted) return;
      if (entered) {
        Navigator.pushNamedAndRemoveUntil(context, RcRoutes.home, (_) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Secure sign-in link sent. Check your work email.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Secure sign-in is unavailable. Check connectivity.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _googleSignIn() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final entered =
          await AppScope.of(context).signInWithGoogle(selectedRole: _role);
      if (!mounted) return;
      if (entered) {
        Navigator.pushNamedAndRemoveUntil(context, RcRoutes.home, (_) => false);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google sign-in could not be started.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Positioned(
              top: -90,
              right: -70,
              child: _ComfortShape(
                size: 230,
                color: colorScheme.primaryContainer.withOpacity(.72),
              ),
            ),
            Positioned(
              bottom: -105,
              left: -80,
              child: _ComfortShape(
                size: 250,
                color: colorScheme.secondaryContainer.withOpacity(.6),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Card(
                    color: colorScheme.surface.withOpacity(.96),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: RcBrand(),
                          ),
                          const SizedBox(height: 28),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: RcStatusChip(
                              label: 'FIELD READY',
                              icon: Icons.wb_sunny_outlined,
                              tone: RcStatusTone.success,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Welcome back',
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(height: 9),
                          Text(
                            'Continue the verified evidence chain for every house, from scope to payment.',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 26),
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
                            onPressed: _busy ? null : _signIn,
                            icon: _busy
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                    ),
                                  )
                                : const Icon(Icons.login),
                            label: const Text('SIGN IN SECURELY'),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _busy ? null : _googleSignIn,
                            icon: const Icon(Icons.g_mobiledata, size: 25),
                            label: const Text('CONTINUE WITH GOOGLE'),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.tertiaryContainer,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(22),
                                topRight: Radius.circular(12),
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(22),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Icon(
                                  Icons.shield_outlined,
                                  color: colorScheme.onTertiaryContainer,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Role and parish access stay enforced across every connected workflow.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color:
                                              colorScheme.onTertiaryContainer,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComfortShape extends StatelessWidget {
  const _ComfortShape({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(110),
            topRight: Radius.circular(54),
            bottomLeft: Radius.circular(54),
            bottomRight: Radius.circular(110),
          ),
        ),
      ),
    );
  }
}
