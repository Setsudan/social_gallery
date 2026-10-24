import 'package:flutter_test/flutter_test.dart';
import 'package:social_gallery/core/cloud_backup/cloud_vault_key_store.dart';

void main() {
  test('register once; second register throws; unlock validates', () async {
    final store = CloudVaultKeyStore(storage: MemoryCloudSecureKv());
    expect(await store.isConfigured(), isFalse);

    await store.registerPassword('password-ok-1');
    expect(await store.isConfigured(), isTrue);

    final passwordBefore = await store.readPassword();
    await expectLater(
      store.registerPassword('password-ok-1'),
      throwsA(isA<StateError>()),
    );

    expect(await store.unlock('wrong-password'), isFalse);
    expect(await store.unlock('password-ok-1'), isTrue);
    expect(await store.readPassword(), passwordBefore);

    final key = await store.deriveEncryptionKey();
    expect(key, isNotNull);
    expect(key!.length, 32);
  });
}
