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
  String get actionReset => 'Réinitialiser';

  @override
  String get actionKeep => 'Conserver';

  @override
  String get actionUnlock => 'Déverrouiller';

  @override
  String get actionClear => 'Effacer';

  @override
  String get actionOpenSettings => 'Ouvrir les paramètres';

  @override
  String get actionGoBack => 'Retour';

  @override
  String get valueNotSet => 'Non défini';

  @override
  String get errorGeneric => 'Erreur';

  @override
  String get errorCouldNotLoad => 'Impossible de charger';

  @override
  String get errorMediaNotFound => 'Média introuvable';

  @override
  String get errorFolderNotFound => 'Dossier introuvable';

  @override
  String get errorCouldNotUseFolder => 'Impossible d\'utiliser ce dossier';

  @override
  String errorFailedToSelectFolder(String error) {
    return 'Échec de la sélection du dossier : $error';
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
  String get navDiscover => 'Découvrir';

  @override
  String get navLockedAlbums => 'Albums verrouillés';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get settingsTitle => 'Paramètres';

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
  String get settingsSectionAbout => 'À propos';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageSystem => 'Langue du système';

  @override
  String get settingsLanguageEnglish => 'Anglais';

  @override
  String get settingsLanguageFrench => 'Français';

  @override
  String get settingsTheme => 'Thème';

  @override
  String get settingsAccentColor => 'Couleur d\'accent';

  @override
  String get settingsAccentColorDescription =>
      'Choisissez la couleur utilisée pour les boutons, liens et surlignages.';

  @override
  String get settingsFontSize => 'Taille du texte';

  @override
  String get settingsFontSizeDescription =>
      'Ajustez la taille du texte dans toute l\'application.';

  @override
  String get settingsAnimationSpeed => 'Vitesse des animations';

  @override
  String get settingsAnimationSpeedDescription =>
      'Prévisualisez la vitesse des transitions dans l\'application.';

  @override
  String get settingsGalleryRootFolder => 'Dossier racine de la galerie';

  @override
  String get settingsGalleryRootFolderEmptySubtitle =>
      'Choisissez un dossier à analyser pour les photos et vidéos';

  @override
  String get settingsGalleryGridSize => 'Taille de la grille';

  @override
  String get settingsGalleryViewMode => 'Mode galerie';

  @override
  String get settingsGalleryViewModeSubtitle =>
      'Onglet galerie avec pincement au lieu d\'Accueil et Explorer';

  @override
  String get settingsManageContent => 'Gérer le contenu';

  @override
  String get settingsManageContentSubtitle =>
      'Dossiers, fil d\'accueil et visibilité';

  @override
  String get settingsTravelMode => 'Mode voyage';

  @override
  String get settingsTravelModeSubtitle =>
      'Voyages et organisation par période';

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
  String get settingsReleaseKeptPhotos => 'Remettre les photos conservées';

  @override
  String get settingsReleaseKeptPhotosSubtitle =>
      'Remettre les photos traitees dans la file d\'organisation';

  @override
  String get settingsTrashRetention => 'Rétention de la corbeille';

  @override
  String get settingsTrashRetentionDescription =>
      'Les éléments de la corbeille sont supprimés définitivement après cette période.';

  @override
  String settingsTrashRetentionDays(int days) {
    return '$days jours';
  }

  @override
  String get settingsDeletedItems => 'Éléments supprimés';

  @override
  String get settingsDeletedItemsSubtitle =>
      'Voir, restaurer ou vider la corbeille';

  @override
  String get settingsCache => 'Cache';

  @override
  String get settingsCacheSizeLimit => 'Limite de taille du cache';

  @override
  String get settingsCacheSizeLimitDescription =>
      'Stockage maximal utilisé par les miniatures et fichiers temporaires.';

  @override
  String settingsCacheSizeLimitValue(int limitMb) {
    return '$limitMb Mo';
  }

  @override
  String get settingsAutoClearOnClose => 'Effacer à la fermeture';

  @override
  String get settingsAutoClearOnCloseSubtitle =>
      'Effacer le cache lorsque l\'application est fermée';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsPrivacyPolicy => 'Politique de confidentialité';

  @override
  String get settingsOpenSourceLicenses => 'Licences open source';

  @override
  String get settingsShareApp => 'Partager l\'application';

  @override
  String get settingsShareAppMessage =>
      'Découvrez Social Gallery - une galerie photo locale.';

  @override
  String get dialogClearCacheTitle => 'Effacer le cache';

  @override
  String dialogClearCacheMessage(int size) {
    return 'Effacer $size de miniatures et fichiers temporaires en cache ?';
  }

  @override
  String get snackbarCacheCleared => 'Cache effacé';

  @override
  String get snackbarReleasedKeptPhotos => 'Photos conservées remises en file';

  @override
  String get snackbarGalleryRootUpdated =>
      'Dossier racine mis à jour. Réanalyse de la bibliothèque.';

  @override
  String get dialogSelectRootGalleryFolder =>
      'Sélectionner le dossier racine de la galerie';

  @override
  String get debugBuildTitle => 'Version de debug';

  @override
  String get debugBuildMessage =>
      'Ce n\'est pas une version de production et elle peut contenir des erreurs.';

  @override
  String get themeSystemDefault => 'Système';

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
  String get gridSizeStandard => 'Confortable';

  @override
  String get gridSizeLarge => 'Grand';

  @override
  String get gridSizeCompactSubtitle =>
      'Miniatures plus petites, plus de colonnes';

  @override
  String get gridSizeStandardSubtitle => 'Taille de miniature confortable';

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
  String get fontSizeExtraLarge => 'Très grand';

  @override
  String get animationSpeedInstant => 'Instantané';

  @override
  String get animationSpeedFast => 'Rapide';

  @override
  String get animationSpeedNormal => 'Normal';

  @override
  String get animationSpeedSlow => 'Lent';

  @override
  String get queueOrderRandom => 'Aléatoire';

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
      'Vos photos restent sur votre appareil. Configurez quelques préférences et nous indexerons votre bibliothèque en arrière-plan.';

  @override
  String get onboardingPermissionsHeader => 'Autorisations';

  @override
  String get onboardingPermissionsSubtitle =>
      'Autorisez l\'accès pour analyser vos albums.';

  @override
  String get onboardingSelectGalleryFolderTitle =>
      'Sélectionner le dossier de la galerie';

  @override
  String get onboardingSelectGalleryFolderMessage =>
      'Choisissez un dossier sur votre ordinateur pour analyser les photos et vidéos.';

  @override
  String get onboardingChooseFolder => 'Choisir un dossier';

  @override
  String get onboardingAllFilesAccessTitle =>
      'Accès à tous les fichiers (optionnel)';

  @override
  String get onboardingAllFilesAccessMessage =>
      'Sur Android 11+, accordez l\'accès à tous les fichiers pour déplacer ou supprimer des éléments entre albums. Vous pouvez passer et l\'accorder plus tard.';

  @override
  String get onboardingGrantAccess => 'Accorder l\'accès';

  @override
  String get onboardingContinueWithout => 'Continuer sans';

  @override
  String get onboardingPhotosAccessTitle => 'Accès aux photos requis';

  @override
  String get onboardingPhotosAccessMessage =>
      'Social Gallery a besoin d\'accéder à vos photos et vidéos pour construire votre bibliothèque.';

  @override
  String get onboardingGrantPermission => 'Accorder l\'autorisation';

  @override
  String get onboardingAccessGrantedTitle => 'Accès accordé';

  @override
  String get onboardingAccessGrantedLimitedMessage =>
      'Accès photo limité activé. Votre bibliothèque s\'indexé en arrière-plan.';

  @override
  String get onboardingAccessGrantedFullMessage =>
      'Votre bibliothèque s\'indexé en arrière-plan pendant que vous terminez la configuration.';

  @override
  String get onboardingGallerySyncRunning =>
      'Synchronisation de la galerie en cours';

  @override
  String get onboardingLocationScanRunning =>
      'Indexation des lieux photo en arrière-plan';

  @override
  String get onboardingChooseLanguageTitle => 'Choisir votre langue';

  @override
  String get onboardingChooseLanguageSubtitle =>
      'Sélectionnez la langue utilisée dans Social Gallery. Vous pourrez la modifier plus tard dans les paramètres.';

  @override
  String get onboardingChooseThemeTitle => 'Choisir un theme';

  @override
  String get onboardingChooseThemeSubtitle =>
      'Choisissez l\'apparence de Social Gallery. Vous pourrez la modifier plus tard.';

  @override
  String get onboardingAccentAndTextTitle => 'Accent et texte';

  @override
  String get onboardingAccentAndTextSubtitle =>
      'Ajustez les couleurs et la lisibilité.';

  @override
  String get onboardingViewModeTitle => 'Galerie ou social ?';

  @override
  String get onboardingViewModeSubtitle =>
      'Choisissez votre style de navigation par défaut.';

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
      'Vous pouvez changer de mode à tout moment dans les Paramètres.';

  @override
  String get onboardingYourFoldersTitle => 'Vos dossiers';

  @override
  String get onboardingYourFoldersSubtitleIndexing =>
      'L\'indexation est en cours. Vous pourrez ajuster les dossiers plus tard dans les Paramètres.';

  @override
  String get onboardingYourFoldersSubtitleChoose =>
      'Choisissez ce qui apparaît sur le fil d\'accueil, en compte uniquement ou masqué.';

  @override
  String get onboardingNoFoldersYet =>
      'Aucun dossier trouvé. Appuyez sur Commencer pour entrer dans l\'application pendant la synchronisation.';

  @override
  String folderItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments',
      one: '1 élément',
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
  String get folderVisibilityAccountLocked => 'Compte uniquement (verrouillé)';

  @override
  String get folderVisibilityHidden => 'Masqué';

  @override
  String get discoverBurstsTitle => 'Rafales';

  @override
  String get discoverBurstsMessage =>
      'La détection de rafales n\'est pas encore disponible. Cet écran regroupera les prises en rafale.';

  @override
  String get discoverSuggestionsTitle => 'Suggestions intelligentes';

  @override
  String get discoverSuggestionsMessage =>
      'Les suggestions mettront en avant des albums et des idées de nettoyage selon votre bibliothèque.';

  @override
  String get discoverLocationsTitle => 'Lieux';

  @override
  String get discoverLocationsMessage =>
      'Parcourez vos photos regroupées par lieu sur une carte ou en albums.';

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
      'Préparation de l\'index des lieux...';

  @override
  String get locationsBackfillPreparing => 'Lecture du GPS des photos...';

  @override
  String locationsBackfillProgress(int indexed, int total) {
    return 'Lecture du GPS $indexed / $total...';
  }

  @override
  String get locationsEmptyTitle => 'Aucune photo géolocalisée';

  @override
  String get locationsEmptyMessage =>
      'Les photos avec des données GPS de votre appareil photo apparaîtront ici après la prochaine synchronisation.';

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
    return '$count géolocalisées';
  }

  @override
  String get locationsErrorTitle => 'Impossible de charger les lieux';

  @override
  String get locationsErrorMessage =>
      'Un problème est survenu lors de la résolution des lieux de vos photos. Réessayez plus tard.';

  @override
  String get homeErrorLoadFeed => 'Impossible de charger le fil';

  @override
  String get homeEmptyTitle => 'Aucune publication';

  @override
  String get homeEmptyMessage =>
      'Ajoutez des dossiers au fil d\'accueil dans Gérer le contenu.';

  @override
  String get snackbarCameraCaptureComingSoon =>
      'Capture photo bientôt disponible';

  @override
  String get tooltipSearchGallery => 'Rechercher photos et vidéos';

  @override
  String get galleryErrorLoad => 'Impossible de charger la galerie';

  @override
  String get galleryEmptySearchTitle => 'Aucun média trouvé';

  @override
  String get galleryEmptyTitle => 'Aucun média';

  @override
  String get galleryEmptySearchMessage =>
      'Essayez un autre nom de photo, album ou chemin de dossier.';

  @override
  String get galleryEmptyMessage =>
      'Synchronisez votre bibliothèque pour voir vos photos et vidéos ici.';

  @override
  String get tooltipSearch => 'Rechercher';

  @override
  String get exploreErrorLoad => 'Impossible de charger la bibliothèque';

  @override
  String get exploreEmptyTitle => 'Aucun média trouvé';

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
  String get searchRecentSearches => 'Recherches récentes';

  @override
  String get searchClearAll => 'Tout effacer';

  @override
  String get searchHint => 'Rechercher photos, vidéos, objets ou couleurs';

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
      'Les photos sont encore indexées pour la recherche. Réessayez dans un instant.';

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
  String get tooltipLockedAlbums => 'Albums verrouillés';

  @override
  String get albumsErrorLoad => 'Impossible de charger les albums';

  @override
  String get albumsTitle => 'Albums';

  @override
  String get albumsEmptyTitle => 'Aucun album';

  @override
  String get albumsEmptyMessage =>
      'Synchronisez votre bibliothèque pour voir les albums de votre appareil.';

  @override
  String get lockedAlbumsTitle => 'Albums verrouillés';

  @override
  String get lockedAlbumsEmptyTitle => 'Aucun album verrouillé';

  @override
  String get lockedAlbumsEmptyMessage =>
      'Les albums protégés par biométrie apparaîtront ici.';

  @override
  String get favoritesEmptyTitle => 'Aucun favori';

  @override
  String get favoritesEmptyMessage =>
      'Double-appuyez sur une publication pour l\'ajouter aux favoris.';

  @override
  String get storageAllFilesAccessTitle => 'Accès à tous les fichiers';

  @override
  String get storageAllFilesAccessGranted =>
      'Accordé. Vous pouvez déplacer et supprimer des éléments entre albums.';

  @override
  String get storageAllFilesAccessRequired =>
      'Requis sur Android 11+ pour déplacer ou supprimer des éléments entre albums.';

  @override
  String get storageGrantInSettings => 'Accorder dans les paramètres';

  @override
  String get storageAllFilesAccessDialogMessage =>
      'La suppression ou le déplacement d\'éléments entre albums sur Android 11+ nécessite l\'accès à tous les fichiers dans les paramètres système.';

  @override
  String get profileSelectFolder => 'Sélectionner un dossier';

  @override
  String get tooltipFileAccess => 'Accès aux fichiers';

  @override
  String get tooltipManageContent => 'Gérer le contenu';

  @override
  String get tooltipSettings => 'Paramètres';

  @override
  String get profileNoFolderSelected => 'Aucun dossier sélectionné';

  @override
  String get profileNoFolderSelectedMessage =>
      'Synchronisez votre bibliothèque ou choisissez un dossier.';

  @override
  String get profileNoMediaInFolder => 'Aucun média dans ce dossier';

  @override
  String get profileErrorLoadFolder => 'Impossible de charger le dossier';

  @override
  String get profileErrorLoadFolders => 'Impossible de charger les dossiers';

  @override
  String selectionCount(int count) {
    return '$count sélectionné(s)';
  }

  @override
  String get folderManagementNoFolders => 'Aucun dossier trouvé.';

  @override
  String get folderShowInStories => 'Afficher dans Stories';

  @override
  String get folderSecureLock => 'Verrouillage sécurisé';

  @override
  String get folderChangeCover => 'Changer la couverture';

  @override
  String get folderUseLatestPhoto => 'Utiliser la dernière photo';

  @override
  String get folderVisibilityTitle => 'Visibilité du dossier';

  @override
  String get folderBiographyTitle => 'Biographie';

  @override
  String get folderAddBiography => 'Ajouter une biographie';

  @override
  String get folderNoMedia => 'Aucun média';

  @override
  String get tooltipAlbumOptions => 'Options de l\'album';

  @override
  String get folderPickerDefaultTitle => 'Déplacer les éléments vers...';

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
      'Cet album n\'a pas de photos à utiliser comme couverture.';

  @override
  String get folderLockedTitle => 'Ce dossier est verrouillé';

  @override
  String folderLockedMessage(String folderName) {
    return 'Utilisez la biométrie pour voir $folderName.';
  }

  @override
  String folderUnlockReason(String folderName) {
    return 'Déverrouiller $folderName';
  }

  @override
  String get folderBiometricsUnavailable =>
      'La biométrie n\'est pas disponible. Enregistrez une empreinte ou un visage dans les paramètres de l\'appareil.';

  @override
  String get folderAuthFailed => 'Authentification échouée ou annulée.';

  @override
  String get postMoveToTrash => 'Déplacer vers la corbeille';

  @override
  String get postMoveToTrashMessage =>
      'Cet élément sera déplacé vers la corbeille et pourra être restauré depuis les Paramètres.';

  @override
  String get tooltipDetails => 'Détails';

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
  String get metadataTitle => 'Détails';

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
  String get mediaKindVideo => 'Vidéo';

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
  String get organizeMoveFailed =>
      'Impossible de déplacer cet élément. Réessayez.';

  @override
  String get organizeBatchComplete => 'Lot terminé';

  @override
  String get organizeAllCaughtUp => 'Tout est à jour';

  @override
  String organizeRemainingItems(int count) {
    return '$count éléments correspondent encore à vos filtres.';
  }

  @override
  String get organizeNoMoreItems =>
      'Plus aucun élément ne correspond aux filtres actuels.';

  @override
  String get organizeLoadNextBatch => 'Charger le lot suivant';

  @override
  String organizeReviewTrash(int count) {
    return 'Vérifier la corbeille ($count)';
  }

  @override
  String get organizeChangeFilter => 'Changer le filtre';

  @override
  String get organizeReleaseKeptPhotos => 'Remettre les photos conservées';

  @override
  String get organizeFiltersTitle => 'Filtres';

  @override
  String get organizeMediaType => 'Type de média';

  @override
  String get organizeMediaAll => 'Tous';

  @override
  String get organizeMediaImage => 'Image';

  @override
  String get organizeMediaVideo => 'Vidéo';

  @override
  String get organizeFilterFolder => 'Dossier';

  @override
  String get organizeAllFolders => 'Tous les dossiers';

  @override
  String get organizeFilterMonth => 'Mois (AAAA-MM)';

  @override
  String get organizeStatsTitle => 'Statistiques d\'organisation';

  @override
  String get organizeStatProcessed => 'Traités';

  @override
  String get organizeStatDeleted => 'Supprimés';

  @override
  String get organizeStatLiked => 'Aimés';

  @override
  String get organizeStatSpaceSaved => 'Espace économisé';

  @override
  String organizeTrashReviewTitle(int count) {
    return 'Vérifier la corbeille ($count)';
  }

  @override
  String get organizeTrashReviewMessage =>
      'Les éléments sélectionnés seront supprimés définitivement de votre appareil.';

  @override
  String organizeTrashDeleteCount(int count) {
    return 'Supprimer $count éléments';
  }

  @override
  String get bulkMoveToTrashTitle => 'Déplacer vers la corbeille';

  @override
  String bulkMoveToTrashMessage(int count) {
    return 'Déplacer $count éléments vers la corbeille ? Vous pourrez les restaurer depuis les Paramètres.';
  }

  @override
  String snackbarMovedToTrash(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments déplacés',
      one: '1 élément déplacé',
    );
    return '$_temp0 vers la corbeille';
  }

  @override
  String snackbarMovedItems(int moved) {
    String _temp0 = intl.Intl.pluralLogic(
      moved,
      locale: localeName,
      other: '$moved éléments déplacés',
      one: '1 élément déplacé',
    );
    return '$_temp0';
  }

  @override
  String get snackbarMoveFailed =>
      'Impossible de déplacer les éléments. Approuvez la demande système si affichée, ou vérifiez l\'accès au stockage dans les Paramètres.';

  @override
  String snackbarMovedPartial(int moved, int total) {
    return '$moved sur $total éléments déplacés';
  }

  @override
  String get bulkCreateAlbumTitle => 'Créer un album';

  @override
  String get bulkAlbumNameLabel => 'Nom de l\'album';

  @override
  String get bulkCreateAndMove => 'Créer et déplacer';

  @override
  String snackbarAlbumCreatedAndMoved(String albumName, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments déplacés',
      one: '1 élément déplacé',
    );
    return 'Album \"$albumName\" créé et $_temp0';
  }

  @override
  String get snackbarAlbumCreateFailed =>
      'Impossible de créer l\'album. Vérifiez l\'accès au stockage.';

  @override
  String get tooltipCancelSelection => 'Annuler la sélection';

  @override
  String get tooltipFavoriteSelected => 'Ajouter aux favoris';

  @override
  String get tooltipUnfavoriteSelected => 'Retirer des favoris';

  @override
  String get tooltipMoveSelected => 'Déplacer la sélection';

  @override
  String get tooltipCreateAlbumAndMove => 'Créer un album et déplacer';

  @override
  String get tooltipSetAlbumCover => 'Définir comme couverture';

  @override
  String get tooltipMoveToTrash => 'Déplacer vers la corbeille';

  @override
  String get selectionActionMove => 'Déplacer';

  @override
  String get selectionActionShare => 'Partager';

  @override
  String get selectionActionDelete => 'Supprimer';

  @override
  String get selectionActionMore => 'Plus';

  @override
  String get selectionCopyToClipboard => 'Copier dans le presse-papiers';

  @override
  String get selectionSetAsWallpaper => 'Définir comme fond d\'écran';

  @override
  String snackbarSharedItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments partagés',
      one: '1 élément partagé',
    );
    return '$_temp0';
  }

  @override
  String get snackbarShareFailed => 'Impossible de partager la sélection';

  @override
  String get snackbarCopiedToClipboard => 'Copie dans le presse-papiers';

  @override
  String get snackbarCopyFailed =>
      'Impossible de copier dans le presse-papiers';

  @override
  String get snackbarCopyUnsupported =>
      'Seules les images peuvent être copiees';

  @override
  String get snackbarWallpaperSet => 'Fond d\'écran mis à jour';

  @override
  String get snackbarWallpaperFailed =>
      'Impossible de définir le fond d\'écran';

  @override
  String get snackbarWallpaperUnsupported =>
      'Le fond d\'écran est disponible uniquement pour les images sur Android';

  @override
  String get wallpaperConfirmTitle => 'Définir comme fond d\'écran ?';

  @override
  String get wallpaperConfirmMessage =>
      'Cette image sera définie comme fond d\'écran de l\'écran d\'accueil.';

  @override
  String get wallpaperConfirmAction => 'Définir';

  @override
  String get trashDeletePermanentlyTitle => 'Supprimer définitivement';

  @override
  String trashDeletePermanentlyMessage(int count) {
    return 'Voulez-vous vraiment supprimer définitivement ces $count éléments de votre appareil ? Cette action est irreversible.';
  }

  @override
  String get trashDeletePermanentlyAction => 'Supprimer définitivement';

  @override
  String snackbarRestoredItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments restaurés',
      one: '1 élément restauré',
    );
    return '$_temp0';
  }

  @override
  String snackbarPermanentlyDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments supprimés',
      one: '1 élément supprimé',
    );
    return '$_temp0 définitivement';
  }

  @override
  String get tooltipRestoreSelected => 'Restaurer la sélection';

  @override
  String get tooltipDeletePermanently => 'Supprimer définitivement';

  @override
  String get trashEmptyTitle => 'Corbeille vide';

  @override
  String get trashEmptyMessage =>
      'Les fichiers supprimés restent ici pour recuperation jusqu\'a expiration.';

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
  String get discoverErrorLoad => 'Impossible de charger Découvrir';

  @override
  String get discoverDeepOrganize => 'Organisation approfondie';

  @override
  String get discoverDeepOrganizeSubtitle =>
      'Analyse, photos similaires, basse qualité, compression';

  @override
  String get discoverShootingStats => 'Statistiques photo';

  @override
  String discoverShootingStatsSubtitle(int count) {
    return '$count éléments organises jusqu\'ici';
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
  String get discoverLocationsSubtitle => 'Photos regroupées par lieu';

  @override
  String get discoverScreenshotsTitle => 'Captures d\'écran';

  @override
  String get discoverScreenshotsSubtitle =>
      'Parcourir et nettoyer les captures';

  @override
  String get discoverScreenshotsEmptyTitle => 'Aucune capture';

  @override
  String get discoverScreenshotsEmptyMessage =>
      'Les captures detectees par nom ou album apparaîtront ici.';

  @override
  String get discoverDocumentsTitle => 'Documents et texte';

  @override
  String get discoverDocumentsSubtitle =>
      'Recus, notes et photos riches en texte';

  @override
  String get discoverDocumentsEmptyTitle => 'Aucun document';

  @override
  String get discoverDocumentsEmptyMessage =>
      'Lancez l\'indexation du texte pour trouver recus, notes et pages scannees.';

  @override
  String get discoverDocumentsSearchHint =>
      'Rechercher du texte dans les photos';

  @override
  String get discoverOcrIndexAction => 'Indexer le texte';

  @override
  String discoverOcrIndexProgress(int scanned, int total) {
    return 'OCR $scanned/$total';
  }

  @override
  String get settingsWidgetsTitle => 'Widgets écran d\'accueil';

  @override
  String get settingsWidgetsSubtitle =>
      'Ajoutez des diaporamas d\'albums sur Android';

  @override
  String get settingsWidgetsHelpBody =>
      'Appuyez longuement sur l\'écran d\'accueil, choisissez Widgets, puis Social Gallery. Configurez l\'album, l\'intervalle et le rafraîchissement au déverrouillage.';

  @override
  String get widgetConfigTitle => 'Widget dossier';

  @override
  String get widgetConfigFolder => 'Album';

  @override
  String get widgetConfigInterval => 'Changer toutes les';

  @override
  String get widgetConfigInterval10m => '10 minutes';

  @override
  String get widgetConfigInterval30m => '30 minutes';

  @override
  String get widgetConfigInterval1h => '1 heure';

  @override
  String get widgetConfigIntervalCustom => 'Personnalisé (minutes)';

  @override
  String get widgetConfigRefreshOnUnlock => 'Changer au déverrouillage';

  @override
  String get widgetConfigPickMode => 'Ordre des photos';

  @override
  String get widgetConfigPickRandom => 'Aléatoire';

  @override
  String get widgetConfigPickRecent => 'Plus récentes';

  @override
  String get widgetConfigSave => 'Enregistrer';

  @override
  String get deepOrganizeTitle => 'Organisation approfondie';

  @override
  String get deepOrganizeSubtitle =>
      'Analysez votre bibliothèque sur l\'appareil pour trouver des photos similaires et de basse qualité.';

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
  String get deepOrganizeLowQuality => 'Basse qualité';

  @override
  String deepOrganizeLowQualityCount(int count) {
    return '$count éléments signales';
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
    return '$count éléments similaires';
  }

  @override
  String get similarPhotosKeepBestDeleteOthers =>
      'Garder la meilleure, supprimer les autres';

  @override
  String get similarPhotosDeleteTitle => 'Supprimer les photos similaires';

  @override
  String similarPhotosDeleteMessage(String name, int count) {
    return 'Conserver \"$name\" et supprimer $count éléments similaires ?';
  }

  @override
  String get lowQualityReviewTitle => 'Revue basse qualité';

  @override
  String get lowQualityReviewSubtitle =>
      'Vérifiez les prises signalees et supprimez ce dont vous n\'avez pas besoin.';

  @override
  String get lowQualityEmptyTitle => 'Aucun élément de basse qualité';

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
    return '$done images compressées, $mb Mo économisés';
  }

  @override
  String compressionCandidatesCount(int count) {
    return '$count images de plus de 3 Mo';
  }

  @override
  String get compressionCompressing => 'Compression en cours...';

  @override
  String compressionCompressSelected(int count) {
    return 'Compresser $count sélectionné(s)';
  }

  @override
  String get likesReviewEmptySubtitle =>
      'Glissez vers la droite dans Organiser pour ajouter aux favoris.';

  @override
  String get likesReviewEmptyTitle => 'Aucun élément aime';

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
  String get shootingStatsVideos => 'Vidéos';

  @override
  String get shootingStatsScreenshots => 'Captures d\'écran';

  @override
  String get shootingStatsLiked => 'Aimés';

  @override
  String get shootingStatsFolders => 'Dossiers';

  @override
  String get shootingStatsVideoDuration => 'Duree vidéo';

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
  String get shootingStatsHeatmap => 'Carte d\'activité';

  @override
  String get shootingStatsNoActivity => 'Aucune activité ce mois-ci.';

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
      'Préparation de l\'analyse des doublons...';

  @override
  String get duplicatesEmptyTitle => 'Aucun groupe de doublons';

  @override
  String get duplicatesEmptyMessage =>
      'Aucune photo quasi identique trouvée. Les doublons sont detectes par similarite visuelle, pas seulement par taille de fichier.';

  @override
  String duplicatesGroupBadge(int count) {
    return '$count doublons';
  }

  @override
  String get duplicatesKeepBestAndReview => 'Garder la meilleure et vérifier';

  @override
  String get duplicateReviewTitle => 'Vérifier les doublons';

  @override
  String get duplicateReviewSubtitle =>
      'La meilleure est présélectionnée. Appuyez sur les éléments pour modifier ce qui sera supprimé.';

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
      other: '$count doublons supprimés',
      one: '1 doublon supprimé',
    );
    return '$_temp0.';
  }

  @override
  String get snackbarDuplicatesRemoveFailed =>
      'Impossible de supprimer certains éléments. Vérifiez les autorisations.';

  @override
  String get travelModeEmptyTitle => 'Aucun voyage';

  @override
  String get travelModeEmptyMessage =>
      'Creez un mode voyage pour organiser automatiquement les photos d\'une période.';

  @override
  String get travelModeStatusActive => 'Actif';

  @override
  String get travelModeStatusUpcoming => 'A venir';

  @override
  String get travelModeStatusCompleted => 'Terminé';

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
      'Nom de l\'album pour les médias déplacés automatiquement (sans coffre)';

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
  String get storyNoStoriesFound => 'Aucune story récente dans ce dossier.';

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
  String get backupRefreshLibrary => 'Actualiser la bibliothèque';

  @override
  String get backupRefreshLibrarySubtitle =>
      'Reanalyser les dossiers après de nouvelles sauvegardes';

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
      'Sur votre ordinateur, activez Recevoir les sauvegardes dans les Paramètres et entrez le PIN affiché.';

  @override
  String get backupDesktopAddress => 'Adresse du bureau';

  @override
  String get backupPort => 'Port';

  @override
  String get backupPinLabel => 'PIN a 6 chiffres';

  @override
  String get backupScanPairingQr => 'Scanner le QR d\'appairage';

  @override
  String get backupFindOnNetwork => 'Rechercher sur le réseau';

  @override
  String get backupPair => 'Apparier';

  @override
  String get backupErrorNoDesktopFound =>
      'Aucun bureau trouvé. Entrez l\'adresse affichée sur votre ordinateur.';

  @override
  String get backupErrorEnterHostPortPin =>
      'Entrez l\'hôte, le port et le PIN a 6 chiffres du bureau.';

  @override
  String get backupErrorPairingFailed =>
      'Échec de l\'appairage. Vérifiez le PIN et réessayez.';

  @override
  String get backupErrorInvalidQr =>
      'Le QR code n\'est pas un lien d\'appairage validé.';

  @override
  String get backupPairingSuccessTitle => 'Appairage réussi';

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
      'Scannez avec l\'appareil photo ou utilisez Scanner le QR dans Paramètres > Sauvegarde bureau.';

  @override
  String get backupScanPairingQrTitle => 'Scanner le QR d\'appairage';

  @override
  String backupStatusBackingUp(int processed, int total) {
    return 'Sauvegarde $processed/$total';
  }

  @override
  String get backupStatusOff => 'Désactivé';

  @override
  String get backupStatusWaitingForDesktop => 'En attente du bureau';

  @override
  String get backupStatusDesktopReady => 'Bureau pret';

  @override
  String backupStatusLastBackup(String relativeTime) {
    return 'Dernière sauvegarde $relativeTime';
  }

  @override
  String get backupStatusUpToDate => 'À jour';

  @override
  String backupStatusError(String detail) {
    return 'Erreur - $detail';
  }

  @override
  String get backupStatusIdle => 'Inactif';

  @override
  String get timeJustNow => 'à l\'instant';

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
  String get backupNotificationPreparing => 'Préparation de la sauvegarde...';

  @override
  String get backupNotificationInProgress => 'Sauvegarde en cours';

  @override
  String backupNotificationProgress(int processed, int total) {
    return '$processed / $total éléments sauvegardes';
  }

  @override
  String get backupNotificationComplete => 'Sauvegarde terminee';

  @override
  String get backupNotificationFailed => 'Échec de la sauvegarde';

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
      'Préparation de l\'analyse des doublons...';

  @override
  String notificationDuplicateScanProgress(int scanned, int total) {
    return 'Analyse de $scanned / $total photos...';
  }

  @override
  String get notificationDuplicateScanNoneTitle => 'Aucun doublon trouvé';

  @override
  String get notificationDuplicateScanNoneBody =>
      'Aucune photo quasi identique trouvée dans votre bibliothèque.';

  @override
  String get notificationDuplicateScanCompleteTitle =>
      'Analyse des doublons terminee';

  @override
  String notificationDuplicateScanCompleteBody(int count, String Found) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count groupes de doublons trouvés',
      one: '1 groupe de doublons trouve',
    );
    return '$_temp0';
  }

  @override
  String get notificationDuplicateScanFailedTitle =>
      'Échec de l\'analyse des doublons';

  @override
  String get notificationDuplicateScanFailedBody =>
      'Impossible de terminer l\'analyse. Ouvrez Doublons pour réessayer.';

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
    return '$name trouvé';
  }

  @override
  String get backupDetailNoDesktopFound => 'Aucun bureau trouvé sur le réseau';

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
    return 'Reconciliation de $count éléments';
  }

  @override
  String get backupDetailReconciling => 'Reconciliation avec le bureau';

  @override
  String backupDetailBackingUpItems(int count) {
    return 'Sauvegarde de $count éléments';
  }

  @override
  String get backupDetailCheckingItems => 'Recherche d\'éléments a sauvegarder';

  @override
  String get backupDetailDesktopDisconnected => 'Bureau devenu indisponible';

  @override
  String get backupDetailWaitingForSync =>
      'En attente de la fin de la synchronisation...';

  @override
  String backupDetailFoundMoreItems(int count) {
    return '$count éléments supplementaires a sauvegarder';
  }

  @override
  String get backupDetailAllBackedUp => 'Toutes les photos sont sauvegardees';

  @override
  String backupDetailBackedUpItems(int count) {
    return '$count éléments sauvegardes';
  }

  @override
  String backupDetailBackingUpBatch(int batch, int count) {
    return 'Sauvegarde du lot $batch ($count éléments)';
  }

  @override
  String backupDetailBackingUpFile(String folder, String name) {
    return 'Sauvegarde de $folder/$name';
  }

  @override
  String get backupDetailBackupFailed => 'Échec de la sauvegarde';

  @override
  String backupDetailReconcilingProgress(int count) {
    return 'Reconciliation de $count éléments...';
  }

  @override
  String get backupDetailReconcileFailed => 'Échec de la reconciliation';

  @override
  String backupDetailVerifyingItems(int count) {
    return 'Verification de $count éléments sauvegardes...';
  }

  @override
  String get backupDetailVerifyFailed => 'Échec de la verification';

  @override
  String get backupDetailDesktopDisconnectedDuringReconcile =>
      'Bureau devenu indisponible pendant la reconciliation';

  @override
  String get backupDetailDesktopDisconnectedDuringVerify =>
      'Bureau devenu indisponible pendant la verification';

  @override
  String get backupDetailDesktopDisconnectedDuringBackup =>
      'Bureau déconnecté pendant la sauvegarde';

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
  String get backupPhasePreparing => 'Préparation du fichier...';

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
    return '$succeeded éléments sauvegardes, $failed en échec';
  }

  @override
  String get backupCloseBlockedTitle => 'Sauvegarde en cours';

  @override
  String get backupCloseBlockedMessage =>
      'Votre telephone envoie encore des photos. Quitter maintenant peut interrompre la sauvegarde.';

  @override
  String get backupCloseWait => 'Attendre la fin';

  @override
  String get backupCloseQuitAnyway => 'Quitter quand meme';

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

  @override
  String get settingsOrganizeGestures => 'Gestes d\'organisation';

  @override
  String get settingsOrganizeGesturesSubtitle =>
      'Reassigner les glissements gauche, droite, haut et bas';

  @override
  String get settingsOrganizeGesturesReset => 'Réinitialiser';

  @override
  String settingsOrganizeGesturesSwapHint(String direction) {
    return 'Echange avec $direction';
  }

  @override
  String get settingsOrganizeGesturesDuplicateError =>
      'Chaque direction doit avoir une action unique';

  @override
  String get organizeActionTrash => 'Corbeille';

  @override
  String get organizeActionFavorite => 'Favori';

  @override
  String get organizeActionKeep => 'Garder';

  @override
  String get organizeActionMove => 'Déplacer';

  @override
  String get organizeDirectionLeft => 'Glisser a gauche';

  @override
  String get organizeDirectionRight => 'Glisser a droite';

  @override
  String get organizeDirectionUp => 'Glisser vers le haut';

  @override
  String get organizeDirectionDown => 'Glisser vers le bas';

  @override
  String organizeCardSemanticLabel(String name, String folder) {
    return '$name de $folder';
  }

  @override
  String organizeSwipeHintLeft(String action) {
    return 'Glisser a gauche pour $action';
  }

  @override
  String organizeSwipeHintRight(String action) {
    return 'Glisser a droite pour $action';
  }

  @override
  String organizeSwipeHintUp(String action) {
    return 'Glisser vers le haut pour $action';
  }

  @override
  String organizeSwipeHintDown(String action) {
    return 'Glisser vers le bas pour $action';
  }

  @override
  String get mediaKindPhoto => 'Photo';

  @override
  String feedPostSemanticLabel(String folder, String kind, String name) {
    return 'Publication de $folder, $kind $name';
  }

  @override
  String feedPostOpenFolderSemanticLabel(String folder) {
    return 'Ouvrir l\'album $folder';
  }

  @override
  String feedPostOpenMediaSemanticLabel(String kind) {
    return 'Ouvrir $kind';
  }

  @override
  String get feedPostDoubleTapFavoriteHint =>
      'Appuyer deux fois pour ajouter aux favoris';
}
