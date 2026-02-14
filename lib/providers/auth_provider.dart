import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  String? _token;
  UserModel? _user;
  bool _isLoading = true;
  String? _error;

  String? get token => _token;
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _token != null && _user != null;
  String? get error => _error;

  ApiService get api => ApiService(token: _token);

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    try {
      _token = await _storage.getToken();
      if (_token != null) {
        _user = await _loadUser();
      }
    } catch (_) {
      await logout();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<UserModel?> _loadUser() async {
    try {
      final stored = await _storage.getStoredUser();
      if (stored != null) return stored;
      await ApiService(token: _token).getDashboard();
      return stored;
    } catch (_) {
      return null;
    }
  }

  Future<bool> login(String email, String password, {bool rememberMe = false}) async {
    _error = null;
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _api.login(email, password);
      _token = response.token;
      _user = response.user;
      await _storage.setToken(response.token);
      if (rememberMe) {
        await _storage.setRememberMe(true);
        await _storage.setSavedEmail(email);
        await _storage.setStoredUser(response.user);
      } else {
        await _storage.setRememberMe(false);
        await _storage.setSavedEmail(null);
        await _storage.clearStoredUser();
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await api.logout();
    } catch (_) {}
    _token = null;
    _user = null;
    await _storage.clearToken();
    await _storage.clearStoredUser();
    notifyListeners();
  }
}
