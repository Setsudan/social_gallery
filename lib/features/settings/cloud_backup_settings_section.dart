import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/cloud_backup/cloud_backup_controller.dart';
import 'package:social_gallery/core/cloud_backup/cloud_provider_preset.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/core/platform/desktop_gallery_platform.dart';
import 'package:social_gallery/features/settings/vault_password_dialog.dart';
import 'package:social_gallery/l10n/app_localizations.dart';
import 'package:social_gallery/shared/widgets/one_ui/one_ui_settings_tile.dart';

/// Mobile-only encrypted cloud backup settings (MinIO / RustFS / Cloudflare R2).
class CloudBackupSettingsSection extends ConsumerStatefulWidget {
  const CloudBackupSettingsSection({super.key});

  @override
  ConsumerState<CloudBackupSettingsSection> createState() =>
      _CloudBackupSettingsSectionState();
}

class _CloudBackupSettingsSectionState
    extends ConsumerState<CloudBackupSettingsSection> {
  @override
  Widget build(BuildContext context) {
    if (usesFilesystemGallery) return const SizedBox.shrink();

    final l10n = context.l10n;
    final prefs = ref.watch(preferencesRepositoryProvider);
    final cloud = ref.watch(cloudBackupProvider);
    final notifier = ref.read(cloudBackupProvider.notifier);

    ref.listen(
      cloudBackupProvider.select((s) => s.needsPassword),
      (previous, next) async {
        if (next != true || !mounted) return;
        final configured =
            await ref.read(cloudVaultKeyStoreProvider).isConfigured();
        if (!context.mounted) return;
        final password = await showVaultPasswordDialog(
          context,
          isNewPassword: !configured,
        );
        if (password == null || !context.mounted) return;
        if (configured) {
          await notifier.unlockEncryptionPassword(password);
        } else {
          await notifier.registerEncryptionPassword(password);
        }
      },
    );

    return OneUiSettingsSection(
      title: l10n.cloudBackupSectionTitle,
      children: [
        OneUiSettingsTile(
          icon: OneUiSettingsIcon.cloud,
          title: l10n.cloudBackupEnableTitle,
          subtitle: l10n.cloudBackupEnableSubtitle,
          trailing: Switch.adaptive(
            value: prefs.cloudBackupEnabled,
            onChanged: (value) => notifier.setEnabled(value),
          ),
          showChevron: false,
        ),
        if (prefs.cloudBackupEnabled) ...[
          OneUiSettingsTile(
            icon: OneUiSettingsIcon.device,
            title: l10n.cloudBackupConfigureTitle,
            subtitle: _statusSubtitle(l10n, cloud, prefs.lastCloudBackupAt),
            onTap: () => _openConfigSheet(context),
          ),
          OneUiSettingsTile(
            icon: OneUiSettingsIcon.privacy,
            title: l10n.cloudBackupPasswordTitle,
            subtitle: l10n.cloudBackupPasswordSubtitle,
            onTap: () async {
              final configured =
                  await ref.read(cloudVaultKeyStoreProvider).isConfigured();
              if (!context.mounted) return;
              final password = await showVaultPasswordDialog(
                context,
                isNewPassword: !configured,
              );
              if (password == null) return;
              if (configured) {
                final ok = await notifier.unlockEncryptionPassword(password);
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.cloudBackupPasswordWrong)),
                  );
                }
              } else {
                await notifier.registerEncryptionPassword(password);
              }
            },
          ),
          OneUiSettingsTile(
            icon: OneUiSettingsIcon.folder,
            title: l10n.cloudArchiveBrowseTitle,
            subtitle: l10n.cloudArchiveBrowseSubtitle,
            onTap: () => context.push('/cloud-archive'),
          ),
          OneUiSettingsTile(
            icon: OneUiSettingsIcon.sync,
            title: l10n.cloudBackupNowTitle,
            subtitle: l10n.cloudBackupNowSubtitle,
            onTap: cloud.isRunning
                ? null
                : () => notifier.checkAndMaybeRun(force: true),
          ),
          OneUiSettingsTile(
            icon: OneUiSettingsIcon.trash,
            title: l10n.cloudBackupUnlinkTitle,
            subtitle: l10n.cloudBackupUnlinkSubtitle,
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.cloudBackupUnlinkTitle),
                  content: Text(l10n.cloudBackupUnlinkConfirm),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l10n.actionCancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(l10n.cloudBackupUnlinkTitle),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await notifier.unlink();
              }
            },
          ),
        ],
      ],
    );
  }

  String _statusSubtitle(
    AppLocalizations l10n,
    CloudBackupState cloud,
    DateTime? lastAt,
  ) {
    if (cloud.phase == CloudBackupPhase.needsConfig) {
      return l10n.cloudBackupNeedsConfig;
    }
    if (cloud.phase == CloudBackupPhase.needsPassword) {
      return l10n.cloudBackupNeedsPassword;
    }
    if (cloud.phase == CloudBackupPhase.waitingForWifi) {
      return l10n.cloudBackupWaitingWifi;
    }
    if (cloud.phase == CloudBackupPhase.error && cloud.errorMessage != null) {
      return cloud.errorMessage!;
    }
    if (cloud.isRunning) {
      return l10n.cloudBackupSyncing(cloud.processed, cloud.total);
    }
    if (lastAt != null) {
      return l10n.cloudBackupLastAt(lastAt.toLocal().toString());
    }
    return cloud.provider.displayName;
  }

  Future<void> _openConfigSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const _CloudBackupConfigSheet(),
    );
  }
}

class _CloudBackupConfigSheet extends ConsumerStatefulWidget {
  const _CloudBackupConfigSheet();

  @override
  ConsumerState<_CloudBackupConfigSheet> createState() =>
      _CloudBackupConfigSheetState();
}

class _CloudBackupConfigSheetState
    extends ConsumerState<_CloudBackupConfigSheet> {
  late CloudBackupProvider _provider;
  late final TextEditingController _endpoint;
  late final TextEditingController _region;
  late final TextEditingController _bucket;
  late final TextEditingController _prefix;
  late final TextEditingController _access;
  late final TextEditingController _secret;
  late bool _pathStyle;
  var _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(preferencesRepositoryProvider);
    _provider = CloudBackupProvider.fromId(prefs.cloudBackupProvider);
    final preset = CloudProviderPreset.forProvider(_provider);
    _endpoint = TextEditingController(text: prefs.cloudBackupEndpoint);
    _region = TextEditingController(
      text: prefs.cloudBackupRegion.isEmpty
          ? preset.defaultRegion
          : prefs.cloudBackupRegion,
    );
    _bucket = TextEditingController(text: prefs.cloudBackupBucket);
    _prefix = TextEditingController(text: prefs.cloudBackupPrefix);
    _access = TextEditingController();
    _secret = TextEditingController();
    _pathStyle = prefs.cloudBackupForcePathStyle;
    ref.read(cloudCredentialStoreProvider).readAccessKey().then((v) {
      if (v != null && mounted) _access.text = v;
    });
    ref.read(cloudCredentialStoreProvider).readSecretKey().then((v) {
      if (v != null && mounted) _secret.text = v;
    });
  }

  @override
  void dispose() {
    _endpoint.dispose();
    _region.dispose();
    _bucket.dispose();
    _prefix.dispose();
    _access.dispose();
    _secret.dispose();
    super.dispose();
  }

  void _applyPreset(CloudBackupProvider provider) {
    final preset = CloudProviderPreset.forProvider(provider);
    setState(() {
      _provider = provider;
      _pathStyle = preset.forcePathStyle;
      if (_region.text.isEmpty ||
          _region.text == 'us-east-1' ||
          _region.text == 'auto') {
        _region.text = preset.defaultRegion;
      }
      if (_endpoint.text.isEmpty) {
        _endpoint.text = '';
      }
    });
  }

  Future<void> _save({bool test = false}) async {
    final l10n = context.l10n;
    setState(() {
      _busy = true;
      _message = null;
    });
    final notifier = ref.read(cloudBackupProvider.notifier);
    await notifier.saveConnection(
      provider: _provider,
      endpoint: _endpoint.text,
      region: _region.text,
      bucket: _bucket.text,
      prefix: _prefix.text,
      forcePathStyle: _pathStyle,
      accessKey: _access.text,
      secretKey: _secret.text,
    );
    if (test) {
      final ok = await notifier.testConnection();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = ok
            ? l10n.cloudBackupTestOk
            : l10n.cloudBackupTestFailed;
      });
      return;
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final preset = CloudProviderPreset.forProvider(_provider);

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.cloudBackupConfigureTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: CloudBackupProvider.values.map((p) {
                return ChoiceChip(
                  label: Text(p.displayName),
                  selected: _provider == p,
                  onSelected: (_) => _applyPreset(p),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _endpoint,
              decoration: InputDecoration(
                labelText: l10n.cloudBackupEndpoint,
                hintText: preset.endpointHint,
              ),
              keyboardType: TextInputType.url,
            ),
            TextField(
              controller: _region,
              decoration: InputDecoration(labelText: l10n.cloudBackupRegion),
            ),
            TextField(
              controller: _bucket,
              decoration: InputDecoration(labelText: l10n.cloudBackupBucket),
            ),
            TextField(
              controller: _prefix,
              decoration: InputDecoration(
                labelText: l10n.cloudBackupPrefix,
              ),
            ),
            TextField(
              controller: _access,
              decoration:
                  InputDecoration(labelText: l10n.cloudBackupAccessKey),
            ),
            TextField(
              controller: _secret,
              decoration:
                  InputDecoration(labelText: l10n.cloudBackupSecretKey),
              obscureText: true,
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.cloudBackupPathStyle),
              value: _pathStyle,
              onChanged: (v) => setState(() => _pathStyle = v),
            ),
            if (_message != null) ...[
              const SizedBox(height: 8),
              Text(_message!),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : () => _save(test: true),
                    child: Text(l10n.cloudBackupTestConnection),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _busy ? null : () => _save(),
                    child: Text(l10n.actionSave),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
