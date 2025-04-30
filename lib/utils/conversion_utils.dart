// Chuyển Đổi giá trị nhiệt độ từ độ C sang độ F
double convertCelsiusToFahrenheit(double celsius) {
  return (celsius * 9 / 5) + 32;
}

// Hàm chuyển đổi nhiệt độ dựa trên đơn vị
double convertTemperature(double temp, String unit) {
  if (unit == 'F') {
    return convertCelsiusToFahrenheit(temp);
  }
  return temp; // Mặc định là độ C
}
