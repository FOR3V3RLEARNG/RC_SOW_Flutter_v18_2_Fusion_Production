import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/design_tokens.dart';
import '../../state/app_state.dart';

class LiveTrackerScreen extends StatelessWidget {
  const LiveTrackerScreen({
    super.key,
    required this.state,
    this.showMapFirst = false,
  });
  final AppState state;
  final bool showMapFirst;

  @override
  Widget build(BuildContext context) {
    final p = state.profile!;
    return Scaffold(
      appBar: AppBar(title: Text(showMapFirst ? 'Field Map' : 'Live Tracker')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: showMapFirst
            ? state.repository.houseLocations(p)
            : state.repository.liveTrackers(p),
        builder: (context, snap) {
          final list = snap.data ?? const <Map<String, dynamic>>[];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (snap.hasError)
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Map/tracker data could not be loaded. Check your parish access and connection.',
                    ),
                  ),
                ),
              Card(
                color: RcColors.blueSoft,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Map and tracker content mounts only when opened. This keeps the five-tab field shell lightweight and avoids blocking core work on a map SDK.',
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (snap.connectionState == ConnectionState.waiting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: CircularProgressIndicator(),
                  ),
                ),
              if (list.isEmpty &&
                  snap.connectionState != ConnectionState.waiting)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text(
                      'No live tracker or house-location records are available for this account yet.',
                    ),
                  ),
                ),
              Card(
                child: Column(
                  children: list.map((r) {
                    final label =
                        '${r['house_code'] ?? r['label'] ?? r['parish'] ?? 'Live resource'}';
                    final parish = '${r['parish'] ?? ''}';
                    final rawUrl = '${r['maps_url'] ?? r['url'] ?? ''}';
                    return ListTile(
                      leading: Icon(
                        showMapFirst
                            ? Icons.location_on_outlined
                            : Icons.location_searching,
                        color: RcColors.brand,
                      ),
                      title: Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(parish),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: rawUrl.isEmpty
                          ? null
                          : () async {
                              final uri = Uri.tryParse(rawUrl);
                              if (uri == null) return;
                              final opened = await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                              if (!opened && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'This map link could not be opened.',
                                    ),
                                  ),
                                );
                              }
                            },
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
