import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../features/emergency/data/sensor_repository.dart';
import '../../features/connectivity/presentation/connectivity_service.dart';

// Entry point for formatting
Future<void> initializeService() async {
  if (kIsWeb) return;

  final service = FlutterBackgroundService();

  // Android Notification Channel
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'foreground_service', // id (Updated as per user request to 'foreground_service', though earlier was 'my_foreground'. User asked for 'channel ID: foreground_service')
    'Last Hope Service', // title
    description: 'This channel is used for important notifications.',
    importance: Importance.low,
  );

  // Crash Notification Channel (High Importance)
  const AndroidNotificationChannel crashChannel = AndroidNotificationChannel(
    'crash_alert',
    'Crash Alerts',
    description: 'Notifications for detected crashes',
    importance: Importance.high,
    playSound: true,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(crashChannel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'foreground_service',
      initialNotificationTitle: 'Last Hope Active',
      initialNotificationContent: 'Monitoring for Crashes...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  service.startService();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // For Android, ensure we are promoted to foreground
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.invoke("setAsForeground");

  // 1. Acquire WakeLock
  try {
    WakelockPlus.enable();
  } catch (e) {
    debugPrint("WakeLock Error: $e");
  }

  // 2. Initialize Dependencies in Background Isolate
  final SensorRepository sensorRepository = SensorRepository();
  sensorRepository.startMonitoring();

  final ConnectivityService connectivityService = ConnectivityService();
  // ConnectivityService auto-connects in constructor, but let's be sure.
  // Wait, I should verify if I need to call connect(). It is called in constructor of ConnectivityService.
  // connectivityService.connect();

  // 3. Listen to Crashes
  sensorRepository.crashStream.listen((reason) {
    // A. Forward to UI
    service.invoke("CRASH_DETECTED", {"reason": reason});
    debugPrint("Background Service Detected Crash: $reason");

    // B. Trigger High Priority Notification (Wake Logic)
    flutterLocalNotificationsPlugin.show(
      999, // Distinct ID
      'CRASH DETECTED!',
      'Initiating Emergency Protocols... ($reason)',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'crash_alert',
          'Crash Alerts',
          importance: Importance.high,
          priority: Priority.high,
          enableLights: true,
          fullScreenIntent: true, // Wakes screen
          playSound: true,
        ),
      ),
    );
  });

  service.on('stopService').listen((event) {
    sensorRepository.dispose(); // Dispose local instance
    service.stopSelf();
  });

  // Keep alive loop
  Timer.periodic(const Duration(seconds: 30), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        flutterLocalNotificationsPlugin.show(
          888,
          'Last Hope Active',
          'Monitoring for Crashes... (Alive: ${DateTime.now().second}s)',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'foreground_service',
              'Last Hope Service',
              icon: 'ic_bg_service_small',
              ongoing: true,
            ),
          ),
        );
      }
    }
    service.invoke('update', {
      "current_date": DateTime.now().toIso8601String(),
    });

    // Keep WebSocket Alive & Verify Connection
    connectivityService.sendPing();
    debugPrint("Background Service: Ping Sent");
  });
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
