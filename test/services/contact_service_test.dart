import 'package:campus_online/services/contact_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContactFeedbackPayloadBuilder', () {
    const builder = ContactFeedbackPayloadBuilder();

    test('allows authenticated submission without contact email', () {
      final payload = builder.build(
        draft: const ContactFeedbackDraft(
          category: ContactFeedbackCategory.general,
          subject: 'Uygulama deneyimi',
          message: 'Arayuz genel olarak akici calisiyor.',
          devicePlatform: 'android',
        ),
        currentUserId: 'user-123',
      );

      expect(payload['user_id'], 'user-123');
      expect(payload['contact_email'], isNull);
      expect(payload['category'], 'general');
    });

    test('requires email for guest submission', () {
      expect(
        () => builder.build(
          draft: const ContactFeedbackDraft(
            category: ContactFeedbackCategory.suggestion,
            subject: 'Yeni filtre onerisi',
            message: 'Etkinliklerde bina bazli filtre faydali olur.',
            devicePlatform: 'ios',
          ),
          currentUserId: null,
        ),
        throwsA(isA<ContactValidationException>()),
      );
    });

    test('rejects invalid email format', () {
      expect(
        () => builder.build(
          draft: const ContactFeedbackDraft(
            category: ContactFeedbackCategory.bugReport,
            subject: 'Harita kaymasi',
            message: 'Bazi cihazlarda harita kayiyor gibi gorunuyor.',
            contactEmail: 'gecersiz-mail',
            devicePlatform: 'android',
          ),
          currentUserId: null,
        ),
        throwsA(isA<ContactValidationException>()),
      );
    });

    test('normalizes whitespace and email casing', () {
      final payload = builder.build(
        draft: const ContactFeedbackDraft(
          category: ContactFeedbackCategory.recommendation,
          subject: '  Etkinlik  bildirimleri  ',
          message:
              '  Bildirimlerin ders saatlerine gore ozellestirilmesi iyi olur.  ',
          contactEmail: '  Ogrenci@Universite.edu.tr  ',
          devicePlatform: 'android',
        ),
        currentUserId: null,
      );

      expect(payload['subject'], 'Etkinlik bildirimleri');
      expect(
        payload['message'],
        'Bildirimlerin ders saatlerine gore ozellestirilmesi iyi olur.',
      );
      expect(payload['contact_email'], 'ogrenci@universite.edu.tr');
    });

    test('caps very long device platform values', () {
      final payload = builder.build(
        draft: const ContactFeedbackDraft(
          category: ContactFeedbackCategory.general,
          subject: 'Performans notu',
          message: 'Uygulama acilisi son surumde daha hizli.',
          devicePlatform: 'android-super-long-platform-name-that-exceeds-limit',
          contactEmail: 'kullanici@ornek.com',
        ),
        currentUserId: null,
      );

      expect(
          (payload['device_platform'] as String).length, lessThanOrEqualTo(32));
    });
  });
}
