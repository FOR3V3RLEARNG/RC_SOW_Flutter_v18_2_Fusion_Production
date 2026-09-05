import 'package:flutter/material.dart';

import 'models.dart';
import 'routes.dart';

class ControlModuleDefinition {
  const ControlModuleDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.phase,
    required this.icon,
    required this.route,
    required this.priority,
  });

  final String id;
  final String title;
  final String description;
  final LifecyclePhase phase;
  final IconData icon;
  final String route;
  final int priority;
}

abstract final class ControlModules {
  static const List<ControlModuleDefinition> all = <ControlModuleDefinition>[
    ControlModuleDefinition(
      id: 'production-board',
      title: 'Production Command Board',
      description: 'See today’s blockers, capacity, stock and approvals.',
      phase: LifecyclePhase.plan,
      icon: Icons.space_dashboard_outlined,
      route: RcRoutes.productionBoard,
      priority: 1,
    ),
    ControlModuleDefinition(
      id: 'work-plan',
      title: 'Work Plan',
      description: 'Plan sequence, owners, dates and crew.',
      phase: LifecyclePhase.plan,
      icon: Icons.event_note_outlined,
      route: RcRoutes.workPlan,
      priority: 1,
    ),
    ControlModuleDefinition(
      id: 'work-projections',
      title: 'Work Projection Log',
      description: 'One signed weekly file per admin staff member with daily 09:00–17:00 or custom hours and role-scoped review.',
      phase: LifecyclePhase.plan,
      icon: Icons.trending_up_outlined,
      route: RcRoutes.workProjections,
      priority: 2,
    ),
    ControlModuleDefinition(
      id: 'documents',
      title: 'Document Checklist',
      description: 'Keep required documents visible and complete.',
      phase: LifecyclePhase.plan,
      icon: Icons.library_books_outlined,
      route: RcRoutes.documentChecklist,
      priority: 4,
    ),
    ControlModuleDefinition(
      id: 'schedule',
      title: 'Construction Schedule',
      description: 'Coordinate house phases, blockers, dates and teams.',
      phase: LifecyclePhase.plan,
      icon: Icons.event_available_outlined,
      route: RcRoutes.schedule,
      priority: 2,
    ),
    ControlModuleDefinition(
      id: 'team-resources',
      title: 'Team Resource Manager',
      description: 'Assign crews and balance field capacity.',
      phase: LifecyclePhase.plan,
      icon: Icons.groups_2_outlined,
      route: RcRoutes.teamResources,
      priority: 3,
    ),
    ControlModuleDefinition(
      id: 'transfers',
      title: 'Transfer Management',
      description: 'Request, approve and track personnel or materials.',
      phase: LifecyclePhase.delivery,
      icon: Icons.swap_horiz_outlined,
      route: RcRoutes.transfers,
      priority: 1,
    ),
    ControlModuleDefinition(
      id: 'site-visits',
      title: 'Site Visits',
      description: 'Record technical visits, calls and findings.',
      phase: LifecyclePhase.delivery,
      icon: Icons.location_on_outlined,
      route: RcRoutes.siteVisits,
      priority: 3,
    ),
    ControlModuleDefinition(
      id: 'daily-log',
      title: 'Daily Site Log',
      description: 'Capture attendance, work progress and issues.',
      phase: LifecyclePhase.delivery,
      icon: Icons.edit_note_outlined,
      route: RcRoutes.dailyLog,
      priority: 2,
    ),
    ControlModuleDefinition(
      id: 'control-work-log',
      title: 'Control of Work Log',
      description: 'Record crew, progress, work, materials and blockers.',
      phase: LifecyclePhase.delivery,
      icon: Icons.playlist_add_check_circle_outlined,
      route: RcRoutes.workLogs,
      priority: 1,
    ),
    ControlModuleDefinition(
      id: 'materials',
      title: 'Material Request',
      description: 'Request house-level materials against inventory.',
      phase: LifecyclePhase.delivery,
      icon: Icons.local_shipping_outlined,
      route: RcRoutes.materialRequest,
      priority: 4,
    ),
    ControlModuleDefinition(
      id: 'consumables',
      title: 'Consumables',
      description: 'Track tools and consumable field requests.',
      phase: LifecyclePhase.delivery,
      icon: Icons.handyman_outlined,
      route: RcRoutes.consumableRequest,
      priority: 6,
    ),
    ControlModuleDefinition(
      id: 'inventory',
      title: 'Inventory Reconciliation',
      description: 'Connect BOQ, delivered, additions and leftovers.',
      phase: LifecyclePhase.delivery,
      icon: Icons.inventory_2_outlined,
      route: RcRoutes.inventory,
      priority: 5,
    ),
    ControlModuleDefinition(
      id: 'inventory-transfer',
      title: 'Parish / House Stock Transfer',
      description: 'Move materials between depot, cluster and house ledgers.',
      phase: LifecyclePhase.delivery,
      icon: Icons.move_down_outlined,
      route: RcRoutes.inventoryTransfer,
      priority: 4,
    ),
    ControlModuleDefinition(
      id: 'sync-monitor',
      title: 'Offline Sync Monitor',
      description: 'Inspect device queues, backend health and retry status.',
      phase: LifecyclePhase.delivery,
      icon: Icons.sync_outlined,
      route: RcRoutes.syncMonitor,
      priority: 8,
    ),
    ControlModuleDefinition(
      id: 'live-briefing',
      title: 'Live Team Briefing',
      description: 'Coordinate the house team and document decisions.',
      phase: LifecyclePhase.delivery,
      icon: Icons.video_camera_front_outlined,
      route: RcRoutes.liveBriefing,
      priority: 7,
    ),
    ControlModuleDefinition(
      id: 'monitoring',
      title: 'Monitoring Checklist',
      description: 'Inspect technical criteria with evidence.',
      phase: LifecyclePhase.quality,
      icon: Icons.fact_check_outlined,
      route: RcRoutes.monitoring,
      priority: 1,
    ),
    ControlModuleDefinition(
      id: 'final-inspection',
      title: 'Final Inspection',
      description: 'Confirm safety, workmanship and close-out readiness.',
      phase: LifecyclePhase.quality,
      icon: Icons.verified_outlined,
      route: RcRoutes.finalInspection,
      priority: 2,
    ),
    ControlModuleDefinition(
      id: 'production-review',
      title: 'Production Review',
      description: 'Review issues, evidence, approvals and resources.',
      phase: LifecyclePhase.quality,
      icon: Icons.manage_search_outlined,
      route: RcRoutes.productionCommand,
      priority: 3,
    ),
    ControlModuleDefinition(
      id: 'completion',
      title: 'Notice of Completion',
      description: 'Complete signatures and evidence readiness.',
      phase: LifecyclePhase.closeOut,
      icon: Icons.task_alt_outlined,
      route: RcRoutes.completion,
      priority: 1,
    ),
    ControlModuleDefinition(
      id: 'payment',
      title: 'Payment Submission',
      description: 'Review allocation, approvals and finance state.',
      phase: LifecyclePhase.finance,
      icon: Icons.payments_outlined,
      route: RcRoutes.payment,
      priority: 1,
    ),
  ];

  static ControlModuleDefinition byId(String id) =>
      all.firstWhere((module) => module.id == id);
}
