import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: AppTheme.textMuted),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title!, style: Theme.of(context).textTheme.titleLarge),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
          if (title != null)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Divider(height: 1),
            ),
          Padding(
            padding: title != null
                ? padding.copyWith(top: 14)
                : padding,
            child: child,
          ),
        ],
      ),
    );
  }
}

class FormFieldGroup extends StatelessWidget {
  const FormFieldGroup({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(title, style: Theme.of(context).textTheme.labelSmall),
        ),
        child,
      ],
    );
  }
}

class AppIconBadge extends StatelessWidget {
  const AppIconBadge({
    super.key,
    required this.icon,
    this.color,
    this.size = 18,
  });

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(icon, size: size, color: color ?? AppTheme.textSecondary);
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.labelSmall);
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
    this.outlined = false,
    this.compact = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final bool outlined;
  final bool compact;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final height = compact ? 34.0 : 36.0;
    final accent = color ?? AppTheme.accent;

    Widget button;
    if (outlined) {
      button = icon != null
          ? OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 15),
              label: Text(label),
              style: OutlinedButton.styleFrom(foregroundColor: accent),
            )
          : OutlinedButton(onPressed: onPressed, child: Text(label));
    } else if (color != null) {
      button = icon != null
          ? FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 15),
              label: Text(label),
              style: FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                side: BorderSide.none,
              ),
            )
          : FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(backgroundColor: color, side: BorderSide.none),
              child: Text(label),
            );
    } else {
      button = icon != null
          ? FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 15),
              label: Text(label),
            )
          : FilledButton(onPressed: onPressed, child: Text(label));
    }

    if (!expand) return button;
    return SizedBox(width: double.infinity, height: height, child: button);
  }
}

class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (icon == null) {
      return TextButton(onPressed: onPressed, child: Text(label));
    }
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 15),
      label: Text(label),
    );
  }
}

class MetricCell extends StatelessWidget {
  const MetricCell({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.accentColor,
    this.bold = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? accentColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppTheme.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: accent.withValues(alpha: 0.85)),
                const SizedBox(width: 5),
              ],
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        letterSpacing: 0.3,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: bold ? 18 : 15,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                  letterSpacing: bold ? -0.4 : -0.2,
                  color: bold ? (accentColor ?? AppTheme.textPrimary) : AppTheme.textPrimary,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class MetricsPanel extends StatelessWidget {
  const MetricsPanel({super.key, required this.metrics, this.premium = false});

  final List<MetricCell> metrics;
  final bool premium;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 640;

        final decoration = BoxDecoration(
          color: premium ? AppTheme.card : AppTheme.surfaceRaised,
          borderRadius: BorderRadius.circular(premium ? AppTheme.radiusLg : AppTheme.radiusMd),
          border: premium ? null : Border.all(color: AppTheme.borderSubtle),
          boxShadow: premium
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        );

        if (wide) {
          return Container(
            decoration: decoration,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < metrics.length; i++) ...[
                    if (i > 0)
                      VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: AppTheme.border.withValues(alpha: 0.6),
                      ),
                    Expanded(child: metrics[i]),
                  ],
                ],
              ),
            ),
          );
        }

        return Container(
          decoration: decoration,
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.8,
            padding: EdgeInsets.zero,
            children: metrics,
          ),
        );
      },
    );
  }
}

class StatusDot extends StatelessWidget {
  const StatusDot({super.key, required this.label, this.active = true});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: active
            ? AppTheme.success.withValues(alpha: 0.12)
            : AppTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: active
              ? AppTheme.success.withValues(alpha: 0.22)
              : AppTheme.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: active ? AppTheme.success : AppTheme.textMuted,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: active ? AppTheme.success : AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class AppBanner extends StatelessWidget {
  const AppBanner({
    super.key,
    required this.icon,
    required this.message,
    this.action,
    this.tone = AppBannerTone.neutral,
  });

  final IconData icon;
  final String message;
  final Widget? action;
  final AppBannerTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, border, iconColor) = switch (tone) {
      AppBannerTone.warning => (
          AppTheme.warning.withValues(alpha: 0.1),
          AppTheme.warning.withValues(alpha: 0.22),
          AppTheme.warning,
        ),
      AppBannerTone.success => (
          AppTheme.success.withValues(alpha: 0.1),
          AppTheme.success.withValues(alpha: 0.22),
          AppTheme.success,
        ),
      AppBannerTone.neutral => (
          AppTheme.surfaceRaised,
          AppTheme.border,
          AppTheme.textMuted,
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodySmall),
          ),
          ?action,
        ],
      ),
    );
  }
}

enum AppBannerTone { neutral, warning, success }

// Alias para compatibilidade
typedef ResultTile = MetricCell;
