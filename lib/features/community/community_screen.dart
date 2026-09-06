import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/design_tokens.dart';
import '../../core/rc_components.dart';
import '../../models/app_models.dart';
import '../../state/app_state.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key, required this.state});
  final AppState state;

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  late Future<List<ProductionRecord>> future;

  @override
  void initState() {
    super.initState();
    future = widget.state.repository.communityRecords(widget.state.profile!);
  }

  Future<void> refresh() async {
    setState(
      () => future = widget.state.repository.communityRecords(
        widget.state.profile!,
      ),
    );
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.state.profile!;
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: refresh,
      child: FutureBuilder<List<ProductionRecord>>(
        future: future,
        builder: (_, snap) {
          final records = snap.data ?? const <ProductionRecord>[];
          final posts = records
              .where((r) => r.eventType == 'communityPost')
              .toList();
          if (snap.hasError) {
            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                RcExpressiveSurface(
                  tone: theme.colorScheme.errorContainer,
                  child: Column(
                    children: [
                      const Text(
                        'Community Board could not be loaded. Existing posts are unchanged.',
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
              ],
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 124),
            children: [
              RcPageHeading(
                eyebrow: 'Team community',
                title: 'Community Board',
                subtitle: profile.canViewAllParishes
                    ? 'All-parish team news, events, recognition and field coordination.'
                    : '${profile.parish} team news, events and recognition.',
                trailing: profile.canCreateCommunityEvent
                    ? IconButton.filledTonal(
                        onPressed: _addPost,
                        icon: const Icon(Icons.add_rounded),
                        tooltip: 'Create community post',
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              RcExpressiveSurface(
                shape: RcSurfaceShape.hero,
                tone: theme.colorScheme.primaryContainer.withValues(alpha: .34),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.groups_2_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 9),
                        Text(
                          'Building back safer — together',
                          style: theme.textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Red Cross news • upcoming meetings • team events • safety recognition • efficient crew performance. Community Admin and limited roles can read and send suggestions for review.',
                    ),
                    if (!profile.canCreateCommunityEvent) ...[
                      const SizedBox(height: 12),
                      FilledButton.tonalIcon(
                        onPressed: _suggest,
                        icon: const Icon(Icons.lightbulb_outline),
                        label: const Text('Send suggestion'),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _RecognitionStrip(records: posts),
              const SizedBox(height: 18),
              Text('Latest', style: theme.textTheme.titleLarge),
              const SizedBox(height: 9),
              if (posts.isEmpty &&
                  snap.connectionState != ConnectionState.waiting)
                const RcExpressiveSurface(
                  child: Text(
                    'No published community updates yet. Authorized supervisors can create the first event or team update.',
                  ),
                ),
              ...posts.map(
                (post) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: RcExpressiveSurface(
                    shape: RcSurfaceShape.offset,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            RcStatusPill(
                              label: '${post.item['category'] ?? 'UPDATE'}'
                                  .toUpperCase(),
                              color: _categoryColor(
                                '${post.item['category'] ?? ''}',
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _date(post.updatedAt),
                              style: theme.textTheme.labelSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(post.title, style: theme.textTheme.titleLarge),
                        const SizedBox(height: 6),
                        Text('${post.item['body'] ?? post.summary}'),
                        if ('${post.item['mediaUrl'] ?? ''}'.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _CommunityMedia(url: '${post.item['mediaUrl']}'),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          post.parish.isEmpty ? 'All Parishes' : post.parish,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _categoryColor(String category) => switch (category.toLowerCase()) {
    'event' => RcColors.purple,
    'meeting' => RcColors.blue,
    'recognition' => RcColors.success,
    'urgent' => RcColors.warning,
    _ => Theme.of(context).colorScheme.primary,
  };

  Future<void> _suggest() async {
    final controller = TextEditingController();
    final text = await showModalBottomSheet<String>(
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Community suggestion',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              minLines: 4,
              maxLines: 7,
              decoration: const InputDecoration(
                labelText: 'Suggestion / event request',
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Send to Admin'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (text == null || text.isEmpty) return;
    try {
      await widget.state.repository.submitCommunitySuggestion(
        profile: widget.state.profile!,
        body: text,
      );
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Suggestion sent to Admin.')),
        );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Suggestion could not be sent. Check connectivity and retry.',
            ),
          ),
        );
    }
  }

  Future<void> _addPost() async {
    final title = TextEditingController();
    final body = TextEditingController();
    String category = 'News';
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (_, setSheetState) => Padding(
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
                  'Publish team update',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items:
                      const [
                            'News',
                            'Event',
                            'Meeting',
                            'Recognition',
                            'Urgent',
                          ]
                          .map(
                            (x) => DropdownMenuItem(value: x, child: Text(x)),
                          )
                          .toList(),
                  onChanged: (v) => setSheetState(() => category = v!),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: body,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(labelText: 'Update'),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () async {
                    if (title.text.trim().isEmpty || body.text.trim().isEmpty)
                      return;
                    try {
                      await widget.state.repository.submitCommunityPost(
                        profile: widget.state.profile!,
                        title: title.text.trim(),
                        body: body.text.trim(),
                        category: category,
                      );
                      if (context.mounted) Navigator.pop(context, true);
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Community update could not be published.',
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Publish'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    title.dispose();
    body.dispose();
    if (saved == true) await refresh();
  }

  String _date(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

class _RecognitionStrip extends StatelessWidget {
  const _RecognitionStrip({required this.records});
  final List<ProductionRecord> records;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recognition = records
        .where((r) => '${r.item['category']}'.toLowerCase() == 'recognition')
        .firstOrNull;
    return RcExpressiveSurface(
      shape: RcSurfaceShape.pill,
      tone: theme.colorScheme.tertiaryContainer.withValues(alpha: .35),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_outlined, size: RcIconSize.lg),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Team recognition', style: theme.textTheme.titleMedium),
                Text(
                  recognition == null
                      ? 'Recognition is calculated from verified production data; publish approved team awards here.'
                      : recognition.title,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityMedia extends StatelessWidget {
  const _CommunityMedia({required this.url});

  final String url;

  bool get _isImage {
    final lower = url.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif');
  }

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return const SizedBox.shrink();
    if (_isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(RcRadius.md),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            semanticLabel: 'Community post media',
            errorBuilder: (_, _, _) => _MediaLink(uri: uri),
          ),
        ),
      );
    }
    return _MediaLink(uri: uri);
  }
}

class _MediaLink extends StatelessWidget {
  const _MediaLink({required this.uri});

  final Uri uri;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: () => launchUrl(uri, mode: LaunchMode.externalApplication),
    icon: const Icon(Icons.play_circle_outline, size: RcIconSize.sm),
    label: const Text('Open attached media'),
  );
}

extension _First<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
