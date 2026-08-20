import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';
import '../../state/app_state.dart';

class ActiveUsersScreen extends StatelessWidget {
  const ActiveUsersScreen({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users (Online)')),
      body: FutureBuilder<List<Map<String, dynamic>>>(future: state.repository.activeUsers(), builder: (context, snap) {
        final users = snap.data ?? const <Map<String, dynamic>>[];
        return ListView(padding: const EdgeInsets.all(16), children: [
          Row(children: [const Icon(Icons.circle, size: 11, color: RcColors.success), const SizedBox(width: 6), Text('${users.length} online', style: const TextStyle(fontWeight: FontWeight.w900))]),
          const SizedBox(height: 12),
          if (snap.connectionState == ConnectionState.waiting) const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator())),
          Card(child: Column(children: users.map((u) => ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text('${u['full_name'] ?? u['email'] ?? 'RC SOW user'}', style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text('${u['role'] ?? ''} • ${u['parish'] ?? ''}'),
            trailing: const Icon(Icons.circle, size: 10, color: RcColors.success),
          )).toList())),
        ]);
      }),
    );
  }
}
