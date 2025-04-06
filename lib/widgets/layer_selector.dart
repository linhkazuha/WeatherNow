import 'package:flutter/material.dart';
import '../models/weather_layer.dart';

class LayerSelector extends StatefulWidget {
  final String currentLayer;
  final Function(String) onLayerChanged;

  const LayerSelector({
    super.key,
    required this.currentLayer,
    required this.onLayerChanged,
  });

  @override
  State<LayerSelector> createState() => _LayerSelectorState();
}

class _LayerSelectorState extends State<LayerSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Tìm layer hiện tại
    final WeatherLayer currentLayerObject = weatherLayers.firstWhere(
      (layer) => layer.value == widget.currentLayer,
      orElse: () => weatherLayers.first,
    );

    return Positioned(
      right: 16,
      bottom: 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Hiển thị menu mở rộng nếu đang mở
          if (_isExpanded)
            SizeTransition(
              sizeFactor: _animation,
              axisAlignment: 1.0,
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Color.fromRGBO(0, 0, 0, 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      weatherLayers
                          .where((layer) => layer.value != widget.currentLayer)
                          .map((layer) => _buildLayerOption(layer))
                          .toList(),
                ),
              ),
            ),

          // Nút chọn layer chính
          GestureDetector(
            onTap: _toggleMenu,
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(27),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  currentLayerObject.icon,
                  color: Colors.blue,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayerOption(WeatherLayer layer) {
    return GestureDetector(
      onTap: () {
        widget.onLayerChanged(layer.value);
        _toggleMenu();
      },
      child: Container(
        width: 160,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(layer.icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              layer.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
