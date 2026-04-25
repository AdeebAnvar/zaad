// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drift_database.dart';

// ignore_for_file: type=lint
class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _branchIdMeta =
      const VerificationMeta('branchId');
  @override
  late final GeneratedColumn<int> branchId = GeneratedColumn<int>(
      'branch_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _usertypeMeta =
      const VerificationMeta('usertype');
  @override
  late final GeneratedColumn<String> usertype = GeneratedColumn<String>(
      'usertype', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mobilePasswordMeta =
      const VerificationMeta('mobilePassword');
  @override
  late final GeneratedColumn<String> mobilePassword = GeneratedColumn<String>(
      'mobile_password', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _permissionsMeta =
      const VerificationMeta('permissions');
  @override
  late final GeneratedColumn<String> permissions = GeneratedColumn<String>(
      'permissions', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, branchId, name, usertype, mobilePassword, permissions, role];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(Insertable<User> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('branch_id')) {
      context.handle(_branchIdMeta,
          branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta));
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('usertype')) {
      context.handle(_usertypeMeta,
          usertype.isAcceptableOrUnknown(data['usertype']!, _usertypeMeta));
    } else if (isInserting) {
      context.missing(_usertypeMeta);
    }
    if (data.containsKey('mobile_password')) {
      context.handle(
          _mobilePasswordMeta,
          mobilePassword.isAcceptableOrUnknown(
              data['mobile_password']!, _mobilePasswordMeta));
    } else if (isInserting) {
      context.missing(_mobilePasswordMeta);
    }
    if (data.containsKey('permissions')) {
      context.handle(
          _permissionsMeta,
          permissions.isAcceptableOrUnknown(
              data['permissions']!, _permissionsMeta));
    } else if (isInserting) {
      context.missing(_permissionsMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      branchId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}branch_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      usertype: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}usertype'])!,
      mobilePassword: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}mobile_password'])!,
      permissions: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}permissions'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role']),
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final int id;
  final int branchId;
  final String name;
  final String usertype;
  final String mobilePassword;
  final String permissions;
  final String? role;
  const User(
      {required this.id,
      required this.branchId,
      required this.name,
      required this.usertype,
      required this.mobilePassword,
      required this.permissions,
      this.role});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['branch_id'] = Variable<int>(branchId);
    map['name'] = Variable<String>(name);
    map['usertype'] = Variable<String>(usertype);
    map['mobile_password'] = Variable<String>(mobilePassword);
    map['permissions'] = Variable<String>(permissions);
    if (!nullToAbsent || role != null) {
      map['role'] = Variable<String>(role);
    }
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      branchId: Value(branchId),
      name: Value(name),
      usertype: Value(usertype),
      mobilePassword: Value(mobilePassword),
      permissions: Value(permissions),
      role: role == null && nullToAbsent ? const Value.absent() : Value(role),
    );
  }

  factory User.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<int>(json['id']),
      branchId: serializer.fromJson<int>(json['branchId']),
      name: serializer.fromJson<String>(json['name']),
      usertype: serializer.fromJson<String>(json['usertype']),
      mobilePassword: serializer.fromJson<String>(json['mobilePassword']),
      permissions: serializer.fromJson<String>(json['permissions']),
      role: serializer.fromJson<String?>(json['role']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'branchId': serializer.toJson<int>(branchId),
      'name': serializer.toJson<String>(name),
      'usertype': serializer.toJson<String>(usertype),
      'mobilePassword': serializer.toJson<String>(mobilePassword),
      'permissions': serializer.toJson<String>(permissions),
      'role': serializer.toJson<String?>(role),
    };
  }

  User copyWith(
          {int? id,
          int? branchId,
          String? name,
          String? usertype,
          String? mobilePassword,
          String? permissions,
          Value<String?> role = const Value.absent()}) =>
      User(
        id: id ?? this.id,
        branchId: branchId ?? this.branchId,
        name: name ?? this.name,
        usertype: usertype ?? this.usertype,
        mobilePassword: mobilePassword ?? this.mobilePassword,
        permissions: permissions ?? this.permissions,
        role: role.present ? role.value : this.role,
      );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      name: data.name.present ? data.name.value : this.name,
      usertype: data.usertype.present ? data.usertype.value : this.usertype,
      mobilePassword: data.mobilePassword.present
          ? data.mobilePassword.value
          : this.mobilePassword,
      permissions:
          data.permissions.present ? data.permissions.value : this.permissions,
      role: data.role.present ? data.role.value : this.role,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('branchId: $branchId, ')
          ..write('name: $name, ')
          ..write('usertype: $usertype, ')
          ..write('mobilePassword: $mobilePassword, ')
          ..write('permissions: $permissions, ')
          ..write('role: $role')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, branchId, name, usertype, mobilePassword, permissions, role);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.branchId == this.branchId &&
          other.name == this.name &&
          other.usertype == this.usertype &&
          other.mobilePassword == this.mobilePassword &&
          other.permissions == this.permissions &&
          other.role == this.role);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<int> id;
  final Value<int> branchId;
  final Value<String> name;
  final Value<String> usertype;
  final Value<String> mobilePassword;
  final Value<String> permissions;
  final Value<String?> role;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.branchId = const Value.absent(),
    this.name = const Value.absent(),
    this.usertype = const Value.absent(),
    this.mobilePassword = const Value.absent(),
    this.permissions = const Value.absent(),
    this.role = const Value.absent(),
  });
  UsersCompanion.insert({
    this.id = const Value.absent(),
    required int branchId,
    required String name,
    required String usertype,
    required String mobilePassword,
    required String permissions,
    this.role = const Value.absent(),
  })  : branchId = Value(branchId),
        name = Value(name),
        usertype = Value(usertype),
        mobilePassword = Value(mobilePassword),
        permissions = Value(permissions);
  static Insertable<User> custom({
    Expression<int>? id,
    Expression<int>? branchId,
    Expression<String>? name,
    Expression<String>? usertype,
    Expression<String>? mobilePassword,
    Expression<String>? permissions,
    Expression<String>? role,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (branchId != null) 'branch_id': branchId,
      if (name != null) 'name': name,
      if (usertype != null) 'usertype': usertype,
      if (mobilePassword != null) 'mobile_password': mobilePassword,
      if (permissions != null) 'permissions': permissions,
      if (role != null) 'role': role,
    });
  }

  UsersCompanion copyWith(
      {Value<int>? id,
      Value<int>? branchId,
      Value<String>? name,
      Value<String>? usertype,
      Value<String>? mobilePassword,
      Value<String>? permissions,
      Value<String?>? role}) {
    return UsersCompanion(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      name: name ?? this.name,
      usertype: usertype ?? this.usertype,
      mobilePassword: mobilePassword ?? this.mobilePassword,
      permissions: permissions ?? this.permissions,
      role: role ?? this.role,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<int>(branchId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (usertype.present) {
      map['usertype'] = Variable<String>(usertype.value);
    }
    if (mobilePassword.present) {
      map['mobile_password'] = Variable<String>(mobilePassword.value);
    }
    if (permissions.present) {
      map['permissions'] = Variable<String>(permissions.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('branchId: $branchId, ')
          ..write('name: $name, ')
          ..write('usertype: $usertype, ')
          ..write('mobilePassword: $mobilePassword, ')
          ..write('permissions: $permissions, ')
          ..write('role: $role')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _otherNameMeta =
      const VerificationMeta('otherName');
  @override
  late final GeneratedColumn<String> otherName = GeneratedColumn<String>(
      'other_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _recordUuidMeta =
      const VerificationMeta('recordUuid');
  @override
  late final GeneratedColumn<String> recordUuid = GeneratedColumn<String>(
      'record_uuid', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _branchIdMeta =
      const VerificationMeta('branchId');
  @override
  late final GeneratedColumn<int> branchId = GeneratedColumn<int>(
      'branch_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _categorySlugMeta =
      const VerificationMeta('categorySlug');
  @override
  late final GeneratedColumn<String> categorySlug = GeneratedColumn<String>(
      'category_slug', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, otherName, recordUuid, branchId, categorySlug, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(Insertable<Category> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('other_name')) {
      context.handle(_otherNameMeta,
          otherName.isAcceptableOrUnknown(data['other_name']!, _otherNameMeta));
    } else if (isInserting) {
      context.missing(_otherNameMeta);
    }
    if (data.containsKey('record_uuid')) {
      context.handle(
          _recordUuidMeta,
          recordUuid.isAcceptableOrUnknown(
              data['record_uuid']!, _recordUuidMeta));
    }
    if (data.containsKey('branch_id')) {
      context.handle(_branchIdMeta,
          branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta));
    }
    if (data.containsKey('category_slug')) {
      context.handle(
          _categorySlugMeta,
          categorySlug.isAcceptableOrUnknown(
              data['category_slug']!, _categorySlugMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      otherName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}other_name'])!,
      recordUuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}record_uuid']),
      branchId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}branch_id']),
      categorySlug: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_slug']),
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final int id;
  final String name;
  final String otherName;

  /// [CategoryCreatedUpdated.uuid] from [PullDataModel] / [CategorySyncResponse]
  final String? recordUuid;
  final int? branchId;
  final String? categorySlug;
  final DateTime? deletedAt;
  const Category(
      {required this.id,
      required this.name,
      required this.otherName,
      this.recordUuid,
      this.branchId,
      this.categorySlug,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['other_name'] = Variable<String>(otherName);
    if (!nullToAbsent || recordUuid != null) {
      map['record_uuid'] = Variable<String>(recordUuid);
    }
    if (!nullToAbsent || branchId != null) {
      map['branch_id'] = Variable<int>(branchId);
    }
    if (!nullToAbsent || categorySlug != null) {
      map['category_slug'] = Variable<String>(categorySlug);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      otherName: Value(otherName),
      recordUuid: recordUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(recordUuid),
      branchId: branchId == null && nullToAbsent
          ? const Value.absent()
          : Value(branchId),
      categorySlug: categorySlug == null && nullToAbsent
          ? const Value.absent()
          : Value(categorySlug),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Category.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      otherName: serializer.fromJson<String>(json['otherName']),
      recordUuid: serializer.fromJson<String?>(json['recordUuid']),
      branchId: serializer.fromJson<int?>(json['branchId']),
      categorySlug: serializer.fromJson<String?>(json['categorySlug']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'otherName': serializer.toJson<String>(otherName),
      'recordUuid': serializer.toJson<String?>(recordUuid),
      'branchId': serializer.toJson<int?>(branchId),
      'categorySlug': serializer.toJson<String?>(categorySlug),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Category copyWith(
          {int? id,
          String? name,
          String? otherName,
          Value<String?> recordUuid = const Value.absent(),
          Value<int?> branchId = const Value.absent(),
          Value<String?> categorySlug = const Value.absent(),
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      Category(
        id: id ?? this.id,
        name: name ?? this.name,
        otherName: otherName ?? this.otherName,
        recordUuid: recordUuid.present ? recordUuid.value : this.recordUuid,
        branchId: branchId.present ? branchId.value : this.branchId,
        categorySlug:
            categorySlug.present ? categorySlug.value : this.categorySlug,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      otherName: data.otherName.present ? data.otherName.value : this.otherName,
      recordUuid:
          data.recordUuid.present ? data.recordUuid.value : this.recordUuid,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      categorySlug: data.categorySlug.present
          ? data.categorySlug.value
          : this.categorySlug,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('otherName: $otherName, ')
          ..write('recordUuid: $recordUuid, ')
          ..write('branchId: $branchId, ')
          ..write('categorySlug: $categorySlug, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, name, otherName, recordUuid, branchId, categorySlug, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.name == this.name &&
          other.otherName == this.otherName &&
          other.recordUuid == this.recordUuid &&
          other.branchId == this.branchId &&
          other.categorySlug == this.categorySlug &&
          other.deletedAt == this.deletedAt);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> otherName;
  final Value<String?> recordUuid;
  final Value<int?> branchId;
  final Value<String?> categorySlug;
  final Value<DateTime?> deletedAt;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.otherName = const Value.absent(),
    this.recordUuid = const Value.absent(),
    this.branchId = const Value.absent(),
    this.categorySlug = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String otherName,
    this.recordUuid = const Value.absent(),
    this.branchId = const Value.absent(),
    this.categorySlug = const Value.absent(),
    this.deletedAt = const Value.absent(),
  })  : name = Value(name),
        otherName = Value(otherName);
  static Insertable<Category> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? otherName,
    Expression<String>? recordUuid,
    Expression<int>? branchId,
    Expression<String>? categorySlug,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (otherName != null) 'other_name': otherName,
      if (recordUuid != null) 'record_uuid': recordUuid,
      if (branchId != null) 'branch_id': branchId,
      if (categorySlug != null) 'category_slug': categorySlug,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  CategoriesCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? otherName,
      Value<String?>? recordUuid,
      Value<int?>? branchId,
      Value<String?>? categorySlug,
      Value<DateTime?>? deletedAt}) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      otherName: otherName ?? this.otherName,
      recordUuid: recordUuid ?? this.recordUuid,
      branchId: branchId ?? this.branchId,
      categorySlug: categorySlug ?? this.categorySlug,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (otherName.present) {
      map['other_name'] = Variable<String>(otherName.value);
    }
    if (recordUuid.present) {
      map['record_uuid'] = Variable<String>(recordUuid.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<int>(branchId.value);
    }
    if (categorySlug.present) {
      map['category_slug'] = Variable<String>(categorySlug.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('otherName: $otherName, ')
          ..write('recordUuid: $recordUuid, ')
          ..write('branchId: $branchId, ')
          ..write('categorySlug: $categorySlug, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $KitchensTable extends Kitchens with TableInfo<$KitchensTable, Kitchen> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KitchensTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _printerIpMeta =
      const VerificationMeta('printerIp');
  @override
  late final GeneratedColumn<String> printerIp = GeneratedColumn<String>(
      'printer_ip', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _printerPortMeta =
      const VerificationMeta('printerPort');
  @override
  late final GeneratedColumn<int> printerPort = GeneratedColumn<int>(
      'printer_port', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(9100));
  static const VerificationMeta _recordUuidMeta =
      const VerificationMeta('recordUuid');
  @override
  late final GeneratedColumn<String> recordUuid = GeneratedColumn<String>(
      'record_uuid', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _branchIdMeta =
      const VerificationMeta('branchId');
  @override
  late final GeneratedColumn<int> branchId = GeneratedColumn<int>(
      'branch_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _printerDetailsMeta =
      const VerificationMeta('printerDetails');
  @override
  late final GeneratedColumn<String> printerDetails = GeneratedColumn<String>(
      'printer_details', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _printerTypeMeta =
      const VerificationMeta('printerType');
  @override
  late final GeneratedColumn<String> printerType = GeneratedColumn<String>(
      'printer_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        printerIp,
        printerPort,
        recordUuid,
        branchId,
        printerDetails,
        printerType,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'kitchens';
  @override
  VerificationContext validateIntegrity(Insertable<Kitchen> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('printer_ip')) {
      context.handle(_printerIpMeta,
          printerIp.isAcceptableOrUnknown(data['printer_ip']!, _printerIpMeta));
    }
    if (data.containsKey('printer_port')) {
      context.handle(
          _printerPortMeta,
          printerPort.isAcceptableOrUnknown(
              data['printer_port']!, _printerPortMeta));
    }
    if (data.containsKey('record_uuid')) {
      context.handle(
          _recordUuidMeta,
          recordUuid.isAcceptableOrUnknown(
              data['record_uuid']!, _recordUuidMeta));
    }
    if (data.containsKey('branch_id')) {
      context.handle(_branchIdMeta,
          branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta));
    }
    if (data.containsKey('printer_details')) {
      context.handle(
          _printerDetailsMeta,
          printerDetails.isAcceptableOrUnknown(
              data['printer_details']!, _printerDetailsMeta));
    }
    if (data.containsKey('printer_type')) {
      context.handle(
          _printerTypeMeta,
          printerType.isAcceptableOrUnknown(
              data['printer_type']!, _printerTypeMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Kitchen map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Kitchen(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      printerIp: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}printer_ip']),
      printerPort: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}printer_port'])!,
      recordUuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}record_uuid']),
      branchId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}branch_id']),
      printerDetails: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}printer_details']),
      printerType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}printer_type']),
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $KitchensTable createAlias(String alias) {
    return $KitchensTable(attachedDatabase, alias);
  }
}

class Kitchen extends DataClass implements Insertable<Kitchen> {
  final int id;
  final String name;
  final String? printerIp;
  final int printerPort;

  /// [KitchensCreatedUpdated] from [KitchenSyncResponse]
  final String? recordUuid;
  final int? branchId;
  final String? printerDetails;
  final String? printerType;
  final DateTime? deletedAt;
  const Kitchen(
      {required this.id,
      required this.name,
      this.printerIp,
      required this.printerPort,
      this.recordUuid,
      this.branchId,
      this.printerDetails,
      this.printerType,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || printerIp != null) {
      map['printer_ip'] = Variable<String>(printerIp);
    }
    map['printer_port'] = Variable<int>(printerPort);
    if (!nullToAbsent || recordUuid != null) {
      map['record_uuid'] = Variable<String>(recordUuid);
    }
    if (!nullToAbsent || branchId != null) {
      map['branch_id'] = Variable<int>(branchId);
    }
    if (!nullToAbsent || printerDetails != null) {
      map['printer_details'] = Variable<String>(printerDetails);
    }
    if (!nullToAbsent || printerType != null) {
      map['printer_type'] = Variable<String>(printerType);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  KitchensCompanion toCompanion(bool nullToAbsent) {
    return KitchensCompanion(
      id: Value(id),
      name: Value(name),
      printerIp: printerIp == null && nullToAbsent
          ? const Value.absent()
          : Value(printerIp),
      printerPort: Value(printerPort),
      recordUuid: recordUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(recordUuid),
      branchId: branchId == null && nullToAbsent
          ? const Value.absent()
          : Value(branchId),
      printerDetails: printerDetails == null && nullToAbsent
          ? const Value.absent()
          : Value(printerDetails),
      printerType: printerType == null && nullToAbsent
          ? const Value.absent()
          : Value(printerType),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Kitchen.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Kitchen(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      printerIp: serializer.fromJson<String?>(json['printerIp']),
      printerPort: serializer.fromJson<int>(json['printerPort']),
      recordUuid: serializer.fromJson<String?>(json['recordUuid']),
      branchId: serializer.fromJson<int?>(json['branchId']),
      printerDetails: serializer.fromJson<String?>(json['printerDetails']),
      printerType: serializer.fromJson<String?>(json['printerType']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'printerIp': serializer.toJson<String?>(printerIp),
      'printerPort': serializer.toJson<int>(printerPort),
      'recordUuid': serializer.toJson<String?>(recordUuid),
      'branchId': serializer.toJson<int?>(branchId),
      'printerDetails': serializer.toJson<String?>(printerDetails),
      'printerType': serializer.toJson<String?>(printerType),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Kitchen copyWith(
          {int? id,
          String? name,
          Value<String?> printerIp = const Value.absent(),
          int? printerPort,
          Value<String?> recordUuid = const Value.absent(),
          Value<int?> branchId = const Value.absent(),
          Value<String?> printerDetails = const Value.absent(),
          Value<String?> printerType = const Value.absent(),
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      Kitchen(
        id: id ?? this.id,
        name: name ?? this.name,
        printerIp: printerIp.present ? printerIp.value : this.printerIp,
        printerPort: printerPort ?? this.printerPort,
        recordUuid: recordUuid.present ? recordUuid.value : this.recordUuid,
        branchId: branchId.present ? branchId.value : this.branchId,
        printerDetails:
            printerDetails.present ? printerDetails.value : this.printerDetails,
        printerType: printerType.present ? printerType.value : this.printerType,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  Kitchen copyWithCompanion(KitchensCompanion data) {
    return Kitchen(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      printerIp: data.printerIp.present ? data.printerIp.value : this.printerIp,
      printerPort:
          data.printerPort.present ? data.printerPort.value : this.printerPort,
      recordUuid:
          data.recordUuid.present ? data.recordUuid.value : this.recordUuid,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      printerDetails: data.printerDetails.present
          ? data.printerDetails.value
          : this.printerDetails,
      printerType:
          data.printerType.present ? data.printerType.value : this.printerType,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Kitchen(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('printerIp: $printerIp, ')
          ..write('printerPort: $printerPort, ')
          ..write('recordUuid: $recordUuid, ')
          ..write('branchId: $branchId, ')
          ..write('printerDetails: $printerDetails, ')
          ..write('printerType: $printerType, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, printerIp, printerPort, recordUuid,
      branchId, printerDetails, printerType, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Kitchen &&
          other.id == this.id &&
          other.name == this.name &&
          other.printerIp == this.printerIp &&
          other.printerPort == this.printerPort &&
          other.recordUuid == this.recordUuid &&
          other.branchId == this.branchId &&
          other.printerDetails == this.printerDetails &&
          other.printerType == this.printerType &&
          other.deletedAt == this.deletedAt);
}

class KitchensCompanion extends UpdateCompanion<Kitchen> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> printerIp;
  final Value<int> printerPort;
  final Value<String?> recordUuid;
  final Value<int?> branchId;
  final Value<String?> printerDetails;
  final Value<String?> printerType;
  final Value<DateTime?> deletedAt;
  const KitchensCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.printerIp = const Value.absent(),
    this.printerPort = const Value.absent(),
    this.recordUuid = const Value.absent(),
    this.branchId = const Value.absent(),
    this.printerDetails = const Value.absent(),
    this.printerType = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  KitchensCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.printerIp = const Value.absent(),
    this.printerPort = const Value.absent(),
    this.recordUuid = const Value.absent(),
    this.branchId = const Value.absent(),
    this.printerDetails = const Value.absent(),
    this.printerType = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Kitchen> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? printerIp,
    Expression<int>? printerPort,
    Expression<String>? recordUuid,
    Expression<int>? branchId,
    Expression<String>? printerDetails,
    Expression<String>? printerType,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (printerIp != null) 'printer_ip': printerIp,
      if (printerPort != null) 'printer_port': printerPort,
      if (recordUuid != null) 'record_uuid': recordUuid,
      if (branchId != null) 'branch_id': branchId,
      if (printerDetails != null) 'printer_details': printerDetails,
      if (printerType != null) 'printer_type': printerType,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  KitchensCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String?>? printerIp,
      Value<int>? printerPort,
      Value<String?>? recordUuid,
      Value<int?>? branchId,
      Value<String?>? printerDetails,
      Value<String?>? printerType,
      Value<DateTime?>? deletedAt}) {
    return KitchensCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      printerIp: printerIp ?? this.printerIp,
      printerPort: printerPort ?? this.printerPort,
      recordUuid: recordUuid ?? this.recordUuid,
      branchId: branchId ?? this.branchId,
      printerDetails: printerDetails ?? this.printerDetails,
      printerType: printerType ?? this.printerType,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (printerIp.present) {
      map['printer_ip'] = Variable<String>(printerIp.value);
    }
    if (printerPort.present) {
      map['printer_port'] = Variable<int>(printerPort.value);
    }
    if (recordUuid.present) {
      map['record_uuid'] = Variable<String>(recordUuid.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<int>(branchId.value);
    }
    if (printerDetails.present) {
      map['printer_details'] = Variable<String>(printerDetails.value);
    }
    if (printerType.present) {
      map['printer_type'] = Variable<String>(printerType.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KitchensCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('printerIp: $printerIp, ')
          ..write('printerPort: $printerPort, ')
          ..write('recordUuid: $recordUuid, ')
          ..write('branchId: $branchId, ')
          ..write('printerDetails: $printerDetails, ')
          ..write('printerType: $printerType, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $KitchenPrintersTable extends KitchenPrinters
    with TableInfo<$KitchenPrintersTable, KitchenPrinter> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KitchenPrintersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _kitchenIdMeta =
      const VerificationMeta('kitchenId');
  @override
  late final GeneratedColumn<int> kitchenId = GeneratedColumn<int>(
      'kitchen_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _printerIpMeta =
      const VerificationMeta('printerIp');
  @override
  late final GeneratedColumn<String> printerIp = GeneratedColumn<String>(
      'printer_ip', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _printerPortMeta =
      const VerificationMeta('printerPort');
  @override
  late final GeneratedColumn<int> printerPort = GeneratedColumn<int>(
      'printer_port', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(9100));
  @override
  List<GeneratedColumn> get $columns => [kitchenId, printerIp, printerPort];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'kitchen_printers';
  @override
  VerificationContext validateIntegrity(Insertable<KitchenPrinter> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('kitchen_id')) {
      context.handle(_kitchenIdMeta,
          kitchenId.isAcceptableOrUnknown(data['kitchen_id']!, _kitchenIdMeta));
    }
    if (data.containsKey('printer_ip')) {
      context.handle(_printerIpMeta,
          printerIp.isAcceptableOrUnknown(data['printer_ip']!, _printerIpMeta));
    } else if (isInserting) {
      context.missing(_printerIpMeta);
    }
    if (data.containsKey('printer_port')) {
      context.handle(
          _printerPortMeta,
          printerPort.isAcceptableOrUnknown(
              data['printer_port']!, _printerPortMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {kitchenId};
  @override
  KitchenPrinter map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KitchenPrinter(
      kitchenId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}kitchen_id'])!,
      printerIp: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}printer_ip'])!,
      printerPort: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}printer_port'])!,
    );
  }

  @override
  $KitchenPrintersTable createAlias(String alias) {
    return $KitchenPrintersTable(attachedDatabase, alias);
  }
}

class KitchenPrinter extends DataClass implements Insertable<KitchenPrinter> {
  final int kitchenId;
  final String printerIp;
  final int printerPort;
  const KitchenPrinter(
      {required this.kitchenId,
      required this.printerIp,
      required this.printerPort});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['kitchen_id'] = Variable<int>(kitchenId);
    map['printer_ip'] = Variable<String>(printerIp);
    map['printer_port'] = Variable<int>(printerPort);
    return map;
  }

  KitchenPrintersCompanion toCompanion(bool nullToAbsent) {
    return KitchenPrintersCompanion(
      kitchenId: Value(kitchenId),
      printerIp: Value(printerIp),
      printerPort: Value(printerPort),
    );
  }

  factory KitchenPrinter.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KitchenPrinter(
      kitchenId: serializer.fromJson<int>(json['kitchenId']),
      printerIp: serializer.fromJson<String>(json['printerIp']),
      printerPort: serializer.fromJson<int>(json['printerPort']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'kitchenId': serializer.toJson<int>(kitchenId),
      'printerIp': serializer.toJson<String>(printerIp),
      'printerPort': serializer.toJson<int>(printerPort),
    };
  }

  KitchenPrinter copyWith(
          {int? kitchenId, String? printerIp, int? printerPort}) =>
      KitchenPrinter(
        kitchenId: kitchenId ?? this.kitchenId,
        printerIp: printerIp ?? this.printerIp,
        printerPort: printerPort ?? this.printerPort,
      );
  KitchenPrinter copyWithCompanion(KitchenPrintersCompanion data) {
    return KitchenPrinter(
      kitchenId: data.kitchenId.present ? data.kitchenId.value : this.kitchenId,
      printerIp: data.printerIp.present ? data.printerIp.value : this.printerIp,
      printerPort:
          data.printerPort.present ? data.printerPort.value : this.printerPort,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KitchenPrinter(')
          ..write('kitchenId: $kitchenId, ')
          ..write('printerIp: $printerIp, ')
          ..write('printerPort: $printerPort')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(kitchenId, printerIp, printerPort);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KitchenPrinter &&
          other.kitchenId == this.kitchenId &&
          other.printerIp == this.printerIp &&
          other.printerPort == this.printerPort);
}

class KitchenPrintersCompanion extends UpdateCompanion<KitchenPrinter> {
  final Value<int> kitchenId;
  final Value<String> printerIp;
  final Value<int> printerPort;
  const KitchenPrintersCompanion({
    this.kitchenId = const Value.absent(),
    this.printerIp = const Value.absent(),
    this.printerPort = const Value.absent(),
  });
  KitchenPrintersCompanion.insert({
    this.kitchenId = const Value.absent(),
    required String printerIp,
    this.printerPort = const Value.absent(),
  }) : printerIp = Value(printerIp);
  static Insertable<KitchenPrinter> custom({
    Expression<int>? kitchenId,
    Expression<String>? printerIp,
    Expression<int>? printerPort,
  }) {
    return RawValuesInsertable({
      if (kitchenId != null) 'kitchen_id': kitchenId,
      if (printerIp != null) 'printer_ip': printerIp,
      if (printerPort != null) 'printer_port': printerPort,
    });
  }

  KitchenPrintersCompanion copyWith(
      {Value<int>? kitchenId,
      Value<String>? printerIp,
      Value<int>? printerPort}) {
    return KitchenPrintersCompanion(
      kitchenId: kitchenId ?? this.kitchenId,
      printerIp: printerIp ?? this.printerIp,
      printerPort: printerPort ?? this.printerPort,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (kitchenId.present) {
      map['kitchen_id'] = Variable<int>(kitchenId.value);
    }
    if (printerIp.present) {
      map['printer_ip'] = Variable<String>(printerIp.value);
    }
    if (printerPort.present) {
      map['printer_port'] = Variable<int>(printerPort.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KitchenPrintersCompanion(')
          ..write('kitchenId: $kitchenId, ')
          ..write('printerIp: $printerIp, ')
          ..write('printerPort: $printerPort')
          ..write(')'))
        .toString();
  }
}

class $ItemsTable extends Items with TableInfo<$ItemsTable, Item> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _otherNameMeta =
      const VerificationMeta('otherName');
  @override
  late final GeneratedColumn<String> otherName = GeneratedColumn<String>(
      'other_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
      'sku', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
      'price', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _stockMeta = const VerificationMeta('stock');
  @override
  late final GeneratedColumn<int> stock = GeneratedColumn<int>(
      'stock', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _stockEnabledMeta =
      const VerificationMeta('stockEnabled');
  @override
  late final GeneratedColumn<bool> stockEnabled = GeneratedColumn<bool>(
      'stock_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("stock_enabled" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _imagePathMeta =
      const VerificationMeta('imagePath');
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
      'image_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _localImagePathMeta =
      const VerificationMeta('localImagePath');
  @override
  late final GeneratedColumn<String> localImagePath = GeneratedColumn<String>(
      'local_image_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _categoryNameMeta =
      const VerificationMeta('categoryName');
  @override
  late final GeneratedColumn<String> categoryName = GeneratedColumn<String>(
      'category_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryOtherNameMeta =
      const VerificationMeta('categoryOtherName');
  @override
  late final GeneratedColumn<String> categoryOtherName =
      GeneratedColumn<String>('category_other_name', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _barcodeMeta =
      const VerificationMeta('barcode');
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
      'barcode', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
      'category_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _kitchenIdMeta =
      const VerificationMeta('kitchenId');
  @override
  late final GeneratedColumn<int> kitchenId = GeneratedColumn<int>(
      'kitchen_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _kitchenNameMeta =
      const VerificationMeta('kitchenName');
  @override
  late final GeneratedColumn<String> kitchenName = GeneratedColumn<String>(
      'kitchen_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _deliveryPartnerMeta =
      const VerificationMeta('deliveryPartner');
  @override
  late final GeneratedColumn<String> deliveryPartner = GeneratedColumn<String>(
      'delivery_partner', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        otherName,
        sku,
        price,
        stock,
        stockEnabled,
        imagePath,
        localImagePath,
        categoryName,
        categoryOtherName,
        barcode,
        categoryId,
        kitchenId,
        kitchenName,
        deliveryPartner
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'items';
  @override
  VerificationContext validateIntegrity(Insertable<Item> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('other_name')) {
      context.handle(_otherNameMeta,
          otherName.isAcceptableOrUnknown(data['other_name']!, _otherNameMeta));
    } else if (isInserting) {
      context.missing(_otherNameMeta);
    }
    if (data.containsKey('sku')) {
      context.handle(
          _skuMeta, sku.isAcceptableOrUnknown(data['sku']!, _skuMeta));
    } else if (isInserting) {
      context.missing(_skuMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
          _priceMeta, price.isAcceptableOrUnknown(data['price']!, _priceMeta));
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('stock')) {
      context.handle(
          _stockMeta, stock.isAcceptableOrUnknown(data['stock']!, _stockMeta));
    } else if (isInserting) {
      context.missing(_stockMeta);
    }
    if (data.containsKey('stock_enabled')) {
      context.handle(
          _stockEnabledMeta,
          stockEnabled.isAcceptableOrUnknown(
              data['stock_enabled']!, _stockEnabledMeta));
    }
    if (data.containsKey('image_path')) {
      context.handle(_imagePathMeta,
          imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta));
    }
    if (data.containsKey('local_image_path')) {
      context.handle(
          _localImagePathMeta,
          localImagePath.isAcceptableOrUnknown(
              data['local_image_path']!, _localImagePathMeta));
    }
    if (data.containsKey('category_name')) {
      context.handle(
          _categoryNameMeta,
          categoryName.isAcceptableOrUnknown(
              data['category_name']!, _categoryNameMeta));
    } else if (isInserting) {
      context.missing(_categoryNameMeta);
    }
    if (data.containsKey('category_other_name')) {
      context.handle(
          _categoryOtherNameMeta,
          categoryOtherName.isAcceptableOrUnknown(
              data['category_other_name']!, _categoryOtherNameMeta));
    } else if (isInserting) {
      context.missing(_categoryOtherNameMeta);
    }
    if (data.containsKey('barcode')) {
      context.handle(_barcodeMeta,
          barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta));
    } else if (isInserting) {
      context.missing(_barcodeMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('kitchen_id')) {
      context.handle(_kitchenIdMeta,
          kitchenId.isAcceptableOrUnknown(data['kitchen_id']!, _kitchenIdMeta));
    }
    if (data.containsKey('kitchen_name')) {
      context.handle(
          _kitchenNameMeta,
          kitchenName.isAcceptableOrUnknown(
              data['kitchen_name']!, _kitchenNameMeta));
    }
    if (data.containsKey('delivery_partner')) {
      context.handle(
          _deliveryPartnerMeta,
          deliveryPartner.isAcceptableOrUnknown(
              data['delivery_partner']!, _deliveryPartnerMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Item map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Item(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      otherName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}other_name'])!,
      sku: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sku'])!,
      price: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}price'])!,
      stock: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}stock'])!,
      stockEnabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}stock_enabled'])!,
      imagePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_path']),
      localImagePath: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}local_image_path']),
      categoryName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_name'])!,
      categoryOtherName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}category_other_name'])!,
      barcode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}barcode'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}category_id'])!,
      kitchenId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}kitchen_id']),
      kitchenName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kitchen_name']),
      deliveryPartner: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}delivery_partner']),
    );
  }

  @override
  $ItemsTable createAlias(String alias) {
    return $ItemsTable(attachedDatabase, alias);
  }
}

class Item extends DataClass implements Insertable<Item> {
  final int id;
  final String name;
  final String otherName;
  final String sku;
  final double price;
  final int stock;

  /// When false, stock quantity is ignored in UI and sales logic.
  final bool stockEnabled;
  final String? imagePath;
  final String? localImagePath;
  final String categoryName;
  final String categoryOtherName;
  final String barcode;
  final int categoryId;
  final int? kitchenId;
  final String? kitchenName;

  /// Delivery partner id/name - items filtered by partner when in delivery mode
  final String? deliveryPartner;
  const Item(
      {required this.id,
      required this.name,
      required this.otherName,
      required this.sku,
      required this.price,
      required this.stock,
      required this.stockEnabled,
      this.imagePath,
      this.localImagePath,
      required this.categoryName,
      required this.categoryOtherName,
      required this.barcode,
      required this.categoryId,
      this.kitchenId,
      this.kitchenName,
      this.deliveryPartner});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['other_name'] = Variable<String>(otherName);
    map['sku'] = Variable<String>(sku);
    map['price'] = Variable<double>(price);
    map['stock'] = Variable<int>(stock);
    map['stock_enabled'] = Variable<bool>(stockEnabled);
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    if (!nullToAbsent || localImagePath != null) {
      map['local_image_path'] = Variable<String>(localImagePath);
    }
    map['category_name'] = Variable<String>(categoryName);
    map['category_other_name'] = Variable<String>(categoryOtherName);
    map['barcode'] = Variable<String>(barcode);
    map['category_id'] = Variable<int>(categoryId);
    if (!nullToAbsent || kitchenId != null) {
      map['kitchen_id'] = Variable<int>(kitchenId);
    }
    if (!nullToAbsent || kitchenName != null) {
      map['kitchen_name'] = Variable<String>(kitchenName);
    }
    if (!nullToAbsent || deliveryPartner != null) {
      map['delivery_partner'] = Variable<String>(deliveryPartner);
    }
    return map;
  }

  ItemsCompanion toCompanion(bool nullToAbsent) {
    return ItemsCompanion(
      id: Value(id),
      name: Value(name),
      otherName: Value(otherName),
      sku: Value(sku),
      price: Value(price),
      stock: Value(stock),
      stockEnabled: Value(stockEnabled),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      localImagePath: localImagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(localImagePath),
      categoryName: Value(categoryName),
      categoryOtherName: Value(categoryOtherName),
      barcode: Value(barcode),
      categoryId: Value(categoryId),
      kitchenId: kitchenId == null && nullToAbsent
          ? const Value.absent()
          : Value(kitchenId),
      kitchenName: kitchenName == null && nullToAbsent
          ? const Value.absent()
          : Value(kitchenName),
      deliveryPartner: deliveryPartner == null && nullToAbsent
          ? const Value.absent()
          : Value(deliveryPartner),
    );
  }

  factory Item.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Item(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      otherName: serializer.fromJson<String>(json['otherName']),
      sku: serializer.fromJson<String>(json['sku']),
      price: serializer.fromJson<double>(json['price']),
      stock: serializer.fromJson<int>(json['stock']),
      stockEnabled: serializer.fromJson<bool>(json['stockEnabled']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      localImagePath: serializer.fromJson<String?>(json['localImagePath']),
      categoryName: serializer.fromJson<String>(json['categoryName']),
      categoryOtherName: serializer.fromJson<String>(json['categoryOtherName']),
      barcode: serializer.fromJson<String>(json['barcode']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      kitchenId: serializer.fromJson<int?>(json['kitchenId']),
      kitchenName: serializer.fromJson<String?>(json['kitchenName']),
      deliveryPartner: serializer.fromJson<String?>(json['deliveryPartner']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'otherName': serializer.toJson<String>(otherName),
      'sku': serializer.toJson<String>(sku),
      'price': serializer.toJson<double>(price),
      'stock': serializer.toJson<int>(stock),
      'stockEnabled': serializer.toJson<bool>(stockEnabled),
      'imagePath': serializer.toJson<String?>(imagePath),
      'localImagePath': serializer.toJson<String?>(localImagePath),
      'categoryName': serializer.toJson<String>(categoryName),
      'categoryOtherName': serializer.toJson<String>(categoryOtherName),
      'barcode': serializer.toJson<String>(barcode),
      'categoryId': serializer.toJson<int>(categoryId),
      'kitchenId': serializer.toJson<int?>(kitchenId),
      'kitchenName': serializer.toJson<String?>(kitchenName),
      'deliveryPartner': serializer.toJson<String?>(deliveryPartner),
    };
  }

  Item copyWith(
          {int? id,
          String? name,
          String? otherName,
          String? sku,
          double? price,
          int? stock,
          bool? stockEnabled,
          Value<String?> imagePath = const Value.absent(),
          Value<String?> localImagePath = const Value.absent(),
          String? categoryName,
          String? categoryOtherName,
          String? barcode,
          int? categoryId,
          Value<int?> kitchenId = const Value.absent(),
          Value<String?> kitchenName = const Value.absent(),
          Value<String?> deliveryPartner = const Value.absent()}) =>
      Item(
        id: id ?? this.id,
        name: name ?? this.name,
        otherName: otherName ?? this.otherName,
        sku: sku ?? this.sku,
        price: price ?? this.price,
        stock: stock ?? this.stock,
        stockEnabled: stockEnabled ?? this.stockEnabled,
        imagePath: imagePath.present ? imagePath.value : this.imagePath,
        localImagePath:
            localImagePath.present ? localImagePath.value : this.localImagePath,
        categoryName: categoryName ?? this.categoryName,
        categoryOtherName: categoryOtherName ?? this.categoryOtherName,
        barcode: barcode ?? this.barcode,
        categoryId: categoryId ?? this.categoryId,
        kitchenId: kitchenId.present ? kitchenId.value : this.kitchenId,
        kitchenName: kitchenName.present ? kitchenName.value : this.kitchenName,
        deliveryPartner: deliveryPartner.present
            ? deliveryPartner.value
            : this.deliveryPartner,
      );
  Item copyWithCompanion(ItemsCompanion data) {
    return Item(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      otherName: data.otherName.present ? data.otherName.value : this.otherName,
      sku: data.sku.present ? data.sku.value : this.sku,
      price: data.price.present ? data.price.value : this.price,
      stock: data.stock.present ? data.stock.value : this.stock,
      stockEnabled: data.stockEnabled.present
          ? data.stockEnabled.value
          : this.stockEnabled,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      localImagePath: data.localImagePath.present
          ? data.localImagePath.value
          : this.localImagePath,
      categoryName: data.categoryName.present
          ? data.categoryName.value
          : this.categoryName,
      categoryOtherName: data.categoryOtherName.present
          ? data.categoryOtherName.value
          : this.categoryOtherName,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      kitchenId: data.kitchenId.present ? data.kitchenId.value : this.kitchenId,
      kitchenName:
          data.kitchenName.present ? data.kitchenName.value : this.kitchenName,
      deliveryPartner: data.deliveryPartner.present
          ? data.deliveryPartner.value
          : this.deliveryPartner,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Item(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('otherName: $otherName, ')
          ..write('sku: $sku, ')
          ..write('price: $price, ')
          ..write('stock: $stock, ')
          ..write('stockEnabled: $stockEnabled, ')
          ..write('imagePath: $imagePath, ')
          ..write('localImagePath: $localImagePath, ')
          ..write('categoryName: $categoryName, ')
          ..write('categoryOtherName: $categoryOtherName, ')
          ..write('barcode: $barcode, ')
          ..write('categoryId: $categoryId, ')
          ..write('kitchenId: $kitchenId, ')
          ..write('kitchenName: $kitchenName, ')
          ..write('deliveryPartner: $deliveryPartner')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      otherName,
      sku,
      price,
      stock,
      stockEnabled,
      imagePath,
      localImagePath,
      categoryName,
      categoryOtherName,
      barcode,
      categoryId,
      kitchenId,
      kitchenName,
      deliveryPartner);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Item &&
          other.id == this.id &&
          other.name == this.name &&
          other.otherName == this.otherName &&
          other.sku == this.sku &&
          other.price == this.price &&
          other.stock == this.stock &&
          other.stockEnabled == this.stockEnabled &&
          other.imagePath == this.imagePath &&
          other.localImagePath == this.localImagePath &&
          other.categoryName == this.categoryName &&
          other.categoryOtherName == this.categoryOtherName &&
          other.barcode == this.barcode &&
          other.categoryId == this.categoryId &&
          other.kitchenId == this.kitchenId &&
          other.kitchenName == this.kitchenName &&
          other.deliveryPartner == this.deliveryPartner);
}

class ItemsCompanion extends UpdateCompanion<Item> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> otherName;
  final Value<String> sku;
  final Value<double> price;
  final Value<int> stock;
  final Value<bool> stockEnabled;
  final Value<String?> imagePath;
  final Value<String?> localImagePath;
  final Value<String> categoryName;
  final Value<String> categoryOtherName;
  final Value<String> barcode;
  final Value<int> categoryId;
  final Value<int?> kitchenId;
  final Value<String?> kitchenName;
  final Value<String?> deliveryPartner;
  const ItemsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.otherName = const Value.absent(),
    this.sku = const Value.absent(),
    this.price = const Value.absent(),
    this.stock = const Value.absent(),
    this.stockEnabled = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.localImagePath = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.categoryOtherName = const Value.absent(),
    this.barcode = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.kitchenId = const Value.absent(),
    this.kitchenName = const Value.absent(),
    this.deliveryPartner = const Value.absent(),
  });
  ItemsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String otherName,
    required String sku,
    required double price,
    required int stock,
    this.stockEnabled = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.localImagePath = const Value.absent(),
    required String categoryName,
    required String categoryOtherName,
    required String barcode,
    required int categoryId,
    this.kitchenId = const Value.absent(),
    this.kitchenName = const Value.absent(),
    this.deliveryPartner = const Value.absent(),
  })  : name = Value(name),
        otherName = Value(otherName),
        sku = Value(sku),
        price = Value(price),
        stock = Value(stock),
        categoryName = Value(categoryName),
        categoryOtherName = Value(categoryOtherName),
        barcode = Value(barcode),
        categoryId = Value(categoryId);
  static Insertable<Item> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? otherName,
    Expression<String>? sku,
    Expression<double>? price,
    Expression<int>? stock,
    Expression<bool>? stockEnabled,
    Expression<String>? imagePath,
    Expression<String>? localImagePath,
    Expression<String>? categoryName,
    Expression<String>? categoryOtherName,
    Expression<String>? barcode,
    Expression<int>? categoryId,
    Expression<int>? kitchenId,
    Expression<String>? kitchenName,
    Expression<String>? deliveryPartner,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (otherName != null) 'other_name': otherName,
      if (sku != null) 'sku': sku,
      if (price != null) 'price': price,
      if (stock != null) 'stock': stock,
      if (stockEnabled != null) 'stock_enabled': stockEnabled,
      if (imagePath != null) 'image_path': imagePath,
      if (localImagePath != null) 'local_image_path': localImagePath,
      if (categoryName != null) 'category_name': categoryName,
      if (categoryOtherName != null) 'category_other_name': categoryOtherName,
      if (barcode != null) 'barcode': barcode,
      if (categoryId != null) 'category_id': categoryId,
      if (kitchenId != null) 'kitchen_id': kitchenId,
      if (kitchenName != null) 'kitchen_name': kitchenName,
      if (deliveryPartner != null) 'delivery_partner': deliveryPartner,
    });
  }

  ItemsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? otherName,
      Value<String>? sku,
      Value<double>? price,
      Value<int>? stock,
      Value<bool>? stockEnabled,
      Value<String?>? imagePath,
      Value<String?>? localImagePath,
      Value<String>? categoryName,
      Value<String>? categoryOtherName,
      Value<String>? barcode,
      Value<int>? categoryId,
      Value<int?>? kitchenId,
      Value<String?>? kitchenName,
      Value<String?>? deliveryPartner}) {
    return ItemsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      otherName: otherName ?? this.otherName,
      sku: sku ?? this.sku,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      stockEnabled: stockEnabled ?? this.stockEnabled,
      imagePath: imagePath ?? this.imagePath,
      localImagePath: localImagePath ?? this.localImagePath,
      categoryName: categoryName ?? this.categoryName,
      categoryOtherName: categoryOtherName ?? this.categoryOtherName,
      barcode: barcode ?? this.barcode,
      categoryId: categoryId ?? this.categoryId,
      kitchenId: kitchenId ?? this.kitchenId,
      kitchenName: kitchenName ?? this.kitchenName,
      deliveryPartner: deliveryPartner ?? this.deliveryPartner,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (otherName.present) {
      map['other_name'] = Variable<String>(otherName.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (stock.present) {
      map['stock'] = Variable<int>(stock.value);
    }
    if (stockEnabled.present) {
      map['stock_enabled'] = Variable<bool>(stockEnabled.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (localImagePath.present) {
      map['local_image_path'] = Variable<String>(localImagePath.value);
    }
    if (categoryName.present) {
      map['category_name'] = Variable<String>(categoryName.value);
    }
    if (categoryOtherName.present) {
      map['category_other_name'] = Variable<String>(categoryOtherName.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (kitchenId.present) {
      map['kitchen_id'] = Variable<int>(kitchenId.value);
    }
    if (kitchenName.present) {
      map['kitchen_name'] = Variable<String>(kitchenName.value);
    }
    if (deliveryPartner.present) {
      map['delivery_partner'] = Variable<String>(deliveryPartner.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('otherName: $otherName, ')
          ..write('sku: $sku, ')
          ..write('price: $price, ')
          ..write('stock: $stock, ')
          ..write('stockEnabled: $stockEnabled, ')
          ..write('imagePath: $imagePath, ')
          ..write('localImagePath: $localImagePath, ')
          ..write('categoryName: $categoryName, ')
          ..write('categoryOtherName: $categoryOtherName, ')
          ..write('barcode: $barcode, ')
          ..write('categoryId: $categoryId, ')
          ..write('kitchenId: $kitchenId, ')
          ..write('kitchenName: $kitchenName, ')
          ..write('deliveryPartner: $deliveryPartner')
          ..write(')'))
        .toString();
  }
}

class $ItemVariantsTable extends ItemVariants
    with TableInfo<$ItemVariantsTable, ItemVariant> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemVariantsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
      'item_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
      'price', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, itemId, name, price];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'item_variants';
  @override
  VerificationContext validateIntegrity(Insertable<ItemVariant> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('item_id')) {
      context.handle(_itemIdMeta,
          itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta));
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
          _priceMeta, price.isAcceptableOrUnknown(data['price']!, _priceMeta));
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {itemId, name},
      ];
  @override
  ItemVariant map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemVariant(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      itemId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}item_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      price: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}price'])!,
    );
  }

  @override
  $ItemVariantsTable createAlias(String alias) {
    return $ItemVariantsTable(attachedDatabase, alias);
  }
}

class ItemVariant extends DataClass implements Insertable<ItemVariant> {
  final int id;
  final int itemId;
  final String name;
  final double price;
  const ItemVariant(
      {required this.id,
      required this.itemId,
      required this.name,
      required this.price});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['item_id'] = Variable<int>(itemId);
    map['name'] = Variable<String>(name);
    map['price'] = Variable<double>(price);
    return map;
  }

  ItemVariantsCompanion toCompanion(bool nullToAbsent) {
    return ItemVariantsCompanion(
      id: Value(id),
      itemId: Value(itemId),
      name: Value(name),
      price: Value(price),
    );
  }

  factory ItemVariant.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemVariant(
      id: serializer.fromJson<int>(json['id']),
      itemId: serializer.fromJson<int>(json['itemId']),
      name: serializer.fromJson<String>(json['name']),
      price: serializer.fromJson<double>(json['price']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'itemId': serializer.toJson<int>(itemId),
      'name': serializer.toJson<String>(name),
      'price': serializer.toJson<double>(price),
    };
  }

  ItemVariant copyWith({int? id, int? itemId, String? name, double? price}) =>
      ItemVariant(
        id: id ?? this.id,
        itemId: itemId ?? this.itemId,
        name: name ?? this.name,
        price: price ?? this.price,
      );
  ItemVariant copyWithCompanion(ItemVariantsCompanion data) {
    return ItemVariant(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      name: data.name.present ? data.name.value : this.name,
      price: data.price.present ? data.price.value : this.price,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemVariant(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('name: $name, ')
          ..write('price: $price')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, itemId, name, price);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemVariant &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.name == this.name &&
          other.price == this.price);
}

class ItemVariantsCompanion extends UpdateCompanion<ItemVariant> {
  final Value<int> id;
  final Value<int> itemId;
  final Value<String> name;
  final Value<double> price;
  const ItemVariantsCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.name = const Value.absent(),
    this.price = const Value.absent(),
  });
  ItemVariantsCompanion.insert({
    this.id = const Value.absent(),
    required int itemId,
    required String name,
    required double price,
  })  : itemId = Value(itemId),
        name = Value(name),
        price = Value(price);
  static Insertable<ItemVariant> custom({
    Expression<int>? id,
    Expression<int>? itemId,
    Expression<String>? name,
    Expression<double>? price,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (name != null) 'name': name,
      if (price != null) 'price': price,
    });
  }

  ItemVariantsCompanion copyWith(
      {Value<int>? id,
      Value<int>? itemId,
      Value<String>? name,
      Value<double>? price}) {
    return ItemVariantsCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      price: price ?? this.price,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemVariantsCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('name: $name, ')
          ..write('price: $price')
          ..write(')'))
        .toString();
  }
}

class $ItemToppingsTable extends ItemToppings
    with TableInfo<$ItemToppingsTable, ItemTopping> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemToppingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
      'item_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
      'price', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _maxQtyMeta = const VerificationMeta('maxQty');
  @override
  late final GeneratedColumn<int> maxQty = GeneratedColumn<int>(
      'max_qty', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _maximumMeta =
      const VerificationMeta('maximum');
  @override
  late final GeneratedColumn<int> maximum = GeneratedColumn<int>(
      'maximum', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, itemId, name, price, maxQty, maximum];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'item_toppings';
  @override
  VerificationContext validateIntegrity(Insertable<ItemTopping> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('item_id')) {
      context.handle(_itemIdMeta,
          itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta));
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
          _priceMeta, price.isAcceptableOrUnknown(data['price']!, _priceMeta));
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('max_qty')) {
      context.handle(_maxQtyMeta,
          maxQty.isAcceptableOrUnknown(data['max_qty']!, _maxQtyMeta));
    }
    if (data.containsKey('maximum')) {
      context.handle(_maximumMeta,
          maximum.isAcceptableOrUnknown(data['maximum']!, _maximumMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {itemId, name},
      ];
  @override
  ItemTopping map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemTopping(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      itemId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}item_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      price: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}price'])!,
      maxQty: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}max_qty'])!,
      maximum: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}maximum']),
    );
  }

  @override
  $ItemToppingsTable createAlias(String alias) {
    return $ItemToppingsTable(attachedDatabase, alias);
  }
}

class ItemTopping extends DataClass implements Insertable<ItemTopping> {
  final int id;
  final int itemId;
  final String name;
  final double price;
  final int maxQty;
  final int? maximum;
  const ItemTopping(
      {required this.id,
      required this.itemId,
      required this.name,
      required this.price,
      required this.maxQty,
      this.maximum});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['item_id'] = Variable<int>(itemId);
    map['name'] = Variable<String>(name);
    map['price'] = Variable<double>(price);
    map['max_qty'] = Variable<int>(maxQty);
    if (!nullToAbsent || maximum != null) {
      map['maximum'] = Variable<int>(maximum);
    }
    return map;
  }

  ItemToppingsCompanion toCompanion(bool nullToAbsent) {
    return ItemToppingsCompanion(
      id: Value(id),
      itemId: Value(itemId),
      name: Value(name),
      price: Value(price),
      maxQty: Value(maxQty),
      maximum: maximum == null && nullToAbsent
          ? const Value.absent()
          : Value(maximum),
    );
  }

  factory ItemTopping.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemTopping(
      id: serializer.fromJson<int>(json['id']),
      itemId: serializer.fromJson<int>(json['itemId']),
      name: serializer.fromJson<String>(json['name']),
      price: serializer.fromJson<double>(json['price']),
      maxQty: serializer.fromJson<int>(json['maxQty']),
      maximum: serializer.fromJson<int?>(json['maximum']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'itemId': serializer.toJson<int>(itemId),
      'name': serializer.toJson<String>(name),
      'price': serializer.toJson<double>(price),
      'maxQty': serializer.toJson<int>(maxQty),
      'maximum': serializer.toJson<int?>(maximum),
    };
  }

  ItemTopping copyWith(
          {int? id,
          int? itemId,
          String? name,
          double? price,
          int? maxQty,
          Value<int?> maximum = const Value.absent()}) =>
      ItemTopping(
        id: id ?? this.id,
        itemId: itemId ?? this.itemId,
        name: name ?? this.name,
        price: price ?? this.price,
        maxQty: maxQty ?? this.maxQty,
        maximum: maximum.present ? maximum.value : this.maximum,
      );
  ItemTopping copyWithCompanion(ItemToppingsCompanion data) {
    return ItemTopping(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      name: data.name.present ? data.name.value : this.name,
      price: data.price.present ? data.price.value : this.price,
      maxQty: data.maxQty.present ? data.maxQty.value : this.maxQty,
      maximum: data.maximum.present ? data.maximum.value : this.maximum,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemTopping(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('name: $name, ')
          ..write('price: $price, ')
          ..write('maxQty: $maxQty, ')
          ..write('maximum: $maximum')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, itemId, name, price, maxQty, maximum);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemTopping &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.name == this.name &&
          other.price == this.price &&
          other.maxQty == this.maxQty &&
          other.maximum == this.maximum);
}

class ItemToppingsCompanion extends UpdateCompanion<ItemTopping> {
  final Value<int> id;
  final Value<int> itemId;
  final Value<String> name;
  final Value<double> price;
  final Value<int> maxQty;
  final Value<int?> maximum;
  const ItemToppingsCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.name = const Value.absent(),
    this.price = const Value.absent(),
    this.maxQty = const Value.absent(),
    this.maximum = const Value.absent(),
  });
  ItemToppingsCompanion.insert({
    this.id = const Value.absent(),
    required int itemId,
    required String name,
    required double price,
    this.maxQty = const Value.absent(),
    this.maximum = const Value.absent(),
  })  : itemId = Value(itemId),
        name = Value(name),
        price = Value(price);
  static Insertable<ItemTopping> custom({
    Expression<int>? id,
    Expression<int>? itemId,
    Expression<String>? name,
    Expression<double>? price,
    Expression<int>? maxQty,
    Expression<int>? maximum,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (name != null) 'name': name,
      if (price != null) 'price': price,
      if (maxQty != null) 'max_qty': maxQty,
      if (maximum != null) 'maximum': maximum,
    });
  }

  ItemToppingsCompanion copyWith(
      {Value<int>? id,
      Value<int>? itemId,
      Value<String>? name,
      Value<double>? price,
      Value<int>? maxQty,
      Value<int?>? maximum}) {
    return ItemToppingsCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      price: price ?? this.price,
      maxQty: maxQty ?? this.maxQty,
      maximum: maximum ?? this.maximum,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (maxQty.present) {
      map['max_qty'] = Variable<int>(maxQty.value);
    }
    if (maximum.present) {
      map['maximum'] = Variable<int>(maximum.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemToppingsCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('name: $name, ')
          ..write('price: $price, ')
          ..write('maxQty: $maxQty, ')
          ..write('maximum: $maximum')
          ..write(')'))
        .toString();
  }
}

class $ToppingGroupsTable extends ToppingGroups
    with TableInfo<$ToppingGroupsTable, ToppingGroup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ToppingGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
      'item_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _minMeta = const VerificationMeta('min');
  @override
  late final GeneratedColumn<int> min = GeneratedColumn<int>(
      'min', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _maxMeta = const VerificationMeta('max');
  @override
  late final GeneratedColumn<int> max = GeneratedColumn<int>(
      'max', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [id, itemId, name, min, max];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'topping_groups';
  @override
  VerificationContext validateIntegrity(Insertable<ToppingGroup> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('item_id')) {
      context.handle(_itemIdMeta,
          itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta));
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('min')) {
      context.handle(
          _minMeta, min.isAcceptableOrUnknown(data['min']!, _minMeta));
    }
    if (data.containsKey('max')) {
      context.handle(
          _maxMeta, max.isAcceptableOrUnknown(data['max']!, _maxMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ToppingGroup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ToppingGroup(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      itemId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}item_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      min: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}min'])!,
      max: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}max'])!,
    );
  }

  @override
  $ToppingGroupsTable createAlias(String alias) {
    return $ToppingGroupsTable(attachedDatabase, alias);
  }
}

class ToppingGroup extends DataClass implements Insertable<ToppingGroup> {
  final int id;
  final int itemId;
  final String name;
  final int min;
  final int max;
  const ToppingGroup(
      {required this.id,
      required this.itemId,
      required this.name,
      required this.min,
      required this.max});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['item_id'] = Variable<int>(itemId);
    map['name'] = Variable<String>(name);
    map['min'] = Variable<int>(min);
    map['max'] = Variable<int>(max);
    return map;
  }

  ToppingGroupsCompanion toCompanion(bool nullToAbsent) {
    return ToppingGroupsCompanion(
      id: Value(id),
      itemId: Value(itemId),
      name: Value(name),
      min: Value(min),
      max: Value(max),
    );
  }

  factory ToppingGroup.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ToppingGroup(
      id: serializer.fromJson<int>(json['id']),
      itemId: serializer.fromJson<int>(json['itemId']),
      name: serializer.fromJson<String>(json['name']),
      min: serializer.fromJson<int>(json['min']),
      max: serializer.fromJson<int>(json['max']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'itemId': serializer.toJson<int>(itemId),
      'name': serializer.toJson<String>(name),
      'min': serializer.toJson<int>(min),
      'max': serializer.toJson<int>(max),
    };
  }

  ToppingGroup copyWith(
          {int? id, int? itemId, String? name, int? min, int? max}) =>
      ToppingGroup(
        id: id ?? this.id,
        itemId: itemId ?? this.itemId,
        name: name ?? this.name,
        min: min ?? this.min,
        max: max ?? this.max,
      );
  ToppingGroup copyWithCompanion(ToppingGroupsCompanion data) {
    return ToppingGroup(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      name: data.name.present ? data.name.value : this.name,
      min: data.min.present ? data.min.value : this.min,
      max: data.max.present ? data.max.value : this.max,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ToppingGroup(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('name: $name, ')
          ..write('min: $min, ')
          ..write('max: $max')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, itemId, name, min, max);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ToppingGroup &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.name == this.name &&
          other.min == this.min &&
          other.max == this.max);
}

class ToppingGroupsCompanion extends UpdateCompanion<ToppingGroup> {
  final Value<int> id;
  final Value<int> itemId;
  final Value<String> name;
  final Value<int> min;
  final Value<int> max;
  const ToppingGroupsCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.name = const Value.absent(),
    this.min = const Value.absent(),
    this.max = const Value.absent(),
  });
  ToppingGroupsCompanion.insert({
    this.id = const Value.absent(),
    required int itemId,
    required String name,
    this.min = const Value.absent(),
    this.max = const Value.absent(),
  })  : itemId = Value(itemId),
        name = Value(name);
  static Insertable<ToppingGroup> custom({
    Expression<int>? id,
    Expression<int>? itemId,
    Expression<String>? name,
    Expression<int>? min,
    Expression<int>? max,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (name != null) 'name': name,
      if (min != null) 'min': min,
      if (max != null) 'max': max,
    });
  }

  ToppingGroupsCompanion copyWith(
      {Value<int>? id,
      Value<int>? itemId,
      Value<String>? name,
      Value<int>? min,
      Value<int>? max}) {
    return ToppingGroupsCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      min: min ?? this.min,
      max: max ?? this.max,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (min.present) {
      map['min'] = Variable<int>(min.value);
    }
    if (max.present) {
      map['max'] = Variable<int>(max.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ToppingGroupsCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('name: $name, ')
          ..write('min: $min, ')
          ..write('max: $max')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions with TableInfo<$SessionsTable, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
      'user_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _branchIdMeta =
      const VerificationMeta('branchId');
  @override
  late final GeneratedColumn<int> branchId = GeneratedColumn<int>(
      'branch_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _activeCartIdMeta =
      const VerificationMeta('activeCartId');
  @override
  late final GeneratedColumn<int> activeCartId = GeneratedColumn<int>(
      'active_cart_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, userId, branchId, role, activeCartId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(Insertable<Session> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(_branchIdMeta,
          branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta));
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('active_cart_id')) {
      context.handle(
          _activeCartIdMeta,
          activeCartId.isAcceptableOrUnknown(
              data['active_cart_id']!, _activeCartIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}user_id'])!,
      branchId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}branch_id'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      activeCartId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}active_cart_id']),
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class Session extends DataClass implements Insertable<Session> {
  final int id;
  final int userId;

  /// Default for SQLite ALTER (legacy DBs that lacked this column). Real logins set explicitly.
  final int branchId;
  final String role;

  /// Current draft cart id for Take Away (persisted so cart survives navigation/reload).
  final int? activeCartId;
  const Session(
      {required this.id,
      required this.userId,
      required this.branchId,
      required this.role,
      this.activeCartId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<int>(userId);
    map['branch_id'] = Variable<int>(branchId);
    map['role'] = Variable<String>(role);
    if (!nullToAbsent || activeCartId != null) {
      map['active_cart_id'] = Variable<int>(activeCartId);
    }
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      userId: Value(userId),
      branchId: Value(branchId),
      role: Value(role),
      activeCartId: activeCartId == null && nullToAbsent
          ? const Value.absent()
          : Value(activeCartId),
    );
  }

  factory Session.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Session(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      branchId: serializer.fromJson<int>(json['branchId']),
      role: serializer.fromJson<String>(json['role']),
      activeCartId: serializer.fromJson<int?>(json['activeCartId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int>(userId),
      'branchId': serializer.toJson<int>(branchId),
      'role': serializer.toJson<String>(role),
      'activeCartId': serializer.toJson<int?>(activeCartId),
    };
  }

  Session copyWith(
          {int? id,
          int? userId,
          int? branchId,
          String? role,
          Value<int?> activeCartId = const Value.absent()}) =>
      Session(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        branchId: branchId ?? this.branchId,
        role: role ?? this.role,
        activeCartId:
            activeCartId.present ? activeCartId.value : this.activeCartId,
      );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      role: data.role.present ? data.role.value : this.role,
      activeCartId: data.activeCartId.present
          ? data.activeCartId.value
          : this.activeCartId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('branchId: $branchId, ')
          ..write('role: $role, ')
          ..write('activeCartId: $activeCartId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, branchId, role, activeCartId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.branchId == this.branchId &&
          other.role == this.role &&
          other.activeCartId == this.activeCartId);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<int> id;
  final Value<int> userId;
  final Value<int> branchId;
  final Value<String> role;
  final Value<int?> activeCartId;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.role = const Value.absent(),
    this.activeCartId = const Value.absent(),
  });
  SessionsCompanion.insert({
    this.id = const Value.absent(),
    required int userId,
    this.branchId = const Value.absent(),
    required String role,
    this.activeCartId = const Value.absent(),
  })  : userId = Value(userId),
        role = Value(role);
  static Insertable<Session> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<int>? branchId,
    Expression<String>? role,
    Expression<int>? activeCartId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (branchId != null) 'branch_id': branchId,
      if (role != null) 'role': role,
      if (activeCartId != null) 'active_cart_id': activeCartId,
    });
  }

  SessionsCompanion copyWith(
      {Value<int>? id,
      Value<int>? userId,
      Value<int>? branchId,
      Value<String>? role,
      Value<int?>? activeCartId}) {
    return SessionsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      branchId: branchId ?? this.branchId,
      role: role ?? this.role,
      activeCartId: activeCartId ?? this.activeCartId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<int>(branchId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (activeCartId.present) {
      map['active_cart_id'] = Variable<int>(activeCartId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('branchId: $branchId, ')
          ..write('role: $role, ')
          ..write('activeCartId: $activeCartId')
          ..write(')'))
        .toString();
  }
}

class $CartsTable extends Carts with TableInfo<$CartsTable, Cart> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CartsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _invoiceNumberMeta =
      const VerificationMeta('invoiceNumber');
  @override
  late final GeneratedColumn<String> invoiceNumber = GeneratedColumn<String>(
      'invoice_number', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _orderTypeMeta =
      const VerificationMeta('orderType');
  @override
  late final GeneratedColumn<String> orderType = GeneratedColumn<String>(
      'order_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('take_away'));
  static const VerificationMeta _deliveryPartnerMeta =
      const VerificationMeta('deliveryPartner');
  @override
  late final GeneratedColumn<String> deliveryPartner = GeneratedColumn<String>(
      'delivery_partner', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, invoiceNumber, createdAt, orderType, deliveryPartner];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'carts';
  @override
  VerificationContext validateIntegrity(Insertable<Cart> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('invoice_number')) {
      context.handle(
          _invoiceNumberMeta,
          invoiceNumber.isAcceptableOrUnknown(
              data['invoice_number']!, _invoiceNumberMeta));
    } else if (isInserting) {
      context.missing(_invoiceNumberMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('order_type')) {
      context.handle(_orderTypeMeta,
          orderType.isAcceptableOrUnknown(data['order_type']!, _orderTypeMeta));
    }
    if (data.containsKey('delivery_partner')) {
      context.handle(
          _deliveryPartnerMeta,
          deliveryPartner.isAcceptableOrUnknown(
              data['delivery_partner']!, _deliveryPartnerMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Cart map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Cart(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      invoiceNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}invoice_number'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      orderType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}order_type'])!,
      deliveryPartner: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}delivery_partner']),
    );
  }

  @override
  $CartsTable createAlias(String alias) {
    return $CartsTable(attachedDatabase, alias);
  }
}

class Cart extends DataClass implements Insertable<Cart> {
  final int id;
  final String invoiceNumber;
  final DateTime createdAt;

  /// 'take_away' | 'delivery' | 'dine_in'
  final String orderType;

  /// Delivery partner name (Swiggy, Zomato, etc.) when orderType is 'delivery'
  final String? deliveryPartner;
  const Cart(
      {required this.id,
      required this.invoiceNumber,
      required this.createdAt,
      required this.orderType,
      this.deliveryPartner});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['invoice_number'] = Variable<String>(invoiceNumber);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['order_type'] = Variable<String>(orderType);
    if (!nullToAbsent || deliveryPartner != null) {
      map['delivery_partner'] = Variable<String>(deliveryPartner);
    }
    return map;
  }

  CartsCompanion toCompanion(bool nullToAbsent) {
    return CartsCompanion(
      id: Value(id),
      invoiceNumber: Value(invoiceNumber),
      createdAt: Value(createdAt),
      orderType: Value(orderType),
      deliveryPartner: deliveryPartner == null && nullToAbsent
          ? const Value.absent()
          : Value(deliveryPartner),
    );
  }

  factory Cart.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Cart(
      id: serializer.fromJson<int>(json['id']),
      invoiceNumber: serializer.fromJson<String>(json['invoiceNumber']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      orderType: serializer.fromJson<String>(json['orderType']),
      deliveryPartner: serializer.fromJson<String?>(json['deliveryPartner']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'invoiceNumber': serializer.toJson<String>(invoiceNumber),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'orderType': serializer.toJson<String>(orderType),
      'deliveryPartner': serializer.toJson<String?>(deliveryPartner),
    };
  }

  Cart copyWith(
          {int? id,
          String? invoiceNumber,
          DateTime? createdAt,
          String? orderType,
          Value<String?> deliveryPartner = const Value.absent()}) =>
      Cart(
        id: id ?? this.id,
        invoiceNumber: invoiceNumber ?? this.invoiceNumber,
        createdAt: createdAt ?? this.createdAt,
        orderType: orderType ?? this.orderType,
        deliveryPartner: deliveryPartner.present
            ? deliveryPartner.value
            : this.deliveryPartner,
      );
  Cart copyWithCompanion(CartsCompanion data) {
    return Cart(
      id: data.id.present ? data.id.value : this.id,
      invoiceNumber: data.invoiceNumber.present
          ? data.invoiceNumber.value
          : this.invoiceNumber,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      orderType: data.orderType.present ? data.orderType.value : this.orderType,
      deliveryPartner: data.deliveryPartner.present
          ? data.deliveryPartner.value
          : this.deliveryPartner,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Cart(')
          ..write('id: $id, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('createdAt: $createdAt, ')
          ..write('orderType: $orderType, ')
          ..write('deliveryPartner: $deliveryPartner')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, invoiceNumber, createdAt, orderType, deliveryPartner);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Cart &&
          other.id == this.id &&
          other.invoiceNumber == this.invoiceNumber &&
          other.createdAt == this.createdAt &&
          other.orderType == this.orderType &&
          other.deliveryPartner == this.deliveryPartner);
}

class CartsCompanion extends UpdateCompanion<Cart> {
  final Value<int> id;
  final Value<String> invoiceNumber;
  final Value<DateTime> createdAt;
  final Value<String> orderType;
  final Value<String?> deliveryPartner;
  const CartsCompanion({
    this.id = const Value.absent(),
    this.invoiceNumber = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.orderType = const Value.absent(),
    this.deliveryPartner = const Value.absent(),
  });
  CartsCompanion.insert({
    this.id = const Value.absent(),
    required String invoiceNumber,
    required DateTime createdAt,
    this.orderType = const Value.absent(),
    this.deliveryPartner = const Value.absent(),
  })  : invoiceNumber = Value(invoiceNumber),
        createdAt = Value(createdAt);
  static Insertable<Cart> custom({
    Expression<int>? id,
    Expression<String>? invoiceNumber,
    Expression<DateTime>? createdAt,
    Expression<String>? orderType,
    Expression<String>? deliveryPartner,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (invoiceNumber != null) 'invoice_number': invoiceNumber,
      if (createdAt != null) 'created_at': createdAt,
      if (orderType != null) 'order_type': orderType,
      if (deliveryPartner != null) 'delivery_partner': deliveryPartner,
    });
  }

  CartsCompanion copyWith(
      {Value<int>? id,
      Value<String>? invoiceNumber,
      Value<DateTime>? createdAt,
      Value<String>? orderType,
      Value<String?>? deliveryPartner}) {
    return CartsCompanion(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      createdAt: createdAt ?? this.createdAt,
      orderType: orderType ?? this.orderType,
      deliveryPartner: deliveryPartner ?? this.deliveryPartner,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (invoiceNumber.present) {
      map['invoice_number'] = Variable<String>(invoiceNumber.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (orderType.present) {
      map['order_type'] = Variable<String>(orderType.value);
    }
    if (deliveryPartner.present) {
      map['delivery_partner'] = Variable<String>(deliveryPartner.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CartsCompanion(')
          ..write('id: $id, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('createdAt: $createdAt, ')
          ..write('orderType: $orderType, ')
          ..write('deliveryPartner: $deliveryPartner')
          ..write(')'))
        .toString();
  }
}

class $CartItemsTable extends CartItems
    with TableInfo<$CartItemsTable, CartItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CartItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _cartIdMeta = const VerificationMeta('cartId');
  @override
  late final GeneratedColumn<int> cartId = GeneratedColumn<int>(
      'cart_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES carts (id)'));
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
      'item_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES items (id)'));
  static const VerificationMeta _itemVariantIdMeta =
      const VerificationMeta('itemVariantId');
  @override
  late final GeneratedColumn<int> itemVariantId = GeneratedColumn<int>(
      'item_variant_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES item_variants (id)'));
  static const VerificationMeta _itemToppingIdMeta =
      const VerificationMeta('itemToppingId');
  @override
  late final GeneratedColumn<int> itemToppingId = GeneratedColumn<int>(
      'item_topping_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES item_toppings (id)'));
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
      'quantity', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<double> total = GeneratedColumn<double>(
      'total', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _discountMeta =
      const VerificationMeta('discount');
  @override
  late final GeneratedColumn<double> discount = GeneratedColumn<double>(
      'discount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _discountTypeMeta =
      const VerificationMeta('discountType');
  @override
  late final GeneratedColumn<String> discountType = GeneratedColumn<String>(
      'discount_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        cartId,
        itemId,
        itemVariantId,
        itemToppingId,
        quantity,
        total,
        discount,
        discountType,
        notes
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cart_items';
  @override
  VerificationContext validateIntegrity(Insertable<CartItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('cart_id')) {
      context.handle(_cartIdMeta,
          cartId.isAcceptableOrUnknown(data['cart_id']!, _cartIdMeta));
    } else if (isInserting) {
      context.missing(_cartIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(_itemIdMeta,
          itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta));
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('item_variant_id')) {
      context.handle(
          _itemVariantIdMeta,
          itemVariantId.isAcceptableOrUnknown(
              data['item_variant_id']!, _itemVariantIdMeta));
    }
    if (data.containsKey('item_topping_id')) {
      context.handle(
          _itemToppingIdMeta,
          itemToppingId.isAcceptableOrUnknown(
              data['item_topping_id']!, _itemToppingIdMeta));
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('total')) {
      context.handle(
          _totalMeta, total.isAcceptableOrUnknown(data['total']!, _totalMeta));
    }
    if (data.containsKey('discount')) {
      context.handle(_discountMeta,
          discount.isAcceptableOrUnknown(data['discount']!, _discountMeta));
    }
    if (data.containsKey('discount_type')) {
      context.handle(
          _discountTypeMeta,
          discountType.isAcceptableOrUnknown(
              data['discount_type']!, _discountTypeMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CartItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CartItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      cartId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cart_id'])!,
      itemId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}item_id'])!,
      itemVariantId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}item_variant_id']),
      itemToppingId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}item_topping_id']),
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}quantity'])!,
      total: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total'])!,
      discount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}discount'])!,
      discountType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}discount_type']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
    );
  }

  @override
  $CartItemsTable createAlias(String alias) {
    return $CartItemsTable(attachedDatabase, alias);
  }
}

class CartItem extends DataClass implements Insertable<CartItem> {
  final int id;
  final int cartId;
  final int itemId;
  final int? itemVariantId;
  final int? itemToppingId;
  final int quantity;
  final double total;
  final double discount;
  final String? discountType;
  final String? notes;
  const CartItem(
      {required this.id,
      required this.cartId,
      required this.itemId,
      this.itemVariantId,
      this.itemToppingId,
      required this.quantity,
      required this.total,
      required this.discount,
      this.discountType,
      this.notes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['cart_id'] = Variable<int>(cartId);
    map['item_id'] = Variable<int>(itemId);
    if (!nullToAbsent || itemVariantId != null) {
      map['item_variant_id'] = Variable<int>(itemVariantId);
    }
    if (!nullToAbsent || itemToppingId != null) {
      map['item_topping_id'] = Variable<int>(itemToppingId);
    }
    map['quantity'] = Variable<int>(quantity);
    map['total'] = Variable<double>(total);
    map['discount'] = Variable<double>(discount);
    if (!nullToAbsent || discountType != null) {
      map['discount_type'] = Variable<String>(discountType);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  CartItemsCompanion toCompanion(bool nullToAbsent) {
    return CartItemsCompanion(
      id: Value(id),
      cartId: Value(cartId),
      itemId: Value(itemId),
      itemVariantId: itemVariantId == null && nullToAbsent
          ? const Value.absent()
          : Value(itemVariantId),
      itemToppingId: itemToppingId == null && nullToAbsent
          ? const Value.absent()
          : Value(itemToppingId),
      quantity: Value(quantity),
      total: Value(total),
      discount: Value(discount),
      discountType: discountType == null && nullToAbsent
          ? const Value.absent()
          : Value(discountType),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
    );
  }

  factory CartItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CartItem(
      id: serializer.fromJson<int>(json['id']),
      cartId: serializer.fromJson<int>(json['cartId']),
      itemId: serializer.fromJson<int>(json['itemId']),
      itemVariantId: serializer.fromJson<int?>(json['itemVariantId']),
      itemToppingId: serializer.fromJson<int?>(json['itemToppingId']),
      quantity: serializer.fromJson<int>(json['quantity']),
      total: serializer.fromJson<double>(json['total']),
      discount: serializer.fromJson<double>(json['discount']),
      discountType: serializer.fromJson<String?>(json['discountType']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cartId': serializer.toJson<int>(cartId),
      'itemId': serializer.toJson<int>(itemId),
      'itemVariantId': serializer.toJson<int?>(itemVariantId),
      'itemToppingId': serializer.toJson<int?>(itemToppingId),
      'quantity': serializer.toJson<int>(quantity),
      'total': serializer.toJson<double>(total),
      'discount': serializer.toJson<double>(discount),
      'discountType': serializer.toJson<String?>(discountType),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  CartItem copyWith(
          {int? id,
          int? cartId,
          int? itemId,
          Value<int?> itemVariantId = const Value.absent(),
          Value<int?> itemToppingId = const Value.absent(),
          int? quantity,
          double? total,
          double? discount,
          Value<String?> discountType = const Value.absent(),
          Value<String?> notes = const Value.absent()}) =>
      CartItem(
        id: id ?? this.id,
        cartId: cartId ?? this.cartId,
        itemId: itemId ?? this.itemId,
        itemVariantId:
            itemVariantId.present ? itemVariantId.value : this.itemVariantId,
        itemToppingId:
            itemToppingId.present ? itemToppingId.value : this.itemToppingId,
        quantity: quantity ?? this.quantity,
        total: total ?? this.total,
        discount: discount ?? this.discount,
        discountType:
            discountType.present ? discountType.value : this.discountType,
        notes: notes.present ? notes.value : this.notes,
      );
  CartItem copyWithCompanion(CartItemsCompanion data) {
    return CartItem(
      id: data.id.present ? data.id.value : this.id,
      cartId: data.cartId.present ? data.cartId.value : this.cartId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      itemVariantId: data.itemVariantId.present
          ? data.itemVariantId.value
          : this.itemVariantId,
      itemToppingId: data.itemToppingId.present
          ? data.itemToppingId.value
          : this.itemToppingId,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      total: data.total.present ? data.total.value : this.total,
      discount: data.discount.present ? data.discount.value : this.discount,
      discountType: data.discountType.present
          ? data.discountType.value
          : this.discountType,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CartItem(')
          ..write('id: $id, ')
          ..write('cartId: $cartId, ')
          ..write('itemId: $itemId, ')
          ..write('itemVariantId: $itemVariantId, ')
          ..write('itemToppingId: $itemToppingId, ')
          ..write('quantity: $quantity, ')
          ..write('total: $total, ')
          ..write('discount: $discount, ')
          ..write('discountType: $discountType, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, cartId, itemId, itemVariantId,
      itemToppingId, quantity, total, discount, discountType, notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CartItem &&
          other.id == this.id &&
          other.cartId == this.cartId &&
          other.itemId == this.itemId &&
          other.itemVariantId == this.itemVariantId &&
          other.itemToppingId == this.itemToppingId &&
          other.quantity == this.quantity &&
          other.total == this.total &&
          other.discount == this.discount &&
          other.discountType == this.discountType &&
          other.notes == this.notes);
}

class CartItemsCompanion extends UpdateCompanion<CartItem> {
  final Value<int> id;
  final Value<int> cartId;
  final Value<int> itemId;
  final Value<int?> itemVariantId;
  final Value<int?> itemToppingId;
  final Value<int> quantity;
  final Value<double> total;
  final Value<double> discount;
  final Value<String?> discountType;
  final Value<String?> notes;
  const CartItemsCompanion({
    this.id = const Value.absent(),
    this.cartId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.itemVariantId = const Value.absent(),
    this.itemToppingId = const Value.absent(),
    this.quantity = const Value.absent(),
    this.total = const Value.absent(),
    this.discount = const Value.absent(),
    this.discountType = const Value.absent(),
    this.notes = const Value.absent(),
  });
  CartItemsCompanion.insert({
    this.id = const Value.absent(),
    required int cartId,
    required int itemId,
    this.itemVariantId = const Value.absent(),
    this.itemToppingId = const Value.absent(),
    required int quantity,
    this.total = const Value.absent(),
    this.discount = const Value.absent(),
    this.discountType = const Value.absent(),
    this.notes = const Value.absent(),
  })  : cartId = Value(cartId),
        itemId = Value(itemId),
        quantity = Value(quantity);
  static Insertable<CartItem> custom({
    Expression<int>? id,
    Expression<int>? cartId,
    Expression<int>? itemId,
    Expression<int>? itemVariantId,
    Expression<int>? itemToppingId,
    Expression<int>? quantity,
    Expression<double>? total,
    Expression<double>? discount,
    Expression<String>? discountType,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cartId != null) 'cart_id': cartId,
      if (itemId != null) 'item_id': itemId,
      if (itemVariantId != null) 'item_variant_id': itemVariantId,
      if (itemToppingId != null) 'item_topping_id': itemToppingId,
      if (quantity != null) 'quantity': quantity,
      if (total != null) 'total': total,
      if (discount != null) 'discount': discount,
      if (discountType != null) 'discount_type': discountType,
      if (notes != null) 'notes': notes,
    });
  }

  CartItemsCompanion copyWith(
      {Value<int>? id,
      Value<int>? cartId,
      Value<int>? itemId,
      Value<int?>? itemVariantId,
      Value<int?>? itemToppingId,
      Value<int>? quantity,
      Value<double>? total,
      Value<double>? discount,
      Value<String?>? discountType,
      Value<String?>? notes}) {
    return CartItemsCompanion(
      id: id ?? this.id,
      cartId: cartId ?? this.cartId,
      itemId: itemId ?? this.itemId,
      itemVariantId: itemVariantId ?? this.itemVariantId,
      itemToppingId: itemToppingId ?? this.itemToppingId,
      quantity: quantity ?? this.quantity,
      total: total ?? this.total,
      discount: discount ?? this.discount,
      discountType: discountType ?? this.discountType,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cartId.present) {
      map['cart_id'] = Variable<int>(cartId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (itemVariantId.present) {
      map['item_variant_id'] = Variable<int>(itemVariantId.value);
    }
    if (itemToppingId.present) {
      map['item_topping_id'] = Variable<int>(itemToppingId.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (total.present) {
      map['total'] = Variable<double>(total.value);
    }
    if (discount.present) {
      map['discount'] = Variable<double>(discount.value);
    }
    if (discountType.present) {
      map['discount_type'] = Variable<String>(discountType.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CartItemsCompanion(')
          ..write('id: $id, ')
          ..write('cartId: $cartId, ')
          ..write('itemId: $itemId, ')
          ..write('itemVariantId: $itemVariantId, ')
          ..write('itemToppingId: $itemToppingId, ')
          ..write('quantity: $quantity, ')
          ..write('total: $total, ')
          ..write('discount: $discount, ')
          ..write('discountType: $discountType, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $DriversTable extends Drivers with TableInfo<$DriversTable, Driver> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DriversTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'drivers';
  @override
  VerificationContext validateIntegrity(Insertable<Driver> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Driver map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Driver(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
    );
  }

  @override
  $DriversTable createAlias(String alias) {
    return $DriversTable(attachedDatabase, alias);
  }
}

class Driver extends DataClass implements Insertable<Driver> {
  final int id;
  final String name;
  const Driver({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  DriversCompanion toCompanion(bool nullToAbsent) {
    return DriversCompanion(
      id: Value(id),
      name: Value(name),
    );
  }

  factory Driver.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Driver(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  Driver copyWith({int? id, String? name}) => Driver(
        id: id ?? this.id,
        name: name ?? this.name,
      );
  Driver copyWithCompanion(DriversCompanion data) {
    return Driver(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Driver(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Driver && other.id == this.id && other.name == this.name);
}

class DriversCompanion extends UpdateCompanion<Driver> {
  final Value<int> id;
  final Value<String> name;
  const DriversCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  DriversCompanion.insert({
    this.id = const Value.absent(),
    required String name,
  }) : name = Value(name);
  static Insertable<Driver> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  DriversCompanion copyWith({Value<int>? id, Value<String>? name}) {
    return DriversCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DriversCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $OrdersTable extends Orders with TableInfo<$OrdersTable, Order> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrdersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _cartIdMeta = const VerificationMeta('cartId');
  @override
  late final GeneratedColumn<int> cartId = GeneratedColumn<int>(
      'cart_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES carts (id)'));
  static const VerificationMeta _invoiceNumberMeta =
      const VerificationMeta('invoiceNumber');
  @override
  late final GeneratedColumn<String> invoiceNumber = GeneratedColumn<String>(
      'invoice_number', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _referenceNumberMeta =
      const VerificationMeta('referenceNumber');
  @override
  late final GeneratedColumn<String> referenceNumber = GeneratedColumn<String>(
      'reference_number', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _totalAmountMeta =
      const VerificationMeta('totalAmount');
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
      'total_amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _discountAmountMeta =
      const VerificationMeta('discountAmount');
  @override
  late final GeneratedColumn<double> discountAmount = GeneratedColumn<double>(
      'discount_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _discountTypeMeta =
      const VerificationMeta('discountType');
  @override
  late final GeneratedColumn<String> discountType = GeneratedColumn<String>(
      'discount_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _finalAmountMeta =
      const VerificationMeta('finalAmount');
  @override
  late final GeneratedColumn<double> finalAmount = GeneratedColumn<double>(
      'final_amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _customerNameMeta =
      const VerificationMeta('customerName');
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
      'customer_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _customerEmailMeta =
      const VerificationMeta('customerEmail');
  @override
  late final GeneratedColumn<String> customerEmail = GeneratedColumn<String>(
      'customer_email', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _customerPhoneMeta =
      const VerificationMeta('customerPhone');
  @override
  late final GeneratedColumn<String> customerPhone = GeneratedColumn<String>(
      'customer_phone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _customerGenderMeta =
      const VerificationMeta('customerGender');
  @override
  late final GeneratedColumn<String> customerGender = GeneratedColumn<String>(
      'customer_gender', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _cashAmountMeta =
      const VerificationMeta('cashAmount');
  @override
  late final GeneratedColumn<double> cashAmount = GeneratedColumn<double>(
      'cash_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _creditAmountMeta =
      const VerificationMeta('creditAmount');
  @override
  late final GeneratedColumn<double> creditAmount = GeneratedColumn<double>(
      'credit_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _cardAmountMeta =
      const VerificationMeta('cardAmount');
  @override
  late final GeneratedColumn<double> cardAmount = GeneratedColumn<double>(
      'card_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _onlineAmountMeta =
      const VerificationMeta('onlineAmount');
  @override
  late final GeneratedColumn<double> onlineAmount = GeneratedColumn<double>(
      'online_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('placed'));
  static const VerificationMeta _orderTypeMeta =
      const VerificationMeta('orderType');
  @override
  late final GeneratedColumn<String> orderType = GeneratedColumn<String>(
      'order_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _deliveryPartnerMeta =
      const VerificationMeta('deliveryPartner');
  @override
  late final GeneratedColumn<String> deliveryPartner = GeneratedColumn<String>(
      'delivery_partner', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _driverIdMeta =
      const VerificationMeta('driverId');
  @override
  late final GeneratedColumn<int> driverId = GeneratedColumn<int>(
      'driver_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES drivers (id)'));
  static const VerificationMeta _driverNameMeta =
      const VerificationMeta('driverName');
  @override
  late final GeneratedColumn<String> driverName = GeneratedColumn<String>(
      'driver_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        cartId,
        invoiceNumber,
        referenceNumber,
        totalAmount,
        discountAmount,
        discountType,
        finalAmount,
        customerName,
        customerEmail,
        customerPhone,
        customerGender,
        cashAmount,
        creditAmount,
        cardAmount,
        onlineAmount,
        createdAt,
        status,
        orderType,
        deliveryPartner,
        driverId,
        driverName
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'orders';
  @override
  VerificationContext validateIntegrity(Insertable<Order> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('cart_id')) {
      context.handle(_cartIdMeta,
          cartId.isAcceptableOrUnknown(data['cart_id']!, _cartIdMeta));
    } else if (isInserting) {
      context.missing(_cartIdMeta);
    }
    if (data.containsKey('invoice_number')) {
      context.handle(
          _invoiceNumberMeta,
          invoiceNumber.isAcceptableOrUnknown(
              data['invoice_number']!, _invoiceNumberMeta));
    } else if (isInserting) {
      context.missing(_invoiceNumberMeta);
    }
    if (data.containsKey('reference_number')) {
      context.handle(
          _referenceNumberMeta,
          referenceNumber.isAcceptableOrUnknown(
              data['reference_number']!, _referenceNumberMeta));
    }
    if (data.containsKey('total_amount')) {
      context.handle(
          _totalAmountMeta,
          totalAmount.isAcceptableOrUnknown(
              data['total_amount']!, _totalAmountMeta));
    } else if (isInserting) {
      context.missing(_totalAmountMeta);
    }
    if (data.containsKey('discount_amount')) {
      context.handle(
          _discountAmountMeta,
          discountAmount.isAcceptableOrUnknown(
              data['discount_amount']!, _discountAmountMeta));
    }
    if (data.containsKey('discount_type')) {
      context.handle(
          _discountTypeMeta,
          discountType.isAcceptableOrUnknown(
              data['discount_type']!, _discountTypeMeta));
    }
    if (data.containsKey('final_amount')) {
      context.handle(
          _finalAmountMeta,
          finalAmount.isAcceptableOrUnknown(
              data['final_amount']!, _finalAmountMeta));
    } else if (isInserting) {
      context.missing(_finalAmountMeta);
    }
    if (data.containsKey('customer_name')) {
      context.handle(
          _customerNameMeta,
          customerName.isAcceptableOrUnknown(
              data['customer_name']!, _customerNameMeta));
    }
    if (data.containsKey('customer_email')) {
      context.handle(
          _customerEmailMeta,
          customerEmail.isAcceptableOrUnknown(
              data['customer_email']!, _customerEmailMeta));
    }
    if (data.containsKey('customer_phone')) {
      context.handle(
          _customerPhoneMeta,
          customerPhone.isAcceptableOrUnknown(
              data['customer_phone']!, _customerPhoneMeta));
    }
    if (data.containsKey('customer_gender')) {
      context.handle(
          _customerGenderMeta,
          customerGender.isAcceptableOrUnknown(
              data['customer_gender']!, _customerGenderMeta));
    }
    if (data.containsKey('cash_amount')) {
      context.handle(
          _cashAmountMeta,
          cashAmount.isAcceptableOrUnknown(
              data['cash_amount']!, _cashAmountMeta));
    }
    if (data.containsKey('credit_amount')) {
      context.handle(
          _creditAmountMeta,
          creditAmount.isAcceptableOrUnknown(
              data['credit_amount']!, _creditAmountMeta));
    }
    if (data.containsKey('card_amount')) {
      context.handle(
          _cardAmountMeta,
          cardAmount.isAcceptableOrUnknown(
              data['card_amount']!, _cardAmountMeta));
    }
    if (data.containsKey('online_amount')) {
      context.handle(
          _onlineAmountMeta,
          onlineAmount.isAcceptableOrUnknown(
              data['online_amount']!, _onlineAmountMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('order_type')) {
      context.handle(_orderTypeMeta,
          orderType.isAcceptableOrUnknown(data['order_type']!, _orderTypeMeta));
    }
    if (data.containsKey('delivery_partner')) {
      context.handle(
          _deliveryPartnerMeta,
          deliveryPartner.isAcceptableOrUnknown(
              data['delivery_partner']!, _deliveryPartnerMeta));
    }
    if (data.containsKey('driver_id')) {
      context.handle(_driverIdMeta,
          driverId.isAcceptableOrUnknown(data['driver_id']!, _driverIdMeta));
    }
    if (data.containsKey('driver_name')) {
      context.handle(
          _driverNameMeta,
          driverName.isAcceptableOrUnknown(
              data['driver_name']!, _driverNameMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Order map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Order(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      cartId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cart_id'])!,
      invoiceNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}invoice_number'])!,
      referenceNumber: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}reference_number']),
      totalAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_amount'])!,
      discountAmount: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}discount_amount'])!,
      discountType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}discount_type']),
      finalAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}final_amount'])!,
      customerName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_name']),
      customerEmail: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_email']),
      customerPhone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_phone']),
      customerGender: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_gender']),
      cashAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}cash_amount'])!,
      creditAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}credit_amount'])!,
      cardAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}card_amount'])!,
      onlineAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}online_amount'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      orderType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}order_type']),
      deliveryPartner: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}delivery_partner']),
      driverId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}driver_id']),
      driverName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}driver_name']),
    );
  }

  @override
  $OrdersTable createAlias(String alias) {
    return $OrdersTable(attachedDatabase, alias);
  }
}

class Order extends DataClass implements Insertable<Order> {
  final int id;
  final int cartId;
  final String invoiceNumber;
  final String? referenceNumber;
  final double totalAmount;
  final double discountAmount;
  final String? discountType;
  final double finalAmount;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? customerGender;
  final double cashAmount;
  final double creditAmount;
  final double cardAmount;
  final double onlineAmount;
  final DateTime createdAt;
  final String status;

  /// 'take_away' | 'delivery' | 'dine_in'
  final String? orderType;
  final String? deliveryPartner;
  final int? driverId;
  final String? driverName;
  const Order(
      {required this.id,
      required this.cartId,
      required this.invoiceNumber,
      this.referenceNumber,
      required this.totalAmount,
      required this.discountAmount,
      this.discountType,
      required this.finalAmount,
      this.customerName,
      this.customerEmail,
      this.customerPhone,
      this.customerGender,
      required this.cashAmount,
      required this.creditAmount,
      required this.cardAmount,
      required this.onlineAmount,
      required this.createdAt,
      required this.status,
      this.orderType,
      this.deliveryPartner,
      this.driverId,
      this.driverName});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['cart_id'] = Variable<int>(cartId);
    map['invoice_number'] = Variable<String>(invoiceNumber);
    if (!nullToAbsent || referenceNumber != null) {
      map['reference_number'] = Variable<String>(referenceNumber);
    }
    map['total_amount'] = Variable<double>(totalAmount);
    map['discount_amount'] = Variable<double>(discountAmount);
    if (!nullToAbsent || discountType != null) {
      map['discount_type'] = Variable<String>(discountType);
    }
    map['final_amount'] = Variable<double>(finalAmount);
    if (!nullToAbsent || customerName != null) {
      map['customer_name'] = Variable<String>(customerName);
    }
    if (!nullToAbsent || customerEmail != null) {
      map['customer_email'] = Variable<String>(customerEmail);
    }
    if (!nullToAbsent || customerPhone != null) {
      map['customer_phone'] = Variable<String>(customerPhone);
    }
    if (!nullToAbsent || customerGender != null) {
      map['customer_gender'] = Variable<String>(customerGender);
    }
    map['cash_amount'] = Variable<double>(cashAmount);
    map['credit_amount'] = Variable<double>(creditAmount);
    map['card_amount'] = Variable<double>(cardAmount);
    map['online_amount'] = Variable<double>(onlineAmount);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || orderType != null) {
      map['order_type'] = Variable<String>(orderType);
    }
    if (!nullToAbsent || deliveryPartner != null) {
      map['delivery_partner'] = Variable<String>(deliveryPartner);
    }
    if (!nullToAbsent || driverId != null) {
      map['driver_id'] = Variable<int>(driverId);
    }
    if (!nullToAbsent || driverName != null) {
      map['driver_name'] = Variable<String>(driverName);
    }
    return map;
  }

  OrdersCompanion toCompanion(bool nullToAbsent) {
    return OrdersCompanion(
      id: Value(id),
      cartId: Value(cartId),
      invoiceNumber: Value(invoiceNumber),
      referenceNumber: referenceNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(referenceNumber),
      totalAmount: Value(totalAmount),
      discountAmount: Value(discountAmount),
      discountType: discountType == null && nullToAbsent
          ? const Value.absent()
          : Value(discountType),
      finalAmount: Value(finalAmount),
      customerName: customerName == null && nullToAbsent
          ? const Value.absent()
          : Value(customerName),
      customerEmail: customerEmail == null && nullToAbsent
          ? const Value.absent()
          : Value(customerEmail),
      customerPhone: customerPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(customerPhone),
      customerGender: customerGender == null && nullToAbsent
          ? const Value.absent()
          : Value(customerGender),
      cashAmount: Value(cashAmount),
      creditAmount: Value(creditAmount),
      cardAmount: Value(cardAmount),
      onlineAmount: Value(onlineAmount),
      createdAt: Value(createdAt),
      status: Value(status),
      orderType: orderType == null && nullToAbsent
          ? const Value.absent()
          : Value(orderType),
      deliveryPartner: deliveryPartner == null && nullToAbsent
          ? const Value.absent()
          : Value(deliveryPartner),
      driverId: driverId == null && nullToAbsent
          ? const Value.absent()
          : Value(driverId),
      driverName: driverName == null && nullToAbsent
          ? const Value.absent()
          : Value(driverName),
    );
  }

  factory Order.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Order(
      id: serializer.fromJson<int>(json['id']),
      cartId: serializer.fromJson<int>(json['cartId']),
      invoiceNumber: serializer.fromJson<String>(json['invoiceNumber']),
      referenceNumber: serializer.fromJson<String?>(json['referenceNumber']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      discountAmount: serializer.fromJson<double>(json['discountAmount']),
      discountType: serializer.fromJson<String?>(json['discountType']),
      finalAmount: serializer.fromJson<double>(json['finalAmount']),
      customerName: serializer.fromJson<String?>(json['customerName']),
      customerEmail: serializer.fromJson<String?>(json['customerEmail']),
      customerPhone: serializer.fromJson<String?>(json['customerPhone']),
      customerGender: serializer.fromJson<String?>(json['customerGender']),
      cashAmount: serializer.fromJson<double>(json['cashAmount']),
      creditAmount: serializer.fromJson<double>(json['creditAmount']),
      cardAmount: serializer.fromJson<double>(json['cardAmount']),
      onlineAmount: serializer.fromJson<double>(json['onlineAmount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      status: serializer.fromJson<String>(json['status']),
      orderType: serializer.fromJson<String?>(json['orderType']),
      deliveryPartner: serializer.fromJson<String?>(json['deliveryPartner']),
      driverId: serializer.fromJson<int?>(json['driverId']),
      driverName: serializer.fromJson<String?>(json['driverName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cartId': serializer.toJson<int>(cartId),
      'invoiceNumber': serializer.toJson<String>(invoiceNumber),
      'referenceNumber': serializer.toJson<String?>(referenceNumber),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'discountAmount': serializer.toJson<double>(discountAmount),
      'discountType': serializer.toJson<String?>(discountType),
      'finalAmount': serializer.toJson<double>(finalAmount),
      'customerName': serializer.toJson<String?>(customerName),
      'customerEmail': serializer.toJson<String?>(customerEmail),
      'customerPhone': serializer.toJson<String?>(customerPhone),
      'customerGender': serializer.toJson<String?>(customerGender),
      'cashAmount': serializer.toJson<double>(cashAmount),
      'creditAmount': serializer.toJson<double>(creditAmount),
      'cardAmount': serializer.toJson<double>(cardAmount),
      'onlineAmount': serializer.toJson<double>(onlineAmount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'status': serializer.toJson<String>(status),
      'orderType': serializer.toJson<String?>(orderType),
      'deliveryPartner': serializer.toJson<String?>(deliveryPartner),
      'driverId': serializer.toJson<int?>(driverId),
      'driverName': serializer.toJson<String?>(driverName),
    };
  }

  Order copyWith(
          {int? id,
          int? cartId,
          String? invoiceNumber,
          Value<String?> referenceNumber = const Value.absent(),
          double? totalAmount,
          double? discountAmount,
          Value<String?> discountType = const Value.absent(),
          double? finalAmount,
          Value<String?> customerName = const Value.absent(),
          Value<String?> customerEmail = const Value.absent(),
          Value<String?> customerPhone = const Value.absent(),
          Value<String?> customerGender = const Value.absent(),
          double? cashAmount,
          double? creditAmount,
          double? cardAmount,
          double? onlineAmount,
          DateTime? createdAt,
          String? status,
          Value<String?> orderType = const Value.absent(),
          Value<String?> deliveryPartner = const Value.absent(),
          Value<int?> driverId = const Value.absent(),
          Value<String?> driverName = const Value.absent()}) =>
      Order(
        id: id ?? this.id,
        cartId: cartId ?? this.cartId,
        invoiceNumber: invoiceNumber ?? this.invoiceNumber,
        referenceNumber: referenceNumber.present
            ? referenceNumber.value
            : this.referenceNumber,
        totalAmount: totalAmount ?? this.totalAmount,
        discountAmount: discountAmount ?? this.discountAmount,
        discountType:
            discountType.present ? discountType.value : this.discountType,
        finalAmount: finalAmount ?? this.finalAmount,
        customerName:
            customerName.present ? customerName.value : this.customerName,
        customerEmail:
            customerEmail.present ? customerEmail.value : this.customerEmail,
        customerPhone:
            customerPhone.present ? customerPhone.value : this.customerPhone,
        customerGender:
            customerGender.present ? customerGender.value : this.customerGender,
        cashAmount: cashAmount ?? this.cashAmount,
        creditAmount: creditAmount ?? this.creditAmount,
        cardAmount: cardAmount ?? this.cardAmount,
        onlineAmount: onlineAmount ?? this.onlineAmount,
        createdAt: createdAt ?? this.createdAt,
        status: status ?? this.status,
        orderType: orderType.present ? orderType.value : this.orderType,
        deliveryPartner: deliveryPartner.present
            ? deliveryPartner.value
            : this.deliveryPartner,
        driverId: driverId.present ? driverId.value : this.driverId,
        driverName: driverName.present ? driverName.value : this.driverName,
      );
  Order copyWithCompanion(OrdersCompanion data) {
    return Order(
      id: data.id.present ? data.id.value : this.id,
      cartId: data.cartId.present ? data.cartId.value : this.cartId,
      invoiceNumber: data.invoiceNumber.present
          ? data.invoiceNumber.value
          : this.invoiceNumber,
      referenceNumber: data.referenceNumber.present
          ? data.referenceNumber.value
          : this.referenceNumber,
      totalAmount:
          data.totalAmount.present ? data.totalAmount.value : this.totalAmount,
      discountAmount: data.discountAmount.present
          ? data.discountAmount.value
          : this.discountAmount,
      discountType: data.discountType.present
          ? data.discountType.value
          : this.discountType,
      finalAmount:
          data.finalAmount.present ? data.finalAmount.value : this.finalAmount,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      customerEmail: data.customerEmail.present
          ? data.customerEmail.value
          : this.customerEmail,
      customerPhone: data.customerPhone.present
          ? data.customerPhone.value
          : this.customerPhone,
      customerGender: data.customerGender.present
          ? data.customerGender.value
          : this.customerGender,
      cashAmount:
          data.cashAmount.present ? data.cashAmount.value : this.cashAmount,
      creditAmount: data.creditAmount.present
          ? data.creditAmount.value
          : this.creditAmount,
      cardAmount:
          data.cardAmount.present ? data.cardAmount.value : this.cardAmount,
      onlineAmount: data.onlineAmount.present
          ? data.onlineAmount.value
          : this.onlineAmount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      status: data.status.present ? data.status.value : this.status,
      orderType: data.orderType.present ? data.orderType.value : this.orderType,
      deliveryPartner: data.deliveryPartner.present
          ? data.deliveryPartner.value
          : this.deliveryPartner,
      driverId: data.driverId.present ? data.driverId.value : this.driverId,
      driverName:
          data.driverName.present ? data.driverName.value : this.driverName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Order(')
          ..write('id: $id, ')
          ..write('cartId: $cartId, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('referenceNumber: $referenceNumber, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('discountType: $discountType, ')
          ..write('finalAmount: $finalAmount, ')
          ..write('customerName: $customerName, ')
          ..write('customerEmail: $customerEmail, ')
          ..write('customerPhone: $customerPhone, ')
          ..write('customerGender: $customerGender, ')
          ..write('cashAmount: $cashAmount, ')
          ..write('creditAmount: $creditAmount, ')
          ..write('cardAmount: $cardAmount, ')
          ..write('onlineAmount: $onlineAmount, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('orderType: $orderType, ')
          ..write('deliveryPartner: $deliveryPartner, ')
          ..write('driverId: $driverId, ')
          ..write('driverName: $driverName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        cartId,
        invoiceNumber,
        referenceNumber,
        totalAmount,
        discountAmount,
        discountType,
        finalAmount,
        customerName,
        customerEmail,
        customerPhone,
        customerGender,
        cashAmount,
        creditAmount,
        cardAmount,
        onlineAmount,
        createdAt,
        status,
        orderType,
        deliveryPartner,
        driverId,
        driverName
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Order &&
          other.id == this.id &&
          other.cartId == this.cartId &&
          other.invoiceNumber == this.invoiceNumber &&
          other.referenceNumber == this.referenceNumber &&
          other.totalAmount == this.totalAmount &&
          other.discountAmount == this.discountAmount &&
          other.discountType == this.discountType &&
          other.finalAmount == this.finalAmount &&
          other.customerName == this.customerName &&
          other.customerEmail == this.customerEmail &&
          other.customerPhone == this.customerPhone &&
          other.customerGender == this.customerGender &&
          other.cashAmount == this.cashAmount &&
          other.creditAmount == this.creditAmount &&
          other.cardAmount == this.cardAmount &&
          other.onlineAmount == this.onlineAmount &&
          other.createdAt == this.createdAt &&
          other.status == this.status &&
          other.orderType == this.orderType &&
          other.deliveryPartner == this.deliveryPartner &&
          other.driverId == this.driverId &&
          other.driverName == this.driverName);
}

class OrdersCompanion extends UpdateCompanion<Order> {
  final Value<int> id;
  final Value<int> cartId;
  final Value<String> invoiceNumber;
  final Value<String?> referenceNumber;
  final Value<double> totalAmount;
  final Value<double> discountAmount;
  final Value<String?> discountType;
  final Value<double> finalAmount;
  final Value<String?> customerName;
  final Value<String?> customerEmail;
  final Value<String?> customerPhone;
  final Value<String?> customerGender;
  final Value<double> cashAmount;
  final Value<double> creditAmount;
  final Value<double> cardAmount;
  final Value<double> onlineAmount;
  final Value<DateTime> createdAt;
  final Value<String> status;
  final Value<String?> orderType;
  final Value<String?> deliveryPartner;
  final Value<int?> driverId;
  final Value<String?> driverName;
  const OrdersCompanion({
    this.id = const Value.absent(),
    this.cartId = const Value.absent(),
    this.invoiceNumber = const Value.absent(),
    this.referenceNumber = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.discountAmount = const Value.absent(),
    this.discountType = const Value.absent(),
    this.finalAmount = const Value.absent(),
    this.customerName = const Value.absent(),
    this.customerEmail = const Value.absent(),
    this.customerPhone = const Value.absent(),
    this.customerGender = const Value.absent(),
    this.cashAmount = const Value.absent(),
    this.creditAmount = const Value.absent(),
    this.cardAmount = const Value.absent(),
    this.onlineAmount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.status = const Value.absent(),
    this.orderType = const Value.absent(),
    this.deliveryPartner = const Value.absent(),
    this.driverId = const Value.absent(),
    this.driverName = const Value.absent(),
  });
  OrdersCompanion.insert({
    this.id = const Value.absent(),
    required int cartId,
    required String invoiceNumber,
    this.referenceNumber = const Value.absent(),
    required double totalAmount,
    this.discountAmount = const Value.absent(),
    this.discountType = const Value.absent(),
    required double finalAmount,
    this.customerName = const Value.absent(),
    this.customerEmail = const Value.absent(),
    this.customerPhone = const Value.absent(),
    this.customerGender = const Value.absent(),
    this.cashAmount = const Value.absent(),
    this.creditAmount = const Value.absent(),
    this.cardAmount = const Value.absent(),
    this.onlineAmount = const Value.absent(),
    required DateTime createdAt,
    this.status = const Value.absent(),
    this.orderType = const Value.absent(),
    this.deliveryPartner = const Value.absent(),
    this.driverId = const Value.absent(),
    this.driverName = const Value.absent(),
  })  : cartId = Value(cartId),
        invoiceNumber = Value(invoiceNumber),
        totalAmount = Value(totalAmount),
        finalAmount = Value(finalAmount),
        createdAt = Value(createdAt);
  static Insertable<Order> custom({
    Expression<int>? id,
    Expression<int>? cartId,
    Expression<String>? invoiceNumber,
    Expression<String>? referenceNumber,
    Expression<double>? totalAmount,
    Expression<double>? discountAmount,
    Expression<String>? discountType,
    Expression<double>? finalAmount,
    Expression<String>? customerName,
    Expression<String>? customerEmail,
    Expression<String>? customerPhone,
    Expression<String>? customerGender,
    Expression<double>? cashAmount,
    Expression<double>? creditAmount,
    Expression<double>? cardAmount,
    Expression<double>? onlineAmount,
    Expression<DateTime>? createdAt,
    Expression<String>? status,
    Expression<String>? orderType,
    Expression<String>? deliveryPartner,
    Expression<int>? driverId,
    Expression<String>? driverName,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cartId != null) 'cart_id': cartId,
      if (invoiceNumber != null) 'invoice_number': invoiceNumber,
      if (referenceNumber != null) 'reference_number': referenceNumber,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (discountAmount != null) 'discount_amount': discountAmount,
      if (discountType != null) 'discount_type': discountType,
      if (finalAmount != null) 'final_amount': finalAmount,
      if (customerName != null) 'customer_name': customerName,
      if (customerEmail != null) 'customer_email': customerEmail,
      if (customerPhone != null) 'customer_phone': customerPhone,
      if (customerGender != null) 'customer_gender': customerGender,
      if (cashAmount != null) 'cash_amount': cashAmount,
      if (creditAmount != null) 'credit_amount': creditAmount,
      if (cardAmount != null) 'card_amount': cardAmount,
      if (onlineAmount != null) 'online_amount': onlineAmount,
      if (createdAt != null) 'created_at': createdAt,
      if (status != null) 'status': status,
      if (orderType != null) 'order_type': orderType,
      if (deliveryPartner != null) 'delivery_partner': deliveryPartner,
      if (driverId != null) 'driver_id': driverId,
      if (driverName != null) 'driver_name': driverName,
    });
  }

  OrdersCompanion copyWith(
      {Value<int>? id,
      Value<int>? cartId,
      Value<String>? invoiceNumber,
      Value<String?>? referenceNumber,
      Value<double>? totalAmount,
      Value<double>? discountAmount,
      Value<String?>? discountType,
      Value<double>? finalAmount,
      Value<String?>? customerName,
      Value<String?>? customerEmail,
      Value<String?>? customerPhone,
      Value<String?>? customerGender,
      Value<double>? cashAmount,
      Value<double>? creditAmount,
      Value<double>? cardAmount,
      Value<double>? onlineAmount,
      Value<DateTime>? createdAt,
      Value<String>? status,
      Value<String?>? orderType,
      Value<String?>? deliveryPartner,
      Value<int?>? driverId,
      Value<String?>? driverName}) {
    return OrdersCompanion(
      id: id ?? this.id,
      cartId: cartId ?? this.cartId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      totalAmount: totalAmount ?? this.totalAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      discountType: discountType ?? this.discountType,
      finalAmount: finalAmount ?? this.finalAmount,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      customerGender: customerGender ?? this.customerGender,
      cashAmount: cashAmount ?? this.cashAmount,
      creditAmount: creditAmount ?? this.creditAmount,
      cardAmount: cardAmount ?? this.cardAmount,
      onlineAmount: onlineAmount ?? this.onlineAmount,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      orderType: orderType ?? this.orderType,
      deliveryPartner: deliveryPartner ?? this.deliveryPartner,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cartId.present) {
      map['cart_id'] = Variable<int>(cartId.value);
    }
    if (invoiceNumber.present) {
      map['invoice_number'] = Variable<String>(invoiceNumber.value);
    }
    if (referenceNumber.present) {
      map['reference_number'] = Variable<String>(referenceNumber.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (discountAmount.present) {
      map['discount_amount'] = Variable<double>(discountAmount.value);
    }
    if (discountType.present) {
      map['discount_type'] = Variable<String>(discountType.value);
    }
    if (finalAmount.present) {
      map['final_amount'] = Variable<double>(finalAmount.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (customerEmail.present) {
      map['customer_email'] = Variable<String>(customerEmail.value);
    }
    if (customerPhone.present) {
      map['customer_phone'] = Variable<String>(customerPhone.value);
    }
    if (customerGender.present) {
      map['customer_gender'] = Variable<String>(customerGender.value);
    }
    if (cashAmount.present) {
      map['cash_amount'] = Variable<double>(cashAmount.value);
    }
    if (creditAmount.present) {
      map['credit_amount'] = Variable<double>(creditAmount.value);
    }
    if (cardAmount.present) {
      map['card_amount'] = Variable<double>(cardAmount.value);
    }
    if (onlineAmount.present) {
      map['online_amount'] = Variable<double>(onlineAmount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (orderType.present) {
      map['order_type'] = Variable<String>(orderType.value);
    }
    if (deliveryPartner.present) {
      map['delivery_partner'] = Variable<String>(deliveryPartner.value);
    }
    if (driverId.present) {
      map['driver_id'] = Variable<int>(driverId.value);
    }
    if (driverName.present) {
      map['driver_name'] = Variable<String>(driverName.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrdersCompanion(')
          ..write('id: $id, ')
          ..write('cartId: $cartId, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('referenceNumber: $referenceNumber, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('discountType: $discountType, ')
          ..write('finalAmount: $finalAmount, ')
          ..write('customerName: $customerName, ')
          ..write('customerEmail: $customerEmail, ')
          ..write('customerPhone: $customerPhone, ')
          ..write('customerGender: $customerGender, ')
          ..write('cashAmount: $cashAmount, ')
          ..write('creditAmount: $creditAmount, ')
          ..write('cardAmount: $cardAmount, ')
          ..write('onlineAmount: $onlineAmount, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('orderType: $orderType, ')
          ..write('deliveryPartner: $deliveryPartner, ')
          ..write('driverId: $driverId, ')
          ..write('driverName: $driverName')
          ..write(')'))
        .toString();
  }
}

class $OrderLogsTable extends OrderLogs
    with TableInfo<$OrderLogsTable, OrderLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrderLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _orderJsonMeta =
      const VerificationMeta('orderJson');
  @override
  late final GeneratedColumn<String> orderJson = GeneratedColumn<String>(
      'order_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [id, orderJson, createdAt, synced];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'order_logs';
  @override
  VerificationContext validateIntegrity(Insertable<OrderLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('order_json')) {
      context.handle(_orderJsonMeta,
          orderJson.isAcceptableOrUnknown(data['order_json']!, _orderJsonMeta));
    } else if (isInserting) {
      context.missing(_orderJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OrderLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrderLog(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      orderJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}order_json'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
    );
  }

  @override
  $OrderLogsTable createAlias(String alias) {
    return $OrderLogsTable(attachedDatabase, alias);
  }
}

class OrderLog extends DataClass implements Insertable<OrderLog> {
  final int id;
  final String orderJson;
  final DateTime createdAt;
  final bool synced;
  const OrderLog(
      {required this.id,
      required this.orderJson,
      required this.createdAt,
      required this.synced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['order_json'] = Variable<String>(orderJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  OrderLogsCompanion toCompanion(bool nullToAbsent) {
    return OrderLogsCompanion(
      id: Value(id),
      orderJson: Value(orderJson),
      createdAt: Value(createdAt),
      synced: Value(synced),
    );
  }

  factory OrderLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrderLog(
      id: serializer.fromJson<int>(json['id']),
      orderJson: serializer.fromJson<String>(json['orderJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'orderJson': serializer.toJson<String>(orderJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  OrderLog copyWith(
          {int? id, String? orderJson, DateTime? createdAt, bool? synced}) =>
      OrderLog(
        id: id ?? this.id,
        orderJson: orderJson ?? this.orderJson,
        createdAt: createdAt ?? this.createdAt,
        synced: synced ?? this.synced,
      );
  OrderLog copyWithCompanion(OrderLogsCompanion data) {
    return OrderLog(
      id: data.id.present ? data.id.value : this.id,
      orderJson: data.orderJson.present ? data.orderJson.value : this.orderJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrderLog(')
          ..write('id: $id, ')
          ..write('orderJson: $orderJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, orderJson, createdAt, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrderLog &&
          other.id == this.id &&
          other.orderJson == this.orderJson &&
          other.createdAt == this.createdAt &&
          other.synced == this.synced);
}

class OrderLogsCompanion extends UpdateCompanion<OrderLog> {
  final Value<int> id;
  final Value<String> orderJson;
  final Value<DateTime> createdAt;
  final Value<bool> synced;
  const OrderLogsCompanion({
    this.id = const Value.absent(),
    this.orderJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.synced = const Value.absent(),
  });
  OrderLogsCompanion.insert({
    this.id = const Value.absent(),
    required String orderJson,
    this.createdAt = const Value.absent(),
    this.synced = const Value.absent(),
  }) : orderJson = Value(orderJson);
  static Insertable<OrderLog> custom({
    Expression<int>? id,
    Expression<String>? orderJson,
    Expression<DateTime>? createdAt,
    Expression<bool>? synced,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (orderJson != null) 'order_json': orderJson,
      if (createdAt != null) 'created_at': createdAt,
      if (synced != null) 'synced': synced,
    });
  }

  OrderLogsCompanion copyWith(
      {Value<int>? id,
      Value<String>? orderJson,
      Value<DateTime>? createdAt,
      Value<bool>? synced}) {
    return OrderLogsCompanion(
      id: id ?? this.id,
      orderJson: orderJson ?? this.orderJson,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (orderJson.present) {
      map['order_json'] = Variable<String>(orderJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrderLogsCompanion(')
          ..write('id: $id, ')
          ..write('orderJson: $orderJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }
}

class $CustomersTable extends Customers
    with TableInfo<$CustomersTable, Customer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
      'server_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
      'gender', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _addressMeta =
      const VerificationMeta('address');
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
      'address', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _cardNoMeta = const VerificationMeta('cardNo');
  @override
  late final GeneratedColumn<String> cardNo = GeneratedColumn<String>(
      'card_no', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _recordUuidMeta =
      const VerificationMeta('recordUuid');
  @override
  late final GeneratedColumn<String> recordUuid = GeneratedColumn<String>(
      'record_uuid', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _branchIdMeta =
      const VerificationMeta('branchId');
  @override
  late final GeneratedColumn<int> branchId = GeneratedColumn<int>(
      'branch_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _customerNumberMeta =
      const VerificationMeta('customerNumber');
  @override
  late final GeneratedColumn<String> customerNumber = GeneratedColumn<String>(
      'customer_number', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        serverId,
        name,
        email,
        phone,
        gender,
        address,
        cardNo,
        recordUuid,
        branchId,
        customerNumber,
        createdAt,
        updatedAt,
        isSynced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customers';
  @override
  VerificationContext validateIntegrity(Insertable<Customer> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(_serverIdMeta,
          serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    }
    if (data.containsKey('gender')) {
      context.handle(_genderMeta,
          gender.isAcceptableOrUnknown(data['gender']!, _genderMeta));
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address']!, _addressMeta));
    }
    if (data.containsKey('card_no')) {
      context.handle(_cardNoMeta,
          cardNo.isAcceptableOrUnknown(data['card_no']!, _cardNoMeta));
    }
    if (data.containsKey('record_uuid')) {
      context.handle(
          _recordUuidMeta,
          recordUuid.isAcceptableOrUnknown(
              data['record_uuid']!, _recordUuidMeta));
    }
    if (data.containsKey('branch_id')) {
      context.handle(_branchIdMeta,
          branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta));
    }
    if (data.containsKey('customer_number')) {
      context.handle(
          _customerNumberMeta,
          customerNumber.isAcceptableOrUnknown(
              data['customer_number']!, _customerNumberMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Customer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Customer(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}server_id']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email']),
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone']),
      gender: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}gender']),
      address: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address']),
      cardNo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}card_no']),
      recordUuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}record_uuid']),
      branchId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}branch_id']),
      customerNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_number']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
    );
  }

  @override
  $CustomersTable createAlias(String alias) {
    return $CustomersTable(attachedDatabase, alias);
  }
}

class Customer extends DataClass implements Insertable<Customer> {
  final int id;
  final String? serverId;
  final String name;
  final String? email;
  final String? phone;
  final String? gender;
  final String? address;
  final String? cardNo;

  /// [CustomerCreatedUpdated.uuid] from [CustomerSyncResponse]
  final String? recordUuid;
  final int? branchId;
  final String? customerNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  const Customer(
      {required this.id,
      this.serverId,
      required this.name,
      this.email,
      this.phone,
      this.gender,
      this.address,
      this.cardNo,
      this.recordUuid,
      this.branchId,
      this.customerNumber,
      required this.createdAt,
      required this.updatedAt,
      required this.isSynced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || gender != null) {
      map['gender'] = Variable<String>(gender);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || cardNo != null) {
      map['card_no'] = Variable<String>(cardNo);
    }
    if (!nullToAbsent || recordUuid != null) {
      map['record_uuid'] = Variable<String>(recordUuid);
    }
    if (!nullToAbsent || branchId != null) {
      map['branch_id'] = Variable<int>(branchId);
    }
    if (!nullToAbsent || customerNumber != null) {
      map['customer_number'] = Variable<String>(customerNumber);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  CustomersCompanion toCompanion(bool nullToAbsent) {
    return CustomersCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      name: Value(name),
      email:
          email == null && nullToAbsent ? const Value.absent() : Value(email),
      phone:
          phone == null && nullToAbsent ? const Value.absent() : Value(phone),
      gender:
          gender == null && nullToAbsent ? const Value.absent() : Value(gender),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      cardNo:
          cardNo == null && nullToAbsent ? const Value.absent() : Value(cardNo),
      recordUuid: recordUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(recordUuid),
      branchId: branchId == null && nullToAbsent
          ? const Value.absent()
          : Value(branchId),
      customerNumber: customerNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(customerNumber),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isSynced: Value(isSynced),
    );
  }

  factory Customer.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Customer(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      name: serializer.fromJson<String>(json['name']),
      email: serializer.fromJson<String?>(json['email']),
      phone: serializer.fromJson<String?>(json['phone']),
      gender: serializer.fromJson<String?>(json['gender']),
      address: serializer.fromJson<String?>(json['address']),
      cardNo: serializer.fromJson<String?>(json['cardNo']),
      recordUuid: serializer.fromJson<String?>(json['recordUuid']),
      branchId: serializer.fromJson<int?>(json['branchId']),
      customerNumber: serializer.fromJson<String?>(json['customerNumber']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<String?>(serverId),
      'name': serializer.toJson<String>(name),
      'email': serializer.toJson<String?>(email),
      'phone': serializer.toJson<String?>(phone),
      'gender': serializer.toJson<String?>(gender),
      'address': serializer.toJson<String?>(address),
      'cardNo': serializer.toJson<String?>(cardNo),
      'recordUuid': serializer.toJson<String?>(recordUuid),
      'branchId': serializer.toJson<int?>(branchId),
      'customerNumber': serializer.toJson<String?>(customerNumber),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  Customer copyWith(
          {int? id,
          Value<String?> serverId = const Value.absent(),
          String? name,
          Value<String?> email = const Value.absent(),
          Value<String?> phone = const Value.absent(),
          Value<String?> gender = const Value.absent(),
          Value<String?> address = const Value.absent(),
          Value<String?> cardNo = const Value.absent(),
          Value<String?> recordUuid = const Value.absent(),
          Value<int?> branchId = const Value.absent(),
          Value<String?> customerNumber = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          bool? isSynced}) =>
      Customer(
        id: id ?? this.id,
        serverId: serverId.present ? serverId.value : this.serverId,
        name: name ?? this.name,
        email: email.present ? email.value : this.email,
        phone: phone.present ? phone.value : this.phone,
        gender: gender.present ? gender.value : this.gender,
        address: address.present ? address.value : this.address,
        cardNo: cardNo.present ? cardNo.value : this.cardNo,
        recordUuid: recordUuid.present ? recordUuid.value : this.recordUuid,
        branchId: branchId.present ? branchId.value : this.branchId,
        customerNumber:
            customerNumber.present ? customerNumber.value : this.customerNumber,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isSynced: isSynced ?? this.isSynced,
      );
  Customer copyWithCompanion(CustomersCompanion data) {
    return Customer(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      name: data.name.present ? data.name.value : this.name,
      email: data.email.present ? data.email.value : this.email,
      phone: data.phone.present ? data.phone.value : this.phone,
      gender: data.gender.present ? data.gender.value : this.gender,
      address: data.address.present ? data.address.value : this.address,
      cardNo: data.cardNo.present ? data.cardNo.value : this.cardNo,
      recordUuid:
          data.recordUuid.present ? data.recordUuid.value : this.recordUuid,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      customerNumber: data.customerNumber.present
          ? data.customerNumber.value
          : this.customerNumber,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Customer(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('gender: $gender, ')
          ..write('address: $address, ')
          ..write('cardNo: $cardNo, ')
          ..write('recordUuid: $recordUuid, ')
          ..write('branchId: $branchId, ')
          ..write('customerNumber: $customerNumber, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      serverId,
      name,
      email,
      phone,
      gender,
      address,
      cardNo,
      recordUuid,
      branchId,
      customerNumber,
      createdAt,
      updatedAt,
      isSynced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Customer &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.name == this.name &&
          other.email == this.email &&
          other.phone == this.phone &&
          other.gender == this.gender &&
          other.address == this.address &&
          other.cardNo == this.cardNo &&
          other.recordUuid == this.recordUuid &&
          other.branchId == this.branchId &&
          other.customerNumber == this.customerNumber &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isSynced == this.isSynced);
}

class CustomersCompanion extends UpdateCompanion<Customer> {
  final Value<int> id;
  final Value<String?> serverId;
  final Value<String> name;
  final Value<String?> email;
  final Value<String?> phone;
  final Value<String?> gender;
  final Value<String?> address;
  final Value<String?> cardNo;
  final Value<String?> recordUuid;
  final Value<int?> branchId;
  final Value<String?> customerNumber;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> isSynced;
  const CustomersCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.phone = const Value.absent(),
    this.gender = const Value.absent(),
    this.address = const Value.absent(),
    this.cardNo = const Value.absent(),
    this.recordUuid = const Value.absent(),
    this.branchId = const Value.absent(),
    this.customerNumber = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
  });
  CustomersCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    required String name,
    this.email = const Value.absent(),
    this.phone = const Value.absent(),
    this.gender = const Value.absent(),
    this.address = const Value.absent(),
    this.cardNo = const Value.absent(),
    this.recordUuid = const Value.absent(),
    this.branchId = const Value.absent(),
    this.customerNumber = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Customer> custom({
    Expression<int>? id,
    Expression<String>? serverId,
    Expression<String>? name,
    Expression<String>? email,
    Expression<String>? phone,
    Expression<String>? gender,
    Expression<String>? address,
    Expression<String>? cardNo,
    Expression<String>? recordUuid,
    Expression<int>? branchId,
    Expression<String>? customerNumber,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isSynced,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (gender != null) 'gender': gender,
      if (address != null) 'address': address,
      if (cardNo != null) 'card_no': cardNo,
      if (recordUuid != null) 'record_uuid': recordUuid,
      if (branchId != null) 'branch_id': branchId,
      if (customerNumber != null) 'customer_number': customerNumber,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isSynced != null) 'is_synced': isSynced,
    });
  }

  CustomersCompanion copyWith(
      {Value<int>? id,
      Value<String?>? serverId,
      Value<String>? name,
      Value<String?>? email,
      Value<String?>? phone,
      Value<String?>? gender,
      Value<String?>? address,
      Value<String?>? cardNo,
      Value<String?>? recordUuid,
      Value<int?>? branchId,
      Value<String?>? customerNumber,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<bool>? isSynced}) {
    return CustomersCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      cardNo: cardNo ?? this.cardNo,
      recordUuid: recordUuid ?? this.recordUuid,
      branchId: branchId ?? this.branchId,
      customerNumber: customerNumber ?? this.customerNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (cardNo.present) {
      map['card_no'] = Variable<String>(cardNo.value);
    }
    if (recordUuid.present) {
      map['record_uuid'] = Variable<String>(recordUuid.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<int>(branchId.value);
    }
    if (customerNumber.present) {
      map['customer_number'] = Variable<String>(customerNumber.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomersCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('gender: $gender, ')
          ..write('address: $address, ')
          ..write('cardNo: $cardNo, ')
          ..write('recordUuid: $recordUuid, ')
          ..write('branchId: $branchId, ')
          ..write('customerNumber: $customerNumber, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }
}

class $DeliveryPartnersTable extends DeliveryPartners
    with TableInfo<$DeliveryPartnersTable, DeliveryPartner> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeliveryPartnersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'delivery_partners';
  @override
  VerificationContext validateIntegrity(Insertable<DeliveryPartner> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DeliveryPartner map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeliveryPartner(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
    );
  }

  @override
  $DeliveryPartnersTable createAlias(String alias) {
    return $DeliveryPartnersTable(attachedDatabase, alias);
  }
}

class DeliveryPartner extends DataClass implements Insertable<DeliveryPartner> {
  final int id;
  final String name;
  const DeliveryPartner({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  DeliveryPartnersCompanion toCompanion(bool nullToAbsent) {
    return DeliveryPartnersCompanion(
      id: Value(id),
      name: Value(name),
    );
  }

  factory DeliveryPartner.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeliveryPartner(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  DeliveryPartner copyWith({int? id, String? name}) => DeliveryPartner(
        id: id ?? this.id,
        name: name ?? this.name,
      );
  DeliveryPartner copyWithCompanion(DeliveryPartnersCompanion data) {
    return DeliveryPartner(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeliveryPartner(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeliveryPartner &&
          other.id == this.id &&
          other.name == this.name);
}

class DeliveryPartnersCompanion extends UpdateCompanion<DeliveryPartner> {
  final Value<int> id;
  final Value<String> name;
  const DeliveryPartnersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  DeliveryPartnersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
  }) : name = Value(name);
  static Insertable<DeliveryPartner> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  DeliveryPartnersCompanion copyWith({Value<int>? id, Value<String>? name}) {
    return DeliveryPartnersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeliveryPartnersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $DiningFloorsTable extends DiningFloors
    with TableInfo<$DiningFloorsTable, DiningFloor> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiningFloorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _recordUuidMeta =
      const VerificationMeta('recordUuid');
  @override
  late final GeneratedColumn<String> recordUuid = GeneratedColumn<String>(
      'record_uuid', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _branchIdMeta =
      const VerificationMeta('branchId');
  @override
  late final GeneratedColumn<int> branchId = GeneratedColumn<int>(
      'branch_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _floorSlugMeta =
      const VerificationMeta('floorSlug');
  @override
  late final GeneratedColumn<String> floorSlug = GeneratedColumn<String>(
      'floor_slug', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, sortOrder, recordUuid, branchId, floorSlug, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dining_floors';
  @override
  VerificationContext validateIntegrity(Insertable<DiningFloor> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('record_uuid')) {
      context.handle(
          _recordUuidMeta,
          recordUuid.isAcceptableOrUnknown(
              data['record_uuid']!, _recordUuidMeta));
    }
    if (data.containsKey('branch_id')) {
      context.handle(_branchIdMeta,
          branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta));
    }
    if (data.containsKey('floor_slug')) {
      context.handle(_floorSlugMeta,
          floorSlug.isAcceptableOrUnknown(data['floor_slug']!, _floorSlugMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DiningFloor map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DiningFloor(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      recordUuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}record_uuid']),
      branchId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}branch_id']),
      floorSlug: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}floor_slug']),
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $DiningFloorsTable createAlias(String alias) {
    return $DiningFloorsTable(attachedDatabase, alias);
  }
}

class DiningFloor extends DataClass implements Insertable<DiningFloor> {
  final int id;
  final String name;
  final int sortOrder;

  /// [FloorsCreatedUpdated] when [PullDataModel.floors] represents dine-in floor
  final String? recordUuid;
  final int? branchId;
  final String? floorSlug;
  final DateTime? deletedAt;
  const DiningFloor(
      {required this.id,
      required this.name,
      required this.sortOrder,
      this.recordUuid,
      this.branchId,
      this.floorSlug,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || recordUuid != null) {
      map['record_uuid'] = Variable<String>(recordUuid);
    }
    if (!nullToAbsent || branchId != null) {
      map['branch_id'] = Variable<int>(branchId);
    }
    if (!nullToAbsent || floorSlug != null) {
      map['floor_slug'] = Variable<String>(floorSlug);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  DiningFloorsCompanion toCompanion(bool nullToAbsent) {
    return DiningFloorsCompanion(
      id: Value(id),
      name: Value(name),
      sortOrder: Value(sortOrder),
      recordUuid: recordUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(recordUuid),
      branchId: branchId == null && nullToAbsent
          ? const Value.absent()
          : Value(branchId),
      floorSlug: floorSlug == null && nullToAbsent
          ? const Value.absent()
          : Value(floorSlug),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory DiningFloor.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DiningFloor(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      recordUuid: serializer.fromJson<String?>(json['recordUuid']),
      branchId: serializer.fromJson<int?>(json['branchId']),
      floorSlug: serializer.fromJson<String?>(json['floorSlug']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'recordUuid': serializer.toJson<String?>(recordUuid),
      'branchId': serializer.toJson<int?>(branchId),
      'floorSlug': serializer.toJson<String?>(floorSlug),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  DiningFloor copyWith(
          {int? id,
          String? name,
          int? sortOrder,
          Value<String?> recordUuid = const Value.absent(),
          Value<int?> branchId = const Value.absent(),
          Value<String?> floorSlug = const Value.absent(),
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      DiningFloor(
        id: id ?? this.id,
        name: name ?? this.name,
        sortOrder: sortOrder ?? this.sortOrder,
        recordUuid: recordUuid.present ? recordUuid.value : this.recordUuid,
        branchId: branchId.present ? branchId.value : this.branchId,
        floorSlug: floorSlug.present ? floorSlug.value : this.floorSlug,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  DiningFloor copyWithCompanion(DiningFloorsCompanion data) {
    return DiningFloor(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      recordUuid:
          data.recordUuid.present ? data.recordUuid.value : this.recordUuid,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      floorSlug: data.floorSlug.present ? data.floorSlug.value : this.floorSlug,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DiningFloor(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('recordUuid: $recordUuid, ')
          ..write('branchId: $branchId, ')
          ..write('floorSlug: $floorSlug, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, name, sortOrder, recordUuid, branchId, floorSlug, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DiningFloor &&
          other.id == this.id &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder &&
          other.recordUuid == this.recordUuid &&
          other.branchId == this.branchId &&
          other.floorSlug == this.floorSlug &&
          other.deletedAt == this.deletedAt);
}

class DiningFloorsCompanion extends UpdateCompanion<DiningFloor> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<String?> recordUuid;
  final Value<int?> branchId;
  final Value<String?> floorSlug;
  final Value<DateTime?> deletedAt;
  const DiningFloorsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.recordUuid = const Value.absent(),
    this.branchId = const Value.absent(),
    this.floorSlug = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  DiningFloorsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.sortOrder = const Value.absent(),
    this.recordUuid = const Value.absent(),
    this.branchId = const Value.absent(),
    this.floorSlug = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<DiningFloor> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<String>? recordUuid,
    Expression<int>? branchId,
    Expression<String>? floorSlug,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (recordUuid != null) 'record_uuid': recordUuid,
      if (branchId != null) 'branch_id': branchId,
      if (floorSlug != null) 'floor_slug': floorSlug,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  DiningFloorsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<int>? sortOrder,
      Value<String?>? recordUuid,
      Value<int?>? branchId,
      Value<String?>? floorSlug,
      Value<DateTime?>? deletedAt}) {
    return DiningFloorsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      recordUuid: recordUuid ?? this.recordUuid,
      branchId: branchId ?? this.branchId,
      floorSlug: floorSlug ?? this.floorSlug,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (recordUuid.present) {
      map['record_uuid'] = Variable<String>(recordUuid.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<int>(branchId.value);
    }
    if (floorSlug.present) {
      map['floor_slug'] = Variable<String>(floorSlug.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DiningFloorsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('recordUuid: $recordUuid, ')
          ..write('branchId: $branchId, ')
          ..write('floorSlug: $floorSlug, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $DiningTablesTable extends DiningTables
    with TableInfo<$DiningTablesTable, DiningTable> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiningTablesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _floorIdMeta =
      const VerificationMeta('floorId');
  @override
  late final GeneratedColumn<int> floorId = GeneratedColumn<int>(
      'floor_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES dining_floors (id)'));
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
      'code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _chairsMeta = const VerificationMeta('chairs');
  @override
  late final GeneratedColumn<int> chairs = GeneratedColumn<int>(
      'chairs', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(4));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('free'));
  static const VerificationMeta _recordUuidMeta =
      const VerificationMeta('recordUuid');
  @override
  late final GeneratedColumn<String> recordUuid = GeneratedColumn<String>(
      'record_uuid', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _branchIdMeta =
      const VerificationMeta('branchId');
  @override
  late final GeneratedColumn<int> branchId = GeneratedColumn<int>(
      'branch_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _pulledTableNameMeta =
      const VerificationMeta('pulledTableName');
  @override
  late final GeneratedColumn<String> pulledTableName = GeneratedColumn<String>(
      'pulled_table_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _pulledTableSlugMeta =
      const VerificationMeta('pulledTableSlug');
  @override
  late final GeneratedColumn<String> pulledTableSlug = GeneratedColumn<String>(
      'pulled_table_slug', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _orderCountMeta =
      const VerificationMeta('orderCount');
  @override
  late final GeneratedColumn<int> orderCount = GeneratedColumn<int>(
      'order_count', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        floorId,
        code,
        chairs,
        status,
        recordUuid,
        branchId,
        pulledTableName,
        pulledTableSlug,
        orderCount,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dining_tables';
  @override
  VerificationContext validateIntegrity(Insertable<DiningTable> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('floor_id')) {
      context.handle(_floorIdMeta,
          floorId.isAcceptableOrUnknown(data['floor_id']!, _floorIdMeta));
    } else if (isInserting) {
      context.missing(_floorIdMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
          _codeMeta, code.isAcceptableOrUnknown(data['code']!, _codeMeta));
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('chairs')) {
      context.handle(_chairsMeta,
          chairs.isAcceptableOrUnknown(data['chairs']!, _chairsMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('record_uuid')) {
      context.handle(
          _recordUuidMeta,
          recordUuid.isAcceptableOrUnknown(
              data['record_uuid']!, _recordUuidMeta));
    }
    if (data.containsKey('branch_id')) {
      context.handle(_branchIdMeta,
          branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta));
    }
    if (data.containsKey('pulled_table_name')) {
      context.handle(
          _pulledTableNameMeta,
          pulledTableName.isAcceptableOrUnknown(
              data['pulled_table_name']!, _pulledTableNameMeta));
    }
    if (data.containsKey('pulled_table_slug')) {
      context.handle(
          _pulledTableSlugMeta,
          pulledTableSlug.isAcceptableOrUnknown(
              data['pulled_table_slug']!, _pulledTableSlugMeta));
    }
    if (data.containsKey('order_count')) {
      context.handle(
          _orderCountMeta,
          orderCount.isAcceptableOrUnknown(
              data['order_count']!, _orderCountMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DiningTable map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DiningTable(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      floorId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}floor_id'])!,
      code: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}code'])!,
      chairs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}chairs'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      recordUuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}record_uuid']),
      branchId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}branch_id']),
      pulledTableName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}pulled_table_name']),
      pulledTableSlug: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}pulled_table_slug']),
      orderCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order_count']),
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $DiningTablesTable createAlias(String alias) {
    return $DiningTablesTable(attachedDatabase, alias);
  }
}

class DiningTable extends DataClass implements Insertable<DiningTable> {
  final int id;
  final int floorId;
  final String code;
  final int chairs;
  final String status;

  /// [TablesCreatedUpdated] from [TableSyncResponse]
  final String? recordUuid;
  final int? branchId;

  /// Maps to API `table_name` from [TablesCreatedUpdated]; column cannot be named `tableName` (Drift reserved).
  final String? pulledTableName;
  final String? pulledTableSlug;
  final int? orderCount;
  final DateTime? deletedAt;
  const DiningTable(
      {required this.id,
      required this.floorId,
      required this.code,
      required this.chairs,
      required this.status,
      this.recordUuid,
      this.branchId,
      this.pulledTableName,
      this.pulledTableSlug,
      this.orderCount,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['floor_id'] = Variable<int>(floorId);
    map['code'] = Variable<String>(code);
    map['chairs'] = Variable<int>(chairs);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || recordUuid != null) {
      map['record_uuid'] = Variable<String>(recordUuid);
    }
    if (!nullToAbsent || branchId != null) {
      map['branch_id'] = Variable<int>(branchId);
    }
    if (!nullToAbsent || pulledTableName != null) {
      map['pulled_table_name'] = Variable<String>(pulledTableName);
    }
    if (!nullToAbsent || pulledTableSlug != null) {
      map['pulled_table_slug'] = Variable<String>(pulledTableSlug);
    }
    if (!nullToAbsent || orderCount != null) {
      map['order_count'] = Variable<int>(orderCount);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  DiningTablesCompanion toCompanion(bool nullToAbsent) {
    return DiningTablesCompanion(
      id: Value(id),
      floorId: Value(floorId),
      code: Value(code),
      chairs: Value(chairs),
      status: Value(status),
      recordUuid: recordUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(recordUuid),
      branchId: branchId == null && nullToAbsent
          ? const Value.absent()
          : Value(branchId),
      pulledTableName: pulledTableName == null && nullToAbsent
          ? const Value.absent()
          : Value(pulledTableName),
      pulledTableSlug: pulledTableSlug == null && nullToAbsent
          ? const Value.absent()
          : Value(pulledTableSlug),
      orderCount: orderCount == null && nullToAbsent
          ? const Value.absent()
          : Value(orderCount),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory DiningTable.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DiningTable(
      id: serializer.fromJson<int>(json['id']),
      floorId: serializer.fromJson<int>(json['floorId']),
      code: serializer.fromJson<String>(json['code']),
      chairs: serializer.fromJson<int>(json['chairs']),
      status: serializer.fromJson<String>(json['status']),
      recordUuid: serializer.fromJson<String?>(json['recordUuid']),
      branchId: serializer.fromJson<int?>(json['branchId']),
      pulledTableName: serializer.fromJson<String?>(json['pulledTableName']),
      pulledTableSlug: serializer.fromJson<String?>(json['pulledTableSlug']),
      orderCount: serializer.fromJson<int?>(json['orderCount']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'floorId': serializer.toJson<int>(floorId),
      'code': serializer.toJson<String>(code),
      'chairs': serializer.toJson<int>(chairs),
      'status': serializer.toJson<String>(status),
      'recordUuid': serializer.toJson<String?>(recordUuid),
      'branchId': serializer.toJson<int?>(branchId),
      'pulledTableName': serializer.toJson<String?>(pulledTableName),
      'pulledTableSlug': serializer.toJson<String?>(pulledTableSlug),
      'orderCount': serializer.toJson<int?>(orderCount),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  DiningTable copyWith(
          {int? id,
          int? floorId,
          String? code,
          int? chairs,
          String? status,
          Value<String?> recordUuid = const Value.absent(),
          Value<int?> branchId = const Value.absent(),
          Value<String?> pulledTableName = const Value.absent(),
          Value<String?> pulledTableSlug = const Value.absent(),
          Value<int?> orderCount = const Value.absent(),
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      DiningTable(
        id: id ?? this.id,
        floorId: floorId ?? this.floorId,
        code: code ?? this.code,
        chairs: chairs ?? this.chairs,
        status: status ?? this.status,
        recordUuid: recordUuid.present ? recordUuid.value : this.recordUuid,
        branchId: branchId.present ? branchId.value : this.branchId,
        pulledTableName: pulledTableName.present
            ? pulledTableName.value
            : this.pulledTableName,
        pulledTableSlug: pulledTableSlug.present
            ? pulledTableSlug.value
            : this.pulledTableSlug,
        orderCount: orderCount.present ? orderCount.value : this.orderCount,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  DiningTable copyWithCompanion(DiningTablesCompanion data) {
    return DiningTable(
      id: data.id.present ? data.id.value : this.id,
      floorId: data.floorId.present ? data.floorId.value : this.floorId,
      code: data.code.present ? data.code.value : this.code,
      chairs: data.chairs.present ? data.chairs.value : this.chairs,
      status: data.status.present ? data.status.value : this.status,
      recordUuid:
          data.recordUuid.present ? data.recordUuid.value : this.recordUuid,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      pulledTableName: data.pulledTableName.present
          ? data.pulledTableName.value
          : this.pulledTableName,
      pulledTableSlug: data.pulledTableSlug.present
          ? data.pulledTableSlug.value
          : this.pulledTableSlug,
      orderCount:
          data.orderCount.present ? data.orderCount.value : this.orderCount,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DiningTable(')
          ..write('id: $id, ')
          ..write('floorId: $floorId, ')
          ..write('code: $code, ')
          ..write('chairs: $chairs, ')
          ..write('status: $status, ')
          ..write('recordUuid: $recordUuid, ')
          ..write('branchId: $branchId, ')
          ..write('pulledTableName: $pulledTableName, ')
          ..write('pulledTableSlug: $pulledTableSlug, ')
          ..write('orderCount: $orderCount, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, floorId, code, chairs, status, recordUuid,
      branchId, pulledTableName, pulledTableSlug, orderCount, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DiningTable &&
          other.id == this.id &&
          other.floorId == this.floorId &&
          other.code == this.code &&
          other.chairs == this.chairs &&
          other.status == this.status &&
          other.recordUuid == this.recordUuid &&
          other.branchId == this.branchId &&
          other.pulledTableName == this.pulledTableName &&
          other.pulledTableSlug == this.pulledTableSlug &&
          other.orderCount == this.orderCount &&
          other.deletedAt == this.deletedAt);
}

class DiningTablesCompanion extends UpdateCompanion<DiningTable> {
  final Value<int> id;
  final Value<int> floorId;
  final Value<String> code;
  final Value<int> chairs;
  final Value<String> status;
  final Value<String?> recordUuid;
  final Value<int?> branchId;
  final Value<String?> pulledTableName;
  final Value<String?> pulledTableSlug;
  final Value<int?> orderCount;
  final Value<DateTime?> deletedAt;
  const DiningTablesCompanion({
    this.id = const Value.absent(),
    this.floorId = const Value.absent(),
    this.code = const Value.absent(),
    this.chairs = const Value.absent(),
    this.status = const Value.absent(),
    this.recordUuid = const Value.absent(),
    this.branchId = const Value.absent(),
    this.pulledTableName = const Value.absent(),
    this.pulledTableSlug = const Value.absent(),
    this.orderCount = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  DiningTablesCompanion.insert({
    this.id = const Value.absent(),
    required int floorId,
    required String code,
    this.chairs = const Value.absent(),
    this.status = const Value.absent(),
    this.recordUuid = const Value.absent(),
    this.branchId = const Value.absent(),
    this.pulledTableName = const Value.absent(),
    this.pulledTableSlug = const Value.absent(),
    this.orderCount = const Value.absent(),
    this.deletedAt = const Value.absent(),
  })  : floorId = Value(floorId),
        code = Value(code);
  static Insertable<DiningTable> custom({
    Expression<int>? id,
    Expression<int>? floorId,
    Expression<String>? code,
    Expression<int>? chairs,
    Expression<String>? status,
    Expression<String>? recordUuid,
    Expression<int>? branchId,
    Expression<String>? pulledTableName,
    Expression<String>? pulledTableSlug,
    Expression<int>? orderCount,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (floorId != null) 'floor_id': floorId,
      if (code != null) 'code': code,
      if (chairs != null) 'chairs': chairs,
      if (status != null) 'status': status,
      if (recordUuid != null) 'record_uuid': recordUuid,
      if (branchId != null) 'branch_id': branchId,
      if (pulledTableName != null) 'pulled_table_name': pulledTableName,
      if (pulledTableSlug != null) 'pulled_table_slug': pulledTableSlug,
      if (orderCount != null) 'order_count': orderCount,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  DiningTablesCompanion copyWith(
      {Value<int>? id,
      Value<int>? floorId,
      Value<String>? code,
      Value<int>? chairs,
      Value<String>? status,
      Value<String?>? recordUuid,
      Value<int?>? branchId,
      Value<String?>? pulledTableName,
      Value<String?>? pulledTableSlug,
      Value<int?>? orderCount,
      Value<DateTime?>? deletedAt}) {
    return DiningTablesCompanion(
      id: id ?? this.id,
      floorId: floorId ?? this.floorId,
      code: code ?? this.code,
      chairs: chairs ?? this.chairs,
      status: status ?? this.status,
      recordUuid: recordUuid ?? this.recordUuid,
      branchId: branchId ?? this.branchId,
      pulledTableName: pulledTableName ?? this.pulledTableName,
      pulledTableSlug: pulledTableSlug ?? this.pulledTableSlug,
      orderCount: orderCount ?? this.orderCount,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (floorId.present) {
      map['floor_id'] = Variable<int>(floorId.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (chairs.present) {
      map['chairs'] = Variable<int>(chairs.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (recordUuid.present) {
      map['record_uuid'] = Variable<String>(recordUuid.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<int>(branchId.value);
    }
    if (pulledTableName.present) {
      map['pulled_table_name'] = Variable<String>(pulledTableName.value);
    }
    if (pulledTableSlug.present) {
      map['pulled_table_slug'] = Variable<String>(pulledTableSlug.value);
    }
    if (orderCount.present) {
      map['order_count'] = Variable<int>(orderCount.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DiningTablesCompanion(')
          ..write('id: $id, ')
          ..write('floorId: $floorId, ')
          ..write('code: $code, ')
          ..write('chairs: $chairs, ')
          ..write('status: $status, ')
          ..write('recordUuid: $recordUuid, ')
          ..write('branchId: $branchId, ')
          ..write('pulledTableName: $pulledTableName, ')
          ..write('pulledTableSlug: $pulledTableSlug, ')
          ..write('orderCount: $orderCount, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $BranchesTable extends Branches with TableInfo<$BranchesTable, Branche> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BranchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _branchNameMeta =
      const VerificationMeta('branchName');
  @override
  late final GeneratedColumn<String> branchName = GeneratedColumn<String>(
      'branch_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _locationMeta =
      const VerificationMeta('location');
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
      'location', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contactNoMeta =
      const VerificationMeta('contactNo');
  @override
  late final GeneratedColumn<String> contactNo = GeneratedColumn<String>(
      'contact_no', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _socialMediaMeta =
      const VerificationMeta('socialMedia');
  @override
  late final GeneratedColumn<String> socialMedia = GeneratedColumn<String>(
      'social_media', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _vatMeta = const VerificationMeta('vat');
  @override
  late final GeneratedColumn<String> vat = GeneratedColumn<String>(
      'vat', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _vatPercentMeta =
      const VerificationMeta('vatPercent');
  @override
  late final GeneratedColumn<double> vatPercent = GeneratedColumn<double>(
      'vat_percent', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _trnNumberMeta =
      const VerificationMeta('trnNumber');
  @override
  late final GeneratedColumn<String> trnNumber = GeneratedColumn<String>(
      'trn_number', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _prefixInvMeta =
      const VerificationMeta('prefixInv');
  @override
  late final GeneratedColumn<String> prefixInv = GeneratedColumn<String>(
      'prefix_inv', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _invoiceHeaderMeta =
      const VerificationMeta('invoiceHeader');
  @override
  late final GeneratedColumn<String> invoiceHeader = GeneratedColumn<String>(
      'invoice_header', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _imageMeta = const VerificationMeta('image');
  @override
  late final GeneratedColumn<String> image = GeneratedColumn<String>(
      'image', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _localImageMeta =
      const VerificationMeta('localImage');
  @override
  late final GeneratedColumn<String> localImage = GeneratedColumn<String>(
      'local_image', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _installationDateMeta =
      const VerificationMeta('installationDate');
  @override
  late final GeneratedColumn<DateTime> installationDate =
      GeneratedColumn<DateTime>('installation_date', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _expiryDateMeta =
      const VerificationMeta('expiryDate');
  @override
  late final GeneratedColumn<DateTime> expiryDate = GeneratedColumn<DateTime>(
      'expiry_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _openingCashMeta =
      const VerificationMeta('openingCash');
  @override
  late final GeneratedColumn<int> openingCash = GeneratedColumn<int>(
      'opening_cash', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        branchName,
        location,
        contactNo,
        email,
        socialMedia,
        vat,
        vatPercent,
        trnNumber,
        prefixInv,
        invoiceHeader,
        image,
        localImage,
        installationDate,
        expiryDate,
        openingCash
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'branches';
  @override
  VerificationContext validateIntegrity(Insertable<Branche> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('branch_name')) {
      context.handle(
          _branchNameMeta,
          branchName.isAcceptableOrUnknown(
              data['branch_name']!, _branchNameMeta));
    } else if (isInserting) {
      context.missing(_branchNameMeta);
    }
    if (data.containsKey('location')) {
      context.handle(_locationMeta,
          location.isAcceptableOrUnknown(data['location']!, _locationMeta));
    } else if (isInserting) {
      context.missing(_locationMeta);
    }
    if (data.containsKey('contact_no')) {
      context.handle(_contactNoMeta,
          contactNo.isAcceptableOrUnknown(data['contact_no']!, _contactNoMeta));
    } else if (isInserting) {
      context.missing(_contactNoMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    }
    if (data.containsKey('social_media')) {
      context.handle(
          _socialMediaMeta,
          socialMedia.isAcceptableOrUnknown(
              data['social_media']!, _socialMediaMeta));
    }
    if (data.containsKey('vat')) {
      context.handle(
          _vatMeta, vat.isAcceptableOrUnknown(data['vat']!, _vatMeta));
    } else if (isInserting) {
      context.missing(_vatMeta);
    }
    if (data.containsKey('vat_percent')) {
      context.handle(
          _vatPercentMeta,
          vatPercent.isAcceptableOrUnknown(
              data['vat_percent']!, _vatPercentMeta));
    }
    if (data.containsKey('trn_number')) {
      context.handle(_trnNumberMeta,
          trnNumber.isAcceptableOrUnknown(data['trn_number']!, _trnNumberMeta));
    }
    if (data.containsKey('prefix_inv')) {
      context.handle(_prefixInvMeta,
          prefixInv.isAcceptableOrUnknown(data['prefix_inv']!, _prefixInvMeta));
    } else if (isInserting) {
      context.missing(_prefixInvMeta);
    }
    if (data.containsKey('invoice_header')) {
      context.handle(
          _invoiceHeaderMeta,
          invoiceHeader.isAcceptableOrUnknown(
              data['invoice_header']!, _invoiceHeaderMeta));
    } else if (isInserting) {
      context.missing(_invoiceHeaderMeta);
    }
    if (data.containsKey('image')) {
      context.handle(
          _imageMeta, image.isAcceptableOrUnknown(data['image']!, _imageMeta));
    } else if (isInserting) {
      context.missing(_imageMeta);
    }
    if (data.containsKey('local_image')) {
      context.handle(
          _localImageMeta,
          localImage.isAcceptableOrUnknown(
              data['local_image']!, _localImageMeta));
    }
    if (data.containsKey('installation_date')) {
      context.handle(
          _installationDateMeta,
          installationDate.isAcceptableOrUnknown(
              data['installation_date']!, _installationDateMeta));
    } else if (isInserting) {
      context.missing(_installationDateMeta);
    }
    if (data.containsKey('expiry_date')) {
      context.handle(
          _expiryDateMeta,
          expiryDate.isAcceptableOrUnknown(
              data['expiry_date']!, _expiryDateMeta));
    } else if (isInserting) {
      context.missing(_expiryDateMeta);
    }
    if (data.containsKey('opening_cash')) {
      context.handle(
          _openingCashMeta,
          openingCash.isAcceptableOrUnknown(
              data['opening_cash']!, _openingCashMeta));
    } else if (isInserting) {
      context.missing(_openingCashMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Branche map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Branche(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      branchName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}branch_name'])!,
      location: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}location'])!,
      contactNo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}contact_no'])!,
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email']),
      socialMedia: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}social_media']),
      vat: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vat'])!,
      vatPercent: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}vat_percent']),
      trnNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}trn_number']),
      prefixInv: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}prefix_inv'])!,
      invoiceHeader: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}invoice_header'])!,
      image: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image'])!,
      localImage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_image'])!,
      installationDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}installation_date'])!,
      expiryDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}expiry_date'])!,
      openingCash: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}opening_cash'])!,
    );
  }

  @override
  $BranchesTable createAlias(String alias) {
    return $BranchesTable(attachedDatabase, alias);
  }
}

class Branche extends DataClass implements Insertable<Branche> {
  final int id;
  final String branchName;
  final String location;
  final String contactNo;
  final String? email;
  final String? socialMedia;
  final String vat;
  final double? vatPercent;
  final String? trnNumber;
  final String prefixInv;
  final String invoiceHeader;
  final String image;
  final String localImage;
  final DateTime installationDate;
  final DateTime expiryDate;
  final int openingCash;
  const Branche(
      {required this.id,
      required this.branchName,
      required this.location,
      required this.contactNo,
      this.email,
      this.socialMedia,
      required this.vat,
      this.vatPercent,
      this.trnNumber,
      required this.prefixInv,
      required this.invoiceHeader,
      required this.image,
      required this.localImage,
      required this.installationDate,
      required this.expiryDate,
      required this.openingCash});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['branch_name'] = Variable<String>(branchName);
    map['location'] = Variable<String>(location);
    map['contact_no'] = Variable<String>(contactNo);
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || socialMedia != null) {
      map['social_media'] = Variable<String>(socialMedia);
    }
    map['vat'] = Variable<String>(vat);
    if (!nullToAbsent || vatPercent != null) {
      map['vat_percent'] = Variable<double>(vatPercent);
    }
    if (!nullToAbsent || trnNumber != null) {
      map['trn_number'] = Variable<String>(trnNumber);
    }
    map['prefix_inv'] = Variable<String>(prefixInv);
    map['invoice_header'] = Variable<String>(invoiceHeader);
    map['image'] = Variable<String>(image);
    map['local_image'] = Variable<String>(localImage);
    map['installation_date'] = Variable<DateTime>(installationDate);
    map['expiry_date'] = Variable<DateTime>(expiryDate);
    map['opening_cash'] = Variable<int>(openingCash);
    return map;
  }

  BranchesCompanion toCompanion(bool nullToAbsent) {
    return BranchesCompanion(
      id: Value(id),
      branchName: Value(branchName),
      location: Value(location),
      contactNo: Value(contactNo),
      email:
          email == null && nullToAbsent ? const Value.absent() : Value(email),
      socialMedia: socialMedia == null && nullToAbsent
          ? const Value.absent()
          : Value(socialMedia),
      vat: Value(vat),
      vatPercent: vatPercent == null && nullToAbsent
          ? const Value.absent()
          : Value(vatPercent),
      trnNumber: trnNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(trnNumber),
      prefixInv: Value(prefixInv),
      invoiceHeader: Value(invoiceHeader),
      image: Value(image),
      localImage: Value(localImage),
      installationDate: Value(installationDate),
      expiryDate: Value(expiryDate),
      openingCash: Value(openingCash),
    );
  }

  factory Branche.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Branche(
      id: serializer.fromJson<int>(json['id']),
      branchName: serializer.fromJson<String>(json['branchName']),
      location: serializer.fromJson<String>(json['location']),
      contactNo: serializer.fromJson<String>(json['contactNo']),
      email: serializer.fromJson<String?>(json['email']),
      socialMedia: serializer.fromJson<String?>(json['socialMedia']),
      vat: serializer.fromJson<String>(json['vat']),
      vatPercent: serializer.fromJson<double?>(json['vatPercent']),
      trnNumber: serializer.fromJson<String?>(json['trnNumber']),
      prefixInv: serializer.fromJson<String>(json['prefixInv']),
      invoiceHeader: serializer.fromJson<String>(json['invoiceHeader']),
      image: serializer.fromJson<String>(json['image']),
      localImage: serializer.fromJson<String>(json['localImage']),
      installationDate: serializer.fromJson<DateTime>(json['installationDate']),
      expiryDate: serializer.fromJson<DateTime>(json['expiryDate']),
      openingCash: serializer.fromJson<int>(json['openingCash']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'branchName': serializer.toJson<String>(branchName),
      'location': serializer.toJson<String>(location),
      'contactNo': serializer.toJson<String>(contactNo),
      'email': serializer.toJson<String?>(email),
      'socialMedia': serializer.toJson<String?>(socialMedia),
      'vat': serializer.toJson<String>(vat),
      'vatPercent': serializer.toJson<double?>(vatPercent),
      'trnNumber': serializer.toJson<String?>(trnNumber),
      'prefixInv': serializer.toJson<String>(prefixInv),
      'invoiceHeader': serializer.toJson<String>(invoiceHeader),
      'image': serializer.toJson<String>(image),
      'localImage': serializer.toJson<String>(localImage),
      'installationDate': serializer.toJson<DateTime>(installationDate),
      'expiryDate': serializer.toJson<DateTime>(expiryDate),
      'openingCash': serializer.toJson<int>(openingCash),
    };
  }

  Branche copyWith(
          {int? id,
          String? branchName,
          String? location,
          String? contactNo,
          Value<String?> email = const Value.absent(),
          Value<String?> socialMedia = const Value.absent(),
          String? vat,
          Value<double?> vatPercent = const Value.absent(),
          Value<String?> trnNumber = const Value.absent(),
          String? prefixInv,
          String? invoiceHeader,
          String? image,
          String? localImage,
          DateTime? installationDate,
          DateTime? expiryDate,
          int? openingCash}) =>
      Branche(
        id: id ?? this.id,
        branchName: branchName ?? this.branchName,
        location: location ?? this.location,
        contactNo: contactNo ?? this.contactNo,
        email: email.present ? email.value : this.email,
        socialMedia: socialMedia.present ? socialMedia.value : this.socialMedia,
        vat: vat ?? this.vat,
        vatPercent: vatPercent.present ? vatPercent.value : this.vatPercent,
        trnNumber: trnNumber.present ? trnNumber.value : this.trnNumber,
        prefixInv: prefixInv ?? this.prefixInv,
        invoiceHeader: invoiceHeader ?? this.invoiceHeader,
        image: image ?? this.image,
        localImage: localImage ?? this.localImage,
        installationDate: installationDate ?? this.installationDate,
        expiryDate: expiryDate ?? this.expiryDate,
        openingCash: openingCash ?? this.openingCash,
      );
  Branche copyWithCompanion(BranchesCompanion data) {
    return Branche(
      id: data.id.present ? data.id.value : this.id,
      branchName:
          data.branchName.present ? data.branchName.value : this.branchName,
      location: data.location.present ? data.location.value : this.location,
      contactNo: data.contactNo.present ? data.contactNo.value : this.contactNo,
      email: data.email.present ? data.email.value : this.email,
      socialMedia:
          data.socialMedia.present ? data.socialMedia.value : this.socialMedia,
      vat: data.vat.present ? data.vat.value : this.vat,
      vatPercent:
          data.vatPercent.present ? data.vatPercent.value : this.vatPercent,
      trnNumber: data.trnNumber.present ? data.trnNumber.value : this.trnNumber,
      prefixInv: data.prefixInv.present ? data.prefixInv.value : this.prefixInv,
      invoiceHeader: data.invoiceHeader.present
          ? data.invoiceHeader.value
          : this.invoiceHeader,
      image: data.image.present ? data.image.value : this.image,
      localImage:
          data.localImage.present ? data.localImage.value : this.localImage,
      installationDate: data.installationDate.present
          ? data.installationDate.value
          : this.installationDate,
      expiryDate:
          data.expiryDate.present ? data.expiryDate.value : this.expiryDate,
      openingCash:
          data.openingCash.present ? data.openingCash.value : this.openingCash,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Branche(')
          ..write('id: $id, ')
          ..write('branchName: $branchName, ')
          ..write('location: $location, ')
          ..write('contactNo: $contactNo, ')
          ..write('email: $email, ')
          ..write('socialMedia: $socialMedia, ')
          ..write('vat: $vat, ')
          ..write('vatPercent: $vatPercent, ')
          ..write('trnNumber: $trnNumber, ')
          ..write('prefixInv: $prefixInv, ')
          ..write('invoiceHeader: $invoiceHeader, ')
          ..write('image: $image, ')
          ..write('localImage: $localImage, ')
          ..write('installationDate: $installationDate, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('openingCash: $openingCash')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      branchName,
      location,
      contactNo,
      email,
      socialMedia,
      vat,
      vatPercent,
      trnNumber,
      prefixInv,
      invoiceHeader,
      image,
      localImage,
      installationDate,
      expiryDate,
      openingCash);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Branche &&
          other.id == this.id &&
          other.branchName == this.branchName &&
          other.location == this.location &&
          other.contactNo == this.contactNo &&
          other.email == this.email &&
          other.socialMedia == this.socialMedia &&
          other.vat == this.vat &&
          other.vatPercent == this.vatPercent &&
          other.trnNumber == this.trnNumber &&
          other.prefixInv == this.prefixInv &&
          other.invoiceHeader == this.invoiceHeader &&
          other.image == this.image &&
          other.localImage == this.localImage &&
          other.installationDate == this.installationDate &&
          other.expiryDate == this.expiryDate &&
          other.openingCash == this.openingCash);
}

class BranchesCompanion extends UpdateCompanion<Branche> {
  final Value<int> id;
  final Value<String> branchName;
  final Value<String> location;
  final Value<String> contactNo;
  final Value<String?> email;
  final Value<String?> socialMedia;
  final Value<String> vat;
  final Value<double?> vatPercent;
  final Value<String?> trnNumber;
  final Value<String> prefixInv;
  final Value<String> invoiceHeader;
  final Value<String> image;
  final Value<String> localImage;
  final Value<DateTime> installationDate;
  final Value<DateTime> expiryDate;
  final Value<int> openingCash;
  const BranchesCompanion({
    this.id = const Value.absent(),
    this.branchName = const Value.absent(),
    this.location = const Value.absent(),
    this.contactNo = const Value.absent(),
    this.email = const Value.absent(),
    this.socialMedia = const Value.absent(),
    this.vat = const Value.absent(),
    this.vatPercent = const Value.absent(),
    this.trnNumber = const Value.absent(),
    this.prefixInv = const Value.absent(),
    this.invoiceHeader = const Value.absent(),
    this.image = const Value.absent(),
    this.localImage = const Value.absent(),
    this.installationDate = const Value.absent(),
    this.expiryDate = const Value.absent(),
    this.openingCash = const Value.absent(),
  });
  BranchesCompanion.insert({
    this.id = const Value.absent(),
    required String branchName,
    required String location,
    required String contactNo,
    this.email = const Value.absent(),
    this.socialMedia = const Value.absent(),
    required String vat,
    this.vatPercent = const Value.absent(),
    this.trnNumber = const Value.absent(),
    required String prefixInv,
    required String invoiceHeader,
    required String image,
    this.localImage = const Value.absent(),
    required DateTime installationDate,
    required DateTime expiryDate,
    required int openingCash,
  })  : branchName = Value(branchName),
        location = Value(location),
        contactNo = Value(contactNo),
        vat = Value(vat),
        prefixInv = Value(prefixInv),
        invoiceHeader = Value(invoiceHeader),
        image = Value(image),
        installationDate = Value(installationDate),
        expiryDate = Value(expiryDate),
        openingCash = Value(openingCash);
  static Insertable<Branche> custom({
    Expression<int>? id,
    Expression<String>? branchName,
    Expression<String>? location,
    Expression<String>? contactNo,
    Expression<String>? email,
    Expression<String>? socialMedia,
    Expression<String>? vat,
    Expression<double>? vatPercent,
    Expression<String>? trnNumber,
    Expression<String>? prefixInv,
    Expression<String>? invoiceHeader,
    Expression<String>? image,
    Expression<String>? localImage,
    Expression<DateTime>? installationDate,
    Expression<DateTime>? expiryDate,
    Expression<int>? openingCash,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (branchName != null) 'branch_name': branchName,
      if (location != null) 'location': location,
      if (contactNo != null) 'contact_no': contactNo,
      if (email != null) 'email': email,
      if (socialMedia != null) 'social_media': socialMedia,
      if (vat != null) 'vat': vat,
      if (vatPercent != null) 'vat_percent': vatPercent,
      if (trnNumber != null) 'trn_number': trnNumber,
      if (prefixInv != null) 'prefix_inv': prefixInv,
      if (invoiceHeader != null) 'invoice_header': invoiceHeader,
      if (image != null) 'image': image,
      if (localImage != null) 'local_image': localImage,
      if (installationDate != null) 'installation_date': installationDate,
      if (expiryDate != null) 'expiry_date': expiryDate,
      if (openingCash != null) 'opening_cash': openingCash,
    });
  }

  BranchesCompanion copyWith(
      {Value<int>? id,
      Value<String>? branchName,
      Value<String>? location,
      Value<String>? contactNo,
      Value<String?>? email,
      Value<String?>? socialMedia,
      Value<String>? vat,
      Value<double?>? vatPercent,
      Value<String?>? trnNumber,
      Value<String>? prefixInv,
      Value<String>? invoiceHeader,
      Value<String>? image,
      Value<String>? localImage,
      Value<DateTime>? installationDate,
      Value<DateTime>? expiryDate,
      Value<int>? openingCash}) {
    return BranchesCompanion(
      id: id ?? this.id,
      branchName: branchName ?? this.branchName,
      location: location ?? this.location,
      contactNo: contactNo ?? this.contactNo,
      email: email ?? this.email,
      socialMedia: socialMedia ?? this.socialMedia,
      vat: vat ?? this.vat,
      vatPercent: vatPercent ?? this.vatPercent,
      trnNumber: trnNumber ?? this.trnNumber,
      prefixInv: prefixInv ?? this.prefixInv,
      invoiceHeader: invoiceHeader ?? this.invoiceHeader,
      image: image ?? this.image,
      localImage: localImage ?? this.localImage,
      installationDate: installationDate ?? this.installationDate,
      expiryDate: expiryDate ?? this.expiryDate,
      openingCash: openingCash ?? this.openingCash,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (branchName.present) {
      map['branch_name'] = Variable<String>(branchName.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (contactNo.present) {
      map['contact_no'] = Variable<String>(contactNo.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (socialMedia.present) {
      map['social_media'] = Variable<String>(socialMedia.value);
    }
    if (vat.present) {
      map['vat'] = Variable<String>(vat.value);
    }
    if (vatPercent.present) {
      map['vat_percent'] = Variable<double>(vatPercent.value);
    }
    if (trnNumber.present) {
      map['trn_number'] = Variable<String>(trnNumber.value);
    }
    if (prefixInv.present) {
      map['prefix_inv'] = Variable<String>(prefixInv.value);
    }
    if (invoiceHeader.present) {
      map['invoice_header'] = Variable<String>(invoiceHeader.value);
    }
    if (image.present) {
      map['image'] = Variable<String>(image.value);
    }
    if (localImage.present) {
      map['local_image'] = Variable<String>(localImage.value);
    }
    if (installationDate.present) {
      map['installation_date'] = Variable<DateTime>(installationDate.value);
    }
    if (expiryDate.present) {
      map['expiry_date'] = Variable<DateTime>(expiryDate.value);
    }
    if (openingCash.present) {
      map['opening_cash'] = Variable<int>(openingCash.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BranchesCompanion(')
          ..write('id: $id, ')
          ..write('branchName: $branchName, ')
          ..write('location: $location, ')
          ..write('contactNo: $contactNo, ')
          ..write('email: $email, ')
          ..write('socialMedia: $socialMedia, ')
          ..write('vat: $vat, ')
          ..write('vatPercent: $vatPercent, ')
          ..write('trnNumber: $trnNumber, ')
          ..write('prefixInv: $prefixInv, ')
          ..write('invoiceHeader: $invoiceHeader, ')
          ..write('image: $image, ')
          ..write('localImage: $localImage, ')
          ..write('installationDate: $installationDate, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('openingCash: $openingCash')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _decimalPointMeta =
      const VerificationMeta('decimalPoint');
  @override
  late final GeneratedColumn<String> decimalPoint = GeneratedColumn<String>(
      'decimal_point', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateFormatMeta =
      const VerificationMeta('dateFormat');
  @override
  late final GeneratedColumn<String> dateFormat = GeneratedColumn<String>(
      'date_format', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timeFormatMeta =
      const VerificationMeta('timeFormat');
  @override
  late final GeneratedColumn<String> timeFormat = GeneratedColumn<String>(
      'time_format', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _unitPriceMeta =
      const VerificationMeta('unitPrice');
  @override
  late final GeneratedColumn<String> unitPrice = GeneratedColumn<String>(
      'unit_price', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _stockCheckMeta =
      const VerificationMeta('stockCheck');
  @override
  late final GeneratedColumn<String> stockCheck = GeneratedColumn<String>(
      'stock_check', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _stockShowMeta =
      const VerificationMeta('stockShow');
  @override
  late final GeneratedColumn<String> stockShow = GeneratedColumn<String>(
      'stock_show', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _settleCheckPendingMeta =
      const VerificationMeta('settleCheckPending');
  @override
  late final GeneratedColumn<String> settleCheckPending =
      GeneratedColumn<String>('settle_check_pending', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deliverySaleMeta =
      const VerificationMeta('deliverySale');
  @override
  late final GeneratedColumn<String> deliverySale = GeneratedColumn<String>(
      'delivery_sale', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _apiKeyMeta = const VerificationMeta('apiKey');
  @override
  late final GeneratedColumn<String> apiKey = GeneratedColumn<String>(
      'api_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _customProductMeta =
      const VerificationMeta('customProduct');
  @override
  late final GeneratedColumn<String> customProduct = GeneratedColumn<String>(
      'custom_product', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _languageMeta =
      const VerificationMeta('language');
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
      'language', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _staffPinMeta =
      const VerificationMeta('staffPin');
  @override
  late final GeneratedColumn<String> staffPin = GeneratedColumn<String>(
      'staff_pin', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _barcodeMeta =
      const VerificationMeta('barcode');
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
      'barcode', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _drawerPasswordMeta =
      const VerificationMeta('drawerPassword');
  @override
  late final GeneratedColumn<String> drawerPassword = GeneratedColumn<String>(
      'drawer_password', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _paybackPasswordMeta =
      const VerificationMeta('paybackPassword');
  @override
  late final GeneratedColumn<String> paybackPassword = GeneratedColumn<String>(
      'payback_password', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _purchaseMeta =
      const VerificationMeta('purchase');
  @override
  late final GeneratedColumn<String> purchase = GeneratedColumn<String>(
      'purchase', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productionMeta =
      const VerificationMeta('production');
  @override
  late final GeneratedColumn<String> production = GeneratedColumn<String>(
      'production', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _minimumStockMeta =
      const VerificationMeta('minimumStock');
  @override
  late final GeneratedColumn<String> minimumStock = GeneratedColumn<String>(
      'minimum_stock', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _wastageUsageMeta =
      const VerificationMeta('wastageUsage');
  @override
  late final GeneratedColumn<String> wastageUsage = GeneratedColumn<String>(
      'wastage_usage', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _wastageUsageZeroStockMeta =
      const VerificationMeta('wastageUsageZeroStock');
  @override
  late final GeneratedColumn<String> wastageUsageZeroStock =
      GeneratedColumn<String>('wastage_usage_zero_stock', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _customizeItemMeta =
      const VerificationMeta('customizeItem');
  @override
  late final GeneratedColumn<String> customizeItem = GeneratedColumn<String>(
      'customize_item', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _printTypeMeta =
      const VerificationMeta('printType');
  @override
  late final GeneratedColumn<String> printType = GeneratedColumn<String>(
      'print_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _printLinkMeta =
      const VerificationMeta('printLink');
  @override
  late final GeneratedColumn<String> printLink = GeneratedColumn<String>(
      'print_link', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mainPrintTypeMeta =
      const VerificationMeta('mainPrintType');
  @override
  late final GeneratedColumn<String> mainPrintType = GeneratedColumn<String>(
      'main_print_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mainPrintDetailMeta =
      const VerificationMeta('mainPrintDetail');
  @override
  late final GeneratedColumn<String> mainPrintDetail = GeneratedColumn<String>(
      'main_print_detail', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _printImageInBillMeta =
      const VerificationMeta('printImageInBill');
  @override
  late final GeneratedColumn<String> printImageInBill = GeneratedColumn<String>(
      'print_image_in_bill', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _printBranchNameInBillMeta =
      const VerificationMeta('printBranchNameInBill');
  @override
  late final GeneratedColumn<String> printBranchNameInBill =
      GeneratedColumn<String>('print_branch_name_in_bill', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dineInTableOrderCountMeta =
      const VerificationMeta('dineInTableOrderCount');
  @override
  late final GeneratedColumn<String> dineInTableOrderCount =
      GeneratedColumn<String>('dine_in_table_order_count', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _variationMeta =
      const VerificationMeta('variation');
  @override
  late final GeneratedColumn<String> variation = GeneratedColumn<String>(
      'variation', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _qtyReducePasswordMeta =
      const VerificationMeta('qtyReducePassword');
  @override
  late final GeneratedColumn<String> qtyReducePassword =
      GeneratedColumn<String>('qty_reduce_password', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _counterLoginLimitMeta =
      const VerificationMeta('counterLoginLimit');
  @override
  late final GeneratedColumn<String> counterLoginLimit =
      GeneratedColumn<String>('counter_login_limit', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        currency,
        decimalPoint,
        dateFormat,
        timeFormat,
        unitPrice,
        stockCheck,
        stockShow,
        settleCheckPending,
        deliverySale,
        apiKey,
        customProduct,
        language,
        staffPin,
        barcode,
        drawerPassword,
        paybackPassword,
        purchase,
        production,
        minimumStock,
        wastageUsage,
        wastageUsageZeroStock,
        customizeItem,
        printType,
        printLink,
        mainPrintType,
        mainPrintDetail,
        printImageInBill,
        printBranchNameInBill,
        dineInTableOrderCount,
        variation,
        qtyReducePassword,
        counterLoginLimit
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(Insertable<Setting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('decimal_point')) {
      context.handle(
          _decimalPointMeta,
          decimalPoint.isAcceptableOrUnknown(
              data['decimal_point']!, _decimalPointMeta));
    } else if (isInserting) {
      context.missing(_decimalPointMeta);
    }
    if (data.containsKey('date_format')) {
      context.handle(
          _dateFormatMeta,
          dateFormat.isAcceptableOrUnknown(
              data['date_format']!, _dateFormatMeta));
    } else if (isInserting) {
      context.missing(_dateFormatMeta);
    }
    if (data.containsKey('time_format')) {
      context.handle(
          _timeFormatMeta,
          timeFormat.isAcceptableOrUnknown(
              data['time_format']!, _timeFormatMeta));
    } else if (isInserting) {
      context.missing(_timeFormatMeta);
    }
    if (data.containsKey('unit_price')) {
      context.handle(_unitPriceMeta,
          unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta));
    } else if (isInserting) {
      context.missing(_unitPriceMeta);
    }
    if (data.containsKey('stock_check')) {
      context.handle(
          _stockCheckMeta,
          stockCheck.isAcceptableOrUnknown(
              data['stock_check']!, _stockCheckMeta));
    } else if (isInserting) {
      context.missing(_stockCheckMeta);
    }
    if (data.containsKey('stock_show')) {
      context.handle(_stockShowMeta,
          stockShow.isAcceptableOrUnknown(data['stock_show']!, _stockShowMeta));
    } else if (isInserting) {
      context.missing(_stockShowMeta);
    }
    if (data.containsKey('settle_check_pending')) {
      context.handle(
          _settleCheckPendingMeta,
          settleCheckPending.isAcceptableOrUnknown(
              data['settle_check_pending']!, _settleCheckPendingMeta));
    } else if (isInserting) {
      context.missing(_settleCheckPendingMeta);
    }
    if (data.containsKey('delivery_sale')) {
      context.handle(
          _deliverySaleMeta,
          deliverySale.isAcceptableOrUnknown(
              data['delivery_sale']!, _deliverySaleMeta));
    } else if (isInserting) {
      context.missing(_deliverySaleMeta);
    }
    if (data.containsKey('api_key')) {
      context.handle(_apiKeyMeta,
          apiKey.isAcceptableOrUnknown(data['api_key']!, _apiKeyMeta));
    } else if (isInserting) {
      context.missing(_apiKeyMeta);
    }
    if (data.containsKey('custom_product')) {
      context.handle(
          _customProductMeta,
          customProduct.isAcceptableOrUnknown(
              data['custom_product']!, _customProductMeta));
    } else if (isInserting) {
      context.missing(_customProductMeta);
    }
    if (data.containsKey('language')) {
      context.handle(_languageMeta,
          language.isAcceptableOrUnknown(data['language']!, _languageMeta));
    } else if (isInserting) {
      context.missing(_languageMeta);
    }
    if (data.containsKey('staff_pin')) {
      context.handle(_staffPinMeta,
          staffPin.isAcceptableOrUnknown(data['staff_pin']!, _staffPinMeta));
    } else if (isInserting) {
      context.missing(_staffPinMeta);
    }
    if (data.containsKey('barcode')) {
      context.handle(_barcodeMeta,
          barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta));
    } else if (isInserting) {
      context.missing(_barcodeMeta);
    }
    if (data.containsKey('drawer_password')) {
      context.handle(
          _drawerPasswordMeta,
          drawerPassword.isAcceptableOrUnknown(
              data['drawer_password']!, _drawerPasswordMeta));
    } else if (isInserting) {
      context.missing(_drawerPasswordMeta);
    }
    if (data.containsKey('payback_password')) {
      context.handle(
          _paybackPasswordMeta,
          paybackPassword.isAcceptableOrUnknown(
              data['payback_password']!, _paybackPasswordMeta));
    } else if (isInserting) {
      context.missing(_paybackPasswordMeta);
    }
    if (data.containsKey('purchase')) {
      context.handle(_purchaseMeta,
          purchase.isAcceptableOrUnknown(data['purchase']!, _purchaseMeta));
    } else if (isInserting) {
      context.missing(_purchaseMeta);
    }
    if (data.containsKey('production')) {
      context.handle(
          _productionMeta,
          production.isAcceptableOrUnknown(
              data['production']!, _productionMeta));
    } else if (isInserting) {
      context.missing(_productionMeta);
    }
    if (data.containsKey('minimum_stock')) {
      context.handle(
          _minimumStockMeta,
          minimumStock.isAcceptableOrUnknown(
              data['minimum_stock']!, _minimumStockMeta));
    } else if (isInserting) {
      context.missing(_minimumStockMeta);
    }
    if (data.containsKey('wastage_usage')) {
      context.handle(
          _wastageUsageMeta,
          wastageUsage.isAcceptableOrUnknown(
              data['wastage_usage']!, _wastageUsageMeta));
    } else if (isInserting) {
      context.missing(_wastageUsageMeta);
    }
    if (data.containsKey('wastage_usage_zero_stock')) {
      context.handle(
          _wastageUsageZeroStockMeta,
          wastageUsageZeroStock.isAcceptableOrUnknown(
              data['wastage_usage_zero_stock']!, _wastageUsageZeroStockMeta));
    } else if (isInserting) {
      context.missing(_wastageUsageZeroStockMeta);
    }
    if (data.containsKey('customize_item')) {
      context.handle(
          _customizeItemMeta,
          customizeItem.isAcceptableOrUnknown(
              data['customize_item']!, _customizeItemMeta));
    } else if (isInserting) {
      context.missing(_customizeItemMeta);
    }
    if (data.containsKey('print_type')) {
      context.handle(_printTypeMeta,
          printType.isAcceptableOrUnknown(data['print_type']!, _printTypeMeta));
    } else if (isInserting) {
      context.missing(_printTypeMeta);
    }
    if (data.containsKey('print_link')) {
      context.handle(_printLinkMeta,
          printLink.isAcceptableOrUnknown(data['print_link']!, _printLinkMeta));
    } else if (isInserting) {
      context.missing(_printLinkMeta);
    }
    if (data.containsKey('main_print_type')) {
      context.handle(
          _mainPrintTypeMeta,
          mainPrintType.isAcceptableOrUnknown(
              data['main_print_type']!, _mainPrintTypeMeta));
    } else if (isInserting) {
      context.missing(_mainPrintTypeMeta);
    }
    if (data.containsKey('main_print_detail')) {
      context.handle(
          _mainPrintDetailMeta,
          mainPrintDetail.isAcceptableOrUnknown(
              data['main_print_detail']!, _mainPrintDetailMeta));
    } else if (isInserting) {
      context.missing(_mainPrintDetailMeta);
    }
    if (data.containsKey('print_image_in_bill')) {
      context.handle(
          _printImageInBillMeta,
          printImageInBill.isAcceptableOrUnknown(
              data['print_image_in_bill']!, _printImageInBillMeta));
    } else if (isInserting) {
      context.missing(_printImageInBillMeta);
    }
    if (data.containsKey('print_branch_name_in_bill')) {
      context.handle(
          _printBranchNameInBillMeta,
          printBranchNameInBill.isAcceptableOrUnknown(
              data['print_branch_name_in_bill']!, _printBranchNameInBillMeta));
    } else if (isInserting) {
      context.missing(_printBranchNameInBillMeta);
    }
    if (data.containsKey('dine_in_table_order_count')) {
      context.handle(
          _dineInTableOrderCountMeta,
          dineInTableOrderCount.isAcceptableOrUnknown(
              data['dine_in_table_order_count']!, _dineInTableOrderCountMeta));
    } else if (isInserting) {
      context.missing(_dineInTableOrderCountMeta);
    }
    if (data.containsKey('variation')) {
      context.handle(_variationMeta,
          variation.isAcceptableOrUnknown(data['variation']!, _variationMeta));
    } else if (isInserting) {
      context.missing(_variationMeta);
    }
    if (data.containsKey('qty_reduce_password')) {
      context.handle(
          _qtyReducePasswordMeta,
          qtyReducePassword.isAcceptableOrUnknown(
              data['qty_reduce_password']!, _qtyReducePasswordMeta));
    } else if (isInserting) {
      context.missing(_qtyReducePasswordMeta);
    }
    if (data.containsKey('counter_login_limit')) {
      context.handle(
          _counterLoginLimitMeta,
          counterLoginLimit.isAcceptableOrUnknown(
              data['counter_login_limit']!, _counterLoginLimitMeta));
    } else if (isInserting) {
      context.missing(_counterLoginLimitMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      decimalPoint: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}decimal_point'])!,
      dateFormat: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date_format'])!,
      timeFormat: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}time_format'])!,
      unitPrice: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit_price'])!,
      stockCheck: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stock_check'])!,
      stockShow: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stock_show'])!,
      settleCheckPending: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}settle_check_pending'])!,
      deliverySale: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}delivery_sale'])!,
      apiKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}api_key'])!,
      customProduct: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}custom_product'])!,
      language: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}language'])!,
      staffPin: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}staff_pin'])!,
      barcode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}barcode'])!,
      drawerPassword: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}drawer_password'])!,
      paybackPassword: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}payback_password'])!,
      purchase: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}purchase'])!,
      production: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}production'])!,
      minimumStock: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}minimum_stock'])!,
      wastageUsage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}wastage_usage'])!,
      wastageUsageZeroStock: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}wastage_usage_zero_stock'])!,
      customizeItem: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customize_item'])!,
      printType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}print_type'])!,
      printLink: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}print_link'])!,
      mainPrintType: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}main_print_type'])!,
      mainPrintDetail: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}main_print_detail'])!,
      printImageInBill: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}print_image_in_bill'])!,
      printBranchNameInBill: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}print_branch_name_in_bill'])!,
      dineInTableOrderCount: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}dine_in_table_order_count'])!,
      variation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}variation'])!,
      qtyReducePassword: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}qty_reduce_password'])!,
      counterLoginLimit: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}counter_login_limit'])!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final int id;
  final String currency;
  final String decimalPoint;
  final String dateFormat;
  final String timeFormat;
  final String unitPrice;
  final String stockCheck;
  final String stockShow;
  final String settleCheckPending;
  final String deliverySale;
  final String apiKey;
  final String customProduct;
  final String language;
  final String staffPin;
  final String barcode;
  final String drawerPassword;
  final String paybackPassword;
  final String purchase;
  final String production;
  final String minimumStock;
  final String wastageUsage;
  final String wastageUsageZeroStock;
  final String customizeItem;
  final String printType;
  final String printLink;
  final String mainPrintType;
  final String mainPrintDetail;
  final String printImageInBill;
  final String printBranchNameInBill;
  final String dineInTableOrderCount;
  final String variation;
  final String qtyReducePassword;
  final String counterLoginLimit;
  const Setting(
      {required this.id,
      required this.currency,
      required this.decimalPoint,
      required this.dateFormat,
      required this.timeFormat,
      required this.unitPrice,
      required this.stockCheck,
      required this.stockShow,
      required this.settleCheckPending,
      required this.deliverySale,
      required this.apiKey,
      required this.customProduct,
      required this.language,
      required this.staffPin,
      required this.barcode,
      required this.drawerPassword,
      required this.paybackPassword,
      required this.purchase,
      required this.production,
      required this.minimumStock,
      required this.wastageUsage,
      required this.wastageUsageZeroStock,
      required this.customizeItem,
      required this.printType,
      required this.printLink,
      required this.mainPrintType,
      required this.mainPrintDetail,
      required this.printImageInBill,
      required this.printBranchNameInBill,
      required this.dineInTableOrderCount,
      required this.variation,
      required this.qtyReducePassword,
      required this.counterLoginLimit});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['currency'] = Variable<String>(currency);
    map['decimal_point'] = Variable<String>(decimalPoint);
    map['date_format'] = Variable<String>(dateFormat);
    map['time_format'] = Variable<String>(timeFormat);
    map['unit_price'] = Variable<String>(unitPrice);
    map['stock_check'] = Variable<String>(stockCheck);
    map['stock_show'] = Variable<String>(stockShow);
    map['settle_check_pending'] = Variable<String>(settleCheckPending);
    map['delivery_sale'] = Variable<String>(deliverySale);
    map['api_key'] = Variable<String>(apiKey);
    map['custom_product'] = Variable<String>(customProduct);
    map['language'] = Variable<String>(language);
    map['staff_pin'] = Variable<String>(staffPin);
    map['barcode'] = Variable<String>(barcode);
    map['drawer_password'] = Variable<String>(drawerPassword);
    map['payback_password'] = Variable<String>(paybackPassword);
    map['purchase'] = Variable<String>(purchase);
    map['production'] = Variable<String>(production);
    map['minimum_stock'] = Variable<String>(minimumStock);
    map['wastage_usage'] = Variable<String>(wastageUsage);
    map['wastage_usage_zero_stock'] = Variable<String>(wastageUsageZeroStock);
    map['customize_item'] = Variable<String>(customizeItem);
    map['print_type'] = Variable<String>(printType);
    map['print_link'] = Variable<String>(printLink);
    map['main_print_type'] = Variable<String>(mainPrintType);
    map['main_print_detail'] = Variable<String>(mainPrintDetail);
    map['print_image_in_bill'] = Variable<String>(printImageInBill);
    map['print_branch_name_in_bill'] = Variable<String>(printBranchNameInBill);
    map['dine_in_table_order_count'] = Variable<String>(dineInTableOrderCount);
    map['variation'] = Variable<String>(variation);
    map['qty_reduce_password'] = Variable<String>(qtyReducePassword);
    map['counter_login_limit'] = Variable<String>(counterLoginLimit);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      id: Value(id),
      currency: Value(currency),
      decimalPoint: Value(decimalPoint),
      dateFormat: Value(dateFormat),
      timeFormat: Value(timeFormat),
      unitPrice: Value(unitPrice),
      stockCheck: Value(stockCheck),
      stockShow: Value(stockShow),
      settleCheckPending: Value(settleCheckPending),
      deliverySale: Value(deliverySale),
      apiKey: Value(apiKey),
      customProduct: Value(customProduct),
      language: Value(language),
      staffPin: Value(staffPin),
      barcode: Value(barcode),
      drawerPassword: Value(drawerPassword),
      paybackPassword: Value(paybackPassword),
      purchase: Value(purchase),
      production: Value(production),
      minimumStock: Value(minimumStock),
      wastageUsage: Value(wastageUsage),
      wastageUsageZeroStock: Value(wastageUsageZeroStock),
      customizeItem: Value(customizeItem),
      printType: Value(printType),
      printLink: Value(printLink),
      mainPrintType: Value(mainPrintType),
      mainPrintDetail: Value(mainPrintDetail),
      printImageInBill: Value(printImageInBill),
      printBranchNameInBill: Value(printBranchNameInBill),
      dineInTableOrderCount: Value(dineInTableOrderCount),
      variation: Value(variation),
      qtyReducePassword: Value(qtyReducePassword),
      counterLoginLimit: Value(counterLoginLimit),
    );
  }

  factory Setting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      id: serializer.fromJson<int>(json['id']),
      currency: serializer.fromJson<String>(json['currency']),
      decimalPoint: serializer.fromJson<String>(json['decimalPoint']),
      dateFormat: serializer.fromJson<String>(json['dateFormat']),
      timeFormat: serializer.fromJson<String>(json['timeFormat']),
      unitPrice: serializer.fromJson<String>(json['unitPrice']),
      stockCheck: serializer.fromJson<String>(json['stockCheck']),
      stockShow: serializer.fromJson<String>(json['stockShow']),
      settleCheckPending:
          serializer.fromJson<String>(json['settleCheckPending']),
      deliverySale: serializer.fromJson<String>(json['deliverySale']),
      apiKey: serializer.fromJson<String>(json['apiKey']),
      customProduct: serializer.fromJson<String>(json['customProduct']),
      language: serializer.fromJson<String>(json['language']),
      staffPin: serializer.fromJson<String>(json['staffPin']),
      barcode: serializer.fromJson<String>(json['barcode']),
      drawerPassword: serializer.fromJson<String>(json['drawerPassword']),
      paybackPassword: serializer.fromJson<String>(json['paybackPassword']),
      purchase: serializer.fromJson<String>(json['purchase']),
      production: serializer.fromJson<String>(json['production']),
      minimumStock: serializer.fromJson<String>(json['minimumStock']),
      wastageUsage: serializer.fromJson<String>(json['wastageUsage']),
      wastageUsageZeroStock:
          serializer.fromJson<String>(json['wastageUsageZeroStock']),
      customizeItem: serializer.fromJson<String>(json['customizeItem']),
      printType: serializer.fromJson<String>(json['printType']),
      printLink: serializer.fromJson<String>(json['printLink']),
      mainPrintType: serializer.fromJson<String>(json['mainPrintType']),
      mainPrintDetail: serializer.fromJson<String>(json['mainPrintDetail']),
      printImageInBill: serializer.fromJson<String>(json['printImageInBill']),
      printBranchNameInBill:
          serializer.fromJson<String>(json['printBranchNameInBill']),
      dineInTableOrderCount:
          serializer.fromJson<String>(json['dineInTableOrderCount']),
      variation: serializer.fromJson<String>(json['variation']),
      qtyReducePassword: serializer.fromJson<String>(json['qtyReducePassword']),
      counterLoginLimit: serializer.fromJson<String>(json['counterLoginLimit']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'currency': serializer.toJson<String>(currency),
      'decimalPoint': serializer.toJson<String>(decimalPoint),
      'dateFormat': serializer.toJson<String>(dateFormat),
      'timeFormat': serializer.toJson<String>(timeFormat),
      'unitPrice': serializer.toJson<String>(unitPrice),
      'stockCheck': serializer.toJson<String>(stockCheck),
      'stockShow': serializer.toJson<String>(stockShow),
      'settleCheckPending': serializer.toJson<String>(settleCheckPending),
      'deliverySale': serializer.toJson<String>(deliverySale),
      'apiKey': serializer.toJson<String>(apiKey),
      'customProduct': serializer.toJson<String>(customProduct),
      'language': serializer.toJson<String>(language),
      'staffPin': serializer.toJson<String>(staffPin),
      'barcode': serializer.toJson<String>(barcode),
      'drawerPassword': serializer.toJson<String>(drawerPassword),
      'paybackPassword': serializer.toJson<String>(paybackPassword),
      'purchase': serializer.toJson<String>(purchase),
      'production': serializer.toJson<String>(production),
      'minimumStock': serializer.toJson<String>(minimumStock),
      'wastageUsage': serializer.toJson<String>(wastageUsage),
      'wastageUsageZeroStock': serializer.toJson<String>(wastageUsageZeroStock),
      'customizeItem': serializer.toJson<String>(customizeItem),
      'printType': serializer.toJson<String>(printType),
      'printLink': serializer.toJson<String>(printLink),
      'mainPrintType': serializer.toJson<String>(mainPrintType),
      'mainPrintDetail': serializer.toJson<String>(mainPrintDetail),
      'printImageInBill': serializer.toJson<String>(printImageInBill),
      'printBranchNameInBill': serializer.toJson<String>(printBranchNameInBill),
      'dineInTableOrderCount': serializer.toJson<String>(dineInTableOrderCount),
      'variation': serializer.toJson<String>(variation),
      'qtyReducePassword': serializer.toJson<String>(qtyReducePassword),
      'counterLoginLimit': serializer.toJson<String>(counterLoginLimit),
    };
  }

  Setting copyWith(
          {int? id,
          String? currency,
          String? decimalPoint,
          String? dateFormat,
          String? timeFormat,
          String? unitPrice,
          String? stockCheck,
          String? stockShow,
          String? settleCheckPending,
          String? deliverySale,
          String? apiKey,
          String? customProduct,
          String? language,
          String? staffPin,
          String? barcode,
          String? drawerPassword,
          String? paybackPassword,
          String? purchase,
          String? production,
          String? minimumStock,
          String? wastageUsage,
          String? wastageUsageZeroStock,
          String? customizeItem,
          String? printType,
          String? printLink,
          String? mainPrintType,
          String? mainPrintDetail,
          String? printImageInBill,
          String? printBranchNameInBill,
          String? dineInTableOrderCount,
          String? variation,
          String? qtyReducePassword,
          String? counterLoginLimit}) =>
      Setting(
        id: id ?? this.id,
        currency: currency ?? this.currency,
        decimalPoint: decimalPoint ?? this.decimalPoint,
        dateFormat: dateFormat ?? this.dateFormat,
        timeFormat: timeFormat ?? this.timeFormat,
        unitPrice: unitPrice ?? this.unitPrice,
        stockCheck: stockCheck ?? this.stockCheck,
        stockShow: stockShow ?? this.stockShow,
        settleCheckPending: settleCheckPending ?? this.settleCheckPending,
        deliverySale: deliverySale ?? this.deliverySale,
        apiKey: apiKey ?? this.apiKey,
        customProduct: customProduct ?? this.customProduct,
        language: language ?? this.language,
        staffPin: staffPin ?? this.staffPin,
        barcode: barcode ?? this.barcode,
        drawerPassword: drawerPassword ?? this.drawerPassword,
        paybackPassword: paybackPassword ?? this.paybackPassword,
        purchase: purchase ?? this.purchase,
        production: production ?? this.production,
        minimumStock: minimumStock ?? this.minimumStock,
        wastageUsage: wastageUsage ?? this.wastageUsage,
        wastageUsageZeroStock:
            wastageUsageZeroStock ?? this.wastageUsageZeroStock,
        customizeItem: customizeItem ?? this.customizeItem,
        printType: printType ?? this.printType,
        printLink: printLink ?? this.printLink,
        mainPrintType: mainPrintType ?? this.mainPrintType,
        mainPrintDetail: mainPrintDetail ?? this.mainPrintDetail,
        printImageInBill: printImageInBill ?? this.printImageInBill,
        printBranchNameInBill:
            printBranchNameInBill ?? this.printBranchNameInBill,
        dineInTableOrderCount:
            dineInTableOrderCount ?? this.dineInTableOrderCount,
        variation: variation ?? this.variation,
        qtyReducePassword: qtyReducePassword ?? this.qtyReducePassword,
        counterLoginLimit: counterLoginLimit ?? this.counterLoginLimit,
      );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      id: data.id.present ? data.id.value : this.id,
      currency: data.currency.present ? data.currency.value : this.currency,
      decimalPoint: data.decimalPoint.present
          ? data.decimalPoint.value
          : this.decimalPoint,
      dateFormat:
          data.dateFormat.present ? data.dateFormat.value : this.dateFormat,
      timeFormat:
          data.timeFormat.present ? data.timeFormat.value : this.timeFormat,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      stockCheck:
          data.stockCheck.present ? data.stockCheck.value : this.stockCheck,
      stockShow: data.stockShow.present ? data.stockShow.value : this.stockShow,
      settleCheckPending: data.settleCheckPending.present
          ? data.settleCheckPending.value
          : this.settleCheckPending,
      deliverySale: data.deliverySale.present
          ? data.deliverySale.value
          : this.deliverySale,
      apiKey: data.apiKey.present ? data.apiKey.value : this.apiKey,
      customProduct: data.customProduct.present
          ? data.customProduct.value
          : this.customProduct,
      language: data.language.present ? data.language.value : this.language,
      staffPin: data.staffPin.present ? data.staffPin.value : this.staffPin,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      drawerPassword: data.drawerPassword.present
          ? data.drawerPassword.value
          : this.drawerPassword,
      paybackPassword: data.paybackPassword.present
          ? data.paybackPassword.value
          : this.paybackPassword,
      purchase: data.purchase.present ? data.purchase.value : this.purchase,
      production:
          data.production.present ? data.production.value : this.production,
      minimumStock: data.minimumStock.present
          ? data.minimumStock.value
          : this.minimumStock,
      wastageUsage: data.wastageUsage.present
          ? data.wastageUsage.value
          : this.wastageUsage,
      wastageUsageZeroStock: data.wastageUsageZeroStock.present
          ? data.wastageUsageZeroStock.value
          : this.wastageUsageZeroStock,
      customizeItem: data.customizeItem.present
          ? data.customizeItem.value
          : this.customizeItem,
      printType: data.printType.present ? data.printType.value : this.printType,
      printLink: data.printLink.present ? data.printLink.value : this.printLink,
      mainPrintType: data.mainPrintType.present
          ? data.mainPrintType.value
          : this.mainPrintType,
      mainPrintDetail: data.mainPrintDetail.present
          ? data.mainPrintDetail.value
          : this.mainPrintDetail,
      printImageInBill: data.printImageInBill.present
          ? data.printImageInBill.value
          : this.printImageInBill,
      printBranchNameInBill: data.printBranchNameInBill.present
          ? data.printBranchNameInBill.value
          : this.printBranchNameInBill,
      dineInTableOrderCount: data.dineInTableOrderCount.present
          ? data.dineInTableOrderCount.value
          : this.dineInTableOrderCount,
      variation: data.variation.present ? data.variation.value : this.variation,
      qtyReducePassword: data.qtyReducePassword.present
          ? data.qtyReducePassword.value
          : this.qtyReducePassword,
      counterLoginLimit: data.counterLoginLimit.present
          ? data.counterLoginLimit.value
          : this.counterLoginLimit,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('id: $id, ')
          ..write('currency: $currency, ')
          ..write('decimalPoint: $decimalPoint, ')
          ..write('dateFormat: $dateFormat, ')
          ..write('timeFormat: $timeFormat, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('stockCheck: $stockCheck, ')
          ..write('stockShow: $stockShow, ')
          ..write('settleCheckPending: $settleCheckPending, ')
          ..write('deliverySale: $deliverySale, ')
          ..write('apiKey: $apiKey, ')
          ..write('customProduct: $customProduct, ')
          ..write('language: $language, ')
          ..write('staffPin: $staffPin, ')
          ..write('barcode: $barcode, ')
          ..write('drawerPassword: $drawerPassword, ')
          ..write('paybackPassword: $paybackPassword, ')
          ..write('purchase: $purchase, ')
          ..write('production: $production, ')
          ..write('minimumStock: $minimumStock, ')
          ..write('wastageUsage: $wastageUsage, ')
          ..write('wastageUsageZeroStock: $wastageUsageZeroStock, ')
          ..write('customizeItem: $customizeItem, ')
          ..write('printType: $printType, ')
          ..write('printLink: $printLink, ')
          ..write('mainPrintType: $mainPrintType, ')
          ..write('mainPrintDetail: $mainPrintDetail, ')
          ..write('printImageInBill: $printImageInBill, ')
          ..write('printBranchNameInBill: $printBranchNameInBill, ')
          ..write('dineInTableOrderCount: $dineInTableOrderCount, ')
          ..write('variation: $variation, ')
          ..write('qtyReducePassword: $qtyReducePassword, ')
          ..write('counterLoginLimit: $counterLoginLimit')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        currency,
        decimalPoint,
        dateFormat,
        timeFormat,
        unitPrice,
        stockCheck,
        stockShow,
        settleCheckPending,
        deliverySale,
        apiKey,
        customProduct,
        language,
        staffPin,
        barcode,
        drawerPassword,
        paybackPassword,
        purchase,
        production,
        minimumStock,
        wastageUsage,
        wastageUsageZeroStock,
        customizeItem,
        printType,
        printLink,
        mainPrintType,
        mainPrintDetail,
        printImageInBill,
        printBranchNameInBill,
        dineInTableOrderCount,
        variation,
        qtyReducePassword,
        counterLoginLimit
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting &&
          other.id == this.id &&
          other.currency == this.currency &&
          other.decimalPoint == this.decimalPoint &&
          other.dateFormat == this.dateFormat &&
          other.timeFormat == this.timeFormat &&
          other.unitPrice == this.unitPrice &&
          other.stockCheck == this.stockCheck &&
          other.stockShow == this.stockShow &&
          other.settleCheckPending == this.settleCheckPending &&
          other.deliverySale == this.deliverySale &&
          other.apiKey == this.apiKey &&
          other.customProduct == this.customProduct &&
          other.language == this.language &&
          other.staffPin == this.staffPin &&
          other.barcode == this.barcode &&
          other.drawerPassword == this.drawerPassword &&
          other.paybackPassword == this.paybackPassword &&
          other.purchase == this.purchase &&
          other.production == this.production &&
          other.minimumStock == this.minimumStock &&
          other.wastageUsage == this.wastageUsage &&
          other.wastageUsageZeroStock == this.wastageUsageZeroStock &&
          other.customizeItem == this.customizeItem &&
          other.printType == this.printType &&
          other.printLink == this.printLink &&
          other.mainPrintType == this.mainPrintType &&
          other.mainPrintDetail == this.mainPrintDetail &&
          other.printImageInBill == this.printImageInBill &&
          other.printBranchNameInBill == this.printBranchNameInBill &&
          other.dineInTableOrderCount == this.dineInTableOrderCount &&
          other.variation == this.variation &&
          other.qtyReducePassword == this.qtyReducePassword &&
          other.counterLoginLimit == this.counterLoginLimit);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<int> id;
  final Value<String> currency;
  final Value<String> decimalPoint;
  final Value<String> dateFormat;
  final Value<String> timeFormat;
  final Value<String> unitPrice;
  final Value<String> stockCheck;
  final Value<String> stockShow;
  final Value<String> settleCheckPending;
  final Value<String> deliverySale;
  final Value<String> apiKey;
  final Value<String> customProduct;
  final Value<String> language;
  final Value<String> staffPin;
  final Value<String> barcode;
  final Value<String> drawerPassword;
  final Value<String> paybackPassword;
  final Value<String> purchase;
  final Value<String> production;
  final Value<String> minimumStock;
  final Value<String> wastageUsage;
  final Value<String> wastageUsageZeroStock;
  final Value<String> customizeItem;
  final Value<String> printType;
  final Value<String> printLink;
  final Value<String> mainPrintType;
  final Value<String> mainPrintDetail;
  final Value<String> printImageInBill;
  final Value<String> printBranchNameInBill;
  final Value<String> dineInTableOrderCount;
  final Value<String> variation;
  final Value<String> qtyReducePassword;
  final Value<String> counterLoginLimit;
  const SettingsCompanion({
    this.id = const Value.absent(),
    this.currency = const Value.absent(),
    this.decimalPoint = const Value.absent(),
    this.dateFormat = const Value.absent(),
    this.timeFormat = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.stockCheck = const Value.absent(),
    this.stockShow = const Value.absent(),
    this.settleCheckPending = const Value.absent(),
    this.deliverySale = const Value.absent(),
    this.apiKey = const Value.absent(),
    this.customProduct = const Value.absent(),
    this.language = const Value.absent(),
    this.staffPin = const Value.absent(),
    this.barcode = const Value.absent(),
    this.drawerPassword = const Value.absent(),
    this.paybackPassword = const Value.absent(),
    this.purchase = const Value.absent(),
    this.production = const Value.absent(),
    this.minimumStock = const Value.absent(),
    this.wastageUsage = const Value.absent(),
    this.wastageUsageZeroStock = const Value.absent(),
    this.customizeItem = const Value.absent(),
    this.printType = const Value.absent(),
    this.printLink = const Value.absent(),
    this.mainPrintType = const Value.absent(),
    this.mainPrintDetail = const Value.absent(),
    this.printImageInBill = const Value.absent(),
    this.printBranchNameInBill = const Value.absent(),
    this.dineInTableOrderCount = const Value.absent(),
    this.variation = const Value.absent(),
    this.qtyReducePassword = const Value.absent(),
    this.counterLoginLimit = const Value.absent(),
  });
  SettingsCompanion.insert({
    this.id = const Value.absent(),
    required String currency,
    required String decimalPoint,
    required String dateFormat,
    required String timeFormat,
    required String unitPrice,
    required String stockCheck,
    required String stockShow,
    required String settleCheckPending,
    required String deliverySale,
    required String apiKey,
    required String customProduct,
    required String language,
    required String staffPin,
    required String barcode,
    required String drawerPassword,
    required String paybackPassword,
    required String purchase,
    required String production,
    required String minimumStock,
    required String wastageUsage,
    required String wastageUsageZeroStock,
    required String customizeItem,
    required String printType,
    required String printLink,
    required String mainPrintType,
    required String mainPrintDetail,
    required String printImageInBill,
    required String printBranchNameInBill,
    required String dineInTableOrderCount,
    required String variation,
    required String qtyReducePassword,
    required String counterLoginLimit,
  })  : currency = Value(currency),
        decimalPoint = Value(decimalPoint),
        dateFormat = Value(dateFormat),
        timeFormat = Value(timeFormat),
        unitPrice = Value(unitPrice),
        stockCheck = Value(stockCheck),
        stockShow = Value(stockShow),
        settleCheckPending = Value(settleCheckPending),
        deliverySale = Value(deliverySale),
        apiKey = Value(apiKey),
        customProduct = Value(customProduct),
        language = Value(language),
        staffPin = Value(staffPin),
        barcode = Value(barcode),
        drawerPassword = Value(drawerPassword),
        paybackPassword = Value(paybackPassword),
        purchase = Value(purchase),
        production = Value(production),
        minimumStock = Value(minimumStock),
        wastageUsage = Value(wastageUsage),
        wastageUsageZeroStock = Value(wastageUsageZeroStock),
        customizeItem = Value(customizeItem),
        printType = Value(printType),
        printLink = Value(printLink),
        mainPrintType = Value(mainPrintType),
        mainPrintDetail = Value(mainPrintDetail),
        printImageInBill = Value(printImageInBill),
        printBranchNameInBill = Value(printBranchNameInBill),
        dineInTableOrderCount = Value(dineInTableOrderCount),
        variation = Value(variation),
        qtyReducePassword = Value(qtyReducePassword),
        counterLoginLimit = Value(counterLoginLimit);
  static Insertable<Setting> custom({
    Expression<int>? id,
    Expression<String>? currency,
    Expression<String>? decimalPoint,
    Expression<String>? dateFormat,
    Expression<String>? timeFormat,
    Expression<String>? unitPrice,
    Expression<String>? stockCheck,
    Expression<String>? stockShow,
    Expression<String>? settleCheckPending,
    Expression<String>? deliverySale,
    Expression<String>? apiKey,
    Expression<String>? customProduct,
    Expression<String>? language,
    Expression<String>? staffPin,
    Expression<String>? barcode,
    Expression<String>? drawerPassword,
    Expression<String>? paybackPassword,
    Expression<String>? purchase,
    Expression<String>? production,
    Expression<String>? minimumStock,
    Expression<String>? wastageUsage,
    Expression<String>? wastageUsageZeroStock,
    Expression<String>? customizeItem,
    Expression<String>? printType,
    Expression<String>? printLink,
    Expression<String>? mainPrintType,
    Expression<String>? mainPrintDetail,
    Expression<String>? printImageInBill,
    Expression<String>? printBranchNameInBill,
    Expression<String>? dineInTableOrderCount,
    Expression<String>? variation,
    Expression<String>? qtyReducePassword,
    Expression<String>? counterLoginLimit,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (currency != null) 'currency': currency,
      if (decimalPoint != null) 'decimal_point': decimalPoint,
      if (dateFormat != null) 'date_format': dateFormat,
      if (timeFormat != null) 'time_format': timeFormat,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (stockCheck != null) 'stock_check': stockCheck,
      if (stockShow != null) 'stock_show': stockShow,
      if (settleCheckPending != null)
        'settle_check_pending': settleCheckPending,
      if (deliverySale != null) 'delivery_sale': deliverySale,
      if (apiKey != null) 'api_key': apiKey,
      if (customProduct != null) 'custom_product': customProduct,
      if (language != null) 'language': language,
      if (staffPin != null) 'staff_pin': staffPin,
      if (barcode != null) 'barcode': barcode,
      if (drawerPassword != null) 'drawer_password': drawerPassword,
      if (paybackPassword != null) 'payback_password': paybackPassword,
      if (purchase != null) 'purchase': purchase,
      if (production != null) 'production': production,
      if (minimumStock != null) 'minimum_stock': minimumStock,
      if (wastageUsage != null) 'wastage_usage': wastageUsage,
      if (wastageUsageZeroStock != null)
        'wastage_usage_zero_stock': wastageUsageZeroStock,
      if (customizeItem != null) 'customize_item': customizeItem,
      if (printType != null) 'print_type': printType,
      if (printLink != null) 'print_link': printLink,
      if (mainPrintType != null) 'main_print_type': mainPrintType,
      if (mainPrintDetail != null) 'main_print_detail': mainPrintDetail,
      if (printImageInBill != null) 'print_image_in_bill': printImageInBill,
      if (printBranchNameInBill != null)
        'print_branch_name_in_bill': printBranchNameInBill,
      if (dineInTableOrderCount != null)
        'dine_in_table_order_count': dineInTableOrderCount,
      if (variation != null) 'variation': variation,
      if (qtyReducePassword != null) 'qty_reduce_password': qtyReducePassword,
      if (counterLoginLimit != null) 'counter_login_limit': counterLoginLimit,
    });
  }

  SettingsCompanion copyWith(
      {Value<int>? id,
      Value<String>? currency,
      Value<String>? decimalPoint,
      Value<String>? dateFormat,
      Value<String>? timeFormat,
      Value<String>? unitPrice,
      Value<String>? stockCheck,
      Value<String>? stockShow,
      Value<String>? settleCheckPending,
      Value<String>? deliverySale,
      Value<String>? apiKey,
      Value<String>? customProduct,
      Value<String>? language,
      Value<String>? staffPin,
      Value<String>? barcode,
      Value<String>? drawerPassword,
      Value<String>? paybackPassword,
      Value<String>? purchase,
      Value<String>? production,
      Value<String>? minimumStock,
      Value<String>? wastageUsage,
      Value<String>? wastageUsageZeroStock,
      Value<String>? customizeItem,
      Value<String>? printType,
      Value<String>? printLink,
      Value<String>? mainPrintType,
      Value<String>? mainPrintDetail,
      Value<String>? printImageInBill,
      Value<String>? printBranchNameInBill,
      Value<String>? dineInTableOrderCount,
      Value<String>? variation,
      Value<String>? qtyReducePassword,
      Value<String>? counterLoginLimit}) {
    return SettingsCompanion(
      id: id ?? this.id,
      currency: currency ?? this.currency,
      decimalPoint: decimalPoint ?? this.decimalPoint,
      dateFormat: dateFormat ?? this.dateFormat,
      timeFormat: timeFormat ?? this.timeFormat,
      unitPrice: unitPrice ?? this.unitPrice,
      stockCheck: stockCheck ?? this.stockCheck,
      stockShow: stockShow ?? this.stockShow,
      settleCheckPending: settleCheckPending ?? this.settleCheckPending,
      deliverySale: deliverySale ?? this.deliverySale,
      apiKey: apiKey ?? this.apiKey,
      customProduct: customProduct ?? this.customProduct,
      language: language ?? this.language,
      staffPin: staffPin ?? this.staffPin,
      barcode: barcode ?? this.barcode,
      drawerPassword: drawerPassword ?? this.drawerPassword,
      paybackPassword: paybackPassword ?? this.paybackPassword,
      purchase: purchase ?? this.purchase,
      production: production ?? this.production,
      minimumStock: minimumStock ?? this.minimumStock,
      wastageUsage: wastageUsage ?? this.wastageUsage,
      wastageUsageZeroStock:
          wastageUsageZeroStock ?? this.wastageUsageZeroStock,
      customizeItem: customizeItem ?? this.customizeItem,
      printType: printType ?? this.printType,
      printLink: printLink ?? this.printLink,
      mainPrintType: mainPrintType ?? this.mainPrintType,
      mainPrintDetail: mainPrintDetail ?? this.mainPrintDetail,
      printImageInBill: printImageInBill ?? this.printImageInBill,
      printBranchNameInBill:
          printBranchNameInBill ?? this.printBranchNameInBill,
      dineInTableOrderCount:
          dineInTableOrderCount ?? this.dineInTableOrderCount,
      variation: variation ?? this.variation,
      qtyReducePassword: qtyReducePassword ?? this.qtyReducePassword,
      counterLoginLimit: counterLoginLimit ?? this.counterLoginLimit,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (decimalPoint.present) {
      map['decimal_point'] = Variable<String>(decimalPoint.value);
    }
    if (dateFormat.present) {
      map['date_format'] = Variable<String>(dateFormat.value);
    }
    if (timeFormat.present) {
      map['time_format'] = Variable<String>(timeFormat.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<String>(unitPrice.value);
    }
    if (stockCheck.present) {
      map['stock_check'] = Variable<String>(stockCheck.value);
    }
    if (stockShow.present) {
      map['stock_show'] = Variable<String>(stockShow.value);
    }
    if (settleCheckPending.present) {
      map['settle_check_pending'] = Variable<String>(settleCheckPending.value);
    }
    if (deliverySale.present) {
      map['delivery_sale'] = Variable<String>(deliverySale.value);
    }
    if (apiKey.present) {
      map['api_key'] = Variable<String>(apiKey.value);
    }
    if (customProduct.present) {
      map['custom_product'] = Variable<String>(customProduct.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (staffPin.present) {
      map['staff_pin'] = Variable<String>(staffPin.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (drawerPassword.present) {
      map['drawer_password'] = Variable<String>(drawerPassword.value);
    }
    if (paybackPassword.present) {
      map['payback_password'] = Variable<String>(paybackPassword.value);
    }
    if (purchase.present) {
      map['purchase'] = Variable<String>(purchase.value);
    }
    if (production.present) {
      map['production'] = Variable<String>(production.value);
    }
    if (minimumStock.present) {
      map['minimum_stock'] = Variable<String>(minimumStock.value);
    }
    if (wastageUsage.present) {
      map['wastage_usage'] = Variable<String>(wastageUsage.value);
    }
    if (wastageUsageZeroStock.present) {
      map['wastage_usage_zero_stock'] =
          Variable<String>(wastageUsageZeroStock.value);
    }
    if (customizeItem.present) {
      map['customize_item'] = Variable<String>(customizeItem.value);
    }
    if (printType.present) {
      map['print_type'] = Variable<String>(printType.value);
    }
    if (printLink.present) {
      map['print_link'] = Variable<String>(printLink.value);
    }
    if (mainPrintType.present) {
      map['main_print_type'] = Variable<String>(mainPrintType.value);
    }
    if (mainPrintDetail.present) {
      map['main_print_detail'] = Variable<String>(mainPrintDetail.value);
    }
    if (printImageInBill.present) {
      map['print_image_in_bill'] = Variable<String>(printImageInBill.value);
    }
    if (printBranchNameInBill.present) {
      map['print_branch_name_in_bill'] =
          Variable<String>(printBranchNameInBill.value);
    }
    if (dineInTableOrderCount.present) {
      map['dine_in_table_order_count'] =
          Variable<String>(dineInTableOrderCount.value);
    }
    if (variation.present) {
      map['variation'] = Variable<String>(variation.value);
    }
    if (qtyReducePassword.present) {
      map['qty_reduce_password'] = Variable<String>(qtyReducePassword.value);
    }
    if (counterLoginLimit.present) {
      map['counter_login_limit'] = Variable<String>(counterLoginLimit.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('id: $id, ')
          ..write('currency: $currency, ')
          ..write('decimalPoint: $decimalPoint, ')
          ..write('dateFormat: $dateFormat, ')
          ..write('timeFormat: $timeFormat, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('stockCheck: $stockCheck, ')
          ..write('stockShow: $stockShow, ')
          ..write('settleCheckPending: $settleCheckPending, ')
          ..write('deliverySale: $deliverySale, ')
          ..write('apiKey: $apiKey, ')
          ..write('customProduct: $customProduct, ')
          ..write('language: $language, ')
          ..write('staffPin: $staffPin, ')
          ..write('barcode: $barcode, ')
          ..write('drawerPassword: $drawerPassword, ')
          ..write('paybackPassword: $paybackPassword, ')
          ..write('purchase: $purchase, ')
          ..write('production: $production, ')
          ..write('minimumStock: $minimumStock, ')
          ..write('wastageUsage: $wastageUsage, ')
          ..write('wastageUsageZeroStock: $wastageUsageZeroStock, ')
          ..write('customizeItem: $customizeItem, ')
          ..write('printType: $printType, ')
          ..write('printLink: $printLink, ')
          ..write('mainPrintType: $mainPrintType, ')
          ..write('mainPrintDetail: $mainPrintDetail, ')
          ..write('printImageInBill: $printImageInBill, ')
          ..write('printBranchNameInBill: $printBranchNameInBill, ')
          ..write('dineInTableOrderCount: $dineInTableOrderCount, ')
          ..write('variation: $variation, ')
          ..write('qtyReducePassword: $qtyReducePassword, ')
          ..write('counterLoginLimit: $counterLoginLimit')
          ..write(')'))
        .toString();
  }
}

class $PullCategoryRowsTable extends PullCategoryRows
    with TableInfo<$PullCategoryRowsTable, PullCategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PullCategoryRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _resourceKeyMeta =
      const VerificationMeta('resourceKey');
  @override
  late final GeneratedColumn<String> resourceKey = GeneratedColumn<String>(
      'resource_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
      'uuid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _branchIdMeta =
      const VerificationMeta('branchId');
  @override
  late final GeneratedColumn<int> branchId = GeneratedColumn<int>(
      'branch_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _categoryNameMeta =
      const VerificationMeta('categoryName');
  @override
  late final GeneratedColumn<String> categoryName = GeneratedColumn<String>(
      'category_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categorySlugMeta =
      const VerificationMeta('categorySlug');
  @override
  late final GeneratedColumn<String> categorySlug = GeneratedColumn<String>(
      'category_slug', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _otherNameMeta =
      const VerificationMeta('otherName');
  @override
  late final GeneratedColumn<String> otherName = GeneratedColumn<String>(
      'other_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        resourceKey,
        id,
        uuid,
        branchId,
        categoryName,
        categorySlug,
        otherName,
        createdAt,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pull_category_rows';
  @override
  VerificationContext validateIntegrity(Insertable<PullCategoryRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('resource_key')) {
      context.handle(
          _resourceKeyMeta,
          resourceKey.isAcceptableOrUnknown(
              data['resource_key']!, _resourceKeyMeta));
    } else if (isInserting) {
      context.missing(_resourceKeyMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('uuid')) {
      context.handle(
          _uuidMeta, uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta));
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(_branchIdMeta,
          branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta));
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('category_name')) {
      context.handle(
          _categoryNameMeta,
          categoryName.isAcceptableOrUnknown(
              data['category_name']!, _categoryNameMeta));
    } else if (isInserting) {
      context.missing(_categoryNameMeta);
    }
    if (data.containsKey('category_slug')) {
      context.handle(
          _categorySlugMeta,
          categorySlug.isAcceptableOrUnknown(
              data['category_slug']!, _categorySlugMeta));
    } else if (isInserting) {
      context.missing(_categorySlugMeta);
    }
    if (data.containsKey('other_name')) {
      context.handle(_otherNameMeta,
          otherName.isAcceptableOrUnknown(data['other_name']!, _otherNameMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {resourceKey, id};
  @override
  PullCategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PullCategoryRow(
      resourceKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}resource_key'])!,
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uuid'])!,
      branchId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}branch_id'])!,
      categoryName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_name'])!,
      categorySlug: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_slug'])!,
      otherName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}other_name']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $PullCategoryRowsTable createAlias(String alias) {
    return $PullCategoryRowsTable(attachedDatabase, alias);
  }
}

class PullCategoryRow extends DataClass implements Insertable<PullCategoryRow> {
  /// JSON key, e.g. `category`, `variations`, `driver`, `chairs`.
  final String resourceKey;
  final int id;
  final String uuid;
  final int branchId;
  final String categoryName;
  final String categorySlug;
  final String? otherName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const PullCategoryRow(
      {required this.resourceKey,
      required this.id,
      required this.uuid,
      required this.branchId,
      required this.categoryName,
      required this.categorySlug,
      this.otherName,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['resource_key'] = Variable<String>(resourceKey);
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['branch_id'] = Variable<int>(branchId);
    map['category_name'] = Variable<String>(categoryName);
    map['category_slug'] = Variable<String>(categorySlug);
    if (!nullToAbsent || otherName != null) {
      map['other_name'] = Variable<String>(otherName);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  PullCategoryRowsCompanion toCompanion(bool nullToAbsent) {
    return PullCategoryRowsCompanion(
      resourceKey: Value(resourceKey),
      id: Value(id),
      uuid: Value(uuid),
      branchId: Value(branchId),
      categoryName: Value(categoryName),
      categorySlug: Value(categorySlug),
      otherName: otherName == null && nullToAbsent
          ? const Value.absent()
          : Value(otherName),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory PullCategoryRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PullCategoryRow(
      resourceKey: serializer.fromJson<String>(json['resourceKey']),
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      branchId: serializer.fromJson<int>(json['branchId']),
      categoryName: serializer.fromJson<String>(json['categoryName']),
      categorySlug: serializer.fromJson<String>(json['categorySlug']),
      otherName: serializer.fromJson<String?>(json['otherName']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'resourceKey': serializer.toJson<String>(resourceKey),
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'branchId': serializer.toJson<int>(branchId),
      'categoryName': serializer.toJson<String>(categoryName),
      'categorySlug': serializer.toJson<String>(categorySlug),
      'otherName': serializer.toJson<String?>(otherName),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  PullCategoryRow copyWith(
          {String? resourceKey,
          int? id,
          String? uuid,
          int? branchId,
          String? categoryName,
          String? categorySlug,
          Value<String?> otherName = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      PullCategoryRow(
        resourceKey: resourceKey ?? this.resourceKey,
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        branchId: branchId ?? this.branchId,
        categoryName: categoryName ?? this.categoryName,
        categorySlug: categorySlug ?? this.categorySlug,
        otherName: otherName.present ? otherName.value : this.otherName,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  PullCategoryRow copyWithCompanion(PullCategoryRowsCompanion data) {
    return PullCategoryRow(
      resourceKey:
          data.resourceKey.present ? data.resourceKey.value : this.resourceKey,
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      categoryName: data.categoryName.present
          ? data.categoryName.value
          : this.categoryName,
      categorySlug: data.categorySlug.present
          ? data.categorySlug.value
          : this.categorySlug,
      otherName: data.otherName.present ? data.otherName.value : this.otherName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PullCategoryRow(')
          ..write('resourceKey: $resourceKey, ')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('branchId: $branchId, ')
          ..write('categoryName: $categoryName, ')
          ..write('categorySlug: $categorySlug, ')
          ..write('otherName: $otherName, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(resourceKey, id, uuid, branchId, categoryName,
      categorySlug, otherName, createdAt, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PullCategoryRow &&
          other.resourceKey == this.resourceKey &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.branchId == this.branchId &&
          other.categoryName == this.categoryName &&
          other.categorySlug == this.categorySlug &&
          other.otherName == this.otherName &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class PullCategoryRowsCompanion extends UpdateCompanion<PullCategoryRow> {
  final Value<String> resourceKey;
  final Value<int> id;
  final Value<String> uuid;
  final Value<int> branchId;
  final Value<String> categoryName;
  final Value<String> categorySlug;
  final Value<String?> otherName;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const PullCategoryRowsCompanion({
    this.resourceKey = const Value.absent(),
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.branchId = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.categorySlug = const Value.absent(),
    this.otherName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PullCategoryRowsCompanion.insert({
    required String resourceKey,
    required int id,
    required String uuid,
    required int branchId,
    required String categoryName,
    required String categorySlug,
    this.otherName = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : resourceKey = Value(resourceKey),
        id = Value(id),
        uuid = Value(uuid),
        branchId = Value(branchId),
        categoryName = Value(categoryName),
        categorySlug = Value(categorySlug),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<PullCategoryRow> custom({
    Expression<String>? resourceKey,
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<int>? branchId,
    Expression<String>? categoryName,
    Expression<String>? categorySlug,
    Expression<String>? otherName,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (resourceKey != null) 'resource_key': resourceKey,
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (branchId != null) 'branch_id': branchId,
      if (categoryName != null) 'category_name': categoryName,
      if (categorySlug != null) 'category_slug': categorySlug,
      if (otherName != null) 'other_name': otherName,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PullCategoryRowsCompanion copyWith(
      {Value<String>? resourceKey,
      Value<int>? id,
      Value<String>? uuid,
      Value<int>? branchId,
      Value<String>? categoryName,
      Value<String>? categorySlug,
      Value<String?>? otherName,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<int>? rowid}) {
    return PullCategoryRowsCompanion(
      resourceKey: resourceKey ?? this.resourceKey,
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      branchId: branchId ?? this.branchId,
      categoryName: categoryName ?? this.categoryName,
      categorySlug: categorySlug ?? this.categorySlug,
      otherName: otherName ?? this.otherName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (resourceKey.present) {
      map['resource_key'] = Variable<String>(resourceKey.value);
    }
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<int>(branchId.value);
    }
    if (categoryName.present) {
      map['category_name'] = Variable<String>(categoryName.value);
    }
    if (categorySlug.present) {
      map['category_slug'] = Variable<String>(categorySlug.value);
    }
    if (otherName.present) {
      map['other_name'] = Variable<String>(otherName.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PullCategoryRowsCompanion(')
          ..write('resourceKey: $resourceKey, ')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('branchId: $branchId, ')
          ..write('categoryName: $categoryName, ')
          ..write('categorySlug: $categorySlug, ')
          ..write('otherName: $otherName, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PullFloorRowsTable extends PullFloorRows
    with TableInfo<$PullFloorRowsTable, PullFloorRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PullFloorRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _resourceKeyMeta =
      const VerificationMeta('resourceKey');
  @override
  late final GeneratedColumn<String> resourceKey = GeneratedColumn<String>(
      'resource_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
      'uuid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _branchIdMeta =
      const VerificationMeta('branchId');
  @override
  late final GeneratedColumn<int> branchId = GeneratedColumn<int>(
      'branch_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _floorNameMeta =
      const VerificationMeta('floorName');
  @override
  late final GeneratedColumn<String> floorName = GeneratedColumn<String>(
      'floor_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _floorSlugMeta =
      const VerificationMeta('floorSlug');
  @override
  late final GeneratedColumn<String> floorSlug = GeneratedColumn<String>(
      'floor_slug', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _paymentMethodNameMeta =
      const VerificationMeta('paymentMethodName');
  @override
  late final GeneratedColumn<String> paymentMethodName =
      GeneratedColumn<String>('payment_method_name', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _paymentMethodSlugMeta =
      const VerificationMeta('paymentMethodSlug');
  @override
  late final GeneratedColumn<String> paymentMethodSlug =
      GeneratedColumn<String>('payment_method_slug', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _unitNameMeta =
      const VerificationMeta('unitName');
  @override
  late final GeneratedColumn<String> unitName = GeneratedColumn<String>(
      'unit_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _unitSlugMeta =
      const VerificationMeta('unitSlug');
  @override
  late final GeneratedColumn<String> unitSlug = GeneratedColumn<String>(
      'unit_slug', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        resourceKey,
        id,
        uuid,
        branchId,
        floorName,
        floorSlug,
        createdAt,
        updatedAt,
        deletedAt,
        paymentMethodName,
        paymentMethodSlug,
        unitName,
        unitSlug
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pull_floor_rows';
  @override
  VerificationContext validateIntegrity(Insertable<PullFloorRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('resource_key')) {
      context.handle(
          _resourceKeyMeta,
          resourceKey.isAcceptableOrUnknown(
              data['resource_key']!, _resourceKeyMeta));
    } else if (isInserting) {
      context.missing(_resourceKeyMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('uuid')) {
      context.handle(
          _uuidMeta, uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta));
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(_branchIdMeta,
          branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta));
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('floor_name')) {
      context.handle(_floorNameMeta,
          floorName.isAcceptableOrUnknown(data['floor_name']!, _floorNameMeta));
    }
    if (data.containsKey('floor_slug')) {
      context.handle(_floorSlugMeta,
          floorSlug.isAcceptableOrUnknown(data['floor_slug']!, _floorSlugMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('payment_method_name')) {
      context.handle(
          _paymentMethodNameMeta,
          paymentMethodName.isAcceptableOrUnknown(
              data['payment_method_name']!, _paymentMethodNameMeta));
    }
    if (data.containsKey('payment_method_slug')) {
      context.handle(
          _paymentMethodSlugMeta,
          paymentMethodSlug.isAcceptableOrUnknown(
              data['payment_method_slug']!, _paymentMethodSlugMeta));
    }
    if (data.containsKey('unit_name')) {
      context.handle(_unitNameMeta,
          unitName.isAcceptableOrUnknown(data['unit_name']!, _unitNameMeta));
    }
    if (data.containsKey('unit_slug')) {
      context.handle(_unitSlugMeta,
          unitSlug.isAcceptableOrUnknown(data['unit_slug']!, _unitSlugMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {resourceKey, id};
  @override
  PullFloorRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PullFloorRow(
      resourceKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}resource_key'])!,
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uuid'])!,
      branchId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}branch_id'])!,
      floorName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}floor_name']),
      floorSlug: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}floor_slug']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      paymentMethodName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}payment_method_name']),
      paymentMethodSlug: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}payment_method_slug']),
      unitName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit_name']),
      unitSlug: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit_slug']),
    );
  }

  @override
  $PullFloorRowsTable createAlias(String alias) {
    return $PullFloorRowsTable(attachedDatabase, alias);
  }
}

class PullFloorRow extends DataClass implements Insertable<PullFloorRow> {
  final String resourceKey;
  final int id;
  final String uuid;
  final int branchId;
  final String? floorName;
  final String? floorSlug;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? paymentMethodName;
  final String? paymentMethodSlug;
  final String? unitName;
  final String? unitSlug;
  const PullFloorRow(
      {required this.resourceKey,
      required this.id,
      required this.uuid,
      required this.branchId,
      this.floorName,
      this.floorSlug,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      this.paymentMethodName,
      this.paymentMethodSlug,
      this.unitName,
      this.unitSlug});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['resource_key'] = Variable<String>(resourceKey);
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['branch_id'] = Variable<int>(branchId);
    if (!nullToAbsent || floorName != null) {
      map['floor_name'] = Variable<String>(floorName);
    }
    if (!nullToAbsent || floorSlug != null) {
      map['floor_slug'] = Variable<String>(floorSlug);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || paymentMethodName != null) {
      map['payment_method_name'] = Variable<String>(paymentMethodName);
    }
    if (!nullToAbsent || paymentMethodSlug != null) {
      map['payment_method_slug'] = Variable<String>(paymentMethodSlug);
    }
    if (!nullToAbsent || unitName != null) {
      map['unit_name'] = Variable<String>(unitName);
    }
    if (!nullToAbsent || unitSlug != null) {
      map['unit_slug'] = Variable<String>(unitSlug);
    }
    return map;
  }

  PullFloorRowsCompanion toCompanion(bool nullToAbsent) {
    return PullFloorRowsCompanion(
      resourceKey: Value(resourceKey),
      id: Value(id),
      uuid: Value(uuid),
      branchId: Value(branchId),
      floorName: floorName == null && nullToAbsent
          ? const Value.absent()
          : Value(floorName),
      floorSlug: floorSlug == null && nullToAbsent
          ? const Value.absent()
          : Value(floorSlug),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      paymentMethodName: paymentMethodName == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentMethodName),
      paymentMethodSlug: paymentMethodSlug == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentMethodSlug),
      unitName: unitName == null && nullToAbsent
          ? const Value.absent()
          : Value(unitName),
      unitSlug: unitSlug == null && nullToAbsent
          ? const Value.absent()
          : Value(unitSlug),
    );
  }

  factory PullFloorRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PullFloorRow(
      resourceKey: serializer.fromJson<String>(json['resourceKey']),
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      branchId: serializer.fromJson<int>(json['branchId']),
      floorName: serializer.fromJson<String?>(json['floorName']),
      floorSlug: serializer.fromJson<String?>(json['floorSlug']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      paymentMethodName:
          serializer.fromJson<String?>(json['paymentMethodName']),
      paymentMethodSlug:
          serializer.fromJson<String?>(json['paymentMethodSlug']),
      unitName: serializer.fromJson<String?>(json['unitName']),
      unitSlug: serializer.fromJson<String?>(json['unitSlug']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'resourceKey': serializer.toJson<String>(resourceKey),
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'branchId': serializer.toJson<int>(branchId),
      'floorName': serializer.toJson<String?>(floorName),
      'floorSlug': serializer.toJson<String?>(floorSlug),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'paymentMethodName': serializer.toJson<String?>(paymentMethodName),
      'paymentMethodSlug': serializer.toJson<String?>(paymentMethodSlug),
      'unitName': serializer.toJson<String?>(unitName),
      'unitSlug': serializer.toJson<String?>(unitSlug),
    };
  }

  PullFloorRow copyWith(
          {String? resourceKey,
          int? id,
          String? uuid,
          int? branchId,
          Value<String?> floorName = const Value.absent(),
          Value<String?> floorSlug = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          Value<String?> paymentMethodName = const Value.absent(),
          Value<String?> paymentMethodSlug = const Value.absent(),
          Value<String?> unitName = const Value.absent(),
          Value<String?> unitSlug = const Value.absent()}) =>
      PullFloorRow(
        resourceKey: resourceKey ?? this.resourceKey,
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        branchId: branchId ?? this.branchId,
        floorName: floorName.present ? floorName.value : this.floorName,
        floorSlug: floorSlug.present ? floorSlug.value : this.floorSlug,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        paymentMethodName: paymentMethodName.present
            ? paymentMethodName.value
            : this.paymentMethodName,
        paymentMethodSlug: paymentMethodSlug.present
            ? paymentMethodSlug.value
            : this.paymentMethodSlug,
        unitName: unitName.present ? unitName.value : this.unitName,
        unitSlug: unitSlug.present ? unitSlug.value : this.unitSlug,
      );
  PullFloorRow copyWithCompanion(PullFloorRowsCompanion data) {
    return PullFloorRow(
      resourceKey:
          data.resourceKey.present ? data.resourceKey.value : this.resourceKey,
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      floorName: data.floorName.present ? data.floorName.value : this.floorName,
      floorSlug: data.floorSlug.present ? data.floorSlug.value : this.floorSlug,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      paymentMethodName: data.paymentMethodName.present
          ? data.paymentMethodName.value
          : this.paymentMethodName,
      paymentMethodSlug: data.paymentMethodSlug.present
          ? data.paymentMethodSlug.value
          : this.paymentMethodSlug,
      unitName: data.unitName.present ? data.unitName.value : this.unitName,
      unitSlug: data.unitSlug.present ? data.unitSlug.value : this.unitSlug,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PullFloorRow(')
          ..write('resourceKey: $resourceKey, ')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('branchId: $branchId, ')
          ..write('floorName: $floorName, ')
          ..write('floorSlug: $floorSlug, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('paymentMethodName: $paymentMethodName, ')
          ..write('paymentMethodSlug: $paymentMethodSlug, ')
          ..write('unitName: $unitName, ')
          ..write('unitSlug: $unitSlug')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      resourceKey,
      id,
      uuid,
      branchId,
      floorName,
      floorSlug,
      createdAt,
      updatedAt,
      deletedAt,
      paymentMethodName,
      paymentMethodSlug,
      unitName,
      unitSlug);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PullFloorRow &&
          other.resourceKey == this.resourceKey &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.branchId == this.branchId &&
          other.floorName == this.floorName &&
          other.floorSlug == this.floorSlug &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.paymentMethodName == this.paymentMethodName &&
          other.paymentMethodSlug == this.paymentMethodSlug &&
          other.unitName == this.unitName &&
          other.unitSlug == this.unitSlug);
}

class PullFloorRowsCompanion extends UpdateCompanion<PullFloorRow> {
  final Value<String> resourceKey;
  final Value<int> id;
  final Value<String> uuid;
  final Value<int> branchId;
  final Value<String?> floorName;
  final Value<String?> floorSlug;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> paymentMethodName;
  final Value<String?> paymentMethodSlug;
  final Value<String?> unitName;
  final Value<String?> unitSlug;
  final Value<int> rowid;
  const PullFloorRowsCompanion({
    this.resourceKey = const Value.absent(),
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.branchId = const Value.absent(),
    this.floorName = const Value.absent(),
    this.floorSlug = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.paymentMethodName = const Value.absent(),
    this.paymentMethodSlug = const Value.absent(),
    this.unitName = const Value.absent(),
    this.unitSlug = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PullFloorRowsCompanion.insert({
    required String resourceKey,
    required int id,
    required String uuid,
    required int branchId,
    this.floorName = const Value.absent(),
    this.floorSlug = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.paymentMethodName = const Value.absent(),
    this.paymentMethodSlug = const Value.absent(),
    this.unitName = const Value.absent(),
    this.unitSlug = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : resourceKey = Value(resourceKey),
        id = Value(id),
        uuid = Value(uuid),
        branchId = Value(branchId),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<PullFloorRow> custom({
    Expression<String>? resourceKey,
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<int>? branchId,
    Expression<String>? floorName,
    Expression<String>? floorSlug,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? paymentMethodName,
    Expression<String>? paymentMethodSlug,
    Expression<String>? unitName,
    Expression<String>? unitSlug,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (resourceKey != null) 'resource_key': resourceKey,
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (branchId != null) 'branch_id': branchId,
      if (floorName != null) 'floor_name': floorName,
      if (floorSlug != null) 'floor_slug': floorSlug,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (paymentMethodName != null) 'payment_method_name': paymentMethodName,
      if (paymentMethodSlug != null) 'payment_method_slug': paymentMethodSlug,
      if (unitName != null) 'unit_name': unitName,
      if (unitSlug != null) 'unit_slug': unitSlug,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PullFloorRowsCompanion copyWith(
      {Value<String>? resourceKey,
      Value<int>? id,
      Value<String>? uuid,
      Value<int>? branchId,
      Value<String?>? floorName,
      Value<String?>? floorSlug,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String?>? paymentMethodName,
      Value<String?>? paymentMethodSlug,
      Value<String?>? unitName,
      Value<String?>? unitSlug,
      Value<int>? rowid}) {
    return PullFloorRowsCompanion(
      resourceKey: resourceKey ?? this.resourceKey,
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      branchId: branchId ?? this.branchId,
      floorName: floorName ?? this.floorName,
      floorSlug: floorSlug ?? this.floorSlug,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      paymentMethodName: paymentMethodName ?? this.paymentMethodName,
      paymentMethodSlug: paymentMethodSlug ?? this.paymentMethodSlug,
      unitName: unitName ?? this.unitName,
      unitSlug: unitSlug ?? this.unitSlug,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (resourceKey.present) {
      map['resource_key'] = Variable<String>(resourceKey.value);
    }
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<int>(branchId.value);
    }
    if (floorName.present) {
      map['floor_name'] = Variable<String>(floorName.value);
    }
    if (floorSlug.present) {
      map['floor_slug'] = Variable<String>(floorSlug.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (paymentMethodName.present) {
      map['payment_method_name'] = Variable<String>(paymentMethodName.value);
    }
    if (paymentMethodSlug.present) {
      map['payment_method_slug'] = Variable<String>(paymentMethodSlug.value);
    }
    if (unitName.present) {
      map['unit_name'] = Variable<String>(unitName.value);
    }
    if (unitSlug.present) {
      map['unit_slug'] = Variable<String>(unitSlug.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PullFloorRowsCompanion(')
          ..write('resourceKey: $resourceKey, ')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('branchId: $branchId, ')
          ..write('floorName: $floorName, ')
          ..write('floorSlug: $floorSlug, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('paymentMethodName: $paymentMethodName, ')
          ..write('paymentMethodSlug: $paymentMethodSlug, ')
          ..write('unitName: $unitName, ')
          ..write('unitSlug: $unitSlug, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PullDeliveryServiceRowsTable extends PullDeliveryServiceRows
    with TableInfo<$PullDeliveryServiceRowsTable, PullDeliveryServiceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PullDeliveryServiceRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
      'uuid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _branchIdMeta =
      const VerificationMeta('branchId');
  @override
  late final GeneratedColumn<int> branchId = GeneratedColumn<int>(
      'branch_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _serviceNameMeta =
      const VerificationMeta('serviceName');
  @override
  late final GeneratedColumn<String> serviceName = GeneratedColumn<String>(
      'service_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _serviceNameSlugMeta =
      const VerificationMeta('serviceNameSlug');
  @override
  late final GeneratedColumn<String> serviceNameSlug = GeneratedColumn<String>(
      'service_name_slug', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _driverStatusMeta =
      const VerificationMeta('driverStatus');
  @override
  late final GeneratedColumn<String> driverStatus = GeneratedColumn<String>(
      'driver_status', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        uuid,
        branchId,
        serviceName,
        serviceNameSlug,
        driverStatus,
        createdAt,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pull_delivery_service_rows';
  @override
  VerificationContext validateIntegrity(
      Insertable<PullDeliveryServiceRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
          _uuidMeta, uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta));
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(_branchIdMeta,
          branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta));
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('service_name')) {
      context.handle(
          _serviceNameMeta,
          serviceName.isAcceptableOrUnknown(
              data['service_name']!, _serviceNameMeta));
    } else if (isInserting) {
      context.missing(_serviceNameMeta);
    }
    if (data.containsKey('service_name_slug')) {
      context.handle(
          _serviceNameSlugMeta,
          serviceNameSlug.isAcceptableOrUnknown(
              data['service_name_slug']!, _serviceNameSlugMeta));
    } else if (isInserting) {
      context.missing(_serviceNameSlugMeta);
    }
    if (data.containsKey('driver_status')) {
      context.handle(
          _driverStatusMeta,
          driverStatus.isAcceptableOrUnknown(
              data['driver_status']!, _driverStatusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PullDeliveryServiceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PullDeliveryServiceRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uuid'])!,
      branchId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}branch_id'])!,
      serviceName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}service_name'])!,
      serviceNameSlug: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}service_name_slug'])!,
      driverStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}driver_status']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $PullDeliveryServiceRowsTable createAlias(String alias) {
    return $PullDeliveryServiceRowsTable(attachedDatabase, alias);
  }
}

class PullDeliveryServiceRow extends DataClass
    implements Insertable<PullDeliveryServiceRow> {
  final int id;
  final String uuid;
  final int branchId;
  final String serviceName;
  final String serviceNameSlug;
  final String? driverStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const PullDeliveryServiceRow(
      {required this.id,
      required this.uuid,
      required this.branchId,
      required this.serviceName,
      required this.serviceNameSlug,
      this.driverStatus,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['branch_id'] = Variable<int>(branchId);
    map['service_name'] = Variable<String>(serviceName);
    map['service_name_slug'] = Variable<String>(serviceNameSlug);
    if (!nullToAbsent || driverStatus != null) {
      map['driver_status'] = Variable<String>(driverStatus);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  PullDeliveryServiceRowsCompanion toCompanion(bool nullToAbsent) {
    return PullDeliveryServiceRowsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      branchId: Value(branchId),
      serviceName: Value(serviceName),
      serviceNameSlug: Value(serviceNameSlug),
      driverStatus: driverStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(driverStatus),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory PullDeliveryServiceRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PullDeliveryServiceRow(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      branchId: serializer.fromJson<int>(json['branchId']),
      serviceName: serializer.fromJson<String>(json['serviceName']),
      serviceNameSlug: serializer.fromJson<String>(json['serviceNameSlug']),
      driverStatus: serializer.fromJson<String?>(json['driverStatus']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'branchId': serializer.toJson<int>(branchId),
      'serviceName': serializer.toJson<String>(serviceName),
      'serviceNameSlug': serializer.toJson<String>(serviceNameSlug),
      'driverStatus': serializer.toJson<String?>(driverStatus),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  PullDeliveryServiceRow copyWith(
          {int? id,
          String? uuid,
          int? branchId,
          String? serviceName,
          String? serviceNameSlug,
          Value<String?> driverStatus = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      PullDeliveryServiceRow(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        branchId: branchId ?? this.branchId,
        serviceName: serviceName ?? this.serviceName,
        serviceNameSlug: serviceNameSlug ?? this.serviceNameSlug,
        driverStatus:
            driverStatus.present ? driverStatus.value : this.driverStatus,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  PullDeliveryServiceRow copyWithCompanion(
      PullDeliveryServiceRowsCompanion data) {
    return PullDeliveryServiceRow(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      serviceName:
          data.serviceName.present ? data.serviceName.value : this.serviceName,
      serviceNameSlug: data.serviceNameSlug.present
          ? data.serviceNameSlug.value
          : this.serviceNameSlug,
      driverStatus: data.driverStatus.present
          ? data.driverStatus.value
          : this.driverStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PullDeliveryServiceRow(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('branchId: $branchId, ')
          ..write('serviceName: $serviceName, ')
          ..write('serviceNameSlug: $serviceNameSlug, ')
          ..write('driverStatus: $driverStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, uuid, branchId, serviceName,
      serviceNameSlug, driverStatus, createdAt, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PullDeliveryServiceRow &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.branchId == this.branchId &&
          other.serviceName == this.serviceName &&
          other.serviceNameSlug == this.serviceNameSlug &&
          other.driverStatus == this.driverStatus &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class PullDeliveryServiceRowsCompanion
    extends UpdateCompanion<PullDeliveryServiceRow> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<int> branchId;
  final Value<String> serviceName;
  final Value<String> serviceNameSlug;
  final Value<String?> driverStatus;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  const PullDeliveryServiceRowsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.branchId = const Value.absent(),
    this.serviceName = const Value.absent(),
    this.serviceNameSlug = const Value.absent(),
    this.driverStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  PullDeliveryServiceRowsCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required int branchId,
    required String serviceName,
    required String serviceNameSlug,
    this.driverStatus = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
  })  : uuid = Value(uuid),
        branchId = Value(branchId),
        serviceName = Value(serviceName),
        serviceNameSlug = Value(serviceNameSlug),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<PullDeliveryServiceRow> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<int>? branchId,
    Expression<String>? serviceName,
    Expression<String>? serviceNameSlug,
    Expression<String>? driverStatus,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (branchId != null) 'branch_id': branchId,
      if (serviceName != null) 'service_name': serviceName,
      if (serviceNameSlug != null) 'service_name_slug': serviceNameSlug,
      if (driverStatus != null) 'driver_status': driverStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  PullDeliveryServiceRowsCompanion copyWith(
      {Value<int>? id,
      Value<String>? uuid,
      Value<int>? branchId,
      Value<String>? serviceName,
      Value<String>? serviceNameSlug,
      Value<String?>? driverStatus,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt}) {
    return PullDeliveryServiceRowsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      branchId: branchId ?? this.branchId,
      serviceName: serviceName ?? this.serviceName,
      serviceNameSlug: serviceNameSlug ?? this.serviceNameSlug,
      driverStatus: driverStatus ?? this.driverStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<int>(branchId.value);
    }
    if (serviceName.present) {
      map['service_name'] = Variable<String>(serviceName.value);
    }
    if (serviceNameSlug.present) {
      map['service_name_slug'] = Variable<String>(serviceNameSlug.value);
    }
    if (driverStatus.present) {
      map['driver_status'] = Variable<String>(driverStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PullDeliveryServiceRowsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('branchId: $branchId, ')
          ..write('serviceName: $serviceName, ')
          ..write('serviceNameSlug: $serviceNameSlug, ')
          ..write('driverStatus: $driverStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $PullItemRowsTable extends PullItemRows
    with TableInfo<$PullItemRowsTable, PullItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PullItemRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
      'uuid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _branchIdMeta =
      const VerificationMeta('branchId');
  @override
  late final GeneratedColumn<int> branchId = GeneratedColumn<int>(
      'branch_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
      'category_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _unitIdMeta = const VerificationMeta('unitId');
  @override
  late final GeneratedColumn<int> unitId = GeneratedColumn<int>(
      'unit_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _itemNameMeta =
      const VerificationMeta('itemName');
  @override
  late final GeneratedColumn<String> itemName = GeneratedColumn<String>(
      'item_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _itemSlugMeta =
      const VerificationMeta('itemSlug');
  @override
  late final GeneratedColumn<String> itemSlug = GeneratedColumn<String>(
      'item_slug', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _itemOtherNameMeta =
      const VerificationMeta('itemOtherName');
  @override
  late final GeneratedColumn<String> itemOtherName = GeneratedColumn<String>(
      'item_other_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _kitchenIdsMeta =
      const VerificationMeta('kitchenIds');
  @override
  late final GeneratedColumn<String> kitchenIds = GeneratedColumn<String>(
      'kitchen_ids', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _toppingIdsMeta =
      const VerificationMeta('toppingIds');
  @override
  late final GeneratedColumn<String> toppingIds = GeneratedColumn<String>(
      'topping_ids', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _taxMeta = const VerificationMeta('tax');
  @override
  late final GeneratedColumn<String> tax = GeneratedColumn<String>(
      'tax', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _taxPercentMeta =
      const VerificationMeta('taxPercent');
  @override
  late final GeneratedColumn<String> taxPercent = GeneratedColumn<String>(
      'tax_percent', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _minimumQtyMeta =
      const VerificationMeta('minimumQty');
  @override
  late final GeneratedColumn<int> minimumQty = GeneratedColumn<int>(
      'minimum_qty', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _itemTypeMeta =
      const VerificationMeta('itemType');
  @override
  late final GeneratedColumn<String> itemType = GeneratedColumn<String>(
      'item_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _stockApplicableMeta =
      const VerificationMeta('stockApplicable');
  @override
  late final GeneratedColumn<String> stockApplicable = GeneratedColumn<String>(
      'stock_applicable', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ingredientMeta =
      const VerificationMeta('ingredient');
  @override
  late final GeneratedColumn<String> ingredient = GeneratedColumn<String>(
      'ingredient', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _orderTypeMeta =
      const VerificationMeta('orderType');
  @override
  late final GeneratedColumn<String> orderType = GeneratedColumn<String>(
      'order_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deliveryServiceMeta =
      const VerificationMeta('deliveryService');
  @override
  late final GeneratedColumn<String> deliveryService = GeneratedColumn<String>(
      'delivery_service', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _imageMeta = const VerificationMeta('image');
  @override
  late final GeneratedColumn<String> image = GeneratedColumn<String>(
      'image', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _expiryDateMeta =
      const VerificationMeta('expiryDate');
  @override
  late final GeneratedColumn<String> expiryDate = GeneratedColumn<String>(
      'expiry_date', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<String> active = GeneratedColumn<String>(
      'active', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isVariantMeta =
      const VerificationMeta('isVariant');
  @override
  late final GeneratedColumn<int> isVariant = GeneratedColumn<int>(
      'is_variant', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _itemVariationsJsonMeta =
      const VerificationMeta('itemVariationsJson');
  @override
  late final GeneratedColumn<String> itemVariationsJson =
      GeneratedColumn<String>('item_variations_json', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _itempriceJsonMeta =
      const VerificationMeta('itempriceJson');
  @override
  late final GeneratedColumn<String> itempriceJson = GeneratedColumn<String>(
      'itemprice_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        uuid,
        branchId,
        categoryId,
        unitId,
        itemName,
        itemSlug,
        itemOtherName,
        kitchenIds,
        toppingIds,
        tax,
        taxPercent,
        minimumQty,
        itemType,
        stockApplicable,
        ingredient,
        orderType,
        deliveryService,
        image,
        expiryDate,
        active,
        isVariant,
        itemVariationsJson,
        itempriceJson,
        createdAt,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pull_item_rows';
  @override
  VerificationContext validateIntegrity(Insertable<PullItemRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
          _uuidMeta, uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta));
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(_branchIdMeta,
          branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta));
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('unit_id')) {
      context.handle(_unitIdMeta,
          unitId.isAcceptableOrUnknown(data['unit_id']!, _unitIdMeta));
    } else if (isInserting) {
      context.missing(_unitIdMeta);
    }
    if (data.containsKey('item_name')) {
      context.handle(_itemNameMeta,
          itemName.isAcceptableOrUnknown(data['item_name']!, _itemNameMeta));
    } else if (isInserting) {
      context.missing(_itemNameMeta);
    }
    if (data.containsKey('item_slug')) {
      context.handle(_itemSlugMeta,
          itemSlug.isAcceptableOrUnknown(data['item_slug']!, _itemSlugMeta));
    } else if (isInserting) {
      context.missing(_itemSlugMeta);
    }
    if (data.containsKey('item_other_name')) {
      context.handle(
          _itemOtherNameMeta,
          itemOtherName.isAcceptableOrUnknown(
              data['item_other_name']!, _itemOtherNameMeta));
    }
    if (data.containsKey('kitchen_ids')) {
      context.handle(
          _kitchenIdsMeta,
          kitchenIds.isAcceptableOrUnknown(
              data['kitchen_ids']!, _kitchenIdsMeta));
    } else if (isInserting) {
      context.missing(_kitchenIdsMeta);
    }
    if (data.containsKey('topping_ids')) {
      context.handle(
          _toppingIdsMeta,
          toppingIds.isAcceptableOrUnknown(
              data['topping_ids']!, _toppingIdsMeta));
    }
    if (data.containsKey('tax')) {
      context.handle(
          _taxMeta, tax.isAcceptableOrUnknown(data['tax']!, _taxMeta));
    } else if (isInserting) {
      context.missing(_taxMeta);
    }
    if (data.containsKey('tax_percent')) {
      context.handle(
          _taxPercentMeta,
          taxPercent.isAcceptableOrUnknown(
              data['tax_percent']!, _taxPercentMeta));
    }
    if (data.containsKey('minimum_qty')) {
      context.handle(
          _minimumQtyMeta,
          minimumQty.isAcceptableOrUnknown(
              data['minimum_qty']!, _minimumQtyMeta));
    } else if (isInserting) {
      context.missing(_minimumQtyMeta);
    }
    if (data.containsKey('item_type')) {
      context.handle(_itemTypeMeta,
          itemType.isAcceptableOrUnknown(data['item_type']!, _itemTypeMeta));
    } else if (isInserting) {
      context.missing(_itemTypeMeta);
    }
    if (data.containsKey('stock_applicable')) {
      context.handle(
          _stockApplicableMeta,
          stockApplicable.isAcceptableOrUnknown(
              data['stock_applicable']!, _stockApplicableMeta));
    } else if (isInserting) {
      context.missing(_stockApplicableMeta);
    }
    if (data.containsKey('ingredient')) {
      context.handle(
          _ingredientMeta,
          ingredient.isAcceptableOrUnknown(
              data['ingredient']!, _ingredientMeta));
    } else if (isInserting) {
      context.missing(_ingredientMeta);
    }
    if (data.containsKey('order_type')) {
      context.handle(_orderTypeMeta,
          orderType.isAcceptableOrUnknown(data['order_type']!, _orderTypeMeta));
    } else if (isInserting) {
      context.missing(_orderTypeMeta);
    }
    if (data.containsKey('delivery_service')) {
      context.handle(
          _deliveryServiceMeta,
          deliveryService.isAcceptableOrUnknown(
              data['delivery_service']!, _deliveryServiceMeta));
    } else if (isInserting) {
      context.missing(_deliveryServiceMeta);
    }
    if (data.containsKey('image')) {
      context.handle(
          _imageMeta, image.isAcceptableOrUnknown(data['image']!, _imageMeta));
    } else if (isInserting) {
      context.missing(_imageMeta);
    }
    if (data.containsKey('expiry_date')) {
      context.handle(
          _expiryDateMeta,
          expiryDate.isAcceptableOrUnknown(
              data['expiry_date']!, _expiryDateMeta));
    }
    if (data.containsKey('active')) {
      context.handle(_activeMeta,
          active.isAcceptableOrUnknown(data['active']!, _activeMeta));
    } else if (isInserting) {
      context.missing(_activeMeta);
    }
    if (data.containsKey('is_variant')) {
      context.handle(_isVariantMeta,
          isVariant.isAcceptableOrUnknown(data['is_variant']!, _isVariantMeta));
    } else if (isInserting) {
      context.missing(_isVariantMeta);
    }
    if (data.containsKey('item_variations_json')) {
      context.handle(
          _itemVariationsJsonMeta,
          itemVariationsJson.isAcceptableOrUnknown(
              data['item_variations_json']!, _itemVariationsJsonMeta));
    }
    if (data.containsKey('itemprice_json')) {
      context.handle(
          _itempriceJsonMeta,
          itempriceJson.isAcceptableOrUnknown(
              data['itemprice_json']!, _itempriceJsonMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PullItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PullItemRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uuid'])!,
      branchId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}branch_id'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}category_id'])!,
      unitId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}unit_id'])!,
      itemName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_name'])!,
      itemSlug: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_slug'])!,
      itemOtherName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_other_name']),
      kitchenIds: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kitchen_ids'])!,
      toppingIds: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}topping_ids']),
      tax: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tax'])!,
      taxPercent: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tax_percent']),
      minimumQty: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}minimum_qty'])!,
      itemType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_type'])!,
      stockApplicable: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}stock_applicable'])!,
      ingredient: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ingredient'])!,
      orderType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}order_type'])!,
      deliveryService: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}delivery_service'])!,
      image: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image'])!,
      expiryDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}expiry_date']),
      active: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}active'])!,
      isVariant: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}is_variant'])!,
      itemVariationsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}item_variations_json']),
      itempriceJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}itemprice_json']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $PullItemRowsTable createAlias(String alias) {
    return $PullItemRowsTable(attachedDatabase, alias);
  }
}

class PullItemRow extends DataClass implements Insertable<PullItemRow> {
  final int id;
  final String uuid;
  final int branchId;
  final int categoryId;
  final int unitId;
  final String itemName;
  final String itemSlug;
  final String? itemOtherName;
  final String kitchenIds;
  final String? toppingIds;
  final String tax;
  final String? taxPercent;
  final int minimumQty;
  final String itemType;
  final String stockApplicable;
  final String ingredient;
  final String orderType;
  final String deliveryService;
  final String image;
  final String? expiryDate;
  final String active;
  final int isVariant;

  /// JSON: item_variations array from API
  final String? itemVariationsJson;

  /// JSON: itemprice array from API
  final String? itempriceJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const PullItemRow(
      {required this.id,
      required this.uuid,
      required this.branchId,
      required this.categoryId,
      required this.unitId,
      required this.itemName,
      required this.itemSlug,
      this.itemOtherName,
      required this.kitchenIds,
      this.toppingIds,
      required this.tax,
      this.taxPercent,
      required this.minimumQty,
      required this.itemType,
      required this.stockApplicable,
      required this.ingredient,
      required this.orderType,
      required this.deliveryService,
      required this.image,
      this.expiryDate,
      required this.active,
      required this.isVariant,
      this.itemVariationsJson,
      this.itempriceJson,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['branch_id'] = Variable<int>(branchId);
    map['category_id'] = Variable<int>(categoryId);
    map['unit_id'] = Variable<int>(unitId);
    map['item_name'] = Variable<String>(itemName);
    map['item_slug'] = Variable<String>(itemSlug);
    if (!nullToAbsent || itemOtherName != null) {
      map['item_other_name'] = Variable<String>(itemOtherName);
    }
    map['kitchen_ids'] = Variable<String>(kitchenIds);
    if (!nullToAbsent || toppingIds != null) {
      map['topping_ids'] = Variable<String>(toppingIds);
    }
    map['tax'] = Variable<String>(tax);
    if (!nullToAbsent || taxPercent != null) {
      map['tax_percent'] = Variable<String>(taxPercent);
    }
    map['minimum_qty'] = Variable<int>(minimumQty);
    map['item_type'] = Variable<String>(itemType);
    map['stock_applicable'] = Variable<String>(stockApplicable);
    map['ingredient'] = Variable<String>(ingredient);
    map['order_type'] = Variable<String>(orderType);
    map['delivery_service'] = Variable<String>(deliveryService);
    map['image'] = Variable<String>(image);
    if (!nullToAbsent || expiryDate != null) {
      map['expiry_date'] = Variable<String>(expiryDate);
    }
    map['active'] = Variable<String>(active);
    map['is_variant'] = Variable<int>(isVariant);
    if (!nullToAbsent || itemVariationsJson != null) {
      map['item_variations_json'] = Variable<String>(itemVariationsJson);
    }
    if (!nullToAbsent || itempriceJson != null) {
      map['itemprice_json'] = Variable<String>(itempriceJson);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  PullItemRowsCompanion toCompanion(bool nullToAbsent) {
    return PullItemRowsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      branchId: Value(branchId),
      categoryId: Value(categoryId),
      unitId: Value(unitId),
      itemName: Value(itemName),
      itemSlug: Value(itemSlug),
      itemOtherName: itemOtherName == null && nullToAbsent
          ? const Value.absent()
          : Value(itemOtherName),
      kitchenIds: Value(kitchenIds),
      toppingIds: toppingIds == null && nullToAbsent
          ? const Value.absent()
          : Value(toppingIds),
      tax: Value(tax),
      taxPercent: taxPercent == null && nullToAbsent
          ? const Value.absent()
          : Value(taxPercent),
      minimumQty: Value(minimumQty),
      itemType: Value(itemType),
      stockApplicable: Value(stockApplicable),
      ingredient: Value(ingredient),
      orderType: Value(orderType),
      deliveryService: Value(deliveryService),
      image: Value(image),
      expiryDate: expiryDate == null && nullToAbsent
          ? const Value.absent()
          : Value(expiryDate),
      active: Value(active),
      isVariant: Value(isVariant),
      itemVariationsJson: itemVariationsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(itemVariationsJson),
      itempriceJson: itempriceJson == null && nullToAbsent
          ? const Value.absent()
          : Value(itempriceJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory PullItemRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PullItemRow(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      branchId: serializer.fromJson<int>(json['branchId']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      unitId: serializer.fromJson<int>(json['unitId']),
      itemName: serializer.fromJson<String>(json['itemName']),
      itemSlug: serializer.fromJson<String>(json['itemSlug']),
      itemOtherName: serializer.fromJson<String?>(json['itemOtherName']),
      kitchenIds: serializer.fromJson<String>(json['kitchenIds']),
      toppingIds: serializer.fromJson<String?>(json['toppingIds']),
      tax: serializer.fromJson<String>(json['tax']),
      taxPercent: serializer.fromJson<String?>(json['taxPercent']),
      minimumQty: serializer.fromJson<int>(json['minimumQty']),
      itemType: serializer.fromJson<String>(json['itemType']),
      stockApplicable: serializer.fromJson<String>(json['stockApplicable']),
      ingredient: serializer.fromJson<String>(json['ingredient']),
      orderType: serializer.fromJson<String>(json['orderType']),
      deliveryService: serializer.fromJson<String>(json['deliveryService']),
      image: serializer.fromJson<String>(json['image']),
      expiryDate: serializer.fromJson<String?>(json['expiryDate']),
      active: serializer.fromJson<String>(json['active']),
      isVariant: serializer.fromJson<int>(json['isVariant']),
      itemVariationsJson:
          serializer.fromJson<String?>(json['itemVariationsJson']),
      itempriceJson: serializer.fromJson<String?>(json['itempriceJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'branchId': serializer.toJson<int>(branchId),
      'categoryId': serializer.toJson<int>(categoryId),
      'unitId': serializer.toJson<int>(unitId),
      'itemName': serializer.toJson<String>(itemName),
      'itemSlug': serializer.toJson<String>(itemSlug),
      'itemOtherName': serializer.toJson<String?>(itemOtherName),
      'kitchenIds': serializer.toJson<String>(kitchenIds),
      'toppingIds': serializer.toJson<String?>(toppingIds),
      'tax': serializer.toJson<String>(tax),
      'taxPercent': serializer.toJson<String?>(taxPercent),
      'minimumQty': serializer.toJson<int>(minimumQty),
      'itemType': serializer.toJson<String>(itemType),
      'stockApplicable': serializer.toJson<String>(stockApplicable),
      'ingredient': serializer.toJson<String>(ingredient),
      'orderType': serializer.toJson<String>(orderType),
      'deliveryService': serializer.toJson<String>(deliveryService),
      'image': serializer.toJson<String>(image),
      'expiryDate': serializer.toJson<String?>(expiryDate),
      'active': serializer.toJson<String>(active),
      'isVariant': serializer.toJson<int>(isVariant),
      'itemVariationsJson': serializer.toJson<String?>(itemVariationsJson),
      'itempriceJson': serializer.toJson<String?>(itempriceJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  PullItemRow copyWith(
          {int? id,
          String? uuid,
          int? branchId,
          int? categoryId,
          int? unitId,
          String? itemName,
          String? itemSlug,
          Value<String?> itemOtherName = const Value.absent(),
          String? kitchenIds,
          Value<String?> toppingIds = const Value.absent(),
          String? tax,
          Value<String?> taxPercent = const Value.absent(),
          int? minimumQty,
          String? itemType,
          String? stockApplicable,
          String? ingredient,
          String? orderType,
          String? deliveryService,
          String? image,
          Value<String?> expiryDate = const Value.absent(),
          String? active,
          int? isVariant,
          Value<String?> itemVariationsJson = const Value.absent(),
          Value<String?> itempriceJson = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      PullItemRow(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        branchId: branchId ?? this.branchId,
        categoryId: categoryId ?? this.categoryId,
        unitId: unitId ?? this.unitId,
        itemName: itemName ?? this.itemName,
        itemSlug: itemSlug ?? this.itemSlug,
        itemOtherName:
            itemOtherName.present ? itemOtherName.value : this.itemOtherName,
        kitchenIds: kitchenIds ?? this.kitchenIds,
        toppingIds: toppingIds.present ? toppingIds.value : this.toppingIds,
        tax: tax ?? this.tax,
        taxPercent: taxPercent.present ? taxPercent.value : this.taxPercent,
        minimumQty: minimumQty ?? this.minimumQty,
        itemType: itemType ?? this.itemType,
        stockApplicable: stockApplicable ?? this.stockApplicable,
        ingredient: ingredient ?? this.ingredient,
        orderType: orderType ?? this.orderType,
        deliveryService: deliveryService ?? this.deliveryService,
        image: image ?? this.image,
        expiryDate: expiryDate.present ? expiryDate.value : this.expiryDate,
        active: active ?? this.active,
        isVariant: isVariant ?? this.isVariant,
        itemVariationsJson: itemVariationsJson.present
            ? itemVariationsJson.value
            : this.itemVariationsJson,
        itempriceJson:
            itempriceJson.present ? itempriceJson.value : this.itempriceJson,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  PullItemRow copyWithCompanion(PullItemRowsCompanion data) {
    return PullItemRow(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      unitId: data.unitId.present ? data.unitId.value : this.unitId,
      itemName: data.itemName.present ? data.itemName.value : this.itemName,
      itemSlug: data.itemSlug.present ? data.itemSlug.value : this.itemSlug,
      itemOtherName: data.itemOtherName.present
          ? data.itemOtherName.value
          : this.itemOtherName,
      kitchenIds:
          data.kitchenIds.present ? data.kitchenIds.value : this.kitchenIds,
      toppingIds:
          data.toppingIds.present ? data.toppingIds.value : this.toppingIds,
      tax: data.tax.present ? data.tax.value : this.tax,
      taxPercent:
          data.taxPercent.present ? data.taxPercent.value : this.taxPercent,
      minimumQty:
          data.minimumQty.present ? data.minimumQty.value : this.minimumQty,
      itemType: data.itemType.present ? data.itemType.value : this.itemType,
      stockApplicable: data.stockApplicable.present
          ? data.stockApplicable.value
          : this.stockApplicable,
      ingredient:
          data.ingredient.present ? data.ingredient.value : this.ingredient,
      orderType: data.orderType.present ? data.orderType.value : this.orderType,
      deliveryService: data.deliveryService.present
          ? data.deliveryService.value
          : this.deliveryService,
      image: data.image.present ? data.image.value : this.image,
      expiryDate:
          data.expiryDate.present ? data.expiryDate.value : this.expiryDate,
      active: data.active.present ? data.active.value : this.active,
      isVariant: data.isVariant.present ? data.isVariant.value : this.isVariant,
      itemVariationsJson: data.itemVariationsJson.present
          ? data.itemVariationsJson.value
          : this.itemVariationsJson,
      itempriceJson: data.itempriceJson.present
          ? data.itempriceJson.value
          : this.itempriceJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PullItemRow(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('branchId: $branchId, ')
          ..write('categoryId: $categoryId, ')
          ..write('unitId: $unitId, ')
          ..write('itemName: $itemName, ')
          ..write('itemSlug: $itemSlug, ')
          ..write('itemOtherName: $itemOtherName, ')
          ..write('kitchenIds: $kitchenIds, ')
          ..write('toppingIds: $toppingIds, ')
          ..write('tax: $tax, ')
          ..write('taxPercent: $taxPercent, ')
          ..write('minimumQty: $minimumQty, ')
          ..write('itemType: $itemType, ')
          ..write('stockApplicable: $stockApplicable, ')
          ..write('ingredient: $ingredient, ')
          ..write('orderType: $orderType, ')
          ..write('deliveryService: $deliveryService, ')
          ..write('image: $image, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('active: $active, ')
          ..write('isVariant: $isVariant, ')
          ..write('itemVariationsJson: $itemVariationsJson, ')
          ..write('itempriceJson: $itempriceJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        uuid,
        branchId,
        categoryId,
        unitId,
        itemName,
        itemSlug,
        itemOtherName,
        kitchenIds,
        toppingIds,
        tax,
        taxPercent,
        minimumQty,
        itemType,
        stockApplicable,
        ingredient,
        orderType,
        deliveryService,
        image,
        expiryDate,
        active,
        isVariant,
        itemVariationsJson,
        itempriceJson,
        createdAt,
        updatedAt,
        deletedAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PullItemRow &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.branchId == this.branchId &&
          other.categoryId == this.categoryId &&
          other.unitId == this.unitId &&
          other.itemName == this.itemName &&
          other.itemSlug == this.itemSlug &&
          other.itemOtherName == this.itemOtherName &&
          other.kitchenIds == this.kitchenIds &&
          other.toppingIds == this.toppingIds &&
          other.tax == this.tax &&
          other.taxPercent == this.taxPercent &&
          other.minimumQty == this.minimumQty &&
          other.itemType == this.itemType &&
          other.stockApplicable == this.stockApplicable &&
          other.ingredient == this.ingredient &&
          other.orderType == this.orderType &&
          other.deliveryService == this.deliveryService &&
          other.image == this.image &&
          other.expiryDate == this.expiryDate &&
          other.active == this.active &&
          other.isVariant == this.isVariant &&
          other.itemVariationsJson == this.itemVariationsJson &&
          other.itempriceJson == this.itempriceJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class PullItemRowsCompanion extends UpdateCompanion<PullItemRow> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<int> branchId;
  final Value<int> categoryId;
  final Value<int> unitId;
  final Value<String> itemName;
  final Value<String> itemSlug;
  final Value<String?> itemOtherName;
  final Value<String> kitchenIds;
  final Value<String?> toppingIds;
  final Value<String> tax;
  final Value<String?> taxPercent;
  final Value<int> minimumQty;
  final Value<String> itemType;
  final Value<String> stockApplicable;
  final Value<String> ingredient;
  final Value<String> orderType;
  final Value<String> deliveryService;
  final Value<String> image;
  final Value<String?> expiryDate;
  final Value<String> active;
  final Value<int> isVariant;
  final Value<String?> itemVariationsJson;
  final Value<String?> itempriceJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  const PullItemRowsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.branchId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.unitId = const Value.absent(),
    this.itemName = const Value.absent(),
    this.itemSlug = const Value.absent(),
    this.itemOtherName = const Value.absent(),
    this.kitchenIds = const Value.absent(),
    this.toppingIds = const Value.absent(),
    this.tax = const Value.absent(),
    this.taxPercent = const Value.absent(),
    this.minimumQty = const Value.absent(),
    this.itemType = const Value.absent(),
    this.stockApplicable = const Value.absent(),
    this.ingredient = const Value.absent(),
    this.orderType = const Value.absent(),
    this.deliveryService = const Value.absent(),
    this.image = const Value.absent(),
    this.expiryDate = const Value.absent(),
    this.active = const Value.absent(),
    this.isVariant = const Value.absent(),
    this.itemVariationsJson = const Value.absent(),
    this.itempriceJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  PullItemRowsCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required int branchId,
    required int categoryId,
    required int unitId,
    required String itemName,
    required String itemSlug,
    this.itemOtherName = const Value.absent(),
    required String kitchenIds,
    this.toppingIds = const Value.absent(),
    required String tax,
    this.taxPercent = const Value.absent(),
    required int minimumQty,
    required String itemType,
    required String stockApplicable,
    required String ingredient,
    required String orderType,
    required String deliveryService,
    required String image,
    this.expiryDate = const Value.absent(),
    required String active,
    required int isVariant,
    this.itemVariationsJson = const Value.absent(),
    this.itempriceJson = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
  })  : uuid = Value(uuid),
        branchId = Value(branchId),
        categoryId = Value(categoryId),
        unitId = Value(unitId),
        itemName = Value(itemName),
        itemSlug = Value(itemSlug),
        kitchenIds = Value(kitchenIds),
        tax = Value(tax),
        minimumQty = Value(minimumQty),
        itemType = Value(itemType),
        stockApplicable = Value(stockApplicable),
        ingredient = Value(ingredient),
        orderType = Value(orderType),
        deliveryService = Value(deliveryService),
        image = Value(image),
        active = Value(active),
        isVariant = Value(isVariant),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<PullItemRow> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<int>? branchId,
    Expression<int>? categoryId,
    Expression<int>? unitId,
    Expression<String>? itemName,
    Expression<String>? itemSlug,
    Expression<String>? itemOtherName,
    Expression<String>? kitchenIds,
    Expression<String>? toppingIds,
    Expression<String>? tax,
    Expression<String>? taxPercent,
    Expression<int>? minimumQty,
    Expression<String>? itemType,
    Expression<String>? stockApplicable,
    Expression<String>? ingredient,
    Expression<String>? orderType,
    Expression<String>? deliveryService,
    Expression<String>? image,
    Expression<String>? expiryDate,
    Expression<String>? active,
    Expression<int>? isVariant,
    Expression<String>? itemVariationsJson,
    Expression<String>? itempriceJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (branchId != null) 'branch_id': branchId,
      if (categoryId != null) 'category_id': categoryId,
      if (unitId != null) 'unit_id': unitId,
      if (itemName != null) 'item_name': itemName,
      if (itemSlug != null) 'item_slug': itemSlug,
      if (itemOtherName != null) 'item_other_name': itemOtherName,
      if (kitchenIds != null) 'kitchen_ids': kitchenIds,
      if (toppingIds != null) 'topping_ids': toppingIds,
      if (tax != null) 'tax': tax,
      if (taxPercent != null) 'tax_percent': taxPercent,
      if (minimumQty != null) 'minimum_qty': minimumQty,
      if (itemType != null) 'item_type': itemType,
      if (stockApplicable != null) 'stock_applicable': stockApplicable,
      if (ingredient != null) 'ingredient': ingredient,
      if (orderType != null) 'order_type': orderType,
      if (deliveryService != null) 'delivery_service': deliveryService,
      if (image != null) 'image': image,
      if (expiryDate != null) 'expiry_date': expiryDate,
      if (active != null) 'active': active,
      if (isVariant != null) 'is_variant': isVariant,
      if (itemVariationsJson != null)
        'item_variations_json': itemVariationsJson,
      if (itempriceJson != null) 'itemprice_json': itempriceJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  PullItemRowsCompanion copyWith(
      {Value<int>? id,
      Value<String>? uuid,
      Value<int>? branchId,
      Value<int>? categoryId,
      Value<int>? unitId,
      Value<String>? itemName,
      Value<String>? itemSlug,
      Value<String?>? itemOtherName,
      Value<String>? kitchenIds,
      Value<String?>? toppingIds,
      Value<String>? tax,
      Value<String?>? taxPercent,
      Value<int>? minimumQty,
      Value<String>? itemType,
      Value<String>? stockApplicable,
      Value<String>? ingredient,
      Value<String>? orderType,
      Value<String>? deliveryService,
      Value<String>? image,
      Value<String?>? expiryDate,
      Value<String>? active,
      Value<int>? isVariant,
      Value<String?>? itemVariationsJson,
      Value<String?>? itempriceJson,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt}) {
    return PullItemRowsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      branchId: branchId ?? this.branchId,
      categoryId: categoryId ?? this.categoryId,
      unitId: unitId ?? this.unitId,
      itemName: itemName ?? this.itemName,
      itemSlug: itemSlug ?? this.itemSlug,
      itemOtherName: itemOtherName ?? this.itemOtherName,
      kitchenIds: kitchenIds ?? this.kitchenIds,
      toppingIds: toppingIds ?? this.toppingIds,
      tax: tax ?? this.tax,
      taxPercent: taxPercent ?? this.taxPercent,
      minimumQty: minimumQty ?? this.minimumQty,
      itemType: itemType ?? this.itemType,
      stockApplicable: stockApplicable ?? this.stockApplicable,
      ingredient: ingredient ?? this.ingredient,
      orderType: orderType ?? this.orderType,
      deliveryService: deliveryService ?? this.deliveryService,
      image: image ?? this.image,
      expiryDate: expiryDate ?? this.expiryDate,
      active: active ?? this.active,
      isVariant: isVariant ?? this.isVariant,
      itemVariationsJson: itemVariationsJson ?? this.itemVariationsJson,
      itempriceJson: itempriceJson ?? this.itempriceJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<int>(branchId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (unitId.present) {
      map['unit_id'] = Variable<int>(unitId.value);
    }
    if (itemName.present) {
      map['item_name'] = Variable<String>(itemName.value);
    }
    if (itemSlug.present) {
      map['item_slug'] = Variable<String>(itemSlug.value);
    }
    if (itemOtherName.present) {
      map['item_other_name'] = Variable<String>(itemOtherName.value);
    }
    if (kitchenIds.present) {
      map['kitchen_ids'] = Variable<String>(kitchenIds.value);
    }
    if (toppingIds.present) {
      map['topping_ids'] = Variable<String>(toppingIds.value);
    }
    if (tax.present) {
      map['tax'] = Variable<String>(tax.value);
    }
    if (taxPercent.present) {
      map['tax_percent'] = Variable<String>(taxPercent.value);
    }
    if (minimumQty.present) {
      map['minimum_qty'] = Variable<int>(minimumQty.value);
    }
    if (itemType.present) {
      map['item_type'] = Variable<String>(itemType.value);
    }
    if (stockApplicable.present) {
      map['stock_applicable'] = Variable<String>(stockApplicable.value);
    }
    if (ingredient.present) {
      map['ingredient'] = Variable<String>(ingredient.value);
    }
    if (orderType.present) {
      map['order_type'] = Variable<String>(orderType.value);
    }
    if (deliveryService.present) {
      map['delivery_service'] = Variable<String>(deliveryService.value);
    }
    if (image.present) {
      map['image'] = Variable<String>(image.value);
    }
    if (expiryDate.present) {
      map['expiry_date'] = Variable<String>(expiryDate.value);
    }
    if (active.present) {
      map['active'] = Variable<String>(active.value);
    }
    if (isVariant.present) {
      map['is_variant'] = Variable<int>(isVariant.value);
    }
    if (itemVariationsJson.present) {
      map['item_variations_json'] = Variable<String>(itemVariationsJson.value);
    }
    if (itempriceJson.present) {
      map['itemprice_json'] = Variable<String>(itempriceJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PullItemRowsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('branchId: $branchId, ')
          ..write('categoryId: $categoryId, ')
          ..write('unitId: $unitId, ')
          ..write('itemName: $itemName, ')
          ..write('itemSlug: $itemSlug, ')
          ..write('itemOtherName: $itemOtherName, ')
          ..write('kitchenIds: $kitchenIds, ')
          ..write('toppingIds: $toppingIds, ')
          ..write('tax: $tax, ')
          ..write('taxPercent: $taxPercent, ')
          ..write('minimumQty: $minimumQty, ')
          ..write('itemType: $itemType, ')
          ..write('stockApplicable: $stockApplicable, ')
          ..write('ingredient: $ingredient, ')
          ..write('orderType: $orderType, ')
          ..write('deliveryService: $deliveryService, ')
          ..write('image: $image, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('active: $active, ')
          ..write('isVariant: $isVariant, ')
          ..write('itemVariationsJson: $itemVariationsJson, ')
          ..write('itempriceJson: $itempriceJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $SyncPaginationStatesTable extends SyncPaginationStates
    with TableInfo<$SyncPaginationStatesTable, SyncPaginationState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncPaginationStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _resourceKeyMeta =
      const VerificationMeta('resourceKey');
  @override
  late final GeneratedColumn<String> resourceKey = GeneratedColumn<String>(
      'resource_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _currentPageMeta =
      const VerificationMeta('currentPage');
  @override
  late final GeneratedColumn<int> currentPage = GeneratedColumn<int>(
      'current_page', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _pageFromMeta =
      const VerificationMeta('pageFrom');
  @override
  late final GeneratedColumn<int> pageFrom = GeneratedColumn<int>(
      'page_from', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _lastPageMeta =
      const VerificationMeta('lastPage');
  @override
  late final GeneratedColumn<int> lastPage = GeneratedColumn<int>(
      'last_page', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _perPageMeta =
      const VerificationMeta('perPage');
  @override
  late final GeneratedColumn<int> perPage = GeneratedColumn<int>(
      'per_page', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _pageToMeta = const VerificationMeta('pageTo');
  @override
  late final GeneratedColumn<int> pageTo = GeneratedColumn<int>(
      'page_to', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<int> total = GeneratedColumn<int>(
      'total', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [resourceKey, currentPage, pageFrom, lastPage, perPage, pageTo, total];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_pagination_states';
  @override
  VerificationContext validateIntegrity(
      Insertable<SyncPaginationState> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('resource_key')) {
      context.handle(
          _resourceKeyMeta,
          resourceKey.isAcceptableOrUnknown(
              data['resource_key']!, _resourceKeyMeta));
    } else if (isInserting) {
      context.missing(_resourceKeyMeta);
    }
    if (data.containsKey('current_page')) {
      context.handle(
          _currentPageMeta,
          currentPage.isAcceptableOrUnknown(
              data['current_page']!, _currentPageMeta));
    }
    if (data.containsKey('page_from')) {
      context.handle(_pageFromMeta,
          pageFrom.isAcceptableOrUnknown(data['page_from']!, _pageFromMeta));
    }
    if (data.containsKey('last_page')) {
      context.handle(_lastPageMeta,
          lastPage.isAcceptableOrUnknown(data['last_page']!, _lastPageMeta));
    }
    if (data.containsKey('per_page')) {
      context.handle(_perPageMeta,
          perPage.isAcceptableOrUnknown(data['per_page']!, _perPageMeta));
    }
    if (data.containsKey('page_to')) {
      context.handle(_pageToMeta,
          pageTo.isAcceptableOrUnknown(data['page_to']!, _pageToMeta));
    }
    if (data.containsKey('total')) {
      context.handle(
          _totalMeta, total.isAcceptableOrUnknown(data['total']!, _totalMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {resourceKey};
  @override
  SyncPaginationState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncPaginationState(
      resourceKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}resource_key'])!,
      currentPage: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}current_page']),
      pageFrom: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}page_from']),
      lastPage: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_page']),
      perPage: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}per_page']),
      pageTo: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}page_to']),
      total: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total']),
    );
  }

  @override
  $SyncPaginationStatesTable createAlias(String alias) {
    return $SyncPaginationStatesTable(attachedDatabase, alias);
  }
}

class SyncPaginationState extends DataClass
    implements Insertable<SyncPaginationState> {
  /// Stable key, e.g. `pull_category`, `pull_item`, `category`, etc.
  final String resourceKey;
  final int? currentPage;
  final int? pageFrom;
  final int? lastPage;
  final int? perPage;
  final int? pageTo;
  final int? total;
  const SyncPaginationState(
      {required this.resourceKey,
      this.currentPage,
      this.pageFrom,
      this.lastPage,
      this.perPage,
      this.pageTo,
      this.total});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['resource_key'] = Variable<String>(resourceKey);
    if (!nullToAbsent || currentPage != null) {
      map['current_page'] = Variable<int>(currentPage);
    }
    if (!nullToAbsent || pageFrom != null) {
      map['page_from'] = Variable<int>(pageFrom);
    }
    if (!nullToAbsent || lastPage != null) {
      map['last_page'] = Variable<int>(lastPage);
    }
    if (!nullToAbsent || perPage != null) {
      map['per_page'] = Variable<int>(perPage);
    }
    if (!nullToAbsent || pageTo != null) {
      map['page_to'] = Variable<int>(pageTo);
    }
    if (!nullToAbsent || total != null) {
      map['total'] = Variable<int>(total);
    }
    return map;
  }

  SyncPaginationStatesCompanion toCompanion(bool nullToAbsent) {
    return SyncPaginationStatesCompanion(
      resourceKey: Value(resourceKey),
      currentPage: currentPage == null && nullToAbsent
          ? const Value.absent()
          : Value(currentPage),
      pageFrom: pageFrom == null && nullToAbsent
          ? const Value.absent()
          : Value(pageFrom),
      lastPage: lastPage == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPage),
      perPage: perPage == null && nullToAbsent
          ? const Value.absent()
          : Value(perPage),
      pageTo:
          pageTo == null && nullToAbsent ? const Value.absent() : Value(pageTo),
      total:
          total == null && nullToAbsent ? const Value.absent() : Value(total),
    );
  }

  factory SyncPaginationState.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncPaginationState(
      resourceKey: serializer.fromJson<String>(json['resourceKey']),
      currentPage: serializer.fromJson<int?>(json['currentPage']),
      pageFrom: serializer.fromJson<int?>(json['pageFrom']),
      lastPage: serializer.fromJson<int?>(json['lastPage']),
      perPage: serializer.fromJson<int?>(json['perPage']),
      pageTo: serializer.fromJson<int?>(json['pageTo']),
      total: serializer.fromJson<int?>(json['total']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'resourceKey': serializer.toJson<String>(resourceKey),
      'currentPage': serializer.toJson<int?>(currentPage),
      'pageFrom': serializer.toJson<int?>(pageFrom),
      'lastPage': serializer.toJson<int?>(lastPage),
      'perPage': serializer.toJson<int?>(perPage),
      'pageTo': serializer.toJson<int?>(pageTo),
      'total': serializer.toJson<int?>(total),
    };
  }

  SyncPaginationState copyWith(
          {String? resourceKey,
          Value<int?> currentPage = const Value.absent(),
          Value<int?> pageFrom = const Value.absent(),
          Value<int?> lastPage = const Value.absent(),
          Value<int?> perPage = const Value.absent(),
          Value<int?> pageTo = const Value.absent(),
          Value<int?> total = const Value.absent()}) =>
      SyncPaginationState(
        resourceKey: resourceKey ?? this.resourceKey,
        currentPage: currentPage.present ? currentPage.value : this.currentPage,
        pageFrom: pageFrom.present ? pageFrom.value : this.pageFrom,
        lastPage: lastPage.present ? lastPage.value : this.lastPage,
        perPage: perPage.present ? perPage.value : this.perPage,
        pageTo: pageTo.present ? pageTo.value : this.pageTo,
        total: total.present ? total.value : this.total,
      );
  SyncPaginationState copyWithCompanion(SyncPaginationStatesCompanion data) {
    return SyncPaginationState(
      resourceKey:
          data.resourceKey.present ? data.resourceKey.value : this.resourceKey,
      currentPage:
          data.currentPage.present ? data.currentPage.value : this.currentPage,
      pageFrom: data.pageFrom.present ? data.pageFrom.value : this.pageFrom,
      lastPage: data.lastPage.present ? data.lastPage.value : this.lastPage,
      perPage: data.perPage.present ? data.perPage.value : this.perPage,
      pageTo: data.pageTo.present ? data.pageTo.value : this.pageTo,
      total: data.total.present ? data.total.value : this.total,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncPaginationState(')
          ..write('resourceKey: $resourceKey, ')
          ..write('currentPage: $currentPage, ')
          ..write('pageFrom: $pageFrom, ')
          ..write('lastPage: $lastPage, ')
          ..write('perPage: $perPage, ')
          ..write('pageTo: $pageTo, ')
          ..write('total: $total')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      resourceKey, currentPage, pageFrom, lastPage, perPage, pageTo, total);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncPaginationState &&
          other.resourceKey == this.resourceKey &&
          other.currentPage == this.currentPage &&
          other.pageFrom == this.pageFrom &&
          other.lastPage == this.lastPage &&
          other.perPage == this.perPage &&
          other.pageTo == this.pageTo &&
          other.total == this.total);
}

class SyncPaginationStatesCompanion
    extends UpdateCompanion<SyncPaginationState> {
  final Value<String> resourceKey;
  final Value<int?> currentPage;
  final Value<int?> pageFrom;
  final Value<int?> lastPage;
  final Value<int?> perPage;
  final Value<int?> pageTo;
  final Value<int?> total;
  final Value<int> rowid;
  const SyncPaginationStatesCompanion({
    this.resourceKey = const Value.absent(),
    this.currentPage = const Value.absent(),
    this.pageFrom = const Value.absent(),
    this.lastPage = const Value.absent(),
    this.perPage = const Value.absent(),
    this.pageTo = const Value.absent(),
    this.total = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncPaginationStatesCompanion.insert({
    required String resourceKey,
    this.currentPage = const Value.absent(),
    this.pageFrom = const Value.absent(),
    this.lastPage = const Value.absent(),
    this.perPage = const Value.absent(),
    this.pageTo = const Value.absent(),
    this.total = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : resourceKey = Value(resourceKey);
  static Insertable<SyncPaginationState> custom({
    Expression<String>? resourceKey,
    Expression<int>? currentPage,
    Expression<int>? pageFrom,
    Expression<int>? lastPage,
    Expression<int>? perPage,
    Expression<int>? pageTo,
    Expression<int>? total,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (resourceKey != null) 'resource_key': resourceKey,
      if (currentPage != null) 'current_page': currentPage,
      if (pageFrom != null) 'page_from': pageFrom,
      if (lastPage != null) 'last_page': lastPage,
      if (perPage != null) 'per_page': perPage,
      if (pageTo != null) 'page_to': pageTo,
      if (total != null) 'total': total,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncPaginationStatesCompanion copyWith(
      {Value<String>? resourceKey,
      Value<int?>? currentPage,
      Value<int?>? pageFrom,
      Value<int?>? lastPage,
      Value<int?>? perPage,
      Value<int?>? pageTo,
      Value<int?>? total,
      Value<int>? rowid}) {
    return SyncPaginationStatesCompanion(
      resourceKey: resourceKey ?? this.resourceKey,
      currentPage: currentPage ?? this.currentPage,
      pageFrom: pageFrom ?? this.pageFrom,
      lastPage: lastPage ?? this.lastPage,
      perPage: perPage ?? this.perPage,
      pageTo: pageTo ?? this.pageTo,
      total: total ?? this.total,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (resourceKey.present) {
      map['resource_key'] = Variable<String>(resourceKey.value);
    }
    if (currentPage.present) {
      map['current_page'] = Variable<int>(currentPage.value);
    }
    if (pageFrom.present) {
      map['page_from'] = Variable<int>(pageFrom.value);
    }
    if (lastPage.present) {
      map['last_page'] = Variable<int>(lastPage.value);
    }
    if (perPage.present) {
      map['per_page'] = Variable<int>(perPage.value);
    }
    if (pageTo.present) {
      map['page_to'] = Variable<int>(pageTo.value);
    }
    if (total.present) {
      map['total'] = Variable<int>(total.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncPaginationStatesCompanion(')
          ..write('resourceKey: $resourceKey, ')
          ..write('currentPage: $currentPage, ')
          ..write('pageFrom: $pageFrom, ')
          ..write('lastPage: $lastPage, ')
          ..write('perPage: $perPage, ')
          ..write('pageTo: $pageTo, ')
          ..write('total: $total, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsersTable users = $UsersTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $KitchensTable kitchens = $KitchensTable(this);
  late final $KitchenPrintersTable kitchenPrinters =
      $KitchenPrintersTable(this);
  late final $ItemsTable items = $ItemsTable(this);
  late final $ItemVariantsTable itemVariants = $ItemVariantsTable(this);
  late final $ItemToppingsTable itemToppings = $ItemToppingsTable(this);
  late final $ToppingGroupsTable toppingGroups = $ToppingGroupsTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $CartsTable carts = $CartsTable(this);
  late final $CartItemsTable cartItems = $CartItemsTable(this);
  late final $DriversTable drivers = $DriversTable(this);
  late final $OrdersTable orders = $OrdersTable(this);
  late final $OrderLogsTable orderLogs = $OrderLogsTable(this);
  late final $CustomersTable customers = $CustomersTable(this);
  late final $DeliveryPartnersTable deliveryPartners =
      $DeliveryPartnersTable(this);
  late final $DiningFloorsTable diningFloors = $DiningFloorsTable(this);
  late final $DiningTablesTable diningTables = $DiningTablesTable(this);
  late final $BranchesTable branches = $BranchesTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $PullCategoryRowsTable pullCategoryRows =
      $PullCategoryRowsTable(this);
  late final $PullFloorRowsTable pullFloorRows = $PullFloorRowsTable(this);
  late final $PullDeliveryServiceRowsTable pullDeliveryServiceRows =
      $PullDeliveryServiceRowsTable(this);
  late final $PullItemRowsTable pullItemRows = $PullItemRowsTable(this);
  late final $SyncPaginationStatesTable syncPaginationStates =
      $SyncPaginationStatesTable(this);
  late final UsersDao usersDao = UsersDao(this as AppDatabase);
  late final CategoryDao categoryDao = CategoryDao(this as AppDatabase);
  late final CartsDao cartsDao = CartsDao(this as AppDatabase);
  late final ItemDao itemDao = ItemDao(this as AppDatabase);
  late final SessionDao sessionDao = SessionDao(this as AppDatabase);
  late final OrdersDao ordersDao = OrdersDao(this as AppDatabase);
  late final CustomersDao customersDao = CustomersDao(this as AppDatabase);
  late final DeliveryPartnersDao deliveryPartnersDao =
      DeliveryPartnersDao(this as AppDatabase);
  late final DriversDao driversDao = DriversDao(this as AppDatabase);
  late final DiningTablesDao diningTablesDao =
      DiningTablesDao(this as AppDatabase);
  late final BranchesDao branchesDao = BranchesDao(this as AppDatabase);
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  late final PullDataDao pullDataDao = PullDataDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        users,
        categories,
        kitchens,
        kitchenPrinters,
        items,
        itemVariants,
        itemToppings,
        toppingGroups,
        sessions,
        carts,
        cartItems,
        drivers,
        orders,
        orderLogs,
        customers,
        deliveryPartners,
        diningFloors,
        diningTables,
        branches,
        settings,
        pullCategoryRows,
        pullFloorRows,
        pullDeliveryServiceRows,
        pullItemRows,
        syncPaginationStates
      ];
}

typedef $$UsersTableCreateCompanionBuilder = UsersCompanion Function({
  Value<int> id,
  required int branchId,
  required String name,
  required String usertype,
  required String mobilePassword,
  required String permissions,
  Value<String?> role,
});
typedef $$UsersTableUpdateCompanionBuilder = UsersCompanion Function({
  Value<int> id,
  Value<int> branchId,
  Value<String> name,
  Value<String> usertype,
  Value<String> mobilePassword,
  Value<String> permissions,
  Value<String?> role,
});

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get usertype => $composableBuilder(
      column: $table.usertype, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mobilePassword => $composableBuilder(
      column: $table.mobilePassword,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get permissions => $composableBuilder(
      column: $table.permissions, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get usertype => $composableBuilder(
      column: $table.usertype, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mobilePassword => $composableBuilder(
      column: $table.mobilePassword,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get permissions => $composableBuilder(
      column: $table.permissions, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get usertype =>
      $composableBuilder(column: $table.usertype, builder: (column) => column);

  GeneratedColumn<String> get mobilePassword => $composableBuilder(
      column: $table.mobilePassword, builder: (column) => column);

  GeneratedColumn<String> get permissions => $composableBuilder(
      column: $table.permissions, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);
}

class $$UsersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UsersTable,
    User,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableAnnotationComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
    User,
    PrefetchHooks Function()> {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> branchId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> usertype = const Value.absent(),
            Value<String> mobilePassword = const Value.absent(),
            Value<String> permissions = const Value.absent(),
            Value<String?> role = const Value.absent(),
          }) =>
              UsersCompanion(
            id: id,
            branchId: branchId,
            name: name,
            usertype: usertype,
            mobilePassword: mobilePassword,
            permissions: permissions,
            role: role,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int branchId,
            required String name,
            required String usertype,
            required String mobilePassword,
            required String permissions,
            Value<String?> role = const Value.absent(),
          }) =>
              UsersCompanion.insert(
            id: id,
            branchId: branchId,
            name: name,
            usertype: usertype,
            mobilePassword: mobilePassword,
            permissions: permissions,
            role: role,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UsersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UsersTable,
    User,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableAnnotationComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
    User,
    PrefetchHooks Function()>;
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  required String name,
  required String otherName,
  Value<String?> recordUuid,
  Value<int?> branchId,
  Value<String?> categorySlug,
  Value<DateTime?> deletedAt,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> otherName,
  Value<String?> recordUuid,
  Value<int?> branchId,
  Value<String?> categorySlug,
  Value<DateTime?> deletedAt,
});

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get otherName => $composableBuilder(
      column: $table.otherName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recordUuid => $composableBuilder(
      column: $table.recordUuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categorySlug => $composableBuilder(
      column: $table.categorySlug, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get otherName => $composableBuilder(
      column: $table.otherName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recordUuid => $composableBuilder(
      column: $table.recordUuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categorySlug => $composableBuilder(
      column: $table.categorySlug,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get otherName =>
      $composableBuilder(column: $table.otherName, builder: (column) => column);

  GeneratedColumn<String> get recordUuid => $composableBuilder(
      column: $table.recordUuid, builder: (column) => column);

  GeneratedColumn<int> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get categorySlug => $composableBuilder(
      column: $table.categorySlug, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$CategoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CategoriesTable,
    Category,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (Category, BaseReferences<_$AppDatabase, $CategoriesTable, Category>),
    Category,
    PrefetchHooks Function()> {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> otherName = const Value.absent(),
            Value<String?> recordUuid = const Value.absent(),
            Value<int?> branchId = const Value.absent(),
            Value<String?> categorySlug = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
          }) =>
              CategoriesCompanion(
            id: id,
            name: name,
            otherName: otherName,
            recordUuid: recordUuid,
            branchId: branchId,
            categorySlug: categorySlug,
            deletedAt: deletedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required String otherName,
            Value<String?> recordUuid = const Value.absent(),
            Value<int?> branchId = const Value.absent(),
            Value<String?> categorySlug = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
          }) =>
              CategoriesCompanion.insert(
            id: id,
            name: name,
            otherName: otherName,
            recordUuid: recordUuid,
            branchId: branchId,
            categorySlug: categorySlug,
            deletedAt: deletedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CategoriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CategoriesTable,
    Category,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (Category, BaseReferences<_$AppDatabase, $CategoriesTable, Category>),
    Category,
    PrefetchHooks Function()>;
typedef $$KitchensTableCreateCompanionBuilder = KitchensCompanion Function({
  Value<int> id,
  required String name,
  Value<String?> printerIp,
  Value<int> printerPort,
  Value<String?> recordUuid,
  Value<int?> branchId,
  Value<String?> printerDetails,
  Value<String?> printerType,
  Value<DateTime?> deletedAt,
});
typedef $$KitchensTableUpdateCompanionBuilder = KitchensCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String?> printerIp,
  Value<int> printerPort,
  Value<String?> recordUuid,
  Value<int?> branchId,
  Value<String?> printerDetails,
  Value<String?> printerType,
  Value<DateTime?> deletedAt,
});

class $$KitchensTableFilterComposer
    extends Composer<_$AppDatabase, $KitchensTable> {
  $$KitchensTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get printerIp => $composableBuilder(
      column: $table.printerIp, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get printerPort => $composableBuilder(
      column: $table.printerPort, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recordUuid => $composableBuilder(
      column: $table.recordUuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get printerDetails => $composableBuilder(
      column: $table.printerDetails,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get printerType => $composableBuilder(
      column: $table.printerType, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));
}

class $$KitchensTableOrderingComposer
    extends Composer<_$AppDatabase, $KitchensTable> {
  $$KitchensTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get printerIp => $composableBuilder(
      column: $table.printerIp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get printerPort => $composableBuilder(
      column: $table.printerPort, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recordUuid => $composableBuilder(
      column: $table.recordUuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get printerDetails => $composableBuilder(
      column: $table.printerDetails,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get printerType => $composableBuilder(
      column: $table.printerType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$KitchensTableAnnotationComposer
    extends Composer<_$AppDatabase, $KitchensTable> {
  $$KitchensTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get printerIp =>
      $composableBuilder(column: $table.printerIp, builder: (column) => column);

  GeneratedColumn<int> get printerPort => $composableBuilder(
      column: $table.printerPort, builder: (column) => column);

  GeneratedColumn<String> get recordUuid => $composableBuilder(
      column: $table.recordUuid, builder: (column) => column);

  GeneratedColumn<int> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get printerDetails => $composableBuilder(
      column: $table.printerDetails, builder: (column) => column);

  GeneratedColumn<String> get printerType => $composableBuilder(
      column: $table.printerType, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$KitchensTableTableManager extends RootTableManager<
    _$AppDatabase,
    $KitchensTable,
    Kitchen,
    $$KitchensTableFilterComposer,
    $$KitchensTableOrderingComposer,
    $$KitchensTableAnnotationComposer,
    $$KitchensTableCreateCompanionBuilder,
    $$KitchensTableUpdateCompanionBuilder,
    (Kitchen, BaseReferences<_$AppDatabase, $KitchensTable, Kitchen>),
    Kitchen,
    PrefetchHooks Function()> {
  $$KitchensTableTableManager(_$AppDatabase db, $KitchensTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KitchensTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KitchensTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KitchensTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> printerIp = const Value.absent(),
            Value<int> printerPort = const Value.absent(),
            Value<String?> recordUuid = const Value.absent(),
            Value<int?> branchId = const Value.absent(),
            Value<String?> printerDetails = const Value.absent(),
            Value<String?> printerType = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
          }) =>
              KitchensCompanion(
            id: id,
            name: name,
            printerIp: printerIp,
            printerPort: printerPort,
            recordUuid: recordUuid,
            branchId: branchId,
            printerDetails: printerDetails,
            printerType: printerType,
            deletedAt: deletedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String?> printerIp = const Value.absent(),
            Value<int> printerPort = const Value.absent(),
            Value<String?> recordUuid = const Value.absent(),
            Value<int?> branchId = const Value.absent(),
            Value<String?> printerDetails = const Value.absent(),
            Value<String?> printerType = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
          }) =>
              KitchensCompanion.insert(
            id: id,
            name: name,
            printerIp: printerIp,
            printerPort: printerPort,
            recordUuid: recordUuid,
            branchId: branchId,
            printerDetails: printerDetails,
            printerType: printerType,
            deletedAt: deletedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$KitchensTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $KitchensTable,
    Kitchen,
    $$KitchensTableFilterComposer,
    $$KitchensTableOrderingComposer,
    $$KitchensTableAnnotationComposer,
    $$KitchensTableCreateCompanionBuilder,
    $$KitchensTableUpdateCompanionBuilder,
    (Kitchen, BaseReferences<_$AppDatabase, $KitchensTable, Kitchen>),
    Kitchen,
    PrefetchHooks Function()>;
typedef $$KitchenPrintersTableCreateCompanionBuilder = KitchenPrintersCompanion
    Function({
  Value<int> kitchenId,
  required String printerIp,
  Value<int> printerPort,
});
typedef $$KitchenPrintersTableUpdateCompanionBuilder = KitchenPrintersCompanion
    Function({
  Value<int> kitchenId,
  Value<String> printerIp,
  Value<int> printerPort,
});

class $$KitchenPrintersTableFilterComposer
    extends Composer<_$AppDatabase, $KitchenPrintersTable> {
  $$KitchenPrintersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get kitchenId => $composableBuilder(
      column: $table.kitchenId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get printerIp => $composableBuilder(
      column: $table.printerIp, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get printerPort => $composableBuilder(
      column: $table.printerPort, builder: (column) => ColumnFilters(column));
}

class $$KitchenPrintersTableOrderingComposer
    extends Composer<_$AppDatabase, $KitchenPrintersTable> {
  $$KitchenPrintersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get kitchenId => $composableBuilder(
      column: $table.kitchenId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get printerIp => $composableBuilder(
      column: $table.printerIp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get printerPort => $composableBuilder(
      column: $table.printerPort, builder: (column) => ColumnOrderings(column));
}

class $$KitchenPrintersTableAnnotationComposer
    extends Composer<_$AppDatabase, $KitchenPrintersTable> {
  $$KitchenPrintersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get kitchenId =>
      $composableBuilder(column: $table.kitchenId, builder: (column) => column);

  GeneratedColumn<String> get printerIp =>
      $composableBuilder(column: $table.printerIp, builder: (column) => column);

  GeneratedColumn<int> get printerPort => $composableBuilder(
      column: $table.printerPort, builder: (column) => column);
}

class $$KitchenPrintersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $KitchenPrintersTable,
    KitchenPrinter,
    $$KitchenPrintersTableFilterComposer,
    $$KitchenPrintersTableOrderingComposer,
    $$KitchenPrintersTableAnnotationComposer,
    $$KitchenPrintersTableCreateCompanionBuilder,
    $$KitchenPrintersTableUpdateCompanionBuilder,
    (
      KitchenPrinter,
      BaseReferences<_$AppDatabase, $KitchenPrintersTable, KitchenPrinter>
    ),
    KitchenPrinter,
    PrefetchHooks Function()> {
  $$KitchenPrintersTableTableManager(
      _$AppDatabase db, $KitchenPrintersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KitchenPrintersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KitchenPrintersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KitchenPrintersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> kitchenId = const Value.absent(),
            Value<String> printerIp = const Value.absent(),
            Value<int> printerPort = const Value.absent(),
          }) =>
              KitchenPrintersCompanion(
            kitchenId: kitchenId,
            printerIp: printerIp,
            printerPort: printerPort,
          ),
          createCompanionCallback: ({
            Value<int> kitchenId = const Value.absent(),
            required String printerIp,
            Value<int> printerPort = const Value.absent(),
          }) =>
              KitchenPrintersCompanion.insert(
            kitchenId: kitchenId,
            printerIp: printerIp,
            printerPort: printerPort,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$KitchenPrintersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $KitchenPrintersTable,
    KitchenPrinter,
    $$KitchenPrintersTableFilterComposer,
    $$KitchenPrintersTableOrderingComposer,
    $$KitchenPrintersTableAnnotationComposer,
    $$KitchenPrintersTableCreateCompanionBuilder,
    $$KitchenPrintersTableUpdateCompanionBuilder,
    (
      KitchenPrinter,
      BaseReferences<_$AppDatabase, $KitchenPrintersTable, KitchenPrinter>
    ),
    KitchenPrinter,
    PrefetchHooks Function()>;
typedef $$ItemsTableCreateCompanionBuilder = ItemsCompanion Function({
  Value<int> id,
  required String name,
  required String otherName,
  required String sku,
  required double price,
  required int stock,
  Value<bool> stockEnabled,
  Value<String?> imagePath,
  Value<String?> localImagePath,
  required String categoryName,
  required String categoryOtherName,
  required String barcode,
  required int categoryId,
  Value<int?> kitchenId,
  Value<String?> kitchenName,
  Value<String?> deliveryPartner,
});
typedef $$ItemsTableUpdateCompanionBuilder = ItemsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> otherName,
  Value<String> sku,
  Value<double> price,
  Value<int> stock,
  Value<bool> stockEnabled,
  Value<String?> imagePath,
  Value<String?> localImagePath,
  Value<String> categoryName,
  Value<String> categoryOtherName,
  Value<String> barcode,
  Value<int> categoryId,
  Value<int?> kitchenId,
  Value<String?> kitchenName,
  Value<String?> deliveryPartner,
});

final class $$ItemsTableReferences
    extends BaseReferences<_$AppDatabase, $ItemsTable, Item> {
  $$ItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CartItemsTable, List<CartItem>>
      _cartItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.cartItems,
          aliasName: $_aliasNameGenerator(db.items.id, db.cartItems.itemId));

  $$CartItemsTableProcessedTableManager get cartItemsRefs {
    final manager = $$CartItemsTableTableManager($_db, $_db.cartItems)
        .filter((f) => f.itemId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_cartItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ItemsTableFilterComposer extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get otherName => $composableBuilder(
      column: $table.otherName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sku => $composableBuilder(
      column: $table.sku, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get stock => $composableBuilder(
      column: $table.stock, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get stockEnabled => $composableBuilder(
      column: $table.stockEnabled, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localImagePath => $composableBuilder(
      column: $table.localImagePath,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryName => $composableBuilder(
      column: $table.categoryName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryOtherName => $composableBuilder(
      column: $table.categoryOtherName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get barcode => $composableBuilder(
      column: $table.barcode, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get kitchenId => $composableBuilder(
      column: $table.kitchenId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kitchenName => $composableBuilder(
      column: $table.kitchenName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deliveryPartner => $composableBuilder(
      column: $table.deliveryPartner,
      builder: (column) => ColumnFilters(column));

  Expression<bool> cartItemsRefs(
      Expression<bool> Function($$CartItemsTableFilterComposer f) f) {
    final $$CartItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.cartItems,
        getReferencedColumn: (t) => t.itemId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CartItemsTableFilterComposer(
              $db: $db,
              $table: $db.cartItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get otherName => $composableBuilder(
      column: $table.otherName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sku => $composableBuilder(
      column: $table.sku, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get stock => $composableBuilder(
      column: $table.stock, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get stockEnabled => $composableBuilder(
      column: $table.stockEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localImagePath => $composableBuilder(
      column: $table.localImagePath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryName => $composableBuilder(
      column: $table.categoryName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryOtherName => $composableBuilder(
      column: $table.categoryOtherName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get barcode => $composableBuilder(
      column: $table.barcode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get kitchenId => $composableBuilder(
      column: $table.kitchenId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kitchenName => $composableBuilder(
      column: $table.kitchenName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deliveryPartner => $composableBuilder(
      column: $table.deliveryPartner,
      builder: (column) => ColumnOrderings(column));
}

class $$ItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get otherName =>
      $composableBuilder(column: $table.otherName, builder: (column) => column);

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<int> get stock =>
      $composableBuilder(column: $table.stock, builder: (column) => column);

  GeneratedColumn<bool> get stockEnabled => $composableBuilder(
      column: $table.stockEnabled, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<String> get localImagePath => $composableBuilder(
      column: $table.localImagePath, builder: (column) => column);

  GeneratedColumn<String> get categoryName => $composableBuilder(
      column: $table.categoryName, builder: (column) => column);

  GeneratedColumn<String> get categoryOtherName => $composableBuilder(
      column: $table.categoryOtherName, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<int> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => column);

  GeneratedColumn<int> get kitchenId =>
      $composableBuilder(column: $table.kitchenId, builder: (column) => column);

  GeneratedColumn<String> get kitchenName => $composableBuilder(
      column: $table.kitchenName, builder: (column) => column);

  GeneratedColumn<String> get deliveryPartner => $composableBuilder(
      column: $table.deliveryPartner, builder: (column) => column);

  Expression<T> cartItemsRefs<T extends Object>(
      Expression<T> Function($$CartItemsTableAnnotationComposer a) f) {
    final $$CartItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.cartItems,
        getReferencedColumn: (t) => t.itemId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CartItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.cartItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ItemsTable,
    Item,
    $$ItemsTableFilterComposer,
    $$ItemsTableOrderingComposer,
    $$ItemsTableAnnotationComposer,
    $$ItemsTableCreateCompanionBuilder,
    $$ItemsTableUpdateCompanionBuilder,
    (Item, $$ItemsTableReferences),
    Item,
    PrefetchHooks Function({bool cartItemsRefs})> {
  $$ItemsTableTableManager(_$AppDatabase db, $ItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> otherName = const Value.absent(),
            Value<String> sku = const Value.absent(),
            Value<double> price = const Value.absent(),
            Value<int> stock = const Value.absent(),
            Value<bool> stockEnabled = const Value.absent(),
            Value<String?> imagePath = const Value.absent(),
            Value<String?> localImagePath = const Value.absent(),
            Value<String> categoryName = const Value.absent(),
            Value<String> categoryOtherName = const Value.absent(),
            Value<String> barcode = const Value.absent(),
            Value<int> categoryId = const Value.absent(),
            Value<int?> kitchenId = const Value.absent(),
            Value<String?> kitchenName = const Value.absent(),
            Value<String?> deliveryPartner = const Value.absent(),
          }) =>
              ItemsCompanion(
            id: id,
            name: name,
            otherName: otherName,
            sku: sku,
            price: price,
            stock: stock,
            stockEnabled: stockEnabled,
            imagePath: imagePath,
            localImagePath: localImagePath,
            categoryName: categoryName,
            categoryOtherName: categoryOtherName,
            barcode: barcode,
            categoryId: categoryId,
            kitchenId: kitchenId,
            kitchenName: kitchenName,
            deliveryPartner: deliveryPartner,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required String otherName,
            required String sku,
            required double price,
            required int stock,
            Value<bool> stockEnabled = const Value.absent(),
            Value<String?> imagePath = const Value.absent(),
            Value<String?> localImagePath = const Value.absent(),
            required String categoryName,
            required String categoryOtherName,
            required String barcode,
            required int categoryId,
            Value<int?> kitchenId = const Value.absent(),
            Value<String?> kitchenName = const Value.absent(),
            Value<String?> deliveryPartner = const Value.absent(),
          }) =>
              ItemsCompanion.insert(
            id: id,
            name: name,
            otherName: otherName,
            sku: sku,
            price: price,
            stock: stock,
            stockEnabled: stockEnabled,
            imagePath: imagePath,
            localImagePath: localImagePath,
            categoryName: categoryName,
            categoryOtherName: categoryOtherName,
            barcode: barcode,
            categoryId: categoryId,
            kitchenId: kitchenId,
            kitchenName: kitchenName,
            deliveryPartner: deliveryPartner,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ItemsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({cartItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (cartItemsRefs) db.cartItems],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (cartItemsRefs)
                    await $_getPrefetchedData<Item, $ItemsTable, CartItem>(
                        currentTable: table,
                        referencedTable:
                            $$ItemsTableReferences._cartItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ItemsTableReferences(db, table, p0).cartItemsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.itemId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ItemsTable,
    Item,
    $$ItemsTableFilterComposer,
    $$ItemsTableOrderingComposer,
    $$ItemsTableAnnotationComposer,
    $$ItemsTableCreateCompanionBuilder,
    $$ItemsTableUpdateCompanionBuilder,
    (Item, $$ItemsTableReferences),
    Item,
    PrefetchHooks Function({bool cartItemsRefs})>;
typedef $$ItemVariantsTableCreateCompanionBuilder = ItemVariantsCompanion
    Function({
  Value<int> id,
  required int itemId,
  required String name,
  required double price,
});
typedef $$ItemVariantsTableUpdateCompanionBuilder = ItemVariantsCompanion
    Function({
  Value<int> id,
  Value<int> itemId,
  Value<String> name,
  Value<double> price,
});

final class $$ItemVariantsTableReferences
    extends BaseReferences<_$AppDatabase, $ItemVariantsTable, ItemVariant> {
  $$ItemVariantsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CartItemsTable, List<CartItem>>
      _cartItemsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.cartItems,
              aliasName: $_aliasNameGenerator(
                  db.itemVariants.id, db.cartItems.itemVariantId));

  $$CartItemsTableProcessedTableManager get cartItemsRefs {
    final manager = $$CartItemsTableTableManager($_db, $_db.cartItems)
        .filter((f) => f.itemVariantId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_cartItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ItemVariantsTableFilterComposer
    extends Composer<_$AppDatabase, $ItemVariantsTable> {
  $$ItemVariantsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnFilters(column));

  Expression<bool> cartItemsRefs(
      Expression<bool> Function($$CartItemsTableFilterComposer f) f) {
    final $$CartItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.cartItems,
        getReferencedColumn: (t) => t.itemVariantId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CartItemsTableFilterComposer(
              $db: $db,
              $table: $db.cartItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ItemVariantsTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemVariantsTable> {
  $$ItemVariantsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnOrderings(column));
}

class $$ItemVariantsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemVariantsTable> {
  $$ItemVariantsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  Expression<T> cartItemsRefs<T extends Object>(
      Expression<T> Function($$CartItemsTableAnnotationComposer a) f) {
    final $$CartItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.cartItems,
        getReferencedColumn: (t) => t.itemVariantId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CartItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.cartItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ItemVariantsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ItemVariantsTable,
    ItemVariant,
    $$ItemVariantsTableFilterComposer,
    $$ItemVariantsTableOrderingComposer,
    $$ItemVariantsTableAnnotationComposer,
    $$ItemVariantsTableCreateCompanionBuilder,
    $$ItemVariantsTableUpdateCompanionBuilder,
    (ItemVariant, $$ItemVariantsTableReferences),
    ItemVariant,
    PrefetchHooks Function({bool cartItemsRefs})> {
  $$ItemVariantsTableTableManager(_$AppDatabase db, $ItemVariantsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemVariantsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemVariantsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemVariantsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> itemId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<double> price = const Value.absent(),
          }) =>
              ItemVariantsCompanion(
            id: id,
            itemId: itemId,
            name: name,
            price: price,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int itemId,
            required String name,
            required double price,
          }) =>
              ItemVariantsCompanion.insert(
            id: id,
            itemId: itemId,
            name: name,
            price: price,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ItemVariantsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({cartItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (cartItemsRefs) db.cartItems],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (cartItemsRefs)
                    await $_getPrefetchedData<ItemVariant, $ItemVariantsTable,
                            CartItem>(
                        currentTable: table,
                        referencedTable: $$ItemVariantsTableReferences
                            ._cartItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ItemVariantsTableReferences(db, table, p0)
                                .cartItemsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.itemVariantId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ItemVariantsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ItemVariantsTable,
    ItemVariant,
    $$ItemVariantsTableFilterComposer,
    $$ItemVariantsTableOrderingComposer,
    $$ItemVariantsTableAnnotationComposer,
    $$ItemVariantsTableCreateCompanionBuilder,
    $$ItemVariantsTableUpdateCompanionBuilder,
    (ItemVariant, $$ItemVariantsTableReferences),
    ItemVariant,
    PrefetchHooks Function({bool cartItemsRefs})>;
typedef $$ItemToppingsTableCreateCompanionBuilder = ItemToppingsCompanion
    Function({
  Value<int> id,
  required int itemId,
  required String name,
  required double price,
  Value<int> maxQty,
  Value<int?> maximum,
});
typedef $$ItemToppingsTableUpdateCompanionBuilder = ItemToppingsCompanion
    Function({
  Value<int> id,
  Value<int> itemId,
  Value<String> name,
  Value<double> price,
  Value<int> maxQty,
  Value<int?> maximum,
});

final class $$ItemToppingsTableReferences
    extends BaseReferences<_$AppDatabase, $ItemToppingsTable, ItemTopping> {
  $$ItemToppingsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CartItemsTable, List<CartItem>>
      _cartItemsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.cartItems,
              aliasName: $_aliasNameGenerator(
                  db.itemToppings.id, db.cartItems.itemToppingId));

  $$CartItemsTableProcessedTableManager get cartItemsRefs {
    final manager = $$CartItemsTableTableManager($_db, $_db.cartItems)
        .filter((f) => f.itemToppingId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_cartItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ItemToppingsTableFilterComposer
    extends Composer<_$AppDatabase, $ItemToppingsTable> {
  $$ItemToppingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxQty => $composableBuilder(
      column: $table.maxQty, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maximum => $composableBuilder(
      column: $table.maximum, builder: (column) => ColumnFilters(column));

  Expression<bool> cartItemsRefs(
      Expression<bool> Function($$CartItemsTableFilterComposer f) f) {
    final $$CartItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.cartItems,
        getReferencedColumn: (t) => t.itemToppingId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CartItemsTableFilterComposer(
              $db: $db,
              $table: $db.cartItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ItemToppingsTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemToppingsTable> {
  $$ItemToppingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxQty => $composableBuilder(
      column: $table.maxQty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maximum => $composableBuilder(
      column: $table.maximum, builder: (column) => ColumnOrderings(column));
}

class $$ItemToppingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemToppingsTable> {
  $$ItemToppingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<int> get maxQty =>
      $composableBuilder(column: $table.maxQty, builder: (column) => column);

  GeneratedColumn<int> get maximum =>
      $composableBuilder(column: $table.maximum, builder: (column) => column);

  Expression<T> cartItemsRefs<T extends Object>(
      Expression<T> Function($$CartItemsTableAnnotationComposer a) f) {
    final $$CartItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.cartItems,
        getReferencedColumn: (t) => t.itemToppingId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CartItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.cartItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ItemToppingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ItemToppingsTable,
    ItemTopping,
    $$ItemToppingsTableFilterComposer,
    $$ItemToppingsTableOrderingComposer,
    $$ItemToppingsTableAnnotationComposer,
    $$ItemToppingsTableCreateCompanionBuilder,
    $$ItemToppingsTableUpdateCompanionBuilder,
    (ItemTopping, $$ItemToppingsTableReferences),
    ItemTopping,
    PrefetchHooks Function({bool cartItemsRefs})> {
  $$ItemToppingsTableTableManager(_$AppDatabase db, $ItemToppingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemToppingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemToppingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemToppingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> itemId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<double> price = const Value.absent(),
            Value<int> maxQty = const Value.absent(),
            Value<int?> maximum = const Value.absent(),
          }) =>
              ItemToppingsCompanion(
            id: id,
            itemId: itemId,
            name: name,
            price: price,
            maxQty: maxQty,
            maximum: maximum,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int itemId,
            required String name,
            required double price,
            Value<int> maxQty = const Value.absent(),
            Value<int?> maximum = const Value.absent(),
          }) =>
              ItemToppingsCompanion.insert(
            id: id,
            itemId: itemId,
            name: name,
            price: price,
            maxQty: maxQty,
            maximum: maximum,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ItemToppingsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({cartItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (cartItemsRefs) db.cartItems],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (cartItemsRefs)
                    await $_getPrefetchedData<ItemTopping, $ItemToppingsTable,
                            CartItem>(
                        currentTable: table,
                        referencedTable: $$ItemToppingsTableReferences
                            ._cartItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ItemToppingsTableReferences(db, table, p0)
                                .cartItemsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.itemToppingId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ItemToppingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ItemToppingsTable,
    ItemTopping,
    $$ItemToppingsTableFilterComposer,
    $$ItemToppingsTableOrderingComposer,
    $$ItemToppingsTableAnnotationComposer,
    $$ItemToppingsTableCreateCompanionBuilder,
    $$ItemToppingsTableUpdateCompanionBuilder,
    (ItemTopping, $$ItemToppingsTableReferences),
    ItemTopping,
    PrefetchHooks Function({bool cartItemsRefs})>;
typedef $$ToppingGroupsTableCreateCompanionBuilder = ToppingGroupsCompanion
    Function({
  Value<int> id,
  required int itemId,
  required String name,
  Value<int> min,
  Value<int> max,
});
typedef $$ToppingGroupsTableUpdateCompanionBuilder = ToppingGroupsCompanion
    Function({
  Value<int> id,
  Value<int> itemId,
  Value<String> name,
  Value<int> min,
  Value<int> max,
});

class $$ToppingGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $ToppingGroupsTable> {
  $$ToppingGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get min => $composableBuilder(
      column: $table.min, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get max => $composableBuilder(
      column: $table.max, builder: (column) => ColumnFilters(column));
}

class $$ToppingGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $ToppingGroupsTable> {
  $$ToppingGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get min => $composableBuilder(
      column: $table.min, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get max => $composableBuilder(
      column: $table.max, builder: (column) => ColumnOrderings(column));
}

class $$ToppingGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ToppingGroupsTable> {
  $$ToppingGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get min =>
      $composableBuilder(column: $table.min, builder: (column) => column);

  GeneratedColumn<int> get max =>
      $composableBuilder(column: $table.max, builder: (column) => column);
}

class $$ToppingGroupsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ToppingGroupsTable,
    ToppingGroup,
    $$ToppingGroupsTableFilterComposer,
    $$ToppingGroupsTableOrderingComposer,
    $$ToppingGroupsTableAnnotationComposer,
    $$ToppingGroupsTableCreateCompanionBuilder,
    $$ToppingGroupsTableUpdateCompanionBuilder,
    (
      ToppingGroup,
      BaseReferences<_$AppDatabase, $ToppingGroupsTable, ToppingGroup>
    ),
    ToppingGroup,
    PrefetchHooks Function()> {
  $$ToppingGroupsTableTableManager(_$AppDatabase db, $ToppingGroupsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ToppingGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ToppingGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ToppingGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> itemId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> min = const Value.absent(),
            Value<int> max = const Value.absent(),
          }) =>
              ToppingGroupsCompanion(
            id: id,
            itemId: itemId,
            name: name,
            min: min,
            max: max,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int itemId,
            required String name,
            Value<int> min = const Value.absent(),
            Value<int> max = const Value.absent(),
          }) =>
              ToppingGroupsCompanion.insert(
            id: id,
            itemId: itemId,
            name: name,
            min: min,
            max: max,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ToppingGroupsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ToppingGroupsTable,
    ToppingGroup,
    $$ToppingGroupsTableFilterComposer,
    $$ToppingGroupsTableOrderingComposer,
    $$ToppingGroupsTableAnnotationComposer,
    $$ToppingGroupsTableCreateCompanionBuilder,
    $$ToppingGroupsTableUpdateCompanionBuilder,
    (
      ToppingGroup,
      BaseReferences<_$AppDatabase, $ToppingGroupsTable, ToppingGroup>
    ),
    ToppingGroup,
    PrefetchHooks Function()>;
typedef $$SessionsTableCreateCompanionBuilder = SessionsCompanion Function({
  Value<int> id,
  required int userId,
  Value<int> branchId,
  required String role,
  Value<int?> activeCartId,
});
typedef $$SessionsTableUpdateCompanionBuilder = SessionsCompanion Function({
  Value<int> id,
  Value<int> userId,
  Value<int> branchId,
  Value<String> role,
  Value<int?> activeCartId,
});

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get activeCartId => $composableBuilder(
      column: $table.activeCartId, builder: (column) => ColumnFilters(column));
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get activeCartId => $composableBuilder(
      column: $table.activeCartId,
      builder: (column) => ColumnOrderings(column));
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<int> get activeCartId => $composableBuilder(
      column: $table.activeCartId, builder: (column) => column);
}

class $$SessionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SessionsTable,
    Session,
    $$SessionsTableFilterComposer,
    $$SessionsTableOrderingComposer,
    $$SessionsTableAnnotationComposer,
    $$SessionsTableCreateCompanionBuilder,
    $$SessionsTableUpdateCompanionBuilder,
    (Session, BaseReferences<_$AppDatabase, $SessionsTable, Session>),
    Session,
    PrefetchHooks Function()> {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> userId = const Value.absent(),
            Value<int> branchId = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<int?> activeCartId = const Value.absent(),
          }) =>
              SessionsCompanion(
            id: id,
            userId: userId,
            branchId: branchId,
            role: role,
            activeCartId: activeCartId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int userId,
            Value<int> branchId = const Value.absent(),
            required String role,
            Value<int?> activeCartId = const Value.absent(),
          }) =>
              SessionsCompanion.insert(
            id: id,
            userId: userId,
            branchId: branchId,
            role: role,
            activeCartId: activeCartId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SessionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SessionsTable,
    Session,
    $$SessionsTableFilterComposer,
    $$SessionsTableOrderingComposer,
    $$SessionsTableAnnotationComposer,
    $$SessionsTableCreateCompanionBuilder,
    $$SessionsTableUpdateCompanionBuilder,
    (Session, BaseReferences<_$AppDatabase, $SessionsTable, Session>),
    Session,
    PrefetchHooks Function()>;
typedef $$CartsTableCreateCompanionBuilder = CartsCompanion Function({
  Value<int> id,
  required String invoiceNumber,
  required DateTime createdAt,
  Value<String> orderType,
  Value<String?> deliveryPartner,
});
typedef $$CartsTableUpdateCompanionBuilder = CartsCompanion Function({
  Value<int> id,
  Value<String> invoiceNumber,
  Value<DateTime> createdAt,
  Value<String> orderType,
  Value<String?> deliveryPartner,
});

final class $$CartsTableReferences
    extends BaseReferences<_$AppDatabase, $CartsTable, Cart> {
  $$CartsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CartItemsTable, List<CartItem>>
      _cartItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.cartItems,
          aliasName: $_aliasNameGenerator(db.carts.id, db.cartItems.cartId));

  $$CartItemsTableProcessedTableManager get cartItemsRefs {
    final manager = $$CartItemsTableTableManager($_db, $_db.cartItems)
        .filter((f) => f.cartId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_cartItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$OrdersTable, List<Order>> _ordersRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.orders,
          aliasName: $_aliasNameGenerator(db.carts.id, db.orders.cartId));

  $$OrdersTableProcessedTableManager get ordersRefs {
    final manager = $$OrdersTableTableManager($_db, $_db.orders)
        .filter((f) => f.cartId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_ordersRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$CartsTableFilterComposer extends Composer<_$AppDatabase, $CartsTable> {
  $$CartsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get invoiceNumber => $composableBuilder(
      column: $table.invoiceNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get orderType => $composableBuilder(
      column: $table.orderType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deliveryPartner => $composableBuilder(
      column: $table.deliveryPartner,
      builder: (column) => ColumnFilters(column));

  Expression<bool> cartItemsRefs(
      Expression<bool> Function($$CartItemsTableFilterComposer f) f) {
    final $$CartItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.cartItems,
        getReferencedColumn: (t) => t.cartId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CartItemsTableFilterComposer(
              $db: $db,
              $table: $db.cartItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> ordersRefs(
      Expression<bool> Function($$OrdersTableFilterComposer f) f) {
    final $$OrdersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.cartId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableFilterComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CartsTableOrderingComposer
    extends Composer<_$AppDatabase, $CartsTable> {
  $$CartsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get invoiceNumber => $composableBuilder(
      column: $table.invoiceNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get orderType => $composableBuilder(
      column: $table.orderType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deliveryPartner => $composableBuilder(
      column: $table.deliveryPartner,
      builder: (column) => ColumnOrderings(column));
}

class $$CartsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CartsTable> {
  $$CartsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get invoiceNumber => $composableBuilder(
      column: $table.invoiceNumber, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get orderType =>
      $composableBuilder(column: $table.orderType, builder: (column) => column);

  GeneratedColumn<String> get deliveryPartner => $composableBuilder(
      column: $table.deliveryPartner, builder: (column) => column);

  Expression<T> cartItemsRefs<T extends Object>(
      Expression<T> Function($$CartItemsTableAnnotationComposer a) f) {
    final $$CartItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.cartItems,
        getReferencedColumn: (t) => t.cartId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CartItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.cartItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> ordersRefs<T extends Object>(
      Expression<T> Function($$OrdersTableAnnotationComposer a) f) {
    final $$OrdersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.cartId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableAnnotationComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CartsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CartsTable,
    Cart,
    $$CartsTableFilterComposer,
    $$CartsTableOrderingComposer,
    $$CartsTableAnnotationComposer,
    $$CartsTableCreateCompanionBuilder,
    $$CartsTableUpdateCompanionBuilder,
    (Cart, $$CartsTableReferences),
    Cart,
    PrefetchHooks Function({bool cartItemsRefs, bool ordersRefs})> {
  $$CartsTableTableManager(_$AppDatabase db, $CartsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CartsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CartsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CartsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> invoiceNumber = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String> orderType = const Value.absent(),
            Value<String?> deliveryPartner = const Value.absent(),
          }) =>
              CartsCompanion(
            id: id,
            invoiceNumber: invoiceNumber,
            createdAt: createdAt,
            orderType: orderType,
            deliveryPartner: deliveryPartner,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String invoiceNumber,
            required DateTime createdAt,
            Value<String> orderType = const Value.absent(),
            Value<String?> deliveryPartner = const Value.absent(),
          }) =>
              CartsCompanion.insert(
            id: id,
            invoiceNumber: invoiceNumber,
            createdAt: createdAt,
            orderType: orderType,
            deliveryPartner: deliveryPartner,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$CartsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({cartItemsRefs = false, ordersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (cartItemsRefs) db.cartItems,
                if (ordersRefs) db.orders
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (cartItemsRefs)
                    await $_getPrefetchedData<Cart, $CartsTable, CartItem>(
                        currentTable: table,
                        referencedTable:
                            $$CartsTableReferences._cartItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CartsTableReferences(db, table, p0).cartItemsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.cartId == item.id),
                        typedResults: items),
                  if (ordersRefs)
                    await $_getPrefetchedData<Cart, $CartsTable, Order>(
                        currentTable: table,
                        referencedTable:
                            $$CartsTableReferences._ordersRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CartsTableReferences(db, table, p0).ordersRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.cartId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$CartsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CartsTable,
    Cart,
    $$CartsTableFilterComposer,
    $$CartsTableOrderingComposer,
    $$CartsTableAnnotationComposer,
    $$CartsTableCreateCompanionBuilder,
    $$CartsTableUpdateCompanionBuilder,
    (Cart, $$CartsTableReferences),
    Cart,
    PrefetchHooks Function({bool cartItemsRefs, bool ordersRefs})>;
typedef $$CartItemsTableCreateCompanionBuilder = CartItemsCompanion Function({
  Value<int> id,
  required int cartId,
  required int itemId,
  Value<int?> itemVariantId,
  Value<int?> itemToppingId,
  required int quantity,
  Value<double> total,
  Value<double> discount,
  Value<String?> discountType,
  Value<String?> notes,
});
typedef $$CartItemsTableUpdateCompanionBuilder = CartItemsCompanion Function({
  Value<int> id,
  Value<int> cartId,
  Value<int> itemId,
  Value<int?> itemVariantId,
  Value<int?> itemToppingId,
  Value<int> quantity,
  Value<double> total,
  Value<double> discount,
  Value<String?> discountType,
  Value<String?> notes,
});

final class $$CartItemsTableReferences
    extends BaseReferences<_$AppDatabase, $CartItemsTable, CartItem> {
  $$CartItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CartsTable _cartIdTable(_$AppDatabase db) => db.carts
      .createAlias($_aliasNameGenerator(db.cartItems.cartId, db.carts.id));

  $$CartsTableProcessedTableManager get cartId {
    final $_column = $_itemColumn<int>('cart_id')!;

    final manager = $$CartsTableTableManager($_db, $_db.carts)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cartIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ItemsTable _itemIdTable(_$AppDatabase db) => db.items
      .createAlias($_aliasNameGenerator(db.cartItems.itemId, db.items.id));

  $$ItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<int>('item_id')!;

    final manager = $$ItemsTableTableManager($_db, $_db.items)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ItemVariantsTable _itemVariantIdTable(_$AppDatabase db) =>
      db.itemVariants.createAlias(
          $_aliasNameGenerator(db.cartItems.itemVariantId, db.itemVariants.id));

  $$ItemVariantsTableProcessedTableManager? get itemVariantId {
    final $_column = $_itemColumn<int>('item_variant_id');
    if ($_column == null) return null;
    final manager = $$ItemVariantsTableTableManager($_db, $_db.itemVariants)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemVariantIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ItemToppingsTable _itemToppingIdTable(_$AppDatabase db) =>
      db.itemToppings.createAlias(
          $_aliasNameGenerator(db.cartItems.itemToppingId, db.itemToppings.id));

  $$ItemToppingsTableProcessedTableManager? get itemToppingId {
    final $_column = $_itemColumn<int>('item_topping_id');
    if ($_column == null) return null;
    final manager = $$ItemToppingsTableTableManager($_db, $_db.itemToppings)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemToppingIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$CartItemsTableFilterComposer
    extends Composer<_$AppDatabase, $CartItemsTable> {
  $$CartItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get total => $composableBuilder(
      column: $table.total, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get discount => $composableBuilder(
      column: $table.discount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get discountType => $composableBuilder(
      column: $table.discountType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  $$CartsTableFilterComposer get cartId {
    final $$CartsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cartId,
        referencedTable: $db.carts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CartsTableFilterComposer(
              $db: $db,
              $table: $db.carts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ItemsTableFilterComposer get itemId {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.itemId,
        referencedTable: $db.items,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ItemsTableFilterComposer(
              $db: $db,
              $table: $db.items,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ItemVariantsTableFilterComposer get itemVariantId {
    final $$ItemVariantsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.itemVariantId,
        referencedTable: $db.itemVariants,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ItemVariantsTableFilterComposer(
              $db: $db,
              $table: $db.itemVariants,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ItemToppingsTableFilterComposer get itemToppingId {
    final $$ItemToppingsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.itemToppingId,
        referencedTable: $db.itemToppings,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ItemToppingsTableFilterComposer(
              $db: $db,
              $table: $db.itemToppings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CartItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $CartItemsTable> {
  $$CartItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get total => $composableBuilder(
      column: $table.total, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get discount => $composableBuilder(
      column: $table.discount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get discountType => $composableBuilder(
      column: $table.discountType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  $$CartsTableOrderingComposer get cartId {
    final $$CartsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cartId,
        referencedTable: $db.carts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CartsTableOrderingComposer(
              $db: $db,
              $table: $db.carts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ItemsTableOrderingComposer get itemId {
    final $$ItemsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.itemId,
        referencedTable: $db.items,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ItemsTableOrderingComposer(
              $db: $db,
              $table: $db.items,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ItemVariantsTableOrderingComposer get itemVariantId {
    final $$ItemVariantsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.itemVariantId,
        referencedTable: $db.itemVariants,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ItemVariantsTableOrderingComposer(
              $db: $db,
              $table: $db.itemVariants,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ItemToppingsTableOrderingComposer get itemToppingId {
    final $$ItemToppingsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.itemToppingId,
        referencedTable: $db.itemToppings,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ItemToppingsTableOrderingComposer(
              $db: $db,
              $table: $db.itemToppings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CartItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CartItemsTable> {
  $$CartItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<double> get discount =>
      $composableBuilder(column: $table.discount, builder: (column) => column);

  GeneratedColumn<String> get discountType => $composableBuilder(
      column: $table.discountType, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  $$CartsTableAnnotationComposer get cartId {
    final $$CartsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cartId,
        referencedTable: $db.carts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CartsTableAnnotationComposer(
              $db: $db,
              $table: $db.carts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ItemsTableAnnotationComposer get itemId {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.itemId,
        referencedTable: $db.items,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.items,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ItemVariantsTableAnnotationComposer get itemVariantId {
    final $$ItemVariantsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.itemVariantId,
        referencedTable: $db.itemVariants,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ItemVariantsTableAnnotationComposer(
              $db: $db,
              $table: $db.itemVariants,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ItemToppingsTableAnnotationComposer get itemToppingId {
    final $$ItemToppingsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.itemToppingId,
        referencedTable: $db.itemToppings,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ItemToppingsTableAnnotationComposer(
              $db: $db,
              $table: $db.itemToppings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CartItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CartItemsTable,
    CartItem,
    $$CartItemsTableFilterComposer,
    $$CartItemsTableOrderingComposer,
    $$CartItemsTableAnnotationComposer,
    $$CartItemsTableCreateCompanionBuilder,
    $$CartItemsTableUpdateCompanionBuilder,
    (CartItem, $$CartItemsTableReferences),
    CartItem,
    PrefetchHooks Function(
        {bool cartId, bool itemId, bool itemVariantId, bool itemToppingId})> {
  $$CartItemsTableTableManager(_$AppDatabase db, $CartItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CartItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CartItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CartItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> cartId = const Value.absent(),
            Value<int> itemId = const Value.absent(),
            Value<int?> itemVariantId = const Value.absent(),
            Value<int?> itemToppingId = const Value.absent(),
            Value<int> quantity = const Value.absent(),
            Value<double> total = const Value.absent(),
            Value<double> discount = const Value.absent(),
            Value<String?> discountType = const Value.absent(),
            Value<String?> notes = const Value.absent(),
          }) =>
              CartItemsCompanion(
            id: id,
            cartId: cartId,
            itemId: itemId,
            itemVariantId: itemVariantId,
            itemToppingId: itemToppingId,
            quantity: quantity,
            total: total,
            discount: discount,
            discountType: discountType,
            notes: notes,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int cartId,
            required int itemId,
            Value<int?> itemVariantId = const Value.absent(),
            Value<int?> itemToppingId = const Value.absent(),
            required int quantity,
            Value<double> total = const Value.absent(),
            Value<double> discount = const Value.absent(),
            Value<String?> discountType = const Value.absent(),
            Value<String?> notes = const Value.absent(),
          }) =>
              CartItemsCompanion.insert(
            id: id,
            cartId: cartId,
            itemId: itemId,
            itemVariantId: itemVariantId,
            itemToppingId: itemToppingId,
            quantity: quantity,
            total: total,
            discount: discount,
            discountType: discountType,
            notes: notes,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CartItemsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {cartId = false,
              itemId = false,
              itemVariantId = false,
              itemToppingId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (cartId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.cartId,
                    referencedTable:
                        $$CartItemsTableReferences._cartIdTable(db),
                    referencedColumn:
                        $$CartItemsTableReferences._cartIdTable(db).id,
                  ) as T;
                }
                if (itemId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.itemId,
                    referencedTable:
                        $$CartItemsTableReferences._itemIdTable(db),
                    referencedColumn:
                        $$CartItemsTableReferences._itemIdTable(db).id,
                  ) as T;
                }
                if (itemVariantId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.itemVariantId,
                    referencedTable:
                        $$CartItemsTableReferences._itemVariantIdTable(db),
                    referencedColumn:
                        $$CartItemsTableReferences._itemVariantIdTable(db).id,
                  ) as T;
                }
                if (itemToppingId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.itemToppingId,
                    referencedTable:
                        $$CartItemsTableReferences._itemToppingIdTable(db),
                    referencedColumn:
                        $$CartItemsTableReferences._itemToppingIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$CartItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CartItemsTable,
    CartItem,
    $$CartItemsTableFilterComposer,
    $$CartItemsTableOrderingComposer,
    $$CartItemsTableAnnotationComposer,
    $$CartItemsTableCreateCompanionBuilder,
    $$CartItemsTableUpdateCompanionBuilder,
    (CartItem, $$CartItemsTableReferences),
    CartItem,
    PrefetchHooks Function(
        {bool cartId, bool itemId, bool itemVariantId, bool itemToppingId})>;
typedef $$DriversTableCreateCompanionBuilder = DriversCompanion Function({
  Value<int> id,
  required String name,
});
typedef $$DriversTableUpdateCompanionBuilder = DriversCompanion Function({
  Value<int> id,
  Value<String> name,
});

final class $$DriversTableReferences
    extends BaseReferences<_$AppDatabase, $DriversTable, Driver> {
  $$DriversTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$OrdersTable, List<Order>> _ordersRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.orders,
          aliasName: $_aliasNameGenerator(db.drivers.id, db.orders.driverId));

  $$OrdersTableProcessedTableManager get ordersRefs {
    final manager = $$OrdersTableTableManager($_db, $_db.orders)
        .filter((f) => f.driverId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_ordersRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$DriversTableFilterComposer
    extends Composer<_$AppDatabase, $DriversTable> {
  $$DriversTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  Expression<bool> ordersRefs(
      Expression<bool> Function($$OrdersTableFilterComposer f) f) {
    final $$OrdersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.driverId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableFilterComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$DriversTableOrderingComposer
    extends Composer<_$AppDatabase, $DriversTable> {
  $$DriversTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));
}

class $$DriversTableAnnotationComposer
    extends Composer<_$AppDatabase, $DriversTable> {
  $$DriversTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  Expression<T> ordersRefs<T extends Object>(
      Expression<T> Function($$OrdersTableAnnotationComposer a) f) {
    final $$OrdersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.driverId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableAnnotationComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$DriversTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DriversTable,
    Driver,
    $$DriversTableFilterComposer,
    $$DriversTableOrderingComposer,
    $$DriversTableAnnotationComposer,
    $$DriversTableCreateCompanionBuilder,
    $$DriversTableUpdateCompanionBuilder,
    (Driver, $$DriversTableReferences),
    Driver,
    PrefetchHooks Function({bool ordersRefs})> {
  $$DriversTableTableManager(_$AppDatabase db, $DriversTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DriversTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DriversTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DriversTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
          }) =>
              DriversCompanion(
            id: id,
            name: name,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
          }) =>
              DriversCompanion.insert(
            id: id,
            name: name,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$DriversTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({ordersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (ordersRefs) db.orders],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (ordersRefs)
                    await $_getPrefetchedData<Driver, $DriversTable, Order>(
                        currentTable: table,
                        referencedTable:
                            $$DriversTableReferences._ordersRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$DriversTableReferences(db, table, p0).ordersRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.driverId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$DriversTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DriversTable,
    Driver,
    $$DriversTableFilterComposer,
    $$DriversTableOrderingComposer,
    $$DriversTableAnnotationComposer,
    $$DriversTableCreateCompanionBuilder,
    $$DriversTableUpdateCompanionBuilder,
    (Driver, $$DriversTableReferences),
    Driver,
    PrefetchHooks Function({bool ordersRefs})>;
typedef $$OrdersTableCreateCompanionBuilder = OrdersCompanion Function({
  Value<int> id,
  required int cartId,
  required String invoiceNumber,
  Value<String?> referenceNumber,
  required double totalAmount,
  Value<double> discountAmount,
  Value<String?> discountType,
  required double finalAmount,
  Value<String?> customerName,
  Value<String?> customerEmail,
  Value<String?> customerPhone,
  Value<String?> customerGender,
  Value<double> cashAmount,
  Value<double> creditAmount,
  Value<double> cardAmount,
  Value<double> onlineAmount,
  required DateTime createdAt,
  Value<String> status,
  Value<String?> orderType,
  Value<String?> deliveryPartner,
  Value<int?> driverId,
  Value<String?> driverName,
});
typedef $$OrdersTableUpdateCompanionBuilder = OrdersCompanion Function({
  Value<int> id,
  Value<int> cartId,
  Value<String> invoiceNumber,
  Value<String?> referenceNumber,
  Value<double> totalAmount,
  Value<double> discountAmount,
  Value<String?> discountType,
  Value<double> finalAmount,
  Value<String?> customerName,
  Value<String?> customerEmail,
  Value<String?> customerPhone,
  Value<String?> customerGender,
  Value<double> cashAmount,
  Value<double> creditAmount,
  Value<double> cardAmount,
  Value<double> onlineAmount,
  Value<DateTime> createdAt,
  Value<String> status,
  Value<String?> orderType,
  Value<String?> deliveryPartner,
  Value<int?> driverId,
  Value<String?> driverName,
});

final class $$OrdersTableReferences
    extends BaseReferences<_$AppDatabase, $OrdersTable, Order> {
  $$OrdersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CartsTable _cartIdTable(_$AppDatabase db) =>
      db.carts.createAlias($_aliasNameGenerator(db.orders.cartId, db.carts.id));

  $$CartsTableProcessedTableManager get cartId {
    final $_column = $_itemColumn<int>('cart_id')!;

    final manager = $$CartsTableTableManager($_db, $_db.carts)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cartIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $DriversTable _driverIdTable(_$AppDatabase db) => db.drivers
      .createAlias($_aliasNameGenerator(db.orders.driverId, db.drivers.id));

  $$DriversTableProcessedTableManager? get driverId {
    final $_column = $_itemColumn<int>('driver_id');
    if ($_column == null) return null;
    final manager = $$DriversTableTableManager($_db, $_db.drivers)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_driverIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$OrdersTableFilterComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get invoiceNumber => $composableBuilder(
      column: $table.invoiceNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get referenceNumber => $composableBuilder(
      column: $table.referenceNumber,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalAmount => $composableBuilder(
      column: $table.totalAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get discountAmount => $composableBuilder(
      column: $table.discountAmount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get discountType => $composableBuilder(
      column: $table.discountType, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get finalAmount => $composableBuilder(
      column: $table.finalAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customerName => $composableBuilder(
      column: $table.customerName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customerEmail => $composableBuilder(
      column: $table.customerEmail, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customerPhone => $composableBuilder(
      column: $table.customerPhone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customerGender => $composableBuilder(
      column: $table.customerGender,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get cashAmount => $composableBuilder(
      column: $table.cashAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get creditAmount => $composableBuilder(
      column: $table.creditAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get cardAmount => $composableBuilder(
      column: $table.cardAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get onlineAmount => $composableBuilder(
      column: $table.onlineAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get orderType => $composableBuilder(
      column: $table.orderType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deliveryPartner => $composableBuilder(
      column: $table.deliveryPartner,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get driverName => $composableBuilder(
      column: $table.driverName, builder: (column) => ColumnFilters(column));

  $$CartsTableFilterComposer get cartId {
    final $$CartsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cartId,
        referencedTable: $db.carts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CartsTableFilterComposer(
              $db: $db,
              $table: $db.carts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$DriversTableFilterComposer get driverId {
    final $$DriversTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.driverId,
        referencedTable: $db.drivers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DriversTableFilterComposer(
              $db: $db,
              $table: $db.drivers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$OrdersTableOrderingComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get invoiceNumber => $composableBuilder(
      column: $table.invoiceNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get referenceNumber => $composableBuilder(
      column: $table.referenceNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalAmount => $composableBuilder(
      column: $table.totalAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get discountAmount => $composableBuilder(
      column: $table.discountAmount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get discountType => $composableBuilder(
      column: $table.discountType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get finalAmount => $composableBuilder(
      column: $table.finalAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customerName => $composableBuilder(
      column: $table.customerName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customerEmail => $composableBuilder(
      column: $table.customerEmail,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customerPhone => $composableBuilder(
      column: $table.customerPhone,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customerGender => $composableBuilder(
      column: $table.customerGender,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get cashAmount => $composableBuilder(
      column: $table.cashAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get creditAmount => $composableBuilder(
      column: $table.creditAmount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get cardAmount => $composableBuilder(
      column: $table.cardAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get onlineAmount => $composableBuilder(
      column: $table.onlineAmount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get orderType => $composableBuilder(
      column: $table.orderType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deliveryPartner => $composableBuilder(
      column: $table.deliveryPartner,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get driverName => $composableBuilder(
      column: $table.driverName, builder: (column) => ColumnOrderings(column));

  $$CartsTableOrderingComposer get cartId {
    final $$CartsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cartId,
        referencedTable: $db.carts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CartsTableOrderingComposer(
              $db: $db,
              $table: $db.carts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$DriversTableOrderingComposer get driverId {
    final $$DriversTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.driverId,
        referencedTable: $db.drivers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DriversTableOrderingComposer(
              $db: $db,
              $table: $db.drivers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$OrdersTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get invoiceNumber => $composableBuilder(
      column: $table.invoiceNumber, builder: (column) => column);

  GeneratedColumn<String> get referenceNumber => $composableBuilder(
      column: $table.referenceNumber, builder: (column) => column);

  GeneratedColumn<double> get totalAmount => $composableBuilder(
      column: $table.totalAmount, builder: (column) => column);

  GeneratedColumn<double> get discountAmount => $composableBuilder(
      column: $table.discountAmount, builder: (column) => column);

  GeneratedColumn<String> get discountType => $composableBuilder(
      column: $table.discountType, builder: (column) => column);

  GeneratedColumn<double> get finalAmount => $composableBuilder(
      column: $table.finalAmount, builder: (column) => column);

  GeneratedColumn<String> get customerName => $composableBuilder(
      column: $table.customerName, builder: (column) => column);

  GeneratedColumn<String> get customerEmail => $composableBuilder(
      column: $table.customerEmail, builder: (column) => column);

  GeneratedColumn<String> get customerPhone => $composableBuilder(
      column: $table.customerPhone, builder: (column) => column);

  GeneratedColumn<String> get customerGender => $composableBuilder(
      column: $table.customerGender, builder: (column) => column);

  GeneratedColumn<double> get cashAmount => $composableBuilder(
      column: $table.cashAmount, builder: (column) => column);

  GeneratedColumn<double> get creditAmount => $composableBuilder(
      column: $table.creditAmount, builder: (column) => column);

  GeneratedColumn<double> get cardAmount => $composableBuilder(
      column: $table.cardAmount, builder: (column) => column);

  GeneratedColumn<double> get onlineAmount => $composableBuilder(
      column: $table.onlineAmount, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get orderType =>
      $composableBuilder(column: $table.orderType, builder: (column) => column);

  GeneratedColumn<String> get deliveryPartner => $composableBuilder(
      column: $table.deliveryPartner, builder: (column) => column);

  GeneratedColumn<String> get driverName => $composableBuilder(
      column: $table.driverName, builder: (column) => column);

  $$CartsTableAnnotationComposer get cartId {
    final $$CartsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cartId,
        referencedTable: $db.carts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CartsTableAnnotationComposer(
              $db: $db,
              $table: $db.carts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$DriversTableAnnotationComposer get driverId {
    final $$DriversTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.driverId,
        referencedTable: $db.drivers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DriversTableAnnotationComposer(
              $db: $db,
              $table: $db.drivers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$OrdersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OrdersTable,
    Order,
    $$OrdersTableFilterComposer,
    $$OrdersTableOrderingComposer,
    $$OrdersTableAnnotationComposer,
    $$OrdersTableCreateCompanionBuilder,
    $$OrdersTableUpdateCompanionBuilder,
    (Order, $$OrdersTableReferences),
    Order,
    PrefetchHooks Function({bool cartId, bool driverId})> {
  $$OrdersTableTableManager(_$AppDatabase db, $OrdersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrdersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrdersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrdersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> cartId = const Value.absent(),
            Value<String> invoiceNumber = const Value.absent(),
            Value<String?> referenceNumber = const Value.absent(),
            Value<double> totalAmount = const Value.absent(),
            Value<double> discountAmount = const Value.absent(),
            Value<String?> discountType = const Value.absent(),
            Value<double> finalAmount = const Value.absent(),
            Value<String?> customerName = const Value.absent(),
            Value<String?> customerEmail = const Value.absent(),
            Value<String?> customerPhone = const Value.absent(),
            Value<String?> customerGender = const Value.absent(),
            Value<double> cashAmount = const Value.absent(),
            Value<double> creditAmount = const Value.absent(),
            Value<double> cardAmount = const Value.absent(),
            Value<double> onlineAmount = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> orderType = const Value.absent(),
            Value<String?> deliveryPartner = const Value.absent(),
            Value<int?> driverId = const Value.absent(),
            Value<String?> driverName = const Value.absent(),
          }) =>
              OrdersCompanion(
            id: id,
            cartId: cartId,
            invoiceNumber: invoiceNumber,
            referenceNumber: referenceNumber,
            totalAmount: totalAmount,
            discountAmount: discountAmount,
            discountType: discountType,
            finalAmount: finalAmount,
            customerName: customerName,
            customerEmail: customerEmail,
            customerPhone: customerPhone,
            customerGender: customerGender,
            cashAmount: cashAmount,
            creditAmount: creditAmount,
            cardAmount: cardAmount,
            onlineAmount: onlineAmount,
            createdAt: createdAt,
            status: status,
            orderType: orderType,
            deliveryPartner: deliveryPartner,
            driverId: driverId,
            driverName: driverName,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int cartId,
            required String invoiceNumber,
            Value<String?> referenceNumber = const Value.absent(),
            required double totalAmount,
            Value<double> discountAmount = const Value.absent(),
            Value<String?> discountType = const Value.absent(),
            required double finalAmount,
            Value<String?> customerName = const Value.absent(),
            Value<String?> customerEmail = const Value.absent(),
            Value<String?> customerPhone = const Value.absent(),
            Value<String?> customerGender = const Value.absent(),
            Value<double> cashAmount = const Value.absent(),
            Value<double> creditAmount = const Value.absent(),
            Value<double> cardAmount = const Value.absent(),
            Value<double> onlineAmount = const Value.absent(),
            required DateTime createdAt,
            Value<String> status = const Value.absent(),
            Value<String?> orderType = const Value.absent(),
            Value<String?> deliveryPartner = const Value.absent(),
            Value<int?> driverId = const Value.absent(),
            Value<String?> driverName = const Value.absent(),
          }) =>
              OrdersCompanion.insert(
            id: id,
            cartId: cartId,
            invoiceNumber: invoiceNumber,
            referenceNumber: referenceNumber,
            totalAmount: totalAmount,
            discountAmount: discountAmount,
            discountType: discountType,
            finalAmount: finalAmount,
            customerName: customerName,
            customerEmail: customerEmail,
            customerPhone: customerPhone,
            customerGender: customerGender,
            cashAmount: cashAmount,
            creditAmount: creditAmount,
            cardAmount: cardAmount,
            onlineAmount: onlineAmount,
            createdAt: createdAt,
            status: status,
            orderType: orderType,
            deliveryPartner: deliveryPartner,
            driverId: driverId,
            driverName: driverName,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$OrdersTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({cartId = false, driverId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (cartId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.cartId,
                    referencedTable: $$OrdersTableReferences._cartIdTable(db),
                    referencedColumn:
                        $$OrdersTableReferences._cartIdTable(db).id,
                  ) as T;
                }
                if (driverId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.driverId,
                    referencedTable: $$OrdersTableReferences._driverIdTable(db),
                    referencedColumn:
                        $$OrdersTableReferences._driverIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$OrdersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OrdersTable,
    Order,
    $$OrdersTableFilterComposer,
    $$OrdersTableOrderingComposer,
    $$OrdersTableAnnotationComposer,
    $$OrdersTableCreateCompanionBuilder,
    $$OrdersTableUpdateCompanionBuilder,
    (Order, $$OrdersTableReferences),
    Order,
    PrefetchHooks Function({bool cartId, bool driverId})>;
typedef $$OrderLogsTableCreateCompanionBuilder = OrderLogsCompanion Function({
  Value<int> id,
  required String orderJson,
  Value<DateTime> createdAt,
  Value<bool> synced,
});
typedef $$OrderLogsTableUpdateCompanionBuilder = OrderLogsCompanion Function({
  Value<int> id,
  Value<String> orderJson,
  Value<DateTime> createdAt,
  Value<bool> synced,
});

class $$OrderLogsTableFilterComposer
    extends Composer<_$AppDatabase, $OrderLogsTable> {
  $$OrderLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get orderJson => $composableBuilder(
      column: $table.orderJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnFilters(column));
}

class $$OrderLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $OrderLogsTable> {
  $$OrderLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get orderJson => $composableBuilder(
      column: $table.orderJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnOrderings(column));
}

class $$OrderLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrderLogsTable> {
  $$OrderLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get orderJson =>
      $composableBuilder(column: $table.orderJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$OrderLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OrderLogsTable,
    OrderLog,
    $$OrderLogsTableFilterComposer,
    $$OrderLogsTableOrderingComposer,
    $$OrderLogsTableAnnotationComposer,
    $$OrderLogsTableCreateCompanionBuilder,
    $$OrderLogsTableUpdateCompanionBuilder,
    (OrderLog, BaseReferences<_$AppDatabase, $OrderLogsTable, OrderLog>),
    OrderLog,
    PrefetchHooks Function()> {
  $$OrderLogsTableTableManager(_$AppDatabase db, $OrderLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrderLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrderLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrderLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> orderJson = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
          }) =>
              OrderLogsCompanion(
            id: id,
            orderJson: orderJson,
            createdAt: createdAt,
            synced: synced,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String orderJson,
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
          }) =>
              OrderLogsCompanion.insert(
            id: id,
            orderJson: orderJson,
            createdAt: createdAt,
            synced: synced,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$OrderLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OrderLogsTable,
    OrderLog,
    $$OrderLogsTableFilterComposer,
    $$OrderLogsTableOrderingComposer,
    $$OrderLogsTableAnnotationComposer,
    $$OrderLogsTableCreateCompanionBuilder,
    $$OrderLogsTableUpdateCompanionBuilder,
    (OrderLog, BaseReferences<_$AppDatabase, $OrderLogsTable, OrderLog>),
    OrderLog,
    PrefetchHooks Function()>;
typedef $$CustomersTableCreateCompanionBuilder = CustomersCompanion Function({
  Value<int> id,
  Value<String?> serverId,
  required String name,
  Value<String?> email,
  Value<String?> phone,
  Value<String?> gender,
  Value<String?> address,
  Value<String?> cardNo,
  Value<String?> recordUuid,
  Value<int?> branchId,
  Value<String?> customerNumber,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> isSynced,
});
typedef $$CustomersTableUpdateCompanionBuilder = CustomersCompanion Function({
  Value<int> id,
  Value<String?> serverId,
  Value<String> name,
  Value<String?> email,
  Value<String?> phone,
  Value<String?> gender,
  Value<String?> address,
  Value<String?> cardNo,
  Value<String?> recordUuid,
  Value<int?> branchId,
  Value<String?> customerNumber,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> isSynced,
});

class $$CustomersTableFilterComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get gender => $composableBuilder(
      column: $table.gender, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cardNo => $composableBuilder(
      column: $table.cardNo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recordUuid => $composableBuilder(
      column: $table.recordUuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customerNumber => $composableBuilder(
      column: $table.customerNumber,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));
}

class $$CustomersTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get gender => $composableBuilder(
      column: $table.gender, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cardNo => $composableBuilder(
      column: $table.cardNo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recordUuid => $composableBuilder(
      column: $table.recordUuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customerNumber => $composableBuilder(
      column: $table.customerNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));
}

class $$CustomersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get cardNo =>
      $composableBuilder(column: $table.cardNo, builder: (column) => column);

  GeneratedColumn<String> get recordUuid => $composableBuilder(
      column: $table.recordUuid, builder: (column) => column);

  GeneratedColumn<int> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get customerNumber => $composableBuilder(
      column: $table.customerNumber, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);
}

class $$CustomersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CustomersTable,
    Customer,
    $$CustomersTableFilterComposer,
    $$CustomersTableOrderingComposer,
    $$CustomersTableAnnotationComposer,
    $$CustomersTableCreateCompanionBuilder,
    $$CustomersTableUpdateCompanionBuilder,
    (Customer, BaseReferences<_$AppDatabase, $CustomersTable, Customer>),
    Customer,
    PrefetchHooks Function()> {
  $$CustomersTableTableManager(_$AppDatabase db, $CustomersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> serverId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            Value<String?> gender = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<String?> cardNo = const Value.absent(),
            Value<String?> recordUuid = const Value.absent(),
            Value<int?> branchId = const Value.absent(),
            Value<String?> customerNumber = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
          }) =>
              CustomersCompanion(
            id: id,
            serverId: serverId,
            name: name,
            email: email,
            phone: phone,
            gender: gender,
            address: address,
            cardNo: cardNo,
            recordUuid: recordUuid,
            branchId: branchId,
            customerNumber: customerNumber,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isSynced: isSynced,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> serverId = const Value.absent(),
            required String name,
            Value<String?> email = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            Value<String?> gender = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<String?> cardNo = const Value.absent(),
            Value<String?> recordUuid = const Value.absent(),
            Value<int?> branchId = const Value.absent(),
            Value<String?> customerNumber = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
          }) =>
              CustomersCompanion.insert(
            id: id,
            serverId: serverId,
            name: name,
            email: email,
            phone: phone,
            gender: gender,
            address: address,
            cardNo: cardNo,
            recordUuid: recordUuid,
            branchId: branchId,
            customerNumber: customerNumber,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isSynced: isSynced,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CustomersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CustomersTable,
    Customer,
    $$CustomersTableFilterComposer,
    $$CustomersTableOrderingComposer,
    $$CustomersTableAnnotationComposer,
    $$CustomersTableCreateCompanionBuilder,
    $$CustomersTableUpdateCompanionBuilder,
    (Customer, BaseReferences<_$AppDatabase, $CustomersTable, Customer>),
    Customer,
    PrefetchHooks Function()>;
typedef $$DeliveryPartnersTableCreateCompanionBuilder
    = DeliveryPartnersCompanion Function({
  Value<int> id,
  required String name,
});
typedef $$DeliveryPartnersTableUpdateCompanionBuilder
    = DeliveryPartnersCompanion Function({
  Value<int> id,
  Value<String> name,
});

class $$DeliveryPartnersTableFilterComposer
    extends Composer<_$AppDatabase, $DeliveryPartnersTable> {
  $$DeliveryPartnersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));
}

class $$DeliveryPartnersTableOrderingComposer
    extends Composer<_$AppDatabase, $DeliveryPartnersTable> {
  $$DeliveryPartnersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));
}

class $$DeliveryPartnersTableAnnotationComposer
    extends Composer<_$AppDatabase, $DeliveryPartnersTable> {
  $$DeliveryPartnersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);
}

class $$DeliveryPartnersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DeliveryPartnersTable,
    DeliveryPartner,
    $$DeliveryPartnersTableFilterComposer,
    $$DeliveryPartnersTableOrderingComposer,
    $$DeliveryPartnersTableAnnotationComposer,
    $$DeliveryPartnersTableCreateCompanionBuilder,
    $$DeliveryPartnersTableUpdateCompanionBuilder,
    (
      DeliveryPartner,
      BaseReferences<_$AppDatabase, $DeliveryPartnersTable, DeliveryPartner>
    ),
    DeliveryPartner,
    PrefetchHooks Function()> {
  $$DeliveryPartnersTableTableManager(
      _$AppDatabase db, $DeliveryPartnersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeliveryPartnersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeliveryPartnersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeliveryPartnersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
          }) =>
              DeliveryPartnersCompanion(
            id: id,
            name: name,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
          }) =>
              DeliveryPartnersCompanion.insert(
            id: id,
            name: name,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DeliveryPartnersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DeliveryPartnersTable,
    DeliveryPartner,
    $$DeliveryPartnersTableFilterComposer,
    $$DeliveryPartnersTableOrderingComposer,
    $$DeliveryPartnersTableAnnotationComposer,
    $$DeliveryPartnersTableCreateCompanionBuilder,
    $$DeliveryPartnersTableUpdateCompanionBuilder,
    (
      DeliveryPartner,
      BaseReferences<_$AppDatabase, $DeliveryPartnersTable, DeliveryPartner>
    ),
    DeliveryPartner,
    PrefetchHooks Function()>;
typedef $$DiningFloorsTableCreateCompanionBuilder = DiningFloorsCompanion
    Function({
  Value<int> id,
  required String name,
  Value<int> sortOrder,
  Value<String?> recordUuid,
  Value<int?> branchId,
  Value<String?> floorSlug,
  Value<DateTime?> deletedAt,
});
typedef $$DiningFloorsTableUpdateCompanionBuilder = DiningFloorsCompanion
    Function({
  Value<int> id,
  Value<String> name,
  Value<int> sortOrder,
  Value<String?> recordUuid,
  Value<int?> branchId,
  Value<String?> floorSlug,
  Value<DateTime?> deletedAt,
});

final class $$DiningFloorsTableReferences
    extends BaseReferences<_$AppDatabase, $DiningFloorsTable, DiningFloor> {
  $$DiningFloorsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DiningTablesTable, List<DiningTable>>
      _diningTablesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.diningTables,
              aliasName: $_aliasNameGenerator(
                  db.diningFloors.id, db.diningTables.floorId));

  $$DiningTablesTableProcessedTableManager get diningTablesRefs {
    final manager = $$DiningTablesTableTableManager($_db, $_db.diningTables)
        .filter((f) => f.floorId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_diningTablesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$DiningFloorsTableFilterComposer
    extends Composer<_$AppDatabase, $DiningFloorsTable> {
  $$DiningFloorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recordUuid => $composableBuilder(
      column: $table.recordUuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get floorSlug => $composableBuilder(
      column: $table.floorSlug, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> diningTablesRefs(
      Expression<bool> Function($$DiningTablesTableFilterComposer f) f) {
    final $$DiningTablesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.diningTables,
        getReferencedColumn: (t) => t.floorId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DiningTablesTableFilterComposer(
              $db: $db,
              $table: $db.diningTables,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$DiningFloorsTableOrderingComposer
    extends Composer<_$AppDatabase, $DiningFloorsTable> {
  $$DiningFloorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recordUuid => $composableBuilder(
      column: $table.recordUuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get floorSlug => $composableBuilder(
      column: $table.floorSlug, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$DiningFloorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DiningFloorsTable> {
  $$DiningFloorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get recordUuid => $composableBuilder(
      column: $table.recordUuid, builder: (column) => column);

  GeneratedColumn<int> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get floorSlug =>
      $composableBuilder(column: $table.floorSlug, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> diningTablesRefs<T extends Object>(
      Expression<T> Function($$DiningTablesTableAnnotationComposer a) f) {
    final $$DiningTablesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.diningTables,
        getReferencedColumn: (t) => t.floorId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DiningTablesTableAnnotationComposer(
              $db: $db,
              $table: $db.diningTables,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$DiningFloorsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DiningFloorsTable,
    DiningFloor,
    $$DiningFloorsTableFilterComposer,
    $$DiningFloorsTableOrderingComposer,
    $$DiningFloorsTableAnnotationComposer,
    $$DiningFloorsTableCreateCompanionBuilder,
    $$DiningFloorsTableUpdateCompanionBuilder,
    (DiningFloor, $$DiningFloorsTableReferences),
    DiningFloor,
    PrefetchHooks Function({bool diningTablesRefs})> {
  $$DiningFloorsTableTableManager(_$AppDatabase db, $DiningFloorsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DiningFloorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DiningFloorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DiningFloorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<String?> recordUuid = const Value.absent(),
            Value<int?> branchId = const Value.absent(),
            Value<String?> floorSlug = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
          }) =>
              DiningFloorsCompanion(
            id: id,
            name: name,
            sortOrder: sortOrder,
            recordUuid: recordUuid,
            branchId: branchId,
            floorSlug: floorSlug,
            deletedAt: deletedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<int> sortOrder = const Value.absent(),
            Value<String?> recordUuid = const Value.absent(),
            Value<int?> branchId = const Value.absent(),
            Value<String?> floorSlug = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
          }) =>
              DiningFloorsCompanion.insert(
            id: id,
            name: name,
            sortOrder: sortOrder,
            recordUuid: recordUuid,
            branchId: branchId,
            floorSlug: floorSlug,
            deletedAt: deletedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$DiningFloorsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({diningTablesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (diningTablesRefs) db.diningTables],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (diningTablesRefs)
                    await $_getPrefetchedData<DiningFloor, $DiningFloorsTable,
                            DiningTable>(
                        currentTable: table,
                        referencedTable: $$DiningFloorsTableReferences
                            ._diningTablesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$DiningFloorsTableReferences(db, table, p0)
                                .diningTablesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.floorId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$DiningFloorsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DiningFloorsTable,
    DiningFloor,
    $$DiningFloorsTableFilterComposer,
    $$DiningFloorsTableOrderingComposer,
    $$DiningFloorsTableAnnotationComposer,
    $$DiningFloorsTableCreateCompanionBuilder,
    $$DiningFloorsTableUpdateCompanionBuilder,
    (DiningFloor, $$DiningFloorsTableReferences),
    DiningFloor,
    PrefetchHooks Function({bool diningTablesRefs})>;
typedef $$DiningTablesTableCreateCompanionBuilder = DiningTablesCompanion
    Function({
  Value<int> id,
  required int floorId,
  required String code,
  Value<int> chairs,
  Value<String> status,
  Value<String?> recordUuid,
  Value<int?> branchId,
  Value<String?> pulledTableName,
  Value<String?> pulledTableSlug,
  Value<int?> orderCount,
  Value<DateTime?> deletedAt,
});
typedef $$DiningTablesTableUpdateCompanionBuilder = DiningTablesCompanion
    Function({
  Value<int> id,
  Value<int> floorId,
  Value<String> code,
  Value<int> chairs,
  Value<String> status,
  Value<String?> recordUuid,
  Value<int?> branchId,
  Value<String?> pulledTableName,
  Value<String?> pulledTableSlug,
  Value<int?> orderCount,
  Value<DateTime?> deletedAt,
});

final class $$DiningTablesTableReferences
    extends BaseReferences<_$AppDatabase, $DiningTablesTable, DiningTable> {
  $$DiningTablesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DiningFloorsTable _floorIdTable(_$AppDatabase db) =>
      db.diningFloors.createAlias(
          $_aliasNameGenerator(db.diningTables.floorId, db.diningFloors.id));

  $$DiningFloorsTableProcessedTableManager get floorId {
    final $_column = $_itemColumn<int>('floor_id')!;

    final manager = $$DiningFloorsTableTableManager($_db, $_db.diningFloors)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_floorIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$DiningTablesTableFilterComposer
    extends Composer<_$AppDatabase, $DiningTablesTable> {
  $$DiningTablesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get chairs => $composableBuilder(
      column: $table.chairs, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recordUuid => $composableBuilder(
      column: $table.recordUuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pulledTableName => $composableBuilder(
      column: $table.pulledTableName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pulledTableSlug => $composableBuilder(
      column: $table.pulledTableSlug,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get orderCount => $composableBuilder(
      column: $table.orderCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  $$DiningFloorsTableFilterComposer get floorId {
    final $$DiningFloorsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.floorId,
        referencedTable: $db.diningFloors,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DiningFloorsTableFilterComposer(
              $db: $db,
              $table: $db.diningFloors,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DiningTablesTableOrderingComposer
    extends Composer<_$AppDatabase, $DiningTablesTable> {
  $$DiningTablesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get chairs => $composableBuilder(
      column: $table.chairs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recordUuid => $composableBuilder(
      column: $table.recordUuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pulledTableName => $composableBuilder(
      column: $table.pulledTableName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pulledTableSlug => $composableBuilder(
      column: $table.pulledTableSlug,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get orderCount => $composableBuilder(
      column: $table.orderCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  $$DiningFloorsTableOrderingComposer get floorId {
    final $$DiningFloorsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.floorId,
        referencedTable: $db.diningFloors,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DiningFloorsTableOrderingComposer(
              $db: $db,
              $table: $db.diningFloors,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DiningTablesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DiningTablesTable> {
  $$DiningTablesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<int> get chairs =>
      $composableBuilder(column: $table.chairs, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get recordUuid => $composableBuilder(
      column: $table.recordUuid, builder: (column) => column);

  GeneratedColumn<int> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get pulledTableName => $composableBuilder(
      column: $table.pulledTableName, builder: (column) => column);

  GeneratedColumn<String> get pulledTableSlug => $composableBuilder(
      column: $table.pulledTableSlug, builder: (column) => column);

  GeneratedColumn<int> get orderCount => $composableBuilder(
      column: $table.orderCount, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$DiningFloorsTableAnnotationComposer get floorId {
    final $$DiningFloorsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.floorId,
        referencedTable: $db.diningFloors,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DiningFloorsTableAnnotationComposer(
              $db: $db,
              $table: $db.diningFloors,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DiningTablesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DiningTablesTable,
    DiningTable,
    $$DiningTablesTableFilterComposer,
    $$DiningTablesTableOrderingComposer,
    $$DiningTablesTableAnnotationComposer,
    $$DiningTablesTableCreateCompanionBuilder,
    $$DiningTablesTableUpdateCompanionBuilder,
    (DiningTable, $$DiningTablesTableReferences),
    DiningTable,
    PrefetchHooks Function({bool floorId})> {
  $$DiningTablesTableTableManager(_$AppDatabase db, $DiningTablesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DiningTablesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DiningTablesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DiningTablesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> floorId = const Value.absent(),
            Value<String> code = const Value.absent(),
            Value<int> chairs = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> recordUuid = const Value.absent(),
            Value<int?> branchId = const Value.absent(),
            Value<String?> pulledTableName = const Value.absent(),
            Value<String?> pulledTableSlug = const Value.absent(),
            Value<int?> orderCount = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
          }) =>
              DiningTablesCompanion(
            id: id,
            floorId: floorId,
            code: code,
            chairs: chairs,
            status: status,
            recordUuid: recordUuid,
            branchId: branchId,
            pulledTableName: pulledTableName,
            pulledTableSlug: pulledTableSlug,
            orderCount: orderCount,
            deletedAt: deletedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int floorId,
            required String code,
            Value<int> chairs = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> recordUuid = const Value.absent(),
            Value<int?> branchId = const Value.absent(),
            Value<String?> pulledTableName = const Value.absent(),
            Value<String?> pulledTableSlug = const Value.absent(),
            Value<int?> orderCount = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
          }) =>
              DiningTablesCompanion.insert(
            id: id,
            floorId: floorId,
            code: code,
            chairs: chairs,
            status: status,
            recordUuid: recordUuid,
            branchId: branchId,
            pulledTableName: pulledTableName,
            pulledTableSlug: pulledTableSlug,
            orderCount: orderCount,
            deletedAt: deletedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$DiningTablesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({floorId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (floorId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.floorId,
                    referencedTable:
                        $$DiningTablesTableReferences._floorIdTable(db),
                    referencedColumn:
                        $$DiningTablesTableReferences._floorIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$DiningTablesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DiningTablesTable,
    DiningTable,
    $$DiningTablesTableFilterComposer,
    $$DiningTablesTableOrderingComposer,
    $$DiningTablesTableAnnotationComposer,
    $$DiningTablesTableCreateCompanionBuilder,
    $$DiningTablesTableUpdateCompanionBuilder,
    (DiningTable, $$DiningTablesTableReferences),
    DiningTable,
    PrefetchHooks Function({bool floorId})>;
typedef $$BranchesTableCreateCompanionBuilder = BranchesCompanion Function({
  Value<int> id,
  required String branchName,
  required String location,
  required String contactNo,
  Value<String?> email,
  Value<String?> socialMedia,
  required String vat,
  Value<double?> vatPercent,
  Value<String?> trnNumber,
  required String prefixInv,
  required String invoiceHeader,
  required String image,
  Value<String> localImage,
  required DateTime installationDate,
  required DateTime expiryDate,
  required int openingCash,
});
typedef $$BranchesTableUpdateCompanionBuilder = BranchesCompanion Function({
  Value<int> id,
  Value<String> branchName,
  Value<String> location,
  Value<String> contactNo,
  Value<String?> email,
  Value<String?> socialMedia,
  Value<String> vat,
  Value<double?> vatPercent,
  Value<String?> trnNumber,
  Value<String> prefixInv,
  Value<String> invoiceHeader,
  Value<String> image,
  Value<String> localImage,
  Value<DateTime> installationDate,
  Value<DateTime> expiryDate,
  Value<int> openingCash,
});

class $$BranchesTableFilterComposer
    extends Composer<_$AppDatabase, $BranchesTable> {
  $$BranchesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get branchName => $composableBuilder(
      column: $table.branchName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get location => $composableBuilder(
      column: $table.location, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contactNo => $composableBuilder(
      column: $table.contactNo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get socialMedia => $composableBuilder(
      column: $table.socialMedia, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get vat => $composableBuilder(
      column: $table.vat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get vatPercent => $composableBuilder(
      column: $table.vatPercent, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get trnNumber => $composableBuilder(
      column: $table.trnNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get prefixInv => $composableBuilder(
      column: $table.prefixInv, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get invoiceHeader => $composableBuilder(
      column: $table.invoiceHeader, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get image => $composableBuilder(
      column: $table.image, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localImage => $composableBuilder(
      column: $table.localImage, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get installationDate => $composableBuilder(
      column: $table.installationDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get expiryDate => $composableBuilder(
      column: $table.expiryDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get openingCash => $composableBuilder(
      column: $table.openingCash, builder: (column) => ColumnFilters(column));
}

class $$BranchesTableOrderingComposer
    extends Composer<_$AppDatabase, $BranchesTable> {
  $$BranchesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get branchName => $composableBuilder(
      column: $table.branchName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get location => $composableBuilder(
      column: $table.location, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contactNo => $composableBuilder(
      column: $table.contactNo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get socialMedia => $composableBuilder(
      column: $table.socialMedia, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get vat => $composableBuilder(
      column: $table.vat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get vatPercent => $composableBuilder(
      column: $table.vatPercent, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get trnNumber => $composableBuilder(
      column: $table.trnNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get prefixInv => $composableBuilder(
      column: $table.prefixInv, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get invoiceHeader => $composableBuilder(
      column: $table.invoiceHeader,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get image => $composableBuilder(
      column: $table.image, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localImage => $composableBuilder(
      column: $table.localImage, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get installationDate => $composableBuilder(
      column: $table.installationDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get expiryDate => $composableBuilder(
      column: $table.expiryDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get openingCash => $composableBuilder(
      column: $table.openingCash, builder: (column) => ColumnOrderings(column));
}

class $$BranchesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BranchesTable> {
  $$BranchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get branchName => $composableBuilder(
      column: $table.branchName, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get contactNo =>
      $composableBuilder(column: $table.contactNo, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get socialMedia => $composableBuilder(
      column: $table.socialMedia, builder: (column) => column);

  GeneratedColumn<String> get vat =>
      $composableBuilder(column: $table.vat, builder: (column) => column);

  GeneratedColumn<double> get vatPercent => $composableBuilder(
      column: $table.vatPercent, builder: (column) => column);

  GeneratedColumn<String> get trnNumber =>
      $composableBuilder(column: $table.trnNumber, builder: (column) => column);

  GeneratedColumn<String> get prefixInv =>
      $composableBuilder(column: $table.prefixInv, builder: (column) => column);

  GeneratedColumn<String> get invoiceHeader => $composableBuilder(
      column: $table.invoiceHeader, builder: (column) => column);

  GeneratedColumn<String> get image =>
      $composableBuilder(column: $table.image, builder: (column) => column);

  GeneratedColumn<String> get localImage => $composableBuilder(
      column: $table.localImage, builder: (column) => column);

  GeneratedColumn<DateTime> get installationDate => $composableBuilder(
      column: $table.installationDate, builder: (column) => column);

  GeneratedColumn<DateTime> get expiryDate => $composableBuilder(
      column: $table.expiryDate, builder: (column) => column);

  GeneratedColumn<int> get openingCash => $composableBuilder(
      column: $table.openingCash, builder: (column) => column);
}

class $$BranchesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BranchesTable,
    Branche,
    $$BranchesTableFilterComposer,
    $$BranchesTableOrderingComposer,
    $$BranchesTableAnnotationComposer,
    $$BranchesTableCreateCompanionBuilder,
    $$BranchesTableUpdateCompanionBuilder,
    (Branche, BaseReferences<_$AppDatabase, $BranchesTable, Branche>),
    Branche,
    PrefetchHooks Function()> {
  $$BranchesTableTableManager(_$AppDatabase db, $BranchesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BranchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BranchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BranchesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> branchName = const Value.absent(),
            Value<String> location = const Value.absent(),
            Value<String> contactNo = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<String?> socialMedia = const Value.absent(),
            Value<String> vat = const Value.absent(),
            Value<double?> vatPercent = const Value.absent(),
            Value<String?> trnNumber = const Value.absent(),
            Value<String> prefixInv = const Value.absent(),
            Value<String> invoiceHeader = const Value.absent(),
            Value<String> image = const Value.absent(),
            Value<String> localImage = const Value.absent(),
            Value<DateTime> installationDate = const Value.absent(),
            Value<DateTime> expiryDate = const Value.absent(),
            Value<int> openingCash = const Value.absent(),
          }) =>
              BranchesCompanion(
            id: id,
            branchName: branchName,
            location: location,
            contactNo: contactNo,
            email: email,
            socialMedia: socialMedia,
            vat: vat,
            vatPercent: vatPercent,
            trnNumber: trnNumber,
            prefixInv: prefixInv,
            invoiceHeader: invoiceHeader,
            image: image,
            localImage: localImage,
            installationDate: installationDate,
            expiryDate: expiryDate,
            openingCash: openingCash,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String branchName,
            required String location,
            required String contactNo,
            Value<String?> email = const Value.absent(),
            Value<String?> socialMedia = const Value.absent(),
            required String vat,
            Value<double?> vatPercent = const Value.absent(),
            Value<String?> trnNumber = const Value.absent(),
            required String prefixInv,
            required String invoiceHeader,
            required String image,
            Value<String> localImage = const Value.absent(),
            required DateTime installationDate,
            required DateTime expiryDate,
            required int openingCash,
          }) =>
              BranchesCompanion.insert(
            id: id,
            branchName: branchName,
            location: location,
            contactNo: contactNo,
            email: email,
            socialMedia: socialMedia,
            vat: vat,
            vatPercent: vatPercent,
            trnNumber: trnNumber,
            prefixInv: prefixInv,
            invoiceHeader: invoiceHeader,
            image: image,
            localImage: localImage,
            installationDate: installationDate,
            expiryDate: expiryDate,
            openingCash: openingCash,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$BranchesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BranchesTable,
    Branche,
    $$BranchesTableFilterComposer,
    $$BranchesTableOrderingComposer,
    $$BranchesTableAnnotationComposer,
    $$BranchesTableCreateCompanionBuilder,
    $$BranchesTableUpdateCompanionBuilder,
    (Branche, BaseReferences<_$AppDatabase, $BranchesTable, Branche>),
    Branche,
    PrefetchHooks Function()>;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  Value<int> id,
  required String currency,
  required String decimalPoint,
  required String dateFormat,
  required String timeFormat,
  required String unitPrice,
  required String stockCheck,
  required String stockShow,
  required String settleCheckPending,
  required String deliverySale,
  required String apiKey,
  required String customProduct,
  required String language,
  required String staffPin,
  required String barcode,
  required String drawerPassword,
  required String paybackPassword,
  required String purchase,
  required String production,
  required String minimumStock,
  required String wastageUsage,
  required String wastageUsageZeroStock,
  required String customizeItem,
  required String printType,
  required String printLink,
  required String mainPrintType,
  required String mainPrintDetail,
  required String printImageInBill,
  required String printBranchNameInBill,
  required String dineInTableOrderCount,
  required String variation,
  required String qtyReducePassword,
  required String counterLoginLimit,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<int> id,
  Value<String> currency,
  Value<String> decimalPoint,
  Value<String> dateFormat,
  Value<String> timeFormat,
  Value<String> unitPrice,
  Value<String> stockCheck,
  Value<String> stockShow,
  Value<String> settleCheckPending,
  Value<String> deliverySale,
  Value<String> apiKey,
  Value<String> customProduct,
  Value<String> language,
  Value<String> staffPin,
  Value<String> barcode,
  Value<String> drawerPassword,
  Value<String> paybackPassword,
  Value<String> purchase,
  Value<String> production,
  Value<String> minimumStock,
  Value<String> wastageUsage,
  Value<String> wastageUsageZeroStock,
  Value<String> customizeItem,
  Value<String> printType,
  Value<String> printLink,
  Value<String> mainPrintType,
  Value<String> mainPrintDetail,
  Value<String> printImageInBill,
  Value<String> printBranchNameInBill,
  Value<String> dineInTableOrderCount,
  Value<String> variation,
  Value<String> qtyReducePassword,
  Value<String> counterLoginLimit,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get decimalPoint => $composableBuilder(
      column: $table.decimalPoint, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dateFormat => $composableBuilder(
      column: $table.dateFormat, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get timeFormat => $composableBuilder(
      column: $table.timeFormat, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unitPrice => $composableBuilder(
      column: $table.unitPrice, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get stockCheck => $composableBuilder(
      column: $table.stockCheck, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get stockShow => $composableBuilder(
      column: $table.stockShow, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get settleCheckPending => $composableBuilder(
      column: $table.settleCheckPending,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deliverySale => $composableBuilder(
      column: $table.deliverySale, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get apiKey => $composableBuilder(
      column: $table.apiKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customProduct => $composableBuilder(
      column: $table.customProduct, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get language => $composableBuilder(
      column: $table.language, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get staffPin => $composableBuilder(
      column: $table.staffPin, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get barcode => $composableBuilder(
      column: $table.barcode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get drawerPassword => $composableBuilder(
      column: $table.drawerPassword,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get paybackPassword => $composableBuilder(
      column: $table.paybackPassword,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get purchase => $composableBuilder(
      column: $table.purchase, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get production => $composableBuilder(
      column: $table.production, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get minimumStock => $composableBuilder(
      column: $table.minimumStock, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get wastageUsage => $composableBuilder(
      column: $table.wastageUsage, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get wastageUsageZeroStock => $composableBuilder(
      column: $table.wastageUsageZeroStock,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customizeItem => $composableBuilder(
      column: $table.customizeItem, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get printType => $composableBuilder(
      column: $table.printType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get printLink => $composableBuilder(
      column: $table.printLink, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mainPrintType => $composableBuilder(
      column: $table.mainPrintType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mainPrintDetail => $composableBuilder(
      column: $table.mainPrintDetail,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get printImageInBill => $composableBuilder(
      column: $table.printImageInBill,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get printBranchNameInBill => $composableBuilder(
      column: $table.printBranchNameInBill,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dineInTableOrderCount => $composableBuilder(
      column: $table.dineInTableOrderCount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get variation => $composableBuilder(
      column: $table.variation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get qtyReducePassword => $composableBuilder(
      column: $table.qtyReducePassword,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get counterLoginLimit => $composableBuilder(
      column: $table.counterLoginLimit,
      builder: (column) => ColumnFilters(column));
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get decimalPoint => $composableBuilder(
      column: $table.decimalPoint,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dateFormat => $composableBuilder(
      column: $table.dateFormat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get timeFormat => $composableBuilder(
      column: $table.timeFormat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unitPrice => $composableBuilder(
      column: $table.unitPrice, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get stockCheck => $composableBuilder(
      column: $table.stockCheck, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get stockShow => $composableBuilder(
      column: $table.stockShow, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get settleCheckPending => $composableBuilder(
      column: $table.settleCheckPending,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deliverySale => $composableBuilder(
      column: $table.deliverySale,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get apiKey => $composableBuilder(
      column: $table.apiKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customProduct => $composableBuilder(
      column: $table.customProduct,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get language => $composableBuilder(
      column: $table.language, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get staffPin => $composableBuilder(
      column: $table.staffPin, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get barcode => $composableBuilder(
      column: $table.barcode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get drawerPassword => $composableBuilder(
      column: $table.drawerPassword,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get paybackPassword => $composableBuilder(
      column: $table.paybackPassword,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get purchase => $composableBuilder(
      column: $table.purchase, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get production => $composableBuilder(
      column: $table.production, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get minimumStock => $composableBuilder(
      column: $table.minimumStock,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get wastageUsage => $composableBuilder(
      column: $table.wastageUsage,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get wastageUsageZeroStock => $composableBuilder(
      column: $table.wastageUsageZeroStock,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customizeItem => $composableBuilder(
      column: $table.customizeItem,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get printType => $composableBuilder(
      column: $table.printType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get printLink => $composableBuilder(
      column: $table.printLink, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mainPrintType => $composableBuilder(
      column: $table.mainPrintType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mainPrintDetail => $composableBuilder(
      column: $table.mainPrintDetail,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get printImageInBill => $composableBuilder(
      column: $table.printImageInBill,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get printBranchNameInBill => $composableBuilder(
      column: $table.printBranchNameInBill,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dineInTableOrderCount => $composableBuilder(
      column: $table.dineInTableOrderCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get variation => $composableBuilder(
      column: $table.variation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get qtyReducePassword => $composableBuilder(
      column: $table.qtyReducePassword,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get counterLoginLimit => $composableBuilder(
      column: $table.counterLoginLimit,
      builder: (column) => ColumnOrderings(column));
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get decimalPoint => $composableBuilder(
      column: $table.decimalPoint, builder: (column) => column);

  GeneratedColumn<String> get dateFormat => $composableBuilder(
      column: $table.dateFormat, builder: (column) => column);

  GeneratedColumn<String> get timeFormat => $composableBuilder(
      column: $table.timeFormat, builder: (column) => column);

  GeneratedColumn<String> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<String> get stockCheck => $composableBuilder(
      column: $table.stockCheck, builder: (column) => column);

  GeneratedColumn<String> get stockShow =>
      $composableBuilder(column: $table.stockShow, builder: (column) => column);

  GeneratedColumn<String> get settleCheckPending => $composableBuilder(
      column: $table.settleCheckPending, builder: (column) => column);

  GeneratedColumn<String> get deliverySale => $composableBuilder(
      column: $table.deliverySale, builder: (column) => column);

  GeneratedColumn<String> get apiKey =>
      $composableBuilder(column: $table.apiKey, builder: (column) => column);

  GeneratedColumn<String> get customProduct => $composableBuilder(
      column: $table.customProduct, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get staffPin =>
      $composableBuilder(column: $table.staffPin, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<String> get drawerPassword => $composableBuilder(
      column: $table.drawerPassword, builder: (column) => column);

  GeneratedColumn<String> get paybackPassword => $composableBuilder(
      column: $table.paybackPassword, builder: (column) => column);

  GeneratedColumn<String> get purchase =>
      $composableBuilder(column: $table.purchase, builder: (column) => column);

  GeneratedColumn<String> get production => $composableBuilder(
      column: $table.production, builder: (column) => column);

  GeneratedColumn<String> get minimumStock => $composableBuilder(
      column: $table.minimumStock, builder: (column) => column);

  GeneratedColumn<String> get wastageUsage => $composableBuilder(
      column: $table.wastageUsage, builder: (column) => column);

  GeneratedColumn<String> get wastageUsageZeroStock => $composableBuilder(
      column: $table.wastageUsageZeroStock, builder: (column) => column);

  GeneratedColumn<String> get customizeItem => $composableBuilder(
      column: $table.customizeItem, builder: (column) => column);

  GeneratedColumn<String> get printType =>
      $composableBuilder(column: $table.printType, builder: (column) => column);

  GeneratedColumn<String> get printLink =>
      $composableBuilder(column: $table.printLink, builder: (column) => column);

  GeneratedColumn<String> get mainPrintType => $composableBuilder(
      column: $table.mainPrintType, builder: (column) => column);

  GeneratedColumn<String> get mainPrintDetail => $composableBuilder(
      column: $table.mainPrintDetail, builder: (column) => column);

  GeneratedColumn<String> get printImageInBill => $composableBuilder(
      column: $table.printImageInBill, builder: (column) => column);

  GeneratedColumn<String> get printBranchNameInBill => $composableBuilder(
      column: $table.printBranchNameInBill, builder: (column) => column);

  GeneratedColumn<String> get dineInTableOrderCount => $composableBuilder(
      column: $table.dineInTableOrderCount, builder: (column) => column);

  GeneratedColumn<String> get variation =>
      $composableBuilder(column: $table.variation, builder: (column) => column);

  GeneratedColumn<String> get qtyReducePassword => $composableBuilder(
      column: $table.qtyReducePassword, builder: (column) => column);

  GeneratedColumn<String> get counterLoginLimit => $composableBuilder(
      column: $table.counterLoginLimit, builder: (column) => column);
}

class $$SettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SettingsTable,
    Setting,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
    Setting,
    PrefetchHooks Function()> {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<String> decimalPoint = const Value.absent(),
            Value<String> dateFormat = const Value.absent(),
            Value<String> timeFormat = const Value.absent(),
            Value<String> unitPrice = const Value.absent(),
            Value<String> stockCheck = const Value.absent(),
            Value<String> stockShow = const Value.absent(),
            Value<String> settleCheckPending = const Value.absent(),
            Value<String> deliverySale = const Value.absent(),
            Value<String> apiKey = const Value.absent(),
            Value<String> customProduct = const Value.absent(),
            Value<String> language = const Value.absent(),
            Value<String> staffPin = const Value.absent(),
            Value<String> barcode = const Value.absent(),
            Value<String> drawerPassword = const Value.absent(),
            Value<String> paybackPassword = const Value.absent(),
            Value<String> purchase = const Value.absent(),
            Value<String> production = const Value.absent(),
            Value<String> minimumStock = const Value.absent(),
            Value<String> wastageUsage = const Value.absent(),
            Value<String> wastageUsageZeroStock = const Value.absent(),
            Value<String> customizeItem = const Value.absent(),
            Value<String> printType = const Value.absent(),
            Value<String> printLink = const Value.absent(),
            Value<String> mainPrintType = const Value.absent(),
            Value<String> mainPrintDetail = const Value.absent(),
            Value<String> printImageInBill = const Value.absent(),
            Value<String> printBranchNameInBill = const Value.absent(),
            Value<String> dineInTableOrderCount = const Value.absent(),
            Value<String> variation = const Value.absent(),
            Value<String> qtyReducePassword = const Value.absent(),
            Value<String> counterLoginLimit = const Value.absent(),
          }) =>
              SettingsCompanion(
            id: id,
            currency: currency,
            decimalPoint: decimalPoint,
            dateFormat: dateFormat,
            timeFormat: timeFormat,
            unitPrice: unitPrice,
            stockCheck: stockCheck,
            stockShow: stockShow,
            settleCheckPending: settleCheckPending,
            deliverySale: deliverySale,
            apiKey: apiKey,
            customProduct: customProduct,
            language: language,
            staffPin: staffPin,
            barcode: barcode,
            drawerPassword: drawerPassword,
            paybackPassword: paybackPassword,
            purchase: purchase,
            production: production,
            minimumStock: minimumStock,
            wastageUsage: wastageUsage,
            wastageUsageZeroStock: wastageUsageZeroStock,
            customizeItem: customizeItem,
            printType: printType,
            printLink: printLink,
            mainPrintType: mainPrintType,
            mainPrintDetail: mainPrintDetail,
            printImageInBill: printImageInBill,
            printBranchNameInBill: printBranchNameInBill,
            dineInTableOrderCount: dineInTableOrderCount,
            variation: variation,
            qtyReducePassword: qtyReducePassword,
            counterLoginLimit: counterLoginLimit,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String currency,
            required String decimalPoint,
            required String dateFormat,
            required String timeFormat,
            required String unitPrice,
            required String stockCheck,
            required String stockShow,
            required String settleCheckPending,
            required String deliverySale,
            required String apiKey,
            required String customProduct,
            required String language,
            required String staffPin,
            required String barcode,
            required String drawerPassword,
            required String paybackPassword,
            required String purchase,
            required String production,
            required String minimumStock,
            required String wastageUsage,
            required String wastageUsageZeroStock,
            required String customizeItem,
            required String printType,
            required String printLink,
            required String mainPrintType,
            required String mainPrintDetail,
            required String printImageInBill,
            required String printBranchNameInBill,
            required String dineInTableOrderCount,
            required String variation,
            required String qtyReducePassword,
            required String counterLoginLimit,
          }) =>
              SettingsCompanion.insert(
            id: id,
            currency: currency,
            decimalPoint: decimalPoint,
            dateFormat: dateFormat,
            timeFormat: timeFormat,
            unitPrice: unitPrice,
            stockCheck: stockCheck,
            stockShow: stockShow,
            settleCheckPending: settleCheckPending,
            deliverySale: deliverySale,
            apiKey: apiKey,
            customProduct: customProduct,
            language: language,
            staffPin: staffPin,
            barcode: barcode,
            drawerPassword: drawerPassword,
            paybackPassword: paybackPassword,
            purchase: purchase,
            production: production,
            minimumStock: minimumStock,
            wastageUsage: wastageUsage,
            wastageUsageZeroStock: wastageUsageZeroStock,
            customizeItem: customizeItem,
            printType: printType,
            printLink: printLink,
            mainPrintType: mainPrintType,
            mainPrintDetail: mainPrintDetail,
            printImageInBill: printImageInBill,
            printBranchNameInBill: printBranchNameInBill,
            dineInTableOrderCount: dineInTableOrderCount,
            variation: variation,
            qtyReducePassword: qtyReducePassword,
            counterLoginLimit: counterLoginLimit,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SettingsTable,
    Setting,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
    Setting,
    PrefetchHooks Function()>;
typedef $$PullCategoryRowsTableCreateCompanionBuilder
    = PullCategoryRowsCompanion Function({
  required String resourceKey,
  required int id,
  required String uuid,
  required int branchId,
  required String categoryName,
  required String categorySlug,
  Value<String?> otherName,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$PullCategoryRowsTableUpdateCompanionBuilder
    = PullCategoryRowsCompanion Function({
  Value<String> resourceKey,
  Value<int> id,
  Value<String> uuid,
  Value<int> branchId,
  Value<String> categoryName,
  Value<String> categorySlug,
  Value<String?> otherName,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

class $$PullCategoryRowsTableFilterComposer
    extends Composer<_$AppDatabase, $PullCategoryRowsTable> {
  $$PullCategoryRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get resourceKey => $composableBuilder(
      column: $table.resourceKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryName => $composableBuilder(
      column: $table.categoryName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categorySlug => $composableBuilder(
      column: $table.categorySlug, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get otherName => $composableBuilder(
      column: $table.otherName, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));
}

class $$PullCategoryRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $PullCategoryRowsTable> {
  $$PullCategoryRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get resourceKey => $composableBuilder(
      column: $table.resourceKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryName => $composableBuilder(
      column: $table.categoryName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categorySlug => $composableBuilder(
      column: $table.categorySlug,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get otherName => $composableBuilder(
      column: $table.otherName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$PullCategoryRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PullCategoryRowsTable> {
  $$PullCategoryRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get resourceKey => $composableBuilder(
      column: $table.resourceKey, builder: (column) => column);

  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<int> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get categoryName => $composableBuilder(
      column: $table.categoryName, builder: (column) => column);

  GeneratedColumn<String> get categorySlug => $composableBuilder(
      column: $table.categorySlug, builder: (column) => column);

  GeneratedColumn<String> get otherName =>
      $composableBuilder(column: $table.otherName, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$PullCategoryRowsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PullCategoryRowsTable,
    PullCategoryRow,
    $$PullCategoryRowsTableFilterComposer,
    $$PullCategoryRowsTableOrderingComposer,
    $$PullCategoryRowsTableAnnotationComposer,
    $$PullCategoryRowsTableCreateCompanionBuilder,
    $$PullCategoryRowsTableUpdateCompanionBuilder,
    (
      PullCategoryRow,
      BaseReferences<_$AppDatabase, $PullCategoryRowsTable, PullCategoryRow>
    ),
    PullCategoryRow,
    PrefetchHooks Function()> {
  $$PullCategoryRowsTableTableManager(
      _$AppDatabase db, $PullCategoryRowsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PullCategoryRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PullCategoryRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PullCategoryRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> resourceKey = const Value.absent(),
            Value<int> id = const Value.absent(),
            Value<String> uuid = const Value.absent(),
            Value<int> branchId = const Value.absent(),
            Value<String> categoryName = const Value.absent(),
            Value<String> categorySlug = const Value.absent(),
            Value<String?> otherName = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PullCategoryRowsCompanion(
            resourceKey: resourceKey,
            id: id,
            uuid: uuid,
            branchId: branchId,
            categoryName: categoryName,
            categorySlug: categorySlug,
            otherName: otherName,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String resourceKey,
            required int id,
            required String uuid,
            required int branchId,
            required String categoryName,
            required String categorySlug,
            Value<String?> otherName = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PullCategoryRowsCompanion.insert(
            resourceKey: resourceKey,
            id: id,
            uuid: uuid,
            branchId: branchId,
            categoryName: categoryName,
            categorySlug: categorySlug,
            otherName: otherName,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PullCategoryRowsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PullCategoryRowsTable,
    PullCategoryRow,
    $$PullCategoryRowsTableFilterComposer,
    $$PullCategoryRowsTableOrderingComposer,
    $$PullCategoryRowsTableAnnotationComposer,
    $$PullCategoryRowsTableCreateCompanionBuilder,
    $$PullCategoryRowsTableUpdateCompanionBuilder,
    (
      PullCategoryRow,
      BaseReferences<_$AppDatabase, $PullCategoryRowsTable, PullCategoryRow>
    ),
    PullCategoryRow,
    PrefetchHooks Function()>;
typedef $$PullFloorRowsTableCreateCompanionBuilder = PullFloorRowsCompanion
    Function({
  required String resourceKey,
  required int id,
  required String uuid,
  required int branchId,
  Value<String?> floorName,
  Value<String?> floorSlug,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<String?> paymentMethodName,
  Value<String?> paymentMethodSlug,
  Value<String?> unitName,
  Value<String?> unitSlug,
  Value<int> rowid,
});
typedef $$PullFloorRowsTableUpdateCompanionBuilder = PullFloorRowsCompanion
    Function({
  Value<String> resourceKey,
  Value<int> id,
  Value<String> uuid,
  Value<int> branchId,
  Value<String?> floorName,
  Value<String?> floorSlug,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String?> paymentMethodName,
  Value<String?> paymentMethodSlug,
  Value<String?> unitName,
  Value<String?> unitSlug,
  Value<int> rowid,
});

class $$PullFloorRowsTableFilterComposer
    extends Composer<_$AppDatabase, $PullFloorRowsTable> {
  $$PullFloorRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get resourceKey => $composableBuilder(
      column: $table.resourceKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get floorName => $composableBuilder(
      column: $table.floorName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get floorSlug => $composableBuilder(
      column: $table.floorSlug, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get paymentMethodName => $composableBuilder(
      column: $table.paymentMethodName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get paymentMethodSlug => $composableBuilder(
      column: $table.paymentMethodSlug,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unitName => $composableBuilder(
      column: $table.unitName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unitSlug => $composableBuilder(
      column: $table.unitSlug, builder: (column) => ColumnFilters(column));
}

class $$PullFloorRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $PullFloorRowsTable> {
  $$PullFloorRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get resourceKey => $composableBuilder(
      column: $table.resourceKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get floorName => $composableBuilder(
      column: $table.floorName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get floorSlug => $composableBuilder(
      column: $table.floorSlug, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get paymentMethodName => $composableBuilder(
      column: $table.paymentMethodName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get paymentMethodSlug => $composableBuilder(
      column: $table.paymentMethodSlug,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unitName => $composableBuilder(
      column: $table.unitName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unitSlug => $composableBuilder(
      column: $table.unitSlug, builder: (column) => ColumnOrderings(column));
}

class $$PullFloorRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PullFloorRowsTable> {
  $$PullFloorRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get resourceKey => $composableBuilder(
      column: $table.resourceKey, builder: (column) => column);

  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<int> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get floorName =>
      $composableBuilder(column: $table.floorName, builder: (column) => column);

  GeneratedColumn<String> get floorSlug =>
      $composableBuilder(column: $table.floorSlug, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get paymentMethodName => $composableBuilder(
      column: $table.paymentMethodName, builder: (column) => column);

  GeneratedColumn<String> get paymentMethodSlug => $composableBuilder(
      column: $table.paymentMethodSlug, builder: (column) => column);

  GeneratedColumn<String> get unitName =>
      $composableBuilder(column: $table.unitName, builder: (column) => column);

  GeneratedColumn<String> get unitSlug =>
      $composableBuilder(column: $table.unitSlug, builder: (column) => column);
}

class $$PullFloorRowsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PullFloorRowsTable,
    PullFloorRow,
    $$PullFloorRowsTableFilterComposer,
    $$PullFloorRowsTableOrderingComposer,
    $$PullFloorRowsTableAnnotationComposer,
    $$PullFloorRowsTableCreateCompanionBuilder,
    $$PullFloorRowsTableUpdateCompanionBuilder,
    (
      PullFloorRow,
      BaseReferences<_$AppDatabase, $PullFloorRowsTable, PullFloorRow>
    ),
    PullFloorRow,
    PrefetchHooks Function()> {
  $$PullFloorRowsTableTableManager(_$AppDatabase db, $PullFloorRowsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PullFloorRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PullFloorRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PullFloorRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> resourceKey = const Value.absent(),
            Value<int> id = const Value.absent(),
            Value<String> uuid = const Value.absent(),
            Value<int> branchId = const Value.absent(),
            Value<String?> floorName = const Value.absent(),
            Value<String?> floorSlug = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String?> paymentMethodName = const Value.absent(),
            Value<String?> paymentMethodSlug = const Value.absent(),
            Value<String?> unitName = const Value.absent(),
            Value<String?> unitSlug = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PullFloorRowsCompanion(
            resourceKey: resourceKey,
            id: id,
            uuid: uuid,
            branchId: branchId,
            floorName: floorName,
            floorSlug: floorSlug,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            paymentMethodName: paymentMethodName,
            paymentMethodSlug: paymentMethodSlug,
            unitName: unitName,
            unitSlug: unitSlug,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String resourceKey,
            required int id,
            required String uuid,
            required int branchId,
            Value<String?> floorName = const Value.absent(),
            Value<String?> floorSlug = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String?> paymentMethodName = const Value.absent(),
            Value<String?> paymentMethodSlug = const Value.absent(),
            Value<String?> unitName = const Value.absent(),
            Value<String?> unitSlug = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PullFloorRowsCompanion.insert(
            resourceKey: resourceKey,
            id: id,
            uuid: uuid,
            branchId: branchId,
            floorName: floorName,
            floorSlug: floorSlug,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            paymentMethodName: paymentMethodName,
            paymentMethodSlug: paymentMethodSlug,
            unitName: unitName,
            unitSlug: unitSlug,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PullFloorRowsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PullFloorRowsTable,
    PullFloorRow,
    $$PullFloorRowsTableFilterComposer,
    $$PullFloorRowsTableOrderingComposer,
    $$PullFloorRowsTableAnnotationComposer,
    $$PullFloorRowsTableCreateCompanionBuilder,
    $$PullFloorRowsTableUpdateCompanionBuilder,
    (
      PullFloorRow,
      BaseReferences<_$AppDatabase, $PullFloorRowsTable, PullFloorRow>
    ),
    PullFloorRow,
    PrefetchHooks Function()>;
typedef $$PullDeliveryServiceRowsTableCreateCompanionBuilder
    = PullDeliveryServiceRowsCompanion Function({
  Value<int> id,
  required String uuid,
  required int branchId,
  required String serviceName,
  required String serviceNameSlug,
  Value<String?> driverStatus,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
});
typedef $$PullDeliveryServiceRowsTableUpdateCompanionBuilder
    = PullDeliveryServiceRowsCompanion Function({
  Value<int> id,
  Value<String> uuid,
  Value<int> branchId,
  Value<String> serviceName,
  Value<String> serviceNameSlug,
  Value<String?> driverStatus,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
});

class $$PullDeliveryServiceRowsTableFilterComposer
    extends Composer<_$AppDatabase, $PullDeliveryServiceRowsTable> {
  $$PullDeliveryServiceRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serviceName => $composableBuilder(
      column: $table.serviceName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serviceNameSlug => $composableBuilder(
      column: $table.serviceNameSlug,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get driverStatus => $composableBuilder(
      column: $table.driverStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));
}

class $$PullDeliveryServiceRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $PullDeliveryServiceRowsTable> {
  $$PullDeliveryServiceRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serviceName => $composableBuilder(
      column: $table.serviceName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serviceNameSlug => $composableBuilder(
      column: $table.serviceNameSlug,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get driverStatus => $composableBuilder(
      column: $table.driverStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$PullDeliveryServiceRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PullDeliveryServiceRowsTable> {
  $$PullDeliveryServiceRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<int> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get serviceName => $composableBuilder(
      column: $table.serviceName, builder: (column) => column);

  GeneratedColumn<String> get serviceNameSlug => $composableBuilder(
      column: $table.serviceNameSlug, builder: (column) => column);

  GeneratedColumn<String> get driverStatus => $composableBuilder(
      column: $table.driverStatus, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$PullDeliveryServiceRowsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PullDeliveryServiceRowsTable,
    PullDeliveryServiceRow,
    $$PullDeliveryServiceRowsTableFilterComposer,
    $$PullDeliveryServiceRowsTableOrderingComposer,
    $$PullDeliveryServiceRowsTableAnnotationComposer,
    $$PullDeliveryServiceRowsTableCreateCompanionBuilder,
    $$PullDeliveryServiceRowsTableUpdateCompanionBuilder,
    (
      PullDeliveryServiceRow,
      BaseReferences<_$AppDatabase, $PullDeliveryServiceRowsTable,
          PullDeliveryServiceRow>
    ),
    PullDeliveryServiceRow,
    PrefetchHooks Function()> {
  $$PullDeliveryServiceRowsTableTableManager(
      _$AppDatabase db, $PullDeliveryServiceRowsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PullDeliveryServiceRowsTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$PullDeliveryServiceRowsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PullDeliveryServiceRowsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> uuid = const Value.absent(),
            Value<int> branchId = const Value.absent(),
            Value<String> serviceName = const Value.absent(),
            Value<String> serviceNameSlug = const Value.absent(),
            Value<String?> driverStatus = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
          }) =>
              PullDeliveryServiceRowsCompanion(
            id: id,
            uuid: uuid,
            branchId: branchId,
            serviceName: serviceName,
            serviceNameSlug: serviceNameSlug,
            driverStatus: driverStatus,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String uuid,
            required int branchId,
            required String serviceName,
            required String serviceNameSlug,
            Value<String?> driverStatus = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
          }) =>
              PullDeliveryServiceRowsCompanion.insert(
            id: id,
            uuid: uuid,
            branchId: branchId,
            serviceName: serviceName,
            serviceNameSlug: serviceNameSlug,
            driverStatus: driverStatus,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PullDeliveryServiceRowsTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $PullDeliveryServiceRowsTable,
        PullDeliveryServiceRow,
        $$PullDeliveryServiceRowsTableFilterComposer,
        $$PullDeliveryServiceRowsTableOrderingComposer,
        $$PullDeliveryServiceRowsTableAnnotationComposer,
        $$PullDeliveryServiceRowsTableCreateCompanionBuilder,
        $$PullDeliveryServiceRowsTableUpdateCompanionBuilder,
        (
          PullDeliveryServiceRow,
          BaseReferences<_$AppDatabase, $PullDeliveryServiceRowsTable,
              PullDeliveryServiceRow>
        ),
        PullDeliveryServiceRow,
        PrefetchHooks Function()>;
typedef $$PullItemRowsTableCreateCompanionBuilder = PullItemRowsCompanion
    Function({
  Value<int> id,
  required String uuid,
  required int branchId,
  required int categoryId,
  required int unitId,
  required String itemName,
  required String itemSlug,
  Value<String?> itemOtherName,
  required String kitchenIds,
  Value<String?> toppingIds,
  required String tax,
  Value<String?> taxPercent,
  required int minimumQty,
  required String itemType,
  required String stockApplicable,
  required String ingredient,
  required String orderType,
  required String deliveryService,
  required String image,
  Value<String?> expiryDate,
  required String active,
  required int isVariant,
  Value<String?> itemVariationsJson,
  Value<String?> itempriceJson,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
});
typedef $$PullItemRowsTableUpdateCompanionBuilder = PullItemRowsCompanion
    Function({
  Value<int> id,
  Value<String> uuid,
  Value<int> branchId,
  Value<int> categoryId,
  Value<int> unitId,
  Value<String> itemName,
  Value<String> itemSlug,
  Value<String?> itemOtherName,
  Value<String> kitchenIds,
  Value<String?> toppingIds,
  Value<String> tax,
  Value<String?> taxPercent,
  Value<int> minimumQty,
  Value<String> itemType,
  Value<String> stockApplicable,
  Value<String> ingredient,
  Value<String> orderType,
  Value<String> deliveryService,
  Value<String> image,
  Value<String?> expiryDate,
  Value<String> active,
  Value<int> isVariant,
  Value<String?> itemVariationsJson,
  Value<String?> itempriceJson,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
});

class $$PullItemRowsTableFilterComposer
    extends Composer<_$AppDatabase, $PullItemRowsTable> {
  $$PullItemRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get unitId => $composableBuilder(
      column: $table.unitId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemName => $composableBuilder(
      column: $table.itemName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemSlug => $composableBuilder(
      column: $table.itemSlug, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemOtherName => $composableBuilder(
      column: $table.itemOtherName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kitchenIds => $composableBuilder(
      column: $table.kitchenIds, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get toppingIds => $composableBuilder(
      column: $table.toppingIds, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tax => $composableBuilder(
      column: $table.tax, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get taxPercent => $composableBuilder(
      column: $table.taxPercent, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minimumQty => $composableBuilder(
      column: $table.minimumQty, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemType => $composableBuilder(
      column: $table.itemType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get stockApplicable => $composableBuilder(
      column: $table.stockApplicable,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ingredient => $composableBuilder(
      column: $table.ingredient, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get orderType => $composableBuilder(
      column: $table.orderType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deliveryService => $composableBuilder(
      column: $table.deliveryService,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get image => $composableBuilder(
      column: $table.image, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get expiryDate => $composableBuilder(
      column: $table.expiryDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get isVariant => $composableBuilder(
      column: $table.isVariant, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemVariationsJson => $composableBuilder(
      column: $table.itemVariationsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itempriceJson => $composableBuilder(
      column: $table.itempriceJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));
}

class $$PullItemRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $PullItemRowsTable> {
  $$PullItemRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get unitId => $composableBuilder(
      column: $table.unitId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemName => $composableBuilder(
      column: $table.itemName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemSlug => $composableBuilder(
      column: $table.itemSlug, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemOtherName => $composableBuilder(
      column: $table.itemOtherName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kitchenIds => $composableBuilder(
      column: $table.kitchenIds, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get toppingIds => $composableBuilder(
      column: $table.toppingIds, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tax => $composableBuilder(
      column: $table.tax, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get taxPercent => $composableBuilder(
      column: $table.taxPercent, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minimumQty => $composableBuilder(
      column: $table.minimumQty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemType => $composableBuilder(
      column: $table.itemType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get stockApplicable => $composableBuilder(
      column: $table.stockApplicable,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ingredient => $composableBuilder(
      column: $table.ingredient, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get orderType => $composableBuilder(
      column: $table.orderType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deliveryService => $composableBuilder(
      column: $table.deliveryService,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get image => $composableBuilder(
      column: $table.image, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get expiryDate => $composableBuilder(
      column: $table.expiryDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get isVariant => $composableBuilder(
      column: $table.isVariant, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemVariationsJson => $composableBuilder(
      column: $table.itemVariationsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itempriceJson => $composableBuilder(
      column: $table.itempriceJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$PullItemRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PullItemRowsTable> {
  $$PullItemRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<int> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<int> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => column);

  GeneratedColumn<int> get unitId =>
      $composableBuilder(column: $table.unitId, builder: (column) => column);

  GeneratedColumn<String> get itemName =>
      $composableBuilder(column: $table.itemName, builder: (column) => column);

  GeneratedColumn<String> get itemSlug =>
      $composableBuilder(column: $table.itemSlug, builder: (column) => column);

  GeneratedColumn<String> get itemOtherName => $composableBuilder(
      column: $table.itemOtherName, builder: (column) => column);

  GeneratedColumn<String> get kitchenIds => $composableBuilder(
      column: $table.kitchenIds, builder: (column) => column);

  GeneratedColumn<String> get toppingIds => $composableBuilder(
      column: $table.toppingIds, builder: (column) => column);

  GeneratedColumn<String> get tax =>
      $composableBuilder(column: $table.tax, builder: (column) => column);

  GeneratedColumn<String> get taxPercent => $composableBuilder(
      column: $table.taxPercent, builder: (column) => column);

  GeneratedColumn<int> get minimumQty => $composableBuilder(
      column: $table.minimumQty, builder: (column) => column);

  GeneratedColumn<String> get itemType =>
      $composableBuilder(column: $table.itemType, builder: (column) => column);

  GeneratedColumn<String> get stockApplicable => $composableBuilder(
      column: $table.stockApplicable, builder: (column) => column);

  GeneratedColumn<String> get ingredient => $composableBuilder(
      column: $table.ingredient, builder: (column) => column);

  GeneratedColumn<String> get orderType =>
      $composableBuilder(column: $table.orderType, builder: (column) => column);

  GeneratedColumn<String> get deliveryService => $composableBuilder(
      column: $table.deliveryService, builder: (column) => column);

  GeneratedColumn<String> get image =>
      $composableBuilder(column: $table.image, builder: (column) => column);

  GeneratedColumn<String> get expiryDate => $composableBuilder(
      column: $table.expiryDate, builder: (column) => column);

  GeneratedColumn<String> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<int> get isVariant =>
      $composableBuilder(column: $table.isVariant, builder: (column) => column);

  GeneratedColumn<String> get itemVariationsJson => $composableBuilder(
      column: $table.itemVariationsJson, builder: (column) => column);

  GeneratedColumn<String> get itempriceJson => $composableBuilder(
      column: $table.itempriceJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$PullItemRowsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PullItemRowsTable,
    PullItemRow,
    $$PullItemRowsTableFilterComposer,
    $$PullItemRowsTableOrderingComposer,
    $$PullItemRowsTableAnnotationComposer,
    $$PullItemRowsTableCreateCompanionBuilder,
    $$PullItemRowsTableUpdateCompanionBuilder,
    (
      PullItemRow,
      BaseReferences<_$AppDatabase, $PullItemRowsTable, PullItemRow>
    ),
    PullItemRow,
    PrefetchHooks Function()> {
  $$PullItemRowsTableTableManager(_$AppDatabase db, $PullItemRowsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PullItemRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PullItemRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PullItemRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> uuid = const Value.absent(),
            Value<int> branchId = const Value.absent(),
            Value<int> categoryId = const Value.absent(),
            Value<int> unitId = const Value.absent(),
            Value<String> itemName = const Value.absent(),
            Value<String> itemSlug = const Value.absent(),
            Value<String?> itemOtherName = const Value.absent(),
            Value<String> kitchenIds = const Value.absent(),
            Value<String?> toppingIds = const Value.absent(),
            Value<String> tax = const Value.absent(),
            Value<String?> taxPercent = const Value.absent(),
            Value<int> minimumQty = const Value.absent(),
            Value<String> itemType = const Value.absent(),
            Value<String> stockApplicable = const Value.absent(),
            Value<String> ingredient = const Value.absent(),
            Value<String> orderType = const Value.absent(),
            Value<String> deliveryService = const Value.absent(),
            Value<String> image = const Value.absent(),
            Value<String?> expiryDate = const Value.absent(),
            Value<String> active = const Value.absent(),
            Value<int> isVariant = const Value.absent(),
            Value<String?> itemVariationsJson = const Value.absent(),
            Value<String?> itempriceJson = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
          }) =>
              PullItemRowsCompanion(
            id: id,
            uuid: uuid,
            branchId: branchId,
            categoryId: categoryId,
            unitId: unitId,
            itemName: itemName,
            itemSlug: itemSlug,
            itemOtherName: itemOtherName,
            kitchenIds: kitchenIds,
            toppingIds: toppingIds,
            tax: tax,
            taxPercent: taxPercent,
            minimumQty: minimumQty,
            itemType: itemType,
            stockApplicable: stockApplicable,
            ingredient: ingredient,
            orderType: orderType,
            deliveryService: deliveryService,
            image: image,
            expiryDate: expiryDate,
            active: active,
            isVariant: isVariant,
            itemVariationsJson: itemVariationsJson,
            itempriceJson: itempriceJson,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String uuid,
            required int branchId,
            required int categoryId,
            required int unitId,
            required String itemName,
            required String itemSlug,
            Value<String?> itemOtherName = const Value.absent(),
            required String kitchenIds,
            Value<String?> toppingIds = const Value.absent(),
            required String tax,
            Value<String?> taxPercent = const Value.absent(),
            required int minimumQty,
            required String itemType,
            required String stockApplicable,
            required String ingredient,
            required String orderType,
            required String deliveryService,
            required String image,
            Value<String?> expiryDate = const Value.absent(),
            required String active,
            required int isVariant,
            Value<String?> itemVariationsJson = const Value.absent(),
            Value<String?> itempriceJson = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
          }) =>
              PullItemRowsCompanion.insert(
            id: id,
            uuid: uuid,
            branchId: branchId,
            categoryId: categoryId,
            unitId: unitId,
            itemName: itemName,
            itemSlug: itemSlug,
            itemOtherName: itemOtherName,
            kitchenIds: kitchenIds,
            toppingIds: toppingIds,
            tax: tax,
            taxPercent: taxPercent,
            minimumQty: minimumQty,
            itemType: itemType,
            stockApplicable: stockApplicable,
            ingredient: ingredient,
            orderType: orderType,
            deliveryService: deliveryService,
            image: image,
            expiryDate: expiryDate,
            active: active,
            isVariant: isVariant,
            itemVariationsJson: itemVariationsJson,
            itempriceJson: itempriceJson,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PullItemRowsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PullItemRowsTable,
    PullItemRow,
    $$PullItemRowsTableFilterComposer,
    $$PullItemRowsTableOrderingComposer,
    $$PullItemRowsTableAnnotationComposer,
    $$PullItemRowsTableCreateCompanionBuilder,
    $$PullItemRowsTableUpdateCompanionBuilder,
    (
      PullItemRow,
      BaseReferences<_$AppDatabase, $PullItemRowsTable, PullItemRow>
    ),
    PullItemRow,
    PrefetchHooks Function()>;
typedef $$SyncPaginationStatesTableCreateCompanionBuilder
    = SyncPaginationStatesCompanion Function({
  required String resourceKey,
  Value<int?> currentPage,
  Value<int?> pageFrom,
  Value<int?> lastPage,
  Value<int?> perPage,
  Value<int?> pageTo,
  Value<int?> total,
  Value<int> rowid,
});
typedef $$SyncPaginationStatesTableUpdateCompanionBuilder
    = SyncPaginationStatesCompanion Function({
  Value<String> resourceKey,
  Value<int?> currentPage,
  Value<int?> pageFrom,
  Value<int?> lastPage,
  Value<int?> perPage,
  Value<int?> pageTo,
  Value<int?> total,
  Value<int> rowid,
});

class $$SyncPaginationStatesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncPaginationStatesTable> {
  $$SyncPaginationStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get resourceKey => $composableBuilder(
      column: $table.resourceKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get currentPage => $composableBuilder(
      column: $table.currentPage, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get pageFrom => $composableBuilder(
      column: $table.pageFrom, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastPage => $composableBuilder(
      column: $table.lastPage, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get perPage => $composableBuilder(
      column: $table.perPage, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get pageTo => $composableBuilder(
      column: $table.pageTo, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get total => $composableBuilder(
      column: $table.total, builder: (column) => ColumnFilters(column));
}

class $$SyncPaginationStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncPaginationStatesTable> {
  $$SyncPaginationStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get resourceKey => $composableBuilder(
      column: $table.resourceKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get currentPage => $composableBuilder(
      column: $table.currentPage, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get pageFrom => $composableBuilder(
      column: $table.pageFrom, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastPage => $composableBuilder(
      column: $table.lastPage, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get perPage => $composableBuilder(
      column: $table.perPage, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get pageTo => $composableBuilder(
      column: $table.pageTo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get total => $composableBuilder(
      column: $table.total, builder: (column) => ColumnOrderings(column));
}

class $$SyncPaginationStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncPaginationStatesTable> {
  $$SyncPaginationStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get resourceKey => $composableBuilder(
      column: $table.resourceKey, builder: (column) => column);

  GeneratedColumn<int> get currentPage => $composableBuilder(
      column: $table.currentPage, builder: (column) => column);

  GeneratedColumn<int> get pageFrom =>
      $composableBuilder(column: $table.pageFrom, builder: (column) => column);

  GeneratedColumn<int> get lastPage =>
      $composableBuilder(column: $table.lastPage, builder: (column) => column);

  GeneratedColumn<int> get perPage =>
      $composableBuilder(column: $table.perPage, builder: (column) => column);

  GeneratedColumn<int> get pageTo =>
      $composableBuilder(column: $table.pageTo, builder: (column) => column);

  GeneratedColumn<int> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);
}

class $$SyncPaginationStatesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncPaginationStatesTable,
    SyncPaginationState,
    $$SyncPaginationStatesTableFilterComposer,
    $$SyncPaginationStatesTableOrderingComposer,
    $$SyncPaginationStatesTableAnnotationComposer,
    $$SyncPaginationStatesTableCreateCompanionBuilder,
    $$SyncPaginationStatesTableUpdateCompanionBuilder,
    (
      SyncPaginationState,
      BaseReferences<_$AppDatabase, $SyncPaginationStatesTable,
          SyncPaginationState>
    ),
    SyncPaginationState,
    PrefetchHooks Function()> {
  $$SyncPaginationStatesTableTableManager(
      _$AppDatabase db, $SyncPaginationStatesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncPaginationStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncPaginationStatesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncPaginationStatesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> resourceKey = const Value.absent(),
            Value<int?> currentPage = const Value.absent(),
            Value<int?> pageFrom = const Value.absent(),
            Value<int?> lastPage = const Value.absent(),
            Value<int?> perPage = const Value.absent(),
            Value<int?> pageTo = const Value.absent(),
            Value<int?> total = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncPaginationStatesCompanion(
            resourceKey: resourceKey,
            currentPage: currentPage,
            pageFrom: pageFrom,
            lastPage: lastPage,
            perPage: perPage,
            pageTo: pageTo,
            total: total,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String resourceKey,
            Value<int?> currentPage = const Value.absent(),
            Value<int?> pageFrom = const Value.absent(),
            Value<int?> lastPage = const Value.absent(),
            Value<int?> perPage = const Value.absent(),
            Value<int?> pageTo = const Value.absent(),
            Value<int?> total = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncPaginationStatesCompanion.insert(
            resourceKey: resourceKey,
            currentPage: currentPage,
            pageFrom: pageFrom,
            lastPage: lastPage,
            perPage: perPage,
            pageTo: pageTo,
            total: total,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncPaginationStatesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $SyncPaginationStatesTable,
        SyncPaginationState,
        $$SyncPaginationStatesTableFilterComposer,
        $$SyncPaginationStatesTableOrderingComposer,
        $$SyncPaginationStatesTableAnnotationComposer,
        $$SyncPaginationStatesTableCreateCompanionBuilder,
        $$SyncPaginationStatesTableUpdateCompanionBuilder,
        (
          SyncPaginationState,
          BaseReferences<_$AppDatabase, $SyncPaginationStatesTable,
              SyncPaginationState>
        ),
        SyncPaginationState,
        PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$KitchensTableTableManager get kitchens =>
      $$KitchensTableTableManager(_db, _db.kitchens);
  $$KitchenPrintersTableTableManager get kitchenPrinters =>
      $$KitchenPrintersTableTableManager(_db, _db.kitchenPrinters);
  $$ItemsTableTableManager get items =>
      $$ItemsTableTableManager(_db, _db.items);
  $$ItemVariantsTableTableManager get itemVariants =>
      $$ItemVariantsTableTableManager(_db, _db.itemVariants);
  $$ItemToppingsTableTableManager get itemToppings =>
      $$ItemToppingsTableTableManager(_db, _db.itemToppings);
  $$ToppingGroupsTableTableManager get toppingGroups =>
      $$ToppingGroupsTableTableManager(_db, _db.toppingGroups);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$CartsTableTableManager get carts =>
      $$CartsTableTableManager(_db, _db.carts);
  $$CartItemsTableTableManager get cartItems =>
      $$CartItemsTableTableManager(_db, _db.cartItems);
  $$DriversTableTableManager get drivers =>
      $$DriversTableTableManager(_db, _db.drivers);
  $$OrdersTableTableManager get orders =>
      $$OrdersTableTableManager(_db, _db.orders);
  $$OrderLogsTableTableManager get orderLogs =>
      $$OrderLogsTableTableManager(_db, _db.orderLogs);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db, _db.customers);
  $$DeliveryPartnersTableTableManager get deliveryPartners =>
      $$DeliveryPartnersTableTableManager(_db, _db.deliveryPartners);
  $$DiningFloorsTableTableManager get diningFloors =>
      $$DiningFloorsTableTableManager(_db, _db.diningFloors);
  $$DiningTablesTableTableManager get diningTables =>
      $$DiningTablesTableTableManager(_db, _db.diningTables);
  $$BranchesTableTableManager get branches =>
      $$BranchesTableTableManager(_db, _db.branches);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$PullCategoryRowsTableTableManager get pullCategoryRows =>
      $$PullCategoryRowsTableTableManager(_db, _db.pullCategoryRows);
  $$PullFloorRowsTableTableManager get pullFloorRows =>
      $$PullFloorRowsTableTableManager(_db, _db.pullFloorRows);
  $$PullDeliveryServiceRowsTableTableManager get pullDeliveryServiceRows =>
      $$PullDeliveryServiceRowsTableTableManager(
          _db, _db.pullDeliveryServiceRows);
  $$PullItemRowsTableTableManager get pullItemRows =>
      $$PullItemRowsTableTableManager(_db, _db.pullItemRows);
  $$SyncPaginationStatesTableTableManager get syncPaginationStates =>
      $$SyncPaginationStatesTableTableManager(_db, _db.syncPaginationStates);
}

mixin _$UsersDaoMixin on DatabaseAccessor<AppDatabase> {
  $UsersTable get users => attachedDatabase.users;
}
mixin _$CategoryDaoMixin on DatabaseAccessor<AppDatabase> {
  $CategoriesTable get categories => attachedDatabase.categories;
}
mixin _$CartsDaoMixin on DatabaseAccessor<AppDatabase> {
  $CartsTable get carts => attachedDatabase.carts;
  $ItemsTable get items => attachedDatabase.items;
  $ItemVariantsTable get itemVariants => attachedDatabase.itemVariants;
  $ItemToppingsTable get itemToppings => attachedDatabase.itemToppings;
  $CartItemsTable get cartItems => attachedDatabase.cartItems;
}
mixin _$ItemDaoMixin on DatabaseAccessor<AppDatabase> {
  $KitchensTable get kitchens => attachedDatabase.kitchens;
  $KitchenPrintersTable get kitchenPrinters => attachedDatabase.kitchenPrinters;
  $ItemsTable get items => attachedDatabase.items;
  $ItemVariantsTable get itemVariants => attachedDatabase.itemVariants;
  $ItemToppingsTable get itemToppings => attachedDatabase.itemToppings;
  $ToppingGroupsTable get toppingGroups => attachedDatabase.toppingGroups;
}
mixin _$SessionDaoMixin on DatabaseAccessor<AppDatabase> {
  $SessionsTable get sessions => attachedDatabase.sessions;
}
mixin _$OrdersDaoMixin on DatabaseAccessor<AppDatabase> {
  $CartsTable get carts => attachedDatabase.carts;
  $DriversTable get drivers => attachedDatabase.drivers;
  $OrdersTable get orders => attachedDatabase.orders;
  $OrderLogsTable get orderLogs => attachedDatabase.orderLogs;
  $ItemsTable get items => attachedDatabase.items;
  $ItemVariantsTable get itemVariants => attachedDatabase.itemVariants;
  $ItemToppingsTable get itemToppings => attachedDatabase.itemToppings;
  $CartItemsTable get cartItems => attachedDatabase.cartItems;
}
mixin _$CustomersDaoMixin on DatabaseAccessor<AppDatabase> {
  $CustomersTable get customers => attachedDatabase.customers;
}
mixin _$DeliveryPartnersDaoMixin on DatabaseAccessor<AppDatabase> {
  $DeliveryPartnersTable get deliveryPartners =>
      attachedDatabase.deliveryPartners;
}
mixin _$DriversDaoMixin on DatabaseAccessor<AppDatabase> {
  $DriversTable get drivers => attachedDatabase.drivers;
}
mixin _$DiningTablesDaoMixin on DatabaseAccessor<AppDatabase> {
  $DiningFloorsTable get diningFloors => attachedDatabase.diningFloors;
  $DiningTablesTable get diningTables => attachedDatabase.diningTables;
}
mixin _$BranchesDaoMixin on DatabaseAccessor<AppDatabase> {
  $BranchesTable get branches => attachedDatabase.branches;
}
mixin _$SettingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $SettingsTable get settings => attachedDatabase.settings;
}
mixin _$PullDataDaoMixin on DatabaseAccessor<AppDatabase> {
  $PullCategoryRowsTable get pullCategoryRows =>
      attachedDatabase.pullCategoryRows;
  $PullFloorRowsTable get pullFloorRows => attachedDatabase.pullFloorRows;
  $PullDeliveryServiceRowsTable get pullDeliveryServiceRows =>
      attachedDatabase.pullDeliveryServiceRows;
  $PullItemRowsTable get pullItemRows => attachedDatabase.pullItemRows;
  $SyncPaginationStatesTable get syncPaginationStates =>
      attachedDatabase.syncPaginationStates;
}
