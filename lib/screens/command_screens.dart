import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/models.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

class ConstructionScheduleScreen extends StatefulWidget {
  const ConstructionScheduleScreen({super.key});

  @override
  State<ConstructionScheduleScreen> createState() =>
      _ConstructionScheduleScreenState();
}

class _ConstructionScheduleScreenState
    extends State<ConstructionScheduleScreen> {
  LifecyclePhase? _phase;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final houses = state.houses
        .where((house) => _phase == null || house.phase == _phase)
        .toList();
    return Scaffold(
      appBar: RcAppBar(
        title: const Text('Construction Schedule'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Live team briefing',
            onPressed: () =>
                Navigator.pushNamed(context, RcRoutes.liveBriefing),
            icon: const Icon(Icons.video_camera_front_outlined),
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
                          eyebrow: 'Plan / Delivery sequence',
                          title: 'Construction schedule',
                          description:
                              'See house phases, blockers and assigned teams in one live production sequence.',
                          action: FilledButton.tonalIcon(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              RcRoutes.teamResources,
                            ),
                            icon: const Icon(Icons.groups_2_outlined),
                            label: const Text('CREW CAPACITY'),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: <Widget>[
                              ChoiceChip(
                                label: const Text('All phases'),
                                selected: _phase == null,
                                onSelected: (_) =>
                                    setState(() => _phase = null),
                              ),
                              const SizedBox(width: 8),
                              for (final phase in LifecyclePhase.values) ...<Widget>[
                                ChoiceChip(
                                  avatar: Icon(phase.icon, size: 17),
                                  label: Text(phase.label),
                                  selected: _phase == phase,
                                  onSelected: (_) =>
                                      setState(() => _phase = phase),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        RcSectionHeader(
                          title: '${houses.length} scheduled houses',
                          subtitle:
                              '${state.attentionHouses} need intervention before the next phase',
                        ),
                        const SizedBox(height: 12),
                        if (houses.isEmpty)
                          const RcEmptyState(
                            icon: Icons.event_busy_outlined,
                            title: 'No houses in this phase',
                            message:
                                'Choose another phase to inspect the active schedule.',
                          )
                        else
                          ...houses.map(
                            (house) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ScheduleCard(house: house),
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

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.house});

  final HouseRecord house;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final isFinalPhase = house.phase == LifecyclePhase.finance;
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
                  child: Text(
                    house.code,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        house.beneficiary,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text('${house.community} • ${house.cluster}'),
                    ],
                  ),
                ),
                RcStatusChip(
                  label: house.phase.label.toUpperCase(),
                  tone: house.needsAttention
                      ? RcStatusTone.warning
                      : RcStatusTone.info,
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: 16),
            RcLifecycleRail(phase: house.phase, compact: true),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: house.progress,
              minHeight: 7,
              color: house.needsAttention ? RcColors.warning : RcColors.success,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            const SizedBox(height: 12),
            Text(
              house.blocker == null
                  ? 'Next: ${house.nextAction}'
                  : 'Blocker: ${house.blocker}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: house.blocker == null
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : RcColors.warning,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: () {
                    state.selectHouse(house.code);
                    Navigator.pushNamed(context, RcRoutes.houseCommand);
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('OPEN HOUSE'),
                ),
                if (house.blocker != null)
                  OutlinedButton.icon(
                    onPressed: () {
                      state.selectHouse(house.code);
                      Navigator.pushNamed(context, RcRoutes.transfers);
                    },
                    icon: const Icon(Icons.swap_horiz_outlined),
                    label: const Text('RESOLVE BLOCKER'),
                  ),
                FilledButton.icon(
                  onPressed: () {
                    state.selectHouse(house.code);
                    if (isFinalPhase) {
                      Navigator.pushNamed(context, RcRoutes.payment);
                    } else {
                      state.advanceSchedule(house.code);
                      showSavedMessage(context, submitted: true);
                    }
                  },
                  icon: Icon(
                    isFinalPhase
                        ? Icons.payments_outlined
                        : Icons.arrow_forward,
                  ),
                  label: Text(
                    isFinalPhase ? 'OPEN PAYMENT' : 'ADVANCE PHASE',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LiveBriefingScreen extends StatefulWidget {
  const LiveBriefingScreen({super.key});

  @override
  State<LiveBriefingScreen> createState() => _LiveBriefingScreenState();
}

class _LiveBriefingScreenState extends State<LiveBriefingScreen> {
  final _notes = TextEditingController();
  final Set<String> _completedAgenda = <String>{};
  bool _joined = false;

  static const _agenda = <String>[
    'Safety moment and attendance',
    'H12 zinc shortage and transfer ETA',
    'H2 close-out evidence review',
    'Crew allocation for tomorrow',
  ];

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final house = state.selectedHouse;
    return Scaffold(
      appBar: RcAppBar(title: const Text('Live Team Briefing')),
      body: Column(
        children: <Widget>[
          const RcSyncBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: <Widget>[
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        RcPageHeading(
                          eyebrow: 'Delivery / Live coordination',
                          title: _joined
                              ? 'Briefing room connected'
                              : 'Daily production briefing',
                          description:
                              'Coordinate decisions live, then save the outcome against ${house.code} so the field trail remains complete.',
                          action: RcStatusChip(
                            label: _joined ? 'LIVE NOW' : 'READY',
                            icon: _joined
                                ? Icons.fiber_manual_record
                                : Icons.schedule_outlined,
                            tone: _joined
                                ? RcStatusTone.error
                                : RcStatusTone.info,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            children: <Widget>[
                              Icon(
                                _joined
                                    ? Icons.groups_2_outlined
                                    : Icons.video_camera_front_outlined,
                                size: 64,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _joined
                                    ? '${state.team.where((member) => member.online).length} participants connected'
                                    : '08:00 Hanover operations call',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _joined
                                    ? 'Camera and microphone controls are available on your device.'
                                    : 'The room preserves house and action context when you join.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: () =>
                                    setState(() => _joined = !_joined),
                                icon: Icon(
                                  _joined
                                      ? Icons.call_end_outlined
                                      : Icons.video_call_outlined,
                                ),
                                label: Text(
                                  _joined ? 'LEAVE BRIEFING' : 'JOIN BRIEFING',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const RcSectionHeader(
                          title: 'Agenda',
                          subtitle:
                              'Check decisions as the team completes them.',
                        ),
                        const SizedBox(height: 10),
                        Card(
                          child: Column(
                            children: _agenda
                                .map(
                                  (item) => CheckboxListTile(
                                    title: Text(item),
                                    value: _completedAgenda.contains(item),
                                    onChanged: (_) => setState(() {
                                      if (!_completedAgenda.add(item)) {
                                        _completedAgenda.remove(item);
                                      }
                                    }),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const RcSectionHeader(
                          title: 'Decision notes',
                          subtitle:
                              'Saved notes become part of the selected house history.',
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _notes,
                          minLines: 4,
                          maxLines: 7,
                          decoration: InputDecoration(
                            labelText: '${house.code} briefing outcome',
                            hintText:
                                'Record owners, decisions and follow-up dates…',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            FilledButton.icon(
                              onPressed: () {
                                state.saveForm(
                                  type: 'Live Team Briefing',
                                  houseCode: house.code,
                                  values: <String, String>{
                                    'notes': _notes.text.trim(),
                                    'agenda': _completedAgenda.join(' | '),
                                  },
                                  submit: true,
                                );
                                showSavedMessage(context, submitted: true);
                              },
                              icon: const Icon(Icons.save_outlined),
                              label: const Text('SAVE BRIEFING'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => Navigator.pushNamed(
                                context,
                                RcRoutes.schedule,
                              ),
                              icon: const Icon(Icons.event_outlined),
                              label: const Text('OPEN SCHEDULE'),
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

class ProductionCommandScreen extends StatelessWidget {
  const ProductionCommandScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final issues = state.houses.where((house) => house.needsAttention).toList();
    final shortages = state.inventory
        .where((item) => item.delivered + item.additions < item.boq)
        .toList();
    return Scaffold(
      appBar: RcAppBar(
        title: const Text('Production Command'),
        actions: <Widget>[
          IconButton(
            tooltip: 'HQ command',
            onPressed: () => Navigator.pushNamed(context, RcRoutes.hqCommand),
            icon: const Icon(Icons.account_balance_outlined),
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
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        RcPageHeading(
                          eyebrow: 'Management / Production database',
                          title: 'One command view of delivery risk',
                          description:
                              'Bring house progress, issues, resources, transfers and approvals together without separating them from the source record.',
                          action: FilledButton.icon(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              RcRoutes.approvalQueue,
                            ),
                            icon: const Icon(Icons.approval_outlined),
                            label: const Text('APPROVAL QUEUE'),
                          ),
                        ),
                        const SizedBox(height: 20),
                        RcResponsiveGrid(
                          minItemWidth: 190,
                          childAspectRatio: 1.35,
                          children: <Widget>[
                            RcMetricTile(
                              label: 'Active houses',
                              value: '${state.activeHouses}',
                              icon: Icons.home_work_outlined,
                              color: RcColors.brand,
                              onTap: () => Navigator.pushNamed(
                                context,
                                RcRoutes.houses,
                              ),
                            ),
                            RcMetricTile(
                              label: 'Open issues',
                              value: '${issues.length}',
                              icon: Icons.report_problem_outlined,
                              color: RcColors.warning,
                            ),
                            RcMetricTile(
                              label: 'Material shortages',
                              value: '${shortages.length}',
                              icon: Icons.inventory_2_outlined,
                              color: RcColors.info,
                              onTap: () => Navigator.pushNamed(
                                context,
                                RcRoutes.inventory,
                              ),
                            ),
                            RcMetricTile(
                              label: 'Transfers awaiting approval',
                              value: '${state.pendingTransfers}',
                              icon: Icons.swap_horiz_outlined,
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
                          title: 'Issue manager',
                          subtitle:
                              'Each intervention opens the connected house or resource flow.',
                        ),
                        const SizedBox(height: 10),
                        if (issues.isEmpty)
                          const RcEmptyState(
                            icon: Icons.done_all,
                            title: 'No open delivery issues',
                            message:
                                'New blockers will appear here with their source house.',
                          )
                        else
                          Card(
                            child: Column(
                              children: issues
                                  .map(
                                    (house) => ListTile(
                                      leading: const Icon(
                                        Icons.report_problem_outlined,
                                        color: RcColors.warning,
                                      ),
                                      title: Text('${house.code} • ${house.blocker}'),
                                      subtitle: Text(
                                        '${house.community} • ${house.phase.label} • ${house.team.length} assigned',
                                      ),
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () {
                                        state.selectHouse(house.code);
                                        Navigator.pushNamed(
                                          context,
                                          RcRoutes.houseCommand,
                                        );
                                      },
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        const SizedBox(height: 22),
                        const RcSectionHeader(
                          title: 'Resource manager',
                          subtitle:
                              'BOQ shortages and workforce capacity requiring action.',
                        ),
                        const SizedBox(height: 10),
                        RcResponsiveGrid(
                          minItemWidth: 300,
                          childAspectRatio: 1.75,
                          children: <Widget>[
                            _CommandLinkCard(
                              icon: Icons.inventory_2_outlined,
                              title: '${shortages.length} material shortages',
                              subtitle:
                                  'Review stock, delivery and transfer availability.',
                              route: RcRoutes.inventory,
                            ),
                            _CommandLinkCard(
                              icon: Icons.groups_2_outlined,
                              title: '${state.crewsDeployed} crews deployed',
                              subtitle:
                                  'Balance workload and specialist capacity.',
                              route: RcRoutes.teamResources,
                            ),
                            _CommandLinkCard(
                              icon: Icons.event_available_outlined,
                              title: 'Construction schedule',
                              subtitle:
                                  'Inspect phase sequence and advance verified work.',
                              route: RcRoutes.schedule,
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

class FinanceCommandScreen extends StatelessWidget {
  const FinanceCommandScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final finance = state.houses
        .where((house) => house.phase == LifecyclePhase.finance)
        .toList();
    return Scaffold(
      appBar: RcAppBar(title: const Text('Finance Command')),
      body: Column(
        children: <Widget>[
          const RcSyncBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: <Widget>[
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        RcPageHeading(
                          eyebrow: 'Finance / Payout control',
                          title: 'Payment queue with production evidence',
                          description:
                              'Review, approve and release payments only after the connected house package is complete.',
                          action: FilledButton.tonalIcon(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              RcRoutes.approvalQueue,
                            ),
                            icon: const Icon(Icons.approval_outlined),
                            label: const Text('ALL APPROVALS'),
                          ),
                        ),
                        const SizedBox(height: 20),
                        RcResponsiveGrid(
                          minItemWidth: 200,
                          childAspectRatio: 1.4,
                          children: <Widget>[
                            RcMetricTile(
                              label: 'Finance records',
                              value: '${finance.length}',
                              icon: Icons.receipt_long_outlined,
                              color: RcColors.info,
                            ),
                            RcMetricTile(
                              label: 'Awaiting approval',
                              value:
                                  '${finance.where((house) => house.status == RecordStatus.submitted).length}',
                              icon: Icons.pending_actions_outlined,
                              color: RcColors.warning,
                            ),
                            RcMetricTile(
                              label: 'Approved to release',
                              value:
                                  '${finance.where((house) => house.status == RecordStatus.approved).length}',
                              icon: Icons.price_check_outlined,
                              color: RcColors.success,
                            ),
                            RcMetricTile(
                              label: 'Paid records',
                              value:
                                  '${finance.where((house) => house.status == RecordStatus.paid).length}',
                              icon: Icons.payments_outlined,
                              color: RcColors.brand,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        RcSectionHeader(
                          title: 'Payment submissions',
                          subtitle: '${finance.length} house-linked records',
                        ),
                        const SizedBox(height: 10),
                        if (finance.isEmpty)
                          const RcEmptyState(
                            icon: Icons.account_balance_wallet_outlined,
                            title: 'Finance queue is empty',
                            message:
                                'Approved close-out records will appear here.',
                          )
                        else
                          ...finance.map(
                            (house) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _FinanceCard(house: house),
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

class _FinanceCard extends StatelessWidget {
  const _FinanceCard({required this.house});

  final HouseRecord house;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const CircleAvatar(child: Icon(Icons.payments_outlined)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${house.code} • ${house.beneficiary}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text('${house.community} • ${house.evidenceComplete}/${house.evidenceRequired} evidence'),
                    ],
                  ),
                ),
                RcStatusChip(
                  label: house.status.label.toUpperCase(),
                  tone: house.status == RecordStatus.paid ||
                          house.status == RecordStatus.approved
                      ? RcStatusTone.success
                      : RcStatusTone.warning,
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: () {
                    state.selectHouse(house.code);
                    Navigator.pushNamed(context, RcRoutes.payment);
                  },
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('OPEN SUBMISSION'),
                ),
                if (house.status == RecordStatus.submitted)
                  FilledButton.icon(
                    onPressed: () {
                      state.approvePayment(house.code);
                      showSavedMessage(context, submitted: true);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('APPROVE'),
                  ),
                if (house.status == RecordStatus.approved)
                  FilledButton.icon(
                    onPressed: () {
                      state.markPaymentPaid(house.code);
                      showSavedMessage(context, submitted: true);
                    },
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('MARK PAID'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HqCommandScreen extends StatelessWidget {
  const HqCommandScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: RcAppBar(title: const Text('HQ Command Centre')),
      body: Column(
        children: <Widget>[
          const RcSyncBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: <Widget>[
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        RcPageHeading(
                          eyebrow: 'Headquarters / Operational oversight',
                          title: 'National delivery command',
                          description:
                              'Monitor field production, people, finance and institutional reporting from one traceable command layer.',
                          action: FilledButton.icon(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              RcRoutes.institutionalReport,
                            ),
                            icon: const Icon(Icons.summarize_outlined),
                            label: const Text('HQ REPORT'),
                          ),
                        ),
                        const SizedBox(height: 20),
                        RcResponsiveGrid(
                          minItemWidth: 190,
                          childAspectRatio: 1.35,
                          children: <Widget>[
                            RcMetricTile(
                              label: 'Active production',
                              value: '${state.activeHouses}',
                              icon: Icons.home_work_outlined,
                              color: RcColors.brand,
                              onTap: () => Navigator.pushNamed(
                                context,
                                RcRoutes.productionCommand,
                              ),
                            ),
                            RcMetricTile(
                              label: 'Delivery attention',
                              value: '${state.attentionHouses}',
                              icon: Icons.report_problem_outlined,
                              color: RcColors.warning,
                              onTap: () => Navigator.pushNamed(
                                context,
                                RcRoutes.productionCommand,
                              ),
                            ),
                            RcMetricTile(
                              label: 'Evidence readiness',
                              value: '${(state.evidenceReadiness * 100).round()}%',
                              icon: Icons.verified_outlined,
                              color: RcColors.success,
                              onTap: () => Navigator.pushNamed(
                                context,
                                RcRoutes.evidence,
                              ),
                            ),
                            RcMetricTile(
                              label: 'Pending finance',
                              value: '${state.paymentsPending}',
                              icon: Icons.payments_outlined,
                              color: RcColors.info,
                              onTap: () => Navigator.pushNamed(
                                context,
                                RcRoutes.financeCommand,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const RcSectionHeader(
                          title: 'Command workspaces',
                          subtitle:
                              'Open a focused view without losing the shared operational truth.',
                        ),
                        const SizedBox(height: 12),
                        RcResponsiveGrid(
                          minItemWidth: 300,
                          childAspectRatio: 1.7,
                          children: const <Widget>[
                            _CommandLinkCard(
                              icon: Icons.precision_manufacturing_outlined,
                              title: 'Production command',
                              subtitle:
                                  'Houses, issues, materials and crew capacity.',
                              route: RcRoutes.productionCommand,
                            ),
                            _CommandLinkCard(
                              icon: Icons.account_balance_wallet_outlined,
                              title: 'Finance command',
                              subtitle:
                                  'Approval, payout and evidence readiness.',
                              route: RcRoutes.financeCommand,
                            ),
                            _CommandLinkCard(
                              icon: Icons.groups_2_outlined,
                              title: 'Team performance',
                              subtitle:
                                  'Quality, safety, recognition and progression.',
                              route: RcRoutes.teamPerformance,
                            ),
                            _CommandLinkCard(
                              icon: Icons.settings_suggest_outlined,
                              title: 'Administration command',
                              subtitle:
                                  'System features, policy logic and layout.',
                              route: RcRoutes.adminCommand,
                            ),
                            _CommandLinkCard(
                              icon: Icons.approval_outlined,
                              title: 'Connected approval queue',
                              subtitle:
                                  'Transfers, close-out and finance decisions.',
                              route: RcRoutes.approvalQueue,
                            ),
                            _CommandLinkCard(
                              icon: Icons.analytics_outlined,
                              title: 'Production analytics',
                              subtitle:
                                  'Parish, phase and evidence performance.',
                              route: RcRoutes.analytics,
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

class InstitutionalReportScreen extends StatelessWidget {
  const InstitutionalReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final complete = state.houses.where((house) => house.progress >= 1).length;
    return Scaffold(
      appBar: RcAppBar(title: const Text('Institutional Report')),
      body: Column(
        children: <Widget>[
          const RcSyncBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: <Widget>[
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        RcPageHeading(
                          eyebrow: 'HQ / Executive reporting',
                          title: 'Connected Green Gate report',
                          description:
                              'A decision-ready summary derived from the same house, evidence, transfer, team and finance records used in the field.',
                          action: RcStatusChip(
                            label: state.hqReportApproved
                                ? 'HQ APPROVED'
                                : 'DRAFT REVIEW',
                            icon: state.hqReportApproved
                                ? Icons.verified_user_outlined
                                : Icons.description_outlined,
                            tone: state.hqReportApproved
                                ? RcStatusTone.success
                                : RcStatusTone.warning,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Executive summary',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '${state.houses.length} houses are registered in ${state.selectedParish}. '
                                  '$complete reached full construction progress; ${state.attentionHouses} require operational attention. '
                                  'Evidence readiness is ${(state.evidenceReadiness * 100).round()}% and ${state.pendingTransfers} transfer request(s) remain in approval.',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 20),
                                _ReportLine(
                                  label: 'Open production',
                                  value: '${state.activeHouses} houses',
                                ),
                                _ReportLine(
                                  label: 'Close-out ready',
                                  value: '${state.closeOutReady} houses',
                                ),
                                _ReportLine(
                                  label: 'Evidence readiness',
                                  value:
                                      '${(state.evidenceReadiness * 100).round()}%',
                                ),
                                _ReportLine(
                                  label: 'Average team quality',
                                  value:
                                      '${(state.averageCrewQuality * 100).round()}%',
                                ),
                                _ReportLine(
                                  label: 'Pending transfers',
                                  value: '${state.pendingTransfers}',
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            FilledButton.icon(
                              onPressed: state.hqReportApproved
                                  ? () => ScaffoldMessenger.of(context)
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'This report is already HQ approved.',
                                        ),
                                      ),
                                    )
                                  : () {
                                      state.approveHqReport();
                                      showSavedMessage(
                                        context,
                                        submitted: true,
                                      );
                                    },
                              icon: const Icon(Icons.verified_user_outlined),
                              label: Text(
                                state.hqReportApproved
                                    ? 'APPROVED'
                                    : 'APPROVE HQ REPORT',
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Report export prepared for secure sharing.',
                                    ),
                                  ),
                                ),
                              icon: const Icon(Icons.download_outlined),
                              label: const Text('EXPORT REPORT'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => Navigator.pushNamed(
                                context,
                                RcRoutes.hqCommand,
                              ),
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('BACK TO HQ'),
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

class _ReportLine extends StatelessWidget {
  const _ReportLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class AdminCommandScreen extends StatelessWidget {
  const AdminCommandScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: RcAppBar(title: const Text('Administration Command')),
      body: Column(
        children: <Widget>[
          const RcSyncBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: <Widget>[
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const RcPageHeading(
                          eyebrow: 'Admin / System controls',
                          title: 'Configure the operational system',
                          description:
                              'Manage approved features, automation policies, users, templates and the Control workspace from one accountable layer.',
                        ),
                        const SizedBox(height: 20),
                        RcResponsiveGrid(
                          minItemWidth: 280,
                          childAspectRatio: 1.75,
                          children: const <Widget>[
                            _CommandLinkCard(
                              icon: Icons.dashboard_customize_outlined,
                              title: 'Control layout',
                              subtitle:
                                  'Change divisions, tile order, density and visibility.',
                              route: RcRoutes.controlLayout,
                            ),
                            _CommandLinkCard(
                              icon: Icons.swap_horiz_outlined,
                              title: 'Transfer automation',
                              subtitle:
                                  'Configure proposals, buffers and parish overrides.',
                              route: RcRoutes.transferAutomation,
                            ),
                            _CommandLinkCard(
                              icon: Icons.workspace_premium_outlined,
                              title: 'Awards & incentives',
                              subtitle:
                                  'Configure recognition and verified safety rewards.',
                              route: RcRoutes.awardsIncentives,
                            ),
                            _CommandLinkCard(
                              icon: Icons.manage_accounts_outlined,
                              title: 'User access',
                              subtitle:
                                  'Roles, parish scope and administration rights.',
                              route: RcRoutes.adminUsers,
                            ),
                            _CommandLinkCard(
                              icon: Icons.dashboard_outlined,
                              title: 'Templates',
                              subtitle:
                                  'Operational forms and connected data templates.',
                              route: RcRoutes.adminTemplates,
                            ),
                            _CommandLinkCard(
                              icon: Icons.map_outlined,
                              title: 'Parish & cluster geography',
                              subtitle:
                                  'Locations, operational pins and beneficiary context.',
                              route: RcRoutes.operationalMap,
                            ),
                            _CommandLinkCard(
                              icon: Icons.inventory_2_outlined,
                              title: 'Inventory & storage',
                              subtitle:
                                  'Parish stock, reconciliation and storage health.',
                              route: RcRoutes.inventory,
                            ),
                            _CommandLinkCard(
                              icon: Icons.event_available_outlined,
                              title: 'Schedule configuration',
                              subtitle:
                                  'House sequence, crew demand and phase progression.',
                              route: RcRoutes.schedule,
                            ),
                            _CommandLinkCard(
                              icon: Icons.approval_outlined,
                              title: 'Override approvals',
                              subtitle:
                                  'Review exceptions through the connected queue.',
                              route: RcRoutes.approvalQueue,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const RcSectionHeader(
                          title: 'Feature controls',
                          subtitle:
                              'Every change is recorded in operational history.',
                        ),
                        const SizedBox(height: 10),
                        Card(
                          child: Column(
                            children: state.adminFeatures.entries
                                .map(
                                  (entry) => SwitchListTile(
                                    secondary: Icon(
                                      entry.value
                                          ? Icons.toggle_on_outlined
                                          : Icons.toggle_off_outlined,
                                    ),
                                    title: Text(entry.key),
                                    value: entry.value,
                                    onChanged: (_) =>
                                        state.toggleAdminFeature(entry.key),
                                  ),
                                )
                                .toList(),
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

class ApprovalQueueScreen extends StatelessWidget {
  const ApprovalQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final transfers = state.transfers
        .where((transfer) => transfer.status == 'Pending approval')
        .toList();
    final closeOut = state.houses
        .where(
          (house) =>
              house.phase == LifecyclePhase.closeOut &&
              house.status != RecordStatus.approved &&
              house.status != RecordStatus.complete,
        )
        .toList();
    final finance = state.houses
        .where(
          (house) =>
              house.phase == LifecyclePhase.finance &&
              house.status == RecordStatus.submitted,
        )
        .toList();
    final total = transfers.length + closeOut.length + finance.length;
    return Scaffold(
      appBar: RcAppBar(title: const Text('Connected Approval Queue')),
      body: Column(
        children: <Widget>[
          const RcSyncBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: <Widget>[
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        RcPageHeading(
                          eyebrow: 'Management / Decisions',
                          title: 'Connected approval queue',
                          description:
                              'Review transfer, close-out and payment decisions with their house context and audit trail intact.',
                          action: RcStatusChip(
                            label: '$total PENDING',
                            icon: Icons.pending_actions_outlined,
                            tone: total == 0
                                ? RcStatusTone.success
                                : RcStatusTone.warning,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (total == 0)
                          const RcEmptyState(
                            icon: Icons.done_all,
                            title: 'All decisions are current',
                            message:
                                'New submissions will appear here with their source record.',
                          )
                        else ...<Widget>[
                          if (transfers.isNotEmpty) ...<Widget>[
                            RcSectionHeader(
                              title: 'Transfer approvals',
                              subtitle: '${transfers.length} pending',
                            ),
                            const SizedBox(height: 10),
                            ...transfers.map(
                              (transfer) => _ApprovalCard(
                                icon: Icons.swap_horiz_outlined,
                                title: '${transfer.id} • ${transfer.resource}',
                                subtitle:
                                    '${transfer.origin} → ${transfer.destination}\n${transfer.houseCode} • ${transfer.urgency}',
                                onOpen: () {
                                  state.selectTransfer(transfer.id);
                                  Navigator.pushNamed(
                                    context,
                                    RcRoutes.transferDetail,
                                  );
                                },
                                onApprove: () => state.updateTransferStatus(
                                  transfer.id,
                                  'Approved',
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          if (closeOut.isNotEmpty) ...<Widget>[
                            RcSectionHeader(
                              title: 'Close-out approvals',
                              subtitle: '${closeOut.length} pending',
                            ),
                            const SizedBox(height: 10),
                            ...closeOut.map(
                              (house) => _ApprovalCard(
                                icon: Icons.task_alt_outlined,
                                title:
                                    '${house.code} • ${house.beneficiary}',
                                subtitle:
                                    '${house.evidenceComplete}/${house.evidenceRequired} evidence • ${house.community}',
                                onOpen: () {
                                  state.selectHouse(house.code);
                                  Navigator.pushNamed(
                                    context,
                                    RcRoutes.completion,
                                  );
                                },
                                onApprove: () =>
                                    state.approveCompletion(house.code),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          if (finance.isNotEmpty) ...<Widget>[
                            RcSectionHeader(
                              title: 'Payment approvals',
                              subtitle: '${finance.length} pending',
                            ),
                            const SizedBox(height: 10),
                            ...finance.map(
                              (house) => _ApprovalCard(
                                icon: Icons.payments_outlined,
                                title:
                                    '${house.code} • ${house.beneficiary}',
                                subtitle:
                                    '${house.evidenceComplete}/${house.evidenceRequired} evidence • ${house.community}',
                                onOpen: () {
                                  state.selectHouse(house.code);
                                  Navigator.pushNamed(
                                    context,
                                    RcRoutes.payment,
                                  );
                                },
                                onApprove: () =>
                                    state.approvePayment(house.code),
                              ),
                            ),
                          ],
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
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onOpen,
    required this.onApprove,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onOpen;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(child: Icon(icon)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(subtitle),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('OPEN RECORD'),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      onApprove();
                      showSavedMessage(context, submitted: true);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('APPROVE'),
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

class _CommandLinkCard extends StatelessWidget {
  const _CommandLinkCard({
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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
