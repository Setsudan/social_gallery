import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/domain/models/media_analysis_result.dart';
import 'package:social_gallery/shared/widgets/one_ui/discover_hub_card.dart';

class DeepOrganizeToolsList extends StatelessWidget {
  const DeepOrganizeToolsList({
    super.key,
    required this.hub,
    this.compressionSubtitle = 'Shrink large images',
  });

  final DiscoverHubData? hub;
  final String compressionSubtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DiscoverHubCard(
          leading: const Icon(Icons.compare),
          title: 'Similar photos',
          subtitle: '${hub?.similarGroupCount ?? 0} groups',
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
          subtitle: compressionSubtitle,
          onTap: () => context.push('/discover/compression'),
        ),
      ],
    );
  }
}
