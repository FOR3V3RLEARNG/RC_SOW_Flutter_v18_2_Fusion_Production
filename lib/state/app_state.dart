import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_constants.dart';
import '../models/app_models.dart';
import '../services/rc_sow_repository.dart';

class AppState extends ChangeNotifier {
  AppState(this.repository);

  final RcSowRepository repository;

  UserProfile? profile;
  bool loading = true;
  bool highContrast = false;
  bool reduceMotion = false;
  bool haptics = true;
  bool snapDrawing = true;
  bool showGrid = true;
  bool offlineMode = false;
  bool compactDensity = false;
  bool showPaymentReceived = true;
  bool showPaymentDue = true;
  String measurementUnit = 'Feet';
  ThemeMode themeMode = ThemeMode.system;
  RcDesignDna designDna = RcDesignDna.redCrossClassic;
  int selectedTab = 0;
  String? lastAuthDiagnostic;
  Map<String, dynamic> remoteUiConfig = const {};
  String presenceStatus = 'active';

  String uiText(String key, String fallback) {
    final value = '${remoteUiConfig[key] ?? ''}'.trim();
    return value.isEmpty ? fallback : value;
  }

  int get controlColumns {
    final raw = remoteUiConfig['controlColumns'];
    final value = raw is num ? raw.toInt() : int.tryParse('$raw') ?? 2;
    return value.clamp(1, 3);
  }

  String get controlDefaultView {
    final value = '${remoteUiConfig['controlDefaultView'] ?? 'houses'}';
    return value == 'modules' ? 'modules' : 'houses';
  }

  List<String> get controlModuleOrder =>
      (remoteUiConfig['controlModuleOrder'] as List? ?? const [])
          .map((value) => '$value')
          .where((value) => value.isNotEmpty)
          .toList();

  bool _authSyncInFlight = false;
  bool _authSyncQueued = false;
  Timer? _presenceTimer;

  bool get signedIn => Supabase.instance.client.auth.currentSession != null;

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    highContrast = prefs.getBool('highContrast') ?? false;
    reduceMotion = prefs.getBool('reduceMotion') ?? false;
    haptics = prefs.getBool('haptics') ?? true;
    snapDrawing = prefs.getBool('snapDrawing') ?? true;
    showGrid = prefs.getBool('showGrid') ?? true;
    offlineMode = prefs.getBool('offlineMode') ?? false;
    compactDensity = prefs.getBool('compactDensity') ?? false;
    showPaymentReceived = prefs.getBool('showPaymentReceived') ?? true;
    showPaymentDue = prefs.getBool('showPaymentDue') ?? true;
    measurementUnit = prefs.getString('measurementUnit') ?? 'Feet';
    themeMode = _themeModeFromString(prefs.getString('themeMode'));
    designDna = _dnaFromString(prefs.getString('designDna'));
    await synchronizeAuthSession(reason: 'bootstrap');
    loading = false;
    notifyListeners();
  }

  Future<void> synchronizeAuthSession({String reason = 'auth-event'}) async {
    if (_authSyncInFlight) {
      _authSyncQueued = true;
      return;
    }
    do {
      _authSyncQueued = false;
      _authSyncInFlight = true;
      try {
        profile = await repository.currentProfile();
        if (profile != null) {
          presenceStatus = await repository.myPresenceStatus();
        }
        await _loadRemoteUiConfig();
        await _submitPendingRoleRequestIfNeeded();
        lastAuthDiagnostic = signedIn
            ? 'Session synchronized ($reason)'
            : 'Signed out ($reason)';
      } catch (error) {
        lastAuthDiagnostic =
            'Session sync failed ($reason): ${error.runtimeType}';
        if (!signedIn) profile = null;
      } finally {
        _authSyncInFlight = false;
        _ensurePresenceHeartbeat();
        notifyListeners();
      }
    } while (_authSyncQueued);
  }

  Future<void> refreshUiConfig() async {
    await _loadRemoteUiConfig();
    notifyListeners();
  }

  Future<void> _loadRemoteUiConfig() async {
    final current = profile;
    if (current == null) {
      remoteUiConfig = const {};
      return;
    }
    try {
      remoteUiConfig = await repository.uiConfig(current);
    } catch (_) {
      remoteUiConfig = const {};
    }
  }

  Future<void> refreshProfile() =>
      synchronizeAuthSession(reason: 'manual-refresh');

  Future<void> _submitPendingRoleRequestIfNeeded() async {
    if (!signedIn || profile == null || profile!.approved) return;
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('pendingRequestedRole');
    final parish = prefs.getString('pendingRequestedParish');
    if (role == null || role.isEmpty || parish == null || parish.isEmpty) {
      return;
    }
    try {
      final user = Supabase.instance.client.auth.currentUser;
      await Supabase.instance.client.rpc(
        'request_role_assignment',
        params: {
          'p_requested_role': role,
          'p_requested_parish': parish,
          'p_full_name':
              user?.userMetadata?['full_name'] ??
              user?.email?.split('@').first ??
              'RC SOW user',
        },
      );
      await prefs.remove('pendingRequestedRole');
      await prefs.remove('pendingRequestedParish');
      profile = await repository.currentProfile();
    } catch (_) {
      // Retain request for retry after connectivity/auth recovery.
    }
  }

  void _ensurePresenceHeartbeat() {
    final current = profile;
    if (!signedIn ||
        current == null ||
        !current.approved ||
        !current.active) {
      _presenceTimer?.cancel();
      _presenceTimer = null;
      return;
    }
    if (_presenceTimer != null) return;
    unawaited(repository.touchPresence());
    _presenceTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (signedIn) unawaited(repository.touchPresence());
    });
  }

  Future<void> setPresenceStatus(String value) async {
    final normalized = value.toLowerCase();
    if (!const {'active', 'busy', 'invisible'}.contains(normalized)) {
      return;
    }
    await repository.setPresenceStatus(normalized);
    presenceStatus = normalized;
    await repository.touchPresence();
    notifyListeners();
  }

  void selectTab(int value) {
    if (value < 0 || value > 4 || selectedTab == value) return;
    selectedTab = value;
    feedback();
    notifyListeners();
  }

  Future<void> feedback({bool strong = false}) async {
    if (!haptics) return;
    if (strong) {
      await HapticFeedback.mediumImpact();
    } else {
      await HapticFeedback.selectionClick();
    }
  }

  Future<void> setSetting(String key, Object value) async {
    final prefs = await SharedPreferences.getInstance();
    switch (key) {
      case 'highContrast':
        highContrast = value as bool;
        await prefs.setBool(key, highContrast);
      case 'reduceMotion':
        reduceMotion = value as bool;
        await prefs.setBool(key, reduceMotion);
      case 'haptics':
        haptics = value as bool;
        await prefs.setBool(key, haptics);
      case 'snapDrawing':
        snapDrawing = value as bool;
        await prefs.setBool(key, snapDrawing);
      case 'showGrid':
        showGrid = value as bool;
        await prefs.setBool(key, showGrid);
      case 'offlineMode':
        offlineMode = value as bool;
        await prefs.setBool(key, offlineMode);
      case 'compactDensity':
        compactDensity = value as bool;
        await prefs.setBool(key, compactDensity);
      case 'showPaymentReceived':
        showPaymentReceived = value as bool;
        await prefs.setBool(key, showPaymentReceived);
      case 'showPaymentDue':
        showPaymentDue = value as bool;
        await prefs.setBool(key, showPaymentDue);
      case 'measurementUnit':
        measurementUnit = value as String;
        await prefs.setString(key, measurementUnit);
      case 'themeMode':
        themeMode = value as ThemeMode;
        await prefs.setString(key, themeMode.name);
      case 'designDna':
        designDna = value as RcDesignDna;
        await prefs.setString(key, designDna.name);
    }
    notifyListeners();
  }

  ThemeMode _themeModeFromString(String? value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  @override
  void dispose() {
    _presenceTimer?.cancel();
    super.dispose();
  }

  RcDesignDna _dnaFromString(String? value) => RcDesignDna.values.firstWhere(
    (dna) => dna.name == value,
    orElse: () => RcDesignDna.redCrossClassic,
  );
}
