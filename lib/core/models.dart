import 'package:flutter/material.dart';

enum LifecyclePhase {
  scope('Scope', Icons.architecture_outlined),
  plan('Plan', Icons.event_note_outlined),
  delivery('Delivery', Icons.construction_outlined),
  quality('Quality', Icons.fact_check_outlined),
  closeOut('Close-out', Icons.task_alt_outlined),
  finance('Finance', Icons.payments_outlined);

  const LifecyclePhase(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum RecordStatus {
  draft('Draft'),
  active('Active'),
  attention('Needs attention'),
  ready('Ready'),
  submitted('Submitted'),
  approved('Approved'),
  complete('Complete'),
  paid('Paid');

  const RecordStatus(this.label);
  final String label;
}

enum SyncCondition {
  synced('All changes synced', Icons.cloud_done_outlined),
  savedLocal('Saved on device', Icons.save_outlined),
  syncing('Syncing changes', Icons.sync),
  waiting('Waiting for connection', Icons.cloud_off_outlined),
  failed("Couldn't sync", Icons.sync_problem_outlined);

  const SyncCondition(this.label, this.icon);
  final String label;
  final IconData icon;
}

class HouseRecord {
  HouseRecord({
    required this.code,
    required this.beneficiary,
    required this.parish,
    required this.cluster,
    required this.community,
    required this.phase,
    required this.status,
    required this.progress,
    required this.evidenceComplete,
    required this.evidenceRequired,
    required this.nextAction,
    required this.team,
    this.phone = '',
    this.gps = '',
    this.roofType = 'Gable',
    this.roofArea = 0,
    this.blocker,
    this.lastVisit,
  });

  final String code;
  String beneficiary;
  String parish;
  String cluster;
  String community;
  String phone;
  String gps;
  String roofType;
  double roofArea;
  LifecyclePhase phase;
  RecordStatus status;
  double progress;
  int evidenceComplete;
  int evidenceRequired;
  String nextAction;
  String? blocker;
  DateTime? lastVisit;
  final List<String> team;

  bool get needsAttention =>
      blocker != null || status == RecordStatus.attention;
  bool get evidenceReady => evidenceComplete >= evidenceRequired;
}

class ActivityEntry {
  const ActivityEntry({
    required this.id,
    required this.houseCode,
    required this.title,
    required this.detail,
    required this.actor,
    required this.time,
    required this.icon,
  });

  final String id;
  final String houseCode;
  final String title;
  final String detail;
  final String actor;
  final DateTime time;
  final IconData icon;
}

class InventoryItem {
  InventoryItem({
    required this.name,
    required this.unit,
    required this.boq,
    required this.delivered,
    required this.additions,
    required this.leftovers,
    required this.location,
  });

  final String name;
  final String unit;
  double boq;
  double delivered;
  double additions;
  double leftovers;
  String location;

  double get issued => delivered + additions;
  double get used => (issued - leftovers).clamp(0, double.infinity).toDouble();
  double get variance => boq - issued;
}

class EvidenceItem {
  const EvidenceItem({
    required this.id,
    required this.houseCode,
    required this.type,
    required this.caption,
    required this.capturedBy,
    required this.capturedAt,
    required this.approved,
  });

  final String id;
  final String houseCode;
  final String type;
  final String caption;
  final String capturedBy;
  final DateTime capturedAt;
  final bool approved;
}

class AppNotification {
  AppNotification({
    required this.id,
    required this.title,
    required this.detail,
    required this.time,
    required this.priority,
    this.houseCode,
    this.read = false,
  });

  final String id;
  final String title;
  final String detail;
  final DateTime time;
  final String priority;
  final String? houseCode;
  bool read;
}

class TeamMember {
  TeamMember({
    required this.name,
    required this.role,
    required this.parish,
    required this.online,
  });

  final String name;
  String role;
  String parish;
  final bool online;
}

class WorkLogEntry {
  const WorkLogEntry({
    required this.id,
    required this.user,
    required this.role,
    required this.parish,
    required this.houseCode,
    required this.category,
    required this.detail,
    required this.hours,
    required this.createdAt,
  });

  final String id;
  final String user;
  final String role;
  final String parish;
  final String houseCode;
  final String category;
  final String detail;
  final double hours;
  final DateTime createdAt;
}

class FormFieldSpec {
  const FormFieldSpec({
    required this.keyName,
    required this.label,
    this.hint,
    this.required = false,
    this.multiline = false,
    this.number = false,
    this.options = const <String>[],
  });

  final String keyName;
  final String label;
  final String? hint;
  final bool required;
  final bool multiline;
  final bool number;
  final List<String> options;
}

class FormSectionSpec {
  const FormSectionSpec({
    required this.title,
    required this.icon,
    required this.fields,
  });

  final String title;
  final IconData icon;
  final List<FormFieldSpec> fields;
}
