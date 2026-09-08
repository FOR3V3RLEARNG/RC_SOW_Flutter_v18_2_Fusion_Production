import 'package:flutter/material.dart';

class RcUiVisuals extends ThemeExtension<RcUiVisuals> {
  const RcUiVisuals({
    this.expressiveness = .78,
    this.depth = .72,
    this.surfaceFinish = 'suede',
    this.iconPack = 'rounded',
    this.iconShape = 'squircle',
    this.accentMood = 'red',
    this.accent = const Color(0xFFC91F2C),
  });

  final double expressiveness;
  final double depth;
  final String surfaceFinish;
  final String iconPack;
  final String iconShape;
  final String accentMood;
  final Color accent;

  static Color accentFor(String mood, Color fallback) => switch (mood) {
    'red' => const Color(0xFFC91F2C),
    'ocean' => const Color(0xFF1769E0),
    'forest' => const Color(0xFF16805C),
    'violet' => const Color(0xFF7655D8),
    'gold' => const Color(0xFFB57700),
    'teal' => const Color(0xFF087E8B),
    _ => fallback,
  };

  @override
  RcUiVisuals copyWith({
    double? expressiveness,
    double? depth,
    String? surfaceFinish,
    String? iconPack,
    String? iconShape,
    String? accentMood,
    Color? accent,
  }) => RcUiVisuals(
    expressiveness: expressiveness ?? this.expressiveness,
    depth: depth ?? this.depth,
    surfaceFinish: surfaceFinish ?? this.surfaceFinish,
    iconPack: iconPack ?? this.iconPack,
    iconShape: iconShape ?? this.iconShape,
    accentMood: accentMood ?? this.accentMood,
    accent: accent ?? this.accent,
  );

  @override
  RcUiVisuals lerp(ThemeExtension<RcUiVisuals>? other, double t) {
    if (other is! RcUiVisuals) return this;
    return RcUiVisuals(
      expressiveness:
          expressiveness + (other.expressiveness - expressiveness) * t,
      depth: depth + (other.depth - depth) * t,
      surfaceFinish: t < .5 ? surfaceFinish : other.surfaceFinish,
      iconPack: t < .5 ? iconPack : other.iconPack,
      iconShape: t < .5 ? iconShape : other.iconShape,
      accentMood: t < .5 ? accentMood : other.accentMood,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
    );
  }
}

abstract final class RcIconCatalog {
  static const Map<String, IconData> icons = {
    'dashboard': Icons.space_dashboard_rounded,
    'home': Icons.home_repair_service_rounded,
    'scope': Icons.architecture_rounded,
    'control': Icons.construction_rounded,
    'houses': Icons.holiday_village_rounded,
    'community': Icons.groups_2_rounded,
    'map': Icons.map_rounded,
    'tracker': Icons.radar_rounded,
    'messages': Icons.forum_rounded,
    'settings': Icons.tune_rounded,
    'site_visit': Icons.location_on_rounded,
    'daily_log': Icons.menu_book_rounded,
    'materials': Icons.inventory_2_rounded,
    'consumables': Icons.handyman_rounded,
    'monitoring': Icons.fact_check_rounded,
    'checklist': Icons.task_alt_rounded,
    'completion': Icons.verified_rounded,
    'payment': Icons.payments_rounded,
    'work_plan': Icons.event_note_rounded,
    'attendance': Icons.how_to_reg_rounded,
    'boq': Icons.receipt_long_rounded,
    'inventory': Icons.warehouse_rounded,
    'media': Icons.play_circle_fill_rounded,
    'live': Icons.sensors_rounded,
    'calendar': Icons.calendar_month_rounded,
    'camera': Icons.photo_camera_rounded,
    'document': Icons.description_rounded,
    'link': Icons.link_rounded,
    'safety': Icons.health_and_safety_rounded,
    'tools': Icons.home_repair_service_rounded,
    'bolt': Icons.bolt_rounded,
    'star': Icons.auto_awesome_rounded,
    'shield': Icons.shield_rounded,
    'timeline': Icons.view_timeline_rounded,
    'pin': Icons.push_pin_rounded,
    'schedule': Icons.calendar_view_week_rounded,
    'people': Icons.groups_rounded,
    'signature': Icons.draw_rounded,
    'photo': Icons.photo_library_rounded,
    'clipboard': Icons.assignment_rounded,
    'truck': Icons.local_shipping_rounded,
  };

  static const Map<String, String> coreSlots = {
    'nav.dashboard': 'Dashboard',
    'nav.scope': 'Scope',
    'nav.control': 'Control',
    'nav.houses': 'Houses',
    'nav.community': 'Community',
    'nav.map': 'Map',
    'nav.tracker': 'Live Tracker',
    'header.messages': 'Notifications',
    'header.settings': 'Settings',
  };

  static const Map<String, Map<String, String>> packs = {
    'rounded': {
      'nav.dashboard': 'dashboard',
      'nav.scope': 'scope',
      'nav.control': 'control',
      'nav.houses': 'houses',
      'nav.community': 'community',
      'nav.map': 'map',
      'nav.tracker': 'tracker',
      'header.messages': 'messages',
      'header.settings': 'settings',
      'module.siteVisit': 'site_visit',
      'module.dailyLog': 'daily_log',
      'module.materialRequest': 'materials',
      'module.consumables': 'consumables',
      'module.monitoring': 'monitoring',
      'module.documentChecklist': 'checklist',
      'module.notice': 'completion',
      'module.payment': 'payment',
      'module.workPlan': 'work_plan',
      'module.crewAttendance': 'attendance',
      'module.inventory': 'inventory',
    },
    'builder': {
      'nav.dashboard': 'home',
      'nav.scope': 'scope',
      'nav.control': 'tools',
      'nav.houses': 'houses',
      'nav.community': 'community',
      'nav.map': 'pin',
      'nav.tracker': 'timeline',
      'header.messages': 'messages',
      'header.settings': 'settings',
      'module.siteVisit': 'pin',
      'module.dailyLog': 'document',
      'module.materialRequest': 'truck',
      'module.consumables': 'tools',
      'module.monitoring': 'shield',
      'module.documentChecklist': 'clipboard',
      'module.notice': 'completion',
      'module.payment': 'payment',
      'module.workPlan': 'schedule',
      'module.crewAttendance': 'people',
      'module.inventory': 'inventory',
    },
    'bold': {
      'nav.dashboard': 'bolt',
      'nav.scope': 'star',
      'nav.control': 'tools',
      'nav.houses': 'home',
      'nav.community': 'community',
      'nav.map': 'map',
      'nav.tracker': 'live',
      'header.messages': 'messages',
      'header.settings': 'settings',
      'module.siteVisit': 'site_visit',
      'module.dailyLog': 'timeline',
      'module.materialRequest': 'materials',
      'module.consumables': 'tools',
      'module.monitoring': 'safety',
      'module.documentChecklist': 'checklist',
      'module.notice': 'star',
      'module.payment': 'payment',
      'module.workPlan': 'schedule',
      'module.crewAttendance': 'people',
      'module.inventory': 'inventory',
    },
  };

  static List<String> get availableNames => icons.keys.toList()..sort();

  static IconData resolveName(String? name, IconData fallback) =>
      icons[name] ?? fallback;

  static IconData resolveSlot({
    required String slot,
    required String pack,
    required Map<String, String> overrides,
    required IconData fallback,
  }) {
    final override = overrides[slot];
    if (override != null && override.isNotEmpty) {
      return resolveName(override, fallback);
    }
    final preset = packs[pack]?[slot];
    return resolveName(preset, fallback);
  }
}
