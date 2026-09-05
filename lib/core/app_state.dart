import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'models.dart';
import 'production_models.dart';
import '../services/production_backend.dart';

class AppState extends ChangeNotifier {
  AppState._({
    required this.houses,
    required this.inventory,
    required this.evidence,
    required this.activities,
    required this.notifications,
    required this.team,
    required this.workLogs,
    required this.stockLedger,
    required this.workProjections,
    required this.productionIssues,
    required this.backend,
  });

  factory AppState.production({ProductionBackend? backend}) {
    final state = AppState.seeded(backend: backend);
    state.houses.clear();
    state.inventory.clear();
    state.evidence.clear();
    state.activities.clear();
    state.notifications.clear();
    state.team.clear();
    state.workLogs.clear();
    state.stockLedger.clear();
    state.workProjections.clear();
    state.productionIssues.clear();
    state.transfers.clear();
    state.crews.clear();
    state.communityEvents.clear();
    state.shoutOuts.clear();
    state.incentives.clear();
    state.promotionCandidates.clear();
    state.formDrafts.clear();
    state.completedDocuments.clear();
    state.monitoring.clear();
    state.monitoringComments.clear();
    state.roofDrawings.clear();
    state.selectedHouseCode = '';
    state.selectedTransferId = '';
    state.syncCondition = SyncCondition.synced;
    state.queuedChanges = 0;
    return state;
  }

  factory AppState.seeded({ProductionBackend? backend}) {
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
          team: <String>[],
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
          capturedBy: 'Seeded Site Supervisor',
          capturedAt: now.subtract(const Duration(days: 9)),
          approved: true,
        ),
        EvidenceItem(
          id: 'EV-118',
          houseCode: 'H12',
          type: 'During',
          caption: 'Wall plate and rafter installation',
          capturedBy: 'Seeded Site Supervisor',
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
          capturedBy: 'Seeded Site Supervisor',
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
      stockLedger: <StockLedgerItem>[
        StockLedgerItem(
          id: 'STK-HAN-RIDGE',
          materialCode: 'MAT-001',
          name: 'Ridge beam 2×8×20',
          unit: 'lengths',
          tier: InventoryTier.parish,
          parish: 'Hanover',
          location: 'Hanover Central Depot',
          zone: 'Zone A • Lumber',
          opening: 40,
          received: 20,
          issued: 15,
          adjustments: 0,
          minimumStock: 18,
          unitCostJmd: 9800,
          updatedAt: now.subtract(const Duration(minutes: 18)),
        ),
        StockLedgerItem(
          id: 'STK-HAN-RAFTER',
          materialCode: 'MAT-002',
          name: 'Rafters / Collars 2×6×14',
          unit: 'lengths',
          tier: InventoryTier.parish,
          parish: 'Hanover',
          location: 'Hanover Central Depot',
          zone: 'Zone A • Lumber',
          opening: 110,
          received: 50,
          issued: 40,
          adjustments: 0,
          minimumStock: 45,
          unitCostJmd: 6200,
          updatedAt: now.subtract(const Duration(minutes: 18)),
        ),
        StockLedgerItem(
          id: 'STK-HAN-ZINC',
          materialCode: 'MAT-042',
          name: 'Zinc 26 gauge 36 in × 14 ft',
          unit: 'sheets',
          tier: InventoryTier.parish,
          parish: 'Hanover',
          location: 'Hanover Central Depot',
          zone: 'Zone B • Roofing',
          opening: 470,
          received: 180,
          issued: 300,
          adjustments: 0,
          minimumStock: 400,
          unitCostJmd: 7400,
          updatedAt: now.subtract(const Duration(minutes: 18)),
        ),
        StockLedgerItem(
          id: 'STK-SEL-ZINC',
          materialCode: 'MAT-042',
          name: 'Zinc 26 gauge 36 in × 14 ft',
          unit: 'sheets',
          tier: InventoryTier.parish,
          parish: 'St. Elizabeth',
          location: 'St. Elizabeth Depot',
          zone: 'Zone B • Roofing',
          opening: 520,
          received: 220,
          issued: 190,
          adjustments: 4,
          minimumStock: 300,
          unitCostJmd: 7400,
          updatedAt: now.subtract(const Duration(minutes: 29)),
        ),
        StockLedgerItem(
          id: 'STK-WES-ZINC',
          materialCode: 'MAT-042',
          name: 'Zinc 26 gauge 36 in × 14 ft',
          unit: 'sheets',
          tier: InventoryTier.parish,
          parish: 'Westmoreland',
          location: 'Savanna-la-Mar Depot',
          zone: 'Zone B • Roofing',
          opening: 250,
          received: 80,
          issued: 205,
          adjustments: -3,
          minimumStock: 160,
          unitCostJmd: 7400,
          updatedAt: now.subtract(const Duration(hours: 2)),
          liveSynced: false,
        ),
        StockLedgerItem(
          id: 'STK-THO-ZINC',
          materialCode: 'MAT-042',
          name: 'Zinc 26 gauge 36 in × 14 ft',
          unit: 'sheets',
          tier: InventoryTier.cluster,
          parish: 'Hanover',
          cluster: 'Thornton Cluster A3',
          location: 'Thornton Site Store',
          zone: 'Roofing rack',
          opening: 60,
          received: 20,
          issued: 68,
          adjustments: 0,
          minimumStock: 24,
          unitCostJmd: 7400,
          updatedAt: now.subtract(const Duration(minutes: 41)),
        ),
        StockLedgerItem(
          id: 'STK-H12-ZINC',
          materialCode: 'MAT-042',
          name: 'Zinc 26 gauge 36 in × 14 ft',
          unit: 'sheets',
          tier: InventoryTier.house,
          parish: 'Hanover',
          cluster: 'Thornton Cluster A3',
          houseCode: 'H12',
          location: 'H12 secured site store',
          opening: 0,
          received: 16,
          issued: 12,
          adjustments: 0,
          minimumStock: 12,
          unitCostJmd: 7400,
          updatedAt: now.subtract(const Duration(hours: 1)),
        ),
        StockLedgerItem(
          id: 'STK-H12-STRAP',
          materialCode: 'MAT-063',
          name: 'Hurricane straps H3',
          unit: 'pieces',
          tier: InventoryTier.house,
          parish: 'Hanover',
          cluster: 'Thornton Cluster A3',
          houseCode: 'H12',
          location: 'H12 secured site store',
          opening: 0,
          received: 100,
          issued: 88,
          adjustments: 0,
          minimumStock: 8,
          unitCostJmd: 620,
          updatedAt: now.subtract(const Duration(hours: 1)),
        ),
      ],
      workProjections: <WorkProjection>[
        WorkProjection(
          id: 'PRJ-42-H12',
          weekStarting: DateTime(2026, 9, 7),
          parish: 'Hanover',
          cluster: 'Thornton Cluster A3',
          houseCode: 'H12',
          milestone: 'Roofing complete',
          estimatedHours: 120,
          actualHours: 76,
          crewNeeded: 3,
          materialNeeds: '12 zinc sheets; 1 roll coiled strap',
          risks: 'Zinc transfer approval required by Monday 08:00.',
          status: ProjectionStatus.atRisk,
        ),
        WorkProjection(
          id: 'PRJ-42-H2',
          weekStarting: DateTime(2026, 9, 7),
          parish: 'Hanover',
          cluster: 'Haughton Grove Cluster 1',
          houseCode: 'H2',
          milestone: 'Final inspection and handover',
          estimatedHours: 32,
          actualHours: 22,
          crewNeeded: 2,
          materialNeeds: 'Gutter end caps; certificate pack',
          risks: 'Homeowner signature appointment not confirmed.',
          status: ProjectionStatus.submitted,
        ),
        WorkProjection(
          id: 'PRJ-42-H18',
          weekStarting: DateTime(2026, 9, 7),
          parish: 'Hanover',
          cluster: 'Miles Town Cluster 2',
          houseCode: 'H18',
          milestone: 'Scope and work plan approved',
          estimatedHours: 24,
          actualHours: 8,
          crewNeeded: 1,
          materialNeeds: 'Measurement kit; beneficiary printout',
          risks: 'Secondary structure dimensions need verification.',
          status: ProjectionStatus.draft,
        ),
      ],
      productionIssues: <ProductionIssue>[
        ProductionIssue(
          id: 'ISS-H12-ZINC',
          houseCode: 'H12',
          title: '12 sheets of 14 ft zinc awaiting transfer',
          owner: 'Maria Green',
          dueAt: now.add(const Duration(hours: 18)),
          severity: ProductionIssueSeverity.critical,
        ),
        ProductionIssue(
          id: 'ISS-H2-SIGN',
          houseCode: 'H2',
          title: 'Confirm homeowner handover signature time',
          owner: 'Andre Brown',
          dueAt: now.add(const Duration(days: 2)),
          severity: ProductionIssueSeverity.warning,
        ),
      ],
      backend: backend ?? const LocalProductionBackend(),
    );
  }

  final List<HouseRecord> houses;
  final List<InventoryItem> inventory;
  final List<EvidenceItem> evidence;
  final List<ActivityEntry> activities;
  final List<AppNotification> notifications;
  final List<TeamMember> team;
  final List<WorkLogEntry> workLogs;
  final List<StockLedgerItem> stockLedger;
  final List<WorkProjection> workProjections;
  final List<ProductionIssue> productionIssues;
  final List<LegacyImportBatch> importBatches = <LegacyImportBatch>[];
  final Map<String, RoofDrawingDocument> roofDrawings =
      <String, RoofDrawingDocument>{};
  final ProductionBackend backend;
  final List<BackendWrite> pendingBackendWrites = <BackendWrite>[];

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
    'production-board',
    'work-plan',
    'work-projections',
    'documents',
    'schedule',
    'team-resources',
    'transfers',
    'site-visits',
    'daily-log',
    'control-work-log',
    'materials',
    'consumables',
    'inventory',
    'inventory-transfer',
    'sync-monitor',
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
  TransferRecord get selectedTransfer {
    for (final transfer in transfers) {
      if (transfer.id == selectedTransferId) return transfer;
    }
    return TransferRecord(
      id: 'UNASSIGNED',
      category: '',
      resource: '',
      quantity: 0,
      origin: '',
      destination: '',
      houseCode: '',
      urgency: 'Routine',
      reason: '',
      startDate: DateTime.now(),
      budgetImpact: 0,
      status: 'Draft',
    );
  }
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

  bool get remoteConnected => backend.connected;
  String get backendConnectionLabel => backend.connectionLabel;
  int get unresolvedProductionIssues =>
      productionIssues.where((issue) => !issue.resolved).length;
  int get atRiskProjections => workProjections
      .where((projection) => projection.status == ProjectionStatus.atRisk)
      .length;
  double get projectedHours => workProjections.fold<double>(
        0,
        (sum, projection) => sum + projection.estimatedHours,
      );
  double get recordedProjectionHours => workProjections.fold<double>(
        0,
        (sum, projection) => sum + projection.actualHours,
      );
  double get parishStockValueJmd => stockLedger
      .where((item) => item.tier == InventoryTier.parish)
      .fold<double>(0, (sum, item) => sum + item.stockValueJmd);

  List<StockLedgerItem> inventoryFor({
    InventoryTier? tier,
    String? parish,
    String? cluster,
    String? houseCode,
  }) =>
      stockLedger.where((item) {
        if (tier != null && item.tier != tier) return false;
        if (parish != null && item.parish != parish) return false;
        if (cluster != null && item.cluster != cluster) return false;
        if (houseCode != null && item.houseCode != houseCode) return false;
        return true;
      }).toList();

  HouseRecord houseByCode(String code) {
    for (final house in houses) {
      if (house.code == code) return house;
    }
    return HouseRecord(
      code: code.trim().isEmpty ? 'UNASSIGNED' : code,
      beneficiary: '',
      parish: selectedParish,
      cluster: '',
      community: '',
      phase: LifecyclePhase.scope,
      status: RecordStatus.draft,
      progress: 0,
      evidenceComplete: 0,
      evidenceRequired: 0,
      nextAction: 'Create or import a house before entering production records',
      team: <String>[],
    );
  }

  Future<void> bootstrapSession() async {
    if (!backend.connected) return;
    try {
      final profile = await backend.currentProfile();
      if (profile == null || !profile.approved) return;
      authenticated = true;
      role = _displayRole(profile.role);
      if (profile.assignedParishes.isNotEmpty) {
        selectedParish = profile.assignedParishes.first;
      }
      syncCondition = SyncCondition.synced;
      notifyListeners();
    } catch (_) {
      syncCondition = SyncCondition.failed;
      notifyListeners();
    }
  }

  Future<bool> requestSecureEmailSignIn({
    required String email,
    required String selectedRole,
  }) async {
    if (!backend.connected) {
      login(selectedRole: selectedRole);
      return true;
    }
    await backend.requestMagicLink(email);
    return false;
  }

  Future<bool> signInWithGoogle({required String selectedRole}) async {
    if (!backend.connected) {
      login(selectedRole: selectedRole);
      return true;
    }
    await backend.signInWithGoogle();
    return false;
  }

  void login({required String selectedRole}) {
    authenticated = true;
    role = selectedRole;
    notifyListeners();
  }

  void logout() {
    unawaited(backend.signOut());
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
        team: <String>[],
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
    if (offline) {
      syncCondition =
          queuedChanges > 0 ? SyncCondition.waiting : SyncCondition.savedLocal;
    } else if (pendingBackendWrites.isNotEmpty && backend.connected) {
      syncCondition = SyncCondition.syncing;
      unawaited(_flushPendingWrites());
    } else {
      queuedChanges = 0;
      syncCondition = SyncCondition.synced;
    }
    notifyListeners();
  }

  Future<void> retrySync() async {
    if (offline) {
      syncCondition = queuedChanges > 0
          ? SyncCondition.waiting
          : SyncCondition.savedLocal;
      notifyListeners();
      return;
    }
    if (backend.connected && pendingBackendWrites.isNotEmpty) {
      syncCondition = SyncCondition.syncing;
      notifyListeners();
      await _flushPendingWrites();
      return;
    }
    queuedChanges = 0;
    syncCondition = SyncCondition.synced;
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
    _dispatchWrite(
      BackendWrite(
        houseCode: houseCode,
        parish: house.parish,
        recordType: type,
        status: submit ? 'submitted' : 'draft',
        payload: <String, dynamic>{
          ...values,
          'house_code': houseCode,
          'lifecycle_phase': house.phase.name,
        },
        idempotencyKey:
            '$houseCode-${type.toLowerCase().replaceAll(' ', '-')}-${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
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
        capturedBy: role,
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

  void createOperationalNotification({
    required String title,
    required String detail,
    required String priority,
    required String kind,
    required List<String> audiences,
    String? houseCode,
    DateTime? scheduledFor,
  }) {
    notifications.insert(
      0,
      AppNotification(
        id: 'N-${DateTime.now().microsecondsSinceEpoch}',
        title: title,
        detail: detail,
        time: DateTime.now(),
        priority: priority,
        houseCode: houseCode,
        audiences: audiences,
        sender: role,
        scheduledFor: scheduledFor,
        kind: kind,
      ),
    );
    final notification = notifications.first;
    final effectiveHouseCode = houseCode?.trim() ?? '';
    final parish = _isProductionHouse(effectiveHouseCode)
        ? houseByCode(effectiveHouseCode).parish
        : selectedParish;
    _dispatchWrite(
      BackendWrite(
        houseCode: effectiveHouseCode,
        parish: parish,
        recordType: 'Broadcast Notification',
        status: scheduledFor == null ? 'sent' : 'scheduled',
        payload: <String, dynamic>{
          'notification_id': notification.id,
          'title': title,
          'detail': detail,
          'priority': priority,
          'kind': kind,
          'audiences': audiences,
          'sender': role,
          'house_code': houseCode,
          'scheduled_for': scheduledFor?.toIso8601String(),
          'created_at': notification.time.toIso8601String(),
        },
        idempotencyKey: notification.id,
      ),
    );
    syncCondition = offline ? SyncCondition.savedLocal : SyncCondition.synced;
    notifyListeners();
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
    double progress = 0,
    List<String> crewPresent = const <String>[],
    String materialsUsed = '',
    String blocker = '',
    String nextAction = '',
  }) {
    final house = houseByCode(houseCode);
    workLogs.insert(
      0,
      WorkLogEntry(
        id: 'WL-${DateTime.now().millisecondsSinceEpoch}',
        user: role,
        role: role,
        parish: selectedParish,
        houseCode: houseCode,
        category: category,
        detail: detail,
        hours: hours,
        createdAt: DateTime.now(),
        progress: progress,
        crewPresent: List<String>.from(crewPresent),
        materialsUsed: materialsUsed,
        blocker: blocker,
        nextAction: nextAction,
      ),
    );
    if (progress > 0) {
      house.progress = (progress / 100).clamp(0, 1).toDouble();
    }
    if (blocker.trim().isNotEmpty) {
      house.blocker = blocker.trim();
      house.status = RecordStatus.attention;
    }
    if (nextAction.trim().isNotEmpty) house.nextAction = nextAction.trim();
    _recordActivity(
      houseCode: houseCode,
      title: 'Work log saved',
      detail: '$category • ${hours.toStringAsFixed(1)} hours',
      icon: Icons.schedule_outlined,
    );
    _markChanged();
    _dispatchWrite(
      BackendWrite(
        houseCode: houseCode,
        parish: house.parish,
        recordType: 'Control of Work Log',
        payload: <String, dynamic>{
          'category': category,
          'detail': detail,
          'hours': hours,
          'progress_percent': progress,
          'crew_present': crewPresent,
          'materials_used': materialsUsed,
          'blocker': blocker,
          'next_action': nextAction,
        },
        idempotencyKey:
            '$houseCode-work-log-${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
  }

  RoofDrawingDocument roofDrawingFor(String houseCode) {
    return roofDrawings.putIfAbsent(houseCode, () {
      final section = defaultRoofSection();
      final house = houseByCode(houseCode);
      section
        ..roofType = house.roofType
        ..lengthFt = house.roofArea > 0 ? 24 : 24.5
        ..widthFt = house.roofArea > 0
            ? (house.roofArea / 24).clamp(8, 60).toDouble()
            : 18;
      return RoofDrawingDocument(
        houseCode: houseCode,
        sections: <RoofSection>[section],
        selectedSectionId: section.id,
        updatedAt: DateTime.now(),
      );
    });
  }

  void saveRoofDrawing(RoofDrawingDocument document, {bool submit = false}) {
    final copy = document.deepCopy()..updatedAt = DateTime.now();
    roofDrawings[document.houseCode] = copy;
    final house = houseByCode(document.houseCode);
    house
      ..roofType = copy.selectedSection.roofType
      ..roofArea = copy.totalPlanAreaSqFt;
    saveForm(
      type: 'Scope Roof Drawing',
      houseCode: document.houseCode,
      submit: submit,
      values: <String, String>{
        'roofType': copy.selectedSection.roofType,
        'structures': '${copy.sections.length}',
        'areaSqFt': copy.totalPlanAreaSqFt.toStringAsFixed(1),
        'source': copy.source,
        'sourceFile': copy.sourceFileName ?? '',
        'aiConfidence': copy.aiConfidence?.toStringAsFixed(3) ?? '',
        'drawing': copy.toMap().toString(),
      },
    );
  }

  Future<AiRoofSuggestion> analyzeRoofImage({
    required String fileName,
    required Uint8List bytes,
  }) async {
    try {
      return await backend.analyzeRoofImage(
        houseCode: selectedHouseCode,
        fileName: fileName,
        bytes: bytes,
      );
    } on Object {
      syncCondition = SyncCondition.failed;
      notifyListeners();
      return const LocalProductionBackend().analyzeRoofImage(
        houseCode: selectedHouseCode,
        fileName: fileName,
        bytes: bytes,
      );
    }
  }

  Future<LegacyImportBatch> previewLegacyImport({
    required String fileName,
    required Uint8List bytes,
  }) async {
    LegacyImportBatch batch;
    try {
      batch = await backend.previewLegacyImport(
        fileName: fileName,
        bytes: bytes,
      );
    } on Object {
      syncCondition = SyncCondition.failed;
      batch = await const LocalProductionBackend().previewLegacyImport(
        fileName: fileName,
        bytes: bytes,
      );
    }
    importBatches.insert(0, batch);
    notifyListeners();
    return batch;
  }

  Future<void> commitLegacyImport(LegacyImportBatch batch) async {
    if (!batch.canImport) {
      throw StateError('Map every required field before importing.');
    }
    batch.status = offline || !backend.connected
        ? LegacyImportStatus.queued
        : LegacyImportStatus.imported;
    _recordActivity(
      houseCode: selectedHouseCode,
      title: 'Legacy import ${batch.status.label.toLowerCase()}',
      detail: '${batch.fileName} • ${batch.rowCount} rows • '
          '${batch.mappedFields} fields mapped.',
      icon: Icons.upload_file_outlined,
    );
    _markChanged();
    if (backend.connected && !offline) {
      try {
        await backend.commitLegacyImport(batch);
      } on Object {
        batch.status = LegacyImportStatus.queued;
        syncCondition = SyncCondition.failed;
        notifyListeners();
      }
    }
  }

  String addWorkProjection({
    required DateTime weekStarting,
    required String houseCode,
    required String milestone,
    required double estimatedHours,
    required int crewNeeded,
    required String materialNeeds,
    required String risks,
    bool submit = false,
  }) {
    final house = houseByCode(houseCode);
    final id = 'PRJ-${DateTime.now().microsecondsSinceEpoch}';
    final projection = WorkProjection(
      id: id,
      weekStarting: weekStarting,
      parish: house.parish,
      cluster: house.cluster,
      houseCode: houseCode,
      milestone: milestone,
      estimatedHours: estimatedHours,
      actualHours: 0,
      crewNeeded: crewNeeded,
      materialNeeds: materialNeeds,
      risks: risks,
      status: submit ? ProjectionStatus.submitted : ProjectionStatus.draft,
    );
    workProjections.insert(0, projection);
    _recordActivity(
      houseCode: houseCode,
      title: submit ? 'Weekly projection submitted' : 'Weekly projection saved',
      detail:
          '$milestone • ${estimatedHours.toStringAsFixed(1)} hours • $crewNeeded people.',
      icon: Icons.trending_up_outlined,
    );
    _markChanged();
    _dispatchWrite(
      BackendWrite(
        houseCode: houseCode,
        parish: house.parish,
        recordType: 'Weekly Projection',
        status: projection.status.name,
        payload: <String, dynamic>{
          'week_starting': weekStarting.toIso8601String(),
          'cluster': house.cluster,
          'milestone': milestone,
          'estimated_hours': estimatedHours,
          'crew_needed': crewNeeded,
          'material_needs': materialNeeds,
          'risks': risks,
        },
        idempotencyKey: id,
      ),
    );
    return id;
  }

  void updateProjectionActual(String id, double hours) {
    final projection = workProjections.firstWhere((item) => item.id == id);
    final previousStatus = projection.status;
    projection.actualHours = hours.clamp(0, 500).toDouble();
    if (projection.actualHours > projection.estimatedHours * 1.2) {
      projection.status = ProjectionStatus.atRisk;
    } else if (projection.actualHours >= projection.estimatedHours) {
      projection.status = ProjectionStatus.complete;
    }
    _recordActivity(
      houseCode: projection.houseCode,
      title: previousStatus == projection.status
          ? 'Production hours updated'
          : 'Production status changed',
      detail:
          '${projection.milestone} • ${projection.actualHours.toStringAsFixed(1)} actual hours • ${projection.status.label}.',
      icon: projection.status == ProjectionStatus.atRisk
          ? Icons.warning_amber_outlined
          : Icons.trending_up_outlined,
    );
    _markChanged();
  }

  void approveProjection(String id) {
    final projection = workProjections.firstWhere((item) => item.id == id);
    projection.status = ProjectionStatus.approved;
    _recordActivity(
      houseCode: projection.houseCode,
      title: 'Weekly projection approved',
      detail: '${projection.milestone} • ${projection.estimatedHours} hours.',
      icon: Icons.fact_check_outlined,
    );
    _markChanged();
  }

  void updateStockLedger({
    required String id,
    required double received,
    required double issued,
    required double adjustments,
  }) {
    final item = stockLedger.firstWhere((record) => record.id == id);
    item
      ..received = received
      ..issued = issued
      ..adjustments = adjustments
      ..updatedAt = DateTime.now()
      ..liveSynced = !offline;
    _recordActivity(
      houseCode: item.houseCode ?? selectedHouseCode,
      title: '${item.tier.label} stock reconciled',
      detail: '${item.name} • ${item.onHand.toStringAsFixed(0)} ${item.unit} '
          'on hand at ${item.location}.',
      icon: Icons.inventory_2_outlined,
    );
    _markChanged();
    _dispatchWrite(
      BackendWrite(
        houseCode: item.houseCode ?? selectedHouseCode,
        parish: item.parish,
        recordType: 'Inventory Ledger',
        payload: <String, dynamic>{
          'stock_id': item.id,
          'material_code': item.materialCode,
          'tier': item.tier.name,
          'cluster': item.cluster,
          'location': item.location,
          'opening': item.opening,
          'received': item.received,
          'issued': item.issued,
          'adjustments': item.adjustments,
          'on_hand': item.onHand,
        },
        idempotencyKey:
            '${item.id}-stock-${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
  }

  bool transferStock({
    required String sourceId,
    required String destinationId,
    required double quantity,
  }) {
    if (quantity <= 0 || sourceId == destinationId) return false;
    final source = stockLedger.firstWhere((item) => item.id == sourceId);
    final destination =
        stockLedger.firstWhere((item) => item.id == destinationId);
    if (source.materialCode != destination.materialCode ||
        source.onHand < quantity) {
      return false;
    }
    source
      ..issued += quantity
      ..updatedAt = DateTime.now()
      ..liveSynced = !offline;
    destination
      ..received += quantity
      ..updatedAt = DateTime.now()
      ..liveSynced = !offline;
    _recordActivity(
      houseCode: destination.houseCode ?? selectedHouseCode,
      title: 'Inventory transfer recorded',
      detail: '${quantity.toStringAsFixed(0)} ${source.unit} of '
          '${source.name}: ${source.scopeLabel} → ${destination.scopeLabel}.',
      icon: Icons.swap_horiz_outlined,
    );
    _markChanged();
    _dispatchWrite(
      BackendWrite(
        houseCode: destination.houseCode ?? selectedHouseCode,
        parish: destination.parish,
        recordType: 'Inventory Transfer',
        status: 'completed',
        payload: <String, dynamic>{
          'source_stock_id': sourceId,
          'destination_stock_id': destinationId,
          'material_code': source.materialCode,
          'quantity': quantity,
          'unit': source.unit,
        },
        idempotencyKey:
            'stock-transfer-${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    return true;
  }

  void resolveProductionIssue(String id) {
    final issue = productionIssues.firstWhere((item) => item.id == id);
    issue.resolved = true;
    _recordActivity(
      houseCode: issue.houseCode,
      title: 'Production issue resolved',
      detail: issue.title,
      icon: Icons.task_alt_outlined,
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
        author: role,
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
        'production-board',
        'work-plan',
        'work-projections',
        'documents',
        'schedule',
        'team-resources',
        'transfers',
        'site-visits',
        'daily-log',
        'control-work-log',
        'materials',
        'consumables',
        'inventory',
        'inventory-transfer',
        'sync-monitor',
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

  void _dispatchWrite(BackendWrite write) {
    if (!backend.connected) return;
    if (offline) {
      pendingBackendWrites.add(write);
      return;
    }
    syncCondition = SyncCondition.syncing;
    notifyListeners();
    unawaited(
      backend.writeRecord(write).then((_) {
        syncCondition = SyncCondition.synced;
        notifyListeners();
      }).catchError((Object _) {
        if (!pendingBackendWrites.any(
          (pending) => pending.idempotencyKey == write.idempotencyKey,
        )) {
          pendingBackendWrites.add(write);
        }
        queuedChanges = pendingBackendWrites.length;
        syncCondition = SyncCondition.failed;
        notifyListeners();
      }),
    );
  }

  Future<void> _flushPendingWrites() async {
    final writes = List<BackendWrite>.from(pendingBackendWrites);
    for (final write in writes) {
      try {
        await backend.writeRecord(write);
        pendingBackendWrites.removeWhere(
          (pending) => pending.idempotencyKey == write.idempotencyKey,
        );
      } catch (_) {
        queuedChanges = pendingBackendWrites.length;
        syncCondition = SyncCondition.failed;
        notifyListeners();
        return;
      }
    }
    queuedChanges = 0;
    syncCondition = SyncCondition.synced;
    notifyListeners();
  }

  String _displayRole(String value) {
    final words = value.replaceAll('_', ' ').split(' ');
    return words
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  void _recordActivity({
    required String houseCode,
    required String title,
    required String detail,
    required IconData icon,
    bool createNotification = true,
  }) {
    final now = DateTime.now();
    activities.insert(
      0,
      ActivityEntry(
        id: 'ACT-${now.microsecondsSinceEpoch}',
        houseCode: houseCode,
        title: title,
        detail: detail,
        actor: role,
        time: now,
        icon: icon,
      ),
    );

    if (createNotification && _isProductionHouse(houseCode)) {
      final house = houseByCode(houseCode);
      final audiences = _productionAudiencesFor(house, title);
      final priority = _productionPriority(title, house);
      final notification = AppNotification(
        id: 'AUTO-${now.microsecondsSinceEpoch}',
        title: '${house.code} • $title',
        detail: detail,
        time: now,
        priority: priority,
        houseCode: house.code,
        audiences: audiences,
        sender: role,
        kind: _productionNotificationKind(title),
      );
      notifications.insert(0, notification);

      _dispatchWrite(
        BackendWrite(
          houseCode: house.code,
          parish: house.parish,
          recordType: 'Production Notification',
          status: 'new',
          payload: <String, dynamic>{
            'notification_id': notification.id,
            'title': notification.title,
            'detail': notification.detail,
            'priority': notification.priority,
            'kind': notification.kind,
            'audiences': notification.audiences,
            'sender': notification.sender,
            'house_code': house.code,
            'lifecycle_phase': house.phase.name,
            'record_status': house.status.name,
            'progress_percent': (house.progress * 100).round(),
            'created_at': now.toIso8601String(),
          },
          idempotencyKey: '${notification.id}-${house.code}',
        ),
      );
    }
  }

  bool _isProductionHouse(String houseCode) {
    final normalized = houseCode.trim().toUpperCase();
    if (normalized.isEmpty || normalized == 'UNASSIGNED') return false;
    return houses.any((house) => house.code == normalized);
  }

  List<String> _productionAudiencesFor(HouseRecord house, String title) {
    final audiences = <String>{
      'Crew • ${house.code}',
      'Parish • ${house.parish}',
      'Regional Supervisors',
      'Construction Specialists',
    };
    for (final member in house.team) {
      if (member.trim().isNotEmpty) {
        audiences.add('Individual • ${member.trim()}');
      }
    }
    final normalized = title.toLowerCase();
    if (normalized.contains('payment') ||
        normalized.contains('finance') ||
        normalized.contains('completion approved')) {
      audiences.add('Accounts');
    }
    return audiences.toList(growable: false);
  }

  String _productionPriority(String title, HouseRecord house) {
    final normalized = title.toLowerCase();
    if (house.needsAttention ||
        normalized.contains('issue') ||
        normalized.contains('blocker') ||
        normalized.contains('at risk') ||
        normalized.contains('failed')) {
      return 'High';
    }
    if (normalized.contains('submitted') ||
        normalized.contains('approval') ||
        normalized.contains('transfer') ||
        normalized.contains('completion') ||
        normalized.contains('payment')) {
      return 'Action';
    }
    return 'Info';
  }

  String _productionNotificationKind(String title) {
    final normalized = title.toLowerCase();
    if (normalized.contains('payment') || normalized.contains('finance')) {
      return 'Finance';
    }
    if (normalized.contains('completion') ||
        normalized.contains('inspection') ||
        normalized.contains('monitoring')) {
      return 'Quality / Close-out';
    }
    if (normalized.contains('material') ||
        normalized.contains('inventory') ||
        normalized.contains('transfer')) {
      return 'Materials / Logistics';
    }
    if (normalized.contains('work plan') ||
        normalized.contains('projection') ||
        normalized.contains('work log')) {
      return 'Production';
    }
    if (normalized.contains('scope') ||
        normalized.contains('boq') ||
        normalized.contains('roof')) {
      return 'Scope / Technical';
    }
    return 'Operational';
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
