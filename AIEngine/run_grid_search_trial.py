"""
Script chạy Grid Search Trial
==============================
Thực hiện tối ưu hóa hyperparameter cho mô hình SCR.
"""

import logging
import sys
import torch
from models.scr_model import SCRMultimodalRecommender
from data.dataset import create_dummy_records, build_dataloaders
from training.grid_search import run_grid_search

# Setup logging
logging.basicConfig(level=logging.INFO, format="%(message)s")
logger = logging.getLogger(__name__)

def model_factory(config):
    return SCRMultimodalRecommender(
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

def main():
    print("=== STARTING GRID SEARCH OPTIMIZATION TRIAL ===")
    
    # 1. Setup base config
    base_config = {
        "num_users": 50,
        "num_items": 100,
        "num_time_slots": 48,
        "item_dim": 64,
        "user_dim": 64,
        "time_dim": 32,
        "lstm_hidden": 64,
        "image_dim": 256,
        "learning_rate": 0.001,
        "dropout": 0.5,
        "num_heads": 2,
        "batch_size": 16,
        "num_epochs": 2,
        "device": "cpu"
    }

    # 2. Create small dummy dataset
    records = create_dummy_records(num_users=10, num_items=100, interactions_per_user=20)
    train_loader, val_loader, _ = build_dataloaders(
        records, num_items=100, batch_size=16
    )

    # 3. Define search space (rút gọn để chạy nhanh)
    search_grid = {
        "learning_rate": [0.001, 0.0005],
        "dropout": [0.3, 0.5],
        "num_heads": [2]
    }

    # 4. Run grid search
    run_grid_search(
        model_factory=model_factory,
        base_config=base_config,
        train_loader=train_loader,
        val_loader=val_loader,
        grid=search_grid,
        max_epochs_per_run=1,  # Chỉ 1 epoch mỗi run để demo
        device="cpu"
    )

if __name__ == "__main__":
    main()
