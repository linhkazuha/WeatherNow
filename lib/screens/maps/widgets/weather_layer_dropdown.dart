import 'package:flutter/material.dart';
import '../../../../models/weather_models.dart';

class WeatherLayerDropdown extends StatefulWidget {
  final List<MapLayer> availableLayers;
  final String currentLayerId;
  final bool isLoading;
  final Function(String) onLayerSelected;

  const WeatherLayerDropdown({
    Key? key,
    required this.availableLayers,
    required this.currentLayerId,
    required this.onLayerSelected,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<WeatherLayerDropdown> createState() => _WeatherLayerDropdownState();
}

class _WeatherLayerDropdownState extends State<WeatherLayerDropdown> {
  bool _showOptions = false;
  final GlobalKey _buttonKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _toggleOptions() {
    if (_showOptions) {
      _removeOverlay();
    } else {
      _showOverlay();
    }

    setState(() {
      _showOptions = !_showOptions;
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  OverlayEntry _createOverlayEntry() {
    // Tìm vị trí của nút
    RenderBox renderBox =
        _buttonKey.currentContext!.findRenderObject() as RenderBox;
    var size = renderBox.size;
    var offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder:
          (context) => Positioned(
            // Đặt dropdown ở bên phải màn hình, cùng hàng với nút
            right: 16,
            top: offset.dy + size.height + 8, // Đặt dropdown bên dưới nút
            child: Material(
              elevation: 0,
              color: Colors.transparent,
              child: _buildOptionsPanel(),
            ),
          ),
    );
  }

  MapLayer get _currentLayerData {
    return widget.availableLayers.firstWhere(
      (layer) => layer.id == widget.currentLayerId,
      orElse: () => widget.availableLayers.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Đảm bảo nút luôn được căn sang phải
    return Align(
      alignment: Alignment.centerRight,
      child: _buildCurrentSelection(),
    );
  }

  Widget _buildCurrentSelection() {
    IconData currentIcon = _getIconForLayer(_currentLayerData.id);

    return Container(
      key: _buttonKey,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: _toggleOptions,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(currentIcon, color: _currentLayerData.color, size: 24),
          ),
        ),
      ),
    );
  }

  IconData _getIconForLayer(String layerId) {
    switch (layerId) {
      case 'temp_new':
        return Icons.thermostat_outlined;
      case 'precipitation_new':
        return Icons.water_drop_outlined;
      case 'wind_new':
        return Icons.air;
      case 'clouds_new':
        return Icons.cloud_outlined;
      case 'pressure_new':
        return Icons.compress;
      default:
        return Icons.layers;
    }
  }

  Widget _buildOptionsPanel() {
    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children:
              widget.availableLayers.map((layer) {
                IconData icon = _getIconForLayer(layer.id);
                return _buildLayerOption(layer, icon);
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildLayerOption(MapLayer layer, IconData icon) {
    final isSelected = widget.currentLayerId == layer.id;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:
            widget.isLoading
                ? null
                : () {
                  widget.onLayerSelected(layer.id);
                  _removeOverlay();
                  setState(() {
                    _showOptions = false;
                  });
                },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color:
                isSelected ? layer.color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? layer.color : Colors.black54,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                layer.name,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? layer.color : Colors.black87,
                ),
              ),
              if (isSelected) ...[
                const Spacer(),
                Icon(Icons.check, color: layer.color, size: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
