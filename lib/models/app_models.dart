import '../core/app_constants.dart';

class UserProfile {
  const UserProfile({
    required this.userId,
    required this.email,
    required this.role,
    required this.parish,
    required this.approved,
    required this.privileges,
    this.fullName,
    this.active = true,
    this.registrationStatus = 'approved',
  });

  final String userId;
  final String email;
  final String role;
  final String parish;
  final bool approved;
  final bool active;
  final String registrationStatus;
  final Map<String, dynamic> privileges;
  final String? fullName;

  bool get isAdmin => role == 'Admin';
  bool get isManagement => RcApp.managementRoles.contains(role);
  bool get isCrew => RcApp.crewRoles.contains(role);
  bool get isCarpenter => role == 'Carpenter';
  bool get isSiteSupervisor => role == 'Site Supervisor';
  bool get isTechnicalAdmin => role == 'Technical Admin';
  bool get isCommunityAdmin => role == 'Community Admin';
  bool get isLimitedParishRole => isSiteSupervisor || isTechnicalAdmin || isCommunityAdmin || isCrew;

  bool hasPrivilege(String key) => privileges[key] == true;

  bool get canViewAllParishes => hasPrivilege('viewAllParishes');
  bool get canViewAdmin => isAdmin && hasPrivilege('viewAdmin');
  bool get canManageUsers => isAdmin && hasPrivilege('manageUsers');
  bool get canManagePrivileges => isAdmin && hasPrivilege('managePrivileges');
  bool get canApproveScope => hasPrivilege('approveScope');
  bool get canExportData => hasPrivilege('exportData');
  bool get canEditProduction => hasPrivilege('editControl');
  bool get canCreateCommunityEvent => isAdmin && hasPrivilege('manageCommunity');
  bool get canModerateCommunity => isAdmin && hasPrivilege('manageCommunity');

  String get displayName => (fullName?.trim().isNotEmpty ?? false)
      ? fullName!.trim()
      : email.split('@').first;

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        userId: '${map['user_id'] ?? ''}',
        email: '${map['email'] ?? ''}',
        role: '${map['role'] ?? ''}',
        parish: '${map['parish'] ?? ''}',
        approved: map['approved'] == true,
        active: map['active'] != false,
        registrationStatus: '${map['registration_status'] ?? 'approved'}',
        privileges: Map<String, dynamic>.from(map['privileges'] as Map? ?? const {}),
        fullName: map['full_name'] as String?,
      );
}

class BeneficiaryRecord {
  const BeneficiaryRecord({
    required this.houseCode,
    required this.beneficiaryName,
    required this.parish,
    required this.cluster,
    this.phone = '',
    this.gps = '',
    this.latitude,
    this.longitude,
    this.mapsUrl,
    this.roofLength,
    this.roofWidth,
    this.wallHeight,
    this.roofType,
  });

  final String houseCode;
  final String beneficiaryName;
  final String parish;
  final String cluster;
  final String phone;
  final String gps;
  final double? latitude;
  final double? longitude;
  final String? mapsUrl;
  final double? roofLength;
  final double? roofWidth;
  final double? wallHeight;
  final String? roofType;

  bool get hasCoordinates => latitude != null && longitude != null;

  factory BeneficiaryRecord.fromMap(Map<String, dynamic> map) {
    final source = Map<String, dynamic>.from(map['source_payload'] as Map? ?? const {});
    double? d(Object? value) => value is num ? value.toDouble() : double.tryParse('$value');
    return BeneficiaryRecord(
      houseCode: '${map['house_code'] ?? ''}',
      beneficiaryName: '${map['beneficiary_name'] ?? ''}',
      parish: '${map['parish'] ?? ''}',
      cluster: '${map['cluster'] ?? ''}',
      phone: '${map['phone'] ?? ''}',
      gps: '${map['gps'] ?? ''}',
      latitude: d(map['latitude']),
      longitude: d(map['longitude']),
      mapsUrl: map['maps_url'] as String?,
      roofLength: d(source['roof_length'] ?? source['roofLength']),
      roofWidth: d(source['roof_width'] ?? source['roofWidth']),
      wallHeight: d(source['wall_height'] ?? source['wallHeight']),
      roofType: (source['roof_type'] ?? source['roofType'])?.toString(),
    );
  }
}

class HouseRecord {
  const HouseRecord({
    required this.code,
    required this.beneficiary,
    required this.parish,
    required this.cluster,
    required this.stage,
    required this.progress,
    this.assignedCrew = const [],
    this.updatedAt,
  });

  final String code;
  final String beneficiary;
  final String parish;
  final String cluster;
  final String stage;
  final int progress;
  final List<String> assignedCrew;
  final DateTime? updatedAt;

  factory HouseRecord.fromEvent(Map<String, dynamic> row) {
    final item = Map<String, dynamic>.from(row['item'] as Map? ?? const {});
    return HouseRecord(
      code: '${row['house_code'] ?? item['houseCode'] ?? item['code'] ?? '—'}',
      beneficiary: '${item['beneficiary'] ?? item['beneficiaryName'] ?? '—'}',
      parish: '${row['parish'] ?? item['parish'] ?? ''}',
      cluster: '${item['cluster'] ?? ''}',
      stage: '${item['stage'] ?? item['status'] ?? 'Not specified'}',
      progress: ((item['progress'] as num?)?.round() ?? 0).clamp(0, 100).toInt(),
      assignedCrew: (item['assignedCrew'] as List? ?? const []).map((e) => '$e').toList(),
      updatedAt: DateTime.tryParse('${row['updated_at'] ?? row['created_at'] ?? ''}'),
    );
  }
}

class MessageRecord {
  const MessageRecord({
    required this.id,
    required this.sender,
    required this.senderEmail,
    required this.senderRole,
    required this.subject,
    required this.body,
    required this.createdAt,
    required this.unread,
    this.houseCode,
    this.priority = 'Normal',
    this.recipients = const [],
  });

  final String id;
  final String sender;
  final String senderEmail;
  final String senderRole;
  final String subject;
  final String body;
  final DateTime createdAt;
  final bool unread;
  final String? houseCode;
  final String priority;
  final List<Map<String, dynamic>> recipients;

  factory MessageRecord.fromEvent(Map<String, dynamic> row, String email) {
    final item = Map<String, dynamic>.from(row['item'] as Map? ?? const {});
    final readBy = (item['readBy'] as List?)?.map((e) => '$e').toSet() ?? <String>{};
    final recipientRaw = row['recipients'] as List? ?? item['recipients'] as List? ?? const [];
    return MessageRecord(
      id: '${row['item_id'] ?? row['id']}',
      sender: '${item['senderName'] ?? row['created_by_email'] ?? 'RC SOW'}',
      senderEmail: '${item['fromEmail'] ?? row['created_by_email'] ?? ''}',
      senderRole: '${item['fromRole'] ?? ''}',
      subject: '${item['subject'] ?? item['title'] ?? 'Message'}',
      body: '${item['body'] ?? item['message'] ?? ''}',
      createdAt: DateTime.tryParse('${row['created_at'] ?? ''}') ?? DateTime.now(),
      unread: !readBy.contains(email),
      houseCode: (row['house_code'] ?? item['houseCode'])?.toString(),
      priority: '${item['priority'] ?? 'Normal'}',
      recipients: recipientRaw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(),
    );
  }
}

class ManagedUser {
  const ManagedUser({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.role,
    required this.parish,
    required this.approved,
    required this.active,
    required this.registrationStatus,
    required this.privileges,
    this.lastSeen,
  });

  final String userId;
  final String email;
  final String fullName;
  final String role;
  final String parish;
  final bool approved;
  final bool active;
  final String registrationStatus;
  final Map<String, dynamic> privileges;
  final DateTime? lastSeen;

  factory ManagedUser.fromMap(Map<String, dynamic> map) => ManagedUser(
        userId: '${map['user_id'] ?? ''}',
        email: '${map['email'] ?? ''}',
        fullName: '${map['full_name'] ?? ''}',
        role: '${map['role'] ?? ''}',
        parish: '${map['parish'] ?? ''}',
        approved: map['approved'] == true,
        active: map['active'] == true,
        registrationStatus: '${map['registration_status'] ?? ''}',
        privileges: Map<String, dynamic>.from(map['privileges'] as Map? ?? const {}),
        lastSeen: DateTime.tryParse('${map['last_seen'] ?? ''}'),
      );
}

class RoofMeasurements {
  const RoofMeasurements({
    required this.widthFt,
    required this.lengthFt,
    required this.wallHeightFt,
    required this.pitchRisePer12,
  });

  final double widthFt;
  final double lengthFt;
  final double wallHeightFt;
  final double pitchRisePer12;

  double get ridgeRiseFt => widthFt / 2 * pitchRisePer12 / 12;
  double get ridgeHeightFt => wallHeightFt + ridgeRiseFt;
  double get halfSpanFt => widthFt / 2;
  double get rafterLengthFt => (halfSpanFt * halfSpanFt + ridgeRiseFt * ridgeRiseFt).sqrt();
}

extension _NumSqrt on double {
  double sqrt() {
    if (this <= 0) return 0;
    var x = this;
    for (var i = 0; i < 16; i++) {
      x = 0.5 * (x + this / x);
    }
    return x;
  }
}

class ProductionRecord {
  const ProductionRecord({
    required this.id,
    required this.eventType,
    required this.houseCode,
    required this.parish,
    required this.status,
    required this.title,
    required this.summary,
    required this.updatedAt,
    required this.item,
  });

  final String id;
  final String eventType;
  final String houseCode;
  final String parish;
  final String status;
  final String title;
  final String summary;
  final DateTime updatedAt;
  final Map<String, dynamic> item;

  bool get isClosed => const {'Completed', 'Approved', 'Paid', 'Closed'}.contains(status);
  bool get needsAttention => const {'Rejected', 'Blocked', 'Overdue', 'Critical', 'Need Attention'}.contains(status);
  bool get paymentReceived => eventType == 'payment' && status == 'Paid';

  factory ProductionRecord.fromEvent(Map<String, dynamic> row) {
    final item = Map<String, dynamic>.from(row['item'] as Map? ?? const {});
    final eventType = '${row['event_type'] ?? ''}';
    return ProductionRecord(
      id: '${row['item_id'] ?? row['id'] ?? ''}',
      eventType: eventType,
      houseCode: '${row['house_code'] ?? item['houseCode'] ?? '—'}',
      parish: '${row['parish'] ?? item['parish'] ?? ''}',
      status: '${item['status'] ?? 'Open'}',
      title: '${item['title'] ?? productionTitle(eventType)}',
      summary: '${item['summary'] ?? item['note'] ?? item['description'] ?? ''}',
      updatedAt: DateTime.tryParse('${row['updated_at'] ?? row['created_at'] ?? ''}') ?? DateTime.now(),
      item: item,
    );
  }
}

String productionTitle(String eventType) => switch (eventType) {
      'scope' => 'Scope of Work',
      'controlData' => 'Control of Work',
      'workPlan' => 'Work Plan',
      'workProjection' => 'Weekly Work Projection',
      'constructionSchedule' => 'Construction Schedule',
      'crewAttendance' => 'Crew Daily Attendance',
      'monitoring' => 'Monitoring Checklist',
      'siteVisit' => 'Site Visit',
      'dailyLog' => 'Daily Site Log',
      'documentChecklist' => 'Document Checklist',
      'materialRequest' => 'Material Request',
      'consumables' => 'Consumables Form',
      'inventory' => 'Inventory Tracker',
      'notice' => 'Notice of Completion',
      'payment' => 'Payment Request',
      'communityPost' => 'Community Post',
      'communitySuggestion' => 'Community Suggestion',
      'signatureRequest' => 'Signature Request',
      _ => eventType.isEmpty ? 'Production Record' : eventType,
    };
