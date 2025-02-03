import 'package:uuid/uuid.dart';
import 'database.dart';
import 'setup.dart';
import 'device.dart';
import 'package:drift/drift.dart';

class Group {
  final String _id;
  final String? name;
  late List<String> apps;
  late List<String> sites;
  late bool allow;
  late final String _deviceId;
  final GroupEntry? _entry;

  get id => _id;
  get deviceId => _deviceId;

  static Stream<List<Group>> watchAllNamed({String? deviceId}) {
    deviceId = deviceId ?? getIt<Device>().id;
    return getIt<AppDatabase>().getNamedGroups(deviceId).map((groups) => groups.map((e) => Group.fromEntry(e)).toList());
  }

  Group({this.name, this.apps = const [], this.sites = const [], this.allow = false})
      : _id = Uuid().v4(), _entry = null {
        _deviceId = getIt<Device>().id;
  }

  Group.fromEntry(GroupEntry entry)
      : _id = entry.id,
        name = entry.name,
        allow = entry.allow,
        apps = entry.apps,
        sites = entry.sites,
        _deviceId = entry.device,
        _entry = entry;

  save() async {
    await getIt<AppDatabase>().upsertGroup(GroupsCompanion(
      id: Value(_id), 
      name: Value(name), 
      allow: Value(allow), 
      device: Value(deviceId),
      apps: Value(apps),
      sites: Value(sites),
      changes: Value(changes),
      updatedAt: Value(DateTime.now()),
    ));
  }

  delete() async {
    await getIt<AppDatabase>().tempDeleteGroup(_id);
  }

  bool get saved {
    return _entry != null;
  }

  bool get named {
    return name != null && name!.isNotEmpty;
  }

  List<String> get changes {
    if (_entry == null) return [];

    List<String> changes = [];

    if (_entry.name != name) changes.add('name');
    if (_entry.allow != allow) changes.add('allow');

    return changes;
  }

  bool get modified {
    return _entry == null || changes.isNotEmpty;
  }
}