import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/weather_models.dart';

class WeatherService {
  final String apiKey = dotenv.env['OpenWeather_API_key'] ?? '';

  // Cache for weather data
  final Map<String, WeatherPoint> _weatherCache = {};
  final Map<String, LatLng> _locationCache = {};

  // Cache TTL in minutes
  final int _cacheTtlMinutes = 30;
  final Map<String, DateTime> _cacheTimestamps = {};

  Future<WeatherPoint> getWeatherAtPoint(LatLng point) async {
    // Create cache key from coordinates
    final String cacheKey =
        '${point.latitude.toStringAsFixed(4)},${point.longitude.toStringAsFixed(4)}';

    // Check cache before making API call
    if (_isValidCache(cacheKey)) {
      return _weatherCache[cacheKey]!;
    }

    try {
      final response = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?lat=${point.latitude}&lon=${point.longitude}&units=metric&appid=$apiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final weatherPoint = WeatherPoint(
          location: data['name'],
          temperature: data['main']['temp'],
          weather: data['weather'][0]['main'],
          description: data['weather'][0]['description'],
          humidity: data['main']['humidity'],
          windSpeed: data['wind']['speed'],
          pressure: data['main']['pressure'],
          feelsLike: data['main']['feels_like'],
          coordinates: point,
        );

        // Cache the result
        _weatherCache[cacheKey] = weatherPoint;
        _cacheTimestamps[cacheKey] = DateTime.now();

        return weatherPoint;
      } else {
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching weather data: $e');
      throw Exception('Failed to fetch weather data: $e');
    }
  }

  Future<LatLng?> searchLocation(String query) async {
    // Check cache first
    if (_isValidCache(query) && _locationCache.containsKey(query)) {
      return _locationCache[query];
    }

    try {
      final response = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/geo/1.0/direct?q=$query&limit=1&appid=$apiKey',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        if (data.isNotEmpty) {
          final location = data.first;
          final coordinates = LatLng(location['lat'], location['lon']);

          // Cache the result
          _locationCache[query] = coordinates;
          _cacheTimestamps[query] = DateTime.now();

          return coordinates;
        } else {
          return null; // No results found
        }
      } else {
        throw Exception('Failed to search location: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error searching location: $e');
      throw Exception('Failed to search location: $e');
    }
  }

  /// Check if cache entry is valid (not expired)
  bool _isValidCache(String key) {
    if (!_cacheTimestamps.containsKey(key)) return false;

    final cacheTime = _cacheTimestamps[key]!;
    final now = DateTime.now();
    final difference = now.difference(cacheTime).inMinutes;

    return difference < _cacheTtlMinutes;
  }

  /// Clear expired cache entries
  void cleanCache() {
    final now = DateTime.now();
    final keysToRemove = <String>[];

    _cacheTimestamps.forEach((key, timestamp) {
      final difference = now.difference(timestamp).inMinutes;
      if (difference >= _cacheTtlMinutes) {
        keysToRemove.add(key);
      }
    });

    for (final key in keysToRemove) {
      _cacheTimestamps.remove(key);
      _weatherCache.remove(key);
      _locationCache.remove(key);
    }
  }

  /// Get forecast data for a specific location
  Future<List<WeatherPoint>> getForecast(LatLng point, {int hours = 24}) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?lat=${point.latitude}&lon=${point.longitude}&units=metric&appid=$apiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> forecastList = data['list'];
        final String locationName = data['city']['name'];

        // Limit to requested number of forecast points
        final limitedList = forecastList.take(hours ~/ 3).toList();

        return limitedList
            .map(
              (item) => WeatherPoint(
                location: locationName,
                temperature: item['main']['temp'],
                weather: item['weather'][0]['main'],
                description: item['weather'][0]['description'],
                humidity: item['main']['humidity'],
                windSpeed: item['wind']['speed'],
                pressure: item['main']['pressure'],
                feelsLike: item['main']['feels_like'],
                coordinates: point,
              ),
            )
            .toList();
      } else {
        throw Exception('Failed to load forecast data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching forecast data: $e');
      throw Exception('Failed to fetch forecast data: $e');
    }
  }
}
