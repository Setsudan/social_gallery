import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/auth/biometric_service.dart';
import 'package:social_gallery/core/auth/folder_unlock_store.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/domain/models/folder_info.dart';

typedef FolderUnlockedBuilder = Widget Function(BuildContext context);

class FolderLockGate extends ConsumerStatefulWidget {
  const FolderLockGate({
    super.key,
    required this.folder,
    required this.builder,
    this.autoPrompt = true,
  });

  final FolderInfo folder;
  final FolderUnlockedBuilder builder;
  final bool autoPrompt;

  @override
  ConsumerState<FolderLockGate> createState() => _FolderLockGateState();
}

class _FolderLockGateState extends ConsumerState<FolderLockGate> {
  bool _authenticating = false;
  bool _autoPrompted = false;
  String? _error;
  FolderUnlockStore? _unlockStore;
  BiometricService? _biometric;

  bool get _needsLock => widget.folder.isLockedAccount;

  bool _isUnlocked(FolderUnlockStore store) {
    if (!_needsLock) return true;
    return store.isUnlocked(widget.folder.path);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _unlockStore = ref.read(folderUnlockStoreProvider);
    _biometric = ref.read(biometricServiceProvider);
  }

  @override
  void initState() {
    super.initState();
    _scheduleAutoPrompt();
  }

  @override
  void didUpdateWidget(FolderLockGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.folder.path != widget.folder.path ||
        oldWidget.folder.isBiometricLocked != widget.folder.isBiometricLocked ||
        oldWidget.folder.followStatus != widget.folder.followStatus) {
      _autoPrompted = false;
      _scheduleAutoPrompt();
    }
  }

  void _scheduleAutoPrompt() {
    if (!widget.autoPrompt) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoPrompt());
  }

  Future<void> _maybeAutoPrompt() async {
    final store = _unlockStore;
    if (!mounted || store == null || _autoPrompted || !_needsLock) return;
    if (_isUnlocked(store)) return;
    _autoPrompted = true;
    await _unlock();
  }

  Future<void> _unlock() async {
    if (!mounted) return;
    final store = _unlockStore;
    final biometric = _biometric;
    if (store == null || biometric == null) return;

    final l10n = context.l10n;

    setState(() {
      _authenticating = true;
      _error = null;
    });

    final canUse = await biometric.canCheckBiometrics();
    if (!mounted) return;
    if (!canUse) {
      setState(() {
        _authenticating = false;
        _error = l10n.folderBiometricsUnavailable;
      });
      return;
    }

    final ok = await biometric.authenticate(
      reason: l10n.folderUnlockReason(widget.folder.name),
    );
    if (!mounted) return;

    if (ok) {
      store.unlock(widget.folder.path);
    }

    setState(() {
      _authenticating = false;
      if (!ok) {
        _error = l10n.folderAuthFailed;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final store = ref.watch(folderUnlockStoreProvider);
    if (_isUnlocked(store)) {
      return widget.builder(context);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48),
            const SizedBox(height: 16),
            Text(
              l10n.folderLockedTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.folderLockedMessage(widget.folder.name),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _authenticating ? null : _unlock,
              child: _authenticating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.actionUnlock),
            ),
          ],
        ),
      ),
    );
  }
}
