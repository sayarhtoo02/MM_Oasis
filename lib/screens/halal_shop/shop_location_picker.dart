import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/config/glass_theme.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_scaffold.dart';

class ShopLocationPicker extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const ShopLocationPicker({super.key, this.initialLat, this.initialLng});

  @override
  State<ShopLocationPicker> createState() => _ShopLocationPickerState();
}

class _ShopLocationPickerState extends State<ShopLocationPicker> {
  final Completer<GoogleMapController> _controller = Completer();
  LatLng? _selectedLocation;
  String _address = '';
  bool _isLoading = true;
  Set<Marker> _markers = {};

  // Default to Yangon, Myanmar
  static const LatLng _defaultLocation = LatLng(16.8661, 96.1951);

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    LatLng initialPosition;

    if (widget.initialLat != null && widget.initialLng != null) {
      initialPosition = LatLng(widget.initialLat!, widget.initialLng!);
    } else {
      // Try to get current location
      try {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          await Geolocator.requestPermission();
        }

        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        initialPosition = LatLng(position.latitude, position.longitude);
      } catch (e) {
        initialPosition = _defaultLocation;
      }
    }

    setState(() {
      _selectedLocation = initialPosition;
      _isLoading = false;
      _updateMarker(initialPosition);
    });

    _getAddressFromLatLng(initialPosition);
  }

  void _updateMarker(LatLng position) {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('selected'),
          position: position,
          draggable: true,
          onDragEnd: (newPosition) {
            _onMapTap(newPosition);
          },
        ),
      };
    });
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _address = [
            place.street,
            place.subLocality,
            place.locality,
            place.administrativeArea,
            place.country,
          ].where((e) => e != null && e.isNotEmpty).join(', ');
        });
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
    }
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _selectedLocation = position;
      _updateMarker(position);
    });
    _getAddressFromLatLng(position);
  }

  void _confirmLocation() {
    if (_selectedLocation != null) {
      Navigator.pop(context, {
        'lat': _selectedLocation!.latitude,
        'lng': _selectedLocation!.longitude,
        'address': _address,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final isDark = settings.isDarkMode;
        final textColor = GlassTheme.text(isDark);
        final accentColor = GlassTheme.accent(isDark);

        return GlassScaffold(
          title: 'Select Shop Location',
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: accentColor))
              : Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _selectedLocation ?? _defaultLocation,
                        zoom: 16,
                      ),
                      onMapCreated: (controller) {
                        _controller.complete(controller);
                      },
                      onTap: _onMapTap,
                      markers: _markers,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      mapType: MapType.normal,
                    ),
                    // Address display at bottom
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 100,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.8)
                              : Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.location_on, color: accentColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _address.isNotEmpty
                                        ? _address
                                        : 'Tap on map to select location',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (_selectedLocation != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, '
                                'Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                                style: TextStyle(
                                  color: textColor.withValues(alpha: 0.6),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    // Confirm button
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 24,
                      child: ElevatedButton(
                        onPressed: _selectedLocation != null
                            ? _confirmLocation
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Confirm Location',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
