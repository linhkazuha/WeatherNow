import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode;

  ThemeProvider() : _isDarkMode = _getInitialTheme();

  static bool _getInitialTheme() {
    final hour = DateTime.now().hour;
    return !(hour >= 6 && hour < 18); // true nếu là ban đêm
  }

  bool get isDarkMode => _isDarkMode;

  Map<String, dynamic> get themeData => _isDarkMode ? darkTheme : lightTheme;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;

    // Cập nhật thanh trạng thái dựa vào theme
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            _isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );
    notifyListeners();
  }

  // Optional: gọi lại hàm này để cập nhật theme theo giờ
  void updateThemeByTime() {
    final hour = DateTime.now().hour;
    final shouldUseDark = !(hour >= 6 && hour < 18);
    if (_isDarkMode != shouldUseDark) {
      _isDarkMode = shouldUseDark;
      notifyListeners();
    }
  }
}

// ---------------- Theme Data ---------------- //

final Map<String, dynamic> lightTheme = {
  "generalBackgroundColor": const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF7DCDFF), Color(0xFF138BC0)],
  ),
  "mainText": const Color(0xFF1E1F33),
  "auxiliaryText": const Color(0xFF2A78A6),
  "currentWeatherCardColor": Colors.transparent,
  "backCardColor": const Color(0xFF92E1FF),
  "separateLine": const Color(0xFF226287),
  "sideBarColor": const Color(0xFF53B1F7),
  "searchFieldColor": const Color(0x99FFFFFF),
  "cardLocationColor": const Color(0xFF92E1FF),
  "cardLocationBorderColor": const Color(0x99000000),
  "didyouknowButton": const Color(0xCCFFFFFF),
  "typeColor": const Color.fromARGB(255, 169, 229, 252),
  "typeBorderColor": const Color(0x99000000),
  "didyouknowCardColor": const Color(0xFFE4F2FD),
};

final Map<String, dynamic> darkTheme = {
  "generalBackgroundColor": const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF151A3A), Color(0xFF101A5F)],
  ),
  "mainText": const Color(0xFFEFF5F1),
  "auxiliaryText": const Color(0xFF9599B6),
  "currentWeatherCardColor": Colors.transparent,
  "backCardColor": const Color(0xFF3C437A),
  "separateLine": const Color(0xFFBCC1E6),
  "sideBarColor": const Color(0xFF272C4C),
  "searchFieldColor": const Color.fromARGB(153, 93, 99, 168),
  "cardLocationColor": const Color(0xFF3C437A),
  "cardLocationBorderColor": const Color(0x99FFFFFF),
  "didyouknowButton": const Color(0xCCFFFFFF),
  "typeColor": const Color(0xFF3C437A),
  "typeBorderColor": const Color(0x99FFFFFF),
  "didyouknowCardColor": const Color(0xFF2C2F50),
};
