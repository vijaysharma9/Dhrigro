class UserModel {
  const UserModel({
    required this.id,
    this.email,
    this.phone,
    this.name,
    required this.role,
    this.isVerified = false,
    this.avatarUrl,
  });

  final String id;
  final String? email;
  final String? phone;
  final String? name;
  final String role;
  final bool isVerified;
  final String? avatarUrl;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? json;
    return UserModel(
      id: user['id'] as String,
      email: user['email'] as String?,
      phone: user['phone'] as String?,
      name: user['name'] as String?,
      role: user['role'] as String? ?? 'CUSTOMER',
      isVerified: user['isVerified'] as bool? ?? false,
      avatarUrl: user['avatarUrl'] as String?,
    );
  }

  bool get isAdmin => isStaff;

  bool get isStaff => const {
        'SUPER_ADMIN',
        'OPERATIONS_ADMIN',
        'INVENTORY_MANAGER',
        'CUSTOMER_SUPPORT',
      }.contains(role);

  bool get isDeliveryPartner => role == 'DELIVERY_PARTNER';
}

class AuthResponse {
  const AuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  final UserModel user;
  final String accessToken;
  final String refreshToken;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: UserModel.fromJson(json),
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }
}
