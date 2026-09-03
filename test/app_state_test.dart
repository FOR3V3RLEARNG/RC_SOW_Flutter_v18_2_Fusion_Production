import 'package:flutter_test/flutter_test.dart';
import 'package:rc_sow_connected/core/app_state.dart';
import 'package:rc_sow_connected/core/models.dart';

void main() {
  group('connected operational state', () {
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
