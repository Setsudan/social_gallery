import 'package:social_gallery/core/cloud_backup/cloud_provider_preset.dart';

/// Validated S3-compatible connection settings for cloud backup.
class CloudBackupConfig {
  const CloudBackupConfig({
    required this.provider,
    required this.endpoint,
    required this.region,
    required this.bucket,
    required this.accessKey,
    required this.secretKey,
    required this.forcePathStyle,
    this.prefix = '',
    this.deviceId = '',
  });

  final CloudBackupProvider provider;
  final String endpoint;
  final String region;
  final String bucket;
  final String accessKey;
  final String secretKey;
  final bool forcePathStyle;
  final String prefix;
  final String deviceId;

  bool get isComplete =>
      endpoint.trim().isNotEmpty &&
      bucket.trim().isNotEmpty &&
      accessKey.trim().isNotEmpty &&
      secretKey.trim().isNotEmpty;

  Uri get endpointUri {
    var raw = endpoint.trim();
    if (!raw.startsWith('http://') && !raw.startsWith('https://')) {
      raw = 'https://$raw';
    }
    return Uri.parse(raw);
  }

  String objectKeyForChecksum(String plaintextChecksum) {
    final parts = <String>[
      if (prefix.trim().isNotEmpty)
        prefix.trim().replaceAll(RegExp(r'^/+|/+$'), ''),
      if (deviceId.trim().isNotEmpty) deviceId.trim(),
      plaintextChecksum,
    ];
    return parts.join('/');
  }
}
