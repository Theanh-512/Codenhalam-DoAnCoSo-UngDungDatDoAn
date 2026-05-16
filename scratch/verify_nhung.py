import os
import sys
import torch

# Setup path
CURRENT_DIR = os.getcwd()
sys.path.append(CURRENT_DIR)

from Backend.AIService.main import FoodRecognitionManager

try:
    print("--- Đang kiểm tra việc nhúng Model ---")
    vision = FoodRecognitionManager()
    if vision.model is not None:
        print(f"✅ Thành công! Đã nạp được Model với {len(vision.classes)} nhãn.")
        print(f"Danh sách nhãn: {vision.classes[:10]}...")
    else:
        print("❌ Thất bại: Model không khởi tạo được.")
except Exception as e:
    print(f"❌ Lỗi: {e}")
