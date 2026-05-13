import torch
import torch.nn as nn
from models.scr_model import SCRMultimodalRecommender

def test_model():
    print("=== Khởi tạo mô hình ===")
    batch_size = 4
    num_items = 1000
    seq_len = 50      # 50 lượt tương tác dài hạn
    session_len = 10  # 10 tương tác trong 24h
    
    model = SCRMultimodalRecommender(num_items=num_items, item_dim=128, lstm_hidden=128, image_dim=256)
    
    print("=== Tạo dữ liệu Dummy ===")
    # Dữ liệu dài hạn
    long_items = torch.randint(0, num_items, (batch_size, seq_len))
    time_scores = torch.rand(batch_size, seq_len, 1) # Jaccard scores
    dist_scores = torch.rand(batch_size, seq_len, 1) # Distance weights
    
    # Dữ liệu ngắn hạn
    short_items = torch.randint(0, num_items, (batch_size, session_len))
    
    # Dữ liệu hình ảnh (DenseNet201 nhận ảnh 224x224 RGB)
    image_tensors = torch.randn(batch_size, 3, 224, 224)
    
    # Label ground truth (món ăn tiếp theo)
    target_items = torch.randint(0, num_items, (batch_size,))
    
    print("\n=== Chạy Forward Pass ===")
    log_probs, attn_weights = model(long_items, time_scores, dist_scores, short_items, image_tensors)
    
    print(f"Kích thước Log_Probs: {log_probs.shape} (Dự kiến: [{batch_size}, {num_items}])")
    print(f"Kích thước Attention Weights: {attn_weights.shape} (Dự kiến: [{batch_size}, {session_len}, {session_len}])")
    
    assert log_probs.shape == (batch_size, num_items), "Lỗi: Chiều của Output không khớp!"
    assert attn_weights.shape == (batch_size, session_len, session_len), "Lỗi: Chiều của Attention không khớp!"
    
    print("\n=== Tính Loss (Negative Log-Likelihood) ===")
    loss_fn = nn.NLLLoss()
    loss = loss_fn(log_probs, target_items)
    
    print(f"Loss value: {loss.item():.4f}")
    
    print("\n✅ Verification thành công: Mô hình chạy mượt mà không gặp lỗi Dimension!")

if __name__ == "__main__":
    test_model()
