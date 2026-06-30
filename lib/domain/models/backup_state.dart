/// Per-media backup status stored in [MediaItems.backupState].
enum MediaBackupState {
  pending(0),
  backedUp(1),
  inProgress(2),
  failed(3),
  skipped(4);

  const MediaBackupState(this.value);

  final int value;

  static MediaBackupState fromValue(int value) {
    return MediaBackupState.values.firstWhere(
      (state) => state.value == value,
      orElse: () => MediaBackupState.pending,
    );
  }

  bool get needsBackup =>
      this == MediaBackupState.pending || this == MediaBackupState.failed;
}
