import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// One backed-up file tracked on the desktop receiver.
class BackupInventoryEntry {
  const BackupInventoryEntry({
    this.mediaId,
    required this.checksum,
    required this.relativePath,
    required this.folderName,
    required this.fileName,
    this.syncedAtMs,
  });

  final int? mediaId;
  final String checksum;
  final String relativePath;
  final String folderName;
  final String fileName;
  final int? syncedAtMs;

  factory BackupInventoryEntry.fromJson(Map<String, dynamic> json) {
    return BackupInventoryEntry(
      mediaId: json['mediaId'] as int?,
      checksum: json['checksum'] as String? ?? '',
      relativePath: json['relativePath'] as String? ?? '',
      folderName: json['folderName'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      syncedAtMs: json['syncedAtMs'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (mediaId != null) 'mediaId': mediaId,
    'checksum': checksum,
    'relativePath': relativePath,
    'folderName': folderName,
    'fileName': fileName,
    if (syncedAtMs != null) 'syncedAtMs': syncedAtMs,
  };

  BackupInventoryEntry copyWith({
    int? mediaId,
    String? checksum,
    String? relativePath,
    String? folderName,
    String? fileName,
    int? syncedAtMs,
  }) {
    return BackupInventoryEntry(
      mediaId: mediaId ?? this.mediaId,
      checksum: checksum ?? this.checksum,
      relativePath: relativePath ?? this.relativePath,
      folderName: folderName ?? this.folderName,
      fileName: fileName ?? this.fileName,
      syncedAtMs: syncedAtMs ?? this.syncedAtMs,
    );
  }
}

/// Persisted manifest of files received on the desktop backup root.
class DesktopBackupInventory {
  DesktopBackupInventory({required this.backupRoot});

  final String backupRoot;

  static const _inventoryVersion = 1;
  static const _hiddenDir = '.social_gallery';
  static const _inventoryFile = 'inventory.json';

  static const _mediaExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
    '.heic',
    '.heif',
    '.mp4',
    '.mov',
    '.avi',
    '.mkv',
    '.webm',
  };

  final Map<int, BackupInventoryEntry> _byMediaId = {};
  final Map<String, BackupInventoryEntry> _byCanonicalPath = {};
  final Map<String, BackupInventoryEntry> _byFolderChecksum = {};

  String get _inventoryPath =>
      p.join(backupRoot, _hiddenDir, _inventoryFile);

  static String sanitizeFileName(String fileName) {
    return p.basename(fileName).replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }

  static String sanitizeFolderName(String folderName) {
    final safe = folderName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
    return safe.isEmpty ? 'Unsorted' : safe;
  }

  static String canonicalKey(String folderName, String fileName) {
    return '${sanitizeFolderName(folderName)}/${sanitizeFileName(fileName)}';
  }

  static String folderChecksumKey(String folderName, String checksum) {
    return '${sanitizeFolderName(folderName)}:$checksum';
  }

  Future<void> load() async {
    _byMediaId.clear();
    _byCanonicalPath.clear();
    _byFolderChecksum.clear();

    final file = File(_inventoryPath);
    if (!await file.exists()) return;

    try {
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final entries = json['entries'] as List<dynamic>? ?? const [];
      for (final raw in entries) {
        final entry = BackupInventoryEntry.fromJson(
          raw as Map<String, dynamic>,
        );
        _indexEntry(entry);
      }
    } catch (e) {
      debugPrint('Failed to load backup inventory: $e');
    }
  }

  Future<void> save() async {
    final dir = Directory(p.join(backupRoot, _hiddenDir));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }

    final seen = <String>{};
    final entries = <BackupInventoryEntry>[];

    void addUnique(BackupInventoryEntry entry) {
      final key = entry.relativePath;
      if (seen.add(key)) {
        entries.add(entry);
      }
    }

    for (final entry in _byMediaId.values) {
      addUnique(entry);
    }
    for (final entry in _byCanonicalPath.values) {
      addUnique(entry);
    }

    final payload = {
      'version': _inventoryVersion,
      'entries': entries.map((e) => e.toJson()).toList(),
    };
    await File(_inventoryPath).writeAsString(jsonEncode(payload));
  }

  void _indexEntry(BackupInventoryEntry entry) {
    _byCanonicalPath[canonicalKey(entry.folderName, entry.fileName)] = entry;
    _byFolderChecksum[folderChecksumKey(entry.folderName, entry.checksum)] =
        entry;
    final mediaId = entry.mediaId;
    if (mediaId != null) {
      _byMediaId[mediaId] = entry;
    }
  }

  BackupInventoryEntry? lookup(int mediaId) => _byMediaId[mediaId];

  BackupInventoryEntry? lookupByCanonicalPath(
    String folderName,
    String fileName,
  ) {
    return _byCanonicalPath[canonicalKey(folderName, fileName)];
  }

  BackupInventoryEntry? lookupByChecksumInFolder(
    String folderName,
    String checksum,
  ) {
    return _byFolderChecksum[folderChecksumKey(folderName, checksum)];
  }

  Future<void> upsert(BackupInventoryEntry entry) async {
    _indexEntry(entry);
    await save();
  }

  Future<void> backfillFromDisk({
    void Function(int scanned)? onProgress,
  }) async {
    final root = Directory(backupRoot);
    if (!await root.exists()) return;

    var scanned = 0;
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;

      final relative = p.relative(entity.path, from: backupRoot);
      if (relative.startsWith('$_hiddenDir${p.separator}') ||
          relative.startsWith('$_hiddenDir/')) {
        continue;
      }

      final ext = p.extension(entity.path).toLowerCase();
      if (!_mediaExtensions.contains(ext)) continue;

      scanned++;
      onProgress?.call(scanned);

      final checksum = await _hashFile(entity.path);
      final folderName = sanitizeFolderName(p.basename(p.dirname(entity.path)));
      final fileName = sanitizeFileName(p.basename(entity.path));

      final existing = lookupByCanonicalPath(folderName, fileName);
      if (existing != null && existing.checksum == checksum) {
        continue;
      }

      final entry = BackupInventoryEntry(
        checksum: checksum,
        relativePath: relative.replaceAll('\\', '/'),
        folderName: folderName,
        fileName: fileName,
      );
      _indexEntry(entry);
    }

    await save();
  }

  static Future<String> _hashFile(String path) async {
    final digest = await sha256.bind(File(path).openRead()).first;
    return digest.toString();
  }
}
