import 'package:flutter/material.dart';

class WeatherSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final Function(String) onSearch;

  const WeatherSearchBar({
    Key? key,
    required this.controller,
    required this.isLoading,
    required this.onSearch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm địa điểm',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => controller.clear(),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              onSearch(value);
            }
          },
          enabled: !isLoading,
        ),
      ),
    );
  }
}
