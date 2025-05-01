// Chuyển Đổi giá trị nhiệt độ từ độ C sang độ F
double convertCelsiusToFahrenheit(double celsius) {
  return (celsius * 9 / 5) + 32;
}

// Hàm chuyển đổi nhiệt độ dựa trên đơn vị
double convertTemperature(double temp, String unit) {
  if (unit == 'F') {
    return (temp * 9 / 5) + 32; // Chuyển từ độ C sang độ F
  }
  return temp; // Mặc định là độ C
}

// Chuyển đổi tốc độ gió
double convertWindSpeed(double value, String unit) {
  switch (unit) {
    case 'km/h': // Chuyển từ m/s sang km/h
      return value * 3.6;
    case 'mph': // Chuyển từ m/s sang mph
      return value * 2.23694;
    case 'bft': // Chuyển từ m/s sang Beaufort scale (xấp xỉ)
      if (value < 0.5) return 0;
      if (value < 1.5) return 1;
      if (value < 3.3) return 2;
      if (value < 5.5) return 3;
      if (value < 7.9) return 4;
      if (value < 10.7) return 5;
      if (value < 13.8) return 6;
      if (value < 17.1) return 7;
      if (value < 20.7) return 8;
      if (value < 24.4) return 9;
      if (value < 28.4) return 10;
      if (value < 32.6) return 11;
      return 12;
    case 'kn': // Chuyển từ m/s sang knots
      return value * 1.94384;
    default: // Mặc định là m/s
      return value;
  }
}

// Chuyển đổi áp suất
double convertPressure(double value, String unit) {
  switch (unit) {
    case 'mm Hg': // Chuyển từ hPa sang mmHg
      return value * 0.750062;
    case 'mbar': // Chuyển từ hPa sang mbar (1:1)
      return value;
    case 'inHg': // Chuyển từ hPa sang inHg
      return value * 0.02953;
    case 'Kpa': // Chuyển từ hPa sang kPa
      return value * 0.1;
    default: // Mặc định là hPa
      return value;
  }
}

// Chuyển đổi khoảng cách
double convertDistance(double value, String unit) {
  switch (unit) {
    case 'km': // Chuyển từ mét sang km
      return value / 1000;
    default: // Mặc định là mét
      return value;
  }
}
