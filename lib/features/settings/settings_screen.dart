import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/design_tokens.dart';
import '../../state/app_state.dart';
import '../admin/admin_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      children: [
        const SectionLabel('Appearance'),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.style_outlined),
                title: const Text('Display style'),
                subtitle: Text(state.designStyle.label),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _style(context),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.contrast),
                title: const Text('High contrast'),
                value: state.highContrast,
                onChanged: (v) => state.setSetting('highContrast', v),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.motion_photos_off),
                title: const Text('Reduced motion'),
                value: state.reduceMotion,
                onChanged: (v) => state.setSetting('reduceMotion', v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SectionLabel('Field Drawing'),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.grid_4x4),
                title: const Text('Construction grid'),
                value: state.showGrid,
                onChanged: (v) => state.setSetting('showGrid', v),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.straighten),
                title: const Text('Snap geometry'),
                value: state.snapDrawing,
                onChanged: (v) => state.setSetting('snapDrawing', v),
              ),
              ListTile(
                leading: const Icon(Icons.square_foot),
                title: const Text('Measurement units'),
                subtitle: Text(state.measurementUnit),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _units(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SectionLabel('Communication'),
        Card(
          child: Column(
            children: [
              const ListTile(
                leading: Icon(Icons.forum_outlined),
                title: Text('RC SOW interactive messages'),
                subtitle: Text(
                  'Message drawer, replies and online-user messaging are enabled.',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.mail_outline),
                title: const Text('Gmail access'),
                subtitle: Text(
                  Supabase.instance.client.auth.currentSession?.providerToken ==
                          null
                      ? 'Reconnect Google to grant Gmail scopes'
                      : 'Google provider token available',
                ),
                trailing: const Icon(Icons.info_outline),
              ),
            ],
          ),
        ),
        if (state.profile?.canViewAdmin == true) ...[
          const SizedBox(height: 16),
          const SectionLabel('Administration'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text('Manage users, privileges & templates'),
              subtitle: const Text(
                'Block, suspend, restore, promote and configure RC SOW access.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AdminScreen(state: state)),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        const SectionLabel('Account'),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.account_circle_outlined),
                title: Text(
                  state.profile?.fullName ?? state.profile?.email ?? 'User',
                ),
                subtitle: Text(
                  '${state.profile?.role ?? ''} • ${state.profile?.parish ?? ''}',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Refresh account & permissions'),
                onTap: () async {
                  await state.refreshProfile();
                  if (context.mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Account refreshed.')),
                    );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: RcColors.danger),
                title: const Text('Sign out'),
                onTap: () => Supabase.instance.client.auth.signOut(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SectionLabel('About'),
        const Card(
          child: ListTile(
            leading: Icon(Icons.home_repair_service_outlined),
            title: Text('RC SOW'),
            subtitle: Text('Fusion Production v18.3 source candidate'),
          ),
        ),
      ],
    ),
  );
  Future<void> _style(BuildContext context) async {
    final selected = await showModalBottomSheet<RcDesignStyle>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Display style',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            ...RcDesignStyle.values.map(
              (s) => ListTile(
                title: Text(s.label),
                trailing: state.designStyle == s
                    ? const Icon(Icons.check, color: RcColors.brand)
                    : null,
                onTap: () => Navigator.pop(ctx, s),
              ),
            ),
          ],
        ),
      ),
    );
    if (selected != null) await state.setSetting('designStyle', selected);
  }

  Future<void> _units(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Feet', 'Metric']
              .map(
                (u) => ListTile(
                  title: Text(u),
                  trailing: state.measurementUnit == u
                      ? const Icon(Icons.check, color: RcColors.brand)
                      : null,
                  onTap: () => Navigator.pop(ctx, u),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (selected != null) await state.setSetting('measurementUnit', selected);
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
        color: RcColors.muted,
      ),
    ),
  );
}
