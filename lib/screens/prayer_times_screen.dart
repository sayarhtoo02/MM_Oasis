import 'dart:async';
// import 'dart:ui'; // Removed unused import
import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';
import 'package:munajat_e_maqbool_app/services/prayer_time_service.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import '../services/location_service.dart';
// Needed for other checks if any, or remove if unused
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:munajat_e_maqbool_app/config/glass_theme.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_scaffold.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_card.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  late PrayerTimeService _prayerTimeService;
  Map<String, String> _prayerTimes = {};
  Map<String, dynamic>? _nextPrayerData;
  CalculationMethod? _selectedMethod;
  Madhab _asrMethod = Madhab.hanafi;
  double _latitude = 21.4225; // Yangon, Myanmar
  double _longitude = 96.0836;
  String _currentCity = 'Yangon, Myanmar';

  bool _isLocating = false;
  Timer? _timer;
  Duration _timeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _prayerTimeService = PrayerTimeService();
    _loadSavedSettings();
    _startTimer();

    // Auto-fetch location if it appears to be the default
    // Using a microtask to allow _loadSavedSettings to complete its sync state update
    Future.microtask(() {
      if (_currentCity == 'Yangon, Myanmar') {
        _getCurrentLocation();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_nextPrayerData != null) {
        setState(() {
          final nextTime = _nextPrayerData!['time'] as DateTime;
          final now = DateTime.now();
          if (nextTime.isAfter(now)) {
            _timeRemaining = nextTime.difference(now);
          } else {
            _loadPrayerTimes(); // Refresh if time passed
          }
        });
      }
    });
  }

  void _loadSavedSettings() {
    final settings = Provider.of<SettingsProvider>(
      context,
      listen: false,
    ).appSettings;
    setState(() {
      _latitude = settings.prayerLatitude ?? 21.4225;
      _longitude = settings.prayerLongitude ?? 96.0836;
      _currentCity = settings.prayerCity ?? 'Yangon, Myanmar';
      if (settings.prayerCalculationMethod != null) {
        _selectedMethod = CalculationMethod.values.firstWhere(
          (m) => m.name == settings.prayerCalculationMethod,
          orElse: () => CalculationMethod.other,
        );
      }
      _asrMethod = settings.prayerAsrMethod == 'shafi'
          ? Madhab.shafi
          : Madhab.hanafi;
    });
    _loadPrayerTimes();
  }

  void _saveSettings() {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    settingsProvider.updateSettings(
      settingsProvider.appSettings.copyWith(
        prayerLatitude: _latitude,
        prayerLongitude: _longitude,
        prayerCity: _currentCity,
        prayerCalculationMethod: _selectedMethod?.name,
        prayerAsrMethod: _asrMethod == Madhab.shafi ? 'shafi' : 'hanafi',
      ),
    );
  }

  void _loadPrayerTimes() {
    final times = _prayerTimeService.getPrayerTimesFormatted(
      latitude: _latitude,
      longitude: _longitude,
      method: _selectedMethod,
      asrMethod: _asrMethod,
      use24Hour: false,
    );

    final nextPrayer = _prayerTimeService.getNextPrayer(
      latitude: _latitude,
      longitude: _longitude,
      method: _selectedMethod,
      asrMethod: _asrMethod,
    );

    setState(() {
      _prayerTimes = times;
      _nextPrayerData = nextPrayer;
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      final locationData = await LocationService().refreshLocation();

      if (mounted) {
        setState(() {
          _latitude = locationData.latitude;
          _longitude = locationData.longitude;
          _currentCity = locationData.cityName;
        });

        _saveSettings();
        _loadPrayerTimes();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location updated: $_currentCity')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
      }
    }
  }

  IconData _getPrayerIcon(String prayerName) {
    switch (prayerName) {
      case 'fajr':
        return Icons.wb_twilight;
      case 'sunrise':
        return Icons.wb_sunny;
      case 'dhuhr':
        return Icons.wb_sunny_outlined;
      case 'asr':
        return Icons.wb_cloudy_outlined;
      case 'maghrib':
        return Icons.nights_stay_outlined;
      case 'isha':
        return Icons.nights_stay;
      default:
        return Icons.access_time;
    }
  }

  String _getPrayerDisplayName(String prayerName) {
    switch (prayerName) {
      case 'fajr':
        return 'Fajr';
      case 'sunrise':
        return 'Sunrise';
      case 'dhuhr':
        return 'Dhuhr';
      case 'asr':
        return 'Asr';
      case 'maghrib':
        return 'Maghrib';
      case 'isha':
        return 'Isha';
      default:
        return prayerName.toUpperCase();
    }
  }

  // Method _getGradientForPrayer removed as it is replaced by Global Theme

  Future<void> _showCitySearch() async {
    final controller = TextEditingController();
    List<Map<String, dynamic>> searchResults = [];
    bool isSearching = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Search City'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Enter city name',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () async {
                      if (controller.text.isEmpty) return;
                      setDialogState(() => isSearching = true);
                      try {
                        final response = await http.get(
                          Uri.parse(
                            'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(controller.text)}&format=json&limit=5',
                          ),
                          headers: {'User-Agent': 'MunajatApp/1.0'},
                        );
                        if (response.statusCode == 200) {
                          final List<dynamic> data = json.decode(response.body);
                          searchResults = data
                              .map(
                                (item) => <String, dynamic>{
                                  'name': item['display_name'] as String,
                                  'lat': double.parse(item['lat']),
                                  'lon': double.parse(item['lon']),
                                },
                              )
                              .toList();
                        }
                      } catch (e) {
                        // Ignore error
                      } finally {
                        setDialogState(() => isSearching = false);
                      }
                    },
                  ),
                ),
              ),
              if (isSearching) const LinearProgressIndicator(),
              if (searchResults.isNotEmpty)
                SizedBox(
                  height: 200,
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      final item = searchResults[index];
                      return ListTile(
                        title: Text(item['name'] ?? 'Unknown'),
                        onTap: () {
                          try {
                            final lat = item['lat'];
                            final lon = item['lon'];
                            final name = item['name'] as String? ?? '';

                            debugPrint(
                              'City Search: Selected $name at ($lat, $lon)',
                            );

                            if (lat != null && lon != null) {
                              // Close dialog first
                              Navigator.pop(context);

                              // Then update state on the main screen
                              setState(() {
                                _latitude = lat is double
                                    ? lat
                                    : double.tryParse(lat.toString()) ??
                                          _latitude;
                                _longitude = lon is double
                                    ? lon
                                    : double.tryParse(lon.toString()) ??
                                          _longitude;
                                _currentCity = name
                                    .split(',')
                                    .where((s) => s.trim().isNotEmpty)
                                    .take(2)
                                    .join(', ');
                              });

                              _saveSettings();
                              _loadPrayerTimes();

                              debugPrint(
                                'City Search: Applied - $_currentCity',
                              );
                            } else {
                              debugPrint('City Search: lat or lon is null');
                            }
                          } catch (e, stackTrace) {
                            debugPrint('City Search Error: $e');
                            debugPrint('Stack: $stackTrace');
                          }
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Calculation Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<CalculationMethod>(
              initialValue: _selectedMethod,
              decoration: const InputDecoration(
                labelText: 'Method',
                border: OutlineInputBorder(),
              ),
              items: CalculationMethod.values
                  .map(
                    (m) => DropdownMenuItem(
                      value: m,
                      child: Text(m.name.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                setState(() => _selectedMethod = v);
                _saveSettings();
                _loadPrayerTimes();
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Madhab>(
              initialValue: _asrMethod,
              decoration: const InputDecoration(
                labelText: 'Asr Method',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: Madhab.shafi,
                  child: Text('Shafi (Standard)'),
                ),
                DropdownMenuItem(value: Madhab.hanafi, child: Text('Hanafi')),
              ],
              onChanged: (v) {
                setState(() => _asrMethod = v!);
                _saveSettings();
                _loadPrayerTimes();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nextPrayerName = _nextPrayerData?['name'] as String? ?? '';
    final nextPrayerTime = _nextPrayerData?['time'] as DateTime?;

    return GlassScaffold(
      title: 'Prayer Times',
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: _showSettingsSheet,
        ),
      ],
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          final isDark = settingsProvider.isDarkMode;
          final textColor = GlassTheme.text(isDark);
          final accentColor = GlassTheme.accent(isDark);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Date Display
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    DateFormat('EEEE, d MMMM y').format(DateTime.now()),
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Hero Section - Next Prayer
                GlassCard(
                  isDark: isDark,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Next Prayer',
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getPrayerDisplayName(nextPrayerName),
                            style: TextStyle(
                              color: textColor,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (nextPrayerTime != null)
                            Text(
                              DateFormat('h:mm a').format(nextPrayerTime),
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              value: 0.7, // Placeholder for progress if needed
                              strokeWidth: 6,
                              backgroundColor: textColor.withValues(alpha: 0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                accentColor,
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${_timeRemaining.inHours}:${(_timeRemaining.inMinutes % 60).toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Left',
                                style: TextStyle(
                                  color: textColor.withValues(alpha: 0.7),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Location Bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: textColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: textColor.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: textColor.withValues(alpha: 0.7),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _currentCity,
                          style: TextStyle(color: textColor, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_isLocating)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: textColor,
                          ),
                        )
                      else ...[
                        IconButton(
                          icon: Icon(
                            Icons.my_location,
                            color: textColor.withValues(alpha: 0.7),
                            size: 20,
                          ),
                          onPressed: () async {
                            setState(() => _isLocating = true);
                            try {
                              await _getCurrentLocation();
                            } finally {
                              setState(() => _isLocating = false);
                            }
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            Icons.search,
                            color: textColor.withValues(alpha: 0.7),
                            size: 20,
                          ),
                          onPressed: _showCitySearch,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Prayer List
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildPrayerTile(
                        'fajr',
                        nextPrayerName == 'fajr',
                        isDark,
                      ),
                      _buildPrayerTile('sunrise', false, isDark),
                      _buildPrayerTile(
                        'dhuhr',
                        nextPrayerName == 'dhuhr',
                        isDark,
                      ),
                      _buildPrayerTile('asr', nextPrayerName == 'asr', isDark),
                      _buildPrayerTile(
                        'maghrib',
                        nextPrayerName == 'maghrib',
                        isDark,
                      ),
                      _buildPrayerTile(
                        'isha',
                        nextPrayerName == 'isha',
                        isDark,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPrayerTile(String prayer, bool isNext, bool isDark) {
    final time = _prayerTimes[prayer] ?? '--:--';
    final textColor = GlassTheme.text(isDark);
    final accentColor = GlassTheme.accent(isDark);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        isDark: isDark,
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(
              _getPrayerIcon(prayer),
              color: isNext ? accentColor : textColor.withValues(alpha: 0.7),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _getPrayerDisplayName(prayer),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
                  color: isNext ? accentColor : textColor,
                ),
              ),
            ),
            Text(
              time,
              style: TextStyle(
                fontSize: 18,
                fontWeight: isNext ? FontWeight.bold : FontWeight.w600,
                color: isNext ? accentColor : textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
