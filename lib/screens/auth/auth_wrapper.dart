import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_online/screens/auth/login_screen.dart';
import 'package:campus_online/screens/main_screen.dart';
import 'package:campus_online/services/firebase/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Firebase Auth yükleniyor
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Kullanıcı giriş yapmış
        if (snapshot.hasData && snapshot.data != null) {
          return const MainScreen();
        }

        // Kullanıcı giriş yapmamış
        return const LoginScreen();
      },
    );
  }
}
