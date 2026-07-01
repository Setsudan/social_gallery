import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/app/router.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/core/utils/haptics.dart';
import 'package:social_gallery/domain/models/travel_mode.dart';
import 'package:social_gallery/shared/widgets/empty_state.dart';
import 'package:social_gallery/shared/widgets/motion/pressable_scale.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';
import 'package:social_gallery/shared/widgets/motion/staggered_entrance.dart';
import 'package:social_gallery/l10n/app_localizations.dart';

class TravelModeListScreen extends ConsumerWidget {
  const TravelModeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final modesAsync = ref.watch(travelModesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            AppHaptics.light();
            context.pop();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          AppHaptics.light();
          context.push(travelModeEditorLocation());
        },
        child: const Icon(Icons.add),
      ),
      body: modesAsync.when(
        data: (modes) {
          if (modes.isEmpty) {
            return EmptyState(
              title: l10n.travelModeEmptyTitle,
              message: l10n.travelModeEmptyMessage,
              icon: Icons.flight_outlined,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: OneUiSpacing.xl),
            itemCount: modes.length,
            separatorBuilder: (_, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final mode = modes[index];
              final listIndex = index;
              final status = travelModeStatus(mode);
              final statusLabel = _statusLabel(l10n, status);
              final statusColor = switch (status) {
                TravelModeStatus.active => theme.colorScheme.primary,
                TravelModeStatus.upcoming => theme.colorScheme.secondary,
                TravelModeStatus.completed =>
                  theme.colorScheme.onSurfaceVariant,
              };

              return StaggeredEntrance(
                index: listIndex,
                playOnceKey: 'travel_${mode.id}',
                child: Dismissible(
                  key: ValueKey(mode.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    color: theme.colorScheme.errorContainer,
                    child: Icon(
                      Icons.edit_outlined,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                  confirmDismiss: (_) async {
                    AppHaptics.light();
                    context.push(travelModeEditorLocation(id: mode.id));
                    return false;
                  },
                  child: PressableScale(
                    onTap: () {
                      AppHaptics.light();
                      context.push(travelModeEditorLocation(id: mode.id));
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(OneUiRadii.card),
                      ),
                      margin: const EdgeInsets.symmetric(
                        horizontal: OneUiSpacing.pageHorizontal,
                      ),
                      child: ListTile(
                        leading: Icon(Icons.flight, color: statusColor),
                        title: Text(mode.name),
                        subtitle: Text(
                          l10n.travelModeListSubtitle(
                            _formatDay(mode.startDate),
                            _formatDay(mode.endDate),
                            mode.folderPath,
                          ),
                        ),
                        isThreeLine: true,
                        trailing: Chip(
                          label: Text(statusLabel),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          title: l10n.travelModeErrorLoad,
          message: e.toString(),
        ),
      ),
    );
  }

  static String _statusLabel(AppLocalizations l10n, TravelModeStatus status) {
    return switch (status) {
      TravelModeStatus.active => l10n.travelModeStatusActive,
      TravelModeStatus.upcoming => l10n.travelModeStatusUpcoming,
      TravelModeStatus.completed => l10n.travelModeStatusCompleted,
    };
  }

  static String _formatDay(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
