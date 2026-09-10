import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../core/rc_components.dart';
import '../../models/app_models.dart';
import '../../services/beneficiary_import_service.dart';
import '../../state/app_state.dart';

class BeneficiarySearchScreen extends StatefulWidget {
  const BeneficiarySearchScreen({super.key, required this.state});
  final AppState state;

  @override
  State<BeneficiarySearchScreen> createState() =>
      _BeneficiarySearchScreenState();
}

class _BeneficiarySearchScreenState extends State<BeneficiarySearchScreen> {
  final search = TextEditingController();
  Future<List<BeneficiaryRecord>>? future;
  bool importing = false;

  bool get canImport =>
      widget.state.profile!.isAdmin ||
      widget.state.profile!.hasPrivilege('manageBeneficiarySources');

  @override
  void initState() {
    super.initState();
    run();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void run() => setState(
    () => future = widget.state.repository.searchBeneficiaries(
      widget.state.profile!,
      query: search.text.trim(),
      limit: 500,
    ),
  );

  Future<void> _importShelterWorkbook() async {
    if (!canImport || importing) return;

    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'xls'],
    );
    if (picked == null) return;

    setState(() => importing = true);
    try {
      final bytes = await picked.readAsBytes();
      final profile = widget.state.profile!;
      final fallbackParish = profile.canViewAllParishes
          ? 'Hanover'
          : profile.parish;

      final parsed = BeneficiaryImportService.parse(
        bytes,
        fileName: picked.name,
        fallbackParish: fallbackParish,
      );

      final count = await widget.state.repository.importBeneficiaryRows(
        parsed.rows,
      );
      if (!mounted) return;

      search.clear();
      run();

      final sheets = parsed.sheetNames.isEmpty
          ? ''
          : ' from ${parsed.sheetNames.join(', ')}';
      final skipped = parsed.skippedRows == 0
          ? ''
          : ' ${parsed.skippedRows} incomplete row(s) skipped.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$count Shelter beneficiary record(s) loaded$sheets.$skipped',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Beneficiary workbook import failed: $error')),
      );
    } finally {
      if (mounted) setState(() => importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IA • Shelter Beneficiary Data'),
        actions: [
          if (canImport)
            IconButton(
              tooltip: 'Import Shelter XLS/XLSX',
              onPressed: importing ? null : _importShelterWorkbook,
              icon: importing
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file_outlined),
            ),
        ],
      ),
      body: Column(
        children: [
          if (canImport)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: RcExpressiveSurface(
                shape: RcSurfaceShape.offset,
                child: Row(
                  children: [
                    const Icon(Icons.table_view_outlined),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Shelter beneficiary workbook',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Import House Code, beneficiary, community/cluster, GPS, contact and roof fields from Excel. Multiple worksheet tabs are supported.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.tonalIcon(
                      onPressed: importing ? null : _importShelterWorkbook,
                      icon: const Icon(Icons.upload_file_outlined),
                      label: const Text('Import XLS/XLSX'),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: search,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'House code / beneficiary / community',
                prefixIcon: const Icon(Icons.auto_awesome_outlined),
                suffixIcon: IconButton(
                  onPressed: run,
                  icon: const Icon(Icons.search),
                ),
              ),
              onSubmitted: (_) => run(),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<BeneficiaryRecord>>(
              future: future,
              builder: (_, snap) {
                final records = snap.data ?? const <BeneficiaryRecord>[];
                if (future == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: RcExpressiveSurface(
                        tone: Theme.of(context).colorScheme.errorContainer,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Beneficiary data could not be loaded. Check your connection and parish access.',
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: run,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                if (records.isEmpty) {
                  return const Center(
                    child: Text(
                      'No matching beneficiary records are visible for this account.',
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 40),
                  itemCount: records.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 7),
                  itemBuilder: (_, index) {
                    final item = records[index];
                    return RcExpressiveSurface(
                      shape: RcSurfaceShape.offset,
                      onTap: () => Navigator.of(context).pop(item),
                      semanticLabel:
                          'Select ${item.houseCode} ${item.beneficiaryName}',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.houseCode} • ${item.beneficiaryName}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.parish} • ${item.cluster}${item.gps.isEmpty ? '' : '\n${item.gps}'}',
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilledButton.tonalIcon(
                                onPressed: () =>
                                    Navigator.of(context).pop(item),
                                icon: const Icon(Icons.check_circle_outline),
                                label: const Text('Use this house'),
                              ),
                              if (item.hasCoordinates)
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final uri = Uri.parse(
                                      item.mapsUrl ??
                                          'https://www.google.com/maps/search/?api=1&query=${item.latitude},${item.longitude}',
                                    );
                                    await launchUrl(
                                      uri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  },
                                  icon: const Icon(Icons.map_outlined),
                                  label: const Text('Open mapped house'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
