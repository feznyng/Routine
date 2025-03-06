import 'database/database.dart';
import 'package:get_it/get_it.dart';
import 'models/device.dart';
import 'services/sync_service.dart';

final getIt = GetIt.instance;

void setup() async {
  final db = AppDatabase();
  getIt.registerSingleton<AppDatabase>(db);

  final currDevice = await Device.getCurrent();

  getIt.registerSingleton<Device>(currDevice); 

  await db.initialize();

  SyncService().addJob(SyncJob(remote: false));
}