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
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _usernameMeta =
      const VerificationMeta('username');
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
      'username', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _passwordMeta =
      const VerificationMeta('password');
  @override
  late final GeneratedColumn<String> password = GeneratedColumn<String>(
      'password', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _employeeIdMeta =
      const VerificationMeta('employeeId');
  @override
  late final GeneratedColumn<String> employeeId = GeneratedColumn<String>(
      'employee_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _companyIdMeta =
      const VerificationMeta('companyId');
  @override
  late final GeneratedColumn<int> companyId = GeneratedColumn<int>(
      'company_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _companyNameMeta =
      const VerificationMeta('companyName');
  @override
  late final GeneratedColumn<String> companyName = GeneratedColumn<String>(
      'company_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _branchNameMeta =
      const VerificationMeta('branchName');
  @override
  late final GeneratedColumn<String> branchName = GeneratedColumn<String>(
      'branch_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _companyLogoMeta =
      const VerificationMeta('companyLogo');
  @override
  late final GeneratedColumn<String> companyLogo = GeneratedColumn<String>(
      'company_logo', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _companyLogoLocalMeta =
      const VerificationMeta('companyLogoLocal');
  @override
  late final GeneratedColumn<String> companyLogoLocal = GeneratedColumn<String>(
      'company_logo_local', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _branchIdMeta =
      const VerificationMeta('branchId');
  @override
  late final GeneratedColumn<int> branchId = GeneratedColumn<int>(
      'branch_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        username,
        password,
        employeeId,
        companyId,
        companyName,
        branchName,
        companyLogo,
        companyLogoLocal,
        branchId,
        role
      ];
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
    if (data.containsKey('username')) {
      context.handle(_usernameMeta,
          username.isAcceptableOrUnknown(data['username']!, _usernameMeta));
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('password')) {
      context.handle(_passwordMeta,
          password.isAcceptableOrUnknown(data['password']!, _passwordMeta));
    } else if (isInserting) {
      context.missing(_passwordMeta);
    }
    if (data.containsKey('employee_id')) {
      context.handle(
          _employeeIdMeta,
          employeeId.isAcceptableOrUnknown(
              data['employee_id']!, _employeeIdMeta));
    } else if (isInserting) {
      context.missing(_employeeIdMeta);
    }
    if (data.containsKey('company_id')) {
      context.handle(_companyIdMeta,
          companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta));
    } else if (isInserting) {
      context.missing(_companyIdMeta);
    }
    if (data.containsKey('company_name')) {
      context.handle(
          _companyNameMeta,
          companyName.isAcceptableOrUnknown(
              data['company_name']!, _companyNameMeta));
    } else if (isInserting) {
      context.missing(_companyNameMeta);
    }
    if (data.containsKey('branch_name')) {
      context.handle(
          _branchNameMeta,
          branchName.isAcceptableOrUnknown(
              data['branch_name']!, _branchNameMeta));
    } else if (isInserting) {
      context.missing(_branchNameMeta);
    }
    if (data.containsKey('company_logo')) {
      context.handle(
          _companyLogoMeta,
          companyLogo.isAcceptableOrUnknown(
              data['company_logo']!, _companyLogoMeta));
    } else if (isInserting) {
      context.missing(_companyLogoMeta);
    }
    if (data.containsKey('company_logo_local')) {
      context.handle(
          _companyLogoLocalMeta,
          companyLogoLocal.isAcceptableOrUnknown(
              data['company_logo_local']!, _companyLogoLocalMeta));
    } else if (isInserting) {
      context.missing(_companyLogoLocalMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(_branchIdMeta,
          branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta));
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
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
      username: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}username'])!,
      password: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}password'])!,
      employeeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}employee_id'])!,
      companyId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}company_id'])!,
      companyName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}company_name'])!,
      branchName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}branch_name'])!,
      companyLogo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}company_logo'])!,
      companyLogoLocal: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}company_logo_local'])!,
      branchId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}branch_id'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final int id;
  final String username;
  final String password;
  final String employeeId;
  final int companyId;
  final String companyName;
  final String branchName;
  final String companyLogo;
  final String companyLogoLocal;
  final int branchId;
  final String role;
  const User(
      {required this.id,
      required this.username,
      required this.password,
      required this.employeeId,
      required this.companyId,
      required this.companyName,
      required this.branchName,
      required this.companyLogo,
      required this.companyLogoLocal,
      required this.branchId,
      required this.role});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['username'] = Variable<String>(username);
    map['password'] = Variable<String>(password);
    map['employee_id'] = Variable<String>(employeeId);
    map['company_id'] = Variable<int>(companyId);
    map['company_name'] = Variable<String>(companyName);
    map['branch_name'] = Variable<String>(branchName);
    map['company_logo'] = Variable<String>(companyLogo);
    map['company_logo_local'] = Variable<String>(companyLogoLocal);
    map['branch_id'] = Variable<int>(branchId);
    map['role'] = Variable<String>(role);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      username: Value(username),
      password: Value(password),
      employeeId: Value(employeeId),
      companyId: Value(companyId),
      companyName: Value(companyName),
      branchName: Value(branchName),
      companyLogo: Value(companyLogo),
      companyLogoLocal: Value(companyLogoLocal),
      branchId: Value(branchId),
      role: Value(role),
    );
  }

  factory User.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<int>(json['id']),
      username: serializer.fromJson<String>(json['username']),
      password: serializer.fromJson<String>(json['password']),
      employeeId: serializer.fromJson<String>(json['employeeId']),
      companyId: serializer.fromJson<int>(json['companyId']),
      companyName: serializer.fromJson<String>(json['companyName']),
      branchName: serializer.fromJson<String>(json['branchName']),
      companyLogo: serializer.fromJson<String>(json['companyLogo']),
      companyLogoLocal: serializer.fromJson<String>(json['companyLogoLocal']),
      branchId: serializer.fromJson<int>(json['branchId']),
      role: serializer.fromJson<String>(json['role']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'username': serializer.toJson<String>(username),
      'password': serializer.toJson<String>(password),
      'employeeId': serializer.toJson<String>(employeeId),
      'companyId': serializer.toJson<int>(companyId),
      'companyName': serializer.toJson<String>(companyName),
      'branchName': serializer.toJson<String>(branchName),
      'companyLogo': serializer.toJson<String>(companyLogo),
      'companyLogoLocal': serializer.toJson<String>(companyLogoLocal),
      'branchId': serializer.toJson<int>(branchId),
      'role': serializer.toJson<String>(role),
    };
  }

  User copyWith(
          {int? id,
          String? username,
          String? password,
          String? employeeId,
          int? companyId,
          String? companyName,
          String? branchName,
          String? companyLogo,
          String? companyLogoLocal,
          int? branchId,
          String? role}) =>
      User(
        id: id ?? this.id,
        username: username ?? this.username,
        password: password ?? this.password,
        employeeId: employeeId ?? this.employeeId,
        companyId: companyId ?? this.companyId,
        companyName: companyName ?? this.companyName,
        branchName: branchName ?? this.branchName,
        companyLogo: companyLogo ?? this.companyLogo,
        companyLogoLocal: companyLogoLocal ?? this.companyLogoLocal,
        branchId: branchId ?? this.branchId,
        role: role ?? this.role,
      );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      username: data.username.present ? data.username.value : this.username,
      password: data.password.present ? data.password.value : this.password,
      employeeId:
          data.employeeId.present ? data.employeeId.value : this.employeeId,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      companyName:
          data.companyName.present ? data.companyName.value : this.companyName,
      branchName:
          data.branchName.present ? data.branchName.value : this.branchName,
      companyLogo:
          data.companyLogo.present ? data.companyLogo.value : this.companyLogo,
      companyLogoLocal: data.companyLogoLocal.present
          ? data.companyLogoLocal.value
          : this.companyLogoLocal,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      role: data.role.present ? data.role.value : this.role,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('password: $password, ')
          ..write('employeeId: $employeeId, ')
          ..write('companyId: $companyId, ')
          ..write('companyName: $companyName, ')
          ..write('branchName: $branchName, ')
          ..write('companyLogo: $companyLogo, ')
          ..write('companyLogoLocal: $companyLogoLocal, ')
          ..write('branchId: $branchId, ')
          ..write('role: $role')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, username, password, employeeId, companyId,
      companyName, branchName, companyLogo, companyLogoLocal, branchId, role);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.username == this.username &&
          other.password == this.password &&
          other.employeeId == this.employeeId &&
          other.companyId == this.companyId &&
          other.companyName == this.companyName &&
          other.branchName == this.branchName &&
          other.companyLogo == this.companyLogo &&
          other.companyLogoLocal == this.companyLogoLocal &&
          other.branchId == this.branchId &&
          other.role == this.role);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<int> id;
  final Value<String> username;
  final Value<String> password;
  final Value<String> employeeId;
  final Value<int> companyId;
  final Value<String> companyName;
  final Value<String> branchName;
  final Value<String> companyLogo;
  final Value<String> companyLogoLocal;
  final Value<int> branchId;
  final Value<String> role;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.username = const Value.absent(),
    this.password = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.companyId = const Value.absent(),
    this.companyName = const Value.absent(),
    this.branchName = const Value.absent(),
    this.companyLogo = const Value.absent(),
    this.companyLogoLocal = const Value.absent(),
    this.branchId = const Value.absent(),
    this.role = const Value.absent(),
  });
  UsersCompanion.insert({
    this.id = const Value.absent(),
    required String username,
    required String password,
    required String employeeId,
    required int companyId,
    required String companyName,
    required String branchName,
    required String companyLogo,
    required String companyLogoLocal,
    required int branchId,
    required String role,
  })  : username = Value(username),
        password = Value(password),
        employeeId = Value(employeeId),
        companyId = Value(companyId),
        companyName = Value(companyName),
        branchName = Value(branchName),
        companyLogo = Value(companyLogo),
        companyLogoLocal = Value(companyLogoLocal),
        branchId = Value(branchId),
        role = Value(role);
  static Insertable<User> custom({
    Expression<int>? id,
    Expression<String>? username,
    Expression<String>? password,
    Expression<String>? employeeId,
    Expression<int>? companyId,
    Expression<String>? companyName,
    Expression<String>? branchName,
    Expression<String>? companyLogo,
    Expression<String>? companyLogoLocal,
    Expression<int>? branchId,
    Expression<String>? role,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (username != null) 'username': username,
      if (password != null) 'password': password,
      if (employeeId != null) 'employee_id': employeeId,
      if (companyId != null) 'company_id': companyId,
      if (companyName != null) 'company_name': companyName,
      if (branchName != null) 'branch_name': branchName,
      if (companyLogo != null) 'company_logo': companyLogo,
      if (companyLogoLocal != null) 'company_logo_local': companyLogoLocal,
      if (branchId != null) 'branch_id': branchId,
      if (role != null) 'role': role,
    });
  }

  UsersCompanion copyWith(
      {Value<int>? id,
      Value<String>? username,
      Value<String>? password,
      Value<String>? employeeId,
      Value<int>? companyId,
      Value<String>? companyName,
      Value<String>? branchName,
      Value<String>? companyLogo,
      Value<String>? companyLogoLocal,
      Value<int>? branchId,
      Value<String>? role}) {
    return UsersCompanion(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      employeeId: employeeId ?? this.employeeId,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      branchName: branchName ?? this.branchName,
      companyLogo: companyLogo ?? this.companyLogo,
      companyLogoLocal: companyLogoLocal ?? this.companyLogoLocal,
      branchId: branchId ?? this.branchId,
      role: role ?? this.role,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (password.present) {
      map['password'] = Variable<String>(password.value);
    }
    if (employeeId.present) {
      map['employee_id'] = Variable<String>(employeeId.value);
    }
    if (companyId.present) {
      map['company_id'] = Variable<int>(companyId.value);
    }
    if (companyName.present) {
      map['company_name'] = Variable<String>(companyName.value);
    }
    if (branchName.present) {
      map['branch_name'] = Variable<String>(branchName.value);
    }
    if (companyLogo.present) {
      map['company_logo'] = Variable<String>(companyLogo.value);
    }
    if (companyLogoLocal.present) {
      map['company_logo_local'] = Variable<String>(companyLogoLocal.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<int>(branchId.value);
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
          ..write('username: $username, ')
          ..write('password: $password, ')
          ..write('employeeId: $employeeId, ')
          ..write('companyId: $companyId, ')
          ..write('companyName: $companyName, ')
          ..write('branchName: $branchName, ')
          ..write('companyLogo: $companyLogo, ')
          ..write('companyLogoLocal: $companyLogoLocal, ')
          ..write('branchId: $branchId, ')
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
  @override
  List<GeneratedColumn> get $columns => [id, name, otherName];
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
  const Category(
      {required this.id, required this.name, required this.otherName});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['other_name'] = Variable<String>(otherName);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      otherName: Value(otherName),
    );
  }

  factory Category.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      otherName: serializer.fromJson<String>(json['otherName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'otherName': serializer.toJson<String>(otherName),
    };
  }

  Category copyWith({int? id, String? name, String? otherName}) => Category(
        id: id ?? this.id,
        name: name ?? this.name,
        otherName: otherName ?? this.otherName,
      );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      otherName: data.otherName.present ? data.otherName.value : this.otherName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('otherName: $otherName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, otherName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.name == this.name &&
          other.otherName == this.otherName);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> otherName;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.otherName = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String otherName,
  })  : name = Value(name),
        otherName = Value(otherName);
  static Insertable<Category> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? otherName,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (otherName != null) 'other_name': otherName,
    });
  }

  CategoriesCompanion copyWith(
      {Value<int>? id, Value<String>? name, Value<String>? otherName}) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      otherName: otherName ?? this.otherName,
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('otherName: $otherName')
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
  @override
  List<GeneratedColumn> get $columns => [id, name, printerIp, printerPort];
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
  const Kitchen(
      {required this.id,
      required this.name,
      this.printerIp,
      required this.printerPort});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || printerIp != null) {
      map['printer_ip'] = Variable<String>(printerIp);
    }
    map['printer_port'] = Variable<int>(printerPort);
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
    };
  }

  Kitchen copyWith(
          {int? id,
          String? name,
          Value<String?> printerIp = const Value.absent(),
          int? printerPort}) =>
      Kitchen(
        id: id ?? this.id,
        name: name ?? this.name,
        printerIp: printerIp.present ? printerIp.value : this.printerIp,
        printerPort: printerPort ?? this.printerPort,
      );
  Kitchen copyWithCompanion(KitchensCompanion data) {
    return Kitchen(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      printerIp: data.printerIp.present ? data.printerIp.value : this.printerIp,
      printerPort:
          data.printerPort.present ? data.printerPort.value : this.printerPort,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Kitchen(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('printerIp: $printerIp, ')
          ..write('printerPort: $printerPort')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, printerIp, printerPort);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Kitchen &&
          other.id == this.id &&
          other.name == this.name &&
          other.printerIp == this.printerIp &&
          other.printerPort == this.printerPort);
}

class KitchensCompanion extends UpdateCompanion<Kitchen> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> printerIp;
  final Value<int> printerPort;
  const KitchensCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.printerIp = const Value.absent(),
    this.printerPort = const Value.absent(),
  });
  KitchensCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.printerIp = const Value.absent(),
    this.printerPort = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Kitchen> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? printerIp,
    Expression<int>? printerPort,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (printerIp != null) 'printer_ip': printerIp,
      if (printerPort != null) 'printer_port': printerPort,
    });
  }

  KitchensCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String?>? printerIp,
      Value<int>? printerPort}) {
    return KitchensCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      printerIp: printerIp ?? this.printerIp,
      printerPort: printerPort ?? this.printerPort,
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KitchensCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('printerIp: $printerIp, ')
          ..write('printerPort: $printerPort')
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
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        otherName,
        sku,
        price,
        stock,
        imagePath,
        localImagePath,
        categoryName,
        categoryOtherName,
        barcode,
        categoryId,
        kitchenId,
        kitchenName
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
  final String? imagePath;
  final String? localImagePath;
  final String categoryName;
  final String categoryOtherName;
  final String barcode;
  final int categoryId;
  final int? kitchenId;
  final String? kitchenName;
  const Item(
      {required this.id,
      required this.name,
      required this.otherName,
      required this.sku,
      required this.price,
      required this.stock,
      this.imagePath,
      this.localImagePath,
      required this.categoryName,
      required this.categoryOtherName,
      required this.barcode,
      required this.categoryId,
      this.kitchenId,
      this.kitchenName});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['other_name'] = Variable<String>(otherName);
    map['sku'] = Variable<String>(sku);
    map['price'] = Variable<double>(price);
    map['stock'] = Variable<int>(stock);
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
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      localImagePath: serializer.fromJson<String?>(json['localImagePath']),
      categoryName: serializer.fromJson<String>(json['categoryName']),
      categoryOtherName: serializer.fromJson<String>(json['categoryOtherName']),
      barcode: serializer.fromJson<String>(json['barcode']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      kitchenId: serializer.fromJson<int?>(json['kitchenId']),
      kitchenName: serializer.fromJson<String?>(json['kitchenName']),
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
      'imagePath': serializer.toJson<String?>(imagePath),
      'localImagePath': serializer.toJson<String?>(localImagePath),
      'categoryName': serializer.toJson<String>(categoryName),
      'categoryOtherName': serializer.toJson<String>(categoryOtherName),
      'barcode': serializer.toJson<String>(barcode),
      'categoryId': serializer.toJson<int>(categoryId),
      'kitchenId': serializer.toJson<int?>(kitchenId),
      'kitchenName': serializer.toJson<String?>(kitchenName),
    };
  }

  Item copyWith(
          {int? id,
          String? name,
          String? otherName,
          String? sku,
          double? price,
          int? stock,
          Value<String?> imagePath = const Value.absent(),
          Value<String?> localImagePath = const Value.absent(),
          String? categoryName,
          String? categoryOtherName,
          String? barcode,
          int? categoryId,
          Value<int?> kitchenId = const Value.absent(),
          Value<String?> kitchenName = const Value.absent()}) =>
      Item(
        id: id ?? this.id,
        name: name ?? this.name,
        otherName: otherName ?? this.otherName,
        sku: sku ?? this.sku,
        price: price ?? this.price,
        stock: stock ?? this.stock,
        imagePath: imagePath.present ? imagePath.value : this.imagePath,
        localImagePath:
            localImagePath.present ? localImagePath.value : this.localImagePath,
        categoryName: categoryName ?? this.categoryName,
        categoryOtherName: categoryOtherName ?? this.categoryOtherName,
        barcode: barcode ?? this.barcode,
        categoryId: categoryId ?? this.categoryId,
        kitchenId: kitchenId.present ? kitchenId.value : this.kitchenId,
        kitchenName: kitchenName.present ? kitchenName.value : this.kitchenName,
      );
  Item copyWithCompanion(ItemsCompanion data) {
    return Item(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      otherName: data.otherName.present ? data.otherName.value : this.otherName,
      sku: data.sku.present ? data.sku.value : this.sku,
      price: data.price.present ? data.price.value : this.price,
      stock: data.stock.present ? data.stock.value : this.stock,
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
          ..write('imagePath: $imagePath, ')
          ..write('localImagePath: $localImagePath, ')
          ..write('categoryName: $categoryName, ')
          ..write('categoryOtherName: $categoryOtherName, ')
          ..write('barcode: $barcode, ')
          ..write('categoryId: $categoryId, ')
          ..write('kitchenId: $kitchenId, ')
          ..write('kitchenName: $kitchenName')
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
      imagePath,
      localImagePath,
      categoryName,
      categoryOtherName,
      barcode,
      categoryId,
      kitchenId,
      kitchenName);
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
          other.imagePath == this.imagePath &&
          other.localImagePath == this.localImagePath &&
          other.categoryName == this.categoryName &&
          other.categoryOtherName == this.categoryOtherName &&
          other.barcode == this.barcode &&
          other.categoryId == this.categoryId &&
          other.kitchenId == this.kitchenId &&
          other.kitchenName == this.kitchenName);
}

class ItemsCompanion extends UpdateCompanion<Item> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> otherName;
  final Value<String> sku;
  final Value<double> price;
  final Value<int> stock;
  final Value<String?> imagePath;
  final Value<String?> localImagePath;
  final Value<String> categoryName;
  final Value<String> categoryOtherName;
  final Value<String> barcode;
  final Value<int> categoryId;
  final Value<int?> kitchenId;
  final Value<String?> kitchenName;
  const ItemsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.otherName = const Value.absent(),
    this.sku = const Value.absent(),
    this.price = const Value.absent(),
    this.stock = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.localImagePath = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.categoryOtherName = const Value.absent(),
    this.barcode = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.kitchenId = const Value.absent(),
    this.kitchenName = const Value.absent(),
  });
  ItemsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String otherName,
    required String sku,
    required double price,
    required int stock,
    this.imagePath = const Value.absent(),
    this.localImagePath = const Value.absent(),
    required String categoryName,
    required String categoryOtherName,
    required String barcode,
    required int categoryId,
    this.kitchenId = const Value.absent(),
    this.kitchenName = const Value.absent(),
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
    Expression<String>? imagePath,
    Expression<String>? localImagePath,
    Expression<String>? categoryName,
    Expression<String>? categoryOtherName,
    Expression<String>? barcode,
    Expression<int>? categoryId,
    Expression<int>? kitchenId,
    Expression<String>? kitchenName,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (otherName != null) 'other_name': otherName,
      if (sku != null) 'sku': sku,
      if (price != null) 'price': price,
      if (stock != null) 'stock': stock,
      if (imagePath != null) 'image_path': imagePath,
      if (localImagePath != null) 'local_image_path': localImagePath,
      if (categoryName != null) 'category_name': categoryName,
      if (categoryOtherName != null) 'category_other_name': categoryOtherName,
      if (barcode != null) 'barcode': barcode,
      if (categoryId != null) 'category_id': categoryId,
      if (kitchenId != null) 'kitchen_id': kitchenId,
      if (kitchenName != null) 'kitchen_name': kitchenName,
    });
  }

  ItemsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? otherName,
      Value<String>? sku,
      Value<double>? price,
      Value<int>? stock,
      Value<String?>? imagePath,
      Value<String?>? localImagePath,
      Value<String>? categoryName,
      Value<String>? categoryOtherName,
      Value<String>? barcode,
      Value<int>? categoryId,
      Value<int?>? kitchenId,
      Value<String?>? kitchenName}) {
    return ItemsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      otherName: otherName ?? this.otherName,
      sku: sku ?? this.sku,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      imagePath: imagePath ?? this.imagePath,
      localImagePath: localImagePath ?? this.localImagePath,
      categoryName: categoryName ?? this.categoryName,
      categoryOtherName: categoryOtherName ?? this.categoryOtherName,
      barcode: barcode ?? this.barcode,
      categoryId: categoryId ?? this.categoryId,
      kitchenId: kitchenId ?? this.kitchenId,
      kitchenName: kitchenName ?? this.kitchenName,
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
          ..write('imagePath: $imagePath, ')
          ..write('localImagePath: $localImagePath, ')
          ..write('categoryName: $categoryName, ')
          ..write('categoryOtherName: $categoryOtherName, ')
          ..write('barcode: $barcode, ')
          ..write('categoryId: $categoryId, ')
          ..write('kitchenId: $kitchenId, ')
          ..write('kitchenName: $kitchenName')
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
  List<GeneratedColumn> get $columns => [id, userId, role, activeCartId];
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
  final String role;

  /// Current draft cart id for Take Away (persisted so cart survives navigation/reload).
  final int? activeCartId;
  const Session(
      {required this.id,
      required this.userId,
      required this.role,
      this.activeCartId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<int>(userId);
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
      'role': serializer.toJson<String>(role),
      'activeCartId': serializer.toJson<int?>(activeCartId),
    };
  }

  Session copyWith(
          {int? id,
          int? userId,
          String? role,
          Value<int?> activeCartId = const Value.absent()}) =>
      Session(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        role: role ?? this.role,
        activeCartId:
            activeCartId.present ? activeCartId.value : this.activeCartId,
      );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
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
          ..write('role: $role, ')
          ..write('activeCartId: $activeCartId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, role, activeCartId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.role == this.role &&
          other.activeCartId == this.activeCartId);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<int> id;
  final Value<int> userId;
  final Value<String> role;
  final Value<int?> activeCartId;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.role = const Value.absent(),
    this.activeCartId = const Value.absent(),
  });
  SessionsCompanion.insert({
    this.id = const Value.absent(),
    required int userId,
    required String role,
    this.activeCartId = const Value.absent(),
  })  : userId = Value(userId),
        role = Value(role);
  static Insertable<Session> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<String>? role,
    Expression<int>? activeCartId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (role != null) 'role': role,
      if (activeCartId != null) 'active_cart_id': activeCartId,
    });
  }

  SessionsCompanion copyWith(
      {Value<int>? id,
      Value<int>? userId,
      Value<String>? role,
      Value<int?>? activeCartId}) {
    return SessionsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
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
  @override
  List<GeneratedColumn> get $columns => [id, invoiceNumber, createdAt];
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
  const Cart(
      {required this.id, required this.invoiceNumber, required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['invoice_number'] = Variable<String>(invoiceNumber);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CartsCompanion toCompanion(bool nullToAbsent) {
    return CartsCompanion(
      id: Value(id),
      invoiceNumber: Value(invoiceNumber),
      createdAt: Value(createdAt),
    );
  }

  factory Cart.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Cart(
      id: serializer.fromJson<int>(json['id']),
      invoiceNumber: serializer.fromJson<String>(json['invoiceNumber']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'invoiceNumber': serializer.toJson<String>(invoiceNumber),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Cart copyWith({int? id, String? invoiceNumber, DateTime? createdAt}) => Cart(
        id: id ?? this.id,
        invoiceNumber: invoiceNumber ?? this.invoiceNumber,
        createdAt: createdAt ?? this.createdAt,
      );
  Cart copyWithCompanion(CartsCompanion data) {
    return Cart(
      id: data.id.present ? data.id.value : this.id,
      invoiceNumber: data.invoiceNumber.present
          ? data.invoiceNumber.value
          : this.invoiceNumber,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Cart(')
          ..write('id: $id, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, invoiceNumber, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Cart &&
          other.id == this.id &&
          other.invoiceNumber == this.invoiceNumber &&
          other.createdAt == this.createdAt);
}

class CartsCompanion extends UpdateCompanion<Cart> {
  final Value<int> id;
  final Value<String> invoiceNumber;
  final Value<DateTime> createdAt;
  const CartsCompanion({
    this.id = const Value.absent(),
    this.invoiceNumber = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CartsCompanion.insert({
    this.id = const Value.absent(),
    required String invoiceNumber,
    required DateTime createdAt,
  })  : invoiceNumber = Value(invoiceNumber),
        createdAt = Value(createdAt);
  static Insertable<Cart> custom({
    Expression<int>? id,
    Expression<String>? invoiceNumber,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (invoiceNumber != null) 'invoice_number': invoiceNumber,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CartsCompanion copyWith(
      {Value<int>? id,
      Value<String>? invoiceNumber,
      Value<DateTime>? createdAt}) {
    return CartsCompanion(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      createdAt: createdAt ?? this.createdAt,
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CartsCompanion(')
          ..write('id: $id, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('createdAt: $createdAt')
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
        createdAt,
        status
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
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
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
  final DateTime createdAt;
  final String status;
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
      required this.createdAt,
      required this.status});
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
    map['created_at'] = Variable<DateTime>(createdAt);
    map['status'] = Variable<String>(status);
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
      createdAt: Value(createdAt),
      status: Value(status),
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
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      status: serializer.fromJson<String>(json['status']),
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
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'status': serializer.toJson<String>(status),
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
          DateTime? createdAt,
          String? status}) =>
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
        createdAt: createdAt ?? this.createdAt,
        status: status ?? this.status,
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
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      status: data.status.present ? data.status.value : this.status,
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
          ..write('createdAt: $createdAt, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
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
      createdAt,
      status);
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
          other.createdAt == this.createdAt &&
          other.status == this.status);
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
  final Value<DateTime> createdAt;
  final Value<String> status;
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
    this.createdAt = const Value.absent(),
    this.status = const Value.absent(),
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
    required DateTime createdAt,
    this.status = const Value.absent(),
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
    Expression<DateTime>? createdAt,
    Expression<String>? status,
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
      if (createdAt != null) 'created_at': createdAt,
      if (status != null) 'status': status,
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
      Value<DateTime>? createdAt,
      Value<String>? status}) {
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
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
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
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
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
          ..write('createdAt: $createdAt, ')
          ..write('status: $status')
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
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, serverId, name, email, phone, gender, createdAt, updatedAt, isSynced);
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
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isSynced: $isSynced')
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
  late final $OrdersTable orders = $OrdersTable(this);
  late final $CustomersTable customers = $CustomersTable(this);
  late final UsersDao usersDao = UsersDao(this as AppDatabase);
  late final CategoryDao categoryDao = CategoryDao(this as AppDatabase);
  late final CartsDao cartsDao = CartsDao(this as AppDatabase);
  late final ItemDao itemDao = ItemDao(this as AppDatabase);
  late final SessionDao sessionDao = SessionDao(this as AppDatabase);
  late final OrdersDao ordersDao = OrdersDao(this as AppDatabase);
  late final CustomersDao customersDao = CustomersDao(this as AppDatabase);
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
        orders,
        customers
      ];
}

typedef $$UsersTableCreateCompanionBuilder = UsersCompanion Function({
  Value<int> id,
  required String username,
  required String password,
  required String employeeId,
  required int companyId,
  required String companyName,
  required String branchName,
  required String companyLogo,
  required String companyLogoLocal,
  required int branchId,
  required String role,
});
typedef $$UsersTableUpdateCompanionBuilder = UsersCompanion Function({
  Value<int> id,
  Value<String> username,
  Value<String> password,
  Value<String> employeeId,
  Value<int> companyId,
  Value<String> companyName,
  Value<String> branchName,
  Value<String> companyLogo,
  Value<String> companyLogoLocal,
  Value<int> branchId,
  Value<String> role,
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

  ColumnFilters<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get password => $composableBuilder(
      column: $table.password, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get employeeId => $composableBuilder(
      column: $table.employeeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get companyId => $composableBuilder(
      column: $table.companyId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get companyName => $composableBuilder(
      column: $table.companyName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get branchName => $composableBuilder(
      column: $table.branchName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get companyLogo => $composableBuilder(
      column: $table.companyLogo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get companyLogoLocal => $composableBuilder(
      column: $table.companyLogoLocal,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnFilters(column));

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

  ColumnOrderings<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get password => $composableBuilder(
      column: $table.password, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get employeeId => $composableBuilder(
      column: $table.employeeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get companyId => $composableBuilder(
      column: $table.companyId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get companyName => $composableBuilder(
      column: $table.companyName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get branchName => $composableBuilder(
      column: $table.branchName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get companyLogo => $composableBuilder(
      column: $table.companyLogo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get companyLogoLocal => $composableBuilder(
      column: $table.companyLogoLocal,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnOrderings(column));

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

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get password =>
      $composableBuilder(column: $table.password, builder: (column) => column);

  GeneratedColumn<String> get employeeId => $composableBuilder(
      column: $table.employeeId, builder: (column) => column);

  GeneratedColumn<int> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<String> get companyName => $composableBuilder(
      column: $table.companyName, builder: (column) => column);

  GeneratedColumn<String> get branchName => $composableBuilder(
      column: $table.branchName, builder: (column) => column);

  GeneratedColumn<String> get companyLogo => $composableBuilder(
      column: $table.companyLogo, builder: (column) => column);

  GeneratedColumn<String> get companyLogoLocal => $composableBuilder(
      column: $table.companyLogoLocal, builder: (column) => column);

  GeneratedColumn<int> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

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
            Value<String> username = const Value.absent(),
            Value<String> password = const Value.absent(),
            Value<String> employeeId = const Value.absent(),
            Value<int> companyId = const Value.absent(),
            Value<String> companyName = const Value.absent(),
            Value<String> branchName = const Value.absent(),
            Value<String> companyLogo = const Value.absent(),
            Value<String> companyLogoLocal = const Value.absent(),
            Value<int> branchId = const Value.absent(),
            Value<String> role = const Value.absent(),
          }) =>
              UsersCompanion(
            id: id,
            username: username,
            password: password,
            employeeId: employeeId,
            companyId: companyId,
            companyName: companyName,
            branchName: branchName,
            companyLogo: companyLogo,
            companyLogoLocal: companyLogoLocal,
            branchId: branchId,
            role: role,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String username,
            required String password,
            required String employeeId,
            required int companyId,
            required String companyName,
            required String branchName,
            required String companyLogo,
            required String companyLogoLocal,
            required int branchId,
            required String role,
          }) =>
              UsersCompanion.insert(
            id: id,
            username: username,
            password: password,
            employeeId: employeeId,
            companyId: companyId,
            companyName: companyName,
            branchName: branchName,
            companyLogo: companyLogo,
            companyLogoLocal: companyLogoLocal,
            branchId: branchId,
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
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> otherName,
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
          }) =>
              CategoriesCompanion(
            id: id,
            name: name,
            otherName: otherName,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required String otherName,
          }) =>
              CategoriesCompanion.insert(
            id: id,
            name: name,
            otherName: otherName,
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
});
typedef $$KitchensTableUpdateCompanionBuilder = KitchensCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String?> printerIp,
  Value<int> printerPort,
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
          }) =>
              KitchensCompanion(
            id: id,
            name: name,
            printerIp: printerIp,
            printerPort: printerPort,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String?> printerIp = const Value.absent(),
            Value<int> printerPort = const Value.absent(),
          }) =>
              KitchensCompanion.insert(
            id: id,
            name: name,
            printerIp: printerIp,
            printerPort: printerPort,
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
  Value<String?> imagePath,
  Value<String?> localImagePath,
  required String categoryName,
  required String categoryOtherName,
  required String barcode,
  required int categoryId,
  Value<int?> kitchenId,
  Value<String?> kitchenName,
});
typedef $$ItemsTableUpdateCompanionBuilder = ItemsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> otherName,
  Value<String> sku,
  Value<double> price,
  Value<int> stock,
  Value<String?> imagePath,
  Value<String?> localImagePath,
  Value<String> categoryName,
  Value<String> categoryOtherName,
  Value<String> barcode,
  Value<int> categoryId,
  Value<int?> kitchenId,
  Value<String?> kitchenName,
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
            Value<String?> imagePath = const Value.absent(),
            Value<String?> localImagePath = const Value.absent(),
            Value<String> categoryName = const Value.absent(),
            Value<String> categoryOtherName = const Value.absent(),
            Value<String> barcode = const Value.absent(),
            Value<int> categoryId = const Value.absent(),
            Value<int?> kitchenId = const Value.absent(),
            Value<String?> kitchenName = const Value.absent(),
          }) =>
              ItemsCompanion(
            id: id,
            name: name,
            otherName: otherName,
            sku: sku,
            price: price,
            stock: stock,
            imagePath: imagePath,
            localImagePath: localImagePath,
            categoryName: categoryName,
            categoryOtherName: categoryOtherName,
            barcode: barcode,
            categoryId: categoryId,
            kitchenId: kitchenId,
            kitchenName: kitchenName,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required String otherName,
            required String sku,
            required double price,
            required int stock,
            Value<String?> imagePath = const Value.absent(),
            Value<String?> localImagePath = const Value.absent(),
            required String categoryName,
            required String categoryOtherName,
            required String barcode,
            required int categoryId,
            Value<int?> kitchenId = const Value.absent(),
            Value<String?> kitchenName = const Value.absent(),
          }) =>
              ItemsCompanion.insert(
            id: id,
            name: name,
            otherName: otherName,
            sku: sku,
            price: price,
            stock: stock,
            imagePath: imagePath,
            localImagePath: localImagePath,
            categoryName: categoryName,
            categoryOtherName: categoryOtherName,
            barcode: barcode,
            categoryId: categoryId,
            kitchenId: kitchenId,
            kitchenName: kitchenName,
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
  required String role,
  Value<int?> activeCartId,
});
typedef $$SessionsTableUpdateCompanionBuilder = SessionsCompanion Function({
  Value<int> id,
  Value<int> userId,
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
            Value<String> role = const Value.absent(),
            Value<int?> activeCartId = const Value.absent(),
          }) =>
              SessionsCompanion(
            id: id,
            userId: userId,
            role: role,
            activeCartId: activeCartId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int userId,
            required String role,
            Value<int?> activeCartId = const Value.absent(),
          }) =>
              SessionsCompanion.insert(
            id: id,
            userId: userId,
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
});
typedef $$CartsTableUpdateCompanionBuilder = CartsCompanion Function({
  Value<int> id,
  Value<String> invoiceNumber,
  Value<DateTime> createdAt,
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
          }) =>
              CartsCompanion(
            id: id,
            invoiceNumber: invoiceNumber,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String invoiceNumber,
            required DateTime createdAt,
          }) =>
              CartsCompanion.insert(
            id: id,
            invoiceNumber: invoiceNumber,
            createdAt: createdAt,
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
  required DateTime createdAt,
  Value<String> status,
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
  Value<DateTime> createdAt,
  Value<String> status,
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

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

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

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
    PrefetchHooks Function({bool cartId})> {
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
            Value<DateTime> createdAt = const Value.absent(),
            Value<String> status = const Value.absent(),
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
            createdAt: createdAt,
            status: status,
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
            required DateTime createdAt,
            Value<String> status = const Value.absent(),
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
            createdAt: createdAt,
            status: status,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$OrdersTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({cartId = false}) {
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
    PrefetchHooks Function({bool cartId})>;
typedef $$CustomersTableCreateCompanionBuilder = CustomersCompanion Function({
  Value<int> id,
  Value<String?> serverId,
  required String name,
  Value<String?> email,
  Value<String?> phone,
  Value<String?> gender,
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
  $$OrdersTableTableManager get orders =>
      $$OrdersTableTableManager(_db, _db.orders);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db, _db.customers);
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
  $OrdersTable get orders => attachedDatabase.orders;
  $ItemsTable get items => attachedDatabase.items;
  $ItemVariantsTable get itemVariants => attachedDatabase.itemVariants;
  $ItemToppingsTable get itemToppings => attachedDatabase.itemToppings;
  $CartItemsTable get cartItems => attachedDatabase.cartItems;
}
mixin _$CustomersDaoMixin on DatabaseAccessor<AppDatabase> {
  $CustomersTable get customers => attachedDatabase.customers;
}
