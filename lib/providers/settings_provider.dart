import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  // Đơn vị
  String _temperatureUnit = 'C'; // Celsius
  String _windSpeedUnit = 'm/s'; // metre/sec
  String _pressureUnit = 'hPa'; // Millibar
  String _distanceUnit = 'm'; // metres

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
  Future<void> setTemperatureUnit(String unit) async {
    _temperatureUnit = unit;
    notifyListeners();

    // Lưu đơn vị nhiệt độ vào SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('temperatureUnit', unit);
  }

  Future<void> loadTemperatureUnit() async {
    final prefs = await SharedPreferences.getInstance();
    _temperatureUnit =
        prefs.getString('temperatureUnit') ?? 'C'; // Mặc định là 'C'
    notifyListeners();
  }

  Future<void> setWindSpeedUnit(String unit) async {
    _windSpeedUnit = unit;
    notifyListeners();

    // Lưu đơn vị tốc độ gió vào SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('windSpeedUnit', unit);
  }

  Future<void> loadWindSpeedUnit() async {
    final prefs = await SharedPreferences.getInstance();
    _windSpeedUnit =
        prefs.getString('windSpeedUnit') ?? 'm/s'; // Mặc định là 'm/s'
    notifyListeners();
  }

  Future<void> setPressureUnit(String unit) async {
    _pressureUnit = unit;
    notifyListeners();

    // Lưu đơn vị áp suất vào SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pressureUnit', unit);
  }

  Future<void> loadPressureUnit() async {
    final prefs = await SharedPreferences.getInstance();
    _pressureUnit =
        prefs.getString('pressureUnit') ?? 'hPa'; // Mặc định là 'hPa'
    notifyListeners();
  }

  Future<void> setDistanceUnit(String unit) async {
    _distanceUnit = unit;
    notifyListeners();

    // Lưu đơn vị khoảng cách vào SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('distanceUnit', unit);
  }

  Future<void> loadDistanceUnit() async {
    final prefs = await SharedPreferences.getInstance();
    _distanceUnit = prefs.getString('distanceUnit') ?? 'm'; // Mặc định là 'm'
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
    _windSpeedUnit = 'm/s';
    _pressureUnit = 'hPa';
    _distanceUnit = 'm';
    _isWidgetEnabled = true;
    _isNotificationEnabled = true;
    notifyListeners();
  }
}
