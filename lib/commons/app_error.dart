import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppError {
  AppError._();

  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static String getUserFriendlyMessage(dynamic e) {
    if (e is AuthException) {
      switch (e.message) {
        case 'Invalid login credentials':
          return 'Geçersiz giriş bilgileri. Lütfen e-posta ve şifrenizi kontrol edin.';
        case 'User already registered':
          return 'Bu e-posta adresi ile zaten bir hesap mevcut.';
        default:
          return e.message;
      }
    }
    return e.toString();
  }
}
