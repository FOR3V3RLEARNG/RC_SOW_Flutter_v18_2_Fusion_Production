import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_models.dart';

class RcSowRepository {
  RcSowRepository(this.client);

  final SupabaseClient client;

  User? get user => client.auth.currentUser;

  Future<UserProfile?> currentProfile() async {
    final id = user?.id;
    if (id == null) return null;
    final row = await client.from('profiles').select().eq('user_id', id).maybeSingle();
    if (row == null) return null;
    return UserProfile.fromMap(Map<String, dynamic>.from(row));
  }

  Future<List<HouseRecord>> houses(UserProfile profile) async {
    var query = client.from('app_events').select().eq('event_type', 'house');
    if (!profile.canViewAllParishes && profile.parish.isNotEmpty) {
      query = query.eq('parish', profile.parish);
    }
    final rows = await query.order('updated_at', ascending: false);
    final byCode = <String, HouseRecord>{};
    for (final raw in rows) {
      final house = HouseRecord.fromEvent(Map<String, dynamic>.from(raw));
      byCode.putIfAbsent(house.code, () => house);
    }
    return byCode.values.toList();
  }

  Future<List<MessageRecord>> messages(UserProfile profile) async {
    final rows = await client
        .from('app_events')
        .select()
        .eq('event_type', 'message')
        .order('created_at', ascending: false)
        .limit(100);
    return rows
        .map((e) => MessageRecord.fromEvent(Map<String, dynamic>.from(e), profile.email))
        .toList();
  }

  Future<void> markMessageRead(MessageRecord message, UserProfile profile) async {
    final row = await client
        .from('app_events')
        .select()
        .eq('event_type', 'message')
        .eq('item_id', message.id)
        .maybeSingle();
    if (row == null) return;
    final item = Map<String, dynamic>.from(row['item'] as Map? ?? const {});
    final readBy = (item['readBy'] as List?)?.map((e) => '$e').toSet() ?? <String>{};
    readBy.add(profile.email);
    item['readBy'] = readBy.toList();
    await client.rpc('upsert_app_event', params: {
      'p_event': {
        'event_type': 'message',
        'item_id': message.id,
        'parish': row['parish'],
        'house_code': row['house_code'],
        'recipients': row['recipients'] ?? [],
        'item': item,
      },
    });
  }

  Future<void> sendMessage({
    required UserProfile profile,
    required String subject,
    required String body,
    String? parish,
  }) async {
    final id = 'msg-${DateTime.now().microsecondsSinceEpoch}';
    await client.rpc('upsert_app_event', params: {
      'p_event': {
        'event_type': 'message',
        'item_id': id,
        'parish': parish ?? (profile.canViewAllParishes ? null : profile.parish),
        'recipients': [],
        'item': {
          'subject': subject,
          'body': body,
          'senderName': profile.fullName ?? profile.email,
          'readBy': [profile.email],
        },
      },
    });
  }

  Future<List<Map<String, dynamic>>> activeUsers() async {
    final result = await client.rpc('list_active_users');
    return (result as List? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> registrationRequests() async {
    final result = await client.rpc('list_registration_requests');
    return (result as List? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> approveRegistration(String userId) async {
    await client.rpc('approve_registration_request', params: {'p_user_id': userId});
  }

  Future<void> rejectRegistration(String userId) async {
    await client.rpc('reject_registration_request', params: {'p_user_id': userId});
  }

  Future<List<Map<String, dynamic>>> liveTrackers() async {
    final rows = await client
        .from('parish_live_trackers')
        .select()
        .eq('enabled', true)
        .order('parish');
    return rows.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> houseLocations(UserProfile profile) async {
    var query = client.from('house_locations').select();
    if (!profile.canViewAllParishes && profile.parish.isNotEmpty) {
      query = query.eq('parish', profile.parish);
    }
    final rows = await query.order('house_code');
    return rows.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<ProductionRecord>> productionRecords(UserProfile profile) async {
    var query = client.from('app_events').select();
    if (!profile.canViewAllParishes && profile.parish.isNotEmpty) {
      query = query.eq('parish', profile.parish);
    }
    final rows = await query.order('updated_at', ascending: false).limit(250);
    const productionTypes = {
      'scope',
      'controlData',
      'workPlan',
      'monitoring',
      'siteVisit',
      'dailyLog',
      'documentChecklist',
      'materialRequest',
      'consumables',
      'inventory',
      'notice',
      'payment',
    };
    return rows
        .map((e) => Map<String, dynamic>.from(e))
        .where((row) => productionTypes.contains('${row['event_type'] ?? ''}'))
        .map(ProductionRecord.fromEvent)
        .toList();
  }

  Future<void> submitControlEvent({
    required UserProfile profile,
    required String eventType,
    required String houseCode,
    required String parish,
    required Map<String, dynamic> item,
  }) async {
    final id = '$eventType-${DateTime.now().microsecondsSinceEpoch}';
    await client.rpc('upsert_app_event', params: {
      'p_event': {
        'event_type': eventType,
        'item_id': id,
        'parish': parish,
        'house_code': houseCode,
        'recipients': [],
        'item': item,
      },
    });
  }

  String debugSummary(UserProfile? profile) => jsonEncode({
        'connected': user != null,
        'role': profile?.role,
        'parish': profile?.parish,
        'adminVisible': profile?.canViewAdmin,
      });
}
