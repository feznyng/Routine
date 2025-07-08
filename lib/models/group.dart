import 'package:uuid/uuid.dart';
import '../database/database.dart';
import '../setup.dart';
import 'device.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../services/sync_service.dart';
import 'syncable.dart';

class Group implements Syncable {
  final String _id;
  String? name;
  late List<String> apps;
  late List<String> sites;
  late List<String> categories;
  late bool allow;
  late final String _deviceId;
  final GroupEntry? _entry;

  @override
  String get id => _id;
  get deviceId => _deviceId;

  static Stream<List<Group>> watchAllNamed({String? deviceId}) {
    deviceId = deviceId ?? getIt<Device>().id;
    return getIt<AppDatabase>().getNamedGroups(deviceId).map((groups) => groups.map((e) => Group.fromEntry(e)).toList());
  }

  Group({this.name, this.apps = const [], this.sites = const [], this.categories = const [], this.allow = false})
      : _id = Uuid().v4(), _entry = null {
        _deviceId = getIt<Device>().id;
  }

  Group.fromEntry(GroupEntry entry)
      : _id = entry.id,
        name = entry.name,
        allow = entry.allow,
        apps = entry.apps,
        sites = entry.sites,
        categories = entry.categories,
        _deviceId = entry.device,
        _entry = entry;

  Group.from(Group other)
      : _id = other._id,
        name = other.name,
        allow = other.allow,
        apps = List<String>.from(other.apps),
        sites = List<String>.from(other.sites),
        categories = List<String>.from(other.categories),
        _deviceId = other._deviceId,
        _entry = other._entry;

  @override
  Future<void> save() async {
    final changes = this.changes;
    
    if (_entry == null) {
      changes.add('new');
    }

    await getIt<AppDatabase>().upsertGroup(GroupsCompanion(
      id: Value(_id), 
      name: Value(name), 
      allow: Value(allow), 
      device: Value(deviceId),
      apps: Value(apps),
      sites: Value(sites),
      categories: Value(categories),
      changes: Value(changes),
      updatedAt: Value(DateTime.now()),
    ));
    SyncService().sync();
  }

  @override
  Future<void> delete() async {
    await getIt<AppDatabase>().tempDeleteGroup(_id);
    await SyncService().sync();
  }

  @override
  bool get saved {
    return _entry != null;
  }

  bool get named {
    return name != null && name!.isNotEmpty;
  }

  @override
  List<String> get changes {
    if (_entry == null) return [];

    List<String> changes = [];

    if (_entry.name != name) changes.add('name');
    if (_entry.allow != allow) changes.add('allow');
    if (!listEquals(_entry.apps, apps)) changes.add('apps');
    if (!listEquals(_entry.sites, sites)) changes.add('sites');
    if (!listEquals(_entry.categories, categories)) changes.add('categories');

    return changes;
  }

  @override
  bool get modified {
    return _entry == null || changes.isNotEmpty;
  }
  
  @override
  void scheduleSyncJob() {
    SyncService().addJob(SyncJob(remote: false));
  }
}