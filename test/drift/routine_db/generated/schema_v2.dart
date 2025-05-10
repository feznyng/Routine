// dart format width=80
// GENERATED CODE, DO NOT EDIT BY HAND.
// ignore_for_file: type=lint
import 'package:drift/drift.dart';

class Routines extends Table with TableInfo<Routines, RoutinesData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Routines(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<bool> monday = GeneratedColumn<bool>(
      'monday', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("monday" IN (0, 1))'));
  late final GeneratedColumn<bool> tuesday = GeneratedColumn<bool>(
      'tuesday', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("tuesday" IN (0, 1))'));
  late final GeneratedColumn<bool> wednesday = GeneratedColumn<bool>(
      'wednesday', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("wednesday" IN (0, 1))'));
  late final GeneratedColumn<bool> thursday = GeneratedColumn<bool>(
      'thursday', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("thursday" IN (0, 1))'));
  late final GeneratedColumn<bool> friday = GeneratedColumn<bool>(
      'friday', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("friday" IN (0, 1))'));
  late final GeneratedColumn<bool> saturday = GeneratedColumn<bool>(
      'saturday', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("saturday" IN (0, 1))'));
  late final GeneratedColumn<bool> sunday = GeneratedColumn<bool>(
      'sunday', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("sunday" IN (0, 1))'));
  late final GeneratedColumn<int> startTime = GeneratedColumn<int>(
      'start_time', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  late final GeneratedColumn<int> endTime = GeneratedColumn<int>(
      'end_time', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  late final GeneratedColumn<int> recurrence = GeneratedColumn<int>(
      'recurrence', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  late final GeneratedColumn<String> changes = GeneratedColumn<String>(
      'changes', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
      'deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("deleted" IN (0, 1))'));
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  late final GeneratedColumn<String> groups = GeneratedColumn<String>(
      'groups', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<int> numBreaksTaken = GeneratedColumn<int>(
      'num_breaks_taken', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  late final GeneratedColumn<DateTime> lastBreakAt = GeneratedColumn<DateTime>(
      'last_break_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  late final GeneratedColumn<DateTime> pausedUntil = GeneratedColumn<DateTime>(
      'paused_until', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  late final GeneratedColumn<int> maxBreaks = GeneratedColumn<int>(
      'max_breaks', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  late final GeneratedColumn<int> maxBreakDuration = GeneratedColumn<int>(
      'max_break_duration', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  late final GeneratedColumn<String> friction = GeneratedColumn<String>(
      'friction', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<int> frictionLen = GeneratedColumn<int>(
      'friction_len', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  late final GeneratedColumn<DateTime> snoozedUntil = GeneratedColumn<DateTime>(
      'snoozed_until', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  late final GeneratedColumn<String> conditions = GeneratedColumn<String>(
      'conditions', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<bool> strictMode = GeneratedColumn<bool>(
      'strict_mode', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("strict_mode" IN (0, 1))'));
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
        recurrence,
        changes,
        deleted,
        updatedAt,
        groups,
        numBreaksTaken,
        lastBreakAt,
        pausedUntil,
        maxBreaks,
        maxBreakDuration,
        friction,
        frictionLen,
        snoozedUntil,
        conditions,
        strictMode
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'routines';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RoutinesData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RoutinesData(
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
      recurrence: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}recurrence']),
      changes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}changes'])!,
      deleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}deleted'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      groups: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}groups'])!,
      numBreaksTaken: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}num_breaks_taken']),
      lastBreakAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_break_at']),
      pausedUntil: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}paused_until']),
      maxBreaks: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}max_breaks']),
      maxBreakDuration: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}max_break_duration'])!,
      friction: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}friction'])!,
      frictionLen: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}friction_len']),
      snoozedUntil: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}snoozed_until']),
      conditions: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}conditions'])!,
      strictMode: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}strict_mode'])!,
    );
  }

  @override
  Routines createAlias(String alias) {
    return Routines(attachedDatabase, alias);
  }
}

class RoutinesData extends DataClass implements Insertable<RoutinesData> {
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
  final int? recurrence;
  final String changes;
  final bool deleted;
  final DateTime updatedAt;
  final String groups;
  final int? numBreaksTaken;
  final DateTime? lastBreakAt;
  final DateTime? pausedUntil;
  final int? maxBreaks;
  final int maxBreakDuration;
  final String friction;
  final int? frictionLen;
  final DateTime? snoozedUntil;
  final String conditions;
  final bool strictMode;
  const RoutinesData(
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
      this.recurrence,
      required this.changes,
      required this.deleted,
      required this.updatedAt,
      required this.groups,
      this.numBreaksTaken,
      this.lastBreakAt,
      this.pausedUntil,
      this.maxBreaks,
      required this.maxBreakDuration,
      required this.friction,
      this.frictionLen,
      this.snoozedUntil,
      required this.conditions,
      required this.strictMode});
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
    if (!nullToAbsent || recurrence != null) {
      map['recurrence'] = Variable<int>(recurrence);
    }
    map['changes'] = Variable<String>(changes);
    map['deleted'] = Variable<bool>(deleted);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['groups'] = Variable<String>(groups);
    if (!nullToAbsent || numBreaksTaken != null) {
      map['num_breaks_taken'] = Variable<int>(numBreaksTaken);
    }
    if (!nullToAbsent || lastBreakAt != null) {
      map['last_break_at'] = Variable<DateTime>(lastBreakAt);
    }
    if (!nullToAbsent || pausedUntil != null) {
      map['paused_until'] = Variable<DateTime>(pausedUntil);
    }
    if (!nullToAbsent || maxBreaks != null) {
      map['max_breaks'] = Variable<int>(maxBreaks);
    }
    map['max_break_duration'] = Variable<int>(maxBreakDuration);
    map['friction'] = Variable<String>(friction);
    if (!nullToAbsent || frictionLen != null) {
      map['friction_len'] = Variable<int>(frictionLen);
    }
    if (!nullToAbsent || snoozedUntil != null) {
      map['snoozed_until'] = Variable<DateTime>(snoozedUntil);
    }
    map['conditions'] = Variable<String>(conditions);
    map['strict_mode'] = Variable<bool>(strictMode);
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
      recurrence: recurrence == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrence),
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
      pausedUntil: pausedUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(pausedUntil),
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
      conditions: Value(conditions),
      strictMode: Value(strictMode),
    );
  }

  factory RoutinesData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RoutinesData(
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
      recurrence: serializer.fromJson<int?>(json['recurrence']),
      changes: serializer.fromJson<String>(json['changes']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      groups: serializer.fromJson<String>(json['groups']),
      numBreaksTaken: serializer.fromJson<int?>(json['numBreaksTaken']),
      lastBreakAt: serializer.fromJson<DateTime?>(json['lastBreakAt']),
      pausedUntil: serializer.fromJson<DateTime?>(json['pausedUntil']),
      maxBreaks: serializer.fromJson<int?>(json['maxBreaks']),
      maxBreakDuration: serializer.fromJson<int>(json['maxBreakDuration']),
      friction: serializer.fromJson<String>(json['friction']),
      frictionLen: serializer.fromJson<int?>(json['frictionLen']),
      snoozedUntil: serializer.fromJson<DateTime?>(json['snoozedUntil']),
      conditions: serializer.fromJson<String>(json['conditions']),
      strictMode: serializer.fromJson<bool>(json['strictMode']),
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
      'recurrence': serializer.toJson<int?>(recurrence),
      'changes': serializer.toJson<String>(changes),
      'deleted': serializer.toJson<bool>(deleted),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'groups': serializer.toJson<String>(groups),
      'numBreaksTaken': serializer.toJson<int?>(numBreaksTaken),
      'lastBreakAt': serializer.toJson<DateTime?>(lastBreakAt),
      'pausedUntil': serializer.toJson<DateTime?>(pausedUntil),
      'maxBreaks': serializer.toJson<int?>(maxBreaks),
      'maxBreakDuration': serializer.toJson<int>(maxBreakDuration),
      'friction': serializer.toJson<String>(friction),
      'frictionLen': serializer.toJson<int?>(frictionLen),
      'snoozedUntil': serializer.toJson<DateTime?>(snoozedUntil),
      'conditions': serializer.toJson<String>(conditions),
      'strictMode': serializer.toJson<bool>(strictMode),
    };
  }

  RoutinesData copyWith(
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
          Value<int?> recurrence = const Value.absent(),
          String? changes,
          bool? deleted,
          DateTime? updatedAt,
          String? groups,
          Value<int?> numBreaksTaken = const Value.absent(),
          Value<DateTime?> lastBreakAt = const Value.absent(),
          Value<DateTime?> pausedUntil = const Value.absent(),
          Value<int?> maxBreaks = const Value.absent(),
          int? maxBreakDuration,
          String? friction,
          Value<int?> frictionLen = const Value.absent(),
          Value<DateTime?> snoozedUntil = const Value.absent(),
          String? conditions,
          bool? strictMode}) =>
      RoutinesData(
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
        recurrence: recurrence.present ? recurrence.value : this.recurrence,
        changes: changes ?? this.changes,
        deleted: deleted ?? this.deleted,
        updatedAt: updatedAt ?? this.updatedAt,
        groups: groups ?? this.groups,
        numBreaksTaken:
            numBreaksTaken.present ? numBreaksTaken.value : this.numBreaksTaken,
        lastBreakAt: lastBreakAt.present ? lastBreakAt.value : this.lastBreakAt,
        pausedUntil: pausedUntil.present ? pausedUntil.value : this.pausedUntil,
        maxBreaks: maxBreaks.present ? maxBreaks.value : this.maxBreaks,
        maxBreakDuration: maxBreakDuration ?? this.maxBreakDuration,
        friction: friction ?? this.friction,
        frictionLen: frictionLen.present ? frictionLen.value : this.frictionLen,
        snoozedUntil:
            snoozedUntil.present ? snoozedUntil.value : this.snoozedUntil,
        conditions: conditions ?? this.conditions,
        strictMode: strictMode ?? this.strictMode,
      );
  RoutinesData copyWithCompanion(RoutinesCompanion data) {
    return RoutinesData(
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
      recurrence:
          data.recurrence.present ? data.recurrence.value : this.recurrence,
      changes: data.changes.present ? data.changes.value : this.changes,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      groups: data.groups.present ? data.groups.value : this.groups,
      numBreaksTaken: data.numBreaksTaken.present
          ? data.numBreaksTaken.value
          : this.numBreaksTaken,
      lastBreakAt:
          data.lastBreakAt.present ? data.lastBreakAt.value : this.lastBreakAt,
      pausedUntil:
          data.pausedUntil.present ? data.pausedUntil.value : this.pausedUntil,
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
      conditions:
          data.conditions.present ? data.conditions.value : this.conditions,
      strictMode:
          data.strictMode.present ? data.strictMode.value : this.strictMode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RoutinesData(')
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
          ..write('recurrence: $recurrence, ')
          ..write('changes: $changes, ')
          ..write('deleted: $deleted, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('groups: $groups, ')
          ..write('numBreaksTaken: $numBreaksTaken, ')
          ..write('lastBreakAt: $lastBreakAt, ')
          ..write('pausedUntil: $pausedUntil, ')
          ..write('maxBreaks: $maxBreaks, ')
          ..write('maxBreakDuration: $maxBreakDuration, ')
          ..write('friction: $friction, ')
          ..write('frictionLen: $frictionLen, ')
          ..write('snoozedUntil: $snoozedUntil, ')
          ..write('conditions: $conditions, ')
          ..write('strictMode: $strictMode')
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
        recurrence,
        changes,
        deleted,
        updatedAt,
        groups,
        numBreaksTaken,
        lastBreakAt,
        pausedUntil,
        maxBreaks,
        maxBreakDuration,
        friction,
        frictionLen,
        snoozedUntil,
        conditions,
        strictMode
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoutinesData &&
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
          other.recurrence == this.recurrence &&
          other.changes == this.changes &&
          other.deleted == this.deleted &&
          other.updatedAt == this.updatedAt &&
          other.groups == this.groups &&
          other.numBreaksTaken == this.numBreaksTaken &&
          other.lastBreakAt == this.lastBreakAt &&
          other.pausedUntil == this.pausedUntil &&
          other.maxBreaks == this.maxBreaks &&
          other.maxBreakDuration == this.maxBreakDuration &&
          other.friction == this.friction &&
          other.frictionLen == this.frictionLen &&
          other.snoozedUntil == this.snoozedUntil &&
          other.conditions == this.conditions &&
          other.strictMode == this.strictMode);
}

class RoutinesCompanion extends UpdateCompanion<RoutinesData> {
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
  final Value<int?> recurrence;
  final Value<String> changes;
  final Value<bool> deleted;
  final Value<DateTime> updatedAt;
  final Value<String> groups;
  final Value<int?> numBreaksTaken;
  final Value<DateTime?> lastBreakAt;
  final Value<DateTime?> pausedUntil;
  final Value<int?> maxBreaks;
  final Value<int> maxBreakDuration;
  final Value<String> friction;
  final Value<int?> frictionLen;
  final Value<DateTime?> snoozedUntil;
  final Value<String> conditions;
  final Value<bool> strictMode;
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
    this.recurrence = const Value.absent(),
    this.changes = const Value.absent(),
    this.deleted = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.groups = const Value.absent(),
    this.numBreaksTaken = const Value.absent(),
    this.lastBreakAt = const Value.absent(),
    this.pausedUntil = const Value.absent(),
    this.maxBreaks = const Value.absent(),
    this.maxBreakDuration = const Value.absent(),
    this.friction = const Value.absent(),
    this.frictionLen = const Value.absent(),
    this.snoozedUntil = const Value.absent(),
    this.conditions = const Value.absent(),
    this.strictMode = const Value.absent(),
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
    this.recurrence = const Value.absent(),
    required String changes,
    required bool deleted,
    required DateTime updatedAt,
    required String groups,
    this.numBreaksTaken = const Value.absent(),
    this.lastBreakAt = const Value.absent(),
    this.pausedUntil = const Value.absent(),
    this.maxBreaks = const Value.absent(),
    required int maxBreakDuration,
    required String friction,
    this.frictionLen = const Value.absent(),
    this.snoozedUntil = const Value.absent(),
    required String conditions,
    required bool strictMode,
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
        deleted = Value(deleted),
        updatedAt = Value(updatedAt),
        groups = Value(groups),
        maxBreakDuration = Value(maxBreakDuration),
        friction = Value(friction),
        conditions = Value(conditions),
        strictMode = Value(strictMode);
  static Insertable<RoutinesData> custom({
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
    Expression<int>? recurrence,
    Expression<String>? changes,
    Expression<bool>? deleted,
    Expression<DateTime>? updatedAt,
    Expression<String>? groups,
    Expression<int>? numBreaksTaken,
    Expression<DateTime>? lastBreakAt,
    Expression<DateTime>? pausedUntil,
    Expression<int>? maxBreaks,
    Expression<int>? maxBreakDuration,
    Expression<String>? friction,
    Expression<int>? frictionLen,
    Expression<DateTime>? snoozedUntil,
    Expression<String>? conditions,
    Expression<bool>? strictMode,
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
      if (recurrence != null) 'recurrence': recurrence,
      if (changes != null) 'changes': changes,
      if (deleted != null) 'deleted': deleted,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (groups != null) 'groups': groups,
      if (numBreaksTaken != null) 'num_breaks_taken': numBreaksTaken,
      if (lastBreakAt != null) 'last_break_at': lastBreakAt,
      if (pausedUntil != null) 'paused_until': pausedUntil,
      if (maxBreaks != null) 'max_breaks': maxBreaks,
      if (maxBreakDuration != null) 'max_break_duration': maxBreakDuration,
      if (friction != null) 'friction': friction,
      if (frictionLen != null) 'friction_len': frictionLen,
      if (snoozedUntil != null) 'snoozed_until': snoozedUntil,
      if (conditions != null) 'conditions': conditions,
      if (strictMode != null) 'strict_mode': strictMode,
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
      Value<int?>? recurrence,
      Value<String>? changes,
      Value<bool>? deleted,
      Value<DateTime>? updatedAt,
      Value<String>? groups,
      Value<int?>? numBreaksTaken,
      Value<DateTime?>? lastBreakAt,
      Value<DateTime?>? pausedUntil,
      Value<int?>? maxBreaks,
      Value<int>? maxBreakDuration,
      Value<String>? friction,
      Value<int?>? frictionLen,
      Value<DateTime?>? snoozedUntil,
      Value<String>? conditions,
      Value<bool>? strictMode,
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
      recurrence: recurrence ?? this.recurrence,
      changes: changes ?? this.changes,
      deleted: deleted ?? this.deleted,
      updatedAt: updatedAt ?? this.updatedAt,
      groups: groups ?? this.groups,
      numBreaksTaken: numBreaksTaken ?? this.numBreaksTaken,
      lastBreakAt: lastBreakAt ?? this.lastBreakAt,
      pausedUntil: pausedUntil ?? this.pausedUntil,
      maxBreaks: maxBreaks ?? this.maxBreaks,
      maxBreakDuration: maxBreakDuration ?? this.maxBreakDuration,
      friction: friction ?? this.friction,
      frictionLen: frictionLen ?? this.frictionLen,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      conditions: conditions ?? this.conditions,
      strictMode: strictMode ?? this.strictMode,
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
    if (recurrence.present) {
      map['recurrence'] = Variable<int>(recurrence.value);
    }
    if (changes.present) {
      map['changes'] = Variable<String>(changes.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (groups.present) {
      map['groups'] = Variable<String>(groups.value);
    }
    if (numBreaksTaken.present) {
      map['num_breaks_taken'] = Variable<int>(numBreaksTaken.value);
    }
    if (lastBreakAt.present) {
      map['last_break_at'] = Variable<DateTime>(lastBreakAt.value);
    }
    if (pausedUntil.present) {
      map['paused_until'] = Variable<DateTime>(pausedUntil.value);
    }
    if (maxBreaks.present) {
      map['max_breaks'] = Variable<int>(maxBreaks.value);
    }
    if (maxBreakDuration.present) {
      map['max_break_duration'] = Variable<int>(maxBreakDuration.value);
    }
    if (friction.present) {
      map['friction'] = Variable<String>(friction.value);
    }
    if (frictionLen.present) {
      map['friction_len'] = Variable<int>(frictionLen.value);
    }
    if (snoozedUntil.present) {
      map['snoozed_until'] = Variable<DateTime>(snoozedUntil.value);
    }
    if (conditions.present) {
      map['conditions'] = Variable<String>(conditions.value);
    }
    if (strictMode.present) {
      map['strict_mode'] = Variable<bool>(strictMode.value);
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
          ..write('recurrence: $recurrence, ')
          ..write('changes: $changes, ')
          ..write('deleted: $deleted, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('groups: $groups, ')
          ..write('numBreaksTaken: $numBreaksTaken, ')
          ..write('lastBreakAt: $lastBreakAt, ')
          ..write('pausedUntil: $pausedUntil, ')
          ..write('maxBreaks: $maxBreaks, ')
          ..write('maxBreakDuration: $maxBreakDuration, ')
          ..write('friction: $friction, ')
          ..write('frictionLen: $frictionLen, ')
          ..write('snoozedUntil: $snoozedUntil, ')
          ..write('conditions: $conditions, ')
          ..write('strictMode: $strictMode, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Devices extends Table with TableInfo<Devices, DevicesData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Devices(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<bool> curr = GeneratedColumn<bool>(
      'curr', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("curr" IN (0, 1))'));
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
      'deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("deleted" IN (0, 1))'));
  late final GeneratedColumn<String> changes = GeneratedColumn<String>(
      'changes', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DevicesData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DevicesData(
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
      changes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}changes'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      lastPulledAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_pulled_at']),
    );
  }

  @override
  Devices createAlias(String alias) {
    return Devices(attachedDatabase, alias);
  }
}

class DevicesData extends DataClass implements Insertable<DevicesData> {
  final String id;
  final String name;
  final String type;
  final bool curr;
  final bool deleted;
  final String changes;
  final DateTime updatedAt;
  final DateTime? lastPulledAt;
  const DevicesData(
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
    map['changes'] = Variable<String>(changes);
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

  factory DevicesData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DevicesData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      curr: serializer.fromJson<bool>(json['curr']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      changes: serializer.fromJson<String>(json['changes']),
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
      'changes': serializer.toJson<String>(changes),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'lastPulledAt': serializer.toJson<DateTime?>(lastPulledAt),
    };
  }

  DevicesData copyWith(
          {String? id,
          String? name,
          String? type,
          bool? curr,
          bool? deleted,
          String? changes,
          DateTime? updatedAt,
          Value<DateTime?> lastPulledAt = const Value.absent()}) =>
      DevicesData(
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
  DevicesData copyWithCompanion(DevicesCompanion data) {
    return DevicesData(
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
    return (StringBuffer('DevicesData(')
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
      (other is DevicesData &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.curr == this.curr &&
          other.deleted == this.deleted &&
          other.changes == this.changes &&
          other.updatedAt == this.updatedAt &&
          other.lastPulledAt == this.lastPulledAt);
}

class DevicesCompanion extends UpdateCompanion<DevicesData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> type;
  final Value<bool> curr;
  final Value<bool> deleted;
  final Value<String> changes;
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
    required bool deleted,
    required String changes,
    required DateTime updatedAt,
    this.lastPulledAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        type = Value(type),
        curr = Value(curr),
        deleted = Value(deleted),
        changes = Value(changes),
        updatedAt = Value(updatedAt);
  static Insertable<DevicesData> custom({
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
      Value<String>? changes,
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
      map['changes'] = Variable<String>(changes.value);
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

class Groups extends Table with TableInfo<Groups, GroupsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Groups(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  late final GeneratedColumn<String> device = GeneratedColumn<String>(
      'device', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES devices (id)'));
  late final GeneratedColumn<bool> allow = GeneratedColumn<bool>(
      'allow', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("allow" IN (0, 1))'));
  late final GeneratedColumn<String> apps = GeneratedColumn<String>(
      'apps', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> sites = GeneratedColumn<String>(
      'sites', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> categories = GeneratedColumn<String>(
      'categories', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> changes = GeneratedColumn<String>(
      'changes', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
      'deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("deleted" IN (0, 1))'));
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        device,
        allow,
        apps,
        sites,
        categories,
        changes,
        deleted,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'groups';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GroupsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupsData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name']),
      device: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device'])!,
      allow: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}allow'])!,
      apps: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}apps'])!,
      sites: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sites'])!,
      categories: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}categories'])!,
      changes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}changes'])!,
      deleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}deleted'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  Groups createAlias(String alias) {
    return Groups(attachedDatabase, alias);
  }
}

class GroupsData extends DataClass implements Insertable<GroupsData> {
  final String id;
  final String? name;
  final String device;
  final bool allow;
  final String apps;
  final String sites;
  final String categories;
  final String changes;
  final bool deleted;
  final DateTime updatedAt;
  const GroupsData(
      {required this.id,
      this.name,
      required this.device,
      required this.allow,
      required this.apps,
      required this.sites,
      required this.categories,
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
    map['apps'] = Variable<String>(apps);
    map['sites'] = Variable<String>(sites);
    map['categories'] = Variable<String>(categories);
    map['changes'] = Variable<String>(changes);
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
      categories: Value(categories),
      changes: Value(changes),
      deleted: Value(deleted),
      updatedAt: Value(updatedAt),
    );
  }

  factory GroupsData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupsData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
      device: serializer.fromJson<String>(json['device']),
      allow: serializer.fromJson<bool>(json['allow']),
      apps: serializer.fromJson<String>(json['apps']),
      sites: serializer.fromJson<String>(json['sites']),
      categories: serializer.fromJson<String>(json['categories']),
      changes: serializer.fromJson<String>(json['changes']),
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
      'apps': serializer.toJson<String>(apps),
      'sites': serializer.toJson<String>(sites),
      'categories': serializer.toJson<String>(categories),
      'changes': serializer.toJson<String>(changes),
      'deleted': serializer.toJson<bool>(deleted),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  GroupsData copyWith(
          {String? id,
          Value<String?> name = const Value.absent(),
          String? device,
          bool? allow,
          String? apps,
          String? sites,
          String? categories,
          String? changes,
          bool? deleted,
          DateTime? updatedAt}) =>
      GroupsData(
        id: id ?? this.id,
        name: name.present ? name.value : this.name,
        device: device ?? this.device,
        allow: allow ?? this.allow,
        apps: apps ?? this.apps,
        sites: sites ?? this.sites,
        categories: categories ?? this.categories,
        changes: changes ?? this.changes,
        deleted: deleted ?? this.deleted,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  GroupsData copyWithCompanion(GroupsCompanion data) {
    return GroupsData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      device: data.device.present ? data.device.value : this.device,
      allow: data.allow.present ? data.allow.value : this.allow,
      apps: data.apps.present ? data.apps.value : this.apps,
      sites: data.sites.present ? data.sites.value : this.sites,
      categories:
          data.categories.present ? data.categories.value : this.categories,
      changes: data.changes.present ? data.changes.value : this.changes,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroupsData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('device: $device, ')
          ..write('allow: $allow, ')
          ..write('apps: $apps, ')
          ..write('sites: $sites, ')
          ..write('categories: $categories, ')
          ..write('changes: $changes, ')
          ..write('deleted: $deleted, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, device, allow, apps, sites,
      categories, changes, deleted, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupsData &&
          other.id == this.id &&
          other.name == this.name &&
          other.device == this.device &&
          other.allow == this.allow &&
          other.apps == this.apps &&
          other.sites == this.sites &&
          other.categories == this.categories &&
          other.changes == this.changes &&
          other.deleted == this.deleted &&
          other.updatedAt == this.updatedAt);
}

class GroupsCompanion extends UpdateCompanion<GroupsData> {
  final Value<String> id;
  final Value<String?> name;
  final Value<String> device;
  final Value<bool> allow;
  final Value<String> apps;
  final Value<String> sites;
  final Value<String> categories;
  final Value<String> changes;
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
    this.categories = const Value.absent(),
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
    required String apps,
    required String sites,
    required String categories,
    required String changes,
    required bool deleted,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        device = Value(device),
        allow = Value(allow),
        apps = Value(apps),
        sites = Value(sites),
        categories = Value(categories),
        changes = Value(changes),
        deleted = Value(deleted),
        updatedAt = Value(updatedAt);
  static Insertable<GroupsData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? device,
    Expression<bool>? allow,
    Expression<String>? apps,
    Expression<String>? sites,
    Expression<String>? categories,
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
      if (categories != null) 'categories': categories,
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
      Value<String>? apps,
      Value<String>? sites,
      Value<String>? categories,
      Value<String>? changes,
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
      categories: categories ?? this.categories,
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
      map['apps'] = Variable<String>(apps.value);
    }
    if (sites.present) {
      map['sites'] = Variable<String>(sites.value);
    }
    if (categories.present) {
      map['categories'] = Variable<String>(categories.value);
    }
    if (changes.present) {
      map['changes'] = Variable<String>(changes.value);
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
          ..write('categories: $categories, ')
          ..write('changes: $changes, ')
          ..write('deleted: $deleted, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class DatabaseAtV2 extends GeneratedDatabase {
  DatabaseAtV2(QueryExecutor e) : super(e);
  late final Routines routines = Routines(this);
  late final Devices devices = Devices(this);
  late final Groups groups = Groups(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [routines, devices, groups];
  @override
  int get schemaVersion => 2;
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}
