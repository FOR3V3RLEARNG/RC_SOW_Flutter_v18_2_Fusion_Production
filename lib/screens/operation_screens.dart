import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/models.dart';
import '../core/production_models.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

class HouseCommandScreen extends StatelessWidget {
  const HouseCommandScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final house = state.selectedHouse;
    final activities = state.activities
        .where((entry) => entry.houseCode == house.code)
        .take(4)
        .toList();
    final documents = state.completedDocuments[house.code]?.length ?? 0;
    return Scaffold(
      appBar: RcAppBar(
        title: Text('${house.code} • House Command'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Activity',
            onPressed: () => Navigator.pushNamed(context, RcRoutes.activity),
            icon: const Icon(Icons.history),
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
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        RcPageHeading(
                          eyebrow: '${house.parish} • ${house.cluster}',
                          title: '${house.code} — ${house.beneficiary}',
                          description:
                              '${house.community} • ${house.roofType} • ${house.roofArea.toStringAsFixed(0)} sq ft',
                          action: RcStatusChip(
                            label: house.status.label.toUpperCase(),
                            tone: house.needsAttention
                                ? RcStatusTone.warning
                                : RcStatusTone.success,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        'House lifecycle',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge,
                                      ),
                                    ),
                                    Text(
                                      '${(house.progress * 100).round()}%',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                RcLifecycleRail(phase: house.phase),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (house.blocker != null) ...<Widget>[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: RcColors.warningSoft,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: <Widget>[
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: RcColors.warning,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      const Text(
                                        'BLOCKER',
                                        style: TextStyle(
                                          color: RcColors.warning,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      Text(
                                        house.blocker!,
                                        style: const TextStyle(
                                          color: RcColors.ink,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pushNamed(
                                    context,
                                    RcRoutes.materialRequest,
                                  ),
                                  child: const Text('RESOLVE'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        RcNextActionCard(
                          house: house,
                          onPressed: () =>
                              _openNextAction(context, house.phase),
                        ),
                        const SizedBox(height: 20),
                        RcResponsiveGrid(
                          minItemWidth: 200,
                          childAspectRatio: 1.28,
                          children: <Widget>[
                            RcMetricTile(
                              label: 'Evidence readiness',
                              value:
                                  '${house.evidenceComplete}/${house.evidenceRequired}',
                              icon: Icons.photo_library_outlined,
                              color: house.evidenceReady
                                  ? RcColors.success
                                  : RcColors.warning,
                              onTap: () => Navigator.pushNamed(
                                context,
                                RcRoutes.evidence,
                              ),
                            ),
                            RcMetricTile(
                              label: 'Documents complete',
                              value: '$documents/7',
                              icon: Icons.description_outlined,
                              color: RcColors.info,
                              onTap: () => Navigator.pushNamed(
                                context,
                                RcRoutes.documentChecklist,
                              ),
                            ),
                            RcMetricTile(
                              label: 'Assigned team',
                              value: '${house.team.length}',
                              icon: Icons.groups_outlined,
                              color: RcColors.brand,
                              onTap: () => Navigator.pushNamed(
                                context,
                                RcRoutes.usersOnline,
                              ),
                            ),
                            RcMetricTile(
                              label: 'Material lines',
                              value: '${state.inventory.length}',
                              icon: Icons.inventory_2_outlined,
                              color: RcColors.warning,
                              onTap: () => Navigator.pushNamed(
                                context,
                                RcRoutes.inventory,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        RcSectionHeader(
                          title: '${house.code} records',
                          subtitle:
                              'Every tile belongs to this house and opens its input form or working record.',
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _HouseRecordTile(
                                title: 'Completion',
                                subtitle: 'Close-out',
                                icon: Icons.task_alt_outlined,
                                route: RcRoutes.completion,
                                emphasized: true,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _HouseRecordTile(
                                title: 'Payment',
                                subtitle: 'Finance',
                                icon: Icons.payments_outlined,
                                route: RcRoutes.payment,
                                emphasized: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const RcSectionHeader(
                          title: 'Technical & scope',
                          subtitle: 'Beneficiary, roof, quantities and document readiness.',
                        ),
                        const SizedBox(height: 8),
                        RcResponsiveGrid(
                          minItemWidth: 145,
                          childAspectRatio: 1.25,
                          children: const <Widget>[
                            _HouseRecordTile(
                              title: 'Beneficiary & Scope',
                              subtitle: 'House input',
                              icon: Icons.person_pin_circle_outlined,
                              route: RcRoutes.scopeHouse,
                            ),
                            _HouseRecordTile(
                              title: 'Roof Drawing',
                              subtitle: 'Custom geometry',
                              icon: Icons.architecture_outlined,
                              route: RcRoutes.scopeRoof,
                            ),
                            _HouseRecordTile(
                              title: 'BOQ',
                              subtitle: 'Quantities',
                              icon: Icons.calculate_outlined,
                              route: RcRoutes.boq,
                            ),
                            _HouseRecordTile(
                              title: 'Documents',
                              subtitle: 'Readiness',
                              icon: Icons.fact_check_outlined,
                              route: RcRoutes.documentChecklist,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const RcSectionHeader(
                          title: 'Delivery & crew',
                          subtitle: 'Planning, visits, daily production, materials and house stock.',
                        ),
                        const SizedBox(height: 8),
                        RcResponsiveGrid(
                          minItemWidth: 145,
                          childAspectRatio: 1.25,
                          children: const <Widget>[
                            _HouseRecordTile(
                              title: 'Work Plan',
                              subtitle: 'Plan & crew',
                              icon: Icons.event_note_outlined,
                              route: RcRoutes.workPlan,
                            ),
                            _HouseRecordTile(
                              title: 'Site Visits',
                              subtitle: 'Inspection',
                              icon: Icons.location_on_outlined,
                              route: RcRoutes.siteVisits,
                            ),
                            _HouseRecordTile(
                              title: 'Daily Log',
                              subtitle: 'Production',
                              icon: Icons.menu_book_outlined,
                              route: RcRoutes.dailyLog,
                            ),
                            _HouseRecordTile(
                              title: 'Materials',
                              subtitle: 'Request',
                              icon: Icons.inventory_2_outlined,
                              route: RcRoutes.materialRequest,
                            ),
                            _HouseRecordTile(
                              title: 'Consumables',
                              subtitle: 'Request',
                              icon: Icons.handyman_outlined,
                              route: RcRoutes.consumableRequest,
                            ),
                            _HouseRecordTile(
                              title: 'Inventory',
                              subtitle: 'House stock',
                              icon: Icons.warehouse_outlined,
                              route: RcRoutes.inventory,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const RcSectionHeader(
                          title: 'Quality & evidence',
                          subtitle: 'Monitoring, photo/file evidence, production hours and audit trail.',
                        ),
                        const SizedBox(height: 8),
                        RcResponsiveGrid(
                          minItemWidth: 145,
                          childAspectRatio: 1.25,
                          children: const <Widget>[
                            _HouseRecordTile(
                              title: 'Monitoring',
                              subtitle: 'Quality',
                              icon: Icons.rule_folder_outlined,
                              route: RcRoutes.monitoring,
                            ),
                            _HouseRecordTile(
                              title: 'Evidence',
                              subtitle: 'Photos & files',
                              icon: Icons.photo_library_outlined,
                              route: RcRoutes.evidence,
                            ),
                            _HouseRecordTile(
                              title: 'Work Logs',
                              subtitle: 'Hours & work',
                              icon: Icons.edit_note_outlined,
                              route: RcRoutes.workLogs,
                            ),
                            _HouseRecordTile(
                              title: 'Activity',
                              subtitle: 'Audit trail',
                              icon: Icons.history,
                              route: RcRoutes.activity,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        RcSectionHeader(
                          title: 'Recent activity',
                          trailing: TextButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, RcRoutes.activity),
                            child: const Text('VIEW ALL'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (activities.isEmpty)
                          const RcEmptyState(
                            icon: Icons.history,
                            title: 'No activity yet',
                            message:
                                'Saving the first record will start the traceability thread.',
                          )
                        else
                          Card(
                            child: Column(
                              children: activities.map((entry) {
                                return ListTile(
                                  leading: CircleAvatar(
                                    child: Icon(entry.icon, size: 19),
                                  ),
                                  title: Text(entry.title),
                                  subtitle: Text(
                                    '${entry.detail}\n${entry.actor}',
                                  ),
                                  isThreeLine: true,
                                );
                              }).toList(),
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

  void _openNextAction(BuildContext context, LifecyclePhase phase) {
    final route = switch (phase) {
      LifecyclePhase.scope => RcRoutes.scopeHouse,
      LifecyclePhase.plan => RcRoutes.workPlan,
      LifecyclePhase.delivery => RcRoutes.dailyLog,
      LifecyclePhase.quality => RcRoutes.monitoring,
      LifecyclePhase.closeOut => RcRoutes.completion,
      LifecyclePhase.finance => RcRoutes.payment,
    };
    Navigator.pushNamed(context, route);
  }
}

class _HouseRecordTile extends StatelessWidget {
  const _HouseRecordTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    this.emphasized = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: emphasized ? scheme.primaryContainer : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.pushNamed(context, route),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: emphasized
                      ? scheme.primary.withOpacity(.12)
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: emphasized ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommandTile extends StatelessWidget {
  const _CommandTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minVerticalPadding: 13,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.pushNamed(context, route),
    );
  }
}

class NewControlScreen extends StatefulWidget {
  const NewControlScreen({super.key});

  @override
  State<NewControlScreen> createState() => _NewControlScreenState();
}

class _NewControlScreenState extends State<NewControlScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _beneficiary = TextEditingController();
  final _community = TextEditingController();
  final _cluster = TextEditingController();
  String _parish = 'Hanover';
  String? _duplicateCode;

  @override
  void dispose() {
    _code.dispose();
    _beneficiary.dispose();
    _community.dispose();
    _cluster.dispose();
    super.dispose();
  }

  void _create() {
    if (!_formKey.currentState!.validate()) return;
    final state = AppScope.of(context);
    final created = state.createHouse(
      code: _code.text,
      beneficiary: _beneficiary.text,
      parish: _parish,
      cluster: _cluster.text,
      community: _community.text,
    );
    if (!created) {
      setState(() => _duplicateCode = _code.text.trim().toUpperCase());
      return;
    }
    Navigator.pushReplacementNamed(context, RcRoutes.scopeHouse);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RcAppBar(title: const Text('New Control')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const RcPageHeading(
                      eyebrow: 'Control / Create',
                      title: 'Start a house control',
                      description:
                          'A duplicate-safe production record begins at Scope and preserves the complete evidence chain.',
                    ),
                    const SizedBox(height: 20),
                    if (_duplicateCode != null) ...<Widget>[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: RcColors.warningSoft,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(
                              Icons.content_copy_outlined,
                              color: RcColors.warning,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '$_duplicateCode already has a control. No duplicate was created.',
                                style: const TextStyle(
                                  color: RcColors.ink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                AppScope.of(context)
                                    .selectHouse(_duplicateCode!);
                                Navigator.pushReplacementNamed(
                                  context,
                                  RcRoutes.houseCommand,
                                );
                              },
                              child: const Text('OPEN'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: <Widget>[
                            TextFormField(
                              controller: _code,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                labelText: 'House code',
                                hintText: 'Example: H21',
                                prefixIcon: Icon(Icons.home_work_outlined),
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                      ? 'Enter a house code.'
                                      : null,
                            ),
                            const SizedBox(height: 13),
                            TextFormField(
                              controller: _beneficiary,
                              decoration: const InputDecoration(
                                labelText: 'Beneficiary name',
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                      ? 'Enter the beneficiary name.'
                                      : null,
                            ),
                            const SizedBox(height: 13),
                            DropdownButtonFormField<String>(
                              value: _parish,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Parish',
                              ),
                              items: const <String>[
                                'Hanover',
                                'St. Elizabeth',
                                'Westmoreland',
                                'St. James',
                              ]
                                  .map(
                                    (item) => DropdownMenuItem<String>(
                                      value: item,
                                      child: Text(
                                        item,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _parish = value ?? _parish),
                            ),
                            const SizedBox(height: 13),
                            TextFormField(
                              controller: _community,
                              decoration: const InputDecoration(
                                labelText: 'Community / Village',
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                      ? 'Enter the community.'
                                      : null,
                            ),
                            const SizedBox(height: 13),
                            TextFormField(
                              controller: _cluster,
                              decoration: const InputDecoration(
                                labelText: 'Cluster',
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                      ? 'Enter the cluster.'
                                      : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _create,
                      icon: const Icon(Icons.add_home_work_outlined),
                      label: const Text('CREATE & START SCOPE'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SiteVisitsScreen extends StatelessWidget {
  const SiteVisitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final house = state.selectedHouse;
    final visits = state.activities
        .where(
          (entry) =>
              entry.houseCode == house.code &&
              entry.title.toLowerCase().contains('visit'),
        )
        .toList();
    return Scaffold(
      appBar: RcAppBar(title: const Text('Site Visits')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, RcRoutes.siteVisitDetail),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('NEW VISIT'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  RcPageHeading(
                    eyebrow: '${house.code} / Delivery',
                    title: 'Site visits',
                    description:
                        'Technical visits and beneficiary calls remain linked to delivery progress and evidence.',
                    action: const RcStatusChip(
                      label: 'FIELD READY',
                      tone: RcStatusTone.success,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (visits.isEmpty)
                    RcEmptyState(
                      icon: Icons.location_on_outlined,
                      title: 'No site visits recorded',
                      message:
                          'Create the first visit. Existing house data is safe.',
                      action: FilledButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          RcRoutes.siteVisitDetail,
                        ),
                        child: const Text('CREATE VISIT'),
                      ),
                    )
                  else
                    Card(
                      child: Column(
                        children: visits.map((visit) {
                          return ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.location_on_outlined),
                            ),
                            title: Text(visit.title),
                            subtitle: Text('${visit.detail}\n${visit.actor}'),
                            isThreeLine: true,
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.pushNamed(
                              context,
                              RcRoutes.siteVisitDetail,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SiteVisitDetailScreen extends StatefulWidget {
  const SiteVisitDetailScreen({super.key});

  @override
  State<SiteVisitDetailScreen> createState() => _SiteVisitDetailScreenState();
}

class _SiteVisitDetailScreenState extends State<SiteVisitDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _participants = TextEditingController(text: 'Sarah Jenkins, Mike Ross');
  final _comments = TextEditingController();
  String _type = 'Visit';
  String _status = 'On Track';
  double _completion = 65;
  double _workDays = 3;
  double _daysActive = 14;

  @override
  void dispose() {
    _participants.dispose();
    _comments.dispose();
    super.dispose();
  }

  void _save(bool submit) {
    if (!_formKey.currentState!.validate()) return;
    final state = AppScope.of(context);
    state.saveForm(
      type: 'Site Visit',
      houseCode: state.selectedHouseCode,
      values: <String, String>{
        'date': DateTime.now().toIso8601String().split('T').first,
        'type': _type,
        'participants': _participants.text.trim(),
        'completion': _completion.toStringAsFixed(0),
        'status': _status,
        'workDays': _workDays.toStringAsFixed(0),
        'daysActive': _daysActive.toStringAsFixed(0),
        'comments': _comments.text.trim(),
      },
      submit: submit,
    );
    showSavedMessage(context, submitted: submit);
  }

  @override
  Widget build(BuildContext context) {
    final house = AppScope.of(context).selectedHouse;
    return Scaffold(
      appBar: RcAppBar(title: Text('${house.code} • Site Visit')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
          children: <Widget>[
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    RcPageHeading(
                      eyebrow: '${house.code} / Delivery',
                      title: 'Site visit',
                      description:
                          'Record details for field delivery operations.',
                    ),
                    const SizedBox(height: 18),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            SegmentedButton<String>(
                              segments: const <ButtonSegment<String>>[
                                ButtonSegment<String>(
                                  value: 'Visit',
                                  label: Text('Visit'),
                                  icon: Icon(Icons.location_on_outlined),
                                ),
                                ButtonSegment<String>(
                                  value: 'Call',
                                  label: Text('Call'),
                                  icon: Icon(Icons.call_outlined),
                                ),
                              ],
                              selected: <String>{_type},
                              onSelectionChanged: (selection) =>
                                  setState(() => _type = selection.first),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _participants,
                              decoration: const InputDecoration(
                                labelText: 'Technical Team Participants',
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                      ? 'Enter at least one participant.'
                                      : null,
                            ),
                            const SizedBox(height: 14),
                            _LabeledSlider(
                              label: 'Estimated completion',
                              value: _completion,
                              min: 0,
                              max: 100,
                              suffix: '%',
                              onChanged: (value) =>
                                  setState(() => _completion = value),
                            ),
                            DropdownButtonFormField<String>(
                              value: _status,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                              ),
                              items: const <String>[
                                'On Track',
                                'Attention',
                                'Delayed',
                                'Paused',
                                'Complete',
                              ]
                                  .map(
                                    (item) => DropdownMenuItem<String>(
                                      value: item,
                                      child: Text(
                                        item,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _status = value ?? _status),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: _NumberStepper(
                                    label: 'Work days',
                                    value: _workDays,
                                    onChanged: (value) =>
                                        setState(() => _workDays = value),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _NumberStepper(
                                    label: 'Days active',
                                    value: _daysActive,
                                    onChanged: (value) =>
                                        setState(() => _daysActive = value),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _comments,
                              minLines: 4,
                              maxLines: 6,
                              decoration: const InputDecoration(
                                labelText: 'Issues / Comments',
                                alignLabelWithHint: true,
                              ),
                            ),
                            const SizedBox(height: 14),
                            OutlinedButton.icon(
                              onPressed: () => Navigator.pushNamed(
                                context,
                                RcRoutes.evidence,
                              ),
                              icon: const Icon(Icons.add_a_photo_outlined),
                              label: const Text('ATTACH FIELD EVIDENCE'),
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
      bottomSheet: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(12),
          color: Theme.of(context).colorScheme.surface,
          child: Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _save(false),
                  child: const Text('SAVE DRAFT'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => _save(true),
                  child: const Text('SUBMIT VISIT'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  const _LabeledSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.suffix,
    required this.onChanged,
  });
  final String label;
  final double value;
  final double min;
  final double max;
  final String suffix;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${value.round()}$suffix',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).round(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _NumberStepper extends StatelessWidget {
  const _NumberStepper({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: value <= 0 ? null : () => onChanged(value - 1),
            icon: const Icon(Icons.remove),
          ),
          Expanded(
            child: Text(
              '${value.round()}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          IconButton(
            onPressed: () => onChanged(value + 1),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  InventoryTier _tier = InventoryTier.parish;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final ledger = state.inventoryFor(
      tier: _tier,
      parish: state.selectedParish,
      houseCode:
          _tier == InventoryTier.house ? state.selectedHouseCode : null,
    );
    final shortages = ledger
        .where((item) => item.health != InventoryHealth.healthy)
        .length;
    final totalValue =
        ledger.fold<double>(0, (sum, item) => sum + item.stockValueJmd);
    return Scaffold(
      appBar: RcAppBar(title: Text('${state.selectedParish} • Inventory')),
      body: Column(
        children: <Widget>[
          const RcSyncBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
              children: <Widget>[
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1050),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        RcPageHeading(
                          eyebrow: '${state.selectedParish} / Logistics',
                          title: 'Live inventory',
                          description:
                              'See each material at parish depot, cluster store and house level, then reconcile or transfer stock without losing the audit trail.',
                          action: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.end,
                            children: <Widget>[
                              OutlinedButton.icon(
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  RcRoutes.inventoryTransfer,
                                ),
                                icon: const Icon(Icons.swap_horiz_outlined),
                                label: const Text('TRANSFER'),
                              ),
                              FilledButton.icon(
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  RcRoutes.addInventory,
                                ),
                                icon: const Icon(Icons.add),
                                label: const Text('ADD RECORD'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        RcResponsiveGrid(
                          minItemWidth: 160,
                          childAspectRatio: 1.05,
                          children: <Widget>[
                            RcMetricTile(
                              label: 'Material lines',
                              value: '${ledger.length}',
                              icon: Icons.inventory_2_outlined,
                              color: RcColors.info,
                            ),
                            RcMetricTile(
                              label: 'Low / critical lines',
                              value: '$shortages',
                              icon: Icons.warning_amber_rounded,
                              color: RcColors.warning,
                            ),
                            RcMetricTile(
                              label: 'Stock value',
                              value: _compactJmd(totalValue),
                              icon: Icons.account_balance_wallet_outlined,
                              color: RcColors.success,
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SegmentedButton<InventoryTier>(
                            segments: InventoryTier.values
                                .map(
                                  (tier) => ButtonSegment<InventoryTier>(
                                    value: tier,
                                    icon: Icon(
                                      switch (tier) {
                                        InventoryTier.parish =>
                                          Icons.warehouse_outlined,
                                        InventoryTier.cluster =>
                                          Icons.hub_outlined,
                                        InventoryTier.house =>
                                          Icons.home_work_outlined,
                                      },
                                    ),
                                    label: Text(tier.label.toUpperCase()),
                                  ),
                                )
                                .toList(),
                            selected: <InventoryTier>{_tier},
                            onSelectionChanged: (value) =>
                                setState(() => _tier = value.first),
                          ),
                        ),
                        const SizedBox(height: 20),
                        RcSectionHeader(
                          title: '${_tier.label} ledger',
                          subtitle: _tier == InventoryTier.house
                              ? '${state.selectedHouseCode} • received, consumed and remaining'
                              : '${state.selectedParish} • live quantities and storage zones',
                          trailing: RcStatusChip(
                            label: '$shortages ATTENTION',
                            tone: shortages > 0
                                ? RcStatusTone.warning
                                : RcStatusTone.success,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (ledger.isEmpty)
                          const RcEmptyState(
                            icon: Icons.inventory_2_outlined,
                            title: 'No stock lines at this level',
                            message:
                                'Choose another inventory level or record the first allocation.',
                          )
                        else
                          for (final item in ledger) ...<Widget>[
                            _StockLedgerCard(item: item),
                            const SizedBox(height: 10),
                          ],
                        const SizedBox(height: 14),
                        const RcSectionHeader(
                          title: 'Material catalog',
                          subtitle:
                              'House BOQ reconciliation retained for delivery audit',
                        ),
                        const SizedBox(height: 10),
                        for (final item in state.inventory) ...<Widget>[
                          _InventoryCard(item: item),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, RcRoutes.addInventory),
        icon: const Icon(Icons.sync),
        label: const Text('SYNC / RECONCILE'),
      ),
    );
  }
}

class _StockLedgerCard extends StatelessWidget {
  const _StockLedgerCard({required this.item});

  final StockLedgerItem item;

  @override
  Widget build(BuildContext context) {
    final color = switch (item.health) {
      InventoryHealth.healthy => RcColors.success,
      InventoryHealth.low => RcColors.warning,
      InventoryHealth.critical || InventoryHealth.outOfStock => RcColors.brand,
    };
    final tone = switch (item.health) {
      InventoryHealth.healthy => RcStatusTone.success,
      InventoryHealth.low => RcStatusTone.warning,
      InventoryHealth.critical || InventoryHealth.outOfStock =>
        RcStatusTone.error,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(.12),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(10),
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(18),
                    ),
                  ),
                  child: Icon(Icons.inventory_2_outlined, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(item.name,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 3),
                      Text(
                        '${item.materialCode} • ${item.location}${item.zone.isEmpty ? '' : ' • ${item.zone}'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                RcStatusChip(
                  label: item.health.label.toUpperCase(),
                  tone: tone,
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 22,
              runSpacing: 10,
              children: <Widget>[
                _InventoryFact(
                  label: 'On hand',
                  value: item.onHand,
                  unit: item.unit,
                ),
                _InventoryFact(
                  label: 'Received',
                  value: item.received,
                  unit: item.unit,
                ),
                _InventoryFact(
                  label: 'Issued / used',
                  value: item.issued,
                  unit: item.unit,
                ),
                _InventoryFact(
                  label: 'Minimum',
                  value: item.minimumStock,
                  unit: item.unit,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Icon(
                  item.liveSynced
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_off_outlined,
                  size: 17,
                  color: item.liveSynced ? RcColors.success : RcColors.warning,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.liveSynced
                        ? 'Live ledger synchronized'
                        : 'Saved on device • waiting to sync',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _editLedger(context),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('RECONCILE'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editLedger(BuildContext context) async {
    final received =
        TextEditingController(text: item.received.toStringAsFixed(0));
    final issued = TextEditingController(text: item.issued.toStringAsFixed(0));
    final adjustments =
        TextEditingController(text: item.adjustments.toStringAsFixed(0));
    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Reconcile ${item.materialCode}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: received,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Total received'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: issued,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(labelText: 'Total issued / used'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: adjustments,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(labelText: 'Stock adjustment'),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
    if (save == true && context.mounted) {
      AppScope.of(context).updateStockLedger(
        id: item.id,
        received: double.tryParse(received.text) ?? item.received,
        issued: double.tryParse(issued.text) ?? item.issued,
        adjustments: double.tryParse(adjustments.text) ?? item.adjustments,
      );
      showSavedMessage(context, submitted: false);
    }
    received.dispose();
    issued.dispose();
    adjustments.dispose();
  }
}

String _compactJmd(double value) {
  if (value >= 1000000) return 'JMD ${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return 'JMD ${(value / 1000).toStringAsFixed(0)}K';
  return 'JMD ${value.toStringAsFixed(0)}';
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({required this.item});
  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final shortage = item.variance > 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                RcStatusChip(
                  label: shortage
                      ? '${item.variance.toStringAsFixed(0)} SHORT'
                      : 'AVAILABLE',
                  tone: shortage ? RcStatusTone.warning : RcStatusTone.success,
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              item.location,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 18,
              runSpacing: 10,
              children: <Widget>[
                _InventoryFact(label: 'BOQ', value: item.boq, unit: item.unit),
                _InventoryFact(
                  label: 'Delivered',
                  value: item.delivered,
                  unit: item.unit,
                ),
                _InventoryFact(
                  label: 'Additions',
                  value: item.additions,
                  unit: item.unit,
                ),
                _InventoryFact(
                  label: 'Leftovers',
                  value: item.leftovers,
                  unit: item.unit,
                ),
                _InventoryFact(
                  label: 'Used',
                  value: item.used,
                  unit: item.unit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryFact extends StatelessWidget {
  const _InventoryFact({
    required this.label,
    required this.value,
    required this.unit,
  });
  final String label;
  final double value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 108,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Text(
            '${value.toStringAsFixed(0)} $unit',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class InventoryEditScreen extends StatefulWidget {
  const InventoryEditScreen({super.key});

  @override
  State<InventoryEditScreen> createState() => _InventoryEditScreenState();
}

class _InventoryEditScreenState extends State<InventoryEditScreen> {
  String? _itemName;
  final _delivered = TextEditingController();
  final _additions = TextEditingController();
  final _leftovers = TextEditingController();

  @override
  void dispose() {
    _delivered.dispose();
    _additions.dispose();
    _leftovers.dispose();
    super.dispose();
  }

  void _select(InventoryItem item) {
    setState(() {
      _itemName = item.name;
      _delivered.text = item.delivered.toStringAsFixed(0);
      _additions.text = item.additions.toStringAsFixed(0);
      _leftovers.text = item.leftovers.toStringAsFixed(0);
    });
  }

  void _save() {
    if (_itemName == null) return;
    AppScope.of(context).updateInventory(
      itemName: _itemName!,
      delivered: double.tryParse(_delivered.text) ?? 0,
      additions: double.tryParse(_additions.text) ?? 0,
      leftovers: double.tryParse(_leftovers.text) ?? 0,
    );
    showSavedMessage(context, submitted: false);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: RcAppBar(title: const Text('Inventory Record')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const RcPageHeading(
                    eyebrow: 'Logistics / Reconciliation',
                    title: 'Update inventory',
                    description:
                        'Changes update the house activity and offline sync queue.',
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    value: _itemName,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Material item',
                    ),
                    items: state.inventory
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item.name,
                            child: Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null)
                        _select(
                          state.inventory.firstWhere(
                            (item) => item.name == value,
                          ),
                        );
                    },
                  ),
                  const SizedBox(height: 13),
                  TextField(
                    controller: _delivered,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Delivered quantity',
                    ),
                  ),
                  const SizedBox(height: 13),
                  TextField(
                    controller: _additions,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Additional quantity',
                    ),
                  ),
                  const SizedBox(height: 13),
                  TextField(
                    controller: _leftovers,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Leftovers'),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _itemName == null ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('SAVE RECONCILIATION'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CompletionScreen extends StatefulWidget {
  const CompletionScreen({super.key});

  @override
  State<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends State<CompletionScreen> {
  bool _datesVerified = true;
  bool _inspectionComplete = false;
  bool _beneficiarySigned = false;
  bool _representativeSigned = false;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final house = state.selectedHouse;
    final documents = state.completedDocuments[house.code]?.length ?? 0;
    final ready = _datesVerified &&
        _inspectionComplete &&
        _beneficiarySigned &&
        _representativeSigned &&
        house.evidenceReady;
    return Scaffold(
      appBar: RcAppBar(title: Text('${house.code} • Notice of Completion')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
        children: <Widget>[
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 780),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  RcPageHeading(
                    eyebrow: '${house.code} / Close-out',
                    title: 'Project close-out',
                    description:
                        'A controlled readiness gate for completion evidence, technical approval and acknowledgements.',
                    action: RcStatusChip(
                      label: ready ? 'READY TO SUBMIT' : 'NOT READY',
                      tone: ready ? RcStatusTone.success : RcStatusTone.warning,
                    ),
                  ),
                  const SizedBox(height: 18),
                  RcResponsiveGrid(
                    minItemWidth: 160,
                    childAspectRatio: 1.05,
                    children: <Widget>[
                      RcMetricTile(
                        label: 'Evidence',
                        value:
                            '${house.evidenceComplete}/${house.evidenceRequired}',
                        icon: Icons.photo_library_outlined,
                        color: house.evidenceReady
                            ? RcColors.success
                            : RcColors.warning,
                        onTap: () =>
                            Navigator.pushNamed(context, RcRoutes.evidence),
                      ),
                      RcMetricTile(
                        label: 'Documents',
                        value: '$documents/7',
                        icon: Icons.description_outlined,
                        color: RcColors.info,
                        onTap: () => Navigator.pushNamed(
                          context,
                          RcRoutes.documentChecklist,
                        ),
                      ),
                      RcMetricTile(
                        label: 'Production',
                        value: '${(house.progress * 100).round()}%',
                        icon: Icons.construction_outlined,
                        color: RcColors.brand,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: <Widget>[
                          _ReadinessCheck(
                            title: 'Timeline verification',
                            subtitle:
                                'Working dates and approved extension are recorded.',
                            value: _datesVerified,
                            onChanged: (value) =>
                                setState(() => _datesVerified = value),
                          ),
                          const Divider(),
                          _ReadinessCheck(
                            title: 'Final technical inspection',
                            subtitle:
                                'All safety and workmanship criteria passed.',
                            value: _inspectionComplete,
                            onChanged: (value) =>
                                setState(() => _inspectionComplete = value),
                            action: TextButton(
                              onPressed: () => Navigator.pushNamed(
                                context,
                                RcRoutes.finalInspection,
                              ),
                              child: const Text('OPEN'),
                            ),
                          ),
                          const Divider(),
                          _ReadinessCheck(
                            title: 'Beneficiary acknowledgement',
                            subtitle:
                                'Beneficiary accepts the completed roof repair.',
                            value: _beneficiarySigned,
                            onChanged: (value) =>
                                setState(() => _beneficiarySigned = value),
                          ),
                          const Divider(),
                          _ReadinessCheck(
                            title: 'Red Cross representative sign-off',
                            subtitle: 'Authorized representative has signed.',
                            value: _representativeSigned,
                            onChanged: (value) =>
                                setState(() => _representativeSigned = value),
                          ),
                          const Divider(),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              house.evidenceReady
                                  ? Icons.check_circle
                                  : Icons.warning_amber,
                              color: house.evidenceReady
                                  ? RcColors.success
                                  : RcColors.warning,
                            ),
                            title: const Text(
                              'Required evidence',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              house.evidenceReady
                                  ? 'All evidence classes are complete.'
                                  : '${house.evidenceRequired - house.evidenceComplete} required items are missing.',
                            ),
                            trailing: TextButton(
                              onPressed: () => Navigator.pushNamed(
                                context,
                                RcRoutes.evidence,
                              ),
                              child: const Text('VIEW'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: ready
                        ? () {
                            state.submitCompletion(house.code);
                            showSavedMessage(context, submitted: true);
                          }
                        : null,
                    icon: const Icon(Icons.send_outlined),
                    label: const Text('SUBMIT COMPLETION'),
                  ),
                  if (!ready) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      'Complete every readiness item to enable submission. Your draft remains safe.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadinessCheck extends StatelessWidget {
  const _ReadinessCheck({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.action,
  });
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Checkbox(value: value, onChanged: (next) => onChanged(next ?? false)),
        const SizedBox(width: 4),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class FinalInspectionScreen extends StatefulWidget {
  const FinalInspectionScreen({super.key});

  @override
  State<FinalInspectionScreen> createState() => _FinalInspectionScreenState();
}

class _FinalInspectionScreenState extends State<FinalInspectionScreen> {
  final Map<String, bool> _checks = <String, bool>{
    'Structural timber and connections': false,
    'Roof angle and drainage': false,
    'Zinc, ridge cap and flashing': false,
    'Hurricane straps and fasteners': false,
    'Fascia, overhang and gutters': false,
    'Site cleared and safe': false,
  };

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final house = state.selectedHouse;
    final passed = _checks.values.where((value) => value).length;
    final complete = passed == _checks.length;
    return Scaffold(
      appBar: RcAppBar(title: Text('${house.code} • Final Inspection')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  RcPageHeading(
                    eyebrow: '${house.code} / Quality',
                    title: 'Final technical inspection',
                    description:
                        'Verify the completed roof before close-out can proceed.',
                    action: RcStatusChip(
                      label: '$passed/${_checks.length} PASSED',
                      tone: complete
                          ? RcStatusTone.success
                          : RcStatusTone.warning,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Card(
                    child: Column(
                      children: _checks.entries.map((entry) {
                        return CheckboxListTile(
                          value: entry.value,
                          title: Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            entry.value ? 'Verified' : 'Inspection required',
                          ),
                          secondary: Icon(
                            entry.value
                                ? Icons.verified_outlined
                                : Icons.rule_outlined,
                            color: entry.value
                                ? RcColors.success
                                : RcColors.warning,
                          ),
                          onChanged: (value) => setState(
                            () => _checks[entry.key] = value ?? false,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, RcRoutes.evidence),
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: const Text('ADD FINAL INSPECTION EVIDENCE'),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: complete
                        ? () {
                            state.saveForm(
                              type: 'Final Inspection',
                              houseCode: house.code,
                              values: <String, String>{
                                for (final entry in _checks.entries)
                                  entry.key: entry.value ? 'Pass' : 'Fail',
                              },
                              submit: true,
                            );
                            showSavedMessage(context, submitted: true);
                          }
                        : null,
                    icon: const Icon(Icons.verified_outlined),
                    label: const Text('APPROVE FINAL INSPECTION'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final house = state.selectedHouse;
    final squares = house.roofArea / 100;
    final base = squares * 23000;
    const demolition = 12000.0;
    const additional = 6500.0;
    final total = base + demolition + additional;
    final ready = house.progress >= .9 && house.evidenceReady;
    return Scaffold(
      appBar: RcAppBar(title: Text('${house.code} • Payment')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
        children: <Widget>[
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  RcPageHeading(
                    eyebrow: '${house.code} / Finance',
                    title: 'Payment submission',
                    description:
                        'Review readiness, allocation, approval chain and finance state.',
                    action: RcStatusChip(
                      label: ready ? 'READY' : 'NOT READY',
                      tone: ready ? RcStatusTone.success : RcStatusTone.warning,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const RcSectionHeader(title: 'Project information'),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 26,
                            runSpacing: 12,
                            children: <Widget>[
                              _PaymentFact(label: 'Project', value: house.code),
                              _PaymentFact(
                                label: 'Beneficiary',
                                value: house.beneficiary,
                              ),
                              _PaymentFact(
                                label: 'Parish',
                                value: house.parish,
                              ),
                              _PaymentFact(
                                label: 'Cluster',
                                value: house.cluster,
                              ),
                              _PaymentFact(
                                label: 'Roof area',
                                value:
                                    '${house.roofArea.toStringAsFixed(0)} sq ft',
                              ),
                              _PaymentFact(
                                label: 'Rate',
                                value: 'JMD 23,000 / square',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const RcSectionHeader(title: 'Financial summary'),
                          const SizedBox(height: 12),
                          _MoneyRow(
                            label:
                                'Roof labour (${squares.toStringAsFixed(2)} squares)',
                            value: base,
                          ),
                          const _MoneyRow(
                            label: 'Demolition',
                            value: demolition,
                          ),
                          const _MoneyRow(
                            label: 'Additional work',
                            value: additional,
                          ),
                          const Divider(height: 28),
                          _MoneyRow(
                            label: 'Total gross',
                            value: total,
                            emphasized: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const RcSectionHeader(
                            title: 'Team allocation',
                            subtitle:
                                'Carpenter 46% • Worker 31% • Apprentice 23%',
                          ),
                          const SizedBox(height: 14),
                          _AllocationBar(
                            label: 'Carpenter',
                            percent: .46,
                            value: total * .46,
                            color: RcColors.brand,
                          ),
                          const SizedBox(height: 12),
                          _AllocationBar(
                            label: 'Worker',
                            percent: .31,
                            value: total * .31,
                            color: RcColors.info,
                          ),
                          const SizedBox(height: 12),
                          _AllocationBar(
                            label: 'Apprentice',
                            percent: .23,
                            value: total * .23,
                            color: RcColors.success,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Column(
                      children: <Widget>[
                        _ApprovalTile(
                          title: 'Site Supervisor',
                          state: 'Verified',
                          complete: true,
                        ),
                        const Divider(height: 1),
                        _ApprovalTile(
                          title: 'Regional Supervisor',
                          state: ready
                              ? 'Ready for review'
                              : 'Waiting for readiness',
                          complete: false,
                        ),
                        const Divider(height: 1),
                        const _ApprovalTile(
                          title: 'Finance Officer',
                          state: 'Not started',
                          complete: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: ready
                        ? () {
                            state.submitPayment(house.code);
                            showSavedMessage(context, submitted: true);
                          }
                        : null,
                    icon: const Icon(Icons.send_outlined),
                    label: Text(ready ? 'SUBMIT PAYMENT' : 'PAYMENT NOT READY'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentFact extends StatelessWidget {
  const _PaymentFact({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 175,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });
  final String label;
  final double value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: emphasized ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
          Text(
            'JMD ${value.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: emphasized ? 20 : 15,
              fontWeight: FontWeight.w900,
              color: emphasized ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _AllocationBar extends StatelessWidget {
  const _AllocationBar({
    required this.label,
    required this.percent,
    required this.value,
    required this.color,
  });
  final String label;
  final double percent;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                '$label • ${(percent * 100).round()}%',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              'JMD ${value.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: percent,
          minHeight: 8,
          color: color,
          borderRadius: BorderRadius.circular(99),
        ),
      ],
    );
  }
}

class _ApprovalTile extends StatelessWidget {
  const _ApprovalTile({
    required this.title,
    required this.state,
    required this.complete,
  });
  final String title;
  final String state;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        complete ? Icons.check_circle : Icons.schedule,
        color: complete ? RcColors.success : RcColors.warning,
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(state),
    );
  }
}

class EvidenceScreen extends StatelessWidget {
  const EvidenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final house = state.selectedHouse;
    final items =
        state.evidence.where((item) => item.houseCode == house.code).toList();
    return Scaffold(
      appBar: RcAppBar(title: Text('${house.code} • Evidence Viewer')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  RcPageHeading(
                    eyebrow: '${house.code} / Evidence',
                    title: 'Inspection gallery',
                    description:
                        'Classified photos and documents preserve source, timestamp, approval and house context.',
                    action: RcStatusChip(
                      label:
                          '${house.evidenceComplete}/${house.evidenceRequired} COMPLETE',
                      tone: house.evidenceReady
                          ? RcStatusTone.success
                          : RcStatusTone.warning,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (items.isEmpty)
                    const RcEmptyState(
                      icon: Icons.photo_library_outlined,
                      title: 'No evidence yet',
                      message:
                          'Capture a classified item from Scope Files or a field form.',
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final count = (constraints.maxWidth / 260)
                            .floor()
                            .clamp(1, 3)
                            .toInt();
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: count,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: .92,
                          ),
                          itemCount: items.length,
                          itemBuilder: (context, index) =>
                              _EvidenceCard(item: items[index]),
                        );
                      },
                    ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () => _showCaptureDialog(context),
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: const Text('CAPTURE / ADD EVIDENCE'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCaptureDialog(BuildContext context) {
    String caption = '';
    String selectedType = 'During';
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Capture evidence'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DropdownButtonFormField<String>(
                value: selectedType,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Classification'),
                items: const <String>[
                  'Before',
                  'During',
                  'After',
                  'Delivery',
                  'Defect',
                  'Completion',
                  'Document',
                ]
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(
                          item,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setDialogState(() => selectedType = value ?? selectedType),
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: (value) => caption = value,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              onPressed: () {
                final description = caption.trim();
                if (description.isEmpty) return;
                AppScope.of(
                  context,
                ).addEvidence(type: selectedType, caption: description);
                Navigator.pop(dialogContext);
                showSavedMessage(context, submitted: false);
              },
              child: const Text('SAVE ON DEVICE'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  const _EvidenceCard({required this.item});
  final EvidenceItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                item.type == 'Document'
                    ? Icons.picture_as_pdf_outlined
                    : Icons.roofing_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary.withOpacity(.65),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    RcStatusChip(
                      label: item.type.toUpperCase(),
                      compact: true,
                      tone: RcStatusTone.info,
                    ),
                    const Spacer(),
                    Icon(
                      item.approved ? Icons.verified : Icons.schedule,
                      size: 18,
                      color:
                          item.approved ? RcColors.success : RcColors.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  item.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  item.capturedBy,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final house = state.selectedHouse;
    final items = state.activities
        .where((entry) => entry.houseCode == house.code)
        .toList();
    return Scaffold(
      appBar: RcAppBar(title: Text('${house.code} • Activity History')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  RcPageHeading(
                    eyebrow: '${house.code} / Audit',
                    title: 'Traceability thread',
                    description:
                        'Every saved field action, evidence item, approval and sync state remains human-readable.',
                  ),
                  const SizedBox(height: 20),
                  if (items.isEmpty)
                    const RcEmptyState(
                      icon: Icons.history,
                      title: 'No activity recorded',
                      message:
                          'Saving a connected form will create the first event.',
                    )
                  else
                    for (var index = 0; index < items.length; index++)
                      _ActivityTimelineItem(
                        item: items[index],
                        last: index == items.length - 1,
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTimelineItem extends StatelessWidget {
  const _ActivityTimelineItem({required this.item, required this.last});
  final ActivityEntry item;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 46,
          child: Column(
            children: <Widget>[
              CircleAvatar(radius: 20, child: Icon(item.icon, size: 19)),
              if (!last)
                Container(
                  width: 2,
                  height: 92,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 20),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 5),
                    Text(item.detail),
                    const SizedBox(height: 9),
                    Text(
                      '${item.actor} • ${_relativeTime(item.time)}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _relativeTime(DateTime time) {
  final difference = DateTime.now().difference(time);
  if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
  if (difference.inHours < 24) return '${difference.inHours}h ago';
  return '${difference.inDays}d ago';
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _unreadOnly = false;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final items = state.notifications
        .where((item) => !_unreadOnly || !item.read)
        .toList();
    return Scaffold(
      appBar: RcAppBar(
        title: const Text('Operational Notifications'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Send notification',
            onPressed: () =>
                Navigator.pushNamed(context, RcRoutes.notificationCompose),
            icon: const Icon(Icons.add_alert_outlined),
          ),
          IconButton(
            tooltip: _unreadOnly ? 'Show all' : 'Unread only',
            onPressed: () => setState(() => _unreadOnly = !_unreadOnly),
            icon: Icon(
              _unreadOnly ? Icons.filter_alt : Icons.filter_alt_outlined,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  RcPageHeading(
                    eyebrow: 'Alert Center',
                    title: _unreadOnly
                        ? 'Unread notifications'
                        : 'Operational notifications',
                    description:
                        'Priority, house context and next action remain visible without exposing raw system errors.',
                    action: RcStatusChip(
                      label: '${state.unreadNotifications} UNREAD',
                      tone: state.unreadNotifications > 0
                          ? RcStatusTone.brand
                          : RcStatusTone.success,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (items.isEmpty)
                    const RcEmptyState(
                      icon: Icons.notifications_none,
                      title: 'Nothing waiting',
                      message: 'There are no unread operational alerts.',
                    )
                  else
                    Card(
                      child: Column(
                        children: items.map((item) {
                          final tone = item.priority == 'High'
                              ? RcStatusTone.error
                              : item.priority == 'Action'
                                  ? RcStatusTone.warning
                                  : RcStatusTone.info;
                          return ListTile(
                            minVerticalPadding: 13,
                            leading: CircleAvatar(
                              backgroundColor: item.read
                                  ? Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest
                                  : Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                              child: Icon(
                                item.priority == 'High'
                                    ? Icons.warning_amber_rounded
                                    : Icons.notifications_outlined,
                                color: item.priority == 'High'
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            title: Text(
                              item.title,
                              style: TextStyle(
                                fontWeight: item.read
                                    ? FontWeight.w600
                                    : FontWeight.w900,
                              ),
                            ),
                            subtitle: Text(
                              '${item.detail}\n'
                              '${item.audiences.isEmpty ? '' : '${item.audiences.join(' • ')}\n'}'
                              '${_relativeTime(item.time)}',
                            ),
                            isThreeLine: true,
                            trailing: RcStatusChip(
                              label: item.priority.toUpperCase(),
                              compact: true,
                              tone: tone,
                            ),
                            onTap: () {
                              state.markNotificationRead(item.id);
                              if (item.houseCode != null) {
                                state.selectHouse(item.houseCode!);
                                Navigator.pushNamed(
                                  context,
                                  RcRoutes.houseCommand,
                                );
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UsersOnlineScreen extends StatelessWidget {
  const UsersOnlineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final online = state.team.where((person) => person.online).toList();
    final offline = state.team.where((person) => !person.online).toList();
    return Scaffold(
      appBar: RcAppBar(title: const Text('Users Online')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  RcPageHeading(
                    eyebrow: 'Collaboration',
                    title: '${online.length} users online',
                    description:
                        'Message the correct operational person without losing house context.',
                  ),
                  const SizedBox(height: 18),
                  Card(
                    child: Column(
                      children: online
                          .map((person) => _PersonTile(person: person))
                          .toList(),
                    ),
                  ),
                  if (offline.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 22),
                    const RcSectionHeader(title: 'Recently offline'),
                    const SizedBox(height: 10),
                    Card(
                      child: Column(
                        children: offline
                            .map((person) => _PersonTile(person: person))
                            .toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonTile extends StatelessWidget {
  const _PersonTile({required this.person});
  final TeamMember person;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minVerticalPadding: 11,
      leading: Stack(
        children: <Widget>[
          CircleAvatar(
            child: Text(
              person.name.split(' ').map((part) => part[0]).take(2).join(),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: person.online ? RcColors.success : Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
      title: Text(
        person.name,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text('${person.role} • ${person.parish}'),
      trailing: IconButton.filledTonal(
        tooltip: 'Message ${person.name}',
        onPressed: () => Navigator.pushNamed(context, RcRoutes.messages),
        icon: const Icon(Icons.message_outlined),
      ),
      onTap: () => _showProfile(context),
    );
  }

  void _showProfile(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CircleAvatar(
                radius: 34,
                child: Text(
                  person.name.split(' ').map((part) => part[0]).take(2).join(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(person.name, style: Theme.of(context).textTheme.titleLarge),
              Text('${person.role} • ${person.parish}'),
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, RcRoutes.messages);
                      },
                      icon: const Icon(Icons.message_outlined),
                      label: const Text('MESSAGE'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Call request prepared.'),
                        ),
                      ),
                      icon: const Icon(Icons.call_outlined),
                      label: const Text('CALL'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _controller = TextEditingController();
  final List<String> _sent = <String>[];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _sent.add(text);
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final house = state.selectedHouse;
    return Scaffold(
      appBar: RcAppBar(
        title: const Text('Operational Messages'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Archive',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Conversation archived.')),
            ),
            icon: const Icon(Icons.archive_outlined),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              children: <Widget>[
                const Icon(Icons.link),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Linked context: ${house.code} • ${house.beneficiary}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, RcRoutes.houseCommand),
                  child: const Text('OPEN'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              reverse: true,
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                for (final message in _sent.reversed)
                  _MessageBubble(text: message, mine: true, label: 'You • now'),
                if (_sent.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('No messages in this house thread yet.'),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: <Widget>[
                  IconButton.outlined(
                    onPressed: () =>
                        Navigator.pushNamed(context, RcRoutes.evidence),
                    icon: const Icon(Icons.attach_file),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        labelText: 'Reply',
                        hintText: 'Type an operational message…',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.text,
    required this.mine,
    required this.label,
  });
  final String text;
  final bool mine;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: mine
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 4),
            bottomRight: Radius.circular(mine ? 4 : 18),
          ),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(text),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: RcAppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  RcPageHeading(
                    eyebrow: state.role,
                    title: 'Settings & access',
                    description:
                        'Display, field resilience, accessibility and account controls.',
                    action: const RcStatusChip(
                      label: 'MATERIAL 3 • COMFORTABLE',
                      icon: Icons.palette_outlined,
                      tone: RcStatusTone.info,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const RcSectionHeader(title: 'Field experience'),
                  const SizedBox(height: 10),
                  Card(
                    child: Column(
                      children: <Widget>[
                        SwitchListTile(
                          value: state.offline,
                          onChanged: (_) => state.toggleOffline(),
                          secondary: const Icon(Icons.cloud_off_outlined),
                          title: const Text('Offline simulation'),
                          subtitle: const Text(
                            'Keep changes on device and queue synchronization.',
                          ),
                        ),
                        SwitchListTile(
                          value: state.reviewMode,
                          onChanged: (_) => state.toggleReviewMode(),
                          secondary: const Icon(
                            Icons.view_compact_alt_outlined,
                          ),
                          title: const Text('Review density'),
                          subtitle: const Text(
                            'Use denser tablet and management layouts.',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const RcSectionHeader(title: 'Appearance & accessibility'),
                  const SizedBox(height: 10),
                  Card(
                    child: Column(
                      children: <Widget>[
                        SwitchListTile(
                          value: state.darkMode,
                          onChanged: (_) => state.toggleDarkMode(),
                          secondary: const Icon(Icons.dark_mode_outlined),
                          title: const Text('Dark theme'),
                        ),
                        SwitchListTile(
                          value: state.highContrast,
                          onChanged: (_) => state.toggleHighContrast(),
                          secondary: const Icon(Icons.contrast),
                          title: const Text('High contrast'),
                        ),
                        SwitchListTile(
                          value: state.reducedMotion,
                          onChanged: (_) => state.toggleReducedMotion(),
                          secondary: const Icon(
                            Icons.motion_photos_off_outlined,
                          ),
                          title: const Text('Reduced motion'),
                          subtitle: const Text(
                            'Uses a shorter splash and restrained transitions.',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const RcSectionHeader(title: 'Account'),
                  const SizedBox(height: 10),
                  Card(
                    child: Column(
                      children: <Widget>[
                        ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                          title: Text(
                            state.role,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${state.role} • ${state.selectedParish}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => showModalBottomSheet<void>(
                            context: context,
                            showDragHandle: true,
                            builder: (sheetContext) => SafeArea(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 8, 20, 24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      state.role,
                                      style: Theme.of(sheetContext)
                                          .textTheme
                                          .headlineMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Text('${state.role} • ${state.selectedParish}'),
                                    const SizedBox(height: 16),
                                    RcStatusChip(
                                      label: state.backendConnectionLabel
                                          .toUpperCase(),
                                      icon: state.remoteConnected
                                          ? Icons.cloud_done_outlined
                                          : Icons.phone_android_outlined,
                                      tone: state.remoteConnected
                                          ? RcStatusTone.success
                                          : RcStatusTone.info,
                                    ),
                                    const SizedBox(height: 18),
                                    FilledButton.tonalIcon(
                                      onPressed: () {
                                        Navigator.pop(sheetContext);
                                        Navigator.pushNamed(
                                          context,
                                          RcRoutes.adminUsers,
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.manage_accounts_outlined,
                                      ),
                                      label: const Text('VIEW ACCESS PROFILE'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.security_outlined),
                          title: const Text('Permissions'),
                          subtitle: const Text(
                            'Field records, evidence, messages and assigned parish',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () =>
                              Navigator.pushNamed(context, RcRoutes.adminUsers),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: () {
                      state.logout();
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        RcRoutes.login,
                        (_) => false,
                      );
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('SIGN OUT'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WorkLogsScreen extends StatefulWidget {
  const WorkLogsScreen({super.key});

  @override
  State<WorkLogsScreen> createState() => _WorkLogsScreenState();
}

class _WorkLogsScreenState extends State<WorkLogsScreen> {
  final _detail = TextEditingController();
  final _hours = TextEditingController(text: '8');
  final _materials = TextEditingController();
  final _blocker = TextEditingController();
  final _nextAction = TextEditingController();
  String _category = 'Site monitoring';
  double _progress = 0;
  final Set<String> _crewPresent = <String>{};

  @override
  void dispose() {
    _detail.dispose();
    _hours.dispose();
    _materials.dispose();
    _blocker.dispose();
    _nextAction.dispose();
    super.dispose();
  }

  void _save() {
    if (_detail.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Describe the work completed.')),
      );
      return;
    }
    final state = AppScope.of(context);
    state.addWorkLog(
      houseCode: state.selectedHouseCode,
      category: _category,
      detail: _detail.text.trim(),
      hours: double.tryParse(_hours.text) ?? 0,
      progress: _progress,
      crewPresent: _crewPresent.toList(),
      materialsUsed: _materials.text.trim(),
      blocker: _blocker.text.trim(),
      nextAction: _nextAction.text.trim(),
    );
    _detail.clear();
    _materials.clear();
    _blocker.clear();
    _nextAction.clear();
    showSavedMessage(context, submitted: false);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: RcAppBar(title: const Text('Control of Work')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  RcPageHeading(
                    eyebrow: 'Fast Entry / Field Operations',
                    title: 'Control of work log',
                    description:
                        'Record who worked, what changed, measured progress, materials consumed, blockers and the next action for the house.',
                    action: OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        RcRoutes.workProjections,
                      ),
                      icon: const Icon(Icons.trending_up_outlined),
                      label: const Text('WEEKLY PROJECTION'),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          DropdownButtonFormField<String>(
                            value: state.selectedHouseCode,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Cluster / House',
                            ),
                            items: state.houses
                                .map(
                                  (house) => DropdownMenuItem<String>(
                                    value: house.code,
                                    child: Text(
                                      '${house.code} • ${house.cluster}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) state.selectHouse(value);
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _category,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Activity category',
                            ),
                            items: const <String>[
                              'Technical evaluation visit',
                              'Scope of Work preparation',
                              'Site monitoring',
                              'Materials and logistics',
                              'Tracker update',
                              'Project meeting',
                              'Administrative work',
                              'Beneficiary monitoring',
                              'Clearance visit',
                            ]
                                .map(
                                  (item) => DropdownMenuItem<String>(
                                    value: item,
                                    child: Text(
                                      item,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _category = value ?? _category),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _hours,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Daily work hours',
                            ),
                          ),
                          const SizedBox(height: 12),
                          InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Verified progress',
                              prefixIcon: Icon(Icons.percent),
                            ),
                            child: Column(
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        '${state.selectedHouseCode} completion',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge,
                                      ),
                                    ),
                                    Text(
                                      '${_progress.round()}%',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(color: RcColors.brand),
                                    ),
                                  ],
                                ),
                                Slider(
                                  value: _progress,
                                  min: 0,
                                  max: 100,
                                  divisions: 20,
                                  label: '${_progress.round()}%',
                                  onChanged: (value) =>
                                      setState(() => _progress = value),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Crew present',
                              alignLabelWithHint: true,
                            ),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: state.selectedHouse.team.map((name) {
                                return FilterChip(
                                  label: Text(name),
                                  selected: _crewPresent.contains(name),
                                  onSelected: (selected) => setState(() {
                                    if (selected) {
                                      _crewPresent.add(name);
                                    } else {
                                      _crewPresent.remove(name);
                                    }
                                  }),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _materials,
                            minLines: 2,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Materials consumed / needed',
                              alignLabelWithHint: true,
                              hintText:
                                  'Example: 8 zinc sheets used; 12 more required.',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _blocker,
                            minLines: 2,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Delay, issue or blocker',
                              alignLabelWithHint: true,
                              hintText: 'Leave blank when work is unblocked.',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _nextAction,
                            decoration: const InputDecoration(
                              labelText: 'Next action and owner',
                              prefixIcon: Icon(Icons.next_plan_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _detail,
                            minLines: 4,
                            maxLines: 7,
                            decoration: const InputDecoration(
                              labelText: 'Detailed work',
                              alignLabelWithHint: true,
                              hintText:
                                  'Describe visits, records, materials, blockers and decisions.',
                            ),
                          ),
                          const SizedBox(height: 14),
                          FilledButton.icon(
                            onPressed: _save,
                            icon: const Icon(Icons.save_outlined),
                            label: const Text('SAVE WORK LOG'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  RcSectionHeader(
                    title: 'Recent logs',
                    subtitle:
                        '${state.workLogs.fold<double>(0, (sum, log) => sum + log.hours).toStringAsFixed(1)} total hours recorded',
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: Column(
                      children: state.workLogs.map((log) {
                        return ListTile(
                          leading: CircleAvatar(child: Text(log.houseCode)),
                          title: Text(
                            log.category,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${log.detail}\n${log.user} • ${log.hours.toStringAsFixed(1)} hours • ${log.progress.toStringAsFixed(0)}% • ${_relativeTime(log.createdAt)}',
                          ),
                          isThreeLine: true,
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _parish = 'All';

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final houses = state.houses
        .where((house) => _parish == 'All' || house.parish == _parish)
        .toList();
    return Scaffold(
      appBar: RcAppBar(
        title: const Text('Production Database'),
        actions: <Widget>[
          TextButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Current filtered view exported.')),
            ),
            icon: const Icon(Icons.download_outlined),
            label: const Text('EXPORT'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const RcPageHeading(
                    eyebrow: 'Management Review',
                    title: 'Production analytics',
                    description:
                        'Operational review for throughput, evidence, visits, work hours, materials, completion and payment queues.',
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    value: _parish,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Parish filter',
                      prefixIcon: Icon(Icons.filter_alt_outlined),
                    ),
                    items: <String>{
                      'All',
                      ...state.houses.map((house) => house.parish),
                    }
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item,
                            child: Text(
                              item,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _parish = value ?? _parish),
                  ),
                  const SizedBox(height: 18),
                  RcResponsiveGrid(
                    minItemWidth: 160,
                    childAspectRatio: 1.05,
                    children: <Widget>[
                      RcMetricTile(
                        label: 'Houses',
                        value: '${houses.length}',
                        icon: Icons.holiday_village_outlined,
                        color: RcColors.brand,
                      ),
                      RcMetricTile(
                        label: 'Average progress',
                        value: houses.isEmpty
                            ? '0%'
                            : '${(houses.fold<double>(0, (sum, house) => sum + house.progress) / houses.length * 100).round()}%',
                        icon: Icons.trending_up,
                        color: RcColors.success,
                      ),
                      RcMetricTile(
                        label: 'Evidence readiness',
                        value: '${(state.evidenceReadiness * 100).round()}%',
                        icon: Icons.verified_outlined,
                        color: RcColors.info,
                      ),
                      RcMetricTile(
                        label: 'Work-log hours',
                        value: state.workLogs
                            .fold<double>(0, (sum, log) => sum + log.hours)
                            .toStringAsFixed(1),
                        icon: Icons.schedule_outlined,
                        color: RcColors.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cards = <Widget>[
                        _AnalyticsCard(
                          title: 'Lifecycle distribution',
                          child: _LifecycleBars(houses: houses),
                        ),
                        _AnalyticsCard(
                          title: 'Evidence readiness',
                          child: _EvidenceGauge(value: state.evidenceReadiness),
                        ),
                      ];
                      if (constraints.maxWidth >= 800) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(child: cards[0]),
                            const SizedBox(width: 14),
                            Expanded(child: cards[1]),
                          ],
                        );
                      }
                      return Column(
                        children: <Widget>[
                          cards[0],
                          const SizedBox(height: 14),
                          cards[1],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  const RcSectionHeader(
                    title: 'Production records',
                    subtitle: 'Current filtered operational view',
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const <DataColumn>[
                          DataColumn(label: Text('House')),
                          DataColumn(label: Text('Beneficiary')),
                          DataColumn(label: Text('Parish')),
                          DataColumn(label: Text('Phase')),
                          DataColumn(label: Text('Progress')),
                          DataColumn(label: Text('Evidence')),
                        ],
                        rows: houses.map((house) {
                          return DataRow(
                            onSelectChanged: (_) {
                              state.selectHouse(house.code);
                              Navigator.pushNamed(
                                context,
                                RcRoutes.houseCommand,
                              );
                            },
                            cells: <DataCell>[
                              DataCell(
                                Text(
                                  house.code,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              DataCell(Text(house.beneficiary)),
                              DataCell(Text(house.parish)),
                              DataCell(Text(house.phase.label)),
                              DataCell(
                                Text('${(house.progress * 100).round()}%'),
                              ),
                              DataCell(
                                Text(
                                  '${house.evidenceComplete}/${house.evidenceRequired}',
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _LifecycleBars extends StatelessWidget {
  const _LifecycleBars({required this.houses});
  final List<HouseRecord> houses;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: LifecyclePhase.values.map((phase) {
        final count = houses.where((house) => house.phase == phase).length;
        final value = houses.isEmpty ? 0.0 : count / houses.length;
        return Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 72,
                child: Text(
                  phase.label,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              Expanded(
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 9,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              SizedBox(
                width: 32,
                child: Text(
                  '$count',
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _EvidenceGauge extends StatelessWidget {
  const _EvidenceGauge({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          SizedBox(
            width: 180,
            height: 180,
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: 18,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '${(value * 100).round()}%',
                style: Theme.of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.primary),
              ),
              const Text(
                'evidence ready',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HouseGeoPoint {
  const _HouseGeoPoint({required this.house, required this.latitude, required this.longitude});
  final HouseRecord house;
  final double latitude;
  final double longitude;
}

_HouseGeoPoint? _houseGeoPoint(HouseRecord house) {
  final raw = house.gps.trim();
  if (raw.isEmpty) return null;
  final matches = RegExp(r'-?\d+(?:\.\d+)?').allMatches(raw).toList();
  if (matches.length < 2) return null;
  final lat = double.tryParse(matches[0].group(0)!);
  final lng = double.tryParse(matches[1].group(0)!);
  if (lat == null || lng == null || lat.abs() > 90 || lng.abs() > 180) {
    return null;
  }
  return _HouseGeoPoint(house: house, latitude: lat, longitude: lng);
}

class OperationalMapScreen extends StatefulWidget {
  const OperationalMapScreen({super.key});

  @override
  State<OperationalMapScreen> createState() => _OperationalMapScreenState();
}

class _OperationalMapScreenState extends State<OperationalMapScreen> {
  bool _tracking = true;
  DateTime _lastRefresh = DateTime.now();

  void _refresh() {
    setState(() => _lastRefresh = DateTime.now());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Latest permitted house positions loaded.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final points = state.houses
        .map(_houseGeoPoint)
        .whereType<_HouseGeoPoint>()
        .toList(growable: false);
    return Scaffold(
      appBar: RcAppBar(
        title: const Text('Beneficiary / House Map'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Refresh live positions',
            onPressed: _refresh,
            icon: const Icon(Icons.my_location_outlined),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: <Widget>[
              Positioned.fill(
                child: CustomPaint(
                  painter: _OperationalMapPainter(
                    colorScheme: Theme.of(context).colorScheme,
                    houses: state.houses,
                  ),
                ),
              ),
              for (final point in points)
                Builder(
                  builder: (context) {
                    final minLat = points.isEmpty
                        ? 0.0
                        : points.map((p) => p.latitude).reduce(math.min);
                    final maxLat = points.isEmpty
                        ? 1.0
                        : points.map((p) => p.latitude).reduce(math.max);
                    final minLng = points.isEmpty
                        ? 0.0
                        : points.map((p) => p.longitude).reduce(math.min);
                    final maxLng = points.isEmpty
                        ? 1.0
                        : points.map((p) => p.longitude).reduce(math.max);
                    final latSpan = math.max(.0001, maxLat - minLat);
                    final lngSpan = math.max(.0001, maxLng - minLng);
                    final x = .12 + ((point.longitude - minLng) / lngSpan) * .76;
                    final y = .82 - ((point.latitude - minLat) / latSpan) * .64;
                    return Positioned(
                      left: constraints.maxWidth * x - 24,
                      top: constraints.maxHeight * y - 24,
                      child: Semantics(
                        label:
                            '${point.house.code}, ${point.house.beneficiary}, ${point.house.community}',
                        button: true,
                        child: IconButton.filled(
                          tooltip: '${point.house.code} • ${point.house.beneficiary}',
                          style: IconButton.styleFrom(
                            backgroundColor: point.house.needsAttention
                                ? RcColors.warning
                                : RcColors.brand,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            state.selectHouse(point.house.code);
                            Navigator.pushNamed(context, RcRoutes.houseCommand);
                          },
                          icon: Text(
                            point.house.code,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              Positioned(
                left: 16,
                right: 16,
                top: 16,
                child: SafeArea(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: RcColors.infoSoft,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.radar_outlined,
                              color: RcColors.info,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  '${state.selectedParish} • ${points.length} GPS-linked houses',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  _tracking
                                      ? 'Live refresh on • ${_relativeTime(_lastRefresh)}'
                                      : 'Live refresh paused • last known positions shown',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _tracking,
                            onChanged: (value) =>
                                setState(() => _tracking = value),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 18,
                child: SafeArea(
                  top: false,
                  child: Card(
                    child: SizedBox(
                      height: 92,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.all(10),
                        itemCount: state.houses.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final house = state.houses[index];
                          return ActionChip(
                            avatar: const Icon(Icons.house_outlined, size: 18),
                            label: Text(
                              '${house.code} • ${house.beneficiary}\n'
                              '${house.gps.isEmpty ? 'GPS required' : house.community}',
                            ),
                            onPressed: () {
                              state.selectHouse(house.code);
                              Navigator.pushNamed(
                                context,
                                RcRoutes.houseCommand,
                              );
                            },
                          );
                        },
                      ),
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

class _OperationalMapPainter extends CustomPainter {
  const _OperationalMapPainter({
    required this.colorScheme,
    required this.houses,
  });
  final ColorScheme colorScheme;
  final List<HouseRecord> houses;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = colorScheme.surfaceContainerLow,
    );
    final road = Paint()
      ..color = colorScheme.outlineVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final minorRoad = Paint()
      ..color = colorScheme.outlineVariant.withOpacity(.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final paths = <Path>[
      Path()
        ..moveTo(-20, size.height * .28)
        ..cubicTo(
          size.width * .25,
          size.height * .12,
          size.width * .45,
          size.height * .45,
          size.width + 20,
          size.height * .22,
        ),
      Path()
        ..moveTo(size.width * .12, -20)
        ..cubicTo(
          size.width * .35,
          size.height * .25,
          size.width * .25,
          size.height * .64,
          size.width * .7,
          size.height + 20,
        ),
      Path()
        ..moveTo(-20, size.height * .72)
        ..cubicTo(
          size.width * .28,
          size.height * .62,
          size.width * .62,
          size.height * .88,
          size.width + 20,
          size.height * .58,
        ),
    ];
    canvas.drawPath(paths[0], road);
    canvas.drawPath(paths[1], minorRoad);
    canvas.drawPath(paths[2], road);
  }

  @override
  bool shouldRepaint(covariant _OperationalMapPainter oldDelegate) =>
      oldDelegate.colorScheme != colorScheme ||
      oldDelegate.houses.length != houses.length;
}
