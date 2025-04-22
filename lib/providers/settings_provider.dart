import 'package:flutter/material.dart';

class SettingsProvider with ChangeNotifier {
  // Đơn vị
  String _temperatureUnit = 'C'; // Celsius
  String _windSpeedUnit = 'km/h'; // Kilometers per hour
  String _pressureUnit = 'hPa'; // Millibar
  String _distanceUnit = 'km'; // Kilometers

  // Cài đặt khác
  bool _isWidgetEnabled = true;

  bool _isNotificationEnabled = true;

  // Getters
  String get temperatureUnit => _temperatureUnit;
  String get windSpeedUnit => _windSpeedUnit;
  String get pressureUnit => _pressureUnit;
  String get distanceUnit => _distanceUnit;

  bool get isWidgetEnabled => _isWidgetEnabled;
  bool get isNotificationEnabled => _isNotificationEnabled;

  // Setters
  void setTemperatureUnit(String unit) {
    _temperatureUnit = unit;
    notifyListeners();
  }

  void setWindSpeedUnit(String unit) {
    _windSpeedUnit = unit;
    notifyListeners();
  }

  void setPressureUnit(String unit) {
    _pressureUnit = unit;
    notifyListeners();
  }

  void setDistanceUnit(String unit) {
    _distanceUnit = unit;
    notifyListeners();
  }

  void setWidgetEnabled(bool isEnabled) {
    _isWidgetEnabled = isEnabled;
    notifyListeners();
  }

  void setNotificationEnabled(bool isEnabled) {
    _isNotificationEnabled = isEnabled;
    notifyListeners();
  }

  // Khôi phục cài đặt mặc định
  void resetToDefault() {
    _temperatureUnit = 'C';
    _windSpeedUnit = 'km/h';
    _pressureUnit = 'hPa';
    _distanceUnit = 'km';
    _isWidgetEnabled = true;
    _isNotificationEnabled = true;
    notifyListeners();
  }
}
