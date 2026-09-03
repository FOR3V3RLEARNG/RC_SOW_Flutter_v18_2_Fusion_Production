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

  final List<TransferRecord> transfers = <TransferRecord>[
    TransferRecord(
      id: 'TRF-8924A',
      category: 'Personnel',
      resource: '1 Master Carpenter, 2 Assistants',
      quantity: 3,
      origin: 'Hanover Central Hub',
      destination: 'Thornton Cluster A3',
      houseCode: 'H12',
      urgency: 'Priority',
      reason: 'Roof framing and structural reinforcement.',
      startDate: DateTime(2026, 9, 3),
      endDate: DateTime(2026, 9, 6),
      budgetImpact: 1200,
      status: 'Pending approval',
    ),
    TransferRecord(
      id: 'TRF-8930B',
      category: 'Materials',
      resource: '12 zinc sheets • 14 ft',
      quantity: 12,
      origin: 'Hanover Central Depot',
      destination: 'Thornton Site Store',
      houseCode: 'H12',
      urgency: 'Critical',
      reason: 'Resolve active roofing-material blocker.',
      startDate: DateTime(2026, 9, 3),
      budgetImpact: 450,
      status: 'In transit',
    ),
    TransferRecord(
      id: 'TRF-8912C',
      category: 'Personnel',
      resource: '1 Carpenter',
      quantity: 1,
      origin: 'Haughton Grove Cluster 1',
      destination: 'Miles Town Cluster 2',
      houseCode: 'H18',
      urgency: 'Routine',
      reason: 'Temporary scope-verification support.',
      startDate: DateTime(2026, 8, 29),
      endDate: DateTime(2026, 8, 30),
      budgetImpact: 250,
      status: 'Completed',
    ),
  ];

  final List<CrewRecord> crews = <CrewRecord>[
    CrewRecord(
      id: 'CREW-A',
      name: 'Alpha Crew',
      lead: 'Andre Brown',
      parish: 'Hanover',
      cluster: 'Thornton Cluster A3',
      currentHouse: 'H12',
      currentPhase: 'Roof framing',
      members: <String>['Andre Brown', 'Michael Grant', 'Jason Reid'],
      housesCompleted: 14,
      incidents: 0,
      qualityScore: .96,
      efficiency: 1.12,
      payoutVelocity: 3.1,
      availability: 'Deployed',
    ),
    CrewRecord(
      id: 'CREW-B',
      name: 'Bravo Squad',
      lead: 'David Clarke',
      parish: 'Hanover',
      cluster: 'Haughton Grove Cluster 1',
      currentHouse: 'H2',
      currentPhase: 'Close-out',
      members: <String>['David Clarke', 'Ian Smith', 'Maria Green'],
      housesCompleted: 9,
      incidents: 1,
      qualityScore: .92,
      efficiency: 1.04,
      payoutVelocity: 3.8,
      availability: 'Deployed',
    ),
    CrewRecord(
      id: 'CREW-C',
      name: 'Charlie Team',
      lead: 'Kim Ross',
      parish: 'Hanover',
      cluster: 'Miles Town Cluster 2',
      currentHouse: 'H18',
      currentPhase: 'Technical scope',
      members: <String>['Kim Ross', 'Samuel Reid'],
      housesCompleted: 11,
      incidents: 0,
      qualityScore: .94,
      efficiency: 1.08,
      payoutVelocity: 3.4,
      availability: 'Available',
    ),
  ];

  final List<CommunityEventRecord> communityEvents =
      <CommunityEventRecord>[
    CommunityEventRecord(
      id: 'EVT-1',
      title: 'Technical workshop: roof anchors',
      location: 'Hanover Site HQ',
      startsAt: DateTime(2026, 9, 4, 8),
      kind: 'Training',
    ),
    CommunityEventRecord(
      id: 'EVT-2',
      title: 'Field supervisor synchronization',
      location: 'Virtual command room',
      startsAt: DateTime(2026, 9, 5, 10),
      kind: 'Meeting',
    ),
    CommunityEventRecord(
      id: 'EVT-3',
      title: 'Community outreach: Miles Town',
      location: 'Miles Town Community Centre',
      startsAt: DateTime(2026, 9, 7, 13),
      kind: 'Community',
    ),
  ];

  final List<ShoutOutRecord> shoutOuts = <ShoutOutRecord>[
    ShoutOutRecord(
      id: 'SH-1',
      message:
          'Thanks to David Clarke for supporting the H12 material delivery when transport was delayed.',
      author: 'Maria Green',
      crew: 'Bravo Squad',
      createdAt: DateTime(2026, 9, 2, 15, 30),
    ),
    ShoutOutRecord(
      id: 'SH-2',
      message:
          'Excellent framing solution by Alpha Crew while preserving the approved roof geometry.',
      author: 'Construction Specialist',
      crew: 'Alpha Crew',
      createdAt: DateTime(2026, 9, 1, 11),
    ),
  ];

  final List<IncentiveRecord> incentives = <IncentiveRecord>[
    IncentiveRecord(
      id: 'INC-SAFE',
      title: 'Safety Bonus',
      description: 'Quarterly reward for zero verified safety incidents.',
      qualification: '0 incidents • evidence verified',
      active: true,
    ),
    IncentiveRecord(
      id: 'INC-QUALITY',
      title: 'Quality Payout',
      description: 'Recognizes teams maintaining a 95% or higher quality score.',
      qualification: '95% quality threshold',
      active: true,
    ),
    IncentiveRecord(
      id: 'INC-EFFICIENCY',
      title: 'Efficiency Reward',
      description: 'Recognizes safe completion ahead of the baseline schedule.',
      qualification: 'On time • no quality regression',
      active: true,
    ),
  ];

  final List<PromotionCandidate> promotionCandidates = <PromotionCandidate>[
    PromotionCandidate(
      id: 'PC-8842-A',
      name: 'David Clarke',
      currentRole: 'Carpenter Lead',
      targetRole: 'Master Carpenter',
      qualityScore: .98,
      speedIndex: 1.2,
      attendance: 1,
      routingTarget: 'Thornton Cluster A3',
    ),
    PromotionCandidate(
      id: 'PC-8848-B',
      name: 'Jason Reid',
      currentRole: 'Assistant Carpenter',
      targetRole: 'Carpenter',
      qualityScore: .96,
      speedIndex: 1.1,
      attendance: .98,
      routingTarget: 'Miles Town Cluster 2',
    ),
  ];

  final List<String> controlTileOrder = <String>[
    'work-plan',
    'documents',
    'schedule',
    'team-resources',
    'transfers',
    'site-visits',
    'daily-log',
    'materials',
    'consumables',
    'inventory',
    'live-briefing',
    'monitoring',
    'final-inspection',
    'production-review',
    'completion',
    'payment',
  ];
  final Set<String> hiddenControlTiles = <String>{};
  final Map<String, bool> adminFeatures = <String, bool>{
    'Automated transfers': true,
    'Centralized parish and cluster control': true,
    'Cluster geography management': true,
    'Parish location management': true,
    'Multi-parish inventory': true,
    'Storage health alerts': true,
    'Notification priorities': true,
    'Manual override approvals': true,
    'Payment payout logic': true,
    'Safety bonus logic': true,
    'Construction schedule policy': true,
    'Repair details library': true,
    'Legacy data import': false,
    'AI paper mapping review': true,
    'Automatic cloud synchronization': true,
  };

  String selectedTransferId = 'TRF-8924A';
  String controlGrouping = 'Lifecycle';
  String controlDensity = 'Comfortable';
  bool controlShowHero = true;
  bool controlShowInsights = true;
  bool autoRoutingEnabled = true;
  bool autoTransferEnabled = true;
  int safetyIncidentThreshold = 0;
  String safetyCalculationPeriod = 'Quarterly';
  bool safetyAutoApply = true;
  bool hqReportApproved = false;

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
  int get pendingTransfers => transfers
      .where((transfer) => transfer.status == 'Pending approval')
      .length;
  int get crewsDeployed =>
      crews.where((crew) => crew.availability == 'Deployed').length;
  double get averageCrewQuality => crews.isEmpty
      ? 0
      : crews.fold<double>(0, (sum, crew) => sum + crew.qualityScore) /
          crews.length;
  TransferRecord get selectedTransfer => transfers.firstWhere(
        (transfer) => transfer.id == selectedTransferId,
        orElse: () => transfers.first,
      );
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

  void approveCompletion(String houseCode) {
    final house = houseByCode(houseCode);
    house.phase = LifecyclePhase.closeOut;
    house.status = RecordStatus.approved;
    house.progress = 1;
    house.nextAction = 'Prepare payment submission';
    _recordActivity(
      houseCode: houseCode,
      title: 'Completion approved',
      detail: 'Close-out evidence and signatures passed review.',
      icon: Icons.verified_outlined,
    );
    _markChanged();
  }

  void approvePayment(String houseCode) {
    final house = houseByCode(houseCode);
    house.phase = LifecyclePhase.finance;
    house.status = RecordStatus.approved;
    house.nextAction = 'Release approved payment';
    _recordActivity(
      houseCode: houseCode,
      title: 'Payment approved',
      detail: 'Finance review passed and the payout is ready to release.',
      icon: Icons.price_check_outlined,
    );
    _markChanged();
  }

  void markPaymentPaid(String houseCode) {
    final house = houseByCode(houseCode);
    house.phase = LifecyclePhase.finance;
    house.status = RecordStatus.paid;
    house.nextAction = 'Archive the complete production record';
    _recordActivity(
      houseCode: houseCode,
      title: 'Payment released',
      detail: 'The payment status is now paid.',
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

  String createTransfer({
    required String category,
    required String resource,
    required int quantity,
    required String origin,
    required String destination,
    required String houseCode,
    required String urgency,
    required String reason,
    required bool temporary,
  }) {
    final id = 'TRF-${DateTime.now().millisecondsSinceEpoch}';
    transfers.insert(
      0,
      TransferRecord(
        id: id,
        category: category,
        resource: resource,
        quantity: quantity,
        origin: origin,
        destination: destination,
        houseCode: houseCode,
        urgency: urgency,
        reason: reason,
        startDate: DateTime.now(),
        endDate: temporary ? DateTime.now().add(const Duration(days: 3)) : null,
        budgetImpact: category == 'Personnel' ? quantity * 400 : quantity * 35,
        status: 'Pending approval',
      ),
    );
    selectedTransferId = id;
    notifications.insert(
      0,
      AppNotification(
        id: 'N-$id',
        title: 'Transfer request needs approval',
        detail: '$resource requested for $houseCode from $origin.',
        time: DateTime.now(),
        priority: urgency == 'Critical' ? 'High' : 'Action',
        houseCode: houseCode,
      ),
    );
    _recordActivity(
      houseCode: houseCode,
      title: 'Transfer request created',
      detail: '$resource • $origin to $destination • $urgency',
      icon: Icons.swap_horiz_outlined,
    );
    _markChanged();
    return id;
  }

  void selectTransfer(String id) {
    selectedTransferId = id;
    notifyListeners();
  }

  void updateTransferStatus(String id, String status) {
    final transfer = transfers.firstWhere((item) => item.id == id);
    transfer.status = status;
    _recordActivity(
      houseCode: transfer.houseCode,
      title: 'Transfer $status',
      detail: '${transfer.id} • ${transfer.resource}',
      icon: status == 'Declined'
          ? Icons.cancel_outlined
          : Icons.local_shipping_outlined,
    );
    if (status == 'Approved') {
      notifications.insert(
        0,
        AppNotification(
          id: 'N-${DateTime.now().microsecondsSinceEpoch}',
          title: 'Transfer approved',
          detail: '${transfer.resource} approved for ${transfer.houseCode}.',
          time: DateTime.now(),
          priority: 'Info',
          houseCode: transfer.houseCode,
        ),
      );
    }
    _markChanged();
  }

  void assignCrew(String crewId, String houseCode) {
    final crew = crews.firstWhere((item) => item.id == crewId);
    final house = houseByCode(houseCode);
    crew.currentHouse = houseCode;
    crew.cluster = house.cluster;
    crew.parish = house.parish;
    crew.currentPhase = house.phase.label;
    crew.availability = 'Deployed';
    _recordActivity(
      houseCode: houseCode,
      title: '${crew.name} assigned',
      detail: '${crew.members.length} team members routed to ${house.cluster}.',
      icon: Icons.groups_outlined,
    );
    _markChanged();
  }

  void addShoutOut({required String crew, required String message}) {
    shoutOuts.insert(
      0,
      ShoutOutRecord(
        id: 'SH-${DateTime.now().microsecondsSinceEpoch}',
        message: message,
        author: 'Andre Brown',
        crew: crew,
        createdAt: DateTime.now(),
      ),
    );
    _recordActivity(
      houseCode: selectedHouseCode,
      title: 'Team shout-out published',
      detail: '$crew • $message',
      icon: Icons.campaign_outlined,
    );
    _markChanged();
  }

  void publishAward({required String crew, required String reason}) {
    addShoutOut(
      crew: crew,
      message: '$crew received Team of the Month recognition: $reason',
    );
    notifications.insert(
      0,
      AppNotification(
        id: 'N-AWARD-${DateTime.now().microsecondsSinceEpoch}',
        title: 'Team award published',
        detail: '$crew is now featured in Team Excellence.',
        time: DateTime.now(),
        priority: 'Info',
      ),
    );
    notifyListeners();
  }

  void toggleIncentive(String id) {
    final incentive = incentives.firstWhere((item) => item.id == id);
    incentive.active = !incentive.active;
    _recordActivity(
      houseCode: selectedHouseCode,
      title: 'Incentive configuration updated',
      detail: '${incentive.title}: ${incentive.active ? 'Active' : 'Paused'}',
      icon: Icons.workspace_premium_outlined,
    );
    _markChanged();
  }

  void promoteCandidate(String id) {
    final candidate = promotionCandidates.firstWhere((item) => item.id == id);
    candidate.promoted = true;
    for (final member in team.where((item) => item.name == candidate.name)) {
      member.role = candidate.targetRole;
    }
    _recordActivity(
      houseCode: selectedHouseCode,
      title: 'Promotion approved',
      detail:
          '${candidate.name}: ${candidate.currentRole} to ${candidate.targetRole}; routed to ${candidate.routingTarget}.',
      icon: Icons.military_tech_outlined,
    );
    _markChanged();
  }

  void updateSafetyPolicy({
    required int incidentThreshold,
    required String calculationPeriod,
    required bool autoApply,
  }) {
    safetyIncidentThreshold = incidentThreshold;
    safetyCalculationPeriod = calculationPeriod;
    safetyAutoApply = autoApply;
    _recordActivity(
      houseCode: selectedHouseCode,
      title: 'Safety incentive policy updated',
      detail:
          '$calculationPeriod • $incidentThreshold incident threshold • auto apply ${autoApply ? 'on' : 'off'}.',
      icon: Icons.health_and_safety_outlined,
    );
    _markChanged();
  }

  void setAutoTransfer(bool enabled) {
    autoTransferEnabled = enabled;
    _recordActivity(
      houseCode: selectedHouseCode,
      title: 'Transfer automation updated',
      detail: enabled
          ? 'Automated transfer proposals are enabled; approval remains required.'
          : 'Automated transfer proposals are paused.',
      icon: Icons.swap_horiz_outlined,
    );
    _markChanged();
  }

  void setAutoRouting(bool enabled) {
    autoRoutingEnabled = enabled;
    _recordActivity(
      houseCode: selectedHouseCode,
      title: 'Promotion routing updated',
      detail: enabled
          ? 'Qualified promotion candidates can be routed automatically.'
          : 'Promotion routing now requires a manual destination.',
      icon: Icons.route_outlined,
    );
    _markChanged();
  }

  void toggleAdminFeature(String name) {
    adminFeatures[name] = !(adminFeatures[name] ?? false);
    _recordActivity(
      houseCode: selectedHouseCode,
      title: 'System configuration updated',
      detail: '$name: ${adminFeatures[name]! ? 'Enabled' : 'Disabled'}',
      icon: Icons.settings_suggest_outlined,
    );
    _markChanged();
  }

  void toggleControlTile(String id) {
    if (!hiddenControlTiles.add(id)) hiddenControlTiles.remove(id);
    notifyListeners();
  }

  void moveControlTile(String id, int offset) {
    final oldIndex = controlTileOrder.indexOf(id);
    if (oldIndex < 0) return;
    final newIndex = (oldIndex + offset)
        .clamp(0, controlTileOrder.length - 1)
        .toInt();
    if (oldIndex == newIndex) return;
    controlTileOrder
      ..removeAt(oldIndex)
      ..insert(newIndex, id);
    notifyListeners();
  }

  void setControlGrouping(String grouping) {
    controlGrouping = grouping;
    notifyListeners();
  }

  void setControlDensity(String density) {
    controlDensity = density;
    notifyListeners();
  }

  void setControlSectionVisibility({
    bool? showHero,
    bool? showInsights,
  }) {
    if (showHero != null) controlShowHero = showHero;
    if (showInsights != null) controlShowInsights = showInsights;
    notifyListeners();
  }

  void resetControlLayout() {
    controlTileOrder
      ..clear()
      ..addAll(<String>[
        'work-plan',
        'documents',
        'schedule',
        'team-resources',
        'transfers',
        'site-visits',
        'daily-log',
        'materials',
        'consumables',
        'inventory',
        'live-briefing',
        'monitoring',
        'final-inspection',
        'production-review',
        'completion',
        'payment',
      ]);
    hiddenControlTiles.clear();
    controlGrouping = 'Lifecycle';
    controlDensity = 'Comfortable';
    controlShowHero = true;
    controlShowInsights = true;
    notifyListeners();
  }

  void advanceSchedule(String houseCode) {
    final house = houseByCode(houseCode);
    final index = LifecyclePhase.values.indexOf(house.phase);
    if (index < LifecyclePhase.values.length - 1) {
      house.phase = LifecyclePhase.values[index + 1];
      house.progress = (house.progress + .15).clamp(0, 1).toDouble();
      house.status = RecordStatus.active;
      house.nextAction = 'Complete ${house.phase.label} requirements';
    }
    _recordActivity(
      houseCode: houseCode,
      title: 'Construction schedule advanced',
      detail: '${house.code} moved to ${house.phase.label}.',
      icon: Icons.event_available_outlined,
    );
    _markChanged();
  }

  void approveHqReport() {
    hqReportApproved = true;
    _recordActivity(
      houseCode: selectedHouseCode,
      title: 'Institutional report approved',
      detail: 'HQ verification and sign-off recorded.',
      icon: Icons.verified_user_outlined,
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
