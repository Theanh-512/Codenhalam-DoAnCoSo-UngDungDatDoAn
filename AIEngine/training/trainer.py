"""Training loop cho SCR-Multimodal Recommender."""
import logging, os, time
from typing import Optional
import torch
import torch.nn as nn
from torch.utils.data import DataLoader

logger = logging.getLogger(__name__)


def recall_at_k(log_probs: torch.Tensor, targets: torch.Tensor, k: int = 10) -> float:
    """Recall@K: tỉ lệ target nằm trong top-K dự đoán."""
    topk = torch.topk(log_probs, k, dim=-1).indices
    hits = (topk == targets.unsqueeze(1)).any(dim=1).float()
    return hits.mean().item()


def ndcg_at_k(log_probs: torch.Tensor, targets: torch.Tensor, k: int = 10) -> float:
    """NDCG@K: Normalized Discounted Cumulative Gain."""
    import math
    topk = torch.topk(log_probs, k, dim=-1).indices
    ndcg_sum = 0.0
    for i in range(len(targets)):
        t = targets[i].item()
        rank_list = topk[i].tolist()
        if t in rank_list:
            rank = rank_list.index(t) + 1
            ndcg_sum += 1.0 / math.log2(rank + 1)
    return ndcg_sum / len(targets)


class SCRTrainer:
    """
    Trainer hoàn chỉnh cho SCRMultimodalRecommender.
    Loss: NLL Loss → argmin(Θ) = -Σ g_k
    """

    def __init__(self, model: nn.Module, config: dict, save_dir: str = "checkpoints"):
        self.model    = model
        self.config   = config
        self.device   = torch.device(config.get("device", "cpu"))
        self.model.to(self.device)

        self.optimizer = torch.optim.Adam(
            model.parameters(),
            lr=config["learning_rate"],
            weight_decay=config.get("weight_decay", 1e-5)
        )
        self.scheduler = torch.optim.lr_scheduler.ReduceLROnPlateau(
            self.optimizer, mode='min', patience=3, factor=0.5
        )
        self.loss_fn  = nn.NLLLoss()
        self.save_dir = save_dir
        os.makedirs(save_dir, exist_ok=True)

        self.best_val_loss  = float('inf')
        self.patience_count = 0
        self.history        = {'train_loss': [], 'val_loss': [], 'val_recall': [], 'val_ndcg': []}
        logger.info(f"[SCRTrainer] device={self.device}, lr={config['learning_rate']}")

    def _batch_to_device(self, batch: dict) -> dict:
        return {k: v.to(self.device) if isinstance(v, torch.Tensor) else v
                for k, v in batch.items()}

    def _forward_batch(self, batch: dict):
        b = self._batch_to_device(batch)
        log_probs, attn, fusion = self.model(
            user_ids       = b['user_id'],
            long_item_ids  = b['long_item_ids'],
            long_time_ids  = b['long_time_ids'],
            delta_ts       = b.get('delta_ts', None),
            history_slots  = b['history_slots'],
            current_slots  = b['current_slots'],
            history_coords = b['history_coords'],
            current_coord  = b['current_coord'],
            short_item_ids = b['short_item_ids'],
            image_tensors  = b['image_tensor'],
            padding_mask   = b['padding_mask'],
        )
        return log_probs, b['target_item_id']

    def train_epoch(self, loader: DataLoader) -> float:
        self.model.train()
        total_loss, n_batches = 0.0, 0
        clip = self.config.get("clip_grad_norm", 5.0)
        log_interval = self.config.get("log_interval", 10)

        for i, batch in enumerate(loader):
            self.optimizer.zero_grad()
            log_probs, targets = self._forward_batch(batch)
            loss = self.loss_fn(log_probs, targets)
            loss.backward()
            nn.utils.clip_grad_norm_(self.model.parameters(), clip)
            self.optimizer.step()
            total_loss += loss.item()
            n_batches  += 1
            if (i + 1) % log_interval == 0:
                logger.info(f"  [Train] Batch {i+1}/{len(loader)} | loss={loss.item():.4f}")

        return total_loss / max(n_batches, 1)

    @torch.no_grad()
    def evaluate(self, loader: DataLoader, k: int = 10):
        self.model.eval()
        total_loss, total_recall, total_ndcg, n = 0.0, 0.0, 0.0, 0
        for batch in loader:
            log_probs, targets = self._forward_batch(batch)
            loss = self.loss_fn(log_probs, targets)
            total_loss   += loss.item()
            total_recall += recall_at_k(log_probs, targets, k)
            total_ndcg   += ndcg_at_k(log_probs, targets, k)
            n += 1
        return (total_loss / max(n, 1),
                total_recall / max(n, 1),
                total_ndcg / max(n, 1))

    def fit(self, train_loader: DataLoader, val_loader: DataLoader):
        num_epochs = self.config.get("num_epochs", 50)
        patience   = self.config.get("patience", 10)

        for epoch in range(1, num_epochs + 1):
            t0 = time.time()
            train_loss = self.train_epoch(train_loader)
            val_loss, val_recall, val_ndcg = self.evaluate(val_loader)
            elapsed = time.time() - t0

            self.scheduler.step(val_loss)
            self.history['train_loss'].append(train_loss)
            self.history['val_loss'].append(val_loss)
            self.history['val_recall'].append(val_recall)
            self.history['val_ndcg'].append(val_ndcg)

            logger.info(
                f"Epoch {epoch:03d}/{num_epochs} | "
                f"train_loss={train_loss:.4f} | val_loss={val_loss:.4f} | "
                f"Recall@10={val_recall:.4f} | NDCG@10={val_ndcg:.4f} | {elapsed:.1f}s"
            )

            if val_loss < self.best_val_loss:
                self.best_val_loss = val_loss
                self.patience_count = 0
                ckpt_path = os.path.join(self.save_dir, "best_scr_model.pt")
                torch.save(self.model.state_dict(), ckpt_path)
                logger.info(f"  ✅ Best model saved → {ckpt_path}")
            else:
                self.patience_count += 1
                if self.patience_count >= patience:
                    logger.info(f"  ⏹️  Early stopping at epoch {epoch}")
                    break

        return self.history
