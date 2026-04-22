import 'package:campus_online/services/push_notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  Future<void> signUp(String userName, String email, String password) async {
    final cleanName = userName.trim();
    final cleanEmail = email.trim().toLowerCase();

    final AuthResponse response = await _supabase.auth.signUp(
      email: cleanEmail,
      password: password,
      data: {'display_name': cleanName},
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Kayıt işlemi başarısız oldu.');
    }

    await _supabase.from('users').upsert({
      'id': user.id,
      'email': cleanEmail,
      'display_name': cleanName,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> signIn(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();

    final AuthResponse response = await _supabase.auth.signInWithPassword(
      email: cleanEmail,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Giriş işlemi başarısız oldu.');
    }
  }

  Future<void> signOut() async {
    try {
      if (isPushMessagingSupportedPlatform()) {
        final token = await FirebaseMessaging.instance.getToken();
        final trimmedToken = token?.trim();
        if (trimmedToken != null && trimmedToken.isNotEmpty) {
          await _supabase.rpc(
            'unregister_push_token',
            params: {'p_token': trimmedToken},
          );
        }
      }

      await _supabase.auth.signOut();
    } catch (error) {
      debugPrint('SignOut Error: $error');
      rethrow;
    }
  }
}
