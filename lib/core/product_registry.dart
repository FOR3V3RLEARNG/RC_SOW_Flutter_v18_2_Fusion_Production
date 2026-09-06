import '../models/app_models.dart';
import 'record_schemas.dart';

enum RcDashboardMetricKey {
  activeHouses,
  unreadMessages,
  attendance,
  fieldRequests,
  parishInputs,
  actionRequired,
  paymentQueue,
}

enum RcQuickActionKey {
  workProjection,
  constructionSchedule,
  crewAttendance,
  payment,
  materialRequest,
  consumables,
  dailyLog,
  monitoring,
  adminUsers,
  adminForms,
  adminTemplates,
  beneficiarySources,
}

class RcRoleExperience {
  const RcRoleExperience({
    required this.eyebrow,
    required this.subtitle,
    required this.heroTitle,
    required this.allowedRecordTypes,
    required this.metrics,
    required this.quickActions,
    this.communityReadOnly = false,
    this.showActionQueue = true,
    this.showPaymentDue = true,
    this.showPaymentReceived = false,
  });

  final String eyebrow;
  final String subtitle;
  final String heroTitle;
  final Set<String> allowedRecordTypes;
  final List<RcDashboardMetricKey> metrics;
  final List<RcQuickActionKey> quickActions;
  final bool communityReadOnly;
  final bool showActionQueue;
  final bool showPaymentDue;
  final bool showPaymentReceived;
}

abstract final class RcProductRegistry {
  static const Set<String> crewRecordTypes = {
    'crewAttendance',
    'materialRequest',
    'consumables',
    'dailyLog',
  };

  static const Set<String> inputRoleRecordTypes = {
    'siteVisit',
    'dailyLog',
    'documentChecklist',
    'monitoring',
  };

  static RcRoleExperience experience(UserProfile profile) {
    if (profile.isAdmin) {
      return const RcRoleExperience(
        eyebrow: 'National production command',
        subtitle:
            'Users, privileges, parishes, templates, alerts, production, completion and finance in one controlled view.',
        heroTitle: 'National production control',
        allowedRecordTypes: {},
        metrics: [
          RcDashboardMetricKey.activeHouses,
          RcDashboardMetricKey.unreadMessages,
          RcDashboardMetricKey.actionRequired,
          RcDashboardMetricKey.paymentQueue,
        ],
        quickActions: [
          RcQuickActionKey.adminUsers,
          RcQuickActionKey.adminForms,
          RcQuickActionKey.adminTemplates,
          RcQuickActionKey.beneficiarySources,
        ],
        showPaymentReceived: true,
      );
    }
    if (profile.isManagement) {
      return const RcRoleExperience(
        eyebrow: 'All-parish production command',
        subtitle:
            'All-parish houses, schedules, evidence, attendance, materials, close-out and payment queues.',
        heroTitle: 'All-parish production efficiency',
        allowedRecordTypes: {},
        metrics: [
          RcDashboardMetricKey.activeHouses,
          RcDashboardMetricKey.unreadMessages,
          RcDashboardMetricKey.actionRequired,
          RcDashboardMetricKey.paymentQueue,
        ],
        quickActions: [
          RcQuickActionKey.workProjection,
          RcQuickActionKey.constructionSchedule,
          RcQuickActionKey.crewAttendance,
          RcQuickActionKey.payment,
        ],
        showPaymentReceived: true,
      );
    }
    if (profile.isSiteSupervisor) {
      final scopeLabel = profile.canViewAllParishes
          ? 'Expanded site production'
          : '${profile.parish} site production';
      final scopeDescription = profile.canViewAllParishes
          ? 'Admin-granted multi-parish production access: houses, schedules, attendance, evidence, requests and required actions.'
          : 'Only ${profile.parish} production: active houses, schedules, attendance, evidence, requests and required actions.';
      return RcRoleExperience(
        eyebrow: scopeLabel,
        subtitle: scopeDescription,
        heroTitle: profile.canViewAllParishes
            ? 'Multi-parish production workspace'
            : '${profile.parish} production workspace',
        allowedRecordTypes: const {},
        metrics: const [
          RcDashboardMetricKey.activeHouses,
          RcDashboardMetricKey.unreadMessages,
          RcDashboardMetricKey.actionRequired,
          RcDashboardMetricKey.paymentQueue,
        ],
        quickActions: const [
          RcQuickActionKey.workProjection,
          RcQuickActionKey.constructionSchedule,
          RcQuickActionKey.crewAttendance,
          RcQuickActionKey.payment,
        ],
        showPaymentReceived: true,
      );
    }
    if (profile.isTechnicalAdmin || profile.isCommunityAdmin) {
      return RcRoleExperience(
        eyebrow: profile.isTechnicalAdmin
            ? '${profile.parish} technical input'
            : '${profile.parish} community operations',
        subtitle:
            'Your authorized inputs and active ${profile.parish} houses; Community Board is read-only with suggestion and event-request actions.',
        heroTitle: '${profile.parish} input workspace',
        allowedRecordTypes: inputRoleRecordTypes,
        metrics: const [
          RcDashboardMetricKey.activeHouses,
          RcDashboardMetricKey.unreadMessages,
          RcDashboardMetricKey.parishInputs,
          RcDashboardMetricKey.actionRequired,
        ],
        quickActions: const [
          RcQuickActionKey.dailyLog,
          RcQuickActionKey.monitoring,
        ],
        communityReadOnly: true,
        showPaymentDue: false,
        showPaymentReceived: false,
      );
    }
    if (profile.isCrew) {
      return const RcRoleExperience(
        eyebrow: 'Assigned field work',
        subtitle:
            'Assigned houses, daily attendance, work evidence, material/consumable requests and messages.',
        heroTitle: 'Today’s assigned field work',
        allowedRecordTypes: crewRecordTypes,
        metrics: [
          RcDashboardMetricKey.activeHouses,
          RcDashboardMetricKey.unreadMessages,
          RcDashboardMetricKey.attendance,
          RcDashboardMetricKey.fieldRequests,
        ],
        quickActions: [
          RcQuickActionKey.crewAttendance,
          RcQuickActionKey.materialRequest,
          RcQuickActionKey.consumables,
          RcQuickActionKey.dailyLog,
        ],
        communityReadOnly: true,
        showActionQueue: false,
        showPaymentDue: false,
        showPaymentReceived: false,
      );
    }
    return const RcRoleExperience(
      eyebrow: 'RC SOW operations',
      subtitle: 'House-centred production management.',
      heroTitle: 'Production workspace',
      allowedRecordTypes: inputRoleRecordTypes,
      metrics: [
        RcDashboardMetricKey.activeHouses,
        RcDashboardMetricKey.unreadMessages,
      ],
      quickActions: [],
      showPaymentDue: false,
    );
  }

  static List<RcRecordSchema> visibleSchemas(
    UserProfile profile, {
    List<RcRecordSchema> customSchemas = const [],
  }) {
    final all = <RcRecordSchema>[...RcRecordSchemas.schemas, ...customSchemas];
    final allowed = experience(profile).allowedRecordTypes;
    if (allowed.isEmpty) return all;
    return all.where((schema) => allowed.contains(schema.eventType)).toList();
  }

  static RcRecordSchema resolveSchema(
    String eventType, {
    List<RcRecordSchema> customSchemas = const [],
  }) {
    for (final schema in customSchemas) {
      if (schema.eventType == eventType) return schema;
    }
    return RcRecordSchemas.byEventType(eventType);
  }

  static bool isCustomEventType(String value) => value.startsWith('custom:');
}
