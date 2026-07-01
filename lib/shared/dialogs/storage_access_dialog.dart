import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';

Future<bool> ensureAllFilesAccess(BuildContext context, WidgetRef ref) async {
  final storage = ref.read(storageAccessServiceProvider);
  if (await storage.hasAllFilesAccess()) {
    return true;
  }

  if (!context.mounted) return false;

  final l10n = context.l10n;
  final proceed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.storageAllFilesAccessTitle),
      content: Text(l10n.storageAllFilesAccessDialogMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.actionOpenSettings),
        ),
      ],
    ),
  );

  if (proceed != true) return false;

  await storage.requestAllFilesAccess();
  return storage.hasAllFilesAccess();
}
