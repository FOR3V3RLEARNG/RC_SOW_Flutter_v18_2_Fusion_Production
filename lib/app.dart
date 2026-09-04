import 'package:flutter/material.dart';

import 'core/app_state.dart';
import 'core/routes.dart';
import 'core/theme.dart';
import 'core/widgets.dart';
import 'core/production_models.dart';
import 'screens/admin_screens.dart';
import 'screens/auth_screens.dart';
import 'screens/command_screens.dart';
import 'screens/control_layout_screen.dart';
import 'screens/form_screens.dart';
import 'screens/operation_screens.dart';
import 'screens/production_system_screens.dart';
import 'screens/shell.dart';
import 'screens/scope_screens.dart';
import 'screens/team_screens.dart';
import 'screens/transfer_screens.dart';

class RcSowApp extends StatelessWidget {
  const RcSowApp({required this.state, super.key});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          return MaterialApp(
            title: 'RC SOW Operations',
            debugShowCheckedModeBanner: false,
            theme: RcTheme.light(
              highContrast: state.highContrast,
              reducedMotion: state.reducedMotion,
            ),
            darkTheme: RcTheme.dark(
              highContrast: state.highContrast,
              reducedMotion: state.reducedMotion,
            ),
            themeMode: state.darkMode ? ThemeMode.dark : ThemeMode.light,
            initialRoute: RcRoutes.splash,
            onGenerateRoute: buildRcRoute,
          );
        },
      ),
    );
  }
}

Route<dynamic> buildRcRoute(RouteSettings settings) {
  final screen = switch (settings.name) {
    RcRoutes.splash => const RcSplashScreen(),
    RcRoutes.login => const LoginScreen(),
    RcRoutes.home || RcRoutes.dashboard => const AppShell(initialIndex: 0),
    RcRoutes.scopeHouse => const ScopeWorkspace(
        initialStep: 0,
        standalone: true,
      ),
    RcRoutes.scopeRoof => const ScopeWorkspace(
        initialStep: 1,
        standalone: true,
      ),
    RcRoutes.scopePrint => const ScopeWorkspace(
        initialStep: 2,
        standalone: true,
      ),
    RcRoutes.scopeFiles => const ScopeWorkspace(
        initialStep: 3,
        standalone: true,
      ),
    RcRoutes.scopeImport => ScopeImportScreen(
        seedDocument: settings.arguments is RoofDrawingDocument
            ? settings.arguments! as RoofDrawingDocument
            : null,
      ),
    RcRoutes.control => const AppShell(initialIndex: 2),
    RcRoutes.houses => const AppShell(initialIndex: 3),
    RcRoutes.houseCommand => const HouseCommandScreen(),
    RcRoutes.newControl => const NewControlScreen(),
    RcRoutes.workPlan => const OperationalFormScreen.workPlan(),
    RcRoutes.documentChecklist => const DocumentChecklistScreen(),
    RcRoutes.monitoring => const MonitoringChecklistScreen(),
    RcRoutes.siteVisits => const SiteVisitsScreen(),
    RcRoutes.siteVisitDetail => const SiteVisitDetailScreen(),
    RcRoutes.dailyLog => const OperationalFormScreen.dailyLog(),
    RcRoutes.materialRequest => const OperationalFormScreen.materialRequest(),
    RcRoutes.consumableRequest =>
      const OperationalFormScreen.consumableRequest(),
    RcRoutes.inventory => const InventoryScreen(),
    RcRoutes.addInventory => const InventoryEditScreen(),
    RcRoutes.inventoryTransfer => const InventoryTransferScreen(),
    RcRoutes.completion => const CompletionScreen(),
    RcRoutes.finalInspection => const FinalInspectionScreen(),
    RcRoutes.payment => const PaymentScreen(),
    RcRoutes.evidence => const EvidenceScreen(),
    RcRoutes.activity => const ActivityScreen(),
    RcRoutes.notifications => const NotificationsScreen(),
    RcRoutes.usersOnline => const UsersOnlineScreen(),
    RcRoutes.messages => const MessagesScreen(),
    RcRoutes.settings => const SettingsScreen(),
    RcRoutes.workLogs => const WorkLogsScreen(),
    RcRoutes.workProjections => const WorkProjectionScreen(),
    RcRoutes.productionBoard => const ProductionBoardScreen(),
    RcRoutes.syncMonitor => const SyncMonitorScreen(),
    RcRoutes.analytics => const AnalyticsScreen(),
    RcRoutes.operationalMap => const OperationalMapScreen(),
    RcRoutes.adminUsers => const AdminUsersScreen(),
    RcRoutes.adminTemplates => const AdminTemplatesScreen(),
    RcRoutes.gmail => const GmailScreen(),
    RcRoutes.transfers => const TransferHubScreen(),
    RcRoutes.newTransfer => const NewTransferScreen(),
    RcRoutes.transferDetail => const TransferDetailScreen(),
    RcRoutes.transferAutomation => const TransferAutomationScreen(),
    RcRoutes.teamCommunity => const TeamCommunityScreen(),
    RcRoutes.teamPerformance => const TeamPerformanceScreen(),
    RcRoutes.teamResources => const TeamResourceScreen(),
    RcRoutes.awardsIncentives => const AwardsIncentivesScreen(),
    RcRoutes.promotionRouting => const PromotionRoutingScreen(),
    RcRoutes.schedule => const ConstructionScheduleScreen(),
    RcRoutes.liveBriefing => const LiveBriefingScreen(),
    RcRoutes.productionCommand => const ProductionCommandScreen(),
    RcRoutes.financeCommand => const FinanceCommandScreen(),
    RcRoutes.hqCommand => const HqCommandScreen(),
    RcRoutes.institutionalReport => const InstitutionalReportScreen(),
    RcRoutes.adminCommand => const AdminCommandScreen(),
    RcRoutes.approvalQueue => const ApprovalQueueScreen(),
    RcRoutes.controlLayout => const ControlLayoutScreen(),
    _ => UnknownRouteScreen(routeName: settings.name ?? 'unknown'),
  };
  return MaterialPageRoute<dynamic>(builder: (_) => screen, settings: settings);
}

class UnknownRouteScreen extends StatelessWidget {
  const UnknownRouteScreen({required this.routeName, super.key});

  final String routeName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RcAppBar(title: const Text('Page unavailable')),
      body: Center(
        child: Text('No RC SOW screen is registered for $routeName.'),
      ),
    );
  }
}
