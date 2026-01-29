import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/config/glass_theme.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_scaffold.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_card.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_app_bar.dart';
import 'package:munajat_e_maqbool_app/services/location_service.dart';

class QiblaFinderScreen extends StatefulWidget {
  const QiblaFinderScreen({super.key});

  @override
  State<QiblaFinderScreen> createState() => _QiblaFinderScreenState();
}

class _QiblaFinderScreenState extends State<QiblaFinderScreen>
    with SingleTickerProviderStateMixin {
  final _locationStreamController =
      StreamController<LocationStatus>.broadcast();

  Stream<LocationStatus> get stream => _locationStreamController.stream;

  late AnimationController _animationController;
  final LocationService _locationService = LocationService();

  String _locationText = 'Loading...';
  bool _isRefreshing = false;
  bool _usedSavedLocation = false;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat();

    // Load saved location first (instant), then check GPS
    _loadSavedLocation();
    _checkLocationStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _locationStreamController.close();
    super.dispose();
  }

  /// Load saved location from SettingsProvider for instant startup
  void _loadSavedLocation() {
    final settings = Provider.of<SettingsProvider>(
      context,
      listen: false,
    ).appSettings;

    final savedLat = settings.prayerLatitude;
    final savedLon = settings.prayerLongitude;
    final savedCity = settings.prayerCity;

    if (savedLat != null && savedLon != null) {
      // Initialize LocationService with saved data
      _locationService.setFromSettings(
        latitude: savedLat,
        longitude: savedLon,
        cityName: savedCity,
      );

      setState(() {
        _latitude = savedLat;
        _longitude = savedLon;
        _locationText =
            savedCity ??
            '${savedLat.toStringAsFixed(4)}, ${savedLon.toStringAsFixed(4)}';

        // If the saved location is the default one (Yangon), treat it as NOT used
        // so that we force a GPS refresh.
        if (savedCity == 'Yangon, Myanmar') {
          _usedSavedLocation = false;
        } else {
          _usedSavedLocation = true;
        }
      });
    }
  }

  Future<void> _checkLocationStatus() async {
    final locationStatus = await FlutterQiblah.checkLocationStatus();
    if (locationStatus.enabled &&
        locationStatus.status == LocationPermission.denied) {
      await FlutterQiblah.requestPermissions();
      final s = await FlutterQiblah.checkLocationStatus();
      _locationStreamController.sink.add(s);
    } else {
      _locationStreamController.sink.add(locationStatus);
    }

    // Only fetch GPS if we don't have saved location
    if (!_usedSavedLocation &&
        locationStatus.enabled &&
        (locationStatus.status == LocationPermission.always ||
            locationStatus.status == LocationPermission.whileInUse)) {
      _refreshLocation();
    }
  }

  /// Refresh location using GPS (can be called manually)
  Future<void> _refreshLocation() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final locationData = await _locationService.refreshLocation();

      if (mounted) {
        setState(() {
          _latitude = locationData.latitude;
          _longitude = locationData.longitude;
          _locationText = locationData.cityName;
          _isRefreshing = false;
        });

        // Save to settings for next time
        _saveLocationToSettings(locationData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location updated: ${locationData.cityName}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Location error: $e')));
      }
    }
  }

  /// Save location to SettingsProvider for persistence
  void _saveLocationToSettings(LocationData locationData) {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    settingsProvider.updateSettings(
      settingsProvider.appSettings.copyWith(
        prayerLatitude: locationData.latitude,
        prayerLongitude: locationData.longitude,
        prayerCity: locationData.cityName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      body: SafeArea(
        child: Column(
          children: [
            GlassAppBar(
              title: "Qibla Finder",
              isDark: context
                  .watch<SettingsProvider>()
                  .isDarkMode, // Use theme setting
              actions: [
                // Location Refresh Action
                Consumer<SettingsProvider>(
                  builder: (context, settings, child) {
                    final isDark = settings.isDarkMode; // Use theme setting
                    final accentColor = GlassTheme.accent(isDark);
                    final textColor = GlassTheme.text(isDark);

                    return GlassCard(
                      isDark: isDark,
                      borderRadius: 20,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, color: accentColor, size: 14),
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 150),
                            child: Text(
                              _locationText,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_isRefreshing)
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: accentColor,
                              ),
                            )
                          else
                            InkWell(
                              onTap: _refreshLocation,
                              child: Icon(
                                Icons.refresh,
                                color: textColor.withValues(alpha: 0.7),
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
              ],
            ),
            Expanded(
              child: StreamBuilder<LocationStatus>(
                stream: stream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingState();
                  }

                  if (snapshot.hasData) {
                    final locationStatus = snapshot.data!;

                    if (locationStatus.enabled == true) {
                      switch (locationStatus.status) {
                        case LocationPermission.always:
                        case LocationPermission.whileInUse:
                          return _buildQiblaCompass();

                        case LocationPermission.denied:
                        case LocationPermission.deniedForever:
                          return _buildPermissionDeniedState();

                        default:
                          return _buildPermissionDeniedState();
                      }
                    } else {
                      return _buildLocationDisabledState();
                    }
                  }

                  return _buildLoadingState();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateQiblaBearing(double lat, double lon) {
    if (lat == 0 && lon == 0) return 0;

    // Kaaba coordinates
    const kaabaLat = 21.422487;
    const kaabaLon = 39.826206;

    final phiK = kaabaLat * math.pi / 180.0;
    final lambdaK = kaabaLon * math.pi / 180.0;
    final phi = lat * math.pi / 180.0;
    final lambda = lon * math.pi / 180.0;

    final psi =
        180.0 /
        math.pi *
        math.atan2(
          math.sin(lambdaK - lambda),
          math.cos(phi) * math.tan(phiK) -
              math.sin(phi) * math.cos(lambdaK - lambda),
        );

    return psi;
  }

  // _buildAppBar removed as it is replaced by GlassAppBar

  Widget _buildQiblaCompass() {
    return StreamBuilder<QiblahDirection>(
      stream: FlutterQiblah.qiblahStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        if (snapshot.hasData) {
          final qiblahDirection = snapshot.data!;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildCompassWidget(qiblahDirection),
                const SizedBox(height: 24),
                _buildCalibrationHint(),
              ],
            ),
          );
        }

        return _buildLoadingState();
      },
    );
  }

  Widget _buildCompassWidget(QiblahDirection qiblahDirection) {
    // 1. Get manually calculated Qibla bearing (Static target angle from North)
    double qiblaBearing = 0;
    if (_latitude != null && _longitude != null) {
      qiblaBearing = _calculateQiblaBearing(_latitude!, _longitude!);
    } else {
      // Fallback to library value if position not yet available
      qiblaBearing = qiblahDirection.qiblah;
    }

    // 2. Get device Heading (Direction phone is pointing relative to North)
    final heading = qiblahDirection.direction;

    // 3. Calculate dynamic needle angle
    // If bearing is 283° (Qibla) and heading is 0° (North), needle should point to 283°
    // The needle rotation is relative to the dial (which is already rotated by -heading)
    // So we need the absolute difference

    // Angle from North to Qibla
    final qiblaAngle = qiblaBearing;

    // Angle difference between where phone points and Qibla
    // Example: Phone points North (0°), Qibla is West (270°).
    // Diff should be -90 or 270.
    double diff = qiblaAngle - heading;

    // Normalize to -180 to 180
    final normalizedDiff = (diff + 180) % 360 - 180;
    final offset = normalizedDiff.abs();

    // 4. Color Logic with precise Yellow range
    // 0-5°: Green (Perfect)
    // 5-30°: Gradient from Green -> Yellow -> Red
    // >30°: Red (Far)
    Color needleColor;
    if (offset < 5) {
      needleColor = const Color(0xFF00E676); // Bright Green
    } else if (offset > 30) {
      needleColor = const Color(0xFFFF1744); // Bright Red
    } else {
      // Transition range: 5° to 30°
      final t = (offset - 5) / (30 - 5);
      if (t < 0.5) {
        // First half: Green to Yellow
        needleColor = Color.lerp(
          const Color(0xFF00E676),
          const Color(0xFFFFC107), // Amber/Yellow
          t * 2,
        )!;
      } else {
        // Second half: Yellow to Red
        needleColor = Color.lerp(
          const Color(0xFFFFC107),
          const Color(0xFFFF1744),
          (t - 0.5) * 2,
        )!;
      }
    }

    final isAligned = offset < 5.0;

    return Column(
      children: [
        // Islamic decorative header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF004D40).withValues(alpha: 0.8), // Emerald
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFFFD700), // Gold
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Image.asset(
            'assets/icons/icon_qibla.png',
            width: 40,
            height: 40,
          ),
        ),
        const SizedBox(height: 32),

        // Main Islamic Compass
        Container(
          width: 320,
          height: 320,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFFFFD700,
                ).withValues(alpha: 0.15), // Gold glow
                blurRadius: 60,
                spreadRadius: 10,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer gold ring
              Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFD700), // Gold
                      Color(0xFFB8860B), // Dark Gold
                      Color(0xFFFFD700), // Gold
                    ],
                  ),
                  border: Border.all(width: 1, color: const Color(0x44000000)),
                ),
              ),

              // Inner dark emerald background
              Container(
                width: 300,
                height: 300,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF00251A), // Deepest Emerald
                ),
              ),

              // Rotating Dial (Rub el Hizb pattern + Ticks)
              Transform.rotate(
                angle: (heading * (math.pi / 180) * -1),
                child: CustomPaint(
                  size: const Size(280, 280),
                  painter: IslamicCompassDialPainter(),
                ),
              ),

              // Rotating Needle (Minaret shape)
              Transform.rotate(
                angle: (normalizedDiff * (math.pi / 180)),
                child: CustomPaint(
                  size: const Size(260, 260),
                  painter: IslamicNeedlePainter(needleColor: needleColor),
                ),
              ),

              // Center Pivot (Gold centerpiece)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFFFFECB3),
                      Color(0xFFFFD700),
                      Color(0xFFB8860B),
                    ],
                    stops: [0.2, 0.5, 1.0],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF004D40), // Emerald dot center
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Debug & Info Card (Styled)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF00251A).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFFD700).withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Mecca Bearing: ${qiblaBearing.toStringAsFixed(1)}°',
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: 'Serif', // Adds a classic feel
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Heading: ${heading.toStringAsFixed(1)}°',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                  Container(
                    height: 12,
                    width: 1,
                    color: Colors.white24,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  Text(
                    'Diff: ${offset.toStringAsFixed(1)}°',
                    style: TextStyle(
                      color: isAligned
                          ? const Color(0xFF00E676)
                          : const Color(0xFFFF1744),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // "You're facing Mecca" Indicator
        AnimatedOpacity(
          opacity: isAligned ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF004D40), Color(0xFF00695C)],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: const Color(0xFFFFD700), // Gold border
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E676).withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFFFFD700),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  "Facing Mecca",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Serif',
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalibrationHint() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFFFD700), // Gold
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            'Move device in figure-8 for accuracy',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RotationTransition(
            turns: _animationController,
            child: const Icon(
              Icons.explore_rounded,
              color: Color(0xFFE0B40A),
              size: 64,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Finding Qibla direction...',

            style: TextStyle(
              fontSize: 16,
              color: GlassTheme.text(
                Provider.of<SettingsProvider>(context).isDarkMode,
              ),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationDisabledState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_off_rounded,
                size: 64,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Location Service Disabled',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: GlassTheme.text(
                  Provider.of<SettingsProvider>(context).isDarkMode,
                ),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Please enable location services to find the Qibla direction',
              style: TextStyle(
                fontSize: 15,
                color: GlassTheme.text(
                  Provider.of<SettingsProvider>(context).isDarkMode,
                ).withValues(alpha: 0.8),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                await Geolocator.openLocationSettings();
                _checkLocationStatus();
              },
              icon: const Icon(Icons.settings_rounded),
              label: const Text('Open Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE0B40A),
                foregroundColor: const Color(0xFF0D3B2E),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_disabled_rounded,
                size: 64,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Location Permission Required',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: GlassTheme.text(
                  Provider.of<SettingsProvider>(context).isDarkMode,
                ),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'We need your location to calculate the direction to Mecca',
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.8),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                await FlutterQiblah.requestPermissions();
                _checkLocationStatus();
              },
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text('Grant Permission'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE0B40A),
                foregroundColor: const Color(0xFF0D3B2E),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            const Text(
              'Error',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              error,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.8),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ISLAMIC COMPASS PAINTERS
// -----------------------------------------------------------------------------

class IslamicCompassDialPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paintCode = Paint()..style = PaintingStyle.stroke;

    // 1. Draw Rub el Hizb (8-pointed star) Background
    // Two squares rotated 45 degrees
    final starPaint = Paint()
      ..color = const Color(0xFFFFD700)
          .withValues(alpha: 0.1) // Faint Gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final squareRadius = radius * 0.75;

    // Square 1
    canvas.drawRect(
      Rect.fromCenter(
        center: center,
        width: squareRadius * 1.8,
        height: squareRadius * 1.8,
      ),
      starPaint,
    );

    // Square 2 (Rotated)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(45 * math.pi / 180);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset.zero,
        width: squareRadius * 1.8,
        height: squareRadius * 1.8,
      ),
      starPaint,
    );
    canvas.restore();

    // 2. Ticks
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int i = 0; i < 360; i += 5) {
      final angle = (i - 90) * math.pi / 180;
      final isCardinal = i % 90 == 0;
      final isMainTick = i % 30 == 0;

      double innerR = radius - 15;
      double outerR = radius;
      Color tickColor = const Color(0xFF80CBC4); // Light Teal
      double strokeW = 1;

      if (isCardinal) {
        innerR = radius - 25;
        tickColor = const Color(0xFFFFD700); // Gold
        strokeW = 3;
      } else if (isMainTick) {
        innerR = radius - 20;
        tickColor = Colors.white70;
        strokeW = 2;
      }

      final p1 = Offset(
        center.dx + innerR * math.cos(angle),
        center.dy + innerR * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + outerR * math.cos(angle),
        center.dy + outerR * math.sin(angle),
      );

      paintCode
        ..color = tickColor
        ..strokeWidth = strokeW;

      canvas.drawLine(p1, p2, paintCode);

      // Draw Degree Numbers for main ticks (excluding cardinals)
      if (isMainTick && !isCardinal) {
        final textRadius = radius - 35;
        final tx = center.dx + textRadius * math.cos(angle);
        final ty = center.dy + textRadius * math.sin(angle);

        textPainter.text = TextSpan(
          text: '$i',
          style: const TextStyle(
            color: Color(0xFFB2DFDB), // Pale Teal
            fontSize: 10,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(tx - textPainter.width / 2, ty - textPainter.height / 2),
        );
      }
    }

    // 3. Cardinal Directions
    final cardinals = ['N', 'E', 'S', 'W'];
    for (int i = 0; i < 4; i++) {
      final angle = (i * 90 - 90) * math.pi / 180;
      final textRadius = radius - 55;
      final tx = center.dx + textRadius * math.cos(angle);
      final ty = center.dy + textRadius * math.sin(angle);

      textPainter.text = TextSpan(
        text: cardinals[i],
        style: TextStyle(
          color: i == 0
              ? const Color(0xFFFF1744)
              : const Color(0xFFFFD700), // North is Red, others Gold
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: 'Serif',
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(tx - textPainter.width / 2, ty - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class IslamicNeedlePainter extends CustomPainter {
  final Color needleColor;

  IslamicNeedlePainter({required this.needleColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final length = size.height / 2 - 40;

    // Ornate "Minaret" Needle Shape
    final path = Path();

    // Top Tip (sharp)
    path.moveTo(center.dx, center.dy - length);

    // Right side curves
    path.cubicTo(
      center.dx + 15,
      center.dy - length * 0.6, // Control point 1
      center.dx + 5,
      center.dy - length * 0.4, // Control point 2
      center.dx + 12,
      center.dy, // Center right
    );

    // Bottom tail (counterweight)
    path.lineTo(center.dx + 8, center.dy + 30);
    path.lineTo(center.dx, center.dy + 45); // Tail tip
    path.lineTo(center.dx - 8, center.dy + 30);

    // Left side curves
    path.lineTo(center.dx - 12, center.dy);
    path.cubicTo(
      center.dx - 5,
      center.dy - length * 0.4,
      center.dx - 15,
      center.dy - length * 0.6,
      center.dx,
      center.dy - length,
    );

    path.close();

    // 1. Fill with dynamic color
    final fillPaint = Paint()
      ..color = needleColor
      ..style = PaintingStyle.fill;

    // Add glow/shadow
    canvas.drawShadow(path, needleColor.withValues(alpha: 0.5), 8, true);
    canvas.drawPath(path, fillPaint);

    // 2. Gold Border
    final borderPaint = Paint()
      ..color =
          const Color(0xFFFFD700) // Gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, borderPaint);

    // 3. Inner details (Decorative line)
    final detailPath = Path();
    detailPath.moveTo(center.dx, center.dy - length + 15);
    detailPath.lineTo(center.dx, center.dy + 35);

    final detailPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(detailPath, detailPaint);
  }

  @override
  bool shouldRepaint(covariant IslamicNeedlePainter oldDelegate) =>
      oldDelegate.needleColor != needleColor;
}
