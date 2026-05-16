import os
import sys
import torch
from torchvision import models
import torch.nn as nn

# Setup path
PROJECT_ROOT = os.getcwd()
sys.path.append(PROJECT_ROOT)

model_path = os.path.join(PROJECT_ROOT, "Backend", "AIService", "archive_1_model.pth")

print(f"--- Đang kiểm tra Model: {os.path.basename(model_path)} ---")

try:
    if os.path.exists(model_path):
        checkpoint = torch.load(model_path, map_location='cpu')
        classes = checkpoint['classes']
        
        print(f"✅ Đã nạp thành công file .pth")
        print(f"✅ Số lượng nhãn (món ăn): {len(classes)}")
        print(f"✅ Danh sách 10 nhãn đầu tiên: {classes[:10]}")
        
        # Thử khởi tạo model
        model = models.efficientnet_v2_s(weights=None)
        num_ftrs = model.classifier[1].in_features
        model.classifier[1] = nn.Linear(num_ftrs, len(classes))
        model.load_state_dict(checkpoint['model_state_dict'])
        print(f"✅ Đã khởi tạo cấu trúc và nạp trọng số thành công!")
    else:
        print(f"❌ Không tìm thấy file tại: {model_path}")
except Exception as e:
    print(f"❌ Lỗi: {e}")
