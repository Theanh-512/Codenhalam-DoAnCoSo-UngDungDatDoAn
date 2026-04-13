## 🚀 Hệ sinh thái M-CARS-Food (AI & Location)

Dự án hiện đã được nâng cấp lên tầm nhìn **M-CARS-Food**, tập trung vào việc cá nhân hóa trải nghiệm người dùng thông qua Trí tuệ nhân tạo.

### 🗺 Lộ trình phát triển đã triển khai:

#### Giai đoạn 1: Nền tảng Cơ sở
- **Backend:** Cấu trúc Clean Architecture hoàn chỉnh.
- **Entities:** `User`, `Restaurant` (Vendor), `FoodItem`, `Order`, `TrackingLog`.
- **Frontend (Mobile):** Khởi tạo khung ứng dụng **Flutter** với Riverpod.

#### Giai đoạn 2: Ngữ cảnh & Tracking
- **Location Service:** Tích hợp tọa độ (GPS) vào `Restaurant` và `TrackingLog`.
- **Behavior Logging:** `TrackingService` đã sẵn sàng ghi lại thao tác Click/View của người dùng.

#### Giai đoạn 3: AI Core (SCR Model)
- **Module AICore:** Thiết lập khung cho mô hình **LSTM** (Sở thích dài hạn) và **Attention** (Sở thích ngắn hạn).
- **Prediction:** Thuật toán dự đoán Top-N quán ăn dựa trên ngữ cảnh thực tế ($U, L, T$).

#### Giai đoạn 4: Tối ưu
- **Caching & Async:** Sẵn sàng tích hợp Redis và Background Services cho luồng Tracking nặng.

---
**Lưu ý kỹ thuật:** 
Do môi trường terminal đang bị giới hạn truy cập ổ `D:`, vui lòng thực hiện các lệnh sau để đồng bộ hệ thống:
1. `dotnet sln add Backend/AICore/AICore.csproj` (Thêm module AI vào Solution).
2. `dotnet ef migrations add UpdateMCarsFoodCore -p Backend/Infrastructure -s Backend/API` (Cập nhật DB).
3. `flutter pub get` (Trong thư mục Frontend/flutter).

## 🗂 Cấu trúc thư mục mới (Folder Structure)

```text
/
├── Backend/           # .NET Core 9.0 (API, AICore, Domain, Infrastructure, Application)
├── Database/          # Script SQL cho Supabase
├── Frontend/          
│   ├── flutter/       # Ứng dụng Mobile (Flutter + Supabase)
│   └── angular/       # Ứng dụng Web (Angular)
└── README.md
```

## 🧠 Kiến trúc Clean Architecture (Backend)

Sự phụ thuộc (Dependencies) của các project trong Backend được quy định chặt chẽ:
1. `Domain` nằm ở trung tâm và **không phụ thuộc** vào bất kỳ project nào.
2. `Application` **phụ thuộc vào** `Domain`. Đây là nơi chứa logic nghiệp vụ đặc thù của ứng dụng.
3. `Infrastructure` **phụ thuộc vào** `Application` và `Domain`. Nhiệm vụ của nó là implement các Interfaces (vd: IRepository) mà lớp `Application` định nghĩa để truy xuất Database hoặc gọi API ngoài (AI API, Map API).
4. `API` (Presentation) **phụ thuộc vào** `Application` và `Infrastructure`. Nó chỉ làm nhiệm vụ nhận Request, gọi Application Layer xử lý, và trả về Response.

Thiết kế này đặc biệt mạnh mẽ khi ở Đồ Án Chuyên Ngành bạn muốn nhúng thêm AI hoặc đổi Database, bạn chỉ cần sửa ở `Infrastructure` mà không làm thay đổi hay gây lỗi cho logic nghiệp vụ trong `Application`.

## 🛠 Hướng dẫn phát triển cơ bản

### 1. Chạy Backend
Mở Terminal, đi vào thư mục Backend/API:
```bash
cd Backend/API
dotnet run
```
Sau đó truy cập link `https://localhost:<port>/swagger` hiển thị trên terminal để xem và giao tiếp với API.

### 2. Chạy Frontend Web (Angular)
Mở Terminal, đi vào thư mục Frontend/angular:
```bash
cd Frontend/angular
npm install
npm start
```

### 3. Chạy Frontend Mobile (Flutter)
Mở Terminal, đi vào thư mục Frontend/flutter:
```bash
cd Frontend/flutter
flutter pub get
flutter run
```
Truy cập `http://localhost:4200/` trên trình duyệt.


password supabase : Codenhalam123