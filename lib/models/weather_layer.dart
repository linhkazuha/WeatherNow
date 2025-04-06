import 'package:flutter/material.dart';

class WeatherLayer {
  final String name;
  final String value;
  final IconData icon;

  const WeatherLayer({
    required this.name,
    required this.value,
    required this.icon,
  });
}

final List<WeatherLayer> weatherLayers = [
  WeatherLayer(name: 'Nhiệt độ', value: 'temp', icon: Icons.thermostat),
  WeatherLayer(name: 'Lượng mưa', value: 'rain', icon: Icons.water_drop),
  WeatherLayer(name: 'Gió', value: 'wind', icon: Icons.air),
  WeatherLayer(name: 'Mây', value: 'clouds', icon: Icons.cloud),
  WeatherLayer(name: 'Áp suất', value: 'pressure', icon: Icons.speed),
  WeatherLayer(name: 'Độ ẩm', value: 'rh', icon: Icons.water),
  WeatherLayer(name: 'UV', value: 'uvindex', icon: Icons.wb_sunny),
  WeatherLayer(name: 'PM2.5', value: 'pm2p5', icon: Icons.masks),
];
