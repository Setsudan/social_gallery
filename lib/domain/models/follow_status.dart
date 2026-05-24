enum FollowStatus {
  homeFeed,
  accountOnly,
  unfollowed;

  String get storageValue {
    switch (this) {
      case FollowStatus.homeFeed:
        return 'HOME_FEED';
      case FollowStatus.accountOnly:
        return 'ACCOUNT_ONLY';
      case FollowStatus.unfollowed:
        return 'UNFOLLOWED';
    }
  }

  static FollowStatus fromStorage(String value) {
    switch (value) {
      case 'ACCOUNT_ONLY':
        return FollowStatus.accountOnly;
      case 'UNFOLLOWED':
        return FollowStatus.unfollowed;
      default:
        return FollowStatus.homeFeed;
    }
  }
}
