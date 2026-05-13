"""
SCR-Multimodal Recommender — Model Tổng Hợp
============================================
Kết hợp 3 khối:
  A. Long-Term Preference  : CustomLSTMCell + Jaccard + Distance
  B. Short-Term Preference : Self Multi-Head Attn + Vanilla Attn
  C. Multimodal & Prediction: DenseNet201 → Fusion → Log-Softmax

Loss: NLLLoss  →  argmin_Θ = -Σ g_k  (Negative Log-Likelihood)
"""

import logging
import torch
import torch.nn as nn
import torch.nn.functional as F

from .long_term  import LongTermPreference, TimeDistanceWeightedLSTM
from .short_term import ShortTermPreference, SelfAttentionAggregator
from .multimodal import ImageFeatureExtractor

logger = logging.getLogger(__name__)


class SCRMultimodalRecommender(nn.Module):
    """
    Mô hình gợi ý đa phương thức SCR.

    Tham số quan trọng:
        num_users  : Tổng số user (cho User Embedding)
        num_items  : Tổng số item/món ăn (cho Item Embedding + đầu ra)
        num_time_slots: 48 khe giờ (24h weekday + 24h weekend)
        item_dim   : Chiều nhúng item  (d)
        user_dim   : Chiều nhúng user  (d)
        time_dim   : Chiều nhúng time slot
        lstm_hidden: Chiều hidden LSTM = U_long dim
        image_dim  : Chiều vector ảnh  = e_img dim (DenseNet → 256)
        num_heads  : Số đầu Multi-Head Attention (paper baseline: 2)
        dropout    : Dropout rate (paper baseline: 0.5)
    """

    def __init__(self,
                 num_users:      int   = 1000,
                 num_items:      int   = 500,
                 num_time_slots: int   = 48,
                 item_dim:       int   = 128,
                 user_dim:       int   = 128,
                 time_dim:       int   = 64,
                 lstm_hidden:    int   = 128,
                 image_dim:      int   = 256,
                 num_heads:      int   = 2,
                 dropout:        float = 0.5):
        super().__init__()

        # ── A. Embedding Layers ──────────────────────────────────────────────
        self.user_embedding = nn.Embedding(num_users, user_dim)
        self.item_embedding = nn.Embedding(num_items, item_dim)
        self.time_embedding = nn.Embedding(num_time_slots, time_dim)

        # ── B. Long-Term Preference Module ──────────────────────────────────
        self.long_term = LongTermPreference(
            item_dim=item_dim,
            time_dim=time_dim,
            hidden_dim=lstm_hidden,
            num_time_slots=num_time_slots,
        )

        # ── C. Short-Term Preference Module ─────────────────────────────────
        self.short_term = ShortTermPreference(
            item_dim=item_dim,
            user_dim=user_dim,
            num_heads=num_heads,
            dropout=dropout,
        )

        # ── D. Image Feature Extractor (DenseNet201) ─────────────────────────
        self.image_module = ImageFeatureExtractor(feature_dim=image_dim)

        # ── E. Fusion & Prediction Head ──────────────────────────────────────
        # Concat: [U_short(item_dim), U_long(lstm_hidden), e_img(image_dim)]
        concat_dim = item_dim + lstm_hidden + image_dim

        self.fc = nn.Sequential(
            nn.Linear(concat_dim, 512),
            nn.ReLU(),
            nn.Dropout(dropout),
            nn.Linear(512, 256),
            nn.ReLU(),
            nn.Dropout(dropout),
            nn.Linear(256, num_items),   # Dự đoán xác suất cho toàn bộ num_items
        )

        logger.info(
            f"[SCRMultimodalRecommender] Initialized | "
            f"num_items={num_items}, item_dim={item_dim}, user_dim={user_dim}, "
            f"time_dim={time_dim}, lstm_hidden={lstm_hidden}, "
            f"image_dim={image_dim}, num_heads={num_heads}, dropout={dropout} | "
            f"concat_dim={concat_dim}"
        )

    def forward(self,
                user_ids:       torch.Tensor,
                long_item_ids:  torch.Tensor,
                long_time_ids:  torch.Tensor,
                history_slots:  torch.Tensor,
                current_slots:  torch.Tensor,
                history_coords: torch.Tensor,
                current_coord:  torch.Tensor,
                short_item_ids: torch.Tensor,
                image_tensors:  torch.Tensor,
                padding_mask:   torch.Tensor = None):
        """
        Args:
            user_ids:       (B,)          — User IDs
            long_item_ids:  (B, L)        — Item IDs lịch sử dài hạn
            long_time_ids:  (B, L)        — Time slot IDs lịch sử dài hạn
            history_slots:  (B, L, 48)    — Binary time-slot vectors lịch sử
            current_slots:  (B, 48)       — Time-slot vector phiên hiện tại
            history_coords: (B, L, 2)     — [lat, lon] các phiên lịch sử
            current_coord:  (B, 2)        — [lat, lon] vị trí user hiện tại
            short_item_ids: (B, S)        — Item IDs trong phiên S_n (24h)
            image_tensors:  (B, 3, 224, 224) — Ảnh món ăn hiện tại
            padding_mask:   (B, S) bool   — True = padding trong phiên ngắn hạn

        Returns:
            log_probs:   (B, num_items)   — Log-Softmax probabilities
            attn_weights:(B, S, S)        — Self-attention weights (short-term)
        """
        # ── A. Embeddings ──────────────────────────────────────────────────
        u_user   = self.user_embedding(user_ids)         # (B, user_dim)
        e_long   = self.item_embedding(long_item_ids)    # (B, L, item_dim)
        e_time_l = self.time_embedding(long_time_ids)    # (B, L, time_dim)
        e_short  = self.item_embedding(short_item_ids)   # (B, S, item_dim)

        # ── B. Long-Term U_long ─────────────────────────────────────────────
        u_long, gamma, dist_w = self.long_term(
            e_items=e_long,
            e_times=e_time_l,
            history_slots=history_slots,
            current_slots=current_slots,
            history_coords=history_coords,
            current_coord=current_coord,
        )  # u_long: (B, lstm_hidden)

        # ── C. Short-Term U_short ───────────────────────────────────────────
        u_short, attn_weights = self.short_term(
            e_session=e_short,
            u_user=u_user,
            key_padding_mask=padding_mask,
        )  # u_short: (B, item_dim)

        # ── D. Image Feature e_img ──────────────────────────────────────────
        e_img = self.image_module(image_tensors)         # (B, image_dim)

        # ── E. Fusion → Prediction ──────────────────────────────────────────
        # Concat [U_short || U_long || e_img]
        fused  = torch.cat([u_short, u_long, e_img], dim=-1)   # (B, concat_dim)
        logits = self.fc(fused)                                  # (B, num_items)

        # Log-Softmax → dùng với NLLLoss: L = -Σ g_k
        log_probs = F.log_softmax(logits, dim=-1)               # (B, num_items)

        logger.debug(
            f"[SCR.forward] log_probs={log_probs.shape}, "
            f"u_long={u_long.shape}, u_short={u_short.shape}, e_img={e_img.shape}"
        )
        return log_probs, attn_weights


# ── Backward-compat wrapper (giữ API của test.py cũ) ────────────────────────
class SCRMultimodalRecommenderLegacy(nn.Module):
    """
    Legacy wrapper: giữ nguyên signature cũ của test.py
      forward(long_items, time_scores, dist_scores, short_items, image_tensors)
    """

    def __init__(self, num_items: int, item_dim: int = 128,
                 lstm_hidden: int = 128, image_dim: int = 256):
        super().__init__()

        self.item_embedding = nn.Embedding(num_items, item_dim)
        self.long_term_module = TimeDistanceWeightedLSTM(
            input_dim=item_dim, hidden_dim=lstm_hidden
        )
        self.short_term_module = SelfAttentionAggregator(
            embed_dim=item_dim, num_heads=2
        )
        self.image_module = ImageFeatureExtractor(feature_dim=image_dim)

        concat_dim = item_dim + lstm_hidden + image_dim
        self.fc = nn.Sequential(
            nn.Linear(concat_dim, 512),
            nn.ReLU(),
            nn.Dropout(0.2),
            nn.Linear(512, num_items)
        )

    def forward(self, long_items, time_scores, dist_scores, short_items, image_tensors):
        e_long   = self.item_embedding(long_items)   # (B, L, D)
        u_long   = self.long_term_module(e_long, time_scores, dist_scores)

        e_short  = self.item_embedding(short_items)  # (B, S, D)
        u_short, attn_weights = self.short_term_module(e_short)

        e_img    = self.image_module(image_tensors)
        fused    = torch.cat([u_short, u_long, e_img], dim=-1)
        logits   = self.fc(fused)
        log_probs = F.log_softmax(logits, dim=-1)
        return log_probs, attn_weights
