import 'package:flutter/foundation.dart';

class FolderUnlockStore extends ChangeNotifier {
  final Set<String> _unlockedPaths = {};

  bool isUnlocked(String folderPath) => _unlockedPaths.contains(folderPath);

  void unlock(String folderPath) {
    if (_unlockedPaths.add(folderPath)) {
      notifyListeners();
    }
  }

  void lock(String folderPath) {
    if (_unlockedPaths.remove(folderPath)) {
      notifyListeners();
    }
  }

  void lockAll() {
    if (_unlockedPaths.isEmpty) return;
    _unlockedPaths.clear();
    notifyListeners();
  }
}
