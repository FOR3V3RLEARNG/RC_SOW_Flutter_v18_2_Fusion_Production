import 'package:flutter_test/flutter_test.dart';
import 'package:rc_sow_flutter/models/app_models.dart';

void main() {
  test('production record maps lifecycle status and attention state', () {
    final record = ProductionRecord.fromEvent({
      'event_type': 'monitoring',
      'item_id': 'm1',
      'house_code': 'H15',
      'parish': 'Hanover',
      'updated_at': '2026-08-20T12:00:00Z',
      'item': {'status': 'Blocked', 'summary': 'Awaiting correction'},
    });
    expect(record.title, 'Monitoring Checklist');
    expect(record.needsAttention, isTrue);
    expect(record.isClosed, isFalse);
    expect(record.houseCode, 'H15');
  });

  test('closed production statuses are recognized', () {
    final record = ProductionRecord.fromEvent({
      'event_type': 'payment',
      'item': {'status': 'Paid'},
    });
    expect(record.isClosed, isTrue);
  });
}
