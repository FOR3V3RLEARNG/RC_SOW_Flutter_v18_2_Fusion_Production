import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/rc_components.dart';
import '../../state/app_state.dart';
import '../messages/messages_screen.dart';

Future<void> showUsersOnlinePanel(BuildContext context, AppState state) async {
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Users online',
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
            width: MediaQuery.sizeOf(
              context,
            ).width.clamp(0.0, 390.0).toDouble(),
            height: MediaQuery.sizeOf(context).height * .72,
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 86),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
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
    transitionBuilder: (_, animation, _, child) {
      final curve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
      );
      return SlideTransition(
        position: Tween(
          begin: const Offset(.04, .15),
          end: Offset.zero,
        ).animate(curve),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
  );
}

class ActiveUsersScreen extends StatelessWidget {
  const ActiveUsersScreen({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users online')),
      body: ActiveUsersBody(state: state),
    );
  }
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

  @override
  void initState() {
    super.initState();
    future = widget.state.repository.activeUsers();
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
                    Text('Users Online', style: theme.textTheme.titleLarge),
                    Text(
                      'Tap a user to message or view context.',
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
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: future,
            builder: (_, snap) {
              final users = snap.data ?? const <Map<String, dynamic>>[];
              if (snap.connectionState == ConnectionState.waiting &&
                  users.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: RcExpressiveSurface(
                      tone: theme.colorScheme.errorContainer,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('User presence could not be loaded.'),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => setState(
                              () => future = widget.state.repository
                                  .activeUsers(),
                            ),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              if (users.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No active approved users are currently visible.',
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 22),
                itemCount: users.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (_, index) {
                  final user = users[index];
                  final active = user['active'] == true;
                  final name = '${user['full_name'] ?? ''}'.trim();
                  final email = '${user['email'] ?? ''}';
                  return RcExpressiveSurface(
                    shape: RcSurfaceShape.offset,
                    padding: const EdgeInsets.all(10),
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
                                width: 11,
                                height: 11,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: active
                                      ? Colors.green
                                      : theme.colorScheme.outline,
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
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
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
                        Icon(
                          active
                              ? Icons.chat_bubble_outline
                              : Icons.chevron_right,
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
    );
  }

  Future<void> _openUser(Map<String, dynamic> user) async {
    final email = '${user['email'] ?? ''}';
    final role = '${user['role'] ?? ''}';
    final name = '${user['full_name'] ?? email}';
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  child: Text(name.isEmpty ? '?' : name[0].toUpperCase()),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: Theme.of(context).textTheme.titleLarge),
                      Text('$role • ${user['parish'] ?? ''}'),
                    ],
                  ),
                ),
              ],
            ),
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
                if (context.mounted) {
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
