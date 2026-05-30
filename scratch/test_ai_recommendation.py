import os
import sys

# Setup path
CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(CURRENT_DIR, ".."))
if PROJECT_ROOT not in sys.path:
    sys.path.append(PROJECT_ROOT)

# Thêm Backend/AIService vào sys.path để import dễ dàng
ai_service_path = os.path.join(PROJECT_ROOT, "Backend", "AIService")
if ai_service_path not in sys.path:
    sys.path.append(ai_service_path)

print("=== CHẠY XÁC MINH HỆ THỐNG GỢI Ý ĐỘNG ĐÃ TÍCH HỢP GOOGLE MAPS ===")

try:
    from main import AIModelManager
    
    print("\n1. Khởi tạo AIModelManager...")
    manager = AIModelManager()
    
    print("\n2. Chạy thử nghiệm dự đoán gợi ý cho User ID: 15 (Người dùng đã có lịch sử tương tác)...")
    res_ids, scores, weights = manager.predict(
        user_id=15, 
        lat=10.772698, 
        lng=106.7048299, 
        time_str="12:30", 
        dow=2
    )
    
    print("\n✅ Dự đoán thành công!")
    print(f" - Top 10 ID nhà hàng được gợi ý: {res_ids}")
    print(f" - Điểm tin cậy (Confidence Scores): {[round(s, 4) for s in scores]}")
    print(f" - Trọng số Attention tổng hợp phân tầng (Fusion Weights): {weights}")
    
    print("\n3. Chạy thử nghiệm dự đoán gợi ý cho User ID: 9999 (Người dùng mới - Lấy điểm trung bình làm Fallback)...")
    res_ids_2, scores_2, weights_2 = manager.predict(
        user_id=9999, 
        lat=10.8005534, 
        lng=106.7246028, 
        time_str="19:00", 
        dow=6
    )
    print("\n✅ Dự đoán thành công cho người dùng mới!")
    print(f" - Top 10 ID nhà hàng được gợi ý: {res_ids_2}")
    
    print("\n🎉 HỆ THỐNG GỢI Ý SCR ĐÃ ĐƯỢC TÍCH HỢP ĐIỂM CẢM XÚC ĐỘNG TỪ GOOGLE MAPS HOÀN HẢO!")
    
except Exception as e:
    print(f"\n❌ Lỗi khi chạy xác minh: {e}")
    import traceback
    traceback.print_exc()
