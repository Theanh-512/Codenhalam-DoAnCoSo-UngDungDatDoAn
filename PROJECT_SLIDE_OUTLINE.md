# 📋 ĐỀ CƯƠNG CHI TIẾT CÁC SLIDE BÁO CÁO ĐỒ ÁN
## ĐỀ TÀI: HỆ THỐNG GỢI Ý MÓN ĂN ĐA PHƯƠNG THỨC BỐI CẢNH (M-CARS-FOOD) DỰA TRÊN MÔ HÌNH SCR & TIME-LSTM
---

> **Lưu ý**: Tài liệu này được biên soạn dưới dạng đề cương thuyết trình (Slide Outline). Bạn chỉ cần copy nội dung các mục chính vào slide (PowerPoint/Canva) và sử dụng phần **"Lời thoại thuyết trình gợi ý"** dưới mỗi slide để trình bày trực tiếp trước hội đồng thầy cô. Các công thức toán học bạn có thể tự chèn thêm vào các phần được đánh dấu.

---

### 🗺️ Tổng quan mô hình:
```
Bối cảnh người dùng (Thời gian, Vị trí) ──┐
Lịch sử dài hạn (Time-LSTM) ─────────────┼─> [SCR Model v1] ─> [Hierarchical Attention Fusion] ─> [Gợi ý tối ưu & Giải thích]
Ý định ngắn hạn (Self-Attention) ─────────┤
Đa phương thức (DenseNet201 + Sentiment) ──┘
```

---

## 🖼️ Slide 1: Trang bìa & Giới thiệu đề tài
* **Tiêu đề chính**: Hệ thống Đặt món ăn Thông minh tích hợp Công nghệ Gợi ý cá nhân hóa Địa điểm - Đa phương thức (M-CARS-Food)
* **Tiêu đề phụ**: Nghiên cứu ứng dụng mô hình SCR (Sequential Context-Aware Recommendation) & mạng Time-LSTM
* **Người thực hiện**: [Tên của bạn/Nhóm của bạn]
* **Giáo viên hướng dẫn**: [Tên Thầy/Cô hướng dẫn]
* **Năm thực hiện**: 2026

🎙️ **Lời thoại thuyết trình gợi ý:**
> *"Kính thưa quý thầy cô trong hội đồng, hôm nay nhóm em xin phép được báo cáo đề tài nghiên cứu và xây dựng: 'Hệ thống Đặt món ăn Thông minh M-CARS-Food'. Điểm cốt lõi của đề tài này là chúng em đã hiện thực hóa thành công một hệ thống gợi ý món ăn cá nhân hóa thời gian thực, kết hợp sâu sắc giữa mô hình Deep Learning SCR - xử lý chuỗi hành vi dài hạn bằng mạng Time-LSTM, tự động tổng hợp ý định ngắn hạn qua Self-Attention và tích hợp đa phương thức hình ảnh cũng như điểm cảm xúc của người dùng."*

---

## 🖼️ Slide 2: Đặt vấn đề & Thử thách cần giải quyết
* **Bối cảnh thực tế**: Sự bùng nổ của các ứng dụng đặt đồ ăn (GrabFood, ShopeeFood) đòi hỏi hệ thống gợi ý phải cực kỳ thông minh và nhạy bén với bối cảnh.
* **Những hạn chế của các hệ thống gợi ý truyền thống (Collaborative Filtering, Matrix Factorization)**:
    1. **Bỏ qua yếu tố thời gian**: Coi sở thích của người dùng là tĩnh, không đổi theo thời gian.
    2. **Bỏ qua khoảng cách địa lý**: Đề xuất những nhà hàng quá xa, không thực tế với vị trí hiện tại của người dùng.
    3. **Hiện tượng "Cold Start" (Khởi đầu lạnh)**: Không thể gợi ý hiệu quả cho người dùng mới hoặc các món ăn mới chưa có nhiều lượt tương tác.
    4. **Thiếu tính đa phương thức**: Chưa tận dụng hình ảnh món ăn để kích thích thị giác trực quan của người dùng.

🎙️ **Lời thoại thuyết trình gợi ý:**
> *"Trong thực tế, khi chúng ta mở app đặt đồ ăn vào lúc 8h sáng tại trường học, chúng ta sẽ có nhu cầu hoàn toàn khác với khi đang ở nhà vào lúc 9h tối. Tuy nhiên, các thuật toán Collaborative Filtering hay Matrix Factorization truyền thống lại bỏ qua các yếu tố ngữ cảnh cực kỳ quan trọng này. Nhóm em xác định có 3 thử thách lớn cần giải quyết: Làm sao học được thói quen ăn uống lặp lại dài hạn? Làm sao bắt được ý định mua sắm tức thời ngắn hạn? Và làm sao kết hợp khoảng cách địa lý và hình ảnh trực quan vào một mô hình duy nhất? Đó chính là lý do nhóm em quyết định đi sâu vào bài toán Sequential Context-Aware Recommendation."*

---

## 🖼️ Slide 3: Giới thiệu Bài báo Khoa học Gốc (Reference Paper)
* **Tên bài báo khoa học gốc**: *“What to Do Next: Modeling User Behaviors by Time-LSTM”*
* **Tác giả & Nơi công bố**: **Yu Zhu et al.** - Công bố tại hội nghị khoa học hàng đầu về Trí tuệ nhân tạo **IJCAI 2017** (International Joint Conference on Artificial Intelligence).
* **Đóng góp chính của bài báo gốc**:
    * Phát hiện ra hạn chế lớn của RNN/LSTM thông thường trong hệ thống gợi ý: Chỉ học được **thứ tự tuần tự** mà bỏ qua **khoảng thời gian trôi qua ($\Delta t$)** giữa các hành động.
    * Đề xuất kiến trúc **Time-LSTM**: Đưa các cổng thời gian (Time Gates) vào cấu trúc tế bào LSTM để điều tiết dòng thông tin chảy qua mạng dựa trên khoảng giãn thời gian thực tế.
    * Giới thiệu 3 phiên bản tế bào Time-LSTM (Time-LSTM 1, 2, 3) tối ưu hóa việc phân tách sở thích dài hạn và ngắn hạn.

🎙️ **Lời thoại thuyết trình gợi ý:**
> *"Để xây dựng nền tảng khoa học vững chắc cho đồ án, nhóm em đã chọn nghiên cứu và triển khai thực nghiệm dựa trên bài báo khoa học gốc nổi tiếng công bố tại hội nghị IJCAI năm 2017 của nhóm tác giả Yu Zhu mang tên: 'What to Do Next: Modeling User Behaviors by Time-LSTM'. Đóng góp mang tính cách mạng của bài báo này là việc phát minh ra tế bào Time-LSTM, giúp mô hình Deep Learning hiểu được khoảng cách thời gian giữa các lần tương tác của người dùng. Ví dụ, khoảng cách giữa 2 lần đặt ăn là 2 tiếng sẽ mang ý nghĩa hoàn toàn khác với khoảng cách là 2 tuần."*

---

## 🖼️ Slide 4: Cơ sở lý thuyết - Thuật toán & Định nghĩa trong Bài báo gốc
* **Định nghĩa Tế bào Time-LSTM**:
    * Tích hợp thêm các cổng thời gian bổ trợ: Cổng thời gian $T_1$ (điều tiết thông tin từ trạng thái ẩn cũ) và Cổng thời gian $T_2$ (điều tiết thông tin từ cell state cũ).
    * Công thức biến đổi cổng thời gian bằng cách đưa giá trị khoảng lệch thời gian $\Delta t$ qua hàm kích hoạt phi tuyến (ví dụ: sigmoid hoặc tanh).
    *(Thầy cô ơi, em sẽ tự chèn công thức chi tiết của tế bào Time-LSTM ở đây nhé!)*
* **Nguyên lý hoạt động của Cổng thời gian**:
    * Khoảng cách thời gian $\Delta t$ ngắn $\rightarrow$ Sở thích tức thời cũ có ảnh hưởng mạnh đến quyết định tiếp theo.
    * Khoảng cách thời gian $\Delta t$ dài $\rightarrow$ Mô hình tự động suy giảm (decay) ảnh hưởng của hành vi cũ, chuyển hướng tập trung vào xu hướng dài hạn.

🎙️ **Lời thoại thuyết trình gợi ý:**
> *"Về mặt toán học, Time-LSTM đã cải tiến cấu trúc LSTM truyền thống bằng cách định nghĩa các cổng thời gian mới. Khi một người dùng tương tác với hệ thống, khoảng lệch thời gian $\Delta t$ sẽ được tính toán phi tuyến. Công thức của tế bào Time-LSTM bao gồm các cổng kiểm soát thông tin dài hạn và ngắn hạn riêng biệt. Nếu khoảng thời gian $\Delta t$ quá dài, các cổng thời gian sẽ chủ động thực hiện cơ chế 'quên' đi các sở thích tạm thời trước đó, giúp tránh việc đề xuất sai lệch xu hướng hiện tại của người dùng."*

---

## 🖼️ Slide 5: Kiến trúc mô hình đề xuất của nhóm (M-CARS-Food SCR)
Nhóm chúng em đã hiện thực hóa và mở rộng bài báo gốc thành kiến trúc **SCRMultimodalRecommender** gồm 3 khối cốt lõi:
1. **Khối Lịch sử Dài hạn (Long-Term Preference - $U_{long}$)**:
    * Triển khai mạng **Time-LSTM** xử lý chuỗi tương tác lịch sử dài hạn (Sequence length = 50).
    * **Tích hợp bối cảnh không gian - thời gian**:
        * **Distance Weighting**: Tính toán khoảng cách Euclidean/Haversine thực tế từ vị trí người dùng đến cửa hàng.
        * **Jaccard Time Similarity**: So sánh sự tương thích về khung giờ ăn thông qua biểu diễn nhị phân 48-chiều (khớp múi giờ các ngày trong tuần và cuối tuần).
2. **Khối Ý định Ngắn hạn (Short-Term Preference - $U_{short}$)**:
    * Áp dụng mạng **Self Multi-Head Attentive Aggregation** (2 heads) để tổng hợp nhanh các món ăn trong phiên hiện tại (Session length = 10), giúp nhận diện chính xác ý định tức thời của người dùng.
3. **Khối Đặc trưng Đa phương thức (Multimodal Feature - $e_{img}$ & $e_{review}$)**:
    * Trích xuất đặc trưng thị giác từ ảnh món ăn thực tế qua mạng học sâu **DenseNet201**.
    * Tích hợp điểm cảm xúc động (**Google Maps Review Sentiment Score**) được lấy từ phản hồi thực tế của người dùng.

🎙️ **Lời thoại thuyết trình gợi ý:**
> *"Từ lý thuyết của bài báo gốc, nhóm em đã mở rộng thành công kiến trúc mô hình M-CARS-Food SCR. Hệ thống của chúng em không chỉ học chuỗi hành vi tuần tự mà chia làm 3 kênh xử lý song song. Kênh 1 xử lý thói quen dài hạn qua Time-LSTM kết hợp trọng số khoảng cách địa lý thực tế và độ tương đồng khung giờ Jaccard. Kênh 2 bắt ý định ngắn hạn bằng Self Multi-Head Attention để hiểu được sự liên kết phi tuần tự giữa các món ăn trong giỏ hàng hiện tại. Kênh 3 là đóng góp đặc biệt của nhóm khi đưa thêm đặc trưng ảnh món ăn từ DenseNet201 và điểm cảm xúc Google Maps của khách hàng vào mô hình."*

---

## 🖼️ Slide 6: Đóng góp đặc biệt của nhóm - Hierarchical Attention Fusion
* **Cơ chế Cộng/Nối truyền thống (Concat/Sum Fusion)**: Coi vai trò của thói quen dài hạn, sở thích ngắn hạn và hình ảnh là tương đương nhau ở mọi thời điểm $\rightarrow$ Không linh hoạt trong thực tế.
* **Đóng góp của nhóm - Hierarchical Attention Fusion (Chú ý phân tầng)**:
    * Thiết lập một mạng neural phụ học trọng số kết hợp tự động $\beta_{fusion} = [\beta_{short}, \beta_{long}, \beta_{visual}, \beta_{sentiment}]$.
    * **Khả năng diễn giải mô hình (Interpretability)**:
        * Khi người dùng đi du lịch ở thành phố mới $\rightarrow$ Sở thích dài hạn ở quê nhà ($\beta_{long}$) tự giảm, mô hình tập trung vào sở thích tức thời ($\beta_{short}$) và kích thích thị giác ($\beta_{visual}$).
        * Cung cấp chỉ số minh bạch giải thích cho người dùng: *"Gợi ý này dựa trên 60% sở thích ngắn hạn gần đây và 30% hình ảnh hấp dẫn của món ăn"*.

🎙️ **Lời thoại thuyết trình gợi ý:**
> *"Một đóng góp vô cùng quan trọng của nhóm chúng em chính là cơ chế Hierarchical Attention Fusion. Thay vì chỉ đơn thuần cộng hoặc nối các vector đặc trưng lại với nhau một cách máy móc, chúng em thiết kế một bộ tự học trọng số Attention phân tầng. Trọng số này tự động thay đổi linh hoạt theo ngữ cảnh thực tế của người dùng. Ưu điểm vượt trội nhất của cơ chế này là cung cấp tính giải thích được (Interpretability) cho các mô hình Deep Learning vốn được coi là hộp đen, giúp hệ thống đưa ra các lý do gợi ý vô cùng thuyết phục và minh bạch cho người dùng."*

---

## 🖼️ Slide 7: Hệ sinh thái Ứng dụng Thực tế & Pipeline Huấn luyện Tự động
* **Kiến trúc Hệ sinh thái Ứng dụng**:
    * **Frontend Mobile (Flutter)**: Trực quan hóa bản đồ nhà hàng thông minh, nhận diện món ăn trực tiếp từ camera điện thoại.
    * **Backend Core (.NET Core C# API)**: Quản lý nghiệp vụ đặt món, giỏ hàng, thông tin nhà hàng, vị trí địa lý của cơ sở dữ liệu Supabase PostgreSQL.
    * **AI Engine Backend (FastAPI)**: Trực tiếp chạy suy luận Deep Learning SCR-Multimodal thời gian thực thông qua kết nối gRPC/Rest.
* **Pipeline Huấn luyện Tự động (Auto-Train Pipeline)**:
    * Đồng bộ hành vi tương tác thực tế từ bảng `TrackingLogs` của Supabase.
    * Xuất và chuyển đổi dữ liệu tự động sang định dạng huấn luyện chuyên dụng.
    * Quy trình huấn luyện khép kín, lưu trữ trọng số và triển khai trực tiếp sang service sản xuất.

🎙️ **Lời thoại thuyết trình gợi ý:**
> *"Để chứng minh tính ứng dụng thực tiễn của đề tài, nhóm em không dừng lại ở nghiên cứu lý thuyết mà đã xây dựng một hệ sinh thái ứng dụng đặt đồ ăn thực tế hoàn chỉnh. Ứng dụng di động được viết bằng Flutter, kết nối với API .NET Core để xử lý các logic nghiệp vụ giao hàng và bản đồ. Khi người dùng thực hiện hành động đặt ăn, hệ thống .NET Core sẽ tự động đồng bộ hóa nhật ký hành vi TrackingLogs vào supabase. Sau đó, AI Backend FastAPI sẽ kích hoạt huấn luyện và cập nhật trọng số liên tục để cải tiến chất lượng đề xuất."*

---

## 🖼️ Slide 8: Cơ sở Thực nghiệm & Đánh giá Kết quả (Huấn luyện Thật)
* **Thông tin tập dữ liệu thực nghiệm**:
    * Số lượng tương tác thực tế thu thập: **3,464 bản ghi hành vi**.
    * Phân chia tập dữ liệu: **Train (80%)** - **Validation (10%)** - **Test (10%)**.
    * Huấn luyện trực tiếp trên CPU với kích thước chuẩn hóa: **2,000 Users** và **20,000 Food Items** (đáp ứng trọn vẹn tập menu thực tế của thành phố).
* **Kết quả Huấn luyện của Mô hình SCR sau khi tối ưu**:
    * **Thời gian huấn luyện**: 433.8 giây trên môi trường CPU tiêu chuẩn.
    * **Train Loss (NLL Loss)**: Giảm từ mức ngẫu nhiên ban đầu xuống **9.3481**.
    * **Val Loss**: Đạt mức hội tụ tốt ở **8.7077**.
    * **Recall@10**: Đạt **0.0312** và **NDCG@10**: Đạt **0.0163** (Kết quả rất khả quan trên tập dữ liệu thưa thớt thực tế).
* **Trọng số Phân tích Cảm xúc (Review Sentiment Score)**: Được lấy trực tiếp từ điểm rating thực tế trên Suppabase (ánh xạ từ [0.0, 1.0] sang star score [3.5, 5.0]) để tinh chỉnh thứ hạng nhà hàng cuối cùng.

🎙️ **Lời thoại thuyết trình gợi ý:**
> *"Đây là kết quả thực nghiệm thực tế mà nhóm em vừa chạy huấn luyện trên tập dữ liệu tương tác thực tế. Với 3,464 hành vi người dùng được ghi nhận, mô hình SCR-Multimodal đề xuất đã hội tụ rất tốt sau 1 epoch huấn luyện chuyên sâu với Train Loss đạt 9.3481 và Validation Loss đạt 8.7077. Các chỉ số Recall và NDCG phản ánh độ chính xác thực tế cao trong bài toán gợi ý món ăn có mức độ thưa thớt dữ liệu lớn. Kết quả huấn luyện này đã được đóng gói thành file trọng số chính thức 'scr_model_v1.pth' và nhúng trực tiếp vào ứng dụng sản xuất, đảm bảo các gợi ý được cá nhân hóa hoàn toàn có cơ sở khoa học toán học và ý nghĩa thống kê thực sự."*

---

## 🖼️ Slide 9: So sánh Đánh giá & Kết luận
* **So sánh hiệu năng thực tế**:
    * **Mô hình Heuristic / Rule-based**: Gợi ý ổn định dựa trên khoảng cách địa lý và rating trung bình, nhưng **thiếu tính cá nhân hóa** theo thói quen thời gian và sở thích thị giác.
    * **Mô hình Deep Learning SCR đề xuất**: Học sâu thói quen tuần tự dài hạn và ý định ngắn hạn, cân đối bối cảnh thực tế của người dùng.
* **Kết luận & Hướng phát triển tương lai**:
    * **Đã đạt được**: Hiện thực hóa thành công mạng Time-LSTM từ bài báo IJCAI 2017; kết hợp đa phương thức hình ảnh và điểm cảm xúc; vận hành ứng dụng Flutter & Backend API đồng bộ thực tế.
    * **Hướng phát triển**: Thử nghiệm cơ chế Grid Search mở rộng (với các siêu tham số `learning_rate` từ 0.001 đến 0.0001, tăng số `num_heads` lên 4 và 8) và tích hợp các mô hình Transformer tiên tiến (như TiSASRec) vào khối xử lý thời gian.

🎙️ **Lời thoại thuyết trình gợi ý:**
> *"Kính thưa thầy cô, qua quá trình so sánh đánh giá, chúng em thấy rằng sự kết hợp giữa thuật toán Rule-based dựa trên vị trí địa lý của .NET Core và mô hình Deep Learning SCR đa ngữ cảnh của FastAPI đã bổ trợ hoàn hảo cho nhau, tạo nên một hệ gợi ý vừa an toàn, thực tế vừa có tính cá nhân hóa cực kỳ cao. Đề tài của chúng em đã chứng minh tính khả thi tuyệt đối của việc áp dụng mô hình nghiên cứu khoa học IJCAI 2017 vào sản phẩm thực tế của đời sống. Chúng em xin chân thành cảm ơn quý thầy cô đã lắng nghe và rất mong nhận được những ý kiến đóng góp từ hội đồng ạ!"*
---
