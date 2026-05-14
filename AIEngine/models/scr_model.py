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


class HierarchicalFusion(nn.Module):
    """
    Logic Hierarchical Attention (chú ý phân tầng) để kết hợp:
    1. Short-term Preference (U_short)
    2. Long-term Preference (U_long)
    3. Multimodal Features (e_img)
    """
    def __init__(self, dim: int, dropout: float = 0.5):
        super().__init__()
        self.W_fusion = nn.Linear(dim, dim)
        self.v_fusion = nn.Linear(dim, 1, bias=False)
        self.dropout = nn.Dropout(dropout)

    def forward(self, u_short, u_long, e_img, e_review):
        """
        Args:
            u_short: (B, D)
            u_long:  (B, D)
            e_img:   (B, D)
            e_review: (B, D) - Vector đặc trưng cảm xúc từ Review
        Returns:
            fused: (B, D)
        """
        # Stack vectors: (B, 4, D)
        stacked = torch.stack([u_short, u_long, e_img, e_review], dim=1)
        
        # Attention scores: (B, 4)
        scores = self.v_fusion(torch.tanh(self.W_fusion(stacked))).squeeze(-1) 
        weights = F.softmax(scores, dim=-1).unsqueeze(-1) # (B, 4, 1)
        
        # Weighted sum
        fused = (weights * stacked).sum(dim=1) # (B, D)
        return self.dropout(fused), weights

class SCRMultimodalRecommender(nn.Module):
    """
    Mô hình gợi ý đa phương thức SCR với Hierarchical Fusion.
    """

    def __init__(self,
                 num_users:      int   = 1000,
                 num_items:      int   = 500,
                 num_time_slots: int   = 48,
                 item_dim:       int   = 64,   # Paper baseline: 64
                 user_dim:       int   = 64,   # Paper baseline: 64
                 time_dim:       int   = 32,
                 lstm_hidden:    int   = 64,   # Paper baseline: 64
                 image_dim:      int   = 64,   # Project to 64
                 num_heads:      int   = 2,    # Paper baseline: 2
                 dropout:        float = 0.5): # Paper baseline: 0.5
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
        # Đảm bảo các vector có cùng chiều để dùng Hierarchical Attention
        # Nếu khác chiều, ta sẽ thêm các lớp Linear để map về chung item_dim (64)
        self.map_long   = nn.Linear(lstm_hidden, item_dim) if lstm_hidden != item_dim else nn.Identity()
        self.map_image  = nn.Linear(image_dim, item_dim)   if image_dim != item_dim else nn.Identity()
        self.map_review = nn.Linear(1, item_dim) # Ánh xạ điểm sentiment (1 chiều) sang item_dim (64 chiều)

        self.hierarchical_fusion = HierarchicalFusion(dim=item_dim, dropout=dropout)

        self.prediction_head = nn.Sequential(
            nn.Linear(item_dim, 256),
            nn.ReLU(),
            nn.Dropout(dropout),
            nn.Linear(256, num_items),
        )

        logger.info(
            f"[SCRMultimodalRecommender] Hierarchical Fusion Initialized | "
            f"dim={item_dim}, num_heads={num_heads}, dropout={dropout}"
        )

    def forward(self,
                user_ids:       torch.Tensor,
                long_item_ids:  torch.Tensor,
                long_time_ids:  torch.Tensor,
                delta_ts:       torch.Tensor,
                history_slots:  torch.Tensor,
                current_slots:  torch.Tensor,
                history_coords: torch.Tensor,
                current_coord:  torch.Tensor,
                short_item_ids: torch.Tensor,
                image_tensors:  torch.Tensor,
                review_scores:  torch.Tensor, # (B, 1) - Điểm cảm xúc từ Google/Supabase
                padding_mask:   torch.Tensor = None):
        """
        Args:
            user_ids:       (B,)
            long_item_ids:  (B, L)
            long_time_ids:  (B, L)
            delta_ts:       (B, L, 1)     — Time intervals for Time-LSTM
            history_slots:  (B, L, 48)
            current_slots:  (B, 48)
            history_coords: (B, L, 2)
            current_coord:  (B, 2)
            short_item_ids: (B, S)
            image_tensors:  (B, 3, 224, 224)
            review_scores:  (B, 1)
            padding_mask:   (B, S)
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
            delta_ts=delta_ts,
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

        # ── E. Hierarchical Fusion → Prediction ─────────────────────────────
        u_long_mapped   = self.map_long(u_long)
        e_img_mapped    = self.map_image(e_img)
        e_review_mapped = self.map_review(review_scores)
        
        fused, fusion_weights = self.hierarchical_fusion(
            u_short, u_long_mapped, e_img_mapped, e_review_mapped
        )
        
        logits = self.prediction_head(fused)
        log_probs = F.log_softmax(logits, dim=-1)

        return log_probs, attn_weights, fusion_weights


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
