# Project verification

- Run `flutter analyze` for static analysis and `flutter test` for the full test suite.
- Run focused tests with `flutter test <test-file>` while iterating.
- Format changed Dart code with `dart format`, then check it with `dart format --output=none --set-exit-if-changed <files>`.
- Unit tests can use `AppDatabase.forTesting(NativeDatabase.memory())` for isolated Drift storage and `SharedPreferences.setMockInitialValues` for preferences.
- Platform-independent sync tests implement `MediaScanSource` instead of invoking photo-manager or filesystem scanning.

# Provider boundaries

- `lib/app/providers.dart` is a compatibility export facade. Internal controllers and provider modules should import focused provider libraries rather than depending back on that facade.
- `lib/shared/pagination/paginated_list_notifier.dart` is a compatibility export facade. Pagination implementation lives in `media_pagination_providers.dart`; app-wide refresh coordination lives in `lib/app/providers/feed_refresh_providers.dart`.
- Keep device scan coordination in `MediaSyncService`, sync persistence in `MediaSyncRepository`, and scanned-row merge rules in `media_sync_merge.dart`.
