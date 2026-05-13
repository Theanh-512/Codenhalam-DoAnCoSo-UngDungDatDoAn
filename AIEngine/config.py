"""
SCR-Multimodal Recommender — Hyperparameter Configuration
==========================================================
Single source of truth cho tất cả hyperparameter.
Grid search sẽ override các giá trị này khi thử nghiệm.
"""

# ─── DATA CONFIG ──────────────────────────────────────────────────────────────
DATA_CONFIG = {
    "num_users":      1000,     # Tổng số User trong hệ thống
    "num_items":      500,      # Tổng số món ăn / nhà hàng
    "num_time_slots": 48,       # 24h weekday + 24h weekend
    "seq_len":        50,       # Độ dài chuỗi lịch sử dài hạn
    "session_len":    10,       # Số tương tác tối đa trong 1 phiên 24h
    "image_size":     224,      # Input size cho DenseNet201
    "train_ratio":    0.8,
    "val_ratio":      0.1,
    "test_ratio":     0.1,
}

# ─── MODEL ARCHITECTURE CONFIG ────────────────────────────────────────────────
MODEL_CONFIG = {
    "item_dim":       64,       # d: Chiều không gian nhúng Item (Paper: 64)
    "user_dim":       64,       # d: Chiều không gian nhúng User (Paper: 64)
    "time_dim":       32,       # d: Chiều nhúng Time Slot
    "lstm_hidden":    64,       # Kích thước hidden state LSTM (Paper: 64)
    "image_dim":      64,       # Chiều vector đặc trưng ảnh (DenseNet201 → 64)
    "num_heads":      2,        # Số đầu Multi-Head Attention (paper baseline)
    "dropout":        0.5,      # Dropout rate (paper baseline)
    "num_lstm_layers":1,        # Số lớp LSTM
}

# ─── TRAINING CONFIG ──────────────────────────────────────────────────────────
TRAIN_CONFIG = {
    "learning_rate":  0.001,    # Adam lr (paper baseline)
    "weight_decay":   1e-5,     # L2 regularization
    "batch_size":     64,
    "num_epochs":     50,
    "patience":       10,       # Early stopping patience
    "clip_grad_norm": 5.0,      # Gradient clipping
    "log_interval":   10,       # Log mỗi N batch
    "save_dir":       "checkpoints/",
    "device":         "cpu",    # Thay thành "cuda" khi có GPU
}

# ─── GRID SEARCH CONFIG ───────────────────────────────────────────────────────
GRID_SEARCH_CONFIG = {
    "learning_rate":  [0.001, 0.0005, 0.0001],
    "dropout":        [0.3,   0.5,    0.7],
    "num_heads":      [2,     4,      8],
    # Tổng: 3 × 3 × 3 = 27 thí nghiệm
    # Metric: Recall@10, NDCG@10
}

# ─── DISTANCE CONFIG ──────────────────────────────────────────────────────────
DISTANCE_CONFIG = {
    "epsilon":        1e-6,     # Tránh chia cho 0 khi d = 0
    # Euclidean distance: d_{lt,h} = sqrt((lon_lt - lon_h)^2 + (lat_lt - lat_h)^2)
    # Weight: w_h = 1 / (d_{lt,h} + epsilon)
}
