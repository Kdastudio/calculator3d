import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Painel unificado — um cartão grande com seções internas.
class UnifiedPanel extends StatelessWidget {
  const UnifiedPanel({
    super.key,
    required this.title,
    this.subtitle,
    this.child,
    this.children,
  });

  final String title;
  final String? subtitle;
  final Widget? child;
  final List<Widget>? children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: AppTheme.border.withValues(alpha: 0.5)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child ?? Column(children: children!),
          ),
        ],
      ),
    );
  }
}

class PanelSection extends StatelessWidget {
  const PanelSection({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.trailing,
    this.showDivider = true,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final Widget? trailing;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: AppTheme.textMuted),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: 12),
        child,
        if (showDivider) ...[
          const SizedBox(height: 18),
          Divider(height: 1, color: AppTheme.border.withValues(alpha: 0.45)),
          const SizedBox(height: 18),
        ],
      ],
    );
  }
}

class FadeInBox extends StatefulWidget {
  const FadeInBox({super.key, required this.child, this.duration = const Duration(milliseconds: 280)});

  final Widget child;
  final Duration duration;

  @override
  State<FadeInBox> createState() => _FadeInBoxState();
}

class _FadeInBoxState extends State<FadeInBox> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero).animate(_fade);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
