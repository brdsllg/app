import 'dart:io';
import 'package:kosher_dart/kosher_dart.dart';

void main() {
  // Coordinates: -37, 145 (latitude, longitude) — e.g. Melbourne area
  final double latitude = -37.8663;
  final double longitude = 145.0007;
  final String locationName = 'Lat: $latitude, Lng: $longitude';

  // One full year: July 1, 2026 → June 30, 2027
  final DateTime startDate = DateTime(2026, 7, 1);
  final DateTime endDate = DateTime(2027, 6, 30);

  final file = File('year_zmanim_2026-2027.csv');
  final csvBuffer = StringBuffer();

  // ── CSV Header ──
  csvBuffer.writeln(
    'Date,Alot Hashachar,Netz HaChama,Sof Zman K"S,Sof Zman Tefilah,'
    'Mincha Gedola,Mincha Ketanah,Plag HaMincha,Shkiah,'
    'Tzeit Hakochavim,Tzeit 8.5°,Sof Zman Achilas Chametz,'
    'Sof Zman Biur Chametz,Shaah Zmanit (min),Midnight',
  );

  // ── Console: Markdown table header ──
  print(
    '| Date | Alot Hashachar | Netz HaChama | Sof Zman K"S | '
    'Sof Zman Tefilah | Mincha Gedola | Mincha Ketanah | '
    'Plag HaMincha | Shkiah | Tzeit Hakochavim | Tzeit 8.5° | '
    'Sof Zman Achilas Chametz | Sof Zman Biur Chametz | '
    'Shaah Zmanit (min:sec) | Midnight |',
  );
  print(
    '|------|----------------|--------------|--------------|'
    '------------------|---------------|----------------|'
    '---------------|--------|------------------|------------|'
    '--------------------------|------------------------|'
    '------------------------|----------|',
  );

  // ── Iterate each day ──
  DateTime currentDate = startDate;
  while (!currentDate.isAfter(endDate)) {
    // Timezone-adjusted DateTime
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

    // Today's calendar
    final calendar = ComplexZmanimCalendar();
    calendar.setGeoLocation(location);

    // Tomorrow for midnight
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowCalendar = ComplexZmanimCalendar();
    tomorrowCalendar.setGeoLocation(location);
    tomorrowCalendar.setCalendar(tomorrow);
    final netzAmitiTomorrow = tomorrowCalendar.getSunriseBaalHatanya();

    // Baal Hatanya zmanim
    final netzAmiti = calendar.getSunriseBaalHatanya();
    final shkiahAmitis = calendar.getSunsetBaalHatanya();
    final shaahZmanisMs = calendar.getShaahZmanisBaalHatanya();

    final shaahMinutes = shaahZmanisMs > 0
        ? (shaahZmanisMs / 60000).floor()
        : 0;
    final shaahSeconds = shaahZmanisMs > 0
        ? ((shaahZmanisMs % 60000) / 1000).round()
        : 0;

    final zmanim = {
      'Alot Hashachar': calendar.getAlosBaalHatanya(),
      'Netz HaChama': netzAmiti,
      'Sof Zman K"S': calendar.getSofZmanShmaBaalHatanya(),
      'Sof Zman Tefilah': calendar.getSofZmanTfilaBaalHatanya(),
      'Mincha Gedola': calendar.getMinchaGedolaBaalHatanya(),
      'Mincha Ketanah': calendar.getMinchaKetanaBaalHatanya(),
      'Plag HaMincha': calendar.getPlagHaminchaBaalHatanya(),
      'Shkiah': shkiahAmitis,
      'Tzeit Hakochavim': calendar.getTzaisBaalHatanya(),
      'Tzeit 8.5°': calendar.getTzaisGeonim8Point5Degrees(),
      'Sof Zman Achilas Chametz':
          calendar.getSofZmanAchilasChametzBaalHatanya(),
      'Sof Zman Biur Chametz':
          calendar.getSofZmanBiurChametzBaalHatanya(),
      'Midnight': _midnightBetween(shkiahAmitis, netzAmitiTomorrow),
    };

    // ── Format helpers ──
    String formatTime(DateTime? time) {
      if (time == null) return '--:--';
      final hour = time.hour;
      final minute = time.minute.toString().padLeft(2, '0');
      final second = time.second.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : hour > 12 ? hour - 12 : hour;
      return '${displayHour.toString().padLeft(2, '0')}:$minute:$second $period';
    }

    String shaahDisplay =
        shaahZmanisMs > 0 ? '$shaahMinutes min $shaahSeconds sec' : '--:--';

    String dateStr = '${currentDate.month}/${currentDate.day}/${currentDate.year}';

    // ── Console: Markdown row ──
    print(
      '| $dateStr | ${formatTime(zmanim['Alot Hashachar'])} | '
      '${formatTime(zmanim['Netz HaChama'])} | '
      '${formatTime(zmanim['Sof Zman K"S'])} | '
      '${formatTime(zmanim['Sof Zman Tefilah'])} | '
      '${formatTime(zmanim['Mincha Gedola'])} | '
      '${formatTime(zmanim['Mincha Ketanah'])} | '
      '${formatTime(zmanim['Plag HaMincha'])} | '
      '${formatTime(zmanim['Shkiah'])} | '
      '${formatTime(zmanim['Tzeit Hakochavim'])} | '
      '${formatTime(zmanim['Tzeit 8.5°'])} | '
      '${formatTime(zmanim['Sof Zman Achilas Chametz'])} | '
      '${formatTime(zmanim['Sof Zman Biur Chametz'])} | '
      '$shaahDisplay | '
      '${formatTime(zmanim['Midnight'])} |',
    );

    // ── CSV row (comma-separated, quoted for safety) ──
    String csvEscape(String v) => '"${v.replaceAll('"', '""')}"';

    csvBuffer.writeln(
      '${csvEscape(dateStr)},'
      '${csvEscape(formatTime(zmanim['Alot Hashachar']))},'
      '${csvEscape(formatTime(zmanim['Netz HaChama']))},'
      '${csvEscape(formatTime(zmanim['Sof Zman K"S']))},'
      '${csvEscape(formatTime(zmanim['Sof Zman Tefilah']))},'
      '${csvEscape(formatTime(zmanim['Mincha Gedola']))},'
      '${csvEscape(formatTime(zmanim['Mincha Ketanah']))},'
      '${csvEscape(formatTime(zmanim['Plag HaMincha']))},'
      '${csvEscape(formatTime(zmanim['Shkiah']))},'
      '${csvEscape(formatTime(zmanim['Tzeit Hakochavim']))},'
      '${csvEscape(formatTime(zmanim['Tzeit 8.5°']))},'
      '${csvEscape(formatTime(zmanim['Sof Zman Achilas Chametz']))},'
      '${csvEscape(formatTime(zmanim['Sof Zman Biur Chametz']))},'
      '"$shaahMinutes",'
      '${csvEscape(formatTime(zmanim['Midnight']))}',
    );

    // Next day
    currentDate = currentDate.add(const Duration(days: 1));
  }

  // ── Write CSV file ──
  file.writeAsStringSync(csvBuffer.toString());
  print('\n✅ CSV written to year_zmanim_2026-2027.csv');
  print('   Total days: ${endDate.difference(startDate).inDays + 1}');
}

/// Midpoint between two DateTimes
DateTime? _midnightBetween(DateTime? a, DateTime? b) {
  if (a == null || b == null) return null;
  final midpointMs = (a.millisecondsSinceEpoch + b.millisecondsSinceEpoch) ~/ 2;
  return DateTime.fromMillisecondsSinceEpoch(midpointMs);
}