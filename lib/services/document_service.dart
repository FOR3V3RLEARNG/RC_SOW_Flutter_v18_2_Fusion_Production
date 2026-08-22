import 'dart:typed_data';
import 'package:cross_file/cross_file.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_models.dart';

class RcTemplateDefinition {
  const RcTemplateDefinition({required this.key, required this.title, required this.assetPath, required this.fileName, required this.mimeType, required this.eventType});
  final String key; final String title; final String assetPath; final String fileName; final String mimeType; final String eventType;
}

abstract final class RcTemplates {
  static const all = <RcTemplateDefinition>[
    RcTemplateDefinition(key:'scope',title:'Scope of Work',assetPath:'assets/templates/original/SOW_Excel_Template_Blank.xlsx',fileName:'SOW_Excel_Template_Blank.xlsx',mimeType:'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',eventType:'scope'),
    RcTemplateDefinition(key:'workPlan',title:'Work Plan',assetPath:'assets/templates/original/Workplan_Blank.xlsx',fileName:'Workplan-Blank.xlsx',mimeType:'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',eventType:'workPlan'),
    RcTemplateDefinition(key:'controlData',title:'Control of Works',assetPath:'assets/templates/original/Control_of_Works_Blank.xlsx',fileName:'Control-of-works-Blank.xlsx',mimeType:'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',eventType:'controlData'),
    RcTemplateDefinition(key:'monitoring',title:'Monitoring Checklist',assetPath:'assets/templates/original/Monitoring_Checklist_Roof_Repair.docx',fileName:'Monitoring-checklist-roof-repair.docx',mimeType:'application/vnd.openxmlformats-officedocument.wordprocessingml.document',eventType:'monitoring'),
    RcTemplateDefinition(key:'notice',title:'Notice of Completion',assetPath:'assets/templates/original/Notice_of_Completion.docx',fileName:'Notice-of-Completion.docx',mimeType:'application/vnd.openxmlformats-officedocument.wordprocessingml.document',eventType:'notice'),
    RcTemplateDefinition(key:'payment',title:'Payment Request',assetPath:'assets/templates/original/Payment_Request_Form.docx',fileName:'Payment-Request.docx',mimeType:'application/vnd.openxmlformats-officedocument.wordprocessingml.document',eventType:'payment'),
  ];
  static RcTemplateDefinition? forEventType(String eventType) {
    for (final t in all) { if (t.eventType == eventType) return t; }
    if (const {'siteVisit','dailyLog','documentChecklist','materialRequest','consumables','inventory'}.contains(eventType)) return all.firstWhere((e) => e.key == 'controlData');
    return null;
  }
}

class RcDocumentService {
  RcDocumentService(this.client); final SupabaseClient client;
  Future<Uint8List> templateBytes(RcTemplateDefinition template) async {
    try {
      final row = await client.from('document_templates').select('storage_path').eq('template_key', template.key).eq('active', true).maybeSingle();
      final path = row?['storage_path'] as String?;
      if (path != null && path.isNotEmpty) return client.storage.from('document-templates').download(path);
    } catch (_) {}
    final data = await rootBundle.load(template.assetPath);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }
  Future<Uri?> saveTemplate(RcTemplateDefinition template) async => FilePicker.saveFile(dialogTitle:'Save ${template.title} template', fileName:template.fileName, bytes:await templateBytes(template));
  Future<void> shareTemplate(RcTemplateDefinition template) async {
    final bytes = await templateBytes(template);
    await shareBytes(bytes: bytes, fileName: template.fileName, mimeType: template.mimeType, subject:'RC SOW — ${template.title}');
  }
  Future<void> replaceTemplate({required RcTemplateDefinition template, required UserProfile profile}) async {
    if (!profile.canManageTemplates) throw StateError('Template management privilege required.');
    final picked = await FilePicker.pickFile(type: FileType.custom, allowedExtensions:[template.fileName.split('.').last]);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final storagePath = '${template.key}/${DateTime.now().millisecondsSinceEpoch}.${template.fileName.split('.').last}';
    await client.storage.from('document-templates').uploadBinary(storagePath, bytes, fileOptions: FileOptions(contentType: template.mimeType, upsert: true));
    await client.from('document_templates').upsert({'template_key':template.key,'display_name':template.title,'file_name':picked.name,'mime_type':template.mimeType,'storage_path':storagePath,'active':true,'updated_by':profile.userId});
  }
  Future<Uint8List> productionXlsx(List<ProductionRecord> records) async {
    final excel = Excel.createExcel(); final sheet = excel[excel.getDefaultSheet() ?? 'Sheet1'];
    sheet.appendRow([TextCellValue('House Code'),TextCellValue('Parish'),TextCellValue('Record Type'),TextCellValue('Status'),TextCellValue('Title'),TextCellValue('Summary'),TextCellValue('Updated')]);
    for (final r in records) { sheet.appendRow([TextCellValue(r.houseCode),TextCellValue(r.parish),TextCellValue(r.eventType),TextCellValue(r.status),TextCellValue(r.title),TextCellValue(r.summary),TextCellValue(r.updatedAt.toLocal().toIso8601String())]); }
    final encoded=excel.encode(); if (encoded==null) throw StateError('Could not generate Excel export.'); return Uint8List.fromList(encoded);
  }
  Future<Uint8List> productionPdf(List<ProductionRecord> records) async {
    final pdf=pw.Document(); pdf.addPage(pw.MultiPage(pageFormat:PdfPageFormat.a4.landscape, build:(_)=>[pw.Text('RC SOW — Production Export',style:pw.TextStyle(fontSize:16,fontWeight:pw.FontWeight.bold)),pw.SizedBox(height:12),pw.TableHelper.fromTextArray(headers:const ['House','Parish','Type','Status','Title','Summary','Updated'],data:records.map((r)=>[r.houseCode,r.parish,r.eventType,r.status,r.title,r.summary,r.updatedAt.toLocal().toString()]).toList(),headerStyle:pw.TextStyle(fontWeight:pw.FontWeight.bold),cellStyle:const pw.TextStyle(fontSize:8))])); return pdf.save();
  }
  Future<void> shareBytes({required Uint8List bytes,required String fileName,required String mimeType,String? subject,String? text}) async => SharePlus.instance.share(ShareParams(subject:subject,text:text,files:[XFile.fromData(bytes,mimeType:mimeType)],fileNameOverrides:[fileName]));
}
