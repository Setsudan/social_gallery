import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';
import 'package:social_gallery/features/discover/widgets/deep_organize_tools_list.dart';
import 'package:social_gallery/shared/widgets/one_ui/one_ui_page_header.dart';
import 'package:social_gallery/shared/widgets/one_ui/one_ui_subpage_scaffold.dart';

class DeepOrganizeScreen extends ConsumerWidget {
  const DeepOrganizeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scan = ref.watch(mediaAnalysisControllerProvider);
    final hub = ref.watch(discoverHubProvider).valueOrNull;
    final l10n = context.l10n;

    return OneUiSubpageScaffold(
      title: l10n.deepOrganizeTitle,
      subtitle: l10n.deepOrganizeSubtitle,
      padding: const EdgeInsets.all(16),
      body: ListView(
        children: [
          if (scan.isScanning) ...[
            LinearProgressIndicator(value: scan.progress),
            const SizedBox(height: 8),
            Text(l10n.deepOrganizeScanProgress(scan.scanned, scan.total)),
            const SizedBox(height: 16),
          ],
          FilledButton.icon(
            onPressed: scan.isScanning
                ? null
                : () =>
                    ref.read(mediaAnalysisControllerProvider.notifier).startScan(),
            icon: const Icon(Icons.document_scanner_outlined),
            label: Text(
              scan.isScanning ? l10n.deepOrganizeScanning : l10n.deepOrganizeStartScan,
            ),
          ),
          const SizedBox(height: OneUiSpacing.sectionGap),
          OneUiSectionHeader(l10n.deepOrganizeToolsHeader),
          const SizedBox(height: OneUiSpacing.sm),
          DeepOrganizeToolsList(hub: hub),
        ],
      ),
    );
  }
}
