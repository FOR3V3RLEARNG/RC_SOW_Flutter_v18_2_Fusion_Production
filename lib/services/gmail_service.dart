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

  final String id;
  final String threadId;
  final String subject;
  final String from;
  final String snippet;
  final String date;
}

class GmailMessageDetail extends GmailMessageSummary {
  const GmailMessageDetail({
    required super.id,
    required super.threadId,
    required super.subject,
    required super.from,
    required super.snippet,
    required super.date,
    required this.body,
  });

  final String body;
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
    _requireConnection();
    final response = await http.get(
      Uri.https('gmail.googleapis.com', '/gmail/v1/users/me/messages', {
        'labelIds': 'INBOX',
        'maxResults': '$maxResults',
      }),
      headers: _headers,
    );
    _ensureOk(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final refs = (json['messages'] as List? ?? const []).take(maxResults);
    final messages = <GmailMessageSummary>[];
    for (final rawRef in refs) {
      final ref = Map<String, dynamic>.from(rawRef as Map);
      final id = '${ref['id'] ?? ''}';
      if (id.isEmpty) {
        continue;
      }
      messages.add(await _metadata(id));
    }
    return messages;
  }

  Future<GmailMessageDetail> message(String id) async {
    _requireConnection();
    final response = await http.get(
      Uri.https('gmail.googleapis.com', '/gmail/v1/users/me/messages/$id', {
        'format': 'full',
      }),
      headers: _headers,
    );
    _ensureOk(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final payload = Map<String, dynamic>.from(
      json['payload'] as Map? ?? const {},
    );
    final metadata = _metadataFromPayload(id, json, payload);
    final body = _extractBody(payload).trim();
    return GmailMessageDetail(
      id: metadata.id,
      threadId: metadata.threadId,
      subject: metadata.subject,
      from: metadata.from,
      snippet: metadata.snippet,
      date: metadata.date,
      body: body.isEmpty ? metadata.snippet : body,
    );
  }

  Future<void> send({
    required String to,
    required String subject,
    required String body,
  }) async {
    _requireConnection();
    final raw =
        'To: $to\r\nSubject: $subject\r\nContent-Type: text/plain; charset=utf-8\r\n\r\n$body';
    final encoded = base64Url.encode(utf8.encode(raw)).replaceAll('=', '');
    final response = await http.post(
      Uri.https('gmail.googleapis.com', '/gmail/v1/users/me/messages/send'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode({'raw': encoded}),
    );
    _ensureOk(response);
  }

  Future<GmailMessageSummary> _metadata(String id) async {
    final response = await http.get(
      Uri.https('gmail.googleapis.com', '/gmail/v1/users/me/messages/$id', {
        'format': 'metadata',
        'metadataHeaders': ['Subject', 'From', 'Date'],
      }),
      headers: _headers,
    );
    _ensureOk(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final payload = Map<String, dynamic>.from(
      json['payload'] as Map? ?? const {},
    );
    return _metadataFromPayload(id, json, payload);
  }

  GmailMessageSummary _metadataFromPayload(
    String id,
    Map<String, dynamic> json,
    Map<String, dynamic> payload,
  ) {
    final headers = (payload['headers'] as List? ?? const [])
        .map((raw) => Map<String, dynamic>.from(raw as Map))
        .toList();
    String header(String name) {
      for (final value in headers) {
        if ('${value['name']}'.toLowerCase() == name.toLowerCase()) {
          return '${value['value'] ?? ''}';
        }
      }
      return '';
    }

    final subject = header('Subject');
    return GmailMessageSummary(
      id: id,
      threadId: '${json['threadId'] ?? ''}',
      subject: subject.isEmpty ? '(No subject)' : subject,
      from: header('From'),
      snippet: '${json['snippet'] ?? ''}',
      date: header('Date'),
    );
  }

  String _extractBody(Map<String, dynamic> part) {
    final mimeType = '${part['mimeType'] ?? ''}'.toLowerCase();
    final body = Map<String, dynamic>.from(part['body'] as Map? ?? const {});
    final data = '${body['data'] ?? ''}';
    if (data.isNotEmpty && (mimeType == 'text/plain' || mimeType.isEmpty)) {
      return _decodeBody(data);
    }

    final childParts = (part['parts'] as List? ?? const [])
        .map((raw) => Map<String, dynamic>.from(raw as Map))
        .toList();
    for (final child in childParts) {
      if ('${child['mimeType'] ?? ''}'.toLowerCase() == 'text/plain') {
        final text = _extractBody(child);
        if (text.isNotEmpty) {
          return text;
        }
      }
    }
    for (final child in childParts) {
      final text = _extractBody(child);
      if (text.isNotEmpty) {
        return text;
      }
    }
    if (data.isNotEmpty) {
      final decoded = _decodeBody(data);
      if (mimeType == 'text/html') {
        return decoded
            .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
            .replaceAll(RegExp(r'<[^>]+>'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
      }
      return decoded;
    }
    return '';
  }

  String _decodeBody(String value) {
    try {
      return utf8.decode(base64Url.decode(base64Url.normalize(value)));
    } catch (_) {
      return '';
    }
  }

  void _requireConnection() {
    if (!connected) {
      throw StateError('Reconnect Google to grant Gmail access.');
    }
  }

  void _ensureOk(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw StateError(
      'Gmail request failed (${response.statusCode}). Reconnect Google if access expired.',
    );
  }
}
