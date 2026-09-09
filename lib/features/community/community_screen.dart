import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/app_constants.dart';
import '../../core/design_tokens.dart';
import '../../core/rc_components.dart';
import '../../models/app_models.dart';
import '../../state/app_state.dart';

Future<bool?> showCommunityComposer(
  BuildContext context,
  AppState state, {
  bool adminMode = false,
}) async {
  final title = TextEditingController();
  final body = TextEditingController();
  final mediaUrl = TextEditingController();
  final thumbnailUrl = TextEditingController();
  final location = TextEditingController();
  final ctaLabel = TextEditingController();
  final ctaUrl = TextEditingController();

  String category = 'News';
  String mediaType = 'None';
  String parish = state.profile!.canViewAllParishes
      ? 'All Parishes'
      : state.profile!.parish;
  bool featured = false;
  bool embed = true;
  DateTime? eventStart;

  Future<DateTime?> chooseDateTime(
    BuildContext sheetContext,
    DateTime? current,
  ) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: sheetContext,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 4),
      initialDate: current ?? now,
    );
    if (date == null || !sheetContext.mounted) return current;
    final time = await showTimePicker(
      context: sheetContext,
      initialTime: TimeOfDay.fromDateTime(current ?? now),
    );
    if (time == null) return DateTime(date.year, date.month, date.day);
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) => FractionallySizedBox(
        heightFactor: .94,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            18,
            0,
            18,
            22 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    adminMode
                        ? 'Community Media Studio'
                        : 'Publish Community Update',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                if (adminMode)
                  const RcStatusPill(
                    label: 'ADMIN CONTROLLED',
                    icon: Icons.admin_panel_settings_outlined,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: const InputDecoration(labelText: 'Content type'),
              items:
                  const [
                        'News',
                        'Event',
                        'Meeting',
                        'Live Stream',
                        'Recognition',
                        'Training',
                        'Safety',
                        'Urgent',
                      ]
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
              onChanged: (value) =>
                  setSheetState(() => category = value ?? 'News'),
            ),
            const SizedBox(height: 9),
            if (state.profile!.canViewAllParishes)
              DropdownButtonFormField<String>(
                initialValue: parish,
                decoration: const InputDecoration(labelText: 'Audience'),
                items: ['All Parishes', ...RcApp.parishes]
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setSheetState(() => parish = value ?? 'All Parishes'),
              ),
            if (state.profile!.canViewAllParishes) const SizedBox(height: 9),
            TextField(
              controller: title,
              decoration: const InputDecoration(
                labelText: 'Title',
                prefixIcon: Icon(Icons.title_rounded),
              ),
            ),
            const SizedBox(height: 9),
            TextField(
              controller: body,
              minLines: 4,
              maxLines: 9,
              decoration: const InputDecoration(
                labelText: 'Description / agenda / update',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Event & meeting details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await chooseDateTime(context, eventStart);
                if (picked != null) {
                  setSheetState(() => eventStart = picked);
                }
              },
              icon: const Icon(Icons.calendar_month_rounded),
              label: Text(
                eventStart == null
                    ? 'Add event date & time'
                    : _dateTimeLabel(eventStart!),
              ),
            ),
            const SizedBox(height: 9),
            TextField(
              controller: location,
              decoration: const InputDecoration(
                labelText: 'Location / meeting place',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Media & live connection',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: mediaType,
              decoration: const InputDecoration(labelText: 'Media type'),
              items:
                  const [
                        'None',
                        'Image',
                        'YouTube',
                        'Live Stream',
                        'Microsoft Teams',
                        'Zoom',
                        'Video',
                        'Document / File',
                        'Website',
                      ]
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
              onChanged: (value) =>
                  setSheetState(() => mediaType = value ?? 'None'),
            ),
            const SizedBox(height: 9),
            TextField(
              controller: mediaUrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Display / media / meeting URL',
                hintText:
                    'YouTube, Teams, Zoom, livestream, document or web URL',
                prefixIcon: Icon(Icons.link_rounded),
              ),
            ),
            const SizedBox(height: 9),
            TextField(
              controller: thumbnailUrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Thumbnail / preview image URL (optional)',
                prefixIcon: Icon(Icons.image_outlined),
              ),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Open inside Red Cross Scope of Work'),
              subtitle: const Text(
                'YouTube, Teams, Zoom, websites and livestreams use the embedded viewer when supported, with an external-app fallback.',
              ),
              value: embed,
              onChanged: (value) => setSheetState(() => embed = value),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Feature this update'),
              subtitle: const Text(
                'Featured items receive stronger visual treatment and priority.',
              ),
              value: featured,
              onChanged: (value) => setSheetState(() => featured = value),
            ),
            const SizedBox(height: 8),
            Text(
              'Call to action',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ctaLabel,
              decoration: const InputDecoration(
                labelText: 'Button label (optional)',
                hintText: 'Join meeting, Watch live, View file…',
              ),
            ),
            const SizedBox(height: 9),
            TextField(
              controller: ctaUrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Button URL (optional)',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                if (title.text.trim().isEmpty || body.text.trim().isEmpty) {
                  return;
                }
                try {
                  await state.repository.submitCommunityPost(
                    profile: state.profile!,
                    title: title.text.trim(),
                    body: body.text.trim(),
                    category: category,
                    mediaUrl: mediaUrl.text.trim().isEmpty
                        ? null
                        : mediaUrl.text.trim(),
                    mediaType: mediaType,
                    thumbnailUrl: thumbnailUrl.text.trim().isEmpty
                        ? null
                        : thumbnailUrl.text.trim(),
                    location: location.text.trim().isEmpty
                        ? null
                        : location.text.trim(),
                    eventStart: eventStart,
                    ctaLabel: ctaLabel.text.trim().isEmpty
                        ? null
                        : ctaLabel.text.trim(),
                    ctaUrl: ctaUrl.text.trim().isEmpty
                        ? null
                        : ctaUrl.text.trim(),
                    embed: embed,
                    featured: featured,
                    parish: parish,
                  );
                  if (context.mounted) Navigator.pop(context, true);
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Community item could not be published: $error',
                        ),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.publish_rounded),
              label: const Text('Publish Community Item'),
            ),
          ],
        ),
      ),
    ),
  );

  for (final controller in [
    title,
    body,
    mediaUrl,
    thumbnailUrl,
    location,
    ctaLabel,
    ctaUrl,
  ]) {
    controller.dispose();
  }
  return saved;
}

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key, required this.state});
  final AppState state;

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  late Future<List<ProductionRecord>> future;
  late final PageController tickerController;
  Timer? tickerTimer;
  int tickerIndex = 0;
  int tickerItemCount = 0;
  bool tickerVisible = true;

  @override
  void initState() {
    super.initState();
    tickerController = PageController();
    tickerVisible =
        widget.state.remoteUiConfig['communityTickerEnabled'] != false;
    future = widget.state.repository.communityRecords(widget.state.profile!);
    tickerTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted ||
          !tickerVisible ||
          tickerItemCount < 2 ||
          !tickerController.hasClients) {
        return;
      }
      tickerIndex = (tickerIndex + 1) % tickerItemCount;
      tickerController.animateToPage(
        tickerIndex,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    tickerTimer?.cancel();
    tickerController.dispose();
    super.dispose();
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
              .where((record) => record.eventType == 'communityPost')
              .toList();
          final upcoming = _upcoming(posts);
          tickerItemCount = posts.take(8).length;

          if (snap.hasError) {
            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                RcExpressiveSurface(
                  tone: theme.colorScheme.errorContainer,
                  child: Column(
                    children: [
                      const Text(
                        'Community could not be loaded. Existing posts were not changed.',
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
                title: 'Community',
                subtitle: profile.canViewAllParishes
                    ? 'All-parish events, meetings, livestreams, recognition, files and team updates.'
                    : '${profile.parish} events, meetings, livestreams, recognition and team updates.',
                trailing: profile.canCreateCommunityEvent
                    ? IconButton.filledTonal(
                        onPressed: _addPost,
                        tooltip: 'Create community item',
                        icon: const Icon(Icons.add_rounded),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              RcExpressiveSurface(
                shape: RcSurfaceShape.hero,
                tone: theme.colorScheme.primaryContainer.withValues(alpha: .30),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RcIconWell(
                      icon: Icons.groups_2_rounded,
                      color: theme.colorScheme.primary,
                      size: 54,
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Building back safer — together',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Upcoming events, live meetings, training, media, files, field recognition and operational updates in one place.',
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
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _CommunityCommandBoard(
                posts: posts,
                upcoming: upcoming,
                tickerController: tickerController,
                tickerVisible: tickerVisible,
                onToggleTicker: () =>
                    setState(() => tickerVisible = !tickerVisible),
                onOpen: _openPost,
              ),
              const SizedBox(height: 18),
              _RecognitionStrip(records: posts),
              const SizedBox(height: 18),
              Text('Latest', style: theme.textTheme.titleLarge),
              const SizedBox(height: 9),
              if (posts.isEmpty &&
                  snap.connectionState != ConnectionState.waiting)
                const RcExpressiveSurface(
                  child: Text('No published community updates yet.'),
                ),
              ...posts.map(
                (post) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PostCard(post: post, onOpen: () => _openPost(post)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<ProductionRecord> _upcoming(List<ProductionRecord> posts) {
    final now = DateTime.now().subtract(const Duration(hours: 6));
    final events = posts.where((post) {
      final category = '${post.item['category'] ?? ''}'.toLowerCase();
      final start = DateTime.tryParse('${post.item['eventStart'] ?? ''}');
      final eventLike = {
        'event',
        'meeting',
        'live stream',
        'training',
      }.contains(category);
      return eventLike && (start == null || start.isAfter(now));
    }).toList();
    events.sort((a, b) {
      final ad = DateTime.tryParse('${a.item['eventStart'] ?? ''}');
      final bd = DateTime.tryParse('${b.item['eventStart'] ?? ''}');
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return ad.compareTo(bd);
    });
    return events;
  }

  Future<void> _addPost() async {
    final saved = await showCommunityComposer(
      context,
      widget.state,
      adminMode: widget.state.profile!.canViewAdmin,
    );
    if (saved == true) await refresh();
  }

  Future<void> _openPost(ProductionRecord post) async {
    final mediaUrl = '${post.item['mediaUrl'] ?? ''}'.trim();
    final ctaUrl = '${post.item['ctaUrl'] ?? ''}'.trim();
    final url = mediaUrl.isNotEmpty ? mediaUrl : ctaUrl;
    if (url.isEmpty) return;
    await _openMedia(
      context,
      url: url,
      title: post.title,
      mediaType: '${post.item['mediaType'] ?? 'Website'}',
      embed: post.item['embed'] != false,
    );
  }

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Suggestion sent to Admin.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Suggestion could not be sent.')),
        );
      }
    }
  }
}

class _CommunityCommandBoard extends StatelessWidget {
  const _CommunityCommandBoard({
    required this.posts,
    required this.upcoming,
    required this.tickerController,
    required this.tickerVisible,
    required this.onToggleTicker,
    required this.onOpen,
  });

  final List<ProductionRecord> posts;
  final List<ProductionRecord> upcoming;
  final PageController tickerController;
  final bool tickerVisible;
  final VoidCallback onToggleTicker;
  final ValueChanged<ProductionRecord> onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ticker = posts.take(8).toList();

    Widget tickerPanel() => RcExpressiveSurface(
      shape: RcSurfaceShape.offset,
      tone: Color.alphaBlend(
        RcColors.brand.withValues(alpha: .09),
        theme.colorScheme.surface,
      ),
      child: SizedBox(
        height: 118,
        child: Column(
          children: [
            Row(
              children: [
                const RcStatusPill(
                  label: 'LIVE TICKER',
                  icon: Icons.campaign_rounded,
                  color: RcColors.brand,
                ),
                const Spacer(),
                IconButton(
                  tooltip: tickerVisible ? 'Hide ticker' : 'Show ticker',
                  onPressed: onToggleTicker,
                  icon: Icon(
                    tickerVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ],
            ),
            if (!tickerVisible)
              const Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Ticker hidden — tap the eye to show it.'),
                ),
              )
            else if (ticker.isEmpty)
              const Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('No community ticker items yet.'),
                ),
              )
            else
              Expanded(
                child: PageView.builder(
                  controller: tickerController,
                  itemCount: ticker.length,
                  itemBuilder: (_, index) {
                    final post = ticker[index];
                    final category = '${post.item['category'] ?? 'Update'}';
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => onOpen(post),
                      child: Row(
                        children: [
                          RcIconWell(
                            icon: _categoryIcon(category),
                            color: _categoryColor(context, category),
                            size: 42,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  post.summary.isEmpty
                                      ? '${post.item['body'] ?? ''}'
                                      : post.summary,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );

    Widget compactSidebar() => RcExpressiveSurface(
      shape: RcSurfaceShape.offset,
      tone: Color.alphaBlend(
        RcColors.blue.withValues(alpha: .09),
        theme.colorScheme.surface,
      ),
      child: SizedBox(
        height: 118,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_upcoming_rounded, color: RcColors.blue),
                const SizedBox(width: 7),
                Expanded(
                  child: Text('Upcoming', style: theme.textTheme.titleMedium),
                ),
                Text('${upcoming.length}', style: theme.textTheme.labelLarge),
              ],
            ),
            const SizedBox(height: 5),
            Expanded(
              child: upcoming.isEmpty
                  ? const Center(child: Text('No upcoming events.'))
                  : ListView.builder(
                      itemCount: upcoming.take(3).length,
                      itemBuilder: (_, index) {
                        final event = upcoming[index];
                        final start = DateTime.tryParse(
                          '${event.item['eventStart'] ?? ''}',
                        );
                        return InkWell(
                          onTap: () => onOpen(event),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 54,
                                  child: Text(
                                    start == null
                                        ? 'SOON'
                                        : _compactDate(start),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: RcColors.blue,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    event.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelLarge,
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );

    Widget mobileEventRail() {
      if (upcoming.isEmpty) {
        return const RcExpressiveSurface(
          child: Text('No upcoming events or meetings yet.'),
        );
      }
      return SizedBox(
        height: 150,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: upcoming.take(6).length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, index) => SizedBox(
            width: 238,
            child: _UpcomingEventCard(
              record: upcoming[index],
              onOpen: () => onOpen(upcoming[index]),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 760) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: tickerPanel()),
              const SizedBox(width: 10),
              SizedBox(width: 330, child: compactSidebar()),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            tickerPanel(),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Upcoming Events',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text('Swipe →', style: theme.textTheme.labelSmall),
              ],
            ),
            const SizedBox(height: 6),
            mobileEventRail(),
          ],
        );
      },
    );
  }
}

class _UpcomingEventCard extends StatelessWidget {
  const _UpcomingEventCard({required this.record, required this.onOpen});
  final ProductionRecord record;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = DateTime.tryParse('${record.item['eventStart'] ?? ''}');
    final category = '${record.item['category'] ?? 'Event'}';
    return RcExpressiveSurface(
      shape: RcSurfaceShape.offset,
      onTap: onOpen,
      tone: theme.colorScheme.secondaryContainer.withValues(alpha: .24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RcStatusPill(
                label: category.toUpperCase(),
                icon: _categoryIcon(category),
                color: _categoryColor(context, category),
              ),
              const Spacer(),
              if (start != null)
                Text(_compactDate(start), style: theme.textTheme.labelMedium),
            ],
          ),
          const Spacer(),
          Text(
            record.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            '${record.item['location'] ?? record.parish}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                _mediaIcon('${record.item['mediaType'] ?? ''}'),
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _defaultAction(record.item),
                  style: theme.textTheme.labelLarge,
                ),
              ),
              const Icon(Icons.arrow_forward_rounded),
            ],
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.onOpen});
  final ProductionRecord post;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = '${post.item['category'] ?? 'Update'}';
    final featured = post.item['featured'] == true;
    final mediaUrl = '${post.item['mediaUrl'] ?? ''}'.trim();
    final ctaUrl = '${post.item['ctaUrl'] ?? ''}'.trim();
    final actionable = mediaUrl.isNotEmpty || ctaUrl.isNotEmpty;
    return RcExpressiveSurface(
      shape: featured ? RcSurfaceShape.hero : RcSurfaceShape.offset,
      tone: featured
          ? theme.colorScheme.primaryContainer.withValues(alpha: .20)
          : null,
      onTap: actionable ? onOpen : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RcStatusPill(
                label: category.toUpperCase(),
                icon: _categoryIcon(category),
                color: _categoryColor(context, category),
              ),
              if (featured) ...[
                const SizedBox(width: 6),
                const RcStatusPill(
                  label: 'FEATURED',
                  icon: Icons.auto_awesome_rounded,
                  color: RcColors.gold,
                ),
              ],
              const Spacer(),
              Text(
                _compactDate(post.updatedAt),
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(post.title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text('${post.item['body'] ?? post.summary}'),
          if (mediaUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            _CommunityMedia(post: post),
          ],
          if (mediaUrl.isEmpty && ctaUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new_rounded),
              label: Text(_defaultAction(post.item)),
            ),
          ],
          if ('${post.item['eventStart'] ?? ''}'.isNotEmpty ||
              '${post.item['location'] ?? ''}'.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if ('${post.item['eventStart'] ?? ''}'.isNotEmpty)
                  RcStatusPill(
                    label: _dateTimeLabel(
                      DateTime.tryParse('${post.item['eventStart']}') ??
                          post.updatedAt,
                    ),
                    icon: Icons.event_rounded,
                    color: RcColors.blue,
                  ),
                if ('${post.item['location'] ?? ''}'.isNotEmpty)
                  RcStatusPill(
                    label: '${post.item['location']}',
                    icon: Icons.location_on_outlined,
                    color: RcColors.teal,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 9),
          Text(
            post.parish.isEmpty ? 'All Parishes' : post.parish,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityMedia extends StatelessWidget {
  const _CommunityMedia({required this.post});
  final ProductionRecord post;

  @override
  Widget build(BuildContext context) {
    final item = post.item;
    final url = '${item['mediaUrl'] ?? ''}'.trim();
    final type = '${item['mediaType'] ?? 'Website'}';
    final thumbnail = '${item['thumbnailUrl'] ?? ''}'.trim();
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return const SizedBox.shrink();

    final preview = thumbnail.isNotEmpty ? thumbnail : _youtubeThumbnail(url);
    if (type.toLowerCase() == 'image') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(RcRadius.md),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _MediaActionCard(
              type: type,
              url: url,
              title: post.title,
              embed: item['embed'] != false,
            ),
          ),
        ),
      );
    }

    if (preview != null) {
      return InkWell(
        borderRadius: BorderRadius.circular(RcRadius.md),
        onTap: () => _openMedia(
          context,
          url: url,
          title: post.title,
          mediaType: type,
          embed: item['embed'] != false,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(RcRadius.md),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  preview,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: .52),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: RcIconWell(
                    icon: _mediaIcon(type),
                    color: Colors.white,
                    size: 62,
                    iconSize: RcIconSize.lg,
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 10,
                  child: Text(
                    _defaultAction(item),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _MediaActionCard(
      type: type,
      url: url,
      title: post.title,
      embed: item['embed'] != false,
    );
  }
}

class _MediaActionCard extends StatelessWidget {
  const _MediaActionCard({
    required this.type,
    required this.url,
    required this.title,
    required this.embed,
  });
  final String type;
  final String url;
  final String title;
  final bool embed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RcExpressiveSurface(
      shape: RcSurfaceShape.pill,
      tone: theme.colorScheme.secondaryContainer.withValues(alpha: .28),
      onTap: () => _openMedia(
        context,
        url: url,
        title: title,
        mediaType: type,
        embed: embed,
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          RcIconWell(
            icon: _mediaIcon(type),
            color: theme.colorScheme.secondary,
            size: 46,
            iconSize: RcIconSize.md,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(type, style: theme.textTheme.titleMedium)),
          Text(
            embed ? 'Open in app' : 'Open',
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(width: 5),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _RecognitionStrip extends StatelessWidget {
  const _RecognitionStrip({required this.records});
  final List<ProductionRecord> records;

  @override
  Widget build(BuildContext context) {
    ProductionRecord? recognition;
    for (final record in records) {
      if ('${record.item['category']}'.toLowerCase() == 'recognition') {
        recognition = record;
        break;
      }
    }
    final theme = Theme.of(context);
    return RcExpressiveSurface(
      shape: RcSurfaceShape.pill,
      tone: theme.colorScheme.tertiaryContainer.withValues(alpha: .32),
      child: Row(
        children: [
          const RcIconWell(
            icon: Icons.emoji_events_rounded,
            color: RcColors.gold,
            size: 50,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Team recognition', style: theme.textTheme.titleMedium),
                Text(
                  recognition == null
                      ? 'Celebrate verified safety, quality and production achievements.'
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

Future<void> _openMedia(
  BuildContext context, {
  required String url,
  required String title,
  required String mediaType,
  required bool embed,
}) async {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) return;
  final embeddable = {
    'youtube',
    'live stream',
    'microsoft teams',
    'zoom',
    'video',
    'website',
  }.contains(mediaType.toLowerCase());

  if (embed && embeddable) {
    final embeddedUrl = mediaType.toLowerCase() == 'youtube'
        ? _youtubeEmbed(url) ?? url
        : url;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _EmbeddedMediaScreen(
          title: title,
          url: embeddedUrl,
          externalUrl: url,
        ),
      ),
    );
    return;
  }
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

class _EmbeddedMediaScreen extends StatefulWidget {
  const _EmbeddedMediaScreen({
    required this.title,
    required this.url,
    required this.externalUrl,
  });
  final String title;
  final String url;
  final String externalUrl;

  @override
  State<_EmbeddedMediaScreen> createState() => _EmbeddedMediaScreenState();
}

class _EmbeddedMediaScreenState extends State<_EmbeddedMediaScreen> {
  late final WebViewController controller;
  int progress = 0;

  @override
  void initState() {
    super.initState();
    controller = WebViewController();
    if (!kIsWeb) {
      controller
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (value) {
              if (mounted) setState(() => progress = value);
            },
          ),
        );
    }
    controller.loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Open in external app/browser',
            onPressed: () => launchUrl(
              Uri.parse(widget.externalUrl),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.open_in_new_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!kIsWeb && progress < 100)
            LinearProgressIndicator(value: progress / 100),
          Expanded(child: WebViewWidget(controller: controller)),
        ],
      ),
    );
  }
}

IconData _mediaIcon(String type) => switch (type.toLowerCase()) {
  'youtube' => Icons.play_circle_fill_rounded,
  'live stream' => Icons.sensors_rounded,
  'microsoft teams' => Icons.groups_rounded,
  'zoom' => Icons.video_camera_front_rounded,
  'video' => Icons.movie_rounded,
  'document / file' => Icons.description_rounded,
  'image' => Icons.image_rounded,
  _ => Icons.language_rounded,
};

IconData _categoryIcon(String category) => switch (category.toLowerCase()) {
  'event' => Icons.event_rounded,
  'meeting' => Icons.groups_rounded,
  'live stream' => Icons.sensors_rounded,
  'training' => Icons.school_rounded,
  'recognition' => Icons.emoji_events_rounded,
  'safety' => Icons.health_and_safety_rounded,
  'urgent' => Icons.warning_amber_rounded,
  _ => Icons.campaign_rounded,
};

Color _categoryColor(BuildContext context, String category) =>
    switch (category.toLowerCase()) {
      'event' => RcColors.purple,
      'meeting' => RcColors.blue,
      'live stream' => RcColors.danger,
      'training' => RcColors.teal,
      'recognition' => RcColors.success,
      'safety' => RcColors.gold,
      'urgent' => RcColors.warning,
      _ => Theme.of(context).colorScheme.primary,
    };

String _defaultAction(Map<String, dynamic> item) {
  final label = '${item['ctaLabel'] ?? ''}'.trim();
  if (label.isNotEmpty) return label;
  return switch ('${item['mediaType'] ?? ''}'.toLowerCase()) {
    'youtube' => 'Watch video',
    'live stream' => 'Watch live',
    'microsoft teams' => 'Join Teams meeting',
    'zoom' => 'Join Zoom meeting',
    'document / file' => 'Open file',
    'video' => 'Play video',
    _ => 'Open link',
  };
}

String? _youtubeId(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return null;
  if (uri.host.contains('youtu.be')) {
    return uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
  }
  if (uri.host.contains('youtube.com')) {
    if (uri.queryParameters['v']?.isNotEmpty == true) {
      return uri.queryParameters['v'];
    }
    final segments = uri.pathSegments;
    final embedIndex = segments.indexOf('embed');
    if (embedIndex >= 0 && embedIndex + 1 < segments.length) {
      return segments[embedIndex + 1];
    }
    final liveIndex = segments.indexOf('live');
    if (liveIndex >= 0 && liveIndex + 1 < segments.length) {
      return segments[liveIndex + 1];
    }
  }
  return null;
}

String? _youtubeThumbnail(String url) {
  final id = _youtubeId(url);
  return id == null ? null : 'https://img.youtube.com/vi/$id/hqdefault.jpg';
}

String? _youtubeEmbed(String url) {
  final id = _youtubeId(url);
  return id == null
      ? null
      : 'https://www.youtube.com/embed/$id?playsinline=1&autoplay=0';
}

String _compactDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/'
    '${value.month.toString().padLeft(2, '0')}/${value.year}';

String _dateTimeLabel(DateTime value) =>
    '${_compactDate(value)} • '
    '${value.hour.toString().padLeft(2, '0')}:'
    '${value.minute.toString().padLeft(2, '0')}';
