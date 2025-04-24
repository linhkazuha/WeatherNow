import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/weather_models.dart';

class WeatherApiService {
  final String apiKey = dotenv.env['OPENWEATHER_API_KEY'] ?? '';

  // Lấy vị trí hiện tại và dữ liệu thời tiết
  Future<WeatherData> getCurrentLocationWeather() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return await getWeatherByCity("Hanoi");
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return await getWeatherByCity("Hanoi");
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return await getWeatherByCity("Hanoi");
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 5),
      );
      return await getWeatherData(position.latitude, position.longitude);
    } catch (e) {
      return await getWeatherByCity("Hanoi");
    }
  }

  // Lấy thời tiết theo tên thành phố
  Future<WeatherData> getWeatherByCity(String cityName) async {
    try {
      final currentWeatherUrl =
          'https://api.openweathermap.org/data/2.5/weather?q=$cityName&units=metric&lang=vi&appid=$apiKey';
      final currentResponse = await http.get(Uri.parse(currentWeatherUrl));

      if (currentResponse.statusCode == 200) {
        final currentData = json.decode(currentResponse.body);

        final lat = currentData['coord']['lat'];
        final lon = currentData['coord']['lon'];

        final forecastUrl =
            'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&units=metric&lang=vi&appid=$apiKey';
        final forecastResponse = await http.get(Uri.parse(forecastUrl));

        final airQualityUrl =
            'https://api.openweathermap.org/data/2.5/air_pollution?lat=$lat&lon=$lon&appid=$apiKey';
        final airQualityResponse = await http.get(Uri.parse(airQualityUrl));

        if (forecastResponse.statusCode == 200) {
          final forecastData = json.decode(forecastResponse.body);

          AirQuality? airQuality;
          if (airQualityResponse.statusCode == 200) {
            final airQualityData = json.decode(airQualityResponse.body);
            airQuality = AirQuality.fromJson(airQualityData);
          }

          // Sử dụng tên thành phố từ API nếu có
          String displayName = cityName;
          if (currentData['name'] != null &&
              currentData['name'].toString().isNotEmpty) {
            displayName = currentData['name'];
          }

          return WeatherData.fromJson(
            currentData,
            forecastData['list'],
            displayName,
            airQuality: airQuality,
          );
        } else {
          throw Exception('Không thể lấy dữ liệu dự báo');
        }
      } else {
        throw Exception('Không tìm thấy thành phố');
      }
    } catch (e) {
      throw Exception('Không thể lấy dữ liệu thời tiết: $e');
    }
  }

  // Lấy thời tiết theo tọa độ
  Future<WeatherData> getWeatherData(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      String cityName =
          placemarks.first.locality ??
          placemarks.first.administrativeArea ??
          placemarks.first.subAdministrativeArea ??
          'Unknown';

      final currentWeatherUrl =
          'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&lang=vi&appid=$apiKey';
      final currentResponse = await http.get(Uri.parse(currentWeatherUrl));

      final forecastUrl =
          'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&units=metric&lang=vi&appid=$apiKey';
      final forecastResponse = await http.get(Uri.parse(forecastUrl));

      final airQualityUrl =
          'https://api.openweathermap.org/data/2.5/air_pollution?lat=$lat&lon=$lon&appid=$apiKey';
      final airQualityResponse = await http.get(Uri.parse(airQualityUrl));

      if (currentResponse.statusCode == 200 &&
          forecastResponse.statusCode == 200) {
        final currentData = json.decode(currentResponse.body);
        final forecastData = json.decode(forecastResponse.body);

        // Sử dụng tên thành phố từ API nếu có
        if (currentData['name'] != null &&
            currentData['name'].toString().isNotEmpty) {
          cityName = currentData['name'];
        }

        AirQuality? airQuality;
        if (airQualityResponse.statusCode == 200) {
          final airQualityData = json.decode(airQualityResponse.body);
          airQuality = AirQuality.fromJson(airQualityData);
        }

        return WeatherData.fromJson(
          currentData,
          forecastData['list'],
          cityName,
          airQuality: airQuality,
        );
      } else {
        throw Exception('Lỗi API');
      }
    } catch (e) {
      throw Exception('Không thể lấy dữ liệu thời tiết: $e');
    }
  }
}
