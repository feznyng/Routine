import '../services/sync_service.dart';

/// An abstract class that defines the interface for entities that can be synced
/// across devices in the Routine app.
/// 
/// Classes that implement this interface should provide functionality for:
/// - Saving changes to the local database
/// - Deleting entities from the local database
/// - Tracking changes made to the entity
/// - Determining if the entity has been modified
abstract class Syncable {
  /// The unique identifier for this entity
  String get id;
  
  /// Saves the entity to the local database and schedules a sync job
  Future<void> save();
  
  /// Deletes the entity from the local database and schedules a sync job
  Future<void> delete();
  
  /// Returns a list of field names that have been changed since the last save
  List<String> get changes;
  
  /// Returns true if the entity has been modified since it was last saved
  bool get modified;
  
  /// Returns true if the entity has been saved to the database
  bool get saved;
  
  /// Helper method to schedule a sync job after save or delete operations
  void scheduleSyncJob() {
    SyncService().addJob(SyncJob(remote: false));
  }
}
