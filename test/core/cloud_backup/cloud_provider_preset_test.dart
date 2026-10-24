import 'package:flutter_test/flutter_test.dart';
import 'package:social_gallery/core/cloud_backup/cloud_provider_preset.dart';

void main() {
  test('presets set path-style and region defaults', () {
    final minio = CloudProviderPreset.forProvider(CloudBackupProvider.minio);
    expect(minio.forcePathStyle, isTrue);
    expect(minio.defaultRegion, 'us-east-1');

    final rustfs = CloudProviderPreset.forProvider(CloudBackupProvider.rustfs);
    expect(rustfs.forcePathStyle, isTrue);

    final r2 =
        CloudProviderPreset.forProvider(CloudBackupProvider.cloudflareR2);
    expect(r2.defaultRegion, 'auto');
    expect(r2.forcePathStyle, isFalse);
  });
}
