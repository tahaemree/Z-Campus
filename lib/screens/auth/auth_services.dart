import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Authentication service — no UI logic, only business logic.
class AuthServices {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Sign up a new user and create their profile row.
  Future<void> signUp(String userName, String email, String password) async {
    final AuthResponse res = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': userName},
    );

    final user = res.user;
    if (user != null) {
      await _supabase.from('users').upsert({
        'id': user.id,
        'email': email,
        'display_name': userName,
        'created_at': DateTime.now().toIso8601String(),
      });
    } else {
      throw Exception('Kayıt işlemi başarısız oldu.');
    }
  }

  /// Sign in with email/password.
  Future<void> signIn(String email, String password) async {
    final AuthResponse res = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (res.user == null) {
      throw Exception('Giriş işlemi başarısız oldu.');
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('SignOut Error: $e');
      rethrow;
    }
  }
}
