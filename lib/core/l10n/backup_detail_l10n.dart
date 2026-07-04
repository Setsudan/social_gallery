import 'package:social_gallery/l10n/app_localizations.dart';

String localizeBackupDetail(AppLocalizations l10n, String detail) {
  if (detail.isEmpty) return detail;

  if (detail == 'Backup disabled') return l10n.backupDetailDisabled;
  if (detail == 'Not receiving backups') return l10n.backupDetailNotReceiving;
  if (detail == 'Ready to receive backups') return l10n.backupDetailReadyToReceive;
  if (detail == 'Indexing existing backups...') {
    return l10n.backupDetailIndexingBackups;
  }
  if (detail == 'Searching for desktop...') return l10n.backupDetailSearchingDesktop;
  if (detail == 'No desktop found on network') {
    return l10n.backupDetailNoDesktopFound;
  }
  if (detail == 'Not paired') return l10n.backupDetailNotPaired;
  if (detail == 'Checking desktop availability...') {
    return l10n.backupDetailCheckingDesktop;
  }
  if (detail == 'Waiting for desktop') return l10n.backupDetailWaitingForDesktop;
  if (detail == 'Desktop ready') return l10n.backupDetailDesktopReady;
  if (detail == 'Reconciling with desktop') return l10n.backupDetailReconciling;
  if (detail == 'Checking for items to back up') {
    return l10n.backupDetailCheckingItems;
  }
  if (detail == 'Desktop became unavailable') {
    return l10n.backupDetailDesktopDisconnected;
  }
  if (detail == 'Waiting for library sync to finish...') {
    return l10n.backupDetailWaitingForSync;
  }
  if (detail == 'All photos are backed up') return l10n.backupDetailAllBackedUp;
  if (detail == 'Backup failed') return l10n.backupDetailBackupFailed;
  if (detail == 'Reconcile failed') return l10n.backupDetailReconcileFailed;
  if (detail == 'Verify failed') return l10n.backupDetailVerifyFailed;
  if (detail == 'Desktop became unavailable during reconcile') {
    return l10n.backupDetailDesktopDisconnectedDuringReconcile;
  }
  if (detail == 'Desktop became unavailable during verify') {
    return l10n.backupDetailDesktopDisconnectedDuringVerify;
  }
  if (detail == 'Desktop disconnected during backup') {
    return l10n.backupDetailDesktopDisconnectedDuringBackup;
  }
  if (detail == 'Desktop app does not upload to itself') {
    return l10n.backupDetailDesktopDoesNotUpload;
  }
  if (detail == 'Not paired with a desktop') {
    return l10n.backupDetailNotPairedWithDesktop;
  }
  if (detail == 'Desktop unavailable') return l10n.backupDetailDesktopUnavailable;

  if (detail.startsWith('Paired with ')) {
    return l10n.backupDetailPairedWith(
      detail.substring('Paired with '.length),
    );
  }
  if (detail.startsWith('Receiving backup from ')) {
    return l10n.backupReceivingFromDevice(
      detail.substring('Receiving backup from '.length),
    );
  }
  if (detail.startsWith('Found ')) {
    return l10n.backupDetailFoundDesktop(detail.substring('Found '.length));
  }
  if (detail.startsWith('Indexing existing backups (')) {
    final scanned = _extractParenNumber(detail);
    if (scanned != null) {
      return l10n.backupDetailIndexingBackupsProgress(scanned);
    }
  }
  if (detail.startsWith('Reconciling ') && detail.endsWith(' items')) {
    final count = int.tryParse(
      detail.substring('Reconciling '.length, detail.length - ' items'.length),
    );
    if (count != null) return l10n.backupDetailReconcilingItems(count);
  }
  if (detail.startsWith('Reconciling ') && detail.endsWith(' items...')) {
    final count = int.tryParse(
      detail.substring(
        'Reconciling '.length,
        detail.length - ' items...'.length,
      ),
    );
    if (count != null) return l10n.backupDetailReconcilingProgress(count);
  }
  if (detail.startsWith('Backing up ') && detail.endsWith(' items')) {
    final count = int.tryParse(
      detail.substring('Backing up '.length, detail.length - ' items'.length),
    );
    if (count != null) return l10n.backupDetailBackingUpItems(count);
  }
  if (detail.startsWith('Found ') && detail.contains(' more items to back up')) {
    final count = int.tryParse(
      detail.substring('Found '.length, detail.indexOf(' more items')),
    );
    if (count != null) return l10n.backupDetailFoundMoreItems(count);
  }
  if (detail.startsWith('Backed up ') && detail.endsWith(' items')) {
    final count = int.tryParse(
      detail.substring('Backed up '.length, detail.length - ' items'.length),
    );
    if (count != null) return l10n.backupDetailBackedUpItems(count);
  }
  if (detail.startsWith('Verifying ') && detail.endsWith(' backed-up items...')) {
    final count = int.tryParse(
      detail.substring(
        'Verifying '.length,
        detail.length - ' backed-up items...'.length,
      ),
    );
    if (count != null) return l10n.backupDetailVerifyingItems(count);
  }
  if (detail.startsWith('Backing up batch ')) {
    final match = RegExp(r'^Backing up batch (\d+) \((\d+) items\)$').firstMatch(
      detail,
    );
    if (match != null) {
      return l10n.backupDetailBackingUpBatch(
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
      );
    }
  }
  if (detail.startsWith('Backed up ') && detail.contains(' failed')) {
    final match = RegExp(
      r'^Backed up (\d+) items, (\d+) failed$',
    ).firstMatch(detail);
    if (match != null) {
      return l10n.backupDetailBackedUpWithFailures(
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
      );
    }
  }
  if (detail.startsWith('Backing up ') && detail.endsWith('%)')) {
    final match = RegExp(r'^Backing up (\d+) files \((\d+)%\)$').firstMatch(
      detail,
    );
    if (match != null) {
      return l10n.backupDetailBackingUpFilesProgress(
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
      );
    }
  }
  if (detail.startsWith('Backing up ') && detail.contains('/')) {
    final percentMatch = RegExp(r'^Backing up (.+) \((\d+)%\)$').firstMatch(detail);
    if (percentMatch != null) {
      return l10n.backupDetailBackingUpFileProgress(
        percentMatch.group(1)!,
        int.parse(percentMatch.group(2)!),
      );
    }
    final slash = detail.indexOf('/');
    final folder = detail.substring('Backing up '.length, slash);
    final name = detail.substring(slash + 1);
    return l10n.backupDetailBackingUpFile(folder, name);
  }

  if (detail.contains(' - ') && RegExp(r' - \d+%$').hasMatch(detail)) {
    final match = RegExp(r'^(.+) - (\d+)%$').firstMatch(detail);
    if (match != null) {
      return l10n.backupDetailReceivingFileProgress(
        match.group(1)!,
        int.parse(match.group(2)!),
      );
    }
  }

  return detail;
}

int? _extractParenNumber(String detail) {
  final start = detail.indexOf('(');
  final end = detail.indexOf(' files');
  if (start == -1 || end == -1 || end <= start + 1) return null;
  return int.tryParse(detail.substring(start + 1, end));
}

String localizeBackupRelativeTime(AppLocalizations l10n, DateTime? lastBackupAt) {
  if (lastBackupAt == null) return l10n.backupStatusUpToDate;
  final diff = DateTime.now().difference(lastBackupAt);
  if (diff.inMinutes < 1) return l10n.timeJustNow;
  if (diff.inHours < 1) return l10n.timeMinutesAgo(diff.inMinutes);
  if (diff.inDays < 1) return l10n.timeHoursAgo(diff.inHours);
  return l10n.timeDaysAgo(diff.inDays);
}
