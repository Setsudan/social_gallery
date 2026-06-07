import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_gallery/data/repositories/organize_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('pending trash ids persist across repository reads', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = OrganizeRepository(prefs);

    await repo.addPendingTrash(10);
    await repo.addPendingTrash(20);
    expect(repo.pendingTrashIds, {10, 20});

    await repo.removePendingTrash(10);
    expect(repo.pendingTrashIds, {20});

    await repo.clearPendingTrash();
    expect(repo.pendingTrashIds, isEmpty);
  });

  test('processed ids and stats update', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = OrganizeRepository(prefs);

    await repo.addProcessed(1);
    await repo.addProcessed(2);
    expect(repo.processedIds, {1, 2});

    await repo.updateStats(
      repo.stats.copyWith(processedCount: 2, deletedCount: 1, savedBytes: 5000),
    );
    expect(repo.stats.processedCount, 2);
    expect(repo.stats.deletedCount, 1);
    expect(repo.stats.savedBytes, 5000);

    await repo.clearProcessed();
    expect(repo.processedIds, isEmpty);
  });
}
