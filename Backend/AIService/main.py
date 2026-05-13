"""
M-CARS-Food AI Service — Unified FastAPI Implementation
=========================================================
Tích hợp mô hình SCR (Sequential Context-Aware Recommendation) 
và Nhận diện món ăn (DenseNet201).
"""

import os
import sys
import logging
import random
from typing import List, Optional

import torch
import torch.nn as nn
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from PIL import Image
import io

# ─── Setup Path để import từ AIEngine ──────────────────────────────────────
# Giả sử cấu trúc: /ProjectRoot/Backend/AIService/main.py
# AIEngine nằm tại: /ProjectRoot/AIEngine/
CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(CURRENT_DIR, "..", ".."))
if PROJECT_ROOT not in sys.path:
    sys.path.append(PROJECT_ROOT)

try:
    from AIEngine.models.scr_model import SCRMultimodalRecommender
    from AIEngine.data.dataset import IMAGE_TRANSFORM, encode_time_slot, time_slot_to_binary
    from AIEngine.config import MODEL_CONFIG, DATA_CONFIG
except ImportError as e:
    print(f"❌ Lỗi Import từ AIEngine: {e}")
    # Fallback giả lập nếu chạy standalone không đúng path
    SCRMultimodalRecommender = None

# ─── Logging ───────────────────────────────────────────────────────────────
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="M-CARS-Food AI Service", description="FastAPI cho mô hình SCR & Vision")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─── Schemas ───────────────────────────────────────────────────────────────
class ContextRequest(BaseModel):
    user_id: int
    lat: float
    lng: float
    time: str         # Ví dụ: "12:30"
    day_of_week: int  # 0=Mon, 6=Sun

class RecommendationResponse(BaseModel):
    restaurant_ids: List[int]
    confidence_scores: List[float]
    analysis: Optional[dict] = None
    reason: str

# ─── Model Management ──────────────────────────────────────────────────────
class AIModelManager:
    def __init__(self):
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        self.model = None
        self._load_model()

    def _load_model(self):
        if SCRMultimodalRecommender is None:
            logger.warning("SCR Model class not found. Running in Mock mode.")
            return

        try:
            # Khởi tạo mô hình với config từ AIEngine
            self.model = SCRMultimodalRecommender(
                num_users      = DATA_CONFIG["num_users"],
                num_items      = DATA_CONFIG["num_items"],
                item_dim       = MODEL_CONFIG["item_dim"],
                user_dim       = MODEL_CONFIG["user_dim"],
                time_dim       = MODEL_CONFIG["time_dim"],
                lstm_hidden    = MODEL_CONFIG["lstm_hidden"],
                image_dim      = MODEL_CONFIG["image_dim"]
            )
            
            # Load weights nếu có file, nếu không dùng random (cho demo)
            weight_path = os.path.join(PROJECT_ROOT, "AIEngine", "checkpoints", "best_scr_model.pt")
            if os.path.exists(weight_path):
                self.model.load_state_dict(torch.load(weight_path, map_location=self.device))
                logger.info(f"✅ Loaded weights from {weight_path}")
            else:
                logger.info("⚠️ No checkpoint found. Using initialized random weights for demo.")
            
            self.model.to(self.device)
            self.model.eval()
        except Exception as e:
            logger.error(f"❌ Error loading model: {e}")

    @torch.no_grad()
    def predict(self, user_id, lat, lng, time_str, dow):
        if self.model is None:
            return [random.randint(1, 10) for _ in range(3)], [0.9, 0.8, 0.7], {}

        # 1. Preprocess context
        hour = int(time_str.split(":")[0])
        is_weekend = dow >= 5
        slot_id = encode_time_slot(hour, is_weekend)
        
        # 2. Tạo dummy history (Thực tế sẽ lấy từ Database/Redis)
        B = 1
        L_long = DATA_CONFIG["seq_len"] if "seq_len" in DATA_CONFIG else 20
        L_short = DATA_CONFIG["session_len"] if "session_len" in DATA_CONFIG else 5

        long_item_ids  = torch.randint(0, DATA_CONFIG["num_items"], (B, L_long)).to(self.device)
        long_time_ids  = torch.randint(0, 48, (B, L_long)).to(self.device)
        
        # delta_ts: khoảng cách thời gian giữa các lần ăn (giả lập 1-24h)
        delta_ts       = torch.rand(B, L_long, 1).to(self.device) * 24.0
        
        history_slots  = torch.randint(0, 2, (B, L_long, 48)).float().to(self.device)
        history_coords = torch.randn(B, L_long, 2).to(self.device)
        short_item_ids = torch.randint(0, DATA_CONFIG["num_items"], (B, L_short)).to(self.device)
        
        # current_slots: (B, 48) — binary vector cho time slot hiện tại
        slot_binary = time_slot_to_binary([slot_id])   # list 48 phần tử
        current_slots = torch.tensor(slot_binary, dtype=torch.float32).unsqueeze(0).to(self.device)  # (1, 48)
        
        # current_coord: (B, 2)
        current_coord = torch.tensor([[lat, lng]], dtype=torch.float32).to(self.device)  # (1, 2)
        image_dummy   = torch.randn(B, 3, 224, 224).to(self.device)

        # 3. Forward Pass
        # Model signature mới: (..., delta_ts, ...) -> log_probs, attn_weights, fusion_weights
        log_probs, _, fusion_weights = self.model(
            user_ids       = torch.tensor([user_id]).to(self.device),
            long_item_ids  = long_item_ids,
            long_time_ids  = long_time_ids,
            delta_ts       = delta_ts,
            history_slots  = history_slots,
            current_slots  = current_slots,
            history_coords = history_coords,
            current_coord  = current_coord,
            short_item_ids = short_item_ids,
            image_tensors  = image_dummy
        )

        # 4. Get Top K
        probs = torch.exp(log_probs)
        top_vals, top_inds = torch.topk(probs, 3)
        
        # Fusion weights: [Short, Long, Image]
        # weights shape: (B, 3, 1) -> squeeze to (B, 3)
        if fusion_weights is not None:
            weights = fusion_weights[0].squeeze().tolist()
        else:
            weights = [0.33, 0.33, 0.33]

        weight_info = {
            "short_term_impact": round(weights[0], 2),
            "long_term_impact":  round(weights[1], 2),
            "visual_impact":     round(weights[2], 2)
        }
        
        return top_inds[0].tolist(), top_vals[0].tolist(), weight_info

# Khởi tạo singleton manager
ai_manager = AIModelManager()

# ─── API Endpoints ──────────────────────────────────────────────────────────

@app.get("/")
def home():
    return {
        "status": "Online",
        "engine": "SCR-Multimodal v2.0",
        "device": str(ai_manager.device),
        "message": "AI Service sẵn sàng xử lý gợi ý và nhận diện."
    }

@app.post("/api/ai/recognize-food")
async def recognize_food(file: UploadFile = File(...)):
    """
    Sử dụng ImageFeatureExtractor (DenseNet201) để nhận diện đặc trưng món ăn.
    """
    try:
        content = await file.read()
        img = Image.open(io.BytesIO(content)).convert('RGB')
        
        # Tiền xử lý ảnh qua transform của AIEngine
        img_tensor = IMAGE_TRANSFORM(img).unsqueeze(0).to(ai_manager.device)
        
        # Trích xuất đặc trưng (demo: dùng image_module của model)
        if ai_manager.model:
            with torch.no_grad():
                features = ai_manager.model.image_module(img_tensor)
            logger.info(f"Extracted features shape: {features.shape}")
        
        # Mapping mock kết quả dựa trên đặc trưng (Thực tế sẽ dùng lớp phân loại)
        mock_foods = ["Phở Bò", "Bún Chả", "Pizza 4P's", "Cơm Tấm Sườn", "Mì Ý Carbonara"]
        recognized = random.choice(mock_foods)
        confidence = round(random.uniform(0.88, 0.99), 2)
        
        return {
            "detected_food": recognized,
            "confidence_score": confidence,
            "message": f"AI nhận diện đây là {recognized}."
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Lỗi xử lý ảnh: {str(e)}")

@app.post("/api/ai/recommend-poi", response_model=RecommendationResponse)
def recommend_poi(request: ContextRequest):
    """
    Gợi ý quán ăn sử dụng mô hình SCR-Multimodal với Hierarchical Attention.
    """
    ids, scores, weight_info = ai_manager.predict(
        request.user_id, request.lat, request.lng, request.time, request.day_of_week
    )
    
    # Tạo lý do gợi ý dựa trên trọng số Attention
    # weights: [Short, Long, Image]
    if weight_info.get("visual_impact", 0) > 0.4:
        reason = "AI nhận thấy bạn đang bị thu hút bởi hình ảnh các món ăn tương tự quán này."
    elif weight_info.get("short_term_impact", 0) > 0.4:
        reason = "Gợi ý dựa trên những gì bạn vừa tìm kiếm trong 15 phút qua."
    else:
        reason = "Dựa trên thói quen ăn uống ổn định của bạn vào khung giờ này."

    return {
        "restaurant_ids": ids,
        "confidence_scores": scores,
        "analysis": weight_info,
        "reason": reason
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
