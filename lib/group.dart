import 'package:uuid/uuid.dart';
import 'database.dart';
import 'setup.dart';
import 'device.dart';

class Group {
  final String _id;
  final String? name;
  late final List<String> apps;
  late final List<String> sites;
  late final bool allow;
  late final String _deviceId;
  final GroupEntry? _entry;

  get id => _id;
  get deviceId => _deviceId;

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
    await getIt<AppDatabase>().upsertGroup(GroupEntry(
      id: _id, 
      name: name, 
      allow: allow, 
      device: deviceId,
      apps: apps,
      sites: sites,
      changes: changes,
      status: _entry == null ? Status.created : Status.updated,
    ));
  }

  List<String> get changes {
    if (_entry == null) return [];

    List<String> changes = [];

    if (_entry.name != name) changes.add('name');
    if (_entry.allow != allow) changes.add('allow');

    return changes;
  }
}