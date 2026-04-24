// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sipeka/providers/dio_provider.dart';
import '../models/user_model.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  AuthState _state = AuthState.initial;
  UserModel? _user;
  String? _errorMessage;

  AuthState get state => _state;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == AuthState.loading;
  bool get isAuthenticated => _state == AuthState.authenticated;

  // ─── Check login saat app dibuka ────────────────────────────────────────
  Future<void> checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null || token.isEmpty) {
      _state = AuthState.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      // ✅ getUser sekarang return Map<String, dynamic>?
      final userData = await DioProvider().getUser(token);

      if (userData != null) {
        _user = UserModel.fromJson(userData); // ✅ populate _user
        _state = AuthState.authenticated;
      } else {
        // Token expired atau invalid
        await prefs.remove("token");
        _user = null;
        _state = AuthState.unauthenticated;
      }
    } catch (e) {
      _user = null;
      _state = AuthState.unauthenticated;
    }

    notifyListeners();
  }

  // ─── Login ───────────────────────────────────────────────────────────────
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await DioProvider().getToken(email, password);

      if (result == true) {
        // ✅ Setelah dapat token, ambil data user
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString("token");

        if (token != null) {
          final userData = await DioProvider().getUser(token);
          if (userData != null) {
            _user = UserModel.fromJson(userData); // ✅ populate _user
          }
        }

        _state = AuthState.authenticated;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Username atau password salah';
        _state = AuthState.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan koneksi';
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────────
  Future<void> logout() async {
    _state = AuthState.loading;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token != null) {
        await DioProvider().logout(token);
      }

      await prefs.remove("token");
    } catch (e) {
      // Abaikan error API, tetap logout lokal
    }

    _user = null;
    _errorMessage = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  // ─── Force logout (dari interceptor 401) ─────────────────────────────────
  void forceLogout() {
    _user = null;
    _errorMessage = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_state == AuthState.error) _state = AuthState.unauthenticated;
    notifyListeners();
  }
}