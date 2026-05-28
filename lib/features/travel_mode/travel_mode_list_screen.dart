import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/app/router.dart';
import 'package:social_gallery/core/utils/haptics.dart';
import 'package:social_gallery/domain/models/travel_mode.dart';
import 'package:social_gallery/shared/widgets/empty_state.dart';
import 'package:social_gallery/shared/widgets/motion/pressable_scale.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';
import 'package:social_gallery/shared/widgets/motion/staggered_entrance.dart';
import 'package:social_gallery/shared/widgets/one_ui/one_ui_page_header.dart';

class TravelModeListScreen extends ConsumerWidget {
  const TravelModeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            return const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OneUiPageHeader(
                  title: 'Travel Mode',
                  subtitle:
                      'Auto-organize photos from a date range into a folder.',
                ),
                Expanded(
                  child: EmptyState(
                    title: 'No trips yet',
                    message:
                        'Create a travel mode to auto-organize photos from a date range.',
                    icon: Icons.flight_outlined,
                  ),
                ),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: OneUiSpacing.xl),
            itemCount: modes.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return const OneUiPageHeader(
                  title: 'Travel Mode',
                  subtitle:
                      'Auto-organize photos from a date range into a folder.',
                );
              }
              final mode = modes[index - 1];
              final listIndex = index - 1;
              final status = travelModeStatus(mode);
              final statusLabel = switch (status) {
                TravelModeStatus.active => 'Active',
                TravelModeStatus.upcoming => 'Upcoming',
                TravelModeStatus.completed => 'Completed',
              };
              final statusColor = switch (status) {
                TravelModeStatus.active => theme.colorScheme.primary,
                TravelModeStatus.upcoming => theme.colorScheme.secondary,
                TravelModeStatus.completed =>
                  theme.colorScheme.onSurfaceVariant,
              };

              return StaggeredEntrance(
                index: listIndex,
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
                          '${_formatDay(mode.startDate)} - ${_formatDay(mode.endDate)}\n'
                          'Folder: ${mode.folderPath}',
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
          title: 'Could not load travel modes',
          message: e.toString(),
        ),
      ),
    );
  }

  static String _formatDay(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
