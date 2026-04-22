import 'package:campus_online/models/event_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EventModel.fromSupabaseJson', () {
    test('marks event as favorite when joined favorite row matches user', () {
      final json = <String, dynamic>{
        'id': 'event-1',
        'title': 'Kariyer Zirvesi',
        'start_at': '2026-05-01T10:00:00Z',
        'end_at': '2026-05-01T12:00:00Z',
        'is_published': true,
        'event_favorites': [
          {'user_id': 'user-1'},
        ],
      };

      final model = EventModel.fromSupabaseJson(json, userId: 'user-1');

      expect(model.id, 'event-1');
      expect(model.title, 'Kariyer Zirvesi');
      expect(model.isFavorite, isTrue);
    });

    test('keeps event as not favorite for other users', () {
      final json = <String, dynamic>{
        'id': 'event-2',
        'title': 'Teknoloji Gunleri',
        'start_at': '2026-05-10T09:00:00Z',
        'end_at': '2026-05-10T11:30:00Z',
        'is_published': true,
        'event_favorites': [
          {'user_id': 'user-10'},
        ],
      };

      final model = EventModel.fromSupabaseJson(json, userId: 'user-2');

      expect(model.id, 'event-2');
      expect(model.isFavorite, isFalse);
    });
  });
}