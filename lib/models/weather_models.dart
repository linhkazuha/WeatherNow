// lib/models/weather_models.dart

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
