from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List
import random
import datetime

app = FastAPI(title="M-CARS-Food AI Service", description="FastAPI cho mô hình nhận diện món ăn và gợi ý SCR")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

class ContextRequest(BaseModel):
    user_id: int
    lat: float
    lng: float
    time: str # Ví dụ: "12:30"
    day_of_week: int

class RecommendationResponse(BaseModel):
    restaurant_ids: List[int]
    reason: str

@app.get("/")
def home():
    return {"message": "AI Service đang chạy. Hãy gọi /docs để xem chi tiết API."}

# ======== CHỨC NĂNG 1: Computer Vision (Nhận diện món ăn) ========
@app.post("/api/ai/recognize-food")
async def recognize_food(file: UploadFile = File(...)):
    """
    Mock API cho mô hình CNN (EfficientNetB4).
    Nhận vào ảnh (bát phở, bún) và trả về tên món ăn.
    """
    # TODO: Thực tế sẽ load model AI tại đây bằng PyTorch/TensorFlow.
    # img = Image.open(file.file)
    # prediction = model.predict(img)
    
    mock_foods = ["Phở Bò", "Bún Chả", "Pizza", "Cơm Tấm", "Mì Ý"]
    recognized = random.choice(mock_foods)
    confidence = round(random.uniform(0.85, 0.99), 2)
    
    return {
        "detected_food": recognized,
        "confidence_score": confidence,
        "message": f"Mô hình AI nhận diện đây là {recognized} với độ chính xác {confidence*100}%"
    }

# ======== CHỨC NĂNG 2: Context-Aware Recommendation (SCR Model) ========
@app.post("/api/ai/recommend-poi", response_model=RecommendationResponse)
def recommend_poi(request: ContextRequest):
    """
    Mock API cho bài báo: Deep Sequential Model for context-aware POI recommendation (SCR).
    Sử dụng User History (dữ liệu truyền ngầm hoặc lấy từ Database chung) + Thời gian thực + Vị trí thực (Context)
    để dùng GRU/Self-Attention dự đoán danh sách quán ăn (POI) phù hợp nhất.
    """
    # TODO: Load SCR Torch Model -> embedding các context -> dự đoán Top K quán.
    # user_emb = attention_layer(user_history)
    # spatial_emb = geo_encode(request.lat, request.lng)
    # temporal_emb = time_encode(request.time, request.day_of_week)
    
    # Mock logic trả về ID của các quán ngẫu nhiên (Ví dụ: ID quán có trong CSDL)
    # Database có quán Phở Thìn (ID 1), Pizza 4P's (ID 2), Bún chả (ID 3)
    mock_recommended_ids = random.sample([1, 2, 3], 2)
    
    # Chẩn đoán theo ngữ cảnh:
    hour = int(request.time.split(":")[0])
    if 6 <= hour <= 10:
        context_reason = "Buổi sáng, AI gợi ý các món nước nóng hổi gần bạn."
    elif 11 <= hour <= 14:
        context_reason = "Buổi trưa, AI gợi ý món ăn phù hợp với thói quen ăn trưa của bạn."
    else:
        context_reason = "Buổi tối, AI kết hợp khoảng cách và sự đa dạng thực đơn để gợi ý."

    return {
        "restaurant_ids": mock_recommended_ids,
        "reason": context_reason
    }

# Để chạy: uvicorn main:app --reload --port 8000
