"""
Grid Search cho SCR-Multimodal Recommender
==========================================
Tìm kiếm tổ hợp tối ưu: learning_rate × dropout × num_heads
Metric: Recall@10, NDCG@10
"""

import logging, copy, itertools
from typing import Callable
import torch
from torch.utils.data import DataLoader

logger = logging.getLogger(__name__)

# Tham số grid mặc định theo đề bài (paper baseline: lr=0.001, dropout=0.5, #head=2)
DEFAULT_GRID = {
    "learning_rate": [0.001, 0.0005, 0.0001],
    "dropout":       [0.3,   0.5,    0.7],
    "num_heads":     [2,     4,      8],
}


def run_grid_search(
    model_factory: Callable,
    base_config:   dict,
    train_loader:  DataLoader,
    val_loader:    DataLoader,
    grid: dict = None,
    max_epochs_per_run: int = 5,
    device: str = "cpu",
) -> dict:
    """
    Chạy exhaustive grid search và trả về kết quả tổng hợp.

    Args:
        model_factory:       Hàm nhận (config) → trả về model mới
        base_config:         Config gốc (sẽ được override với từng combo)
        train_loader:        DataLoader tập train
        val_loader:          DataLoader tập val
        grid:                Dict {param_name: [values]}
        max_epochs_per_run:  Số epoch tối đa mỗi thí nghiệm (nhanh hơn)
        device:              "cpu" hoặc "cuda"
    Returns:
        results: {'best_config': ..., 'best_recall': ..., 'all_results': [...]}
    """
    from training.trainer import SCRTrainer

    if grid is None:
        grid = DEFAULT_GRID

    # Sinh tất cả tổ hợp tham số
    param_names = list(grid.keys())
    param_values = list(grid.values())
    combinations = list(itertools.product(*param_values))

    logger.info(
        f"[GridSearch] Bắt đầu {len(combinations)} thí nghiệm | "
        f"Params: {param_names}"
    )

    all_results = []
    best_recall = -1.0
    best_config = None

    for run_idx, combo in enumerate(combinations):
        run_config = copy.deepcopy(base_config)
        run_config.update(dict(zip(param_names, combo)))
        run_config["num_epochs"] = max_epochs_per_run
        run_config["device"]     = device
        run_config["patience"]   = max_epochs_per_run  # Không early-stop sớm

        logger.info(
            f"\n{'='*60}\n"
            f"[GridSearch] Run {run_idx+1}/{len(combinations)} | {dict(zip(param_names, combo))}"
        )

        try:
            model = model_factory(run_config)
            trainer = SCRTrainer(model, run_config, save_dir=f"checkpoints/grid_run_{run_idx}")
            trainer.fit(train_loader, val_loader)

            # Đánh giá trên val set
            val_loss, val_recall, val_ndcg = trainer.evaluate(val_loader)

            result = {
                "run_idx":    run_idx,
                "config":     dict(zip(param_names, combo)),
                "val_loss":   round(val_loss, 4),
                "val_recall": round(val_recall, 4),
                "val_ndcg":   round(val_ndcg, 4),
            }
            all_results.append(result)

            logger.info(
                f"  → val_loss={val_loss:.4f} | "
                f"Recall@10={val_recall:.4f} | NDCG@10={val_ndcg:.4f}"
            )

            if val_recall > best_recall:
                best_recall = val_recall
                best_config = run_config
                logger.info(f"  ⭐ New best! Recall@10={best_recall:.4f}")

        except Exception as e:
            logger.error(f"  ❌ Run {run_idx+1} FAILED: {e}")
            all_results.append({
                "run_idx": run_idx, "config": dict(zip(param_names, combo)),
                "error": str(e)
            })

    # In bảng tổng kết
    logger.info("\n" + "="*60)
    logger.info("[GridSearch] KẾT QUẢ TỔNG HỢP:")
    logger.info(f"{'Run':<5} {'lr':<8} {'dropout':<10} {'heads':<7} {'Recall@10':<12} {'NDCG@10'}")
    for r in sorted(all_results, key=lambda x: x.get('val_recall', -1), reverse=True):
        if 'error' not in r:
            c = r['config']
            logger.info(
                f"{r['run_idx']:<5} "
                f"{c.get('learning_rate', '?'):<8} "
                f"{c.get('dropout', '?'):<10} "
                f"{c.get('num_heads', '?'):<7} "
                f"{r['val_recall']:<12} "
                f"{r['val_ndcg']}"
            )
    logger.info(f"\n✅ Best config: {best_config}")
    logger.info(f"✅ Best Recall@10: {best_recall:.4f}")

    return {
        "best_config":  best_config,
        "best_recall":  best_recall,
        "all_results":  all_results,
    }
