import 'dart:convert';

import 'package:social_gallery/core/backup/backup_file_metadata.dart';

/// Shared backup API constants and JSON models.
class BackupProtocol {
  BackupProtocol._();

  static const protocolVersion = 1;
  static const serviceType = '_socialgallery._tcp';
  static const chunkSize = 4 * 1024 * 1024;

  static Map<String, dynamic> decodeJson(String body) {
    return jsonDecode(body) as Map<String, dynamic>;
  }

  static String encodeJson(Map<String, dynamic> data) => jsonEncode(data);
}

class HealthResponse {
  const HealthResponse({
    required this.status,
    required this.deviceName,
    required this.protocolVersion,
    this.tokenValid = false,
  });

  factory HealthResponse.fromJson(Map<String, dynamic> json) {
    return HealthResponse(
      status: json['status'] as String? ?? 'unknown',
      deviceName: json['deviceName'] as String? ?? '',
      protocolVersion: json['protocolVersion'] as int? ?? 0,
      tokenValid: json['tokenValid'] as bool? ?? false,
    );
  }

  final String status;
  final String deviceName;
  final int protocolVersion;
  final bool tokenValid;

  bool get isReady => status == 'ready';
}

class PairRequest {
  const PairRequest({required this.pin, required this.deviceName});

  Map<String, dynamic> toJson() => {
    'pin': pin,
    'deviceName': deviceName,
  };

  final String pin;
  final String deviceName;
}

class PairResponse {
  const PairResponse({
    required this.token,
    required this.deviceId,
    required this.desktopName,
  });

  factory PairResponse.fromJson(Map<String, dynamic> json) {
    return PairResponse(
      token: json['token'] as String,
      deviceId: json['deviceId'] as String,
      desktopName: json['desktopName'] as String? ?? 'Desktop',
    );
  }

  final String token;
  final String deviceId;
  final String desktopName;
}

class BackupInitItem {
  const BackupInitItem({
    required this.id,
    required this.name,
    required this.folderName,
    required this.size,
    required this.mime,
    required this.checksum,
    this.dateTaken,
    this.dateModified,
    this.dateAdded,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'folderName': folderName,
    'size': size,
    'mime': mime,
    'checksum': checksum,
    if (dateTaken != null) 'dateTaken': dateTaken,
    if (dateModified != null) 'dateModified': dateModified,
    if (dateAdded != null) 'dateAdded': dateAdded,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
  };

  final int id;
  final String name;
  final String folderName;
  final int size;
  final String mime;
  final String checksum;
  final int? dateTaken;
  final int? dateModified;
  final int? dateAdded;
  final double? latitude;
  final double? longitude;

  BackupFileMetadata get metadata => BackupFileMetadata(
    dateTaken: dateTaken,
    dateModified: dateModified,
    dateAdded: dateAdded,
    latitude: latitude,
    longitude: longitude,
  );
}

class BackupInitResponse {
  const BackupInitResponse({required this.sessions});

  factory BackupInitResponse.fromJson(Map<String, dynamic> json) {
    final list = json['sessions'] as List<dynamic>? ?? const [];
    return BackupInitResponse(
      sessions: list
          .map((e) => BackupSession.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final List<BackupSession> sessions;
}

class BackupSession {
  const BackupSession({
    required this.mediaId,
    required this.sessionId,
    required this.relativePath,
    required this.alreadyExists,
  });

  factory BackupSession.fromJson(Map<String, dynamic> json) {
    return BackupSession(
      mediaId: json['mediaId'] as int,
      sessionId: json['sessionId'] as String,
      relativePath: json['relativePath'] as String? ?? '',
      alreadyExists: json['alreadyExists'] as bool? ?? false,
    );
  }

  final int mediaId;
  final String sessionId;
  final String relativePath;
  final bool alreadyExists;
}

class BackupCompleteRequest {
  const BackupCompleteRequest({
    required this.sessionId,
    required this.checksum,
  });

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'checksum': checksum,
  };

  final String sessionId;
  final String checksum;
}

class BackupCompleteResponse {
  const BackupCompleteResponse({
    required this.success,
    this.path,
    this.mediaId,
    this.checksum,
  });

  factory BackupCompleteResponse.fromJson(Map<String, dynamic> json) {
    return BackupCompleteResponse(
      success: json['success'] as bool? ?? false,
      path: json['path'] as String?,
      mediaId: json['mediaId'] as int?,
      checksum: json['checksum'] as String?,
    );
  }

  final bool success;
  final String? path;
  final int? mediaId;
  final String? checksum;

  bool matchesAck({required int mediaId, required String checksum}) {
    return success && this.mediaId == mediaId && this.checksum == checksum;
  }
}

class BackupReconcileItem {
  const BackupReconcileItem({
    required this.id,
    required this.checksum,
    required this.folderName,
    required this.name,
  });

  factory BackupReconcileItem.fromMedia({
    required int id,
    required String checksum,
    required String folderName,
    required String name,
  }) {
    return BackupReconcileItem(
      id: id,
      checksum: checksum,
      folderName: folderName,
      name: name,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'checksum': checksum,
    'folderName': folderName,
    'name': name,
  };

  final int id;
  final String checksum;
  final String folderName;
  final String name;
}

enum BackupReconcileStatus {
  present,
  missing,
  mismatch;

  static BackupReconcileStatus fromJson(String value) {
    return BackupReconcileStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => BackupReconcileStatus.missing,
    );
  }
}

class BackupReconcileResult {
  const BackupReconcileResult({
    required this.mediaId,
    required this.status,
  });

  factory BackupReconcileResult.fromJson(Map<String, dynamic> json) {
    return BackupReconcileResult(
      mediaId: json['mediaId'] as int,
      status: BackupReconcileStatus.fromJson(
        json['status'] as String? ?? 'missing',
      ),
    );
  }

  final int mediaId;
  final BackupReconcileStatus status;
}

class BackupReconcileResponse {
  const BackupReconcileResponse({required this.results});

  factory BackupReconcileResponse.fromJson(Map<String, dynamic> json) {
    final list = json['results'] as List<dynamic>? ?? const [];
    return BackupReconcileResponse(
      results: list
          .map((e) => BackupReconcileResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final List<BackupReconcileResult> results;
}

enum BackupVerifyStatus {
  present,
  missing;

  static BackupVerifyStatus fromJson(String value) {
    return BackupVerifyStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => BackupVerifyStatus.missing,
    );
  }
}

class BackupVerifyResult {
  const BackupVerifyResult({
    required this.mediaId,
    required this.status,
  });

  factory BackupVerifyResult.fromJson(Map<String, dynamic> json) {
    return BackupVerifyResult(
      mediaId: json['mediaId'] as int,
      status: BackupVerifyStatus.fromJson(
        json['status'] as String? ?? 'missing',
      ),
    );
  }

  final int mediaId;
  final BackupVerifyStatus status;
}

class BackupVerifyResponse {
  const BackupVerifyResponse({required this.results});

  factory BackupVerifyResponse.fromJson(Map<String, dynamic> json) {
    final list = json['results'] as List<dynamic>? ?? const [];
    return BackupVerifyResponse(
      results: list
          .map((e) => BackupVerifyResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final List<BackupVerifyResult> results;
}

class DiscoveredDesktop {
  const DiscoveredDesktop({
    required this.host,
    required this.port,
    required this.deviceName,
  });

  final String host;
  final int port;
  final String deviceName;
}
