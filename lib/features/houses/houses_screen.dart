import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';
import '../../core/rc_components.dart';
import '../../models/app_models.dart';
import '../../state/app_state.dart';

class HousesScreen extends StatefulWidget {
  const HousesScreen({super.key, required this.state});
  final AppState state;

  @override
  State<HousesScreen> createState() => _HousesScreenState();
}

class _HousesScreenState extends State<HousesScreen> {
  String query = '';
  late Future<List<HouseRecord>> future;

  @override
  void initState() {
    super.initState();
    future = widget.state.repository.houses(widget.state.profile!);
  }

  Future<void> _refresh() async {
    setState(() => future = widget.state.repository.houses(widget.state.profile!));
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.state.profile!;
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<HouseRecord>>(
        future: future,
        builder: (context, snap) {
          final all = snap.data ?? const <HouseRecord>[];
          final filtered = all
              .where(
                (h) => '${h.code} ${h.beneficiary} ${h.parish} ${h.cluster}'
                    .toLowerCase()
                    .contains(query.toLowerCase()),
              )
              .toList();
          final grouped = <String, List<HouseRecord>>{};
          for (final house in filtered) {
            grouped.putIfAbsent(house.parish, () => []).add(house);
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 124),
            children: [
              RcPageHeading(
                eyebrow: 'Portfolio',
                title: 'Active Houses',
                subtitle:
                    'Each house is a production container for scope, control records, evidence, close-out and payment.',
                trailing: profile.canViewAllParishes
                    ? const RcStatusPill(
                        label: 'ALL PARISHES',
                        icon: Icons.public_outlined,
                        color: RcColors.blue,
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              SearchBar(
                hintText: 'Search house, beneficiary, parish…',
                leading: const Icon(Icons.search),
                onChanged: (v) => setState(() => query = v),
              ),
              const SizedBox(height: 16),
              if (snap.connectionState == ConnectionState.waiting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: CircularProgressIndicator(),
                  ),
                ),
              if (snap.hasError)
                RcExpressiveSurface(
                  tone: theme.colorScheme.errorContainer,
                  child: const Text(
                    'Could not load houses. Check connectivity and pull to refresh.',
                  ),
                ),
              if (snap.connectionState != ConnectionState.waiting && filtered.isEmpty)
                const RcExpressiveSurface(
                  child: Text('No active houses are visible for this account.'),
                ),
              for (final parish in grouped.keys.toList()..sort()) ...[
                if (profile.canViewAllParishes)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
                    child: Text(parish, style: theme.textTheme.titleMedium),
                  ),
                ...grouped[parish]!.map(
                  (h) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: RcExpressiveSurface(
                      shape: RcSurfaceShape.offset,
                      onTap: () => _openHouse(context, h),
                      semanticLabel: 'Open ${h.code} ${h.beneficiary}',
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(19),
                                topRight: Radius.circular(11),
                                bottomLeft: Radius.circular(11),
                                bottomRight: Radius.circular(19),
                              ),
                            ),
                            child: Icon(
                              Icons.home_work_outlined,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${h.code} • ${h.beneficiary}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${h.cluster}${h.cluster.isEmpty ? '' : ' • '}${h.stage}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          RcProgressOrb(
                            value: h.progress / 100,
                            label: 'done',
                            size: 62,
                            color: h.progress >= 80
                                ? RcColors.success
                                : theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _openHouse(BuildContext context, HouseRecord house) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        settings: RouteSettings(name: '/houses/${house.code}'),
        transitionDuration:
            widget.state.reduceMotion ? Duration.zero : RcMotion.medium,
        pageBuilder: (_, _, _) => HouseCommandScreen(
          state: widget.state,
          house: house,
        ),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(.02, .01),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
      ),
    );
  }
}

class HouseCommandScreen extends StatelessWidget {
  const HouseCommandScreen({
    super.key,
    required this.state,
    required this.house,
  });
  final AppState state;
  final HouseRecord house;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(house.code)),
      body: FutureBuilder<List<ProductionRecord>>(
        future: state.repository.productionRecords(state.profile!),
        builder: (context, snap) {
          final records = (snap.data ?? const <ProductionRecord>[])
              .where((r) => r.houseCode.toLowerCase() == house.code.toLowerCase())
              .toList();
          final open = records.where((r) => !r.isClosed).length;
          final attention = records.where((r) => r.needsAttention).length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
            children: [
              RcExpressiveSurface(
                shape: RcSurfaceShape.hero,
                tone: theme.colorScheme.primaryContainer.withValues(alpha: .42),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final info = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${house.code} • ${house.beneficiary}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${house.parish}${house.cluster.isEmpty ? '' : ' • ${house.cluster}'}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            RcStatusPill(
                              label: house.stage.toUpperCase(),
                              icon: Icons.flag_outlined,
                            ),
                            RcStatusPill(
                              label: '$open OPEN',
                              color: RcColors.blue,
                            ),
                            RcStatusPill(
                              label: '$attention ATTENTION',
                              color: attention > 0 ? RcColors.warning : RcColors.success,
                            ),
                          ],
                        ),
                      ],
                    );
                    if (constraints.maxWidth < 500) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          info,
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.center,
                            child: RcProgressOrb(
                              value: house.progress / 100,
                              label: 'house',
                              size: 112,
                            ),
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: info),
                        RcProgressOrb(
                          value: house.progress / 100,
                          label: 'house',
                          size: 116,
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              Text('Production chain', style: theme.textTheme.titleLarge),
              const SizedBox(height: 9),
              _HousePipeline(records: records),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: Text('Evidence & activity', style: theme.textTheme.titleLarge)),
                  Text('${records.length} records', style: theme.textTheme.labelMedium),
                ],
              ),
              const SizedBox(height: 9),
              if (snap.connectionState == ConnectionState.waiting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (records.isEmpty)
                const RcExpressiveSurface(
                  child: Text('No production records are linked to this house yet.'),
                )
              else
                ...records.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: RcExpressiveSurface(
                      shape: RcSurfaceShape.offset,
                      child: Row(
                        children: [
                          Icon(
                            r.needsAttention
                                ? Icons.warning_amber_rounded
                                : Icons.description_outlined,
                            color: r.needsAttention
                                ? RcColors.warning
                                : theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                                const SizedBox(height: 2),
                                Text(
                                  r.summary.isEmpty ? r.eventType : r.summary,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          RcStatusPill(
                            label: r.status.toUpperCase(),
                            color: r.needsAttention
                                ? RcColors.warning
                                : r.isClosed
                                    ? RcColors.success
                                    : theme.colorScheme.secondary,
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
}

class _HousePipeline extends StatelessWidget {
  const _HousePipeline({required this.records});
  final List<ProductionRecord> records;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool hasAny(Set<String> types) => records.any((r) => types.contains(r.eventType));
    final steps = [
      ('Scope', hasAny({'scope'})),
      ('Plan', hasAny({'controlData', 'workPlan', 'documentChecklist'})),
      ('Delivery', hasAny({'siteVisit', 'dailyLog', 'materialRequest', 'consumables', 'inventory'})),
      ('Quality', hasAny({'monitoring'})),
      ('Complete', hasAny({'notice'})),
      ('Payment', hasAny({'payment'})),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                color: steps[i].$2
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Icon(
                    steps[i].$2 ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 17,
                    color: steps[i].$2
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    steps[i].$1,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            if (i != steps.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: theme.colorScheme.outline,
                ),
              ),
          ],
        ],
      ),
    );
  }
}
