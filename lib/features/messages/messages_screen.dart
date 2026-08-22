import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';
import '../../models/app_models.dart';
import '../../state/app_state.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key, required this.state, this.composeTo});

  final AppState state;
  final String? composeTo;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  late Future<List<MessageRecord>> future;
  String search = '';

  @override
  void initState() {
    super.initState();
    future = widget.state.repository.messages(widget.state.profile!);
    if (widget.composeTo != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _compose(prefill: widget.composeTo),
      );
    }
  }

  void refresh() {
    setState(() {
      future = widget.state.repository.messages(widget.state.profile!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _compose(),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Compose'),
      ),
      body: FutureBuilder<List<MessageRecord>>(
        future: future,
        builder: (context, snap) {
          final messages = (snap.data ?? const <MessageRecord>[])
              .where(
                (m) => '${m.sender} ${m.subject} ${m.body}'
                    .toLowerCase()
                    .contains(search.toLowerCase()),
              )
              .toList();
          return RefreshIndicator(
            onRefresh: () async {
              refresh();
              await future;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                SearchBar(
                  hintText: 'Search messages',
                  leading: const Icon(Icons.search),
                  onChanged: (v) => setState(() => search = v),
                ),
                const SizedBox(height: 12),
                if (snap.connectionState == ConnectionState.waiting)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                if (snap.hasError)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Could not load messages: ${snap.error}'),
                    ),
                  ),
                ...messages.map(
                  (m) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: m.unread
                            ? RcColors.brandSoft
                            : RcColors.surface2,
                        child: Icon(
                          m.unread
                              ? Icons.mark_email_unread_outlined
                              : Icons.mail_outline,
                          color: m.unread ? RcColors.brand : RcColors.muted,
                        ),
                      ),
                      title: Text(
                        m.sender,
                        style: TextStyle(
                          fontWeight: m.unread
                              ? FontWeight.w900
                              : FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        '${m.subject}\n${m.body}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      isThreeLine: true,
                      trailing: m.unread
                          ? const Badge(label: Text('NEW'))
                          : const Icon(Icons.chevron_right),
                      onTap: () => _open(m),
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

  Future<void> _open(MessageRecord message) async {
    await widget.state.repository.markMessageRead(
      message,
      widget.state.profile!,
    );
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(message.subject, style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                message.sender,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const Divider(height: 24),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(ctx).height * .45,
                ),
                child: SingleChildScrollView(
                  child: SelectableText(message.body),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _compose(prefill: message.senderEmail, replyTo: message);
                },
                icon: const Icon(Icons.reply),
                label: const Text('Reply'),
              ),
            ],
          ),
        ),
      ),
    );
    refresh();
  }

  Future<void> _compose({String? prefill, MessageRecord? replyTo}) async {
    final to = TextEditingController(text: prefill ?? '');
    final subject = TextEditingController(
      text: replyTo == null ? '' : 'Re: ${replyTo.subject}',
    );
    final body = TextEditingController();
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          4,
          18,
          18 + MediaQuery.viewInsetsOf(ctx).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                replyTo == null ? 'New RC SOW message' : 'Reply',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: to,
                decoration: const InputDecoration(
                  labelText: 'Recipient email(s)',
                  hintText: 'name@example.org, team@example.org',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: subject,
                decoration: const InputDecoration(labelText: 'Subject'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: body,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Message'),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () async {
                  final recipients = to.text
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();
                  if (recipients.isEmpty ||
                      subject.text.trim().isEmpty ||
                      body.text.trim().isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Recipient, subject and message are required.',
                        ),
                      ),
                    );
                    return;
                  }
                  await widget.state.repository.sendMessage(
                    profile: widget.state.profile!,
                    subject: subject.text.trim(),
                    body: body.text.trim(),
                    recipients: recipients,
                    replyTo: replyTo?.id,
                    threadId: replyTo?.threadId,
                  );
                  if (ctx.mounted) Navigator.pop(ctx, true);
                },
                icon: const Icon(Icons.send),
                label: const Text('Send'),
              ),
            ],
          ),
        ),
      ),
    );
    to.dispose();
    subject.dispose();
    body.dispose();
    if (sent == true) refresh();
  }
}

class MessageDrawerPanel extends StatelessWidget {
  const MessageDrawerPanel({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width.clamp(280, 420).toDouble();
    return SizedBox(
      width: width,
      child: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.forum_outlined),
                title: const Text(
                  'Messages',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                trailing: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: FutureBuilder<List<MessageRecord>>(
                  future: state.repository.messages(state.profile!),
                  builder: (context, snap) {
                    final messages = snap.data ?? const <MessageRecord>[];
                    return ListView(
                      children: [
                        if (snap.connectionState == ConnectionState.waiting)
                          const LinearProgressIndicator(),
                        ...messages
                            .take(20)
                            .map(
                              (m) => ListTile(
                                leading: Icon(
                                  m.unread
                                      ? Icons.mark_email_unread
                                      : Icons.mail_outline,
                                  color: m.unread ? RcColors.brand : null,
                                ),
                                title: Text(
                                  m.subject,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '${m.sender}\n${m.body}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          MessagesScreen(state: state),
                                    ),
                                  );
                                },
                              ),
                            ),
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MessagesScreen(state: state),
                      ),
                    );
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open message center'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
