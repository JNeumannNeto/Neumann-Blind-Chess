import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<void> register(String username, String email, String password) async {
    _isLoading = true;
_error = null;
  notifyListeners();

    try {
      _user = await _apiService.register(username, email, password);
      _isLoading = false;
      notifyListeners();
 } catch (e) {
      _error = e.toString();
 _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _apiService.login(email, password);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loadUser() async {
    try {
      _user = await _apiService.getMe();
    notifyListeners();
    } catch (e) {
      _user = null;
 notifyListeners();
    }
  }

  Future<void> logout() async {
    await _apiService.logout();
    _user = null;
    notifyListeners();
  }

  Future<bool> checkAuth() async {
    final isLoggedIn = await _apiService.isLoggedIn();
    if (isLoggedIn) {
await loadUser();
    }
    return isAuthenticated;
  }
}
