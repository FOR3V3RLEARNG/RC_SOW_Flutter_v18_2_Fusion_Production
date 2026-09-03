import 'package:flutter_test/flutter_test.dart';
import 'package:rc_sow_connected/core/app_state.dart';
import 'package:rc_sow_connected/core/models.dart';

void main() {
  test('transfer workflow creates and advances a traceable request', () {
    final state = AppState.seeded();
    final originalCount = state.transfers.length;

    final id = state.createTransfer(
      category: 'Materials',
      resource: 'Hurricane straps',
      quantity: 24,
      origin: 'Hanover Central Depot',
      destination: 'Thornton Site Store',
      houseCode: 'H12',
      urgency: 'Critical',
      reason: 'Protect the delivery sequence.',
      temporary: false,
    );

    expect(state.transfers.length, originalCount + 1);
    expect(state.selectedTransferId, id);
    expect(state.selectedTransfer.status, 'Pending approval');

    state.updateTransferStatus(id, 'Approved');
    expect(state.selectedTransfer.status, 'Approved');
    state.updateTransferStatus(id, 'In transit');
    expect(state.selectedTransfer.status, 'In transit');
    state.updateTransferStatus(id, 'Completed');
    expect(state.selectedTransfer.status, 'Completed');
    expect(
      state.activities.any((entry) => entry.title == 'Transfer Completed'),
      isTrue,
    );
  });

  test('crew assignment, recognition and promotion update connected state', () {
    final state = AppState.seeded();
    final activityCount = state.activities.length;

    state.assignCrew('CREW-C', 'H15');
    expect(state.crews.firstWhere((crew) => crew.id == 'CREW-C').currentHouse,
        'H15');

    state.addShoutOut(
      crew: 'Charlie Team',
      message: 'Strong scope verification and beneficiary coordination.',
    );
    expect(state.shoutOuts.first.crew, 'Charlie Team');

    state.publishAward(
      crew: 'Charlie Team',
      reason: 'verified quality and community coordination',
    );
    expect(state.shoutOuts.first.message, contains('Team of the Month'));

    state.promoteCandidate('PC-8842-A');
    expect(state.promotionCandidates.first.promoted, isTrue);
    expect(
      state.team.firstWhere((member) => member.name == 'David Clarke').role,
      'Master Carpenter',
    );
    expect(state.activities.length, greaterThan(activityCount));
  });

  test('Control workspace supports tile visibility, ordering and reset', () {
    final state = AppState.seeded();
    final first = state.controlTileOrder.first;

    state.toggleControlTile(first);
    expect(state.hiddenControlTiles, contains(first));
    state.moveControlTile(first, 1);
    expect(state.controlTileOrder[1], first);
    state.setControlGrouping('Custom');
    state.setControlDensity('Compact');
    state.setControlSectionVisibility(showHero: false, showInsights: false);

    expect(state.controlGrouping, 'Custom');
    expect(state.controlDensity, 'Compact');
    expect(state.controlShowHero, isFalse);
    expect(state.controlShowInsights, isFalse);

    state.resetControlLayout();
    expect(state.controlTileOrder.first, 'work-plan');
    expect(state.hiddenControlTiles, isEmpty);
    expect(state.controlGrouping, 'Lifecycle');
    expect(state.controlDensity, 'Comfortable');
    expect(state.controlShowHero, isTrue);
    expect(state.controlShowInsights, isTrue);
  });

  test('schedule, approvals, finance and HQ report remain connected', () {
    final state = AppState.seeded();

    state.advanceSchedule('H12');
    expect(state.houseByCode('H12').phase, LifecyclePhase.quality);

    state.approveCompletion('H2');
    expect(state.houseByCode('H2').status, RecordStatus.approved);

    state.approvePayment('H1');
    expect(state.houseByCode('H1').status, RecordStatus.approved);
    state.markPaymentPaid('H1');
    expect(state.houseByCode('H1').status, RecordStatus.paid);

    state.approveHqReport();
    expect(state.hqReportApproved, isTrue);
  });

  test('automation policies are independently configurable', () {
    final state = AppState.seeded();

    state.setAutoTransfer(false);
    state.setAutoRouting(false);
    state.updateSafetyPolicy(
      incidentThreshold: 1,
      calculationPeriod: 'Monthly',
      autoApply: false,
    );

    expect(state.autoTransferEnabled, isFalse);
    expect(state.autoRoutingEnabled, isFalse);
    expect(state.safetyIncidentThreshold, 1);
    expect(state.safetyCalculationPeriod, 'Monthly');
    expect(state.safetyAutoApply, isFalse);
  });
}
