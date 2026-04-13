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

## 🛠 Hướng dẫn Clone và Khởi chạy (Dành cho máy mới)

Dự án này đã được tự động hóa tối đa. Toàn bộ cơ sở dữ liệu đều được lưu trữ tập trung trên **Supabase Cloud**. Khi bạn clone về một máy tính hoàn toàn mới, dữ liệu tự hiển thị đẩy đủ mà không cần cấu hình SQL thủ công.

### 1. Đồng bộ và Chạy Backend (.NET Core 9.0)
Hệ thống được tích hợp **Auto-Migration & Data Seeding**. Mỗi khi Backend chạy lên, nó sẽ tự động nhận diện kết nối Database Supabase và bơm dữ liệu mặc định (tài khoản admin, nhà hàng) nếu DB còn trống.

Mở Terminal và đi vào thư mục Backend/API:
```powershell
cd Backend/API
dotnet run
```
*Lưu ý: Bạn không cần phải chạy `dotnet ef database update` vì `Program.cs` đã được thiết lập để tự động chạy Migrate và Seed data khi gọi lệnh `dotnet run` (Sử dụng tệp `SeedData.cs`).*

- URL API cho Frontend: `http://localhost:5149` (hoặc cổng hiển thị trong Terminal)
- Dữ liệu có sẵn trên Supabase: Database `Codenhalam123`

### 2. Chạy Frontend Mobile & Web (Flutter)
Mở Terminal mới, đi vào thư mục Frontend/flutter:
```powershell
cd Frontend/flutter
flutter pub get
flutter run -d windows  # Hoặc -d chrome để chạy Web
```

### 🔐 Thông tin Tài khoản Mặc định (Seed Data)
Hệ thống đã tự động tạo sẵn các tài khoản sau để bạn test đăng nhập (API Backend):
- **Tài khoản Khách hàng**: `test1@gmail.com` / Pass: `123456`
- **Tài khoản Admin (Quản trị)**: `admin@foodapp.com` / Pass: `123456` *(Tính năng: Vào thẳng Admin Dashboard)*

### 3. Chạy Frontend Web Dự phòng (Angular - Nếu sử dụng)
```powershell
cd Frontend/angular
npm install
npm start
```
Truy cập `http://localhost:4200/` trên trình duyệt.