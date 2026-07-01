import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/core/backup/backup_deep_link.dart';
import 'package:social_gallery/core/backup/desktop_backup_controller.dart';
import 'package:social_gallery/core/l10n/backup_detail_l10n.dart';
import 'package:social_gallery/features/settings/vault_password_dialog.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/core/platform/desktop_gallery_platform.dart';
import 'package:social_gallery/core/sync/gallery_sync_controller.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';
import 'package:social_gallery/l10n/app_localizations.dart';
import 'package:social_gallery/shared/widgets/one_ui/one_ui_settings_tile.dart';

/// Mobile flow to discover a desktop and pair with a PIN.
class BackupPairingSheet extends ConsumerStatefulWidget {
  const BackupPairingSheet({super.key});

  @override
  ConsumerState<BackupPairingSheet> createState() => _BackupPairingSheetState();
}

class _BackupPairingSheetState extends ConsumerState<BackupPairingSheet> {
  final _pinController = TextEditingController();
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _discover() async {
    final l10n = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    final found = await ref.read(desktopBackupProvider.notifier).discoverDesktop();
    if (!mounted) return;
    if (found != null) {
      _hostController.text = found.host;
      _portController.text = found.port.toString();
    } else {
      _error = l10n.backupErrorNoDesktopFound;
    }
    setState(() => _busy = false);
  }

  Future<void> _pair() async {
    final l10n = context.l10n;
    final host = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim());
    final pin = _pinController.text.trim();
    if (host.isEmpty || port == null || pin.length != 6) {
      setState(() => _error = l10n.backupErrorEnterHostPortPin);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final deviceName = Platform.localHostname;
    final ok = await ref.read(desktopBackupProvider.notifier).pairWithDesktop(
      host: host,
      port: port,
      pin: pin,
      mobileDeviceName: deviceName,
    );

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _busy = false;
      _error = l10n.backupErrorPairingFailed;
    });
  }

  Future<void> _pairFromParams(BackupPairingParams params) async {
    _hostController.text = params.address;
    _portController.text = params.port.toString();
    _pinController.text = params.pin;
    await _pair();
  }

  Future<void> _scanQr() async {
    final l10n = context.l10n;
    final payload = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const _BackupQrScannerScreen()),
    );
    if (!mounted || payload == null) return;
    final params = BackupDeepLink.parsePayload(payload);
    if (params == null) {
      setState(() => _error = l10n.backupErrorInvalidQr);
      return;
    }
    await _pairFromParams(params);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(
        left: OneUiSpacing.pageHorizontal,
        right: OneUiSpacing.pageHorizontal,
        top: OneUiSpacing.sm,
        bottom: MediaQuery.viewInsetsOf(context).bottom + OneUiSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.backupPairSheetTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: OneUiSpacing.sm),
          Text(
            l10n.backupPairSheetDescription,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: OneUiSpacing.md),
          TextField(
            controller: _hostController,
            decoration: InputDecoration(
              labelText: l10n.backupDesktopAddress,
              hintText: '192.168.1.10',
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: OneUiSpacing.sm),
          TextField(
            controller: _portController,
            decoration: InputDecoration(labelText: l10n.backupPort),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: OneUiSpacing.sm),
          TextField(
            controller: _pinController,
            decoration: InputDecoration(labelText: l10n.backupPinLabel),
            keyboardType: TextInputType.number,
            maxLength: 6,
          ),
          if (_error != null) ...[
            const SizedBox(height: OneUiSpacing.sm),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: OneUiSpacing.md),
          FilledButton.tonalIcon(
            onPressed: _busy ? null : _scanQr,
            icon: const Icon(Icons.qr_code_scanner),
            label: Text(l10n.backupScanPairingQr),
          ),
          const SizedBox(height: OneUiSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : _discover,
                  child: Text(l10n.backupFindOnNetwork),
                ),
              ),
              const SizedBox(width: OneUiSpacing.sm),
              Expanded(
                child: FilledButton(
                  onPressed: _busy ? null : _pair,
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.backupPair),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String backupStatusLabel(
  AppLocalizations l10n,
  DesktopBackupState state,
  DateTime? lastBackupAt,
) {
  if (state.showsProgressUi) {
    if (state.total > 0) {
      return l10n.backupStatusBackingUp(state.processed, state.total);
    }
    return localizeBackupDetail(l10n, state.detail);
  }
  if (state.isRunning) {
    return localizeBackupDetail(l10n, state.detail);
  }
  return switch (state.phase) {
    DesktopBackupPhase.disabled => l10n.backupStatusOff,
    DesktopBackupPhase.waitingForDesktop => l10n.backupStatusWaitingForDesktop,
    DesktopBackupPhase.desktopReady => l10n.backupStatusDesktopReady,
    DesktopBackupPhase.indexing => localizeBackupDetail(l10n, state.detail),
    DesktopBackupPhase.reconciling => localizeBackupDetail(l10n, state.detail),
    DesktopBackupPhase.verifying => localizeBackupDetail(l10n, state.detail),
    DesktopBackupPhase.syncing => localizeBackupDetail(l10n, state.detail),
    DesktopBackupPhase.done => lastBackupAt != null
        ? l10n.backupStatusLastBackup(
            localizeBackupRelativeTime(l10n, lastBackupAt),
          )
        : l10n.backupStatusUpToDate,
    DesktopBackupPhase.error => l10n.backupStatusError(
      localizeBackupDetail(l10n, state.detail),
    ),
    _ => state.detail.isNotEmpty
        ? localizeBackupDetail(l10n, state.detail)
        : l10n.backupStatusIdle,
  };
}

Future<void> showBackupPairingSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (context) => const BackupPairingSheet(),
  );
}

Future<void> showPairingSuccessDialog(
  BuildContext context,
  String deviceName,
) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      final l10n = context.l10n;
      return AlertDialog(
        title: Text(l10n.backupPairingSuccessTitle),
        content: Text(l10n.backupPairingSuccessMessage(deviceName)),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.actionOk),
          ),
        ],
      );
    },
  );
}

Future<void> showDesktopBackupQrSheet(BuildContext context, WidgetRef ref) {
  final backup = ref.read(desktopBackupProvider);
  final prefs = ref.read(preferencesRepositoryProvider);
  if (prefs.backupAuthToken != null) return Future.value();

  final pin = backup.pairingPin;
  final host = backup.localIp;
  final port = backup.localServerPort;
  if (pin == null || host == null || port == null) return Future.value();

  final deepLink = BackupDeepLink.pairingUri(
    address: host,
    port: port,
    pin: pin,
  );

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _DesktopBackupQrSheet(deepLink: deepLink, pin: pin, host: host, port: port),
  );
}

class _DesktopBackupQrSheet extends ConsumerStatefulWidget {
  const _DesktopBackupQrSheet({
    required this.deepLink,
    required this.pin,
    required this.host,
    required this.port,
  });

  final Uri deepLink;
  final String pin;
  final String host;
  final int port;

  @override
  ConsumerState<_DesktopBackupQrSheet> createState() =>
      _DesktopBackupQrSheetState();
}

class _DesktopBackupQrSheetState extends ConsumerState<_DesktopBackupQrSheet> {
  @override
  Widget build(BuildContext context) {
    ref.listen(
      desktopBackupProvider.select((s) => s.pairingSuccessDeviceName),
      (previous, next) {
        if (next != null && mounted) {
          Navigator.pop(context);
        }
      },
    );

    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(OneUiSpacing.pageHorizontal),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.backupPairYourPhoneTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: OneUiSpacing.sm),
          Text(l10n.backupPinDisplay(widget.pin), style: theme.textTheme.headlineSmall),
          Text('${widget.host}:${widget.port}', style: theme.textTheme.bodyMedium),
          const SizedBox(height: OneUiSpacing.md),
          QrImageView(
            data: widget.deepLink.toString(),
            size: 200,
            embeddedImageStyle: const QrEmbeddedImageStyle(size: Size(0, 0)),
          ),
          const SizedBox(height: OneUiSpacing.sm),
          SelectableText(
            widget.deepLink.toString(),
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: OneUiSpacing.md),
          Text(
            l10n.backupQrInstructions,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: OneUiSpacing.lg),
        ],
      ),
    );
  }
}

class _BackupQrScannerScreen extends StatefulWidget {
  const _BackupQrScannerScreen();

  @override
  State<_BackupQrScannerScreen> createState() => _BackupQrScannerScreenState();
}

class _BackupQrScannerScreenState extends State<_BackupQrScannerScreen> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.backupScanPairingQrTitle)),
      body: MobileScanner(
        onDetect: (capture) {
          if (_handled) return;
          final value = capture.barcodes.firstOrNull?.rawValue;
          if (value == null || value.isEmpty) return;
          if (BackupDeepLink.parsePayload(value) == null) return;
          _handled = true;
          Navigator.pop(context, value);
        },
      ),
    );
  }
}

/// Settings tiles for desktop backup on mobile and desktop.
class BackupSettingsSection extends ConsumerStatefulWidget {
  const BackupSettingsSection({super.key});

  @override
  ConsumerState<BackupSettingsSection> createState() =>
      _BackupSettingsSectionState();
}

class _BackupSettingsSectionState extends ConsumerState<BackupSettingsSection> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final prefs = ref.watch(preferencesRepositoryProvider);
    final backupState = ref.watch(desktopBackupProvider);
    final notifier = ref.read(desktopBackupProvider.notifier);

    if (!usesFilesystemGallery) {
      ref.listen(
        desktopBackupProvider.select((s) => s.needsVaultPassword),
        (previous, next) async {
          if (next != true || !mounted) return;
          final password = await showVaultPasswordDialog(
            context,
            isNewPassword: true,
          );
          if (password != null && mounted) {
            await notifier.registerVaultPassword(password);
          }
        },
      );
    }

    if (usesFilesystemGallery) {
      ref.listen(
        desktopBackupProvider.select((s) => s.pairingSuccessDeviceName),
        (previous, next) {
          if (next == null) return;
          notifier.clearPairingSuccess();
          unawaited(showPairingSuccessDialog(context, next));
        },
      );

      final isDesktopPaired = prefs.backupAuthToken != null &&
          prefs.pairedMobileDeviceName != null;

      return OneUiSettingsSection(
        title: l10n.backupSectionTitle,
        children: [
          OneUiSettingsTile(
            icon: OneUiSettingsIcon.cloud,
            title: l10n.backupReceiveBackups,
            subtitle: l10n.backupReceiveBackupsSubtitle,
            trailing: Switch.adaptive(
              value: prefs.desktopReceiveBackups,
              onChanged: (value) => notifier.setDesktopReceiveEnabled(value),
            ),
            showChevron: false,
          ),
          if (prefs.desktopReceiveBackups) ...[
            if (backupState.phase == DesktopBackupPhase.indexing &&
                backupState.isRunning)
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.sync,
                title: l10n.backupIndexingBackups,
                subtitle: localizeBackupDetail(l10n, backupState.detail),
                showChevron: false,
              ),
            if (!isDesktopPaired)
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.folder,
                title: l10n.backupShowPairingCode,
                subtitle: backupState.localIp != null &&
                        backupState.localServerPort != null
                    ? '${backupState.localIp}:${backupState.localServerPort}'
                    : l10n.backupStartReceivingToShowCode,
                onTap: () => showDesktopBackupQrSheet(context, ref),
              ),
            if (isDesktopPaired) ...[
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.device,
                title: l10n.backupPairedDevice,
                value: prefs.pairedMobileDeviceName,
                showChevron: false,
              ),
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.trash,
                title: l10n.backupUnpairDevice,
                subtitle: l10n.backupUnpairDeviceSubtitle,
                onTap: () => notifier.unpairDesktopReceiver(),
              ),
            ],
            OneUiSettingsTile(
              icon: OneUiSettingsIcon.sync,
              title: l10n.backupRefreshLibrary,
              subtitle: l10n.backupRefreshLibrarySubtitle,
              onTap: () =>
                  ref.read(gallerySyncProvider.notifier).run(force: true),
            ),
            if (_serverVaultCount(backupState) > 0)
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.privacy,
                title: l10n.backupVaultStorageTitle,
                subtitle: l10n.backupVaultStorageCount(_serverVaultCount(backupState)),
                showChevron: false,
              ),
          ],
        ],
      );
    }

    final isPaired = prefs.backupAuthToken != null;
    return OneUiSettingsSection(
      title: l10n.backupSectionTitle,
      children: [
        OneUiSettingsTile(
          icon: OneUiSettingsIcon.cloud,
          title: l10n.backupBackUpToDesktop,
          subtitle: l10n.backupBackUpToDesktopSubtitle,
          trailing: Switch.adaptive(
            value: prefs.backupEnabled,
            onChanged: (value) => notifier.setBackupEnabled(value),
          ),
          showChevron: false,
        ),
        if (prefs.backupEnabled) ...[
          OneUiSettingsTile(
            icon: OneUiSettingsIcon.device,
            title: isPaired ? l10n.backupPairedDesktop : l10n.backupPairWithDesktop,
            value: isPaired ? prefs.pairedDesktopName : null,
            subtitle: backupStatusLabel(l10n, backupState, prefs.lastBackupAt),
            onTap: isPaired
                ? null
                : () => showBackupPairingSheet(context),
            showChevron: !isPaired,
          ),
          if (isPaired)
            OneUiSettingsTile(
              icon: OneUiSettingsIcon.folder,
              title: l10n.desktopArchiveBrowseTitle,
              subtitle: l10n.desktopArchiveBrowseSubtitle,
              onTap: () => context.push('/desktop-archive'),
            ),
          if (isPaired)
            OneUiSettingsTile(
              icon: OneUiSettingsIcon.privacy,
              title: l10n.vaultPasswordChangeTitle,
              subtitle: l10n.vaultPasswordChangeSubtitle,
              onTap: () async {
                final password = await showVaultPasswordDialog(
                  context,
                  isNewPassword: true,
                );
                if (password != null) {
                  await notifier.registerVaultPassword(password);
                }
              },
            ),
          if (isPaired)
            OneUiSettingsTile(
              icon: OneUiSettingsIcon.sync,
              title: l10n.backupBackUpNow,
              subtitle: l10n.backupBackUpNowSubtitle,
              onTap: backupState.isRunning
                  ? null
                  : () => notifier.checkAndMaybeRun(force: true),
            ),
          if (isPaired)
            OneUiSettingsTile(
              icon: OneUiSettingsIcon.trash,
              title: l10n.backupUnpairDesktop,
              onTap: () => notifier.unpair(),
            ),
        ],
      ],
    );
  }
}

int _serverVaultCount(DesktopBackupState state) => state.vaultEncryptedCount;
