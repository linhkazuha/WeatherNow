import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/services/notification_service.dart';

class SettingsProvider with ChangeNotifier {
  // Đơn vị
  String _temperatureUnit = 'C'; // Celsius
  String _windSpeedUnit = 'm/s'; // metre/sec
  String _pressureUnit = 'hPa'; // Millibar
  String _distanceUnit = 'm'; // metres

  // Cài đặt khác
  bool _isWidgetEnabled = true;

  bool _isNotificationEnabled = true;
  TimeOfDay _notificationTime = TimeOfDay(hour: 7, minute: 0);

  // Vị trí mặc định cho thông báo (sẽ được cập nhật từ vị trí hiện tại của người dùng)
  String _notificationLatitude = '21.0278'; // Hà Nội mặc định
  String _notificationLongitude = '105.8342';

  // Getters
  String get temperatureUnit => _temperatureUnit;
  String get windSpeedUnit => _windSpeedUnit;
  String get pressureUnit => _pressureUnit;
  String get distanceUnit => _distanceUnit;

  bool get isWidgetEnabled => _isWidgetEnabled;
  bool get isNotificationEnabled => _isNotificationEnabled;
  TimeOfDay get notificationTime => _notificationTime;

  String get notificationLatitude => _notificationLatitude;
  String get notificationLongitude => _notificationLongitude;

  // Khởi tạo
  Future<void> initialize() async {
    await loadAllSettings();

    // Nếu thông báo được bật, lên lịch thông báo
    if (_isNotificationEnabled) {
      await scheduleNotification();
    }
  }

  // Load tất cả cài đặt từ SharedPreferences
  Future<void> loadAllSettings() async {
    await Future.wait([
      loadTemperatureUnit(),
      loadWindSpeedUnit(),
      loadPressureUnit(),
      loadDistanceUnit(),
      loadWidgetSettings(),
      loadNotificationSettings(),
    ]);
  }

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

  Future<void> setWidgetEnabled(bool isEnabled) async {
    _isWidgetEnabled = isEnabled;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isWidgetEnabled', isEnabled);
  }

  Future<void> loadWidgetSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isWidgetEnabled = prefs.getBool('isWidgetEnabled') ?? true;
    notifyListeners();
  }

  Future<void> setNotificationEnabled(bool isEnabled) async {
    _isNotificationEnabled = isEnabled;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isNotificationEnabled', isEnabled);

    // Khi bật/tắt thông báo, cập nhật lịch thông báo
    if (isEnabled) {
      await scheduleNotification();
    } else {
      await NotificationService.cancelScheduledNotifications();
    }

    return;
  }

  Future<void> setNotificationTime(TimeOfDay time) async {
    _notificationTime = time;
    notifyListeners();

    // Lưu local
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notificationHour', time.hour);
    await prefs.setInt('notificationMinute', time.minute);

    // Cập nhật lịch thông báo nếu thông báo đang được bật
    if (_isNotificationEnabled) {
      await scheduleNotification();
    }
  }

  // Cập nhật vị trí cho thông báo
  Future<void> setNotificationLocation(
    String latitude,
    String longitude,
  ) async {
    _notificationLatitude = latitude;
    _notificationLongitude = longitude;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notificationLatitude', latitude);
    await prefs.setString('notificationLongitude', longitude);

    // Cập nhật lịch thông báo với vị trí mới nếu thông báo đang được bật
    if (_isNotificationEnabled) {
      await scheduleNotification();
    }
  }

  Future<void> loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Tải cài đặt thông báo
    _isNotificationEnabled = prefs.getBool('isNotificationEnabled') ?? true;

    // Tải thời gian thông báo
    int hour = prefs.getInt('notificationHour') ?? 7;
    int minute = prefs.getInt('notificationMinute') ?? 0;
    _notificationTime = TimeOfDay(hour: hour, minute: minute);

    // Tải vị trí thông báo
    _notificationLatitude =
        prefs.getString('notificationLatitude') ?? '21.0278';
    _notificationLongitude =
        prefs.getString('notificationLongitude') ?? '105.8342';

    notifyListeners();
  }

  // Lên lịch thông báo
  Future<void> scheduleNotification() async {
    await NotificationService.scheduleWeatherNotification(
      _notificationTime,
      _notificationLatitude,
      _notificationLongitude,
      this,
    );
  }

  // Khôi phục cài đặt mặc định
  Future<void> resetToDefault() async {
    _temperatureUnit = 'C';
    _windSpeedUnit = 'm/s';
    _pressureUnit = 'hPa';
    _distanceUnit = 'm';
    _isWidgetEnabled = true;
    _isNotificationEnabled = true;
    _notificationTime = TimeOfDay(hour: 7, minute: 0);

    // Hủy thông báo hiện tại
    await NotificationService.cancelScheduledNotifications();

    // Lên lịch lại thông báo với cài đặt mặc định
    if (_isNotificationEnabled) {
      await scheduleNotification();
    }

    // Lưu cài đặt mặc định
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('temperatureUnit', 'C');
    await prefs.setString('windSpeedUnit', 'm/s');
    await prefs.setString('pressureUnit', 'hPa');
    await prefs.setString('distanceUnit', 'm');
    await prefs.setBool('isWidgetEnabled', true);
    await prefs.setBool('isNotificationEnabled', true);
    await prefs.setInt('notificationHour', 7);
    await prefs.setInt('notificationMinute', 0);

    notifyListeners();
  }
}

// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class SettingsProvider with ChangeNotifier {
//   // Đơn vị
//   String _temperatureUnit = 'C'; // Celsius
//   String _windSpeedUnit = 'm/s'; // metre/sec
//   String _pressureUnit = 'hPa'; // Millibar
//   String _distanceUnit = 'm'; // metres

//   // Cài đặt khác
//   bool _isWidgetEnabled = true;

//   bool _isNotificationEnabled = true;

//   // Getters
//   String get temperatureUnit => _temperatureUnit;
//   String get windSpeedUnit => _windSpeedUnit;
//   String get pressureUnit => _pressureUnit;
//   String get distanceUnit => _distanceUnit;

//   bool get isWidgetEnabled => _isWidgetEnabled;
//   bool get isNotificationEnabled => _isNotificationEnabled;

//   // Setters
//   Future<void> setTemperatureUnit(String unit) async {
//     _temperatureUnit = unit;
//     notifyListeners();

//     // Lưu đơn vị nhiệt độ vào SharedPreferences
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('temperatureUnit', unit);
//   }

//   Future<void> loadTemperatureUnit() async {
//     final prefs = await SharedPreferences.getInstance();
//     _temperatureUnit =
//         prefs.getString('temperatureUnit') ?? 'C'; // Mặc định là 'C'
//     notifyListeners();
//   }

//   Future<void> setWindSpeedUnit(String unit) async {
//     _windSpeedUnit = unit;
//     notifyListeners();

//     // Lưu đơn vị tốc độ gió vào SharedPreferences
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('windSpeedUnit', unit);
//   }

//   Future<void> loadWindSpeedUnit() async {
//     final prefs = await SharedPreferences.getInstance();
//     _windSpeedUnit =
//         prefs.getString('windSpeedUnit') ?? 'm/s'; // Mặc định là 'm/s'
//     notifyListeners();
//   }

//   Future<void> setPressureUnit(String unit) async {
//     _pressureUnit = unit;
//     notifyListeners();

//     // Lưu đơn vị áp suất vào SharedPreferences
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('pressureUnit', unit);
//   }

//   Future<void> loadPressureUnit() async {
//     final prefs = await SharedPreferences.getInstance();
//     _pressureUnit =
//         prefs.getString('pressureUnit') ?? 'hPa'; // Mặc định là 'hPa'
//     notifyListeners();
//   }

//   Future<void> setDistanceUnit(String unit) async {
//     _distanceUnit = unit;
//     notifyListeners();

//     // Lưu đơn vị khoảng cách vào SharedPreferences
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('distanceUnit', unit);
//   }

//   Future<void> loadDistanceUnit() async {
//     final prefs = await SharedPreferences.getInstance();
//     _distanceUnit = prefs.getString('distanceUnit') ?? 'm'; // Mặc định là 'm'
//     notifyListeners();
//   }

//   void setWidgetEnabled(bool isEnabled) {
//     _isWidgetEnabled = isEnabled;
//     notifyListeners();
//   }

//   void setNotificationEnabled(bool isEnabled) {
//     _isNotificationEnabled = isEnabled;
//     notifyListeners();
//   }

//   // Khôi phục cài đặt mặc định
//   void resetToDefault() {
//     _temperatureUnit = 'C';
//     _windSpeedUnit = 'm/s';
//     _pressureUnit = 'hPa';
//     _distanceUnit = 'm';
//     _isWidgetEnabled = true;
//     _isNotificationEnabled = true;
//     notifyListeners();
//   }
// }
