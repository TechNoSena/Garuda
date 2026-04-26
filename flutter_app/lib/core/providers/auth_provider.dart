import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

// Auth state
class AuthState {
  final UserProfile? user;
  final bool isLoading;
  final String? error;
  final bool isInitialized;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
  });

  bool get isLoggedIn => user != null;
  UserRole? get role => user?.role;

  AuthState copyWith({
    UserProfile? user,
    bool? isLoading,
    String? error,
    bool? isInitialized,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService = AuthService();

  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    final user = await _authService.getSavedUser();
    state = AuthState(user: user, isInitialized: true);
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final authResp = await _authService.login(email, password);
      final profile = authResp.profile ?? UserProfile(
        uid: authResp.localId,
        email: authResp.email,
        name: '',
        role: UserRole.consumer,
      );
      state = state.copyWith(user: profile, isLoading: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message, isLoading: false);
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String role,
    String? companyName,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.register(
        email: email,
        password: password,
        name: name,
        role: role,
        companyName: companyName,
        phone: phone,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message, isLoading: false);
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState(isInitialized: true);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
