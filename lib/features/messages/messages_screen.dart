import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';
import '../../models/app_models.dart';
import '../../state/app_state.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key, required this.state});
  final AppState state;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  late Future<List<MessageRecord>> future;
  String search = '';

  @override
  void initState() { super.initState(); future = widget.state.repository.messages(widget.state.profile!); }

  void refresh() => setState(() => future = widget.state.repository.messages(widget.state.profile!));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      floatingActionButton: FloatingActionButton(onPressed: _compose, child: const Icon(Icons.edit_outlined)),
      body: FutureBuilder<List<MessageRecord>>(
        future: future,
        builder: (context, snap) {
          final messages = (snap.data ?? const <MessageRecord>[]).where((m) => '${m.sender} ${m.subject} ${m.body}'.toLowerCase().contains(search.toLowerCase())).toList();
          return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 90), children: [
            SearchBar(hintText: 'Search messages', leading: const Icon(Icons.search), onChanged: (v) => setState(() => search = v)),
            const SizedBox(height: 12),
            if (snap.connectionState == ConnectionState.waiting) const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator())),
            if (snap.hasError) Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Could not load messages: ${snap.error}'))),
            if (snap.connectionState != ConnectionState.waiting && messages.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('No messages match this view.'))),
            Card(child: Column(children: messages.map((m) => ListTile(
              leading: CircleAvatar(backgroundColor: m.unread ? RcColors.brandSoft : RcColors.surface2, child: Icon(m.unread ? Icons.mark_email_unread_outlined : Icons.mail_outline, color: m.unread ? RcColors.brand : RcColors.muted)),
              title: Text(m.sender, style: TextStyle(fontWeight: m.unread ? FontWeight.w900 : FontWeight.w700)),
              subtitle: Text('${m.subject}\n${m.body}', maxLines: 2, overflow: TextOverflow.ellipsis),
              isThreeLine: true,
              trailing: m.unread ? const Badge(label: Text('NEW')) : const Icon(Icons.chevron_right),
              onTap: () => _open(m),
            )).toList())),
          ]);
        },
      ),
    );
  }

  Future<void> _open(MessageRecord message) async {
    await widget.state.repository.markMessageRead(message, widget.state.profile!);
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
      appBar: AppBar(title: Text(message.subject)),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        Text(message.sender, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(message.createdAt.toLocal().toString(), style: const TextStyle(color: RcColors.muted)),
        const Divider(height: 28),
        SelectableText(message.body, style: const TextStyle(fontSize: 15, height: 1.5)),
      ]),
    )));
    refresh();
  }

  Future<void> _compose() async {
    final subject = TextEditingController();
    final body = TextEditingController();
    await showDialog<void>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('New Message'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: subject, decoration: const InputDecoration(labelText: 'Subject')),
        const SizedBox(height: 10),
        TextField(controller: body, maxLines: 6, decoration: const InputDecoration(labelText: 'Message')),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          if (subject.text.trim().isEmpty || body.text.trim().isEmpty) {
            return;
          }
          await widget.state.repository.sendMessage(profile: widget.state.profile!, subject: subject.text.trim(), body: body.text.trim());
          if (ctx.mounted) Navigator.pop(ctx);
        }, child: const Text('Send')),
      ],
    ));
    refresh();
  }
}
