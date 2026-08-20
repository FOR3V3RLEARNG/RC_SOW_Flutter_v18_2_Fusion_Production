import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth_support.dart';
import '../../core/design_tokens.dart';
import '../../core/rc_components.dart';
import '../../state/app_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          const RcPageHeading(
            eyebrow: 'RC SOW',
            title: 'Settings',
            subtitle:
                'Tune the field experience without weakening predictable interaction or production controls.',
          ),
          const SizedBox(height: 18),
          const SectionLabel('Appearance'),
          _Group(
            children: [
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Appearance mode'),
                subtitle: Text(_themeModeLabel(state.themeMode)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _themeMode(context),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.contrast_outlined),
                title: const Text('High contrast'),
                subtitle: const Text('Stronger operational boundaries'),
                value: state.highContrast,
                onChanged: (v) => state.setSetting('highContrast', v),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.density_medium_outlined),
                title: const Text('Compact field density'),
                subtitle: const Text('Reduce spacing in dense operational views'),
                value: state.compactDensity,
                onChanged: (v) => state.setSetting('compactDensity', v),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const SectionLabel('Accessibility & motion'),
          _Group(
            shape: RcSurfaceShape.hero,
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.motion_photos_off_outlined),
                title: const Text('Reduced motion'),
                subtitle: const Text('Remove non-essential container transitions'),
                value: state.reduceMotion,
                onChanged: (v) => state.setSetting('reduceMotion', v),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.vibration_outlined),
                title: const Text('Haptics'),
                subtitle: const Text('Feedback only for deliberate actions'),
                value: state.haptics,
                onChanged: (v) => state.setSetting('haptics', v),
              ),
              const ListTile(
                leading: Icon(Icons.text_fields_outlined),
                title: Text('System text scaling'),
                subtitle: Text('RC SOW respects the device accessibility text size.'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const SectionLabel('Field drawing'),
          _Group(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.grid_4x4_outlined),
                title: const Text('Construction grid'),
                value: state.showGrid,
                onChanged: (v) => state.setSetting('showGrid', v),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.straighten_outlined),
                title: const Text('Snap geometry'),
                subtitle: const Text('Keep wall and ridge placement aligned where practical'),
                value: state.snapDrawing,
                onChanged: (v) => state.setSetting('snapDrawing', v),
              ),
              ListTile(
                leading: const Icon(Icons.square_foot_outlined),
                title: const Text('Measurement units'),
                subtitle: Text(state.measurementUnit),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _units(context),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const SectionLabel('Maps & location'),
          _Group(
            shape: RcSurfaceShape.offset,
            children: [
              ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: const Text('House location behavior'),
                subtitle: const Text('Open saved house coordinates in the configured map provider.'),
                trailing: const Icon(Icons.info_outline),
                onTap: () => _info(
                  context,
                  'Maps & Location',
                  'RC SOW only opens location resources when requested. Core Scope and Control workflows remain usable without loading a map SDK.',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.my_location_outlined),
                title: const Text('Live Tracker'),
                subtitle: const Text('Tracker resources remain role/parish scoped.'),
                trailing: const Icon(Icons.verified_user_outlined),
                onTap: () => _info(
                  context,
                  'Location privacy',
                  'Tracker and house-location visibility follows backend access rules. The app does not bypass parish or role policy.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const SectionLabel('Connectivity'),
          _Group(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.cloud_off_outlined),
                title: const Text('Offline-aware mode'),
                subtitle: const Text('Prefer local-safe screens and explicit retry states during weak connectivity'),
                value: state.offlineMode,
                onChanged: (v) => state.setSetting('offlineMode', v),
              ),
              ListTile(
                leading: const Icon(Icons.sync_outlined),
                title: const Text('Refresh account & permissions'),
                subtitle: const Text('Re-read the signed-in RC SOW profile from Supabase'),
                trailing: const Icon(Icons.refresh_rounded),
                onTap: () async {
                  await state.refreshProfile();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Account and permissions refreshed.')),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          const SectionLabel('Account & security'),
          _Group(
            shape: RcSurfaceShape.hero,
            children: [
              ListTile(
                leading: const Icon(Icons.account_circle_outlined),
                title: Text(state.profile?.fullName ?? state.profile?.email ?? 'Signed-in user'),
                subtitle: Text('${state.profile?.role ?? ''} • ${state.profile?.parish ?? ''}'),
              ),
              const ListTile(
                leading: Icon(Icons.key_off_outlined),
                title: Text('Credential storage'),
                subtitle: Text('RC SOW never stores passwords or auth tokens in SharedPreferences.'),
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: RcColors.danger),
                title: const Text('Sign out'),
                onTap: () => Supabase.instance.client.auth.signOut(),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const SectionLabel('Diagnostics'),
          _Group(
            children: [
              ListTile(
                leading: const Icon(Icons.health_and_safety_outlined),
                title: const Text('Session callback status'),
                subtitle: Text(state.lastAuthDiagnostic ?? 'No callback diagnostic yet'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _diagnostics(context),
              ),
              const ListTile(
                leading: Icon(Icons.shield_outlined),
                title: Text('OAuth return URI'),
                subtitle: Text(RcAuthSupport.oauthRedirectUri),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const SectionLabel('About'),
          _Group(
            shape: RcSurfaceShape.offset,
            children: [
              const ListTile(
                leading: Icon(Icons.home_repair_service_outlined),
                title: Text('RC SOW'),
                subtitle: Text('Flutter v18.2 • Fusion production management edition'),
              ),
              ListTile(
                leading: const Icon(Icons.accessibility_new_outlined),
                title: const Text('Interaction principles'),
                subtitle: const Text('Orientation, accessibility and predictable return paths remain mandatory.'),
                onTap: () => _info(
                  context,
                  'Interaction principles',
                  'Expressive shapes and motion are used only when they clarify hierarchy or state. Standard back behavior, labeled navigation destinations, large touch targets and semantic controls remain intact.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _themeModeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'Use device setting',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      };

  Future<void> _themeMode(BuildContext context) async {
    final selected = await showModalBottomSheet<ThemeMode>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values
              .map(
                (mode) => ListTile(
                  leading: Icon(switch (mode) {
                    ThemeMode.system => Icons.brightness_auto_outlined,
                    ThemeMode.light => Icons.light_mode_outlined,
                    ThemeMode.dark => Icons.dark_mode_outlined,
                  }),
                  title: Text(_themeModeLabel(mode)),
                  trailing: state.themeMode == mode
                      ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                      : null,
                  onTap: () => Navigator.pop(ctx, mode),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (selected != null) await state.setSetting('themeMode', selected);
  }

  Future<void> _units(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('Measurement Units', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
            for (final unit in const ['Feet', 'Metric'])
              ListTile(
                title: Text(unit),
                trailing: state.measurementUnit == unit
                    ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, unit),
              ),
          ],
        ),
      ),
    );
    if (selected != null) await state.setSetting('measurementUnit', selected);
  }

  Future<void> _diagnostics(BuildContext context) => _info(
        context,
        'Diagnostics',
        'Session: ${state.signedIn ? 'signed in' : 'signed out'}\n'
        'Profile: ${state.profile?.role ?? 'not loaded'} / ${state.profile?.parish ?? '—'}\n'
        'Callback: ${RcAuthSupport.oauthRedirectUri}\n'
        'Last auth diagnostic: ${state.lastAuthDiagnostic ?? 'none'}\n\n'
        'No password, access token, refresh token or secret is shown here.',
      );

  Future<void> _info(BuildContext context, String title, String body) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 10),
                Text(body, style: Theme.of(ctx).textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      );
}

class _Group extends StatelessWidget {
  const _Group({required this.children, this.shape = RcSurfaceShape.standard});
  final List<Widget> children;
  final RcSurfaceShape shape;

  @override
  Widget build(BuildContext context) => RcExpressiveSurface(
        shape: shape,
        padding: EdgeInsets.zero,
        child: Column(children: children),
      );
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
        child: Text(
          text.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.15,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
}
