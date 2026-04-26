enum UserRole {
  supplier('SUPPLIER', 'Supplier', '🏗️'),
  logistics('LOGISTICS', 'Logistics Partner', '🚛'),
  deliveryMan('DELIVERY_MAN', 'Delivery Man', '🛵'),
  consumer('CONSUMER', 'Consumer', '👤');

  final String value;
  final String label;
  final String emoji;
  const UserRole(this.value, this.label, this.emoji);

  static UserRole fromString(String val) {
    return UserRole.values.firstWhere(
      (e) => e.value == val,
      orElse: () => UserRole.consumer,
    );
  }
}

class UserProfile {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final String? companyName;
  final String? phone;
  final String? createdAt;

  UserProfile({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.companyName,
    this.phone,
    this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] ?? json['localId'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? json['displayName'] ?? '',
      role: UserRole.fromString(json['role'] ?? 'CONSUMER'),
      companyName: json['company_name'],
      phone: json['phone'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'name': name,
    'role': role.value,
    'company_name': companyName,
    'phone': phone,
  };
}

class AuthResponse {
  final String idToken;
  final String email;
  final String localId;
  final UserProfile? profile;

  AuthResponse({
    required this.idToken,
    required this.email,
    required this.localId,
    this.profile,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    UserProfile? profile;
    if (json['profile'] != null) {
      profile = UserProfile.fromJson(json['profile']);
    }
    return AuthResponse(
      idToken: json['idToken'] ?? 'mock-token',
      email: json['email'] ?? '',
      localId: json['localId'] ?? json['uid'] ?? '',
      profile: profile,
    );
  }
}
