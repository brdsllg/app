import 'package:flutter/material.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:geolocator/geolocator.dart';
import 'package:material_hebrew_date_picker/material_hebrew_date_picker.dart';

class ZmanimScreen extends StatefulWidget {
  const ZmanimScreen({super.key});

  @override
  State<ZmanimScreen> createState() => _ZmanimScreenState();
}

class _ZmanimScreenState extends State<ZmanimScreen> {
  final Map<String, Object?> _zmanim = {};
  String? _shaahZmanisDisplay;
  String? _locationName;
  bool _isLoading = true;
  String? _error;
  double? _currentLatitude;
  double? _currentLongitude;
  double? _currentAltitude;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _getCurrentLocationAndCalculate();
  }

  Future<void> _getCurrentLocationAndCalculate() async {
    setState(() {
      _isLoading = true;
      _zmanim.clear();
      _shaahZmanisDisplay = null;
      _error = null;
    });

    try {
      // Check if location services are enabled
      final isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationServiceEnabled) {
        setState(() {
          _error = 'Location services are disabled. Please enable them in your device settings.';
          _isLoading = false;
        });
        return;
      }

      // Check and request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _error = 'Location permission denied. Please grant location access to use this app.';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Location permission permanently denied. Please enable it in app settings.';
          _isLoading = false;
        });
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 100,
        ),
      );

      _currentLatitude = position.latitude;
      _currentLongitude = position.longitude;
      _currentAltitude = position.altitude;

      // Set location name from coordinates
      final latStr = position.latitude.toStringAsFixed(4);
      final lngStr = position.longitude.toStringAsFixed(4);
      _locationName = 'Lat: $latStr, Lng: $lngStr';

      _calculateZmanim();
    } catch (e) {
      setState(() {
        _error = 'Failed to get location: $e';
        _isLoading = false;
      });
    }
  }

  // BAAL_HATANYA_NATIVE: Replaced manual degree-offset calculations with native kosher_dart
  // Baal Hatanya methods that match Chabad.org. See REVERT_LOG_BAAL_HATANYA.md to revert.
  void _calculateZmanim() {
    final lat = _currentLatitude;
    final lng = _currentLongitude;

    try {
      // kosher_dart uses the DateTime's own timezone offset for all calculations,
      // so make sure the selected date is represented in the device's timezone.
      final tzOffset = DateTime.now().timeZoneOffset;
      final now = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedDate.hour,
        _selectedDate.minute,
        _selectedDate.second,
        _selectedDate.millisecond,
      ).add(tzOffset);

      // Create GeoLocation for current position.
      // kosher_dart 2.0.20 GeoLocation.setLocation takes:
      // locationName, latitude, longitude, dateTime, [elevation]
      final location = GeoLocation.setLocation(
        _locationName ?? 'Current Location',
        lat!, // latitude (negative = South)
        lng!, // longitude (negative = West, positive = East)
        now,
        _currentAltitude ?? 0, // elevation
      );
      location.setLocationName(_locationName ?? 'Current Location');

      // BAAL_HATANYA_NATIVE: Using native ComplexZmanimCalendar Baal Hatanya methods
      final calendar = ComplexZmanimCalendar();
      calendar.setGeoLocation(location);

      // BAAL_HATANYA_NATIVE: Use native getSunriseBaalHatanya / getSunsetBaalHatanya (1.583° offset)
      final netzAmiti = calendar.getSunriseBaalHatanya();
      final shkiahAmitis = calendar.getSunsetBaalHatanya();

      // BAAL_HATANYA_NATIVE: Use native shaah zmanis (milliseconds double) for the day
      final shaahZmanisMs = calendar.getShaahZmanisBaalHatanya();

      // Tomorrow morning's netz amiti for correct midnight calculation
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowCalendar = ComplexZmanimCalendar();
      tomorrowCalendar.setGeoLocation(location);
      tomorrowCalendar.setCalendar(tomorrow);
      // BAAL_HATANYA_NATIVE: Use native method for tomorrow
      final netzAmitiTomorrow = tomorrowCalendar.getSunriseBaalHatanya();

      // Helper function: add temporal hours to a DateTime
      DateTime? addTemporalHours(DateTime? start, double hours) {
        if (start == null || shaahZmanisMs <= 0) return null;
        return start.add(Duration(milliseconds: (shaahZmanisMs * hours).toInt()));
      }

      final sunrise = calendar.getSunrise();
      final sunset = calendar.getSunset();

      // BAAL_HATANYA_NATIVE: All zmanim use native Baal Hatanya methods
      final zmanim = <String, Object?>{
        // BAAL_HATANYA_NATIVE: 16.9° - 72 min before netz amiti
        ' Dawn (Alot Hashachar)':
            calendar.getAlosBaalHatanya(),

        ' Earliest Tallit and Tefillin (Misheyakir)':
            calendar.getSunriseOffsetByDegrees(90 + 10.2),

        ' Sunrise (Hanetz Hachamah)':
            sunrise,

        // BAAL_HATANYA_NATIVE: 3 shaos zmaniyos after netz amiti
        ' Latest Shema (Sof Zman Krias Shema)':
            calendar.getSofZmanShmaBaalHatanya(),

        // BAAL_HATANYA_NATIVE: 4 shaos zmaniyos after netz amiti
        ' Latest Shacharit (Sof Zman Shachris)':
            calendar.getSofZmanTfilaBaalHatanya(),

        ' Midday (Chatzot Hayom)':
            addTemporalHours(netzAmiti, 6),

        // BAAL_HATANYA_NATIVE: 6.5 shaos zmaniyos after netz amiti
        ' Earliest Mincha (Mincha Gedolah)':
            calendar.getMinchaGedolaBaalHatanya(),

        // BAAL_HATANYA_NATIVE: 9.5 shaos zmaniyos after netz amiti
        ' Mincha Ketanah ("Small Mincha")':
            calendar.getMinchaKetanaBaalHatanya(),

        // BAAL_HATANYA_NATIVE: 10.75 shaos zmaniyos after netz amiti
        ' Plag Hamincha ("Half of Mincha")':
            calendar.getPlagHaminchaBaalHatanya(),

        ' Sunset (Shkiah)':
            sunset,

        // BAAL_HATANYA_NATIVE: 6° below horizon
        ' Nightfall (Tzeit Hakochavim)':
            calendar.getTzaisBaalHatanya(),

        // BAAL_HATANYA_NATIVE: 8.5° lechumra
        ' Nightfall 8.5° (Tzeit L\'Chumra)':
            calendar.getTzaisGeonim8Point5Degrees(),

        // BAAL_HATANYA_NATIVE: 4 shaos - Erev Pesach relevant
        ' Sof Zman Achilas Chametz':
            calendar.getSofZmanAchilasChametzBaalHatanya(),

        // BAAL_HATANYA_NATIVE: 5 shaos - Erev Pesach relevant
        ' Sof Zman Biur Chametz':
            calendar.getSofZmanBiurChametzBaalHatanya(),

        // Midnight: midpoint between tonight's shkiah amitis and tomorrow's netz amiti
        ' Midnight (Chatzot HaLailah)':
            _midnightBetween(shkiahAmitis, netzAmitiTomorrow),
      };

      // Format shaah zmanis as minutes and seconds string
      final shaahMinutes = (shaahZmanisMs / 60000).floor();
      final shaahSeconds = ((shaahZmanisMs % 60000) / 1000).round();

      // DEBUG: Print all zmanim to console
            /*
      debugPrint('[ZMAN_DEBUG] Date: ${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}');
      debugPrint('[ZMAN_DEBUG] Location: ${_currentLatitude?.toStringAsFixed(4) ?? "N/A"}, ${_currentLongitude?.toStringAsFixed(4) ?? "N/A"}');
      for (final entry in zmanim.entries) {
        final value = entry.value;
        String timeStr;
        if (value is DateTime) {
          final h = value.hour.toString().padLeft(2, '0');
          final m = value.minute.toString().padLeft(2, '0');
          final s = value.second.toString().padLeft(2, '0');
          timeStr = '$h:$m:$s';
        } else if (value == null) {
          timeStr = 'null';
        } else {
          timeStr = value.toString();
        }
        debugPrint('[ZMAN_DEBUG] ${entry.key}: $timeStr');
      }

      debugPrint('[ZMAN_DEBUG]  Shaah Zmanit (Baal Hatanya): $shaahMinutes:$shaahSeconds');
      */

      setState(() {
        _zmanim.addAll(zmanim);
        // BAAL_HATANYA_NATIVE: Shaah zmanis now from getShaahZmanisBaalHatanya()
        _shaahZmanisDisplay = ' Shaah Zmanit (Baal Hatanya): $shaahMinutes min $shaahSeconds sec';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _goToPreviousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
    _calculateZmanim();
  }

  void _goToNextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
    _calculateZmanim();
  }

  Future<void> _pickDate() async {
    // First choose which calendar type
    final calendarType = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose Calendar'),
          content: const Text('Select the calendar type to pick a date from:'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('gregorian'),
              child: const Text('Gregorian'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('hebrew'),
              child: const Text('Hebrew'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (calendarType == null) return;
    if (!mounted) return;

    DateTime? picked;

    if (calendarType == 'gregorian') {
      picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
    } else {
      // Hebrew calendar using material_hebrew_date_picker with transliterated display
      picked = await showDialog<DateTime>(
        context: context,
        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: SizedBox(
              width: 328,
              height: 500,
              child: Column(
                children: [
                  Expanded(
                    child: MaterialHebrewDatePicker(
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      hebrewFormat: false, // transliterated Hebrew calendar
                      onDateChange: (DateTime date) {
                        setState(() {
                          _selectedDate = date;
                        });
                        Navigator.of(context).pop(date);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    if (picked != null && mounted) {
      final newDate = picked;
      setState(() {
        _selectedDate = newDate;
      });
      _calculateZmanim();
    }
  }

  void _goToTodayOrReload() {
    final today = DateTime.now();
    if (_selectedDate.year == today.year &&
        _selectedDate.month == today.month &&
        _selectedDate.day == today.day) {
      // Already on today — reload location and recalculate
      _getCurrentLocationAndCalculate();
    } else {
      setState(() {
        _selectedDate = today;
      });
      _calculateZmanim();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Container(
          color: Theme.of(context).colorScheme.inversePrimary,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hamburger (leading) - 20% width -> flex 2 out of 10
              Expanded(
                flex: 2,
                child: IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    // TODO: open drawer
                  },
                  iconSize: 30,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints.expand(),
                ),
              ),
              // Title - 30% width -> flex 3
              Expanded(
                flex: 3,
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.noScaling,
                  ),
                  child: const Center(
                    child: Text(
                      'Zmanim',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              // Today button - part of actions, allocate flex 2 (20%)
              Expanded(
                flex: 2,
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.noScaling,
                  ),
                  child: TextButton(
                    onPressed: _goToTodayOrReload,
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                    ),
                    child: const Text(
                      'Today',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
              // IconButton left - flex 1 (10%)
              Expanded(
                flex: 1,
                child: IconButton(
                  icon: const Icon(Icons.chevron_left),
                  iconSize: 30,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints.expand(),
                  onPressed: _goToPreviousDay,
                ),
              ),
              // IconButton calendar - flex 1 (10%)
              Expanded(
                flex: 1,
                child: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  iconSize: 30,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints.expand(),
                  onPressed: _pickDate,
                ),
              ),
              // IconButton right - flex 1 (10%)
              Expanded(
                flex: 1,
                child: IconButton(
                  icon: const Icon(Icons.chevron_right),
                  iconSize: 30,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints.expand(),
                  onPressed: _goToNextDay,
                ),
              ),
            ],
          ),
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    // DIAGNOSTIC: print device metrics for cross-device layout comparison

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Getting current location...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _getCurrentLocationAndCalculate,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final selected = _selectedDate;

    final monthsOfYear = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final monthName = monthsOfYear[selected.month - 1];
    final dateFormatted = '${selected.day} $monthName';

    // Format Hebrew date: e.g. "Monday, 7 Tamuz"
    final daysOfWeek = [
      'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
    ];
    final dayOfWeek = daysOfWeek[selected.weekday % 7];
    final jewishDate = JewishDate.fromDateTime(selected);
    final hebrewFormatter = HebrewDateFormatter();
    final jewishMonthName = hebrewFormatter.transliteratedMonths[jewishDate.getJewishMonth() - 1];
    final mainHeaderLine = '$dayOfWeek, ${jewishDate.getJewishDayOfMonth()} $jewishMonthName';
    final items = _zmanim.entries.toList();

    // Header widget to be placed as the first item in the list
    Widget headerWidget = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Column(
        children: [
          Text(
            mainHeaderLine,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            dateFormatted,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            _locationName ?? 'Current Location',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );

    final totalZmanimItems = items.length + (_shaahZmanisDisplay != null ? 1 : 0);
    final totalItems = 1 + totalZmanimItems; // +1 for the header

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 8),
            itemCount: totalItems,
            separatorBuilder: (context, index) {
              // No divider after the header (index 0)
              if (index == 0) return const SizedBox.shrink();
              return const Divider(height: 1, indent: 16, endIndent: 16);
            },
            itemBuilder: (context, index) {
              // First item is the header
              if (index == 0) return headerWidget;

              final zmanIndex = index - 1;

              if (_shaahZmanisDisplay != null && zmanIndex == items.length) {
                // Last item: shaah zmanis as a duration label
                return _DurationTile(label: _shaahZmanisDisplay!);
              }
              final entry = items[zmanIndex];
              final value = entry.value;
              if (value is DateTime) {
                return _ZmanimTile(
                  label: entry.key,
                  time: value,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}

/// Calculates the midpoint between two DateTimes.
DateTime? _midnightBetween(DateTime? a, DateTime? b) {
  if (a == null || b == null) return null;
  final midpointMs = (a.millisecondsSinceEpoch + b.millisecondsSinceEpoch) ~/ 2;
  return DateTime.fromMillisecondsSinceEpoch(midpointMs);
}

class _ZmanimTile extends StatelessWidget {
  final String label;
  final DateTime? time;

  const _ZmanimTile({
    required this.label,
    required this.time,
  });

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '--:--';
    // 12-hour format with AM/PM
    int hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }
    final hourStr = hour.toString().padLeft(2, '0');
    return '$hourStr:$minute:$second $period';
  }

  @override
  Widget build(BuildContext context) {
    final isNull = time == null;
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isNull ? Colors.grey : null,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isNull
              ? Colors.grey.shade200
              : Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          _formatTime(time),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: isNull ? Colors.grey : null,
          ),
        ),
      ),
    );
  }
}

class _DurationTile extends StatelessWidget {
  final String label;

  const _DurationTile({required this.label});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}