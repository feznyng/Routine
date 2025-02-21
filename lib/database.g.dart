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
  static const VerificationMeta _recurringMeta =
      const VerificationMeta('recurring');
  @override
  late final GeneratedColumn<bool> recurring = GeneratedColumn<bool>(
      'recurring', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("recurring" IN (0, 1))'));
  static const VerificationMeta _changesMeta =
      const VerificationMeta('changes');
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> changes =
      GeneratedColumn<String>('changes', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<List<String>>($RoutinesTable.$converterchanges);
  static const VerificationMeta _deletedMeta =
      const VerificationMeta('deleted');
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
      'deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("deleted" IN (0, 1))'),
      clientDefault: () => false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _groupsMeta = const VerificationMeta('groups');
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> groups =
      GeneratedColumn<String>('groups', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<List<String>>($RoutinesTable.$convertergroups);
  static const VerificationMeta _numBreaksTakenMeta =
      const VerificationMeta('numBreaksTaken');
  @override
  late final GeneratedColumn<int> numBreaksTaken = GeneratedColumn<int>(
      'num_breaks_taken', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _lastBreakAtMeta =
      const VerificationMeta('lastBreakAt');
  @override
  late final GeneratedColumn<DateTime> lastBreakAt = GeneratedColumn<DateTime>(
      'last_break_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _breakUntilMeta =
      const VerificationMeta('breakUntil');
  @override
  late final GeneratedColumn<DateTime> breakUntil = GeneratedColumn<DateTime>(
      'break_until', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _maxBreaksMeta =
      const VerificationMeta('maxBreaks');
  @override
  late final GeneratedColumn<int> maxBreaks = GeneratedColumn<int>(
      'max_breaks', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _maxBreakDurationMeta =
      const VerificationMeta('maxBreakDuration');
  @override
  late final GeneratedColumn<int> maxBreakDuration = GeneratedColumn<int>(
      'max_break_duration', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      clientDefault: () => 15);
  static const VerificationMeta _frictionMeta =
      const VerificationMeta('friction');
  @override
  late final GeneratedColumnWithTypeConverter<FrictionType, String> friction =
      GeneratedColumn<String>('friction', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<FrictionType>($RoutinesTable.$converterfriction);
  static const VerificationMeta _frictionLenMeta =
      const VerificationMeta('frictionLen');
  @override
  late final GeneratedColumn<int> frictionLen = GeneratedColumn<int>(
      'friction_len', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _snoozedUntilMeta =
      const VerificationMeta('snoozedUntil');
  @override
  late final GeneratedColumn<DateTime> snoozedUntil = GeneratedColumn<DateTime>(
      'snoozed_until', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
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
        recurring,
        changes,
        deleted,
        updatedAt,
        groups,
        numBreaksTaken,
        lastBreakAt,
        breakUntil,
        maxBreaks,
        maxBreakDuration,
        friction,
        frictionLen,
        snoozedUntil
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
    if (data.containsKey('recurring')) {
      context.handle(_recurringMeta,
          recurring.isAcceptableOrUnknown(data['recurring']!, _recurringMeta));
    } else if (isInserting) {
      context.missing(_recurringMeta);
    }
    context.handle(_changesMeta, const VerificationResult.success());
    if (data.containsKey('deleted')) {
      context.handle(_deletedMeta,
          deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    context.handle(_groupsMeta, const VerificationResult.success());
    if (data.containsKey('num_breaks_taken')) {
      context.handle(
          _numBreaksTakenMeta,
          numBreaksTaken.isAcceptableOrUnknown(
              data['num_breaks_taken']!, _numBreaksTakenMeta));
    }
    if (data.containsKey('last_break_at')) {
      context.handle(
          _lastBreakAtMeta,
          lastBreakAt.isAcceptableOrUnknown(
              data['last_break_at']!, _lastBreakAtMeta));
    }
    if (data.containsKey('break_until')) {
      context.handle(
          _breakUntilMeta,
          breakUntil.isAcceptableOrUnknown(
              data['break_until']!, _breakUntilMeta));
    }
    if (data.containsKey('max_breaks')) {
      context.handle(_maxBreaksMeta,
          maxBreaks.isAcceptableOrUnknown(data['max_breaks']!, _maxBreaksMeta));
    }
    if (data.containsKey('max_break_duration')) {
      context.handle(
          _maxBreakDurationMeta,
          maxBreakDuration.isAcceptableOrUnknown(
              data['max_break_duration']!, _maxBreakDurationMeta));
    }
    context.handle(_frictionMeta, const VerificationResult.success());
    if (data.containsKey('friction_len')) {
      context.handle(
          _frictionLenMeta,
          frictionLen.isAcceptableOrUnknown(
              data['friction_len']!, _frictionLenMeta));
    }
    if (data.containsKey('snoozed_until')) {
      context.handle(
          _snoozedUntilMeta,
          snoozedUntil.isAcceptableOrUnknown(
              data['snoozed_until']!, _snoozedUntilMeta));
    }
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
      recurring: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}recurring'])!,
      changes: $RoutinesTable.$converterchanges.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}changes'])!),
      deleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}deleted'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      groups: $RoutinesTable.$convertergroups.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}groups'])!),
      numBreaksTaken: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}num_breaks_taken']),
      lastBreakAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_break_at']),
      breakUntil: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}break_until']),
      maxBreaks: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}max_breaks']),
      maxBreakDuration: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}max_break_duration'])!,
      friction: $RoutinesTable.$converterfriction.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}friction'])!),
      frictionLen: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}friction_len']),
      snoozedUntil: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}snoozed_until']),
    );
  }

  @override
  $RoutinesTable createAlias(String alias) {
    return $RoutinesTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $converterchanges =
      StringListTypeConverter();
  static TypeConverter<List<String>, String> $convertergroups =
      StringListTypeConverter();
  static JsonTypeConverter2<FrictionType, String, String> $converterfriction =
      const EnumNameConverter<FrictionType>(FrictionType.values);
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
  final bool recurring;
  final List<String> changes;
  final bool deleted;
  final DateTime updatedAt;
  final List<String> groups;
  final int? numBreaksTaken;
  final DateTime? lastBreakAt;
  final DateTime? breakUntil;
  final int? maxBreaks;
  final int maxBreakDuration;
  final FrictionType friction;
  final int? frictionLen;
  final DateTime? snoozedUntil;
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
      required this.recurring,
      required this.changes,
      required this.deleted,
      required this.updatedAt,
      required this.groups,
      this.numBreaksTaken,
      this.lastBreakAt,
      this.breakUntil,
      this.maxBreaks,
      required this.maxBreakDuration,
      required this.friction,
      this.frictionLen,
      this.snoozedUntil});
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
    map['recurring'] = Variable<bool>(recurring);
    {
      map['changes'] =
          Variable<String>($RoutinesTable.$converterchanges.toSql(changes));
    }
    map['deleted'] = Variable<bool>(deleted);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    {
      map['groups'] =
          Variable<String>($RoutinesTable.$convertergroups.toSql(groups));
    }
    if (!nullToAbsent || numBreaksTaken != null) {
      map['num_breaks_taken'] = Variable<int>(numBreaksTaken);
    }
    if (!nullToAbsent || lastBreakAt != null) {
      map['last_break_at'] = Variable<DateTime>(lastBreakAt);
    }
    if (!nullToAbsent || breakUntil != null) {
      map['break_until'] = Variable<DateTime>(breakUntil);
    }
    if (!nullToAbsent || maxBreaks != null) {
      map['max_breaks'] = Variable<int>(maxBreaks);
    }
    map['max_break_duration'] = Variable<int>(maxBreakDuration);
    {
      map['friction'] =
          Variable<String>($RoutinesTable.$converterfriction.toSql(friction));
    }
    if (!nullToAbsent || frictionLen != null) {
      map['friction_len'] = Variable<int>(frictionLen);
    }
    if (!nullToAbsent || snoozedUntil != null) {
      map['snoozed_until'] = Variable<DateTime>(snoozedUntil);
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
      recurring: Value(recurring),
      changes: Value(changes),
      deleted: Value(deleted),
      updatedAt: Value(updatedAt),
      groups: Value(groups),
      numBreaksTaken: numBreaksTaken == null && nullToAbsent
          ? const Value.absent()
          : Value(numBreaksTaken),
      lastBreakAt: lastBreakAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastBreakAt),
      breakUntil: breakUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(breakUntil),
      maxBreaks: maxBreaks == null && nullToAbsent
          ? const Value.absent()
          : Value(maxBreaks),
      maxBreakDuration: Value(maxBreakDuration),
      friction: Value(friction),
      frictionLen: frictionLen == null && nullToAbsent
          ? const Value.absent()
          : Value(frictionLen),
      snoozedUntil: snoozedUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(snoozedUntil),
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
      recurring: serializer.fromJson<bool>(json['recurring']),
      changes: serializer.fromJson<List<String>>(json['changes']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      groups: serializer.fromJson<List<String>>(json['groups']),
      numBreaksTaken: serializer.fromJson<int?>(json['numBreaksTaken']),
      lastBreakAt: serializer.fromJson<DateTime?>(json['lastBreakAt']),
      breakUntil: serializer.fromJson<DateTime?>(json['breakUntil']),
      maxBreaks: serializer.fromJson<int?>(json['maxBreaks']),
      maxBreakDuration: serializer.fromJson<int>(json['maxBreakDuration']),
      friction: $RoutinesTable.$converterfriction
          .fromJson(serializer.fromJson<String>(json['friction'])),
      frictionLen: serializer.fromJson<int?>(json['frictionLen']),
      snoozedUntil: serializer.fromJson<DateTime?>(json['snoozedUntil']),
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
      'recurring': serializer.toJson<bool>(recurring),
      'changes': serializer.toJson<List<String>>(changes),
      'deleted': serializer.toJson<bool>(deleted),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'groups': serializer.toJson<List<String>>(groups),
      'numBreaksTaken': serializer.toJson<int?>(numBreaksTaken),
      'lastBreakAt': serializer.toJson<DateTime?>(lastBreakAt),
      'breakUntil': serializer.toJson<DateTime?>(breakUntil),
      'maxBreaks': serializer.toJson<int?>(maxBreaks),
      'maxBreakDuration': serializer.toJson<int>(maxBreakDuration),
      'friction': serializer
          .toJson<String>($RoutinesTable.$converterfriction.toJson(friction)),
      'frictionLen': serializer.toJson<int?>(frictionLen),
      'snoozedUntil': serializer.toJson<DateTime?>(snoozedUntil),
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
          bool? recurring,
          List<String>? changes,
          bool? deleted,
          DateTime? updatedAt,
          List<String>? groups,
          Value<int?> numBreaksTaken = const Value.absent(),
          Value<DateTime?> lastBreakAt = const Value.absent(),
          Value<DateTime?> breakUntil = const Value.absent(),
          Value<int?> maxBreaks = const Value.absent(),
          int? maxBreakDuration,
          FrictionType? friction,
          Value<int?> frictionLen = const Value.absent(),
          Value<DateTime?> snoozedUntil = const Value.absent()}) =>
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
        recurring: recurring ?? this.recurring,
        changes: changes ?? this.changes,
        deleted: deleted ?? this.deleted,
        updatedAt: updatedAt ?? this.updatedAt,
        groups: groups ?? this.groups,
        numBreaksTaken:
            numBreaksTaken.present ? numBreaksTaken.value : this.numBreaksTaken,
        lastBreakAt: lastBreakAt.present ? lastBreakAt.value : this.lastBreakAt,
        breakUntil: breakUntil.present ? breakUntil.value : this.breakUntil,
        maxBreaks: maxBreaks.present ? maxBreaks.value : this.maxBreaks,
        maxBreakDuration: maxBreakDuration ?? this.maxBreakDuration,
        friction: friction ?? this.friction,
        frictionLen: frictionLen.present ? frictionLen.value : this.frictionLen,
        snoozedUntil:
            snoozedUntil.present ? snoozedUntil.value : this.snoozedUntil,
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
      recurring: data.recurring.present ? data.recurring.value : this.recurring,
      changes: data.changes.present ? data.changes.value : this.changes,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      groups: data.groups.present ? data.groups.value : this.groups,
      numBreaksTaken: data.numBreaksTaken.present
          ? data.numBreaksTaken.value
          : this.numBreaksTaken,
      lastBreakAt:
          data.lastBreakAt.present ? data.lastBreakAt.value : this.lastBreakAt,
      breakUntil:
          data.breakUntil.present ? data.breakUntil.value : this.breakUntil,
      maxBreaks: data.maxBreaks.present ? data.maxBreaks.value : this.maxBreaks,
      maxBreakDuration: data.maxBreakDuration.present
          ? data.maxBreakDuration.value
          : this.maxBreakDuration,
      friction: data.friction.present ? data.friction.value : this.friction,
      frictionLen:
          data.frictionLen.present ? data.frictionLen.value : this.frictionLen,
      snoozedUntil: data.snoozedUntil.present
          ? data.snoozedUntil.value
          : this.snoozedUntil,
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
          ..write('recurring: $recurring, ')
          ..write('changes: $changes, ')
          ..write('deleted: $deleted, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('groups: $groups, ')
          ..write('numBreaksTaken: $numBreaksTaken, ')
          ..write('lastBreakAt: $lastBreakAt, ')
          ..write('breakUntil: $breakUntil, ')
          ..write('maxBreaks: $maxBreaks, ')
          ..write('maxBreakDuration: $maxBreakDuration, ')
          ..write('friction: $friction, ')
          ..write('frictionLen: $frictionLen, ')
          ..write('snoozedUntil: $snoozedUntil')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
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
        recurring,
        changes,
        deleted,
        updatedAt,
        groups,
        numBreaksTaken,
        lastBreakAt,
        breakUntil,
        maxBreaks,
        maxBreakDuration,
        friction,
        frictionLen,
        snoozedUntil
      ]);
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
          other.recurring == this.recurring &&
          other.changes == this.changes &&
          other.deleted == this.deleted &&
          other.updatedAt == this.updatedAt &&
          other.groups == this.groups &&
          other.numBreaksTaken == this.numBreaksTaken &&
          other.lastBreakAt == this.lastBreakAt &&
          other.breakUntil == this.breakUntil &&
          other.maxBreaks == this.maxBreaks &&
          other.maxBreakDuration == this.maxBreakDuration &&
          other.friction == this.friction &&
          other.frictionLen == this.frictionLen &&
          other.snoozedUntil == this.snoozedUntil);
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
  final Value<bool> recurring;
  final Value<List<String>> changes;
  final Value<bool> deleted;
  final Value<DateTime> updatedAt;
  final Value<List<String>> groups;
  final Value<int?> numBreaksTaken;
  final Value<DateTime?> lastBreakAt;
  final Value<DateTime?> breakUntil;
  final Value<int?> maxBreaks;
  final Value<int> maxBreakDuration;
  final Value<FrictionType> friction;
  final Value<int?> frictionLen;
  final Value<DateTime?> snoozedUntil;
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
    this.recurring = const Value.absent(),
    this.changes = const Value.absent(),
    this.deleted = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.groups = const Value.absent(),
    this.numBreaksTaken = const Value.absent(),
    this.lastBreakAt = const Value.absent(),
    this.breakUntil = const Value.absent(),
    this.maxBreaks = const Value.absent(),
    this.maxBreakDuration = const Value.absent(),
    this.friction = const Value.absent(),
    this.frictionLen = const Value.absent(),
    this.snoozedUntil = const Value.absent(),
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
    required bool recurring,
    required List<String> changes,
    this.deleted = const Value.absent(),
    required DateTime updatedAt,
    required List<String> groups,
    this.numBreaksTaken = const Value.absent(),
    this.lastBreakAt = const Value.absent(),
    this.breakUntil = const Value.absent(),
    this.maxBreaks = const Value.absent(),
    this.maxBreakDuration = const Value.absent(),
    required FrictionType friction,
    this.frictionLen = const Value.absent(),
    this.snoozedUntil = const Value.absent(),
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
        recurring = Value(recurring),
        changes = Value(changes),
        updatedAt = Value(updatedAt),
        groups = Value(groups),
        friction = Value(friction);
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
    Expression<bool>? recurring,
    Expression<String>? changes,
    Expression<bool>? deleted,
    Expression<DateTime>? updatedAt,
    Expression<String>? groups,
    Expression<int>? numBreaksTaken,
    Expression<DateTime>? lastBreakAt,
    Expression<DateTime>? breakUntil,
    Expression<int>? maxBreaks,
    Expression<int>? maxBreakDuration,
    Expression<String>? friction,
    Expression<int>? frictionLen,
    Expression<DateTime>? snoozedUntil,
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
      if (recurring != null) 'recurring': recurring,
      if (changes != null) 'changes': changes,
      if (deleted != null) 'deleted': deleted,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (groups != null) 'groups': groups,
      if (numBreaksTaken != null) 'num_breaks_taken': numBreaksTaken,
      if (lastBreakAt != null) 'last_break_at': lastBreakAt,
      if (breakUntil != null) 'break_until': breakUntil,
      if (maxBreaks != null) 'max_breaks': maxBreaks,
      if (maxBreakDuration != null) 'max_break_duration': maxBreakDuration,
      if (friction != null) 'friction': friction,
      if (frictionLen != null) 'friction_len': frictionLen,
      if (snoozedUntil != null) 'snoozed_until': snoozedUntil,
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
      Value<bool>? recurring,
      Value<List<String>>? changes,
      Value<bool>? deleted,
      Value<DateTime>? updatedAt,
      Value<List<String>>? groups,
      Value<int?>? numBreaksTaken,
      Value<DateTime?>? lastBreakAt,
      Value<DateTime?>? breakUntil,
      Value<int?>? maxBreaks,
      Value<int>? maxBreakDuration,
      Value<FrictionType>? friction,
      Value<int?>? frictionLen,
      Value<DateTime?>? snoozedUntil,
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
      recurring: recurring ?? this.recurring,
      changes: changes ?? this.changes,
      deleted: deleted ?? this.deleted,
      updatedAt: updatedAt ?? this.updatedAt,
      groups: groups ?? this.groups,
      numBreaksTaken: numBreaksTaken ?? this.numBreaksTaken,
      lastBreakAt: lastBreakAt ?? this.lastBreakAt,
      breakUntil: breakUntil ?? this.breakUntil,
      maxBreaks: maxBreaks ?? this.maxBreaks,
      maxBreakDuration: maxBreakDuration ?? this.maxBreakDuration,
      friction: friction ?? this.friction,
      frictionLen: frictionLen ?? this.frictionLen,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
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
    if (recurring.present) {
      map['recurring'] = Variable<bool>(recurring.value);
    }
    if (changes.present) {
      map['changes'] = Variable<String>(
          $RoutinesTable.$converterchanges.toSql(changes.value));
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (groups.present) {
      map['groups'] =
          Variable<String>($RoutinesTable.$convertergroups.toSql(groups.value));
    }
    if (numBreaksTaken.present) {
      map['num_breaks_taken'] = Variable<int>(numBreaksTaken.value);
    }
    if (lastBreakAt.present) {
      map['last_break_at'] = Variable<DateTime>(lastBreakAt.value);
    }
    if (breakUntil.present) {
      map['break_until'] = Variable<DateTime>(breakUntil.value);
    }
    if (maxBreaks.present) {
      map['max_breaks'] = Variable<int>(maxBreaks.value);
    }
    if (maxBreakDuration.present) {
      map['max_break_duration'] = Variable<int>(maxBreakDuration.value);
    }
    if (friction.present) {
      map['friction'] = Variable<String>(
          $RoutinesTable.$converterfriction.toSql(friction.value));
    }
    if (frictionLen.present) {
      map['friction_len'] = Variable<int>(frictionLen.value);
    }
    if (snoozedUntil.present) {
      map['snoozed_until'] = Variable<DateTime>(snoozedUntil.value);
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
          ..write('recurring: $recurring, ')
          ..write('changes: $changes, ')
          ..write('deleted: $deleted, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('groups: $groups, ')
          ..write('numBreaksTaken: $numBreaksTaken, ')
          ..write('lastBreakAt: $lastBreakAt, ')
          ..write('breakUntil: $breakUntil, ')
          ..write('maxBreaks: $maxBreaks, ')
          ..write('maxBreakDuration: $maxBreakDuration, ')
          ..write('friction: $friction, ')
          ..write('frictionLen: $frictionLen, ')
          ..write('snoozedUntil: $snoozedUntil, ')
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
  static const VerificationMeta _deletedMeta =
      const VerificationMeta('deleted');
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
      'deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("deleted" IN (0, 1))'),
      clientDefault: () => false);
  static const VerificationMeta _changesMeta =
      const VerificationMeta('changes');
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> changes =
      GeneratedColumn<String>('changes', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<List<String>>($DevicesTable.$converterchanges);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _lastPulledAtMeta =
      const VerificationMeta('lastPulledAt');
  @override
  late final GeneratedColumn<DateTime> lastPulledAt = GeneratedColumn<DateTime>(
      'last_pulled_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, type, curr, deleted, changes, updatedAt, lastPulledAt];
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
    if (data.containsKey('deleted')) {
      context.handle(_deletedMeta,
          deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta));
    }
    context.handle(_changesMeta, const VerificationResult.success());
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('last_pulled_at')) {
      context.handle(
          _lastPulledAtMeta,
          lastPulledAt.isAcceptableOrUnknown(
              data['last_pulled_at']!, _lastPulledAtMeta));
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
      deleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}deleted'])!,
      changes: $DevicesTable.$converterchanges.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}changes'])!),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      lastPulledAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_pulled_at']),
    );
  }

  @override
  $DevicesTable createAlias(String alias) {
    return $DevicesTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $converterchanges =
      StringListTypeConverter();
}

class DeviceEntry extends DataClass implements Insertable<DeviceEntry> {
  final String id;
  final String name;
  final String type;
  final bool curr;
  final bool deleted;
  final List<String> changes;
  final DateTime updatedAt;
  final DateTime? lastPulledAt;
  const DeviceEntry(
      {required this.id,
      required this.name,
      required this.type,
      required this.curr,
      required this.deleted,
      required this.changes,
      required this.updatedAt,
      this.lastPulledAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['curr'] = Variable<bool>(curr);
    map['deleted'] = Variable<bool>(deleted);
    {
      map['changes'] =
          Variable<String>($DevicesTable.$converterchanges.toSql(changes));
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || lastPulledAt != null) {
      map['last_pulled_at'] = Variable<DateTime>(lastPulledAt);
    }
    return map;
  }

  DevicesCompanion toCompanion(bool nullToAbsent) {
    return DevicesCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      curr: Value(curr),
      deleted: Value(deleted),
      changes: Value(changes),
      updatedAt: Value(updatedAt),
      lastPulledAt: lastPulledAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPulledAt),
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
      deleted: serializer.fromJson<bool>(json['deleted']),
      changes: serializer.fromJson<List<String>>(json['changes']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      lastPulledAt: serializer.fromJson<DateTime?>(json['lastPulledAt']),
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
      'deleted': serializer.toJson<bool>(deleted),
      'changes': serializer.toJson<List<String>>(changes),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'lastPulledAt': serializer.toJson<DateTime?>(lastPulledAt),
    };
  }

  DeviceEntry copyWith(
          {String? id,
          String? name,
          String? type,
          bool? curr,
          bool? deleted,
          List<String>? changes,
          DateTime? updatedAt,
          Value<DateTime?> lastPulledAt = const Value.absent()}) =>
      DeviceEntry(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        curr: curr ?? this.curr,
        deleted: deleted ?? this.deleted,
        changes: changes ?? this.changes,
        updatedAt: updatedAt ?? this.updatedAt,
        lastPulledAt:
            lastPulledAt.present ? lastPulledAt.value : this.lastPulledAt,
      );
  DeviceEntry copyWithCompanion(DevicesCompanion data) {
    return DeviceEntry(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      curr: data.curr.present ? data.curr.value : this.curr,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      changes: data.changes.present ? data.changes.value : this.changes,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastPulledAt: data.lastPulledAt.present
          ? data.lastPulledAt.value
          : this.lastPulledAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeviceEntry(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('curr: $curr, ')
          ..write('deleted: $deleted, ')
          ..write('changes: $changes, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastPulledAt: $lastPulledAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, name, type, curr, deleted, changes, updatedAt, lastPulledAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeviceEntry &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.curr == this.curr &&
          other.deleted == this.deleted &&
          other.changes == this.changes &&
          other.updatedAt == this.updatedAt &&
          other.lastPulledAt == this.lastPulledAt);
}

class DevicesCompanion extends UpdateCompanion<DeviceEntry> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> type;
  final Value<bool> curr;
  final Value<bool> deleted;
  final Value<List<String>> changes;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> lastPulledAt;
  final Value<int> rowid;
  const DevicesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.curr = const Value.absent(),
    this.deleted = const Value.absent(),
    this.changes = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastPulledAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DevicesCompanion.insert({
    required String id,
    required String name,
    required String type,
    required bool curr,
    this.deleted = const Value.absent(),
    required List<String> changes,
    required DateTime updatedAt,
    this.lastPulledAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        type = Value(type),
        curr = Value(curr),
        changes = Value(changes),
        updatedAt = Value(updatedAt);
  static Insertable<DeviceEntry> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<bool>? curr,
    Expression<bool>? deleted,
    Expression<String>? changes,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? lastPulledAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (curr != null) 'curr': curr,
      if (deleted != null) 'deleted': deleted,
      if (changes != null) 'changes': changes,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastPulledAt != null) 'last_pulled_at': lastPulledAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DevicesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? type,
      Value<bool>? curr,
      Value<bool>? deleted,
      Value<List<String>>? changes,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? lastPulledAt,
      Value<int>? rowid}) {
    return DevicesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      curr: curr ?? this.curr,
      deleted: deleted ?? this.deleted,
      changes: changes ?? this.changes,
      updatedAt: updatedAt ?? this.updatedAt,
      lastPulledAt: lastPulledAt ?? this.lastPulledAt,
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
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (changes.present) {
      map['changes'] = Variable<String>(
          $DevicesTable.$converterchanges.toSql(changes.value));
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (lastPulledAt.present) {
      map['last_pulled_at'] = Variable<DateTime>(lastPulledAt.value);
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
          ..write('deleted: $deleted, ')
          ..write('changes: $changes, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastPulledAt: $lastPulledAt, ')
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
  static const VerificationMeta _deletedMeta =
      const VerificationMeta('deleted');
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
      'deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("deleted" IN (0, 1))'),
      clientDefault: () => false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, device, allow, apps, sites, changes, deleted, updatedAt];
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
    if (data.containsKey('deleted')) {
      context.handle(_deletedMeta,
          deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
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
      deleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}deleted'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
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
}

class GroupEntry extends DataClass implements Insertable<GroupEntry> {
  final String id;
  final String? name;
  final String device;
  final bool allow;
  final List<String> apps;
  final List<String> sites;
  final List<String> changes;
  final bool deleted;
  final DateTime updatedAt;
  const GroupEntry(
      {required this.id,
      this.name,
      required this.device,
      required this.allow,
      required this.apps,
      required this.sites,
      required this.changes,
      required this.deleted,
      required this.updatedAt});
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
    map['deleted'] = Variable<bool>(deleted);
    map['updated_at'] = Variable<DateTime>(updatedAt);
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
      deleted: Value(deleted),
      updatedAt: Value(updatedAt),
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
      deleted: serializer.fromJson<bool>(json['deleted']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
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
      'deleted': serializer.toJson<bool>(deleted),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
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
          bool? deleted,
          DateTime? updatedAt}) =>
      GroupEntry(
        id: id ?? this.id,
        name: name.present ? name.value : this.name,
        device: device ?? this.device,
        allow: allow ?? this.allow,
        apps: apps ?? this.apps,
        sites: sites ?? this.sites,
        changes: changes ?? this.changes,
        deleted: deleted ?? this.deleted,
        updatedAt: updatedAt ?? this.updatedAt,
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
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
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
          ..write('deleted: $deleted, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, name, device, allow, apps, sites, changes, deleted, updatedAt);
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
          other.deleted == this.deleted &&
          other.updatedAt == this.updatedAt);
}

class GroupsCompanion extends UpdateCompanion<GroupEntry> {
  final Value<String> id;
  final Value<String?> name;
  final Value<String> device;
  final Value<bool> allow;
  final Value<List<String>> apps;
  final Value<List<String>> sites;
  final Value<List<String>> changes;
  final Value<bool> deleted;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const GroupsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.device = const Value.absent(),
    this.allow = const Value.absent(),
    this.apps = const Value.absent(),
    this.sites = const Value.absent(),
    this.changes = const Value.absent(),
    this.deleted = const Value.absent(),
    this.updatedAt = const Value.absent(),
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
    this.deleted = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        device = Value(device),
        allow = Value(allow),
        apps = Value(apps),
        sites = Value(sites),
        changes = Value(changes),
        updatedAt = Value(updatedAt);
  static Insertable<GroupEntry> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? device,
    Expression<bool>? allow,
    Expression<String>? apps,
    Expression<String>? sites,
    Expression<String>? changes,
    Expression<bool>? deleted,
    Expression<DateTime>? updatedAt,
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
      if (deleted != null) 'deleted': deleted,
      if (updatedAt != null) 'updated_at': updatedAt,
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
      Value<bool>? deleted,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return GroupsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      device: device ?? this.device,
      allow: allow ?? this.allow,
      apps: apps ?? this.apps,
      sites: sites ?? this.sites,
      changes: changes ?? this.changes,
      deleted: deleted ?? this.deleted,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
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
          ..write('deleted: $deleted, ')
          ..write('updatedAt: $updatedAt, ')
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
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [routines, devices, groups];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
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
  required bool recurring,
  required List<String> changes,
  Value<bool> deleted,
  required DateTime updatedAt,
  required List<String> groups,
  Value<int?> numBreaksTaken,
  Value<DateTime?> lastBreakAt,
  Value<DateTime?> breakUntil,
  Value<int?> maxBreaks,
  Value<int> maxBreakDuration,
  required FrictionType friction,
  Value<int?> frictionLen,
  Value<DateTime?> snoozedUntil,
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
  Value<bool> recurring,
  Value<List<String>> changes,
  Value<bool> deleted,
  Value<DateTime> updatedAt,
  Value<List<String>> groups,
  Value<int?> numBreaksTaken,
  Value<DateTime?> lastBreakAt,
  Value<DateTime?> breakUntil,
  Value<int?> maxBreaks,
  Value<int> maxBreakDuration,
  Value<FrictionType> friction,
  Value<int?> frictionLen,
  Value<DateTime?> snoozedUntil,
  Value<int> rowid,
});

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

  ColumnFilters<bool> get recurring => $composableBuilder(
      column: $table.recurring, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
      get changes => $composableBuilder(
          column: $table.changes,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<bool> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
      get groups => $composableBuilder(
          column: $table.groups,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get numBreaksTaken => $composableBuilder(
      column: $table.numBreaksTaken,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastBreakAt => $composableBuilder(
      column: $table.lastBreakAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get breakUntil => $composableBuilder(
      column: $table.breakUntil, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxBreaks => $composableBuilder(
      column: $table.maxBreaks, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxBreakDuration => $composableBuilder(
      column: $table.maxBreakDuration,
      builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<FrictionType, FrictionType, String>
      get friction => $composableBuilder(
          column: $table.friction,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get frictionLen => $composableBuilder(
      column: $table.frictionLen, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get snoozedUntil => $composableBuilder(
      column: $table.snoozedUntil, builder: (column) => ColumnFilters(column));
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

  ColumnOrderings<bool> get recurring => $composableBuilder(
      column: $table.recurring, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get changes => $composableBuilder(
      column: $table.changes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groups => $composableBuilder(
      column: $table.groups, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get numBreaksTaken => $composableBuilder(
      column: $table.numBreaksTaken,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastBreakAt => $composableBuilder(
      column: $table.lastBreakAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get breakUntil => $composableBuilder(
      column: $table.breakUntil, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxBreaks => $composableBuilder(
      column: $table.maxBreaks, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxBreakDuration => $composableBuilder(
      column: $table.maxBreakDuration,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get friction => $composableBuilder(
      column: $table.friction, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get frictionLen => $composableBuilder(
      column: $table.frictionLen, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get snoozedUntil => $composableBuilder(
      column: $table.snoozedUntil,
      builder: (column) => ColumnOrderings(column));
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

  GeneratedColumn<bool> get recurring =>
      $composableBuilder(column: $table.recurring, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get changes =>
      $composableBuilder(column: $table.changes, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get groups =>
      $composableBuilder(column: $table.groups, builder: (column) => column);

  GeneratedColumn<int> get numBreaksTaken => $composableBuilder(
      column: $table.numBreaksTaken, builder: (column) => column);

  GeneratedColumn<DateTime> get lastBreakAt => $composableBuilder(
      column: $table.lastBreakAt, builder: (column) => column);

  GeneratedColumn<DateTime> get breakUntil => $composableBuilder(
      column: $table.breakUntil, builder: (column) => column);

  GeneratedColumn<int> get maxBreaks =>
      $composableBuilder(column: $table.maxBreaks, builder: (column) => column);

  GeneratedColumn<int> get maxBreakDuration => $composableBuilder(
      column: $table.maxBreakDuration, builder: (column) => column);

  GeneratedColumnWithTypeConverter<FrictionType, String> get friction =>
      $composableBuilder(column: $table.friction, builder: (column) => column);

  GeneratedColumn<int> get frictionLen => $composableBuilder(
      column: $table.frictionLen, builder: (column) => column);

  GeneratedColumn<DateTime> get snoozedUntil => $composableBuilder(
      column: $table.snoozedUntil, builder: (column) => column);
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
    (RoutineEntry, BaseReferences<_$AppDatabase, $RoutinesTable, RoutineEntry>),
    RoutineEntry,
    PrefetchHooks Function()> {
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
            Value<bool> recurring = const Value.absent(),
            Value<List<String>> changes = const Value.absent(),
            Value<bool> deleted = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<List<String>> groups = const Value.absent(),
            Value<int?> numBreaksTaken = const Value.absent(),
            Value<DateTime?> lastBreakAt = const Value.absent(),
            Value<DateTime?> breakUntil = const Value.absent(),
            Value<int?> maxBreaks = const Value.absent(),
            Value<int> maxBreakDuration = const Value.absent(),
            Value<FrictionType> friction = const Value.absent(),
            Value<int?> frictionLen = const Value.absent(),
            Value<DateTime?> snoozedUntil = const Value.absent(),
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
            recurring: recurring,
            changes: changes,
            deleted: deleted,
            updatedAt: updatedAt,
            groups: groups,
            numBreaksTaken: numBreaksTaken,
            lastBreakAt: lastBreakAt,
            breakUntil: breakUntil,
            maxBreaks: maxBreaks,
            maxBreakDuration: maxBreakDuration,
            friction: friction,
            frictionLen: frictionLen,
            snoozedUntil: snoozedUntil,
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
            required bool recurring,
            required List<String> changes,
            Value<bool> deleted = const Value.absent(),
            required DateTime updatedAt,
            required List<String> groups,
            Value<int?> numBreaksTaken = const Value.absent(),
            Value<DateTime?> lastBreakAt = const Value.absent(),
            Value<DateTime?> breakUntil = const Value.absent(),
            Value<int?> maxBreaks = const Value.absent(),
            Value<int> maxBreakDuration = const Value.absent(),
            required FrictionType friction,
            Value<int?> frictionLen = const Value.absent(),
            Value<DateTime?> snoozedUntil = const Value.absent(),
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
            recurring: recurring,
            changes: changes,
            deleted: deleted,
            updatedAt: updatedAt,
            groups: groups,
            numBreaksTaken: numBreaksTaken,
            lastBreakAt: lastBreakAt,
            breakUntil: breakUntil,
            maxBreaks: maxBreaks,
            maxBreakDuration: maxBreakDuration,
            friction: friction,
            frictionLen: frictionLen,
            snoozedUntil: snoozedUntil,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
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
    (RoutineEntry, BaseReferences<_$AppDatabase, $RoutinesTable, RoutineEntry>),
    RoutineEntry,
    PrefetchHooks Function()>;
typedef $$DevicesTableCreateCompanionBuilder = DevicesCompanion Function({
  required String id,
  required String name,
  required String type,
  required bool curr,
  Value<bool> deleted,
  required List<String> changes,
  required DateTime updatedAt,
  Value<DateTime?> lastPulledAt,
  Value<int> rowid,
});
typedef $$DevicesTableUpdateCompanionBuilder = DevicesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> type,
  Value<bool> curr,
  Value<bool> deleted,
  Value<List<String>> changes,
  Value<DateTime> updatedAt,
  Value<DateTime?> lastPulledAt,
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

  ColumnFilters<bool> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
      get changes => $composableBuilder(
          column: $table.changes,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastPulledAt => $composableBuilder(
      column: $table.lastPulledAt, builder: (column) => ColumnFilters(column));

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

  ColumnOrderings<bool> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get changes => $composableBuilder(
      column: $table.changes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastPulledAt => $composableBuilder(
      column: $table.lastPulledAt,
      builder: (column) => ColumnOrderings(column));
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

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get changes =>
      $composableBuilder(column: $table.changes, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastPulledAt => $composableBuilder(
      column: $table.lastPulledAt, builder: (column) => column);

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
            Value<bool> deleted = const Value.absent(),
            Value<List<String>> changes = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> lastPulledAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DevicesCompanion(
            id: id,
            name: name,
            type: type,
            curr: curr,
            deleted: deleted,
            changes: changes,
            updatedAt: updatedAt,
            lastPulledAt: lastPulledAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String type,
            required bool curr,
            Value<bool> deleted = const Value.absent(),
            required List<String> changes,
            required DateTime updatedAt,
            Value<DateTime?> lastPulledAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DevicesCompanion.insert(
            id: id,
            name: name,
            type: type,
            curr: curr,
            deleted: deleted,
            changes: changes,
            updatedAt: updatedAt,
            lastPulledAt: lastPulledAt,
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
  Value<bool> deleted,
  required DateTime updatedAt,
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
  Value<bool> deleted,
  Value<DateTime> updatedAt,
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

  ColumnFilters<bool> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

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

  ColumnOrderings<bool> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

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

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

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
    PrefetchHooks Function({bool device})> {
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
            Value<bool> deleted = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
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
            deleted: deleted,
            updatedAt: updatedAt,
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
            Value<bool> deleted = const Value.absent(),
            required DateTime updatedAt,
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
            deleted: deleted,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$GroupsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({device = false}) {
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
                return [];
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
    PrefetchHooks Function({bool device})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$RoutinesTableTableManager get routines =>
      $$RoutinesTableTableManager(_db, _db.routines);
  $$DevicesTableTableManager get devices =>
      $$DevicesTableTableManager(_db, _db.devices);
  $$GroupsTableTableManager get groups =>
      $$GroupsTableTableManager(_db, _db.groups);
}
