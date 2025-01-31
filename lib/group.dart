class Group {
  final String _id;
  final String? _name;
  final List<String> _apps;
  final List<String> _sites;
  final bool _allowList;
  final String? _deviceId;

  const Group({
    required String id,
    required String? deviceId,
    String? name,
    List<String>? apps,
    List<String>? sites,
    bool allowList = false,
  }) : _id = id,
       _name = name,
       _apps = apps ?? const [],
       _sites = sites ?? const [],
       _allowList = allowList,
       _deviceId = deviceId;

  // Getters
  String get id => _id;
  String? get name => _name;
  List<String> get apps => List.unmodifiable(_apps);
  List<String> get sites => List.unmodifiable(_sites);
  bool get allow => _allowList;

  // Create a new BlockList with updated values
  Group copyWith({
    String? id,
    String? deviceId,
    String? routineId,
    String? name,
    List<String>? apps,
    List<String>? sites,
    bool? allowList,
  }) {
    return Group(
      id: id ?? _id,
      deviceId: deviceId ?? _deviceId,
      name: name ?? _name,
      apps: apps ?? List.from(_apps),
      sites: sites ?? List.from(_sites),
      allowList: allowList ?? _allowList,
    );
  }
}