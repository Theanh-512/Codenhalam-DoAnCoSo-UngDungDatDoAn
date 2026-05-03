# BÁO CÁO TIẾN ĐỘ DỰ ÁN: HỆ THỐNG ĐẶT MÓN ĂN THÔNG MINH (M-CARS AI)

Tài liệu này tổng hợp toàn bộ các tính năng đã thực hiện và cấu trúc hệ thống hiện tại để phục vụ việc báo cáo và quản lý dự án.

---

## 🏗 1. KIẾN TRÚC HỆ THỐNG (ARCHITECTURE)
Hệ thống được xây dựng theo mô hình **Microservices & Multi-Platform**:
- **Backend Core**: .NET 9.0 (C#) - Xử lý logic nghiệp vụ, quản lý Database (PostgreSQL/Supabase).
- **AI Microservice**: FastAPI (Python) - Phân tích dữ liệu bằng Deep Learning models.
- **Mobile App**: Flutter - Dành cho khách hàng (Android/iOS).
- **Web Admin/App**: Angular 17+ - Dành cho quản trị và giao diện Web.

---

## 🧠 2. CÁC TÍNH NĂNG AI & THUẬT TOÁN (CORE RESEARCH)
Đây là phần quan trọng nhất giúp đồ án đạt tiêu chuẩn nghiên cứu khoa học:

### I. Gợi ý thông minh (SCR Model)
- **Thuật toán**: Deep Sequential Model cho Context-Aware POI Recommendation.
- **Chức năng**: Dự đoán nhà hàng người dùng muốn đến dựa trên:
    - *Short-term preference*: Các quán vừa xem/đặt.
    - *Long-term preference*: Thói quen cũ.
    - *Context*: Vị trí thực tế (Lat/Lng) và thời gian hiện tại.
- **Trạng thái**: Đã tích hợp luồng gọi API từ Flutter/Angular sang Backend.

### II. Nhận diện món ăn (Computer Vision)
- **Công nghệ**: CNN - EfficientNetB4 (Transfer Learning).
- **Chức năng**: Người dùng chụp ảnh món ăn -> AI phân tích tên món -> Tìm các nhà hàng xung quanh bán món đó.
- **Trạng thái**: Đã xây dựng giao diện Dashboard AI quét ảnh và logic xử lý API Vision.

### III. Tối ưu lộ trình giao hàng (Route Optimization)
- **Thuật toán**: Greedy Algorithm (TSP Heuristic) kết hợp khoảng cách Haversine.
- **Chức năng**: Tự động tính toán đường đi ngắn nhất cho Shipper khi giao nhiều đơn hàng cùng lúc.
- **Trạng thái**: Đã hoàn thiện thuật toán trong C# và giao diện bản đồ lộ trình trong Admin.

---

## 💻 3. CHI TIẾT CÁC PHÂN HỆ FRONTEND

### A. Mobile (Flutter)
- **Authentication**: Đăng nhập/Đăng ký, quản lý Token.
- **Home**: Banner AI, danh sách quán ăn theo danh mục.
- **AI Recommendation**: Màn hình xem gợi ý cá nhân hóa.
- **Food Recognition**: Tích hợp Camera để nhận diện món.
- **Cart & Order**: Quy trình đặt món và lưu lịch sử đơn hàng.
- **Admin Mobile**: Dashboard xem thống kê nhanh.

### B. Web Admin (Angular)
- **Giao diện**: Sử dụng Tailwind CSS, thiết kế Premium (Dark navigation, Glassmorphism).
- **Authentication**: Login phân quyền Admin/User.
- **Admin Dashboard**: Thống kê số liệu thực tế (Nhà hàng, Đơn hàng, Doanh thu).
- **CRUD Management**:
    - Quản lý Nhà hàng: Thêm, sửa, xóa, tìm kiếm.
    - Quản lý Người dùng & Đơn hàng (Cấu hình sẵn Route).
- **UI Components Reusable**: Hệ thống nút bấm và thẻ thống kê dùng chung giúp tối ưu code.

---

## ⚙️ 4. BACKEND & DATABASE (.NET 9)
- **Controllers**: 
    - `RestaurantsController`: CRUD nhà hàng + Gợi ý AI.
    - `OrdersController`: Xử lý đơn hàng + Thuật toán tối ưu lộ trình.
    - `UsersController`: Quản lý tài khoản + Đăng nhập.
- **Infrastructure**: Giao tiếp PostgreSQL qua Entity Framework Core.
- **Seed Data**: Đã cấu hình sẵn dữ liệu mẫu để Clone code về là chạy được ngay.

---

## 🚩 5. CÁC CÔNG VIỆC TIẾP THEO (NEXT STEPS)
1.  **Model Training**: Chạy mã nguồn Python để train mô hình SCR với tập dữ liệu Foursquare.
2.  **Payment Integration**: Tích hợp cổng thanh toán (Momo/VNPAY).
3.  **Real-time Tracking**: Sử dụng SignalR để theo dõi vị trí Shipper trên bản đồ.

*Tài liệu được tạo tự động bởi Antigravity AI - Hỗ trợ phát triển đồ án chuyên sâu.*
