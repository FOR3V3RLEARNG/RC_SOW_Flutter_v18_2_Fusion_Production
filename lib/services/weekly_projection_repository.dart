import '../core/app_state.dart';
import '../core/weekly_projection.dart';
import 'production_backend.dart';

class WeeklyProjectionRepository {
  WeeklyProjectionRepository(this.state);

  final AppState state;

  Future<BackendProfile?> profile() async {
    try {
      return await state.backend.currentProfile();
    } on Object {
      return null;
    }
  }

  Future<List<WeeklyAdminProjectionFile>> fetchWeek(
    DateTime weekStarting,
  ) async {
    final normalized = rcWeekStarting(weekStarting);

    if (state.backend is SupabaseProductionBackend && !state.offline) {
      final backend = state.backend as SupabaseProductionBackend;

      await _pushLocalDraftsForCurrentUser(backend, normalized);

      final rows = await backend.client
          .from('weekly_admin_projections')
          .select()
          .eq('week_starting', rcWeekKey(normalized))
          .order('parish')
          .order('owner_name');

      final files = (rows as List)
          .whereType<Map>()
          .map(
            (row) => WeeklyAdminProjectionFile.fromMap(
              Map<String, dynamic>.from(row),
            ),
          )
          .toList();

      for (final file in files) {
        _cache(file, synced: true);
      }

      return files;
    }

    return _localWeek(normalized);
  }

  Future<void> save(WeeklyAdminProjectionFile file) async {
    _cache(file);

    if (state.backend is! SupabaseProductionBackend || state.offline) {
      state.queuedChanges = _unsyncedLocalCount;
      return;
    }

    final backend = state.backend as SupabaseProductionBackend;
    final user = backend.client.auth.currentUser;
    if (user == null) {
      throw StateError('Sign in before saving a weekly work projection.');
    }
    if (file.ownerId != user.id) {
      throw StateError('A weekly file can only be edited by its owner.');
    }

    try {
      await _upsert(backend, file);
      _markSynced(file);
      state.queuedChanges = _unsyncedLocalCount;
    } on Object {
      state.queuedChanges = _unsyncedLocalCount;
      rethrow;
    }
  }

  List<WeeklyAdminProjectionFile> _localWeek(DateTime weekStarting) {
    final prefix = 'weekly-admin-projection:';
    final weekKey = rcWeekKey(weekStarting);
    final results = <WeeklyAdminProjectionFile>[];

    for (final entry in state.formDrafts.entries) {
      if (!entry.key.startsWith(prefix)) continue;
      if (entry.value['week'] != weekKey) continue;
      final json = entry.value['json'];
      if (json == null || json.isEmpty) continue;
      try {
        results.add(WeeklyAdminProjectionFile.fromJson(json));
      } on FormatException {
        continue;
      }
    }

    results.sort((a, b) {
      final parishCompare = a.parish.compareTo(b.parish);
      return parishCompare != 0
          ? parishCompare
          : a.ownerName.compareTo(b.ownerName);
    });
    return results;
  }

  void _cache(WeeklyAdminProjectionFile file, {bool synced = false}) {
    state.formDrafts[weeklyProjectionCacheKey(
      file.ownerId,
      file.weekStarting,
    )] = <String, String>{
      'json': file.toJson(),
      'week': rcWeekKey(file.weekStarting),
      'ownerId': file.ownerId,
      'synced': synced ? 'true' : 'false',
    };
  }

  void _markSynced(WeeklyAdminProjectionFile file) {
    final key = weeklyProjectionCacheKey(file.ownerId, file.weekStarting);
    final current = state.formDrafts[key];
    if (current != null) current['synced'] = 'true';
  }

  int get _unsyncedLocalCount => state.formDrafts.values
      .where((value) => value['synced'] == 'false')
      .length;

  Future<void> _pushLocalDraftsForCurrentUser(
    SupabaseProductionBackend backend,
    DateTime weekStarting,
  ) async {
    final user = backend.client.auth.currentUser;
    if (user == null) return;

    final key = weeklyProjectionCacheKey(user.id, weekStarting);
    final local = state.formDrafts[key];
    if (local == null || local['synced'] != 'false') return;

    final json = local['json'];
    if (json == null || json.isEmpty) return;

    final file = WeeklyAdminProjectionFile.fromJson(json);
    await _upsert(backend, file);
    local['synced'] = 'true';
    state.queuedChanges = _unsyncedLocalCount;
  }

  Future<void> _upsert(
    SupabaseProductionBackend backend,
    WeeklyAdminProjectionFile file,
  ) async {
    final payload = Map<String, dynamic>.from(file.toMap())
      ..remove('id');

    await backend.client.from('weekly_admin_projections').upsert(
      payload,
      onConflict: 'owner_id,week_starting',
    );
  }
}
