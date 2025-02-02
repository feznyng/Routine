import 'package:uuid/uuid.dart';

class Group {
  final String _id;
  final String? name;
  final List<String> apps;
  final List<String> sites;
  final bool allow;
  final String? deviceId;

  Group({this.name, this.apps = const [], this.sites = const [], this.allow = false, this.deviceId})
      : _id = Uuid().v4();

  get id => _id;
}