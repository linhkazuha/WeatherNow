import 'package:flutter/material.dart';
import 'package:weather_app/models/air_quality_model.dart';

class AirQualityCard extends StatefulWidget {
  final AirQuality airQuality;
  final Map<String, dynamic> themeData;

  const AirQualityCard({
    super.key,
    required this.airQuality,
    required this.themeData,
  });

  @override
  State<AirQualityCard> createState() => _AirQualityCardState();
}

class _AirQualityCardState extends State<AirQualityCard> {
  bool _showDetails = false;
  
  // Lấy màu tương ứng với mức AQI
  Color _getAqiColorForLevel(int aqi) {
    switch (aqi) {
      case 1: return Color(0xFF4CAF50); // Xanh lá - Tốt
      case 2: return Color(0xFFFFC107); // Vàng - Trung bình
      case 3: return Color(0xFFFF9800); // Cam - Trung bình kém
      case 4: return Color(0xFFF44336); // Đỏ - Kém
      case 5: return Color(0xFF9C27B0); // Tím - Rất kém
      default: return Color(0xFF9E9E9E); // Màu xám mặc định
    }
  }

  @override
  Widget build(BuildContext context) {
    final aqiColor = _getAqiColorForLevel(widget.airQuality.aqi);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: widget.themeData['backCardColor'].withOpacity(0.8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Tiêu đề và nút dropdown
            Stack(
              alignment: Alignment.center,
              children: [
                // Tiêu đề ở chính giữa
                Center(
                  child: Text(
                    'AQI',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: widget.themeData['mainText'],
                    ),
                  ),
                ),
                // Nút dropdown ở bên phải
                Positioned(
                  right: 0,
                  child: IconButton(
                    icon: Icon(
                      _showDetails ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: widget.themeData['auxiliaryText'],
                    ),
                    onPressed: () {
                      setState(() {
                        _showDetails = !_showDetails;
                      });
                    },
                  ),
                ),
              ],
            ),
            
            // Mô tả tình trạng chất lượng không khí
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'Không tốt cho sức khỏe đối với\ncác nhóm nhạy cảm (${widget.airQuality.aqi})',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: aqiColor,
                ),
              ),
            ),
            
            // Cảnh báo sức khỏe
            Container(
              margin: EdgeInsets.symmetric(vertical: 12),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: aqiColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: aqiColor),
              ),
              child: Text(
                widget.airQuality.healthRecommendation,
                style: TextStyle(
                  color: widget.themeData['mainText'],
                  fontSize: 14,
                ),
              ),
            ),
            
            // Chi tiết các chỉ số ô nhiễm (hiển thị khi nhấn dropdown)
            if (_showDetails) _buildPollutantsList(),
          ],
        ),
      ),
    );
  }

  // Danh sách các chỉ số ô nhiễm - với thanh ngăn cách
  Widget _buildPollutantsList() {
    // Sử dụng cấu trúc dữ liệu an toàn hơn với kiểu rõ ràng
    final List<Map<String, dynamic>> pollutants = [
      {'name': 'PM2.5', 'value': widget.airQuality.components['pm2_5'] ?? 0.0},
      {'name': 'PM10', 'value': widget.airQuality.components['pm10'] ?? 0.0},
      {'name': 'O3', 'value': widget.airQuality.components['o3'] ?? 0.0},
      {'name': 'SO2', 'value': widget.airQuality.components['so2'] ?? 0.0},
      {'name': 'NO2', 'value': widget.airQuality.components['no2'] ?? 0.0},
      {'name': 'CO', 'value': widget.airQuality.components['co'] ?? 0.0},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(pollutants.length * 2 - 1, (index) {
        // Nếu index chẵn, thì đây là một hàng chỉ số
        if (index % 2 == 0) {
          final pollutantIndex = index ~/ 2;
          final pollutant = pollutants[pollutantIndex];
          
          // Lấy giá trị với kiểu dữ liệu an toàn
          final String name = pollutant['name'] as String;
          final double value = pollutant['value'] as double;
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: widget.themeData['mainText'],
                  ),
                ),
                Text(
                  '${value.toStringAsFixed(1)} μg/m³',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: widget.themeData['auxiliaryText'],
                  ),
                ),
              ],
            ),
          );
        } else {
          // Nếu index lẻ, thì đây là một thanh phân cách
          return Divider(
            color: widget.themeData['separateLine']?.withOpacity(0.3) ?? Colors.grey.withOpacity(0.3),
            height: 1,
          );
        }
      }),
    );
  }
}