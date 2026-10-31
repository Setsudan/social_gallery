/// S3-compatible provider presets for cloud backup settings.
enum CloudBackupProvider {
  minio('minio'),
  rustfs('rustfs'),
  cloudflareR2('cloudflare_r2');

  const CloudBackupProvider(this.id);

  final String id;

  static CloudBackupProvider fromId(String id) {
    return CloudBackupProvider.values.firstWhere(
      (p) => p.id == id,
      orElse: () => CloudBackupProvider.minio,
    );
  }

  String get displayName => switch (this) {
    CloudBackupProvider.minio => 'MinIO',
    CloudBackupProvider.rustfs => 'RustFS',
    CloudBackupProvider.cloudflareR2 => 'Cloudflare R2',
  };
}

class CloudProviderPreset {
  const CloudProviderPreset({
    required this.provider,
    required this.defaultRegion,
    required this.forcePathStyle,
    this.endpointHint = '',
  });

  final CloudBackupProvider provider;
  final String defaultRegion;
  final bool forcePathStyle;
  final String endpointHint;

  static CloudProviderPreset forProvider(CloudBackupProvider provider) {
    return switch (provider) {
      CloudBackupProvider.minio => const CloudProviderPreset(
        provider: CloudBackupProvider.minio,
        defaultRegion: 'us-east-1',
        forcePathStyle: true,
        endpointHint: 'https://minio.example.com:9000',
      ),
      CloudBackupProvider.rustfs => const CloudProviderPreset(
        provider: CloudBackupProvider.rustfs,
        defaultRegion: 'us-east-1',
        forcePathStyle: true,
        endpointHint: 'https://rustfs.example.com',
      ),
      CloudBackupProvider.cloudflareR2 => const CloudProviderPreset(
        provider: CloudBackupProvider.cloudflareR2,
        defaultRegion: 'auto',
        forcePathStyle: false,
        endpointHint: 'https://<accountid>.r2.cloudflarestorage.com',
      ),
    };
  }
}
