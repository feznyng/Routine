import 'database.dart';
import 'package:get_it/get_it.dart';
import 'device.dart';

final getIt = GetIt.instance;

void setup() async {
  final db = AppDatabase();
  getIt.registerSingleton<AppDatabase>(db);

  final currDevice = await Device.getCurrent();

  getIt.registerSingleton<Device>(currDevice); 

  db.initialize();
}