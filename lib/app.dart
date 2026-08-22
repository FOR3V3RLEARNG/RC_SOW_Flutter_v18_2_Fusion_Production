import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/design_tokens.dart';
import 'features/auth/login_screen.dart';
import 'features/shell/app_shell.dart';
import 'features/splash/premium_splash.dart';
import 'services/rc_sow_repository.dart';
import 'state/app_state.dart';

class RcSowApp extends StatefulWidget {
  const RcSowApp({super.key});

  @override
  State<RcSowApp> createState() => _RcSowAppState();
}

class _RcSowAppState extends State<RcSowApp> {
  late final AppState state;
  bool splashDone = false;
  StreamSubscription<AuthState>? authSubscription;

  @override
  void initState() {
    super.initState();
    state = AppState(RcSowRepository(Supabase.instance.client));
    state.addListener(_redraw);
    state.bootstrap();
    authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      _,
    ) {
      state.refreshProfile();
    });
  }

  void _redraw() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    authSubscription?.cancel();
    state.removeListener(_redraw);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RC SOW',
      debugShowCheckedModeBanner: false,
      theme: buildRcTheme(
        highContrast: state.highContrast,
        designStyle: state.designStyle,
      ),
      home: !splashDone
          ? PremiumSplash(
              onComplete: () => setState(() => splashDone = true),
              reduceMotion: state.reduceMotion,
            )
          : state.loading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : Supabase.instance.client.auth.currentSession == null
          ? LoginScreen(state: state)
          : AppShell(state: state),
    );
  }
}
