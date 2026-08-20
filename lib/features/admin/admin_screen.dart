import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';
import '../../state/app_state.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key, required this.state});
  final AppState state;

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  late Future<List<Map<String, dynamic>>> requests;

  @override
  void initState() {
    super.initState();
    requests = widget.state.profile?.canViewAdmin == true
        ? widget.state.repository.registrationRequests()
        : Future.value(const <Map<String, dynamic>>[]);
  }

  void refresh() {
    if (widget.state.profile?.canViewAdmin != true) return;
    setState(() => requests = widget.state.repository.registrationRequests());
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state.profile?.canViewAdmin != true) {
      return Scaffold(appBar: AppBar(title: const Text('Admin Dashboard')), body: const Center(child: Padding(padding: EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.lock_outline, size: 54, color: RcColors.brand), SizedBox(height: 14), Text('Admin access only', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), SizedBox(height: 8), Text('This area is restricted to the Admin role.', textAlign: TextAlign.center)]))));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: FutureBuilder<List<Map<String, dynamic>>>(future: requests, builder: (context, snap) {
        final list = snap.data ?? const <Map<String, dynamic>>[];
        return ListView(padding: const EdgeInsets.all(16), children: [
          Wrap(spacing: 8, runSpacing: 8, children: [
            Chip(avatar: const Icon(Icons.admin_panel_settings, size: 18, color: RcColors.brand), label: const Text('Admin Only')),
            Chip(label: Text('${list.length} pending registration${list.length == 1 ? '' : 's'}')),
          ]),
          const SizedBox(height: 14),
          const Text('Registration approvals', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          if (snap.connectionState == ConnectionState.waiting) const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator())),
          if (snap.hasError) Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Could not load requests: ${snap.error}'))),
          if (snap.connectionState != ConnectionState.waiting && list.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('No pending registration requests.'))),
          Card(child: Column(children: list.map((r) => ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_add_alt_1_outlined)),
            title: Text('${r['full_name'] ?? r['email'] ?? 'New user'}', style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text('${r['requested_role'] ?? 'Role pending'} • ${r['requested_parish'] ?? 'Parish pending'}'),
            trailing: PopupMenuButton<String>(onSelected: (action) => _act(action, '${r['user_id']}'), itemBuilder: (_) => const [PopupMenuItem(value: 'approve', child: Text('Approve')), PopupMenuItem(value: 'reject', child: Text('Reject'))]),
          )).toList())),
        ]);
      }),
    );
  }

  Future<void> _act(String action, String userId) async {
    if (action == 'approve') {
      await widget.state.repository.approveRegistration(userId);
    } else {
      await widget.state.repository.rejectRegistration(userId);
    }
    refresh();
  }
}
