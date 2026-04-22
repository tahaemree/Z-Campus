import 'package:campus_online/commons/app_error.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('AppError.getUserFriendlyMessage', () {
    test('maps AuthException invalid credentials message', () {
      const error = AuthException('Invalid login credentials');

      final message = AppError.getUserFriendlyMessage(error);

      expect(
        message,
        'Geçersiz giriş bilgileri. Lütfen e-posta ve şifrenizi kontrol edin.',
      );
    });

    test('maps pkce async storage message to localized text', () {
      const raw = 'You need to provide asyncStorage to perform pkce flow';

      final message = AppError.getUserFriendlyMessage(raw);

      expect(
        message,
        'Kimlik doğrulama akışı başlatılamadı. Lütfen uygulamayı güncelleyip tekrar deneyin.',
      );
    });

    test('removes Exception prefix from generic exceptions', () {
      final message =
          AppError.getUserFriendlyMessage(Exception('Beklenmeyen hata'));

      expect(message, 'Beklenmeyen hata');
    });
  });
}
