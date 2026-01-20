import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Centralized location service for the app.
/// Manages GPS location with caching to avoid redundant calls.
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Cached location data
  double? _latitude;
  double? _longitude;
  String? _cityName;
  DateTime? _lastFetched;

  // Default location (Yangon, Myanmar)
  static const double defaultLatitude = 21.4225;
  static const double defaultLongitude = 96.0836;
  static const String defaultCity = 'Yangon, Myanmar';

  // Cache duration - refresh if older than this
  static const Duration cacheValidDuration = Duration(hours: 1);

  /// Check if we have a valid cached location
  bool get hasValidCache {
    if (_latitude == null || _longitude == null) return false;
    if (_lastFetched == null) return false;
    return DateTime.now().difference(_lastFetched!) < cacheValidDuration;
  }

  /// Get current location (uses cache if available, otherwise fetches)
  Future<LocationData> getLocation({bool forceRefresh = false}) async {
    // If we have valid cache and not forcing refresh, return cached
    if (!forceRefresh && hasValidCache) {
      return LocationData(
        latitude: _latitude!,
        longitude: _longitude!,
        cityName: _cityName ?? defaultCity,
        isFromCache: true,
      );
    }

    // Try to fetch fresh location
    try {
      final result = await _fetchFreshLocation();
      return result;
    } catch (e) {
      debugPrint('LocationService: Error fetching location: $e');
      // Return cached or default
      return LocationData(
        latitude: _latitude ?? defaultLatitude,
        longitude: _longitude ?? defaultLongitude,
        cityName: _cityName ?? defaultCity,
        isFromCache: true,
        error: e.toString(),
      );
    }
  }

  /// Force refresh location from GPS
  Future<LocationData> refreshLocation() async {
    return getLocation(forceRefresh: true);
  }

  /// Set location from saved settings (called when app loads)
  void setFromSettings({
    required double? latitude,
    required double? longitude,
    required String? cityName,
  }) {
    if (latitude != null && longitude != null) {
      _latitude = latitude;
      _longitude = longitude;
      _cityName = cityName;
      // Don't update _lastFetched so it can be refreshed if needed
    }
  }

  /// Fetch fresh location from GPS
  Future<LocationData> _fetchFreshLocation() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException('Location services are disabled');
    }

    // Check permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException('Location permission denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationException('Location permissions permanently denied');
    }

    // Get position
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );

    _latitude = position.latitude;
    _longitude = position.longitude;
    _lastFetched = DateTime.now();

    // Try to get city name
    _cityName = await _reverseGeocode(position.latitude, position.longitude);

    return LocationData(
      latitude: _latitude!,
      longitude: _longitude!,
      cityName: _cityName ?? defaultCity,
      isFromCache: false,
    );
  }

  /// Reverse geocode coordinates to city name
  Future<String?> _reverseGeocode(double lat, double lon) async {
    String? foundTown;
    String? foundCountry;

    // Try Nominatim API FIRST - it's more reliable for Myanmar locations
    try {
      debugPrint('LocationService: Trying Nominatim API');
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&addressdetails=1',
        ),
        headers: {'User-Agent': 'MunajatApp/1.0'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('LocationService: Nominatim response: ${response.body}');

        final address = data['address'];
        if (address != null) {
          foundTown =
              address['city'] ??
              address['town'] ??
              address['village'] ??
              address['municipality'] ??
              address['suburb'] ??
              address['county'] ??
              address['state_district'] ??
              address['state'];

          foundCountry = address['country'] ?? '';

          debugPrint(
            'LocationService: Nominatim town=$foundTown, country=$foundCountry',
          );

          if (foundTown != null &&
              foundCountry!.isNotEmpty &&
              foundTown.toLowerCase() != foundCountry.toLowerCase()) {
            return '$foundTown, $foundCountry';
          }
        }
      }
    } catch (e) {
      debugPrint('LocationService: Nominatim API failed: $e');
    }

    // Fallback to geocoding package
    try {
      debugPrint('LocationService: Trying geocoding package fallback');
      final placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        foundCountry = place.country ?? foundCountry;

        debugPrint(
          'LocationService: Placemark - locality=${place.locality}, subLocality=${place.subLocality}, admin=${place.administrativeArea}',
        );

        // Filter candidates - exclude empty and country-matching values
        final countryLower = (foundCountry ?? '').toLowerCase();
        final candidates =
            [place.locality, place.subLocality, place.subAdministrativeArea]
                .where(
                  (s) =>
                      s != null &&
                      s.isNotEmpty &&
                      s.toLowerCase() != countryLower &&
                      s.toLowerCase() != 'myanmar',
                )
                .toList();

        if (candidates.isNotEmpty) {
          foundTown = candidates.first;
        }

        if (foundTown != null &&
            foundCountry != null &&
            foundCountry.isNotEmpty) {
          return '$foundTown, $foundCountry';
        }
      }
    } catch (e) {
      debugPrint('LocationService: geocoding package failed: $e');
    }

    // Return country if we have it
    if (foundCountry != null && foundCountry.isNotEmpty) {
      debugPrint(
        'LocationService: No town found, returning country: $foundCountry',
      );
      return foundCountry;
    }

    // Final fallback to coordinates
    debugPrint('LocationService: Falling back to coordinates');
    return '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';
  }

  /// Check if location services are available
  Future<bool> isLocationAvailable() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      LocationPermission permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      return false;
    }
  }

  /// Calculate distance between two points in kilometers
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Returns distance in meters, convert to km
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }
}

/// Location data result
class LocationData {
  final double latitude;
  final double longitude;
  final String cityName;
  final bool isFromCache;
  final String? error;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.cityName,
    this.isFromCache = false,
    this.error,
  });

  @override
  String toString() =>
      'LocationData($cityName, $latitude, $longitude, cached: $isFromCache)';
}

/// Location exception
class LocationException implements Exception {
  final String message;
  LocationException(this.message);

  @override
  String toString() => message;
}
