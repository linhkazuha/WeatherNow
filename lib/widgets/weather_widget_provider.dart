// lib/widgets/weather_widget_provider.dart
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

class WeatherWidgetProvider {
  static const String appGroupId = 'com.example.weatherApp';
  static const String widgetKey = 'weather_widget_data';
  static const String locationKey = 'weather_widget_location';
  static const String descriptionKey = 'weather_widget_description';
  static const String iconKey = 'weather_widget_icon';

  // Cập nhật đầy đủ thông tin cho widget
  static Future<void> updateWidget(
    String temperature, 
    String location, 
    String description, 
    String iconCode
  ) async {
    try {
      await HomeWidget.saveWidgetData<String>(widgetKey, temperature);
      await HomeWidget.saveWidgetData<String>(locationKey, location);
      await HomeWidget.saveWidgetData<String>(descriptionKey, description);
      await HomeWidget.saveWidgetData<String>(iconKey, iconCode);
      await HomeWidget.updateWidget(
        androidName: 'WeatherWidgetProvider',
        iOSName: '', // Không sử dụng cho iOS
      );
    } catch (e) {
      debugPrint('Không thể cập nhật widget: $e');
    }
  }

  // Khởi tạo widget với dữ liệu mặc định
  static Future<void> initWidget() async {
    await updateWidget('--°C', 'Vị trí không xác định', 'không có dữ liệu', '01d');
  }
  
  // Cập nhật chỉ vị trí 
  static Future<void> updateLocation(String location) async {
    try {
      await HomeWidget.saveWidgetData<String>(locationKey, location);
      await HomeWidget.updateWidget(
        androidName: 'WeatherWidgetProvider',
        iOSName: '', // Không sử dụng cho iOS
      );
    } catch (e) {
      debugPrint('Không thể cập nhật vị trí widget: $e');
    }
  }
}