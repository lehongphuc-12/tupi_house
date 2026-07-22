# HƯỚNG DẪN KIỂM THỬ (TEST GUIDE) – NGƯỜI 2: SẢN PHẨM & TÌM KIẾM/BỘ LỌC/ĐÁNH GIÁ

Tài liệu này hướng dẫn chi tiết cách kiểm thử các chức năng của **Người 2** trong dự án **Tupi House**. Các chức năng này tập trung vào trải nghiệm hiển thị sản phẩm tối ưu, tìm kiếm nhanh chống spam, bộ lọc đa tiêu chí, sắp xếp linh hoạt, phân trang lazy loading và thống kê đánh giá chi tiết.

---

## 📋 CÁC KỊCH BẢN KIỂM THỬ CHI TIẾT (TEST CASES)

### Kịch bản 1: Tối ưu Danh Sách Sản Phẩm (Product List UI & UX)
* **Mục tiêu**: Đảm bảo màn hình danh sách sản phẩm đẹp mắt, hiển thị đúng thông tin khuyến mãi và các chip danh mục.
* **Các bước thực hiện**:
  1. Mở ứng dụng, đi tới màn hình chính (**Khám phá Tulip Decor**).
  2. Quan sát phần đầu trang:
     * Dòng text chào mừng và mô tả tinh tế.
     * Dãy chip danh mục nằm ngang (Category Chips) có thể cuộn ngang mượt mà.
  3. Chọn các chip danh mục khác nhau -> Xác minh danh sách sản phẩm bên dưới được lọc tương ứng theo danh mục đã chọn.
  4. Quan sát từng thẻ sản phẩm (`OptimizedProductCard`):
     * Thẻ sản phẩm có hiệu ứng bo góc mượt mà, viền mỏng và đổ bóng nhẹ (Glassmorphism / Premium look).
     * Sản phẩm đang sale: Có tag **SALE** màu đỏ nổi bật, giá gốc gạch ngang màu xám và giá sale màu hồng đậm to rõ.
     * Số sao trung bình và số lượt đánh giá hiển thị tinh tế dưới tên sản phẩm.
     * Số lượng đã bán hiển thị ở góc thẻ sản phẩm.

---

### Kịch bản 2: Tìm Kiếm Với Cơ Chế Debounce (Debounced Search)
* **Mục tiêu**: Kiểm tra tính năng tìm kiếm sản phẩm theo tên hoặc danh mục, đảm bảo tối ưu hóa số lượng truy vấn tới Firestore.
* **Các bước thực hiện**:
  1. Nhấp vào ô **Tìm kiếm** ở đầu trang.
  2. Gõ nhanh từ khóa (ví dụ: *"Búp bê"* hoặc *"BB04"*).
  3. Chú ý tốc độ phản hồi của ứng dụng:
     * Khi đang gõ liên tục, danh sách sản phẩm **không** được tự động reload ngay lập tức (để tránh spam Firestore read).
     * Chỉ sau khi ngừng gõ khoảng **300ms** (cơ chế Debounce), danh sách sản phẩm mới tự động cập nhật kết quả tìm kiếm.
  4. Nhấp vào nút **X** ở bên phải ô tìm kiếm để xóa từ khóa -> Xác minh danh sách sản phẩm quay về trạng thái ban đầu và ô tìm kiếm trống.
* **Kết quả mong đợi**:
  * Tìm kiếm cho ra kết quả chính xác (lọc theo tên hoặc categoryName).
  * Cơ chế debounce hoạt động ổn định giúp giảm tải băng thông mạng.

---

### Kịch bản 3: Bộ Lọc Đa Tiêu Chí (Advanced Filter Sheet)
* **Mục tiêu**: Kiểm tra khả năng lọc sản phẩm theo danh mục, khoảng giá, rating tối thiểu và trạng thái kho hàng.
* **Các bước thực hiện**:
  1. Nhấp vào icon **Bộ lọc (Tune)** nằm bên phải ô tìm kiếm để hiển thị Bottom Sheet bộ lọc.
  2. Thực hiện các bộ lọc sau:
     * **Danh mục sản phẩm**: Nhấp chọn một danh mục cụ thể (ví dụ: *"Móc khóa"* hoặc *"Hoa"*).
     * **Khoảng giá**: Kéo thanh trượt (RangeSlider) chọn khoảng giá (ví dụ: từ `100.000₫` đến `400.000₫`). Xác minh nhãn hiển thị tiền VND thay đổi động theo vị trí ngón tay kéo.
     * **Đánh giá tối thiểu**: Nhấp chọn mức rating mong muốn (ví dụ: `4★+`).
     * **Trạng thái**: Bật công tắc **Chỉ hiện sản phẩm còn hàng** (`onlyInStock`).
  3. Nhấn **Áp dụng bộ lọc** ở cuối trang.
  4. Quan sát danh sách sản phẩm hiển thị trên UI.
  5. Mở lại Bottom Sheet bộ lọc -> Nhấn **Thiết lập lại** -> Kiểm tra xem các tiêu chí lọc có quay về trạng thái mặc định ban đầu không.
* **Kết quả mong đợi**:
  * Các sản phẩm hiển thị sau khi lọc phải thỏa mãn cùng lúc 100% tất cả các tiêu chí đã chọn.
  * Nếu không có sản phẩm nào phù hợp, ứng dụng hiển thị giao diện báo trống kèm nút **Bỏ bộ lọc**. Nhấp vào nút này sẽ reset toàn bộ lọc và đưa danh sách về mặc định.

---

### Kịch bản 4: Sắp Xếp Sản Phẩm (Sort Options)
* **Mục tiêu**: Xác minh các tùy chọn sắp xếp hoạt động chính xác.
* **Các bước thực hiện**:
  1. Nhấp vào icon **Bộ lọc (Tune)**.
  2. Ở phần **Sắp xếp theo**, chọn lần lượt các tùy chọn:
     * *Giá tăng dần ⬆️*: Xác minh các sản phẩm có giá thấp hơn được xếp trước.
     * *Giá giảm dần ⬇️*: Xác minh các sản phẩm có giá cao hơn được xếp trước.
     * *Rating cao ⭐️*: Xác minh sản phẩm có điểm đánh giá cao hơn (5.0, 4.8...) được đưa lên đầu.
     * *Bán chạy 🔥*: Xác minh sản phẩm có thuộc tính `sold` (số lượng đã bán) lớn hơn xếp trước.
  3. Nhấn **Áp dụng bộ lọc** và kiểm tra thứ tự sắp xếp của các thẻ sản phẩm.
* **Kết quả mong đợi**:
  * Thứ tự sắp xếp chính xác tuyệt đối theo tiêu chí được chọn.

---

### Kịch bản 5: Phân Trang Lazy Loading (Pagination)
* **Mục tiêu**: Tối ưu hóa tải trang bằng cách load trước một số lượng sản phẩm nhất định và tải thêm khi cuộn trang.
* **Các bước thực hiện**:
  1. Nhấp **Thiết lập lại** trong bộ lọc để hiển thị toàn bộ sản phẩm.
  2. Quan sát danh sách sản phẩm lúc mới load:
     * Chỉ hiển thị đúng **4 sản phẩm** đầu tiên (theo mặc định cấu hình `_displayedCount = 4`).
  3. Thực hiện cuộn (scroll) màn hình xuống phía dưới.
  4. Khi cuộn tới gần đáy màn hình (cách đáy khoảng `200px`):
     * Xuất hiện một vòng xoay loading nhỏ (`CircularProgressIndicator`) cùng dòng chữ *"Đang tải thêm sản phẩm..."*.
     * Danh sách tự động tải và hiển thị thêm **4 sản phẩm tiếp theo** (tổng cộng 8 sản phẩm).
  5. Tiếp tục cuộn xuống cho đến khi hết sản phẩm.
* **Kết quả mong đợi**:
  * Quá trình load thêm sản phẩm diễn ra tự động và mượt mà khi cuộn.
  * Khi đã tải hết toàn bộ sản phẩm trong database, ở cuối trang hiển thị thông báo: *"🌱 Đã hiển thị tất cả N sản phẩm"* và vòng xoay loading không còn xuất hiện.

---

### Kịch bản 6: Tối ưu Chi Tiết Sản Phẩm (Product Detail UI & UX)
* **Mục tiêu**: Kiểm tra giao diện chi tiết sản phẩm cao cấp, trình chiếu ảnh gallery và sản phẩm tương tự.
* **Các bước thực hiện**:
  1. Nhấp vào một sản phẩm bất kỳ từ màn hình danh sách để mở màn hình **Chi tiết sản phẩm**.
  2. Kiểm tra phần **Ảnh sản phẩm (Gallery)**:
     * Trượt ngang qua lại giữa các ảnh của sản phẩm.
     * Xác minh thanh chỉ số indicator (các chấm tròn nhỏ) co giãn và thay đổi độ đậm nhạt tương ứng với ảnh đang hiển thị (Animated Container Indicator).
  3. Kiểm tra phần **Mô tả sản phẩm**:
     * Đối với mô tả dạng HTML: Xác minh định dạng chữ, font, màu sắc hiển thị đúng chuẩn qua widget `Html`.
  4. Kiểm tra phần **Sản phẩm tương tự**:
     * Cuộn ngang dãy sản phẩm ở dưới cùng.
     * Xác minh các sản phẩm này có cùng `categoryId` với sản phẩm hiện tại và không chứa chính sản phẩm hiện tại. Nhấp vào một sản phẩm tương tự sẽ mở trang chi tiết của sản phẩm đó.

---

### Kịch bản 7: Xem Thống Kê & Nhận Xét (Reviews & Ratings Stats)
* **Mục tiêu**: Đảm bảo thống kê số lượng sao trung bình và danh sách nhận xét hiển thị chính xác.
* **Các bước thực hiện**:
  1. Trong màn hình chi tiết sản phẩm, cuộn xuống phần **Đánh giá & Nhận xét**.
  2. Kiểm tra bảng thống kê **Rating Breakdown**:
     * Điểm đánh giá trung bình hiển thị dạng chữ to đậm (ví dụ: `4.5` hoặc `5.0`) kèm số sao tương ứng.
     * Các thanh tiến trình nằm ngang (LinearProgressIndicator) thể hiện tỷ lệ phần trăm phân bố đánh giá từ 5 sao xuống 1 sao hoạt động chính xác.
  3. Kiểm tra danh sách nhận xét (`ReviewCard`):
     * Hiển thị đầy đủ tên người đánh giá, số sao đánh giá, thời gian đăng nhận xét, và nội dung bình luận của từng khách hàng.

---

### Kịch bản 8: Trừ/Hoàn Tồn Kho (Stock Deduction & Restoration)
* **Mục tiêu**: Xác minh số lượng tồn kho giảm khi đặt hàng thành công và được hoàn lại khi đơn hàng bị hủy.
* **Các bước thực hiện**:
  1. Chọn một sản phẩm (ví dụ: `Sản phẩm A`) có số lượng tồn kho hiện tại là `10`.
  2. Thực hiện đặt hàng với số lượng là `2` sản phẩm A.
  3. Sau khi đặt hàng thành công, kiểm tra tồn kho của sản phẩm A.
     * *Kết quả mong đợi*: Số lượng tồn kho giảm xuống `8`, số lượng đã bán (`sold`) tăng thêm `2`.
  4. Hủy đơn hàng vừa đặt (hoặc sử dụng tài khoản Admin chuyển trạng thái đơn hàng sang **Đã hủy (cancelled)**).
  5. Kiểm tra lại tồn kho của sản phẩm A.
     * *Kết quả mong đợi*: Số lượng tồn kho được hoàn lại thành `10`, số lượng đã bán (`sold`) giảm đi `2`.

---

### Kịch bản 9: Cảnh Báo Sắp Hết Hàng Trong Admin (Admin Low Stock Alert)
* **Mục tiêu**: Kiểm tra tính năng lọc sản phẩm sắp hết hàng và hiển thị nhãn cảnh báo màu đỏ dạng `⚠️ Sắp hết hàng (Còn: X)`.
* **Các bước thực hiện**:
  1. Đăng ký một tài khoản mới hoặc đăng nhập với email có chứa chữ **`admin`** (ví dụ: `admin@gmail.com`, mật khẩu tùy ý như `123456`).
     * *Lưu ý*: Hệ thống sẽ tự động phát hiện email và nâng quyền của tài khoản này lên `admin` trong Firestore, sau đó chuyển bạn thẳng đến **Admin Dashboard**.
  2. Chọn mục **Sản phẩm** trên menu quản lý để vào trang Quản lý sản phẩm.
  3. Chọn chip lọc **Cảnh báo tồn kho (Kho < 5)**.
     * *Kết quả mong đợi*: Danh sách chỉ hiển thị các sản phẩm có số lượng tồn kho nhỏ hơn 5 (bao gồm sản phẩm đã được hệ thống tự động cấu hình có `stock = 3` ở bước khởi động).
  4. Quan sát các sản phẩm trong danh sách này:
     * *Kết quả mong đợi*: Các sản phẩm này hiển thị dòng text cảnh báo màu đỏ có biểu tượng cảnh báo: `⚠️ Sắp hết hàng (Còn: 3)` thay vì dòng chữ thông thường `Kho X`.

---

### Kịch bản 10: Đếm Ngược Flash Sale (Flash Sale Countdown & Pricing)
* **Mục tiêu**: Xác minh hiển thị tag Flash Sale, đồng hồ đếm ngược hoạt động chính xác theo thời gian thực và áp dụng giá ưu đãi Flash Sale.
* **Các bước thực hiện**:
  1. Thực hiện **Hot Restart** (nhấn phím `R` viết hoa trong terminal chạy `flutter run`) hoặc khởi động lại ứng dụng.
     * *Lưu ý*: Hệ thống sẽ tự động cấu hình sản phẩm thứ 2 trong database thành sản phẩm Flash Sale với giá gốc `50.000₫`, giá Flash Sale `15.000₫`, thời gian bắt đầu trước hiện tại và thời gian kết thúc sau hiện tại 1 giờ.
  2. Xem danh sách sản phẩm ở Trang chủ (Product List):
     * *Kết quả mong đợi*:
       * Sản phẩm Flash Sale hiển thị tag màu cam **⚡ FLASH** nổi bật ở góc thẻ sản phẩm.
       * Giá bán hiển thị là `15.000₫`, giá gốc `50.000₫` bị gạch ngang.
  3. Nhấn vào sản phẩm Flash Sale để mở trang **Chi tiết sản phẩm**:
     * *Kết quả mong đợi*:
       * Xuất hiện Widget đếm ngược **FLASH SALE** màu cam/đỏ nổi bật hiển thị thời gian còn lại (Giờ : Phút : Giây) và các số đếm ngược thay đổi theo từng giây.
       * Badge **⚡ FLASH SALE** hiển thị cạnh tên sản phẩm.
       * Giá bán là giá Flash Sale (`15.000₫`).
  4. Nhấn **Mua ngay** hoặc **Thêm vào giỏ** -> Đi tới Checkout:
     * *Kết quả mong đợi*: Giá trị tiền hàng trong hóa đơn được tính dựa trên giá Flash Sale `15.000₫` thay vì giá gốc.
