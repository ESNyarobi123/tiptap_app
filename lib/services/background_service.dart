import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:http/http.dart' as http;
import 'package:vibration/vibration.dart';

import '../core/config.dart';
import '../services/storage_service.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  BACKGROUND SERVICE — Runs even when app is closed (like WhatsApp)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Notification plugin instance
final FlutterLocalNotificationsPlugin _notificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// IDs of calls already handled in background
final Set<int> _bgSeenCallIds = {};

/// Whether we are currently ringing
bool _bgIsRinging = false;
Timer? _bgVibrationTimer;

// ─── Notification Channel (high-priority for call-like behavior) ───
const String _channelId = 'tiptap_incoming_call';
const String _channelName = 'Incoming Calls';
const String _channelDesc = 'Notifications for incoming customer calls';
const int _callNotificationId = 888;

// ─── Foreground Service Notification Channel ───
const String _fgChannelId = 'tiptap_foreground';
const String _fgChannelName = 'Background Service';
const int _fgNotificationId = 777;

/// Initialize and start the background service
Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  // Create the notification channel for the foreground service
  // This must be done BEFORE the service starts due to Android 14 requirements
  await _createNotificationChannel();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      autoStartOnBoot: true,

      // Foreground notification config
      notificationChannelId: _fgChannelId,
      initialNotificationTitle: 'TIPTAP Waiter',
      initialNotificationContent: 'Listening for customer calls...',
      foregroundServiceNotificationId: _fgNotificationId,
      foregroundServiceTypes: [AndroidForegroundType.dataSync],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  await service.startService();
}

Future<void> _createNotificationChannel() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();

  await _notificationsPlugin.initialize(
    const InitializationSettings(android: androidSettings, iOS: iosSettings),
  );

  final androidPlugin = _notificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  if (androidPlugin != null) {
    // 1. Channel for the persistent foreground service notification
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _fgChannelId,
        _fgChannelName,
        importance: Importance.low, // Silent
        showBadge: false,
      ),
    );

    // 2. Channel for high-priority incoming calls
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.max,
        playSound: false,
        enableVibration: false,
        showBadge: true,
      ),
    );
  }
}

/// iOS background handler
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

/// Main background service entry point
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Ensure plugins are available in the background isolate
  DartPluginRegistrant.ensureInitialized();

  // For flutter_background_service_android, we need to bring the service to foreground explicitly if needed,
  // but `isForegroundMode: true` in configure usually handles it.

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Listen for "syncSeenIds" updates from the foreground CallService
  service.on('syncSeenIds').listen((event) {
    if (event != null && event['ids'] != null) {
      final ids = (event['ids'] as List).cast<int>();
      _bgSeenCallIds.addAll(ids);
    }
  });

  // Listen for "stopRinging" from foreground (user accepted/declined in-app)
  service.on('stopRinging').listen((event) {
    _stopBgRinging();
  });

  // Start polling loop
  Timer.periodic(const Duration(seconds: 5), (_) async {
    await _bgCheckForCalls(service);
  });
}

/// Check API for new calls (runs in background isolate)
Future<void> _bgCheckForCalls(ServiceInstance service) async {
  try {
    // Read token from secure storage
    final storage = StorageService();
    final token = await storage.getToken();
    if (token == null) return;

    // Make API call directly (can't use ApiService in isolate easily)
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/waiter/requests'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode != 200) return;

    final body = jsonDecode(response.body);
    final data = body['data'] as List<dynamic>? ?? [];

    for (final item in data) {
      final id = item['id'] as int;

      // Skip if already seen
      if (_bgSeenCallIds.contains(id)) continue;

      // New call!
      _bgSeenCallIds.add(id);

      final type = item['type'] as String? ?? 'call_waiter';
      final tableNumber = item['table_number']?.toString();
      final displayType = type == 'request_bill'
          ? 'Bill Request'
          : 'Customer Calling';
      final tableDisplay = tableNumber ?? 'General Area / Mapokezi';

      // Notify the foreground UI (if app is open)
      service.invoke('newCall', {
        'id': id,
        'type': type,
        'table_number': tableNumber,
        'created_at': item['created_at'] as String? ?? '',
      });

      // Show a high-priority notification + ring + vibrate
      if (!_bgIsRinging) {
        _startBgRinging();
        _showCallNotification(displayType, tableDisplay, id);
      }
    }
  } catch (e) {
    // Silently fail in background — don't crash the service
  }
}

/// Show a call-like notification
void _showCallNotification(String title, String body, int callId) {
  _notificationsPlugin.show(
    _callNotificationId,
    '📞 $title',
    'Table: $body — Tap to open',
    NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.call,
        fullScreenIntent: true, // Show over lock screen!
        ongoing: true, // Can't be swiped away
        autoCancel: false,
        playSound: false,
        enableVibration: false,
        icon: '@mipmap/ic_launcher',
        colorized: true,
        color: const Color(0xFF06B6D4),
        ticker: 'Incoming Call - $title',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    ),
  );
}

/// Start ringing + vibrating in background
void _startBgRinging() {
  _bgIsRinging = true;

  // Play system ringtone
  FlutterRingtonePlayer().play(
    android: AndroidSounds.ringtone,
    ios: IosSounds.electronic,
    looping: true,
    volume: 1.0,
    asAlarm: true,
  );

  // Vibration pattern
  _bgVibrationTimer?.cancel();
  _bgVibrationTimer = Timer.periodic(const Duration(milliseconds: 1500), (
    _,
  ) async {
    if (_bgIsRinging) {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        Vibration.vibrate(
          pattern: [0, 500, 200, 500],
          intensities: [0, 255, 0, 200],
        );
      }
    }
  });
  Vibration.vibrate(pattern: [0, 500, 200, 500], intensities: [0, 255, 0, 200]);
}

/// Stop ringing + vibrating in background
void _stopBgRinging() {
  _bgIsRinging = false;
  _bgVibrationTimer?.cancel();
  _bgVibrationTimer = null;
  FlutterRingtonePlayer().stop();
  Vibration.cancel();

  // Remove the call notification
  _notificationsPlugin.cancel(_callNotificationId);
}
