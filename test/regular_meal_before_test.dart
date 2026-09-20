import 'package:app/zmanim_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calculateRegularMealBefore', () {
    test('returns nine Baal HaTanya shaos after netz on Friday', () {
      final netz = DateTime(2026, 9, 18, 6);
      const shaahZmanisMs = 60 * 60 * 1000.0;

      final result = calculateRegularMealBefore(
        selectedDate: DateTime(2026, 9, 18), // Friday
        netzAmiti: netz,
        shaahZmanisMs: shaahZmanisMs,
      );

      expect(result, DateTime(2026, 9, 18, 15));
    });

    test('is absent when the selected civil/Jewish date is not Friday', () {
      final result = calculateRegularMealBefore(
        selectedDate: DateTime(2026, 9, 17), // Thursday
        netzAmiti: DateTime(2026, 9, 17, 6),
        shaahZmanisMs: 60 * 60 * 1000.0,
      );

      expect(result, isNull);
    });

    test('is absent when netz or the proportional hour is unavailable', () {
      final friday = DateTime(2026, 9, 18);

      expect(
        calculateRegularMealBefore(
          selectedDate: friday,
          netzAmiti: null,
          shaahZmanisMs: 60 * 60 * 1000.0,
        ),
        isNull,
      );
      expect(
        calculateRegularMealBefore(
          selectedDate: friday,
          netzAmiti: DateTime(2026, 9, 18, 6),
          shaahZmanisMs: 0,
        ),
        isNull,
      );
    });
  });
}
