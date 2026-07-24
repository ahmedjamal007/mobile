import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../models/auth_tokens.dart';
import '../../../models/user.dart';
import '../../api_client.dart';
import '../auth_service.dart';
import 'api_parsing.dart';

/// Auth against `accounts`.
///
/// Login and register both return `{user, tokens}`; the role lives at the top
/// level on login and inside the serialized user everywhere else, so [User]
/// gets whichever is present.
class ApiAuthService implements AuthService {
  final ApiClient _client;

  ApiAuthService(this._client);

  @override
  Future<AuthResult> login(String username, String password) async {
    final res = await _client.post(
      ApiConstants.login,
      data: {'username': username, 'password': password},
      auth: false,
    );

    final body = asMap(res.data);
    return AuthResult(
      User.fromJson(asMap(body['user']), role: body['role']?.toString()),
      AuthTokens.fromJson(body),
    );
  }

  @override
  Future<AuthResult> register(Map<String, dynamic> payload) async {
    final res = await _client.post(
      ApiConstants.register,
      data: payload,
      auth: false,
    );

    final body = asMap(res.data);
    return AuthResult(
      User.fromJson(asMap(body['user']), role: body['role']?.toString()),
      AuthTokens.fromJson(body),
    );
  }

  @override
  Future<User> getProfile() async {
    final res = await _client.get(ApiConstants.profile);
    return User.fromJson(asMap(res.data));
  }

  @override
  Future<User> updateProfile(Map<String, dynamic> fields,
      {String? profilePhotoPath, String? nationalIdPhotoPath}) async {
    final data = <String, dynamic>{...fields};

    if (profilePhotoPath != null) {
      data['profile_photo'] = await MultipartFile.fromFile(profilePhotoPath);
    }
    if (nationalIdPhotoPath != null) {
      data['national_id_photo'] =
          await MultipartFile.fromFile(nationalIdPhotoPath);
    }

    // Send multipart only when there's a file; a plain JSON body keeps the
    // common "just changed my phone number" case simple.
    final hasFiles = profilePhotoPath != null || nationalIdPhotoPath != null;
    await _client.put(
      ApiConstants.profileUpdate,
      data: hasFiles ? FormData.fromMap(data) : data,
    );

    // The update endpoint echoes only the profile block, so re-read the full
    // user to get a complete object back to the caller.
    return getProfile();
  }

  @override
  Future<void> logout() async {
    // Server-side logout is a no-op acknowledgement (no token blacklist), and
    // the caller clears storage regardless — so a failure here is not fatal.
    try {
      await _client.post(ApiConstants.logout);
    } catch (_) {
      // Ignored on purpose: local tokens are dropped by AuthProvider.
    }
  }
}
