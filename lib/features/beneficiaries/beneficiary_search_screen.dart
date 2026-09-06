import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/rc_components.dart';
import '../../models/app_models.dart';
import '../../state/app_state.dart';

class BeneficiarySearchScreen extends StatefulWidget {
  const BeneficiarySearchScreen({super.key, required this.state});
  final AppState state;

  @override
  State<BeneficiarySearchScreen> createState() => _BeneficiarySearchScreenState();
}

class _BeneficiarySearchScreenState extends State<BeneficiarySearchScreen> {
  final search = TextEditingController();
  Future<List<BeneficiaryRecord>>? future;

  @override
  void dispose() { search.dispose(); super.dispose(); }

  void run() => setState(() => future = widget.state.repository.searchBeneficiaries(widget.state.profile!, query: search.text.trim(), limit: 200));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('IA • Shelter Beneficiary Data')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(controller: search, autofocus: true, decoration: InputDecoration(labelText: 'House code / beneficiary / community', prefixIcon: const Icon(Icons.auto_awesome_outlined), suffixIcon: IconButton(onPressed: run, icon: const Icon(Icons.search))), onSubmitted: (_) => run()),
        ),
        Expanded(
          child: FutureBuilder<List<BeneficiaryRecord>>(
            future: future,
            builder: (_, snap) {
              final records = snap.data ?? const <BeneficiaryRecord>[];
              if (future == null) return const Center(child: Text('Search protected Shelter assessment data.'));
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: RcExpressiveSurface(
                      tone: Theme.of(context).colorScheme.errorContainer,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Text('Beneficiary data could not be loaded. Check your connection and parish access.'),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(onPressed: run, icon: const Icon(Icons.refresh), label: const Text('Retry')),
                      ]),
                    ),
                  ),
                );
              }
              if (records.isEmpty) return const Center(child: Text('No matching beneficiary records are visible for this account.'));
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 40),
                itemCount: records.length,
                separatorBuilder: (_, _) => const SizedBox(height: 7),
                itemBuilder: (_, index) {
                  final item = records[index];
                  return RcExpressiveSurface(
                    shape: RcSurfaceShape.offset,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${item.houseCode} • ${item.beneficiaryName}', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('${item.parish} • ${item.cluster}${item.gps.isEmpty ? '' : '\n${item.gps}'}'),
                      if (item.hasCoordinates) ...[
                        const SizedBox(height: 8),
                        OutlinedButton.icon(onPressed: () async {
                          final uri = Uri.parse(item.mapsUrl ?? 'https://www.google.com/maps/search/?api=1&query=${item.latitude},${item.longitude}');
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }, icon: const Icon(Icons.map_outlined), label: const Text('Open mapped house')),
                      ],
                    ]),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}
