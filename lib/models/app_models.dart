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
  });

  final String userId;
  final String email;
  final String role;
  final String parish;
  final bool approved;
  final Map<String, dynamic> privileges;
  final String? fullName;
  final bool active;

  bool get isAdmin => role == 'Admin';
  bool hasPrivilege(String name) => privileges[name] == true;
  bool get canViewAllParishes => hasPrivilege('viewAllParishes');
  bool get canViewAdmin => isAdmin && hasPrivilege('viewAdmin');
  bool get canApproveScope => hasPrivilege('approveScope');
  bool get canManageUsers => isAdmin && hasPrivilege('manageUsers');
  bool get canManagePrivileges => isAdmin && hasPrivilege('managePrivileges');
  bool get canExportData => hasPrivilege('exportData');
  bool get canMessageAllUsers => hasPrivilege('messageAllUsers');
  bool get canManageTemplates => isAdmin || hasPrivilege('manageFolders') || canViewAllParishes;

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        userId: '${map['user_id'] ?? ''}',
        email: '${map['email'] ?? ''}',
        role: '${map['role'] ?? ''}',
        parish: '${map['parish'] ?? ''}',
        approved: map['approved'] == true,
        active: map['active'] != false,
        privileges: Map<String, dynamic>.from(map['privileges'] as Map? ?? const {}),
        fullName: map['full_name'] as String?,
      );
}

class ActiveUserRecord {
  const ActiveUserRecord({required this.userId, required this.email, required this.fullName, required this.role, required this.parish, required this.online, required this.lastSeen});
  final String userId;
  final String email;
  final String fullName;
  final String role;
  final String parish;
  final bool online;
  final DateTime? lastSeen;
  String get displayName => fullName.trim().isEmpty ? email : fullName;
  factory ActiveUserRecord.fromMap(Map<String, dynamic> map) => ActiveUserRecord(
    userId: '${map['user_id'] ?? ''}', email: '${map['email'] ?? ''}', fullName: '${map['full_name'] ?? ''}', role: '${map['role'] ?? ''}', parish: '${map['parish'] ?? ''}', online: map['active'] == true, lastSeen: DateTime.tryParse('${map['lastSeen'] ?? map['last_seen'] ?? ''}'),
  );
}

class ManagedUserRecord {
  const ManagedUserRecord({required this.userId, required this.email, required this.fullName, required this.role, required this.parish, required this.approved, required this.active, required this.registrationStatus, required this.privileges});
  final String userId;
  final String email;
  final String fullName;
  final String role;
  final String parish;
  final bool approved;
  final bool active;
  final String registrationStatus;
  final Map<String, dynamic> privileges;
  String get displayName => fullName.trim().isEmpty ? email : fullName;
  factory ManagedUserRecord.fromMap(Map<String, dynamic> map) => ManagedUserRecord(
    userId: '${map['user_id'] ?? ''}', email: '${map['email'] ?? ''}', fullName: '${map['full_name'] ?? ''}', role: '${map['role'] ?? ''}', parish: '${map['parish'] ?? ''}', approved: map['approved'] == true, active: map['active'] == true, registrationStatus: '${map['registration_status'] ?? ''}', privileges: Map<String, dynamic>.from(map['privileges'] as Map? ?? const {}),
  );
}

class BeneficiaryRecord {
  const BeneficiaryRecord({required this.houseCode, required this.name, required this.parish, required this.cluster, required this.phone, required this.gps, this.latitude, this.longitude, this.mapsUrl});
  final String houseCode;
  final String name;
  final String parish;
  final String cluster;
  final String phone;
  final String gps;
  final double? latitude;
  final double? longitude;
  final String? mapsUrl;
  factory BeneficiaryRecord.fromMap(Map<String, dynamic> map) => BeneficiaryRecord(
    houseCode: '${map['house_code'] ?? ''}', name: '${map['beneficiary_name'] ?? ''}', parish: '${map['parish'] ?? ''}', cluster: '${map['cluster'] ?? ''}', phone: '${map['phone'] ?? ''}', gps: '${map['gps'] ?? ''}', latitude: (map['latitude'] as num?)?.toDouble(), longitude: (map['longitude'] as num?)?.toDouble(), mapsUrl: map['maps_url'] as String?,
  );
}

class HouseRecord {
  const HouseRecord({required this.code, required this.beneficiary, required this.parish, required this.cluster, required this.stage, required this.progress});
  final String code;
  final String beneficiary;
  final String parish;
  final String cluster;
  final String stage;
  final int progress;
  factory HouseRecord.fromEvent(Map<String, dynamic> row) {
    final item = Map<String, dynamic>.from(row['item'] as Map? ?? const {});
    return HouseRecord(code: '${row['house_code'] ?? item['houseCode'] ?? item['code'] ?? '—'}', beneficiary: '${item['beneficiary'] ?? item['beneficiaryName'] ?? 'Beneficiary'}', parish: '${row['parish'] ?? item['parish'] ?? 'Unknown'}', cluster: '${item['cluster'] ?? ''}', stage: '${item['stage'] ?? item['status'] ?? 'In progress'}', progress: ((item['progress'] as num?)?.round() ?? 0).clamp(0, 100).toInt());
  }
}

class MessageRecord {
  const MessageRecord({required this.id, required this.sender, required this.senderEmail, required this.subject, required this.body, required this.createdAt, required this.unread, required this.recipients, this.parish, this.threadId, this.replyTo});
  final String id;
  final String sender;
  final String senderEmail;
  final String subject;
  final String body;
  final DateTime createdAt;
  final bool unread;
  final List<String> recipients;
  final String? parish;
  final String? threadId;
  final String? replyTo;
  factory MessageRecord.fromEvent(Map<String, dynamic> row, String email) {
    final item = Map<String, dynamic>.from(row['item'] as Map? ?? const {});
    final readBy = (item['readBy'] as List?)?.map((e) => '$e').toSet() ?? <String>{};
    final recipients = (row['recipients'] as List? ?? item['recipients'] as List? ?? const []).map((e) => '$e').toList();
    final senderEmail = '${item['fromEmail'] ?? row['created_by_email'] ?? ''}';
    return MessageRecord(id: '${row['item_id'] ?? row['id']}', sender: '${item['senderName'] ?? (senderEmail.trim().isEmpty ? 'RC SOW' : senderEmail)}', senderEmail: senderEmail, subject: '${item['subject'] ?? item['title'] ?? 'Message'}', body: '${item['body'] ?? item['message'] ?? ''}', createdAt: DateTime.tryParse('${row['created_at'] ?? ''}') ?? DateTime.now(), unread: !readBy.contains(email), recipients: recipients, parish: row['parish'] as String?, threadId: item['threadId'] as String?, replyTo: item['replyTo'] as String?);
  }
}

class RoofMeasurements {
  const RoofMeasurements({required this.widthFt, required this.lengthFt, required this.wallHeightFt, required this.pitchRisePer12, this.overhangFt = 1, this.ridgeLengthFt});
  final double widthFt;
  final double lengthFt;
  final double wallHeightFt;
  final double pitchRisePer12;
  final double overhangFt;
  final double? ridgeLengthFt;
  double get ridgeRiseFt => widthFt / 2 * pitchRisePer12 / 12;
  double get ridgeHeightFt => wallHeightFt + ridgeRiseFt;
  double get halfSpanFt => widthFt / 2;
  double get rafterLengthFt => (halfSpanFt * halfSpanFt + ridgeRiseFt * ridgeRiseFt).sqrt();
  double get roofAreaSqFt => 2 * (lengthFt + 2 * overhangFt) * (rafterLengthFt + overhangFt);
}

class RoofWallSegment {
  const RoofWallSegment({required this.label, required this.lengthFt, this.hasDrain = false});
  final String label;
  final double lengthFt;
  final bool hasDrain;
}

extension _NumSqrt on double {
  double sqrt() { if (this <= 0) return 0; var x = this; for (var i = 0; i < 16; i++) { x = 0.5 * (x + this / x); } return x; }
}

class ProductionRecord {
  const ProductionRecord({required this.id, required this.eventType, required this.houseCode, required this.parish, required this.status, required this.title, required this.summary, required this.updatedAt, required this.item});
  final String id;
  final String eventType;
  final String houseCode;
  final String parish;
  final String status;
  final String title;
  final String summary;
  final DateTime updatedAt;
  final Map<String, dynamic> item;
  bool get isClosed => const {'Completed','Approved','Paid','Closed'}.contains(status);
  bool get needsAttention => const {'Rejected','Blocked','Overdue','Critical'}.contains(status);
  factory ProductionRecord.fromEvent(Map<String, dynamic> row) {
    final item = Map<String, dynamic>.from(row['item'] as Map? ?? const {}); final eventType = '${row['event_type'] ?? ''}';
    return ProductionRecord(id: '${row['item_id'] ?? row['id'] ?? ''}', eventType: eventType, houseCode: '${row['house_code'] ?? item['houseCode'] ?? '—'}', parish: '${row['parish'] ?? item['parish'] ?? ''}', status: '${item['status'] ?? 'Open'}', title: '${item['title'] ?? _productionTitle(eventType)}', summary: '${item['summary'] ?? item['note'] ?? item['description'] ?? ''}', updatedAt: DateTime.tryParse('${row['updated_at'] ?? row['created_at'] ?? ''}') ?? DateTime.now(), item: item);
  }
}

String _productionTitle(String eventType) => switch (eventType) {
  'scope' => 'Scope of Work','controlData' => 'Control of Work','workPlan' => 'Work Plan','monitoring' => 'Monitoring Checklist','siteVisit' => 'Site Visit','dailyLog' => 'Daily Site Log','documentChecklist' => 'Document Checklist','materialRequest' => 'Material Request','consumables' => 'Consumables Form','inventory' => 'Inventory Tracker','notice' => 'Notice of Completion','payment' => 'Payment Submission', _ => eventType.isEmpty ? 'Production Record' : eventType,
};
