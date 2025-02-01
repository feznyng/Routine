// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $RoutinesTable extends Routines with TableInfo<$RoutinesTable, Routine> {
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
  static const VerificationMeta _numBreaksMeta =
      const VerificationMeta('numBreaks');
  @override
  late final GeneratedColumn<int> numBreaks = GeneratedColumn<int>(
      'num_breaks', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _maxBreakDurationMeta =
      const VerificationMeta('maxBreakDuration');
  @override
  late final GeneratedColumn<int> maxBreakDuration = GeneratedColumn<int>(
      'max_break_duration', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _frictionTypeMeta =
      const VerificationMeta('frictionType');
  @override
  late final GeneratedColumn<String> frictionType = GeneratedColumn<String>(
      'friction_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _frictionAmtMeta =
      const VerificationMeta('frictionAmt');
  @override
  late final GeneratedColumn<int> frictionAmt = GeneratedColumn<int>(
      'friction_amt', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _frictionSourceMeta =
      const VerificationMeta('frictionSource');
  @override
  late final GeneratedColumn<String> frictionSource = GeneratedColumn<String>(
      'friction_source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _breaksMeta = const VerificationMeta('breaks');
  @override
  late final GeneratedColumn<String> breaks = GeneratedColumn<String>(
      'breaks', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
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
        numBreaks,
        maxBreakDuration,
        frictionType,
        frictionAmt,
        frictionSource,
        breaks
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'routines';
  @override
  VerificationContext validateIntegrity(Insertable<Routine> instance,
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
    if (data.containsKey('num_breaks')) {
      context.handle(_numBreaksMeta,
          numBreaks.isAcceptableOrUnknown(data['num_breaks']!, _numBreaksMeta));
    } else if (isInserting) {
      context.missing(_numBreaksMeta);
    }
    if (data.containsKey('max_break_duration')) {
      context.handle(
          _maxBreakDurationMeta,
          maxBreakDuration.isAcceptableOrUnknown(
              data['max_break_duration']!, _maxBreakDurationMeta));
    } else if (isInserting) {
      context.missing(_maxBreakDurationMeta);
    }
    if (data.containsKey('friction_type')) {
      context.handle(
          _frictionTypeMeta,
          frictionType.isAcceptableOrUnknown(
              data['friction_type']!, _frictionTypeMeta));
    } else if (isInserting) {
      context.missing(_frictionTypeMeta);
    }
    if (data.containsKey('friction_amt')) {
      context.handle(
          _frictionAmtMeta,
          frictionAmt.isAcceptableOrUnknown(
              data['friction_amt']!, _frictionAmtMeta));
    } else if (isInserting) {
      context.missing(_frictionAmtMeta);
    }
    if (data.containsKey('friction_source')) {
      context.handle(
          _frictionSourceMeta,
          frictionSource.isAcceptableOrUnknown(
              data['friction_source']!, _frictionSourceMeta));
    } else if (isInserting) {
      context.missing(_frictionSourceMeta);
    }
    if (data.containsKey('breaks')) {
      context.handle(_breaksMeta,
          breaks.isAcceptableOrUnknown(data['breaks']!, _breaksMeta));
    } else if (isInserting) {
      context.missing(_breaksMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Routine map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Routine(
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
      numBreaks: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}num_breaks'])!,
      maxBreakDuration: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}max_break_duration'])!,
      frictionType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}friction_type'])!,
      frictionAmt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}friction_amt'])!,
      frictionSource: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}friction_source'])!,
      breaks: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}breaks'])!,
    );
  }

  @override
  $RoutinesTable createAlias(String alias) {
    return $RoutinesTable(attachedDatabase, alias);
  }
}

class Routine extends DataClass implements Insertable<Routine> {
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
  final int numBreaks;
  final int maxBreakDuration;
  final String frictionType;
  final int frictionAmt;
  final String frictionSource;
  final String breaks;
  const Routine(
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
      required this.numBreaks,
      required this.maxBreakDuration,
      required this.frictionType,
      required this.frictionAmt,
      required this.frictionSource,
      required this.breaks});
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
    map['num_breaks'] = Variable<int>(numBreaks);
    map['max_break_duration'] = Variable<int>(maxBreakDuration);
    map['friction_type'] = Variable<String>(frictionType);
    map['friction_amt'] = Variable<int>(frictionAmt);
    map['friction_source'] = Variable<String>(frictionSource);
    map['breaks'] = Variable<String>(breaks);
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
      numBreaks: Value(numBreaks),
      maxBreakDuration: Value(maxBreakDuration),
      frictionType: Value(frictionType),
      frictionAmt: Value(frictionAmt),
      frictionSource: Value(frictionSource),
      breaks: Value(breaks),
    );
  }

  factory Routine.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Routine(
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
      numBreaks: serializer.fromJson<int>(json['numBreaks']),
      maxBreakDuration: serializer.fromJson<int>(json['maxBreakDuration']),
      frictionType: serializer.fromJson<String>(json['frictionType']),
      frictionAmt: serializer.fromJson<int>(json['frictionAmt']),
      frictionSource: serializer.fromJson<String>(json['frictionSource']),
      breaks: serializer.fromJson<String>(json['breaks']),
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
      'numBreaks': serializer.toJson<int>(numBreaks),
      'maxBreakDuration': serializer.toJson<int>(maxBreakDuration),
      'frictionType': serializer.toJson<String>(frictionType),
      'frictionAmt': serializer.toJson<int>(frictionAmt),
      'frictionSource': serializer.toJson<String>(frictionSource),
      'breaks': serializer.toJson<String>(breaks),
    };
  }

  Routine copyWith(
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
          int? numBreaks,
          int? maxBreakDuration,
          String? frictionType,
          int? frictionAmt,
          String? frictionSource,
          String? breaks}) =>
      Routine(
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
        numBreaks: numBreaks ?? this.numBreaks,
        maxBreakDuration: maxBreakDuration ?? this.maxBreakDuration,
        frictionType: frictionType ?? this.frictionType,
        frictionAmt: frictionAmt ?? this.frictionAmt,
        frictionSource: frictionSource ?? this.frictionSource,
        breaks: breaks ?? this.breaks,
      );
  Routine copyWithCompanion(RoutinesCompanion data) {
    return Routine(
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
      numBreaks: data.numBreaks.present ? data.numBreaks.value : this.numBreaks,
      maxBreakDuration: data.maxBreakDuration.present
          ? data.maxBreakDuration.value
          : this.maxBreakDuration,
      frictionType: data.frictionType.present
          ? data.frictionType.value
          : this.frictionType,
      frictionAmt:
          data.frictionAmt.present ? data.frictionAmt.value : this.frictionAmt,
      frictionSource: data.frictionSource.present
          ? data.frictionSource.value
          : this.frictionSource,
      breaks: data.breaks.present ? data.breaks.value : this.breaks,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Routine(')
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
          ..write('numBreaks: $numBreaks, ')
          ..write('maxBreakDuration: $maxBreakDuration, ')
          ..write('frictionType: $frictionType, ')
          ..write('frictionAmt: $frictionAmt, ')
          ..write('frictionSource: $frictionSource, ')
          ..write('breaks: $breaks')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
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
      numBreaks,
      maxBreakDuration,
      frictionType,
      frictionAmt,
      frictionSource,
      breaks);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Routine &&
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
          other.numBreaks == this.numBreaks &&
          other.maxBreakDuration == this.maxBreakDuration &&
          other.frictionType == this.frictionType &&
          other.frictionAmt == this.frictionAmt &&
          other.frictionSource == this.frictionSource &&
          other.breaks == this.breaks);
}

class RoutinesCompanion extends UpdateCompanion<Routine> {
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
  final Value<int> numBreaks;
  final Value<int> maxBreakDuration;
  final Value<String> frictionType;
  final Value<int> frictionAmt;
  final Value<String> frictionSource;
  final Value<String> breaks;
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
    this.numBreaks = const Value.absent(),
    this.maxBreakDuration = const Value.absent(),
    this.frictionType = const Value.absent(),
    this.frictionAmt = const Value.absent(),
    this.frictionSource = const Value.absent(),
    this.breaks = const Value.absent(),
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
    required int numBreaks,
    required int maxBreakDuration,
    required String frictionType,
    required int frictionAmt,
    required String frictionSource,
    required String breaks,
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
        numBreaks = Value(numBreaks),
        maxBreakDuration = Value(maxBreakDuration),
        frictionType = Value(frictionType),
        frictionAmt = Value(frictionAmt),
        frictionSource = Value(frictionSource),
        breaks = Value(breaks);
  static Insertable<Routine> custom({
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
    Expression<int>? numBreaks,
    Expression<int>? maxBreakDuration,
    Expression<String>? frictionType,
    Expression<int>? frictionAmt,
    Expression<String>? frictionSource,
    Expression<String>? breaks,
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
      if (numBreaks != null) 'num_breaks': numBreaks,
      if (maxBreakDuration != null) 'max_break_duration': maxBreakDuration,
      if (frictionType != null) 'friction_type': frictionType,
      if (frictionAmt != null) 'friction_amt': frictionAmt,
      if (frictionSource != null) 'friction_source': frictionSource,
      if (breaks != null) 'breaks': breaks,
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
      Value<int>? numBreaks,
      Value<int>? maxBreakDuration,
      Value<String>? frictionType,
      Value<int>? frictionAmt,
      Value<String>? frictionSource,
      Value<String>? breaks,
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
      numBreaks: numBreaks ?? this.numBreaks,
      maxBreakDuration: maxBreakDuration ?? this.maxBreakDuration,
      frictionType: frictionType ?? this.frictionType,
      frictionAmt: frictionAmt ?? this.frictionAmt,
      frictionSource: frictionSource ?? this.frictionSource,
      breaks: breaks ?? this.breaks,
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
    if (numBreaks.present) {
      map['num_breaks'] = Variable<int>(numBreaks.value);
    }
    if (maxBreakDuration.present) {
      map['max_break_duration'] = Variable<int>(maxBreakDuration.value);
    }
    if (frictionType.present) {
      map['friction_type'] = Variable<String>(frictionType.value);
    }
    if (frictionAmt.present) {
      map['friction_amt'] = Variable<int>(frictionAmt.value);
    }
    if (frictionSource.present) {
      map['friction_source'] = Variable<String>(frictionSource.value);
    }
    if (breaks.present) {
      map['breaks'] = Variable<String>(breaks.value);
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
          ..write('numBreaks: $numBreaks, ')
          ..write('maxBreakDuration: $maxBreakDuration, ')
          ..write('frictionType: $frictionType, ')
          ..write('frictionAmt: $frictionAmt, ')
          ..write('frictionSource: $frictionSource, ')
          ..write('breaks: $breaks, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DevicesTable extends Devices with TableInfo<$DevicesTable, Device> {
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
  @override
  List<GeneratedColumn> get $columns => [id, name, type];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'devices';
  @override
  VerificationContext validateIntegrity(Insertable<Device> instance,
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Device map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Device(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
    );
  }

  @override
  $DevicesTable createAlias(String alias) {
    return $DevicesTable(attachedDatabase, alias);
  }
}

class Device extends DataClass implements Insertable<Device> {
  final String id;
  final String name;
  final String type;
  const Device({required this.id, required this.name, required this.type});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    return map;
  }

  DevicesCompanion toCompanion(bool nullToAbsent) {
    return DevicesCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
    );
  }

  factory Device.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Device(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
    };
  }

  Device copyWith({String? id, String? name, String? type}) => Device(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
      );
  Device copyWithCompanion(DevicesCompanion data) {
    return Device(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Device(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, type);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Device &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type);
}

class DevicesCompanion extends UpdateCompanion<Device> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> type;
  final Value<int> rowid;
  const DevicesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DevicesCompanion.insert({
    required String id,
    required String name,
    required String type,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        type = Value(type);
  static Insertable<Device> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DevicesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? type,
      Value<int>? rowid}) {
    return DevicesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
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
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConditionsTable extends Conditions
    with TableInfo<$ConditionsTable, Condition> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConditionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
      'order', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _orMeta = const VerificationMeta('or');
  @override
  late final GeneratedColumn<bool> or = GeneratedColumn<bool>(
      'or', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("or" IN (0, 1))'));
  static const VerificationMeta _lastCompletedAtMeta =
      const VerificationMeta('lastCompletedAt');
  @override
  late final GeneratedColumn<String> lastCompletedAt = GeneratedColumn<String>(
      'last_completed_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, routine, type, value, order, or, lastCompletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conditions';
  @override
  VerificationContext validateIntegrity(Insertable<Condition> instance,
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
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('order')) {
      context.handle(
          _orderMeta, order.isAcceptableOrUnknown(data['order']!, _orderMeta));
    } else if (isInserting) {
      context.missing(_orderMeta);
    }
    if (data.containsKey('or')) {
      context.handle(_orMeta, or.isAcceptableOrUnknown(data['or']!, _orMeta));
    } else if (isInserting) {
      context.missing(_orMeta);
    }
    if (data.containsKey('last_completed_at')) {
      context.handle(
          _lastCompletedAtMeta,
          lastCompletedAt.isAcceptableOrUnknown(
              data['last_completed_at']!, _lastCompletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Condition map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Condition(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      routine: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}routine'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
      order: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order'])!,
      or: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}or'])!,
      lastCompletedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}last_completed_at']),
    );
  }

  @override
  $ConditionsTable createAlias(String alias) {
    return $ConditionsTable(attachedDatabase, alias);
  }
}

class Condition extends DataClass implements Insertable<Condition> {
  final String id;
  final String routine;
  final String type;
  final String value;
  final int order;
  final bool or;
  final String? lastCompletedAt;
  const Condition(
      {required this.id,
      required this.routine,
      required this.type,
      required this.value,
      required this.order,
      required this.or,
      this.lastCompletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['routine'] = Variable<String>(routine);
    map['type'] = Variable<String>(type);
    map['value'] = Variable<String>(value);
    map['order'] = Variable<int>(order);
    map['or'] = Variable<bool>(or);
    if (!nullToAbsent || lastCompletedAt != null) {
      map['last_completed_at'] = Variable<String>(lastCompletedAt);
    }
    return map;
  }

  ConditionsCompanion toCompanion(bool nullToAbsent) {
    return ConditionsCompanion(
      id: Value(id),
      routine: Value(routine),
      type: Value(type),
      value: Value(value),
      order: Value(order),
      or: Value(or),
      lastCompletedAt: lastCompletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastCompletedAt),
    );
  }

  factory Condition.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Condition(
      id: serializer.fromJson<String>(json['id']),
      routine: serializer.fromJson<String>(json['routine']),
      type: serializer.fromJson<String>(json['type']),
      value: serializer.fromJson<String>(json['value']),
      order: serializer.fromJson<int>(json['order']),
      or: serializer.fromJson<bool>(json['or']),
      lastCompletedAt: serializer.fromJson<String?>(json['lastCompletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'routine': serializer.toJson<String>(routine),
      'type': serializer.toJson<String>(type),
      'value': serializer.toJson<String>(value),
      'order': serializer.toJson<int>(order),
      'or': serializer.toJson<bool>(or),
      'lastCompletedAt': serializer.toJson<String?>(lastCompletedAt),
    };
  }

  Condition copyWith(
          {String? id,
          String? routine,
          String? type,
          String? value,
          int? order,
          bool? or,
          Value<String?> lastCompletedAt = const Value.absent()}) =>
      Condition(
        id: id ?? this.id,
        routine: routine ?? this.routine,
        type: type ?? this.type,
        value: value ?? this.value,
        order: order ?? this.order,
        or: or ?? this.or,
        lastCompletedAt: lastCompletedAt.present
            ? lastCompletedAt.value
            : this.lastCompletedAt,
      );
  Condition copyWithCompanion(ConditionsCompanion data) {
    return Condition(
      id: data.id.present ? data.id.value : this.id,
      routine: data.routine.present ? data.routine.value : this.routine,
      type: data.type.present ? data.type.value : this.type,
      value: data.value.present ? data.value.value : this.value,
      order: data.order.present ? data.order.value : this.order,
      or: data.or.present ? data.or.value : this.or,
      lastCompletedAt: data.lastCompletedAt.present
          ? data.lastCompletedAt.value
          : this.lastCompletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Condition(')
          ..write('id: $id, ')
          ..write('routine: $routine, ')
          ..write('type: $type, ')
          ..write('value: $value, ')
          ..write('order: $order, ')
          ..write('or: $or, ')
          ..write('lastCompletedAt: $lastCompletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, routine, type, value, order, or, lastCompletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Condition &&
          other.id == this.id &&
          other.routine == this.routine &&
          other.type == this.type &&
          other.value == this.value &&
          other.order == this.order &&
          other.or == this.or &&
          other.lastCompletedAt == this.lastCompletedAt);
}

class ConditionsCompanion extends UpdateCompanion<Condition> {
  final Value<String> id;
  final Value<String> routine;
  final Value<String> type;
  final Value<String> value;
  final Value<int> order;
  final Value<bool> or;
  final Value<String?> lastCompletedAt;
  final Value<int> rowid;
  const ConditionsCompanion({
    this.id = const Value.absent(),
    this.routine = const Value.absent(),
    this.type = const Value.absent(),
    this.value = const Value.absent(),
    this.order = const Value.absent(),
    this.or = const Value.absent(),
    this.lastCompletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConditionsCompanion.insert({
    required String id,
    required String routine,
    required String type,
    required String value,
    required int order,
    required bool or,
    this.lastCompletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        routine = Value(routine),
        type = Value(type),
        value = Value(value),
        order = Value(order),
        or = Value(or);
  static Insertable<Condition> custom({
    Expression<String>? id,
    Expression<String>? routine,
    Expression<String>? type,
    Expression<String>? value,
    Expression<int>? order,
    Expression<bool>? or,
    Expression<String>? lastCompletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (routine != null) 'routine': routine,
      if (type != null) 'type': type,
      if (value != null) 'value': value,
      if (order != null) 'order': order,
      if (or != null) 'or': or,
      if (lastCompletedAt != null) 'last_completed_at': lastCompletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConditionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? routine,
      Value<String>? type,
      Value<String>? value,
      Value<int>? order,
      Value<bool>? or,
      Value<String?>? lastCompletedAt,
      Value<int>? rowid}) {
    return ConditionsCompanion(
      id: id ?? this.id,
      routine: routine ?? this.routine,
      type: type ?? this.type,
      value: value ?? this.value,
      order: order ?? this.order,
      or: or ?? this.or,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
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
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    if (or.present) {
      map['or'] = Variable<bool>(or.value);
    }
    if (lastCompletedAt.present) {
      map['last_completed_at'] = Variable<String>(lastCompletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConditionsCompanion(')
          ..write('id: $id, ')
          ..write('routine: $routine, ')
          ..write('type: $type, ')
          ..write('value: $value, ')
          ..write('order: $order, ')
          ..write('or: $or, ')
          ..write('lastCompletedAt: $lastCompletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GroupsTable extends Groups with TableInfo<$GroupsTable, Group> {
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
  @override
  List<GeneratedColumn> get $columns => [id, name, device];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'groups';
  @override
  VerificationContext validateIntegrity(Insertable<Group> instance,
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Group map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Group(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name']),
      device: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device'])!,
    );
  }

  @override
  $GroupsTable createAlias(String alias) {
    return $GroupsTable(attachedDatabase, alias);
  }
}

class Group extends DataClass implements Insertable<Group> {
  final String id;
  final String? name;
  final String device;
  const Group({required this.id, this.name, required this.device});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    map['device'] = Variable<String>(device);
    return map;
  }

  GroupsCompanion toCompanion(bool nullToAbsent) {
    return GroupsCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      device: Value(device),
    );
  }

  factory Group.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Group(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
      device: serializer.fromJson<String>(json['device']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String?>(name),
      'device': serializer.toJson<String>(device),
    };
  }

  Group copyWith(
          {String? id,
          Value<String?> name = const Value.absent(),
          String? device}) =>
      Group(
        id: id ?? this.id,
        name: name.present ? name.value : this.name,
        device: device ?? this.device,
      );
  Group copyWithCompanion(GroupsCompanion data) {
    return Group(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      device: data.device.present ? data.device.value : this.device,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Group(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('device: $device')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, device);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Group &&
          other.id == this.id &&
          other.name == this.name &&
          other.device == this.device);
}

class GroupsCompanion extends UpdateCompanion<Group> {
  final Value<String> id;
  final Value<String?> name;
  final Value<String> device;
  final Value<int> rowid;
  const GroupsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.device = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GroupsCompanion.insert({
    required String id,
    this.name = const Value.absent(),
    required String device,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        device = Value(device);
  static Insertable<Group> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? device,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (device != null) 'device': device,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroupsCompanion copyWith(
      {Value<String>? id,
      Value<String?>? name,
      Value<String>? device,
      Value<int>? rowid}) {
    return GroupsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      device: device ?? this.device,
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
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GroupItemsTable extends GroupItems
    with TableInfo<$GroupItemsTable, GroupItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _siteMeta = const VerificationMeta('site');
  @override
  late final GeneratedColumn<bool> site = GeneratedColumn<bool>(
      'site', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("site" IN (0, 1))'));
  static const VerificationMeta _groupMeta = const VerificationMeta('group');
  @override
  late final GeneratedColumn<String> group = GeneratedColumn<String>(
      'group', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES "groups" (id)'));
  @override
  List<GeneratedColumn> get $columns => [value, site, group];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'group_items';
  @override
  VerificationContext validateIntegrity(Insertable<GroupItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('site')) {
      context.handle(
          _siteMeta, site.isAcceptableOrUnknown(data['site']!, _siteMeta));
    } else if (isInserting) {
      context.missing(_siteMeta);
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
  Set<GeneratedColumn> get $primaryKey => {group, value};
  @override
  GroupItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupItem(
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
      site: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}site'])!,
      group: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group'])!,
    );
  }

  @override
  $GroupItemsTable createAlias(String alias) {
    return $GroupItemsTable(attachedDatabase, alias);
  }
}

class GroupItem extends DataClass implements Insertable<GroupItem> {
  final String value;
  final bool site;
  final String group;
  const GroupItem(
      {required this.value, required this.site, required this.group});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['value'] = Variable<String>(value);
    map['site'] = Variable<bool>(site);
    map['group'] = Variable<String>(group);
    return map;
  }

  GroupItemsCompanion toCompanion(bool nullToAbsent) {
    return GroupItemsCompanion(
      value: Value(value),
      site: Value(site),
      group: Value(group),
    );
  }

  factory GroupItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupItem(
      value: serializer.fromJson<String>(json['value']),
      site: serializer.fromJson<bool>(json['site']),
      group: serializer.fromJson<String>(json['group']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'value': serializer.toJson<String>(value),
      'site': serializer.toJson<bool>(site),
      'group': serializer.toJson<String>(group),
    };
  }

  GroupItem copyWith({String? value, bool? site, String? group}) => GroupItem(
        value: value ?? this.value,
        site: site ?? this.site,
        group: group ?? this.group,
      );
  GroupItem copyWithCompanion(GroupItemsCompanion data) {
    return GroupItem(
      value: data.value.present ? data.value.value : this.value,
      site: data.site.present ? data.site.value : this.site,
      group: data.group.present ? data.group.value : this.group,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroupItem(')
          ..write('value: $value, ')
          ..write('site: $site, ')
          ..write('group: $group')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(value, site, group);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupItem &&
          other.value == this.value &&
          other.site == this.site &&
          other.group == this.group);
}

class GroupItemsCompanion extends UpdateCompanion<GroupItem> {
  final Value<String> value;
  final Value<bool> site;
  final Value<String> group;
  final Value<int> rowid;
  const GroupItemsCompanion({
    this.value = const Value.absent(),
    this.site = const Value.absent(),
    this.group = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GroupItemsCompanion.insert({
    required String value,
    required bool site,
    required String group,
    this.rowid = const Value.absent(),
  })  : value = Value(value),
        site = Value(site),
        group = Value(group);
  static Insertable<GroupItem> custom({
    Expression<String>? value,
    Expression<bool>? site,
    Expression<String>? group,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (value != null) 'value': value,
      if (site != null) 'site': site,
      if (group != null) 'group': group,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroupItemsCompanion copyWith(
      {Value<String>? value,
      Value<bool>? site,
      Value<String>? group,
      Value<int>? rowid}) {
    return GroupItemsCompanion(
      value: value ?? this.value,
      site: site ?? this.site,
      group: group ?? this.group,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (site.present) {
      map['site'] = Variable<bool>(site.value);
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
    return (StringBuffer('GroupItemsCompanion(')
          ..write('value: $value, ')
          ..write('site: $site, ')
          ..write('group: $group, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RoutineGroupsTable extends RoutineGroups
    with TableInfo<$RoutineGroupsTable, RoutineGroup> {
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
  VerificationContext validateIntegrity(Insertable<RoutineGroup> instance,
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
  RoutineGroup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RoutineGroup(
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

class RoutineGroup extends DataClass implements Insertable<RoutineGroup> {
  final String id;
  final String routine;
  final String group;
  const RoutineGroup(
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

  factory RoutineGroup.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RoutineGroup(
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

  RoutineGroup copyWith({String? id, String? routine, String? group}) =>
      RoutineGroup(
        id: id ?? this.id,
        routine: routine ?? this.routine,
        group: group ?? this.group,
      );
  RoutineGroup copyWithCompanion(RoutineGroupsCompanion data) {
    return RoutineGroup(
      id: data.id.present ? data.id.value : this.id,
      routine: data.routine.present ? data.routine.value : this.routine,
      group: data.group.present ? data.group.value : this.group,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RoutineGroup(')
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
      (other is RoutineGroup &&
          other.id == this.id &&
          other.routine == this.routine &&
          other.group == this.group);
}

class RoutineGroupsCompanion extends UpdateCompanion<RoutineGroup> {
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
  static Insertable<RoutineGroup> custom({
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
  late final $ConditionsTable conditions = $ConditionsTable(this);
  late final $GroupsTable groups = $GroupsTable(this);
  late final $GroupItemsTable groupItems = $GroupItemsTable(this);
  late final $RoutineGroupsTable routineGroups = $RoutineGroupsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [routines, devices, conditions, groups, groupItems, routineGroups];
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
  required int numBreaks,
  required int maxBreakDuration,
  required String frictionType,
  required int frictionAmt,
  required String frictionSource,
  required String breaks,
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
  Value<int> numBreaks,
  Value<int> maxBreakDuration,
  Value<String> frictionType,
  Value<int> frictionAmt,
  Value<String> frictionSource,
  Value<String> breaks,
  Value<int> rowid,
});

final class $$RoutinesTableReferences
    extends BaseReferences<_$AppDatabase, $RoutinesTable, Routine> {
  $$RoutinesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ConditionsTable, List<Condition>>
      _conditionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.conditions,
              aliasName:
                  $_aliasNameGenerator(db.routines.id, db.conditions.routine));

  $$ConditionsTableProcessedTableManager get conditionsRefs {
    final manager = $$ConditionsTableTableManager($_db, $_db.conditions)
        .filter((f) => f.routine.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_conditionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$RoutineGroupsTable, List<RoutineGroup>>
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

  ColumnFilters<int> get numBreaks => $composableBuilder(
      column: $table.numBreaks, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxBreakDuration => $composableBuilder(
      column: $table.maxBreakDuration,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get frictionType => $composableBuilder(
      column: $table.frictionType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get frictionAmt => $composableBuilder(
      column: $table.frictionAmt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get frictionSource => $composableBuilder(
      column: $table.frictionSource,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get breaks => $composableBuilder(
      column: $table.breaks, builder: (column) => ColumnFilters(column));

  Expression<bool> conditionsRefs(
      Expression<bool> Function($$ConditionsTableFilterComposer f) f) {
    final $$ConditionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.conditions,
        getReferencedColumn: (t) => t.routine,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ConditionsTableFilterComposer(
              $db: $db,
              $table: $db.conditions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

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

  ColumnOrderings<int> get numBreaks => $composableBuilder(
      column: $table.numBreaks, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxBreakDuration => $composableBuilder(
      column: $table.maxBreakDuration,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get frictionType => $composableBuilder(
      column: $table.frictionType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get frictionAmt => $composableBuilder(
      column: $table.frictionAmt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get frictionSource => $composableBuilder(
      column: $table.frictionSource,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get breaks => $composableBuilder(
      column: $table.breaks, builder: (column) => ColumnOrderings(column));
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

  GeneratedColumn<int> get numBreaks =>
      $composableBuilder(column: $table.numBreaks, builder: (column) => column);

  GeneratedColumn<int> get maxBreakDuration => $composableBuilder(
      column: $table.maxBreakDuration, builder: (column) => column);

  GeneratedColumn<String> get frictionType => $composableBuilder(
      column: $table.frictionType, builder: (column) => column);

  GeneratedColumn<int> get frictionAmt => $composableBuilder(
      column: $table.frictionAmt, builder: (column) => column);

  GeneratedColumn<String> get frictionSource => $composableBuilder(
      column: $table.frictionSource, builder: (column) => column);

  GeneratedColumn<String> get breaks =>
      $composableBuilder(column: $table.breaks, builder: (column) => column);

  Expression<T> conditionsRefs<T extends Object>(
      Expression<T> Function($$ConditionsTableAnnotationComposer a) f) {
    final $$ConditionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.conditions,
        getReferencedColumn: (t) => t.routine,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ConditionsTableAnnotationComposer(
              $db: $db,
              $table: $db.conditions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

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
    Routine,
    $$RoutinesTableFilterComposer,
    $$RoutinesTableOrderingComposer,
    $$RoutinesTableAnnotationComposer,
    $$RoutinesTableCreateCompanionBuilder,
    $$RoutinesTableUpdateCompanionBuilder,
    (Routine, $$RoutinesTableReferences),
    Routine,
    PrefetchHooks Function({bool conditionsRefs, bool routineGroupsRefs})> {
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
            Value<int> numBreaks = const Value.absent(),
            Value<int> maxBreakDuration = const Value.absent(),
            Value<String> frictionType = const Value.absent(),
            Value<int> frictionAmt = const Value.absent(),
            Value<String> frictionSource = const Value.absent(),
            Value<String> breaks = const Value.absent(),
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
            numBreaks: numBreaks,
            maxBreakDuration: maxBreakDuration,
            frictionType: frictionType,
            frictionAmt: frictionAmt,
            frictionSource: frictionSource,
            breaks: breaks,
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
            required int numBreaks,
            required int maxBreakDuration,
            required String frictionType,
            required int frictionAmt,
            required String frictionSource,
            required String breaks,
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
            numBreaks: numBreaks,
            maxBreakDuration: maxBreakDuration,
            frictionType: frictionType,
            frictionAmt: frictionAmt,
            frictionSource: frictionSource,
            breaks: breaks,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$RoutinesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {conditionsRefs = false, routineGroupsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (conditionsRefs) db.conditions,
                if (routineGroupsRefs) db.routineGroups
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (conditionsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$RoutinesTableReferences._conditionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$RoutinesTableReferences(db, table, p0)
                                .conditionsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.routine == item.id),
                        typedResults: items),
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
    Routine,
    $$RoutinesTableFilterComposer,
    $$RoutinesTableOrderingComposer,
    $$RoutinesTableAnnotationComposer,
    $$RoutinesTableCreateCompanionBuilder,
    $$RoutinesTableUpdateCompanionBuilder,
    (Routine, $$RoutinesTableReferences),
    Routine,
    PrefetchHooks Function({bool conditionsRefs, bool routineGroupsRefs})>;
typedef $$DevicesTableCreateCompanionBuilder = DevicesCompanion Function({
  required String id,
  required String name,
  required String type,
  Value<int> rowid,
});
typedef $$DevicesTableUpdateCompanionBuilder = DevicesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> type,
  Value<int> rowid,
});

final class $$DevicesTableReferences
    extends BaseReferences<_$AppDatabase, $DevicesTable, Device> {
  $$DevicesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$GroupsTable, List<Group>> _groupsRefsTable(
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
    Device,
    $$DevicesTableFilterComposer,
    $$DevicesTableOrderingComposer,
    $$DevicesTableAnnotationComposer,
    $$DevicesTableCreateCompanionBuilder,
    $$DevicesTableUpdateCompanionBuilder,
    (Device, $$DevicesTableReferences),
    Device,
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
            Value<int> rowid = const Value.absent(),
          }) =>
              DevicesCompanion(
            id: id,
            name: name,
            type: type,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String type,
            Value<int> rowid = const Value.absent(),
          }) =>
              DevicesCompanion.insert(
            id: id,
            name: name,
            type: type,
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
    Device,
    $$DevicesTableFilterComposer,
    $$DevicesTableOrderingComposer,
    $$DevicesTableAnnotationComposer,
    $$DevicesTableCreateCompanionBuilder,
    $$DevicesTableUpdateCompanionBuilder,
    (Device, $$DevicesTableReferences),
    Device,
    PrefetchHooks Function({bool groupsRefs})>;
typedef $$ConditionsTableCreateCompanionBuilder = ConditionsCompanion Function({
  required String id,
  required String routine,
  required String type,
  required String value,
  required int order,
  required bool or,
  Value<String?> lastCompletedAt,
  Value<int> rowid,
});
typedef $$ConditionsTableUpdateCompanionBuilder = ConditionsCompanion Function({
  Value<String> id,
  Value<String> routine,
  Value<String> type,
  Value<String> value,
  Value<int> order,
  Value<bool> or,
  Value<String?> lastCompletedAt,
  Value<int> rowid,
});

final class $$ConditionsTableReferences
    extends BaseReferences<_$AppDatabase, $ConditionsTable, Condition> {
  $$ConditionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RoutinesTable _routineTable(_$AppDatabase db) => db.routines
      .createAlias($_aliasNameGenerator(db.conditions.routine, db.routines.id));

  $$RoutinesTableProcessedTableManager get routine {
    final $_column = $_itemColumn<String>('routine')!;

    final manager = $$RoutinesTableTableManager($_db, $_db.routines)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_routineTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ConditionsTableFilterComposer
    extends Composer<_$AppDatabase, $ConditionsTable> {
  $$ConditionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get order => $composableBuilder(
      column: $table.order, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get or => $composableBuilder(
      column: $table.or, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastCompletedAt => $composableBuilder(
      column: $table.lastCompletedAt,
      builder: (column) => ColumnFilters(column));

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
}

class $$ConditionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConditionsTable> {
  $$ConditionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get order => $composableBuilder(
      column: $table.order, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get or => $composableBuilder(
      column: $table.or, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastCompletedAt => $composableBuilder(
      column: $table.lastCompletedAt,
      builder: (column) => ColumnOrderings(column));

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
}

class $$ConditionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConditionsTable> {
  $$ConditionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<int> get order =>
      $composableBuilder(column: $table.order, builder: (column) => column);

  GeneratedColumn<bool> get or =>
      $composableBuilder(column: $table.or, builder: (column) => column);

  GeneratedColumn<String> get lastCompletedAt => $composableBuilder(
      column: $table.lastCompletedAt, builder: (column) => column);

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
}

class $$ConditionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ConditionsTable,
    Condition,
    $$ConditionsTableFilterComposer,
    $$ConditionsTableOrderingComposer,
    $$ConditionsTableAnnotationComposer,
    $$ConditionsTableCreateCompanionBuilder,
    $$ConditionsTableUpdateCompanionBuilder,
    (Condition, $$ConditionsTableReferences),
    Condition,
    PrefetchHooks Function({bool routine})> {
  $$ConditionsTableTableManager(_$AppDatabase db, $ConditionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConditionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConditionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConditionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> routine = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> order = const Value.absent(),
            Value<bool> or = const Value.absent(),
            Value<String?> lastCompletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ConditionsCompanion(
            id: id,
            routine: routine,
            type: type,
            value: value,
            order: order,
            or: or,
            lastCompletedAt: lastCompletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String routine,
            required String type,
            required String value,
            required int order,
            required bool or,
            Value<String?> lastCompletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ConditionsCompanion.insert(
            id: id,
            routine: routine,
            type: type,
            value: value,
            order: order,
            or: or,
            lastCompletedAt: lastCompletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ConditionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({routine = false}) {
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
                        $$ConditionsTableReferences._routineTable(db),
                    referencedColumn:
                        $$ConditionsTableReferences._routineTable(db).id,
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

typedef $$ConditionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ConditionsTable,
    Condition,
    $$ConditionsTableFilterComposer,
    $$ConditionsTableOrderingComposer,
    $$ConditionsTableAnnotationComposer,
    $$ConditionsTableCreateCompanionBuilder,
    $$ConditionsTableUpdateCompanionBuilder,
    (Condition, $$ConditionsTableReferences),
    Condition,
    PrefetchHooks Function({bool routine})>;
typedef $$GroupsTableCreateCompanionBuilder = GroupsCompanion Function({
  required String id,
  Value<String?> name,
  required String device,
  Value<int> rowid,
});
typedef $$GroupsTableUpdateCompanionBuilder = GroupsCompanion Function({
  Value<String> id,
  Value<String?> name,
  Value<String> device,
  Value<int> rowid,
});

final class $$GroupsTableReferences
    extends BaseReferences<_$AppDatabase, $GroupsTable, Group> {
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

  static MultiTypedResultKey<$GroupItemsTable, List<GroupItem>>
      _groupItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.groupItems,
          aliasName: $_aliasNameGenerator(db.groups.id, db.groupItems.group));

  $$GroupItemsTableProcessedTableManager get groupItemsRefs {
    final manager = $$GroupItemsTableTableManager($_db, $_db.groupItems)
        .filter((f) => f.group.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_groupItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$RoutineGroupsTable, List<RoutineGroup>>
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

  Expression<bool> groupItemsRefs(
      Expression<bool> Function($$GroupItemsTableFilterComposer f) f) {
    final $$GroupItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.groupItems,
        getReferencedColumn: (t) => t.group,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GroupItemsTableFilterComposer(
              $db: $db,
              $table: $db.groupItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
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

  Expression<T> groupItemsRefs<T extends Object>(
      Expression<T> Function($$GroupItemsTableAnnotationComposer a) f) {
    final $$GroupItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.groupItems,
        getReferencedColumn: (t) => t.group,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GroupItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.groupItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
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
    Group,
    $$GroupsTableFilterComposer,
    $$GroupsTableOrderingComposer,
    $$GroupsTableAnnotationComposer,
    $$GroupsTableCreateCompanionBuilder,
    $$GroupsTableUpdateCompanionBuilder,
    (Group, $$GroupsTableReferences),
    Group,
    PrefetchHooks Function(
        {bool device, bool groupItemsRefs, bool routineGroupsRefs})> {
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
            Value<int> rowid = const Value.absent(),
          }) =>
              GroupsCompanion(
            id: id,
            name: name,
            device: device,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> name = const Value.absent(),
            required String device,
            Value<int> rowid = const Value.absent(),
          }) =>
              GroupsCompanion.insert(
            id: id,
            name: name,
            device: device,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$GroupsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {device = false,
              groupItemsRefs = false,
              routineGroupsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (groupItemsRefs) db.groupItems,
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
                  if (groupItemsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$GroupsTableReferences._groupItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$GroupsTableReferences(db, table, p0)
                                .groupItemsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.group == item.id),
                        typedResults: items),
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
    Group,
    $$GroupsTableFilterComposer,
    $$GroupsTableOrderingComposer,
    $$GroupsTableAnnotationComposer,
    $$GroupsTableCreateCompanionBuilder,
    $$GroupsTableUpdateCompanionBuilder,
    (Group, $$GroupsTableReferences),
    Group,
    PrefetchHooks Function(
        {bool device, bool groupItemsRefs, bool routineGroupsRefs})>;
typedef $$GroupItemsTableCreateCompanionBuilder = GroupItemsCompanion Function({
  required String value,
  required bool site,
  required String group,
  Value<int> rowid,
});
typedef $$GroupItemsTableUpdateCompanionBuilder = GroupItemsCompanion Function({
  Value<String> value,
  Value<bool> site,
  Value<String> group,
  Value<int> rowid,
});

final class $$GroupItemsTableReferences
    extends BaseReferences<_$AppDatabase, $GroupItemsTable, GroupItem> {
  $$GroupItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GroupsTable _groupTable(_$AppDatabase db) => db.groups
      .createAlias($_aliasNameGenerator(db.groupItems.group, db.groups.id));

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

class $$GroupItemsTableFilterComposer
    extends Composer<_$AppDatabase, $GroupItemsTable> {
  $$GroupItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get site => $composableBuilder(
      column: $table.site, builder: (column) => ColumnFilters(column));

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

class $$GroupItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $GroupItemsTable> {
  $$GroupItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get site => $composableBuilder(
      column: $table.site, builder: (column) => ColumnOrderings(column));

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

class $$GroupItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GroupItemsTable> {
  $$GroupItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<bool> get site =>
      $composableBuilder(column: $table.site, builder: (column) => column);

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

class $$GroupItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GroupItemsTable,
    GroupItem,
    $$GroupItemsTableFilterComposer,
    $$GroupItemsTableOrderingComposer,
    $$GroupItemsTableAnnotationComposer,
    $$GroupItemsTableCreateCompanionBuilder,
    $$GroupItemsTableUpdateCompanionBuilder,
    (GroupItem, $$GroupItemsTableReferences),
    GroupItem,
    PrefetchHooks Function({bool group})> {
  $$GroupItemsTableTableManager(_$AppDatabase db, $GroupItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> value = const Value.absent(),
            Value<bool> site = const Value.absent(),
            Value<String> group = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GroupItemsCompanion(
            value: value,
            site: site,
            group: group,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String value,
            required bool site,
            required String group,
            Value<int> rowid = const Value.absent(),
          }) =>
              GroupItemsCompanion.insert(
            value: value,
            site: site,
            group: group,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$GroupItemsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({group = false}) {
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
                if (group) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.group,
                    referencedTable:
                        $$GroupItemsTableReferences._groupTable(db),
                    referencedColumn:
                        $$GroupItemsTableReferences._groupTable(db).id,
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

typedef $$GroupItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GroupItemsTable,
    GroupItem,
    $$GroupItemsTableFilterComposer,
    $$GroupItemsTableOrderingComposer,
    $$GroupItemsTableAnnotationComposer,
    $$GroupItemsTableCreateCompanionBuilder,
    $$GroupItemsTableUpdateCompanionBuilder,
    (GroupItem, $$GroupItemsTableReferences),
    GroupItem,
    PrefetchHooks Function({bool group})>;
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

final class $$RoutineGroupsTableReferences
    extends BaseReferences<_$AppDatabase, $RoutineGroupsTable, RoutineGroup> {
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
    RoutineGroup,
    $$RoutineGroupsTableFilterComposer,
    $$RoutineGroupsTableOrderingComposer,
    $$RoutineGroupsTableAnnotationComposer,
    $$RoutineGroupsTableCreateCompanionBuilder,
    $$RoutineGroupsTableUpdateCompanionBuilder,
    (RoutineGroup, $$RoutineGroupsTableReferences),
    RoutineGroup,
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
    RoutineGroup,
    $$RoutineGroupsTableFilterComposer,
    $$RoutineGroupsTableOrderingComposer,
    $$RoutineGroupsTableAnnotationComposer,
    $$RoutineGroupsTableCreateCompanionBuilder,
    $$RoutineGroupsTableUpdateCompanionBuilder,
    (RoutineGroup, $$RoutineGroupsTableReferences),
    RoutineGroup,
    PrefetchHooks Function({bool routine, bool group})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$RoutinesTableTableManager get routines =>
      $$RoutinesTableTableManager(_db, _db.routines);
  $$DevicesTableTableManager get devices =>
      $$DevicesTableTableManager(_db, _db.devices);
  $$ConditionsTableTableManager get conditions =>
      $$ConditionsTableTableManager(_db, _db.conditions);
  $$GroupsTableTableManager get groups =>
      $$GroupsTableTableManager(_db, _db.groups);
  $$GroupItemsTableTableManager get groupItems =>
      $$GroupItemsTableTableManager(_db, _db.groupItems);
  $$RoutineGroupsTableTableManager get routineGroups =>
      $$RoutineGroupsTableTableManager(_db, _db.routineGroups);
}
