import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/production_models.dart';
import '../core/supabase_config.dart';

class BackendProfile {
  const BackendProfile({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.role,
    required this.assignedParishes,
    required this.approved,
  });

  final String userId;
  final String email;
  final String fullName;
  final String role;
  final List<String> assignedParishes;
  final bool approved;
}

class BackendWrite {
  const BackendWrite({
    required this.houseCode,
    required this.parish,
    required this.recordType,
    required this.payload,
    required this.idempotencyKey,
    this.status = 'draft',
  });

  final String houseCode;
  final String parish;
  final String recordType;
  final String status;
  final Map<String, dynamic> payload;
  final String idempotencyKey;
}

abstract class ProductionBackend {
  const ProductionBackend();

  bool get connected;
  String get connectionLabel;

  Future<BackendProfile?> currentProfile();

  Future<void> signInWithGoogle();

  Future<void> requestMagicLink(String email);

  Future<void> signOut();

  Future<void> writeRecord(BackendWrite write);

  Future<AiRoofSuggestion> analyzeRoofImage({
    required String houseCode,
    required String fileName,
    required Uint8List bytes,
  });

  Future<LegacyImportBatch> previewLegacyImport({
    required String fileName,
    required Uint8List bytes,
  });

  Future<void> commitLegacyImport(LegacyImportBatch batch);
}

class LocalProductionBackend extends ProductionBackend {
  const LocalProductionBackend();

  @override
  bool get connected => false;

  @override
  String get connectionLabel => 'Offline field repository';

  @override
  Future<BackendProfile?> currentProfile() async => null;

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> requestMagicLink(String email) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> writeRecord(BackendWrite write) async {}

  @override
  Future<AiRoofSuggestion> analyzeRoofImage({
    required String houseCode,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final section = defaultRoofSection(
      id: 'ai-main',
      name: 'AI proposal • Main roof',
      left: 205,
      top: 175,
      width: 410,
      height: 285,
    );
    section
      ..lengthFt = 24.5
      ..widthFt = 18
      ..wallHeightFt = 8
      ..pitchRisePer12 = 6;
    final document = RoofDrawingDocument(
      houseCode: houseCode,
      sections: <RoofSection>[section],
      selectedSectionId: section.id,
      source: 'Image-assisted proposal',
      sourceFileName: fileName,
      aiConfidence: .78,
      updatedAt: DateTime.now(),
    );
    return AiRoofSuggestion(
      fileName: fileName,
      document: document,
      overallConfidence: .78,
      engineLabel: 'Offline review proposal',
      measurements: const <AiMeasurementSuggestion>[
        AiMeasurementSuggestion(
          label: 'Rafter length',
          value: 14.5,
          unit: 'ft',
          confidence: .89,
        ),
        AiMeasurementSuggestion(
          label: 'Zinc area',
          value: 441,
          unit: 'sq ft',
          confidence: .54,
        ),
        AiMeasurementSuggestion(
          label: 'Wall height',
          value: 8,
          unit: 'ft',
          confidence: .92,
        ),
      ],
    );
  }

  @override
  Future<LegacyImportBatch> previewLegacyImport({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final extension = fileName.split('.').last.toLowerCase();
    if (extension == 'json') {
      return _previewJson(fileName, bytes);
    }
    if (extension == 'csv') {
      return _previewCsv(fileName, bytes);
    }
    return LegacyImportBatch(
      id: 'IMPORT-${DateTime.now().microsecondsSinceEpoch}',
      fileName: fileName,
      rowCount: 0,
      mappings: _defaultMappings(const <String>[], const <String>[]),
      warnings: const <String>[
        'XLSX and PDF files are held on device until the secure connected parser is available.',
        'Confirm every required mapping before importing into production.',
      ],
      createdAt: DateTime.now(),
      status: LegacyImportStatus.mapping,
    );
  }

  @override
  Future<void> commitLegacyImport(LegacyImportBatch batch) async {}

  LegacyImportBatch _previewCsv(String fileName, Uint8List bytes) {
    final text = utf8.decode(bytes, allowMalformed: true);
    final rows = const LineSplitter()
        .convert(text)
        .where((line) => line.trim().isNotEmpty)
        .map(_parseCsvLine)
        .toList();
    final headers = rows.isEmpty ? <String>[] : rows.first;
    final sample = rows.length < 2 ? <String>[] : rows[1];
    return LegacyImportBatch(
      id: 'IMPORT-${DateTime.now().microsecondsSinceEpoch}',
      fileName: fileName,
      rowCount: mathMax(0, rows.length - 1),
      mappings: _defaultMappings(headers, sample),
      warnings: <String>[
        if (rows.length < 2) 'No data rows were found in the selected CSV file.',
        'Potential duplicate beneficiaries will remain blocked until reviewed.',
      ],
      createdAt: DateTime.now(),
      status: LegacyImportStatus.mapping,
    );
  }

  LegacyImportBatch _previewJson(String fileName, Uint8List bytes) {
    final decoded = jsonDecode(utf8.decode(bytes, allowMalformed: true));
    final rows = decoded is List
        ? decoded.whereType<Map>().map(Map<String, dynamic>.from).toList()
        : decoded is Map
            ? <Map<String, dynamic>>[Map<String, dynamic>.from(decoded)]
            : <Map<String, dynamic>>[];
    final first = rows.isEmpty ? <String, dynamic>{} : rows.first;
    final headers = first.keys.toList();
    final sample = headers.map((header) => '${first[header] ?? ''}').toList();
    return LegacyImportBatch(
      id: 'IMPORT-${DateTime.now().microsecondsSinceEpoch}',
      fileName: fileName,
      rowCount: rows.length,
      mappings: _defaultMappings(headers, sample),
      warnings: <String>[
        if (rows.isEmpty) 'No records were found in the selected JSON file.',
        'GPS and beneficiary identity must be verified before activation.',
      ],
      createdAt: DateTime.now(),
      status: LegacyImportStatus.mapping,
    );
  }

  List<ImportFieldMapping> _defaultMappings(
    List<String> headers,
    List<String> sample,
  ) {
    const targets = <String, List<String>>{
      'House code': <String>['house_code', 'housecode', 'code', 'shelter_id'],
      'Beneficiary name': <String>[
        'beneficiary',
        'beneficiary_name',
        'head_of_household',
        'family_name',
      ],
      'Parish': <String>['parish', 'location_parish', 'district', 'region_code'],
      'Cluster': <String>['cluster', 'cluster_id', 'sector_group', 'camp_id'],
      'GPS coordinates': <String>['gps', 'gps_string', 'lat_long', 'coordinates'],
      'Assessment date': <String>['assessment_date', 'date', 'created_at'],
    };
    return targets.entries.map((target) {
      final index = headers.indexWhere((header) {
        final normalized = _normalizeHeader(header);
        return target.value.contains(normalized);
      });
      return ImportFieldMapping(
        systemField: target.key,
        sourceColumn: index < 0 ? '' : headers[index],
        sampleValue:
            index < 0 || index >= sample.length ? '—' : sample[index],
        confidence: index < 0 ? 0 : .92,
        required: const <String>{
          'House code',
          'Beneficiary name',
          'Parish',
        }.contains(target.key),
      );
    }).toList();
  }

  List<String> _parseCsvLine(String line) {
    final values = <String>[];
    final buffer = StringBuffer();
    var quoted = false;
    for (var index = 0; index < line.length; index++) {
      final character = line[index];
      if (character == '"') {
        if (quoted && index + 1 < line.length && line[index + 1] == '"') {
          buffer.write('"');
          index++;
        } else {
          quoted = !quoted;
        }
      } else if (character == ',' && !quoted) {
        values.add(buffer.toString().trim());
        buffer.clear();
      } else {
        buffer.write(character);
      }
    }
    values.add(buffer.toString().trim());
    return values;
  }

  String _normalizeHeader(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '_')
      .replaceAll(RegExp('^_|_\$'), '');
}

class SupabaseProductionBackend extends ProductionBackend {
  const SupabaseProductionBackend(this.client);

  final SupabaseClient client;

  @override
  bool get connected => true;

  @override
  String get connectionLabel => 'Supabase secure sync';

  @override
  Future<BackendProfile?> currentProfile() async {
    final user = client.auth.currentUser;
    if (user == null) return null;
    final row = await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    if (row == null) return null;
    final parishes = (row['assigned_parishes'] as List? ?? const <Object>[])
        .map((value) => '$value')
        .toList();
    return BackendProfile(
      userId: user.id,
      email: user.email ?? '',
      fullName: '${row['full_name'] ?? user.email ?? 'RC SOW user'}',
      role: '${row['role'] ?? ''}',
      assignedParishes: parishes,
      approved: row['active'] == true,
    );
  }

  @override
  Future<void> signInWithGoogle() async {
    await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : SupabaseConfig.oauthRedirectUri,
    );
  }

  @override
  Future<void> requestMagicLink(String email) async {
    await client.auth.signInWithOtp(
      email: email,
      emailRedirectTo: kIsWeb ? null : SupabaseConfig.oauthRedirectUri,
    );
  }

  @override
  Future<void> signOut() => client.auth.signOut();

  @override
  Future<void> writeRecord(BackendWrite write) async {
    await client.rpc(
      'rc_sow_upsert_operational_record',
      params: <String, dynamic>{
        'p_house_code': write.houseCode,
        'p_parish': write.parish,
        'p_record_type': write.recordType,
        'p_status': write.status,
        'p_payload': write.payload,
        'p_idempotency_key': write.idempotencyKey,
      },
    );
  }

  @override
  Future<AiRoofSuggestion> analyzeRoofImage({
    required String houseCode,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final response = await client.functions.invoke(
      SupabaseConfig.aiRoofFunction,
      body: <String, dynamic>{
        'house_code': houseCode,
        'file_name': fileName,
        'content_base64': base64Encode(bytes),
      },
    );
    final payload = Map<String, dynamic>.from(response.data as Map);
    final document = RoofDrawingDocument.fromMap(
      Map<String, dynamic>.from(payload['document'] as Map? ?? const {}),
    );
    final measurements = (payload['measurements'] as List? ?? const <Object>[])
        .map((raw) {
      final value = Map<String, dynamic>.from(raw as Map);
      return AiMeasurementSuggestion(
        label: '${value['label'] ?? 'Measurement'}',
        value: (value['value'] as num?)?.toDouble() ?? 0,
        unit: '${value['unit'] ?? 'ft'}',
        confidence: (value['confidence'] as num?)?.toDouble() ?? 0,
      );
    }).toList();
    return AiRoofSuggestion(
      fileName: fileName,
      document: document,
      measurements: measurements,
      overallConfidence:
          (payload['overall_confidence'] as num?)?.toDouble() ?? 0,
      engineLabel: '${payload['engine_label'] ?? 'RC SOW secure extractor'}',
    );
  }

  @override
  Future<LegacyImportBatch> previewLegacyImport({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final response = await client.functions.invoke(
      SupabaseConfig.legacyImportFunction,
      body: <String, dynamic>{
        'file_name': fileName,
        'content_base64': base64Encode(bytes),
      },
    );
    final payload = Map<String, dynamic>.from(response.data as Map);
    final mappings = (payload['mappings'] as List? ?? const <Object>[])
        .map((raw) {
      final value = Map<String, dynamic>.from(raw as Map);
      return ImportFieldMapping(
        systemField: '${value['system_field'] ?? ''}',
        sourceColumn: '${value['source_column'] ?? ''}',
        sampleValue: '${value['sample_value'] ?? '—'}',
        confidence: (value['confidence'] as num?)?.toDouble() ?? 0,
        required: value['required'] == true,
      );
    }).toList();
    return LegacyImportBatch(
      id: '${payload['id'] ?? 'IMPORT-${DateTime.now().microsecondsSinceEpoch}'}',
      fileName: fileName,
      rowCount: (payload['row_count'] as num?)?.toInt() ?? 0,
      mappings: mappings,
      warnings: (payload['warnings'] as List? ?? const <Object>[])
          .map((warning) => '$warning')
          .toList(),
      createdAt: DateTime.now(),
      status: LegacyImportStatus.mapping,
    );
  }

  @override
  Future<void> commitLegacyImport(LegacyImportBatch batch) async {
    await client.rpc(
      'rc_sow_commit_legacy_import',
      params: <String, dynamic>{'p_import_id': batch.id},
    );
  }
}

abstract final class ProductionBackendFactory {
  static Future<ProductionBackend> create() async {
    if (!SupabaseConfig.isConfigured) return const LocalProductionBackend();
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        // supabase_flutter keeps the historic `anonKey` parameter name. It
        // accepts the current public publishable-key format here.
        anonKey: SupabaseConfig.publishableKey,
      );
      return SupabaseProductionBackend(Supabase.instance.client);
    } catch (_) {
      return const LocalProductionBackend();
    }
  }
}

int mathMax(int first, int second) => first > second ? first : second;
