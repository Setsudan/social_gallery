import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';
import 'package:social_gallery/features/discover/discover_screen.dart';
import 'package:social_gallery/shared/widgets/one_ui/one_ui_page_header.dart';

class DeepOrganizeScreen extends ConsumerWidget {
  const DeepOrganizeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scan = ref.watch(mediaAnalysisControllerProvider);
    final hub = ref.watch(discoverHubProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const OneUiPageHeader(
            title: 'Deep organize',
            subtitle: 'Scan your library on device to find similar and low-quality photos.',
          ),
          if (scan.isScanning) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(value: scan.progress),
            const SizedBox(height: 8),
            Text('Scanning ${scan.scanned} / ${scan.total}'),
          ],
          const SizedBox(height: OneUiSpacing.sectionGap),
          FilledButton.icon(
            onPressed: scan.isScanning
                ? null
                : () => ref.read(mediaAnalysisControllerProvider.notifier).startScan(),
            icon: const Icon(Icons.document_scanner_outlined),
            label: Text(scan.isScanning ? 'Scanning...' : 'Start scan'),
          ),
          const SizedBox(height: OneUiSpacing.sectionGap),
          const OneUiSectionHeader('Tools'),
          const SizedBox(height: OneUiSpacing.sm),
          DiscoverHubCard(
            leading: const Icon(Icons.compare),
            title: 'Similar photos',
            subtitle: '${hub?.similarGroupCount ?? 0} groups found',
            onTap: () => context.push('/discover/similar'),
          ),
          const SizedBox(height: 8),
          DiscoverHubCard(
            leading: const Icon(Icons.blur_off),
            title: 'Low quality',
            subtitle: '${hub?.lowQualityCount ?? 0} items flagged',
            onTap: () => context.push('/discover/low-quality'),
          ),
          const SizedBox(height: 8),
          DiscoverHubCard(
            leading: const Icon(Icons.compress),
            title: 'Compression',
            subtitle: 'Shrink large images on device',
            onTap: () => context.push('/discover/compression'),
          ),
        ],
      ),
    );
  }
}
