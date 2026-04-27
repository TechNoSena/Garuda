import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/models/user_model.dart';
import 'core/providers/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/supplier/supplier_home.dart';
import 'features/consumer/consumer_home.dart';
import 'features/logistics/logistics_home.dart';
import 'features/delivery/delivery_home.dart';

class GarudaApp extends ConsumerWidget {
  const GarudaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Project Garuda',
      debugShowCheckedModeBanner: false,
      theme: GarudaTheme.lightTheme,
      darkTheme: GarudaTheme.darkTheme,
      themeMode: themeMode,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Wait for init
    if (!authState.isInitialized) {
      return Scaffold(
        backgroundColor: GarudaColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🦅', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              const CircularProgressIndicator(color: GarudaColors.primary),
            ],
          ),
        ),
      );
    }

    // Not logged in
    if (!authState.isLoggedIn) {
      return const LoginScreen();
    }

    // Route by role
    return _homeForRole(authState.user!.role);
  }

  Widget _homeForRole(UserRole role) {
    switch (role) {
      case UserRole.supplier:
        return const SupplierHome();
      case UserRole.logistics:
        return const LogisticsHome();
      case UserRole.deliveryMan:
        return const DeliveryHome();
      case UserRole.consumer:
        return const ConsumerHome();
    }
  }
}
