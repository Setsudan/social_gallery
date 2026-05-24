import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/shared/widgets/floating_bottom_nav.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  int _groupCount = 0;
  int _itemCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final candidates =
        await ref.read(mediaRepositoryProvider).getPotentialDuplicates();
    final groups = ref.read(findDuplicateGroupsProvider)(candidates);
    final items = groups.fold<int>(0, (sum, g) => sum + g.count);
    setState(() {
      _groupCount = groups.length;
      _itemCount = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(title: const Text('Discover')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: FloatingNavInsets.scrollPadding(context).add(
                  const EdgeInsets.all(16),
                ),
                children: [
                  Text(
                    'Offline insights',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (_groupCount == 0)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.check_circle_outline),
                        title: const Text('No duplicates found'),
                        subtitle: const Text(
                          'Your library looks clean based on file size and dimensions.',
                        ),
                      ),
                    )
                  else
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.copy_all),
                        title: const Text('Duplicates'),
                        subtitle: Text(
                          '$_groupCount groups, $_itemCount items',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/duplicates'),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
