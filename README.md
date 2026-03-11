# 🍔 FoodApp - Hệ Thống Đặt Đồ Ăn Trực Tuyến Tích Hợp AI & Location

Đây là dự án được thiết kế chuẩn chỉnh từ đầu, phục vụ cho Đồ Án Cơ Sở và sẵn sàng mở rộng quy mô (Scale-up) để làm Đồ Án Chuyên Ngành sau này.
Dự án được xây dựng dựa trên việc áp dụng các công nghệ hiện đại và kiến trúc tiên tiến.

## 🚀 Công nghệ sử dụng
- **Backend:** .NET Core Web API (Sử dụng kiến trúc Clean Architecture / N-Tier để dễ dàng scale và thêm function lớn về sau).
- **Frontend:** Angular 18 (Với Angular, bạn có thể build làm Web, hoặc dễ dàng port sang ứng dụng di động thông qua Ionic hoặc Capacitor).
- **Định hướng phần mở rộng chuyên sâu (AI & Location):** 
  - Tích hợp Location-based services (nhận gợi ý địa điểm qua GPS/Google Maps).
  - Tích hợp chức năng nhận diện hình ảnh thức ăn bằng AI (ML.NET, Azure Cognitive hoặc custom model Python connect via REST/gRPC).

## 🗂 Cấu trúc thư mục (Folder Structure)

Chúng ta có 2 phần chính là Backend và Frontend được tách biệt hoàn toàn để quản lý độc lập theo chuẩn kiến trúc Clean Architecture cho Backend:

```text
/
├── Backend/                       # Chứa giải pháp (Solution) .NET Core
│   ├── FoodApp.sln                # File Solution chính
│   ├── API/                       # Lớp Presentation: Endpoints API (Controllers, Program.cs) - Nhận Request từ UI
│   ├── Application/               # Lớp Ứng dụng: Chứa Use Cases, DTOs, Business Logic, Interfaces (Không phụ thuộc vào bất cứ UI hay DB nào)
│   ├── Domain/                    # Lớp Cốt lõi: Chứa Entities, Value Objects, Enums, Exceptions cốt lõi của bài toán
│   └── Infrastructure/            # Lớp Cơ sở hạ tầng: DbContext (Entity Framework), Repositories, kết nối Third-party APIs (AI/Location), Email, Auth
│
└── Frontend/                      # Chứa ứng dụng Web Angular
    └── food-app-ui/               
        ├── src/
        │   ├── app/
        │   │   ├── components/    # Chứa UI components tái sử dụng
        │   │   ├── pages/         # Chứa các trang View màn hình
        │   │   ├── core/          # Chứa Models, Services gọi API, Interceptors
        │   │   └── shared/        # Các utils, pipes, directives dùng chung
        │   └── assets/            
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

### 2. Chạy Frontend
Mở Terminal, đi vào thư mục Frontend/food-app-ui:
```bash
cd Frontend/food-app-ui
npm install
npm start
```
Truy cập `http://localhost:4200/` trên trình duyệt.
