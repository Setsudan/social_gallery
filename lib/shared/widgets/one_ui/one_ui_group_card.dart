import 'package:flutter/material.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';

/// Rounded grouped container for settings-style lists (One UI).
class OneUiGroupCard extends StatelessWidget {
  const OneUiGroupCard({
    super.key,
    required this.child,
    this.title,
    this.icon,
    this.margin,
  });

  final Widget child;
  final String? title;
  final IconData? icon;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding:
          margin ??
          const EdgeInsets.symmetric(horizontal: OneUiSpacing.pageHorizontal),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(OneUiSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null) ...[
                Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 22, color: theme.colorScheme.primary),
                      const SizedBox(width: OneUiSpacing.sm),
                    ],
                    Text(
                      title!,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: OneUiSpacing.md),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Tappable row inside a [OneUiGroupCard].
class OneUiListRow extends StatelessWidget {
  const OneUiListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.onTap,
    this.trailing = const Icon(Icons.chevron_right, size: 20),
    this.showDivider = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        if (showDivider)
          Divider(
            height: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.6),
          ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: leading,
          title: Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: subtitle != null ? Text(subtitle!) : null,
          trailing: trailing,
          onTap: onTap,
        ),
      ],
    );
  }
}
