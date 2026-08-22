import 'package:excel_plus/excel_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_models.dart';

class RcTemplateDefinition {
  const RcTemplateDefinition({
    required this.key,
    required this.title,
    required this.assetPath,
    required this.fileName,
    required this.mimeType,
    required this.eventType,
  });

  final String key;
  final String title;
  final String assetPath;
  final String fileName;
  final String mimeType;
  final String eventType;
}

abstract final class RcTemplates {
  static const all = <RcTemplateDefinition>[
    RcTemplateDefinition(
      key: 'scope',
      title: 'Scope of Work',
      assetPath: 'assets/templates/original/SOW_Excel_Template_Blank.xlsx',
      fileName: 'SOW_Excel_Template_Blank.xlsx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      eventType: 'scope',
    ),
    RcTemplateDefinition(
      key: 'workPlan',
      title: 'Work Plan',
      assetPath: 'assets/templates/original/Workplan_Blank.xlsx',
      fileName: 'Workplan-Blank.xlsx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      eventType: 'workPlan',
    ),
    RcTemplateDefinition(
      key: 'controlData',
      title: 'Control of Works',
      assetPath: 'assets/templates/original/Control_of_Works_Blank.xlsx',
      fileName: 'Control-of-works-Blank.xlsx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      eventType: 'controlData',
    ),
    RcTemplateDefinition(
      key: 'monitoring',
      title: 'Monitoring Checklist',
      assetPath:
          'assets/templates/original/Monitoring_Checklist_Roof_Repair.docx',
      fileName: 'Monitoring-checklist-roof-repair.docx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      eventType: 'monitoring',
    ),
    RcTemplateDefinition(
      key: 'notice',
      title: 'Notice of Completion',
      assetPath: 'assets/templates/original/Notice_of_Completion.docx',
      fileName: 'Notice-of-Completion.docx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      eventType: 'notice',
    ),
    RcTemplateDefinition(
      key: 'payment',
      title: 'Payment Request',
      assetPath: 'assets/templates/original/Payment_Request_Form.docx',
      fileName: 'Payment-Request.docx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      eventType: 'payment',
    ),
  ];

  static RcTemplateDefinition? forEventType(String eventType) {
    for (final template in all) {
      if (template.eventType == eventType) {
        return template;
      }
    }
    if (const {
      'siteVisit',
      'dailyLog',
      'documentChecklist',
      'materialRequest',
      'consumables',
      'inventory',
    }.contains(eventType)) {
      return all.firstWhere((template) => template.key == 'controlData');
    }
    return null;
  }
}

class RcDocumentService {
  RcDocumentService(this.client);

  final SupabaseClient client;

  Future<Uint8List> templateBytes(RcTemplateDefinition template) async {
    try {
      final row = await client
          .from('document_templates')
          .select('storage_path')
          .eq('template_key', template.key)
          .eq('active', true)
          .maybeSingle();
      final path = row?['storage_path'] as String?;
      if (path != null && path.isNotEmpty) {
        return client.storage.from('document-templates').download(path);
      }
    } catch (_) {
      // The bundled original remains available offline and before a remote
      // template has been provisioned.
    }
    final data = await rootBundle.load(template.assetPath);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  Future<Uri?> saveTemplate(RcTemplateDefinition template) async {
    return FilePicker.saveFile(
      dialogTitle: 'Save ${template.title} template',
      fileName: template.fileName,
      bytes: await templateBytes(template),
      mimeType: template.mimeType,
    );
  }

  Future<void> shareTemplate(RcTemplateDefinition template) async {
    final bytes = await templateBytes(template);
    await shareBytes(
      bytes: bytes,
      fileName: template.fileName,
      mimeType: template.mimeType,
      subject: 'RC SOW — ${template.title}',
    );
  }

  Future<void> replaceTemplate({
    required RcTemplateDefinition template,
    required UserProfile profile,
  }) async {
    if (!profile.canManageTemplates) {
      throw StateError('Template management privilege required.');
    }
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: [template.fileName.split('.').last.toLowerCase()],
    );
    if (picked == null) {
      return;
    }
    final bytes = await picked.readAsBytes();
    final extension = picked.name.contains('.')
        ? picked.name.split('.').last.toLowerCase()
        : template.fileName.split('.').last.toLowerCase();
    final storagePath =
        '${template.key}/${DateTime.now().millisecondsSinceEpoch}.$extension';
    await client.storage
        .from('document-templates')
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            contentType: template.mimeType,
            upsert: true,
          ),
        );
    await client.from('document_templates').upsert({
      'template_key': template.key,
      'display_name': template.title,
      'file_name': picked.name,
      'mime_type': template.mimeType,
      'storage_path': storagePath,
      'active': true,
      'updated_by': profile.userId,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<Uint8List> productionXlsx(List<ProductionRecord> records) async {
    final excel = Excel.createExcel();
    final sheet = excel[excel.getDefaultSheet() ?? 'Sheet1'];
    sheet.appendRow([
      TextCellValue('House Code'),
      TextCellValue('Parish'),
      TextCellValue('Record Type'),
      TextCellValue('Status'),
      TextCellValue('Title'),
      TextCellValue('Summary'),
      TextCellValue('Updated'),
    ]);
    for (final record in records) {
      sheet.appendRow([
        TextCellValue(record.houseCode),
        TextCellValue(record.parish),
        TextCellValue(record.eventType),
        TextCellValue(record.status),
        TextCellValue(record.title),
        TextCellValue(record.summary),
        TextCellValue(record.updatedAt.toLocal().toIso8601String()),
      ]);
    }
    final bytes = excel.save();
    if (bytes == null) {
      throw StateError('Could not generate Excel export.');
    }
    return Uint8List.fromList(bytes);
  }

  Future<Uint8List> scopeXlsx({
    required String houseCode,
    required String beneficiary,
    required String parish,
    required String cluster,
    required String roofType,
    required RoofMeasurements measurements,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel[excel.getDefaultSheet() ?? 'Sheet1'];
    sheet.appendRow([
      TextCellValue('RC SOW Scope of Work'),
      TextCellValue('Value'),
    ]);
    final rows = <(String, String)>[
      ('House Code', houseCode),
      ('Beneficiary', beneficiary),
      ('Parish', parish),
      ('Cluster', cluster),
      ('Roof Type', roofType),
      ('Building Width (ft)', measurements.widthFt.toStringAsFixed(2)),
      ('Building Length (ft)', measurements.lengthFt.toStringAsFixed(2)),
      ('Wall Height (ft)', measurements.wallHeightFt.toStringAsFixed(2)),
      ('Pitch Rise / 12', measurements.pitchRisePer12.toStringAsFixed(2)),
      (
        'Wall Plate to Ridge Rise (ft)',
        measurements.ridgeRiseFt.toStringAsFixed(2),
      ),
      (
        'Ridge Height from Ground (ft)',
        measurements.ridgeHeightFt.toStringAsFixed(2),
      ),
      ('Rafter Length (ft)', measurements.rafterLengthFt.toStringAsFixed(2)),
      ('Roof Area (sq ft)', measurements.roofAreaSqFt.toStringAsFixed(2)),
    ];
    for (final row in rows) {
      sheet.appendRow([TextCellValue(row.$1), TextCellValue(row.$2)]);
    }
    final bytes = excel.save();
    if (bytes == null) {
      throw StateError('Could not generate Scope Excel export.');
    }
    return Uint8List.fromList(bytes);
  }

  Future<Uint8List> productionPdf(List<ProductionRecord> records) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (_) => [
          pw.Text(
            'RC SOW — Production Export',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: const [
              'House',
              'Parish',
              'Type',
              'Status',
              'Title',
              'Summary',
              'Updated',
            ],
            data: records
                .map(
                  (record) => [
                    record.houseCode,
                    record.parish,
                    record.eventType,
                    record.status,
                    record.title,
                    record.summary,
                    record.updatedAt.toLocal().toString(),
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
    );
    return pdf.save();
  }

  Future<Uri?> saveBytes({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) {
    return FilePicker.saveFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: mimeType,
    );
  }

  Future<void> shareBytes({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    String? subject,
    String? text,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        subject: subject,
        text: text,
        files: [XFile.fromData(bytes, mimeType: mimeType)],
        fileNameOverrides: [fileName],
      ),
    );
  }
}
