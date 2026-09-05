import 'dart:convert';

enum WeeklyProjectionStatus {
  draft('Draft'),
  submitted('Submitted');

  const WeeklyProjectionStatus(this.label);
  final String label;
}

class SignaturePointData {
  const SignaturePointData({required this.x, required this.y});

  final double x;
  final double y;

  Map<String, dynamic> toMap() => <String, dynamic>{'x': x, 'y': y};

  factory SignaturePointData.fromMap(Map<String, dynamic> map) {
    return SignaturePointData(
      x: (map['x'] as num?)?.toDouble() ?? 0,
      y: (map['y'] as num?)?.toDouble() ?? 0,
    );
  }
}

class DailyAdminWorkPlan {
  DailyAdminWorkPlan({
    required this.date,
    required this.enabled,
    required this.startMinutes,
    required this.endMinutes,
    required this.detail,
  });

  DateTime date;
  bool enabled;
  int startMinutes;
  int endMinutes;
  String detail;

  double get plannedHours {
    if (!enabled || endMinutes <= startMinutes) return 0;
    return (endMinutes - startMinutes) / 60;
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'date': _dateKey(date),
        'enabled': enabled,
        'start_minutes': startMinutes,
        'end_minutes': endMinutes,
        'detail': detail,
      };

  factory DailyAdminWorkPlan.fromMap(Map<String, dynamic> map) {
    return DailyAdminWorkPlan(
      date: DateTime.tryParse('${map['date'] ?? ''}') ?? DateTime.now(),
      enabled: map['enabled'] == true,
      startMinutes: (map['start_minutes'] as num?)?.toInt() ?? 9 * 60,
      endMinutes: (map['end_minutes'] as num?)?.toInt() ?? 17 * 60,
      detail: '${map['detail'] ?? ''}',
    );
  }
}

class WeeklyAdminProjectionFile {
  WeeklyAdminProjectionFile({
    required this.id,
    required this.weekStarting,
    required this.ownerId,
    required this.ownerName,
    required this.position,
    required this.parish,
    required this.cluster,
    required this.days,
    required this.signatureStrokes,
    required this.status,
    required this.updatedAt,
    this.submittedAt,
  });

  String id;
  DateTime weekStarting;
  String ownerId;
  String ownerName;
  String position;
  String parish;
  String cluster;
  List<DailyAdminWorkPlan> days;
  List<List<SignaturePointData>> signatureStrokes;
  WeeklyProjectionStatus status;
  DateTime updatedAt;
  DateTime? submittedAt;

  int get plannedDays => days.where((day) => day.enabled).length;

  double get plannedHours =>
      days.fold<double>(0, (sum, day) => sum + day.plannedHours);

  bool get hasSignature =>
      signatureStrokes.any((stroke) => stroke.length >= 2);

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'week_starting': _dateKey(weekStarting),
        'owner_id': ownerId,
        'owner_name': ownerName,
        'position': position,
        'parish': parish,
        'cluster': cluster,
        'daily_plan': days.map((day) => day.toMap()).toList(),
        'signature_strokes': signatureStrokes
            .map((stroke) => stroke.map((point) => point.toMap()).toList())
            .toList(),
        'status': status.name,
        'updated_at': updatedAt.toIso8601String(),
        'submitted_at': submittedAt?.toIso8601String(),
      };

  String toJson() => jsonEncode(toMap());

  factory WeeklyAdminProjectionFile.fromMap(Map<String, dynamic> map) {
    final rawStatus = '${map['status'] ?? WeeklyProjectionStatus.draft.name}';
    return WeeklyAdminProjectionFile(
      id: '${map['id'] ?? ''}',
      weekStarting:
          DateTime.tryParse('${map['week_starting'] ?? ''}') ?? DateTime.now(),
      ownerId: '${map['owner_id'] ?? ''}',
      ownerName: '${map['owner_name'] ?? ''}',
      position: '${map['position'] ?? ''}',
      parish: '${map['parish'] ?? ''}',
      cluster: '${map['cluster'] ?? ''}',
      days: (map['daily_plan'] as List? ?? const <Object>[])
          .whereType<Map>()
          .map(
            (day) => DailyAdminWorkPlan.fromMap(
              Map<String, dynamic>.from(day),
            ),
          )
          .toList(),
      signatureStrokes:
          (map['signature_strokes'] as List? ?? const <Object>[])
              .whereType<List>()
              .map(
                (stroke) => stroke
                    .whereType<Map>()
                    .map(
                      (point) => SignaturePointData.fromMap(
                        Map<String, dynamic>.from(point),
                      ),
                    )
                    .toList(),
              )
              .toList(),
      status: WeeklyProjectionStatus.values.firstWhere(
        (value) => value.name == rawStatus,
        orElse: () => WeeklyProjectionStatus.draft,
      ),
      updatedAt:
          DateTime.tryParse('${map['updated_at'] ?? ''}') ?? DateTime.now(),
      submittedAt: DateTime.tryParse('${map['submitted_at'] ?? ''}'),
    );
  }

  factory WeeklyAdminProjectionFile.fromJson(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('Weekly projection file is not an object.');
    }
    return WeeklyAdminProjectionFile.fromMap(
      Map<String, dynamic>.from(decoded),
    );
  }
}

abstract final class WeeklyProjectionAccess {
  static bool isGlobalReviewer(String role) {
    final normalized = normalizeRole(role);
    return normalized == 'admin' ||
        normalized == 'regional site supervisor' ||
        normalized == 'regional supervisor' ||
        normalized == 'construction specialist';
  }

  static bool isParishSupervisor(String role) =>
      normalizeRole(role) == 'site supervisor';

  static bool canView({
    required String viewerRole,
    required String viewerId,
    required Iterable<String> viewerParishes,
    required WeeklyAdminProjectionFile file,
  }) {
    if (viewerId.isNotEmpty && viewerId == file.ownerId) return true;
    if (isGlobalReviewer(viewerRole)) return true;
    if (isParishSupervisor(viewerRole)) {
      return viewerParishes.contains(file.parish);
    }
    return false;
  }

  static bool canEdit({
    required String viewerId,
    required WeeklyAdminProjectionFile file,
  }) =>
      viewerId.isNotEmpty &&
      viewerId == file.ownerId &&
      file.status == WeeklyProjectionStatus.draft;

  static String scopeLabel(String role) {
    if (isGlobalReviewer(role)) return 'All staff • all parishes';
    if (isParishSupervisor(role)) return 'All staff • assigned parish';
    return 'My weekly file only';
  }
}

DateTime rcWeekStarting(DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

String rcWeekKey(DateTime date) => _dateKey(rcWeekStarting(date));

String weeklyProjectionCacheKey(String ownerId, DateTime weekStarting) =>
    'weekly-admin-projection:$ownerId:${rcWeekKey(weekStarting)}';

List<DailyAdminWorkPlan> defaultAdminWorkWeek(DateTime weekStarting) {
  final week = rcWeekStarting(weekStarting);
  return List<DailyAdminWorkPlan>.generate(7, (index) {
    return DailyAdminWorkPlan(
      date: week.add(Duration(days: index)),
      enabled: index < 5,
      startMinutes: 9 * 60,
      endMinutes: 17 * 60,
      detail: '',
    );
  });
}

String normalizeRole(String role) =>
    role.trim().toLowerCase().replaceAll('_', ' ');

String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
