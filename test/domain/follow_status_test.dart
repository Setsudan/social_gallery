import 'package:flutter_test/flutter_test.dart';
import 'package:social_gallery/domain/models/follow_status.dart';

void main() {
  test('filters home feed folders for timeline', () {
    final statuses = [
      FollowStatus.homeFeed,
      FollowStatus.accountOnly,
      FollowStatus.unfollowed,
    ];
    final feedFolders = statuses
        .where((s) => s == FollowStatus.homeFeed)
        .toList();
    expect(feedFolders.length, 1);
  });
}
