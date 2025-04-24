import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'air_quality_model.dart';

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
  final double uvIndex;
  final double dewPoint;
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
    this.uvIndex = 0.0, 
    this.dewPoint = 0.0,   
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
    // Trong phương thức fromJson, thêm phần lấy dữ liệu UV từ JSON
    double uvIndex = 0.0;
    if (current['uvi'] != null) {
      uvIndex = current['uvi'].toDouble();
    }

    // Tính điểm sương từ nhiệt độ và độ ẩm nếu không có trực tiếp từ API
    double dewPoint = 0.0;
    if (current['main']['dew_point'] != null) {
      dewPoint = current['main']['dew_point'].toDouble();
    } else {
      // Công thức gần đúng tính điểm sương
      final temp = current['main']['temp'].toDouble();
      final humidity = current['main']['humidity'].toInt();
      dewPoint = temp - ((100 - humidity) / 5);
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
      uvIndex: uvIndex,    
      dewPoint: dewPoint, 
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
