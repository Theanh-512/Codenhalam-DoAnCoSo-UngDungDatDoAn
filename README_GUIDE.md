# 🚀 AI-Powered Food Platform - Hướng dẫn Cài đặt & Chạy Dự án

Dự án này là một nền tảng đặt đồ ăn tích hợp Trí tuệ nhân tạo (AI) để gợi ý nhà hàng và nhận diện món ăn. Hệ thống bao gồm 3 thành phần chính: Backend (.NET), AI Service (Python), và Frontend (Flutter).

---

## 🛠 1. Yêu cầu hệ thống
- **.NET SDK 9.0**
- **Python 3.9+** (Khuyên dùng 3.10)
- **Flutter SDK 3.x**
- **PostgreSQL/Supabase** (Dùng làm cơ sở dữ liệu chính)

---

## 🏗 2. Khởi chạy Backend (.NET)
Backend chịu trách nhiệm quản lý User, Nhà hàng, Thực đơn và Đơn hàng.

1. Di chuyển vào thư mục: `cd Backend/API`
2. Cấu hình Database: Mở file `appsettings.json`, cập nhật chuỗi kết nối `DefaultConnection` tới database của bạn.
3. Chạy lệnh:
   ```bash
   dotnet run
   ```
   *Mặc định chạy tại port: **5149***

---

## 🧠 3. Khởi chạy AI Service (FastAPI)
AI Service xử lý các thuật toán gợi ý (SCR Model) và nhận diện hình ảnh.

1. Di chuyển vào thư mục: `cd Backend/AIService`
2. Cài đặt thư viện:
   ```bash
   pip install -r requirements.txt
   ```
3. Đồng bộ mô hình (Chỉ thực hiện nếu thay đổi cấu hình):
   ```bash
   python fix_model.py
   ```
4. Chạy service:
   ```bash
   python main.py
   ```
   *Mặc định chạy tại port: **8000***

---

## 📱 4. Khởi chạy Frontend (Flutter)
Ứng dụng di động dành cho người dùng.

1. Di chuyển vào thư mục: `cd Frontend/flutter`
2. Cài đặt packages:
   ```bash
   flutter pub get
   ```
3. Kiểm tra file `lib/common/globs.dart` để đảm bảo `baseUrl` trỏ đúng vào IP/Port của Backend.
4. Chạy ứng dụng:
   ```bash
   flutter run -d chrome  # Hoặc thiết bị thật/giả lập
   ```

---

## 📝 5. Lưu ý quan trọng
- **Thứ tự chạy:** Nên chạy Backend trước -> AI Service -> Frontend.
- **Dữ liệu mẫu (Seed):** Khi Backend chạy lần đầu, nó sẽ tự động tạo các bảng và dữ liệu mẫu (Users, Restaurants, Categories).
- **Lỗi AI Mismatch:** Nếu thấy lỗi `size mismatch` trong log AI, hãy chạy `python fix_model.py` trong thư mục `AIEngine` hoặc `AIService`.

---
*Chúc bạn có buổi thuyết trình/demo thành công!*
