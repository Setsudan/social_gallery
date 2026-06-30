/// Controls where a folder appears in feed, explore, and account cards.
enum FollowStatus {
  /// Visible in home feed, stories (when enabled), and explore.
  homeFeed,

  /// Shown as account cards on Home; excluded from the main feed.
  accountOnly,

  /// Hidden from feed and explore.
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
