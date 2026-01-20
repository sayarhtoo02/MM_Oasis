import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:munajat_e_maqbool_app/config/glass_theme.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/services/shop_service.dart';
import 'package:munajat_e_maqbool_app/services/shop_image_service.dart';
import 'package:munajat_e_maqbool_app/screens/halal_shop/shop_detail_screen.dart';

class ShopMapView extends StatefulWidget {
  const ShopMapView({super.key});

  @override
  State<ShopMapView> createState() => _ShopMapViewState();
}

class _ShopMapViewState extends State<ShopMapView> {
  final Completer<GoogleMapController> _controller = Completer();
  final ShopService _shopService = ShopService();
  final ShopImageService _imageService = ShopImageService();

  List<Map<String, dynamic>> _shops = [];
  Set<Marker> _markers = {};
  Map<String, BitmapDescriptor> _customIcons = {};
  bool _isLoading = true;
  LatLng _currentPosition = const LatLng(16.8661, 96.1951); // Default: Yangon

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  Future<void> _initMap() async {
    await _getCurrentLocation();
    await _loadShops();
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
      }
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  Future<void> _loadShops() async {
    setState(() => _isLoading = true);

    try {
      final shops = await _shopService.getShops();

      // Enrich with logos
      if (shops.isNotEmpty) {
        final shopIds = shops.map((s) => s['id'] as String).toList();
        final logos = await _imageService.getShopImagesForShops(
          shopIds,
          'logo',
        );

        for (final shop in shops) {
          shop['logo_url'] = logos[shop['id']];
        }
      }

      if (mounted) {
        setState(() {
          _shops = shops;
          _isLoading = false;
          _buildMarkers();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _buildMarkers() async {
    final isDark = context.read<SettingsProvider>().isDarkMode;
    final markers = <Marker>{};

    for (final shop in _shops) {
      final lat = shop['lat'] as double?;
      final lng = shop['long'] as double?;

      if (lat == null || lng == null) continue;

      BitmapDescriptor icon;
      if (_customIcons.containsKey(shop['id'])) {
        icon = _customIcons[shop['id']]!;
      } else {
        // Fallback to default while loading or if generation fails
        icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
        // Trigger background generation
        _generateMarkersForShops();
      }

      markers.add(
        Marker(
          markerId: MarkerId(shop['id']),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: shop['name'] ?? 'Shop',
            snippet: shop['address'] ?? '',
            onTap: () => _navigateToShop(shop),
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

  Future<void> _generateMarkersForShops() async {
    for (final shop in _shops) {
      if (_customIcons.containsKey(shop['id'])) continue;

      try {
        final icon = await _createCustomMarker(
          shop['logo_url'] as String?,
          shop['name'] as String? ?? 'Shop',
          shop['is_pro'] == true,
        );
        if (mounted) {
          setState(() {
            _customIcons[shop['id']] = icon;
            // Rebuild markers with the new icon
            _buildMarkers();
          });
        }
      } catch (e) {
        debugPrint('Error generating marker for ${shop['name']}: $e');
      }
    }
  }

  Future<BitmapDescriptor> _createCustomMarker(
    String? logoUrl,
    String name,
    bool isPro,
  ) async {
    const double width = 150;
    const double height = 180;
    const double logoBoxSize = 100;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Marker Shape (Pin)
    final paint = Paint()
      ..color = isPro ? const Color(0xFFFFD700) : Colors.green
      ..style = PaintingStyle.fill;

    // Draw the main circle for logo
    canvas.drawCircle(
      const Offset(width / 2, logoBoxSize / 2),
      logoBoxSize / 2 + 5,
      paint,
    );

    // Draw the pointy part
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
        // Fallback logo if fetch fails
        _drawPlaceholder(canvas, width, logoBoxSize);
      }
    } else {
      _drawPlaceholder(canvas, width, logoBoxSize);
    }
    canvas.restore();

    // Draw Shop Name Label
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
    final paint = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(width / 2, logoBoxSize / 2),
      logoBoxSize / 2,
      paint,
    );
    final textPainter = TextPainter(
      text: const TextSpan(text: '🏪', style: TextStyle(fontSize: 50)),
      textDirection: TextDirection.ltr,
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

  void _navigateToShop(Map<String, dynamic> shop) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShopDetailScreen(shopId: shop['id']),
      ),
    );
  }

  Future<void> _goToCurrentLocation() async {
    final controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(_currentPosition, 14));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final isDark = settings.isDarkMode;
        final textColor = GlassTheme.text(isDark);
        final accentColor = GlassTheme.accent(isDark);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Nearby Halal Shops',
              style: TextStyle(color: textColor),
            ),
            backgroundColor: isDark ? Colors.black87 : Colors.white,
            iconTheme: IconThemeData(color: textColor),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadShops,
              ),
            ],
          ),
          body: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentPosition,
                  zoom: 13,
                ),
                onMapCreated: (controller) {
                  _controller.complete(controller);
                },
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapType: MapType.normal,
              ),
              if (_isLoading)
                Container(
                  color: Colors.black26,
                  child: Center(
                    child: CircularProgressIndicator(color: accentColor),
                  ),
                ),
              // Shop count badge
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black87 : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.storefront, color: accentColor, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '${_shops.length} shops',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _goToCurrentLocation,
            backgroundColor: accentColor,
            child: Icon(
              Icons.my_location,
              color: isDark ? Colors.black : Colors.white,
            ),
          ),
        );
      },
    );
  }
}
