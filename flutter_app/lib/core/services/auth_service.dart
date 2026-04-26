import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  static const _tokenKey = 'garuda_token';
  static const _uidKey = 'garuda_uid';
  static const _emailKey = 'garuda_email';
  static const _roleKey = 'garuda_role';
  static const _nameKey = 'garuda_name';

  final ApiService _api = ApiService();

  Future<AuthResponse> login(String email, String password) async {
    final json = await _api.login(email: email, password: password);
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final authResp = AuthResponse.fromJson(data);
    await _persistAuth(authResp, data);
    return authResp;
  }

  Future<UserProfile> register({
    required String email,
    required String password,
    required String name,
    required String role,
    String? companyName,
    String? phone,
  }) async {
    final json = await _api.register(
      email: email,
      password: password,
      name: name,
      role: role,
      companyName: companyName,
      phone: phone,
    );
    final user = json['user'] as Map<String, dynamic>? ?? json;
    return UserProfile.fromJson(user);
  }

  Future<void> resetPassword(String email) async {
    await _api.resetPassword(email);
  }

  Future<void> _persistAuth(AuthResponse auth, Map<String, dynamic> raw) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, auth.idToken);
    await prefs.setString(_uidKey, auth.localId);
    await prefs.setString(_emailKey, auth.email);
    
    // Get role from profile or raw data
    final role = auth.profile?.role.value ?? 
                 (raw['profile'] as Map<String, dynamic>?)?['role'] ?? 
                 'CONSUMER';
    await prefs.setString(_roleKey, role);

    final name = auth.profile?.name ?? 
                 (raw['profile'] as Map<String, dynamic>?)?['name'] ?? 
                 '';
    await prefs.setString(_nameKey, name);
  }

  Future<UserProfile?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(_uidKey);
    if (uid == null || uid.isEmpty) return null;
    return UserProfile(
      uid: uid,
      email: prefs.getString(_emailKey) ?? '',
      name: prefs.getString(_nameKey) ?? '',
      role: UserRole.fromString(prefs.getString(_roleKey) ?? 'CONSUMER'),
    );
  }

  Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_uidKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_nameKey);
  }
}
