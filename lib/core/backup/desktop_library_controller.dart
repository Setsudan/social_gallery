import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/core/backup/backup_protocol.dart';
import 'package:social_gallery/core/backup/desktop_availability_service.dart';
import 'package:social_gallery/core/backup/desktop_library_client.dart';
import 'package:social_gallery/core/backup/vault_password_store.dart';
import 'package:social_gallery/data/repositories/preferences_repository.dart';

enum DesktopLibraryPhase {
  idle,
  loading,
  ready,
  error,
}

class DesktopLibraryState {
  const DesktopLibraryState({
    this.phase = DesktopLibraryPhase.idle,
    this.folders = const [],
    this.items = const [],
    this.selectedFolder,
    this.error,
    this.vaultToken,
    this.vaultUnlocked = false,
    this.totalCount = 0,
  });

  final DesktopLibraryPhase phase;
  final List<LibraryCatalogFolder> folders;
  final List<LibraryCatalogItem> items;
  final String? selectedFolder;
  final String? error;
  final String? vaultToken;
  final bool vaultUnlocked;
  final int totalCount;

  DesktopLibraryState copyWith({
    DesktopLibraryPhase? phase,
    List<LibraryCatalogFolder>? folders,
    List<LibraryCatalogItem>? items,
    String? selectedFolder,
    String? error,
    String? vaultToken,
    bool? vaultUnlocked,
    int? totalCount,
    bool clearError = false,
    bool clearVaultToken = false,
  }) {
    return DesktopLibraryState(
      phase: phase ?? this.phase,
      folders: folders ?? this.folders,
      items: items ?? this.items,
      selectedFolder: selectedFolder ?? this.selectedFolder,
      error: clearError ? null : (error ?? this.error),
      vaultToken: clearVaultToken ? null : (vaultToken ?? this.vaultToken),
      vaultUnlocked: vaultUnlocked ?? this.vaultUnlocked,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

class DesktopLibraryController extends StateNotifier<DesktopLibraryState> {
  DesktopLibraryController(
    this._prefs,
    this._availability,
    this._vaultPasswordStore,
  ) : super(const DesktopLibraryState());

  final PreferencesRepository _prefs;
  final DesktopAvailabilityService _availability;
  final VaultPasswordStore _vaultPasswordStore;

  DesktopLibraryClient? _client;

  Future<DesktopLibraryClient?> _connect() async {
    final availability = await _availability.check();
    if (!availability.available ||
        availability.host == null ||
        availability.port == null ||
        _prefs.backupAuthToken == null) {
      state = state.copyWith(
        phase: DesktopLibraryPhase.error,
        error: availability.reason ?? 'Desktop unavailable',
      );
      return null;
    }

    _client?.close();
    _client = DesktopLibraryClient(
      host: availability.host!,
      port: availability.port!,
      authToken: _prefs.backupAuthToken!,
    );
    return _client;
  }

  Future<void> loadCatalog({String? folderName}) async {
    state = state.copyWith(
      phase: DesktopLibraryPhase.loading,
      clearError: true,
      selectedFolder: folderName,
    );

    final client = await _connect();
    if (client == null) return;

    final catalog = await client.fetchCatalog(folderName: folderName);
    if (catalog == null) {
      state = state.copyWith(
        phase: DesktopLibraryPhase.error,
        error: 'Failed to load archive',
      );
      return;
    }

    state = state.copyWith(
      phase: DesktopLibraryPhase.ready,
      folders: catalog.folders,
      items: catalog.items,
      totalCount: catalog.totalCount,
    );
  }

  Future<bool> unlockVault({String? password}) async {
    final resolved = password ?? await _vaultPasswordStore.readPassword();
    if (resolved == null || resolved.isEmpty) {
      state = state.copyWith(
        error: 'Vault password required',
      );
      return false;
    }

    final client = await _connect();
    if (client == null) return false;

    final response = await client.unlockVault(resolved);
    if (response == null || response.vaultToken.isEmpty) {
      state = state.copyWith(error: 'Invalid vault password');
      return false;
    }

    await _vaultPasswordStore.savePassword(resolved);
    state = state.copyWith(
      vaultToken: response.vaultToken,
      vaultUnlocked: true,
      clearError: true,
    );
    return true;
  }

  Future<Uint8List?> loadThumbnail(LibraryCatalogItem item) async {
    final client = _client ?? await _connect();
    if (client == null) return null;

    if (item.isVault && !state.vaultUnlocked) {
      final unlocked = await unlockVault();
      if (!unlocked) return null;
    }

    final bytes = await client.fetchThumbnail(
      item.mediaId,
      vaultToken: item.isVault ? state.vaultToken : null,
    );
    return bytes == null ? null : Uint8List.fromList(bytes);
  }

  Future<LibraryStreamInitResponse?> initStream(LibraryCatalogItem item) async {
    final client = _client ?? await _connect();
    if (client == null) return null;

    if (item.isVault && !state.vaultUnlocked) {
      final unlocked = await unlockVault();
      if (!unlocked) return null;
    }

    return client.initStream(
      mediaId: item.mediaId,
      vaultToken: item.isVault ? state.vaultToken : null,
    );
  }

  DesktopLibraryClient? get client => _client;

  @override
  void dispose() {
    _client?.close();
    super.dispose();
  }
}
