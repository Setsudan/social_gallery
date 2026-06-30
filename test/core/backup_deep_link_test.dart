import 'package:flutter_test/flutter_test.dart';
import 'package:social_gallery/core/backup/backup_deep_link.dart';

void main() {
  test('pairingUri builds socialgallery deep link', () {
    final uri = BackupDeepLink.pairingUri(
      address: '192.168.1.14',
      port: 49965,
      pin: '123456',
    );
    expect(uri.toString(), 'socialgallery://pair?ip=192.168.1.14&port=49965&pin=123456');
  });

  test('parse restores pairing params from deep link', () {
    final params = BackupDeepLink.parse(
      Uri.parse('socialgallery://pair?ip=10.0.0.2&port=8080&pin=654321'),
    );
    expect(params?.address, '10.0.0.2');
    expect(params?.port, 8080);
    expect(params?.pin, '654321');
  });

  test('parsePayload accepts deep link strings from QR scanners', () {
    final params = BackupDeepLink.parsePayload(
      'socialgallery://pair?ip=192.168.0.5&port=1234&pin=111111',
    );
    expect(params?.address, '192.168.0.5');
  });
}
