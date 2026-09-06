import 'package:flutter/material.dart';

abstract final class RcApp {
  static const name = 'RC SOW';
  static const versionLabel = '20.4.1 Fusion Production Bugfix';

  static const parishes = <String>[
    'Hanover',
    'Westmoreland',
    'St. James',
    'Trelawny',
    'St. Elizabeth',
    'St. Ann',
    'Clarendon',
    'Manchester',
    'St. Catherine',
    'Kingston',
    'St. Andrew',
    'St. Mary',
    'Portland',
    'St. Thomas',
  ];

  static const roles = <String>[
    'Admin',
    'Regional Supervisor',
    'Construction Specialist',
    'Construction Engineer',
    'Site Supervisor',
    'Technical Admin',
    'Community Admin',
    'Carpenter',
    'Worker',
    'Apprentice',
  ];

  static const managementRoles = <String>{
    'Admin',
    'Regional Supervisor',
    'Construction Specialist',
    'Construction Engineer',
  };

  static const crewRoles = <String>{'Carpenter', 'Worker', 'Apprentice'};
}

enum RcDesignDna {
  redCrossClassic,
  oceanBlue,
  forestGreen,
  sunsetOrange,
  midnightDark,
  islandTeal,
  foruiMinimal,
  shadcnSaas,
  materialExpressive,
}

extension RcDesignDnaX on RcDesignDna {
  String get label => switch (this) {
        RcDesignDna.redCrossClassic => 'Red Cross Classic',
        RcDesignDna.oceanBlue => 'Ocean Blue',
        RcDesignDna.forestGreen => 'Forest Green',
        RcDesignDna.sunsetOrange => 'Sunset Orange',
        RcDesignDna.midnightDark => 'Midnight Dark',
        RcDesignDna.islandTeal => 'Island Teal',
        RcDesignDna.foruiMinimal => 'Forui-inspired Minimal',
        RcDesignDna.shadcnSaas => 'shadcn-inspired SaaS',
        RcDesignDna.materialExpressive => 'Material 3 Expressive',
      };

  String get subtitle => switch (this) {
        RcDesignDna.redCrossClassic => 'Trusted • Bold • Purposeful',
        RcDesignDna.oceanBlue => 'Calm • Focused • Reliable',
        RcDesignDna.forestGreen => 'Growth • Balance • Harmony',
        RcDesignDna.sunsetOrange => 'Energetic • Warm • Inviting',
        RcDesignDna.midnightDark => 'Modern • Sleek • Powerful',
        RcDesignDna.islandTeal => 'Caribbean • Fresh • Vibrant',
        RcDesignDna.foruiMinimal => 'Quiet • Precise • Field-first',
        RcDesignDna.shadcnSaas => 'Crisp • Structured • Operational',
        RcDesignDna.materialExpressive => 'Expressive • Spatial • Accessible',
      };

  Color get seed => switch (this) {
        RcDesignDna.redCrossClassic => const Color(0xFFC91F2C),
        RcDesignDna.oceanBlue => const Color(0xFF174A7E),
        RcDesignDna.forestGreen => const Color(0xFF24633D),
        RcDesignDna.sunsetOrange => const Color(0xFFF05A16),
        RcDesignDna.midnightDark => const Color(0xFF2E7CF6),
        RcDesignDna.islandTeal => const Color(0xFF078D91),
        RcDesignDna.foruiMinimal => const Color(0xFF30343B),
        RcDesignDna.shadcnSaas => const Color(0xFF18181B),
        RcDesignDna.materialExpressive => const Color(0xFFC91F2C),
      };

  bool get prefersDark => this == RcDesignDna.midnightDark;
}
