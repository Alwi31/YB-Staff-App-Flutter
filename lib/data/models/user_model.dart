import 'package:yb_staff_app/domain/entities/user.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.token,
    this.phone,
    this.avatarUrl,
    this.employmentType = 'internal_fulltime',
    this.isMitra = false,
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final String token;
  final String? phone;
  final String? avatarUrl;
  final String employmentType;
  final bool isMitra;

  /// Login response: { "token": "...", "user": {...} }
  /// or wrapped:     { "data": { "token": "...", "user": {...} } }
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final payload = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    final user = payload['user'] as Map<String, dynamic>?;
    return UserModel(
      id: user?['id'] as int? ?? 0,
      name: user?['name'] as String? ?? '',
      email: user?['email'] as String? ?? '',
      role: user?['role'] as String? ?? '',
      token: payload['token'] as String? ?? '',
      phone: user?['phone'] as String?,
      avatarUrl: _parseAvatar(user),
      employmentType:
          user?['employment_type'] as String? ?? 'internal_fulltime',
      isMitra: user?['is_mitra'] as bool? ?? false,
    );
  }

  /// Profile update / avatar upload / getProfile response.
  /// Handles: { "data": {...} }, { "user": {...} }, or flat user fields at root.
  factory UserModel.fromProfileJson(Map<String, dynamic> json) {
    final Map<String, dynamic> data;
    if (json['data'] is Map<String, dynamic>) {
      data = json['data'] as Map<String, dynamic>;
    } else if (json['user'] is Map<String, dynamic>) {
      data = json['user'] as Map<String, dynamic>;
    } else {
      data = json;
    }
    return UserModel(
      id: data['id'] as int? ?? 0,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? '',
      token: '',
      phone: data['phone'] as String?,
      avatarUrl: _parseAvatar(data),
      employmentType: data['employment_type'] as String? ?? 'internal_fulltime',
      isMitra: data['is_mitra'] as bool? ?? false,
    );
  }

  static String? _parseAvatar(Map<String, dynamic>? m) {
    if (m == null) return null;
    return m['avatar_url'] as String? ??
        m['avatar'] as String? ??
        m['photo_url'] as String? ??
        m['photo'] as String?;
  }

  User toEntity() => User(
        id: id,
        name: name,
        email: email,
        role: role,
        token: token,
        phone: phone,
        avatarUrl: avatarUrl,
        employmentType: employmentType,
        isMitra: isMitra,
      );
}
