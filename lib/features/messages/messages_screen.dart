import 'package:flutter/material.dart';

import '../../core/app_constants.dart';
import '../../core/design_tokens.dart';
import '../../core/rc_components.dart';
import '../../models/app_models.dart';
import '../../state/app_state.dart';

Future<void> showMessageDrawer(BuildContext context, AppState state) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Messages',
    barrierColor: Colors.black38,
    transitionDuration: state.reduceMotion ? Duration.zero : RcMotion.medium,
    pageBuilder: (context, animation, secondaryAnimation) => Align(
      alignment: Alignment.topCenter,
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.sizeOf(
              context,
            ).width.clamp(0.0, 760.0).toDouble(),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .78,
            ),
            margin: const EdgeInsets.fromLTRB(10, 6, 10, 0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(28),
                top: Radius.circular(18),
              ),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 28,
                  color: Color(0x26000000),
                  offset: Offset(0, 12),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: MessagesDrawerBody(state: state),
          ),
        ),
      ),
    ),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return SlideTransition(
        position: Tween(
          begin: const Offset(0, -.12),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}

Future<void> showComposeMessage(
  BuildContext context,
  AppState state, {
  String? recipientEmail,
  String? recipientRole,
  String? parish,
  String? houseCode,
  String? replyTo,
  String? initialSubject,
}) async {
  final subject = TextEditingController(text: initialSubject ?? '');
  final body = TextEditingController();
  String targetType = recipientEmail != null
      ? 'email'
      : recipientRole != null
      ? 'role'
      : 'parish';
  String targetValue =
      recipientEmail ?? recipientRole ?? parish ?? state.profile!.parish;
  String priority = 'Normal';
  bool busy = false;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) => Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          0,
          18,
          18 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'New RC SOW message',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: targetType,
                decoration: const InputDecoration(labelText: 'Recipient type'),
                items: [
                  const DropdownMenuItem(
                    value: 'email',
                    child: Text('Individual user'),
                  ),
                  const DropdownMenuItem(
                    value: 'parish',
                    child: Text('Parish'),
                  ),
                  if (state.profile!.hasPrivilege('messageAllUsers')) ...[
                    const DropdownMenuItem(
                      value: 'role',
                      child: Text('Role — all parishes'),
                    ),
                    const DropdownMenuItem(
                      value: 'all',
                      child: Text('All users'),
                    ),
                  ],
                ],
                onChanged: busy
                    ? null
                    : (value) => setSheetState(() {
                        targetType = value!;
                        targetValue = targetType == 'parish'
                            ? state.profile!.parish
                            : '';
                      }),
              ),
              const SizedBox(height: 10),
              if (targetType == 'parish')
                DropdownButtonFormField<String>(
                  initialValue: RcApp.parishes.contains(targetValue)
                      ? targetValue
                      : null,
                  decoration: const InputDecoration(labelText: 'Parish'),
                  items:
                      (state.profile!.canViewAllParishes
                              ? RcApp.parishes
                              : [state.profile!.parish])
                          .map(
                            (p) => DropdownMenuItem(value: p, child: Text(p)),
                          )
                          .toList(),
                  onChanged: busy
                      ? null
                      : (value) => setSheetState(() => targetValue = value!),
                )
              else if (targetType != 'all')
                TextFormField(
                  initialValue: targetValue,
                  decoration: InputDecoration(
                    labelText: targetType == 'email'
                        ? 'Recipient email'
                        : 'Role',
                  ),
                  onChanged: (value) => targetValue = value.trim(),
                ),
              const SizedBox(height: 10),
              TextField(
                controller: subject,
                decoration: const InputDecoration(labelText: 'Subject'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: body,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(labelText: 'Message'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: const ['Normal', 'Action required', 'Urgent']
                    .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                    .toList(),
                onChanged: busy
                    ? null
                    : (value) => setSheetState(() => priority = value!),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: busy
                    ? null
                    : () async {
                        if (subject.text.trim().isEmpty ||
                            body.text.trim().isEmpty ||
                            (targetType != 'all' &&
                                targetValue.trim().isEmpty)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Recipient, subject and message are required.',
                              ),
                            ),
                          );
                          return;
                        }
                        setSheetState(() => busy = true);
                        try {
                          await state.repository.sendMessage(
                            profile: state.profile!,
                            subject: subject.text,
                            body: body.text,
                            recipients: [
                              {
                                'type': targetType,
                                'value': targetType == 'all'
                                    ? 'all'
                                    : targetValue,
                              },
                            ],
                            parish: targetType == 'parish'
                                ? targetValue
                                : parish,
                            houseCode: houseCode,
                            priority: priority,
                            replyTo: replyTo,
                          );
                          if (sheetContext.mounted) Navigator.pop(sheetContext);
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Message could not be sent. Check recipient permissions and connectivity.',
                                ),
                              ),
                            );
                          }
                        } finally {
                          if (context.mounted) {
                            setSheetState(() => busy = false);
                          }
                        }
                      },
                icon: const Icon(Icons.send_outlined),
                label: Text(busy ? 'Sending…' : 'Send message'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  subject.dispose();
  body.dispose();
}

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showComposeMessage(context, state),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Message'),
      ),
      body: MessagesDrawerBody(state: state, embedded: false),
    );
  }
}

class MessagesDrawerBody extends StatefulWidget {
  const MessagesDrawerBody({
    super.key,
    required this.state,
    this.embedded = true,
  });
  final AppState state;
  final bool embedded;

  @override
  State<MessagesDrawerBody> createState() => _MessagesDrawerBodyState();
}

class _MessagesDrawerBodyState extends State<MessagesDrawerBody> {
  late Future<List<MessageRecord>> future;

  @override
  void initState() {
    super.initState();
    future = widget.state.repository.messages(
      widget.state.profile!,
      limit: widget.embedded ? 30 : 100,
    );
  }

  Future<void> refresh() async {
    setState(
      () => future = widget.state.repository.messages(
        widget.state.profile!,
        limit: widget.embedded ? 30 : 100,
      ),
    );
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        if (widget.embedded)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Messages', style: theme.textTheme.titleLarge),
                      Text(
                        'Operational communication without leaving RC SOW',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => showComposeMessage(context, widget.state),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: refresh,
            child: FutureBuilder<List<MessageRecord>>(
              future: future,
              builder: (_, snap) {
                final messages = snap.data ?? const <MessageRecord>[];
                if (snap.connectionState == ConnectionState.waiting &&
                    messages.isEmpty) {
                  return ListView(
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
                          tone: Theme.of(context).colorScheme.errorContainer,
                          child: Column(
                            children: [
                              const Text(
                                'Messages could not be loaded. Your existing data is unchanged.',
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: refresh,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }
                if (messages.isEmpty) {
                  return ListView(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(24),
                        child: RcExpressiveSurface(
                          child: Text(
                            'No messages are visible for this account.',
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                  itemCount: messages.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 7),
                  itemBuilder: (_, index) {
                    final message = messages[index];
                    return RcExpressiveSurface(
                      shape: RcSurfaceShape.offset,
                      tone: message.unread
                          ? theme.colorScheme.primaryContainer.withValues(
                              alpha: .32,
                            )
                          : null,
                      onTap: () => _openMessage(message),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                theme.colorScheme.secondaryContainer,
                            child: Text(
                              message.sender.isEmpty
                                  ? '?'
                                  : message.sender[0].toUpperCase(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        message.subject,
                                        style: theme.textTheme.titleMedium,
                                      ),
                                    ),
                                    if (message.unread)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${message.sender}${message.senderRole.isEmpty ? '' : ' • ${message.senderRole}'}',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  message.body,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (message.houseCode != null &&
                                    message.houseCode!.isNotEmpty) ...[
                                  const SizedBox(height: 5),
                                  RcStatusPill(
                                    label: message.houseCode!,
                                    icon: Icons.home_outlined,
                                    color: RcColors.blue,
                                  ),
                                ],
                              ],
                            ),
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

  Future<void> _openMessage(MessageRecord message) async {
    if (message.unread) {
      try {
        await widget.state.repository.markMessageRead(
          message,
          widget.state.profile!,
        );
      } catch (_) {}
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                message.subject,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${message.sender} • ${message.senderRole} • ${message.priority}',
              ),
              const Divider(height: 28),
              Text(message.body),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => showComposeMessage(
                      context,
                      widget.state,
                      recipientEmail: message.senderEmail,
                      houseCode: message.houseCode,
                      replyTo: message.id,
                      initialSubject: 'Re: ${message.subject}',
                    ),
                    icon: const Icon(Icons.reply),
                    label: const Text('Reply'),
                  ),
                  if (message.houseCode != null)
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.state.selectTab(3);
                      },
                      icon: const Icon(Icons.home_work_outlined),
                      label: Text('Open ${message.houseCode}'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await refresh();
  }
}
