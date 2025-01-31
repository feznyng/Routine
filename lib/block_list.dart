class BlockList {
  String id;
  String? routineId;
  String name;
  List<String> apps = [];
  List<String> sites = [];
  bool allowList = false;

  BlockList({required this.id, required this.name});
}