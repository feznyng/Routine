// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $RoutinesTable extends Routines
    with TableInfo<$RoutinesTable, RoutineEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoutinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mondayMeta = const VerificationMeta('monday');
  @override
  late final GeneratedColumn<bool> monday = GeneratedColumn<bool>(
      'monday', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("monday" IN (0, 1))'));
  static const VerificationMeta _tuesdayMeta =
      const VerificationMeta('tuesday');
  @override
  late final GeneratedColumn<bool> tuesday = GeneratedColumn<bool>(
      'tuesday', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("tuesday" IN (0, 1))'));
  static const VerificationMeta _wednesdayMeta =
      const VerificationMeta('wednesday');
  @override
  late final GeneratedColumn<bool> wednesday = GeneratedColumn<bool>(
      'wednesday', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("wednesday" IN (0, 1))'));
  static const VerificationMeta _thursdayMeta =
      const VerificationMeta('thursday');
  @override
  late final GeneratedColumn<bool> thursday = GeneratedColumn<bool>(
      'thursday', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("thursday" IN (0, 1))'));
  static const VerificationMeta _fridayMeta = const VerificationMeta('friday');
  @override
  late final GeneratedColumn<bool> friday = GeneratedColumn<bool>(
      'friday', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("friday" IN (0, 1))'));
  static const VerificationMeta _saturdayMeta =
      const VerificationMeta('saturday');
  @override
  late final GeneratedColumn<bool> saturday = GeneratedColumn<bool>(
      'saturday', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("saturday" IN (0, 1))'));
  static const VerificationMeta _sundayMeta = const VerificationMeta('sunday');
  @override
  late final GeneratedColumn<bool> sunday = GeneratedColumn<bool>(
      'sunday', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("sunday" IN (0, 1))'));
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<int> startTime = GeneratedColumn<int>(
      'start_time', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _endTimeMeta =
      const VerificationMeta('endTime');
  @override
  late final GeneratedColumn<int> endTime = GeneratedColumn<int>(
      'end_time', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _changesMeta =
      const VerificationMeta('changes');
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> changes =
      GeneratedColumn<String>('changes', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<List<String>>($RoutinesTable.$converterchanges);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumnWithTypeConverter<Status, String> status =
      GeneratedColumn<String>('status', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<Status>($RoutinesTable.$converterstatus);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        monday,
        tuesday,
        wednesday,
        thursday,
        friday,
        saturday,
        sunday,
        startTime,
        endTime,
        changes,
        status
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'routines';
  @override
  VerificationContext validateIntegrity(Insertable<RoutineEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('monday')) {
      context.handle(_mondayMeta,
          monday.isAcceptableOrUnknown(data['monday']!, _mondayMeta));
    } else if (isInserting) {
      context.missing(_mondayMeta);
    }
    if (data.containsKey('tuesday')) {
      context.handle(_tuesdayMeta,
          tuesday.isAcceptableOrUnknown(data['tuesday']!, _tuesdayMeta));
    } else if (isInserting) {
      context.missing(_tuesdayMeta);
    }
    if (data.containsKey('wednesday')) {
      context.handle(_wednesdayMeta,
          wednesday.isAcceptableOrUnknown(data['wednesday']!, _wednesdayMeta));
    } else if (isInserting) {
      context.missing(_wednesdayMeta);
    }
    if (data.containsKey('thursday')) {
      context.handle(_thursdayMeta,
          thursday.isAcceptableOrUnknown(data['thursday']!, _thursdayMeta));
    } else if (isInserting) {
      context.missing(_thursdayMeta);
    }
    if (data.containsKey('friday')) {
      context.handle(_fridayMeta,
          friday.isAcceptableOrUnknown(data['friday']!, _fridayMeta));
    } else if (isInserting) {
      context.missing(_fridayMeta);
    }
    if (data.containsKey('saturday')) {
      context.handle(_saturdayMeta,
          saturday.isAcceptableOrUnknown(data['saturday']!, _saturdayMeta));
    } else if (isInserting) {
      context.missing(_saturdayMeta);
    }
    if (data.containsKey('sunday')) {
      context.handle(_sundayMeta,
          sunday.isAcceptableOrUnknown(data['sunday']!, _sundayMeta));
    } else if (isInserting) {
      context.missing(_sundayMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(_endTimeMeta,
          endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta));
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    context.handle(_changesMeta, const VerificationResult.success());
    context.handle(_statusMeta, const VerificationResult.success());
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RoutineEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RoutineEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      monday: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}monday'])!,
      tuesday: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}tuesday'])!,
      wednesday: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}wednesday'])!,
      thursday: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}thursday'])!,
      friday: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}friday'])!,
      saturday: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}saturday'])!,
      sunday: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}sunday'])!,
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}start_time'])!,
      endTime: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}end_time'])!,
      changes: $RoutinesTable.$converterchanges.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}changes'])!),
      status: $RoutinesTable.$converterstatus.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!),
    );
  }

  @override
  $RoutinesTable createAlias(String alias) {
    return $RoutinesTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $converterchanges =
      StringListTypeConverter();
  static JsonTypeConverter2<Status, String, String> $converterstatus =
      const EnumNameConverter<Status>(Status.values);
}

class RoutineEntry extends DataClass implements Insertable<RoutineEntry> {
  final String id;
  final String name;
  final bool monday;
  final bool tuesday;
  final bool wednesday;
  final bool thursday;
  final bool friday;
  final bool saturday;
  final bool sunday;
  final int startTime;
  final int endTime;
  final List<String> changes;
  final Status status;
  const RoutineEntry(
      {required this.id,
      required this.name,
      required this.monday,
      required this.tuesday,
      required this.wednesday,
      required this.thursday,
      required this.friday,
      required this.saturday,
      required this.sunday,
      required this.startTime,
      required this.endTime,
      required this.changes,
      required this.status});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['monday'] = Variable<bool>(monday);
    map['tuesday'] = Variable<bool>(tuesday);
    map['wednesday'] = Variable<bool>(wednesday);
    map['thursday'] = Variable<bool>(thursday);
    map['friday'] = Variable<bool>(friday);
    map['saturday'] = Variable<bool>(saturday);
    map['sunday'] = Variable<bool>(sunday);
    map['start_time'] = Variable<int>(startTime);
    map['end_time'] = Variable<int>(endTime);
    {
      map['changes'] =
          Variable<String>($RoutinesTable.$converterchanges.toSql(changes));
    }
    {
      map['status'] =
          Variable<String>($RoutinesTable.$converterstatus.toSql(status));
    }
    return map;
  }

  RoutinesCompanion toCompanion(bool nullToAbsent) {
    return RoutinesCompanion(
      id: Value(id),
      name: Value(name),
      monday: Value(monday),
      tuesday: Value(tuesday),
      wednesday: Value(wednesday),
      thursday: Value(thursday),
      friday: Value(friday),
      saturday: Value(saturday),
      sunday: Value(sunday),
      startTime: Value(startTime),
      endTime: Value(endTime),
      changes: Value(changes),
      status: Value(status),
    );
  }

  factory RoutineEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RoutineEntry(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      monday: serializer.fromJson<bool>(json['monday']),
      tuesday: serializer.fromJson<bool>(json['tuesday']),
      wednesday: serializer.fromJson<bool>(json['wednesday']),
      thursday: serializer.fromJson<bool>(json['thursday']),
      friday: serializer.fromJson<bool>(json['friday']),
      saturday: serializer.fromJson<bool>(json['saturday']),
      sunday: serializer.fromJson<bool>(json['sunday']),
      startTime: serializer.fromJson<int>(json['startTime']),
      endTime: serializer.fromJson<int>(json['endTime']),
      changes: serializer.fromJson<List<String>>(json['changes']),
      status: $RoutinesTable.$converterstatus
          .fromJson(serializer.fromJson<String>(json['status'])),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'monday': serializer.toJson<bool>(monday),
      'tuesday': serializer.toJson<bool>(tuesday),
      'wednesday': serializer.toJson<bool>(wednesday),
      'thursday': serializer.toJson<bool>(thursday),
      'friday': serializer.toJson<bool>(friday),
      'saturday': serializer.toJson<bool>(saturday),
      'sunday': serializer.toJson<bool>(sunday),
      'startTime': serializer.toJson<int>(startTime),
      'endTime': serializer.toJson<int>(endTime),
      'changes': serializer.toJson<List<String>>(changes),
      'status': serializer
          .toJson<String>($RoutinesTable.$converterstatus.toJson(status)),
    };
  }

  RoutineEntry copyWith(
          {String? id,
          String? name,
          bool? monday,
          bool? tuesday,
          bool? wednesday,
          bool? thursday,
          bool? friday,
          bool? saturday,
          bool? sunday,
          int? startTime,
          int? endTime,
          List<String>? changes,
          Status? status}) =>
      RoutineEntry(
        id: id ?? this.id,
        name: name ?? this.name,
        monday: monday ?? this.monday,
        tuesday: tuesday ?? this.tuesday,
        wednesday: wednesday ?? this.wednesday,
        thursday: thursday ?? this.thursday,
        friday: friday ?? this.friday,
        saturday: saturday ?? this.saturday,
        sunday: sunday ?? this.sunday,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        changes: changes ?? this.changes,
        status: status ?? this.status,
      );
  RoutineEntry copyWithCompanion(RoutinesCompanion data) {
    return RoutineEntry(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      monday: data.monday.present ? data.monday.value : this.monday,
      tuesday: data.tuesday.present ? data.tuesday.value : this.tuesday,
      wednesday: data.wednesday.present ? data.wednesday.value : this.wednesday,
      thursday: data.thursday.present ? data.thursday.value : this.thursday,
      friday: data.friday.present ? data.friday.value : this.friday,
      saturday: data.saturday.present ? data.saturday.value : this.saturday,
      sunday: data.sunday.present ? data.sunday.value : this.sunday,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      changes: data.changes.present ? data.changes.value : this.changes,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RoutineEntry(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('monday: $monday, ')
          ..write('tuesday: $tuesday, ')
          ..write('wednesday: $wednesday, ')
          ..write('thursday: $thursday, ')
          ..write('friday: $friday, ')
          ..write('saturday: $saturday, ')
          ..write('sunday: $sunday, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('changes: $changes, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, monday, tuesday, wednesday,
      thursday, friday, saturday, sunday, startTime, endTime, changes, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoutineEntry &&
          other.id == this.id &&
          other.name == this.name &&
          other.monday == this.monday &&
          other.tuesday == this.tuesday &&
          other.wednesday == this.wednesday &&
          other.thursday == this.thursday &&
          other.friday == this.friday &&
          other.saturday == this.saturday &&
          other.sunday == this.sunday &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.changes == this.changes &&
          other.status == this.status);
}

class RoutinesCompanion extends UpdateCompanion<RoutineEntry> {
  final Value<String> id;
  final Value<String> name;
  final Value<bool> monday;
  final Value<bool> tuesday;
  final Value<bool> wednesday;
  final Value<bool> thursday;
  final Value<bool> friday;
  final Value<bool> saturday;
  final Value<bool> sunday;
  final Value<int> startTime;
  final Value<int> endTime;
  final Value<List<String>> changes;
  final Value<Status> status;
  final Value<int> rowid;
  const RoutinesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.monday = const Value.absent(),
    this.tuesday = const Value.absent(),
    this.wednesday = const Value.absent(),
    this.thursday = const Value.absent(),
    this.friday = const Value.absent(),
    this.saturday = const Value.absent(),
    this.sunday = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.changes = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RoutinesCompanion.insert({
    required String id,
    required String name,
    required bool monday,
    required bool tuesday,
    required bool wednesday,
    required bool thursday,
    required bool friday,
    required bool saturday,
    required bool sunday,
    required int startTime,
    required int endTime,
    required List<String> changes,
    required Status status,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        monday = Value(monday),
        tuesday = Value(tuesday),
        wednesday = Value(wednesday),
        thursday = Value(thursday),
        friday = Value(friday),
        saturday = Value(saturday),
        sunday = Value(sunday),
        startTime = Value(startTime),
        endTime = Value(endTime),
        changes = Value(changes),
        status = Value(status);
  static Insertable<RoutineEntry> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<bool>? monday,
    Expression<bool>? tuesday,
    Expression<bool>? wednesday,
    Expression<bool>? thursday,
    Expression<bool>? friday,
    Expression<bool>? saturday,
    Expression<bool>? sunday,
    Expression<int>? startTime,
    Expression<int>? endTime,
    Expression<String>? changes,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (monday != null) 'monday': monday,
      if (tuesday != null) 'tuesday': tuesday,
      if (wednesday != null) 'wednesday': wednesday,
      if (thursday != null) 'thursday': thursday,
      if (friday != null) 'friday': friday,
      if (saturday != null) 'saturday': saturday,
      if (sunday != null) 'sunday': sunday,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (changes != null) 'changes': changes,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RoutinesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<bool>? monday,
      Value<bool>? tuesday,
      Value<bool>? wednesday,
      Value<bool>? thursday,
      Value<bool>? friday,
      Value<bool>? saturday,
      Value<bool>? sunday,
      Value<int>? startTime,
      Value<int>? endTime,
      Value<List<String>>? changes,
      Value<Status>? status,
      Value<int>? rowid}) {
    return RoutinesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      monday: monday ?? this.monday,
      tuesday: tuesday ?? this.tuesday,
      wednesday: wednesday ?? this.wednesday,
      thursday: thursday ?? this.thursday,
      friday: friday ?? this.friday,
      saturday: saturday ?? this.saturday,
      sunday: sunday ?? this.sunday,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      changes: changes ?? this.changes,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (monday.present) {
      map['monday'] = Variable<bool>(monday.value);
    }
    if (tuesday.present) {
      map['tuesday'] = Variable<bool>(tuesday.value);
    }
    if (wednesday.present) {
      map['wednesday'] = Variable<bool>(wednesday.value);
    }
    if (thursday.present) {
      map['thursday'] = Variable<bool>(thursday.value);
    }
    if (friday.present) {
      map['friday'] = Variable<bool>(friday.value);
    }
    if (saturday.present) {
      map['saturday'] = Variable<bool>(saturday.value);
    }
    if (sunday.present) {
      map['sunday'] = Variable<bool>(sunday.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<int>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<int>(endTime.value);
    }
    if (changes.present) {
      map['changes'] = Variable<String>(
          $RoutinesTable.$converterchanges.toSql(changes.value));
    }
    if (status.present) {
      map['status'] =
          Variable<String>($RoutinesTable.$converterstatus.toSql(status.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoutinesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('monday: $monday, ')
          ..write('tuesday: $tuesday, ')
          ..write('wednesday: $wednesday, ')
          ..write('thursday: $thursday, ')
          ..write('friday: $friday, ')
          ..write('saturday: $saturday, ')
          ..write('sunday: $sunday, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('changes: $changes, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DevicesTable extends Devices with TableInfo<$DevicesTable, DeviceEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DevicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _currMeta = const VerificationMeta('curr');
  @override
  late final GeneratedColumn<bool> curr = GeneratedColumn<bool>(
      'curr', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("curr" IN (0, 1))'));
  @override
  List<GeneratedColumn> get $columns => [id, name, type, curr];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'devices';
  @override
  VerificationContext validateIntegrity(Insertable<DeviceEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('curr')) {
      context.handle(
          _currMeta, curr.isAcceptableOrUnknown(data['curr']!, _currMeta));
    } else if (isInserting) {
      context.missing(_currMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DeviceEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeviceEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      curr: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}curr'])!,
    );
  }

  @override
  $DevicesTable createAlias(String alias) {
    return $DevicesTable(attachedDatabase, alias);
  }
}

class DeviceEntry extends DataClass implements Insertable<DeviceEntry> {
  final String id;
  final String name;
  final String type;
  final bool curr;
  const DeviceEntry(
      {required this.id,
      required this.name,
      required this.type,
      required this.curr});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['curr'] = Variable<bool>(curr);
    return map;
  }

  DevicesCompanion toCompanion(bool nullToAbsent) {
    return DevicesCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      curr: Value(curr),
    );
  }

  factory DeviceEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeviceEntry(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      curr: serializer.fromJson<bool>(json['curr']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'curr': serializer.toJson<bool>(curr),
    };
  }

  DeviceEntry copyWith({String? id, String? name, String? type, bool? curr}) =>
      DeviceEntry(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        curr: curr ?? this.curr,
      );
  DeviceEntry copyWithCompanion(DevicesCompanion data) {
    return DeviceEntry(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      curr: data.curr.present ? data.curr.value : this.curr,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeviceEntry(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('curr: $curr')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, type, curr);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeviceEntry &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.curr == this.curr);
}

class DevicesCompanion extends UpdateCompanion<DeviceEntry> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> type;
  final Value<bool> curr;
  final Value<int> rowid;
  const DevicesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.curr = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DevicesCompanion.insert({
    required String id,
    required String name,
    required String type,
    required bool curr,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        type = Value(type),
        curr = Value(curr);
  static Insertable<DeviceEntry> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<bool>? curr,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (curr != null) 'curr': curr,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DevicesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? type,
      Value<bool>? curr,
      Value<int>? rowid}) {
    return DevicesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      curr: curr ?? this.curr,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (curr.present) {
      map['curr'] = Variable<bool>(curr.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DevicesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('curr: $curr, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GroupsTable extends Groups with TableInfo<$GroupsTable, GroupEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _deviceMeta = const VerificationMeta('device');
  @override
  late final GeneratedColumn<String> device = GeneratedColumn<String>(
      'device', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES devices (id)'));
  static const VerificationMeta _allowMeta = const VerificationMeta('allow');
  @override
  late final GeneratedColumn<bool> allow = GeneratedColumn<bool>(
      'allow', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("allow" IN (0, 1))'));
  static const VerificationMeta _appsMeta = const VerificationMeta('apps');
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> apps =
      GeneratedColumn<String>('apps', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<List<String>>($GroupsTable.$converterapps);
  static const VerificationMeta _sitesMeta = const VerificationMeta('sites');
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> sites =
      GeneratedColumn<String>('sites', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<List<String>>($GroupsTable.$convertersites);
  static const VerificationMeta _changesMeta =
      const VerificationMeta('changes');
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> changes =
      GeneratedColumn<String>('changes', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<List<String>>($GroupsTable.$converterchanges);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumnWithTypeConverter<Status, String> status =
      GeneratedColumn<String>('status', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<Status>($GroupsTable.$converterstatus);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, device, allow, apps, sites, changes, status];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'groups';
  @override
  VerificationContext validateIntegrity(Insertable<GroupEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('device')) {
      context.handle(_deviceMeta,
          device.isAcceptableOrUnknown(data['device']!, _deviceMeta));
    } else if (isInserting) {
      context.missing(_deviceMeta);
    }
    if (data.containsKey('allow')) {
      context.handle(
          _allowMeta, allow.isAcceptableOrUnknown(data['allow']!, _allowMeta));
    } else if (isInserting) {
      context.missing(_allowMeta);
    }
    context.handle(_appsMeta, const VerificationResult.success());
    context.handle(_sitesMeta, const VerificationResult.success());
    context.handle(_changesMeta, const VerificationResult.success());
    context.handle(_statusMeta, const VerificationResult.success());
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GroupEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name']),
      device: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device'])!,
      allow: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}allow'])!,
      apps: $GroupsTable.$converterapps.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}apps'])!),
      sites: $GroupsTable.$convertersites.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sites'])!),
      changes: $GroupsTable.$converterchanges.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}changes'])!),
      status: $GroupsTable.$converterstatus.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!),
    );
  }

  @override
  $GroupsTable createAlias(String alias) {
    return $GroupsTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $converterapps =
      StringListTypeConverter();
  static TypeConverter<List<String>, String> $convertersites =
      StringListTypeConverter();
  static TypeConverter<List<String>, String> $converterchanges =
      StringListTypeConverter();
  static JsonTypeConverter2<Status, String, String> $converterstatus =
      const EnumNameConverter<Status>(Status.values);
}

class GroupEntry extends DataClass implements Insertable<GroupEntry> {
  final String id;
  final String? name;
  final String device;
  final bool allow;
  final List<String> apps;
  final List<String> sites;
  final List<String> changes;
  final Status status;
  const GroupEntry(
      {required this.id,
      this.name,
      required this.device,
      required this.allow,
      required this.apps,
      required this.sites,
      required this.changes,
      required this.status});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    map['device'] = Variable<String>(device);
    map['allow'] = Variable<bool>(allow);
    {
      map['apps'] = Variable<String>($GroupsTable.$converterapps.toSql(apps));
    }
    {
      map['sites'] =
          Variable<String>($GroupsTable.$convertersites.toSql(sites));
    }
    {
      map['changes'] =
          Variable<String>($GroupsTable.$converterchanges.toSql(changes));
    }
    {
      map['status'] =
          Variable<String>($GroupsTable.$converterstatus.toSql(status));
    }
    return map;
  }

  GroupsCompanion toCompanion(bool nullToAbsent) {
    return GroupsCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      device: Value(device),
      allow: Value(allow),
      apps: Value(apps),
      sites: Value(sites),
      changes: Value(changes),
      status: Value(status),
    );
  }

  factory GroupEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupEntry(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
      device: serializer.fromJson<String>(json['device']),
      allow: serializer.fromJson<bool>(json['allow']),
      apps: serializer.fromJson<List<String>>(json['apps']),
      sites: serializer.fromJson<List<String>>(json['sites']),
      changes: serializer.fromJson<List<String>>(json['changes']),
      status: $GroupsTable.$converterstatus
          .fromJson(serializer.fromJson<String>(json['status'])),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String?>(name),
      'device': serializer.toJson<String>(device),
      'allow': serializer.toJson<bool>(allow),
      'apps': serializer.toJson<List<String>>(apps),
      'sites': serializer.toJson<List<String>>(sites),
      'changes': serializer.toJson<List<String>>(changes),
      'status': serializer
          .toJson<String>($GroupsTable.$converterstatus.toJson(status)),
    };
  }

  GroupEntry copyWith(
          {String? id,
          Value<String?> name = const Value.absent(),
          String? device,
          bool? allow,
          List<String>? apps,
          List<String>? sites,
          List<String>? changes,
          Status? status}) =>
      GroupEntry(
        id: id ?? this.id,
        name: name.present ? name.value : this.name,
        device: device ?? this.device,
        allow: allow ?? this.allow,
        apps: apps ?? this.apps,
        sites: sites ?? this.sites,
        changes: changes ?? this.changes,
        status: status ?? this.status,
      );
  GroupEntry copyWithCompanion(GroupsCompanion data) {
    return GroupEntry(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      device: data.device.present ? data.device.value : this.device,
      allow: data.allow.present ? data.allow.value : this.allow,
      apps: data.apps.present ? data.apps.value : this.apps,
      sites: data.sites.present ? data.sites.value : this.sites,
      changes: data.changes.present ? data.changes.value : this.changes,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroupEntry(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('device: $device, ')
          ..write('allow: $allow, ')
          ..write('apps: $apps, ')
          ..write('sites: $sites, ')
          ..write('changes: $changes, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, device, allow, apps, sites, changes, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupEntry &&
          other.id == this.id &&
          other.name == this.name &&
          other.device == this.device &&
          other.allow == this.allow &&
          other.apps == this.apps &&
          other.sites == this.sites &&
          other.changes == this.changes &&
          other.status == this.status);
}

class GroupsCompanion extends UpdateCompanion<GroupEntry> {
  final Value<String> id;
  final Value<String?> name;
  final Value<String> device;
  final Value<bool> allow;
  final Value<List<String>> apps;
  final Value<List<String>> sites;
  final Value<List<String>> changes;
  final Value<Status> status;
  final Value<int> rowid;
  const GroupsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.device = const Value.absent(),
    this.allow = const Value.absent(),
    this.apps = const Value.absent(),
    this.sites = const Value.absent(),
    this.changes = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GroupsCompanion.insert({
    required String id,
    this.name = const Value.absent(),
    required String device,
    required bool allow,
    required List<String> apps,
    required List<String> sites,
    required List<String> changes,
    required Status status,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        device = Value(device),
        allow = Value(allow),
        apps = Value(apps),
        sites = Value(sites),
        changes = Value(changes),
        status = Value(status);
  static Insertable<GroupEntry> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? device,
    Expression<bool>? allow,
    Expression<String>? apps,
    Expression<String>? sites,
    Expression<String>? changes,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (device != null) 'device': device,
      if (allow != null) 'allow': allow,
      if (apps != null) 'apps': apps,
      if (sites != null) 'sites': sites,
      if (changes != null) 'changes': changes,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroupsCompanion copyWith(
      {Value<String>? id,
      Value<String?>? name,
      Value<String>? device,
      Value<bool>? allow,
      Value<List<String>>? apps,
      Value<List<String>>? sites,
      Value<List<String>>? changes,
      Value<Status>? status,
      Value<int>? rowid}) {
    return GroupsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      device: device ?? this.device,
      allow: allow ?? this.allow,
      apps: apps ?? this.apps,
      sites: sites ?? this.sites,
      changes: changes ?? this.changes,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (device.present) {
      map['device'] = Variable<String>(device.value);
    }
    if (allow.present) {
      map['allow'] = Variable<bool>(allow.value);
    }
    if (apps.present) {
      map['apps'] =
          Variable<String>($GroupsTable.$converterapps.toSql(apps.value));
    }
    if (sites.present) {
      map['sites'] =
          Variable<String>($GroupsTable.$convertersites.toSql(sites.value));
    }
    if (changes.present) {
      map['changes'] =
          Variable<String>($GroupsTable.$converterchanges.toSql(changes.value));
    }
    if (status.present) {
      map['status'] =
          Variable<String>($GroupsTable.$converterstatus.toSql(status.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('device: $device, ')
          ..write('allow: $allow, ')
          ..write('apps: $apps, ')
          ..write('sites: $sites, ')
          ..write('changes: $changes, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RoutineGroupsTable extends RoutineGroups
    with TableInfo<$RoutineGroupsTable, RoutineGroupEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoutineGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _routineMeta =
      const VerificationMeta('routine');
  @override
  late final GeneratedColumn<String> routine = GeneratedColumn<String>(
      'routine', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES routines (id)'));
  static const VerificationMeta _groupMeta = const VerificationMeta('group');
  @override
  late final GeneratedColumn<String> group = GeneratedColumn<String>(
      'group', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES "groups" (id)'));
  @override
  List<GeneratedColumn> get $columns => [id, routine, group];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'routine_groups';
  @override
  VerificationContext validateIntegrity(Insertable<RoutineGroupEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('routine')) {
      context.handle(_routineMeta,
          routine.isAcceptableOrUnknown(data['routine']!, _routineMeta));
    } else if (isInserting) {
      context.missing(_routineMeta);
    }
    if (data.containsKey('group')) {
      context.handle(
          _groupMeta, group.isAcceptableOrUnknown(data['group']!, _groupMeta));
    } else if (isInserting) {
      context.missing(_groupMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RoutineGroupEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RoutineGroupEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      routine: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}routine'])!,
      group: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group'])!,
    );
  }

  @override
  $RoutineGroupsTable createAlias(String alias) {
    return $RoutineGroupsTable(attachedDatabase, alias);
  }
}

class RoutineGroupEntry extends DataClass
    implements Insertable<RoutineGroupEntry> {
  final String id;
  final String routine;
  final String group;
  const RoutineGroupEntry(
      {required this.id, required this.routine, required this.group});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['routine'] = Variable<String>(routine);
    map['group'] = Variable<String>(group);
    return map;
  }

  RoutineGroupsCompanion toCompanion(bool nullToAbsent) {
    return RoutineGroupsCompanion(
      id: Value(id),
      routine: Value(routine),
      group: Value(group),
    );
  }

  factory RoutineGroupEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RoutineGroupEntry(
      id: serializer.fromJson<String>(json['id']),
      routine: serializer.fromJson<String>(json['routine']),
      group: serializer.fromJson<String>(json['group']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'routine': serializer.toJson<String>(routine),
      'group': serializer.toJson<String>(group),
    };
  }

  RoutineGroupEntry copyWith({String? id, String? routine, String? group}) =>
      RoutineGroupEntry(
        id: id ?? this.id,
        routine: routine ?? this.routine,
        group: group ?? this.group,
      );
  RoutineGroupEntry copyWithCompanion(RoutineGroupsCompanion data) {
    return RoutineGroupEntry(
      id: data.id.present ? data.id.value : this.id,
      routine: data.routine.present ? data.routine.value : this.routine,
      group: data.group.present ? data.group.value : this.group,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RoutineGroupEntry(')
          ..write('id: $id, ')
          ..write('routine: $routine, ')
          ..write('group: $group')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, routine, group);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoutineGroupEntry &&
          other.id == this.id &&
          other.routine == this.routine &&
          other.group == this.group);
}

class RoutineGroupsCompanion extends UpdateCompanion<RoutineGroupEntry> {
  final Value<String> id;
  final Value<String> routine;
  final Value<String> group;
  final Value<int> rowid;
  const RoutineGroupsCompanion({
    this.id = const Value.absent(),
    this.routine = const Value.absent(),
    this.group = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RoutineGroupsCompanion.insert({
    required String id,
    required String routine,
    required String group,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        routine = Value(routine),
        group = Value(group);
  static Insertable<RoutineGroupEntry> custom({
    Expression<String>? id,
    Expression<String>? routine,
    Expression<String>? group,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (routine != null) 'routine': routine,
      if (group != null) 'group': group,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RoutineGroupsCompanion copyWith(
      {Value<String>? id,
      Value<String>? routine,
      Value<String>? group,
      Value<int>? rowid}) {
    return RoutineGroupsCompanion(
      id: id ?? this.id,
      routine: routine ?? this.routine,
      group: group ?? this.group,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (routine.present) {
      map['routine'] = Variable<String>(routine.value);
    }
    if (group.present) {
      map['group'] = Variable<String>(group.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoutineGroupsCompanion(')
          ..write('id: $id, ')
          ..write('routine: $routine, ')
          ..write('group: $group, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $RoutinesTable routines = $RoutinesTable(this);
  late final $DevicesTable devices = $DevicesTable(this);
  late final $GroupsTable groups = $GroupsTable(this);
  late final $RoutineGroupsTable routineGroups = $RoutineGroupsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [routines, devices, groups, routineGroups];
}

typedef $$RoutinesTableCreateCompanionBuilder = RoutinesCompanion Function({
  required String id,
  required String name,
  required bool monday,
  required bool tuesday,
  required bool wednesday,
  required bool thursday,
  required bool friday,
  required bool saturday,
  required bool sunday,
  required int startTime,
  required int endTime,
  required List<String> changes,
  required Status status,
  Value<int> rowid,
});
typedef $$RoutinesTableUpdateCompanionBuilder = RoutinesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<bool> monday,
  Value<bool> tuesday,
  Value<bool> wednesday,
  Value<bool> thursday,
  Value<bool> friday,
  Value<bool> saturday,
  Value<bool> sunday,
  Value<int> startTime,
  Value<int> endTime,
  Value<List<String>> changes,
  Value<Status> status,
  Value<int> rowid,
});

final class $$RoutinesTableReferences
    extends BaseReferences<_$AppDatabase, $RoutinesTable, RoutineEntry> {
  $$RoutinesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RoutineGroupsTable, List<RoutineGroupEntry>>
      _routineGroupsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.routineGroups,
              aliasName: $_aliasNameGenerator(
                  db.routines.id, db.routineGroups.routine));

  $$RoutineGroupsTableProcessedTableManager get routineGroupsRefs {
    final manager = $$RoutineGroupsTableTableManager($_db, $_db.routineGroups)
        .filter((f) => f.routine.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_routineGroupsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$RoutinesTableFilterComposer
    extends Composer<_$AppDatabase, $RoutinesTable> {
  $$RoutinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get monday => $composableBuilder(
      column: $table.monday, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get tuesday => $composableBuilder(
      column: $table.tuesday, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get wednesday => $composableBuilder(
      column: $table.wednesday, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get thursday => $composableBuilder(
      column: $table.thursday, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get friday => $composableBuilder(
      column: $table.friday, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get saturday => $composableBuilder(
      column: $table.saturday, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get sunday => $composableBuilder(
      column: $table.sunday, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
      get changes => $composableBuilder(
          column: $table.changes,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<Status, Status, String> get status =>
      $composableBuilder(
          column: $table.status,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  Expression<bool> routineGroupsRefs(
      Expression<bool> Function($$RoutineGroupsTableFilterComposer f) f) {
    final $$RoutineGroupsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.routineGroups,
        getReferencedColumn: (t) => t.routine,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoutineGroupsTableFilterComposer(
              $db: $db,
              $table: $db.routineGroups,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$RoutinesTableOrderingComposer
    extends Composer<_$AppDatabase, $RoutinesTable> {
  $$RoutinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get monday => $composableBuilder(
      column: $table.monday, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get tuesday => $composableBuilder(
      column: $table.tuesday, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get wednesday => $composableBuilder(
      column: $table.wednesday, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get thursday => $composableBuilder(
      column: $table.thursday, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get friday => $composableBuilder(
      column: $table.friday, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get saturday => $composableBuilder(
      column: $table.saturday, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get sunday => $composableBuilder(
      column: $table.sunday, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get changes => $composableBuilder(
      column: $table.changes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));
}

class $$RoutinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RoutinesTable> {
  $$RoutinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get monday =>
      $composableBuilder(column: $table.monday, builder: (column) => column);

  GeneratedColumn<bool> get tuesday =>
      $composableBuilder(column: $table.tuesday, builder: (column) => column);

  GeneratedColumn<bool> get wednesday =>
      $composableBuilder(column: $table.wednesday, builder: (column) => column);

  GeneratedColumn<bool> get thursday =>
      $composableBuilder(column: $table.thursday, builder: (column) => column);

  GeneratedColumn<bool> get friday =>
      $composableBuilder(column: $table.friday, builder: (column) => column);

  GeneratedColumn<bool> get saturday =>
      $composableBuilder(column: $table.saturday, builder: (column) => column);

  GeneratedColumn<bool> get sunday =>
      $composableBuilder(column: $table.sunday, builder: (column) => column);

  GeneratedColumn<int> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<int> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get changes =>
      $composableBuilder(column: $table.changes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Status, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  Expression<T> routineGroupsRefs<T extends Object>(
      Expression<T> Function($$RoutineGroupsTableAnnotationComposer a) f) {
    final $$RoutineGroupsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.routineGroups,
        getReferencedColumn: (t) => t.routine,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoutineGroupsTableAnnotationComposer(
              $db: $db,
              $table: $db.routineGroups,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$RoutinesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RoutinesTable,
    RoutineEntry,
    $$RoutinesTableFilterComposer,
    $$RoutinesTableOrderingComposer,
    $$RoutinesTableAnnotationComposer,
    $$RoutinesTableCreateCompanionBuilder,
    $$RoutinesTableUpdateCompanionBuilder,
    (RoutineEntry, $$RoutinesTableReferences),
    RoutineEntry,
    PrefetchHooks Function({bool routineGroupsRefs})> {
  $$RoutinesTableTableManager(_$AppDatabase db, $RoutinesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoutinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RoutinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RoutinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<bool> monday = const Value.absent(),
            Value<bool> tuesday = const Value.absent(),
            Value<bool> wednesday = const Value.absent(),
            Value<bool> thursday = const Value.absent(),
            Value<bool> friday = const Value.absent(),
            Value<bool> saturday = const Value.absent(),
            Value<bool> sunday = const Value.absent(),
            Value<int> startTime = const Value.absent(),
            Value<int> endTime = const Value.absent(),
            Value<List<String>> changes = const Value.absent(),
            Value<Status> status = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RoutinesCompanion(
            id: id,
            name: name,
            monday: monday,
            tuesday: tuesday,
            wednesday: wednesday,
            thursday: thursday,
            friday: friday,
            saturday: saturday,
            sunday: sunday,
            startTime: startTime,
            endTime: endTime,
            changes: changes,
            status: status,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required bool monday,
            required bool tuesday,
            required bool wednesday,
            required bool thursday,
            required bool friday,
            required bool saturday,
            required bool sunday,
            required int startTime,
            required int endTime,
            required List<String> changes,
            required Status status,
            Value<int> rowid = const Value.absent(),
          }) =>
              RoutinesCompanion.insert(
            id: id,
            name: name,
            monday: monday,
            tuesday: tuesday,
            wednesday: wednesday,
            thursday: thursday,
            friday: friday,
            saturday: saturday,
            sunday: sunday,
            startTime: startTime,
            endTime: endTime,
            changes: changes,
            status: status,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$RoutinesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({routineGroupsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (routineGroupsRefs) db.routineGroups
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (routineGroupsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$RoutinesTableReferences
                            ._routineGroupsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$RoutinesTableReferences(db, table, p0)
                                .routineGroupsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.routine == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$RoutinesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RoutinesTable,
    RoutineEntry,
    $$RoutinesTableFilterComposer,
    $$RoutinesTableOrderingComposer,
    $$RoutinesTableAnnotationComposer,
    $$RoutinesTableCreateCompanionBuilder,
    $$RoutinesTableUpdateCompanionBuilder,
    (RoutineEntry, $$RoutinesTableReferences),
    RoutineEntry,
    PrefetchHooks Function({bool routineGroupsRefs})>;
typedef $$DevicesTableCreateCompanionBuilder = DevicesCompanion Function({
  required String id,
  required String name,
  required String type,
  required bool curr,
  Value<int> rowid,
});
typedef $$DevicesTableUpdateCompanionBuilder = DevicesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> type,
  Value<bool> curr,
  Value<int> rowid,
});

final class $$DevicesTableReferences
    extends BaseReferences<_$AppDatabase, $DevicesTable, DeviceEntry> {
  $$DevicesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$GroupsTable, List<GroupEntry>> _groupsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.groups,
          aliasName: $_aliasNameGenerator(db.devices.id, db.groups.device));

  $$GroupsTableProcessedTableManager get groupsRefs {
    final manager = $$GroupsTableTableManager($_db, $_db.groups)
        .filter((f) => f.device.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_groupsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$DevicesTableFilterComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get curr => $composableBuilder(
      column: $table.curr, builder: (column) => ColumnFilters(column));

  Expression<bool> groupsRefs(
      Expression<bool> Function($$GroupsTableFilterComposer f) f) {
    final $$GroupsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.groups,
        getReferencedColumn: (t) => t.device,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GroupsTableFilterComposer(
              $db: $db,
              $table: $db.groups,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$DevicesTableOrderingComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get curr => $composableBuilder(
      column: $table.curr, builder: (column) => ColumnOrderings(column));
}

class $$DevicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<bool> get curr =>
      $composableBuilder(column: $table.curr, builder: (column) => column);

  Expression<T> groupsRefs<T extends Object>(
      Expression<T> Function($$GroupsTableAnnotationComposer a) f) {
    final $$GroupsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.groups,
        getReferencedColumn: (t) => t.device,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GroupsTableAnnotationComposer(
              $db: $db,
              $table: $db.groups,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$DevicesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DevicesTable,
    DeviceEntry,
    $$DevicesTableFilterComposer,
    $$DevicesTableOrderingComposer,
    $$DevicesTableAnnotationComposer,
    $$DevicesTableCreateCompanionBuilder,
    $$DevicesTableUpdateCompanionBuilder,
    (DeviceEntry, $$DevicesTableReferences),
    DeviceEntry,
    PrefetchHooks Function({bool groupsRefs})> {
  $$DevicesTableTableManager(_$AppDatabase db, $DevicesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DevicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DevicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DevicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<bool> curr = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DevicesCompanion(
            id: id,
            name: name,
            type: type,
            curr: curr,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String type,
            required bool curr,
            Value<int> rowid = const Value.absent(),
          }) =>
              DevicesCompanion.insert(
            id: id,
            name: name,
            type: type,
            curr: curr,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$DevicesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({groupsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (groupsRefs) db.groups],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (groupsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$DevicesTableReferences._groupsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$DevicesTableReferences(db, table, p0).groupsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.device == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$DevicesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DevicesTable,
    DeviceEntry,
    $$DevicesTableFilterComposer,
    $$DevicesTableOrderingComposer,
    $$DevicesTableAnnotationComposer,
    $$DevicesTableCreateCompanionBuilder,
    $$DevicesTableUpdateCompanionBuilder,
    (DeviceEntry, $$DevicesTableReferences),
    DeviceEntry,
    PrefetchHooks Function({bool groupsRefs})>;
typedef $$GroupsTableCreateCompanionBuilder = GroupsCompanion Function({
  required String id,
  Value<String?> name,
  required String device,
  required bool allow,
  required List<String> apps,
  required List<String> sites,
  required List<String> changes,
  required Status status,
  Value<int> rowid,
});
typedef $$GroupsTableUpdateCompanionBuilder = GroupsCompanion Function({
  Value<String> id,
  Value<String?> name,
  Value<String> device,
  Value<bool> allow,
  Value<List<String>> apps,
  Value<List<String>> sites,
  Value<List<String>> changes,
  Value<Status> status,
  Value<int> rowid,
});

final class $$GroupsTableReferences
    extends BaseReferences<_$AppDatabase, $GroupsTable, GroupEntry> {
  $$GroupsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DevicesTable _deviceTable(_$AppDatabase db) => db.devices
      .createAlias($_aliasNameGenerator(db.groups.device, db.devices.id));

  $$DevicesTableProcessedTableManager get device {
    final $_column = $_itemColumn<String>('device')!;

    final manager = $$DevicesTableTableManager($_db, $_db.devices)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_deviceTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$RoutineGroupsTable, List<RoutineGroupEntry>>
      _routineGroupsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.routineGroups,
              aliasName:
                  $_aliasNameGenerator(db.groups.id, db.routineGroups.group));

  $$RoutineGroupsTableProcessedTableManager get routineGroupsRefs {
    final manager = $$RoutineGroupsTableTableManager($_db, $_db.routineGroups)
        .filter((f) => f.group.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_routineGroupsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$GroupsTableFilterComposer
    extends Composer<_$AppDatabase, $GroupsTable> {
  $$GroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get allow => $composableBuilder(
      column: $table.allow, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<String>, List<String>, String> get apps =>
      $composableBuilder(
          column: $table.apps,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
      get sites => $composableBuilder(
          column: $table.sites,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
      get changes => $composableBuilder(
          column: $table.changes,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<Status, Status, String> get status =>
      $composableBuilder(
          column: $table.status,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  $$DevicesTableFilterComposer get device {
    final $$DevicesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.device,
        referencedTable: $db.devices,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DevicesTableFilterComposer(
              $db: $db,
              $table: $db.devices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> routineGroupsRefs(
      Expression<bool> Function($$RoutineGroupsTableFilterComposer f) f) {
    final $$RoutineGroupsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.routineGroups,
        getReferencedColumn: (t) => t.group,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoutineGroupsTableFilterComposer(
              $db: $db,
              $table: $db.routineGroups,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$GroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $GroupsTable> {
  $$GroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get allow => $composableBuilder(
      column: $table.allow, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get apps => $composableBuilder(
      column: $table.apps, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sites => $composableBuilder(
      column: $table.sites, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get changes => $composableBuilder(
      column: $table.changes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  $$DevicesTableOrderingComposer get device {
    final $$DevicesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.device,
        referencedTable: $db.devices,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DevicesTableOrderingComposer(
              $db: $db,
              $table: $db.devices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GroupsTable> {
  $$GroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get allow =>
      $composableBuilder(column: $table.allow, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get apps =>
      $composableBuilder(column: $table.apps, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get sites =>
      $composableBuilder(column: $table.sites, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get changes =>
      $composableBuilder(column: $table.changes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Status, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  $$DevicesTableAnnotationComposer get device {
    final $$DevicesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.device,
        referencedTable: $db.devices,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DevicesTableAnnotationComposer(
              $db: $db,
              $table: $db.devices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> routineGroupsRefs<T extends Object>(
      Expression<T> Function($$RoutineGroupsTableAnnotationComposer a) f) {
    final $$RoutineGroupsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.routineGroups,
        getReferencedColumn: (t) => t.group,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoutineGroupsTableAnnotationComposer(
              $db: $db,
              $table: $db.routineGroups,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$GroupsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GroupsTable,
    GroupEntry,
    $$GroupsTableFilterComposer,
    $$GroupsTableOrderingComposer,
    $$GroupsTableAnnotationComposer,
    $$GroupsTableCreateCompanionBuilder,
    $$GroupsTableUpdateCompanionBuilder,
    (GroupEntry, $$GroupsTableReferences),
    GroupEntry,
    PrefetchHooks Function({bool device, bool routineGroupsRefs})> {
  $$GroupsTableTableManager(_$AppDatabase db, $GroupsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> name = const Value.absent(),
            Value<String> device = const Value.absent(),
            Value<bool> allow = const Value.absent(),
            Value<List<String>> apps = const Value.absent(),
            Value<List<String>> sites = const Value.absent(),
            Value<List<String>> changes = const Value.absent(),
            Value<Status> status = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GroupsCompanion(
            id: id,
            name: name,
            device: device,
            allow: allow,
            apps: apps,
            sites: sites,
            changes: changes,
            status: status,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> name = const Value.absent(),
            required String device,
            required bool allow,
            required List<String> apps,
            required List<String> sites,
            required List<String> changes,
            required Status status,
            Value<int> rowid = const Value.absent(),
          }) =>
              GroupsCompanion.insert(
            id: id,
            name: name,
            device: device,
            allow: allow,
            apps: apps,
            sites: sites,
            changes: changes,
            status: status,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$GroupsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({device = false, routineGroupsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (routineGroupsRefs) db.routineGroups
              ],
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
                if (device) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.device,
                    referencedTable: $$GroupsTableReferences._deviceTable(db),
                    referencedColumn:
                        $$GroupsTableReferences._deviceTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (routineGroupsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$GroupsTableReferences._routineGroupsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$GroupsTableReferences(db, table, p0)
                                .routineGroupsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.group == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$GroupsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GroupsTable,
    GroupEntry,
    $$GroupsTableFilterComposer,
    $$GroupsTableOrderingComposer,
    $$GroupsTableAnnotationComposer,
    $$GroupsTableCreateCompanionBuilder,
    $$GroupsTableUpdateCompanionBuilder,
    (GroupEntry, $$GroupsTableReferences),
    GroupEntry,
    PrefetchHooks Function({bool device, bool routineGroupsRefs})>;
typedef $$RoutineGroupsTableCreateCompanionBuilder = RoutineGroupsCompanion
    Function({
  required String id,
  required String routine,
  required String group,
  Value<int> rowid,
});
typedef $$RoutineGroupsTableUpdateCompanionBuilder = RoutineGroupsCompanion
    Function({
  Value<String> id,
  Value<String> routine,
  Value<String> group,
  Value<int> rowid,
});

final class $$RoutineGroupsTableReferences extends BaseReferences<_$AppDatabase,
    $RoutineGroupsTable, RoutineGroupEntry> {
  $$RoutineGroupsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $RoutinesTable _routineTable(_$AppDatabase db) =>
      db.routines.createAlias(
          $_aliasNameGenerator(db.routineGroups.routine, db.routines.id));

  $$RoutinesTableProcessedTableManager get routine {
    final $_column = $_itemColumn<String>('routine')!;

    final manager = $$RoutinesTableTableManager($_db, $_db.routines)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_routineTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $GroupsTable _groupTable(_$AppDatabase db) => db.groups
      .createAlias($_aliasNameGenerator(db.routineGroups.group, db.groups.id));

  $$GroupsTableProcessedTableManager get group {
    final $_column = $_itemColumn<String>('group')!;

    final manager = $$GroupsTableTableManager($_db, $_db.groups)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$RoutineGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $RoutineGroupsTable> {
  $$RoutineGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  $$RoutinesTableFilterComposer get routine {
    final $$RoutinesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.routine,
        referencedTable: $db.routines,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoutinesTableFilterComposer(
              $db: $db,
              $table: $db.routines,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$GroupsTableFilterComposer get group {
    final $$GroupsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.group,
        referencedTable: $db.groups,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GroupsTableFilterComposer(
              $db: $db,
              $table: $db.groups,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RoutineGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $RoutineGroupsTable> {
  $$RoutineGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  $$RoutinesTableOrderingComposer get routine {
    final $$RoutinesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.routine,
        referencedTable: $db.routines,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoutinesTableOrderingComposer(
              $db: $db,
              $table: $db.routines,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$GroupsTableOrderingComposer get group {
    final $$GroupsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.group,
        referencedTable: $db.groups,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GroupsTableOrderingComposer(
              $db: $db,
              $table: $db.groups,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RoutineGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RoutineGroupsTable> {
  $$RoutineGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  $$RoutinesTableAnnotationComposer get routine {
    final $$RoutinesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.routine,
        referencedTable: $db.routines,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoutinesTableAnnotationComposer(
              $db: $db,
              $table: $db.routines,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$GroupsTableAnnotationComposer get group {
    final $$GroupsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.group,
        referencedTable: $db.groups,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GroupsTableAnnotationComposer(
              $db: $db,
              $table: $db.groups,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RoutineGroupsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RoutineGroupsTable,
    RoutineGroupEntry,
    $$RoutineGroupsTableFilterComposer,
    $$RoutineGroupsTableOrderingComposer,
    $$RoutineGroupsTableAnnotationComposer,
    $$RoutineGroupsTableCreateCompanionBuilder,
    $$RoutineGroupsTableUpdateCompanionBuilder,
    (RoutineGroupEntry, $$RoutineGroupsTableReferences),
    RoutineGroupEntry,
    PrefetchHooks Function({bool routine, bool group})> {
  $$RoutineGroupsTableTableManager(_$AppDatabase db, $RoutineGroupsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoutineGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RoutineGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RoutineGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> routine = const Value.absent(),
            Value<String> group = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RoutineGroupsCompanion(
            id: id,
            routine: routine,
            group: group,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String routine,
            required String group,
            Value<int> rowid = const Value.absent(),
          }) =>
              RoutineGroupsCompanion.insert(
            id: id,
            routine: routine,
            group: group,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$RoutineGroupsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({routine = false, group = false}) {
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
                if (routine) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.routine,
                    referencedTable:
                        $$RoutineGroupsTableReferences._routineTable(db),
                    referencedColumn:
                        $$RoutineGroupsTableReferences._routineTable(db).id,
                  ) as T;
                }
                if (group) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.group,
                    referencedTable:
                        $$RoutineGroupsTableReferences._groupTable(db),
                    referencedColumn:
                        $$RoutineGroupsTableReferences._groupTable(db).id,
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

typedef $$RoutineGroupsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RoutineGroupsTable,
    RoutineGroupEntry,
    $$RoutineGroupsTableFilterComposer,
    $$RoutineGroupsTableOrderingComposer,
    $$RoutineGroupsTableAnnotationComposer,
    $$RoutineGroupsTableCreateCompanionBuilder,
    $$RoutineGroupsTableUpdateCompanionBuilder,
    (RoutineGroupEntry, $$RoutineGroupsTableReferences),
    RoutineGroupEntry,
    PrefetchHooks Function({bool routine, bool group})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$RoutinesTableTableManager get routines =>
      $$RoutinesTableTableManager(_db, _db.routines);
  $$DevicesTableTableManager get devices =>
      $$DevicesTableTableManager(_db, _db.devices);
  $$GroupsTableTableManager get groups =>
      $$GroupsTableTableManager(_db, _db.groups);
  $$RoutineGroupsTableTableManager get routineGroups =>
      $$RoutineGroupsTableTableManager(_db, _db.routineGroups);
}
