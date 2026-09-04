import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rc_sow_connected/core/app_state.dart';
import 'package:rc_sow_connected/core/production_models.dart';

void main() {
  group('v20 production state', () {
    test('control of work updates the durable house context', () {
      final state = AppState.seeded();

      state.addWorkLog(
        houseCode: 'H12',
        category: 'Roof installation',
        detail: 'East slope zinc fixed and overlaps checked.',
        hours: 7.5,
        progress: 72,
        crewPresent: const <String>['Andre Brown', 'Michael Grant'],
        materialsUsed: '8 zinc sheets; 48 zinc screws',
        blocker: 'Ridge cap delivery pending',
        nextAction: 'Michael to confirm ridge cap by 08:00',
      );

      expect(state.workLogs.first.progress, 72);
      expect(state.workLogs.first.crewPresent, hasLength(2));
      expect(state.houseByCode('H12').progress, .72);
      expect(state.houseByCode('H12').blocker, contains('Ridge cap'));
      expect(state.houseByCode('H12').nextAction, contains('Michael'));
    });

    test('stock transfer debits source and credits destination', () {
      final state = AppState.seeded();
      final source = state.stockLedger.firstWhere(
        (item) => item.id == 'STK-HAN-ZINC',
      );
      final destination = state.stockLedger.firstWhere(
        (item) => item.id == 'STK-H12-ZINC',
      );
      final sourceBefore = source.onHand;
      final destinationBefore = destination.onHand;

      final moved = state.transferStock(
        sourceId: source.id,
        destinationId: destination.id,
        quantity: 12,
      );

      expect(moved, isTrue);
      expect(source.onHand, sourceBefore - 12);
      expect(destination.onHand, destinationBefore + 12);
      expect(state.activities.first.title, 'Inventory transfer recorded');
    });

    test('stock transfer blocks mismatched materials and overdraw', () {
      final state = AppState.seeded();

      expect(
        state.transferStock(
          sourceId: 'STK-HAN-RIDGE',
          destinationId: 'STK-H12-ZINC',
          quantity: 1,
        ),
        isFalse,
      );
      expect(
        state.transferStock(
          sourceId: 'STK-HAN-ZINC',
          destinationId: 'STK-H12-ZINC',
          quantity: 10000,
        ),
        isFalse,
      );
    });

    test('weekly projection records capacity and supports approval', () {
      final state = AppState.seeded();
      final id = state.addWorkProjection(
        weekStarting: DateTime(2026, 9, 7),
        houseCode: 'H12',
        milestone: 'Roof watertight',
        estimatedHours: 48,
        crewNeeded: 3,
        materialNeeds: '12 zinc sheets',
        risks: 'Transfer timing',
        submit: true,
      );

      final projection =
          state.workProjections.firstWhere((item) => item.id == id);
      expect(projection.status, ProjectionStatus.submitted);
      state.approveProjection(id);
      expect(projection.status, ProjectionStatus.approved);
      state.updateProjectionActual(id, 24);
      expect(projection.actualHours, 24);
    });

    test('legacy CSV creates a reviewable mapping before import', () async {
      final state = AppState.seeded();
      final bytes = Uint8List.fromList(
        utf8.encode(
          'house_code,beneficiary_name,parish,cluster,gps\n'
          'H88,Janet Brown,Hanover,Miles Town,18.4 -78.1\n',
        ),
      );

      final batch = await state.previewLegacyImport(
        fileName: 'legacy.csv',
        bytes: bytes,
      );

      expect(batch.rowCount, 1);
      expect(batch.canImport, isTrue);
      expect(batch.mappedFields, greaterThanOrEqualTo(5));
      await state.commitLegacyImport(batch);
      expect(batch.status, LegacyImportStatus.queued);
    });

    test('image review returns an editable proposal offline', () async {
      final state = AppState.seeded();

      final suggestion = await state.analyzeRoofImage(
        fileName: 'field-sketch.jpg',
        bytes: Uint8List.fromList(<int>[1, 2, 3]),
      );

      expect(suggestion.document.houseCode, 'H12');
      expect(suggestion.document.sections, isNotEmpty);
      expect(suggestion.overallConfidence, inInclusiveRange(0, 1));
    });
  });
}
