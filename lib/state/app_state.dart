import 'package:flutter/foundation.dart';
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
  bool highContrast = false;
  RcDesignStyle designStyle = RcDesignStyle.materialExpressive;
  bool reduceMotion = false;
  bool haptics = true;
  bool snapDrawing = true;
  bool showGrid = true;
  String measurementUnit = 'Feet';
  int selectedTab = 0;

  bool get signedIn => Supabase.instance.client.auth.currentSession != null;

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    highContrast = prefs.getBool('highContrast') ?? false;
    final style = prefs.getString('designStyle');
    designStyle = RcDesignStyle.values.firstWhere(
      (e) => e.name == style,
      orElse: () => RcDesignStyle.materialExpressive,
    );
    reduceMotion = prefs.getBool('reduceMotion') ?? false;
    haptics = prefs.getBool('haptics') ?? true;
    snapDrawing = prefs.getBool('snapDrawing') ?? true;
    showGrid = prefs.getBool('showGrid') ?? true;
    measurementUnit = prefs.getString('measurementUnit') ?? 'Feet';
    await refreshProfile();
    loading = false;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    profile = await repository.currentProfile();
    await _submitPendingRoleRequestIfNeeded();
    notifyListeners();
  }

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
      // Keep the staged request so a later profile refresh can retry safely.
    }
  }

  void selectTab(int value) {
    selectedTab = value;
    notifyListeners();
  }

  Future<void> setSetting(String key, Object value) async {
    final prefs = await SharedPreferences.getInstance();
    switch (key) {
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
    }
    notifyListeners();
  }
}
