import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class GmailMessageSummary {
  const GmailMessageSummary({
    required this.id,
    required this.threadId,
    required this.subject,
    required this.from,
    required this.snippet,
    required this.date,
  });
  final String id, threadId, subject, from, snippet, date;
}

class GmailService {
  GmailService(this.client);
  final SupabaseClient client;
  String? get providerToken => client.auth.currentSession?.providerToken;
  bool get connected => providerToken?.isNotEmpty == true;
  Map<String, String> get _headers => {
    'Authorization': 'Bearer $providerToken',
    'Accept': 'application/json',
  };
  Future<List<GmailMessageSummary>> inbox({int maxResults = 25}) async {
    if (!connected) throw StateError('Reconnect Google to grant Gmail access.');
    final list = await http.get(
      Uri.https('gmail.googleapis.com', '/gmail/v1/users/me/messages', {
        'labelIds': 'INBOX',
        'maxResults': '$maxResults',
      }),
      headers: _headers,
    );
    _ok(list);
    final refs = (jsonDecode(list.body)['messages'] as List? ?? const []).take(
      maxResults,
    );
    final out = <GmailMessageSummary>[];
    for (final ref in refs) {
      final id = '${(ref as Map)['id']}';
      final r = await http.get(
        Uri.https('gmail.googleapis.com', '/gmail/v1/users/me/messages/$id', {
          'format': 'metadata',
          'metadataHeaders': ['Subject', 'From', 'Date'],
        }),
        headers: _headers,
      );
      _ok(r);
      final j = jsonDecode(r.body) as Map<String, dynamic>;
      final payload = Map<String, dynamic>.from(
        j['payload'] as Map? ?? const {},
      );
      final hs = (payload['headers'] as List? ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      String h(String n) {
        for (final x in hs) {
          if ('${x['name']}'.toLowerCase() == n.toLowerCase())
            return '${x['value'] ?? ''}';
        }
        return '';
      }

      out.add(
        GmailMessageSummary(
          id: id,
          threadId: '${j['threadId'] ?? ''}',
          subject: h('Subject').isEmpty ? '(No subject)' : h('Subject'),
          from: h('From'),
          snippet: '${j['snippet'] ?? ''}',
          date: h('Date'),
        ),
      );
    }
    return out;
  }

  Future<void> send({
    required String to,
    required String subject,
    required String body,
  }) async {
    if (!connected) throw StateError('Reconnect Google to grant Gmail access.');
    final raw =
        'To: $to\r\nSubject: $subject\r\nContent-Type: text/plain; charset=utf-8\r\n\r\n$body';
    final encoded = base64Url.encode(utf8.encode(raw)).replaceAll('=', '');
    final r = await http.post(
      Uri.https('gmail.googleapis.com', '/gmail/v1/users/me/messages/send'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode({'raw': encoded}),
    );
    _ok(r);
  }

  void _ok(http.Response r) {
    if (r.statusCode < 200 || r.statusCode >= 300)
      throw StateError(
        'Gmail request failed (${r.statusCode}). Reconnect Google if access expired.',
      );
  }
}
