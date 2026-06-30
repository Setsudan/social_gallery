import 'package:flutter_test/flutter_test.dart';
import 'package:social_gallery/domain/models/backup_state.dart';

void main() {
  test('MediaBackupState round-trips through database values', () {
    expect(MediaBackupState.pending.value, 0);
    expect(MediaBackupState.backedUp.value, 1);
    expect(MediaBackupState.inProgress.value, 2);
    expect(MediaBackupState.failed.value, 3);
    expect(MediaBackupState.skipped.value, 4);
  });

  test('fromValue falls back to pending for unknown values', () {
    expect(MediaBackupState.fromValue(99), MediaBackupState.pending);
  });

  test('needsBackup is true only for pending and failed', () {
    expect(MediaBackupState.pending.needsBackup, isTrue);
    expect(MediaBackupState.failed.needsBackup, isTrue);
    expect(MediaBackupState.backedUp.needsBackup, isFalse);
    expect(MediaBackupState.inProgress.needsBackup, isFalse);
    expect(MediaBackupState.skipped.needsBackup, isFalse);
  });
}
