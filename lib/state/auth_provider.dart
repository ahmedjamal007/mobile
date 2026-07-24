import 'package:flutter/foundation.dart';

import '../core/enums/app_enums.dart';
import '../data/api_exception.dart';
import '../data/service_locator.dart';
import '../models/user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// App-wide authentication state. Drives routing (splash → login/home) and
/// exposes the current [user] + role to the whole tree.
class AuthProvider extends ChangeNotifier {
  final _services = Services.I;

  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  bool _busy = false;

  AuthStatus get status => _status;
  User? get user => _user;
  bool get busy => _busy;
  bool get isStaff => _user?.role.canReviewPayments ?? false;

  /// Called on app start (splash). If a token is stored we try to restore the
  /// profile; otherwise we go to login.
  Future<void> bootstrap() async {
    final hasToken = await _services.tokenStorage.hasToken;
    if (!hasToken) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      _user = await _services.auth.getProfile();
      _status = AuthStatus.authenticated;
    } on ApiException {
      // Stored token no longer valid — drop it.
      await _services.tokenStorage.clear();
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    _setBusy(true);
    try {
      final result = await _services.auth.login(username, password);
      await _services.tokenStorage
          .save(access: result.tokens.access, refresh: result.tokens.refresh);
      _user = result.user;
      _status = AuthStatus.authenticated;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> register(Map<String, dynamic> payload) async {
    _setBusy(true);
    try {
      final result = await _services.auth.register(payload);
      await _services.tokenStorage
          .save(access: result.tokens.access, refresh: result.tokens.refresh);
      _user = result.user;
      _status = AuthStatus.authenticated;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> logout() async {
    await _services.auth.logout();
    await _services.tokenStorage.clear();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void updateUser(User user) {
    _user = user;
    notifyListeners();
  }

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }
}
