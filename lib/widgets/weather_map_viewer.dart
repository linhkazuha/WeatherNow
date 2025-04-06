import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../utils/constants.dart';

class WeatherMapViewer extends StatefulWidget {
  final double latitude;
  final double longitude;
  final int zoom;
  final String layer;
  final Function(bool) onLoadingChanged;

  const WeatherMapViewer({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.zoom,
    required this.layer,
    required this.onLoadingChanged,
  });

  @override
  State<WeatherMapViewer> createState() => _WeatherMapViewerState();
}

class _WeatherMapViewerState extends State<WeatherMapViewer> {
  late WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _initWebViewController();
  }

  void _initWebViewController() {
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(const Color(0x00000000))
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (_) => widget.onLoadingChanged(true),
              onPageFinished: (_) => widget.onLoadingChanged(false),
              onWebResourceError: (error) {
                widget.onLoadingChanged(false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi tải bản đồ: ${error.description}'),
                  ),
                );
              },
            ),
          );
    _loadMap();
  }

  @override
  void didUpdateWidget(WeatherMapViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude ||
        oldWidget.zoom != widget.zoom ||
        oldWidget.layer != widget.layer) {
      _loadMap();
    }
  }

  void _loadMap() {
    final url =
        '${AppConstants.mapBaseUrl}?lat=${widget.latitude}&lon=${widget.longitude}&zoom=${widget.zoom}&level=surface&overlay=${widget.layer}&product=ecmwf&menu=true';
    _controller.loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
