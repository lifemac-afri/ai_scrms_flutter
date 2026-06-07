import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _loading = false;
  String? _error;

  User? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  Future<bool> checkAuth() async {
    final u = await ApiService.me();
    _user = u;
    notifyListeners();
    return u != null;
  }

  Future<String?> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    final res = await ApiService.login(email, password);
    _loading = false;

    if (res['success'] == true) {
      await checkAuth();
      return null;
    }
    _error = res['error'] ?? 'Login failed';
    notifyListeners();
    return _error;
  }

  Future<String?> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String department = '',
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    final res = await ApiService.register(
      fullName: fullName,
      email: email,
      password: password,
      role: role,
      department: department,
    );
    _loading = false;
    notifyListeners();

    if (res['success'] == true) return null;
    return res['error'] ?? 'Registration failed';
  }

  Future<void> logout() async {
    await ApiService.logout();
    _user = null;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    final u = await ApiService.me();
    if (u != null) {
      _user = u;
      notifyListeners();
    }
  }
}
