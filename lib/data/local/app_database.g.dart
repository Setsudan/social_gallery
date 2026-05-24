// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $FoldersTable extends Folders with TableInfo<$FoldersTable, Folder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoldersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mediaCountMeta = const VerificationMeta(
    'mediaCount',
  );
  @override
  late final GeneratedColumn<int> mediaCount = GeneratedColumn<int>(
    'media_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastModifiedMeta = const VerificationMeta(
    'lastModified',
  );
  @override
  late final GeneratedColumn<int> lastModified = GeneratedColumn<int>(
    'last_modified',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _coverImageUriMeta = const VerificationMeta(
    'coverImageUri',
  );
  @override
  late final GeneratedColumn<String> coverImageUri = GeneratedColumn<String>(
    'cover_image_uri',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isHiddenMeta = const VerificationMeta(
    'isHidden',
  );
  @override
  late final GeneratedColumn<bool> isHidden = GeneratedColumn<bool>(
    'is_hidden',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_hidden" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isPinnedMeta = const VerificationMeta(
    'isPinned',
  );
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
    'is_pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _customCoverUriMeta = const VerificationMeta(
    'customCoverUri',
  );
  @override
  late final GeneratedColumn<String> customCoverUri = GeneratedColumn<String>(
    'custom_cover_uri',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _followStatusMeta = const VerificationMeta(
    'followStatus',
  );
  @override
  late final GeneratedColumn<String> followStatus = GeneratedColumn<String>(
    'follow_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('HOME_FEED'),
  );
  static const VerificationMeta _showInStoriesMeta = const VerificationMeta(
    'showInStories',
  );
  @override
  late final GeneratedColumn<bool> showInStories = GeneratedColumn<bool>(
    'show_in_stories',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_in_stories" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _isBiometricLockedMeta = const VerificationMeta(
    'isBiometricLocked',
  );
  @override
  late final GeneratedColumn<bool> isBiometricLocked = GeneratedColumn<bool>(
    'is_biometric_locked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_biometric_locked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _biographyMeta = const VerificationMeta(
    'biography',
  );
  @override
  late final GeneratedColumn<String> biography = GeneratedColumn<String>(
    'biography',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _storyLastViewedTimeMeta =
      const VerificationMeta('storyLastViewedTime');
  @override
  late final GeneratedColumn<int> storyLastViewedTime = GeneratedColumn<int>(
    'story_last_viewed_time',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    path,
    name,
    mediaCount,
    lastModified,
    coverImageUri,
    isHidden,
    isPinned,
    sortOrder,
    customCoverUri,
    followStatus,
    showInStories,
    isBiometricLocked,
    biography,
    storyLastViewedTime,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'folders';
  @override
  VerificationContext validateIntegrity(
    Insertable<Folder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('media_count')) {
      context.handle(
        _mediaCountMeta,
        mediaCount.isAcceptableOrUnknown(data['media_count']!, _mediaCountMeta),
      );
    }
    if (data.containsKey('last_modified')) {
      context.handle(
        _lastModifiedMeta,
        lastModified.isAcceptableOrUnknown(
          data['last_modified']!,
          _lastModifiedMeta,
        ),
      );
    }
    if (data.containsKey('cover_image_uri')) {
      context.handle(
        _coverImageUriMeta,
        coverImageUri.isAcceptableOrUnknown(
          data['cover_image_uri']!,
          _coverImageUriMeta,
        ),
      );
    }
    if (data.containsKey('is_hidden')) {
      context.handle(
        _isHiddenMeta,
        isHidden.isAcceptableOrUnknown(data['is_hidden']!, _isHiddenMeta),
      );
    }
    if (data.containsKey('is_pinned')) {
      context.handle(
        _isPinnedMeta,
        isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('custom_cover_uri')) {
      context.handle(
        _customCoverUriMeta,
        customCoverUri.isAcceptableOrUnknown(
          data['custom_cover_uri']!,
          _customCoverUriMeta,
        ),
      );
    }
    if (data.containsKey('follow_status')) {
      context.handle(
        _followStatusMeta,
        followStatus.isAcceptableOrUnknown(
          data['follow_status']!,
          _followStatusMeta,
        ),
      );
    }
    if (data.containsKey('show_in_stories')) {
      context.handle(
        _showInStoriesMeta,
        showInStories.isAcceptableOrUnknown(
          data['show_in_stories']!,
          _showInStoriesMeta,
        ),
      );
    }
    if (data.containsKey('is_biometric_locked')) {
      context.handle(
        _isBiometricLockedMeta,
        isBiometricLocked.isAcceptableOrUnknown(
          data['is_biometric_locked']!,
          _isBiometricLockedMeta,
        ),
      );
    }
    if (data.containsKey('biography')) {
      context.handle(
        _biographyMeta,
        biography.isAcceptableOrUnknown(data['biography']!, _biographyMeta),
      );
    }
    if (data.containsKey('story_last_viewed_time')) {
      context.handle(
        _storyLastViewedTimeMeta,
        storyLastViewedTime.isAcceptableOrUnknown(
          data['story_last_viewed_time']!,
          _storyLastViewedTimeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {path};
  @override
  Folder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Folder(
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      mediaCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}media_count'],
      )!,
      lastModified: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_modified'],
      )!,
      coverImageUri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_image_uri'],
      ),
      isHidden: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_hidden'],
      )!,
      isPinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pinned'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      customCoverUri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_cover_uri'],
      ),
      followStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}follow_status'],
      )!,
      showInStories: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_in_stories'],
      )!,
      isBiometricLocked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_biometric_locked'],
      )!,
      biography: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}biography'],
      ),
      storyLastViewedTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}story_last_viewed_time'],
      )!,
    );
  }

  @override
  $FoldersTable createAlias(String alias) {
    return $FoldersTable(attachedDatabase, alias);
  }
}

class Folder extends DataClass implements Insertable<Folder> {
  final String path;
  final String name;
  final int mediaCount;
  final int lastModified;
  final String? coverImageUri;
  final bool isHidden;
  final bool isPinned;
  final int sortOrder;
  final String? customCoverUri;
  final String followStatus;
  final bool showInStories;
  final bool isBiometricLocked;
  final String? biography;
  final int storyLastViewedTime;
  const Folder({
    required this.path,
    required this.name,
    required this.mediaCount,
    required this.lastModified,
    this.coverImageUri,
    required this.isHidden,
    required this.isPinned,
    required this.sortOrder,
    this.customCoverUri,
    required this.followStatus,
    required this.showInStories,
    required this.isBiometricLocked,
    this.biography,
    required this.storyLastViewedTime,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['path'] = Variable<String>(path);
    map['name'] = Variable<String>(name);
    map['media_count'] = Variable<int>(mediaCount);
    map['last_modified'] = Variable<int>(lastModified);
    if (!nullToAbsent || coverImageUri != null) {
      map['cover_image_uri'] = Variable<String>(coverImageUri);
    }
    map['is_hidden'] = Variable<bool>(isHidden);
    map['is_pinned'] = Variable<bool>(isPinned);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || customCoverUri != null) {
      map['custom_cover_uri'] = Variable<String>(customCoverUri);
    }
    map['follow_status'] = Variable<String>(followStatus);
    map['show_in_stories'] = Variable<bool>(showInStories);
    map['is_biometric_locked'] = Variable<bool>(isBiometricLocked);
    if (!nullToAbsent || biography != null) {
      map['biography'] = Variable<String>(biography);
    }
    map['story_last_viewed_time'] = Variable<int>(storyLastViewedTime);
    return map;
  }

  FoldersCompanion toCompanion(bool nullToAbsent) {
    return FoldersCompanion(
      path: Value(path),
      name: Value(name),
      mediaCount: Value(mediaCount),
      lastModified: Value(lastModified),
      coverImageUri: coverImageUri == null && nullToAbsent
          ? const Value.absent()
          : Value(coverImageUri),
      isHidden: Value(isHidden),
      isPinned: Value(isPinned),
      sortOrder: Value(sortOrder),
      customCoverUri: customCoverUri == null && nullToAbsent
          ? const Value.absent()
          : Value(customCoverUri),
      followStatus: Value(followStatus),
      showInStories: Value(showInStories),
      isBiometricLocked: Value(isBiometricLocked),
      biography: biography == null && nullToAbsent
          ? const Value.absent()
          : Value(biography),
      storyLastViewedTime: Value(storyLastViewedTime),
    );
  }

  factory Folder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Folder(
      path: serializer.fromJson<String>(json['path']),
      name: serializer.fromJson<String>(json['name']),
      mediaCount: serializer.fromJson<int>(json['mediaCount']),
      lastModified: serializer.fromJson<int>(json['lastModified']),
      coverImageUri: serializer.fromJson<String?>(json['coverImageUri']),
      isHidden: serializer.fromJson<bool>(json['isHidden']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      customCoverUri: serializer.fromJson<String?>(json['customCoverUri']),
      followStatus: serializer.fromJson<String>(json['followStatus']),
      showInStories: serializer.fromJson<bool>(json['showInStories']),
      isBiometricLocked: serializer.fromJson<bool>(json['isBiometricLocked']),
      biography: serializer.fromJson<String?>(json['biography']),
      storyLastViewedTime: serializer.fromJson<int>(
        json['storyLastViewedTime'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'path': serializer.toJson<String>(path),
      'name': serializer.toJson<String>(name),
      'mediaCount': serializer.toJson<int>(mediaCount),
      'lastModified': serializer.toJson<int>(lastModified),
      'coverImageUri': serializer.toJson<String?>(coverImageUri),
      'isHidden': serializer.toJson<bool>(isHidden),
      'isPinned': serializer.toJson<bool>(isPinned),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'customCoverUri': serializer.toJson<String?>(customCoverUri),
      'followStatus': serializer.toJson<String>(followStatus),
      'showInStories': serializer.toJson<bool>(showInStories),
      'isBiometricLocked': serializer.toJson<bool>(isBiometricLocked),
      'biography': serializer.toJson<String?>(biography),
      'storyLastViewedTime': serializer.toJson<int>(storyLastViewedTime),
    };
  }

  Folder copyWith({
    String? path,
    String? name,
    int? mediaCount,
    int? lastModified,
    Value<String?> coverImageUri = const Value.absent(),
    bool? isHidden,
    bool? isPinned,
    int? sortOrder,
    Value<String?> customCoverUri = const Value.absent(),
    String? followStatus,
    bool? showInStories,
    bool? isBiometricLocked,
    Value<String?> biography = const Value.absent(),
    int? storyLastViewedTime,
  }) => Folder(
    path: path ?? this.path,
    name: name ?? this.name,
    mediaCount: mediaCount ?? this.mediaCount,
    lastModified: lastModified ?? this.lastModified,
    coverImageUri: coverImageUri.present
        ? coverImageUri.value
        : this.coverImageUri,
    isHidden: isHidden ?? this.isHidden,
    isPinned: isPinned ?? this.isPinned,
    sortOrder: sortOrder ?? this.sortOrder,
    customCoverUri: customCoverUri.present
        ? customCoverUri.value
        : this.customCoverUri,
    followStatus: followStatus ?? this.followStatus,
    showInStories: showInStories ?? this.showInStories,
    isBiometricLocked: isBiometricLocked ?? this.isBiometricLocked,
    biography: biography.present ? biography.value : this.biography,
    storyLastViewedTime: storyLastViewedTime ?? this.storyLastViewedTime,
  );
  Folder copyWithCompanion(FoldersCompanion data) {
    return Folder(
      path: data.path.present ? data.path.value : this.path,
      name: data.name.present ? data.name.value : this.name,
      mediaCount: data.mediaCount.present
          ? data.mediaCount.value
          : this.mediaCount,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
      coverImageUri: data.coverImageUri.present
          ? data.coverImageUri.value
          : this.coverImageUri,
      isHidden: data.isHidden.present ? data.isHidden.value : this.isHidden,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      customCoverUri: data.customCoverUri.present
          ? data.customCoverUri.value
          : this.customCoverUri,
      followStatus: data.followStatus.present
          ? data.followStatus.value
          : this.followStatus,
      showInStories: data.showInStories.present
          ? data.showInStories.value
          : this.showInStories,
      isBiometricLocked: data.isBiometricLocked.present
          ? data.isBiometricLocked.value
          : this.isBiometricLocked,
      biography: data.biography.present ? data.biography.value : this.biography,
      storyLastViewedTime: data.storyLastViewedTime.present
          ? data.storyLastViewedTime.value
          : this.storyLastViewedTime,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Folder(')
          ..write('path: $path, ')
          ..write('name: $name, ')
          ..write('mediaCount: $mediaCount, ')
          ..write('lastModified: $lastModified, ')
          ..write('coverImageUri: $coverImageUri, ')
          ..write('isHidden: $isHidden, ')
          ..write('isPinned: $isPinned, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('customCoverUri: $customCoverUri, ')
          ..write('followStatus: $followStatus, ')
          ..write('showInStories: $showInStories, ')
          ..write('isBiometricLocked: $isBiometricLocked, ')
          ..write('biography: $biography, ')
          ..write('storyLastViewedTime: $storyLastViewedTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    path,
    name,
    mediaCount,
    lastModified,
    coverImageUri,
    isHidden,
    isPinned,
    sortOrder,
    customCoverUri,
    followStatus,
    showInStories,
    isBiometricLocked,
    biography,
    storyLastViewedTime,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Folder &&
          other.path == this.path &&
          other.name == this.name &&
          other.mediaCount == this.mediaCount &&
          other.lastModified == this.lastModified &&
          other.coverImageUri == this.coverImageUri &&
          other.isHidden == this.isHidden &&
          other.isPinned == this.isPinned &&
          other.sortOrder == this.sortOrder &&
          other.customCoverUri == this.customCoverUri &&
          other.followStatus == this.followStatus &&
          other.showInStories == this.showInStories &&
          other.isBiometricLocked == this.isBiometricLocked &&
          other.biography == this.biography &&
          other.storyLastViewedTime == this.storyLastViewedTime);
}

class FoldersCompanion extends UpdateCompanion<Folder> {
  final Value<String> path;
  final Value<String> name;
  final Value<int> mediaCount;
  final Value<int> lastModified;
  final Value<String?> coverImageUri;
  final Value<bool> isHidden;
  final Value<bool> isPinned;
  final Value<int> sortOrder;
  final Value<String?> customCoverUri;
  final Value<String> followStatus;
  final Value<bool> showInStories;
  final Value<bool> isBiometricLocked;
  final Value<String?> biography;
  final Value<int> storyLastViewedTime;
  final Value<int> rowid;
  const FoldersCompanion({
    this.path = const Value.absent(),
    this.name = const Value.absent(),
    this.mediaCount = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.coverImageUri = const Value.absent(),
    this.isHidden = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.customCoverUri = const Value.absent(),
    this.followStatus = const Value.absent(),
    this.showInStories = const Value.absent(),
    this.isBiometricLocked = const Value.absent(),
    this.biography = const Value.absent(),
    this.storyLastViewedTime = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FoldersCompanion.insert({
    required String path,
    required String name,
    this.mediaCount = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.coverImageUri = const Value.absent(),
    this.isHidden = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.customCoverUri = const Value.absent(),
    this.followStatus = const Value.absent(),
    this.showInStories = const Value.absent(),
    this.isBiometricLocked = const Value.absent(),
    this.biography = const Value.absent(),
    this.storyLastViewedTime = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : path = Value(path),
       name = Value(name);
  static Insertable<Folder> custom({
    Expression<String>? path,
    Expression<String>? name,
    Expression<int>? mediaCount,
    Expression<int>? lastModified,
    Expression<String>? coverImageUri,
    Expression<bool>? isHidden,
    Expression<bool>? isPinned,
    Expression<int>? sortOrder,
    Expression<String>? customCoverUri,
    Expression<String>? followStatus,
    Expression<bool>? showInStories,
    Expression<bool>? isBiometricLocked,
    Expression<String>? biography,
    Expression<int>? storyLastViewedTime,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (path != null) 'path': path,
      if (name != null) 'name': name,
      if (mediaCount != null) 'media_count': mediaCount,
      if (lastModified != null) 'last_modified': lastModified,
      if (coverImageUri != null) 'cover_image_uri': coverImageUri,
      if (isHidden != null) 'is_hidden': isHidden,
      if (isPinned != null) 'is_pinned': isPinned,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (customCoverUri != null) 'custom_cover_uri': customCoverUri,
      if (followStatus != null) 'follow_status': followStatus,
      if (showInStories != null) 'show_in_stories': showInStories,
      if (isBiometricLocked != null) 'is_biometric_locked': isBiometricLocked,
      if (biography != null) 'biography': biography,
      if (storyLastViewedTime != null)
        'story_last_viewed_time': storyLastViewedTime,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FoldersCompanion copyWith({
    Value<String>? path,
    Value<String>? name,
    Value<int>? mediaCount,
    Value<int>? lastModified,
    Value<String?>? coverImageUri,
    Value<bool>? isHidden,
    Value<bool>? isPinned,
    Value<int>? sortOrder,
    Value<String?>? customCoverUri,
    Value<String>? followStatus,
    Value<bool>? showInStories,
    Value<bool>? isBiometricLocked,
    Value<String?>? biography,
    Value<int>? storyLastViewedTime,
    Value<int>? rowid,
  }) {
    return FoldersCompanion(
      path: path ?? this.path,
      name: name ?? this.name,
      mediaCount: mediaCount ?? this.mediaCount,
      lastModified: lastModified ?? this.lastModified,
      coverImageUri: coverImageUri ?? this.coverImageUri,
      isHidden: isHidden ?? this.isHidden,
      isPinned: isPinned ?? this.isPinned,
      sortOrder: sortOrder ?? this.sortOrder,
      customCoverUri: customCoverUri ?? this.customCoverUri,
      followStatus: followStatus ?? this.followStatus,
      showInStories: showInStories ?? this.showInStories,
      isBiometricLocked: isBiometricLocked ?? this.isBiometricLocked,
      biography: biography ?? this.biography,
      storyLastViewedTime: storyLastViewedTime ?? this.storyLastViewedTime,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (mediaCount.present) {
      map['media_count'] = Variable<int>(mediaCount.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<int>(lastModified.value);
    }
    if (coverImageUri.present) {
      map['cover_image_uri'] = Variable<String>(coverImageUri.value);
    }
    if (isHidden.present) {
      map['is_hidden'] = Variable<bool>(isHidden.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (customCoverUri.present) {
      map['custom_cover_uri'] = Variable<String>(customCoverUri.value);
    }
    if (followStatus.present) {
      map['follow_status'] = Variable<String>(followStatus.value);
    }
    if (showInStories.present) {
      map['show_in_stories'] = Variable<bool>(showInStories.value);
    }
    if (isBiometricLocked.present) {
      map['is_biometric_locked'] = Variable<bool>(isBiometricLocked.value);
    }
    if (biography.present) {
      map['biography'] = Variable<String>(biography.value);
    }
    if (storyLastViewedTime.present) {
      map['story_last_viewed_time'] = Variable<int>(storyLastViewedTime.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoldersCompanion(')
          ..write('path: $path, ')
          ..write('name: $name, ')
          ..write('mediaCount: $mediaCount, ')
          ..write('lastModified: $lastModified, ')
          ..write('coverImageUri: $coverImageUri, ')
          ..write('isHidden: $isHidden, ')
          ..write('isPinned: $isPinned, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('customCoverUri: $customCoverUri, ')
          ..write('followStatus: $followStatus, ')
          ..write('showInStories: $showInStories, ')
          ..write('isBiometricLocked: $isBiometricLocked, ')
          ..write('biography: $biography, ')
          ..write('storyLastViewedTime: $storyLastViewedTime, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MediaItemsTable extends MediaItems
    with TableInfo<$MediaItemsTable, MediaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uriMeta = const VerificationMeta('uri');
  @override
  late final GeneratedColumn<String> uri = GeneratedColumn<String>(
    'uri',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _folderNameMeta = const VerificationMeta(
    'folderName',
  );
  @override
  late final GeneratedColumn<String> folderName = GeneratedColumn<String>(
    'folder_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _folderPathMeta = const VerificationMeta(
    'folderPath',
  );
  @override
  late final GeneratedColumn<String> folderPath = GeneratedColumn<String>(
    'folder_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateAddedMeta = const VerificationMeta(
    'dateAdded',
  );
  @override
  late final GeneratedColumn<int> dateAdded = GeneratedColumn<int>(
    'date_added',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateModifiedMeta = const VerificationMeta(
    'dateModified',
  );
  @override
  late final GeneratedColumn<int> dateModified = GeneratedColumn<int>(
    'date_modified',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateTakenMeta = const VerificationMeta(
    'dateTaken',
  );
  @override
  late final GeneratedColumn<int> dateTaken = GeneratedColumn<int>(
    'date_taken',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
    'size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _thumbnailUriMeta = const VerificationMeta(
    'thumbnailUri',
  );
  @override
  late final GeneratedColumn<String> thumbnailUri = GeneratedColumn<String>(
    'thumbnail_uri',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _videoDurationMeta = const VerificationMeta(
    'videoDuration',
  );
  @override
  late final GeneratedColumn<int> videoDuration = GeneratedColumn<int>(
    'video_duration',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastViewedAtMeta = const VerificationMeta(
    'lastViewedAt',
  );
  @override
  late final GeneratedColumn<int> lastViewedAt = GeneratedColumn<int>(
    'last_viewed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _backupStateMeta = const VerificationMeta(
    'backupState',
  );
  @override
  late final GeneratedColumn<int> backupState = GeneratedColumn<int>(
    'backup_state',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastSyncTimeMeta = const VerificationMeta(
    'lastSyncTime',
  );
  @override
  late final GeneratedColumn<int> lastSyncTime = GeneratedColumn<int>(
    'last_sync_time',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uri,
    displayName,
    folderName,
    folderPath,
    dateAdded,
    dateModified,
    dateTaken,
    size,
    mimeType,
    width,
    height,
    latitude,
    longitude,
    isFavorite,
    thumbnailUri,
    videoDuration,
    lastViewedAt,
    backupState,
    lastSyncTime,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<MediaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uri')) {
      context.handle(
        _uriMeta,
        uri.isAcceptableOrUnknown(data['uri']!, _uriMeta),
      );
    } else if (isInserting) {
      context.missing(_uriMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('folder_name')) {
      context.handle(
        _folderNameMeta,
        folderName.isAcceptableOrUnknown(data['folder_name']!, _folderNameMeta),
      );
    } else if (isInserting) {
      context.missing(_folderNameMeta);
    }
    if (data.containsKey('folder_path')) {
      context.handle(
        _folderPathMeta,
        folderPath.isAcceptableOrUnknown(data['folder_path']!, _folderPathMeta),
      );
    } else if (isInserting) {
      context.missing(_folderPathMeta);
    }
    if (data.containsKey('date_added')) {
      context.handle(
        _dateAddedMeta,
        dateAdded.isAcceptableOrUnknown(data['date_added']!, _dateAddedMeta),
      );
    } else if (isInserting) {
      context.missing(_dateAddedMeta);
    }
    if (data.containsKey('date_modified')) {
      context.handle(
        _dateModifiedMeta,
        dateModified.isAcceptableOrUnknown(
          data['date_modified']!,
          _dateModifiedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dateModifiedMeta);
    }
    if (data.containsKey('date_taken')) {
      context.handle(
        _dateTakenMeta,
        dateTaken.isAcceptableOrUnknown(data['date_taken']!, _dateTakenMeta),
      );
    }
    if (data.containsKey('size')) {
      context.handle(
        _sizeMeta,
        size.isAcceptableOrUnknown(data['size']!, _sizeMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('thumbnail_uri')) {
      context.handle(
        _thumbnailUriMeta,
        thumbnailUri.isAcceptableOrUnknown(
          data['thumbnail_uri']!,
          _thumbnailUriMeta,
        ),
      );
    }
    if (data.containsKey('video_duration')) {
      context.handle(
        _videoDurationMeta,
        videoDuration.isAcceptableOrUnknown(
          data['video_duration']!,
          _videoDurationMeta,
        ),
      );
    }
    if (data.containsKey('last_viewed_at')) {
      context.handle(
        _lastViewedAtMeta,
        lastViewedAt.isAcceptableOrUnknown(
          data['last_viewed_at']!,
          _lastViewedAtMeta,
        ),
      );
    }
    if (data.containsKey('backup_state')) {
      context.handle(
        _backupStateMeta,
        backupState.isAcceptableOrUnknown(
          data['backup_state']!,
          _backupStateMeta,
        ),
      );
    }
    if (data.containsKey('last_sync_time')) {
      context.handle(
        _lastSyncTimeMeta,
        lastSyncTime.isAcceptableOrUnknown(
          data['last_sync_time']!,
          _lastSyncTimeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MediaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uri'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      folderName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder_name'],
      )!,
      folderPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder_path'],
      )!,
      dateAdded: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date_added'],
      )!,
      dateModified: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date_modified'],
      )!,
      dateTaken: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date_taken'],
      ),
      size: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      ),
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      ),
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      thumbnailUri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_uri'],
      ),
      videoDuration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}video_duration'],
      ),
      lastViewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_viewed_at'],
      ),
      backupState: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}backup_state'],
      )!,
      lastSyncTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_sync_time'],
      ),
    );
  }

  @override
  $MediaItemsTable createAlias(String alias) {
    return $MediaItemsTable(attachedDatabase, alias);
  }
}

class MediaRow extends DataClass implements Insertable<MediaRow> {
  final int id;
  final String uri;
  final String displayName;
  final String folderName;
  final String folderPath;
  final int dateAdded;
  final int dateModified;
  final int? dateTaken;
  final int size;
  final String mimeType;
  final int? width;
  final int? height;
  final double? latitude;
  final double? longitude;
  final bool isFavorite;
  final String? thumbnailUri;
  final int? videoDuration;
  final int? lastViewedAt;
  final int backupState;
  final int? lastSyncTime;
  const MediaRow({
    required this.id,
    required this.uri,
    required this.displayName,
    required this.folderName,
    required this.folderPath,
    required this.dateAdded,
    required this.dateModified,
    this.dateTaken,
    required this.size,
    required this.mimeType,
    this.width,
    this.height,
    this.latitude,
    this.longitude,
    required this.isFavorite,
    this.thumbnailUri,
    this.videoDuration,
    this.lastViewedAt,
    required this.backupState,
    this.lastSyncTime,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uri'] = Variable<String>(uri);
    map['display_name'] = Variable<String>(displayName);
    map['folder_name'] = Variable<String>(folderName);
    map['folder_path'] = Variable<String>(folderPath);
    map['date_added'] = Variable<int>(dateAdded);
    map['date_modified'] = Variable<int>(dateModified);
    if (!nullToAbsent || dateTaken != null) {
      map['date_taken'] = Variable<int>(dateTaken);
    }
    map['size'] = Variable<int>(size);
    map['mime_type'] = Variable<String>(mimeType);
    if (!nullToAbsent || width != null) {
      map['width'] = Variable<int>(width);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<int>(height);
    }
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    if (!nullToAbsent || thumbnailUri != null) {
      map['thumbnail_uri'] = Variable<String>(thumbnailUri);
    }
    if (!nullToAbsent || videoDuration != null) {
      map['video_duration'] = Variable<int>(videoDuration);
    }
    if (!nullToAbsent || lastViewedAt != null) {
      map['last_viewed_at'] = Variable<int>(lastViewedAt);
    }
    map['backup_state'] = Variable<int>(backupState);
    if (!nullToAbsent || lastSyncTime != null) {
      map['last_sync_time'] = Variable<int>(lastSyncTime);
    }
    return map;
  }

  MediaItemsCompanion toCompanion(bool nullToAbsent) {
    return MediaItemsCompanion(
      id: Value(id),
      uri: Value(uri),
      displayName: Value(displayName),
      folderName: Value(folderName),
      folderPath: Value(folderPath),
      dateAdded: Value(dateAdded),
      dateModified: Value(dateModified),
      dateTaken: dateTaken == null && nullToAbsent
          ? const Value.absent()
          : Value(dateTaken),
      size: Value(size),
      mimeType: Value(mimeType),
      width: width == null && nullToAbsent
          ? const Value.absent()
          : Value(width),
      height: height == null && nullToAbsent
          ? const Value.absent()
          : Value(height),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      isFavorite: Value(isFavorite),
      thumbnailUri: thumbnailUri == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailUri),
      videoDuration: videoDuration == null && nullToAbsent
          ? const Value.absent()
          : Value(videoDuration),
      lastViewedAt: lastViewedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastViewedAt),
      backupState: Value(backupState),
      lastSyncTime: lastSyncTime == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncTime),
    );
  }

  factory MediaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaRow(
      id: serializer.fromJson<int>(json['id']),
      uri: serializer.fromJson<String>(json['uri']),
      displayName: serializer.fromJson<String>(json['displayName']),
      folderName: serializer.fromJson<String>(json['folderName']),
      folderPath: serializer.fromJson<String>(json['folderPath']),
      dateAdded: serializer.fromJson<int>(json['dateAdded']),
      dateModified: serializer.fromJson<int>(json['dateModified']),
      dateTaken: serializer.fromJson<int?>(json['dateTaken']),
      size: serializer.fromJson<int>(json['size']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      width: serializer.fromJson<int?>(json['width']),
      height: serializer.fromJson<int?>(json['height']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      thumbnailUri: serializer.fromJson<String?>(json['thumbnailUri']),
      videoDuration: serializer.fromJson<int?>(json['videoDuration']),
      lastViewedAt: serializer.fromJson<int?>(json['lastViewedAt']),
      backupState: serializer.fromJson<int>(json['backupState']),
      lastSyncTime: serializer.fromJson<int?>(json['lastSyncTime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uri': serializer.toJson<String>(uri),
      'displayName': serializer.toJson<String>(displayName),
      'folderName': serializer.toJson<String>(folderName),
      'folderPath': serializer.toJson<String>(folderPath),
      'dateAdded': serializer.toJson<int>(dateAdded),
      'dateModified': serializer.toJson<int>(dateModified),
      'dateTaken': serializer.toJson<int?>(dateTaken),
      'size': serializer.toJson<int>(size),
      'mimeType': serializer.toJson<String>(mimeType),
      'width': serializer.toJson<int?>(width),
      'height': serializer.toJson<int?>(height),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'thumbnailUri': serializer.toJson<String?>(thumbnailUri),
      'videoDuration': serializer.toJson<int?>(videoDuration),
      'lastViewedAt': serializer.toJson<int?>(lastViewedAt),
      'backupState': serializer.toJson<int>(backupState),
      'lastSyncTime': serializer.toJson<int?>(lastSyncTime),
    };
  }

  MediaRow copyWith({
    int? id,
    String? uri,
    String? displayName,
    String? folderName,
    String? folderPath,
    int? dateAdded,
    int? dateModified,
    Value<int?> dateTaken = const Value.absent(),
    int? size,
    String? mimeType,
    Value<int?> width = const Value.absent(),
    Value<int?> height = const Value.absent(),
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    bool? isFavorite,
    Value<String?> thumbnailUri = const Value.absent(),
    Value<int?> videoDuration = const Value.absent(),
    Value<int?> lastViewedAt = const Value.absent(),
    int? backupState,
    Value<int?> lastSyncTime = const Value.absent(),
  }) => MediaRow(
    id: id ?? this.id,
    uri: uri ?? this.uri,
    displayName: displayName ?? this.displayName,
    folderName: folderName ?? this.folderName,
    folderPath: folderPath ?? this.folderPath,
    dateAdded: dateAdded ?? this.dateAdded,
    dateModified: dateModified ?? this.dateModified,
    dateTaken: dateTaken.present ? dateTaken.value : this.dateTaken,
    size: size ?? this.size,
    mimeType: mimeType ?? this.mimeType,
    width: width.present ? width.value : this.width,
    height: height.present ? height.value : this.height,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    isFavorite: isFavorite ?? this.isFavorite,
    thumbnailUri: thumbnailUri.present ? thumbnailUri.value : this.thumbnailUri,
    videoDuration: videoDuration.present
        ? videoDuration.value
        : this.videoDuration,
    lastViewedAt: lastViewedAt.present ? lastViewedAt.value : this.lastViewedAt,
    backupState: backupState ?? this.backupState,
    lastSyncTime: lastSyncTime.present ? lastSyncTime.value : this.lastSyncTime,
  );
  MediaRow copyWithCompanion(MediaItemsCompanion data) {
    return MediaRow(
      id: data.id.present ? data.id.value : this.id,
      uri: data.uri.present ? data.uri.value : this.uri,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      folderName: data.folderName.present
          ? data.folderName.value
          : this.folderName,
      folderPath: data.folderPath.present
          ? data.folderPath.value
          : this.folderPath,
      dateAdded: data.dateAdded.present ? data.dateAdded.value : this.dateAdded,
      dateModified: data.dateModified.present
          ? data.dateModified.value
          : this.dateModified,
      dateTaken: data.dateTaken.present ? data.dateTaken.value : this.dateTaken,
      size: data.size.present ? data.size.value : this.size,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      thumbnailUri: data.thumbnailUri.present
          ? data.thumbnailUri.value
          : this.thumbnailUri,
      videoDuration: data.videoDuration.present
          ? data.videoDuration.value
          : this.videoDuration,
      lastViewedAt: data.lastViewedAt.present
          ? data.lastViewedAt.value
          : this.lastViewedAt,
      backupState: data.backupState.present
          ? data.backupState.value
          : this.backupState,
      lastSyncTime: data.lastSyncTime.present
          ? data.lastSyncTime.value
          : this.lastSyncTime,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaRow(')
          ..write('id: $id, ')
          ..write('uri: $uri, ')
          ..write('displayName: $displayName, ')
          ..write('folderName: $folderName, ')
          ..write('folderPath: $folderPath, ')
          ..write('dateAdded: $dateAdded, ')
          ..write('dateModified: $dateModified, ')
          ..write('dateTaken: $dateTaken, ')
          ..write('size: $size, ')
          ..write('mimeType: $mimeType, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('thumbnailUri: $thumbnailUri, ')
          ..write('videoDuration: $videoDuration, ')
          ..write('lastViewedAt: $lastViewedAt, ')
          ..write('backupState: $backupState, ')
          ..write('lastSyncTime: $lastSyncTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uri,
    displayName,
    folderName,
    folderPath,
    dateAdded,
    dateModified,
    dateTaken,
    size,
    mimeType,
    width,
    height,
    latitude,
    longitude,
    isFavorite,
    thumbnailUri,
    videoDuration,
    lastViewedAt,
    backupState,
    lastSyncTime,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaRow &&
          other.id == this.id &&
          other.uri == this.uri &&
          other.displayName == this.displayName &&
          other.folderName == this.folderName &&
          other.folderPath == this.folderPath &&
          other.dateAdded == this.dateAdded &&
          other.dateModified == this.dateModified &&
          other.dateTaken == this.dateTaken &&
          other.size == this.size &&
          other.mimeType == this.mimeType &&
          other.width == this.width &&
          other.height == this.height &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.isFavorite == this.isFavorite &&
          other.thumbnailUri == this.thumbnailUri &&
          other.videoDuration == this.videoDuration &&
          other.lastViewedAt == this.lastViewedAt &&
          other.backupState == this.backupState &&
          other.lastSyncTime == this.lastSyncTime);
}

class MediaItemsCompanion extends UpdateCompanion<MediaRow> {
  final Value<int> id;
  final Value<String> uri;
  final Value<String> displayName;
  final Value<String> folderName;
  final Value<String> folderPath;
  final Value<int> dateAdded;
  final Value<int> dateModified;
  final Value<int?> dateTaken;
  final Value<int> size;
  final Value<String> mimeType;
  final Value<int?> width;
  final Value<int?> height;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<bool> isFavorite;
  final Value<String?> thumbnailUri;
  final Value<int?> videoDuration;
  final Value<int?> lastViewedAt;
  final Value<int> backupState;
  final Value<int?> lastSyncTime;
  const MediaItemsCompanion({
    this.id = const Value.absent(),
    this.uri = const Value.absent(),
    this.displayName = const Value.absent(),
    this.folderName = const Value.absent(),
    this.folderPath = const Value.absent(),
    this.dateAdded = const Value.absent(),
    this.dateModified = const Value.absent(),
    this.dateTaken = const Value.absent(),
    this.size = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.thumbnailUri = const Value.absent(),
    this.videoDuration = const Value.absent(),
    this.lastViewedAt = const Value.absent(),
    this.backupState = const Value.absent(),
    this.lastSyncTime = const Value.absent(),
  });
  MediaItemsCompanion.insert({
    this.id = const Value.absent(),
    required String uri,
    required String displayName,
    required String folderName,
    required String folderPath,
    required int dateAdded,
    required int dateModified,
    this.dateTaken = const Value.absent(),
    required int size,
    required String mimeType,
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.thumbnailUri = const Value.absent(),
    this.videoDuration = const Value.absent(),
    this.lastViewedAt = const Value.absent(),
    this.backupState = const Value.absent(),
    this.lastSyncTime = const Value.absent(),
  }) : uri = Value(uri),
       displayName = Value(displayName),
       folderName = Value(folderName),
       folderPath = Value(folderPath),
       dateAdded = Value(dateAdded),
       dateModified = Value(dateModified),
       size = Value(size),
       mimeType = Value(mimeType);
  static Insertable<MediaRow> custom({
    Expression<int>? id,
    Expression<String>? uri,
    Expression<String>? displayName,
    Expression<String>? folderName,
    Expression<String>? folderPath,
    Expression<int>? dateAdded,
    Expression<int>? dateModified,
    Expression<int>? dateTaken,
    Expression<int>? size,
    Expression<String>? mimeType,
    Expression<int>? width,
    Expression<int>? height,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<bool>? isFavorite,
    Expression<String>? thumbnailUri,
    Expression<int>? videoDuration,
    Expression<int>? lastViewedAt,
    Expression<int>? backupState,
    Expression<int>? lastSyncTime,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uri != null) 'uri': uri,
      if (displayName != null) 'display_name': displayName,
      if (folderName != null) 'folder_name': folderName,
      if (folderPath != null) 'folder_path': folderPath,
      if (dateAdded != null) 'date_added': dateAdded,
      if (dateModified != null) 'date_modified': dateModified,
      if (dateTaken != null) 'date_taken': dateTaken,
      if (size != null) 'size': size,
      if (mimeType != null) 'mime_type': mimeType,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (thumbnailUri != null) 'thumbnail_uri': thumbnailUri,
      if (videoDuration != null) 'video_duration': videoDuration,
      if (lastViewedAt != null) 'last_viewed_at': lastViewedAt,
      if (backupState != null) 'backup_state': backupState,
      if (lastSyncTime != null) 'last_sync_time': lastSyncTime,
    });
  }

  MediaItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? uri,
    Value<String>? displayName,
    Value<String>? folderName,
    Value<String>? folderPath,
    Value<int>? dateAdded,
    Value<int>? dateModified,
    Value<int?>? dateTaken,
    Value<int>? size,
    Value<String>? mimeType,
    Value<int?>? width,
    Value<int?>? height,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<bool>? isFavorite,
    Value<String?>? thumbnailUri,
    Value<int?>? videoDuration,
    Value<int?>? lastViewedAt,
    Value<int>? backupState,
    Value<int?>? lastSyncTime,
  }) {
    return MediaItemsCompanion(
      id: id ?? this.id,
      uri: uri ?? this.uri,
      displayName: displayName ?? this.displayName,
      folderName: folderName ?? this.folderName,
      folderPath: folderPath ?? this.folderPath,
      dateAdded: dateAdded ?? this.dateAdded,
      dateModified: dateModified ?? this.dateModified,
      dateTaken: dateTaken ?? this.dateTaken,
      size: size ?? this.size,
      mimeType: mimeType ?? this.mimeType,
      width: width ?? this.width,
      height: height ?? this.height,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isFavorite: isFavorite ?? this.isFavorite,
      thumbnailUri: thumbnailUri ?? this.thumbnailUri,
      videoDuration: videoDuration ?? this.videoDuration,
      lastViewedAt: lastViewedAt ?? this.lastViewedAt,
      backupState: backupState ?? this.backupState,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uri.present) {
      map['uri'] = Variable<String>(uri.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (folderName.present) {
      map['folder_name'] = Variable<String>(folderName.value);
    }
    if (folderPath.present) {
      map['folder_path'] = Variable<String>(folderPath.value);
    }
    if (dateAdded.present) {
      map['date_added'] = Variable<int>(dateAdded.value);
    }
    if (dateModified.present) {
      map['date_modified'] = Variable<int>(dateModified.value);
    }
    if (dateTaken.present) {
      map['date_taken'] = Variable<int>(dateTaken.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (thumbnailUri.present) {
      map['thumbnail_uri'] = Variable<String>(thumbnailUri.value);
    }
    if (videoDuration.present) {
      map['video_duration'] = Variable<int>(videoDuration.value);
    }
    if (lastViewedAt.present) {
      map['last_viewed_at'] = Variable<int>(lastViewedAt.value);
    }
    if (backupState.present) {
      map['backup_state'] = Variable<int>(backupState.value);
    }
    if (lastSyncTime.present) {
      map['last_sync_time'] = Variable<int>(lastSyncTime.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaItemsCompanion(')
          ..write('id: $id, ')
          ..write('uri: $uri, ')
          ..write('displayName: $displayName, ')
          ..write('folderName: $folderName, ')
          ..write('folderPath: $folderPath, ')
          ..write('dateAdded: $dateAdded, ')
          ..write('dateModified: $dateModified, ')
          ..write('dateTaken: $dateTaken, ')
          ..write('size: $size, ')
          ..write('mimeType: $mimeType, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('thumbnailUri: $thumbnailUri, ')
          ..write('videoDuration: $videoDuration, ')
          ..write('lastViewedAt: $lastViewedAt, ')
          ..write('backupState: $backupState, ')
          ..write('lastSyncTime: $lastSyncTime')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FoldersTable folders = $FoldersTable(this);
  late final $MediaItemsTable mediaItems = $MediaItemsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [folders, mediaItems];
}

typedef $$FoldersTableCreateCompanionBuilder =
    FoldersCompanion Function({
      required String path,
      required String name,
      Value<int> mediaCount,
      Value<int> lastModified,
      Value<String?> coverImageUri,
      Value<bool> isHidden,
      Value<bool> isPinned,
      Value<int> sortOrder,
      Value<String?> customCoverUri,
      Value<String> followStatus,
      Value<bool> showInStories,
      Value<bool> isBiometricLocked,
      Value<String?> biography,
      Value<int> storyLastViewedTime,
      Value<int> rowid,
    });
typedef $$FoldersTableUpdateCompanionBuilder =
    FoldersCompanion Function({
      Value<String> path,
      Value<String> name,
      Value<int> mediaCount,
      Value<int> lastModified,
      Value<String?> coverImageUri,
      Value<bool> isHidden,
      Value<bool> isPinned,
      Value<int> sortOrder,
      Value<String?> customCoverUri,
      Value<String> followStatus,
      Value<bool> showInStories,
      Value<bool> isBiometricLocked,
      Value<String?> biography,
      Value<int> storyLastViewedTime,
      Value<int> rowid,
    });

class $$FoldersTableFilterComposer
    extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mediaCount => $composableBuilder(
    column: $table.mediaCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverImageUri => $composableBuilder(
    column: $table.coverImageUri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isHidden => $composableBuilder(
    column: $table.isHidden,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customCoverUri => $composableBuilder(
    column: $table.customCoverUri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get followStatus => $composableBuilder(
    column: $table.followStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showInStories => $composableBuilder(
    column: $table.showInStories,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBiometricLocked => $composableBuilder(
    column: $table.isBiometricLocked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get biography => $composableBuilder(
    column: $table.biography,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get storyLastViewedTime => $composableBuilder(
    column: $table.storyLastViewedTime,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FoldersTableOrderingComposer
    extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mediaCount => $composableBuilder(
    column: $table.mediaCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverImageUri => $composableBuilder(
    column: $table.coverImageUri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isHidden => $composableBuilder(
    column: $table.isHidden,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customCoverUri => $composableBuilder(
    column: $table.customCoverUri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get followStatus => $composableBuilder(
    column: $table.followStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showInStories => $composableBuilder(
    column: $table.showInStories,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBiometricLocked => $composableBuilder(
    column: $table.isBiometricLocked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get biography => $composableBuilder(
    column: $table.biography,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get storyLastViewedTime => $composableBuilder(
    column: $table.storyLastViewedTime,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FoldersTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get mediaCount => $composableBuilder(
    column: $table.mediaCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => column,
  );

  GeneratedColumn<String> get coverImageUri => $composableBuilder(
    column: $table.coverImageUri,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isHidden =>
      $composableBuilder(column: $table.isHidden, builder: (column) => column);

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get customCoverUri => $composableBuilder(
    column: $table.customCoverUri,
    builder: (column) => column,
  );

  GeneratedColumn<String> get followStatus => $composableBuilder(
    column: $table.followStatus,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showInStories => $composableBuilder(
    column: $table.showInStories,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isBiometricLocked => $composableBuilder(
    column: $table.isBiometricLocked,
    builder: (column) => column,
  );

  GeneratedColumn<String> get biography =>
      $composableBuilder(column: $table.biography, builder: (column) => column);

  GeneratedColumn<int> get storyLastViewedTime => $composableBuilder(
    column: $table.storyLastViewedTime,
    builder: (column) => column,
  );
}

class $$FoldersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoldersTable,
          Folder,
          $$FoldersTableFilterComposer,
          $$FoldersTableOrderingComposer,
          $$FoldersTableAnnotationComposer,
          $$FoldersTableCreateCompanionBuilder,
          $$FoldersTableUpdateCompanionBuilder,
          (Folder, BaseReferences<_$AppDatabase, $FoldersTable, Folder>),
          Folder,
          PrefetchHooks Function()
        > {
  $$FoldersTableTableManager(_$AppDatabase db, $FoldersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> path = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> mediaCount = const Value.absent(),
                Value<int> lastModified = const Value.absent(),
                Value<String?> coverImageUri = const Value.absent(),
                Value<bool> isHidden = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String?> customCoverUri = const Value.absent(),
                Value<String> followStatus = const Value.absent(),
                Value<bool> showInStories = const Value.absent(),
                Value<bool> isBiometricLocked = const Value.absent(),
                Value<String?> biography = const Value.absent(),
                Value<int> storyLastViewedTime = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoldersCompanion(
                path: path,
                name: name,
                mediaCount: mediaCount,
                lastModified: lastModified,
                coverImageUri: coverImageUri,
                isHidden: isHidden,
                isPinned: isPinned,
                sortOrder: sortOrder,
                customCoverUri: customCoverUri,
                followStatus: followStatus,
                showInStories: showInStories,
                isBiometricLocked: isBiometricLocked,
                biography: biography,
                storyLastViewedTime: storyLastViewedTime,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String path,
                required String name,
                Value<int> mediaCount = const Value.absent(),
                Value<int> lastModified = const Value.absent(),
                Value<String?> coverImageUri = const Value.absent(),
                Value<bool> isHidden = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String?> customCoverUri = const Value.absent(),
                Value<String> followStatus = const Value.absent(),
                Value<bool> showInStories = const Value.absent(),
                Value<bool> isBiometricLocked = const Value.absent(),
                Value<String?> biography = const Value.absent(),
                Value<int> storyLastViewedTime = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoldersCompanion.insert(
                path: path,
                name: name,
                mediaCount: mediaCount,
                lastModified: lastModified,
                coverImageUri: coverImageUri,
                isHidden: isHidden,
                isPinned: isPinned,
                sortOrder: sortOrder,
                customCoverUri: customCoverUri,
                followStatus: followStatus,
                showInStories: showInStories,
                isBiometricLocked: isBiometricLocked,
                biography: biography,
                storyLastViewedTime: storyLastViewedTime,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FoldersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoldersTable,
      Folder,
      $$FoldersTableFilterComposer,
      $$FoldersTableOrderingComposer,
      $$FoldersTableAnnotationComposer,
      $$FoldersTableCreateCompanionBuilder,
      $$FoldersTableUpdateCompanionBuilder,
      (Folder, BaseReferences<_$AppDatabase, $FoldersTable, Folder>),
      Folder,
      PrefetchHooks Function()
    >;
typedef $$MediaItemsTableCreateCompanionBuilder =
    MediaItemsCompanion Function({
      Value<int> id,
      required String uri,
      required String displayName,
      required String folderName,
      required String folderPath,
      required int dateAdded,
      required int dateModified,
      Value<int?> dateTaken,
      required int size,
      required String mimeType,
      Value<int?> width,
      Value<int?> height,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<bool> isFavorite,
      Value<String?> thumbnailUri,
      Value<int?> videoDuration,
      Value<int?> lastViewedAt,
      Value<int> backupState,
      Value<int?> lastSyncTime,
    });
typedef $$MediaItemsTableUpdateCompanionBuilder =
    MediaItemsCompanion Function({
      Value<int> id,
      Value<String> uri,
      Value<String> displayName,
      Value<String> folderName,
      Value<String> folderPath,
      Value<int> dateAdded,
      Value<int> dateModified,
      Value<int?> dateTaken,
      Value<int> size,
      Value<String> mimeType,
      Value<int?> width,
      Value<int?> height,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<bool> isFavorite,
      Value<String?> thumbnailUri,
      Value<int?> videoDuration,
      Value<int?> lastViewedAt,
      Value<int> backupState,
      Value<int?> lastSyncTime,
    });

class $$MediaItemsTableFilterComposer
    extends Composer<_$AppDatabase, $MediaItemsTable> {
  $$MediaItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uri => $composableBuilder(
    column: $table.uri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get folderName => $composableBuilder(
    column: $table.folderName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get folderPath => $composableBuilder(
    column: $table.folderPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dateAdded => $composableBuilder(
    column: $table.dateAdded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dateModified => $composableBuilder(
    column: $table.dateModified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dateTaken => $composableBuilder(
    column: $table.dateTaken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailUri => $composableBuilder(
    column: $table.thumbnailUri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get videoDuration => $composableBuilder(
    column: $table.videoDuration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastViewedAt => $composableBuilder(
    column: $table.lastViewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get backupState => $composableBuilder(
    column: $table.backupState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSyncTime => $composableBuilder(
    column: $table.lastSyncTime,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MediaItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaItemsTable> {
  $$MediaItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uri => $composableBuilder(
    column: $table.uri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get folderName => $composableBuilder(
    column: $table.folderName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get folderPath => $composableBuilder(
    column: $table.folderPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dateAdded => $composableBuilder(
    column: $table.dateAdded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dateModified => $composableBuilder(
    column: $table.dateModified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dateTaken => $composableBuilder(
    column: $table.dateTaken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailUri => $composableBuilder(
    column: $table.thumbnailUri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get videoDuration => $composableBuilder(
    column: $table.videoDuration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastViewedAt => $composableBuilder(
    column: $table.lastViewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get backupState => $composableBuilder(
    column: $table.backupState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSyncTime => $composableBuilder(
    column: $table.lastSyncTime,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MediaItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaItemsTable> {
  $$MediaItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uri =>
      $composableBuilder(column: $table.uri, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get folderName => $composableBuilder(
    column: $table.folderName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get folderPath => $composableBuilder(
    column: $table.folderPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dateAdded =>
      $composableBuilder(column: $table.dateAdded, builder: (column) => column);

  GeneratedColumn<int> get dateModified => $composableBuilder(
    column: $table.dateModified,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dateTaken =>
      $composableBuilder(column: $table.dateTaken, builder: (column) => column);

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<String> get thumbnailUri => $composableBuilder(
    column: $table.thumbnailUri,
    builder: (column) => column,
  );

  GeneratedColumn<int> get videoDuration => $composableBuilder(
    column: $table.videoDuration,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastViewedAt => $composableBuilder(
    column: $table.lastViewedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get backupState => $composableBuilder(
    column: $table.backupState,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastSyncTime => $composableBuilder(
    column: $table.lastSyncTime,
    builder: (column) => column,
  );
}

class $$MediaItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MediaItemsTable,
          MediaRow,
          $$MediaItemsTableFilterComposer,
          $$MediaItemsTableOrderingComposer,
          $$MediaItemsTableAnnotationComposer,
          $$MediaItemsTableCreateCompanionBuilder,
          $$MediaItemsTableUpdateCompanionBuilder,
          (MediaRow, BaseReferences<_$AppDatabase, $MediaItemsTable, MediaRow>),
          MediaRow,
          PrefetchHooks Function()
        > {
  $$MediaItemsTableTableManager(_$AppDatabase db, $MediaItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uri = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> folderName = const Value.absent(),
                Value<String> folderPath = const Value.absent(),
                Value<int> dateAdded = const Value.absent(),
                Value<int> dateModified = const Value.absent(),
                Value<int?> dateTaken = const Value.absent(),
                Value<int> size = const Value.absent(),
                Value<String> mimeType = const Value.absent(),
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<String?> thumbnailUri = const Value.absent(),
                Value<int?> videoDuration = const Value.absent(),
                Value<int?> lastViewedAt = const Value.absent(),
                Value<int> backupState = const Value.absent(),
                Value<int?> lastSyncTime = const Value.absent(),
              }) => MediaItemsCompanion(
                id: id,
                uri: uri,
                displayName: displayName,
                folderName: folderName,
                folderPath: folderPath,
                dateAdded: dateAdded,
                dateModified: dateModified,
                dateTaken: dateTaken,
                size: size,
                mimeType: mimeType,
                width: width,
                height: height,
                latitude: latitude,
                longitude: longitude,
                isFavorite: isFavorite,
                thumbnailUri: thumbnailUri,
                videoDuration: videoDuration,
                lastViewedAt: lastViewedAt,
                backupState: backupState,
                lastSyncTime: lastSyncTime,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uri,
                required String displayName,
                required String folderName,
                required String folderPath,
                required int dateAdded,
                required int dateModified,
                Value<int?> dateTaken = const Value.absent(),
                required int size,
                required String mimeType,
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<String?> thumbnailUri = const Value.absent(),
                Value<int?> videoDuration = const Value.absent(),
                Value<int?> lastViewedAt = const Value.absent(),
                Value<int> backupState = const Value.absent(),
                Value<int?> lastSyncTime = const Value.absent(),
              }) => MediaItemsCompanion.insert(
                id: id,
                uri: uri,
                displayName: displayName,
                folderName: folderName,
                folderPath: folderPath,
                dateAdded: dateAdded,
                dateModified: dateModified,
                dateTaken: dateTaken,
                size: size,
                mimeType: mimeType,
                width: width,
                height: height,
                latitude: latitude,
                longitude: longitude,
                isFavorite: isFavorite,
                thumbnailUri: thumbnailUri,
                videoDuration: videoDuration,
                lastViewedAt: lastViewedAt,
                backupState: backupState,
                lastSyncTime: lastSyncTime,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MediaItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MediaItemsTable,
      MediaRow,
      $$MediaItemsTableFilterComposer,
      $$MediaItemsTableOrderingComposer,
      $$MediaItemsTableAnnotationComposer,
      $$MediaItemsTableCreateCompanionBuilder,
      $$MediaItemsTableUpdateCompanionBuilder,
      (MediaRow, BaseReferences<_$AppDatabase, $MediaItemsTable, MediaRow>),
      MediaRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FoldersTableTableManager get folders =>
      $$FoldersTableTableManager(_db, _db.folders);
  $$MediaItemsTableTableManager get mediaItems =>
      $$MediaItemsTableTableManager(_db, _db.mediaItems);
}
