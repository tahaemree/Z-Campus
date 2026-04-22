import 'package:campus_online/commons/postgrest_helpers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('isMissingRelation', () {
    test('returns true for schema cache misses', () {
      const error = PostgrestException(
        message:
            "Could not find the table 'public.user_feedback' in the schema cache",
        code: 'PGRST205',
        details: 'Not Found',
      );

      expect(isMissingRelation(error, dbUserFeedbackTable), isTrue);
    });

    test('returns true for missing relation errors', () {
      const error = PostgrestException(
        message: 'relation "public.notifications" does not exist',
        code: '42P01',
      );

      expect(isMissingRelation(error, dbNotificationsTable), isTrue);
    });

    test('returns false for unrelated relations', () {
      const error = PostgrestException(
        message:
            "Could not find the table 'public.user_recent_searches' in the schema cache",
        code: 'PGRST205',
        details: 'Not Found',
      );

      expect(isMissingRelation(error, dbUserFeedbackTable), isFalse);
    });
  });
}
