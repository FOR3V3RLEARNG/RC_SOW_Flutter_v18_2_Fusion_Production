import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/control_modules.dart';
import '../core/routes.dart';
import '../core/widgets.dart';

class ControlLayoutScreen extends StatelessWidget {
  const ControlLayoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final modulesById = <String, ControlModuleDefinition>{
      for (final module in ControlModules.all) module.id: module,
    };
    final orderedModules = state.controlTileOrder
        .where(modulesById.containsKey)
        .map((id) => modulesById[id]!)
        .toList();
    return Scaffold(
      appBar: RcAppBar(
        title: const Text('Customize Control'),
        actions: <Widget>[
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, RcRoutes.control),
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('PREVIEW'),
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
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const RcPageHeading(
                          eyebrow: 'Control / Workspace design',
                          title: 'Change divisions and tiles',
                          description:
                              'Choose how modules are divided, reorder the custom sequence, hide tiles and control information density.',
                        ),
                        const SizedBox(height: 20),
                        const RcSectionHeader(
                          title: 'Division style',
                          subtitle:
                              'Lifecycle creates phase sections; Priority surfaces urgent work; Custom follows your tile order.',
                        ),
                        const SizedBox(height: 10),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                for (final grouping in const <String>[
                                  'Lifecycle',
                                  'Priority',
                                  'Custom',
                                ])
                                  ChoiceChip(
                                    avatar: Icon(
                                      switch (grouping) {
                                        'Lifecycle' =>
                                          Icons.account_tree_outlined,
                                        'Priority' => Icons.priority_high,
                                        _ => Icons.tune_outlined,
                                      },
                                      size: 18,
                                    ),
                                    label: Text(grouping),
                                    selected:
                                        state.controlGrouping == grouping,
                                    onSelected: (_) =>
                                        state.setControlGrouping(grouping),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const RcSectionHeader(
                          title: 'Tile density',
                          subtitle:
                              'Comfortable tiles show descriptions; Compact tiles show more modules at once.',
                        ),
                        const SizedBox(height: 10),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                for (final density in const <String>[
                                  'Comfortable',
                                  'Compact',
                                ])
                                  ChoiceChip(
                                    label: Text(density),
                                    selected: state.controlDensity == density,
                                    onSelected: (_) =>
                                        state.setControlDensity(density),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const RcSectionHeader(
                          title: 'Visible sections',
                          subtitle:
                              'The lifecycle filter remains available in every configuration.',
                        ),
                        const SizedBox(height: 10),
                        Card(
                          child: Column(
                            children: <Widget>[
                              SwitchListTile(
                                secondary:
                                    const Icon(Icons.view_carousel_outlined),
                                title: const Text('Delivery overview'),
                                subtitle: const Text(
                                  'Show the hero summary and lifecycle rail.',
                                ),
                                value: state.controlShowHero,
                                onChanged: (value) =>
                                    state.setControlSectionVisibility(
                                  showHero: value,
                                ),
                              ),
                              SwitchListTile(
                                secondary: const Icon(Icons.insights_outlined),
                                title: const Text('Operational insights'),
                                subtitle: const Text(
                                  'Show open, attention, transfer and crew metrics.',
                                ),
                                value: state.controlShowInsights,
                                onChanged: (value) =>
                                    state.setControlSectionVisibility(
                                  showInsights: value,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        RcSectionHeader(
                          title: 'Control tiles',
                          subtitle:
                              '${orderedModules.length - state.hiddenControlTiles.length} of ${orderedModules.length} visible',
                        ),
                        const SizedBox(height: 10),
                        Card(
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: <Widget>[
                              for (var index = 0;
                                  index < orderedModules.length;
                                  index++)
                                _TileControlRow(
                                  module: orderedModules[index],
                                  visible: !state.hiddenControlTiles.contains(
                                    orderedModules[index].id,
                                  ),
                                  canMoveUp: index > 0,
                                  canMoveDown:
                                      index < orderedModules.length - 1,
                                  onToggle: () => state.toggleControlTile(
                                    orderedModules[index].id,
                                  ),
                                  onMoveUp: () => state.moveControlTile(
                                    orderedModules[index].id,
                                    -1,
                                  ),
                                  onMoveDown: () => state.moveControlTile(
                                    orderedModules[index].id,
                                    1,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            FilledButton.icon(
                              onPressed: () =>
                                  Navigator.pushNamed(context, RcRoutes.control),
                              icon: const Icon(Icons.visibility_outlined),
                              label: const Text('PREVIEW CONTROL'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () {
                                state.resetControlLayout();
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Control layout restored to the connected default.',
                                      ),
                                    ),
                                  );
                              },
                              icon: const Icon(Icons.restart_alt),
                              label: const Text('RESET DEFAULT'),
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

class _TileControlRow extends StatelessWidget {
  const _TileControlRow({
    required this.module,
    required this.visible,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onToggle,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final ControlModuleDefinition module;
  final bool visible;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onToggle;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              module.icon,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  module.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  module.phase.label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Move ${module.title} up',
            onPressed: canMoveUp ? onMoveUp : null,
            icon: const Icon(Icons.keyboard_arrow_up),
          ),
          IconButton(
            tooltip: 'Move ${module.title} down',
            onPressed: canMoveDown ? onMoveDown : null,
            icon: const Icon(Icons.keyboard_arrow_down),
          ),
          Switch(
            value: visible,
            onChanged: (_) => onToggle(),
          ),
        ],
      ),
    );
  }
}
