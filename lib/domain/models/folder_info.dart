import 'follow_status.dart';

class FolderInfo {
  const FolderInfo({
    required this.path,
    required this.name,
    required this.mediaCount,
    this.coverImageUri,
    this.followStatus = FollowStatus.homeFeed,
    this.showInStories = true,
    this.isBiometricLocked = false,
    this.biography,
  });

  final String path;
  final String name;
  final int mediaCount;
  final String? coverImageUri;
  final FollowStatus followStatus;
  final bool showInStories;
  final bool isBiometricLocked;
  final String? biography;

  bool get isLockedAccount =>
      followStatus == FollowStatus.accountOnly && isBiometricLocked;
}
