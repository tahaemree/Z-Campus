import 'package:supabase_flutter/supabase_flutter.dart';

const dbNotificationsTable = 'notifications';
const dbUserFeedbackTable = 'user_feedback';
const dbUserPushTokensTable = 'user_push_tokens';

String escapePostgrestLikeValue(String value) {
  return value
      .replaceAll(r'\\', r'\\\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_')
      .replaceAll(',', r'\,')
      .replaceAll('(', r'\(')
      .replaceAll(')', r'\)')
      .replaceAll('"', r'\"');
}

bool isMissingRelation(PostgrestException error, String relationName) {
  final normalizedRelation = relationName.trim().toLowerCase();
  final message = error.message.toLowerCase();
  final details = (error.details ?? '').toString().toLowerCase();
  final hint = (error.hint ?? '').toString().toLowerCase();

  final relationMentioned = _mentionsRelation(message, normalizedRelation) ||
      _mentionsRelation(details, normalizedRelation) ||
      _mentionsRelation(hint, normalizedRelation);

  if (error.code == '42P01' || error.code == 'PGRST205') {
    return relationMentioned;
  }

  final looksLikeMissingRelation =
      (message.contains('relation') && message.contains('does not exist')) ||
          message.contains('schema cache') ||
          details.contains('schema cache');

  return looksLikeMissingRelation && relationMentioned;
}

bool _mentionsRelation(String text, String relationName) {
  if (text.isEmpty) return false;

  final publicName = 'public.$relationName';

  return text.contains(publicName) ||
      text.contains("'$publicName'") ||
      text.contains('"$publicName"') ||
      text.contains("'$relationName'") ||
      text.contains('"$relationName"') ||
      text.contains(relationName);
}
