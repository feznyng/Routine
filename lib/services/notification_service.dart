import 'package:Routine/models/device.dart';
import 'package:Routine/services/mobile_service.dart';
import 'package:Routine/services/sync_service.dart';
import 'package:Routine/util.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:Routine/setup.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await MobileService().stopWatching();
  await SyncService().sync();
  await MobileService().updateRoutines(immediate: true);
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final SupabaseClient _client = Supabase.instance.client;
  
  NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  Future<void> fetchAndUpdateToken() async {
    final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
    if (apnsToken != null) {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        updateToken(fcmToken);
      }
    }
  }

  Future<void> updateToken(String fcmToken) async {
    final device = await Device.getCurrent();
    await _client
      .from('devices')
      .update({'fcm_token': fcmToken})
      .eq('id', device.id);
  }

  Future<void> init() async {
    if (Util.isDesktop()) {
      return;
    }

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseMessaging messaging = FirebaseMessaging.instance;

    final _ = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    await fetchAndUpdateToken();

    messaging.onTokenRefresh
      .listen((fcmToken) async {
        await updateToken(fcmToken);
      })
      .onError((err) {
        logger.e("failed to retrieve fcm token $err");
      });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<bool> get granted async {
    final NotificationSettings settings = await FirebaseMessaging.instance.getNotificationSettings();
    final status = settings.authorizationStatus;
    return status == AuthorizationStatus.authorized || status == AuthorizationStatus.provisional;
  }
}