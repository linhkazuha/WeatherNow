class CustomTimeFormatter {
  String format(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    // Ánh xạ thứ trong tuần
    final daysOfWeek = [
      'Chủ nhật',
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy'
    ];

    if (difference.isNegative) {
      if (dateTime.day == now.day) {
        return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else if (dateTime.difference(now).inDays < 7) {
        return '${daysOfWeek[dateTime.weekday % 7]}, ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else {
        return '${dateTime.day}/${dateTime.month}, ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
    } else {
      if (difference.inMinutes < 60) {
        return '${difference.inMinutes} phút trước';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} giờ trước';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} ngày trước';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    }
  }
}
