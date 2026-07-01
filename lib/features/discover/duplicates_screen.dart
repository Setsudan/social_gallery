import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/app/router.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/shared/navigation/media_viewer_session.dart';
import 'package:social_gallery/core/layout/responsive_grid.dart';
import 'package:social_gallery/domain/models/duplicate_group.dart';
import 'package:social_gallery/core/notifications/duplicate_scan_notification_service.dart';
import 'package:social_gallery/features/discover/discover_providers.dart';
import 'package:social_gallery/shared/widgets/empty_state.dart';
import 'package:social_gallery/shared/widgets/media_thumbnail.dart';
import 'package:social_gallery/shared/widgets/one_ui/one_ui_subpage_scaffold.dart';

class DuplicatesScreen extends ConsumerStatefulWidget {
  const DuplicatesScreen({super.key});

  @override
  ConsumerState<DuplicatesScreen> createState() => _DuplicatesScreenState();
}

class _DuplicatesScreenState extends ConsumerState<DuplicatesScreen> {
  DuplicateGroup? _selected;
  DuplicateScanNotificationService? _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = ref.read(duplicateScanNotificationServiceProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifications?.setDuplicatesScreenVisible(true);
      ref.read(duplicateScanControllerProvider.notifier).ensureStarted();
    });
  }

  @override
  void dispose() {
    _notifications?.setDuplicatesScreenVisible(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scan = ref.watch(duplicateScanControllerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_selected != null) {
              setState(() => _selected = null);
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: _buildBody(scan),
    );
  }

  Widget _buildBody(DuplicateScanState scan) {
    final l10n = context.l10n;
    if (scan.error != null) {
      return OneUiSubpageScaffold(
        error: scan.error,
        body: const SizedBox.shrink(),
      );
    }

    if (!scan.isComplete) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (scan.total > 0)
                LinearProgressIndicator(value: scan.progress)
              else
                const LinearProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                scan.total > 0
                    ? l10n.duplicateScanProgress(scan.scanned, scan.total)
                    : l10n.duplicateScanPreparing,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final groups = scan.groups!;
    return _selected == null
        ? _buildGroupList(groups)
        : _buildGroupDetail();
  }

  Widget _buildGroupList(List<DuplicateGroup> groups) {
    final l10n = context.l10n;
    if (groups.isEmpty) {
      return OneUiSubpageScaffold(
        isEmpty: true,
        empty: EmptyState(
          title: l10n.duplicatesEmptyTitle,
          message: l10n.duplicatesEmptyMessage,
          icon: Icons.check_circle_outline,
        ),
        body: const SizedBox.shrink(),
      );
    }

    final columns = gridCrossAxisCountForWidth(
      MediaQuery.sizeOf(context).width,
    );

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        final cover = group.items.first;
        return GestureDetector(
          onTap: () => setState(() => _selected = group),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: MediaThumbnail(assetId: cover.uri),
              ),
              Positioned(
                left: 6,
                right: 6,
                bottom: 6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(
                      l10n.duplicatesGroupBadge(group.count),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGroupDetail() {
    final group = _selected!;
    final l10n = context.l10n;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: () => context.push(duplicateReviewLocation(group.key)),
            icon: const Icon(Icons.auto_fix_high),
            label: Text(l10n.duplicatesKeepBestAndReview),
          ),
        ),
        Builder(
          builder: (context) {
            final columns = gridCrossAxisCountForWidth(
              MediaQuery.sizeOf(context).width,
            );

            return Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: group.items.length,
                itemBuilder: (context, index) {
                  final media = group.items[index];
                  return GestureDetector(
                    onTap: () => openMediaViewer(
                      context,
                      ref,
                      items: group.items,
                      item: media,
                    ),
                    child: MediaThumbnail(
                      assetId: media.uri,
                      showVideoBadge: media.isVideo,
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
