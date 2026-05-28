import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/domain/models/folder_info.dart';

/// Prompts biometrics when [folder] is locked and not yet unlocked this session.
Future<bool> ensureFolderUnlocked({
  required WidgetRef ref,
  required FolderInfo folder,
}) async {
  if (!folder.isLockedAccount) return true;

  final store = ref.read(folderUnlockStoreProvider);
  if (store.isUnlocked(folder.path)) return true;

  final biometric = ref.read(biometricServiceProvider);
  if (!await biometric.canCheckBiometrics()) return false;

  final ok = await biometric.authenticate(reason: 'Unlock ${folder.name}');
  if (ok) {
    store.unlock(folder.path);
  }
  return ok;
}
