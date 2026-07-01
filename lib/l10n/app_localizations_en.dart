// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Social Gallery (beta)';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionSave => 'Save';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionOk => 'OK';

  @override
  String get actionApply => 'Apply';

  @override
  String get actionReset => 'Reset';

  @override
  String get actionKeep => 'Keep';

  @override
  String get actionUnlock => 'Unlock';

  @override
  String get actionClear => 'Clear';

  @override
  String get actionOpenSettings => 'Open settings';

  @override
  String get actionGoBack => 'Go Back';

  @override
  String get valueNotSet => 'Not set';

  @override
  String get errorGeneric => 'Error';

  @override
  String get errorCouldNotLoad => 'Could not load';

  @override
  String get errorMediaNotFound => 'Media not found';

  @override
  String get errorFolderNotFound => 'Folder not found';

  @override
  String get errorCouldNotUseFolder => 'Could not use that folder';

  @override
  String errorFailedToSelectFolder(String error) {
    return 'Failed to select folder: $error';
  }

  @override
  String errorCouldNotLoadFolders(String error) {
    return 'Could not load folders: $error';
  }

  @override
  String get emptyNothingHere => 'Nothing here';

  @override
  String get navHome => 'Home';

  @override
  String get navGallery => 'Gallery';

  @override
  String get navExplore => 'Explore';

  @override
  String get navAlbums => 'Albums';

  @override
  String get navDiscover => 'Discover';

  @override
  String get navLockedAlbums => 'Locked albums';

  @override
  String get navSettings => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get settingsSectionGallery => 'Gallery';

  @override
  String get settingsSectionContent => 'Content';

  @override
  String get settingsSectionOrganize => 'Organize';

  @override
  String get settingsSectionStorage => 'Storage';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System default';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageFrench => 'French';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsAccentColor => 'Accent color';

  @override
  String get settingsAccentColorDescription =>
      'Choose the accent used for buttons, links, and highlights.';

  @override
  String get settingsFontSize => 'Font size';

  @override
  String get settingsFontSizeDescription => 'Scale text across the app.';

  @override
  String get settingsAnimationSpeed => 'Animation speed';

  @override
  String get settingsAnimationSpeedDescription =>
      'Preview how fast transitions feel across the app.';

  @override
  String get settingsGalleryRootFolder => 'Gallery root folder';

  @override
  String get settingsGalleryRootFolderEmptySubtitle =>
      'Choose a folder to scan for photos and videos';

  @override
  String get settingsGalleryGridSize => 'Gallery grid size';

  @override
  String get settingsGalleryViewMode => 'Gallery view mode';

  @override
  String get settingsGalleryViewModeSubtitle =>
      'Pinch-zoom gallery tab instead of Home and Explore';

  @override
  String get settingsManageContent => 'Manage content';

  @override
  String get settingsManageContentSubtitle =>
      'Folders, home feed, and visibility';

  @override
  String get settingsTravelMode => 'Travel mode';

  @override
  String get settingsTravelModeSubtitle => 'Trips and date-range organization';

  @override
  String get settingsBatchSize => 'Batch size';

  @override
  String get settingsBatchSizeDescription =>
      'Number of photos per organize session.';

  @override
  String settingsBatchSizeValue(int count) {
    return '$count photos';
  }

  @override
  String get settingsQueueOrder => 'Queue order';

  @override
  String get settingsReleaseKeptPhotos => 'Release kept photos';

  @override
  String get settingsReleaseKeptPhotosSubtitle =>
      'Return processed photos to the organize queue';

  @override
  String get settingsTrashRetention => 'Trash retention';

  @override
  String get settingsTrashRetentionDescription =>
      'Items in trash are permanently removed after this period.';

  @override
  String settingsTrashRetentionDays(int days) {
    return '$days days';
  }

  @override
  String get settingsDeletedItems => 'Deleted items';

  @override
  String get settingsDeletedItemsSubtitle => 'View, restore, or empty trash';

  @override
  String get settingsCache => 'Cache';

  @override
  String get settingsCacheSizeLimit => 'Cache size limit';

  @override
  String get settingsCacheSizeLimitDescription =>
      'Maximum storage used by thumbnails and temp files.';

  @override
  String settingsCacheSizeLimitValue(int limitMb) {
    return '$limitMb MB';
  }

  @override
  String get settingsAutoClearOnClose => 'Auto-clear on close';

  @override
  String get settingsAutoClearOnCloseSubtitle =>
      'Clear cache when the app is closed';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsPrivacyPolicy => 'Privacy policy';

  @override
  String get settingsOpenSourceLicenses => 'Open-source licenses';

  @override
  String get settingsShareApp => 'Share app';

  @override
  String get settingsShareAppMessage =>
      'Check out Social Gallery - a local-first photo gallery.';

  @override
  String get dialogClearCacheTitle => 'Clear cache';

  @override
  String dialogClearCacheMessage(int size) {
    return 'Clear $size of cached thumbnails and temp files?';
  }

  @override
  String get snackbarCacheCleared => 'Cache cleared';

  @override
  String get snackbarReleasedKeptPhotos => 'Released kept photos';

  @override
  String get snackbarGalleryRootUpdated =>
      'Gallery root updated. Rescanning library.';

  @override
  String get dialogSelectRootGalleryFolder => 'Select Root Gallery Folder';

  @override
  String get debugBuildTitle => 'Debug build';

  @override
  String get debugBuildMessage =>
      'This is not a production build and may contain errors.';

  @override
  String get themeSystemDefault => 'System default';

  @override
  String get themeLight => 'Light';

  @override
  String get themeSolar => 'Solar';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeDarkOled => 'Dark OLED';

  @override
  String get accentBlue => 'Blue';

  @override
  String get accentPurple => 'Purple';

  @override
  String get accentGreen => 'Green';

  @override
  String get accentOrange => 'Orange';

  @override
  String get accentRed => 'Red';

  @override
  String get accentPink => 'Pink';

  @override
  String get accentTeal => 'Teal';

  @override
  String get gridSizeCompact => 'Compact';

  @override
  String get gridSizeStandard => 'Standard';

  @override
  String get gridSizeLarge => 'Large';

  @override
  String get gridSizeCompactSubtitle => 'Smaller thumbnails, more columns';

  @override
  String get gridSizeStandardSubtitle => 'Balanced layout';

  @override
  String get gridSizeLargeSubtitle => 'Bigger thumbnails, fewer columns';

  @override
  String get fontSizeSmall => 'Small';

  @override
  String get fontSizeNormal => 'Normal';

  @override
  String get fontSizeLarge => 'Large';

  @override
  String get fontSizeExtraLarge => 'Extra large';

  @override
  String get animationSpeedInstant => 'Instant';

  @override
  String get animationSpeedFast => 'Fast';

  @override
  String get animationSpeedNormal => 'Normal';

  @override
  String get animationSpeedSlow => 'Slow';

  @override
  String get queueOrderRandom => 'Random';

  @override
  String get queueOrderChronological => 'Chronological';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingGetStarted => 'Get started';

  @override
  String get onboardingWelcomeTitle => 'Welcome to Social Gallery';

  @override
  String get onboardingWelcomeBody =>
      'Your photos stay on your device. Set up a few preferences and we will index your library in the background.';

  @override
  String get onboardingPermissionsHeader => 'Permissions';

  @override
  String get onboardingPermissionsSubtitle =>
      'Allow access so we can scan your albums.';

  @override
  String get onboardingSelectGalleryFolderTitle => 'Select gallery folder';

  @override
  String get onboardingSelectGalleryFolderMessage =>
      'Choose a folder on your computer to scan for photos and videos.';

  @override
  String get onboardingChooseFolder => 'Choose folder';

  @override
  String get onboardingAllFilesAccessTitle => 'All files access (optional)';

  @override
  String get onboardingAllFilesAccessMessage =>
      'On Android 11+, grant \"All files access\" to move or delete items between albums. You can skip and grant it later.';

  @override
  String get onboardingGrantAccess => 'Grant access';

  @override
  String get onboardingContinueWithout => 'Continue without';

  @override
  String get onboardingPhotosAccessTitle => 'Photos access required';

  @override
  String get onboardingPhotosAccessMessage =>
      'Social Gallery needs access to your photos and videos to build your library.';

  @override
  String get onboardingGrantPermission => 'Grant permission';

  @override
  String get onboardingAccessGrantedTitle => 'Access granted';

  @override
  String get onboardingAccessGrantedLimitedMessage =>
      'Limited photo access is enabled. Your library is indexing in the background.';

  @override
  String get onboardingAccessGrantedFullMessage =>
      'Your library is indexing in the background while you finish setup.';

  @override
  String get onboardingGallerySyncRunning =>
      'Gallery sync running in background';

  @override
  String get onboardingLocationScanRunning =>
      'Photo locations indexing in background';

  @override
  String get onboardingChooseLanguageTitle => 'Choose your language';

  @override
  String get onboardingChooseLanguageSubtitle =>
      'Pick the language used across Social Gallery. You can change this later in Settings.';

  @override
  String get onboardingChooseThemeTitle => 'Choose a theme';

  @override
  String get onboardingChooseThemeSubtitle =>
      'Pick how Social Gallery looks. You can change this later.';

  @override
  String get onboardingAccentAndTextTitle => 'Accent and text';

  @override
  String get onboardingAccentAndTextSubtitle =>
      'Fine-tune colors and readability.';

  @override
  String get onboardingViewModeTitle => 'Gallery or social?';

  @override
  String get onboardingViewModeSubtitle =>
      'Choose your default browsing style.';

  @override
  String get onboardingSocialStyleTitle => 'Social style';

  @override
  String get onboardingSocialStyleDescription =>
      'Home feed with stories and posts, plus an Explore tab for discovery.';

  @override
  String get onboardingGalleryStyleTitle => 'Gallery style';

  @override
  String get onboardingGalleryStyleDescription =>
      'Pinch-zoom gallery grid on Home with albums on Explore.';

  @override
  String get onboardingViewModeHint =>
      'You can switch modes anytime in Settings.';

  @override
  String get onboardingYourFoldersTitle => 'Your folders';

  @override
  String get onboardingYourFoldersSubtitleIndexing =>
      'Indexing is still running. You can adjust folders later in Settings.';

  @override
  String get onboardingYourFoldersSubtitleChoose =>
      'Choose what appears on Home Feed, as account-only, or hidden.';

  @override
  String get onboardingNoFoldersYet =>
      'No folders found yet. Tap Get started to enter the app while sync continues.';

  @override
  String folderItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get folderVisibilityHome => 'Home';

  @override
  String get folderVisibilityAccount => 'Account';

  @override
  String get folderVisibilityLock => 'Lock';

  @override
  String get folderVisibilityHide => 'Hide';

  @override
  String get folderVisibilityHomeFeed => 'Home Feed';

  @override
  String get folderVisibilityAccountOnly => 'Account only';

  @override
  String get folderVisibilityAccountLocked => 'Account only (locked)';

  @override
  String get folderVisibilityHidden => 'Hidden';

  @override
  String get discoverBurstsTitle => 'Bursts';

  @override
  String get discoverBurstsMessage =>
      'Burst detection is not available yet. This screen will group rapid-fire shots.';

  @override
  String get discoverSuggestionsTitle => 'Smart suggestions';

  @override
  String get discoverSuggestionsMessage =>
      'Suggestions will highlight albums and clean-up ideas based on your library.';

  @override
  String get discoverLocationsTitle => 'Locations';

  @override
  String get discoverLocationsMessage =>
      'Browse photos grouped by place on a map or in albums.';

  @override
  String get locationsTabPlaces => 'Places';

  @override
  String get locationsTabMap => 'Map';

  @override
  String locationsIndexing(int indexed, int total) {
    return 'Indexing places $indexed / $total...';
  }

  @override
  String get locationsIndexingPreparing => 'Preparing location index...';

  @override
  String get locationsBackfillPreparing => 'Reading GPS from photos...';

  @override
  String locationsBackfillProgress(int indexed, int total) {
    return 'Reading GPS $indexed / $total...';
  }

  @override
  String get locationsEmptyTitle => 'No geotagged photos';

  @override
  String get locationsEmptyMessage =>
      'Photos with GPS data from your camera will appear here after the next library sync.';

  @override
  String locationsPhotoCount(int count) {
    return '$count photos';
  }

  @override
  String get locationsCountry => 'Countries';

  @override
  String get locationsCity => 'Cities';

  @override
  String locationsGeotaggedBadge(int count) {
    return '$count geotagged';
  }

  @override
  String get locationsErrorTitle => 'Could not load places';

  @override
  String get locationsErrorMessage =>
      'Something went wrong while resolving photo locations. Try again later.';

  @override
  String get homeErrorLoadFeed => 'Could not load feed';

  @override
  String get homeEmptyTitle => 'No posts yet';

  @override
  String get homeEmptyMessage => 'Add folders to Home Feed in Manage Content.';

  @override
  String get snackbarCameraCaptureComingSoon => 'Camera capture coming soon';

  @override
  String get tooltipSearchGallery => 'Search photos and videos';

  @override
  String get galleryErrorLoad => 'Could not load gallery';

  @override
  String get galleryEmptySearchTitle => 'No media found';

  @override
  String get galleryEmptyTitle => 'No media yet';

  @override
  String get galleryEmptySearchMessage =>
      'Try another photo name, album, or folder path.';

  @override
  String get galleryEmptyMessage =>
      'Sync your library to see photos and videos here.';

  @override
  String get tooltipSearch => 'Search';

  @override
  String get exploreErrorLoad => 'Could not load library';

  @override
  String get exploreEmptyTitle => 'No media found';

  @override
  String get exploreEmptyMessageNoSearch =>
      'Try a different search or add folders to Home Feed.';

  @override
  String get exploreEmptyMessageSearch =>
      'Try another photo name, album, or folder path.';

  @override
  String get searchAlbumsAndFolders => 'Albums and folders';

  @override
  String get searchNoMatchingAlbums =>
      'No matching albums. Try a photo or folder name.';

  @override
  String get searchRecentSearches => 'Recent searches';

  @override
  String get searchClearAll => 'Clear all';

  @override
  String get searchHint => 'Search photos, videos, or albums';

  @override
  String get tooltipClear => 'Clear';

  @override
  String get tooltipClearSearch => 'Clear search';

  @override
  String get tooltipLockedAlbums => 'Locked albums';

  @override
  String get albumsErrorLoad => 'Could not load albums';

  @override
  String get albumsTitle => 'Albums';

  @override
  String get albumsEmptyTitle => 'No albums yet';

  @override
  String get albumsEmptyMessage =>
      'Sync your library to see albums from your device.';

  @override
  String get lockedAlbumsTitle => 'Locked albums';

  @override
  String get lockedAlbumsEmptyTitle => 'No locked albums';

  @override
  String get lockedAlbumsEmptyMessage =>
      'Albums protected with biometrics will appear here.';

  @override
  String get favoritesEmptyTitle => 'No favorites yet';

  @override
  String get favoritesEmptyMessage =>
      'Double-tap a post on Home to favorite it.';

  @override
  String get storageAllFilesAccessTitle => 'All files access';

  @override
  String get storageAllFilesAccessGranted =>
      'Granted. You can move and delete items across albums.';

  @override
  String get storageAllFilesAccessRequired =>
      'Required on Android 11+ to move or delete items between albums.';

  @override
  String get storageGrantInSettings => 'Grant in settings';

  @override
  String get storageAllFilesAccessDialogMessage =>
      'Deleting or moving items between albums on Android 11+ requires \"All files access\" in system settings.';

  @override
  String get profileSelectFolder => 'Select folder';

  @override
  String get tooltipFileAccess => 'File access';

  @override
  String get tooltipManageContent => 'Manage content';

  @override
  String get tooltipSettings => 'Settings';

  @override
  String get profileNoFolderSelected => 'No folder selected';

  @override
  String get profileNoFolderSelectedMessage =>
      'Sync your library or pick a folder.';

  @override
  String get profileNoMediaInFolder => 'No media in this folder';

  @override
  String get profileErrorLoadFolder => 'Could not load folder';

  @override
  String get profileErrorLoadFolders => 'Could not load folders';

  @override
  String selectionCount(int count) {
    return '$count selected';
  }

  @override
  String get folderManagementNoFolders => 'No folders found.';

  @override
  String get folderShowInStories => 'Show in Stories';

  @override
  String get folderSecureLock => 'Secure Lock';

  @override
  String get folderChangeCover => 'Change cover';

  @override
  String get folderUseLatestPhoto => 'Use latest photo';

  @override
  String get folderVisibilityTitle => 'Folder visibility';

  @override
  String get folderBiographyTitle => 'Biography';

  @override
  String get folderAddBiography => 'Add biography';

  @override
  String get folderNoMedia => 'No media';

  @override
  String get tooltipAlbumOptions => 'Album options';

  @override
  String get folderPickerDefaultTitle => 'Move items to...';

  @override
  String get folderPickerSearchHint => 'Search folders';

  @override
  String albumChooseCoverTitle(String folderName) {
    return 'Choose cover for $folderName';
  }

  @override
  String albumCoverLoadError(String error) {
    return 'Could not load album photos: $error';
  }

  @override
  String get albumCoverNoPhotos =>
      'This album has no photos to use as a cover.';

  @override
  String get folderLockedTitle => 'This folder is locked';

  @override
  String folderLockedMessage(String folderName) {
    return 'Use biometrics to view $folderName.';
  }

  @override
  String folderUnlockReason(String folderName) {
    return 'Unlock $folderName';
  }

  @override
  String get folderBiometricsUnavailable =>
      'Biometrics are not available. Enroll fingerprint or face unlock in device settings.';

  @override
  String get folderAuthFailed => 'Authentication failed or was cancelled.';

  @override
  String get postMoveToTrash => 'Move to trash';

  @override
  String get postMoveToTrashMessage =>
      'This item will be moved to trash and can be restored from Settings.';

  @override
  String get tooltipDetails => 'Details';

  @override
  String get tooltipShare => 'Share';

  @override
  String get tooltipFavorite => 'Favorite';

  @override
  String get postOpenFolder => 'Open folder';

  @override
  String get metadataTitle => 'Details';

  @override
  String get metadataFilename => 'Filename';

  @override
  String get metadataDimensions => 'Dimensions';

  @override
  String get metadataType => 'Type';

  @override
  String get metadataSize => 'Size';

  @override
  String get metadataDateTaken => 'Date taken';

  @override
  String get metadataDateAdded => 'Date added';

  @override
  String get metadataFolder => 'Folder';

  @override
  String metadataDimensionsValue(int width, int height) {
    return '$width x $height';
  }

  @override
  String get mediaKindVideo => 'Video';

  @override
  String get mediaKindAudio => 'Audio';

  @override
  String get mediaKindImage => 'Image';

  @override
  String get mediaKindFile => 'File';

  @override
  String get organizeTitle => 'Organize';

  @override
  String organizeProgress(int done, int size) {
    return '$done / $size';
  }

  @override
  String organizeSharingItem(String name) {
    return 'Sharing $name';
  }

  @override
  String get organizeBatchComplete => 'Batch complete';

  @override
  String get organizeAllCaughtUp => 'All caught up';

  @override
  String organizeRemainingItems(int count) {
    return '$count items still match your filters.';
  }

  @override
  String get organizeNoMoreItems => 'No more items match the current filters.';

  @override
  String get organizeLoadNextBatch => 'Load next batch';

  @override
  String organizeReviewTrash(int count) {
    return 'Review trash ($count)';
  }

  @override
  String get organizeChangeFilter => 'Change filter';

  @override
  String get organizeReleaseKeptPhotos => 'Release kept photos';

  @override
  String get organizeFiltersTitle => 'Filters';

  @override
  String get organizeMediaType => 'Media type';

  @override
  String get organizeMediaAll => 'All';

  @override
  String get organizeMediaImage => 'Image';

  @override
  String get organizeMediaVideo => 'Video';

  @override
  String get organizeFilterFolder => 'Folder';

  @override
  String get organizeAllFolders => 'All folders';

  @override
  String get organizeFilterMonth => 'Month (YYYY-MM)';

  @override
  String get organizeStatsTitle => 'Organize stats';

  @override
  String get organizeStatProcessed => 'Processed';

  @override
  String get organizeStatDeleted => 'Deleted';

  @override
  String get organizeStatLiked => 'Liked';

  @override
  String get organizeStatSpaceSaved => 'Space saved';

  @override
  String organizeTrashReviewTitle(int count) {
    return 'Review trash ($count)';
  }

  @override
  String get organizeTrashReviewMessage =>
      'Selected items will be permanently deleted from your device.';

  @override
  String organizeTrashDeleteCount(int count) {
    return 'Delete $count items';
  }

  @override
  String get bulkMoveToTrashTitle => 'Move to trash';

  @override
  String bulkMoveToTrashMessage(int count) {
    return 'Move $count items to trash? You can restore them from Settings.';
  }

  @override
  String snackbarMovedToTrash(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return 'Moved $_temp0 to trash';
  }

  @override
  String snackbarMovedItems(int moved) {
    String _temp0 = intl.Intl.pluralLogic(
      moved,
      locale: localeName,
      other: '$moved items',
      one: '1 item',
    );
    return 'Moved $_temp0';
  }

  @override
  String get snackbarMoveFailed =>
      'Could not move items. Approve the system prompt if shown, or check storage access in Settings.';

  @override
  String snackbarMovedPartial(int moved, int total) {
    return 'Moved $moved of $total items';
  }

  @override
  String get bulkCreateAlbumTitle => 'Create album';

  @override
  String get bulkAlbumNameLabel => 'Album name';

  @override
  String get bulkCreateAndMove => 'Create and move';

  @override
  String snackbarAlbumCreatedAndMoved(String albumName, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return 'Created \"$albumName\" and moved $_temp0';
  }

  @override
  String get snackbarAlbumCreateFailed =>
      'Could not create album. Check storage access.';

  @override
  String get tooltipCancelSelection => 'Cancel selection';

  @override
  String get tooltipFavoriteSelected => 'Favorite selected';

  @override
  String get tooltipUnfavoriteSelected => 'Unfavorite selected';

  @override
  String get tooltipMoveSelected => 'Move selected';

  @override
  String get tooltipCreateAlbumAndMove => 'Create album and move';

  @override
  String get tooltipSetAlbumCover => 'Set as album cover';

  @override
  String get tooltipMoveToTrash => 'Move to trash';

  @override
  String get trashDeletePermanentlyTitle => 'Delete permanently';

  @override
  String trashDeletePermanentlyMessage(int count) {
    return 'Are you sure you want to permanently delete these $count items from your device? This action cannot be undone.';
  }

  @override
  String get trashDeletePermanentlyAction => 'Delete Permanently';

  @override
  String snackbarRestoredItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return 'Restored $_temp0';
  }

  @override
  String snackbarPermanentlyDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return 'Permanently deleted $_temp0';
  }

  @override
  String get tooltipRestoreSelected => 'Restore selected';

  @override
  String get tooltipDeletePermanently => 'Delete permanently';

  @override
  String get trashEmptyTitle => 'Trash is empty';

  @override
  String get trashEmptyMessage =>
      'Deleted files will stay here for recovery until they expire.';

  @override
  String get trashExpiresToday => 'Expires today';

  @override
  String trashDaysLeft(int days) {
    return '$days days left';
  }

  @override
  String get discoverSectionOrganize => 'Organize';

  @override
  String get discoverSectionDeepOrganize => 'Deep organize';

  @override
  String get discoverSectionInsights => 'Insights';

  @override
  String get discoverSectionCleanup => 'Cleanup';

  @override
  String get discoverSectionExplore => 'Explore';

  @override
  String get discoverErrorLoad => 'Could not load discover';

  @override
  String get discoverDeepOrganize => 'Deep organize';

  @override
  String get discoverDeepOrganizeSubtitle =>
      'Scan, similar photos, low quality, compression';

  @override
  String get discoverShootingStats => 'Shooting stats';

  @override
  String discoverShootingStatsSubtitle(int count) {
    return '$count items organized so far';
  }

  @override
  String get discoverLikesReview => 'Likes review';

  @override
  String discoverLikesReviewSubtitle(int count) {
    return '$count favorites';
  }

  @override
  String get discoverDuplicates => 'Duplicates';

  @override
  String get discoverDuplicatesSubtitle => 'Find near-identical photos';

  @override
  String get discoverBurstsSubtitle => 'Rapid-fire photo groups';

  @override
  String get discoverSuggestionsSubtitle => 'Album and cleanup ideas';

  @override
  String get discoverLocationsSubtitle => 'Photos grouped by place';

  @override
  String get deepOrganizeTitle => 'Deep organize';

  @override
  String get deepOrganizeSubtitle =>
      'Scan your library on device to find similar and low-quality photos.';

  @override
  String deepOrganizeScanProgress(int scanned, int total) {
    return 'Scanning $scanned / $total';
  }

  @override
  String get deepOrganizeScanning => 'Scanning...';

  @override
  String get deepOrganizeStartScan => 'Start scan';

  @override
  String get deepOrganizeToolsHeader => 'Tools';

  @override
  String get deepOrganizeCompressionSubtitle => 'Shrink large images on device';

  @override
  String get deepOrganizeSimilarPhotos => 'Similar photos';

  @override
  String deepOrganizeSimilarGroupsCount(int count) {
    return '$count groups';
  }

  @override
  String get deepOrganizeLowQuality => 'Low quality';

  @override
  String deepOrganizeLowQualityCount(int count) {
    return '$count items flagged';
  }

  @override
  String get deepOrganizeCompression => 'Compression';

  @override
  String get deepOrganizeRunScanFirst => 'Run a scan from Deep organize first.';

  @override
  String get similarPhotosEmptyTitle => 'No similar groups found';

  @override
  String get similarPhotosSubtitle =>
      'Pick the best shot and remove near-duplicates.';

  @override
  String similarPhotosGroupCount(int count) {
    return '$count similar items';
  }

  @override
  String get similarPhotosKeepBestDeleteOthers => 'Keep best, delete others';

  @override
  String get similarPhotosDeleteTitle => 'Delete similar photos';

  @override
  String similarPhotosDeleteMessage(String name, int count) {
    return 'Keep \"$name\" and delete $count similar items?';
  }

  @override
  String get lowQualityReviewTitle => 'Low quality review';

  @override
  String get lowQualityReviewSubtitle =>
      'Review flagged shots and delete what you do not need.';

  @override
  String get lowQualityEmptyTitle => 'No low-quality items';

  @override
  String lowQualityProgress(int index, int total) {
    return '$index / $total';
  }

  @override
  String get compressionTitle => 'Image compression';

  @override
  String get compressionSubtitle =>
      'Compress large photos without leaving the device.';

  @override
  String get compressionBestOnMobile => 'Best on mobile';

  @override
  String get compressionBestOnMobileSubtitle =>
      'Compression works on Android and iOS. Desktop support is limited.';

  @override
  String compressionResult(int done, int mb) {
    return 'Compressed $done images, saved $mb MB';
  }

  @override
  String compressionCandidatesCount(int count) {
    return '$count images over 3 MB';
  }

  @override
  String get compressionCompressing => 'Compressing...';

  @override
  String compressionCompressSelected(int count) {
    return 'Compress $count selected';
  }

  @override
  String get likesReviewEmptySubtitle =>
      'Swipe right in Organize to favorite photos.';

  @override
  String get likesReviewEmptyTitle => 'No liked items yet';

  @override
  String get likesReviewSubtitle => 'Scroll through your favorites.';

  @override
  String likesReviewSharing(String name) {
    return 'Sharing $name';
  }

  @override
  String get shootingStatsSubtitle => 'Your on-device photography habits.';

  @override
  String get shootingStatsPhotos => 'Photos';

  @override
  String get shootingStatsVideos => 'Videos';

  @override
  String get shootingStatsScreenshots => 'Screenshots';

  @override
  String get shootingStatsLiked => 'Liked';

  @override
  String get shootingStatsFolders => 'Folders';

  @override
  String get shootingStatsVideoDuration => 'Video duration';

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String get shootingStatsMostActiveDay => 'Most active day';

  @override
  String shootingStatsMostActiveDayValue(String date, int count) {
    return '$date ($count)';
  }

  @override
  String get shootingStatsHeatmap => 'Activity heatmap';

  @override
  String get shootingStatsNoActivity => 'No activity this month.';

  @override
  String shootingStatsHeatmapTooltip(String date, int count) {
    return '$date: $count';
  }

  @override
  String duplicateScanProgress(int scanned, int total) {
    return 'Analyzing $scanned / $total photos...';
  }

  @override
  String get duplicateScanPreparing => 'Preparing duplicate scan...';

  @override
  String get duplicatesEmptyTitle => 'No duplicate groups found';

  @override
  String get duplicatesEmptyMessage =>
      'No near-identical photos found. Duplicates are matched by visual similarity, not just file size.';

  @override
  String duplicatesGroupBadge(int count) {
    return '$count duplicates';
  }

  @override
  String get duplicatesKeepBestAndReview => 'Keep best and review';

  @override
  String get duplicateReviewTitle => 'Review duplicates';

  @override
  String get duplicateReviewSubtitle =>
      'Keep best is pre-selected. Tap items to change what will be removed.';

  @override
  String get duplicateReviewGroupNotFound => 'Group not found';

  @override
  String duplicateReviewDeleteCount(int count) {
    return 'Delete ($count)';
  }

  @override
  String snackbarDuplicatesRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count duplicates',
      one: '1 duplicate',
    );
    return 'Removed $_temp0.';
  }

  @override
  String get snackbarDuplicatesRemoveFailed =>
      'Could not remove some items. Check permissions.';

  @override
  String get travelModeEmptyTitle => 'No trips yet';

  @override
  String get travelModeEmptyMessage =>
      'Create a travel mode to auto-organize photos from a date range.';

  @override
  String get travelModeStatusActive => 'Active';

  @override
  String get travelModeStatusUpcoming => 'Upcoming';

  @override
  String get travelModeStatusCompleted => 'Completed';

  @override
  String travelModeListSubtitle(String start, String end, String folder) {
    return '$start - ${end}nFolder: $folder';
  }

  @override
  String get travelModeErrorLoad => 'Could not load travel modes';

  @override
  String get travelModeTripName => 'Trip name';

  @override
  String get travelModeTargetFolder => 'Target folder name';

  @override
  String get travelModeTargetFolderHelper =>
      'Album name for auto-moved media (no vault)';

  @override
  String get travelModeStart => 'Start';

  @override
  String get travelModeEnd => 'End';

  @override
  String get travelModeDate => 'Date';

  @override
  String get travelModeTime => 'Time';

  @override
  String get travelModeSpecificTime => 'Specific time';

  @override
  String get snackbarTravelModeRequiredFields =>
      'Name, folder, and dates are required';

  @override
  String get travelModeDeleteTitle => 'Delete travel mode';

  @override
  String get travelModeDeleteMessage => 'This cannot be undone.';

  @override
  String get storyNoStoriesFound => 'No recent stories found in this folder.';

  @override
  String get backupSectionTitle => 'Desktop backup';

  @override
  String get backupReceiveBackups => 'Receive backups';

  @override
  String get backupReceiveBackupsSubtitle =>
      'Allow this computer to receive photos from your phone';

  @override
  String get backupIndexingBackups => 'Indexing backups';

  @override
  String get backupShowPairingCode => 'Show pairing code';

  @override
  String get backupStartReceivingToShowCode => 'Start receiving to show code';

  @override
  String get backupPairedDevice => 'Paired device';

  @override
  String get backupUnpairDevice => 'Unpair device';

  @override
  String get backupUnpairDeviceSubtitle =>
      'Stop accepting backups from this phone';

  @override
  String get backupRefreshLibrary => 'Refresh library';

  @override
  String get backupRefreshLibrarySubtitle =>
      'Rescan folders after new backups arrive';

  @override
  String get backupBackUpToDesktop => 'Back up to desktop';

  @override
  String get backupBackUpToDesktopSubtitle =>
      'Automatic backup on same Wi-Fi when desktop is running';

  @override
  String get backupPairedDesktop => 'Paired desktop';

  @override
  String get backupPairWithDesktop => 'Pair with desktop';

  @override
  String get backupBackUpNow => 'Back up now';

  @override
  String get backupBackUpNowSubtitle => 'Only runs when desktop is available';

  @override
  String get backupUnpairDesktop => 'Unpair desktop';

  @override
  String get backupPairSheetTitle => 'Pair with desktop';

  @override
  String get backupPairSheetDescription =>
      'On your computer, enable Receive backups in Settings and enter the PIN shown there.';

  @override
  String get backupDesktopAddress => 'Desktop address';

  @override
  String get backupPort => 'Port';

  @override
  String get backupPinLabel => '6-digit PIN';

  @override
  String get backupScanPairingQr => 'Scan pairing QR code';

  @override
  String get backupFindOnNetwork => 'Find on network';

  @override
  String get backupPair => 'Pair';

  @override
  String get backupErrorNoDesktopFound =>
      'No desktop found. Enter the address shown on your computer.';

  @override
  String get backupErrorEnterHostPortPin =>
      'Enter host, port, and 6-digit PIN from desktop.';

  @override
  String get backupErrorPairingFailed =>
      'Pairing failed. Check the PIN and try again.';

  @override
  String get backupErrorInvalidQr =>
      'QR code is not a valid backup pairing link.';

  @override
  String get backupPairingSuccessTitle => 'Pairing successful';

  @override
  String backupPairingSuccessMessage(String deviceName) {
    return '$deviceName is now paired with this computer. Backups will start automatically when both devices are on the same Wi-Fi.';
  }

  @override
  String get backupPairYourPhoneTitle => 'Pair your phone';

  @override
  String backupPinDisplay(String pin) {
    return 'PIN: $pin';
  }

  @override
  String get backupQrInstructions =>
      'Scan with your phone camera or use Scan pairing QR in Settings > Desktop backup.';

  @override
  String get backupScanPairingQrTitle => 'Scan pairing QR';

  @override
  String backupStatusBackingUp(int processed, int total) {
    return 'Backing up $processed/$total';
  }

  @override
  String get backupStatusOff => 'Off';

  @override
  String get backupStatusWaitingForDesktop => 'Waiting for desktop';

  @override
  String get backupStatusDesktopReady => 'Desktop ready';

  @override
  String backupStatusLastBackup(String relativeTime) {
    return 'Last backup $relativeTime';
  }

  @override
  String get backupStatusUpToDate => 'Up to date';

  @override
  String backupStatusError(String detail) {
    return 'Error - $detail';
  }

  @override
  String get backupStatusIdle => 'Idle';

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinutesAgo(int n) {
    return '${n}m ago';
  }

  @override
  String timeHoursAgo(int n) {
    return '${n}h ago';
  }

  @override
  String timeDaysAgo(int n) {
    return '${n}d ago';
  }

  @override
  String get backupNotificationPreparing => 'Preparing backup...';

  @override
  String get backupNotificationInProgress => 'Backup in progress';

  @override
  String backupNotificationProgress(int processed, int total) {
    return 'Backed up $processed / $total items';
  }

  @override
  String get backupNotificationComplete => 'Backup complete';

  @override
  String get backupNotificationFailed => 'Backup failed';

  @override
  String get backupNotificationPaused => 'Backup paused';

  @override
  String get notificationChannelDuplicateScan => 'Duplicate scan';

  @override
  String get notificationChannelDuplicateScanDescription =>
      'Progress while searching for duplicate photos';

  @override
  String get notificationDuplicateScanTitle => 'Scanning for duplicates';

  @override
  String get notificationDuplicateScanPreparing =>
      'Preparing duplicate scan...';

  @override
  String notificationDuplicateScanProgress(int scanned, int total) {
    return 'Analyzing $scanned / $total photos...';
  }

  @override
  String get notificationDuplicateScanNoneTitle => 'No duplicates found';

  @override
  String get notificationDuplicateScanNoneBody =>
      'No near-identical photos were found in your library.';

  @override
  String get notificationDuplicateScanCompleteTitle =>
      'Duplicate scan complete';

  @override
  String notificationDuplicateScanCompleteBody(int count, String Found) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Found $count duplicate groups',
      one: 'Found 1 duplicate group',
    );
    return '$_temp0';
  }

  @override
  String get notificationDuplicateScanFailedTitle => 'Duplicate scan failed';

  @override
  String get notificationDuplicateScanFailedBody =>
      'Could not finish scanning. Open Duplicates to try again.';

  @override
  String get notificationChannelDesktopBackup => 'Desktop backup';

  @override
  String get notificationChannelDesktopBackupDescription =>
      'Progress while backing up photos to your computer';

  @override
  String get backupDetailDisabled => 'Backup disabled';

  @override
  String get backupDetailNotReceiving => 'Not receiving backups';

  @override
  String backupDetailPairedWith(String name) {
    return 'Paired with $name';
  }

  @override
  String get backupDetailReadyToReceive => 'Ready to receive backups';

  @override
  String get backupDetailIndexingBackups => 'Indexing existing backups...';

  @override
  String backupDetailIndexingBackupsProgress(int scanned) {
    return 'Indexing existing backups ($scanned files)...';
  }

  @override
  String get backupDetailSearchingDesktop => 'Searching for desktop...';

  @override
  String backupDetailFoundDesktop(String name) {
    return 'Found $name';
  }

  @override
  String get backupDetailNoDesktopFound => 'No desktop found on network';

  @override
  String get backupDetailNotPaired => 'Not paired';

  @override
  String get backupDetailCheckingDesktop => 'Checking desktop availability...';

  @override
  String get backupDetailWaitingForDesktop => 'Waiting for desktop';

  @override
  String get backupDetailDesktopReady => 'Desktop ready';

  @override
  String get backupDetailDesktopUnavailable => 'Desktop unavailable';

  @override
  String backupDetailReconcilingItems(int count) {
    return 'Reconciling $count items';
  }

  @override
  String get backupDetailReconciling => 'Reconciling with desktop';

  @override
  String backupDetailBackingUpItems(int count) {
    return 'Backing up $count items';
  }

  @override
  String get backupDetailCheckingItems => 'Checking for items to back up';

  @override
  String get backupDetailDesktopDisconnected => 'Desktop became unavailable';

  @override
  String get backupDetailWaitingForSync =>
      'Waiting for library sync to finish...';

  @override
  String backupDetailFoundMoreItems(int count) {
    return 'Found $count more items to back up';
  }

  @override
  String get backupDetailAllBackedUp => 'All photos are backed up';

  @override
  String backupDetailBackedUpItems(int count) {
    return 'Backed up $count items';
  }

  @override
  String backupDetailBackingUpBatch(int batch, int count) {
    return 'Backing up batch $batch ($count items)';
  }

  @override
  String backupDetailBackingUpFile(String folder, String name) {
    return 'Backing up $folder/$name';
  }

  @override
  String get backupDetailBackupFailed => 'Backup failed';

  @override
  String backupDetailReconcilingProgress(int count) {
    return 'Reconciling $count items...';
  }

  @override
  String get backupDetailReconcileFailed => 'Reconcile failed';

  @override
  String backupDetailVerifyingItems(int count) {
    return 'Verifying $count backed-up items...';
  }

  @override
  String get backupDetailVerifyFailed => 'Verify failed';

  @override
  String get backupDetailDesktopDisconnectedDuringReconcile =>
      'Desktop became unavailable during reconcile';

  @override
  String get backupDetailDesktopDisconnectedDuringVerify =>
      'Desktop became unavailable during verify';

  @override
  String get backupDetailDesktopDisconnectedDuringBackup =>
      'Desktop disconnected during backup';

  @override
  String get backupDetailDesktopDoesNotUpload =>
      'Desktop app does not upload to itself';

  @override
  String get backupDetailNotPairedWithDesktop => 'Not paired with a desktop';

  @override
  String get vaultPasswordSetTitle => 'Set vault backup password';

  @override
  String get vaultPasswordSetDescription =>
      'Locked albums are encrypted on your desktop as AES-256 protected archives. Choose a password you will use to browse them later.';

  @override
  String get vaultPasswordEnterTitle => 'Enter vault password';

  @override
  String get vaultPasswordEnterDescription =>
      'Enter your vault password to access encrypted backups on desktop.';

  @override
  String get vaultPasswordLabel => 'Password';

  @override
  String get vaultPasswordConfirmLabel => 'Confirm password';

  @override
  String get vaultPasswordChangeTitle => 'Vault backup password';

  @override
  String get vaultPasswordChangeSubtitle =>
      'Change the password used for encrypted locked-album backups';

  @override
  String get backupVaultStorageTitle => 'Encrypted vault storage';

  @override
  String backupVaultStorageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count encrypted files',
      one: '1 encrypted file',
      zero: 'No encrypted files',
    );
    return '$_temp0';
  }

  @override
  String get desktopArchiveTitle => 'Home archive';

  @override
  String get desktopArchiveBrowseTitle => 'Browse home archive';

  @override
  String get desktopArchiveBrowseSubtitle =>
      'View photos and videos stored on your desktop over Wi-Fi';

  @override
  String get desktopArchiveEmpty => 'No archived media found';

  @override
  String get desktopArchiveLoadFailed => 'Could not load desktop archive';

  @override
  String get desktopArchiveStreamFailed => 'Could not stream this file';

  @override
  String desktopArchiveItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }
}
