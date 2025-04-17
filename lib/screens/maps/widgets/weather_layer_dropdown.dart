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

  void _toggleOptions() {
    setState(() {
      _showOptions = !_showOptions;
    });
  }

  MapLayer get _currentLayerData {
    return widget.availableLayers.firstWhere(
      (layer) => layer.id == widget.currentLayerId,
      orElse: () => widget.availableLayers.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Align(
        alignment: Alignment.topRight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildCurrentSelection(),
            if (_showOptions) _buildOptionsPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentSelection() {
    IconData currentIcon = _getIconForLayer(_currentLayerData.id);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleOptions,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(currentIcon, color: _currentLayerData.color, size: 20),
                const SizedBox(width: 8),
                Text(
                  _currentLayerData.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _showOptions ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: Colors.black87,
                ),
              ],
            ),
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

  String? _getAdditionalInfo(String layerId) {
    // switch (layerId) {
    //   case 'wind_new':
    //     return '2.7';
    //   default:
    //     return null;
    // }
    return null;
  }

  Widget _buildOptionsPanel() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      width: 180,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children:
            widget.availableLayers.map((layer) {
              IconData icon = _getIconForLayer(layer.id);
              String? additionalInfo = _getAdditionalInfo(layer.id);

              return _buildLayerOption(layer, icon, additionalInfo);
            }).toList(),
      ),
    );
  }

  Widget _buildLayerOption(
    MapLayer layer,
    IconData icon,
    String? additionalInfo,
  ) {
    final isSelected = widget.currentLayerId == layer.id;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:
            widget.isLoading
                ? null
                : () {
                  widget.onLayerSelected(layer.id);
                  setState(() {
                    _showOptions = false;
                  });
                },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              if (additionalInfo != null) ...[
                const Spacer(),
                Text(
                  additionalInfo,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
