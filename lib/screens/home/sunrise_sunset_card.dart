import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/weather_models.dart';

class SunriseSunsetCard extends StatelessWidget {
  final WeatherData weather;
  final Map<String, dynamic> themeData;

  const SunriseSunsetCard({
    super.key,
    required this.weather,
    required this.themeData,
  });

  @override
  Widget build(BuildContext context) {
    if (weather.sunrise == null || weather.sunset == null) {
      return Card(
        color: themeData['backCardColor'].withOpacity(0.7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'Không có dữ liệu mặt trời mọc/lặn',
              style: TextStyle(color: themeData['mainText']),
            ),
          ),
        ),
      );
    }

    final timeFormat = DateFormat('H:mm a');
    final sunriseTime = timeFormat.format(weather.sunrise!);
    final sunsetTime = timeFormat.format(weather.sunset!);
    
    // Tính toán vị trí của mặt trời dựa trên thời gian hiện tại
    final now = DateTime.now();
    final totalDayDuration = weather.sunset!.difference(weather.sunrise!).inMinutes;
    final currentTimeSinceSunrise = now.difference(weather.sunrise!).inMinutes;
    
    bool isNightTime = now.isBefore(weather.sunrise!) || now.isAfter(weather.sunset!);
    
    double sunPosition = 0.5; 
    
    if (now.isBefore(weather.sunrise!)) {
      sunPosition = 0.0;
    } else if (now.isAfter(weather.sunset!)) {
      sunPosition = 1.0;
    } else {
      // Trong khoảng thời gian từ mọc đến lặn
      sunPosition = currentTimeSinceSunrise / totalDayDuration;
      sunPosition = sunPosition.clamp(0.0, 1.0);
    }

    return Card(
      color: themeData['backCardColor'].withOpacity(0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          children: [
            SizedBox(
              height: 160,
              child: CustomPaint(
                painter: SunPathPainter(
                  sunPosition: sunPosition,
                  pathColor: Colors.orange,
                  sunColor: Colors.orange,
                  isDarkMode: themeData['mainText'] == Colors.white,
                  showSun: !isNightTime,
                ),
                size: Size.infinite,
              ),
            ),
            
            // Thời gian mặt trời mọc và lặn
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mặt trời mọc',
                        style: TextStyle(
                          color: themeData['mainText'],
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        sunriseTime,
                        style: TextStyle(
                          color: themeData['mainText'],
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Mặt trời lặn',
                        style: TextStyle(
                          color: themeData['mainText'],
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        sunsetTime,
                        style: TextStyle(
                          color: themeData['mainText'],
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SunPathPainter extends CustomPainter {
  final double sunPosition; // 0.0 - 1.0
  final Color pathColor;
  final Color sunColor;
  final bool isDarkMode;
  final bool showSun; // Biến để kiểm soát việc hiển thị mặt trời

  SunPathPainter({
    required this.sunPosition,
    required this.pathColor,
    required this.sunColor,
    this.isDarkMode = false,
    this.showSun = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Vẽ đường thẳng ngang
    final linePaint = Paint()
      ..color = isDarkMode ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final lineY = size.height * 0.85;
    canvas.drawLine(
      Offset(0, lineY),
      Offset(size.width, lineY),
      linePaint,
    );

    // Điểm kiểm soát cho đường cong
    final controlPoint = Offset(size.width / 2, lineY - size.height * 0.8);
    final startPoint = Offset(0, lineY);
    final endPoint = Offset(size.width, lineY);

    // Vẽ đường cong đầy đủ với màu mờ
    final fullPathPaint = Paint()
      ..color = isDarkMode ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final fullPath = Path();
    fullPath.moveTo(startPoint.dx, startPoint.dy);
    fullPath.quadraticBezierTo(
      controlPoint.dx, 
      controlPoint.dy,
      endPoint.dx, 
      endPoint.dy
    );
    
    canvas.drawPath(fullPath, fullPathPaint);

    // Vẽ phần đường cong đã đi qua (màu vàng)
    if (showSun && sunPosition > 0) {
      final activePathPaint = Paint()
        ..color = pathColor
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      // Tính toán điểm kết thúc của đường màu vàng
      final currentX = sunPosition * size.width;
      
      // Vẽ phần cụ thể của đường cong từ đầu đến vị trí mặt trời
      final activePath = Path();
      activePath.moveTo(startPoint.dx, startPoint.dy);
      
      // Tìm điểm trên đường cong tại vị trí hiện tại của mặt trời
      // Sử dụng phương trình tham số của đường cong Bezier bậc hai
      // P(t) = (1-t)²*P₀ + 2(1-t)t*P₁ + t²*P₂, với t từ 0 đến 1
      // Trong đó t chính là sunPosition
      final t = sunPosition;
      
      // Chỉ vẽ phần đường cong từ đầu đến vị trí hiện tại
      final tempPath = Path();
      for (double i = 0; i <= t; i += 0.01) {
        final x = (1-i)*(1-i)*startPoint.dx + 2*(1-i)*i*controlPoint.dx + i*i*endPoint.dx;
        final y = (1-i)*(1-i)*startPoint.dy + 2*(1-i)*i*controlPoint.dy + i*i*endPoint.dy;
        
        if (i == 0) {
          tempPath.moveTo(x, y);
        } else {
          tempPath.lineTo(x, y);
        }
      }
      
      // Vẽ đường đã hoàn thành với màu vàng
      canvas.drawPath(tempPath, activePathPaint);
    }

    // Chỉ vẽ mặt trời nếu showSun là true
    if (showSun) {
      // Tính toán vị trí chính xác của mặt trời trên đường cong
      final t = sunPosition;
      final sunX = (1-t)*(1-t)*startPoint.dx + 2*(1-t)*t*controlPoint.dx + t*t*endPoint.dx;
      final sunY = (1-t)*(1-t)*startPoint.dy + 2*(1-t)*t*controlPoint.dy + t*t*endPoint.dy;
      
      // Vẽ mặt trời
      final sunPaint = Paint()
        ..color = sunColor
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(sunX, sunY), 12, sunPaint);
    }
  }

  @override
  bool shouldRepaint(SunPathPainter oldDelegate) {
    return oldDelegate.sunPosition != sunPosition ||
           oldDelegate.pathColor != pathColor ||
           oldDelegate.sunColor != sunColor ||
           oldDelegate.isDarkMode != isDarkMode ||
           oldDelegate.showSun != showSun;
  }
}