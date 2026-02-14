import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:vibration/vibration.dart';

import '../models/dashboard_model.dart';
import '../services/api_service.dart';

/// Manages incoming call detection, ringtone, vibration, and call queue.
/// Works with the background service for when the app is closed.
class CallService extends ChangeNotifier {
  Timer? _pollTimer;
  ApiService? _api;

  // Track which call IDs we've already shown to the user
  final Set<int> _seenCallIds = {};
  // Track which call IDs the user has dismissed/completed
  final Set<int> _dismissedCallIds = {};

  // Current queue of active incoming calls
  final Queue<PendingRequest> _callQueue = Queue<PendingRequest>();

  // Currently ringing call
  PendingRequest? _currentCall;
  bool _isRinging = false;
  bool _isActive = false;

  PendingRequest? get currentCall => _currentCall;
  bool get isRinging => _isRinging;
  bool get hasCallsInQueue => _callQueue.isNotEmpty;
  int get queueCount => _callQueue.length;
  List<PendingRequest> get queuedCalls => _callQueue.toList();

  // Callback to show the incoming call screen
  void Function(PendingRequest call)? onIncomingCall;

  /// Initialize the service with an API instance and start polling
  void start(ApiService api) {
    _api = api;
    _isActive = true;
    _pollTimer?.cancel();

    // Listen for new calls from the background service
    _listenToBackgroundService();

    // Poll every 5 seconds (foreground polling)
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkForNewCalls(),
    );
    // Also check immediately
    _checkForNewCalls();
  }

  /// Listen for messages from the background service isolate
  void _listenToBackgroundService() {
    final service = FlutterBackgroundService();
    service.on('newCall').listen((event) {
      if (event == null) return;

      final id = event['id'] as int;
      final type = event['type'] as String? ?? 'call_waiter';
      final tableNumber = event['table_number']?.toString();
      final createdAt = event['created_at'] as String? ?? '';

      // Skip if already seen in foreground
      if (_seenCallIds.contains(id) || _dismissedCallIds.contains(id)) {
        return;
      }

      // New call from background service!
      _seenCallIds.add(id);
      final request = PendingRequest(
        id: id,
        type: type,
        tableNumber: tableNumber,
        createdAt: createdAt,
      );

      _callQueue.add(request);

      if (!_isRinging) {
        // Tell background service to stop its ringing (we handle it in foreground)
        service.invoke('stopRinging');
        _showNextCall();
      }
    });
  }

  /// Sync our seen IDs to the background service so it doesn't re-notify
  void _syncSeenIdsToBackground() {
    final service = FlutterBackgroundService();
    service.invoke('syncSeenIds', {'ids': _seenCallIds.toList()});
  }

  /// Stop polling
  void stop() {
    _isActive = false;
    _pollTimer?.cancel();
    _pollTimer = null;
    stopRinging();
  }

  /// Check API for new incoming calls (foreground)
  Future<void> _checkForNewCalls() async {
    if (_api == null || !_isActive) return;

    try {
      final requests = await _api!.getPendingRequests();

      for (final req in requests) {
        // Skip if we've already seen or dismissed this call
        if (_seenCallIds.contains(req.id) ||
            _dismissedCallIds.contains(req.id)) {
          continue;
        }

        // New call detected!
        _seenCallIds.add(req.id);
        _callQueue.add(req);
      }

      // Sync IDs to background service so it knows what we've handled
      _syncSeenIdsToBackground();

      // If we have new calls in queue and not currently ringing, ring!
      if (_callQueue.isNotEmpty && !_isRinging) {
        // Stop background ringing if any
        FlutterBackgroundService().invoke('stopRinging');
        _showNextCall();
      }
    } catch (e) {
      debugPrint('CallService poll error: $e');
    }
  }

  /// Show the next call in the queue
  void _showNextCall() {
    if (_callQueue.isEmpty) {
      _currentCall = null;
      _isRinging = false;
      notifyListeners();
      return;
    }

    _currentCall = _callQueue.removeFirst();
    _isRinging = true;
    notifyListeners();

    // Start ringtone + vibration
    _startRinging();

    // Notify the UI to show the incoming call screen
    onIncomingCall?.call(_currentCall!);
  }

  /// Start ringtone and vibration
  void _startRinging() {
    // Play ringtone
    FlutterRingtonePlayer().play(
      android: AndroidSounds.ringtone,
      ios: IosSounds.electronic,
      looping: true,
      volume: 1.0,
      asAlarm: true, // Higher priority, plays over Do Not Disturb
    );

    // Vibrate pattern
    _startVibrationPattern();
  }

  Timer? _vibrationTimer;

  void _startVibrationPattern() {
    _vibrationTimer?.cancel();
    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 1500), (
      _,
    ) async {
      if (_isRinging) {
        final hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator) {
          Vibration.vibrate(
            pattern: [0, 500, 200, 500],
            intensities: [0, 255, 0, 200],
          );
        }
      }
    });
    // Initial vibrate
    Vibration.vibrate(
      pattern: [0, 500, 200, 500],
      intensities: [0, 255, 0, 200],
    );
  }

  /// Stop ringtone and vibration
  void stopRinging() {
    _isRinging = false;
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
    FlutterRingtonePlayer().stop();
    Vibration.cancel();
    notifyListeners();
  }

  /// User accepted the call
  void acceptCall() {
    stopRinging();
    // Tell background service to also stop
    FlutterBackgroundService().invoke('stopRinging');
    _currentCall = null;
    notifyListeners();

    // Check if more calls in queue after a short delay
    Future.delayed(const Duration(seconds: 1), () {
      if (_callQueue.isNotEmpty) {
        _showNextCall();
      }
    });
  }

  /// User declined the call
  void declineCall() {
    stopRinging();
    // Tell background service to also stop
    FlutterBackgroundService().invoke('stopRinging');
    if (_currentCall != null) {
      _dismissedCallIds.add(_currentCall!.id);
    }
    _currentCall = null;
    notifyListeners();

    // Sync dismissed IDs to background
    _syncSeenIdsToBackground();

    // Show next call if queue is not empty
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_callQueue.isNotEmpty) {
        _showNextCall();
      }
    });
  }

  /// Clear seen/dismissed memory (e.g. on logout)
  void reset() {
    stop();
    _seenCallIds.clear();
    _dismissedCallIds.clear();
    _callQueue.clear();
    _currentCall = null;
    _isRinging = false;
    notifyListeners();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
