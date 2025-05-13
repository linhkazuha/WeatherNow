# Ứng dụng di động dự báo thời tiết - Weather Now
**WeatherNow** là ứng dụng di động cung cấp thông tin thời tiết chi tiết, dự báo, và cảnh báo kịp thời. Ứng dụng được thiết kế với giao diện thân thiện, trực quan giúp người dùng dễ dàng theo dõi tình hình thời tiết mọi lúc, mọi nơi.
## 👨‍💻 Thành viên
- Nguyễn Khánh Linh - 22021158 (Nhóm trưởng)
- Nguyễn Thị Hoài Thu - 22021135
- Vũ Văn Huy - 22021202

## 🛠️ Công nghệ sử dụng
- Flutter Framework
- Firebase
- Provider state management
- OpenWeatherMap API

## 🚀 Cài đặt và chạy dự án




```bash
# Kết nối với thiết bị Android hoặc khởi chạy máy ảo Android Studio
# Clone repository
git clone https://github.com/linhkazuha/WeatherNow.git

# Di chuyển vào thư mục dự án
cd WeatherNow

# Cài đặt các gói cần thiết
flutter pub get

# Chạy ứng dụng
flutter run
```
## 🗂️ Cấu trúc dự án
```bash
lib/
|- models/       # Mô hình dữ liệu
|- providers/    # State management
|- screens/      # Màn hình ứng dụng
|- services/     # Dịch vụ API, thông báo
|- utils/        # Tiện ích
|- widgets/      # Các widget tái sử dụng
|- main.dart     # Điểm khởi đầu ứng dụng
```

## 🌟 Tính năng chính
- Cập nhật thông tin thời tiết hiện tại: nhiệt độ, độ ẩm, AQI, các chỉ số liên quan
- Thêm địa điểm mới
- Xem bản đồ nhiệt, lượng mưa, gió, mây tại địa điểm hiện tại
- Gửi thông báo tới người dùng về tình hình thời tiết hiện tại, ngày mai, cảnh báo khi có hiện tượng thời tiết cực đoan
- Cài đặt widget cho ứng dụng trên màn hình chính
- Chuyển đổi đơn vị đo lường, bật tắt thông báo
- Cung cấp kiến thức liên quan đến thời tiết

---
---