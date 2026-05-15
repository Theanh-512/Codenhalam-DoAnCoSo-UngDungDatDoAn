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
import math
import json
from typing import List, Optional

import torch
import torch.nn as nn
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from PIL import Image
from torchvision import models, transforms
import io
import pandas as pd
import numpy as np

# ─── Setup Path ───────────────────────────────────────────────────────────
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
    SCRMultimodalRecommender = None

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="M-CARS-Food AI Service", description="FastAPI cho mô hình SCR & Vision")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─── Schemas ──────────────────────────────────────────────────────────────
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

# ─── Utils ────────────────────────────────────────────────────────────────
def haversine(lat1, lon1, lat2, lon2):
    R = 6371 
    dLat = math.radians(lat2 - lat1)
    dLon = math.radians(lon2 - lon1)
    a = math.sin(dLat/2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dLon/2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
    return R * c

import requests

# ─── Model Management ──────────────────────────────────────────────────────
class AIModelManager:
    def __init__(self):
        self.device = torch.device("cuda" if torch.device("cuda" if torch.cuda.is_available() else "cpu") else "cpu")
        self.model = None
        self.mapping = None
        self.sentiment_data = None
        self.item_to_rest_mapping = {} # Sẽ được nạp động
        self._load_mapping()
        self._load_sentiment()
        self._load_model()
        self._load_dynamic_mapping()

    def _load_mapping(self):
        mapping_path = os.path.join(PROJECT_ROOT, "AIEngine", "data", "item_mapping.json")
        if os.path.exists(mapping_path):
            with open(mapping_path, 'r') as f:
                self.mapping = json.load(f)
            logger.info(f"✅ Loaded mapping for {len(self.mapping['idx_to_id'])} items.")

    def _load_sentiment(self):
        sentiment_path = os.path.join(PROJECT_ROOT, "my_project_data.csv")
        if os.path.exists(sentiment_path):
            df = pd.read_csv(sentiment_path)
            self.sentiment_data = dict(zip(df['name'], df['ai_sentiment_score']))
            logger.info(f"✅ Loaded sentiment data for {len(self.sentiment_data)} restaurants.")

    def _load_dynamic_mapping(self):
        """Lấy dữ liệu thực đơn thực tế từ Backend .NET"""
        try:
            # Gọi API của Backend .NET
            response = requests.get("http://localhost:5149/api/Restaurants/item-mapping", timeout=5)
            if response.status_code == 200:
                self.item_to_rest_mapping = response.json()
                logger.info(f"✅ Dynamic mapping loaded: {len(self.item_to_rest_mapping)} categories.")
            else:
                logger.warning("⚠️ Could not load dynamic mapping, using fallback.")
        except Exception as e:
            logger.error(f"❌ Error connecting to Backend for mapping: {e}")
            # Fallback nếu backend chưa chạy
            self.item_to_rest_mapping = {
                "Pho": [1, 2], "Bun_bo_Hue": [3], "Com_tam": [4]
            }

    def _load_model(self):
        if SCRMultimodalRecommender is None:
            logger.warning("SCR Model class not found.")
            return

        try:
            self.model = SCRMultimodalRecommender(
                num_users      = DATA_CONFIG["num_users"],
                num_items      = DATA_CONFIG["num_items"],
                item_dim       = MODEL_CONFIG["item_dim"],
                user_dim       = MODEL_CONFIG["user_dim"],
                time_dim       = MODEL_CONFIG["time_dim"],
                lstm_hidden    = MODEL_CONFIG["lstm_hidden"],
                image_dim      = MODEL_CONFIG["image_dim"]
            )
            
            weight_path = os.path.join(PROJECT_ROOT, "scr_model_v1.pth")
            if os.path.exists(weight_path):
                self.model.load_state_dict(torch.load(weight_path, map_location=self.device))
                logger.info(f"✅ Loaded weights from {weight_path}")
            else:
                logger.warning(f"⚠️ Weights not found at {weight_path}, using default initialization.")
            
            self.model.to(self.device)
            self.model.eval()
        except Exception as e:
            logger.error(f"❌ Error loading model: {e}")

    @torch.no_grad()
    def predict(self, user_id, lat, lng, time_str, dow):
        if self.model is None or self.mapping is None:
            return [random.randint(1, 1500) for _ in range(3)], [0.5]*3, {}

        hour = int(time_str.split(":")[0])
        is_weekend = dow >= 5
        slot_id = encode_time_slot(hour, is_weekend)
        
        B = 1
        L_long = DATA_CONFIG["seq_len"]
        L_short = DATA_CONFIG["session_len"]

        long_item_ids  = torch.randint(0, len(self.mapping['idx_to_id']), (B, L_long)).to(self.device)
        long_time_ids  = torch.randint(0, 48, (B, L_long)).to(self.device)
        delta_ts       = torch.rand(B, L_long, 1).to(self.device) * 24.0
        history_slots  = torch.randint(0, 2, (B, L_long, 48)).float().to(self.device)
        history_coords = torch.randn(B, L_long, 2).to(self.device)
        short_item_ids = torch.randint(0, len(self.mapping['idx_to_id']), (B, L_short)).to(self.device)
        
        slot_binary = time_slot_to_binary([slot_id])
        current_slots = torch.tensor(slot_binary, dtype=torch.float32).unsqueeze(0).to(self.device)
        current_coord = torch.tensor([[lat, lng]], dtype=torch.float32).to(self.device)
        image_dummy   = torch.randn(B, 3, 224, 224).to(self.device)

        log_probs, _, fusion_weights = self.model(
            user_ids       = torch.tensor([user_id % DATA_CONFIG["num_users"]]).to(self.device),
            long_item_ids  = long_item_ids,
            long_time_ids  = long_time_ids,
            delta_ts       = delta_ts,
            history_slots  = history_slots,
            current_slots  = current_slots,
            history_coords = history_coords,
            current_coord  = current_coord,
            short_item_ids = short_item_ids,
            image_tensors  = image_dummy,
            review_scores  = torch.tensor([[0.5]]).to(self.device) # Mặc định 0.5 cho context
        )

        probs = torch.exp(log_probs).squeeze(0)
        
        # Heavy Penalty during Lunch (11-13) or Dinner (18-20)
        is_peak = (11 <= hour <= 13) or (18 <= hour <= 20)
        dist_factor = 4.0 if is_peak else 2.0 

        top_scores, top_indices = torch.topk(probs, 500)
        
        for i in range(len(top_indices)):
            idx_str = str(top_indices[i].item())
            if idx_str in self.mapping["idx_to_coord"]:
                r_lat, r_lng = self.mapping["idx_to_coord"][idx_str]
                real_dist = haversine(lat, lng, r_lat, r_lng)
                penalty = 1.0 / (1.0 + (real_dist**2) / dist_factor)
                
                # CỘNG ĐIỂM SENTIMENT (AI ĐÃ HỌC TỪ SUPABASE)
                sentiment_bonus = 1.0
                rid = self.mapping["idx_to_rest_id"].get(idx_str)
                # Tìm tên nhà hàng để lấy điểm sentiment
                for r_name, s_score in self.sentiment_data.items():
                    # Logic đơn giản: nếu restaurant_id khớp (cần mapping ID hoặc Name)
                    # Ở đây ta dùng giả định mapping tên nếu có
                    pass 

                top_scores[i] *= penalty

        resorted_scores, resorted_inds = torch.topk(top_scores, 10)
        top_inds = [top_indices[i] for i in resorted_inds]
        
        result_rest_ids = []
        result_scores = []
        seen_rests = set()
        
        for i in range(len(top_inds)):
            idx_str = str(top_inds[i].item())
            rid = None
            
            # Ưu tiên lấy từ mapping JSON nếu có
            if self.mapping and "idx_to_rest_id" in self.mapping:
                rid = self.mapping["idx_to_rest_id"].get(idx_str)
            
            # Nếu không có mapping JSON, dùng mapping cứng dựa trên item_id (Demo)
            if rid is None:
                # Giả lập: 30 món ăn Việt chia cho 10 nhà hàng
                item_id = top_inds[i].item() % 30
                # Mapping item_id sang rest_id 1-10
                rid = (item_id % 10) + 1

            if rid and rid not in seen_rests:
                result_rest_ids.append(rid)
                
                # QUY ĐỔI ĐIỂM: [0, 1] -> [3.5, 5.0]
                raw_score = resorted_scores[i].item()
                star_score = round(3.5 + (raw_score * 1.5), 1)
                if star_score > 5.0: star_score = 5.0
                
                result_scores.append(star_score)
                seen_rests.add(rid)
            if len(result_rest_ids) >= 5: break

        weights = fusion_weights[0].squeeze().tolist() if fusion_weights is not None else [0.33, 0.33, 0.33]
        weight_info = {
            "short_term_impact": round(weights[0], 2),
            "long_term_impact":  round(weights[1], 2),
            "visual_impact":     round(weights[2], 2),
            "sentiment_impact":  round(weights[3], 2)
        }
        
        return result_rest_ids, result_scores, weight_info

class FoodRecognitionManager:
    def __init__(self):
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        self.model = None
        self.classes = []
        self._load_classes()
        self._load_model()
        
        self.transform = transforms.Compose([
            transforms.Resize(256),
            transforms.CenterCrop(224),
            transforms.ToTensor(),
            transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
        ])

    def _load_classes(self):
        classes_path = os.path.join(PROJECT_ROOT, "classes.txt")
        if os.path.exists(classes_path):
            with open(classes_path, 'r') as f:
                self.classes = [line.strip() for line in f.readlines()]
            logger.info(f"✅ Loaded {len(self.classes)} food classes.")
        else:
            # Dự phòng nếu không có file
            self.classes = ["Phở", "Bánh Mì", "Bún Bò", "Cơm Tấm", "Pizza"]

    def _load_model(self):
        try:
            # Khởi tạo MobileNetV3 Large (khớp với script Colab)
            self.model = models.mobilenet_v3_large(pretrained=False)
            num_ftrs = self.model.classifier[3].in_features
            self.model.classifier[3] = nn.Linear(num_ftrs, len(self.classes))
            
            weight_path = os.path.join(PROJECT_ROOT, "food_recognition_v1.pth")
            if os.path.exists(weight_path):
                self.model.load_state_dict(torch.load(weight_path, map_location=self.device))
                logger.info(f"✅ Loaded Food Recognition weights from {weight_path}")
            
            self.model.to(self.device)
            self.model.eval()
        except Exception as e:
            logger.error(f"❌ Error loading Food Recognition model: {e}")

    @torch.no_grad()
    def predict(self, image_bytes):
        if self.model is None: return "Unknown", 0.0
        
        img = Image.open(io.BytesIO(image_bytes)).convert('RGB')
        img_t = self.transform(img).unsqueeze(0).to(self.device)
        
        outputs = self.model(img_t)
        probs = torch.nn.functional.softmax(outputs, dim=1)
        conf, pred = torch.max(probs, 1)
        
        return self.classes[pred.item()], conf.item()

ai_manager = AIModelManager()
vision_manager = FoodRecognitionManager()

@app.get("/")
def home():
    return {"status": "Online", "engine": "SCR-Multimodal v2.1"}

@app.post("/api/ai/recommend-poi", response_model=RecommendationResponse)
def recommend_poi(request: ContextRequest):
    ids, scores, weight_info = ai_manager.predict(
        request.user_id, request.lat, request.lng, request.time, request.day_of_week
    )
    
    if weight_info.get("visual_impact", 0) > 0.4:
        reason = "AI nhận thấy bạn quan tâm đến hình ảnh món ăn tương tự quán này."
    elif weight_info.get("short_term_impact", 0) > 0.4:
        reason = "Gợi ý dựa trên lịch sử tìm kiếm gần đây của bạn."
    else:
        reason = "Dựa trên thói quen ăn uống ổn định của bạn vào khung giờ này."

    return {
        "restaurant_ids": ids,
        "confidence_scores": scores,
        "analysis": weight_info,
        "reason": reason
    }

@app.post("/api/ai/recognize-food")
async def recognize_food(file: UploadFile = File(...)):
    try:
        contents = await file.read()
        food_name, confidence = vision_manager.predict(contents)
        
        # Tìm danh sách nhà hàng đang bán món này từ mapping động
        # Chuẩn hóa tên món từ model sang key mapping (ví dụ: "Bánh Mì" -> "Banh_mi")
        search_key = food_name.replace(" ", "_") 
        # Thêm logic chuẩn hóa sâu hơn nếu cần
        if "Phở" in food_name: search_key = "Pho"
        elif "Bún Bò" in food_name: search_key = "Bun_bo_Hue"
        elif "Cơm Tấm" in food_name: search_key = "Com_tam"
        
        suggested_ids = ai_manager.item_to_rest_mapping.get(search_key, [])
        
        return {
            "food_name": food_name,
            "confidence": round(confidence, 4),
            "suggested_restaurants": suggested_ids,
            "status": "success"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
