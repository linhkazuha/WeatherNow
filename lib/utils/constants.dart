import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1E88E5);
  static const Color background = Colors.white;
  static const Color searchBarBackground = Color(0xFFF5F5F5);
  static const Color layerSelectorBackground = Color(0xCC000000);
  static const Color layerSelectorText = Colors.white;
  static const Color activeLayerBackground = Color(0x99FFFFFF);
}

class AppConstants {
  static const double defaultLat = 20.0;
  static const double defaultLon = 105.0;
  static const int defaultZoom = 8;
  static const String defaultLayer = 'temp';
  static const String mapBaseUrl = 'https://embed.windy.com/embed2.html';
}
