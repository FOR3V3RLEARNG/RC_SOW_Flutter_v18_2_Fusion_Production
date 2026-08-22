import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/design_tokens.dart';
import '../../state/app_state.dart';
import '../admin/admin_screen.dart';
import '../messages/gmail_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          const SectionLabel('Appearance'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.brightness_6_outlined),
                  title: const Text('Appearance'),
                  subtitle: Text(_themeModeLabel(state.themeMode)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _themeMode(context),
                ),
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
                  onChanged: (value) => state.setSetting('highContrast', value),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.motion_photos_off),
                  title: const Text('Reduced motion'),
                  value: state.reduceMotion,
                  onChanged: (value) => state.setSetting('reduceMotion', value),
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
                  onChanged: (value) => state.setSetting('showGrid', value),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.straighten),
                  title: const Text('Snap geometry'),
                  value: state.snapDrawing,
                  onChanged: (value) => state.setSetting('snapDrawing', value),
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
                  title: const Text('Gmail inside RC SOW'),
                  subtitle: Text(
                    session?.providerToken == null
                        ? 'Reconnect Google to grant Gmail read/send access'
                        : 'Google mailbox access is available',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => GmailScreen(state: state),
                    ),
                  ),
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
                  MaterialPageRoute<void>(
                    builder: (_) => AdminScreen(state: state),
                  ),
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
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Account refreshed.')),
                      );
                    }
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
              subtitle: Text('Fusion Production v18.3.1 bugfix candidate'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _themeMode(BuildContext context) async {
    final selected = await showModalBottomSheet<ThemeMode>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values
              .map(
                (mode) => ListTile(
                  leading: Icon(_themeModeIcon(mode)),
                  title: Text(_themeModeLabel(mode)),
                  trailing: state.themeMode == mode
                      ? const Icon(Icons.check, color: RcColors.brand)
                      : null,
                  onTap: () => Navigator.pop(sheetContext, mode),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (selected != null) {
      await state.setSetting('themeMode', selected);
    }
  }

  Future<void> _style(BuildContext context) async {
    final selected = await showModalBottomSheet<RcDesignStyle>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
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
              (style) => ListTile(
                title: Text(style.label),
                subtitle: Text(style.description),
                trailing: state.designStyle == style
                    ? const Icon(Icons.check, color: RcColors.brand)
                    : null,
                onTap: () => Navigator.pop(sheetContext, style),
              ),
            ),
          ],
        ),
      ),
    );
    if (selected != null) {
      await state.setSetting('designStyle', selected);
    }
  }

  Future<void> _units(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Feet', 'Metric']
              .map(
                (unit) => ListTile(
                  title: Text(unit),
                  trailing: state.measurementUnit == unit
                      ? const Icon(Icons.check, color: RcColors.brand)
                      : null,
                  onTap: () => Navigator.pop(sheetContext, unit),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (selected != null) {
      await state.setSetting('measurementUnit', selected);
    }
  }

  static String _themeModeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'System',
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
  };

  static IconData _themeModeIcon(ThemeMode mode) => switch (mode) {
    ThemeMode.system => Icons.brightness_auto_outlined,
    ThemeMode.light => Icons.light_mode_outlined,
    ThemeMode.dark => Icons.dark_mode_outlined,
  };
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
