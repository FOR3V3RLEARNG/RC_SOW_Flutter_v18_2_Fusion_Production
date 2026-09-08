import 'package:flutter/material.dart';

import '../../core/app_constants.dart';
import '../../core/design_tokens.dart';
import '../../core/rc_components.dart';
import '../../models/app_models.dart';
import '../../state/app_state.dart';
import '../control/house_operations_control_screen.dart';

Future<void> showNotificationCentre(BuildContext context, AppState state) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Notification Centre',
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

Future<void> showMessageDrawer(BuildContext context, AppState state) =>
    showNotificationCentre(context, state);

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
  String filter = 'All';

  static const filters = <String>[
    'All',
    'Message',
    'Push',
    'Production',
    'Action',
    'Signature',
    'Safety',
    'Payment',
  ];

  @override
  void initState() {
    super.initState();
    future = widget.state.repository.messages(
      widget.state.profile!,
      limit: widget.embedded ? 60 : 120,
    );
  }

  Future<void> refresh() async {
    setState(
      () => future = widget.state.repository.messages(
        widget.state.profile!,
        limit: widget.embedded ? 60 : 120,
      ),
    );
    await future;
  }

  _NotificationVisual _visual(MessageRecord message) {
    final category = message.category.trim().toLowerCase();
    final subject = message.subject.toLowerCase();
    final priority = message.priority.toLowerCase();

    if (category.contains('signature') ||
        subject.contains('signature required')) {
      return const _NotificationVisual(
        filter: 'Signature',
        label: 'SIGNATURE REQUIRED',
        icon: Icons.draw_rounded,
        color: RcColors.purple,
      );
    }
    if (category.contains('safety')) {
      return const _NotificationVisual(
        filter: 'Safety',
        label: 'SAFETY ALERT',
        icon: Icons.health_and_safety_rounded,
        color: RcColors.danger,
      );
    }
    if (category.contains('payment')) {
      return const _NotificationVisual(
        filter: 'Payment',
        label: 'PAYMENT ALERT',
        icon: Icons.payments_rounded,
        color: RcColors.success,
      );
    }
    if (category.contains('production') ||
        category.contains('house') ||
        category.contains('completion') ||
        subject.contains('production alert')) {
      return const _NotificationVisual(
        filter: 'Production',
        label: 'PRODUCTION ALERT',
        icon: Icons.construction_rounded,
        color: RcColors.warning,
      );
    }
    if (category.contains('push') || category.contains('notice')) {
      return const _NotificationVisual(
        filter: 'Push',
        label: 'PUSH NOTICE',
        icon: Icons.notifications_active_rounded,
        color: RcColors.teal,
      );
    }
    if (category.contains('call to action') ||
        category.contains('action') ||
        priority.contains('action') ||
        priority.contains('urgent')) {
      return const _NotificationVisual(
        filter: 'Action',
        label: 'CALL TO ACTION',
        icon: Icons.priority_high_rounded,
        color: RcColors.brand,
      );
    }
    return const _NotificationVisual(
      filter: 'Message',
      label: 'MESSAGE',
      icon: Icons.forum_rounded,
      color: RcColors.blue,
    );
  }

  bool _matches(MessageRecord message) =>
      filter == 'All' || _visual(message).filter == filter;

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
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(
                    Icons.notifications_active_rounded,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notification Centre',
                        style: theme.textTheme.titleLarge,
                      ),
                      Text(
                        'Messages, push notices, production alerts, required actions and signatures.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Compose message',
                  onPressed: () => showComposeMessage(context, widget.state),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 9),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filters.map((value) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    selected: filter == value,
                    label: Text(value),
                    onSelected: (_) => setState(() => filter = value),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: refresh,
            child: FutureBuilder<List<MessageRecord>>(
              future: future,
              builder: (_, snap) {
                final allMessages = snap.data ?? const <MessageRecord>[];
                final messages = allMessages.where(_matches).toList();

                if (snap.connectionState == ConnectionState.waiting &&
                    allMessages.isEmpty) {
                  return ListView(
                    children: const [
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
                          child: Column(
                            children: [
                              const Text(
                                'Notifications could not be loaded. Your existing data is unchanged.',
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
                        padding: const EdgeInsets.all(24),
                        child: RcExpressiveSurface(
                          child: Text(
                            filter == 'All'
                                ? 'No notifications are visible for this account.'
                                : 'No $filter notifications are visible.',
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                  itemCount: messages.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 9),
                  itemBuilder: (_, index) {
                    final message = messages[index];
                    final visual = _visual(message);
                    return RcExpressiveSurface(
                      shape: RcSurfaceShape.offset,
                      tone: message.unread
                          ? visual.color.withValues(alpha: .09)
                          : null,
                      onTap: () => _openMessage(message),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: visual.color.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(17),
                            ),
                            child: Icon(visual.icon, color: visual.color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    RcStatusPill(
                                      label: visual.label,
                                      color: visual.color,
                                    ),
                                    if (message.priority.toLowerCase() !=
                                        'normal')
                                      RcStatusPill(
                                        label: message.priority.toUpperCase(),
                                        color: message.priority
                                                .toLowerCase()
                                                .contains('urgent')
                                            ? RcColors.danger
                                            : RcColors.warning,
                                      ),
                                    if (message.unread)
                                      RcStatusPill(
                                        label: 'NEW',
                                        color: theme.colorScheme.primary,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  message.subject,
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${message.sender}${message.senderRole.isEmpty ? '' : ' • ${message.senderRole}'}',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  message.body,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 7,
                                  runSpacing: 7,
                                  children: [
                                    if (message.houseCode != null &&
                                        message.houseCode!.isNotEmpty)
                                      RcStatusPill(
                                        label: message.houseCode!,
                                        icon: Icons.home_outlined,
                                        color: RcColors.blue,
                                      ),
                                    TextButton.icon(
                                      onPressed: () => _openMessage(message),
                                      icon: Icon(
                                        visual.filter == 'Signature'
                                            ? Icons.draw_outlined
                                            : Icons.open_in_new_rounded,
                                        size: 17,
                                      ),
                                      label: Text(
                                        visual.filter == 'Signature'
                                            ? 'Complete action'
                                            : message.houseCode != null
                                                ? 'View & act'
                                                : 'Open',
                                      ),
                                    ),
                                  ],
                                ),
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

    final visual = _visual(message);
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
              Align(
                alignment: Alignment.centerLeft,
                child: RcStatusPill(
                  label: visual.label,
                  icon: visual.icon,
                  color: visual.color,
                ),
              ),
              const SizedBox(height: 10),
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
              Text(
                message.body,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
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
                    FilledButton.icon(
                      onPressed: () {
                        final code = message.houseCode!;
                        Navigator.pop(context);
                        Navigator.of(this.context).push(
                          MaterialPageRoute(
                            builder: (_) => HouseControlWorkspaceByCodeScreen(
                              state: widget.state,
                              houseCode: code,
                            ),
                          ),
                        );
                      },
                      icon: Icon(
                        visual.filter == 'Signature'
                            ? Icons.draw_outlined
                            : Icons.home_work_outlined,
                      ),
                      label: Text(
                        visual.filter == 'Signature'
                            ? 'Open ${message.houseCode} for signature'
                            : 'Open ${message.houseCode}',
                      ),
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

class _NotificationVisual {
  const _NotificationVisual({
    required this.filter,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String filter;
  final String label;
  final IconData icon;
  final Color color;
}
