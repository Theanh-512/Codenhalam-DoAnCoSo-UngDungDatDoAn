"""
Khối Sở Thích Ngắn Hạn (Short-Term Preference Block)
======================================================
Hiện thực hóa 2 tầng attention:

1. Self Multi-Head Attention:
   Học mối quan hệ giữa các item KHÔNG liền kề trong phiên S_n (24h).

2. Vanilla Attention Aggregation:
   Query = cat([u_user, h_last])  ← User embedding + Item cuối phiên
   Tổng hợp hidden states H thành vector U_short.

   e_i   = v^T · tanh(W1·h_i + W2·query)
   α_i   = softmax(e_i)
   U_short = Σ α_i · h_i
"""

import logging
import torch
import torch.nn as nn
import torch.nn.functional as F

logger = logging.getLogger(__name__)


class VanillaAttentionAggregator(nn.Module):
    """
    Vanilla Attention với query = cat([user_emb, last_item_emb]).
    """

    def __init__(self, hidden_dim: int, query_dim: int):
        """
        Args:
            hidden_dim: Chiều của mỗi hidden state h_i
            query_dim:  Chiều của query vector (user_dim + item_dim)
        """
        super().__init__()
        # W1: chiếu h_i vào không gian attention
        self.W1 = nn.Linear(hidden_dim, hidden_dim, bias=False)
        # W2: chiếu query vào cùng không gian
        self.W2 = nn.Linear(query_dim, hidden_dim, bias=True)
        # v: vector trọng số cuối
        self.v  = nn.Linear(hidden_dim, 1, bias=False)

    def forward(self, H: torch.Tensor, query: torch.Tensor, mask: torch.Tensor = None):
        """
        Args:
            H:     (B, L, hidden_dim) — Chuỗi hidden states
            query: (B, query_dim)     — cat([u_user, h_last])
            mask:  (B, L) bool        — True = padding (sẽ bị mask = -inf)
        Returns:
            u_short: (B, hidden_dim)
            alpha:   (B, L) — attention weights
        """
        # W1·h_i: (B, L, H)
        w1h = self.W1(H)

        # W2·query: (B, H) → unsqueeze → (B, 1, H) để broadcast
        w2q = self.W2(query).unsqueeze(1)

        # e_i = v^T · tanh(W1·h_i + W2·query)
        e = self.v(torch.tanh(w1h + w2q)).squeeze(-1)  # (B, L)

        # Masking padding positions
        if mask is not None:
            e = e.masked_fill(mask, float('-inf'))

        alpha = F.softmax(e, dim=-1)  # (B, L)

        # U_short = Σ α_i · h_i
        u_short = (alpha.unsqueeze(-1) * H).sum(dim=1)  # (B, H)
        return u_short, alpha


class ShortTermPreference(nn.Module):
    """
    Khối Short-Term Preference hoàn chỉnh:
      1. Self Multi-Head Attention (học quan hệ item không liền kề)
      2. Vanilla Attention Aggregation (tổng hợp → U_short)
    """

    def __init__(self, item_dim: int, user_dim: int,
                 num_heads: int = 2, dropout: float = 0.5):
        """
        Args:
            item_dim:  Chiều embedding của item (= embed_dim cho MHA)
            user_dim:  Chiều embedding của user (dùng trong Vanilla Attn)
            num_heads: Số đầu Multi-Head Attention
            dropout:   Dropout rate
        """
        super().__init__()
        self.item_dim = item_dim
        self.user_dim = user_dim

        # ── Tầng 1: Self Multi-Head Attention ──────────────────────────
        self.multihead_attn = nn.MultiheadAttention(
            embed_dim=item_dim,
            num_heads=num_heads,
            dropout=dropout,
            batch_first=True
        )
        self.layer_norm1 = nn.LayerNorm(item_dim)

        # Feed-Forward Network (Transformer-style)
        self.ffn = nn.Sequential(
            nn.Linear(item_dim, item_dim * 4),
            nn.ReLU(),
            nn.Dropout(dropout),
            nn.Linear(item_dim * 4, item_dim)
        )
        self.layer_norm2 = nn.LayerNorm(item_dim)

        # ── Tầng 2: Vanilla Attention Aggregation ──────────────────────
        # query_dim = user_dim + item_dim (cat([u_user, h_last]))
        query_dim = user_dim + item_dim
        self.vanilla_attn = VanillaAttentionAggregator(
            hidden_dim=item_dim,
            query_dim=query_dim
        )

        self.dropout = nn.Dropout(dropout)

        logger.info(
            f"[ShortTermPreference] item_dim={item_dim}, user_dim={user_dim}, "
            f"num_heads={num_heads}, dropout={dropout}"
        )

    def forward(self, e_session: torch.Tensor,
                u_user: torch.Tensor,
                key_padding_mask: torch.Tensor = None):
        """
        Args:
            e_session:         (B, L, item_dim) — Item embeddings trong phiên S_n
            u_user:            (B, user_dim)    — User embedding
            key_padding_mask:  (B, L) bool      — True nếu là padding
        Returns:
            u_short:      (B, item_dim) — Vector sở thích ngắn hạn
            attn_weights: (B, L, L)    — Self-attention weights
        """
        # ── Tầng 1: Self Multi-Head Attention ──────────────────────────
        attn_output, attn_weights = self.multihead_attn(
            e_session, e_session, e_session,
            key_padding_mask=key_padding_mask
        )
        # Add & Norm
        H = self.layer_norm1(e_session + self.dropout(attn_output))

        # FFN + Add & Norm
        ffn_out = self.ffn(H)
        H = self.layer_norm2(H + self.dropout(ffn_out))  # (B, L, item_dim)

        # ── Tầng 2: Vanilla Attention Aggregation ──────────────────────
        # Query = cat([u_user, h_last])  (h_last = H[:, -1, :])
        h_last = H[:, -1, :]                                        # (B, item_dim)
        query = torch.cat([u_user, h_last], dim=-1)                 # (B, user_dim + item_dim)

        u_short, alpha = self.vanilla_attn(H, query, mask=key_padding_mask)  # (B, item_dim)

        logger.debug(
            f"[ShortTermPreference] u_short.shape={u_short.shape}, "
            f"alpha.shape={alpha.shape}"
        )
        return u_short, attn_weights


# ── Backward-compat alias ────────────────────────────────────────────────────
class SelfAttentionAggregator(nn.Module):
    """
    Legacy alias. Dùng ShortTermPreference bên trong nhưng giữ API cũ:
    forward(x) → (u_short, attn_weights)
    """

    def __init__(self, embed_dim: int, num_heads: int = 2, dropout: float = 0.5):
        super().__init__()
        self._inner = ShortTermPreference(
            item_dim=embed_dim,
            user_dim=embed_dim,   # Dùng zero user embed trong legacy mode
            num_heads=num_heads,
            dropout=dropout
        )
        self._embed_dim = embed_dim
        logger.warning("[SelfAttentionAggregator] Running in legacy mode — user_dim=embed_dim, u_user=zeros")

    def forward(self, x: torch.Tensor):
        """
        Legacy forward: x=(B, L, embed_dim) → (u_short, attn_weights)
        """
        B = x.shape[0]
        u_user_dummy = torch.zeros(B, self._embed_dim, device=x.device)
        return self._inner(x, u_user_dummy)
