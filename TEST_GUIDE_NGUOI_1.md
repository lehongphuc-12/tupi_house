# HƯỚNG DẪN KIỂM THỬ (TEST GUIDE) – NGƯỜI 1: QUẢN LÝ ĐƠN HÀNG & THEO DÕI

Tài liệu này hướng dẫn chi tiết cách kiểm thử các chức năng của **Người 1** trong dự án **Tupi House**. Các chức năng này tập trung vào luồng đặt hàng, lịch sử đơn hàng, chi tiết đơn hàng, timeline theo dõi trạng thái, hủy đơn, nhận thông báo thay đổi và đánh giá sản phẩm sau khi giao hàng thành công.

---

## 🛠️ CÔNG CỤ HỖ TRỢ KIỂM THỬ (TESTING TOOL)

Để hỗ trợ kiểm thử nhanh chóng mà không cần thực hiện nhiều bước thanh toán thủ công, hệ thống đã tích hợp **Công cụ Test nhanh** trong màn hình Lịch sử Đơn hàng.
1. Từ **Trang chủ**, mở **App Drawer** (nút 3 gạch ngang góc trái) và chọn **Đơn hàng của tôi**.
2. Trên AppBar góc phải có nút **Menu 3 chấm** (icon `more_vert`). Click vào nút này để hiển thị các tùy chọn:
   * **Tạo đơn mẫu (6 đơn)**: Tự động khởi tạo 6 đơn hàng mẫu với đầy đủ các trạng thái (`pending`, `confirmed`, `shipping`, `delivered` - có cả đơn chưa đánh giá và đã đánh giá, `cancelled`) trên Firestore.
   * **Xóa tất cả đơn hàng**: Dọn dẹp sạch sẽ toàn bộ đơn hàng của tài khoản hiện tại trên Firestore để test lại từ đầu.

---

## 📋 CÁC KỊCH BẢN KIỂM THỬ CHI TIẾT (TEST CASES)

### Kịch bản 1: Đặt Hàng & Tạo Đơn (Order Creation)
* **Mục tiêu**: Đảm bảo quy trình mua sản phẩm và thanh toán hoạt động trơn tru.
* **Các bước thực hiện**:
  1. Đăng nhập vào ứng dụng (sử dụng email test hoặc tạo mới).
  2. Tại **Trang chủ**, chọn một sản phẩm còn hàng (`stock > 0`) -> Nhấn **Mua ngay** hoặc **Thêm vào giỏ** -> Đi tới **Giỏ hàng**.
  3. Ở màn hình **Giỏ hàng**, chọn sản phẩm muốn thanh toán -> Nhấn **Mua hàng**.
  4. Tại màn hình **Thanh toán (Checkout)**:
     * Nhấp **Thay đổi** ở phần địa chỉ để cập nhật thông tin giao hàng (họ tên, SĐT, số nhà, tỉnh/thành phố). Nhấn **Lưu**.
     * Nhập ghi chú cho người bán (ví dụ: *"Giao giờ hành chính"*).
     * Chọn phương thức thanh toán (ví dụ: **ZaloPay / VNPay** hoặc **COD**).
     * Kiểm tra hiển thị tổng tiền (Tổng tiền hàng + Phí ship 30.000đ).
  5. Nhấn nút **ĐẶT HÀNG** ở cuối trang.
* **Kết quả mong đợi (UI)**:
  * Xuất hiện SnackBar thông báo *"Đặt hàng thành công! Cảm ơn bạn đã mua hàng 💖"*.
  * Ứng dụng tự động điều hướng người dùng quay lại Trang chủ.
  * Giỏ hàng được làm sạch (sản phẩm đã mua bị xóa khỏi giỏ).
* **Kiểm tra trên Firebase Firestore**:
  * Vào Collection `orders` trên Firebase Console. Tìm document có `userId` khớp với tài khoản hiện tại.
  * Xác minh các trường thông tin:
    * `status`: `"pending"`
    * `paymentStatus`: `"unpaid"`
    * `shippingAddress`: Phải khớp với thông tin đã nhập lúc Checkout.
    * `items`: Danh sách sản phẩm, số lượng, hình ảnh thumbnail chính xác.

---

### Kịch bản 2: Xem Lịch Sử Đơn Hàng (Order History)
* **Mục tiêu**: Xác minh danh sách đơn hàng hiển thị chính xác và lọc đúng theo từng trạng thái.
* **Các bước thực hiện**:
  1. Đi tới màn hình **Đơn hàng của tôi** (từ App Drawer).
  2. Sử dụng menu 3 chấm chọn **Tạo đơn mẫu (6 đơn)** để tạo dữ liệu test.
  3. Quan sát danh sách đơn hàng và chuyển đổi qua lại giữa 5 tab:
     * **Tất cả**: Hiển thị toàn bộ đơn hàng (sắp xếp theo ngày đặt mới nhất ở trên cùng).
     * **Đang xử lý**: Chỉ hiển thị các đơn có trạng thái `pending` (Chờ xác nhận) hoặc `confirmed` (Đã xác nhận).
     * **Đang giao**: Chỉ hiển thị đơn có trạng thái `shipping`.
     * **Đã giao**: Chỉ hiển thị đơn có trạng thái `delivered`.
     * **Đã hủy**: Chỉ hiển thị đơn có trạng thái `cancelled`.
* **Kết quả mong đợi**:
  * Mỗi thẻ đơn hàng (`OrderCard`) phải hiển thị:
    * Mã đơn dạng rút gọn (8 ký tự đầu, viết hoa, ví dụ: `#ORDER_17`).
    * Badge trạng thái đúng màu sắc quy định.
    * Ảnh đại diện sản phẩm đầu tiên kèm tên sản phẩm. Nếu đơn có nhiều hơn 1 sản phẩm, hiển thị thêm dòng chữ `+N sản phẩm khác`.
    * Ngày đặt hàng (định dạng `dd/MM/yyyy`) và tổng số tiền thanh toán màu hồng đậm nổi bật.
  * Chuyển tab lọc phải cập nhật tức thì danh sách đơn hàng tương ứng mà không bị giật lag.

---

### Kịch bản 3: Chi Tiết Đơn Hàng & Theo Dõi Trạng Thái (Order Detail & Tracking)
* **Mục tiêu**: Kiểm tra giao diện chi tiết đơn hàng và timeline trạng thái stepper.
* **Các bước thực hiện**:
  1. Trong màn hình **Đơn hàng của tôi**, nhấp chọn một đơn hàng bất kỳ để vào màn hình **Chi tiết đơn hàng**.
  2. Đối với các đơn hàng bình thường (không bị hủy), kiểm tra phần **Theo dõi đơn hàng**:
     * Đơn hàng ở trạng thái nào thì bước đó trong timeline sẽ được tô màu hồng đậm (`AppColors.pastelPinkDark`), hiển thị cả tiêu đề và dòng mô tả dưới (sublabel).
     * Các bước trước đó đã đi qua được đánh dấu tích xanh lá cây (`AppColors.pastelGreenDark`).
     * Các bước chưa tới sẽ hiển thị màu xám mờ và ẩn dòng mô tả dưới.
  3. Đối với đơn hàng có trạng thái **Đã hủy (cancelled)**:
     * Timeline stepper bình thường sẽ ẩn đi.
     * Hiển thị một banner màu đỏ thông báo rõ ràng: *"Đơn hàng đã bị hủy - Đơn hàng này không còn được xử lý nữa."*.
  4. Kiểm tra các phần thông tin khác trên giao diện:
     * Mã đơn hàng, ngày giờ đặt hàng, trạng thái thanh toán, phương thức thanh toán.
     * Họ tên, SĐT, và địa chỉ người nhận.
     * Danh sách chi tiết các mặt hàng đã mua (ảnh, tên, phân loại màu/size, số lượng, giá tiền từng món).
     * Tổng số tiền thanh toán hiển thị trên dải nền gradient bo góc mềm mại.
* **Kết quả mong đợi**:
  * Các thông tin hiển thị chính xác 100% so với dữ liệu Firestore. Giao diện cân đối, sắc nét.

---

### Kịch bản 4: Hủy Đơn Hàng (Cancel Order)
* **Mục tiêu**: Cho phép khách hàng hủy đơn hàng khi shop chưa xác nhận.
* **Các bước thực hiện**:
  1. Chọn một đơn hàng đang ở trạng thái **Chờ xác nhận (pending)** để vào trang Chi tiết đơn hàng.
  2. Xác minh sự xuất hiện của nút **Hủy đơn hàng** (màu đỏ) ở dưới cùng trang.
  3. Chọn một đơn hàng ở trạng thái khác (`confirmed`, `shipping` hoặc `delivered`) -> Xác minh nút **Hủy đơn hàng** **KHÔNG** xuất hiện.
  4. Quay lại đơn hàng `pending`, nhấp vào nút **Hủy đơn hàng**.
  5. Khi hộp thoại xác nhận *"Hủy đơn hàng?"* xuất hiện:
     * Nhấp chọn **Giữ đơn** -> Hộp thoại đóng lại, đơn hàng giữ nguyên trạng thái.
     * Nhấp chọn **Xác nhận hủy** -> Tiến hành hủy đơn.
* **Kết quả mong đợi (UI)**:
  * Xuất hiện SnackBar báo *"✅ Đã hủy đơn hàng thành công"*.
  * Màn hình chi tiết tự động đóng, đưa người dùng quay lại danh sách đơn hàng.
  * Đơn hàng vừa hủy tự động chuyển sang tab **Đã hủy** (nhờ cơ chế lắng nghe real-time).
* **Kiểm tra trên Firebase Firestore**:
  * Document của đơn hàng trong collection `orders` được cập nhật:
    * `status`: `"cancelled"`
    * `updatedAt`: Thời gian cập nhật thực tế.

---

### Kịch bản 5: Thông Báo Trạng Thái Đơn Hàng (Order Notifications)
* **Mục tiêu**: Kiểm tra tính năng cập nhật trạng thái đơn hàng thời gian thực và thông báo đến người dùng.
* **Các bước thực hiện**:
  1. Đăng nhập tài khoản trên app.
  2. Mở ứng dụng quản trị Admin Dashboard hoặc trực tiếp thay đổi trường `status` của đơn hàng trên Firebase Console (Ví dụ: Đổi đơn hàng của bạn từ `pending` sang `confirmed`).
  3. Quan sát màn hình điện thoại khi đang mở ứng dụng.
* **Kết quả mong đợi (In-app Notification)**:
  * Ứng dụng hiển thị ngay lập tức một SnackBar thông báo dạng nổi (floating) màu tối tinh tế với tiêu đề *"Cập nhật đơn hàng"* và nội dung *"Đơn #XXXXXX: Đã xác nhận ✅"* kèm biểu tượng check.
  * Khi vào màn hình **Thông báo** (click biểu tượng chuông trên góc phải AppBar Trang chủ), thông báo mới này xuất hiện trong danh sách với trạng thái chưa đọc (chấm đỏ hoặc chữ in đậm). Nhấp vào thông báo sẽ đánh dấu là đã đọc.

---

### Kịch bản 6: Đánh Giá Sản Phẩm Khi Nhận Hàng Thành Công
* **Mục tiêu**: Đảm bảo khách hàng chỉ có thể đánh giá sản phẩm sau khi đã nhận được hàng thành công (chống đánh giá khống).
* **Các bước thực hiện**:
  1. Đi tới màn hình **Đơn hàng của tôi**, chọn tab **Đã giao**.
  2. Nhấp vào một đơn hàng bất kỳ để xem chi tiết.
  3. Kiểm tra các dòng sản phẩm trong đơn hàng:
     * Mỗi dòng sản phẩm phải hiển thị nút **Đánh giá sản phẩm** ở phía bên phải.
  4. Nhấp vào nút **Đánh giá sản phẩm**:
     * Mở ra một Bottom Sheet viết đánh giá.
     * Cho phép chọn số sao (1 đến 5 sao) bằng cách nhấp chọn trực tiếp (Interactive Star Rating Bar). Tiêu đề cảm nhận tương ứng tự động đổi (vd: 5 sao -> *Tuyệt vời 😍*, 1 sao -> *Không hài lòng 🙁*).
     * Nhập nhận xét vào ô nhập liệu (ví dụ: *"Sản phẩm rất đẹp, đóng gói cẩn thận!"*).
     * Nhấn **Gửi đánh giá**.
  5. Quay lại chi tiết đơn hàng, kiểm tra dòng sản phẩm vừa đánh giá.
* **Kết quả mong đợi**:
  * Sau khi gửi đánh giá thành công, xuất hiện SnackBar thông báo *"🎉 Cảm ơn bạn đã gửi đánh giá!"*.
  * Bottom Sheet tự đóng. Dòng sản phẩm tương ứng trong chi tiết đơn hàng chuyển đổi trạng thái lập tức hiển thị badge xanh lá cây nhẹ: `✓ Đã đánh giá` và nút đánh giá biến mất (ngăn cấm đánh giá lần 2).
* **Kiểm tra trên Firebase Firestore**:
  * Document của sản phẩm đó trong collection `products` được cập nhật lại trường `rating` (điểm trung bình mới) và `reviewCount` (tăng thêm 1).

---

### Kịch bản 7: Áp Dụng Mã Giảm Giá (Voucher Validation & Discount)
* **Mục tiêu**: Xác minh mã giảm giá (voucher) hoạt động đúng logic, áp dụng chính xác cho giá trị đơn hàng.
* **Các bước thực hiện**:
  1. Thực hiện **Hot Restart** (nhấn phím `R` viết hoa trong terminal chạy `flutter run`) hoặc khởi động lại ứng dụng.
     * *Lưu ý*: Điều này giúp hệ thống tự động kiểm tra và khởi tạo 2 mã voucher mẫu trên Firestore: **`TUPI10K`** (giảm 10.000đ cho đơn từ 50.000đ) và **`TUPINEW`** (giảm 20% tối đa 50.000đ).
  2. Thêm một số sản phẩm vào giỏ hàng sao cho tổng tiền hàng đạt khoảng `200.000₫` -> Nhấn **Mua hàng** để vào màn hình **Thanh toán (Checkout)**.
  3. Tại phần **Ưu đãi & Khách hàng thân thiết 🎁**, nhập một mã giảm giá không tồn tại (ví dụ: `SAICODE`) -> Nhấn **Áp dụng**.
     * *Kết quả mong đợi*: Xuất hiện thông báo lỗi màu đỏ dưới ô nhập: *"Mã giảm giá không tồn tại"*.
  4. Nhập mã voucher **`TUPI10K`** nhưng giảm số lượng hàng trong giỏ xuống dưới `50.000₫` (ví dụ: đặt sản phẩm 30.000đ) -> Nhấn **Áp dụng**.
     * *Kết quả mong đợi*: Báo lỗi màu đỏ: *"Đơn hàng chưa đạt giá trị tối thiểu (50.000₫)"*.
  5. Tăng tổng tiền hàng lên trên `50.000₫`, nhập mã voucher **`TUPI10K`** -> Nhấn **Áp dụng**.
     * *Kết quả mong đợi*:
       * Hiển thị dòng chữ *"Đã áp dụng: TUPI10K (Giảm 10.000₫)"* màu xanh lá cây kèm nút **Gỡ bỏ**.
       * Dòng *"Voucher giảm giá"* xuất hiện trong phần Chi tiết thanh toán hiển thị số tiền trừ là `-10.000₫`.
       * Tổng thanh toán được giảm tương ứng.
  6. Nhấn nút **Gỡ bỏ** bên cạnh mã giảm giá.
     * *Kết quả mong đợi*: Mã giảm giá bị gỡ, dòng giảm giá biến mất, tổng thanh toán trở về giá trị ban đầu.
  7. Nhập mã voucher **`TUPINEW`** (giảm 20% tối đa 50.000đ) -> Nhấn **Áp dụng**.
     * *Kết quả mong đợi*: Áp dụng thành công, số tiền giảm được tính chính xác bằng 20% tổng giá trị tiền hàng (không vượt quá 50.000đ).
  8. Nhấn **ĐẶT HÀNG** để hoàn tất đặt hàng.
* **Kiểm tra trên Firebase Firestore**:
  * Document của voucher tương ứng trong collection `vouchers` được cập nhật:
    * `usedCount`: Tăng thêm 1 đơn vị.

---

### Kịch bản 8: Khách Hàng Thân Thiết & Thăng Hạng Thành Viên (Loyalty Points & Tiers)
* **Mục tiêu**: Xác minh tích điểm khi giao hàng thành công, thăng hạng thành viên và dùng điểm thưởng khi thanh toán.
* **Các bước thực hiện**:
  1. **Tích điểm (Earning)**:
     * Đặt một đơn hàng có giá trị `300.000₫`.
     * Sử dụng tài khoản Admin chuyển trạng thái đơn hàng này sang **Đã giao (delivered)**.
     * Kiểm tra thông tin người dùng trong Profile hoặc Firestore.
     * *Kết quả mong đợi*: Người dùng được cộng `(300.000 / 100.000) = 3 điểm` tích lũy.
  2. **Thăng hạng (Tier upgrade)**:
     * Cộng thêm điểm cho người dùng (ví dụ: đạt `50 điểm` để lên Bạc, `200 điểm` lên Vàng, `500 điểm` lên Kim Cương).
     * Xem màn hình **Profile**:
       * *Kết quả mong đợi*: Hiển thị chính xác hạng hiện tại (Đồng/Bạc/Vàng/Kim Cương), điểm tích lũy hiện tại và thanh tiến trình (progress bar) thể hiện phần trăm điểm để đạt hạng tiếp theo.
  3. **Ưu đãi theo hạng thành viên (Tier Benefits)**:
     * Vào màn hình Checkout với tài khoản có hạng:
       * **Hạng Bạc**: Giảm 2% tổng tiền hàng trong Chi tiết thanh toán.
       * **Hạng Vàng**: Giảm 5% tổng tiền hàng + Phí vận chuyển hiển thị là `Freeship` (0đ).
       * **Hạng Kim Cương**: Giảm 10% tổng tiền hàng + Phí vận chuyển là `Freeship` (0đ).
  4. **Đổi điểm thưởng (Points Redemption)**:
     * Tại màn hình Checkout, bật công tắc **Dùng điểm Tupi Loyalty (Còn: X)**.
     * *Kết quả mong đợi*:
       * Dòng *"Đổi điểm thưởng"* hiển thị số tiền giảm trừ chính xác (`1 điểm = 1.000₫`).
       * Tổng thanh toán được giảm tương ứng.
       * Số tiền giảm điểm không được vượt quá số tiền cần trả còn lại sau khi trừ đi Voucher và giảm giá thành viên.
     * Nhấn **ĐẶT HÀNG** để hoàn tất đơn.
     * *Kết quả mong đợi*: Số điểm đã dùng bị trừ khỏi thuộc tính `points` của người dùng trong Firestore.
