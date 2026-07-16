import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/core/utils/haptics.dart';
import 'package:social_gallery/core/widgets/widget_update_service.dart';
import 'package:social_gallery/domain/models/folder_info.dart';
import 'package:social_gallery/shared/widgets/one_ui/one_ui_subpage_scaffold.dart';

class FolderWidgetConfigScreen extends ConsumerStatefulWidget {
  const FolderWidgetConfigScreen({super.key, required this.widgetId});

  final int widgetId;

  @override
  ConsumerState<FolderWidgetConfigScreen> createState() =>
      _FolderWidgetConfigScreenState();
}

class _FolderWidgetConfigScreenState
    extends ConsumerState<FolderWidgetConfigScreen> {
  FolderInfo? _folder;
  int _intervalMinutes = 30;
  bool _customInterval = false;
  final _customController = TextEditingController(text: '15');
  bool _refreshOnUnlock = false;
  WidgetPickMode _pickMode = WidgetPickMode.random;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final existing = await FolderWidgetConfig.load(widget.widgetId);
    if (existing == null || !mounted) return;
    final folders = await ref.read(folderRepositoryProvider).watchAll().first;
    setState(() {
      _folder = folders.cast<FolderInfo?>().firstWhere(
            (f) => f?.path == existing.folderPath,
            orElse: () => null,
          );
      _intervalMinutes = existing.intervalMinutes;
      _customInterval =
          ![10, 30, 60].contains(existing.intervalMinutes);
      if (_customInterval) {
        _customController.text = '${existing.intervalMinutes}';
      }
      _refreshOnUnlock = existing.refreshOnUnlock;
      _pickMode = existing.pickMode;
    });
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final folder = _folder;
    if (folder == null) return;
    setState(() => _saving = true);
    AppHaptics.light();

    final minutes = _customInterval
        ? (int.tryParse(_customController.text.trim()) ?? 15).clamp(5, 1440)
        : _intervalMinutes;

    final config = FolderWidgetConfig(
      widgetId: widget.widgetId,
      folderPath: folder.path,
      folderName: folder.name,
      intervalMinutes: minutes,
      refreshOnUnlock: _refreshOnUnlock,
      pickMode: _pickMode,
    );
    await WidgetUpdateService.updateFolderWidget(config);

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await HomeWidget.updateWidget(
        name: folderWidgetAndroidName,
        androidName: folderWidgetAndroidName,
      );
    }

    if (!mounted) return;
    setState(() => _saving = false);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final foldersAsync = ref.watch(allFoldersProvider);

    return OneUiSubpageScaffold(
      appBarTitle: l10n.widgetConfigTitle,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.widgetConfigFolder, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          foldersAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
            data: (folders) {
              final visible = folders
                  .where((f) => !f.isBiometricLocked && f.mediaCount > 0)
                  .toList();
              return DropdownButtonFormField<String>(
                initialValue: _folder?.path,
                items: [
                  for (final f in visible)
                    DropdownMenuItem(value: f.path, child: Text(f.name)),
                ],
                onChanged: (path) {
                  if (path == null) return;
                  setState(() {
                    _folder = visible.firstWhere((f) => f.path == path);
                  });
                },
              );
            },
          ),
          const SizedBox(height: 24),
          Text(l10n.widgetConfigInterval,
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text(l10n.widgetConfigInterval10m),
                selected: !_customInterval && _intervalMinutes == 10,
                onSelected: (_) => setState(() {
                  _customInterval = false;
                  _intervalMinutes = 10;
                }),
              ),
              ChoiceChip(
                label: Text(l10n.widgetConfigInterval30m),
                selected: !_customInterval && _intervalMinutes == 30,
                onSelected: (_) => setState(() {
                  _customInterval = false;
                  _intervalMinutes = 30;
                }),
              ),
              ChoiceChip(
                label: Text(l10n.widgetConfigInterval1h),
                selected: !_customInterval && _intervalMinutes == 60,
                onSelected: (_) => setState(() {
                  _customInterval = false;
                  _intervalMinutes = 60;
                }),
              ),
              ChoiceChip(
                label: Text(l10n.widgetConfigIntervalCustom),
                selected: _customInterval,
                onSelected: (_) => setState(() => _customInterval = true),
              ),
            ],
          ),
          if (_customInterval) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _customController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.widgetConfigIntervalCustom,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(l10n.widgetConfigRefreshOnUnlock),
            value: _refreshOnUnlock,
            onChanged: (v) => setState(() => _refreshOnUnlock = v),
          ),
          const SizedBox(height: 8),
          Text(l10n.widgetConfigPickMode,
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<WidgetPickMode>(
            segments: [
              ButtonSegment(
                value: WidgetPickMode.random,
                label: Text(l10n.widgetConfigPickRandom),
              ),
              ButtonSegment(
                value: WidgetPickMode.recent,
                label: Text(l10n.widgetConfigPickRecent),
              ),
            ],
            selected: {_pickMode},
            onSelectionChanged: (s) => setState(() => _pickMode = s.first),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _folder == null || _saving ? null : _save,
            child: Text(l10n.widgetConfigSave),
          ),
        ],
      ),
    );
  }
}
