import '../../core/enums/app_enums.dart';
import '../../models/auth_tokens.dart';
import '../../models/user.dart';
import '../api_exception.dart';
import '../mock/mock_backend.dart';

class AuthResult {
  final User user;
  final AuthTokens tokens;
  const AuthResult(this.user, this.tokens);
}

/// Contract the UI depends on. A real implementation calls the auth endpoints;
/// the mock below fakes them. Swapping is a one-line change in the app's
/// service locator.
abstract class AuthService {
  Future<AuthResult> login(String username, String password);
  Future<AuthResult> register(Map<String, dynamic> payload);
  Future<User> getProfile();
  Future<User> updateProfile(Map<String, dynamic> fields,
      {String? profilePhotoPath, String? nationalIdPhotoPath});
  Future<void> logout();
}

class MockAuthService implements AuthService {
  final _backend = MockBackend.instance;

  Future<void> _delay() => Future.delayed(const Duration(milliseconds: 600));

  @override
  Future<AuthResult> login(String username, String password) async {
    await _delay();
    if (username.trim().isEmpty || password.isEmpty) {
      throw const ApiException('Enter your username and password.',
          statusCode: 400);
    }
    // Any username containing "staff" or "admin" logs in with that role so
    // the reviewer flow is reachable in the demo.
    final lower = username.toLowerCase();
    final role = lower.contains('admin')
        ? UserRole.admin
        : lower.contains('staff')
            ? UserRole.staff
            : UserRole.passenger;

    final user = User(
      id: 'u-$lower',
      username: username,
      email: '$lower@sudanrailways.sd',
      firstName: username.isNotEmpty
          ? '${username[0].toUpperCase()}${username.substring(1)}'
          : 'User',
      lastName: role == UserRole.passenger ? 'Passenger' : 'Reviewer',
      phoneNumber: '+249 900 000 000',
      nationalId: '1234567890',
      gender: 'M',
      isVerified: role != UserRole.passenger,
      role: role,
    );
    _backend.currentUser = user;
    if (role.canReviewPayments) _backend.seedStaffQueueIfEmpty();
    return AuthResult(
      user,
      const AuthTokens(access: 'mock-access', refresh: 'mock-refresh'),
    );
  }

  @override
  Future<AuthResult> register(Map<String, dynamic> payload) async {
    await _delay();
    final username = payload['username']?.toString() ?? '';
    if (username.isEmpty) {
      throw const ApiException('Username is required.',
          statusCode: 400, fieldErrors: {'username': 'This field is required.'});
    }
    final user = User(
      id: 'u-$username',
      username: username,
      email: payload['email']?.toString() ?? '',
      firstName: payload['first_name']?.toString() ?? '',
      lastName: payload['last_name']?.toString() ?? '',
      phoneNumber: payload['phone_number']?.toString(),
      nationalId: payload['national_id']?.toString(),
      gender: payload['gender']?.toString(),
      role: UserRole.passenger,
    );
    _backend.currentUser = user;
    return AuthResult(
      user,
      const AuthTokens(access: 'mock-access', refresh: 'mock-refresh'),
    );
  }

  @override
  Future<User> getProfile() async {
    await _delay();
    final user = _backend.currentUser;
    if (user == null) {
      throw const ApiException('Not authenticated.', statusCode: 401);
    }
    return user;
  }

  @override
  Future<User> updateProfile(Map<String, dynamic> fields,
      {String? profilePhotoPath, String? nationalIdPhotoPath}) async {
    await _delay();
    final user = _backend.currentUser;
    if (user == null) {
      throw const ApiException('Not authenticated.', statusCode: 401);
    }
    final updated = user.copyWith(
      phoneNumber: fields['phone_number']?.toString(),
      gender: fields['gender']?.toString(),
      profilePhotoUrl: profilePhotoPath,
      nationalIdPhotoUrl: nationalIdPhotoPath,
    );
    _backend.currentUser = updated;
    return updated;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _backend.currentUser = null;
  }
}
