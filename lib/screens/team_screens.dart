import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/models.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

class TeamCommunityScreen extends StatefulWidget {
  const TeamCommunityScreen({super.key});

  @override
  State<TeamCommunityScreen> createState() => _TeamCommunityScreenState();
}

class _TeamCommunityScreenState extends State<TeamCommunityScreen> {
  final _messageController = TextEditingController();
  String _crew = 'Alpha Crew';
  String _feed = 'All';

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final posts = state.shoutOuts
        .where((post) => _feed == 'All' || post.crew == _feed)
        .toList();
    return Scaffold(
      appBar: RcAppBar(
        title: const Text('Team Excellence Community'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Team performance',
            onPressed: () =>
                Navigator.pushNamed(context, RcRoutes.teamPerformance),
            icon: const Icon(Icons.insights_outlined),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          const RcSyncBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: <Widget>[
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1080),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        RcPageHeading(
                          eyebrow: 'Team / Community / Recognition',
                          title: 'Build together. Recognize excellence.',
                          description:
                              'Share field wins, coordinate events and keep recognition connected to verified production results.',
                          action: FilledButton.tonalIcon(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              RcRoutes.awardsIncentives,
                            ),
                            icon: const Icon(Icons.workspace_premium_outlined),
                            label: const Text('AWARDS'),
                          ),
                        ),
                        const SizedBox(height: 20),
                        RcResponsiveGrid(
                          minItemWidth: 190,
                          childAspectRatio: 1.35,
                          children: <Widget>[
                            RcMetricTile(
                              label: 'Active team members',
                              value: '${state.team.length}',
                              icon: Icons.groups_2_outlined,
                              color: RcColors.brand,
                              onTap: () => Navigator.pushNamed(
                                context,
                                RcRoutes.teamResources,
                              ),
                            ),
                            RcMetricTile(
                              label: 'Crews deployed',
                              value: '${state.crewsDeployed}',
                              icon: Icons.engineering_outlined,
                              color: RcColors.info,
                              onTap: () => Navigator.pushNamed(
                                context,
                                RcRoutes.teamResources,
                              ),
                            ),
                            RcMetricTile(
                              label: 'Quality average',
                              value:
                                  '${(state.averageCrewQuality * 100).round()}%',
                              icon: Icons.verified_outlined,
                              color: RcColors.success,
                              onTap: () => Navigator.pushNamed(
                                context,
                                RcRoutes.teamPerformance,
                              ),
                            ),
                            RcMetricTile(
                              label: 'Upcoming events',
                              value: '${state.communityEvents.length}',
                              icon: Icons.event_outlined,
                              color: RcColors.warning,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const RcSectionHeader(
                          title: 'Give a shout-out',
                          subtitle:
                              'Recognition becomes part of the operational activity trail.',
                        ),
                        const SizedBox(height: 10),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              children: <Widget>[
                                DropdownButtonFormField<String>(
                                  initialValue: _crew,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Recognize a crew',
                                    prefixIcon: Icon(Icons.groups_outlined),
                                  ),
                                  items: state.crews
                                      .map(
                                        (crew) => DropdownMenuItem<String>(
                                          value: crew.name,
                                          child: Text(crew.name),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) =>
                                      setState(() => _crew = value!),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _messageController,
                                  minLines: 2,
                                  maxLines: 4,
                                  decoration: const InputDecoration(
                                    labelText: 'What did the team achieve?',
                                    hintText:
                                        'Connect the recognition to a real field outcome…',
                                    prefixIcon: Icon(Icons.campaign_outlined),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: FilledButton.icon(
                                    onPressed: () =>
                                        _publishShoutOut(context, state),
                                    icon: const Icon(Icons.send_outlined),
                                    label: const Text('PUBLISH SHOUT-OUT'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        RcSectionHeader(
                          title: 'Community feed',
                          subtitle: '${posts.length} verified team updates',
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: <Widget>[
                              for (final option in <String>[
                                'All',
                                ...state.crews.map((crew) => crew.name),
                              ]) ...<Widget>[
                                ChoiceChip(
                                  label: Text(option),
                                  selected: _feed == option,
                                  onSelected: (_) =>
                                      setState(() => _feed = option),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (posts.isEmpty)
                          const RcEmptyState(
                            icon: Icons.forum_outlined,
                            title: 'No recognition in this view',
                            message:
                                'Publish the first verified team shout-out above.',
                          )
                        else
                          ...posts.map(
                            (post) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Card(
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: CircleAvatar(
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                    child: const Icon(Icons.celebration_outlined),
                                  ),
                                  title: Text(post.message),
                                  subtitle: Text(
                                    '${post.crew} • ${post.author} • ${_shortDate(post.createdAt)}',
                                  ),
                                  trailing: const Icon(Icons.favorite_outline),
                                  onTap: () => ScaffoldMessenger.of(context)
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Recognition saved for ${post.crew}.',
                                        ),
                                      ),
                                    ),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        const RcSectionHeader(
                          title: 'Upcoming community events',
                          subtitle: 'Training, coordination and outreach.',
                        ),
                        const SizedBox(height: 10),
                        RcResponsiveGrid(
                          minItemWidth: 280,
                          childAspectRatio: 1.85,
                          children: state.communityEvents
                              .map(
                                (event) => Card(
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: const CircleAvatar(
                                      child: Icon(Icons.event_available_outlined),
                                    ),
                                    title: Text(event.title),
                                    subtitle: Text(
                                      '${event.kind} • ${event.location}\n${_shortDate(event.startsAt)}',
                                    ),
                                    isThreeLine: true,
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      RcRoutes.liveBriefing,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _publishShoutOut(BuildContext context, AppState state) {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a recognition message first.')),
      );
      return;
    }
    state.addShoutOut(crew: _crew, message: message);
    _messageController.clear();
    setState(() => _feed = 'All');
    showSavedMessage(context, submitted: true);
  }
}

class TeamPerformanceScreen extends StatelessWidget {
  const TeamPerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: RcAppBar(title: const Text('Team Performance')),
      body: Column(
        children: <Widget>[
          const RcSyncBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: <Widget>[
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1080),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        RcPageHeading(
                          eyebrow: 'Team / Verified outcomes',
                          title: 'Performance without losing context',
                          description:
                              'Compare quality, safe delivery, completion and payout velocity while keeping every result tied to a crew and house.',
                          action: FilledButton.tonalIcon(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              RcRoutes.teamCommunity,
                            ),
                            icon: const Icon(Icons.diversity_3_outlined),
                            label: const Text('COMMUNITY'),
                          ),
                        ),
                        const SizedBox(height: 20),
                        RcResponsiveGrid(
                          minItemWidth: 190,
                          childAspectRatio: 1.35,
                          children: <Widget>[
                            RcMetricTile(
                              label: 'Average quality',
                              value:
                                  '${(state.averageCrewQuality * 100).round()}%',
                              icon: Icons.verified_outlined,
                              color: RcColors.success,
                            ),
                            RcMetricTile(
                              label: 'Houses completed',
                              value:
                                  '${state.crews.fold<int>(0, (sum, crew) => sum + crew.housesCompleted)}',
                              icon: Icons.home_work_outlined,
                              color: RcColors.brand,
                            ),
                            RcMetricTile(
                              label: 'Safety incidents',
                              value:
                                  '${state.crews.fold<int>(0, (sum, crew) => sum + crew.incidents)}',
                              icon: Icons.health_and_safety_outlined,
                              color: RcColors.warning,
                            ),
                            RcMetricTile(
                              label: 'Deployed now',
                              value: '${state.crewsDeployed}',
                              icon: Icons.engineering_outlined,
                              color: RcColors.info,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const RcSectionHeader(
                          title: 'Crew scorecards',
                          subtitle:
                              'Quality stays the primary signal; speed never overrides safety.',
                        ),
                        const SizedBox(height: 12),
                        ...state.crews.map(
                          (crew) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _CrewScorecard(crew: crew),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: <Widget>[
                            FilledButton.icon(
                              onPressed: () => Navigator.pushNamed(
                                context,
                                RcRoutes.teamResources,
                              ),
                              icon: const Icon(Icons.group_add_outlined),
                              label: const Text('MANAGE RESOURCES'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => Navigator.pushNamed(
                                context,
                                RcRoutes.promotionRouting,
                              ),
                              icon: const Icon(Icons.military_tech_outlined),
                              label: const Text('PROMOTION ROUTING'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => Navigator.pushNamed(
                                context,
                                RcRoutes.awardsIncentives,
                              ),
                              icon: const Icon(Icons.workspace_premium_outlined),
                              label: const Text('AWARDS & INCENTIVES'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CrewScorecard extends StatelessWidget {
  const _CrewScorecard({required this.crew});

  final CrewRecord crew;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: const Icon(Icons.groups_2_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        crew.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text('${crew.lead} • ${crew.currentHouse}'),
                    ],
                  ),
                ),
                RcStatusChip(
                  label: crew.availability.toUpperCase(),
                  compact: true,
                  tone: crew.availability == 'Deployed'
                      ? RcStatusTone.info
                      : RcStatusTone.success,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: crew.qualityScore,
                color: RcColors.success,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                RcStatusChip(
                  label: '${(crew.qualityScore * 100).round()}% QUALITY',
                  tone: RcStatusTone.success,
                  compact: true,
                ),
                RcStatusChip(
                  label: '${crew.efficiency.toStringAsFixed(2)}× EFFICIENCY',
                  tone: RcStatusTone.info,
                  compact: true,
                ),
                RcStatusChip(
                  label: '${crew.payoutVelocity.toStringAsFixed(1)}d PAYOUT',
                  compact: true,
                ),
                RcStatusChip(
                  label: '${crew.incidents} INCIDENTS',
                  tone: crew.incidents == 0
                      ? RcStatusTone.success
                      : RcStatusTone.warning,
                  compact: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TeamResourceScreen extends StatefulWidget {
  const TeamResourceScreen({super.key});

  @override
  State<TeamResourceScreen> createState() => _TeamResourceScreenState();
}

class _TeamResourceScreenState extends State<TeamResourceScreen> {
  final Map<String, String> _assignment = <String, String>{};

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: RcAppBar(title: const Text('Team Resource Manager')),
      body: Column(
        children: <Widget>[
          const RcSyncBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: <Widget>[
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1080),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        RcPageHeading(
                          eyebrow: 'Plan / Workforce capacity',
                          title: 'Put the right crew on the right house',
                          description:
                              'Balance availability, specialist skills and active construction phases without losing house-level accountability.',
                          action: FilledButton.tonalIcon(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              RcRoutes.newTransfer,
                            ),
                            icon: const Icon(Icons.swap_horiz_outlined),
                            label: const Text('TRANSFER'),
                          ),
                        ),
                        const SizedBox(height: 20),
                        RcResponsiveGrid(
                          minItemWidth: 190,
                          childAspectRatio: 1.35,
                          children: <Widget>[
                            RcMetricTile(
                              label: 'Crews deployed',
                              value: '${state.crewsDeployed}',
                              icon: Icons.engineering_outlined,
                              color: RcColors.info,
                            ),
                            RcMetricTile(
                              label: 'Available crews',
                              value:
                                  '${state.crews.where((crew) => crew.availability == 'Available').length}',
                              icon: Icons.person_add_alt_outlined,
                              color: RcColors.success,
                            ),
                            RcMetricTile(
                              label: 'Open houses',
                              value: '${state.activeHouses}',
                              icon: Icons.home_work_outlined,
                              color: RcColors.brand,
                            ),
                            RcMetricTile(
                              label: 'Pending transfers',
                              value: '${state.pendingTransfers}',
                              icon: Icons.pending_actions_outlined,
                              color: RcColors.warning,
                              onTap: () => Navigator.pushNamed(
                                context,
                                RcRoutes.transfers,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const RcSectionHeader(
                          title: 'Crew assignments',
                          subtitle:
                              'Changes update the production trail immediately.',
                        ),
                        const SizedBox(height: 12),
                        ...state.crews.map((crew) {
                          final selected =
                              _assignment[crew.id] ?? crew.currentHouse;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        CircleAvatar(
                                          child: Text(
                                            crew.name
                                                .split(' ')
                                                .map((word) => word[0])
                                                .take(2)
                                                .join(),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                crew.name,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium,
                                              ),
                                              Text(
                                                '${crew.lead} • ${crew.members.length} members • ${crew.currentPhase}',
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    DropdownButtonFormField<String>(
                                      initialValue: selected,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Assigned house',
                                        prefixIcon:
                                            Icon(Icons.holiday_village_outlined),
                                      ),
                                      items: state.houses
                                          .map(
                                            (house) =>
                                                DropdownMenuItem<String>(
                                              value: house.code,
                                              child: Text(
                                                '${house.code} • ${house.community} • ${house.phase.label}',
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) => setState(
                                        () => _assignment[crew.id] = value!,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: FilledButton.icon(
                                        onPressed: () {
                                          final houseCode =
                                              _assignment[crew.id] ??
                                                  crew.currentHouse;
                                          state.assignCrew(crew.id, houseCode);
                                          state.selectHouse(houseCode);
                                          showSavedMessage(
                                            context,
                                            submitted: true,
                                          );
                                        },
                                        icon: const Icon(Icons.route_outlined),
                                        label: const Text('ASSIGN CREW'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AwardsIncentivesScreen extends StatefulWidget {
  const AwardsIncentivesScreen({super.key});

  @override
  State<AwardsIncentivesScreen> createState() =>
      _AwardsIncentivesScreenState();
}

class _AwardsIncentivesScreenState extends State<AwardsIncentivesScreen> {
  String _winner = 'Alpha Crew';
  double _threshold = 0;
  String _period = 'Quarterly';
  bool _autoApply = true;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: RcAppBar(title: const Text('Awards & Incentives')),
      body: Column(
        children: <Widget>[
          const RcSyncBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: <Widget>[
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const RcPageHeading(
                          eyebrow: 'Admin / Recognition policy',
                          title: 'Reward verified team outcomes',
                          description:
                              'Configure transparent incentives and publish recognition without disconnecting rewards from quality or safety.',
                        ),
                        const SizedBox(height: 20),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Team of the Month',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  initialValue: _winner,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Featured crew',
                                    prefixIcon:
                                        Icon(Icons.emoji_events_outlined),
                                  ),
                                  items: state.crews
                                      .map(
                                        (crew) => DropdownMenuItem<String>(
                                          value: crew.name,
                                          child: Text(
                                            '${crew.name} • ${(crew.qualityScore * 100).round()}% quality',
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) =>
                                      setState(() => _winner = value!),
                                ),
                                const SizedBox(height: 12),
                                FilledButton.icon(
                                  onPressed: () {
                                    state.publishAward(
                                      crew: _winner,
                                      reason:
                                          'verified quality, teamwork and safe delivery',
                                    );
                                    showSavedMessage(
                                      context,
                                      submitted: true,
                                    );
                                  },
                                  icon: const Icon(Icons.publish_outlined),
                                  label: const Text('PUBLISH RECOGNITION'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const RcSectionHeader(
                          title: 'Incentive programmes',
                          subtitle:
                              'Pause or reactivate programmes without deleting their rules.',
                        ),
                        const SizedBox(height: 10),
                        Card(
                          child: Column(
                            children: state.incentives
                                .map(
                                  (incentive) => SwitchListTile(
                                    secondary: const Icon(
                                      Icons.workspace_premium_outlined,
                                    ),
                                    title: Text(incentive.title),
                                    subtitle: Text(
                                      '${incentive.description}\n${incentive.qualification}',
                                    ),
                                    isThreeLine: true,
                                    value: incentive.active,
                                    onChanged: (_) =>
                                        state.toggleIncentive(incentive.id),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const RcSectionHeader(
                          title: 'Safety bonus calculation',
                          subtitle:
                              'Quality and evidence gates remain mandatory.',
                        ),
                        const SizedBox(height: 10),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Maximum verified incidents: ${_threshold.round()}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Slider(
                                  value: _threshold,
                                  min: 0,
                                  max: 3,
                                  divisions: 3,
                                  label: '${_threshold.round()}',
                                  onChanged: (value) =>
                                      setState(() => _threshold = value),
                                ),
                                DropdownButtonFormField<String>(
                                  initialValue: _period,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Calculation period',
                                  ),
                                  items: const <String>[
                                    'Monthly',
                                    'Quarterly',
                                    'Per project',
                                  ]
                                      .map(
                                        (value) => DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) =>
                                      setState(() => _period = value!),
                                ),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text(
                                    'Apply automatically after verification',
                                  ),
                                  value: _autoApply,
                                  onChanged: (value) =>
                                      setState(() => _autoApply = value),
                                ),
                                FilledButton.tonalIcon(
                                  onPressed: () {
                                    state.updateSafetyPolicy(
                                      incidentThreshold: _threshold.round(),
                                      calculationPeriod: _period,
                                      autoApply: _autoApply,
                                    );
                                    showSavedMessage(
                                      context,
                                      submitted: false,
                                    );
                                  },
                                  icon: const Icon(Icons.save_outlined),
                                  label: const Text('SAVE POLICY'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PromotionRoutingScreen extends StatelessWidget {
  const PromotionRoutingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: RcAppBar(title: const Text('Promotion Routing')),
      body: Column(
        children: <Widget>[
          const RcSyncBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: <Widget>[
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const RcPageHeading(
                          eyebrow: 'Team / Skills progression',
                          title: 'Route earned promotions into real demand',
                          description:
                              'Review verified performance, approve progression and connect new capability to the cluster that needs it.',
                        ),
                        const SizedBox(height: 20),
                        Card(
                          child: SwitchListTile(
                            secondary: const Icon(Icons.route_outlined),
                            title: const Text('Automatic demand routing'),
                            subtitle: const Text(
                              'Recommend a destination from active workload; a person still approves the promotion.',
                            ),
                            value: state.autoRoutingEnabled,
                            onChanged: state.setAutoRouting,
                          ),
                        ),
                        const SizedBox(height: 20),
                        RcSectionHeader(
                          title: 'Qualified candidates',
                          subtitle:
                              '${state.promotionCandidates.where((candidate) => !candidate.promoted).length} awaiting review',
                        ),
                        const SizedBox(height: 10),
                        ...state.promotionCandidates.map(
                          (candidate) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        const CircleAvatar(
                                          child: Icon(
                                            Icons.military_tech_outlined,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                candidate.name,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium,
                                              ),
                                              Text(
                                                '${candidate.currentRole} → ${candidate.targetRole}',
                                              ),
                                            ],
                                          ),
                                        ),
                                        RcStatusChip(
                                          label: candidate.promoted
                                              ? 'APPROVED'
                                              : 'QUALIFIED',
                                          tone: candidate.promoted
                                              ? RcStatusTone.success
                                              : RcStatusTone.info,
                                          compact: true,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: <Widget>[
                                        RcStatusChip(
                                          label:
                                              '${(candidate.qualityScore * 100).round()}% QUALITY',
                                          tone: RcStatusTone.success,
                                          compact: true,
                                        ),
                                        RcStatusChip(
                                          label:
                                              '${candidate.speedIndex.toStringAsFixed(1)}× SPEED',
                                          tone: RcStatusTone.info,
                                          compact: true,
                                        ),
                                        RcStatusChip(
                                          label:
                                              '${(candidate.attendance * 100).round()}% ATTENDANCE',
                                          compact: true,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      'Routing target: ${candidate.routingTarget}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: candidate.promoted
                                          ? OutlinedButton.icon(
                                              onPressed: () =>
                                                  Navigator.pushNamed(
                                                context,
                                                RcRoutes.teamResources,
                                              ),
                                              icon: const Icon(
                                                Icons.groups_2_outlined,
                                              ),
                                              label: const Text(
                                                'OPEN TEAM RESOURCES',
                                              ),
                                            )
                                          : FilledButton.icon(
                                              onPressed: () {
                                                state.promoteCandidate(
                                                  candidate.id,
                                                );
                                                showSavedMessage(
                                                  context,
                                                  submitted: true,
                                                );
                                              },
                                              icon: const Icon(Icons.check),
                                              label: const Text(
                                                'APPROVE & ROUTE',
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _shortDate(DateTime value) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final minute = value.minute.toString().padLeft(2, '0');
  return '${months[value.month - 1]} ${value.day} • ${value.hour}:$minute';
}
