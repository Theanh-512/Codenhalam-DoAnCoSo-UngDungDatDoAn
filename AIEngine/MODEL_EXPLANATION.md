# Giải thích Mô hình: Vai trò của Trọng số Attention (Interpretability)

Trong module **Short-term Preference ($U_{short}$)** của kiến trúc SCR, chúng ta sử dụng cơ chế **Self Multi-Head Attentive Aggregation**. Cơ chế này không chỉ giúp mô hình học được biểu diễn tốt hơn mà còn cung cấp khả năng diễn giải (Interpretability) cực kỳ mạnh mẽ.

## 1. Trọng số Attention ($\beta_j$) là gì?

Khi áp dụng phương trình Attention:
$$ \text{Attention}(Q, K, V) = \text{softmax}\left(\frac{QK^T}{\sqrt{d_k}}\right)V $$

Ma trận sinh ra từ hàm $\text{softmax}$ chứa các trọng số $\beta_j$. Mỗi giá trị $\beta_j$ đại diện cho mức độ "chú ý" (attention) mà mô hình dành cho một món ăn $j$ cụ thể trong phiên giao dịch ngắn hạn (Session) khi dự đoán món ăn tiếp theo.

## 2. Ý nghĩa của $\beta_j$ trong thực tế (Interpretability)

- **Nhận diện món ăn cốt lõi**: Nếu người dùng vừa xem "Gà rán", "Khoai tây chiên", và "Nước ngọt". Trọng số $\beta$ của "Gà rán" có thể là lớn nhất (vd: 0.6), chứng tỏ đây là mục tiêu chính của người dùng, trong khi "Nước ngọt" chỉ là món ăn kèm ($\beta = 0.1$).
- **Bắt được mối quan hệ phi liên tiếp (Non-consecutive)**: Khác với RNN/LSTM chỉ nhớ theo thứ tự, Attention có thể kết nối mục đầu tiên và mục cuối cùng trong Session mà không bị suy giảm tín hiệu.
- **Tính minh bạch (Transparency)**: Dựa vào $\beta_j$, hệ thống có thể giải thích cho người dùng: *"Chúng tôi gợi ý món Burger vì bạn vừa chú ý nhiều nhất đến Gà rán (dựa trên điểm Attention)"*.

## 3. Hoạt động trên Đa đầu chú ý (Multi-Head)

Do sử dụng `num_heads=4`, mô hình có khả năng học các góc độ giải thích khác nhau đồng thời:
- **Head 1**: Tập trung vào sự tương đồng về danh mục (VD: Cùng là Đồ ăn nhanh).
- **Head 2**: Tập trung vào mức giá (VD: Cùng phân khúc giá rẻ).
- **Head 3**: Tập trung vào hành vi (VD: Các món hay được Mua kèm).

Nhờ vậy, vector $U_{short}$ thu được là một biểu diễn toàn diện, chứa đựng đầy đủ lý do "tại sao" người dùng lại muốn mua món ăn đó ngay lúc này.

## 4. Khối Dài hạn: Time-LSTM với Cổng thời gian
Module **Long-term Preference ($U_{long}$)** sử dụng biến thể **Time-LSTM** để xử lý các chuỗi tương tác dài hạn của người dùng.
- **Cổng thời gian ($T_1, T_2$)**: Khác với LSTM thông thường, Time-LSTM có các cổng phụ thuộc vào khoảng cách thời gian giữa các lần ăn ($\Delta t$). Điều này giúp mô hình "quên" đi những thói quen cũ đã lỗi thời và tập trung vào các thói quen có tính chu kỳ (ví dụ: thói quen ăn phở vào sáng Chủ Nhật).
- **Trọng số Không gian - Thời gian**: Kết hợp khoảng cách địa lý (Distance weight) và sự tương đồng về khung giờ (Jaccard Time similarity) để tạo ra vector sở thích dài hạn chính xác nhất.

## 5. Hierarchical Attention Fusion (Fusion đa phương thức)
Sau khi có $U_{short}$, $U_{long}$ và đặc trưng hình ảnh $e_{img}$ từ DenseNet201, chúng ta không chỉ cộng hay nối chúng lại. Thay vào đó, chúng ta sử dụng **Hierarchical Attention**:
- **Tính toán trọng số Fusion**: Mô hình tự học xem tại thời điểm hiện tại, yếu tố nào quan trọng nhất. 
- **Ví dụ**: Nếu người dùng đang đi du lịch ở một thành phố mới, trọng số của $U_{short}$ (ý định tức thời) và $e_{img}$ (nhìn ảnh thấy ngon) sẽ tăng cao, trong khi $U_{long}$ (thói quen tại nhà) sẽ giảm xuống.
- **Kết quả**: Hệ thống có thể giải thích chi tiết: *"Gợi ý này dựa 60% vào sở thích tức thời của bạn và 30% vào hình ảnh món ăn."*
