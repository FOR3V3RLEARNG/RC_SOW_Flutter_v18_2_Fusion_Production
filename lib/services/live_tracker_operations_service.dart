import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_models.dart';

class LiveTrackerOperationsService {
  LiveTrackerOperationsService(this.client);

  final SupabaseClient client;

  static const eventType = 'liveTrackerHouseOverride';

  Future<List<Map<String, dynamic>>> overrides(
    UserProfile profile, {
    required String parish,
  }) async {
    if (!profile.canViewAllParishes &&
        profile.parish.isNotEmpty &&
        profile.parish.toLowerCase() != parish.toLowerCase()) {
      return const [];
    }

    final rows = await client
        .from('app_events')
        .select()
        .eq('event_type', eventType)
        .eq('parish', parish)
        .order('updated_at', ascending: false)
        .limit(1500);

    final byTracker = <String, Map<String, dynamic>>{};
    for (final raw in rows) {
      final row = Map<String, dynamic>.from(raw);
      final item = Map<String, dynamic>.from(
        row['item'] as Map? ?? const {},
      );
      final trackerCode =
          '${item['trackerHouseCode'] ?? row['house_code'] ?? ''}'
              .trim()
              .toUpperCase();
      if (trackerCode.isEmpty) continue;
      byTracker.putIfAbsent(trackerCode, () => row);
    }
    return byTracker.values.toList();
  }

  Future<void> setRejected({
    required UserProfile profile,
    required String parish,
    required String trackerHouseCode,
    required String resolvedHouseCode,
    required bool rejected,
    String reason = '',
    bool sourceRejected = false,
  }) async {
    final current = await _item(parish, trackerHouseCode);
    final now = DateTime.now().toUtc().toIso8601String();

    current['trackerHouseCode'] = _code(trackerHouseCode);
    current['resolvedHouseCode'] = _code(resolvedHouseCode);
    current['rejected'] = rejected;
    current['sourceRejectedWhenChanged'] = sourceRejected;
    current['updatedAt'] = now;
    current['updatedBy'] = profile.email;

    if (rejected) {
      current['rejectionReason'] = reason.trim();
      current['rejectedAt'] = now;
      current['rejectedBy'] = profile.email;
      current.remove('reinstatedAt');
      current.remove('reinstatedBy');
    } else {
      current['reinstatedAt'] = now;
      current['reinstatedBy'] = profile.email;
      current['previousRejectionReason'] =
          '${current['rejectionReason'] ?? ''}';
      current['rejectionReason'] = '';
    }

    await _write(
      parish: parish,
      trackerHouseCode: trackerHouseCode,
      resolvedHouseCode: resolvedHouseCode,
      item: current,
    );
  }

  Future<void> setMilestoneDone({
    required UserProfile profile,
    required String parish,
    required String trackerHouseCode,
    required String resolvedHouseCode,
    required String milestoneKey,
    required bool done,
  }) async {
    final current = await _item(parish, trackerHouseCode);
    final milestones = _map(current['milestones']);
    final milestone = _map(milestones[milestoneKey]);
    final now = DateTime.now().toUtc().toIso8601String();

    milestone['done'] = done;
    milestone['updatedAt'] = now;
    milestone['updatedBy'] = profile.email;
    if (done) {
      milestone['completedAt'] = now;
      milestone['completedBy'] = profile.email;
    } else {
      milestone['reopenedAt'] = now;
      milestone['reopenedBy'] = profile.email;
    }
    milestones[milestoneKey] = milestone;

    current['trackerHouseCode'] = _code(trackerHouseCode);
    current['resolvedHouseCode'] = _code(resolvedHouseCode);
    current['milestones'] = milestones;
    current['updatedAt'] = now;
    current['updatedBy'] = profile.email;

    await _write(
      parish: parish,
      trackerHouseCode: trackerHouseCode,
      resolvedHouseCode: resolvedHouseCode,
      item: current,
    );
  }

  Future<void> setMilestoneExternalLink({
    required UserProfile profile,
    required String parish,
    required String trackerHouseCode,
    required String resolvedHouseCode,
    required String milestoneKey,
    required String url,
    String label = '',
  }) async {
    final current = await _item(parish, trackerHouseCode);
    final milestones = _map(current['milestones']);
    final milestone = _map(milestones[milestoneKey]);
    final now = DateTime.now().toUtc().toIso8601String();

    milestone['externalUrl'] = url.trim();
    milestone['linkLabel'] = label.trim();
    milestone['updatedAt'] = now;
    milestone['updatedBy'] = profile.email;
    milestones[milestoneKey] = milestone;

    current['trackerHouseCode'] = _code(trackerHouseCode);
    current['resolvedHouseCode'] = _code(resolvedHouseCode);
    current['milestones'] = milestones;
    current['updatedAt'] = now;
    current['updatedBy'] = profile.email;

    await _write(
      parish: parish,
      trackerHouseCode: trackerHouseCode,
      resolvedHouseCode: resolvedHouseCode,
      item: current,
    );
  }

  Future<void> setMilestoneUploadedDocument({
    required UserProfile profile,
    required String parish,
    required String trackerHouseCode,
    required String resolvedHouseCode,
    required String milestoneKey,
    required String storagePath,
    required String fileName,
  }) async {
    final current = await _item(parish, trackerHouseCode);
    final milestones = _map(current['milestones']);
    final milestone = _map(milestones[milestoneKey]);
    final now = DateTime.now().toUtc().toIso8601String();

    milestone['storagePath'] = storagePath;
    milestone['fileName'] = fileName;
    milestone['updatedAt'] = now;
    milestone['updatedBy'] = profile.email;
    milestones[milestoneKey] = milestone;

    current['trackerHouseCode'] = _code(trackerHouseCode);
    current['resolvedHouseCode'] = _code(resolvedHouseCode);
    current['milestones'] = milestones;
    current['updatedAt'] = now;
    current['updatedBy'] = profile.email;

    await _write(
      parish: parish,
      trackerHouseCode: trackerHouseCode,
      resolvedHouseCode: resolvedHouseCode,
      item: current,
    );
  }

  Future<String> uploadDocument({
    required String parish,
    required String houseCode,
    required String milestoneKey,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final safeName = _safeFileName(fileName);
    final path =
        '${_safePath(parish)}/${_safePath(houseCode)}/live-tracker/'
        '${_safePath(milestoneKey)}/${DateTime.now().microsecondsSinceEpoch}_$safeName';

    await client.storage.from('evidence').uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        upsert: false,
        contentType: _mimeType(fileName),
      ),
    );
    return path;
  }

  Future<String> signedDocumentUrl(String storagePath) {
    return client.storage.from('evidence').createSignedUrl(storagePath, 3600);
  }

  Future<bool> syncToWorkbook({
    required UserProfile profile,
    required String parish,
    required String trackerHouseCode,
    required String resolvedHouseCode,
    required Map<String, dynamic> patch,
  }) async {
    try {
      final response = await client.functions.invoke(
        'sync-live-tracker',
        body: {
          'parish': parish,
          'mode': 'writeBack',
          'trackerHouseCode': _code(trackerHouseCode),
          'resolvedHouseCode': _code(resolvedHouseCode),
          'patch': patch,
        },
      );

      final data = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : <String, dynamic>{};

      final confirmed =
          data['writeBack'] == true ||
          data['write_back'] == true ||
          '${data['mode'] ?? ''}'.toLowerCase() == 'writeback';

      if (!confirmed || data['error'] != null) {
        await _setSyncState(
          profile: profile,
          parish: parish,
          trackerHouseCode: trackerHouseCode,
          resolvedHouseCode: resolvedHouseCode,
          state: 'pending',
          patch: patch,
          message:
              '${data['error'] ?? 'Workbook provider has not confirmed write-back.'}',
        );
        return false;
      }

      await _setSyncState(
        profile: profile,
        parish: parish,
        trackerHouseCode: trackerHouseCode,
        resolvedHouseCode: resolvedHouseCode,
        state: 'synced',
        patch: patch,
        message: 'Excel/workbook write-back confirmed.',
      );
      return true;
    } catch (error) {
      await _setSyncState(
        profile: profile,
        parish: parish,
        trackerHouseCode: trackerHouseCode,
        resolvedHouseCode: resolvedHouseCode,
        state: 'pending',
        patch: patch,
        message: '$error',
      );
      return false;
    }
  }

  Future<void> _setSyncState({
    required UserProfile profile,
    required String parish,
    required String trackerHouseCode,
    required String resolvedHouseCode,
    required String state,
    required Map<String, dynamic> patch,
    required String message,
  }) async {
    final current = await _item(parish, trackerHouseCode);
    final now = DateTime.now().toUtc().toIso8601String();

    current['trackerHouseCode'] = _code(trackerHouseCode);
    current['resolvedHouseCode'] = _code(resolvedHouseCode);
    current['workbookSyncState'] = state;
    current['workbookSyncMessage'] = message;
    current['workbookSyncUpdatedAt'] = now;
    current['workbookSyncUpdatedBy'] = profile.email;
    if (state == 'synced') {
      current['lastWorkbookSyncedAt'] = now;
      current.remove('pendingWorkbookPatch');
    } else {
      current['pendingWorkbookPatch'] = patch;
    }

    await _write(
      parish: parish,
      trackerHouseCode: trackerHouseCode,
      resolvedHouseCode: resolvedHouseCode,
      item: current,
    );
  }

  Future<Map<String, dynamic>> _item(
    String parish,
    String trackerHouseCode,
  ) async {
    final id = _id(parish, trackerHouseCode);
    final row = await client
        .from('app_events')
        .select('item')
        .eq('event_type', eventType)
        .eq('item_id', id)
        .maybeSingle();

    return _map(row?['item']);
  }

  Future<void> _write({
    required String parish,
    required String trackerHouseCode,
    required String resolvedHouseCode,
    required Map<String, dynamic> item,
  }) async {
    final id = _id(parish, trackerHouseCode);
    await client.rpc(
      'upsert_app_event',
      params: {
        'p_event': {
          'type': eventType,
          'event_type': eventType,
          'item_id': id,
          'parish': parish,
          'house_code': _code(trackerHouseCode),
          'recipients': const [],
          'item': {
            ...item,
            'id': id,
            'trackerHouseCode': _code(trackerHouseCode),
            'resolvedHouseCode': _code(resolvedHouseCode),
            'parish': parish,
          },
        },
      },
    );
  }

  Map<String, dynamic> _map(Object? raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  String _id(String parish, String trackerHouseCode) =>
      'live-tracker-${_safePath(parish)}-${_safePath(trackerHouseCode)}';

  String _code(String value) => value.trim().toUpperCase();

  String _safePath(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_-]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');

  String _safeFileName(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
    return cleaned.isEmpty ? 'document' : cleaned;
  }

  String _mimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.xlsx')) {
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
    if (lower.endsWith('.xls')) return 'application/vnd.ms-excel';
    if (lower.endsWith('.csv')) return 'text/csv';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
