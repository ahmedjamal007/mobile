import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure persistence for JWTs. Uses Keychain (iOS) /
/// EncryptedSharedPreferences (Android) — never plain storage, per the
/// security requirements.
class TokenStorage {
  static const _access = 'srrs_access_token';
  static const _refresh = 'srrs_refresh_token';

  final FlutterSecureStorage _storage;

  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  Future<void> save({required String access, required String refresh}) async {
    await _storage.write(key: _access, value: access);
    await _storage.write(key: _refresh, value: refresh);
  }

  Future<String?> get accessToken => _storage.read(key: _access);
  Future<String?> get refreshToken => _storage.read(key: _refresh);

  Future<bool> get hasToken async => (await accessToken)?.isNotEmpty ?? false;

  Future<void> updateAccess(String access) =>
      _storage.write(key: _access, value: access);

  Future<void> clear() async {
    await _storage.delete(key: _access);
    await _storage.delete(key: _refresh);
  }
}
