import 'package:flutter_test/flutter_test.dart';
import 'package:rc_sow_connected/core/app_state.dart';
import 'package:rc_sow_connected/core/models.dart';

void main() {
  group('connected operational state', () {

    test('production state starts without demo records', () {
      final state = AppState.production();

      expect(state.houses, isEmpty);
      expect(state.evidence, isEmpty);
      expect(state.notifications, isEmpty);
      expect(state.selectedHouseCode, isEmpty);
    });

    test('new production house does not receive a fake crew', () {
      final state = AppState.production();

      final created = state.createHouse(
        code: 'P01',
        beneficiary: 'Production Beneficiary',
        parish: 'Portland',
        cluster: 'Cluster 1',
        community: 'Community 1',
      );

      expect(created, isTrue);
      expect(state.selectedHouse.team, isEmpty);
    });

    test('targeted notification retains combined audiences', () {
      final state = AppState.production();

      state.createOperationalNotification(
        title: 'Coordination meeting',
        detail: 'Meet at 10:00',
        priority: 'Action',
        kind: 'Meeting',
        audiences: const <String>[
          'Parish • Hanover',
          'Regional Supervisors',
        ],
      );

      expect(state.notifications, hasLength(1));
      expect(
        state.notifications.first.audiences,
        containsAll(<String>['Parish • Hanover', 'Regional Supervisors']),
      );
    });


    test('production activity automatically creates house notification', () {
      final state = AppState.production();

      state.createHouse(
        code: 'H100',
        beneficiary: 'Beneficiary',
        parish: 'Hanover',
        cluster: 'Cluster A',
        community: 'Community A',
      );

      expect(state.notifications, isNotEmpty);
      expect(state.notifications.first.houseCode, 'H100');
      expect(
        state.notifications.first.audiences,
        contains('Parish • Hanover'),
      );
      expect(
        state.notifications.first.audiences,
        contains('Regional Supervisors'),
      );
    });

    test('submitted production record creates status notification', () {
      final state = AppState.production();
      state.createHouse(
        code: 'H101',
        beneficiary: 'Beneficiary',
        parish: 'Hanover',
        cluster: 'Cluster A',
        community: 'Community A',
      );
      final before = state.notifications.length;

      state.saveForm(
        type: 'Work Plan',
        houseCode: 'H101',
        values: const <String, String>{'milestone': 'Roof framing'},
        submit: true,
      );

      expect(state.notifications.length, before + 1);
      expect(state.notifications.first.title, contains('submitted'));
      expect(state.notifications.first.houseCode, 'H101');
    });

    test('payment notification includes Accounts audience', () {
      final state = AppState.production();
      state.createHouse(
        code: 'H102',
        beneficiary: 'Beneficiary',
        parish: 'Hanover',
        cluster: 'Cluster A',
        community: 'Community A',
      );

      state.submitPayment('H102');

      expect(state.notifications.first.title, contains('Payment submitted'));
      expect(state.notifications.first.audiences, contains('Accounts'));
    });

    test('prevents duplicate house controls', () {
      final state = AppState.seeded();

      final created = state.createHouse(
        code: 'H12',
        beneficiary: 'Duplicate Beneficiary',
        parish: 'Hanover',
        cluster: 'Cluster A',
        community: 'Thornton',
      );

      expect(created, isFalse);
      expect(state.houses.where((house) => house.code == 'H12'), hasLength(1));
    });

    test('creates a new control at Scope and selects it', () {
      final state = AppState.seeded();

      final created = state.createHouse(
        code: 'h21',
        beneficiary: 'A New Beneficiary',
        parish: 'Hanover',
        cluster: 'Miles Town Cluster 2',
        community: 'Miles Town',
      );

      expect(created, isTrue);
      expect(state.selectedHouseCode, 'H21');
      expect(state.selectedHouse.phase, LifecyclePhase.scope);
      expect(state.activities.first.houseCode, 'H21');
    });

    test('offline saves queue changes without losing the draft', () {
      final state = AppState.seeded()..toggleOffline();

      state.saveForm(
        type: 'Daily Site Log',
        houseCode: 'H12',
        values: const <String, String>{'workDone': 'Rafter installation'},
      );

      expect(
        state.formDrafts['H12:Daily Site Log']?['workDone'],
        'Rafter installation',
      );
      expect(state.queuedChanges, 1);
      expect(state.syncCondition, SyncCondition.waiting);
    });

    test('completion and payment update the same house lifecycle', () {
      final state = AppState.seeded();

      state.submitCompletion('H2');
      expect(state.houseByCode('H2').phase, LifecyclePhase.closeOut);
      expect(state.houseByCode('H2').status, RecordStatus.submitted);

      state.submitPayment('H2');
      expect(state.houseByCode('H2').phase, LifecyclePhase.finance);
      expect(state.houseByCode('H2').nextAction, 'Track payment approval');
    });

    test('inventory reconciliation writes an audit event', () {
      final state = AppState.seeded();
      final item = state.inventory.first;

      state.updateInventory(
        itemName: item.name,
        delivered: 7,
        additions: 1,
        leftovers: 2,
      );

      expect(item.delivered, 7);
      expect(item.used, 6);
      expect(state.activities.first.title, 'Inventory reconciled');
    });
  });
}
