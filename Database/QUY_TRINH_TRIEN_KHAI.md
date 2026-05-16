# 📖 HƯỚNG DẪN TRIỂN KHAI HỆ THỐNG (SETUP GUIDE)

Tài liệu này hướng dẫn chi tiết các bước để một thành viên mới sau khi **Clone** dự án có thể chạy được toàn bộ hệ thống (Backend, AI, Frontend).

---

## 🛠 1. YÊU CẦU PHẦN MỀM (PREREQUISITES)

Trước khi bắt đầu, hãy đảm bảo máy bạn đã cài đặt:
- **.NET 9.0 SDK**
- **Python 3.10+** (Khuyến nghị 3.11 hoặc 3.12 để ổn định nhất)
- **Node.js** (Nếu dùng Angular)
- **Flutter SDK** (Nếu dùng Mobile)
- **PostgreSQL** hoặc tài khoản **Supabase**.

---

## 🗄 2. CẤU HÌNH DATABASE (MỨC ƯU TIÊN 1)

1.  Truy cập vào Supabase hoặc PostgreSQL của bạn.
2.  Mở file `Database/supabase_schema.sql`.
3.  Copy toàn bộ nội dung SQL và thực thi (Run query) trên Database của bạn để tạo các bảng: `Users`, `Restaurants`, `FoodItems`, `Orders`, `TrackingLogs`, v.v.
4.  Cập nhật **Connection String** trong file:
    *   `Backend/API/appsettings.json` (hoặc `appsettings.Development.json`)

---

## ⚙️ 3. CẤU HÌNH BACKEND (.NET 9)

Mở Terminal tại thư mục gốc và chạy:

```powershell
# Di chuyển vào folder API
cd Backend/API

# Khôi phục các gói NuGet
dotnet restore

# Chạy ứng dụng (Mặc định chạy tại port 5000/5001)
dotnet run
```

---

## 🧠 4. CẤU HÌNH AI SERVICE (PYTHON)

Dịch vụ AI cần được khởi chạy để các tính năng Gợi ý và Nhận diện hoạt động.

```powershell
# Di chuyển vào folder AI Service
cd Backend/AIService

# Cài đặt thư viện cần thiết
python -m pip install -r requirements.txt
python -m pip install torch torchvision torchaudio Pillow pandas scikit-learn

# Khởi chạy AI Server (Port 8000)
python main.py
```

---

## 📱 5. CẤU HÌNH FRONTEND (FLUTTER)

```powershell
# Di chuyển vào folder Flutter
cd Frontend/flutter

# Lấy các thư viện
flutter pub get

# Chạy ứng dụng (Chọn thiết bị Chrome hoặc Emulator)
flutter run
```

---

## 🚩 6. DANH SÁCH PORT MẶC ĐỊNH

| Dịch vụ | URL | Nhiệm vụ |
| :--- | :--- | :--- |
| **Backend API** | `http://localhost:5000` | Xử lý Logic & Database |
| **AI Service** | `http://localhost:8000` | Gợi ý & Nhận diện món ăn |
| **Flutter App** | Mobile/Web | Giao diện khách hàng |

---
*Hướng dẫn được soạn bởi Antigravity AI - Hỗ trợ triển khai đồ án chuyên sâu.*


File AIEngine/MODEL_EXPLANATION.md là nơi chứa đựng toàn bộ nền tảng lý thuyết và các công thức toán học cốt lõi áp dụng vào bài toán của bạn. Đây là tài liệu cực kỳ giá trị để bạn đưa vào báo cáo đồ án.

Dưới đây là tóm tắt các file chứa thuật toán và công thức tương ứng:

1. Thuật toán Sở thích Ngắn hạn (Short-term Preference)
File: AIEngine/models/short_term.py
Lý thuyết: Self Multi-Head Attentive Aggregation.
Công thức: $$ \text{Attention}(Q, K, V) = \text{softmax}\left(\frac{QK^T}{\sqrt{d_k}}\right)V $$
Giải thích: AI sử dụng cơ chế chú ý (Attention) để tính toán sự tương quan giữa các món ăn người dùng vừa xem trong phiên (Session). Hệ số $\beta_j$ sinh ra từ hàm softmax cho biết món ăn nào đang là "mục tiêu chính" của khách hàng.
2. Thuật toán Sở thích Dài hạn (Long-term Preference)
File: AIEngine/models/long_term.py
Lý thuyết: Time-LSTM với Cổng Thời Gian (Time Gates).
Giải thích: Không giống LSTM thông thường, thuật toán này có thêm các cổng $T_1, T_2$ phụ thuộc vào khoảng cách thời gian $\Delta t$ giữa các lần tương tác. Điều này giúp AI hiểu được tính chu kỳ (ví dụ: thói quen ăn Phở vào sáng Chủ Nhật).
3. Thuật toán Hợp nhất Đa phương thức (Multimodal Fusion)
File: AIEngine/models/scr_model.py
Lý thuyết: Hierarchical Attention Fusion.
Giải thích: Đây là nơi kết hợp 3 thành phần: Đặc trưng hình ảnh (từ ảnh chụp), Sở thích ngắn hạn, và Sở thích dài hạn. AI tự học xem yếu tố nào quan trọng hơn tại thời điểm đó để đưa ra gợi ý cuối cùng.
4. Công thức lọc theo Ngữ cảnh (Context-Aware)
File: backend/AIService/main.py (Hàm predict)
Công thức Haversine: Tính khoảng cách địa lý thực tế.
Công thức Penalty: $Score_{final} = Score_{AI} \times Penalty_{distance}$ (Dùng để giới hạn bán kính 10km như bạn yêu cầu).