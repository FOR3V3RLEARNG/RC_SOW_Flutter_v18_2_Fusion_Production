import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'design_tokens.dart';

enum RcSurfaceShape { standard, hero, offset, pill }

class RcExpressiveSurface extends StatelessWidget {
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

  BorderRadius _radius() => switch (shape) {
    RcSurfaceShape.standard => BorderRadius.circular(RcRadius.lg),
    RcSurfaceShape.hero => const BorderRadius.only(
      topLeft: Radius.circular(36),
      topRight: Radius.circular(18),
      bottomLeft: Radius.circular(18),
      bottomRight: Radius.circular(36),
    ),
    RcSurfaceShape.offset => const BorderRadius.only(
      topLeft: Radius.circular(14),
      topRight: Radius.circular(30),
      bottomLeft: Radius.circular(30),
      bottomRight: Radius.circular(14),
    ),
    RcSurfaceShape.pill => BorderRadius.circular(999),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = _radius();
    final surface = DecoratedBox(
      decoration: BoxDecoration(
        color: tone ?? theme.colorScheme.surface,
        borderRadius: radius,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return surface;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(borderRadius: radius, onTap: onTap, child: surface),
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
