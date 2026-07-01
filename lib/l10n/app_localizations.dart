import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Social Gallery (beta)'**
  String get appTitle;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get actionOk;

  /// No description provided for @actionApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get actionApply;

  /// No description provided for @actionReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get actionReset;

  /// No description provided for @actionKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get actionKeep;

  /// No description provided for @actionUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get actionUnlock;

  /// No description provided for @actionClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get actionClear;

  /// No description provided for @actionOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get actionOpenSettings;

  /// No description provided for @actionGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get actionGoBack;

  /// No description provided for @valueNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get valueNotSet;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorGeneric;

  /// No description provided for @errorCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load'**
  String get errorCouldNotLoad;

  /// No description provided for @errorMediaNotFound.
  ///
  /// In en, this message translates to:
  /// **'Media not found'**
  String get errorMediaNotFound;

  /// No description provided for @errorFolderNotFound.
  ///
  /// In en, this message translates to:
  /// **'Folder not found'**
  String get errorFolderNotFound;

  /// No description provided for @errorCouldNotUseFolder.
  ///
  /// In en, this message translates to:
  /// **'Could not use that folder'**
  String get errorCouldNotUseFolder;

  /// No description provided for @errorFailedToSelectFolder.
  ///
  /// In en, this message translates to:
  /// **'Failed to select folder: {error}'**
  String errorFailedToSelectFolder(String error);

  /// No description provided for @errorCouldNotLoadFolders.
  ///
  /// In en, this message translates to:
  /// **'Could not load folders: {error}'**
  String errorCouldNotLoadFolders(String error);

  /// No description provided for @emptyNothingHere.
  ///
  /// In en, this message translates to:
  /// **'Nothing here'**
  String get emptyNothingHere;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get navGallery;

  /// No description provided for @navExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get navExplore;

  /// No description provided for @navAlbums.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get navAlbums;

  /// No description provided for @navDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get navDiscover;

  /// No description provided for @navLockedAlbums.
  ///
  /// In en, this message translates to:
  /// **'Locked albums'**
  String get navLockedAlbums;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsSectionGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get settingsSectionGallery;

  /// No description provided for @settingsSectionContent.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get settingsSectionContent;

  /// No description provided for @settingsSectionOrganize.
  ///
  /// In en, this message translates to:
  /// **'Organize'**
  String get settingsSectionOrganize;

  /// No description provided for @settingsSectionStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get settingsSectionStorage;

  /// No description provided for @settingsSectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSectionAbout;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get settingsLanguageFrench;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsAccentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get settingsAccentColor;

  /// No description provided for @settingsAccentColorDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose the accent used for buttons, links, and highlights.'**
  String get settingsAccentColorDescription;

  /// No description provided for @settingsFontSize.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get settingsFontSize;

  /// No description provided for @settingsFontSizeDescription.
  ///
  /// In en, this message translates to:
  /// **'Scale text across the app.'**
  String get settingsFontSizeDescription;

  /// No description provided for @settingsAnimationSpeed.
  ///
  /// In en, this message translates to:
  /// **'Animation speed'**
  String get settingsAnimationSpeed;

  /// No description provided for @settingsAnimationSpeedDescription.
  ///
  /// In en, this message translates to:
  /// **'Preview how fast transitions feel across the app.'**
  String get settingsAnimationSpeedDescription;

  /// No description provided for @settingsGalleryRootFolder.
  ///
  /// In en, this message translates to:
  /// **'Gallery root folder'**
  String get settingsGalleryRootFolder;

  /// No description provided for @settingsGalleryRootFolderEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a folder to scan for photos and videos'**
  String get settingsGalleryRootFolderEmptySubtitle;

  /// No description provided for @settingsGalleryGridSize.
  ///
  /// In en, this message translates to:
  /// **'Gallery grid size'**
  String get settingsGalleryGridSize;

  /// No description provided for @settingsGalleryViewMode.
  ///
  /// In en, this message translates to:
  /// **'Gallery view mode'**
  String get settingsGalleryViewMode;

  /// No description provided for @settingsGalleryViewModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pinch-zoom gallery tab instead of Home and Explore'**
  String get settingsGalleryViewModeSubtitle;

  /// No description provided for @settingsManageContent.
  ///
  /// In en, this message translates to:
  /// **'Manage content'**
  String get settingsManageContent;

  /// No description provided for @settingsManageContentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Folders, home feed, and visibility'**
  String get settingsManageContentSubtitle;

  /// No description provided for @settingsTravelMode.
  ///
  /// In en, this message translates to:
  /// **'Travel mode'**
  String get settingsTravelMode;

  /// No description provided for @settingsTravelModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Trips and date-range organization'**
  String get settingsTravelModeSubtitle;

  /// No description provided for @settingsBatchSize.
  ///
  /// In en, this message translates to:
  /// **'Batch size'**
  String get settingsBatchSize;

  /// No description provided for @settingsBatchSizeDescription.
  ///
  /// In en, this message translates to:
  /// **'Number of photos per organize session.'**
  String get settingsBatchSizeDescription;

  /// No description provided for @settingsBatchSizeValue.
  ///
  /// In en, this message translates to:
  /// **'{count} photos'**
  String settingsBatchSizeValue(int count);

  /// No description provided for @settingsQueueOrder.
  ///
  /// In en, this message translates to:
  /// **'Queue order'**
  String get settingsQueueOrder;

  /// No description provided for @settingsReleaseKeptPhotos.
  ///
  /// In en, this message translates to:
  /// **'Release kept photos'**
  String get settingsReleaseKeptPhotos;

  /// No description provided for @settingsReleaseKeptPhotosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Return processed photos to the organize queue'**
  String get settingsReleaseKeptPhotosSubtitle;

  /// No description provided for @settingsTrashRetention.
  ///
  /// In en, this message translates to:
  /// **'Trash retention'**
  String get settingsTrashRetention;

  /// No description provided for @settingsTrashRetentionDescription.
  ///
  /// In en, this message translates to:
  /// **'Items in trash are permanently removed after this period.'**
  String get settingsTrashRetentionDescription;

  /// No description provided for @settingsTrashRetentionDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String settingsTrashRetentionDays(int days);

  /// No description provided for @settingsDeletedItems.
  ///
  /// In en, this message translates to:
  /// **'Deleted items'**
  String get settingsDeletedItems;

  /// No description provided for @settingsDeletedItemsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View, restore, or empty trash'**
  String get settingsDeletedItemsSubtitle;

  /// No description provided for @settingsCache.
  ///
  /// In en, this message translates to:
  /// **'Cache'**
  String get settingsCache;

  /// No description provided for @settingsCacheSizeLimit.
  ///
  /// In en, this message translates to:
  /// **'Cache size limit'**
  String get settingsCacheSizeLimit;

  /// No description provided for @settingsCacheSizeLimitDescription.
  ///
  /// In en, this message translates to:
  /// **'Maximum storage used by thumbnails and temp files.'**
  String get settingsCacheSizeLimitDescription;

  /// No description provided for @settingsCacheSizeLimitValue.
  ///
  /// In en, this message translates to:
  /// **'{limitMb} MB'**
  String settingsCacheSizeLimitValue(int limitMb);

  /// No description provided for @settingsAutoClearOnClose.
  ///
  /// In en, this message translates to:
  /// **'Auto-clear on close'**
  String get settingsAutoClearOnClose;

  /// No description provided for @settingsAutoClearOnCloseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clear cache when the app is closed'**
  String get settingsAutoClearOnCloseSubtitle;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsOpenSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get settingsOpenSourceLicenses;

  /// No description provided for @settingsShareApp.
  ///
  /// In en, this message translates to:
  /// **'Share app'**
  String get settingsShareApp;

  /// No description provided for @settingsShareAppMessage.
  ///
  /// In en, this message translates to:
  /// **'Check out Social Gallery - a local-first photo gallery.'**
  String get settingsShareAppMessage;

  /// No description provided for @dialogClearCacheTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get dialogClearCacheTitle;

  /// No description provided for @dialogClearCacheMessage.
  ///
  /// In en, this message translates to:
  /// **'Clear {size} of cached thumbnails and temp files?'**
  String dialogClearCacheMessage(int size);

  /// No description provided for @snackbarCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared'**
  String get snackbarCacheCleared;

  /// No description provided for @snackbarReleasedKeptPhotos.
  ///
  /// In en, this message translates to:
  /// **'Released kept photos'**
  String get snackbarReleasedKeptPhotos;

  /// No description provided for @snackbarGalleryRootUpdated.
  ///
  /// In en, this message translates to:
  /// **'Gallery root updated. Rescanning library.'**
  String get snackbarGalleryRootUpdated;

  /// No description provided for @dialogSelectRootGalleryFolder.
  ///
  /// In en, this message translates to:
  /// **'Select Root Gallery Folder'**
  String get dialogSelectRootGalleryFolder;

  /// No description provided for @debugBuildTitle.
  ///
  /// In en, this message translates to:
  /// **'Debug build'**
  String get debugBuildTitle;

  /// No description provided for @debugBuildMessage.
  ///
  /// In en, this message translates to:
  /// **'This is not a production build and may contain errors.'**
  String get debugBuildMessage;

  /// No description provided for @themeSystemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get themeSystemDefault;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeSolar.
  ///
  /// In en, this message translates to:
  /// **'Solar'**
  String get themeSolar;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeDarkOled.
  ///
  /// In en, this message translates to:
  /// **'Dark OLED'**
  String get themeDarkOled;

  /// No description provided for @accentBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get accentBlue;

  /// No description provided for @accentPurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get accentPurple;

  /// No description provided for @accentGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get accentGreen;

  /// No description provided for @accentOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get accentOrange;

  /// No description provided for @accentRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get accentRed;

  /// No description provided for @accentPink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get accentPink;

  /// No description provided for @accentTeal.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get accentTeal;

  /// No description provided for @gridSizeCompact.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get gridSizeCompact;

  /// No description provided for @gridSizeStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get gridSizeStandard;

  /// No description provided for @gridSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get gridSizeLarge;

  /// No description provided for @gridSizeCompactSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Smaller thumbnails, more columns'**
  String get gridSizeCompactSubtitle;

  /// No description provided for @gridSizeStandardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Balanced layout'**
  String get gridSizeStandardSubtitle;

  /// No description provided for @gridSizeLargeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bigger thumbnails, fewer columns'**
  String get gridSizeLargeSubtitle;

  /// No description provided for @fontSizeSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get fontSizeSmall;

  /// No description provided for @fontSizeNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get fontSizeNormal;

  /// No description provided for @fontSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get fontSizeLarge;

  /// No description provided for @fontSizeExtraLarge.
  ///
  /// In en, this message translates to:
  /// **'Extra large'**
  String get fontSizeExtraLarge;

  /// No description provided for @animationSpeedInstant.
  ///
  /// In en, this message translates to:
  /// **'Instant'**
  String get animationSpeedInstant;

  /// No description provided for @animationSpeedFast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get animationSpeedFast;

  /// No description provided for @animationSpeedNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get animationSpeedNormal;

  /// No description provided for @animationSpeedSlow.
  ///
  /// In en, this message translates to:
  /// **'Slow'**
  String get animationSpeedSlow;

  /// No description provided for @queueOrderRandom.
  ///
  /// In en, this message translates to:
  /// **'Random'**
  String get queueOrderRandom;

  /// No description provided for @queueOrderChronological.
  ///
  /// In en, this message translates to:
  /// **'Chronological'**
  String get queueOrderChronological;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Social Gallery'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Your photos stay on your device. Set up a few preferences and we will index your library in the background.'**
  String get onboardingWelcomeBody;

  /// No description provided for @onboardingPermissionsHeader.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get onboardingPermissionsHeader;

  /// No description provided for @onboardingPermissionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allow access so we can scan your albums.'**
  String get onboardingPermissionsSubtitle;

  /// No description provided for @onboardingSelectGalleryFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Select gallery folder'**
  String get onboardingSelectGalleryFolderTitle;

  /// No description provided for @onboardingSelectGalleryFolderMessage.
  ///
  /// In en, this message translates to:
  /// **'Choose a folder on your computer to scan for photos and videos.'**
  String get onboardingSelectGalleryFolderMessage;

  /// No description provided for @onboardingChooseFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose folder'**
  String get onboardingChooseFolder;

  /// No description provided for @onboardingAllFilesAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'All files access (optional)'**
  String get onboardingAllFilesAccessTitle;

  /// No description provided for @onboardingAllFilesAccessMessage.
  ///
  /// In en, this message translates to:
  /// **'On Android 11+, grant \"All files access\" to move or delete items between albums. You can skip and grant it later.'**
  String get onboardingAllFilesAccessMessage;

  /// No description provided for @onboardingGrantAccess.
  ///
  /// In en, this message translates to:
  /// **'Grant access'**
  String get onboardingGrantAccess;

  /// No description provided for @onboardingContinueWithout.
  ///
  /// In en, this message translates to:
  /// **'Continue without'**
  String get onboardingContinueWithout;

  /// No description provided for @onboardingPhotosAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Photos access required'**
  String get onboardingPhotosAccessTitle;

  /// No description provided for @onboardingPhotosAccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Social Gallery needs access to your photos and videos to build your library.'**
  String get onboardingPhotosAccessMessage;

  /// No description provided for @onboardingGrantPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant permission'**
  String get onboardingGrantPermission;

  /// No description provided for @onboardingAccessGrantedTitle.
  ///
  /// In en, this message translates to:
  /// **'Access granted'**
  String get onboardingAccessGrantedTitle;

  /// No description provided for @onboardingAccessGrantedLimitedMessage.
  ///
  /// In en, this message translates to:
  /// **'Limited photo access is enabled. Your library is indexing in the background.'**
  String get onboardingAccessGrantedLimitedMessage;

  /// No description provided for @onboardingAccessGrantedFullMessage.
  ///
  /// In en, this message translates to:
  /// **'Your library is indexing in the background while you finish setup.'**
  String get onboardingAccessGrantedFullMessage;

  /// No description provided for @onboardingGallerySyncRunning.
  ///
  /// In en, this message translates to:
  /// **'Gallery sync running in background'**
  String get onboardingGallerySyncRunning;

  /// No description provided for @onboardingLocationScanRunning.
  ///
  /// In en, this message translates to:
  /// **'Photo locations indexing in background'**
  String get onboardingLocationScanRunning;

  /// No description provided for @onboardingChooseLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get onboardingChooseLanguageTitle;

  /// No description provided for @onboardingChooseLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick the language used across Social Gallery. You can change this later in Settings.'**
  String get onboardingChooseLanguageSubtitle;

  /// No description provided for @onboardingChooseThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a theme'**
  String get onboardingChooseThemeTitle;

  /// No description provided for @onboardingChooseThemeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick how Social Gallery looks. You can change this later.'**
  String get onboardingChooseThemeSubtitle;

  /// No description provided for @onboardingAccentAndTextTitle.
  ///
  /// In en, this message translates to:
  /// **'Accent and text'**
  String get onboardingAccentAndTextTitle;

  /// No description provided for @onboardingAccentAndTextSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fine-tune colors and readability.'**
  String get onboardingAccentAndTextSubtitle;

  /// No description provided for @onboardingViewModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Gallery or social?'**
  String get onboardingViewModeTitle;

  /// No description provided for @onboardingViewModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your default browsing style.'**
  String get onboardingViewModeSubtitle;

  /// No description provided for @onboardingSocialStyleTitle.
  ///
  /// In en, this message translates to:
  /// **'Social style'**
  String get onboardingSocialStyleTitle;

  /// No description provided for @onboardingSocialStyleDescription.
  ///
  /// In en, this message translates to:
  /// **'Home feed with stories and posts, plus an Explore tab for discovery.'**
  String get onboardingSocialStyleDescription;

  /// No description provided for @onboardingGalleryStyleTitle.
  ///
  /// In en, this message translates to:
  /// **'Gallery style'**
  String get onboardingGalleryStyleTitle;

  /// No description provided for @onboardingGalleryStyleDescription.
  ///
  /// In en, this message translates to:
  /// **'Pinch-zoom gallery grid on Home with albums on Explore.'**
  String get onboardingGalleryStyleDescription;

  /// No description provided for @onboardingViewModeHint.
  ///
  /// In en, this message translates to:
  /// **'You can switch modes anytime in Settings.'**
  String get onboardingViewModeHint;

  /// No description provided for @onboardingYourFoldersTitle.
  ///
  /// In en, this message translates to:
  /// **'Your folders'**
  String get onboardingYourFoldersTitle;

  /// No description provided for @onboardingYourFoldersSubtitleIndexing.
  ///
  /// In en, this message translates to:
  /// **'Indexing is still running. You can adjust folders later in Settings.'**
  String get onboardingYourFoldersSubtitleIndexing;

  /// No description provided for @onboardingYourFoldersSubtitleChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose what appears on Home Feed, as account-only, or hidden.'**
  String get onboardingYourFoldersSubtitleChoose;

  /// No description provided for @onboardingNoFoldersYet.
  ///
  /// In en, this message translates to:
  /// **'No folders found yet. Tap Get started to enter the app while sync continues.'**
  String get onboardingNoFoldersYet;

  /// No description provided for @folderItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String folderItemCount(int count);

  /// No description provided for @folderVisibilityHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get folderVisibilityHome;

  /// No description provided for @folderVisibilityAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get folderVisibilityAccount;

  /// No description provided for @folderVisibilityLock.
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get folderVisibilityLock;

  /// No description provided for @folderVisibilityHide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get folderVisibilityHide;

  /// No description provided for @folderVisibilityHomeFeed.
  ///
  /// In en, this message translates to:
  /// **'Home Feed'**
  String get folderVisibilityHomeFeed;

  /// No description provided for @folderVisibilityAccountOnly.
  ///
  /// In en, this message translates to:
  /// **'Account only'**
  String get folderVisibilityAccountOnly;

  /// No description provided for @folderVisibilityAccountLocked.
  ///
  /// In en, this message translates to:
  /// **'Account only (locked)'**
  String get folderVisibilityAccountLocked;

  /// No description provided for @folderVisibilityHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get folderVisibilityHidden;

  /// No description provided for @discoverBurstsTitle.
  ///
  /// In en, this message translates to:
  /// **'Bursts'**
  String get discoverBurstsTitle;

  /// No description provided for @discoverBurstsMessage.
  ///
  /// In en, this message translates to:
  /// **'Burst detection is not available yet. This screen will group rapid-fire shots.'**
  String get discoverBurstsMessage;

  /// No description provided for @discoverSuggestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart suggestions'**
  String get discoverSuggestionsTitle;

  /// No description provided for @discoverSuggestionsMessage.
  ///
  /// In en, this message translates to:
  /// **'Suggestions will highlight albums and clean-up ideas based on your library.'**
  String get discoverSuggestionsMessage;

  /// No description provided for @discoverLocationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Locations'**
  String get discoverLocationsTitle;

  /// No description provided for @discoverLocationsMessage.
  ///
  /// In en, this message translates to:
  /// **'Browse photos grouped by place on a map or in albums.'**
  String get discoverLocationsMessage;

  /// No description provided for @locationsTabPlaces.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get locationsTabPlaces;

  /// No description provided for @locationsTabMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get locationsTabMap;

  /// No description provided for @locationsIndexing.
  ///
  /// In en, this message translates to:
  /// **'Indexing places {indexed} / {total}...'**
  String locationsIndexing(int indexed, int total);

  /// No description provided for @locationsIndexingPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing location index...'**
  String get locationsIndexingPreparing;

  /// No description provided for @locationsBackfillPreparing.
  ///
  /// In en, this message translates to:
  /// **'Reading GPS from photos...'**
  String get locationsBackfillPreparing;

  /// No description provided for @locationsBackfillProgress.
  ///
  /// In en, this message translates to:
  /// **'Reading GPS {indexed} / {total}...'**
  String locationsBackfillProgress(int indexed, int total);

  /// No description provided for @locationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No geotagged photos'**
  String get locationsEmptyTitle;

  /// No description provided for @locationsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Photos with GPS data from your camera will appear here after the next library sync.'**
  String get locationsEmptyMessage;

  /// No description provided for @locationsPhotoCount.
  ///
  /// In en, this message translates to:
  /// **'{count} photos'**
  String locationsPhotoCount(int count);

  /// No description provided for @locationsCountry.
  ///
  /// In en, this message translates to:
  /// **'Countries'**
  String get locationsCountry;

  /// No description provided for @locationsCity.
  ///
  /// In en, this message translates to:
  /// **'Cities'**
  String get locationsCity;

  /// No description provided for @locationsGeotaggedBadge.
  ///
  /// In en, this message translates to:
  /// **'{count} geotagged'**
  String locationsGeotaggedBadge(int count);

  /// No description provided for @locationsErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load places'**
  String get locationsErrorTitle;

  /// No description provided for @locationsErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while resolving photo locations. Try again later.'**
  String get locationsErrorMessage;

  /// No description provided for @homeErrorLoadFeed.
  ///
  /// In en, this message translates to:
  /// **'Could not load feed'**
  String get homeErrorLoadFeed;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add folders to Home Feed in Manage Content.'**
  String get homeEmptyMessage;

  /// No description provided for @snackbarCameraCaptureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Camera capture coming soon'**
  String get snackbarCameraCaptureComingSoon;

  /// No description provided for @tooltipSearchGallery.
  ///
  /// In en, this message translates to:
  /// **'Search photos and videos'**
  String get tooltipSearchGallery;

  /// No description provided for @galleryErrorLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load gallery'**
  String get galleryErrorLoad;

  /// No description provided for @galleryEmptySearchTitle.
  ///
  /// In en, this message translates to:
  /// **'No media found'**
  String get galleryEmptySearchTitle;

  /// No description provided for @galleryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No media yet'**
  String get galleryEmptyTitle;

  /// No description provided for @galleryEmptySearchMessage.
  ///
  /// In en, this message translates to:
  /// **'Try another photo name, album, or folder path.'**
  String get galleryEmptySearchMessage;

  /// No description provided for @galleryEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Sync your library to see photos and videos here.'**
  String get galleryEmptyMessage;

  /// No description provided for @tooltipSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get tooltipSearch;

  /// No description provided for @exploreErrorLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load library'**
  String get exploreErrorLoad;

  /// No description provided for @exploreEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No media found'**
  String get exploreEmptyTitle;

  /// No description provided for @exploreEmptyMessageNoSearch.
  ///
  /// In en, this message translates to:
  /// **'Try a different search or add folders to Home Feed.'**
  String get exploreEmptyMessageNoSearch;

  /// No description provided for @exploreEmptyMessageSearch.
  ///
  /// In en, this message translates to:
  /// **'Try another photo name, album, or folder path.'**
  String get exploreEmptyMessageSearch;

  /// No description provided for @searchAlbumsAndFolders.
  ///
  /// In en, this message translates to:
  /// **'Albums and folders'**
  String get searchAlbumsAndFolders;

  /// No description provided for @searchNoMatchingAlbums.
  ///
  /// In en, this message translates to:
  /// **'No matching albums. Try a photo or folder name.'**
  String get searchNoMatchingAlbums;

  /// No description provided for @searchRecentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get searchRecentSearches;

  /// No description provided for @searchClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get searchClearAll;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search photos, videos, or albums'**
  String get searchHint;

  /// No description provided for @tooltipClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get tooltipClear;

  /// No description provided for @tooltipClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get tooltipClearSearch;

  /// No description provided for @tooltipLockedAlbums.
  ///
  /// In en, this message translates to:
  /// **'Locked albums'**
  String get tooltipLockedAlbums;

  /// No description provided for @albumsErrorLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load albums'**
  String get albumsErrorLoad;

  /// No description provided for @albumsTitle.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get albumsTitle;

  /// No description provided for @albumsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No albums yet'**
  String get albumsEmptyTitle;

  /// No description provided for @albumsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Sync your library to see albums from your device.'**
  String get albumsEmptyMessage;

  /// No description provided for @lockedAlbumsTitle.
  ///
  /// In en, this message translates to:
  /// **'Locked albums'**
  String get lockedAlbumsTitle;

  /// No description provided for @lockedAlbumsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No locked albums'**
  String get lockedAlbumsEmptyTitle;

  /// No description provided for @lockedAlbumsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Albums protected with biometrics will appear here.'**
  String get lockedAlbumsEmptyMessage;

  /// No description provided for @favoritesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get favoritesEmptyTitle;

  /// No description provided for @favoritesEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Double-tap a post on Home to favorite it.'**
  String get favoritesEmptyMessage;

  /// No description provided for @storageAllFilesAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'All files access'**
  String get storageAllFilesAccessTitle;

  /// No description provided for @storageAllFilesAccessGranted.
  ///
  /// In en, this message translates to:
  /// **'Granted. You can move and delete items across albums.'**
  String get storageAllFilesAccessGranted;

  /// No description provided for @storageAllFilesAccessRequired.
  ///
  /// In en, this message translates to:
  /// **'Required on Android 11+ to move or delete items between albums.'**
  String get storageAllFilesAccessRequired;

  /// No description provided for @storageGrantInSettings.
  ///
  /// In en, this message translates to:
  /// **'Grant in settings'**
  String get storageGrantInSettings;

  /// No description provided for @storageAllFilesAccessDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Deleting or moving items between albums on Android 11+ requires \"All files access\" in system settings.'**
  String get storageAllFilesAccessDialogMessage;

  /// No description provided for @profileSelectFolder.
  ///
  /// In en, this message translates to:
  /// **'Select folder'**
  String get profileSelectFolder;

  /// No description provided for @tooltipFileAccess.
  ///
  /// In en, this message translates to:
  /// **'File access'**
  String get tooltipFileAccess;

  /// No description provided for @tooltipManageContent.
  ///
  /// In en, this message translates to:
  /// **'Manage content'**
  String get tooltipManageContent;

  /// No description provided for @tooltipSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tooltipSettings;

  /// No description provided for @profileNoFolderSelected.
  ///
  /// In en, this message translates to:
  /// **'No folder selected'**
  String get profileNoFolderSelected;

  /// No description provided for @profileNoFolderSelectedMessage.
  ///
  /// In en, this message translates to:
  /// **'Sync your library or pick a folder.'**
  String get profileNoFolderSelectedMessage;

  /// No description provided for @profileNoMediaInFolder.
  ///
  /// In en, this message translates to:
  /// **'No media in this folder'**
  String get profileNoMediaInFolder;

  /// No description provided for @profileErrorLoadFolder.
  ///
  /// In en, this message translates to:
  /// **'Could not load folder'**
  String get profileErrorLoadFolder;

  /// No description provided for @profileErrorLoadFolders.
  ///
  /// In en, this message translates to:
  /// **'Could not load folders'**
  String get profileErrorLoadFolders;

  /// No description provided for @selectionCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectionCount(int count);

  /// No description provided for @folderManagementNoFolders.
  ///
  /// In en, this message translates to:
  /// **'No folders found.'**
  String get folderManagementNoFolders;

  /// No description provided for @folderShowInStories.
  ///
  /// In en, this message translates to:
  /// **'Show in Stories'**
  String get folderShowInStories;

  /// No description provided for @folderSecureLock.
  ///
  /// In en, this message translates to:
  /// **'Secure Lock'**
  String get folderSecureLock;

  /// No description provided for @folderChangeCover.
  ///
  /// In en, this message translates to:
  /// **'Change cover'**
  String get folderChangeCover;

  /// No description provided for @folderUseLatestPhoto.
  ///
  /// In en, this message translates to:
  /// **'Use latest photo'**
  String get folderUseLatestPhoto;

  /// No description provided for @folderVisibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Folder visibility'**
  String get folderVisibilityTitle;

  /// No description provided for @folderBiographyTitle.
  ///
  /// In en, this message translates to:
  /// **'Biography'**
  String get folderBiographyTitle;

  /// No description provided for @folderAddBiography.
  ///
  /// In en, this message translates to:
  /// **'Add biography'**
  String get folderAddBiography;

  /// No description provided for @folderNoMedia.
  ///
  /// In en, this message translates to:
  /// **'No media'**
  String get folderNoMedia;

  /// No description provided for @tooltipAlbumOptions.
  ///
  /// In en, this message translates to:
  /// **'Album options'**
  String get tooltipAlbumOptions;

  /// No description provided for @folderPickerDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Move items to...'**
  String get folderPickerDefaultTitle;

  /// No description provided for @folderPickerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search folders'**
  String get folderPickerSearchHint;

  /// No description provided for @albumChooseCoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose cover for {folderName}'**
  String albumChooseCoverTitle(String folderName);

  /// No description provided for @albumCoverLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load album photos: {error}'**
  String albumCoverLoadError(String error);

  /// No description provided for @albumCoverNoPhotos.
  ///
  /// In en, this message translates to:
  /// **'This album has no photos to use as a cover.'**
  String get albumCoverNoPhotos;

  /// No description provided for @folderLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'This folder is locked'**
  String get folderLockedTitle;

  /// No description provided for @folderLockedMessage.
  ///
  /// In en, this message translates to:
  /// **'Use biometrics to view {folderName}.'**
  String folderLockedMessage(String folderName);

  /// No description provided for @folderUnlockReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock {folderName}'**
  String folderUnlockReason(String folderName);

  /// No description provided for @folderBiometricsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Biometrics are not available. Enroll fingerprint or face unlock in device settings.'**
  String get folderBiometricsUnavailable;

  /// No description provided for @folderAuthFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed or was cancelled.'**
  String get folderAuthFailed;

  /// No description provided for @postMoveToTrash.
  ///
  /// In en, this message translates to:
  /// **'Move to trash'**
  String get postMoveToTrash;

  /// No description provided for @postMoveToTrashMessage.
  ///
  /// In en, this message translates to:
  /// **'This item will be moved to trash and can be restored from Settings.'**
  String get postMoveToTrashMessage;

  /// No description provided for @tooltipDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get tooltipDetails;

  /// No description provided for @tooltipShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get tooltipShare;

  /// No description provided for @tooltipFavorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get tooltipFavorite;

  /// No description provided for @postOpenFolder.
  ///
  /// In en, this message translates to:
  /// **'Open folder'**
  String get postOpenFolder;

  /// No description provided for @metadataTitle.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get metadataTitle;

  /// No description provided for @metadataFilename.
  ///
  /// In en, this message translates to:
  /// **'Filename'**
  String get metadataFilename;

  /// No description provided for @metadataDimensions.
  ///
  /// In en, this message translates to:
  /// **'Dimensions'**
  String get metadataDimensions;

  /// No description provided for @metadataType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get metadataType;

  /// No description provided for @metadataSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get metadataSize;

  /// No description provided for @metadataDateTaken.
  ///
  /// In en, this message translates to:
  /// **'Date taken'**
  String get metadataDateTaken;

  /// No description provided for @metadataDateAdded.
  ///
  /// In en, this message translates to:
  /// **'Date added'**
  String get metadataDateAdded;

  /// No description provided for @metadataFolder.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get metadataFolder;

  /// No description provided for @metadataDimensionsValue.
  ///
  /// In en, this message translates to:
  /// **'{width} x {height}'**
  String metadataDimensionsValue(int width, int height);

  /// No description provided for @mediaKindVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get mediaKindVideo;

  /// No description provided for @mediaKindAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get mediaKindAudio;

  /// No description provided for @mediaKindImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get mediaKindImage;

  /// No description provided for @mediaKindFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get mediaKindFile;

  /// No description provided for @organizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Organize'**
  String get organizeTitle;

  /// No description provided for @organizeProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} / {size}'**
  String organizeProgress(int done, int size);

  /// No description provided for @organizeSharingItem.
  ///
  /// In en, this message translates to:
  /// **'Sharing {name}'**
  String organizeSharingItem(String name);

  /// No description provided for @organizeBatchComplete.
  ///
  /// In en, this message translates to:
  /// **'Batch complete'**
  String get organizeBatchComplete;

  /// No description provided for @organizeAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up'**
  String get organizeAllCaughtUp;

  /// No description provided for @organizeRemainingItems.
  ///
  /// In en, this message translates to:
  /// **'{count} items still match your filters.'**
  String organizeRemainingItems(int count);

  /// No description provided for @organizeNoMoreItems.
  ///
  /// In en, this message translates to:
  /// **'No more items match the current filters.'**
  String get organizeNoMoreItems;

  /// No description provided for @organizeLoadNextBatch.
  ///
  /// In en, this message translates to:
  /// **'Load next batch'**
  String get organizeLoadNextBatch;

  /// No description provided for @organizeReviewTrash.
  ///
  /// In en, this message translates to:
  /// **'Review trash ({count})'**
  String organizeReviewTrash(int count);

  /// No description provided for @organizeChangeFilter.
  ///
  /// In en, this message translates to:
  /// **'Change filter'**
  String get organizeChangeFilter;

  /// No description provided for @organizeReleaseKeptPhotos.
  ///
  /// In en, this message translates to:
  /// **'Release kept photos'**
  String get organizeReleaseKeptPhotos;

  /// No description provided for @organizeFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get organizeFiltersTitle;

  /// No description provided for @organizeMediaType.
  ///
  /// In en, this message translates to:
  /// **'Media type'**
  String get organizeMediaType;

  /// No description provided for @organizeMediaAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get organizeMediaAll;

  /// No description provided for @organizeMediaImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get organizeMediaImage;

  /// No description provided for @organizeMediaVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get organizeMediaVideo;

  /// No description provided for @organizeFilterFolder.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get organizeFilterFolder;

  /// No description provided for @organizeAllFolders.
  ///
  /// In en, this message translates to:
  /// **'All folders'**
  String get organizeAllFolders;

  /// No description provided for @organizeFilterMonth.
  ///
  /// In en, this message translates to:
  /// **'Month (YYYY-MM)'**
  String get organizeFilterMonth;

  /// No description provided for @organizeStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Organize stats'**
  String get organizeStatsTitle;

  /// No description provided for @organizeStatProcessed.
  ///
  /// In en, this message translates to:
  /// **'Processed'**
  String get organizeStatProcessed;

  /// No description provided for @organizeStatDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get organizeStatDeleted;

  /// No description provided for @organizeStatLiked.
  ///
  /// In en, this message translates to:
  /// **'Liked'**
  String get organizeStatLiked;

  /// No description provided for @organizeStatSpaceSaved.
  ///
  /// In en, this message translates to:
  /// **'Space saved'**
  String get organizeStatSpaceSaved;

  /// No description provided for @organizeTrashReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review trash ({count})'**
  String organizeTrashReviewTitle(int count);

  /// No description provided for @organizeTrashReviewMessage.
  ///
  /// In en, this message translates to:
  /// **'Selected items will be permanently deleted from your device.'**
  String get organizeTrashReviewMessage;

  /// No description provided for @organizeTrashDeleteCount.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} items'**
  String organizeTrashDeleteCount(int count);

  /// No description provided for @bulkMoveToTrashTitle.
  ///
  /// In en, this message translates to:
  /// **'Move to trash'**
  String get bulkMoveToTrashTitle;

  /// No description provided for @bulkMoveToTrashMessage.
  ///
  /// In en, this message translates to:
  /// **'Move {count} items to trash? You can restore them from Settings.'**
  String bulkMoveToTrashMessage(int count);

  /// No description provided for @snackbarMovedToTrash.
  ///
  /// In en, this message translates to:
  /// **'Moved {count, plural, =1{1 item} other{{count} items}} to trash'**
  String snackbarMovedToTrash(int count);

  /// No description provided for @snackbarMovedItems.
  ///
  /// In en, this message translates to:
  /// **'Moved {moved, plural, =1{1 item} other{{moved} items}}'**
  String snackbarMovedItems(int moved);

  /// No description provided for @snackbarMoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not move items. Approve the system prompt if shown, or check storage access in Settings.'**
  String get snackbarMoveFailed;

  /// No description provided for @snackbarMovedPartial.
  ///
  /// In en, this message translates to:
  /// **'Moved {moved} of {total} items'**
  String snackbarMovedPartial(int moved, int total);

  /// No description provided for @bulkCreateAlbumTitle.
  ///
  /// In en, this message translates to:
  /// **'Create album'**
  String get bulkCreateAlbumTitle;

  /// No description provided for @bulkAlbumNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Album name'**
  String get bulkAlbumNameLabel;

  /// No description provided for @bulkCreateAndMove.
  ///
  /// In en, this message translates to:
  /// **'Create and move'**
  String get bulkCreateAndMove;

  /// No description provided for @snackbarAlbumCreatedAndMoved.
  ///
  /// In en, this message translates to:
  /// **'Created \"{albumName}\" and moved {count, plural, =1{1 item} other{{count} items}}'**
  String snackbarAlbumCreatedAndMoved(String albumName, int count);

  /// No description provided for @snackbarAlbumCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create album. Check storage access.'**
  String get snackbarAlbumCreateFailed;

  /// No description provided for @tooltipCancelSelection.
  ///
  /// In en, this message translates to:
  /// **'Cancel selection'**
  String get tooltipCancelSelection;

  /// No description provided for @tooltipFavoriteSelected.
  ///
  /// In en, this message translates to:
  /// **'Favorite selected'**
  String get tooltipFavoriteSelected;

  /// No description provided for @tooltipUnfavoriteSelected.
  ///
  /// In en, this message translates to:
  /// **'Unfavorite selected'**
  String get tooltipUnfavoriteSelected;

  /// No description provided for @tooltipMoveSelected.
  ///
  /// In en, this message translates to:
  /// **'Move selected'**
  String get tooltipMoveSelected;

  /// No description provided for @tooltipCreateAlbumAndMove.
  ///
  /// In en, this message translates to:
  /// **'Create album and move'**
  String get tooltipCreateAlbumAndMove;

  /// No description provided for @tooltipSetAlbumCover.
  ///
  /// In en, this message translates to:
  /// **'Set as album cover'**
  String get tooltipSetAlbumCover;

  /// No description provided for @tooltipMoveToTrash.
  ///
  /// In en, this message translates to:
  /// **'Move to trash'**
  String get tooltipMoveToTrash;

  /// No description provided for @trashDeletePermanentlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get trashDeletePermanentlyTitle;

  /// No description provided for @trashDeletePermanentlyMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete these {count} items from your device? This action cannot be undone.'**
  String trashDeletePermanentlyMessage(int count);

  /// No description provided for @trashDeletePermanentlyAction.
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get trashDeletePermanentlyAction;

  /// No description provided for @snackbarRestoredItems.
  ///
  /// In en, this message translates to:
  /// **'Restored {count, plural, =1{1 item} other{{count} items}}'**
  String snackbarRestoredItems(int count);

  /// No description provided for @snackbarPermanentlyDeleted.
  ///
  /// In en, this message translates to:
  /// **'Permanently deleted {count, plural, =1{1 item} other{{count} items}}'**
  String snackbarPermanentlyDeleted(int count);

  /// No description provided for @tooltipRestoreSelected.
  ///
  /// In en, this message translates to:
  /// **'Restore selected'**
  String get tooltipRestoreSelected;

  /// No description provided for @tooltipDeletePermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get tooltipDeletePermanently;

  /// No description provided for @trashEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Trash is empty'**
  String get trashEmptyTitle;

  /// No description provided for @trashEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Deleted files will stay here for recovery until they expire.'**
  String get trashEmptyMessage;

  /// No description provided for @trashExpiresToday.
  ///
  /// In en, this message translates to:
  /// **'Expires today'**
  String get trashExpiresToday;

  /// No description provided for @trashDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days} days left'**
  String trashDaysLeft(int days);

  /// No description provided for @discoverSectionOrganize.
  ///
  /// In en, this message translates to:
  /// **'Organize'**
  String get discoverSectionOrganize;

  /// No description provided for @discoverSectionDeepOrganize.
  ///
  /// In en, this message translates to:
  /// **'Deep organize'**
  String get discoverSectionDeepOrganize;

  /// No description provided for @discoverSectionInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get discoverSectionInsights;

  /// No description provided for @discoverSectionCleanup.
  ///
  /// In en, this message translates to:
  /// **'Cleanup'**
  String get discoverSectionCleanup;

  /// No description provided for @discoverSectionExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get discoverSectionExplore;

  /// No description provided for @discoverErrorLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load discover'**
  String get discoverErrorLoad;

  /// No description provided for @discoverDeepOrganize.
  ///
  /// In en, this message translates to:
  /// **'Deep organize'**
  String get discoverDeepOrganize;

  /// No description provided for @discoverDeepOrganizeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan, similar photos, low quality, compression'**
  String get discoverDeepOrganizeSubtitle;

  /// No description provided for @discoverShootingStats.
  ///
  /// In en, this message translates to:
  /// **'Shooting stats'**
  String get discoverShootingStats;

  /// No description provided for @discoverShootingStatsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} items organized so far'**
  String discoverShootingStatsSubtitle(int count);

  /// No description provided for @discoverLikesReview.
  ///
  /// In en, this message translates to:
  /// **'Likes review'**
  String get discoverLikesReview;

  /// No description provided for @discoverLikesReviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} favorites'**
  String discoverLikesReviewSubtitle(int count);

  /// No description provided for @discoverDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Duplicates'**
  String get discoverDuplicates;

  /// No description provided for @discoverDuplicatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find near-identical photos'**
  String get discoverDuplicatesSubtitle;

  /// No description provided for @discoverBurstsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Rapid-fire photo groups'**
  String get discoverBurstsSubtitle;

  /// No description provided for @discoverSuggestionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Album and cleanup ideas'**
  String get discoverSuggestionsSubtitle;

  /// No description provided for @discoverLocationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Photos grouped by place'**
  String get discoverLocationsSubtitle;

  /// No description provided for @deepOrganizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Deep organize'**
  String get deepOrganizeTitle;

  /// No description provided for @deepOrganizeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan your library on device to find similar and low-quality photos.'**
  String get deepOrganizeSubtitle;

  /// No description provided for @deepOrganizeScanProgress.
  ///
  /// In en, this message translates to:
  /// **'Scanning {scanned} / {total}'**
  String deepOrganizeScanProgress(int scanned, int total);

  /// No description provided for @deepOrganizeScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning...'**
  String get deepOrganizeScanning;

  /// No description provided for @deepOrganizeStartScan.
  ///
  /// In en, this message translates to:
  /// **'Start scan'**
  String get deepOrganizeStartScan;

  /// No description provided for @deepOrganizeToolsHeader.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get deepOrganizeToolsHeader;

  /// No description provided for @deepOrganizeCompressionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shrink large images on device'**
  String get deepOrganizeCompressionSubtitle;

  /// No description provided for @deepOrganizeSimilarPhotos.
  ///
  /// In en, this message translates to:
  /// **'Similar photos'**
  String get deepOrganizeSimilarPhotos;

  /// No description provided for @deepOrganizeSimilarGroupsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} groups'**
  String deepOrganizeSimilarGroupsCount(int count);

  /// No description provided for @deepOrganizeLowQuality.
  ///
  /// In en, this message translates to:
  /// **'Low quality'**
  String get deepOrganizeLowQuality;

  /// No description provided for @deepOrganizeLowQualityCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items flagged'**
  String deepOrganizeLowQualityCount(int count);

  /// No description provided for @deepOrganizeCompression.
  ///
  /// In en, this message translates to:
  /// **'Compression'**
  String get deepOrganizeCompression;

  /// No description provided for @deepOrganizeRunScanFirst.
  ///
  /// In en, this message translates to:
  /// **'Run a scan from Deep organize first.'**
  String get deepOrganizeRunScanFirst;

  /// No description provided for @similarPhotosEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No similar groups found'**
  String get similarPhotosEmptyTitle;

  /// No description provided for @similarPhotosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick the best shot and remove near-duplicates.'**
  String get similarPhotosSubtitle;

  /// No description provided for @similarPhotosGroupCount.
  ///
  /// In en, this message translates to:
  /// **'{count} similar items'**
  String similarPhotosGroupCount(int count);

  /// No description provided for @similarPhotosKeepBestDeleteOthers.
  ///
  /// In en, this message translates to:
  /// **'Keep best, delete others'**
  String get similarPhotosKeepBestDeleteOthers;

  /// No description provided for @similarPhotosDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete similar photos'**
  String get similarPhotosDeleteTitle;

  /// No description provided for @similarPhotosDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Keep \"{name}\" and delete {count} similar items?'**
  String similarPhotosDeleteMessage(String name, int count);

  /// No description provided for @lowQualityReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Low quality review'**
  String get lowQualityReviewTitle;

  /// No description provided for @lowQualityReviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review flagged shots and delete what you do not need.'**
  String get lowQualityReviewSubtitle;

  /// No description provided for @lowQualityEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No low-quality items'**
  String get lowQualityEmptyTitle;

  /// No description provided for @lowQualityProgress.
  ///
  /// In en, this message translates to:
  /// **'{index} / {total}'**
  String lowQualityProgress(int index, int total);

  /// No description provided for @compressionTitle.
  ///
  /// In en, this message translates to:
  /// **'Image compression'**
  String get compressionTitle;

  /// No description provided for @compressionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Compress large photos without leaving the device.'**
  String get compressionSubtitle;

  /// No description provided for @compressionBestOnMobile.
  ///
  /// In en, this message translates to:
  /// **'Best on mobile'**
  String get compressionBestOnMobile;

  /// No description provided for @compressionBestOnMobileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Compression works on Android and iOS. Desktop support is limited.'**
  String get compressionBestOnMobileSubtitle;

  /// No description provided for @compressionResult.
  ///
  /// In en, this message translates to:
  /// **'Compressed {done} images, saved {mb} MB'**
  String compressionResult(int done, int mb);

  /// No description provided for @compressionCandidatesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} images over 3 MB'**
  String compressionCandidatesCount(int count);

  /// No description provided for @compressionCompressing.
  ///
  /// In en, this message translates to:
  /// **'Compressing...'**
  String get compressionCompressing;

  /// No description provided for @compressionCompressSelected.
  ///
  /// In en, this message translates to:
  /// **'Compress {count} selected'**
  String compressionCompressSelected(int count);

  /// No description provided for @likesReviewEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Swipe right in Organize to favorite photos.'**
  String get likesReviewEmptySubtitle;

  /// No description provided for @likesReviewEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No liked items yet'**
  String get likesReviewEmptyTitle;

  /// No description provided for @likesReviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scroll through your favorites.'**
  String get likesReviewSubtitle;

  /// No description provided for @likesReviewSharing.
  ///
  /// In en, this message translates to:
  /// **'Sharing {name}'**
  String likesReviewSharing(String name);

  /// No description provided for @shootingStatsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your on-device photography habits.'**
  String get shootingStatsSubtitle;

  /// No description provided for @shootingStatsPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get shootingStatsPhotos;

  /// No description provided for @shootingStatsVideos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get shootingStatsVideos;

  /// No description provided for @shootingStatsScreenshots.
  ///
  /// In en, this message translates to:
  /// **'Screenshots'**
  String get shootingStatsScreenshots;

  /// No description provided for @shootingStatsLiked.
  ///
  /// In en, this message translates to:
  /// **'Liked'**
  String get shootingStatsLiked;

  /// No description provided for @shootingStatsFolders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get shootingStatsFolders;

  /// No description provided for @shootingStatsVideoDuration.
  ///
  /// In en, this message translates to:
  /// **'Video duration'**
  String get shootingStatsVideoDuration;

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String durationMinutes(int minutes);

  /// No description provided for @durationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String durationHoursMinutes(int hours, int minutes);

  /// No description provided for @shootingStatsMostActiveDay.
  ///
  /// In en, this message translates to:
  /// **'Most active day'**
  String get shootingStatsMostActiveDay;

  /// No description provided for @shootingStatsMostActiveDayValue.
  ///
  /// In en, this message translates to:
  /// **'{date} ({count})'**
  String shootingStatsMostActiveDayValue(String date, int count);

  /// No description provided for @shootingStatsHeatmap.
  ///
  /// In en, this message translates to:
  /// **'Activity heatmap'**
  String get shootingStatsHeatmap;

  /// No description provided for @shootingStatsNoActivity.
  ///
  /// In en, this message translates to:
  /// **'No activity this month.'**
  String get shootingStatsNoActivity;

  /// No description provided for @shootingStatsHeatmapTooltip.
  ///
  /// In en, this message translates to:
  /// **'{date}: {count}'**
  String shootingStatsHeatmapTooltip(String date, int count);

  /// No description provided for @duplicateScanProgress.
  ///
  /// In en, this message translates to:
  /// **'Analyzing {scanned} / {total} photos...'**
  String duplicateScanProgress(int scanned, int total);

  /// No description provided for @duplicateScanPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing duplicate scan...'**
  String get duplicateScanPreparing;

  /// No description provided for @duplicatesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No duplicate groups found'**
  String get duplicatesEmptyTitle;

  /// No description provided for @duplicatesEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No near-identical photos found. Duplicates are matched by visual similarity, not just file size.'**
  String get duplicatesEmptyMessage;

  /// No description provided for @duplicatesGroupBadge.
  ///
  /// In en, this message translates to:
  /// **'{count} duplicates'**
  String duplicatesGroupBadge(int count);

  /// No description provided for @duplicatesKeepBestAndReview.
  ///
  /// In en, this message translates to:
  /// **'Keep best and review'**
  String get duplicatesKeepBestAndReview;

  /// No description provided for @duplicateReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review duplicates'**
  String get duplicateReviewTitle;

  /// No description provided for @duplicateReviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep best is pre-selected. Tap items to change what will be removed.'**
  String get duplicateReviewSubtitle;

  /// No description provided for @duplicateReviewGroupNotFound.
  ///
  /// In en, this message translates to:
  /// **'Group not found'**
  String get duplicateReviewGroupNotFound;

  /// No description provided for @duplicateReviewDeleteCount.
  ///
  /// In en, this message translates to:
  /// **'Delete ({count})'**
  String duplicateReviewDeleteCount(int count);

  /// No description provided for @snackbarDuplicatesRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed {count, plural, =1{1 duplicate} other{{count} duplicates}}.'**
  String snackbarDuplicatesRemoved(int count);

  /// No description provided for @snackbarDuplicatesRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not remove some items. Check permissions.'**
  String get snackbarDuplicatesRemoveFailed;

  /// No description provided for @travelModeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No trips yet'**
  String get travelModeEmptyTitle;

  /// No description provided for @travelModeEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Create a travel mode to auto-organize photos from a date range.'**
  String get travelModeEmptyMessage;

  /// No description provided for @travelModeStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get travelModeStatusActive;

  /// No description provided for @travelModeStatusUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get travelModeStatusUpcoming;

  /// No description provided for @travelModeStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get travelModeStatusCompleted;

  /// No description provided for @travelModeListSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{start} - {end}nFolder: {folder}'**
  String travelModeListSubtitle(String start, String end, String folder);

  /// No description provided for @travelModeErrorLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load travel modes'**
  String get travelModeErrorLoad;

  /// No description provided for @travelModeTripName.
  ///
  /// In en, this message translates to:
  /// **'Trip name'**
  String get travelModeTripName;

  /// No description provided for @travelModeTargetFolder.
  ///
  /// In en, this message translates to:
  /// **'Target folder name'**
  String get travelModeTargetFolder;

  /// No description provided for @travelModeTargetFolderHelper.
  ///
  /// In en, this message translates to:
  /// **'Album name for auto-moved media (no vault)'**
  String get travelModeTargetFolderHelper;

  /// No description provided for @travelModeStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get travelModeStart;

  /// No description provided for @travelModeEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get travelModeEnd;

  /// No description provided for @travelModeDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get travelModeDate;

  /// No description provided for @travelModeTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get travelModeTime;

  /// No description provided for @travelModeSpecificTime.
  ///
  /// In en, this message translates to:
  /// **'Specific time'**
  String get travelModeSpecificTime;

  /// No description provided for @snackbarTravelModeRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Name, folder, and dates are required'**
  String get snackbarTravelModeRequiredFields;

  /// No description provided for @travelModeDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete travel mode'**
  String get travelModeDeleteTitle;

  /// No description provided for @travelModeDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get travelModeDeleteMessage;

  /// No description provided for @storyNoStoriesFound.
  ///
  /// In en, this message translates to:
  /// **'No recent stories found in this folder.'**
  String get storyNoStoriesFound;

  /// No description provided for @backupSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Desktop backup'**
  String get backupSectionTitle;

  /// No description provided for @backupReceiveBackups.
  ///
  /// In en, this message translates to:
  /// **'Receive backups'**
  String get backupReceiveBackups;

  /// No description provided for @backupReceiveBackupsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allow this computer to receive photos from your phone'**
  String get backupReceiveBackupsSubtitle;

  /// No description provided for @backupIndexingBackups.
  ///
  /// In en, this message translates to:
  /// **'Indexing backups'**
  String get backupIndexingBackups;

  /// No description provided for @backupShowPairingCode.
  ///
  /// In en, this message translates to:
  /// **'Show pairing code'**
  String get backupShowPairingCode;

  /// No description provided for @backupStartReceivingToShowCode.
  ///
  /// In en, this message translates to:
  /// **'Start receiving to show code'**
  String get backupStartReceivingToShowCode;

  /// No description provided for @backupPairedDevice.
  ///
  /// In en, this message translates to:
  /// **'Paired device'**
  String get backupPairedDevice;

  /// No description provided for @backupUnpairDevice.
  ///
  /// In en, this message translates to:
  /// **'Unpair device'**
  String get backupUnpairDevice;

  /// No description provided for @backupUnpairDeviceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stop accepting backups from this phone'**
  String get backupUnpairDeviceSubtitle;

  /// No description provided for @backupRefreshLibrary.
  ///
  /// In en, this message translates to:
  /// **'Refresh library'**
  String get backupRefreshLibrary;

  /// No description provided for @backupRefreshLibrarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Rescan folders after new backups arrive'**
  String get backupRefreshLibrarySubtitle;

  /// No description provided for @backupBackUpToDesktop.
  ///
  /// In en, this message translates to:
  /// **'Back up to desktop'**
  String get backupBackUpToDesktop;

  /// No description provided for @backupBackUpToDesktopSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatic backup on same Wi-Fi when desktop is running'**
  String get backupBackUpToDesktopSubtitle;

  /// No description provided for @backupPairedDesktop.
  ///
  /// In en, this message translates to:
  /// **'Paired desktop'**
  String get backupPairedDesktop;

  /// No description provided for @backupPairWithDesktop.
  ///
  /// In en, this message translates to:
  /// **'Pair with desktop'**
  String get backupPairWithDesktop;

  /// No description provided for @backupBackUpNow.
  ///
  /// In en, this message translates to:
  /// **'Back up now'**
  String get backupBackUpNow;

  /// No description provided for @backupBackUpNowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only runs when desktop is available'**
  String get backupBackUpNowSubtitle;

  /// No description provided for @backupUnpairDesktop.
  ///
  /// In en, this message translates to:
  /// **'Unpair desktop'**
  String get backupUnpairDesktop;

  /// No description provided for @backupPairSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Pair with desktop'**
  String get backupPairSheetTitle;

  /// No description provided for @backupPairSheetDescription.
  ///
  /// In en, this message translates to:
  /// **'On your computer, enable Receive backups in Settings and enter the PIN shown there.'**
  String get backupPairSheetDescription;

  /// No description provided for @backupDesktopAddress.
  ///
  /// In en, this message translates to:
  /// **'Desktop address'**
  String get backupDesktopAddress;

  /// No description provided for @backupPort.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get backupPort;

  /// No description provided for @backupPinLabel.
  ///
  /// In en, this message translates to:
  /// **'6-digit PIN'**
  String get backupPinLabel;

  /// No description provided for @backupScanPairingQr.
  ///
  /// In en, this message translates to:
  /// **'Scan pairing QR code'**
  String get backupScanPairingQr;

  /// No description provided for @backupFindOnNetwork.
  ///
  /// In en, this message translates to:
  /// **'Find on network'**
  String get backupFindOnNetwork;

  /// No description provided for @backupPair.
  ///
  /// In en, this message translates to:
  /// **'Pair'**
  String get backupPair;

  /// No description provided for @backupErrorNoDesktopFound.
  ///
  /// In en, this message translates to:
  /// **'No desktop found. Enter the address shown on your computer.'**
  String get backupErrorNoDesktopFound;

  /// No description provided for @backupErrorEnterHostPortPin.
  ///
  /// In en, this message translates to:
  /// **'Enter host, port, and 6-digit PIN from desktop.'**
  String get backupErrorEnterHostPortPin;

  /// No description provided for @backupErrorPairingFailed.
  ///
  /// In en, this message translates to:
  /// **'Pairing failed. Check the PIN and try again.'**
  String get backupErrorPairingFailed;

  /// No description provided for @backupErrorInvalidQr.
  ///
  /// In en, this message translates to:
  /// **'QR code is not a valid backup pairing link.'**
  String get backupErrorInvalidQr;

  /// No description provided for @backupPairingSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Pairing successful'**
  String get backupPairingSuccessTitle;

  /// No description provided for @backupPairingSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'{deviceName} is now paired with this computer. Backups will start automatically when both devices are on the same Wi-Fi.'**
  String backupPairingSuccessMessage(String deviceName);

  /// No description provided for @backupPairYourPhoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Pair your phone'**
  String get backupPairYourPhoneTitle;

  /// No description provided for @backupPinDisplay.
  ///
  /// In en, this message translates to:
  /// **'PIN: {pin}'**
  String backupPinDisplay(String pin);

  /// No description provided for @backupQrInstructions.
  ///
  /// In en, this message translates to:
  /// **'Scan with your phone camera or use Scan pairing QR in Settings > Desktop backup.'**
  String get backupQrInstructions;

  /// No description provided for @backupScanPairingQrTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan pairing QR'**
  String get backupScanPairingQrTitle;

  /// No description provided for @backupStatusBackingUp.
  ///
  /// In en, this message translates to:
  /// **'Backing up {processed}/{total}'**
  String backupStatusBackingUp(int processed, int total);

  /// No description provided for @backupStatusOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get backupStatusOff;

  /// No description provided for @backupStatusWaitingForDesktop.
  ///
  /// In en, this message translates to:
  /// **'Waiting for desktop'**
  String get backupStatusWaitingForDesktop;

  /// No description provided for @backupStatusDesktopReady.
  ///
  /// In en, this message translates to:
  /// **'Desktop ready'**
  String get backupStatusDesktopReady;

  /// No description provided for @backupStatusLastBackup.
  ///
  /// In en, this message translates to:
  /// **'Last backup {relativeTime}'**
  String backupStatusLastBackup(String relativeTime);

  /// No description provided for @backupStatusUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get backupStatusUpToDate;

  /// No description provided for @backupStatusError.
  ///
  /// In en, this message translates to:
  /// **'Error - {detail}'**
  String backupStatusError(String detail);

  /// No description provided for @backupStatusIdle.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get backupStatusIdle;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{n}m ago'**
  String timeMinutesAgo(int n);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{n}h ago'**
  String timeHoursAgo(int n);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{n}d ago'**
  String timeDaysAgo(int n);

  /// No description provided for @backupNotificationPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing backup...'**
  String get backupNotificationPreparing;

  /// No description provided for @backupNotificationInProgress.
  ///
  /// In en, this message translates to:
  /// **'Backup in progress'**
  String get backupNotificationInProgress;

  /// No description provided for @backupNotificationProgress.
  ///
  /// In en, this message translates to:
  /// **'Backed up {processed} / {total} items'**
  String backupNotificationProgress(int processed, int total);

  /// No description provided for @backupNotificationComplete.
  ///
  /// In en, this message translates to:
  /// **'Backup complete'**
  String get backupNotificationComplete;

  /// No description provided for @backupNotificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup failed'**
  String get backupNotificationFailed;

  /// No description provided for @backupNotificationPaused.
  ///
  /// In en, this message translates to:
  /// **'Backup paused'**
  String get backupNotificationPaused;

  /// No description provided for @notificationChannelDuplicateScan.
  ///
  /// In en, this message translates to:
  /// **'Duplicate scan'**
  String get notificationChannelDuplicateScan;

  /// No description provided for @notificationChannelDuplicateScanDescription.
  ///
  /// In en, this message translates to:
  /// **'Progress while searching for duplicate photos'**
  String get notificationChannelDuplicateScanDescription;

  /// No description provided for @notificationDuplicateScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scanning for duplicates'**
  String get notificationDuplicateScanTitle;

  /// No description provided for @notificationDuplicateScanPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing duplicate scan...'**
  String get notificationDuplicateScanPreparing;

  /// No description provided for @notificationDuplicateScanProgress.
  ///
  /// In en, this message translates to:
  /// **'Analyzing {scanned} / {total} photos...'**
  String notificationDuplicateScanProgress(int scanned, int total);

  /// No description provided for @notificationDuplicateScanNoneTitle.
  ///
  /// In en, this message translates to:
  /// **'No duplicates found'**
  String get notificationDuplicateScanNoneTitle;

  /// No description provided for @notificationDuplicateScanNoneBody.
  ///
  /// In en, this message translates to:
  /// **'No near-identical photos were found in your library.'**
  String get notificationDuplicateScanNoneBody;

  /// No description provided for @notificationDuplicateScanCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Duplicate scan complete'**
  String get notificationDuplicateScanCompleteTitle;

  /// No description provided for @notificationDuplicateScanCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Found 1 duplicate group} other{Found {count} duplicate groups}}'**
  String notificationDuplicateScanCompleteBody(int count, String Found);

  /// No description provided for @notificationDuplicateScanFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Duplicate scan failed'**
  String get notificationDuplicateScanFailedTitle;

  /// No description provided for @notificationDuplicateScanFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Could not finish scanning. Open Duplicates to try again.'**
  String get notificationDuplicateScanFailedBody;

  /// No description provided for @notificationChannelDesktopBackup.
  ///
  /// In en, this message translates to:
  /// **'Desktop backup'**
  String get notificationChannelDesktopBackup;

  /// No description provided for @notificationChannelDesktopBackupDescription.
  ///
  /// In en, this message translates to:
  /// **'Progress while backing up photos to your computer'**
  String get notificationChannelDesktopBackupDescription;

  /// No description provided for @backupDetailDisabled.
  ///
  /// In en, this message translates to:
  /// **'Backup disabled'**
  String get backupDetailDisabled;

  /// No description provided for @backupDetailNotReceiving.
  ///
  /// In en, this message translates to:
  /// **'Not receiving backups'**
  String get backupDetailNotReceiving;

  /// No description provided for @backupDetailPairedWith.
  ///
  /// In en, this message translates to:
  /// **'Paired with {name}'**
  String backupDetailPairedWith(String name);

  /// No description provided for @backupDetailReadyToReceive.
  ///
  /// In en, this message translates to:
  /// **'Ready to receive backups'**
  String get backupDetailReadyToReceive;

  /// No description provided for @backupDetailIndexingBackups.
  ///
  /// In en, this message translates to:
  /// **'Indexing existing backups...'**
  String get backupDetailIndexingBackups;

  /// No description provided for @backupDetailIndexingBackupsProgress.
  ///
  /// In en, this message translates to:
  /// **'Indexing existing backups ({scanned} files)...'**
  String backupDetailIndexingBackupsProgress(int scanned);

  /// No description provided for @backupDetailSearchingDesktop.
  ///
  /// In en, this message translates to:
  /// **'Searching for desktop...'**
  String get backupDetailSearchingDesktop;

  /// No description provided for @backupDetailFoundDesktop.
  ///
  /// In en, this message translates to:
  /// **'Found {name}'**
  String backupDetailFoundDesktop(String name);

  /// No description provided for @backupDetailNoDesktopFound.
  ///
  /// In en, this message translates to:
  /// **'No desktop found on network'**
  String get backupDetailNoDesktopFound;

  /// No description provided for @backupDetailNotPaired.
  ///
  /// In en, this message translates to:
  /// **'Not paired'**
  String get backupDetailNotPaired;

  /// No description provided for @backupDetailCheckingDesktop.
  ///
  /// In en, this message translates to:
  /// **'Checking desktop availability...'**
  String get backupDetailCheckingDesktop;

  /// No description provided for @backupDetailWaitingForDesktop.
  ///
  /// In en, this message translates to:
  /// **'Waiting for desktop'**
  String get backupDetailWaitingForDesktop;

  /// No description provided for @backupDetailDesktopReady.
  ///
  /// In en, this message translates to:
  /// **'Desktop ready'**
  String get backupDetailDesktopReady;

  /// No description provided for @backupDetailDesktopUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Desktop unavailable'**
  String get backupDetailDesktopUnavailable;

  /// No description provided for @backupDetailReconcilingItems.
  ///
  /// In en, this message translates to:
  /// **'Reconciling {count} items'**
  String backupDetailReconcilingItems(int count);

  /// No description provided for @backupDetailReconciling.
  ///
  /// In en, this message translates to:
  /// **'Reconciling with desktop'**
  String get backupDetailReconciling;

  /// No description provided for @backupDetailBackingUpItems.
  ///
  /// In en, this message translates to:
  /// **'Backing up {count} items'**
  String backupDetailBackingUpItems(int count);

  /// No description provided for @backupDetailCheckingItems.
  ///
  /// In en, this message translates to:
  /// **'Checking for items to back up'**
  String get backupDetailCheckingItems;

  /// No description provided for @backupDetailDesktopDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Desktop became unavailable'**
  String get backupDetailDesktopDisconnected;

  /// No description provided for @backupDetailWaitingForSync.
  ///
  /// In en, this message translates to:
  /// **'Waiting for library sync to finish...'**
  String get backupDetailWaitingForSync;

  /// No description provided for @backupDetailFoundMoreItems.
  ///
  /// In en, this message translates to:
  /// **'Found {count} more items to back up'**
  String backupDetailFoundMoreItems(int count);

  /// No description provided for @backupDetailAllBackedUp.
  ///
  /// In en, this message translates to:
  /// **'All photos are backed up'**
  String get backupDetailAllBackedUp;

  /// No description provided for @backupDetailBackedUpItems.
  ///
  /// In en, this message translates to:
  /// **'Backed up {count} items'**
  String backupDetailBackedUpItems(int count);

  /// No description provided for @backupDetailBackingUpBatch.
  ///
  /// In en, this message translates to:
  /// **'Backing up batch {batch} ({count} items)'**
  String backupDetailBackingUpBatch(int batch, int count);

  /// No description provided for @backupDetailBackingUpFile.
  ///
  /// In en, this message translates to:
  /// **'Backing up {folder}/{name}'**
  String backupDetailBackingUpFile(String folder, String name);

  /// No description provided for @backupDetailBackupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup failed'**
  String get backupDetailBackupFailed;

  /// No description provided for @backupDetailReconcilingProgress.
  ///
  /// In en, this message translates to:
  /// **'Reconciling {count} items...'**
  String backupDetailReconcilingProgress(int count);

  /// No description provided for @backupDetailReconcileFailed.
  ///
  /// In en, this message translates to:
  /// **'Reconcile failed'**
  String get backupDetailReconcileFailed;

  /// No description provided for @backupDetailVerifyingItems.
  ///
  /// In en, this message translates to:
  /// **'Verifying {count} backed-up items...'**
  String backupDetailVerifyingItems(int count);

  /// No description provided for @backupDetailVerifyFailed.
  ///
  /// In en, this message translates to:
  /// **'Verify failed'**
  String get backupDetailVerifyFailed;

  /// No description provided for @backupDetailDesktopDisconnectedDuringReconcile.
  ///
  /// In en, this message translates to:
  /// **'Desktop became unavailable during reconcile'**
  String get backupDetailDesktopDisconnectedDuringReconcile;

  /// No description provided for @backupDetailDesktopDisconnectedDuringVerify.
  ///
  /// In en, this message translates to:
  /// **'Desktop became unavailable during verify'**
  String get backupDetailDesktopDisconnectedDuringVerify;

  /// No description provided for @backupDetailDesktopDisconnectedDuringBackup.
  ///
  /// In en, this message translates to:
  /// **'Desktop disconnected during backup'**
  String get backupDetailDesktopDisconnectedDuringBackup;

  /// No description provided for @backupDetailDesktopDoesNotUpload.
  ///
  /// In en, this message translates to:
  /// **'Desktop app does not upload to itself'**
  String get backupDetailDesktopDoesNotUpload;

  /// No description provided for @backupDetailNotPairedWithDesktop.
  ///
  /// In en, this message translates to:
  /// **'Not paired with a desktop'**
  String get backupDetailNotPairedWithDesktop;

  /// No description provided for @vaultPasswordSetTitle.
  ///
  /// In en, this message translates to:
  /// **'Set vault backup password'**
  String get vaultPasswordSetTitle;

  /// No description provided for @vaultPasswordSetDescription.
  ///
  /// In en, this message translates to:
  /// **'Locked albums are encrypted on your desktop as AES-256 protected archives. Choose a password you will use to browse them later.'**
  String get vaultPasswordSetDescription;

  /// No description provided for @vaultPasswordEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter vault password'**
  String get vaultPasswordEnterTitle;

  /// No description provided for @vaultPasswordEnterDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter your vault password to access encrypted backups on desktop.'**
  String get vaultPasswordEnterDescription;

  /// No description provided for @vaultPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get vaultPasswordLabel;

  /// No description provided for @vaultPasswordConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get vaultPasswordConfirmLabel;

  /// No description provided for @vaultPasswordChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Vault backup password'**
  String get vaultPasswordChangeTitle;

  /// No description provided for @vaultPasswordChangeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Change the password used for encrypted locked-album backups'**
  String get vaultPasswordChangeSubtitle;

  /// No description provided for @backupVaultStorageTitle.
  ///
  /// In en, this message translates to:
  /// **'Encrypted vault storage'**
  String get backupVaultStorageTitle;

  /// No description provided for @backupVaultStorageCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No encrypted files} =1{1 encrypted file} other{{count} encrypted files}}'**
  String backupVaultStorageCount(int count);

  /// No description provided for @desktopArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Home archive'**
  String get desktopArchiveTitle;

  /// No description provided for @desktopArchiveBrowseTitle.
  ///
  /// In en, this message translates to:
  /// **'Browse home archive'**
  String get desktopArchiveBrowseTitle;

  /// No description provided for @desktopArchiveBrowseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View photos and videos stored on your desktop over Wi-Fi'**
  String get desktopArchiveBrowseSubtitle;

  /// No description provided for @desktopArchiveEmpty.
  ///
  /// In en, this message translates to:
  /// **'No archived media found'**
  String get desktopArchiveEmpty;

  /// No description provided for @desktopArchiveLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load desktop archive'**
  String get desktopArchiveLoadFailed;

  /// No description provided for @desktopArchiveStreamFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not stream this file'**
  String get desktopArchiveStreamFailed;

  /// No description provided for @desktopArchiveItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String desktopArchiveItemCount(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
