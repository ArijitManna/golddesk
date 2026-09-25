import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Resolves the device city for gold-rate lookup (no manual city picker).
class GoldRateLocationService {
  static const _cityCacheKey = 'gold_rate_detected_city';
  static const _cityCachedAtKey = 'gold_rate_detected_city_at';
  static const _cacheTtl = Duration(hours: 12);

  /// Returns a city name when location is available; otherwise null (API uses India).
  Future<String?> detectCity({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await _readCachedCity();
      if (cached != null) return cached;
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 12),
        ),
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) return null;

      final place = placemarks.first;
      final city = _pickCityName(place);
      if (city == null || city.isEmpty) return null;

      await _writeCachedCity(city);
      return city;
    } catch (_) {
      return null;
    }
  }

  String? _pickCityName(Placemark place) {
    for (final candidate in [
      place.locality,
      place.subAdministrativeArea,
      place.administrativeArea,
    ]) {
      final value = candidate?.trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  Future<String?> _readCachedCity() async {
    final prefs = await SharedPreferences.getInstance();
    final city = prefs.getString(_cityCacheKey);
    final cachedAtMs = prefs.getInt(_cityCachedAtKey);
    if (city == null || city.isEmpty || cachedAtMs == null) return null;

    final cachedAt = DateTime.fromMillisecondsSinceEpoch(cachedAtMs);
    if (DateTime.now().difference(cachedAt) > _cacheTtl) return null;
    return city;
  }

  Future<void> _writeCachedCity(String city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cityCacheKey, city);
    await prefs.setInt(_cityCachedAtKey, DateTime.now().millisecondsSinceEpoch);
  }
}
