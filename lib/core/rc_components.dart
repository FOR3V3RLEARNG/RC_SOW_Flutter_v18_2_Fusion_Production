import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'design_tokens.dart';
import 'ui_studio.dart';

enum RcSurfaceShape { standard, hero, offset, pill }

class RcExpressiveSurface extends StatefulWidget {
  const RcExpressiveSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(RcLayout.cardPadding),
    this.shape = RcSurfaceShape.standard,
    this.tone,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final RcSurfaceShape shape;
  final Color? tone;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  State<RcExpressiveSurface> createState() => _RcExpressiveSurfaceState();
}

class _RcExpressiveSurfaceState extends State<RcExpressiveSurface> {
  bool pressed = false;

  BorderRadius _radius(double expression) => switch (widget.shape) {
    RcSurfaceShape.standard =>
      BorderRadius.circular(RcRadius.lg + expression * 3),
    RcSurfaceShape.hero => BorderRadius.only(
      topLeft: Radius.circular(34 + expression * 8),
      topRight: Radius.circular(18 + expression * 4),
      bottomLeft: Radius.circular(18 + expression * 4),
      bottomRight: Radius.circular(34 + expression * 8),
    ),
    RcSurfaceShape.offset => BorderRadius.only(
      topLeft: Radius.circular(13 + expression * 4),
      topRight: Radius.circular(27 + expression * 7),
      bottomLeft: Radius.circular(27 + expression * 7),
      bottomRight: Radius.circular(13 + expression * 4),
    ),
    RcSurfaceShape.pill => BorderRadius.circular(999),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ui = theme.extension<RcUiVisuals>() ?? const RcUiVisuals();
    final radius = _radius(ui.expressiveness);
    final base = widget.tone ?? theme.colorScheme.surface;
    final interactive = widget.onTap != null;
    final accent = ui.accent;

    final pressedTone = Color.alphaBlend(
      accent.withValues(alpha: .07 + ui.expressiveness * .07),
      base,
    );
    final topLift = Color.alphaBlend(
      Colors.white.withValues(
        alpha: ui.surfaceFinish == 'clean'
            ? .015
            : .035 + ui.expressiveness * .035,
      ),
      pressed ? pressedTone : base,
    );
    final bottomTint = Color.alphaBlend(
      accent.withValues(
        alpha: ui.surfaceFinish == 'suede'
            ? .020 + ui.expressiveness * .018
            : .010,
      ),
      pressed ? pressedTone : base,
    );
    final contactShadow = ui.depth * (pressed ? 2.0 : 7.5);
    final ambientShadow = ui.depth * (pressed ? 5.0 : 20.0);

    final surface = AnimatedContainer(
      duration: Duration(
        milliseconds: 95 + (ui.expressiveness * 65).round(),
      ),
      curve: Curves.easeOutCubic,
      transformAlignment: Alignment.center,
      transform: Matrix4.identity()
        ..translate(0.0, pressed ? 2.2 + ui.depth * 1.5 : 0.0)
        ..scale(pressed ? .994 : 1.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: ui.surfaceFinish == 'clean'
              ? [pressed ? pressedTone : base, pressed ? pressedTone : base]
              : [topLift, pressed ? pressedTone : base, bottomTint],
          stops: ui.surfaceFinish == 'clean' ? null : const [0, .52, 1],
        ),
        borderRadius: radius,
        border: Border.all(
          color: pressed
              ? accent.withValues(alpha: .28 + ui.expressiveness * .15)
              : theme.colorScheme.outlineVariant.withValues(
                  alpha: .78 + ui.depth * .18,
                ),
          width: pressed ? 1.35 : 1,
        ),
        boxShadow: interactive || ui.depth > .45
            ? [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(
                    alpha: pressed ? .025 : .035 + ui.depth * .065,
                  ),
                  blurRadius: ambientShadow,
                  offset: Offset(0, pressed ? 2 : 8 * ui.depth),
                ),
                BoxShadow(
                  color: accent.withValues(
                    alpha: pressed ? .015 : .018 + ui.depth * .025,
                  ),
                  blurRadius: contactShadow,
                  offset: Offset(0, pressed ? 1 : 2.5),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          splashColor: accent.withValues(alpha: .10),
          highlightColor: accent.withValues(alpha: .055),
          onTap: widget.onTap,
          onHighlightChanged: interactive
              ? (value) {
                  if (mounted) setState(() => pressed = value);
                }
              : null,
          child: Padding(padding: widget.padding, child: widget.child),
        ),
      ),
    );

    if (!interactive) return surface;
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: surface,
    );
  }
}

class RcIconWell extends StatelessWidget {
  const RcIconWell({
    super.key,
    required this.icon,
    this.color,
    this.size = 48,
    this.iconSize,
  });

  final IconData icon;
  final Color? color;
  final double size;
  final double? iconSize;

  BorderRadius _radius(String shape) => switch (shape) {
    'circle' => BorderRadius.circular(999),
    'pill' => BorderRadius.circular(size * .48),
    'soft' => BorderRadius.circular(size * .22),
    _ => BorderRadius.only(
      topLeft: Radius.circular(size * .32),
      topRight: Radius.circular(size * .18),
      bottomLeft: Radius.circular(size * .18),
      bottomRight: Radius.circular(size * .32),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ui = theme.extension<RcUiVisuals>() ?? const RcUiVisuals();
    final c = color ?? ui.accent;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            c.withValues(alpha: .19),
            c.withValues(alpha: .10),
          ],
        ),
        borderRadius: _radius(ui.iconShape),
        border: Border.all(
          color: c.withValues(alpha: .20 + ui.expressiveness * .13),
        ),
        boxShadow: [
          BoxShadow(
            color: c.withValues(alpha: .07 + ui.depth * .06),
            blurRadius: 8 + ui.depth * 8,
            offset: Offset(0, 2 + ui.depth * 3),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: iconSize ?? size * .46,
        color: c,
      ),
    );
  }
}

class RcPageHeading extends StatelessWidget {
  const RcPageHeading({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                Text(
                  eyebrow!.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(title, style: theme.textTheme.headlineMedium),
              if (subtitle != null) ...[
                const SizedBox(height: 5),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

class RcStatusPill extends StatelessWidget {
  const RcStatusPill({super.key, required this.label, this.icon, this.color});

  final String label;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: c.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: RcIconSize.xs, color: c),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: c,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class RcProgressOrb extends StatelessWidget {
  const RcProgressOrb({
    super.key,
    required this.value,
    required this.label,
    this.size = 82,
    this.color,
  });

  final double value;
  final String label;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    final clamped = value.clamp(0.0, 1.0).toDouble();
    return Semantics(
      label: '$label ${(clamped * 100).round()} percent',
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _ProgressOrbPainter(value: clamped, color: c),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(clamped * 100).round()}%',
                  style: TextStyle(
                    color: c,
                    fontSize: size * .22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: size * .105,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressOrbPainter extends CustomPainter {
  const _ProgressOrbPainter({required this.value, required this.color});
  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = math.max(5.0, size.shortestSide * .075);
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2 + 1);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: .12);
    final progress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(arcRect, -math.pi / 2, math.pi * 2, false, track);
    canvas.drawArc(arcRect, -math.pi / 2, math.pi * 2 * value, false, progress);
  }

  @override
  bool shouldRepaint(covariant _ProgressOrbPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.color != color;
}

class RcResponsiveGrid extends StatelessWidget {
  const RcResponsiveGrid({
    super.key,
    required this.children,
    this.minTileWidth = 190,
    this.spacing = RcLayout.cardGap,
    this.childAspectRatio = 1.8,
  });

  final List<Widget> children;
  final double minTileWidth;
  final double spacing;
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = math.max(
          1,
          ((constraints.maxWidth + spacing) / (minTileWidth + spacing)).floor(),
        );
        return GridView.count(
          crossAxisCount: count,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: childAspectRatio,
          children: children,
        );
      },
    );
  }
}

class RcCommandButton extends StatelessWidget {
  const RcCommandButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final button = emphasized
        ? FilledButton.tonalIcon(
            onPressed: onPressed,
            icon: Icon(icon, size: RcIconSize.sm),
            label: Text(label),
          )
        : TextButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: RcIconSize.sm),
            label: Text(label),
          );
    return Semantics(button: true, label: label, child: button);
  }
}
