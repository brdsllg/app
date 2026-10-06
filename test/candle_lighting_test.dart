import 'package:app/zmanim_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calculateCandleLighting', () {
    test('returns displayed shkiah minus 18 minutes on Friday', () {
      final shkiah = DateTime(2026, 9, 18, 18, 47, 30); // Friday

      final result = calculateCandleLighting(
        selectedDate: DateTime(2026, 9, 18), // Friday
        shkiah: shkiah,
      );

      expect(result, DateTime(2026, 9, 18, 18, 29, 30));
    });

    test('is absent when the selected date is not Friday', () {
      final result = calculateCandleLighting(
        selectedDate: DateTime(2026, 9, 17), // Thursday
        shkiah: DateTime(2026, 9, 17, 18, 48),
      );

      expect(result, isNull);
    });

    test('is absent when the shkiah is unavailable', () {
      expect(
        calculateCandleLighting(
          selectedDate: DateTime(2026, 9, 18), // Friday
          shkiah: null,
        ),
        isNull,
      );
    });
  });
}