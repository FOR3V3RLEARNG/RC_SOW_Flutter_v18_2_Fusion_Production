import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_constants.dart';
import '../../core/rc_components.dart';
import '../../state/app_state.dart';
import '../admin/admin_screen.dart';
import '../gmail/gmail_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final profile = state.profile!;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 70),
        children: [
          const RcPageHeading(
            eyebrow: 'Workspace preferences',
            title: 'Settings',
            subtitle: 'Appearance, field behavior, dashboard visibility, collaboration and account controls.',
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Design DNA',
            icon: Icons.palette_outlined,
            children: [
              DropdownButtonFormField<RcDesignDna>(
                initialValue: state.designDna,
                decoration: const InputDecoration(labelText: 'UI style system'),
                items: RcDesignDna.values.map((dna) => DropdownMenuItem(value: dna, child: Text('${dna.label} — ${dna.subtitle}'))).toList(),
                onChanged: (value) { if (value != null) state.setSetting('designDna', value); },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<ThemeMode>(
                initialValue: state.themeMode,
                decoration: const InputDecoration(labelText: 'Appearance'),
                items: const [
                  DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                  DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                  DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                ],
                onChanged: (value) { if (value != null) state.setSetting('themeMode', value); },
              ),
              SwitchListTile.adaptive(title: const Text('High contrast'), subtitle: const Text('Stronger borders and state separation.'), value: state.highContrast, onChanged: (v) => state.setSetting('highContrast', v)),
              SwitchListTile.adaptive(title: const Text('Compact review density'), subtitle: const Text('Denser tablet/management review surfaces.'), value: state.compactDensity, onChanged: (v) => state.setSetting('compactDensity', v)),
              SwitchListTile.adaptive(title: const Text('Reduced motion'), value: state.reduceMotion, onChanged: (v) => state.setSetting('reduceMotion', v)),
            ],
          ),
          _Section(
            title: 'Dashboard',
            icon: Icons.dashboard_customize_outlined,
            children: [
              SwitchListTile.adaptive(title: const Text('Show payment due'), value: state.showPaymentDue, onChanged: (v) => state.setSetting('showPaymentDue', v)),
              SwitchListTile.adaptive(title: const Text('Show payment received'), subtitle: const Text('Hide paid items from the dashboard without removing production history.'), value: state.showPaymentReceived, onChanged: (v) => state.setSetting('showPaymentReceived', v)),
            ],
          ),
          _Section(
            title: 'Field tools',
            icon: Icons.architecture_outlined,
            children: [
              SwitchListTile.adaptive(title: const Text('Drawing snap'), value: state.snapDrawing, onChanged: (v) => state.setSetting('snapDrawing', v)),
              SwitchListTile.adaptive(title: const Text('Drawing grid'), value: state.showGrid, onChanged: (v) => state.setSetting('showGrid', v)),
              SwitchListTile.adaptive(title: const Text('Haptics'), value: state.haptics, onChanged: (v) => state.setSetting('haptics', v)),
              SwitchListTile.adaptive(title: const Text('Offline mode'), subtitle: const Text('Explicitly show sync confidence and avoid silent data assumptions.'), value: state.offlineMode, onChanged: (v) => state.setSetting('offlineMode', v)),
              DropdownButtonFormField<String>(initialValue: state.measurementUnit, decoration: const InputDecoration(labelText: 'Measurement unit'), items: const ['Feet', 'Meters'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (v) { if (v != null) state.setSetting('measurementUnit', v); }),
            ],
          ),
          _Section(
            title: 'Communication',
            icon: Icons.forum_outlined,
            children: [
              ListTile(
                leading: const Icon(Icons.mail_outline),
                title: const Text('Gmail inside RC SOW'),
                subtitle: Text(state.repository.googleProviderToken == null ? 'Reconnect Google to grant Gmail read/send permission.' : 'Google token available for this session.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => GmailScreen(state: state))),
              ),
            ],
          ),
          if (profile.canViewAdmin)
            _Section(
              title: 'Administration',
              icon: Icons.admin_panel_settings_outlined,
              children: [
                ListTile(leading: const Icon(Icons.manage_accounts_outlined), title: const Text('Admin Control Centre'), subtitle: const Text('Users, privileges, templates, forms, maps and suggestions.'), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AdminScreen(state: state)))),
              ],
            ),
          _Section(
            title: 'Account',
            icon: Icons.person_outline,
            children: [
              ListTile(title: Text(profile.displayName), subtitle: Text('${profile.email}\n${profile.role} • ${profile.parish}'), isThreeLine: true),
              ListTile(leading: const Icon(Icons.refresh), title: const Text('Refresh access profile'), subtitle: Text(state.lastAuthDiagnostic ?? ''), onTap: state.refreshProfile),
              ListTile(leading: const Icon(Icons.logout), title: const Text('Sign out'), onTap: () => Supabase.instance.client.auth.signOut()),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.icon, required this.children});
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: RcExpressiveSurface(
        shape: RcSurfaceShape.offset,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [Icon(icon, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 8), Text(title, style: Theme.of(context).textTheme.titleLarge)]),
          const SizedBox(height: 10),
          ...children,
        ]),
      ),
    );
  }
}
