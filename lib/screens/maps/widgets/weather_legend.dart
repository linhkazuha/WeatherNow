import 'package:flutter/material.dart';
import '../../../../models/weather_models.dart';

class WeatherLegend extends StatelessWidget {
  final MapLayer layerData;

  const WeatherLegend({Key? key, required this.layerData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 180,
      left: 20,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            Container(
              width: 150,
              height: 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                gradient: LinearGradient(
                  colors: List.generate(
                    10,
                    (index) => _getLayerLegendColor(layerData, index / 9),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 150,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getLegendMinValue(layerData),
                    style: const TextStyle(fontSize: 10),
                  ),
                  Text(
                    _getLegendMaxValue(layerData),
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getLayerLegendColor(MapLayer layer, double proportion) {
    final colorMap = layer.colorMap;
    if (colorMap.isEmpty) return layer.color;

    // Sort keys in ascending order
    final sortedKeys = colorMap.keys.toList()..sort();

    // Find appropriate key based on proportion
    final int targetValue =
        (sortedKeys.first + (sortedKeys.last - sortedKeys.first) * proportion)
            .round();

    // Find closest value in color map
    int closestKey = sortedKeys.first;

    for (final key in sortedKeys) {
      if (key <= targetValue) {
        closestKey = key;
      } else {
        break;
      }
    }

    return colorMap[closestKey] ?? layer.color;
  }

  String _getLegendMinValue(MapLayer layer) {
    if (layer.colorMap.isEmpty) return "Min";

    final minKey = layer.colorMap.keys.reduce((a, b) => a < b ? a : b);

    switch (layer.id) {
      case 'temp_new':
        return "$minKey°C";
      case 'precipitation_new':
        return "$minKey mm";
      case 'wind_new':
        return "$minKey m/s";
      case 'clouds_new':
        return "$minKey%";
      case 'pressure_new':
        return "$minKey hPa";
      default:
        return "$minKey";
    }
  }

  String _getLegendMaxValue(MapLayer layer) {
    if (layer.colorMap.isEmpty) return "Max";

    final maxKey = layer.colorMap.keys.reduce((a, b) => a > b ? a : b);

    switch (layer.id) {
      case 'temp_new':
        return "$maxKey°C";
      case 'precipitation_new':
        return "$maxKey mm";
      case 'wind_new':
        return "$maxKey m/s";
      case 'clouds_new':
        return "$maxKey%";
      case 'pressure_new':
        return "$maxKey hPa";
      default:
        return "$maxKey";
    }
  }
}
