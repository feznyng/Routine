import 'package:routine_blocker/models/device.dart';
import 'package:routine_blocker/services/mobile_service.dart';
import 'package:routine_blocker/services/sync_service.dart';
import 'package:routine_blocker/setup.dart';
import 'package:routine_blocker/util.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await MobileService().stopWatching();
  logger.i("background message handler sync");
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

  Future<void> _fetchAndUpdateToken() async {
    final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
    if (apnsToken != null) {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        _updateToken(fcmToken);
      }
    }
  }

  Future<void> _updateToken(String fcmToken) async {
    try {
      logger.i("updating token $fcmToken");
      final device = await Device.getCurrent();
      await _client
        .from('devices')
      .update({'fcm_token': fcmToken})
      .eq('id', device.id);
    } catch (e) {
      Util.report('error updating token', e, null);
    }
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

    await _fetchAndUpdateToken();

    messaging.onTokenRefresh
      .listen((fcmToken) async {
        await _updateToken(fcmToken);
      })
      .onError((err) {
        Util.report('error refreshing fcm token', err, null);
      });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<bool> get granted async {
    final NotificationSettings settings = await FirebaseMessaging.instance.getNotificationSettings();
    final status = settings.authorizationStatus;
    return status == AuthorizationStatus.authorized || status == AuthorizationStatus.provisional;
  }
}