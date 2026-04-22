import 'package:campus_online/commons/postgrest_helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum ContactFeedbackCategory {
  general('general', 'Genel geri bildirim'),
  suggestion('suggestion', 'Öneri'),
  recommendation('recommendation', 'Tavsiye'),
  bugReport('bug_report', 'Hata bildirimi');

  const ContactFeedbackCategory(this.value, this.label);

  final String value;
  final String label;
}

String currentDevicePlatformLabel() {
  if (kIsWeb) return 'web';

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return 'android';
    case TargetPlatform.iOS:
      return 'ios';
    case TargetPlatform.macOS:
      return 'macos';
    case TargetPlatform.windows:
      return 'windows';
    case TargetPlatform.linux:
      return 'linux';
    case TargetPlatform.fuchsia:
      return 'fuchsia';
  }
}

class ContactFeedbackDraft {
  const ContactFeedbackDraft({
    required this.category,
    required this.subject,
    required this.message,
    required this.devicePlatform,
    this.contactEmail,
  });

  final ContactFeedbackCategory category;
  final String subject;
  final String message;
  final String devicePlatform;
  final String? contactEmail;
}

class ContactValidationException implements Exception {
  const ContactValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ContactFeedbackPayloadBuilder {
  const ContactFeedbackPayloadBuilder();

  static final RegExp _emailRegex = RegExp(
    r'^[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}$',
    caseSensitive: false,
  );

  static bool isValidEmail(String value) => _emailRegex.hasMatch(value.trim());

  Map<String, dynamic> build({
    required ContactFeedbackDraft draft,
    required String? currentUserId,
  }) {
    final normalizedSubject = _normalizeWhitespace(draft.subject);
    final normalizedMessage = draft.message.trim();
    final normalizedEmail = _normalizeEmail(draft.contactEmail);
    final normalizedUserId = _normalizeUserId(currentUserId);

    if (normalizedSubject.length < 4 || normalizedSubject.length > 140) {
      throw const ContactValidationException(
        'Konu 4 ile 140 karakter arasında olmalıdır.',
      );
    }

    if (normalizedMessage.length < 10 || normalizedMessage.length > 2000) {
      throw const ContactValidationException(
        'Mesaj 10 ile 2000 karakter arasında olmalıdır.',
      );
    }

    if (normalizedEmail != null && !isValidEmail(normalizedEmail)) {
      throw const ContactValidationException(
        'Lütfen geçerli bir e-posta adresi girin.',
      );
    }

    if (normalizedUserId == null && normalizedEmail == null) {
      throw const ContactValidationException(
        'Giriş yapmadıysanız e-posta alanı zorunludur.',
      );
    }

    final devicePlatform = _normalizeDevicePlatform(draft.devicePlatform);

    return <String, dynamic>{
      'user_id': normalizedUserId,
      'category': draft.category.value,
      'subject': normalizedSubject,
      'message': normalizedMessage,
      'contact_email': normalizedEmail,
      'device_platform': devicePlatform,
    };
  }

  String _normalizeDevicePlatform(String value) {
    final normalized = _normalizeWhitespace(value).toLowerCase();
    if (normalized.isEmpty) return 'unknown';
    if (normalized.length <= 32) return normalized;
    return normalized.substring(0, 32);
  }

  String? _normalizeUserId(String? value) {
    final userId = value?.trim();
    if (userId == null || userId.isEmpty) {
      return null;
    }
    return userId;
  }

  String? _normalizeEmail(String? value) {
    final email = value?.trim().toLowerCase();
    if (email == null || email.isEmpty) {
      return null;
    }
    return email;
  }

  String _normalizeWhitespace(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}

class ContactService {
  ContactService({
    SupabaseClient? supabase,
    ContactFeedbackPayloadBuilder? payloadBuilder,
  })  : _supabase = supabase ?? Supabase.instance.client,
        _payloadBuilder =
            payloadBuilder ?? const ContactFeedbackPayloadBuilder();

  final SupabaseClient _supabase;
  final ContactFeedbackPayloadBuilder _payloadBuilder;

  Future<void> submitFeedback(ContactFeedbackDraft draft) async {
    final payload = _payloadBuilder.build(
      draft: draft,
      currentUserId: _supabase.auth.currentUser?.id,
    );

    try {
      await _supabase.from(dbUserFeedbackTable).insert(payload);
    } on PostgrestException catch (error) {
      if (isMissingRelation(error, dbUserFeedbackTable)) {
        throw Exception(
          'Geri bildirim modülü henüz etkinleştirilmemiş. '
          'Lütfen 012_contact_feedback_module.sql migration dosyasını çalıştırın.',
        );
      }

      if (error.code == '42501') {
        throw Exception('Geri bildirim göndermek için izniniz bulunmuyor.');
      }

      if (error.code == '23514') {
        throw Exception('Girdiğiniz bilgiler doğrulama kurallarına uymuyor.');
      }

      rethrow;
    }
  }
}
