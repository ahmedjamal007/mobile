import '../core/constants/api_constants.dart';
import '../core/enums/app_enums.dart';

/// Authenticated user profile. Fields mirror the backend's user +
/// profile serializers (register/profile endpoints).
class User {
  final String id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? nationalId;
  final String? gender;
  final String? profilePhotoUrl;
  final String? nationalIdPhotoUrl;
  final bool isVerified;
  final UserRole role;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.nationalId,
    this.gender,
    this.profilePhotoUrl,
    this.nationalIdPhotoUrl,
    this.isVerified = false,
    this.role = UserRole.passenger,
  });

  String get fullName {
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? username : name;
  }

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    final combined = '$f$l'.trim();
    if (combined.isNotEmpty) return combined.toUpperCase();
    return username.isNotEmpty ? username[0].toUpperCase() : '?';
  }

  /// Keys match `accounts.serializers.UserSerializer`, which nests the
  /// passenger details under `profile`. [role] lets the caller pass the
  /// top-level `role` from the login response; otherwise it's read from the
  /// serialized user itself.
  factory User.fromJson(Map<String, dynamic> json, {String? role}) {
    final profile = json['profile'] is Map<String, dynamic>
        ? json['profile'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return User(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      phoneNumber: profile['phone_number']?.toString(),
      nationalId: profile['national_id']?.toString(),
      gender: profile['gender']?.toString(),
      profilePhotoUrl: ApiConstants.mediaUrl(profile['profile_photo']?.toString()),
      nationalIdPhotoUrl:
          ApiConstants.mediaUrl(profile['national_id_photo']?.toString()),
      isVerified: profile['is_verified'] == true,
      role: UserRoleX.fromApi(role ?? json['role']?.toString()),
    );
  }

  User copyWith({
    String? phoneNumber,
    String? gender,
    String? profilePhotoUrl,
    String? nationalIdPhotoUrl,
    bool? isVerified,
  }) {
    return User(
      id: id,
      username: username,
      email: email,
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      nationalId: nationalId,
      gender: gender ?? this.gender,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      nationalIdPhotoUrl: nationalIdPhotoUrl ?? this.nationalIdPhotoUrl,
      isVerified: isVerified ?? this.isVerified,
      role: role,
    );
  }
}
