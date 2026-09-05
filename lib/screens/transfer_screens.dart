import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/models.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

class TransferHubScreen extends StatefulWidget {
  const TransferHubScreen({super.key});

  @override
  State<TransferHubScreen> createState() => _TransferHubScreenState();
}

class _TransferHubScreenState extends State<TransferHubScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final transfers = state.transfers.where((transfer) {
      return _filter == 'All' || transfer.status == _filter;
    }).toList();
    return Scaffold(
      appBar: RcAppBar(
        title: const Text('Transfer Management'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Transfer automation',
            onPressed: () =>
                Navigator.pushNamed(context, RcRoutes.transferAutomation),
            icon: const Icon(Icons.settings_suggest_outlined),
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
                          eyebrow: 'Resources / Personnel / Materials',
                          title: 'Transfer command',
                          description:
                              'Request, authorize and trace resource movement between parishes, clusters, stores and houses.',
                          action: FilledButton.icon(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              RcRoutes.newTransfer,
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('NEW REQUEST'),
                          ),
                        ),
                        const SizedBox(height: 20),
                        RcResponsiveGrid(
                          minItemWidth: 190,
                          childAspectRatio: 1.35,
                          children: <Widget>[
                            RcMetricTile(
                              label: 'Pending approval',
                              value: '${state.pendingTransfers}',
                              icon: Icons.pending_actions_outlined,
                              color: RcColors.warning,
                              onTap: () =>
                                  setState(() => _filter = 'Pending approval'),
                            ),
                            RcMetricTile(
                              label: 'In transit',
                              value:
                                  '${state.transfers.where((item) => item.status == 'In transit').length}',
                              icon: Icons.local_shipping_outlined,
                              color: RcColors.info,
                              onTap: () =>
                                  setState(() => _filter = 'In transit'),
                            ),
                            RcMetricTile(
                              label: 'Completed',
                              value:
                                  '${state.transfers.where((item) => item.status == 'Completed').length}',
                              icon: Icons.done_all_outlined,
                              color: RcColors.success,
                              onTap: () =>
                                  setState(() => _filter = 'Completed'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: <Widget>[
                              for (final filter in <String>[
                                'All',
                                'Pending approval',
                                'Approved',
                                'In transit',
                                'Completed',
                                'Declined',
                              ]) ...<Widget>[
                                ChoiceChip(
                                  label: Text(filter),
                                  selected: _filter == filter,
                                  onSelected: (_) =>
                                      setState(() => _filter = filter),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        RcSectionHeader(
                          title: '${transfers.length} transfer records',
                          subtitle:
                              'Every decision is linked to a house and audit trail.',
                        ),
                        const SizedBox(height: 12),
                        if (transfers.isEmpty)
                          const RcEmptyState(
                            icon: Icons.swap_horiz_outlined,
                            title: 'No transfers in this state',
                            message:
                                'Change the filter or create a new personnel or material request.',
                          )
                        else
                          ...transfers.map(
                            (transfer) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _TransferCard(transfer: transfer),
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

class _TransferCard extends StatelessWidget {
  const _TransferCard({required this.transfer});

  final TransferRecord transfer;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(context, state),
        child: Padding(
          padding: const EdgeInsets.all(18),
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
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      transfer.category == 'Personnel'
                          ? Icons.groups_outlined
                          : Icons.inventory_2_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          transfer.id,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          transfer.resource,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  RcStatusChip(
                    label: transfer.status.toUpperCase(),
                    compact: true,
                    tone: _transferTone(transfer.status),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  RcStatusChip(
                    label: transfer.urgency.toUpperCase(),
                    compact: true,
                    tone: transfer.urgency == 'Critical'
                        ? RcStatusTone.error
                        : transfer.urgency == 'Priority'
                            ? RcStatusTone.warning
                            : RcStatusTone.neutral,
                  ),
                  RcStatusChip(
                    label: transfer.temporary ? 'TEMPORARY' : 'PERMANENT',
                    compact: true,
                    tone: RcStatusTone.info,
                  ),
                  RcStatusChip(
                    label: transfer.houseCode,
                    compact: true,
                    tone: RcStatusTone.brand,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(child: _Place(label: 'From', value: transfer.origin)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward),
                  ),
                  Expanded(
                    child: _Place(label: 'To', value: transfer.destination),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                transfer.reason,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: () => _open(context, state),
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('DETAILS'),
                  ),
                  if (transfer.status == 'Pending approval') ...<Widget>[
                    OutlinedButton(
                      onPressed: () =>
                          state.updateTransferStatus(transfer.id, 'Declined'),
                      child: const Text('DECLINE'),
                    ),
                    FilledButton.icon(
                      onPressed: () =>
                          state.updateTransferStatus(transfer.id, 'Approved'),
                      icon: const Icon(Icons.check),
                      label: const Text('APPROVE'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, AppState state) {
    state.selectTransfer(transfer.id);
    Navigator.pushNamed(context, RcRoutes.transferDetail);
  }
}

class _Place extends StatelessWidget {
  const _Place({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
    );
  }
}

class NewTransferScreen extends StatefulWidget {
  const NewTransferScreen({super.key});

  @override
  State<NewTransferScreen> createState() => _NewTransferScreenState();
}

class _NewTransferScreenState extends State<NewTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  String _category = 'Personnel';
  String _resource = 'Master Carpenter';
  String _origin = '';
  String _destination = '';
  String _houseCode = '';
  String _urgency = 'Priority';
  int _quantity = 1;
  bool _temporary = true;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final locations = <String>{
      ...state.stockLedger.map((item) => item.location),
      ...state.houses.map((house) => house.cluster),
      ...state.houses.map((house) => house.community),
    }.where((value) => value.trim().isNotEmpty).toList()
      ..sort();
    final resources = _category == 'Personnel'
        ? const <String>[
            'Master Carpenter',
            'Carpenter',
            'Assistant Carpenter',
            'General Helper',
            'Site Supervisor',
          ]
        : const <String>[
            'Zinc sheets • 14 ft',
            'Rafters 2×6×14',
            'Hurricane straps H3',
            'Zinc screws 2½ in',
            'Framing packs',
          ];
    return Scaffold(
      appBar: RcAppBar(title: const Text('Request Transfer')),
      body: Column(
        children: <Widget>[
          const RcSyncBanner(),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 110),
                children: <Widget>[
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const RcPageHeading(
                            eyebrow: 'Transfer / New request',
                            title: 'Request operational resources',
                            description:
                                'Create a traceable personnel or material movement linked to its target house.',
                          ),
                          const SizedBox(height: 20),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Resource type',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 12),
                                  SegmentedButton<String>(
                                    segments:
                                        const <ButtonSegment<String>>[
                                      ButtonSegment<String>(
                                        value: 'Personnel',
                                        label: Text('Personnel'),
                                        icon: Icon(Icons.groups_outlined),
                                      ),
                                      ButtonSegment<String>(
                                        value: 'Materials',
                                        label: Text('Materials'),
                                        icon: Icon(Icons.inventory_2_outlined),
                                      ),
                                    ],
                                    selected: <String>{_category},
                                    onSelectionChanged: (selection) {
                                      setState(() {
                                        _category = selection.first;
                                        _resource = _category == 'Personnel'
                                            ? 'Master Carpenter'
                                            : 'Zinc sheets • 14 ft';
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  DropdownButtonFormField<String>(
                                    initialValue: _resource,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Personnel or material',
                                    ),
                                    items: resources
                                        .map(
                                          (value) => DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) =>
                                        setState(() => _resource = value!),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          'Quantity required',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                      ),
                                      IconButton.outlined(
                                        tooltip: 'Decrease quantity',
                                        onPressed: _quantity == 1
                                            ? null
                                            : () =>
                                                setState(() => _quantity--),
                                        icon: const Icon(Icons.remove),
                                      ),
                                      SizedBox(
                                        width: 52,
                                        child: Text(
                                          '$_quantity',
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall,
                                        ),
                                      ),
                                      IconButton.filledTonal(
                                        tooltip: 'Increase quantity',
                                        onPressed: () =>
                                            setState(() => _quantity++),
                                        icon: const Icon(Icons.add),
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
                                children: <Widget>[
                                  DropdownButtonFormField<String>(
                                    initialValue:
                                        locations.contains(_origin) ? _origin : null,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Origin',
                                      prefixIcon:
                                          Icon(Icons.outbound_outlined),
                                    ),
                                    items: locations
                                        .map(
                                          (value) => DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          ),
                                        )
                                        .toList(),
                                    validator: (value) =>
                                        value == null || value.isEmpty
                                            ? 'Select a real origin location.'
                                            : null,
                                    onChanged: (value) =>
                                        setState(() => _origin = value ?? ''),
                                  ),
                                  const SizedBox(height: 14),
                                  DropdownButtonFormField<String>(
                                    initialValue: locations.contains(_destination)
                                        ? _destination
                                        : null,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Target destination',
                                      prefixIcon:
                                          Icon(Icons.add_location_alt_outlined),
                                    ),
                                    items: locations
                                        .map(
                                          (value) => DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          ),
                                        )
                                        .toList(),
                                    validator: (value) =>
                                        value == null || value.isEmpty
                                            ? 'Select a real destination.'
                                            : null,
                                    onChanged: (value) =>
                                        setState(() => _destination = value ?? ''),
                                  ),
                                  const SizedBox(height: 14),
                                  DropdownButtonFormField<String>(
                                    initialValue: state.houses.any(
                                      (house) => house.code == _houseCode,
                                    )
                                        ? _houseCode
                                        : null,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Target house',
                                      prefixIcon: Icon(Icons.house_outlined),
                                    ),
                                    items: state.houses
                                        .map(
                                          (house) => DropdownMenuItem<String>(
                                            value: house.code,
                                            child: Text(
                                              '${house.code} • ${house.beneficiary}',
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) =>
                                        setState(() => _houseCode = value!),
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
                                  SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('Temporary assignment'),
                                    subtitle: Text(
                                      _temporary
                                          ? 'Return after three days'
                                          : 'Permanent reassignment',
                                    ),
                                    value: _temporary,
                                    onChanged: (value) =>
                                        setState(() => _temporary = value),
                                  ),
                                  const Divider(),
                                  Text(
                                    'Urgency level',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: <Widget>[
                                      for (final value in <String>[
                                        'Routine',
                                        'Priority',
                                        'Critical',
                                      ])
                                        ChoiceChip(
                                          label: Text(value),
                                          selected: _urgency == value,
                                          onSelected: (_) => setState(
                                            () => _urgency = value,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _reason,
                                    maxLines: 4,
                                    decoration: const InputDecoration(
                                      labelText: 'Reason / justification',
                                      alignLabelWithHint: true,
                                    ),
                                    validator: (value) =>
                                        value == null || value.trim().isEmpty
                                            ? 'Add the operational reason.'
                                            : null,
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
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: () => _submit(context, state),
            icon: const Icon(Icons.send_outlined),
            label: const Text('SUBMIT TRANSFER REQUEST'),
          ),
        ),
      ),
    );
  }

  void _submit(BuildContext context, AppState state) {
    if (!_formKey.currentState!.validate()) return;
    final id = state.createTransfer(
      category: _category,
      resource: _resource,
      quantity: _quantity,
      origin: _origin,
      destination: _destination,
      houseCode: _houseCode,
      urgency: _urgency,
      reason: _reason.text.trim(),
      temporary: _temporary,
    );
    state.selectTransfer(id);
    Navigator.pushReplacementNamed(context, RcRoutes.transferDetail);
  }
}

class TransferDetailScreen extends StatelessWidget {
  const TransferDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final transfer = state.selectedTransfer;
    return Scaffold(
      appBar: RcAppBar(title: Text('${transfer.id} • Transfer Detail')),
      body: Column(
        children: <Widget>[
          const RcSyncBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: <Widget>[
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        RcPageHeading(
                          eyebrow: '${transfer.category} transfer',
                          title: '${transfer.houseCode} assignment overview',
                          description: transfer.reason,
                          action: RcStatusChip(
                            label: transfer.status.toUpperCase(),
                            tone: _transferTone(transfer.status),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: <Widget>[
                                _DetailRow(
                                  icon: Icons.badge_outlined,
                                  label: 'Resource',
                                  value: transfer.resource,
                                ),
                                _DetailRow(
                                  icon: Icons.priority_high,
                                  label: 'Urgency',
                                  value: transfer.urgency,
                                ),
                                _DetailRow(
                                  icon: Icons.event_repeat_outlined,
                                  label: 'Duration',
                                  value: transfer.temporary
                                      ? 'Temporary • 3 days'
                                      : 'Permanent',
                                ),
                                _DetailRow(
                                  icon: Icons.account_balance_wallet_outlined,
                                  label: 'Estimated impact',
                                  value:
                                      '\$${transfer.budgetImpact.toStringAsFixed(0)}',
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: _Place(
                                    label: 'Origin',
                                    value: transfer.origin,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Icon(Icons.arrow_forward),
                                ),
                                Expanded(
                                  child: _Place(
                                    label: 'Destination',
                                    value: transfer.destination,
                                  ),
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
                            OutlinedButton.icon(
                              onPressed: () {
                                state.selectHouse(transfer.houseCode);
                                Navigator.pushNamed(
                                  context,
                                  RcRoutes.houseCommand,
                                );
                              },
                              icon: const Icon(Icons.house_outlined),
                              label: const Text('OPEN HOUSE'),
                            ),
                            if (transfer.status == 'Pending approval') ...<Widget>[
                              OutlinedButton(
                                onPressed: () => state.updateTransferStatus(
                                  transfer.id,
                                  'Declined',
                                ),
                                child: const Text('DECLINE'),
                              ),
                              FilledButton.icon(
                                onPressed: () => state.updateTransferStatus(
                                  transfer.id,
                                  'Approved',
                                ),
                                icon: const Icon(Icons.check),
                                label: const Text('APPROVE'),
                              ),
                            ],
                            if (transfer.status == 'Approved')
                              FilledButton.icon(
                                onPressed: () => state.updateTransferStatus(
                                  transfer.id,
                                  'In transit',
                                ),
                                icon: const Icon(Icons.local_shipping_outlined),
                                label: const Text('MARK IN TRANSIT'),
                              ),
                            if (transfer.status == 'In transit')
                              FilledButton.icon(
                                onPressed: () => state.updateTransferStatus(
                                  transfer.id,
                                  'Completed',
                                ),
                                icon: const Icon(Icons.done_all),
                                label: const Text('CONFIRM ARRIVAL'),
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: <Widget>[
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class TransferAutomationScreen extends StatefulWidget {
  const TransferAutomationScreen({super.key});

  @override
  State<TransferAutomationScreen> createState() =>
      _TransferAutomationScreenState();
}

class _TransferAutomationScreenState extends State<TransferAutomationScreen> {
  double _retentionBuffer = 15;
  String _cluster = 'All clusters';

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final pending = state.transfers
        .where((transfer) => transfer.status == 'Pending approval')
        .toList();
    final scopes = <String>{
      'All clusters',
      ...state.houses.map((house) => house.cluster),
      ...state.houses.map((house) => house.community),
    }.where((value) => value.trim().isNotEmpty).toList()
      ..sort();
    if (!scopes.contains(_cluster)) _cluster = 'All clusters';
    return Scaffold(
      appBar: RcAppBar(title: const Text('Automated Transfer Configuration')),
      body: Column(
        children: <Widget>[
          const RcSyncBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: <Widget>[
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1050),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const RcPageHeading(
                          eyebrow: 'Admin / Resource allocation',
                          title: 'Transfer logic & buffers',
                          description:
                              'Configure proposed cross-parish transfers while keeping every movement subject to review.',
                        ),
                        const SizedBox(height: 20),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              children: <Widget>[
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Auto-transfer engine'),
                                  subtitle: const Text(
                                    'Generate proposals; never move resources without approval.',
                                  ),
                                  value: state.autoTransferEnabled,
                                  onChanged: state.setAutoTransfer,
                                ),
                                const Divider(),
                                DropdownButtonFormField<String>(
                                  initialValue: _cluster,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Parish / cluster scope',
                                  ),
                                  items: scopes
                                      .map(
                                        (value) => DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) =>
                                      setState(() => _cluster = value ?? 'All clusters'),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: <Widget>[
                                    const Expanded(
                                      child: Text(
                                        'Mandatory source retention buffer',
                                      ),
                                    ),
                                    Text(
                                      '${_retentionBuffer.round()}%',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                                Slider(
                                  value: _retentionBuffer,
                                  min: 5,
                                  max: 40,
                                  divisions: 7,
                                  label: '${_retentionBuffer.round()}%',
                                  onChanged: (value) => setState(
                                    () => _retentionBuffer = value,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        RcSectionHeader(
                          title: 'Proposed transfers',
                          subtitle: '${pending.length} awaiting a decision',
                          trailing: pending.isEmpty
                              ? null
                              : FilledButton.tonal(
                                  onPressed: () {
                                    for (final transfer in pending) {
                                      state.updateTransferStatus(
                                        transfer.id,
                                        'Approved',
                                      );
                                    }
                                  },
                                  child: const Text('APPROVE ALL'),
                                ),
                        ),
                        const SizedBox(height: 12),
                        if (pending.isEmpty)
                          const RcEmptyState(
                            icon: Icons.done_all,
                            title: 'Transfer queue is clear',
                            message:
                                'New shortage or workforce proposals will appear here for review.',
                          )
                        else
                          ...pending.map(
                            (transfer) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Card(
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.swap_horiz),
                                  ),
                                  title: Text(
                                    '${transfer.id} • ${transfer.resource}',
                                  ),
                                  subtitle: Text(
                                    '${transfer.origin} → ${transfer.destination}\n${transfer.urgency} • ${transfer.houseCode}',
                                  ),
                                  isThreeLine: true,
                                  trailing: Wrap(
                                    spacing: 4,
                                    children: <Widget>[
                                      IconButton(
                                        tooltip: 'Ignore proposal',
                                        onPressed: () =>
                                            state.updateTransferStatus(
                                          transfer.id,
                                          'Declined',
                                        ),
                                        icon: const Icon(Icons.close),
                                      ),
                                      IconButton.filled(
                                        tooltip: 'Approve proposal',
                                        onPressed: () =>
                                            state.updateTransferStatus(
                                          transfer.id,
                                          'Approved',
                                        ),
                                        icon: const Icon(Icons.check),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    state.selectTransfer(transfer.id);
                                    Navigator.pushNamed(
                                      context,
                                      RcRoutes.transferDetail,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                        const RcSectionHeader(
                          title: 'Parish and cluster overrides',
                          subtitle:
                              'Receiving-only, forced-surplus and paused states.',
                        ),
                        const SizedBox(height: 10),
                        Card(
                          child: Column(
                            children: <Widget>[
                              for (final feature in <String>[
                                'Multi-parish inventory',
                                'Storage health alerts',
                                'Automatic cloud synchronization',
                              ])
                                SwitchListTile(
                                  title: Text(feature),
                                  value: state.adminFeatures[feature] ?? false,
                                  onChanged: (_) =>
                                      state.toggleAdminFeature(feature),
                                ),
                            ],
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

RcStatusTone _transferTone(String status) {
  return switch (status) {
    'Pending approval' => RcStatusTone.warning,
    'Approved' || 'In transit' => RcStatusTone.info,
    'Completed' => RcStatusTone.success,
    'Declined' => RcStatusTone.error,
    _ => RcStatusTone.neutral,
  };
}
