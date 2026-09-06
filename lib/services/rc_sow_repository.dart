import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_models.dart';

class RcSowRepository {
  RcSowRepository(this.client);

  final SupabaseClient client;

  User? get user => client.auth.currentUser;
  String? get googleProviderToken => client.auth.currentSession?.providerToken;

  Future<UserProfile?> currentProfile() async {
    final id = user?.id;
    if (id == null) return null;
    final row = await client
        .from('profiles')
        .select()
        .eq('user_id', id)
        .maybeSingle();
    if (row == null) return null;
    return UserProfile.fromMap(Map<String, dynamic>.from(row));
  }

  Future<List<HouseRecord>> houses(UserProfile profile) async {
    if (profile.isCrew) {
      try {
        final assignments = await client
            .from('house_crew_assignments')
            .select('house_code')
            .eq('active', true)
            .or(
              'user_id.eq.${profile.userId},email.eq.${profile.email.toLowerCase()}',
            );
        final codes = assignments
            .map((row) => '${row['house_code'] ?? ''}'.trim().toUpperCase())
            .where((code) => code.isNotEmpty)
            .toSet()
            .toList();
        if (codes.isEmpty) return const [];
        final rows = await client
            .from('app_events')
            .select()
            .eq('event_type', 'house')
            .inFilter('house_code', codes)
            .order('updated_at', ascending: false)
            .limit(500);
        final byCode = <String, HouseRecord>{};
        for (final raw in rows) {
          final house = HouseRecord.fromEvent(Map<String, dynamic>.from(raw));
          byCode.putIfAbsent(house.code, () => house);
        }
        return byCode.values.toList();
      } catch (_) {
        // Backward-compatible fallback while the v20.3 workforce migration is being applied.
      }
    }

    var query = client.from('app_events').select().eq('event_type', 'house');
    if (!profile.canViewAllParishes && profile.parish.isNotEmpty) {
      query = query.eq('parish', profile.parish);
    }
    final rows = await query.order('updated_at', ascending: false).limit(500);
    final byCode = <String, HouseRecord>{};
    for (final raw in rows) {
      final house = HouseRecord.fromEvent(Map<String, dynamic>.from(raw));
      byCode.putIfAbsent(house.code, () => house);
    }
    final result = byCode.values.toList();
    if (profile.isCrew) {
      return result.where((h) {
        if (h.assignedCrew.isEmpty) return false;
        return h.assignedCrew.any(
          (member) =>
              member.toLowerCase() == profile.email.toLowerCase() ||
              member.toLowerCase() == profile.displayName.toLowerCase(),
        );
      }).toList();
    }
    return result;
  }

  Future<List<MessageRecord>> messages(
    UserProfile profile, {
    int limit = 100,
  }) async {
    final rows = await client
        .from('app_events')
        .select()
        .eq('event_type', 'message')
        .order('created_at', ascending: false)
        .limit(limit);
    return rows
        .map(
          (e) => MessageRecord.fromEvent(
            Map<String, dynamic>.from(e),
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
    if (row == null) return;
    final item = Map<String, dynamic>.from(row['item'] as Map? ?? const {});
    final readBy =
        (item['readBy'] as List?)?.map((e) => '$e').toSet() ?? <String>{};
    readBy.add(profile.email);
    item['readBy'] = readBy.toList();
    item['id'] = message.id;
    await _upsertEvent(
      type: 'message',
      id: message.id,
      parish: row['parish']?.toString(),
      houseCode: row['house_code']?.toString(),
      recipients: _recipientMaps(row['recipients']),
      item: item,
    );
  }

  Future<void> sendMessage({
    required UserProfile profile,
    required String subject,
    required String body,
    required List<Map<String, dynamic>> recipients,
    String? parish,
    String? houseCode,
    String priority = 'Normal',
    String? replyTo,
  }) async {
    if (recipients.isEmpty) {
      throw ArgumentError('At least one recipient is required.');
    }
    final id = 'msg-${DateTime.now().microsecondsSinceEpoch}';
    await _upsertEvent(
      type: 'message',
      id: id,
      parish: parish ?? (profile.canViewAllParishes ? null : profile.parish),
      houseCode: houseCode,
      recipients: recipients,
      item: {
        'id': id,
        'subject': subject.trim(),
        'body': body.trim(),
        'senderName': profile.displayName,
        'fromEmail': profile.email,
        'fromRole': profile.role,
        'priority': priority,
        'readBy': [profile.email],
        if (houseCode != null && houseCode.isNotEmpty) 'houseCode': houseCode,
        if (replyTo != null) 'replyTo': replyTo,
      },
    );
  }

  Future<List<Map<String, dynamic>>> activeUsers() async {
    final result = await client.rpc('list_active_users');
    return (result as List? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<List<ManagedUser>> managedUsers() async {
    final result = await client.rpc('list_managed_users');
    return (result as List? ?? const [])
        .map((e) => ManagedUser.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> manageUser({
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
        .map((e) => Map<String, dynamic>.from(e as Map))
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

  Future<List<Map<String, dynamic>>> liveTrackers(UserProfile profile) async {
    var query = client
        .from('parish_live_trackers')
        .select()
        .eq('enabled', true);
    if (!profile.canViewAllParishes && profile.parish.isNotEmpty) {
      query = query.eq('parish', profile.parish);
    }
    final rows = await query.order('parish');
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

  Future<int> importBeneficiaryRows(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return 0;
    final result = await client.rpc(
      'upsert_beneficiary_directory',
      params: {'p_rows': rows},
    );
    if (result is num) return result.toInt();
    return rows.length;
  }

  Future<List<Map<String, dynamic>>> beneficiarySources() async {
    final rows = await client
        .from('beneficiary_sources')
        .select()
        .order('parish');
    return rows.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> crewAssignments({
    String? houseCode,
  }) async {
    var query = client.from('house_crew_assignments').select();
    if (houseCode != null && houseCode.trim().isNotEmpty) {
      query = query.eq('house_code', houseCode.trim().toUpperCase());
    }
    final rows = await query.order('assigned_at', ascending: false);
    return rows.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> assignCrew({
    required String houseCode,
    required String parish,
    required String userId,
    required String email,
    required String memberName,
    required String role,
    bool active = true,
  }) async {
    await client.rpc(
      'assign_house_crew',
      params: {
        'p_house_code': houseCode.trim().toUpperCase(),
        'p_parish': parish,
        'p_user_id': userId,
        'p_email': email.trim().toLowerCase(),
        'p_member_name': memberName.trim(),
        'p_role': role,
        'p_active': active,
      },
    );
  }

  Future<List<Map<String, dynamic>>> crewAttendance({
    required UserProfile profile,
    String? houseCode,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 300,
  }) async {
    var query = client.from('crew_attendance').select();
    if (houseCode != null && houseCode.trim().isNotEmpty) {
      query = query.eq('house_code', houseCode.trim().toUpperCase());
    }
    if (!profile.canViewAllParishes && profile.parish.isNotEmpty) {
      query = query.eq('parish', profile.parish);
    }
    if (profile.isCrew) query = query.eq('user_id', profile.userId);
    if (startDate != null) query = query.gte('work_date', _date(startDate));
    if (endDate != null) query = query.lte('work_date', _date(endDate));
    final rows = await query.order('work_date', ascending: false).limit(limit);
    return rows.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> submitOwnAttendance({
    required UserProfile profile,
    required String houseCode,
    required DateTime workDate,
    required String status,
    required String clockAction,
    String? note,
    String? evidencePath,
  }) async {
    final result = await client.rpc(
      'upsert_crew_attendance',
      params: {
        'p_house_code': houseCode.trim().toUpperCase(),
        'p_work_date': _date(workDate),
        'p_status': status,
        'p_clock_action': clockAction,
        'p_note': note,
        'p_evidence_path': evidencePath,
      },
    );
    final row = Map<String, dynamic>.from(result as Map? ?? const {});
    final id =
        '${row['id'] ?? 'attendance-${DateTime.now().microsecondsSinceEpoch}'}';
    await _upsertEvent(
      type: 'crewAttendance',
      id: id,
      parish: '${row['parish'] ?? profile.parish}',
      houseCode: houseCode.trim().toUpperCase(),
      item: {
        'id': id,
        'title': 'Crew Daily Attendance',
        'status': row['verified'] == true ? 'Verified' : 'Pending Verification',
        'houseCode': houseCode.trim().toUpperCase(),
        'parish': row['parish'] ?? profile.parish,
        'workDate': row['work_date'] ?? _date(workDate),
        'memberEmail': row['member_email'] ?? profile.email,
        'memberName': row['member_name'] ?? profile.displayName,
        'memberRole': row['member_role'] ?? profile.role,
        'attendanceStatus': row['status'] ?? status,
        'clockIn': row['clock_in'],
        'clockOut': row['clock_out'],
        'verified': row['verified'] == true,
        'evidencePath': row['evidence_path'],
      },
    );
    return row;
  }

  Future<Map<String, dynamic>> verifyAttendance({
    required String attendanceId,
    required bool verified,
    String? status,
  }) async {
    final result = await client.rpc(
      'verify_crew_attendance',
      params: {
        'p_attendance_id': attendanceId,
        'p_verified': verified,
        'p_status': status,
      },
    );
    return Map<String, dynamic>.from(result as Map? ?? const {});
  }

  Future<List<Map<String, dynamic>>> attendancePaymentSummary({
    required String houseCode,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final result = await client.rpc(
      'attendance_payment_summary',
      params: {
        'p_house_code': houseCode.trim().toUpperCase(),
        'p_start_date': startDate == null ? null : _date(startDate),
        'p_end_date': endDate == null ? null : _date(endDate),
      },
    );
    return (result as List? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<String> uploadEvidence({
    required String parish,
    required String houseCode,
    required String recordType,
    required String fieldKey,
    required Uint8List bytes,
    String extension = 'jpg',
  }) async {
    final safeParish = _parishSegment(parish);
    final safeHouse = _safePath(houseCode.toUpperCase());
    final safeType = _safePath(recordType);
    final safeField = _safePath(fieldKey);
    final path =
        '$safeParish/$safeHouse/$safeType/${DateTime.now().microsecondsSinceEpoch}-$safeField.$extension';
    await client.storage
        .from('evidence')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: false,
            contentType: _imageMime(extension),
          ),
        );
    return path;
  }

  Future<String> uploadSignature({
    required String parish,
    required String houseCode,
    required String recordType,
    required String fieldKey,
    required Uint8List bytes,
  }) async {
    final path =
        '${_parishSegment(parish)}/${_safePath(houseCode.toUpperCase())}/${_safePath(recordType)}/${DateTime.now().microsecondsSinceEpoch}-${_safePath(fieldKey)}.png';
    await client.storage
        .from('signatures')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            upsert: false,
            contentType: 'image/png',
          ),
        );
    return path;
  }

  Future<List<BeneficiaryRecord>> searchBeneficiaries(
    UserProfile profile, {
    String query = '',
    int limit = 100,
  }) async {
    try {
      final result = await client.rpc(
        'search_beneficiaries',
        params: {'p_query': query, 'p_limit': limit},
      );
      return (result as List? ?? const [])
          .map(
            (e) =>
                BeneficiaryRecord.fromMap(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } catch (_) {
      var request = client.from('beneficiary_directory').select();
      if (!profile.canViewAllParishes && profile.parish.isNotEmpty) {
        request = request.eq('parish', profile.parish);
      }
      if (query.trim().isNotEmpty) {
        request = request.or(
          'house_code.ilike.%${query.trim()}%,beneficiary_name.ilike.%${query.trim()}%',
        );
      }
      final rows = await request.order('house_code').limit(limit);
      return rows
          .map((e) => BeneficiaryRecord.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  Future<List<ProductionRecord>> productionRecords(
    UserProfile profile, {
    String? eventType,
    String? parish,
    String? houseCode,
    int limit = 500,
  }) async {
    var query = client.from('app_events').select();
    final parishFilter =
        parish ?? (!profile.canViewAllParishes ? profile.parish : null);
    if (parishFilter != null &&
        parishFilter.isNotEmpty &&
        parishFilter != 'All Parishes') {
      query = query.eq('parish', parishFilter);
    }
    if (eventType != null && eventType.isNotEmpty)
      query = query.eq('event_type', eventType);
    if (houseCode != null && houseCode.isNotEmpty)
      query = query.eq('house_code', houseCode);
    final rows = await query.order('updated_at', ascending: false).limit(limit);
    const productionTypes = {
      'scope',
      'controlData',
      'workPlan',
      'workProjection',
      'constructionSchedule',
      'crewAttendance',
      'workLog',
      'monitoring',
      'siteVisit',
      'dailyLog',
      'documentChecklist',
      'materialRequest',
      'consumables',
      'inventory',
      'notice',
      'payment',
      'signatureRequest',
    };
    final visibleRows = rows
        .map((e) => Map<String, dynamic>.from(e))
        .where((row) {
          final type = '${row['event_type'] ?? ''}';
          return productionTypes.contains(type) || type.startsWith('custom:');
        })
        .where((row) {
          if (!(profile.isTechnicalAdmin || profile.isCommunityAdmin))
            return true;
          final item = Map<String, dynamic>.from(
            row['item'] as Map? ?? const {},
          );
          return '${row['created_by_email'] ?? item['updatedBy'] ?? ''}'
                  .toLowerCase() ==
              profile.email.toLowerCase();
        });
    return visibleRows.map(ProductionRecord.fromEvent).toList();
  }

  Future<void> submitControlEvent({
    required UserProfile profile,
    required String eventType,
    required String houseCode,
    required String parish,
    required Map<String, dynamic> item,
    List<Map<String, dynamic>> recipients = const [],
    String? recordId,
  }) async {
    final id =
        recordId ?? '$eventType-${DateTime.now().microsecondsSinceEpoch}';
    await _upsertEvent(
      type: eventType,
      id: id,
      parish: parish,
      houseCode: houseCode,
      recipients: recipients,
      item: {
        ...item,
        'id': id,
        'houseCode': houseCode,
        'parish': parish,
        'updatedBy': profile.email,
      },
    );
  }

  Future<void> deleteProductionRecord(ProductionRecord record) async {
    // Production deletes must always pass through the audited SECURITY DEFINER RPC.
    // Do not fall back to a direct table delete if the audit path is unavailable.
    await client.rpc(
      'delete_app_event',
      params: {'p_event_type': record.eventType, 'p_item_id': record.id},
    );
  }

  Future<List<ProductionRecord>> communityRecords(
    UserProfile profile, {
    int limit = 100,
  }) async {
    final rows = await client
        .from('app_events')
        .select()
        .inFilter('event_type', ['communityPost', 'communitySuggestion'])
        .order('updated_at', ascending: false)
        .limit(limit);
    return rows
        .map((e) => ProductionRecord.fromEvent(Map<String, dynamic>.from(e)))
        .where(
          (r) =>
              profile.canViewAllParishes ||
              r.parish.isEmpty ||
              r.parish == profile.parish ||
              r.parish == 'All Parishes',
        )
        .toList();
  }

  Future<void> submitCommunityPost({
    required UserProfile profile,
    required String title,
    required String body,
    required String category,
    String? mediaUrl,
    String? parish,
  }) async {
    final id = 'community-${DateTime.now().microsecondsSinceEpoch}';
    final targetParish =
        parish ??
        (profile.canViewAllParishes ? 'All Parishes' : profile.parish);
    await _upsertEvent(
      type: 'communityPost',
      id: id,
      parish: targetParish,
      recipients: [
        {'type': 'parish', 'value': targetParish},
      ],
      item: {
        'id': id,
        'title': title,
        'body': body,
        'category': category,
        'mediaUrl': mediaUrl,
        'status': 'Published',
      },
    );
  }

  Future<void> submitCommunitySuggestion({
    required UserProfile profile,
    required String body,
  }) async {
    final id = 'suggestion-${DateTime.now().microsecondsSinceEpoch}';
    await _upsertEvent(
      type: 'communitySuggestion',
      id: id,
      parish: profile.parish,
      recipients: const [
        {'type': 'role', 'value': 'Admin'},
      ],
      item: {
        'id': id,
        'title': 'Community suggestion',
        'body': body,
        'status': 'Submitted',
      },
    );
  }

  Future<void> requestSignature({
    required UserProfile profile,
    required String houseCode,
    required String parish,
    required String recordType,
    required String recordId,
    required String signerRole,
    String? signerEmail,
    String? recipientRole,
  }) async {
    final id = 'signature-${DateTime.now().microsecondsSinceEpoch}';
    final recipient = signerEmail != null && signerEmail.isNotEmpty
        ? {'type': 'email', 'value': signerEmail}
        : {'type': 'role', 'value': recipientRole ?? signerRole};
    await _upsertEvent(
      type: 'signatureRequest',
      id: id,
      parish: parish,
      houseCode: houseCode,
      recipients: [recipient],
      item: {
        'id': id,
        'title': 'Signature required',
        'status': 'Pending',
        'houseCode': houseCode,
        'recordType': recordType,
        'recordId': recordId,
        'signerRole': signerRole,
        'requestedBy': profile.email,
      },
    );
    final messageId = 'msg-$id';
    await _upsertEvent(
      type: 'message',
      id: messageId,
      parish: parish,
      houseCode: houseCode,
      recipients: [recipient],
      item: {
        'id': messageId,
        'subject': 'Signature required • $houseCode',
        'body':
            '$signerRole signature is required for $recordType. Open house $houseCode and complete the linked record.',
        'senderName': profile.displayName,
        'fromEmail': profile.email,
        'fromRole': profile.role,
        'priority': 'Action Required',
        'readBy': [profile.email],
        'houseCode': houseCode,
        'linkedRecordType': recordType,
        'linkedRecordId': recordId,
        'signatureRequestId': id,
      },
    );
  }

  Future<List<Map<String, dynamic>>> customFormTemplates() async {
    final rows = await client
        .from('record_form_templates')
        .select()
        .eq('active', true)
        .order('display_order');
    return rows.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> saveCustomFormTemplate({
    String? templateId,
    required String title,
    required String eventType,
    required String phase,
    required List<Map<String, dynamic>> fields,
    bool active = true,
  }) async {
    final payload = {
      if (templateId != null) 'id': templateId,
      'title': title,
      'event_type': eventType,
      'phase': phase,
      'fields': fields,
      'active': active,
      'updated_by': user?.id,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    await client.from('record_form_templates').upsert(payload);
  }

  Future<void> deleteCustomFormTemplate(String id) async {
    await client.from('record_form_templates').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> documentTemplates() async {
    final rows = await client
        .from('document_templates')
        .select()
        .order('display_name');
    return rows.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> setParishMapUrl({
    required String parish,
    required String url,
  }) async {
    await client.rpc(
      'set_parish_live_tracker',
      params: {'p_parish': parish, 'p_url': url, 'p_enabled': true},
    );
  }

  Future<List<Map<String, dynamic>>> gmailInbox({int maxResults = 20}) async {
    final token = googleProviderToken;
    if (token == null || token.isEmpty) {
      throw StateError(
        'Google access token is not available. Reconnect Google in Settings.',
      );
    }
    final uri = Uri.https(
      'gmail.googleapis.com',
      '/gmail/v1/users/me/messages',
      {'maxResults': '$maxResults', 'labelIds': 'INBOX'},
    );
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200)
      throw StateError('Gmail inbox could not be loaded.');
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final ids = (json['messages'] as List? ?? const [])
        .whereType<Map>()
        .toList();
    final results = <Map<String, dynamic>>[];
    for (final message in ids.take(20)) {
      final id = '${message['id'] ?? ''}';
      if (id.isEmpty) continue;
      final detail = await http.get(
        Uri.https('gmail.googleapis.com', '/gmail/v1/users/me/messages/$id', {
          'format': 'metadata',
        }),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (detail.statusCode != 200) continue;
      final data = jsonDecode(detail.body) as Map<String, dynamic>;
      final payload = Map<String, dynamic>.from(
        data['payload'] as Map? ?? const {},
      );
      final headers = (payload['headers'] as List? ?? const [])
          .whereType<Map>();
      String header(String name) =>
          headers
              .cast<Map>()
              .map((h) => Map<String, dynamic>.from(h))
              .firstWhere(
                (h) => '${h['name']}'.toLowerCase() == name.toLowerCase(),
                orElse: () => const {},
              )['value']
              ?.toString() ??
          '';
      results.add({
        'id': id,
        'threadId': data['threadId'],
        'from': header('From'),
        'subject': header('Subject'),
        'date': header('Date'),
        'snippet': '${data['snippet'] ?? ''}',
      });
    }
    return results;
  }

  Future<Map<String, dynamic>> gmailMessage(String id) async {
    final token = googleProviderToken;
    if (token == null || token.isEmpty)
      throw StateError('Google access token is not available.');
    final response = await http.get(
      Uri.https('gmail.googleapis.com', '/gmail/v1/users/me/messages/$id', {
        'format': 'full',
      }),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200)
      throw StateError('Gmail message could not be loaded.');
    final data = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    final payload = Map<String, dynamic>.from(
      data['payload'] as Map? ?? const {},
    );
    return {...data, 'bodyText': _gmailBodyText(payload)};
  }

  Future<void> gmailSend({
    required String to,
    required String subject,
    required String body,
  }) async {
    if (to.trim().isEmpty) throw ArgumentError('Recipient email is required.');
    if (body.trim().isEmpty) throw ArgumentError('Message body is required.');
    final token = googleProviderToken;
    if (token == null || token.isEmpty)
      throw StateError('Google access token is not available.');
    final raw =
        'To: $to\r\nSubject: $subject\r\nContent-Type: text/plain; charset="UTF-8"\r\n\r\n$body';
    final encoded = base64Url.encode(utf8.encode(raw)).replaceAll('=', '');
    final response = await http.post(
      Uri.https('gmail.googleapis.com', '/gmail/v1/users/me/messages/send'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'raw': encoded}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Gmail message could not be sent.');
    }
  }

  Future<void> _upsertEvent({
    required String type,
    required String id,
    String? parish,
    String? houseCode,
    List<Map<String, dynamic>> recipients = const [],
    required Map<String, dynamic> item,
  }) async {
    await client.rpc(
      'upsert_app_event',
      params: {
        'p_event': {
          'type': type,
          'event_type': type,
          'item_id': id,
          'parish': parish,
          'house_code': houseCode,
          'recipients': recipients,
          'item': {...item, 'id': id, 'recipients': recipients},
        },
      },
    );
  }

  List<Map<String, dynamic>> _recipientMaps(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  String _date(DateTime value) => value.toIso8601String().split('T').first;

  String _gmailBodyText(Map<String, dynamic> payload) {
    String decodeBody(Map<String, dynamic> part) {
      final body = Map<String, dynamic>.from(part['body'] as Map? ?? const {});
      final encoded = '${body['data'] ?? ''}';
      if (encoded.isEmpty) return '';
      try {
        final normalized = base64Url.normalize(encoded);
        return utf8.decode(base64Url.decode(normalized), allowMalformed: true);
      } catch (_) {
        return '';
      }
    }

    String walk(Map<String, dynamic> part, {required bool preferPlain}) {
      final mime = '${part['mimeType'] ?? ''}'.toLowerCase();
      if ((preferPlain && mime == 'text/plain') ||
          (!preferPlain && mime == 'text/html')) {
        final decoded = decodeBody(part);
        if (decoded.isNotEmpty)
          return mime == 'text/html' ? _stripHtml(decoded) : decoded;
      }
      for (final child
          in (part['parts'] as List? ?? const []).whereType<Map>()) {
        final result = walk(
          Map<String, dynamic>.from(child),
          preferPlain: preferPlain,
        );
        if (result.isNotEmpty) return result;
      }
      return '';
    }

    final plain = walk(payload, preferPlain: true);
    if (plain.isNotEmpty) return plain.trim();
    final html = walk(payload, preferPlain: false);
    if (html.isNotEmpty) return html.trim();
    return decodeBody(payload).trim();
  }

  String _stripHtml(String value) => value
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'");

  String _parishSegment(String value) =>
      value.trim().replaceAll(RegExp(r'[/\\]+'), '-');

  String _safePath(String value) => value
      .trim()
      .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '-')
      .replaceAll(RegExp(r'-+'), '-');

  String _imageMime(String extension) => switch (extension.toLowerCase()) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    _ => 'image/jpeg',
  };

  String debugSummary(UserProfile? profile) => jsonEncode({
    'connected': user != null,
    'role': profile?.role,
    'parish': profile?.parish,
    'adminVisible': profile?.canViewAdmin,
  });
}
