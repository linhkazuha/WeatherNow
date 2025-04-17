import 'package:flutter/material.dart';

class WeatherLocationButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const WeatherLocationButton({
    Key? key,
    required this.isLoading,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 180,
      right: 20,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.my_location),
          onPressed: isLoading ? null : onPressed,
        ),
      ),
    );
  }
}
