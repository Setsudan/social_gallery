import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';

Future<bool> ensureAllFilesAccess(BuildContext context, WidgetRef ref) async {
  final storage = ref.read(storageAccessServiceProvider);
  if (await storage.hasAllFilesAccess()) {
    return true;
  }

  if (!context.mounted) return false;

  final proceed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('All files access'),
      content: const Text(
        'Deleting or moving items between albums on Android 11+ requires '
        '"All files access" in system settings.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Open settings'),
        ),
      ],
    ),
  );

  if (proceed != true) return false;

  await storage.requestAllFilesAccess();
  return storage.hasAllFilesAccess();
}
