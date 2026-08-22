import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';
import '../../models/app_models.dart';
import '../../state/app_state.dart';
import '../messages/messages_screen.dart';

class ActiveUsersScreen extends StatelessWidget {
  const ActiveUsersScreen({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users Online')),
      body: FutureBuilder<List<ActiveUserRecord>>(
        future: state.repository.activeUsers(),
        builder: (context, snap) {
          final users = snap.data ?? const <ActiveUserRecord>[];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  const Icon(Icons.circle, size: 11, color: RcColors.success),
                  const SizedBox(width: 6),
                  Text(
                    '${users.length} online',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (snap.connectionState == ConnectionState.waiting)
                const LinearProgressIndicator(),
              ...users.map(
                (u) => Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person_outline),
                    ),
                    title: Text(
                      u.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text('${u.role} • ${u.parish}'),
                    trailing: IconButton(
                      tooltip: 'Message',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MessagesScreen(
                            state: state,
                            composeTo: u.email,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline),
                    ),
                    onTap: () => _popUser(context, u),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _popUser(BuildContext context, ActiveUserRecord user) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const CircleAvatar(child: Icon(Icons.person)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          style: Theme.of(ctx).textTheme.titleMedium,
                        ),
                        Text('${user.role} • ${user.parish}'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MessagesScreen(
                        state: state,
                        composeTo: user.email,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.message),
                label: const Text('Message user'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ActiveUsersPopup extends StatelessWidget {
  const ActiveUsersPopup({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 320,
        height: 420,
        child: FutureBuilder<List<ActiveUserRecord>>(
          future: state.repository.activeUsers(),
          builder: (context, snap) {
            final users = snap.data ?? const <ActiveUserRecord>[];
            return Column(
              children: [
                ListTile(
                  title: Text(
                    '${users.length} users online',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  leading: const Icon(Icons.groups_2_outlined),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    children: users
                        .map(
                          (u) => ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.circle,
                              size: 10,
                              color: RcColors.success,
                            ),
                            title: Text(
                              u.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${u.role} • ${u.parish}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MessagesScreen(
                                  state: state,
                                  composeTo: u.email,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
