import 'package:flutter/material.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';
import 'package:social_gallery/shared/widgets/motion/pressable_scale.dart';

class DiscoverHeroCard extends StatelessWidget {
  const DiscoverHeroCard({
    super.key,
    required this.unprocessedCount,
    required this.onTap,
  });

  final int unprocessedCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PressableScale(
      onTap: onTap,
      child: Card(
        color: theme.colorScheme.primaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OneUiRadii.card),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.swipe,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Organize',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Swipe through memories -- left delete, right favorite, up keep.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$unprocessedCount items waiting',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DiscoverHubCard extends StatelessWidget {
  const DiscoverHubCard({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OneUiRadii.card),
        ),
        child: ListTile(
          leading: leading,
          title: Text(title, style: Theme.of(context).textTheme.titleSmall),
          subtitle: Text(subtitle),
          trailing: Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
