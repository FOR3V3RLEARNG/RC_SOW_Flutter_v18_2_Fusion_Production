import 'package:flutter/material.dart';

import 'models.dart';

class AppState extends ChangeNotifier {
  AppState._({
    required this.houses,
    required this.inventory,
    required this.evidence,
    required this.activities,
    required this.notifications,
    required this.team,
    required this.workLogs,
  });

  factory AppState.seeded() {
    final now = DateTime.now();
    return AppState._(
      houses: <HouseRecord>[
        HouseRecord(
          code: 'H12',
          beneficiary: 'Martha Campbell',
          parish: 'Hanover',
          cluster: 'Thornton Cluster A3',
          community: 'Thornton',
          phone: '(876) 555-0142',
          gps: '18.4102, -78.1315',
          roofType: 'Gable',
          roofArea: 432,
          phase: LifecyclePhase.delivery,
          status: RecordStatus.attention,
          progress: .64,
          evidenceComplete: 4,
          evidenceRequired: 6,
          nextAction: 'Complete today\'s site log',
          blocker: '12 sheets of 14 ft zinc awaiting transfer',
          lastVisit: now.subtract(const Duration(days: 1)),
          team: <String>['Andre Brown', 'Michael Grant', 'Jason Reid'],
        ),
        HouseRecord(
          code: 'H2',
          beneficiary: 'Gloria Thompson',
          parish: 'Hanover',
          cluster: 'Haughton Grove Cluster 1',
          community: 'Haughton Grove',
          phone: '(876) 555-0198',
          gps: '18.4038, -78.0734',
          roofType: 'Hip',
          roofArea: 450,
          phase: LifecyclePhase.closeOut,
          status: RecordStatus.ready,
          progress: .92,
          evidenceComplete: 6,
          evidenceRequired: 6,
          nextAction: 'Submit Notice of Completion',
          lastVisit: now.subtract(const Duration(days: 2)),
          team: <String>['Andre Brown', 'David Clarke', 'Ian Smith'],
        ),
        HouseRecord(
          code: 'H15',
          beneficiary: 'Evelyn Murray',
          parish: 'Hanover',
          cluster: 'Haughton Grove Cluster 1',
          community: 'Haughton Grove',
          roofType: 'Gable',
          roofArea: 390,
          phase: LifecyclePhase.plan,
          status: RecordStatus.active,
          progress: .28,
          evidenceComplete: 2,
          evidenceRequired: 6,
          nextAction: 'Complete work plan and crew assignment',
          team: <String>['Andre Brown'],
        ),
        HouseRecord(
          code: 'H18',
          beneficiary: 'Samuel Grant',
          parish: 'Hanover',
          cluster: 'Miles Town Cluster 2',
          community: 'Miles Town',
          roofType: 'Shed / Mono',
          roofArea: 315,
          phase: LifecyclePhase.scope,
          status: RecordStatus.draft,
          progress: .16,
          evidenceComplete: 1,
          evidenceRequired: 6,
          nextAction: 'Continue roof measurements',
          team: <String>['Andre Brown'],
        ),
        HouseRecord(
          code: 'H1',
          beneficiary: 'Denise Williams',
          parish: 'Hanover',
          cluster: 'Haughton Grove Cluster 1',
          community: 'Haughton Grove',
          roofType: 'Gable',
          roofArea: 408,
          phase: LifecyclePhase.finance,
          status: RecordStatus.submitted,
          progress: 1,
          evidenceComplete: 6,
          evidenceRequired: 6,
          nextAction: 'Track payment approval',
          team: <String>['Andre Brown', 'Michael Grant', 'Jason Reid'],
        ),
      ],
      inventory: <InventoryItem>[
        InventoryItem(
          name: 'Ridge beam 2×8×20',
          unit: 'lengths',
          boq: 4,
          delivered: 4,
          additions: 0,
          leftovers: 0,
          location: 'Hanover Central Depot',
        ),
        InventoryItem(
          name: 'Rafters / Collars 2×6×14',
          unit: 'lengths',
          boq: 24,
          delivered: 18,
          additions: 0,
          leftovers: 2,
          location: 'Thornton Site Store',
        ),
        InventoryItem(
          name: 'Battens / Wall plate 2×4×16',
          unit: 'lengths',
          boq: 36,
          delivered: 36,
          additions: 4,
          leftovers: 6,
          location: 'Thornton Site Store',
        ),
        InventoryItem(
          name: 'Zinc 26 gauge 36 in × 14 ft',
          unit: 'sheets',
          boq: 28,
          delivered: 16,
          additions: 0,
          leftovers: 0,
          location: 'Hanover Central Depot',
        ),
        InventoryItem(
          name: 'Hurricane straps H3',
          unit: 'pieces',
          boq: 96,
          delivered: 100,
          additions: 0,
          leftovers: 12,
          location: 'Thornton Site Store',
        ),
        InventoryItem(
          name: 'Zinc screws 2½ in',
          unit: 'pieces',
          boq: 350,
          delivered: 400,
          additions: 0,
          leftovers: 85,
          location: 'Thornton Site Store',
        ),
      ],
      evidence: <EvidenceItem>[
        EvidenceItem(
          id: 'EV-104',
          houseCode: 'H12',
          type: 'Before',
          caption: 'Damaged eastern roof slope',
          capturedBy: 'Andre Brown',
          capturedAt: now.subtract(const Duration(days: 9)),
          approved: true,
        ),
        EvidenceItem(
          id: 'EV-118',
          houseCode: 'H12',
          type: 'During',
          caption: 'Wall plate and rafter installation',
          capturedBy: 'Andre Brown',
          capturedAt: now.subtract(const Duration(days: 3)),
          approved: true,
        ),
        EvidenceItem(
          id: 'EV-124',
          houseCode: 'H12',
          type: 'Delivery',
          caption: 'Timber delivery received on site',
          capturedBy: 'Michael Grant',
          capturedAt: now.subtract(const Duration(days: 2)),
          approved: false,
        ),
        EvidenceItem(
          id: 'EV-130',
          houseCode: 'H2',
          type: 'Completion',
          caption: 'Final repaired roof inspection',
          capturedBy: 'Andre Brown',
          capturedAt: now.subtract(const Duration(days: 1)),
          approved: true,
        ),
      ],
      activities: <ActivityEntry>[
        ActivityEntry(
          id: 'ACT-1',
          houseCode: 'H12',
          title: 'Site visit saved',
          detail: 'Completion updated to 64%; zinc shortage noted.',
          actor: 'Andre Brown',
          time: now.subtract(const Duration(hours: 5)),
          icon: Icons.location_on_outlined,
        ),
        ActivityEntry(
          id: 'ACT-2',
          houseCode: 'H12',
          title: 'Material request submitted',
          detail: '12 sheets of 14 ft zinc requested for delivery.',
          actor: 'Andre Brown',
          time: now.subtract(const Duration(days: 1)),
          icon: Icons.inventory_2_outlined,
        ),
        ActivityEntry(
          id: 'ACT-3',
          houseCode: 'H2',
          title: 'Final inspection approved',
          detail: 'All technical criteria passed and evidence complete.',
          actor: 'Construction Specialist',
          time: now.subtract(const Duration(days: 2)),
          icon: Icons.verified_outlined,
        ),
      ],
      notifications: <AppNotification>[
        AppNotification(
          id: 'N-1',
          title: 'Material transfer needs approval',
          detail: 'Transfer 12 zinc sheets from Hanover Central Depot to H12.',
          time: now.subtract(const Duration(minutes: 35)),
          priority: 'High',
          houseCode: 'H12',
        ),
        AppNotification(
          id: 'N-2',
          title: 'H2 ready for close-out',
          detail: 'Final inspection and required evidence are complete.',
          time: now.subtract(const Duration(hours: 3)),
          priority: 'Action',
          houseCode: 'H2',
        ),
        AppNotification(
          id: 'N-3',
          title: 'Weekly tracker synchronized',
          detail: 'Hanover production records were updated successfully.',
          time: now.subtract(const Duration(days: 1)),
          priority: 'Info',
          read: true,
        ),
      ],
      team: <TeamMember>[
        TeamMember(
          name: 'Maria Green',
          role: 'Regional Site Supervisor',
          parish: 'Hanover',
          online: true,
        ),
        TeamMember(
          name: 'Andre Brown',
          role: 'Site Supervisor',
          parish: 'Hanover',
          online: true,
        ),
        TeamMember(
          name: 'Kim Ross',
          role: 'Technical Admin',
          parish: 'All Parishes',
          online: true,
        ),
        TeamMember(
          name: 'David Clarke',
          role: 'Carpenter Lead',
          parish: 'Hanover',
          online: false,
        ),
      ],
      workLogs: <WorkLogEntry>[
        WorkLogEntry(
          id: 'WL-1',
          user: 'Andre Brown',
          role: 'Site Supervisor',
          parish: 'Hanover',
          houseCode: 'H12',
          category: 'Site monitoring',
          detail:
              'Monitored rafter installation, verified materials, and met carpenter lead.',
          hours: 5.5,
          createdAt: now.subtract(const Duration(hours: 6)),
        ),
      ],
    );
  }

  final List<HouseRecord> houses;
  final List<InventoryItem> inventory;
  final List<EvidenceItem> evidence;
  final List<ActivityEntry> activities;
  final List<AppNotification> notifications;
  final List<TeamMember> team;
  final List<WorkLogEntry> workLogs;

  final Map<String, Map<String, String>> formDrafts =
      <String, Map<String, String>>{};
  final Map<String, Set<String>> completedDocuments = <String, Set<String>>{
    'H12': <String>{'BOQ', 'Scope', 'Workplan'},
    'H2': <String>{'BOQ', 'Scope', 'Workplan', 'Monitoring Checklist', 'KOBO'},
  };
  final Map<String, Map<String, String>> monitoring =
      <String, Map<String, String>>{
    'H12': <String, String>{
      'Wall Plate': 'Pass',
      'Roof Angle': 'Pass',
      'Rafters': 'Attention',
      'Battens': 'Pending',
      'Plywood / T1-11': 'Pending',
      'Zinc': 'Pending',
      'Other roof elements': 'Pending',
    },
  };
  final Map<String, Map<String, String>> monitoringComments =
      <String, Map<String, String>>{};

  bool authenticated = false;
  bool offline = false;
  bool reviewMode = false;
  bool darkMode = false;
  bool highContrast = false;
  bool reducedMotion = false;
  String role = 'Site Supervisor';
  String selectedParish = 'Hanover';
  String selectedHouseCode = 'H12';
  SyncCondition syncCondition = SyncCondition.synced;
  int queuedChanges = 0;

  HouseRecord get selectedHouse => houseByCode(selectedHouseCode);
  int get unreadNotifications =>
      notifications.where((item) => !item.read).length;
  int get activeHouses => houses.where((house) => house.progress < 1).length;
  int get attentionHouses =>
      houses.where((house) => house.needsAttention).length;
  int get closeOutReady =>
      houses.where((house) => house.phase == LifecyclePhase.closeOut).length;
  int get paymentsPending => houses
      .where(
        (house) =>
            house.phase == LifecyclePhase.finance &&
            house.status != RecordStatus.paid,
      )
      .length;
  double get evidenceReadiness {
    final required = houses.fold<int>(
      0,
      (sum, item) => sum + item.evidenceRequired,
    );
    final complete = houses.fold<int>(
      0,
      (sum, item) => sum + item.evidenceComplete,
    );
    return required == 0 ? 0 : complete / required;
  }

  HouseRecord houseByCode(String code) =>
      houses.firstWhere((house) => house.code == code);

  void login({required String selectedRole}) {
    authenticated = true;
    role = selectedRole;
    notifyListeners();
  }

  void logout() {
    authenticated = false;
    notifyListeners();
  }

  void selectHouse(String code) {
    selectedHouseCode = code;
    selectedParish = houseByCode(code).parish;
    notifyListeners();
  }

  bool createHouse({
    required String code,
    required String beneficiary,
    required String parish,
    required String cluster,
    required String community,
  }) {
    final normalized = code.trim().toUpperCase();
    if (houses.any((house) => house.code == normalized)) return false;
    houses.insert(
      0,
      HouseRecord(
        code: normalized,
        beneficiary: beneficiary.trim(),
        parish: parish,
        cluster: cluster.trim(),
        community: community.trim(),
        phase: LifecyclePhase.scope,
        status: RecordStatus.draft,
        progress: 0,
        evidenceComplete: 0,
        evidenceRequired: 6,
        nextAction: 'Complete house and roof scope',
        team: <String>['Andre Brown'],
      ),
    );
    selectedHouseCode = normalized;
    selectedParish = parish;
    _recordActivity(
      houseCode: normalized,
      title: 'Production control created',
      detail: 'New house record created for $beneficiary in $community.',
      icon: Icons.add_home_work_outlined,
    );
    _markChanged();
    return true;
  }

  void setParish(String parish) {
    selectedParish = parish;
    notifyListeners();
  }

  void toggleOffline() {
    offline = !offline;
    syncCondition = offline
        ? (queuedChanges > 0 ? SyncCondition.waiting : SyncCondition.savedLocal)
        : SyncCondition.synced;
    if (!offline) queuedChanges = 0;
    notifyListeners();
  }

  void toggleReviewMode() {
    reviewMode = !reviewMode;
    notifyListeners();
  }

  void toggleDarkMode() {
    darkMode = !darkMode;
    notifyListeners();
  }

  void toggleHighContrast() {
    highContrast = !highContrast;
    notifyListeners();
  }

  void toggleReducedMotion() {
    reducedMotion = !reducedMotion;
    notifyListeners();
  }

  void saveForm({
    required String type,
    required String houseCode,
    required Map<String, String> values,
    bool submit = false,
  }) {
    formDrafts['$houseCode:$type'] = Map<String, String>.from(values);
    final house = houseByCode(houseCode);
    _applyLifecycleUpdate(house, type, submit);
    _recordActivity(
      houseCode: houseCode,
      title: submit ? '$type submitted' : '$type saved',
      detail: submit
          ? 'Record submitted for review with ${values.length} fields.'
          : 'Draft is safe with ${values.length} fields.',
      icon: submit ? Icons.send_outlined : Icons.save_outlined,
    );
    _markChanged();
  }

  void _applyLifecycleUpdate(HouseRecord house, String type, bool submit) {
    final normalized = type.toLowerCase();
    if (normalized.contains('work plan')) {
      house.phase = LifecyclePhase.plan;
      house.progress = house.progress < .3 ? .3 : house.progress;
    } else if (normalized.contains('visit') ||
        normalized.contains('daily') ||
        normalized.contains('material') ||
        normalized.contains('consumable')) {
      house.phase = LifecyclePhase.delivery;
      house.progress = house.progress < .55 ? .55 : house.progress;
      house.lastVisit = DateTime.now();
    } else if (normalized.contains('inspection') ||
        normalized.contains('monitoring')) {
      house.phase = LifecyclePhase.quality;
      house.progress = house.progress < .8 ? .8 : house.progress;
    }
    house.status = submit ? RecordStatus.submitted : RecordStatus.draft;
  }

  void toggleDocument(String houseCode, String document) {
    final set = completedDocuments.putIfAbsent(houseCode, () => <String>{});
    if (!set.add(document)) set.remove(document);
    _recordActivity(
      houseCode: houseCode,
      title: 'Document checklist updated',
      detail:
          '$document marked ${set.contains(document) ? 'complete' : 'incomplete'}.',
      icon: Icons.description_outlined,
    );
    _markChanged();
  }

  void setMonitoringStatus(String houseCode, String criterion, String status) {
    monitoring.putIfAbsent(houseCode, () => <String, String>{})[criterion] =
        status;
    _recordActivity(
      houseCode: houseCode,
      title: 'Monitoring criterion updated',
      detail: '$criterion marked $status.',
      icon: Icons.fact_check_outlined,
    );
    _markChanged();
  }

  void setMonitoringComment(
    String houseCode,
    String criterion,
    String comment,
  ) {
    monitoringComments.putIfAbsent(
      houseCode,
      () => <String, String>{},
    )[criterion] = comment;
    _recordActivity(
      houseCode: houseCode,
      title: 'Inspection comment added',
      detail: '$criterion: $comment',
      icon: Icons.comment_outlined,
    );
    _markChanged();
  }

  void updateInventory({
    required String itemName,
    required double delivered,
    required double additions,
    required double leftovers,
  }) {
    final item = inventory.firstWhere((entry) => entry.name == itemName);
    item.delivered = delivered;
    item.additions = additions;
    item.leftovers = leftovers;
    _recordActivity(
      houseCode: selectedHouseCode,
      title: 'Inventory reconciled',
      detail:
          '${item.name}: ${item.issued.toStringAsFixed(0)} ${item.unit} issued.',
      icon: Icons.inventory_2_outlined,
    );
    _markChanged();
  }

  void addEvidence({required String type, required String caption}) {
    final house = selectedHouse;
    evidence.insert(
      0,
      EvidenceItem(
        id: 'EV-${DateTime.now().millisecondsSinceEpoch}',
        houseCode: house.code,
        type: type,
        caption: caption,
        capturedBy: 'Andre Brown',
        capturedAt: DateTime.now(),
        approved: false,
      ),
    );
    house.evidenceComplete =
        (house.evidenceComplete + 1).clamp(0, house.evidenceRequired).toInt();
    _recordActivity(
      houseCode: house.code,
      title: '$type evidence added',
      detail: caption,
      icon: Icons.add_a_photo_outlined,
    );
    _markChanged();
  }

  void submitCompletion(String houseCode) {
    final house = houseByCode(houseCode);
    house.phase = LifecyclePhase.closeOut;
    house.status = RecordStatus.submitted;
    house.progress = 1;
    house.nextAction = 'Track close-out approval';
    _recordActivity(
      houseCode: houseCode,
      title: 'Notice of Completion submitted',
      detail: 'Completion package entered the approval queue.',
      icon: Icons.task_alt_outlined,
    );
    _markChanged();
  }

  void submitPayment(String houseCode) {
    final house = houseByCode(houseCode);
    house.phase = LifecyclePhase.finance;
    house.status = RecordStatus.submitted;
    house.nextAction = 'Track payment approval';
    _recordActivity(
      houseCode: houseCode,
      title: 'Payment submitted',
      detail: 'Payment package entered finance review.',
      icon: Icons.payments_outlined,
    );
    _markChanged();
  }

  void markNotificationRead(String id) {
    notifications.firstWhere((item) => item.id == id).read = true;
    notifyListeners();
  }

  void updateTeamAccess({
    required String name,
    String? newRole,
    String? newParish,
  }) {
    final member = team.firstWhere((person) => person.name == name);
    if (newRole != null) member.role = newRole;
    if (newParish != null) member.parish = newParish;
    _recordActivity(
      houseCode: selectedHouseCode,
      title: 'User access updated',
      detail: '$name • ${member.role} • ${member.parish}',
      icon: Icons.admin_panel_settings_outlined,
    );
    _markChanged();
  }

  void addWorkLog({
    required String houseCode,
    required String category,
    required String detail,
    required double hours,
  }) {
    workLogs.insert(
      0,
      WorkLogEntry(
        id: 'WL-${DateTime.now().millisecondsSinceEpoch}',
        user: 'Andre Brown',
        role: role,
        parish: selectedParish,
        houseCode: houseCode,
        category: category,
        detail: detail,
        hours: hours,
        createdAt: DateTime.now(),
      ),
    );
    _recordActivity(
      houseCode: houseCode,
      title: 'Work log saved',
      detail: '$category • ${hours.toStringAsFixed(1)} hours',
      icon: Icons.schedule_outlined,
    );
    _markChanged();
  }

  void _recordActivity({
    required String houseCode,
    required String title,
    required String detail,
    required IconData icon,
  }) {
    activities.insert(
      0,
      ActivityEntry(
        id: 'ACT-${DateTime.now().microsecondsSinceEpoch}',
        houseCode: houseCode,
        title: title,
        detail: detail,
        actor: 'Andre Brown',
        time: DateTime.now(),
        icon: icon,
      ),
    );
  }

  void _markChanged() {
    if (offline) {
      queuedChanges += 1;
      syncCondition = SyncCondition.waiting;
    } else {
      syncCondition = SyncCondition.synced;
    }
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({required AppState state, required super.child, super.key})
      : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing above this context.');
    return scope!.notifier!;
  }
}
