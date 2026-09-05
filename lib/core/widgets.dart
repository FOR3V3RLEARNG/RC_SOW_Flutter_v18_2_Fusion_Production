import 'package:flutter/material.dart';

import 'app_state.dart';
import 'models.dart';
import 'routes.dart';
import 'theme.dart';

class RcAppBar extends AppBar {
  RcAppBar({
    Key? key,
    Widget? title,
    Widget? leading,
    bool automaticallyImplyLeading = true,
    double? titleSpacing,
    List<Widget>? actions,
    bool showGlobalActions = true,
  }) : super(
          key: key,
          title: title == null
              ? null
              : DefaultTextStyle.merge(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  child: title,
                ),
          leading: leading,
          automaticallyImplyLeading: automaticallyImplyLeading,
          titleSpacing: titleSpacing,
          actions: <Widget>[
            ...?actions,
            if (showGlobalActions) const RcGlobalActions(),
          ],
        );
}

class RcGlobalActions extends StatelessWidget {
  const RcGlobalActions({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          tooltip: 'Live tracker map',
          visualDensity: VisualDensity.compact,
          onPressed: () =>
              Navigator.pushNamed(context, RcRoutes.operationalMap),
          icon: const Icon(Icons.location_on_outlined),
        ),
        IconButton(
          tooltip: 'Messages',
          visualDensity: VisualDensity.compact,
          onPressed: () => Navigator.pushNamed(context, RcRoutes.messages),
          icon: Badge(
            isLabelVisible: state.unreadNotifications > 0,
            label: Text('${state.unreadNotifications}'),
            child: const Icon(Icons.chat_bubble_outline),
          ),
        ),
        IconButton(
          tooltip: 'Settings',
          visualDensity: VisualDensity.compact,
          onPressed: () => Navigator.pushNamed(context, RcRoutes.settings),
          icon: const Icon(Icons.settings_outlined),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

class RcBrand extends StatelessWidget {
  const RcBrand({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const SizedBox(
          width: 34,
          height: 34,
          child: CustomPaint(painter: _RcMarkPainter()),
        ),
        if (!compact) ...<Widget>[
          const SizedBox(width: 9),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'RC SOW',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              Text(
                'OPERATIONS',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.3),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _RcMarkPainter extends CustomPainter {
  const _RcMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final red = Paint()
      ..color = RcColors.brand
      ..style = PaintingStyle.fill;
    final soft = Paint()
      ..color = RcColors.brandSoft
      ..style = PaintingStyle.fill;
    final line = Paint()
      ..color = RcColors.brand
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10)),
      soft,
    );
    final roof = Path()
      ..moveTo(size.width * .18, size.height * .48)
      ..lineTo(size.width * .5, size.height * .22)
      ..lineTo(size.width * .82, size.height * .48);
    canvas.drawPath(roof, line);
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * .28,
        size.height * .46,
        size.width * .44,
        size.height * .34,
      ),
      line,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width * .5, size.height * .57),
        width: size.width * .28,
        height: size.height * .09,
      ),
      red,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width * .5, size.height * .57),
        width: size.width * .09,
        height: size.height * .28,
      ),
      red,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RcPageHeading extends StatelessWidget {
  const RcPageHeading({
    required this.eyebrow,
    required this.title,
    required this.description,
    this.action,
    super.key,
  });

  final String eyebrow;
  final String title;
  final String description;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              eyebrow.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
            ),
            const SizedBox(height: 7),
            Text(title, style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Text(
                description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        );
        if (action == null) return copy;
        if (constraints.maxWidth < 720) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              copy,
              const SizedBox(height: 14),
              Align(alignment: Alignment.centerLeft, child: action!),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: copy),
            const SizedBox(width: 16),
            action!,
          ],
        );
      },
    );
  }
}

class RcStatusChip extends StatelessWidget {
  const RcStatusChip({
    required this.label,
    this.icon,
    this.tone = RcStatusTone.neutral,
    this.compact = false,
    super.key,
  });

  final String label;
  final IconData? icon;
  final RcStatusTone tone;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = _statusColors(context, tone);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 11,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.$2.withOpacity(.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: compact ? 14 : 16, color: colors.$2),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: colors.$2, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

enum RcStatusTone { brand, success, warning, info, error, neutral }

(Color, Color) _statusColors(BuildContext context, RcStatusTone tone) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  switch (tone) {
    case RcStatusTone.brand:
      return (
        dark ? const Color(0xFF5C1E22) : RcColors.brandSoft,
        Theme.of(context).colorScheme.primary,
      );
    case RcStatusTone.success:
      return (
        dark ? const Color(0xFF173E23) : RcColors.successSoft,
        dark ? const Color(0xFF82D798) : RcColors.success,
      );
    case RcStatusTone.warning:
      return (
        dark ? const Color(0xFF513500) : RcColors.warningSoft,
        dark ? const Color(0xFFFFC56C) : RcColors.warning,
      );
    case RcStatusTone.info:
      return (
        dark ? const Color(0xFF16384F) : RcColors.infoSoft,
        dark ? const Color(0xFF85C7F5) : RcColors.info,
      );
    case RcStatusTone.error:
      return (
        Theme.of(context).colorScheme.errorContainer,
        Theme.of(context).colorScheme.onErrorContainer,
      );
    case RcStatusTone.neutral:
      return (
        Theme.of(context).colorScheme.surfaceContainerHighest,
        Theme.of(context).colorScheme.onSurfaceVariant,
      );
  }
}

class RcSyncBanner extends StatelessWidget {
  const RcSyncBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final waiting =
        state.syncCondition == SyncCondition.waiting || state.offline;
    final tone = waiting ? RcStatusTone.warning : RcStatusTone.success;
    final label = waiting && state.queuedChanges > 0
        ? '${state.queuedChanges} change${state.queuedChanges == 1 ? '' : 's'} waiting to sync'
        : state.syncCondition.label;
    return Material(
      color: _statusColors(context, tone).$1,
      child: InkWell(
        onTap: state.toggleOffline,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                state.syncCondition.icon,
                size: 17,
                color: _statusColors(context, tone).$2,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: _statusColors(context, tone).$2,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                state.offline ? 'Go online' : 'Simulate offline',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _statusColors(context, tone).$2,
                      decoration: TextDecoration.underline,
                      decorationColor: _statusColors(context, tone).$2,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RcMetricTile extends StatelessWidget {
  const RcMetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color.alphaBlend(
        color.withOpacity(.035),
        Theme.of(context).colorScheme.surface,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withOpacity(.12),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(9),
                        bottomLeft: Radius.circular(9),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Icon(icon, size: 21, color: color),
                  ),
                  const Spacer(),
                  if (onTap != null)
                    Icon(
                      Icons.arrow_outward_rounded,
                      size: 19,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
              const Spacer(),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: color,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RcSectionHeader extends StatelessWidget {
  const RcSectionHeader({
    required this.title,
    this.subtitle,
    this.trailing,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: 3),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
    if (trailing == null) return copy;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              copy,
              const SizedBox(height: 8),
              trailing!,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(child: copy),
            const SizedBox(width: 12),
            trailing!,
          ],
        );
      },
    );
  }
}

class RcLifecycleRail extends StatelessWidget {
  const RcLifecycleRail({required this.phase, this.compact = false, super.key});

  final LifecyclePhase phase;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final current = LifecyclePhase.values.indexOf(phase);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          for (var index = 0;
              index < LifecyclePhase.values.length;
              index++) ...<Widget>[
            _PhaseNode(
              phase: LifecyclePhase.values[index],
              state: index < current
                  ? _PhaseNodeState.complete
                  : index == current
                      ? _PhaseNodeState.current
                      : _PhaseNodeState.future,
              compact: compact,
            ),
            if (index != LifecyclePhase.values.length - 1)
              Container(
                width: compact ? 18 : 30,
                height: 2,
                color: index < current
                    ? RcColors.success
                    : Theme.of(context).colorScheme.outlineVariant,
              ),
          ],
        ],
      ),
    );
  }
}

enum _PhaseNodeState { complete, current, future }

class _PhaseNode extends StatelessWidget {
  const _PhaseNode({
    required this.phase,
    required this.state,
    required this.compact,
  });

  final LifecyclePhase phase;
  final _PhaseNodeState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _PhaseNodeState.complete => RcColors.success,
      _PhaseNodeState.current => Theme.of(context).colorScheme.primary,
      _PhaseNodeState.future => Theme.of(context).colorScheme.outline,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: compact ? 31 : 38,
          height: compact ? 31 : 38,
          decoration: BoxDecoration(
            color: state == _PhaseNodeState.future
                ? Theme.of(context).colorScheme.surface
                : color,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(
            state == _PhaseNodeState.complete ? Icons.check : phase.icon,
            size: compact ? 15 : 18,
            color: state == _PhaseNodeState.future ? color : Colors.white,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          phase.label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: state == _PhaseNodeState.current
                    ? FontWeight.w900
                    : FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class RcHouseCard extends StatelessWidget {
  const RcHouseCard({
    required this.house,
    required this.onOpen,
    this.photoUri,
    this.onScope,
    this.onControl,
    this.onCrew,
    super.key,
  });

  final HouseRecord house;
  final VoidCallback onOpen;
  final String? photoUri;
  final VoidCallback? onScope;
  final VoidCallback? onControl;
  final VoidCallback? onCrew;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUri != null && photoUri!.trim().isNotEmpty;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AspectRatio(
              aspectRatio: 2.1,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  if (hasPhoto)
                    Image.network(
                      photoUri!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const _HousePhotoPlaceholder(),
                    )
                  else
                    const _HousePhotoPlaceholder(),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: RcStatusChip(
                      label: house.code,
                      compact: true,
                      tone: house.needsAttention
                          ? RcStatusTone.warning
                          : RcStatusTone.brand,
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: RcStatusChip(
                      label: house.phase.label.toUpperCase(),
                      compact: true,
                      tone: RcStatusTone.info,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 14, 15, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    house.beneficiary.isEmpty ? 'Beneficiary not assigned' : house.beneficiary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${house.community} • ${house.parish}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: house.progress.clamp(0, 1),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      _HouseMiniFact(
                        icon: Icons.photo_library_outlined,
                        label: '${house.evidenceComplete}/${house.evidenceRequired}',
                        tooltip: 'Evidence',
                      ),
                      const SizedBox(width: 12),
                      _HouseMiniFact(
                        icon: Icons.groups_2_outlined,
                        label: '${house.team.length}',
                        tooltip: 'Crew',
                      ),
                      const SizedBox(width: 12),
                      _HouseMiniFact(
                        icon: Icons.roofing_outlined,
                        label: house.roofArea > 0
                            ? '${house.roofArea.toStringAsFixed(0)} ft²'
                            : 'Roof',
                        tooltip: 'Roof',
                      ),
                      const Spacer(),
                      Text(
                        '${(house.progress * 100).round()}%',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  if (house.team.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: house.team
                          .take(3)
                          .map(
                            (name) => Chip(
                              visualDensity: VisualDensity.compact,
                              avatar: const Icon(Icons.person_outline, size: 14),
                              label: Text(
                                name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _HouseQuickButton(
                          icon: Icons.architecture_outlined,
                          label: 'Scope',
                          onTap: onScope ?? onOpen,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _HouseQuickButton(
                          icon: Icons.build_outlined,
                          label: 'Control',
                          onTap: onControl ?? onOpen,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _HouseQuickButton(
                          icon: Icons.groups_outlined,
                          label: 'Crew',
                          onTap: onCrew ?? onOpen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HousePhotoPlaceholder extends StatelessWidget {
  const _HousePhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
      child: Center(
        child: Icon(
          Icons.add_a_photo_outlined,
          size: 40,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _HouseMiniFact extends StatelessWidget {
  const _HouseMiniFact({
    required this.icon,
    required this.label,
    required this.tooltip,
  });
  final IconData icon;
  final String label;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15),
          const SizedBox(width: 3),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _HouseQuickButton extends StatelessWidget {
  const _HouseQuickButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 15),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RcNextActionCard extends StatelessWidget {
  const RcNextActionCard({
    required this.house,
    required this.onPressed,
    super.key,
  });

  final HouseRecord house;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              Icons.auto_awesome_outlined,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'SMART NEXT ACTION',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  house.nextAction,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
              ],
            ),
          ),
          IconButton.filled(
            onPressed: onPressed,
            icon: const Icon(Icons.arrow_forward),
          ),
        ],
      ),
    );
  }
}

class RcEmptyState extends StatelessWidget {
  const RcEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 34,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 7),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              if (action != null) ...<Widget>[
                const SizedBox(height: 18),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class RcResponsiveGrid extends StatelessWidget {
  const RcResponsiveGrid({
    required this.children,
    this.minItemWidth = 240,
    this.childAspectRatio = 1.35,
    super.key,
  });

  final List<Widget> children;
  final double minItemWidth;
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count =
            (constraints.maxWidth / minItemWidth).floor().clamp(1, 4).toInt();
        return GridView.count(
          crossAxisCount: count,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: childAspectRatio,
          children: children,
        );
      },
    );
  }
}

void showSavedMessage(BuildContext context, {required bool submitted}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: <Widget>[
            Icon(
              submitted ? Icons.send_outlined : Icons.cloud_done_outlined,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                submitted
                    ? 'Submitted successfully. The approval trail is now active.'
                    : 'Draft saved. Your work is safe.',
              ),
            ),
          ],
        ),
      ),
    );
}
