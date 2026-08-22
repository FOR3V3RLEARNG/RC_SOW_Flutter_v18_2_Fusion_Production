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
    future = _load();
    if (widget.composeTo != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _compose(prefill: widget.composeTo),
      );
    }
  }

  Future<List<MessageRecord>> _load() =>
      widget.state.repository.messages(widget.state.profile!);

  Future<void> _refresh() async {
    final next = _load();
    setState(() => future = next);
    await next;
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
        builder: (context, snapshot) {
          final messages = (snapshot.data ?? const <MessageRecord>[])
              .where(
                (message) =>
                    '${message.sender} ${message.subject} ${message.body}'
                        .toLowerCase()
                        .contains(search.toLowerCase()),
              )
              .toList();
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                SearchBar(
                  hintText: 'Search messages',
                  leading: const Icon(Icons.search),
                  onChanged: (value) => setState(() => search = value),
                ),
                const SizedBox(height: 12),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator(),
                if (snapshot.hasError)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Could not load messages: ${snapshot.error}'),
                    ),
                  ),
                if (snapshot.connectionState != ConnectionState.waiting &&
                    !snapshot.hasError &&
                    messages.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No messages found.')),
                  ),
                ...messages.map(
                  (message) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: message.unread
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.surfaceContainer,
                        child: Icon(
                          message.unread
                              ? Icons.mark_email_unread_outlined
                              : Icons.mail_outline,
                          color: message.unread ? RcColors.brand : null,
                        ),
                      ),
                      title: Text(
                        message.sender,
                        style: TextStyle(
                          fontWeight: message.unread
                              ? FontWeight.w900
                              : FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        '${message.subject}\n${message.body}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      isThreeLine: true,
                      trailing: message.unread
                          ? const Badge(label: Text('NEW'))
                          : const Icon(Icons.chevron_right),
                      onTap: () => _open(message),
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
    try {
      await widget.state.repository.markMessageRead(
        message,
        widget.state.profile!,
      );
    } catch (_) {
      // Opening a message should still work while a read receipt is retryable.
    }
    if (!mounted) {
      return;
    }
    await _showMessageDetail(
      context,
      message: message,
      onReply: () => _compose(
        prefill: message.senderEmail,
        replyTo: message,
      ),
    );
    if (mounted) {
      await _refresh();
    }
  }

  Future<void> _compose({String? prefill, MessageRecord? replyTo}) async {
    final sent = await _showComposer(
      context,
      state: widget.state,
      prefill: prefill,
      replyTo: replyTo,
    );
    if (sent && mounted) {
      await _refresh();
    }
  }
}

class MessageDrawerPanel extends StatefulWidget {
  const MessageDrawerPanel({super.key, required this.state});

  final AppState state;

  @override
  State<MessageDrawerPanel> createState() => _MessageDrawerPanelState();
}

class _MessageDrawerPanelState extends State<MessageDrawerPanel> {
  late Future<List<MessageRecord>> future;
  MessageRecord? selected;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<List<MessageRecord>> _load() =>
      widget.state.repository.messages(widget.state.profile!);

  Future<void> _refresh() async {
    final next = _load();
    setState(() => future = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width.clamp(300, 440).toDouble();
    return SizedBox(
      width: width,
      child: Drawer(
        child: SafeArea(
          child: selected == null ? _listView() : _detailView(selected!),
        ),
      ),
    );
  }

  Widget _listView() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.forum_outlined),
          title: const Text(
            'Messages',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          trailing: IconButton(
            tooltip: 'Close messages',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: FutureBuilder<List<MessageRecord>>(
            future: future,
            builder: (context, snapshot) {
              final messages = snapshot.data ?? const <MessageRecord>[];
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  children: [
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const LinearProgressIndicator(),
                    if (snapshot.hasError)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text('Could not load messages: ${snapshot.error}'),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: _refresh,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    if (snapshot.connectionState != ConnectionState.waiting &&
                        !snapshot.hasError &&
                        messages.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(28),
                        child: Center(child: Text('No messages yet.')),
                      ),
                    ...messages.take(30).map(
                          (message) => ListTile(
                            leading: Icon(
                              message.unread
                                  ? Icons.mark_email_unread
                                  : Icons.mail_outline,
                              color: message.unread ? RcColors.brand : null,
                            ),
                            title: Text(
                              message.subject,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: message.unread
                                    ? FontWeight.w900
                                    : FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              '${message.sender}\n${message.body}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _selectMessage(message),
                          ),
                        ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _composeFromDrawer,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Compose'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _openCenter,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Center'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailView(MessageRecord message) {
    return Column(
      children: [
        ListTile(
          leading: IconButton(
            tooltip: 'Back to messages',
            onPressed: () => setState(() => selected = null),
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(
            message.subject,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          trailing: IconButton(
            tooltip: 'Close messages',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(message.sender, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(message.senderEmail),
                const Divider(height: 24),
                SelectableText(message.body),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: () => _replyFromDrawer(message),
            icon: const Icon(Icons.reply),
            label: const Text('Reply'),
          ),
        ),
      ],
    );
  }

  Future<void> _selectMessage(MessageRecord message) async {
    setState(() => selected = message);
    try {
      await widget.state.repository.markMessageRead(
        message,
        widget.state.profile!,
      );
    } catch (_) {
      // The drawer remains interactive even if the read receipt must retry.
    }
  }

  void _openCenter() {
    final navigator = Navigator.of(context);
    navigator.pop();
    Future.microtask(
      () => navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => MessagesScreen(state: widget.state),
        ),
      ),
    );
  }

  void _composeFromDrawer() {
    final navigator = Navigator.of(context);
    navigator.pop();
    Future.microtask(
      () => navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => MessagesScreen(state: widget.state, composeTo: ''),
        ),
      ),
    );
  }

  void _replyFromDrawer(MessageRecord message) {
    final navigator = Navigator.of(context);
    navigator.pop();
    Future.microtask(
      () => navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => MessagesScreen(
            state: widget.state,
            composeTo: message.senderEmail,
          ),
        ),
      ),
    );
  }
}

Future<void> _showMessageDetail(
  BuildContext context, {
  required MessageRecord message,
  required VoidCallback onReply,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(message.subject, style: Theme.of(sheetContext).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(message.sender, style: const TextStyle(fontWeight: FontWeight.w800)),
            const Divider(height: 24),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * .5,
              ),
              child: SingleChildScrollView(child: SelectableText(message.body)),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(sheetContext);
                onReply();
              },
              icon: const Icon(Icons.reply),
              label: const Text('Reply'),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<bool> _showComposer(
  BuildContext context, {
  required AppState state,
  String? prefill,
  MessageRecord? replyTo,
}) async {
  final to = TextEditingController(text: prefill ?? '');
  final subject = TextEditingController(
    text: replyTo == null ? '' : 'Re: ${replyTo.subject}',
  );
  final body = TextEditingController();
  var busy = false;
  String? error;

  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) => Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          4,
          18,
          18 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                replyTo == null ? 'New RC SOW message' : 'Reply',
                style: Theme.of(context).textTheme.titleLarge,
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
                minLines: 5,
                maxLines: 10,
                decoration: const InputDecoration(labelText: 'Message'),
              ),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: busy
                    ? null
                    : () async {
                        final recipients = to.text
                            .split(',')
                            .map((value) => value.trim())
                            .where((value) => value.isNotEmpty)
                            .toList();
                        if (recipients.isEmpty ||
                            subject.text.trim().isEmpty ||
                            body.text.trim().isEmpty) {
                          setSheetState(
                            () => error =
                                'Recipient, subject and message are required.',
                          );
                          return;
                        }
                        setSheetState(() {
                          busy = true;
                          error = null;
                        });
                        try {
                          await state.repository.sendMessage(
                            profile: state.profile!,
                            subject: subject.text.trim(),
                            body: body.text.trim(),
                            recipients: recipients,
                            replyTo: replyTo?.id,
                            threadId: replyTo?.threadId,
                          );
                          if (sheetContext.mounted) {
                            Navigator.pop(sheetContext, true);
                          }
                        } catch (e) {
                          setSheetState(() {
                            busy = false;
                            error = 'Message could not be sent: $e';
                          });
                        }
                      },
                icon: const Icon(Icons.send),
                label: Text(busy ? 'Sending…' : 'Send'),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  to.dispose();
  subject.dispose();
  body.dispose();
  return sent == true;
}
