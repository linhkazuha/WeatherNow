import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class MapLayer {
  final String id;
  final String name;
  final Color color;
  final Map<int, Color> colorMap;

  const MapLayer(this.id, this.name, this.color, [this.colorMap = const {}]);
}

class WeatherPoint {
  final String location;
  final double temperature;
  final String weather;
  final String description;
  final int humidity;
  final double windSpeed;
  final int pressure;
  final double feelsLike;
  final LatLng coordinates;

  const WeatherPoint({
    required this.location,
    required this.temperature,
    required this.weather,
    required this.description,
    required this.humidity,
    required this.windSpeed,
    required this.pressure,
    required this.feelsLike,
    required this.coordinates,
  });
}

// Thêm các model mới từ home_screen.dart
class AirQuality {
  final int aqi;
  final Map<String, double> components;

  AirQuality({required this.aqi, required this.components});

  factory AirQuality.fromJson(Map<String, dynamic> json) {
    final list = json['list'][0];

    return AirQuality(
      aqi: list['main']['aqi'],
      components: {
        'co': list['components']['co'].toDouble(),
        'no2': list['components']['no2'].toDouble(),
        'o3': list['components']['o3'].toDouble(),
        'pm2_5': list['components']['pm2_5'].toDouble(),
        'pm10': list['components']['pm10'].toDouble(),
      },
    );
  }

  String get aqiDescription {
    switch (aqi) {
      case 1:
        return 'Tốt';
      case 2:
        return 'Trung bình';
      case 3:
        return 'Kém';
      case 4:
        return 'Xấu';
      case 5:
        return 'Rất xấu';
      default:
        return 'Không xác định';
    }
  }

  Color get aqiColor {
    switch (aqi) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.yellow;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      case 5:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

class WeatherData {
  final String cityName;
  final double temp;
  final double tempMin;
  final double tempMax;
  final String description;
  final String icon;
  final int humidity;
  final double windSpeed;
  final int pressure;
  final int visibility;
  final double feelsLike;
  final DateTime? sunrise;
  final DateTime? sunset;
  final List<HourlyForecast> hourlyForecast;
  final List<DailyForecast> dailyForecast;
  final AirQuality? airQuality;

  WeatherData({
    required this.cityName,
    required this.temp,
    required this.tempMin,
    required this.tempMax,
    required this.description,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
    required this.pressure,
    required this.visibility,
    required this.feelsLike,
    this.sunrise,
    this.sunset,
    required this.hourlyForecast,
    required this.dailyForecast,
    this.airQuality,
  });

  factory WeatherData.fromJson(
    Map<String, dynamic> current,
    List<dynamic> forecast,
    String cityName, {
    AirQuality? airQuality,
  }) {
    final currentWeather = current['weather'][0];

    DateTime? sunrise;
    DateTime? sunset;

    if (current['sys'] != null) {
      if (current['sys']['sunrise'] != null) {
        sunrise = DateTime.fromMillisecondsSinceEpoch(
          current['sys']['sunrise'] * 1000,
        );
      }
      if (current['sys']['sunset'] != null) {
        sunset = DateTime.fromMillisecondsSinceEpoch(
          current['sys']['sunset'] * 1000,
        );
      }
    }

    List<HourlyForecast> hourlyList = [];
    final now = DateTime.now();

    for (var i = 0; i < forecast.length && hourlyList.length < 24; i++) {
      final item = forecast[i];
      final forecastTime = DateTime.fromMillisecondsSinceEpoch(
        item['dt'] * 1000,
      );

      if (forecastTime.isAfter(now)) {
        hourlyList.add(
          HourlyForecast(
            time: forecastTime,
            temp: item['main']['temp'].toDouble(),
            icon: item['weather'][0]['icon'],
          ),
        );
      }
    }

    List<DailyForecast> dailyList = [];
    Map<String, DailyForecast> dailyMap = {};

    for (var item in forecast) {
      final DateTime forecastTime = DateTime.fromMillisecondsSinceEpoch(
        item['dt'] * 1000,
      );
      final String dateKey =
          '${forecastTime.year}-${forecastTime.month}-${forecastTime.day}';

      if (!dailyMap.containsKey(dateKey)) {
        dailyMap[dateKey] = DailyForecast(
          date: DateTime(
            forecastTime.year,
            forecastTime.month,
            forecastTime.day,
          ),
          tempMax: item['main']['temp_max'].toDouble(),
          tempMin: item['main']['temp_min'].toDouble(),
          icon: item['weather'][0]['icon'],
        );
      } else {
        final existing = dailyMap[dateKey]!;
        if (item['main']['temp_max'].toDouble() > existing.tempMax) {
          dailyMap[dateKey] = DailyForecast(
            date: existing.date,
            tempMax: item['main']['temp_max'].toDouble(),
            tempMin: existing.tempMin,
            icon: existing.icon,
          );
        }
        if (item['main']['temp_min'].toDouble() < existing.tempMin) {
          dailyMap[dateKey] = DailyForecast(
            date: existing.date,
            tempMax: existing.tempMax,
            tempMin: item['main']['temp_min'].toDouble(),
            icon: existing.icon,
          );
        }
      }
    }

    dailyList = dailyMap.values.toList();
    dailyList.sort((a, b) => a.date.compareTo(b.date));

    if (dailyList.length > 7) {
      dailyList = dailyList.sublist(0, 7);
    }

    return WeatherData(
      cityName: cityName,
      temp: current['main']['temp'].toDouble(),
      tempMin: current['main']['temp_min'].toDouble(),
      tempMax: current['main']['temp_max'].toDouble(),
      description: currentWeather['description'],
      icon: currentWeather['icon'],
      humidity: current['main']['humidity'],
      windSpeed: current['wind']['speed'].toDouble(),
      pressure: current['main']['pressure'],
      visibility: current['visibility'] ?? 0,
      feelsLike: current['main']['feels_like'].toDouble(),
      sunrise: sunrise,
      sunset: sunset,
      hourlyForecast: hourlyList,
      dailyForecast: dailyList,
      airQuality: airQuality,
    );
  }
}

class HourlyForecast {
  final DateTime time;
  final double temp;
  final String icon;

  HourlyForecast({required this.time, required this.temp, required this.icon});
}

class DailyForecast {
  final DateTime date;
  final double tempMax;
  final double tempMin;
  final String icon;

  DailyForecast({
    required this.date,
    required this.tempMax,
    required this.tempMin,
    required this.icon,
  });
}
