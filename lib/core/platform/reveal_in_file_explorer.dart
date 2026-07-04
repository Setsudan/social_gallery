import 'dart:io';

import 'package:flutter/foundation.dart';

/// Opens the system file manager and highlights [filePath].
Future<bool> revealInFileExplorer(String filePath) async {
  if (kIsWeb) return false;

  final file = File(filePath);
  if (!file.existsSync()) return false;

  final normalized = file.absolute.path;

  if (Platform.isWindows) {
    final result = await Process.run(
      'explorer.exe',
      ['/select,', normalized.replaceAll('/', r'\')],
    );
    return result.exitCode == 0;
  }

  if (Platform.isMacOS) {
    final result = await Process.run('open', ['-R', normalized]);
    return result.exitCode == 0;
  }

  if (Platform.isLinux) {
    for (final command in [
      ['nautilus', '--select', normalized],
      ['dolphin', '--select', normalized],
      ['nemo', '--select', normalized],
    ]) {
      final result = await Process.run(command[0], command.sublist(1));
      if (result.exitCode == 0) return true;
    }
    final result = await Process.run('xdg-open', [file.parent.path]);
    return result.exitCode == 0;
  }

  return false;
}
