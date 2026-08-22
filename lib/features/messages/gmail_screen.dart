import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_config.dart';
import '../../services/gmail_service.dart';
import '../../state/app_state.dart';

class GmailScreen extends StatefulWidget {
  const GmailScreen({super.key, required this.state});

  final AppState state;

  @override
  State<GmailScreen> createState() => _GmailScreenState();
}

class _GmailScreenState extends State<GmailScreen> {
  late final GmailService gmail;
  Future<List<GmailMessageSummary>>? future;

  @override
  void initState() {
    super.initState();
    gmail = GmailService(Supabase.instance.client);
    if (gmail.connected) {
      future = gmail.inbox();
    }
  }

  void _refresh() {
    if (!gmail.connected) {
      setState(() => future = null);
      return;
    }
    setState(() => future = gmail.inbox());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gmail'),
        actions: [
          IconButton(
            tooltip: 'Refresh Gmail',
            onPressed: gmail.connected ? _refresh : null,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: gmail.connected
          ? FloatingActionButton.extended(
              onPressed: _compose,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Compose'),
            )
          : null,
      body: !gmail.connected
          ? _ReconnectPanel(onReconnect: _reconnect)
          : FutureBuilder<List<GmailMessageSummary>>(
              future: future,
              builder: (context, snapshot) {
                final messages = snapshot.data ?? const <GmailMessageSummary>[];
                return RefreshIndicator(
                  onRefresh: () async {
                    _refresh();
                    if (future != null) {
                      await future;
                    }
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    children: [
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.lock_outline),
                          title: const Text('Google mailbox inside RC SOW'),
                          subtitle: const Text(
                            'Read and send mail with the Google access granted to your signed-in account.',
                          ),
                          trailing: TextButton(
                            onPressed: _reconnect,
                            child: const Text('Reconnect'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const LinearProgressIndicator(),
                      if (snapshot.hasError)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text('Could not load Gmail: ${snapshot.error}'),
                                const SizedBox(height: 8),
                                OutlinedButton(
                                  onPressed: _reconnect,
                                  child: const Text('Reconnect Google'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (snapshot.connectionState != ConnectionState.waiting &&
                          !snapshot.hasError &&
                          messages.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: Text('No inbox messages returned.')),
                        ),
                      ...messages.map(
                        (message) => Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.mail_outline),
                            ),
                            title: Text(
                              message.subject,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${message.from}\n${message.snippet}',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            isThreeLine: true,
                            trailing: const Icon(Icons.chevron_right),
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

  Future<void> _reconnect() async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: SupabaseConfig.oauthRedirectUri,
        authScreenLaunchMode: LaunchMode.externalApplication,
        scopes:
            'openid email profile https://www.googleapis.com/auth/gmail.readonly https://www.googleapis.com/auth/gmail.send',
        queryParams: const {
          'prompt': 'select_account consent',
          'access_type': 'offline',
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google reconnection failed: $e')),
        );
      }
    }
  }

  Future<void> _open(GmailMessageSummary summary) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => FutureBuilder<GmailMessageDetail>(
        future: gmail.message(summary.id),
        builder: (context, snapshot) {
          final detail = snapshot.data;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    detail?.subject ?? summary.subject,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(detail?.from ?? summary.from),
                  const Divider(height: 24),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const LinearProgressIndicator(),
                  if (snapshot.hasError)
                    Text('Could not open message: ${snapshot.error}'),
                  if (detail != null)
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * .55,
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(detail.body),
                      ),
                    ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: detail == null
                        ? null
                        : () {
                            Navigator.pop(sheetContext);
                            _compose(
                              to: _extractEmail(detail.from),
                              subject: 'Re: ${detail.subject}',
                            );
                          },
                    icon: const Icon(Icons.reply),
                    label: const Text('Reply'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _compose({String to = '', String subject = ''}) async {
    final toController = TextEditingController(text: to);
    final subjectController = TextEditingController(text: subject);
    final bodyController = TextEditingController();
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
                Text('Compose Gmail', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                TextField(
                  controller: toController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'To'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(labelText: 'Subject'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: bodyController,
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
                          if (toController.text.trim().isEmpty ||
                              subjectController.text.trim().isEmpty ||
                              bodyController.text.trim().isEmpty) {
                            setSheetState(
                              () => error = 'To, subject and message are required.',
                            );
                            return;
                          }
                          setSheetState(() {
                            busy = true;
                            error = null;
                          });
                          try {
                            await gmail.send(
                              to: toController.text.trim(),
                              subject: subjectController.text.trim(),
                              body: bodyController.text.trim(),
                            );
                            if (sheetContext.mounted) {
                              Navigator.pop(sheetContext, true);
                            }
                          } catch (e) {
                            setSheetState(() {
                              busy = false;
                              error = '$e';
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
    toController.dispose();
    subjectController.dispose();
    bodyController.dispose();
    if (sent == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gmail sent.')),
      );
    }
  }

  String _extractEmail(String from) {
    final match = RegExp(r'<([^>]+)>').firstMatch(from);
    return match?.group(1) ?? from;
  }
}

class _ReconnectPanel extends StatelessWidget {
  const _ReconnectPanel({required this.onReconnect});

  final VoidCallback onReconnect;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mark_email_unread_outlined, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Connect Gmail',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Reconnect your Google account to grant Gmail read/send access inside RC SOW.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: onReconnect,
                    icon: const Icon(Icons.login),
                    label: const Text('Reconnect Google'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
