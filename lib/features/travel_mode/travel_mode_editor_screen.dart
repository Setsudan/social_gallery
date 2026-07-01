import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/core/utils/haptics.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';
import 'package:social_gallery/domain/models/travel_mode.dart';
import 'package:social_gallery/l10n/app_localizations.dart';

class TravelModeEditorScreen extends ConsumerStatefulWidget {
  const TravelModeEditorScreen({super.key, this.travelModeId});

  final String? travelModeId;

  @override
  ConsumerState<TravelModeEditorScreen> createState() =>
      _TravelModeEditorScreenState();
}

class _TravelModeEditorScreenState
    extends ConsumerState<TravelModeEditorScreen> {
  final _nameController = TextEditingController();
  final _folderController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _useStartTime = false;
  bool _useEndTime = false;
  bool _loading = true;
  bool _saving = false;
  TravelMode? _existing;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = widget.travelModeId;
    if (id == null) {
      setState(() {
        _startDate = DateTime.now();
        _endDate = DateTime.now().add(const Duration(days: 7));
        _folderController.text = 'Travel';
        _loading = false;
      });
      return;
    }

    final mode = await ref.read(travelModeUseCaseProvider).getById(id);
    if (!mounted) return;
    if (mode != null) {
      _existing = mode;
      _nameController.text = mode.name;
      _folderController.text = mode.folderPath;
      _startDate = DateTime.fromMillisecondsSinceEpoch(mode.startDate);
      _endDate = DateTime.fromMillisecondsSinceEpoch(mode.endDate);
      if (mode.startTime != null) {
        _useStartTime = true;
        _startTime = _timeFromMs(mode.startTime!);
      }
      if (mode.endTime != null) {
        _useEndTime = true;
        _endTime = _timeFromMs(mode.endTime!);
      }
    }
    setState(() => _loading = false);
  }

  TimeOfDay _timeFromMs(int ms) {
    final hours = ms ~/ (60 * 60 * 1000);
    final minutes = (ms % (60 * 60 * 1000)) ~/ (60 * 1000);
    return TimeOfDay(hour: hours, minute: minutes);
  }

  int _timeToMs(TimeOfDay time) => (time.hour * 60 + time.minute) * 60 * 1000;

  Future<void> _pickDate({required bool start}) async {
    final initial = start ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _pickTime({required bool start}) async {
    final initial = start
        ? (_startTime ?? const TimeOfDay(hour: 9, minute: 0))
        : (_endTime ?? const TimeOfDay(hour: 18, minute: 0));
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    setState(() {
      if (start) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final name = _nameController.text.trim();
    final folder = _folderController.text.trim();
    if (name.isEmpty ||
        folder.isEmpty ||
        _startDate == null ||
        _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.snackbarTravelModeRequiredFields)),
      );
      return;
    }

    setState(() => _saving = true);
    final useCase = ref.read(travelModeUseCaseProvider);
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = _existing?.id ?? now.toString();

    final mode = TravelMode(
      id: id,
      name: name,
      startDate: DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
      ).millisecondsSinceEpoch,
      endDate: DateTime(
        _endDate!.year,
        _endDate!.month,
        _endDate!.day,
      ).millisecondsSinceEpoch,
      startTime: _useStartTime && _startTime != null
          ? _timeToMs(_startTime!)
          : null,
      endTime: _useEndTime && _endTime != null ? _timeToMs(_endTime!) : null,
      folderPath: folder,
      createdAt: _existing?.createdAt ?? now,
    );

    if (_existing != null) {
      await useCase.update(mode);
    } else {
      await useCase.create(mode);
    }

    // TODO(workmanager): schedule TravelModeNotificationWorker-style alerts
    if (mounted) {
      AppHaptics.success();
      context.pop();
    }
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final id = widget.travelModeId;
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.travelModeDeleteTitle),
        content: Text(l10n.travelModeDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(travelModeUseCaseProvider).delete(id);
      if (mounted) context.pop();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _folderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (widget.travelModeId != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: OneUiSpacing.xl),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: OneUiSpacing.pageHorizontal,
                  ),
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: l10n.travelModeTripName,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: OneUiSpacing.pageHorizontal,
                  ),
                  child: TextField(
                    controller: _folderController,
                    decoration: InputDecoration(
                      labelText: l10n.travelModeTargetFolder,
                      helperText: l10n.travelModeTargetFolderHelper,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _dateCard(
                  theme,
                  l10n,
                  title: l10n.travelModeStart,
                  date: _startDate,
                  onPickDate: () => _pickDate(start: true),
                  useTime: _useStartTime,
                  time: _startTime,
                  onToggleTime: (v) => setState(() => _useStartTime = v),
                  onPickTime: () => _pickTime(start: true),
                ),
                const SizedBox(height: 12),
                _dateCard(
                  theme,
                  l10n,
                  title: l10n.travelModeEnd,
                  date: _endDate,
                  onPickDate: () => _pickDate(start: false),
                  useTime: _useEndTime,
                  time: _endTime,
                  onToggleTime: (v) => setState(() => _useEndTime = v),
                  onPickTime: () => _pickTime(start: false),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.actionSave),
                ),
              ],
            ),
    );
  }

  Widget _dateCard(
    ThemeData theme,
    AppLocalizations l10n, {
    required String title,
    required DateTime? date,
    required VoidCallback onPickDate,
    required bool useTime,
    required TimeOfDay? time,
    required ValueChanged<bool> onToggleTime,
    required VoidCallback onPickTime,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    date == null
                        ? l10n.valueNotSet
                        : '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                  ),
                ),
                OutlinedButton(
                  onPressed: onPickDate,
                  child: Text(l10n.travelModeDate),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.travelModeSpecificTime),
              value: useTime,
              onChanged: onToggleTime,
            ),
            if (useTime)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      time == null ? l10n.valueNotSet : time.format(context),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: onPickTime,
                    child: Text(l10n.travelModeTime),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
