# Tupi House 🌷

Tupi House là một ứng dụng di động (và web) xây dựng bằng **Flutter**, mang đến trải nghiệm mua sắm các sản phẩm decor, quà tặng, đặc biệt là hoa Tulip với giao diện cực kỳ dễ thương, hiện đại và chuyên nghiệp.

## 🌟 Tính năng nổi bật

- **Giao diện (UI) hiện đại & mượt mà**: Thiết kế theo phong cách pastel (hồng/xanh) ngọt ngào, kết hợp với các hiệu ứng bo góc, đổ bóng tinh tế.
- **Quản lý Sản phẩm**: Hiển thị danh sách sản phẩm dạng lưới (Grid), hỗ trợ tìm kiếm và sắp xếp.
- **Chi tiết Sản phẩm nâng cao**: 
  - Mô tả sản phẩm hỗ trợ định dạng HTML (`flutter_html`).
  - Giao diện dạng Bottom Sheet nổi bật.
  - Tích hợp Đánh giá & Nhận xét.
  - Mục Sản phẩm gợi ý (Suggested Products).
- **Xác thực người dùng (Authentication)**: 
  - Hỗ trợ duyệt app với tư cách **Khách** (không bắt buộc đăng nhập).
  - Đăng ký / Đăng nhập bằng Email & Mật khẩu.
  - Đăng nhập nhanh bằng **Google** (`google_sign_in`).
- **Giỏ hàng & Yêu thích**: Giao diện trực quan cho việc quản lý các mặt hàng muốn mua (Các tính năng logic đang được tiếp tục phát triển).

## 🛠 Công nghệ sử dụng

- **Framework**: Flutter (Dart)
- **Quản lý trạng thái (State Management)**: `provider`
- **Backend & Database**: Firebase (Authentication, Cloud Firestore)
- **UI & Tiện ích**:
  - `flutter_html`: Render mô tả sản phẩm dạng HTML.
  - `google_sign_in`: Tích hợp đăng nhập qua tài khoản Google.
  - `intl`: Format tiền tệ (VNĐ).
  - `shared_preferences`: Lưu trữ trạng thái đăng nhập nội bộ (Remember me).

## 🚀 Cài đặt & Chạy dự án

### Yêu cầu hệ thống
- Flutter SDK (phiên bản `>=3.0.0`)
- Trình duyệt (Chrome/Edge) để chạy Web hoặc thiết bị thật/máy ảo Android/iOS.

### Hướng dẫn
1. **Clone repository**:
   ```bash
   git clone <đường-dẫn-repo-của-bạn>
   cd tubi_home
   ```
2. **Cài đặt thư viện**:
   ```bash
   flutter pub get
   ```
3. **Cấu hình Firebase**:
   - Dự án đã được liên kết với Firebase qua các file cấu hình. Nếu bạn muốn chạy trên môi trường riêng, vui lòng thiết lập project Firebase mới và ghi đè các file cấu hình (`google-services.json` cho Android, `GoogleService-Info.plist` cho iOS hoặc cấu hình Firebase Web).
4. **Chạy ứng dụng**:
   ```bash
   flutter run
   ```

## 📂 Cấu trúc thư mục

```text
lib/
├── models/         # Các Data class (Product, User...)
├── providers/      # Quản lý State (AuthProvider, ProductProvider...)
├── screens/        # Các màn hình UI (Login, ProductList, ProductDetail...)
├── services/       # Các dịch vụ bên ngoài (StorageService...)
├── theme/          # Cấu hình màu sắc, typography (AppColors...)
├── utils/          # Các hàm tiện ích (Formatters...)
├── widgets/        # Các UI component dùng chung (AppDrawer, ProductCard...)
└── main.dart       # Điểm bắt đầu (Entry point) của ứng dụng
```

## 🤝 Đóng góp
Dự án được xây dựng trong khuôn khổ học tập/cá nhân. Mọi đóng góp, báo lỗi hoặc yêu cầu tính năng vui lòng tạo **Issue** hoặc **Pull Request** trên repository này.

---
*Được phát triển với ❤️ bởi Project Team.*
