// lib/widgets/weather_widget_provider.dart
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

class WeatherWidgetProvider {
  static const String appGroupId = 'com.example.weatherApp';
  static const String widgetKey = 'weather_widget_data';
  static const String locationKey = 'weather_widget_location';

  // Cập nhật dữ liệu cho widget
  static Future<void> updateWidget(String text, String location) async {
    try {
      await HomeWidget.saveWidgetData<String>(widgetKey, text);
      await HomeWidget.saveWidgetData<String>(locationKey, location);
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
    await updateWidget('test thời tiết', 'Vị trí không xác định');
  }
  
  // Cập nhật vị trí hiện tại
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