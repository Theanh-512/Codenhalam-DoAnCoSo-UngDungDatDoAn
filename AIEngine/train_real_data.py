import os
import csv
import logging
import torch
import datetime
from models.scr_model import SCRMultimodalRecommender
from data.dataset import build_dataloaders
from training.trainer import SCRTrainer
from data.dataset import encode_time_slot

logging.basicConfig(level=logging.INFO, format="%(message)s")
logger = logging.getLogger(__name__)

DATA_DIR = os.path.dirname(os.path.abspath(__file__))
INTERACTION_FILE = os.path.join(DATA_DIR, "data", "interactions.csv")

def load_interactions():
    records = []
    if not os.path.exists(INTERACTION_FILE):
        print(f"File {INTERACTION_FILE} không tồn tại. Hãy chạy generate_dataset.py trước.")
        return records
        
    with open(INTERACTION_FILE, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            try:
                dt = datetime.datetime.strptime(row['timestamp'], "%Y-%m-%dT%H:%M:%S")
                records.append({
                    'user_id': int(row['user_id']),
                    'item_id': int(row['item_id']),
                    'timestamp': dt.timestamp(),
                    'lat': float(row['lat']),
                    'lon': float(row['lon']),
                    'time_slot': encode_time_slot(dt.hour, dt.weekday() >= 5),
                    'is_weekend': dt.weekday() >= 5,
                    'image_path': row['image_path']
                })
            except Exception as e:
                continue
    return records

def main():
    print("=== BẮT ĐẦU HUẤN LUYỆN MÔ HÌNH VỚI DỮ LIỆU ẢNH THỰC TẾ ===")
    
    records = load_interactions()
    if not records:
        return
        
    print(f"Đã tải {len(records)} giao dịch.")
    
    # Đếm số lượng user và item thực tế
    num_users = max([r['user_id'] for r in records]) + 1
    num_items = max([r['item_id'] for r in records]) + 1
    
    config = {
        "num_users": num_users,
        "num_items": num_items,
        "num_time_slots": 48,
        "item_dim": 64,
        "user_dim": 64,
        "time_dim": 32,
        "lstm_hidden": 64,
        "image_dim": 64,
        "learning_rate": 0.001,
        "dropout": 0.5,
        "num_heads": 2,
        "batch_size": 32,
        "num_epochs": 2,
        "device": "cuda" if torch.cuda.is_available() else "cpu"
    }
    
    train_loader, val_loader, test_loader = build_dataloaders(
        records, num_items=num_items, batch_size=config["batch_size"]
    )
    
    # Override dataset parameter để nó dùng ảnh thật
    train_loader.dataset.use_dummy = False
    val_loader.dataset.use_dummy = False
    test_loader.dataset.use_dummy = False
    
    model = SCRMultimodalRecommender(
        num_users=config["num_users"],
        num_items=config["num_items"],
        num_time_slots=config["num_time_slots"],
        item_dim=config["item_dim"],
        user_dim=config["user_dim"],
        time_dim=config["time_dim"],
        lstm_hidden=config["lstm_hidden"],
        image_dim=config["image_dim"],
        num_heads=config["num_heads"],
        dropout=config["dropout"]
    )
    
    trainer = SCRTrainer(model, config)
    trainer.fit(train_loader, val_loader)
    
if __name__ == "__main__":
    main()
