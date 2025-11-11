







abstract class Syncable {

  String get id;
  

  Future<void> save();
  

  Future<void> delete();
  

  List<String> get changes;
  

  bool get modified;
  

  bool get saved;
}
