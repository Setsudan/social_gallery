import 'package:flutter_test/flutter_test.dart';
import 'package:social_gallery/domain/models/follow_status.dart';

void main() {
  test('follow status storage roundtrip', () {
    expect(FollowStatus.homeFeed.storageValue, 'HOME_FEED');
    expect(
      FollowStatus.fromStorage('ACCOUNT_ONLY'),
      FollowStatus.accountOnly,
    );
    expect(
      FollowStatus.fromStorage('UNFOLLOWED'),
      FollowStatus.unfollowed,
    );
  });
}
