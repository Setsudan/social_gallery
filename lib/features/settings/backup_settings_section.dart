import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/backup/backup_deep_link.dart';
import 'package:social_gallery/core/backup/desktop_backup_controller.dart';
import 'package:social_gallery/core/platform/desktop_gallery_platform.dart';
import 'package:social_gallery/core/sync/gallery_sync_controller.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';
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
      _error = 'No desktop found. Enter the address shown on your computer.';
    }
    setState(() => _busy = false);
  }

  Future<void> _pair() async {
    final host = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim());
    final pin = _pinController.text.trim();
    if (host.isEmpty || port == null || pin.length != 6) {
      setState(() => _error = 'Enter host, port, and 6-digit PIN from desktop.');
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
      _error = 'Pairing failed. Check the PIN and try again.';
    });
  }

  Future<void> _pairFromParams(BackupPairingParams params) async {
    _hostController.text = params.address;
    _portController.text = params.port.toString();
    _pinController.text = params.pin;
    await _pair();
  }

  Future<void> _scanQr() async {
    final payload = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const _BackupQrScannerScreen()),
    );
    if (!mounted || payload == null) return;
    final params = BackupDeepLink.parsePayload(payload);
    if (params == null) {
      setState(() => _error = 'QR code is not a valid backup pairing link.');
      return;
    }
    await _pairFromParams(params);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          Text('Pair with desktop', style: theme.textTheme.titleLarge),
          const SizedBox(height: OneUiSpacing.sm),
          Text(
            'On your computer, enable Receive backups in Settings and enter the PIN shown there.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: OneUiSpacing.md),
          TextField(
            controller: _hostController,
            decoration: const InputDecoration(
              labelText: 'Desktop address',
              hintText: '192.168.1.10',
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: OneUiSpacing.sm),
          TextField(
            controller: _portController,
            decoration: const InputDecoration(labelText: 'Port'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: OneUiSpacing.sm),
          TextField(
            controller: _pinController,
            decoration: const InputDecoration(labelText: '6-digit PIN'),
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
            label: const Text('Scan pairing QR code'),
          ),
          const SizedBox(height: OneUiSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : _discover,
                  child: const Text('Find on network'),
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
                      : const Text('Pair'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String backupStatusLabel(DesktopBackupState state, DateTime? lastBackupAt) {
  if (state.showsProgressUi) {
    if (state.total > 0) {
      return 'Backing up ${state.processed}/${state.total}';
    }
    return state.detail;
  }
  if (state.isRunning) {
    return state.detail;
  }
  return switch (state.phase) {
    DesktopBackupPhase.disabled => 'Off',
    DesktopBackupPhase.waitingForDesktop => 'Waiting for desktop',
    DesktopBackupPhase.desktopReady => 'Desktop ready',
    DesktopBackupPhase.indexing => state.detail,
    DesktopBackupPhase.reconciling => state.detail,
    DesktopBackupPhase.verifying => state.detail,
    DesktopBackupPhase.syncing => state.detail,
    DesktopBackupPhase.done => lastBackupAt != null
        ? 'Last backup ${_formatRelative(lastBackupAt)}'
        : 'Up to date',
    DesktopBackupPhase.error => 'Error - ${state.detail}',
    _ => state.detail.isNotEmpty ? state.detail : 'Idle',
  };
}

String _formatRelative(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
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
      return AlertDialog(
        title: const Text('Pairing successful'),
        content: Text(
          '$deviceName is now paired with this computer. '
          'Backups will start automatically when both devices are on the same Wi-Fi.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
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
    return Padding(
      padding: const EdgeInsets.all(OneUiSpacing.pageHorizontal),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Pair your phone', style: theme.textTheme.titleLarge),
          const SizedBox(height: OneUiSpacing.sm),
          Text('PIN: ${widget.pin}', style: theme.textTheme.headlineSmall),
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
            'Scan with your phone camera or use Scan pairing QR in Settings > Desktop backup.',
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
    return Scaffold(
      appBar: AppBar(title: const Text('Scan pairing QR')),
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
    final prefs = ref.watch(preferencesRepositoryProvider);
    final backupState = ref.watch(desktopBackupProvider);
    final notifier = ref.read(desktopBackupProvider.notifier);

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
        title: 'Desktop backup',
        children: [
          OneUiSettingsTile(
            icon: OneUiSettingsIcon.cloud,
            title: 'Receive backups',
            subtitle: 'Allow this computer to receive photos from your phone',
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
                title: 'Indexing backups',
                subtitle: backupState.detail,
                showChevron: false,
              ),
            if (!isDesktopPaired)
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.folder,
                title: 'Show pairing code',
                subtitle: backupState.localIp != null &&
                        backupState.localServerPort != null
                    ? '${backupState.localIp}:${backupState.localServerPort}'
                    : 'Start receiving to show code',
                onTap: () => showDesktopBackupQrSheet(context, ref),
              ),
            if (isDesktopPaired) ...[
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.device,
                title: 'Paired device',
                value: prefs.pairedMobileDeviceName,
                showChevron: false,
              ),
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.trash,
                title: 'Unpair device',
                subtitle: 'Stop accepting backups from this phone',
                onTap: () => notifier.unpairDesktopReceiver(),
              ),
            ],
            OneUiSettingsTile(
              icon: OneUiSettingsIcon.sync,
              title: 'Refresh library',
              subtitle: 'Rescan folders after new backups arrive',
              onTap: () =>
                  ref.read(gallerySyncProvider.notifier).run(force: true),
            ),
          ],
        ],
      );
    }

    final isPaired = prefs.backupAuthToken != null;
    return OneUiSettingsSection(
      title: 'Desktop backup',
      children: [
        OneUiSettingsTile(
          icon: OneUiSettingsIcon.cloud,
          title: 'Back up to desktop',
          subtitle: 'Automatic backup on same Wi-Fi when desktop is running',
          trailing: Switch.adaptive(
            value: prefs.backupEnabled,
            onChanged: (value) => notifier.setBackupEnabled(value),
          ),
          showChevron: false,
        ),
        if (prefs.backupEnabled) ...[
          OneUiSettingsTile(
            icon: OneUiSettingsIcon.device,
            title: isPaired ? 'Paired desktop' : 'Pair with desktop',
            value: isPaired ? prefs.pairedDesktopName : null,
            subtitle: backupStatusLabel(backupState, prefs.lastBackupAt),
            onTap: isPaired
                ? null
                : () => showBackupPairingSheet(context),
            showChevron: !isPaired,
          ),
          if (isPaired)
            OneUiSettingsTile(
              icon: OneUiSettingsIcon.sync,
              title: 'Back up now',
              subtitle: 'Only runs when desktop is available',
              onTap: backupState.isRunning
                  ? null
                  : () => notifier.checkAndMaybeRun(force: true),
            ),
          if (isPaired)
            OneUiSettingsTile(
              icon: OneUiSettingsIcon.trash,
              title: 'Unpair desktop',
              onTap: () => notifier.unpair(),
            ),
        ],
      ],
    );
  }
}
