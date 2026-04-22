import 'package:campus_online/models/venue_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VenueModel.fromSupabaseJson', () {
    test('sets isFavorite true when joined user_favorites contains user id',
        () {
      final json = <String, dynamic>{
        'id': 'venue-1',
        'name': 'Merkez Kutuphane',
        'hours': '08:00-22:00',
        'weekend_hours': '10:00-20:00',
        'user_favorites': [
          {'user_id': 'user-1'},
        ],
      };

      final venue = VenueModel.fromSupabaseJson(json, userId: 'user-1');

      expect(venue.id, 'venue-1');
      expect(venue.name, 'Merkez Kutuphane');
      expect(venue.isFavorite, isTrue);
    });

    test('sets isFavorite false when user is null', () {
      final json = <String, dynamic>{
        'id': 'venue-2',
        'name': 'Yemekhane',
        'hours': '08:00-21:00',
        'weekend_hours': '',
        'user_favorites': [
          {'user_id': 'user-9'},
        ],
      };

      final venue = VenueModel.fromSupabaseJson(json);

      expect(venue.id, 'venue-2');
      expect(venue.isFavorite, isFalse);
    });

    test('does not mutate input map when deriving isFavorite', () {
      final json = <String, dynamic>{
        'id': 'venue-3',
        'name': 'Kampus Kafe',
        'hours': '08:00-22:00',
        'weekend_hours': '10:00-20:00',
        'user_favorites': [
          {'user_id': 'user-42'},
        ],
      };

      VenueModel.fromSupabaseJson(json, userId: 'user-42');

      expect(json.containsKey('is_favorite'), isFalse);
    });
  });
}
