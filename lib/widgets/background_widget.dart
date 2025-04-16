import 'package:flutter/material.dart';

class BackgroundWidget extends StatelessWidget {
  final Widget child;

  const BackgroundWidget({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/weather_background.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: child,
    );
  }
}

// Phiên bản với gradient overlay
class GradientBackgroundWidget extends StatelessWidget {
  final Widget child;
  final Color overlayColor;
  final double opacity;

  const GradientBackgroundWidget({
    Key? key,
    required this.child,
    this.overlayColor = const Color(0xFF2B3866),
    this.opacity = 0.8,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/weather_background.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: child,
    );
  }
}
