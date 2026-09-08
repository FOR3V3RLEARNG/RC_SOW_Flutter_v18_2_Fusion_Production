import 'package:flutter_test/flutter_test.dart';
import 'package:rc_sow_flutter/models/app_models.dart';

void main() {
  test('message event preserves notification category', () {
    final message = MessageRecord.fromEvent({
      'item_id': 'm-1',
      'created_at': '2026-09-08T12:00:00Z',
      'item': {
        'senderName': 'RC SOW',
        'fromEmail': 'admin@example.com',
        'fromRole': 'Admin',
        'subject': 'Signature required',
        'body': 'Please sign.',
        'priority': 'Action Required',
        'category': 'Signature Required',
        'readBy': <String>[],
      },
      'recipients': <Map<String, dynamic>>[],
    }, 'worker@example.com');

    expect(message.category, 'Signature Required');
    expect(message.priority, 'Action Required');
    expect(message.unread, isTrue);
  });
}
