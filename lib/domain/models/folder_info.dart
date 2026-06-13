import 'follow_status.dart';

class FolderInfo {
  const FolderInfo({
    required this.path,
    required this.name,
    required this.mediaCount,
    this.coverImageUri,
    this.customCoverUri,
    this.followStatus = FollowStatus.homeFeed,
    this.showInStories = true,
    this.isBiometricLocked = false,
    this.biography,
  });

  final String path;
  final String name;
  final int mediaCount;
  final String? coverImageUri;
  final String? customCoverUri;
  final FollowStatus followStatus;
  final bool showInStories;
  final bool isBiometricLocked;
  final String? biography;

  bool get isLockedAccount =>
      followStatus == FollowStatus.accountOnly && isBiometricLocked;

  /// User-selected cover, else auto cover from the latest item in the album.
  String? get displayCoverUri {
    final custom = customCoverUri?.trim();
    if (custom != null && custom.isNotEmpty) return custom;
    final auto = coverImageUri?.trim();
    if (auto != null && auto.isNotEmpty) return auto;
    return null;
  }
}
