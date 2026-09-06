import 'package:flutter/material.dart';

import '../../core/rc_components.dart';
import '../../state/app_state.dart';

class GmailScreen extends StatefulWidget {
  const GmailScreen({super.key, required this.state});
  final AppState state;

  @override
  State<GmailScreen> createState() => _GmailScreenState();
}

class _GmailScreenState extends State<GmailScreen> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = widget.state.repository.gmailInbox();
  }

  Future<void> refresh() async {
    setState(() => future = widget.state.repository.gmailInbox());
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gmail')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _compose,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Email'),
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: future,
          builder: (_, snap) {
            final items = snap.data ?? const <Map<String, dynamic>>[];
            if (snap.hasError) {
              return ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  RcExpressiveSurface(
                    tone: Theme.of(context).colorScheme.errorContainer,
                    child: const Text(
                      'Gmail could not be loaded. Reconnect Google in Settings and grant Gmail read/send permission.',
                    ),
                  ),
                ],
              );
            }
            if (items.isEmpty &&
                snap.connectionState != ConnectionState.waiting) {
              return ListView(
                children: [
                  Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No Gmail inbox messages were returned.'),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 90),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 7),
              itemBuilder: (_, index) {
                final item = items[index];
                return RcExpressiveSurface(
                  shape: RcSurfaceShape.offset,
                  onTap: () => _open(item),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item['subject'] ?? '(No subject)'}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${item['from'] ?? ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${item['snippet'] ?? ''}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _open(Map<String, dynamic> item) async {
    final id = '${item['id'] ?? ''}';
    if (id.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => FutureBuilder<Map<String, dynamic>>(
        future: widget.state.repository.gmailMessage(id),
        builder: (_, snap) {
          final data = snap.data;
          return FractionallySizedBox(
            heightFactor: .82,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
              child: snap.connectionState == ConnectionState.waiting
                  ? const Center(child: CircularProgressIndicator())
                  : snap.hasError
                  ? const Center(
                      child: Text('Could not load this Gmail message.'),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item['subject'] ?? '(No subject)'}',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 6),
                          Text('${item['from'] ?? ''}'),
                          const Divider(height: 26),
                          Text(
                            '${data?['bodyText'] ?? data?['snippet'] ?? item['snippet'] ?? ''}',
                          ),
                          const SizedBox(height: 18),
                          FilledButton.tonalIcon(
                            onPressed: () {
                              Navigator.pop(context);
                              _compose(
                                to: _emailFromHeader('${item['from'] ?? ''}'),
                                subject: 'Re: ${item['subject'] ?? ''}',
                              );
                            },
                            icon: const Icon(Icons.reply),
                            label: const Text('Reply by Gmail'),
                          ),
                        ],
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  String _emailFromHeader(String value) {
    final match = RegExp(r'<([^>]+)>').firstMatch(value);
    return match?.group(1) ?? value;
  }

  Future<void> _compose({String to = '', String subject = ''}) async {
    final toController = TextEditingController(text: to);
    final subjectController = TextEditingController(text: subject);
    final bodyController = TextEditingController();
    final send = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
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
                'Compose Gmail',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
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
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.send_outlined),
                label: const Text('Send through Gmail'),
              ),
            ],
          ),
        ),
      ),
    );
    if (send == true) {
      if (toController.text.trim().isEmpty ||
          bodyController.text.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recipient and message are required.'),
            ),
          );
        }
      } else {
        try {
          await widget.state.repository.gmailSend(
            to: toController.text.trim(),
            subject: subjectController.text.trim(),
            body: bodyController.text,
          );
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Gmail sent.')));
          }
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Gmail could not be sent. Reconnect Google and retry.',
                ),
              ),
            );
          }
        }
      }
    }
    toController.dispose();
    subjectController.dispose();
    bodyController.dispose();
  }
}
