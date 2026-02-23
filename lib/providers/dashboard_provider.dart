import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/config.dart';
import '../models/dashboard_model.dart';
import '../services/api_service.dart';

class DashboardProvider with ChangeNotifier {
  Timer? _statsTimer;

  DashboardData? _data;
  DashboardStats? _stats;
  bool _isLoading = false;
  bool _isTogglingStatus = false;
  String? _error;

  DashboardData? get data => _data;
  DashboardStats? get stats => _stats;
  bool get isLoading => _isLoading;
  bool get isTogglingStatus => _isTogglingStatus;
  bool get isOnline => _data?.isOnline ?? true;
  bool get isLinked => _data?.isLinked ?? true;
  String? get error => _error;

  Future<void> loadFull(ApiService api) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final dashboardData = await api.getDashboard();
      _data = dashboardData;
      _stats = dashboardData.stats;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to load dashboard';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshStats(ApiService api) async {
    try {
      final newStats = await api.getDashboardStats();
      // Only update if stats have changed or were null
      if (_stats != newStats) {
        _stats = newStats;
        // Also update local data object if it exists to keep them in sync
        if (_data != null) {
          _data = DashboardData(
            stats: newStats,
            unassignedOrders: _data!.unassignedOrders,
            pendingRequests: _data!.pendingRequests,
            recentFeedback: _data!.recentFeedback,
            myOrdersToday: _data!.myOrdersToday,
            waiterInfo: _data!.waiterInfo,
            isOnline: _data!.isOnline,
            isLinked: _data!.isLinked,
          );
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  void startStatsPolling(ApiService api) {
    _statsTimer?.cancel();
    // Refresh immediately on start
    refreshStats(api);
    _statsTimer = Timer.periodic(
      const Duration(seconds: AppConfig.statsPollIntervalSeconds),
      (_) => refreshStats(api),
    );
  }

  void stopStatsPolling() {
    _statsTimer?.cancel();
    _statsTimer = null;
  }

  Future<bool> claimOrder(ApiService api, int orderId) async {
    try {
      await api.claimOrder(orderId);
      await loadFull(api);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeRequest(ApiService api, int requestId) async {
    try {
      await api.completeRequest(requestId);
      await loadFull(api);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  /// Toggle waiter online/offline status
  Future<bool> toggleOnlineStatus(ApiService api, bool goOnline) async {
    _isTogglingStatus = true;
    notifyListeners();
    try {
      await api.updateWaiterStatus(goOnline);
      // Update local data with new status
      if (_data != null) {
        _data = DashboardData(
          stats: _data!.stats,
          unassignedOrders: _data!.unassignedOrders,
          pendingRequests: _data!.pendingRequests,
          recentFeedback: _data!.recentFeedback,
          myOrdersToday: _data!.myOrdersToday,
          waiterInfo: _data!.waiterInfo,
          isOnline: goOnline,
          isLinked: _data!.isLinked,
        );
      }
      _isTogglingStatus = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isTogglingStatus = false;
      notifyListeners();
      return false;
    } catch (_) {
      _isTogglingStatus = false;
      notifyListeners();
      return false;
    }
  }
}
