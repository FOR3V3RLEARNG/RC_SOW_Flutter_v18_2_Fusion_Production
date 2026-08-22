import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/design_tokens.dart';
import '../models/app_models.dart';
import '../services/rc_sow_repository.dart';

class AppState extends ChangeNotifier {
  AppState(this.repository);

  final RcSowRepository repository;

  UserProfile? profile;
  bool loading = true;
  ThemeMode themeMode = ThemeMode.system;
  bool highContrast = false;
  RcDesignStyle designStyle = RcDesignStyle.materialExpressive;
  bool reduceMotion = false;
  bool haptics = true;
  bool snapDrawing = true;
  bool showGrid = true;
  String measurementUnit = 'Feet';
  int selectedTab = 0;

  Future<void>? _authSync;

  bool get signedIn => Supabase.instance.client.auth.currentSession != null;

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    themeMode = _themeModeFromString(prefs.getString('themeMode'));
    highContrast = prefs.getBool('highContrast') ?? false;
    final style = prefs.getString('designStyle');
    designStyle = RcDesignStyle.values.firstWhere(
      (value) => value.name == style,
      orElse: () => RcDesignStyle.materialExpressive,
    );
    reduceMotion = prefs.getBool('reduceMotion') ?? false;
    haptics = prefs.getBool('haptics') ?? true;
    snapDrawing = prefs.getBool('snapDrawing') ?? true;
    showGrid = prefs.getBool('showGrid') ?? true;
    measurementUnit = prefs.getString('measurementUnit') ?? 'Feet';
    await synchronizeAuthSession(reason: 'bootstrap');
    loading = false;
    notifyListeners();
  }

  Future<void> refreshProfile() =>
      synchronizeAuthSession(reason: 'manual-refresh');

  Future<void> synchronizeAuthSession({required String reason}) {
    final running = _authSync;
    if (running != null) {
      return running;
    }
    final next = _performAuthSync();
    _authSync = next;
    return next.whenComplete(() {
      if (identical(_authSync, next)) {
        _authSync = null;
      }
    });
  }

  Future<void> _performAuthSync() async {
    if (!signedIn) {
      profile = null;
      notifyListeners();
      return;
    }

    try {
      profile = await repository.currentProfile();
      await _handlePendingRoleRequest();
      await repository.touchPresence();
    } catch (_) {
      // Authentication/profile reads are retriable. Preserve the current
      // session and let the UI expose refresh instead of forcing sign-out.
    }
    notifyListeners();
  }

  Future<void> _handlePendingRoleRequest() async {
    final prefs = await SharedPreferences.getInstance();
    if (profile?.approved == true) {
      await prefs.remove('pendingRequestedRole');
      await prefs.remove('pendingRequestedParish');
      return;
    }
    if (!signedIn || profile == null) {
      return;
    }

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
      // Keep the staged request so the next sync can retry it safely.
    }
  }

  void selectTab(int value) {
    selectedTab = value.clamp(0, 4).toInt();
    notifyListeners();
  }

  Future<void> setSetting(String key, Object value) async {
    final prefs = await SharedPreferences.getInstance();
    switch (key) {
      case 'themeMode':
        themeMode = value as ThemeMode;
        await prefs.setString(key, themeMode.name);
        break;
      case 'designStyle':
        designStyle = value as RcDesignStyle;
        await prefs.setString(key, designStyle.name);
        break;
      case 'highContrast':
        highContrast = value as bool;
        await prefs.setBool(key, highContrast);
        break;
      case 'reduceMotion':
        reduceMotion = value as bool;
        await prefs.setBool(key, reduceMotion);
        break;
      case 'haptics':
        haptics = value as bool;
        await prefs.setBool(key, haptics);
        break;
      case 'snapDrawing':
        snapDrawing = value as bool;
        await prefs.setBool(key, snapDrawing);
        break;
      case 'showGrid':
        showGrid = value as bool;
        await prefs.setBool(key, showGrid);
        break;
      case 'measurementUnit':
        measurementUnit = value as String;
        await prefs.setString(key, measurementUnit);
        break;
      default:
        throw ArgumentError.value(key, 'key', 'Unknown RC SOW setting');
    }
    notifyListeners();
  }

  ThemeMode _themeModeFromString(String? value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}
