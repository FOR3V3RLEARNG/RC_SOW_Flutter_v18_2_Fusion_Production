import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design_tokens.dart';
import '../../core/rc_components.dart';
import '../../state/app_state.dart';
import '../messages/messages_screen.dart';

Future<void> showUsersOnlinePanel(BuildContext context, AppState state) async {
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Team presence',
    barrierColor: Colors.black26,
    transitionDuration: state.reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 260),
    pageBuilder: (context, _, _) => Align(
      alignment: Alignment.bottomRight,
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.sizeOf(context).width.clamp(0.0, 400.0),
            height: MediaQuery.sizeOf(context).height * .76,
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 86),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 28,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: ActiveUsersBody(state: state, showClose: true),
          ),
        ),
      ),
    ),
  );
}

class ActiveUsersScreen extends StatelessWidget {
  const ActiveUsersScreen({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Team Presence')),
    body: ActiveUsersBody(state: state),
  );
}

class ActiveUsersBody extends StatefulWidget {
  const ActiveUsersBody({
    super.key,
    required this.state,
    this.showClose = false,
  });

  final AppState state;
  final bool showClose;

  @override
  State<ActiveUsersBody> createState() => _ActiveUsersBodyState();
}

class _ActiveUsersBodyState extends State<ActiveUsersBody> {
  late Future<List<Map<String, dynamic>>> future;
  bool changing = false;

  @override
  void initState() {
    super.initState();
    future = widget.state.repository.activeUsers();
  }

  Future<void> _refresh() async {
    setState(() => future = widget.state.repository.activeUsers());
    await future;
  }

  Future<void> _changePresence(String value) async {
    setState(() => changing = true);
    try {
      await widget.state.setPresenceStatus(value);
      await _refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Presence could not be changed: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => changing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Team Presence', style: theme.textTheme.titleLarge),
                    Text(
                      'Only people active in RC SOW within the last 2 minutes are shown.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (widget.showClose)
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
          child: RcExpressiveSurface(
            shape: RcSurfaceShape.pill,
            tone: theme.colorScheme.surfaceContainerLow,
            padding: const EdgeInsets.all(8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'active',
                    icon: Icon(Icons.circle, color: RcColors.success),
                    label: Text('Active'),
                  ),
                  ButtonSegment(
                    value: 'busy',
                    icon: Icon(Icons.circle, color: RcColors.warning),
                    label: Text('Busy'),
                  ),
                  ButtonSegment(
                    value: 'invisible',
                    icon: Icon(Icons.visibility_off_outlined),
                    label: Text('Invisible'),
                  ),
                ],
                selected: {widget.state.presenceStatus},
                showSelectedIcon: false,
                onSelectionChanged: changing
                    ? null
                    : (selection) => _changePresence(selection.first),
              ),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: future,
              builder: (_, snap) {
                final users = snap.data ?? const <Map<String, dynamic>>[];

                if (snap.connectionState == ConnectionState.waiting &&
                    users.isEmpty) {
                  return const ListView(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ],
                  );
                }

                if (snap.hasError) {
                  return ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: RcExpressiveSurface(
                          tone: theme.colorScheme.errorContainer,
                          child: const Text(
                            'Team presence could not be loaded.',
                          ),
                        ),
                      ),
                    ],
                  );
                }

                if (users.isEmpty) {
                  return const ListView(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(28),
                        child: Center(
                          child: Text(
                            'No other users are online right now.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 22),
                  itemCount: users.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 7),
                  itemBuilder: (_, index) {
                    final user = users[index];
                    final status =
                        '${user['presence_status'] ?? 'active'}'.toLowerCase();
                    final busy = status == 'busy';
                    final color = busy ? RcColors.warning : RcColors.success;
                    final name = '${user['full_name'] ?? ''}'.trim();
                    final email = '${user['email'] ?? ''}'.trim();

                    return RcExpressiveSurface(
                      shape: RcSurfaceShape.offset,
                      padding: const EdgeInsets.all(11),
                      onTap: () => _openUser(user),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                child: Text(
                                  (name.isNotEmpty ? name : email).isEmpty
                                      ? '?'
                                      : (name.isNotEmpty ? name : email)[0]
                                            .toUpperCase(),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: color,
                                    border: Border.all(
                                      color: theme.colorScheme.surface,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name.isEmpty ? email : name,
                                  style: theme.textTheme.titleMedium,
                                ),
                                Text(
                                  '${user['role'] ?? ''} • ${user['parish'] ?? ''}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          RcStatusPill(
                            label: busy ? 'BUSY' : 'ACTIVE',
                            color: color,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openUser(Map<String, dynamic> user) async {
    final email = '${user['email'] ?? ''}';
    final role = '${user['role'] ?? ''}';
    final name = '${user['full_name'] ?? email}';
    final busy =
        '${user['presence_status'] ?? 'active'}'.toLowerCase() == 'busy';

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('$role • ${user['parish'] ?? ''}'),
            Text(busy ? 'Busy' : 'Active now'),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                showComposeMessage(
                  this.context,
                  widget.state,
                  recipientEmail: email,
                  recipientRole: role,
                  parish: '${user['parish'] ?? ''}',
                );
              },
              icon: const Icon(Icons.message_outlined),
              label: const Text('Message user'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: email));
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Contact email copied.')),
                  );
                }
              },
              icon: const Icon(Icons.copy_outlined),
              label: const Text('Copy contact email'),
            ),
          ],
        ),
      ),
    );
  }
}
