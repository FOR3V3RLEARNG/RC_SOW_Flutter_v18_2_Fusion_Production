import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_models.dart';

class RcSowRepository {
  RcSowRepository(this.client);

  final SupabaseClient client;

  User? get user => client.auth.currentUser;

  Future<UserProfile?> currentProfile() async {
    final id = user?.id;
    if (id == null) {
      return null;
    }
    final row = await client
        .from('profiles')
        .select()
        .eq('user_id', id)
        .maybeSingle();
    if (row == null) {
      return null;
    }
    return UserProfile.fromMap(Map<String, dynamic>.from(row));
  }

  Future<void> touchPresence({bool active = true}) async {
    if (user == null) {
      return;
    }
    await client.rpc(
      'touch_presence',
      params: {'p_active': active, 'p_push_token': ''},
    );
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
        .limit(150);
    return rows
        .map(
          (raw) => MessageRecord.fromEvent(
            Map<String, dynamic>.from(raw),
            profile.email,
          ),
        )
        .toList();
  }

  Future<void> markMessageRead(
    MessageRecord message,
    UserProfile profile,
  ) async {
    final row = await client
        .from('app_events')
        .select()
        .eq('event_type', 'message')
        .eq('item_id', message.id)
        .maybeSingle();
    if (row == null) {
      return;
    }
    final raw = Map<String, dynamic>.from(row);
    final item = Map<String, dynamic>.from(raw['item'] as Map? ?? const {});
    final readBy =
        (item['readBy'] as List?)?.map((value) => '$value').toSet() ??
            <String>{};
    readBy.add(profile.email);
    item['readBy'] = readBy.toList();
    await _upsertEvent(
      type: 'message',
      itemId: message.id,
      parish: raw['parish'] as String?,
      houseCode: raw['house_code'] as String?,
      recipients: (raw['recipients'] as List? ?? const [])
          .map((value) => '$value')
          .toList(),
      item: item,
    );
  }

  Future<void> sendMessage({
    required UserProfile profile,
    required String subject,
    required String body,
    required List<String> recipients,
    String? parish,
    String? replyTo,
    String? threadId,
  }) async {
    if (recipients.isEmpty) {
      throw ArgumentError('At least one message recipient is required.');
    }
    final id = 'msg-${DateTime.now().microsecondsSinceEpoch}';
    await _upsertEvent(
      type: 'message',
      itemId: id,
      parish: parish ?? (profile.canViewAllParishes ? null : profile.parish),
      recipients: recipients,
      item: {
        'subject': subject,
        'body': body,
        'senderName': profile.fullName ?? profile.email,
        'fromEmail': profile.email,
        'readBy': [profile.email],
        'threadId': threadId ?? replyTo ?? id,
        if (replyTo != null) 'replyTo': replyTo,
      },
    );
  }

  Future<List<ActiveUserRecord>> activeUsers() async {
    await touchPresence();
    final result = await client.rpc('list_active_users');
    return (result as List? ?? const [])
        .map(
          (raw) => ActiveUserRecord.fromMap(
            Map<String, dynamic>.from(raw as Map),
          ),
        )
        .where((record) => record.online)
        .toList();
  }

  Future<List<ManagedUserRecord>> managedUsers() async {
    final result = await client.rpc('list_managed_users');
    return (result as List? ?? const [])
        .map(
          (raw) => ManagedUserRecord.fromMap(
            Map<String, dynamic>.from(raw as Map),
          ),
        )
        .toList();
  }

  Future<void> manageUserAccess({
    required String userId,
    required String action,
    String? role,
    String? parish,
    Map<String, dynamic>? privileges,
  }) async {
    await client.rpc(
      'manage_user_access',
      params: {
        'p_user_id': userId,
        'p_action': action,
        'p_role': role,
        'p_parish': parish,
        'p_privileges': privileges,
      },
    );
  }

  Future<List<Map<String, dynamic>>> registrationRequests() async {
    final result = await client.rpc('list_registration_requests');
    return (result as List? ?? const [])
        .map((raw) => Map<String, dynamic>.from(raw as Map))
        .toList();
  }

  Future<void> approveRegistration(String userId) async {
    await client.rpc(
      'approve_registration_request',
      params: {'p_user_id': userId},
    );
  }

  Future<void> rejectRegistration(String userId) async {
    await client.rpc(
      'reject_registration_request',
      params: {'p_user_id': userId},
    );
  }

  Future<List<BeneficiaryRecord>> beneficiaries({
    String query = '',
    int limit = 100,
  }) async {
    final result = await client.rpc(
      'search_beneficiaries',
      params: {'p_query': query.trim(), 'p_limit': limit},
    );
    return (result as List? ?? const [])
        .map(
          (raw) => BeneficiaryRecord.fromMap(
            Map<String, dynamic>.from(raw as Map),
          ),
        )
        .toList();
  }

  Future<BeneficiaryRecord?> beneficiaryByHouse(String houseCode) async {
    final row = await client
        .from('beneficiary_directory')
        .select()
        .eq('house_code', houseCode.trim().toUpperCase())
        .maybeSingle();
    if (row == null) {
      return null;
    }
    return BeneficiaryRecord.fromMap(Map<String, dynamic>.from(row));
  }

  Future<int> bulkUpsertBeneficiaries(
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) {
      return 0;
    }
    final result = await client.rpc(
      'upsert_beneficiary_directory',
      params: {'p_rows': rows},
    );
    return result is num ? result.toInt() : rows.length;
  }

  Future<List<Map<String, dynamic>>> liveTrackers() async {
    final rows = await client
        .from('parish_live_trackers')
        .select()
        .eq('enabled', true)
        .order('parish');
    return rows.map((raw) => Map<String, dynamic>.from(raw)).toList();
  }

  Future<List<Map<String, dynamic>>> houseLocations(
    UserProfile profile,
  ) async {
    var query = client.from('house_locations').select();
    if (!profile.canViewAllParishes && profile.parish.isNotEmpty) {
      query = query.eq('parish', profile.parish);
    }
    final rows = await query.order('house_code');
    return rows.map((raw) => Map<String, dynamic>.from(raw)).toList();
  }

  Future<List<ProductionRecord>> productionRecords(
    UserProfile profile,
  ) async {
    var query = client.from('app_events').select();
    if (!profile.canViewAllParishes && profile.parish.isNotEmpty) {
      query = query.eq('parish', profile.parish);
    }
    final rows = await query.order('updated_at', ascending: false).limit(500);
    const types = {
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
        .map((raw) => Map<String, dynamic>.from(raw))
        .where((row) => types.contains('${row['event_type'] ?? ''}'))
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
    await _upsertEvent(
      type: eventType,
      itemId: id,
      parish: parish,
      houseCode: houseCode,
      item: item,
    );
  }

  Future<void> submitScope({
    required UserProfile profile,
    required String id,
    required String houseCode,
    required String parish,
    required Map<String, dynamic> item,
  }) async {
    await _upsertEvent(
      type: 'scope',
      itemId: id,
      parish: parish,
      houseCode: houseCode,
      item: item,
    );
  }

  Future<void> _upsertEvent({
    required String type,
    required String itemId,
    required Map<String, dynamic> item,
    String? parish,
    String? houseCode,
    List<String> recipients = const [],
  }) async {
    final normalized = <String, dynamic>{
      ...item,
      'id': itemId,
      if (parish != null && parish.trim().isNotEmpty) 'parish': parish.trim(),
      if (houseCode != null && houseCode.trim().isNotEmpty)
        'houseCode': houseCode.trim().toUpperCase(),
      'recipients': recipients,
    };
    await client.rpc(
      'upsert_app_event',
      params: {
        'p_event': {'type': type, 'item': normalized},
      },
    );
  }

  String debugSummary(UserProfile? profile) => jsonEncode({
        'connected': user != null,
        'role': profile?.role,
        'parish': profile?.parish,
        'adminVisible': profile?.canViewAdmin,
        'allParishes': profile?.canViewAllParishes,
      });
}
