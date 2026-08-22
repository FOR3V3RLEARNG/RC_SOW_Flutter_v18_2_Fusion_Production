import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';
import '../../models/app_models.dart';
import '../../state/app_state.dart';
import '../messages/messages_screen.dart';

class ActiveUsersScreen extends StatefulWidget {
  const ActiveUsersScreen({super.key, required this.state});

  final AppState state;

  @override
  State<ActiveUsersScreen> createState() => _ActiveUsersScreenState();
}

class _ActiveUsersScreenState extends State<ActiveUsersScreen> {
  late Future<List<ActiveUserRecord>> future;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<List<ActiveUserRecord>> _load() => widget.state.repository.activeUsers();

  Future<void> _refresh() async {
    final next = _load();
    setState(() => future = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users online')),
      body: FutureBuilder<List<ActiveUserRecord>>(
        future: future,
        builder: (context, snapshot) {
          final users = snapshot.data ?? const <ActiveUserRecord>[];
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              children: [
                Text(
                  '${users.length} online now',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator(),
                if (snapshot.hasError)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text('Could not load online users: ${snapshot.error}'),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: _refresh,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (snapshot.connectionState != ConnectionState.waiting &&
                    !snapshot.hasError &&
                    users.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(child: Text('No other approved users are online.')),
                  ),
                ...users.map(
                  (user) => Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: RcColors.successSoft,
                        child: Icon(Icons.person, color: RcColors.success),
                      ),
                      title: Text(
                        user.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: Text('${user.role} • ${user.parish}'),
                      trailing: const Icon(Icons.chat_bubble_outline),
                      onTap: () => _userActions(user),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _userActions(ActiveUserRecord user) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(user.displayName, style: Theme.of(context).textTheme.titleLarge),
              Text('${user.role} • ${user.parish}'),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => MessagesScreen(
                        state: widget.state,
                        composeTo: user.email,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.message_outlined),
                label: const Text('Message user'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ActiveUsersPopup extends StatefulWidget {
  const ActiveUsersPopup({super.key, required this.state});

  final AppState state;

  @override
  State<ActiveUsersPopup> createState() => _ActiveUsersPopupState();
}

class _ActiveUsersPopupState extends State<ActiveUsersPopup> {
  late Future<List<ActiveUserRecord>> future;

  @override
  void initState() {
    super.initState();
    future = widget.state.repository.activeUsers();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360, maxHeight: 520),
        child: FutureBuilder<List<ActiveUserRecord>>(
          future: future,
          builder: (context, snapshot) {
            final users = snapshot.data ?? const <ActiveUserRecord>[];
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.groups_outlined),
                  title: const Text(
                    'Users online',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text('${users.length} available'),
                  trailing: IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ),
                const Divider(height: 1),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator(),
                if (snapshot.hasError)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text('Could not load users: ${snapshot.error}'),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () {
                            setState(
                              () => future = widget.state.repository.activeUsers(),
                            );
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                if (snapshot.connectionState != ConnectionState.waiting &&
                    !snapshot.hasError &&
                    users.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No users online right now.'),
                  ),
                if (users.isNotEmpty)
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: users.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: RcColors.successSoft,
                            child: Icon(
                              Icons.person,
                              color: RcColors.success,
                            ),
                          ),
                          title: Text(
                            user.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text('${user.role} • ${user.parish}'),
                          trailing: const Icon(Icons.chat_bubble_outline),
                          onTap: () => _message(user),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _message(ActiveUserRecord user) {
    final navigator = Navigator.of(context, rootNavigator: true);
    navigator.pop();
    Future.microtask(
      () => navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => MessagesScreen(
            state: widget.state,
            composeTo: user.email,
          ),
        ),
      ),
    );
  }
}
