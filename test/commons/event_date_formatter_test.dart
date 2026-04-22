import 'package:campus_online/commons/event_date_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatEventDateRange', () {
    test('omits end date when start and end are on the same day', () {
      final start = DateTime(2026, 4, 18, 9, 30);
      final end = DateTime(2026, 4, 18, 11, 45);

      final value = formatEventDateRange(start, end);

      expect(value, '18.04.2026 09:30 - 11:45');
    });

    test('shows full end date when days differ', () {
      final start = DateTime(2026, 4, 18, 23, 30);
      final end = DateTime(2026, 4, 19, 1, 15);

      final value = formatEventDateRange(start, end);

      expect(value, '18.04.2026 23:30 - 19.04.2026 01:15');
    });
  });
}
