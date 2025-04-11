// lib/widgets/weather_time_slider.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class WeatherTimeSlider extends StatefulWidget {
  final DateTime initialTime;
  final double initialValue;
  final int maxForecastHours;
  final bool isLoading;
  final Function(double) onTimeChanged;

  const WeatherTimeSlider({
    Key? key,
    required this.initialTime,
    required this.initialValue,
    required this.onTimeChanged,
    this.maxForecastHours = 120,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<WeatherTimeSlider> createState() => _WeatherTimeSliderState();
}

class _WeatherTimeSliderState extends State<WeatherTimeSlider> {
  late double _timeSliderValue;
  late DateTime _baseTime; // Thời gian gốc làm cơ sở tính toán
  late DateTime _selectedTime; // Thời gian đã chọn để hiển thị

  bool _isLiveUpdate = false;
  bool _isPlaying = false;

  Timer? _autoUpdateTimer;
  Timer? _playTimer;

  final double _maxSliderValue = 5;
  final List<int> _hourOffsets = [0, 1, 3, 6, 12, 24];

  @override
  void initState() {
    super.initState();
    _timeSliderValue = widget.initialValue;
    _baseTime = DateTime.now(); // Luôn dùng thời gian hiện tại làm cơ sở
    _selectedTime = _calculateSelectedTime(_timeSliderValue);
  }

  @override
  void didUpdateWidget(WeatherTimeSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _timeSliderValue = widget.initialValue;
      _selectedTime = _calculateSelectedTime(_timeSliderValue);
    }
    // Không cập nhật baseTime từ widget nữa, chỉ cập nhật khi live update
  }

  // Phương thức tính thời gian dựa trên vị trí slider
  DateTime _calculateSelectedTime(double value) {
    final index = value.round();
    if (index < 0 || index >= _hourOffsets.length) return _baseTime;

    // Luôn tính toán dựa trên thời gian cơ sở hiện tại
    final hourOffset = _hourOffsets[index];
    return _baseTime.add(Duration(hours: hourOffset));
  }

  void _updateTimeFromSlider(double value) {
    final roundedValue = value.round().toDouble();
    final newTime = _calculateSelectedTime(roundedValue);

    setState(() {
      _timeSliderValue = roundedValue;
      _selectedTime = newTime;
    });

    widget.onTimeChanged(roundedValue);
  }

  void _onTimePointTap(int index) {
    if (widget.isLoading) return;
    _updateTimeFromSlider(index.toDouble());
  }

  String _getFormattedTime() {
    return DateFormat('HH:mm - dd/MM/yyyy').format(_selectedTime);
  }

  String _getTimePointLabel(int index) {
    if (index == 0) return 'Bây giờ';
    final hours = _hourOffsets[index];
    return '+${hours}h';
  }

  void _toggleLiveUpdate() {
    setState(() {
      _isLiveUpdate = !_isLiveUpdate;
      if (_isLiveUpdate) {
        _startAutoUpdate();
      } else {
        _cancelAutoUpdate();
      }
    });
  }

  void _startAutoUpdate() {
    _cancelAutoUpdate();
    // Update ngay lập tức khi bật
    _updateBaseTimeToNow();

    _autoUpdateTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _updateBaseTimeToNow();
    });
  }

  // Phương thức mới để cập nhật thời gian cơ sở
  void _updateBaseTimeToNow() {
    setState(() {
      _baseTime = DateTime.now();
      // Giữ nguyên vị trí slider nhưng cập nhật thời gian tương ứng
      _selectedTime = _calculateSelectedTime(_timeSliderValue);
    });
    // Thông báo cho parent biết có thay đổi
    widget.onTimeChanged(_timeSliderValue);
  }

  void _cancelAutoUpdate() {
    _autoUpdateTimer?.cancel();
    _autoUpdateTimer = null;
  }

  void _togglePlay() {
    if (_isPlaying) {
      _stopPlay();
    } else {
      _startPlay();
    }
  }

  void _startPlay() {
    _stopPlay(); // Clean old

    // Cập nhật thời gian cơ sở trước khi bắt đầu phát
    _updateBaseTimeToNow();

    setState(() => _isPlaying = true);

    _playTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      int nextIndex = _timeSliderValue.round() + 1;
      if (nextIndex < _hourOffsets.length) {
        _updateTimeFromSlider(nextIndex.toDouble());
      } else {
        // Khi quay về đầu, cập nhật lại thời gian cơ sở
        _updateBaseTimeToNow();
        _updateTimeFromSlider(0); // Loop back
      }
    });
  }

  void _stopPlay() {
    _playTimer?.cancel();
    _playTimer = null;
    setState(() => _isPlaying = false);
  }

  @override
  void dispose() {
    _cancelAutoUpdate();
    _stopPlay();
    super.dispose();
  }

  Widget _buildTimePoint(int index) {
    final isSelected = _timeSliderValue.round() == index;

    return GestureDetector(
      onTap: () => _onTimePointTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isSelected ? 10 : 6,
            height: isSelected ? 10 : 6,
            decoration: BoxDecoration(
              color: isSelected ? Colors.amber : Colors.grey.shade400,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow:
                  isSelected
                      ? [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ]
                      : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getTimePointLabel(index),
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.amber : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTimeMarkers() {
    return List.generate(_hourOffsets.length, (i) => _buildTimePoint(i));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: Colors.amber,
                ),
                const SizedBox(width: 6),
                Text(
                  _getFormattedTime(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // const SizedBox(height: 3),
          LayoutBuilder(
            builder: (context, constraints) {
              final double sliderWidth =
                  constraints.maxWidth - 16; // Adjust for padding
              final int segments = _hourOffsets.length - 1;
              final double segmentWidth = sliderWidth / segments;

              return Stack(
                alignment: Alignment.center,
                children: [
                  // Background track
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Active track - only goes up to the selected point
                  if (_timeSliderValue > 0)
                    Positioned(
                      left: 0,
                      child: Container(
                        width: _timeSliderValue * segmentWidth,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                  // Custom slider
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      activeTrackColor: Colors.transparent,
                      inactiveTrackColor: Colors.transparent,
                      thumbColor: Colors.amber,
                      overlayColor: const Color.fromRGBO(255, 193, 7, 0.2),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 8,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 16,
                      ),
                      showValueIndicator: ShowValueIndicator.never,
                    ),
                    child: Slider(
                      min: 0,
                      max: _maxSliderValue,
                      divisions: _maxSliderValue.toInt(),
                      value: _timeSliderValue,
                      onChanged:
                          widget.isLoading ? null : _updateTimeFromSlider,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _buildTimeMarkers(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Cập nhật tự động
              GestureDetector(
                onTap: widget.isLoading ? null : _toggleLiveUpdate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color:
                        _isLiveUpdate
                            ? Colors.amber.withOpacity(0.1)
                            : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color:
                          _isLiveUpdate ? Colors.amber : Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isLiveUpdate
                            ? Icons.autorenew
                            : Icons.autorenew_outlined,
                        size: 14,
                        color:
                            _isLiveUpdate ? Colors.amber : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Cập nhật tự động',
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              _isLiveUpdate
                                  ? Colors.amber
                                  : Colors.grey.shade600,
                          fontWeight:
                              _isLiveUpdate
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Auto-play animation
              GestureDetector(
                onTap: widget.isLoading ? null : _togglePlay,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color:
                        _isPlaying
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isPlaying ? Colors.blue : Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_fill,
                        size: 16,
                        color: _isPlaying ? Colors.blue : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _isPlaying ? 'Tạm dừng phát' : 'Phát tự động',
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              _isPlaying ? Colors.blue : Colors.grey.shade600,
                          fontWeight:
                              _isPlaying ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
