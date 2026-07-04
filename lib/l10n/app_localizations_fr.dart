// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Social Gallery (beta)';

  @override
  String get actionCancel => 'Annuler';

  @override
  String get actionSave => 'Enregistrer';

  @override
  String get actionDelete => 'Supprimer';

  @override
  String get actionOk => 'OK';

  @override
  String get actionApply => 'Appliquer';

  @override
  String get actionReset => 'Reinitialiser';

  @override
  String get actionKeep => 'Conserver';

  @override
  String get actionUnlock => 'Deverrouiller';

  @override
  String get actionClear => 'Effacer';

  @override
  String get actionOpenSettings => 'Ouvrir les parametres';

  @override
  String get actionGoBack => 'Retour';

  @override
  String get valueNotSet => 'Non defini';

  @override
  String get errorGeneric => 'Erreur';

  @override
  String get errorCouldNotLoad => 'Impossible de charger';

  @override
  String get errorMediaNotFound => 'Media introuvable';

  @override
  String get errorFolderNotFound => 'Dossier introuvable';

  @override
  String get errorCouldNotUseFolder => 'Impossible d\'utiliser ce dossier';

  @override
  String errorFailedToSelectFolder(String error) {
    return 'Echec de la selection du dossier : $error';
  }

  @override
  String errorCouldNotLoadFolders(String error) {
    return 'Impossible de charger les dossiers : $error';
  }

  @override
  String get emptyNothingHere => 'Rien ici';

  @override
  String get navHome => 'Accueil';

  @override
  String get navGallery => 'Galerie';

  @override
  String get navExplore => 'Explorer';

  @override
  String get navAlbums => 'Albums';

  @override
  String get navDiscover => 'Decouvrir';

  @override
  String get navLockedAlbums => 'Albums verrouilles';

  @override
  String get navSettings => 'Parametres';

  @override
  String get settingsTitle => 'Parametres';

  @override
  String get settingsSectionAppearance => 'Apparence';

  @override
  String get settingsSectionGallery => 'Galerie';

  @override
  String get settingsSectionContent => 'Contenu';

  @override
  String get settingsSectionOrganize => 'Organiser';

  @override
  String get settingsSectionStorage => 'Stockage';

  @override
  String get settingsSectionAbout => 'A propos';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageSystem => 'Langue du systeme';

  @override
  String get settingsLanguageEnglish => 'Anglais';

  @override
  String get settingsLanguageFrench => 'Francais';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsAccentColor => 'Couleur d\'accent';

  @override
  String get settingsAccentColorDescription =>
      'Choisissez la couleur utilisee pour les boutons, liens et surlignages.';

  @override
  String get settingsFontSize => 'Taille du texte';

  @override
  String get settingsFontSizeDescription =>
      'Ajustez la taille du texte dans toute l\'application.';

  @override
  String get settingsAnimationSpeed => 'Vitesse des animations';

  @override
  String get settingsAnimationSpeedDescription =>
      'Previsualisez la vitesse des transitions dans l\'application.';

  @override
  String get settingsGalleryRootFolder => 'Dossier racine de la galerie';

  @override
  String get settingsGalleryRootFolderEmptySubtitle =>
      'Choisissez un dossier a analyser pour les photos et videos';

  @override
  String get settingsGalleryGridSize => 'Taille de la grille';

  @override
  String get settingsGalleryViewMode => 'Mode galerie';

  @override
  String get settingsGalleryViewModeSubtitle =>
      'Onglet galerie avec pincement au lieu d\'Accueil et Explorer';

  @override
  String get settingsManageContent => 'Gerer le contenu';

  @override
  String get settingsManageContentSubtitle =>
      'Dossiers, fil d\'accueil et visibilite';

  @override
  String get settingsTravelMode => 'Mode voyage';

  @override
  String get settingsTravelModeSubtitle =>
      'Voyages et organisation par periode';

  @override
  String get settingsBatchSize => 'Taille du lot';

  @override
  String get settingsBatchSizeDescription =>
      'Nombre de photos par session d\'organisation.';

  @override
  String settingsBatchSizeValue(int count) {
    return '$count photos';
  }

  @override
  String get settingsQueueOrder => 'Ordre de la file';

  @override
  String get settingsReleaseKeptPhotos => 'Remettre les photos conservees';

  @override
  String get settingsReleaseKeptPhotosSubtitle =>
      'Remettre les photos traitees dans la file d\'organisation';

  @override
  String get settingsTrashRetention => 'Retention de la corbeille';

  @override
  String get settingsTrashRetentionDescription =>
      'Les elements de la corbeille sont supprimes definitivement apres cette periode.';

  @override
  String settingsTrashRetentionDays(int days) {
    return '$days jours';
  }

  @override
  String get settingsDeletedItems => 'Elements supprimes';

  @override
  String get settingsDeletedItemsSubtitle =>
      'Voir, restaurer ou vider la corbeille';

  @override
  String get settingsCache => 'Cache';

  @override
  String get settingsCacheSizeLimit => 'Limite de taille du cache';

  @override
  String get settingsCacheSizeLimitDescription =>
      'Stockage maximal utilise par les miniatures et fichiers temporaires.';

  @override
  String settingsCacheSizeLimitValue(int limitMb) {
    return '$limitMb Mo';
  }

  @override
  String get settingsAutoClearOnClose => 'Effacer a la fermeture';

  @override
  String get settingsAutoClearOnCloseSubtitle =>
      'Effacer le cache lorsque l\'application est fermee';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsPrivacyPolicy => 'Politique de confidentialite';

  @override
  String get settingsOpenSourceLicenses => 'Licences open source';

  @override
  String get settingsShareApp => 'Partager l\'application';

  @override
  String get settingsShareAppMessage =>
      'Decouvrez Social Gallery - une galerie photo locale.';

  @override
  String get dialogClearCacheTitle => 'Effacer le cache';

  @override
  String dialogClearCacheMessage(int size) {
    return 'Effacer $size de miniatures et fichiers temporaires en cache ?';
  }

  @override
  String get snackbarCacheCleared => 'Cache efface';

  @override
  String get snackbarReleasedKeptPhotos => 'Photos conservees remises en file';

  @override
  String get snackbarGalleryRootUpdated =>
      'Dossier racine mis a jour. Reanalyse de la bibliotheque.';

  @override
  String get dialogSelectRootGalleryFolder =>
      'Selectionner le dossier racine de la galerie';

  @override
  String get debugBuildTitle => 'Version de debug';

  @override
  String get debugBuildMessage =>
      'Ce n\'est pas une version de production et elle peut contenir des erreurs.';

  @override
  String get themeSystemDefault => 'Systeme';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeSolar => 'Solaire';

  @override
  String get themeDark => 'Sombre';

  @override
  String get themeDarkOled => 'Sombre OLED';

  @override
  String get accentBlue => 'Bleu';

  @override
  String get accentPurple => 'Violet';

  @override
  String get accentGreen => 'Vert';

  @override
  String get accentOrange => 'Orange';

  @override
  String get accentRed => 'Rouge';

  @override
  String get accentPink => 'Rose';

  @override
  String get accentTeal => 'Sarcelle';

  @override
  String get gridSizeCompact => 'Compact';

  @override
  String get gridSizeStandard => 'Standard';

  @override
  String get gridSizeLarge => 'Grand';

  @override
  String get gridSizeCompactSubtitle =>
      'Miniatures plus petites, plus de colonnes';

  @override
  String get gridSizeStandardSubtitle => 'Disposition equilibree';

  @override
  String get gridSizeLargeSubtitle =>
      'Miniatures plus grandes, moins de colonnes';

  @override
  String get fontSizeSmall => 'Petit';

  @override
  String get fontSizeNormal => 'Normal';

  @override
  String get fontSizeLarge => 'Grand';

  @override
  String get fontSizeExtraLarge => 'Tres grand';

  @override
  String get animationSpeedInstant => 'Instantane';

  @override
  String get animationSpeedFast => 'Rapide';

  @override
  String get animationSpeedNormal => 'Normal';

  @override
  String get animationSpeedSlow => 'Lent';

  @override
  String get queueOrderRandom => 'Aleatoire';

  @override
  String get queueOrderChronological => 'Chronologique';

  @override
  String get onboardingNext => 'Suivant';

  @override
  String get onboardingSkip => 'Passer';

  @override
  String get onboardingGetStarted => 'Commencer';

  @override
  String get onboardingWelcomeTitle => 'Bienvenue dans Social Gallery';

  @override
  String get onboardingWelcomeBody =>
      'Vos photos restent sur votre appareil. Configurez quelques preferences et nous indexerons votre bibliotheque en arriere-plan.';

  @override
  String get onboardingPermissionsHeader => 'Autorisations';

  @override
  String get onboardingPermissionsSubtitle =>
      'Autorisez l\'acces pour analyser vos albums.';

  @override
  String get onboardingSelectGalleryFolderTitle =>
      'Selectionner le dossier de la galerie';

  @override
  String get onboardingSelectGalleryFolderMessage =>
      'Choisissez un dossier sur votre ordinateur pour analyser les photos et videos.';

  @override
  String get onboardingChooseFolder => 'Choisir un dossier';

  @override
  String get onboardingAllFilesAccessTitle =>
      'Acces a tous les fichiers (optionnel)';

  @override
  String get onboardingAllFilesAccessMessage =>
      'Sur Android 11+, accordez l\'acces a tous les fichiers pour deplacer ou supprimer des elements entre albums. Vous pouvez passer et l\'accorder plus tard.';

  @override
  String get onboardingGrantAccess => 'Accorder l\'acces';

  @override
  String get onboardingContinueWithout => 'Continuer sans';

  @override
  String get onboardingPhotosAccessTitle => 'Acces aux photos requis';

  @override
  String get onboardingPhotosAccessMessage =>
      'Social Gallery a besoin d\'acceder a vos photos et videos pour construire votre bibliotheque.';

  @override
  String get onboardingGrantPermission => 'Accorder l\'autorisation';

  @override
  String get onboardingAccessGrantedTitle => 'Acces accorde';

  @override
  String get onboardingAccessGrantedLimitedMessage =>
      'Acces photo limite active. Votre bibliotheque s\'indexe en arriere-plan.';

  @override
  String get onboardingAccessGrantedFullMessage =>
      'Votre bibliotheque s\'indexe en arriere-plan pendant que vous terminez la configuration.';

  @override
  String get onboardingGallerySyncRunning =>
      'Synchronisation de la galerie en cours';

  @override
  String get onboardingLocationScanRunning =>
      'Indexation des lieux photo en arriere-plan';

  @override
  String get onboardingChooseLanguageTitle => 'Choisir votre langue';

  @override
  String get onboardingChooseLanguageSubtitle =>
      'Selectionnez la langue utilisee dans Social Gallery. Vous pourrez la modifier plus tard dans les parametres.';

  @override
  String get onboardingChooseThemeTitle => 'Choisir un theme';

  @override
  String get onboardingChooseThemeSubtitle =>
      'Choisissez l\'apparence de Social Gallery. Vous pourrez la modifier plus tard.';

  @override
  String get onboardingAccentAndTextTitle => 'Accent et texte';

  @override
  String get onboardingAccentAndTextSubtitle =>
      'Ajustez les couleurs et la lisibilite.';

  @override
  String get onboardingViewModeTitle => 'Galerie ou social ?';

  @override
  String get onboardingViewModeSubtitle =>
      'Choisissez votre style de navigation par defaut.';

  @override
  String get onboardingSocialStyleTitle => 'Style social';

  @override
  String get onboardingSocialStyleDescription =>
      'Fil d\'accueil avec stories et publications, plus un onglet Explorer.';

  @override
  String get onboardingGalleryStyleTitle => 'Style galerie';

  @override
  String get onboardingGalleryStyleDescription =>
      'Grille galerie avec pincement sur Accueil et albums sur Explorer.';

  @override
  String get onboardingViewModeHint =>
      'Vous pouvez changer de mode a tout moment dans les Parametres.';

  @override
  String get onboardingYourFoldersTitle => 'Vos dossiers';

  @override
  String get onboardingYourFoldersSubtitleIndexing =>
      'L\'indexation est en cours. Vous pourrez ajuster les dossiers plus tard dans les Parametres.';

  @override
  String get onboardingYourFoldersSubtitleChoose =>
      'Choisissez ce qui apparait sur le fil d\'accueil, en compte uniquement ou masque.';

  @override
  String get onboardingNoFoldersYet =>
      'Aucun dossier trouve. Appuyez sur Commencer pour entrer dans l\'application pendant la synchronisation.';

  @override
  String folderItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elements',
      one: '1 element',
    );
    return '$_temp0';
  }

  @override
  String get folderVisibilityHome => 'Accueil';

  @override
  String get folderVisibilityAccount => 'Compte';

  @override
  String get folderVisibilityLock => 'Verrouiller';

  @override
  String get folderVisibilityHide => 'Masquer';

  @override
  String get folderVisibilityHomeFeed => 'Fil d\'accueil';

  @override
  String get folderVisibilityAccountOnly => 'Compte uniquement';

  @override
  String get folderVisibilityAccountLocked => 'Compte uniquement (verrouille)';

  @override
  String get folderVisibilityHidden => 'Masque';

  @override
  String get discoverBurstsTitle => 'Rafales';

  @override
  String get discoverBurstsMessage =>
      'La detection de rafales n\'est pas encore disponible. Cet ecran regroupera les prises en rafale.';

  @override
  String get discoverSuggestionsTitle => 'Suggestions intelligentes';

  @override
  String get discoverSuggestionsMessage =>
      'Les suggestions mettront en avant des albums et des idees de nettoyage selon votre bibliotheque.';

  @override
  String get discoverLocationsTitle => 'Lieux';

  @override
  String get discoverLocationsMessage =>
      'Parcourez vos photos regroupees par lieu sur une carte ou en albums.';

  @override
  String get locationsTabPlaces => 'Lieux';

  @override
  String get locationsTabMap => 'Carte';

  @override
  String locationsIndexing(int indexed, int total) {
    return 'Indexation des lieux $indexed / $total...';
  }

  @override
  String get locationsIndexingPreparing =>
      'Preparation de l\'index des lieux...';

  @override
  String get locationsBackfillPreparing => 'Lecture du GPS des photos...';

  @override
  String locationsBackfillProgress(int indexed, int total) {
    return 'Lecture du GPS $indexed / $total...';
  }

  @override
  String get locationsEmptyTitle => 'Aucune photo geolocalisee';

  @override
  String get locationsEmptyMessage =>
      'Les photos avec des donnees GPS de votre appareil photo apparaitront ici apres la prochaine synchronisation.';

  @override
  String locationsPhotoCount(int count) {
    return '$count photos';
  }

  @override
  String get locationsCountry => 'Pays';

  @override
  String get locationsCity => 'Villes';

  @override
  String locationsGeotaggedBadge(int count) {
    return '$count geolocalisees';
  }

  @override
  String get locationsErrorTitle => 'Impossible de charger les lieux';

  @override
  String get locationsErrorMessage =>
      'Un probleme est survenu lors de la resolution des lieux de vos photos. Reessayez plus tard.';

  @override
  String get homeErrorLoadFeed => 'Impossible de charger le fil';

  @override
  String get homeEmptyTitle => 'Aucune publication';

  @override
  String get homeEmptyMessage =>
      'Ajoutez des dossiers au fil d\'accueil dans Gerer le contenu.';

  @override
  String get snackbarCameraCaptureComingSoon =>
      'Capture photo bientot disponible';

  @override
  String get tooltipSearchGallery => 'Rechercher photos et videos';

  @override
  String get galleryErrorLoad => 'Impossible de charger la galerie';

  @override
  String get galleryEmptySearchTitle => 'Aucun media trouve';

  @override
  String get galleryEmptyTitle => 'Aucun media';

  @override
  String get galleryEmptySearchMessage =>
      'Essayez un autre nom de photo, album ou chemin de dossier.';

  @override
  String get galleryEmptyMessage =>
      'Synchronisez votre bibliotheque pour voir vos photos et videos ici.';

  @override
  String get tooltipSearch => 'Rechercher';

  @override
  String get exploreErrorLoad => 'Impossible de charger la bibliotheque';

  @override
  String get exploreEmptyTitle => 'Aucun media trouve';

  @override
  String get exploreEmptyMessageNoSearch =>
      'Essayez une autre recherche ou ajoutez des dossiers au fil d\'accueil.';

  @override
  String get exploreEmptyMessageSearch =>
      'Essayez un autre nom de photo, album ou chemin de dossier.';

  @override
  String get searchAlbumsAndFolders => 'Albums et dossiers';

  @override
  String get searchNoMatchingAlbums =>
      'Aucun album correspondant. Essayez un nom de photo ou de dossier.';

  @override
  String get searchRecentSearches => 'Recherches recentes';

  @override
  String get searchClearAll => 'Tout effacer';

  @override
  String get searchHint => 'Rechercher photos, videos, objets ou couleurs';

  @override
  String get searchObjectsAndAnimals => 'Objets et animaux';

  @override
  String get searchFilterByColor => 'Filtrer par couleur';

  @override
  String searchIndexingProgress(int scanned, int total) {
    return 'Indexation pour la recherche : $scanned / $total';
  }

  @override
  String get exploreEmptyMessageIndexing =>
      'Les photos sont encore indexees pour la recherche. Reessayez dans un instant.';

  @override
  String get searchChipCat => 'Chat';

  @override
  String get searchChipDog => 'Chien';

  @override
  String get searchChipPerson => 'Personne';

  @override
  String get searchChipFood => 'Nourriture';

  @override
  String get searchChipCar => 'Voiture';

  @override
  String get searchChipFlower => 'Fleur';

  @override
  String get searchChipBottle => 'Bouteille';

  @override
  String get searchChipBird => 'Oiseau';

  @override
  String get searchChipBeach => 'Plage';

  @override
  String get searchChipMountain => 'Montagne';

  @override
  String get searchColorRed => 'Rouge';

  @override
  String get searchColorOrange => 'Orange';

  @override
  String get searchColorYellow => 'Jaune';

  @override
  String get searchColorGreen => 'Vert';

  @override
  String get searchColorTeal => 'Bleu-vert';

  @override
  String get searchColorBlue => 'Bleu';

  @override
  String get searchColorPurple => 'Violet';

  @override
  String get searchColorPink => 'Rose';

  @override
  String get searchColorBrown => 'Marron';

  @override
  String get searchColorBlack => 'Noir';

  @override
  String get searchColorWhite => 'Blanc';

  @override
  String get searchColorGray => 'Gris';

  @override
  String get deepOrganizeIndexForSearch =>
      'Indexer les photos pour la recherche';

  @override
  String get deepOrganizeIndexingForSearch => 'Indexation pour la recherche...';

  @override
  String get tooltipClear => 'Effacer';

  @override
  String get tooltipClearSearch => 'Effacer la recherche';

  @override
  String get tooltipLockedAlbums => 'Albums verrouilles';

  @override
  String get albumsErrorLoad => 'Impossible de charger les albums';

  @override
  String get albumsTitle => 'Albums';

  @override
  String get albumsEmptyTitle => 'Aucun album';

  @override
  String get albumsEmptyMessage =>
      'Synchronisez votre bibliotheque pour voir les albums de votre appareil.';

  @override
  String get lockedAlbumsTitle => 'Albums verrouilles';

  @override
  String get lockedAlbumsEmptyTitle => 'Aucun album verrouille';

  @override
  String get lockedAlbumsEmptyMessage =>
      'Les albums proteges par biometrie apparaitront ici.';

  @override
  String get favoritesEmptyTitle => 'Aucun favori';

  @override
  String get favoritesEmptyMessage =>
      'Double-appuyez sur une publication pour l\'ajouter aux favoris.';

  @override
  String get storageAllFilesAccessTitle => 'Acces a tous les fichiers';

  @override
  String get storageAllFilesAccessGranted =>
      'Accorde. Vous pouvez deplacer et supprimer des elements entre albums.';

  @override
  String get storageAllFilesAccessRequired =>
      'Requis sur Android 11+ pour deplacer ou supprimer des elements entre albums.';

  @override
  String get storageGrantInSettings => 'Accorder dans les parametres';

  @override
  String get storageAllFilesAccessDialogMessage =>
      'La suppression ou le deplacement d\'elements entre albums sur Android 11+ necessite l\'acces a tous les fichiers dans les parametres systeme.';

  @override
  String get profileSelectFolder => 'Selectionner un dossier';

  @override
  String get tooltipFileAccess => 'Acces aux fichiers';

  @override
  String get tooltipManageContent => 'Gerer le contenu';

  @override
  String get tooltipSettings => 'Parametres';

  @override
  String get profileNoFolderSelected => 'Aucun dossier selectionne';

  @override
  String get profileNoFolderSelectedMessage =>
      'Synchronisez votre bibliotheque ou choisissez un dossier.';

  @override
  String get profileNoMediaInFolder => 'Aucun media dans ce dossier';

  @override
  String get profileErrorLoadFolder => 'Impossible de charger le dossier';

  @override
  String get profileErrorLoadFolders => 'Impossible de charger les dossiers';

  @override
  String selectionCount(int count) {
    return '$count selectionne(s)';
  }

  @override
  String get folderManagementNoFolders => 'Aucun dossier trouve.';

  @override
  String get folderShowInStories => 'Afficher dans Stories';

  @override
  String get folderSecureLock => 'Verrouillage securise';

  @override
  String get folderChangeCover => 'Changer la couverture';

  @override
  String get folderUseLatestPhoto => 'Utiliser la derniere photo';

  @override
  String get folderVisibilityTitle => 'Visibilite du dossier';

  @override
  String get folderBiographyTitle => 'Biographie';

  @override
  String get folderAddBiography => 'Ajouter une biographie';

  @override
  String get folderNoMedia => 'Aucun media';

  @override
  String get tooltipAlbumOptions => 'Options de l\'album';

  @override
  String get folderPickerDefaultTitle => 'Deplacer les elements vers...';

  @override
  String get folderPickerSearchHint => 'Rechercher des dossiers';

  @override
  String albumChooseCoverTitle(String folderName) {
    return 'Choisir la couverture pour $folderName';
  }

  @override
  String albumCoverLoadError(String error) {
    return 'Impossible de charger les photos de l\'album : $error';
  }

  @override
  String get albumCoverNoPhotos =>
      'Cet album n\'a pas de photos a utiliser comme couverture.';

  @override
  String get folderLockedTitle => 'Ce dossier est verrouille';

  @override
  String folderLockedMessage(String folderName) {
    return 'Utilisez la biometrie pour voir $folderName.';
  }

  @override
  String folderUnlockReason(String folderName) {
    return 'Deverrouiller $folderName';
  }

  @override
  String get folderBiometricsUnavailable =>
      'La biometrie n\'est pas disponible. Enregistrez une empreinte ou un visage dans les parametres de l\'appareil.';

  @override
  String get folderAuthFailed => 'Authentification echouee ou annulee.';

  @override
  String get postMoveToTrash => 'Deplacer vers la corbeille';

  @override
  String get postMoveToTrashMessage =>
      'Cet element sera deplace vers la corbeille et pourra etre restaure depuis les Parametres.';

  @override
  String get tooltipDetails => 'Details';

  @override
  String get tooltipShare => 'Partager';

  @override
  String get tooltipFavorite => 'Favori';

  @override
  String get postOpenFolder => 'Ouvrir le dossier';

  @override
  String get postFindInFileExplorer =>
      'Afficher dans l\'explorateur de fichiers';

  @override
  String get postFindInFileExplorerFailed =>
      'Impossible d\'ouvrir l\'emplacement du fichier';

  @override
  String get metadataTitle => 'Details';

  @override
  String get metadataFilename => 'Nom du fichier';

  @override
  String get metadataDimensions => 'Dimensions';

  @override
  String get metadataType => 'Type';

  @override
  String get metadataSize => 'Taille';

  @override
  String get metadataDateTaken => 'Date de prise';

  @override
  String get metadataDateAdded => 'Date d\'ajout';

  @override
  String get metadataFolder => 'Dossier';

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
  String get mediaKindFile => 'Fichier';

  @override
  String get organizeTitle => 'Organiser';

  @override
  String organizeProgress(int done, int size) {
    return '$done / $size';
  }

  @override
  String organizeSharingItem(String name) {
    return 'Partage de $name';
  }

  @override
  String get organizeBatchComplete => 'Lot termine';

  @override
  String get organizeAllCaughtUp => 'Tout est a jour';

  @override
  String organizeRemainingItems(int count) {
    return '$count elements correspondent encore a vos filtres.';
  }

  @override
  String get organizeNoMoreItems =>
      'Plus aucun element ne correspond aux filtres actuels.';

  @override
  String get organizeLoadNextBatch => 'Charger le lot suivant';

  @override
  String organizeReviewTrash(int count) {
    return 'Verifier la corbeille ($count)';
  }

  @override
  String get organizeChangeFilter => 'Changer le filtre';

  @override
  String get organizeReleaseKeptPhotos => 'Remettre les photos conservees';

  @override
  String get organizeFiltersTitle => 'Filtres';

  @override
  String get organizeMediaType => 'Type de media';

  @override
  String get organizeMediaAll => 'Tous';

  @override
  String get organizeMediaImage => 'Image';

  @override
  String get organizeMediaVideo => 'Video';

  @override
  String get organizeFilterFolder => 'Dossier';

  @override
  String get organizeAllFolders => 'Tous les dossiers';

  @override
  String get organizeFilterMonth => 'Mois (AAAA-MM)';

  @override
  String get organizeStatsTitle => 'Statistiques d\'organisation';

  @override
  String get organizeStatProcessed => 'Traites';

  @override
  String get organizeStatDeleted => 'Supprimes';

  @override
  String get organizeStatLiked => 'Aimes';

  @override
  String get organizeStatSpaceSaved => 'Espace economise';

  @override
  String organizeTrashReviewTitle(int count) {
    return 'Verifier la corbeille ($count)';
  }

  @override
  String get organizeTrashReviewMessage =>
      'Les elements selectionnes seront supprimes definitivement de votre appareil.';

  @override
  String organizeTrashDeleteCount(int count) {
    return 'Supprimer $count elements';
  }

  @override
  String get bulkMoveToTrashTitle => 'Deplacer vers la corbeille';

  @override
  String bulkMoveToTrashMessage(int count) {
    return 'Deplacer $count elements vers la corbeille ? Vous pourrez les restaurer depuis les Parametres.';
  }

  @override
  String snackbarMovedToTrash(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elements deplaces',
      one: '1 element deplace',
    );
    return '$_temp0 vers la corbeille';
  }

  @override
  String snackbarMovedItems(int moved) {
    String _temp0 = intl.Intl.pluralLogic(
      moved,
      locale: localeName,
      other: '$moved elements deplaces',
      one: '1 element deplace',
    );
    return '$_temp0';
  }

  @override
  String get snackbarMoveFailed =>
      'Impossible de deplacer les elements. Approuvez la demande systeme si affichee, ou verifiez l\'acces au stockage dans les Parametres.';

  @override
  String snackbarMovedPartial(int moved, int total) {
    return '$moved sur $total elements deplaces';
  }

  @override
  String get bulkCreateAlbumTitle => 'Creer un album';

  @override
  String get bulkAlbumNameLabel => 'Nom de l\'album';

  @override
  String get bulkCreateAndMove => 'Creer et deplacer';

  @override
  String snackbarAlbumCreatedAndMoved(String albumName, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elements deplaces',
      one: '1 element deplace',
    );
    return 'Album \"$albumName\" cree et $_temp0';
  }

  @override
  String get snackbarAlbumCreateFailed =>
      'Impossible de creer l\'album. Verifiez l\'acces au stockage.';

  @override
  String get tooltipCancelSelection => 'Annuler la selection';

  @override
  String get tooltipFavoriteSelected => 'Ajouter aux favoris';

  @override
  String get tooltipUnfavoriteSelected => 'Retirer des favoris';

  @override
  String get tooltipMoveSelected => 'Deplacer la selection';

  @override
  String get tooltipCreateAlbumAndMove => 'Creer un album et deplacer';

  @override
  String get tooltipSetAlbumCover => 'Definir comme couverture';

  @override
  String get tooltipMoveToTrash => 'Deplacer vers la corbeille';

  @override
  String get trashDeletePermanentlyTitle => 'Supprimer definitivement';

  @override
  String trashDeletePermanentlyMessage(int count) {
    return 'Voulez-vous vraiment supprimer definitivement ces $count elements de votre appareil ? Cette action est irreversible.';
  }

  @override
  String get trashDeletePermanentlyAction => 'Supprimer definitivement';

  @override
  String snackbarRestoredItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elements restaures',
      one: '1 element restaure',
    );
    return '$_temp0';
  }

  @override
  String snackbarPermanentlyDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elements supprimes',
      one: '1 element supprime',
    );
    return '$_temp0 definitivement';
  }

  @override
  String get tooltipRestoreSelected => 'Restaurer la selection';

  @override
  String get tooltipDeletePermanently => 'Supprimer definitivement';

  @override
  String get trashEmptyTitle => 'Corbeille vide';

  @override
  String get trashEmptyMessage =>
      'Les fichiers supprimes restent ici pour recuperation jusqu\'a expiration.';

  @override
  String get trashExpiresToday => 'Expire aujourd\'hui';

  @override
  String trashDaysLeft(int days) {
    return '$days jours restants';
  }

  @override
  String get discoverSectionOrganize => 'Organiser';

  @override
  String get discoverSectionDeepOrganize => 'Organisation approfondie';

  @override
  String get discoverSectionInsights => 'Statistiques';

  @override
  String get discoverSectionCleanup => 'Nettoyage';

  @override
  String get discoverSectionExplore => 'Explorer';

  @override
  String get discoverErrorLoad => 'Impossible de charger Decouvrir';

  @override
  String get discoverDeepOrganize => 'Organisation approfondie';

  @override
  String get discoverDeepOrganizeSubtitle =>
      'Analyse, photos similaires, basse qualite, compression';

  @override
  String get discoverShootingStats => 'Statistiques photo';

  @override
  String discoverShootingStatsSubtitle(int count) {
    return '$count elements organises jusqu\'ici';
  }

  @override
  String get discoverLikesReview => 'Revue des favoris';

  @override
  String discoverLikesReviewSubtitle(int count) {
    return '$count favoris';
  }

  @override
  String get discoverDuplicates => 'Doublons';

  @override
  String get discoverDuplicatesSubtitle =>
      'Trouver des photos quasi identiques';

  @override
  String get discoverBurstsSubtitle => 'Groupes de photos en rafale';

  @override
  String get discoverSuggestionsSubtitle => 'Idees d\'albums et de nettoyage';

  @override
  String get discoverLocationsSubtitle => 'Photos regroupees par lieu';

  @override
  String get deepOrganizeTitle => 'Organisation approfondie';

  @override
  String get deepOrganizeSubtitle =>
      'Analysez votre bibliotheque sur l\'appareil pour trouver des photos similaires et de basse qualite.';

  @override
  String deepOrganizeScanProgress(int scanned, int total) {
    return 'Analyse $scanned / $total';
  }

  @override
  String get deepOrganizeScanning => 'Analyse en cours...';

  @override
  String get deepOrganizeStartScan => 'Lancer l\'analyse';

  @override
  String get deepOrganizeToolsHeader => 'Outils';

  @override
  String get deepOrganizeCompressionSubtitle =>
      'Reduire les grandes images sur l\'appareil';

  @override
  String get deepOrganizeSimilarPhotos => 'Photos similaires';

  @override
  String deepOrganizeSimilarGroupsCount(int count) {
    return '$count groupes';
  }

  @override
  String get deepOrganizeLowQuality => 'Basse qualite';

  @override
  String deepOrganizeLowQualityCount(int count) {
    return '$count elements signales';
  }

  @override
  String get deepOrganizeCompression => 'Compression';

  @override
  String get deepOrganizeRunScanFirst =>
      'Lancez d\'abord une analyse depuis Organisation approfondie.';

  @override
  String get similarPhotosEmptyTitle => 'Aucun groupe similaire';

  @override
  String get similarPhotosSubtitle =>
      'Choisissez la meilleure prise et supprimez les quasi-doublons.';

  @override
  String similarPhotosGroupCount(int count) {
    return '$count elements similaires';
  }

  @override
  String get similarPhotosKeepBestDeleteOthers =>
      'Garder la meilleure, supprimer les autres';

  @override
  String get similarPhotosDeleteTitle => 'Supprimer les photos similaires';

  @override
  String similarPhotosDeleteMessage(String name, int count) {
    return 'Conserver \"$name\" et supprimer $count elements similaires ?';
  }

  @override
  String get lowQualityReviewTitle => 'Revue basse qualite';

  @override
  String get lowQualityReviewSubtitle =>
      'Verifiez les prises signalees et supprimez ce dont vous n\'avez pas besoin.';

  @override
  String get lowQualityEmptyTitle => 'Aucun element de basse qualite';

  @override
  String lowQualityProgress(int index, int total) {
    return '$index / $total';
  }

  @override
  String get compressionTitle => 'Compression d\'images';

  @override
  String get compressionSubtitle =>
      'Compressez les grandes photos sans quitter l\'appareil.';

  @override
  String get compressionBestOnMobile => 'Ideal sur mobile';

  @override
  String get compressionBestOnMobileSubtitle =>
      'La compression fonctionne sur Android et iOS. Support bureau limite.';

  @override
  String compressionResult(int done, int mb) {
    return '$done images compressees, $mb Mo economises';
  }

  @override
  String compressionCandidatesCount(int count) {
    return '$count images de plus de 3 Mo';
  }

  @override
  String get compressionCompressing => 'Compression en cours...';

  @override
  String compressionCompressSelected(int count) {
    return 'Compresser $count selectionne(s)';
  }

  @override
  String get likesReviewEmptySubtitle =>
      'Glissez vers la droite dans Organiser pour ajouter aux favoris.';

  @override
  String get likesReviewEmptyTitle => 'Aucun element aime';

  @override
  String get likesReviewSubtitle => 'Parcourez vos favoris.';

  @override
  String likesReviewSharing(String name) {
    return 'Partage de $name';
  }

  @override
  String get shootingStatsSubtitle =>
      'Vos habitudes photographiques sur l\'appareil.';

  @override
  String get shootingStatsPhotos => 'Photos';

  @override
  String get shootingStatsVideos => 'Videos';

  @override
  String get shootingStatsScreenshots => 'Captures d\'ecran';

  @override
  String get shootingStatsLiked => 'Aimes';

  @override
  String get shootingStatsFolders => 'Dossiers';

  @override
  String get shootingStatsVideoDuration => 'Duree video';

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String get shootingStatsMostActiveDay => 'Jour le plus actif';

  @override
  String shootingStatsMostActiveDayValue(String date, int count) {
    return '$date ($count)';
  }

  @override
  String get shootingStatsHeatmap => 'Carte d\'activite';

  @override
  String get shootingStatsNoActivity => 'Aucune activite ce mois-ci.';

  @override
  String shootingStatsHeatmapTooltip(String date, int count) {
    return '$date : $count';
  }

  @override
  String duplicateScanProgress(int scanned, int total) {
    return 'Analyse de $scanned / $total photos...';
  }

  @override
  String get duplicateScanPreparing =>
      'Preparation de l\'analyse des doublons...';

  @override
  String get duplicatesEmptyTitle => 'Aucun groupe de doublons';

  @override
  String get duplicatesEmptyMessage =>
      'Aucune photo quasi identique trouvee. Les doublons sont detectes par similarite visuelle, pas seulement par taille de fichier.';

  @override
  String duplicatesGroupBadge(int count) {
    return '$count doublons';
  }

  @override
  String get duplicatesKeepBestAndReview => 'Garder la meilleure et verifier';

  @override
  String get duplicateReviewTitle => 'Verifier les doublons';

  @override
  String get duplicateReviewSubtitle =>
      'La meilleure est preselectionnee. Appuyez sur les elements pour modifier ce qui sera supprime.';

  @override
  String get duplicateReviewGroupNotFound => 'Groupe introuvable';

  @override
  String duplicateReviewDeleteCount(int count) {
    return 'Supprimer ($count)';
  }

  @override
  String snackbarDuplicatesRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count doublons supprimes',
      one: '1 doublon supprime',
    );
    return '$_temp0.';
  }

  @override
  String get snackbarDuplicatesRemoveFailed =>
      'Impossible de supprimer certains elements. Verifiez les autorisations.';

  @override
  String get travelModeEmptyTitle => 'Aucun voyage';

  @override
  String get travelModeEmptyMessage =>
      'Creez un mode voyage pour organiser automatiquement les photos d\'une periode.';

  @override
  String get travelModeStatusActive => 'Actif';

  @override
  String get travelModeStatusUpcoming => 'A venir';

  @override
  String get travelModeStatusCompleted => 'Termine';

  @override
  String travelModeListSubtitle(String start, String end, String folder) {
    return '$start - ${end}nDossier : $folder';
  }

  @override
  String get travelModeErrorLoad => 'Impossible de charger les modes voyage';

  @override
  String get travelModeTripName => 'Nom du voyage';

  @override
  String get travelModeTargetFolder => 'Nom du dossier cible';

  @override
  String get travelModeTargetFolderHelper =>
      'Nom de l\'album pour les medias deplaces automatiquement (sans coffre)';

  @override
  String get travelModeStart => 'Debut';

  @override
  String get travelModeEnd => 'Fin';

  @override
  String get travelModeDate => 'Date';

  @override
  String get travelModeTime => 'Heure';

  @override
  String get travelModeSpecificTime => 'Heure precise';

  @override
  String get snackbarTravelModeRequiredFields =>
      'Nom, dossier et dates sont requis';

  @override
  String get travelModeDeleteTitle => 'Supprimer le mode voyage';

  @override
  String get travelModeDeleteMessage => 'Cette action est irreversible.';

  @override
  String get storyNoStoriesFound => 'Aucune story recente dans ce dossier.';

  @override
  String get backupSectionTitle => 'Sauvegarde bureau';

  @override
  String get backupReceiveBackups => 'Recevoir les sauvegardes';

  @override
  String get backupReceiveBackupsSubtitle =>
      'Autoriser cet ordinateur a recevoir les photos de votre telephone';

  @override
  String get backupIndexingBackups => 'Indexation des sauvegardes';

  @override
  String get backupShowPairingCode => 'Afficher le code d\'appairage';

  @override
  String get backupStartReceivingToShowCode =>
      'Activez la reception pour afficher le code';

  @override
  String get backupPairedDevice => 'Appareil apparie';

  @override
  String get backupUnpairDevice => 'Desapparier l\'appareil';

  @override
  String get backupUnpairDeviceSubtitle =>
      'Arreter d\'accepter les sauvegardes de ce telephone';

  @override
  String get backupRefreshLibrary => 'Actualiser la bibliotheque';

  @override
  String get backupRefreshLibrarySubtitle =>
      'Reanalyser les dossiers apres de nouvelles sauvegardes';

  @override
  String get backupBackUpToDesktop => 'Sauvegarder vers le bureau';

  @override
  String get backupBackUpToDesktopSubtitle =>
      'Sauvegarde automatique sur le meme Wi-Fi quand le bureau est actif';

  @override
  String get backupPairedDesktop => 'Bureau apparie';

  @override
  String get backupPairWithDesktop => 'Apparier avec le bureau';

  @override
  String get backupBackUpNow => 'Sauvegarder maintenant';

  @override
  String get backupBackUpNowSubtitle =>
      'Ne fonctionne que lorsque le bureau est disponible';

  @override
  String get backupUnpairDesktop => 'Desapparier le bureau';

  @override
  String get backupPairSheetTitle => 'Apparier avec le bureau';

  @override
  String get backupPairSheetDescription =>
      'Sur votre ordinateur, activez Recevoir les sauvegardes dans les Parametres et entrez le PIN affiche.';

  @override
  String get backupDesktopAddress => 'Adresse du bureau';

  @override
  String get backupPort => 'Port';

  @override
  String get backupPinLabel => 'PIN a 6 chiffres';

  @override
  String get backupScanPairingQr => 'Scanner le QR d\'appairage';

  @override
  String get backupFindOnNetwork => 'Rechercher sur le reseau';

  @override
  String get backupPair => 'Apparier';

  @override
  String get backupErrorNoDesktopFound =>
      'Aucun bureau trouve. Entrez l\'adresse affichee sur votre ordinateur.';

  @override
  String get backupErrorEnterHostPortPin =>
      'Entrez l\'hote, le port et le PIN a 6 chiffres du bureau.';

  @override
  String get backupErrorPairingFailed =>
      'Echec de l\'appairage. Verifiez le PIN et reessayez.';

  @override
  String get backupErrorInvalidQr =>
      'Le QR code n\'est pas un lien d\'appairage valide.';

  @override
  String get backupPairingSuccessTitle => 'Appairage reussi';

  @override
  String backupPairingSuccessMessage(String deviceName) {
    return '$deviceName est maintenant apparie avec cet ordinateur. Les sauvegardes demarreront automatiquement sur le meme Wi-Fi.';
  }

  @override
  String get backupPairYourPhoneTitle => 'Appairer votre telephone';

  @override
  String backupPinDisplay(String pin) {
    return 'PIN : $pin';
  }

  @override
  String get backupQrInstructions =>
      'Scannez avec l\'appareil photo ou utilisez Scanner le QR dans Parametres > Sauvegarde bureau.';

  @override
  String get backupScanPairingQrTitle => 'Scanner le QR d\'appairage';

  @override
  String backupStatusBackingUp(int processed, int total) {
    return 'Sauvegarde $processed/$total';
  }

  @override
  String get backupStatusOff => 'Desactive';

  @override
  String get backupStatusWaitingForDesktop => 'En attente du bureau';

  @override
  String get backupStatusDesktopReady => 'Bureau pret';

  @override
  String backupStatusLastBackup(String relativeTime) {
    return 'Derniere sauvegarde $relativeTime';
  }

  @override
  String get backupStatusUpToDate => 'A jour';

  @override
  String backupStatusError(String detail) {
    return 'Erreur - $detail';
  }

  @override
  String get backupStatusIdle => 'Inactif';

  @override
  String get timeJustNow => 'a l\'instant';

  @override
  String timeMinutesAgo(int n) {
    return 'il y a $n min';
  }

  @override
  String timeHoursAgo(int n) {
    return 'il y a $n h';
  }

  @override
  String timeDaysAgo(int n) {
    return 'il y a $n j';
  }

  @override
  String get backupNotificationPreparing => 'Preparation de la sauvegarde...';

  @override
  String get backupNotificationInProgress => 'Sauvegarde en cours';

  @override
  String backupNotificationProgress(int processed, int total) {
    return '$processed / $total elements sauvegardes';
  }

  @override
  String get backupNotificationComplete => 'Sauvegarde terminee';

  @override
  String get backupNotificationFailed => 'Echec de la sauvegarde';

  @override
  String get backupNotificationPaused => 'Sauvegarde en pause';

  @override
  String get notificationChannelDuplicateScan => 'Analyse des doublons';

  @override
  String get notificationChannelDuplicateScanDescription =>
      'Progression de la recherche de photos en double';

  @override
  String get notificationDuplicateScanTitle => 'Analyse des doublons';

  @override
  String get notificationDuplicateScanPreparing =>
      'Preparation de l\'analyse des doublons...';

  @override
  String notificationDuplicateScanProgress(int scanned, int total) {
    return 'Analyse de $scanned / $total photos...';
  }

  @override
  String get notificationDuplicateScanNoneTitle => 'Aucun doublon trouve';

  @override
  String get notificationDuplicateScanNoneBody =>
      'Aucune photo quasi identique trouvee dans votre bibliotheque.';

  @override
  String get notificationDuplicateScanCompleteTitle =>
      'Analyse des doublons terminee';

  @override
  String notificationDuplicateScanCompleteBody(int count, String Found) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count groupes de doublons trouves',
      one: '1 groupe de doublons trouve',
    );
    return '$_temp0';
  }

  @override
  String get notificationDuplicateScanFailedTitle =>
      'Echec de l\'analyse des doublons';

  @override
  String get notificationDuplicateScanFailedBody =>
      'Impossible de terminer l\'analyse. Ouvrez Doublons pour reessayer.';

  @override
  String get notificationChannelDesktopBackup => 'Sauvegarde bureau';

  @override
  String get notificationChannelDesktopBackupDescription =>
      'Progression de la sauvegarde des photos vers votre ordinateur';

  @override
  String get backupDetailDisabled => 'Sauvegarde desactivee';

  @override
  String get backupDetailNotReceiving => 'Reception des sauvegardes desactivee';

  @override
  String backupDetailPairedWith(String name) {
    return 'Apparie avec $name';
  }

  @override
  String get backupDetailReadyToReceive => 'Pret a recevoir les sauvegardes';

  @override
  String get backupDetailIndexingBackups =>
      'Indexation des sauvegardes existantes...';

  @override
  String backupDetailIndexingBackupsProgress(int scanned) {
    return 'Indexation des sauvegardes ($scanned fichiers)...';
  }

  @override
  String get backupDetailSearchingDesktop => 'Recherche du bureau...';

  @override
  String backupDetailFoundDesktop(String name) {
    return '$name trouve';
  }

  @override
  String get backupDetailNoDesktopFound => 'Aucun bureau trouve sur le reseau';

  @override
  String get backupDetailNotPaired => 'Non apparie';

  @override
  String get backupDetailCheckingDesktop =>
      'Verification de la disponibilite du bureau...';

  @override
  String get backupDetailWaitingForDesktop => 'En attente du bureau';

  @override
  String get backupDetailDesktopReady => 'Bureau pret';

  @override
  String get backupDetailDesktopUnavailable => 'Bureau indisponible';

  @override
  String backupDetailReconcilingItems(int count) {
    return 'Reconciliation de $count elements';
  }

  @override
  String get backupDetailReconciling => 'Reconciliation avec le bureau';

  @override
  String backupDetailBackingUpItems(int count) {
    return 'Sauvegarde de $count elements';
  }

  @override
  String get backupDetailCheckingItems => 'Recherche d\'elements a sauvegarder';

  @override
  String get backupDetailDesktopDisconnected => 'Bureau devenu indisponible';

  @override
  String get backupDetailWaitingForSync =>
      'En attente de la fin de la synchronisation...';

  @override
  String backupDetailFoundMoreItems(int count) {
    return '$count elements supplementaires a sauvegarder';
  }

  @override
  String get backupDetailAllBackedUp => 'Toutes les photos sont sauvegardees';

  @override
  String backupDetailBackedUpItems(int count) {
    return '$count elements sauvegardes';
  }

  @override
  String backupDetailBackingUpBatch(int batch, int count) {
    return 'Sauvegarde du lot $batch ($count elements)';
  }

  @override
  String backupDetailBackingUpFile(String folder, String name) {
    return 'Sauvegarde de $folder/$name';
  }

  @override
  String get backupDetailBackupFailed => 'Echec de la sauvegarde';

  @override
  String backupDetailReconcilingProgress(int count) {
    return 'Reconciliation de $count elements...';
  }

  @override
  String get backupDetailReconcileFailed => 'Echec de la reconciliation';

  @override
  String backupDetailVerifyingItems(int count) {
    return 'Verification de $count elements sauvegardes...';
  }

  @override
  String get backupDetailVerifyFailed => 'Echec de la verification';

  @override
  String get backupDetailDesktopDisconnectedDuringReconcile =>
      'Bureau devenu indisponible pendant la reconciliation';

  @override
  String get backupDetailDesktopDisconnectedDuringVerify =>
      'Bureau devenu indisponible pendant la verification';

  @override
  String get backupDetailDesktopDisconnectedDuringBackup =>
      'Bureau deconnecte pendant la sauvegarde';

  @override
  String get backupDetailDesktopDoesNotUpload =>
      'L\'application bureau ne s\'envoie pas de sauvegarde a elle-meme';

  @override
  String get backupDetailNotPairedWithDesktop => 'Non apparie avec un bureau';

  @override
  String backupReceivingFromDevice(String deviceName) {
    return 'Reception de la sauvegarde depuis $deviceName';
  }

  @override
  String backupReceivingFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers recus',
      one: '1 fichier recu',
    );
    return '$_temp0';
  }

  @override
  String get backupPhasePreparing => 'Preparation du fichier...';

  @override
  String get backupPhaseUploading => 'Envoi en cours...';

  @override
  String get backupPhaseCompleting => 'Finalisation du fichier...';

  @override
  String backupUploadFileProgress(int percent) {
    return 'Fichier en cours : $percent %';
  }

  @override
  String backupDetailBackingUpFileProgress(String path, int percent) {
    return 'Sauvegarde de $path ($percent %)';
  }

  @override
  String backupDetailBackingUpFilesProgress(int count, int percent) {
    return 'Sauvegarde de $count fichiers ($percent %)';
  }

  @override
  String backupDetailReceivingFileProgress(String path, int percent) {
    return '$path ($percent %)';
  }

  @override
  String backupDetailBackedUpWithFailures(int succeeded, int failed) {
    return '$succeeded elements sauvegardes, $failed en echec';
  }

  @override
  String get backupCloseBlockedTitle => 'Sauvegarde en cours';

  @override
  String get backupCloseBlockedMessage =>
      'Votre telephone envoie encore des photos. Gardez cette application ouverte jusqu\'a la fin de la sauvegarde.';

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
