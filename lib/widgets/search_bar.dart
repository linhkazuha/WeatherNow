import 'package:flutter/material.dart';

class WeatherSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSearch;

  const WeatherSearchBar({
    super.key,
    required this.controller,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(left: 16, right: 50, top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: TextField(
          controller: controller,
          textAlignVertical: TextAlignVertical.center, // căn giữa chiều dọc
          style: const TextStyle(
            fontSize: 18,
          ), // chỉnh size chữ người dùng nhập
          decoration: InputDecoration(
            hintText: 'Nhập địa điểm...',
            hintStyle: const TextStyle(fontSize: 18), // chỉnh size chữ hintText
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            suffixIcon: SizedBox(
              width: 36, // thu gọn icon search
              child: IconButton(
                icon: const Icon(Icons.search, color: Colors.blue),
                onPressed: () => onSearch(controller.text),
              ),
            ),
          ),
          onSubmitted: onSearch,
        ),
      ),
    );
  }
}
