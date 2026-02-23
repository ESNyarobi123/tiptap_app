import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user_model.dart';

class StorageService {
  static const _tokenKey = 'auth_token';
  static const _rememberKey = 'remember_me';
  static const _emailKey = 'saved_email';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<String?> getToken() => _storage.read(key: _tokenKey);
  Future<void> setToken(String token) =>
      _storage.write(key: _tokenKey, value: token);
  Future<void> clearToken() => _storage.delete(key: _tokenKey);

  Future<bool> getRememberMe() async {
    final v = await _storage.read(key: _rememberKey);
    return v == 'true';
  }

  Future<void> setRememberMe(bool value) =>
      _storage.write(key: _rememberKey, value: value.toString());

  Future<String?> getSavedEmail() => _storage.read(key: _emailKey);
  Future<void> setSavedEmail(String? email) => email != null
      ? _storage.write(key: _emailKey, value: email)
      : _storage.delete(key: _emailKey);

  static const _userKey = 'stored_user';
  Future<UserModel?> getStoredUser() async {
    final json = await _storage.read(key: _userKey);
    if (json == null) return null;
    try {
      return UserModel.fromJson(Map<String, dynamic>.from(jsonDecode(json)));
    } catch (_) {
      return null;
    }
  }

  Future<void> setStoredUser(UserModel user) async {
    final json = jsonEncode({
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'restaurant_id': user.restaurantId,
      'restaurant_name': user.restaurantName,
      'restaurant_location': user.restaurantLocation,
      'waiter_code': user.waiterCode,
      'global_waiter_number': user.globalWaiterNumber,
      'waiter_qr_url': user.waiterQrUrl,
      'is_linked': user.isLinked,
      'roles': user.roles,
    });
    await _storage.write(key: _userKey, value: json);
  }

  Future<void> clearStoredUser() => _storage.delete(key: _userKey);
}
