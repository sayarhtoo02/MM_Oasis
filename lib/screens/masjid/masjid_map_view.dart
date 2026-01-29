import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/services/masjid_service.dart';
import 'package:munajat_e_maqbool_app/services/masjid_image_service.dart';
import 'package:munajat_e_maqbool_app/screens/masjid/masjid_detail_screen.dart';

class MasjidMapView extends StatefulWidget {
  const MasjidMapView({super.key});

  @override
  State<MasjidMapView> createState() => _MasjidMapViewState();
}

class _MasjidMapViewState extends State<MasjidMapView> {
  final Completer<GoogleMapController> _controller = Completer();
  final MasjidService _masjidService = MasjidService();
  final MasjidImageService _imageService = MasjidImageService();

  List<Map<String, dynamic>> _masjids = [];
  Set<Marker> _markers = {};
  final Map<String, BitmapDescriptor> _customIcons = {};
  bool _isLoading = false; // Changed initial to false as we load on map idle
  LatLng _currentPosition = const LatLng(16.8661, 96.1951); // Default: Yangon
  Timer? _debounceTimer; // For map movement

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  Future<void> _initMap() async {
    await _getCurrentLocation();
    // _loadMasjids() removed. We rely on onCameraIdle or initial position.
    // If we want initial data before map moves, we could fetch radius.
    // But onCameraIdle will trigger once map is created and settled.
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
        // Move camera to user location
        final controller = await _controller.future;
        controller.animateCamera(CameraUpdate.newLatLng(_currentPosition));
      }
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  void _onCameraIdle() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _fetchVisibleMasjids();
    });
  }

  Future<void> _fetchVisibleMasjids() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final controller = await _controller.future;
      final bounds = await controller.getVisibleRegion();

      final masjids = await _masjidService.getMasjidsInBounds(
        south: bounds.southwest.latitude,
        west: bounds.southwest.longitude,
        north: bounds.northeast.latitude,
        east: bounds.northeast.longitude,
      );

      // Enrich with logos
      if (masjids.isNotEmpty) {
        final masjidIds = masjids.map((m) => m['id'] as String).toList();
        final logos = await _imageService.getMasjidImagesForMasjids(
          masjidIds,
          'logo',
        );

        for (final masjid in masjids) {
          masjid['logo_url'] = logos[masjid['id']];
        }
      }

      if (mounted) {
        setState(() {
          _masjids = masjids; // Replace list with visible ones? Or merge?
          // For simple bounds, replacing is fine to avoid memory growth.
          // But cleaning up markers is needed. _buildMarkers rebuilds from _masjids.
          _isLoading = false;
          _buildMarkers();
        });
      }
    } catch (e) {
      debugPrint('Error fetching visible masjids: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _buildMarkers() async {
    final markers = <Marker>{};

    for (final masjid in _masjids) {
      final lat = masjid['lat'] as double?;
      final lng = masjid['long'] as double?;

      if (lat == null || lng == null) continue;

      BitmapDescriptor icon;
      if (_customIcons.containsKey(masjid['id'])) {
        icon = _customIcons[masjid['id']]!;
      } else {
        // Fallback to default while loading
        icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
        _generateMarkerForMasjid(masjid);
      }

      markers.add(
        Marker(
          markerId: MarkerId(masjid['id']),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: masjid['name'] ?? 'Masjid',
            snippet: masjid['address'] ?? '',
            onTap: () => _navigateToMasjid(masjid),
          ),
          icon: icon,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers = markers;
      });
    }
  }

  Future<void> _generateMarkerForMasjid(Map<String, dynamic> masjid) async {
    if (_customIcons.containsKey(masjid['id'])) return;

    try {
      final icon = await _createCustomMarker(
        masjid['logo_url'] as String?,
        masjid['name'] as String? ?? 'Masjid',
      );
      if (mounted) {
        setState(() {
          _customIcons[masjid['id']] = icon;
          _buildMarkers();
        });
      }
    } catch (e) {
      debugPrint('Error generating marker for ${masjid['name']}: $e');
    }
  }

  Future<BitmapDescriptor> _createCustomMarker(
    String? logoUrl,
    String name,
  ) async {
    const double width = 150;
    const double height = 180;
    const double logoBoxSize = 100;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Marker Shape (Dome Style)
    final paint = Paint()
      ..color = Colors.teal.shade700
      ..style = PaintingStyle.fill;

    // Main Circle/Dome
    canvas.drawCircle(
      const Offset(width / 2, logoBoxSize / 2),
      logoBoxSize / 2 + 5,
      paint,
    );

    // Pointy part
    final path = Path()
      ..moveTo(width / 2 - 20, logoBoxSize - 5)
      ..lineTo(width / 2 + 20, logoBoxSize - 5)
      ..lineTo(width / 2, logoBoxSize + 20)
      ..close();
    canvas.drawPath(path, paint);

    // Clip for logo
    canvas.save();
    final clipPath = Path()
      ..addOval(
        Rect.fromCircle(
          center: const Offset(width / 2, logoBoxSize / 2),
          radius: logoBoxSize / 2,
        ),
      );
    canvas.clipPath(clipPath);

    // Draw Logo
    if (logoUrl != null && logoUrl.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(logoUrl));
        final bytes = response.bodyBytes;
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        final image = frame.image;

        paintImage(
          canvas: canvas,
          rect: Rect.fromLTWH(
            (width - logoBoxSize) / 2,
            0,
            logoBoxSize,
            logoBoxSize,
          ),
          image: image,
          fit: BoxFit.cover,
        );
      } catch (e) {
        _drawPlaceholder(canvas, width, logoBoxSize);
      }
    } else {
      _drawPlaceholder(canvas, width, logoBoxSize);
    }
    canvas.restore();

    // Text Label
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 2,
      ellipsis: '...',
    );

    textPainter.text = TextSpan(
      text: name,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        shadows: [Shadow(blurRadius: 4, color: Colors.black)],
      ),
    );

    textPainter.layout(maxWidth: width);

    // Label background
    final labelBgPaint = Paint()..color = Colors.black.withValues(alpha: 0.7);
    final labelRect = Rect.fromLTWH(
      (width - textPainter.width) / 2 - 10,
      logoBoxSize + 25,
      textPainter.width + 20,
      textPainter.height + 10,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, const Radius.circular(10)),
      labelBgPaint,
    );

    textPainter.paint(
      canvas,
      Offset((width - textPainter.width) / 2, logoBoxSize + 30),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  void _drawPlaceholder(Canvas canvas, double width, double logoBoxSize) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = const TextSpan(
      text: '🕌',
      style: TextStyle(fontSize: 60),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (width - textPainter.width) / 2,
        (logoBoxSize - textPainter.height) / 2,
      ),
    );
  }

  void _navigateToMasjid(Map<String, dynamic> masjid) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MasjidDetailScreen(masjidId: masjid['id']),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<SettingsProvider>().isDarkMode;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Nearby Masjids Map'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 14,
            ),
            onMapCreated: (controller) => _controller.complete(controller),
            onCameraIdle: _onCameraIdle, // Add bounds listener
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
            style: isDark ? _darkMapStyle : null,
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),

          // Re-center button
          Positioned(
            right: 16,
            bottom: 32,
            child: FloatingActionButton(
              heroTag: 'recenter_masjid',
              onPressed: () async {
                final controller = await _controller.future;
                controller.animateCamera(
                  CameraUpdate.newLatLng(_currentPosition),
                );
              },
              backgroundColor: Colors.teal.shade700,
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  static const String _darkMapStyle =
      '[{"elementType":"geometry","stylers":[{"color":"#242f3e"}]},{"elementType":"labels.text.stroke","stylers":[{"color":"#242f3e"}]},{"elementType":"labels.text.fill","stylers":[{"color":"#746855"}]},{"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},{"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},{"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#263c3f"}]},{"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#6b9a76"}]},{"featureType":"road","elementType":"geometry","stylers":[{"color":"#38414e"}]},{"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#212a37"}]},{"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#9ca5b3"}]},{"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#746855"}]},{"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#1f2835"}]},{"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#f3d19c"}]},{"featureType":"transit","elementType":"geometry","stylers":[{"color":"#2f3948"}]},{"featureType":"transit.station","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},{"featureType":"water","elementType":"geometry","stylers":[{"color":"#17263c"}]},{"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#515c6d"}]},{"featureType":"water","elementType":"labels.text.stroke","stylers":[{"color":"#17263c"}]}]';
}
