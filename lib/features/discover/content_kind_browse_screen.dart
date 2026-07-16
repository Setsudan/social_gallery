import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/analysis/ocr_indexing_controller.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/core/utils/haptics.dart';
import 'package:social_gallery/domain/models/media_content_kind.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/shared/media/media_bulk_actions.dart';
import 'package:social_gallery/shared/navigation/media_viewer_session.dart';
import 'package:social_gallery/shared/pagination/paginated_list_notifier.dart';
import 'package:social_gallery/shared/widgets/empty_state.dart';
import 'package:social_gallery/shared/widgets/floating_selection_chrome.dart';
import 'package:social_gallery/shared/widgets/media_grid.dart';
import 'package:social_gallery/shared/widgets/one_ui/one_ui_subpage_scaffold.dart';

class ContentKindBrowseScreen extends ConsumerStatefulWidget {
  const ContentKindBrowseScreen({
    super.key,
    required this.kind,
  });

  final MediaContentKind kind;

  @override
  ConsumerState<ContentKindBrowseScreen> createState() =>
      _ContentKindBrowseScreenState();
}

class _ContentKindBrowseScreenState
    extends ConsumerState<ContentKindBrowseScreen> {
  final _scrollController = ScrollController();
  final _selectedIds = <int>{};
  final _ocrController = TextEditingController();
  String _ocrQuery = '';

  bool get _isDocument => widget.kind == MediaContentKind.document;
  bool get _inSelection => _selectedIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_isDocument) {
        await ref.read(mediaRepositoryProvider).backfillScreenshotContentKinds();
      }
      await ref
          .read(contentKindPaginatedProvider(widget.kind).notifier)
          .loadMore(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _ocrController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final paginated = ref.read(contentKindPaginatedProvider(widget.kind));
    handlePaginatedScroll(
      _scrollController.position,
      isLoading: paginated.isLoading,
      hasMore: paginated.hasMore,
      loadMore: () =>
          ref.read(contentKindPaginatedProvider(widget.kind).notifier).loadMore(),
    );
  }

  void _toggle(MediaItem item) {
    setState(() {
      if (_selectedIds.contains(item.id)) {
        _selectedIds.remove(item.id);
      } else {
        _selectedIds.add(item.id);
      }
    });
  }

  void _clearSelection() => setState(() => _selectedIds.clear());

  Future<void> _applyOcrFilter(String value) async {
    setState(() => _ocrQuery = value.trim());
    await ref
        .read(contentKindPaginatedProvider(widget.kind).notifier)
        .setOcrQuery(_ocrQuery);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = _isDocument
        ? l10n.discoverDocumentsTitle
        : l10n.discoverScreenshotsTitle;
    final emptyTitle = _isDocument
        ? l10n.discoverDocumentsEmptyTitle
        : l10n.discoverScreenshotsEmptyTitle;
    final emptyMessage = _isDocument
        ? l10n.discoverDocumentsEmptyMessage
        : l10n.discoverScreenshotsEmptyMessage;

    final paginated = ref.watch(contentKindPaginatedProvider(widget.kind));
    final ocrState = ref.watch(ocrIndexingProvider);
    final items = paginated.items;

    return OneUiSubpageScaffold(
      appBarTitle: _inSelection
          ? l10n.selectionCount(_selectedIds.length)
          : title,
      onBack: () {
        AppHaptics.light();
        if (_inSelection) {
          _clearSelection();
        } else {
          Navigator.of(context).maybePop();
        }
      },
      actions: [
        if (_isDocument && !ocrState.isScanning)
          IconButton(
            tooltip: l10n.discoverOcrIndexAction,
            icon: const Icon(Icons.document_scanner_outlined),
            onPressed: () {
              AppHaptics.light();
              ref.read(ocrIndexingProvider.notifier).startScan();
            },
          ),
        if (_isDocument && ocrState.isScanning)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                l10n.discoverOcrIndexProgress(
                  ocrState.scanned,
                  ocrState.total,
                ),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
      ],
      isLoading: items.isEmpty && paginated.isLoading,
      isEmpty: items.isEmpty && !paginated.isLoading,
      empty: EmptyState(
        title: emptyTitle,
        message: emptyMessage,
        icon: _isDocument
            ? Icons.description_outlined
            : Icons.screenshot_outlined,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (_isDocument)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    controller: _ocrController,
                    decoration: InputDecoration(
                      hintText: l10n.discoverDocumentsSearchHint,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _ocrQuery.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _ocrController.clear();
                                _applyOcrFilter('');
                              },
                            ),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: _applyOcrFilter,
                  ),
                ),
              Expanded(
                child: MediaGrid(
                  controller: _scrollController,
                  items: items,
                  selectedIds: _selectedIds,
                  isLoadingMore: paginated.isLoading && items.isNotEmpty,
                  onTap: (item) => openMediaViewer(
                    context,
                    ref,
                    items: items,
                    item: item,
                  ),
                  onLongPress: _toggle,
                  onSelectToggle: _toggle,
                ),
              ),
            ],
          ),
          if (_inSelection)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FloatingSelectionActionBar(
                onDelete: () => bulkTrash(
                  ref,
                  context,
                  _selectedIds,
                  onDone: _clearSelection,
                  useHaptics: true,
                ),
                onMove: () => bulkMove(
                  ref,
                  context,
                  _selectedIds,
                  onDone: _clearSelection,
                  useHaptics: true,
                ),
                onShare: () => bulkShare(
                  ref,
                  context,
                  _selectedIds,
                  onDone: _clearSelection,
                ),
                onMore: () {},
              ),
            ),
        ],
      ),
    );
  }
}
