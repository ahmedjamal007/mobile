/// Access + refresh JWT pair from the login/register/refresh endpoints.
class AuthTokens {
  final String access;
  final String refresh;

  const AuthTokens({required this.access, required this.refresh});

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    // Backend returns tokens either nested under `tokens` or flat.
    final tokens = json['tokens'] is Map<String, dynamic>
        ? json['tokens'] as Map<String, dynamic>
        : json;
    return AuthTokens(
      access: tokens['access']?.toString() ?? '',
      refresh: tokens['refresh']?.toString() ?? '',
    );
  }
}
