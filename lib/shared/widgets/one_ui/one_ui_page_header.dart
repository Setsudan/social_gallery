import 'package:flutter/material.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';

/// Large in-body page title (One UI).
class OneUiPageHeader extends StatelessWidget {
  const OneUiPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding:
          padding ??
          const EdgeInsets.fromLTRB(
            OneUiSpacing.pageHorizontal,
            OneUiSpacing.pageTop,
            OneUiSpacing.pageHorizontal,
            OneUiSpacing.sm,
          ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.headlineLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: OneUiSpacing.sm),
                  Text(subtitle!, style: theme.textTheme.bodyMedium),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Section label above grouped content.
class OneUiSectionHeader extends StatelessWidget {
  const OneUiSectionHeader(this.label, {super.key, this.padding});

  final String label;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          padding ??
          const EdgeInsets.fromLTRB(
            OneUiSpacing.pageHorizontal,
            OneUiSpacing.lg,
            OneUiSpacing.pageHorizontal,
            OneUiSpacing.sm,
          ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
