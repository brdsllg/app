import 'package:kosher_dart/kosher_dart.dart';

void main() {
  // Coordinates: -37.81666666666667, 144.96666666666667 (Melbourne area)
  final double latitude = -37.81666666666667;
  final double longitude = 144.96666666666667;
  final String locationName = 'Lat: $latitude, Lng: $longitude';

  // Date range: July 1–31, 2026
  final DateTime startDate = DateTime(2026, 7, 1);
  final DateTime endDate = DateTime(2026, 7, 31);

  // Print markdown table header
  print('| Date | AlosHashachar | EarliestTefillin | NetzHachamah | LatestShema | LatestTefillah | Chatzos | MinchahGedolah | MinchahKetanah | PlagHaminchah | Shkiah | Tzeis | ChatzosNight | ShaahZmanit |');
  print('|------|--------------|-----------------|-------------|------------|--------------|--------|---------------|--------------|-------------|------|------|------------|-----------|');

  // Iterate through each day
  DateTime currentDate = startDate;
  while (!currentDate.isAfter(endDate)) {
    // Timezone-adjusted DateTime (kosher_dart uses the DateTime's own timezone)
    final tzOffset = DateTime.now().timeZoneOffset;
    final now = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    ).add(tzOffset);

    // Create GeoLocation
    final location = GeoLocation.setLocation(
      locationName,
      latitude,
      longitude,
      now,
      0, // elevation
    );
    location.setLocationName(locationName);

    // Create calendar for today
    final calendar = ComplexZmanimCalendar();
    calendar.setGeoLocation(location);

    // Tomorrow for ChatzosNight (midnight)
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowCalendar = ComplexZmanimCalendar();
    tomorrowCalendar.setGeoLocation(location);
    tomorrowCalendar.setCalendar(tomorrow);
    final netzAmitiTomorrow = tomorrowCalendar.getSunriseBaalHatanya();

    // Baal Hatanya zmanim
    final netzAmiti = calendar.getSunriseBaalHatanya();
    final shkiahAmitis = calendar.getSunsetBaalHatanya();
    final shaahZmanisMs = calendar.getShaahZmanisBaalHatanya();

    // Helper function: add temporal hours to a DateTime
    DateTime? addTemporalHours(DateTime? start, double hours) {
      if (start == null || shaahZmanisMs <= 0) return null;
      return start.add(Duration(milliseconds: (shaahZmanisMs * hours).toInt()));
    }

    // Compute all zmanim
    final alosHashachar = calendar.getAlosBaalHatanya();
    final earliestTefillin = calendar.getSunriseOffsetByDegrees(90 + 10.2);
    final netzHachamah = netzAmiti;
    final latestShema = calendar.getSofZmanShmaBaalHatanya();
    final latestTefillah = calendar.getSofZmanTfilaBaalHatanya();
    final chatzos = addTemporalHours(netzAmiti, 6);
    final minchahGedolah = calendar.getMinchaGedolaBaalHatanya();
    final minchahKetanah = calendar.getMinchaKetanaBaalHatanya();
    final plagHaminchah = calendar.getPlagHaminchaBaalHatanya();
    final shkiah = shkiahAmitis;
    final tzeis = calendar.getTzaisBaalHatanya();
    final chatzosNight = _midnightBetween(shkiahAmitis, netzAmitiTomorrow);

    // Shaah zmanis as minutes:seconds
    final shaahMinutes = shaahZmanisMs > 0 ? (shaahZmanisMs / 60000).floor() : 0;
    final shaahSeconds = shaahZmanisMs > 0 ? ((shaahZmanisMs % 60000) / 1000).round() : 0;
    final shaahDisplay = shaahZmanisMs > 0
        ? '${shaahMinutes.toString().padLeft(2, '0')} min ${shaahSeconds.toString().padLeft(2, '0')} sec'
        : '--:--';

    // Format time helper
    String formatTime(DateTime? time) {
      if (time == null) return '--:--';
      final hour = time.hour;
      final minute = time.minute.toString().padLeft(2, '0');
      final second = time.second.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : hour > 12 ? hour - 12 : hour;
      final hourStr = displayHour.toString().padLeft(2, '0');
      return '$hourStr:$minute:$second $period';
    }

    // Format date
    final String dateStr = '${currentDate.month}/${currentDate.day}/${currentDate.year}';

    // Print table row
    print('| $dateStr | ${formatTime(alosHashachar)} | ${formatTime(earliestTefillin)} | ${formatTime(netzHachamah)} | ${formatTime(latestShema)} | ${formatTime(latestTefillah)} | ${formatTime(chatzos)} | ${formatTime(minchahGedolah)} | ${formatTime(minchahKetanah)} | ${formatTime(plagHaminchah)} | ${formatTime(shkiah)} | ${formatTime(tzeis)} | ${formatTime(chatzosNight)} | $shaahDisplay |');

    // Move to next day
    currentDate = currentDate.add(const Duration(days: 1));
  }
}

/// Midpoint between two DateTimes
DateTime? _midnightBetween(DateTime? a, DateTime? b) {
  if (a == null || b == null) return null;
  final midpointMs = (a.millisecondsSinceEpoch + b.millisecondsSinceEpoch) ~/ 2;
  return DateTime.fromMillisecondsSinceEpoch(midpointMs);
}