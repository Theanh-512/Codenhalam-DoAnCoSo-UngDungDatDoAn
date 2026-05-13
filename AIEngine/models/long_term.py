"""
Khối Sở Thích Dài Hạn (Long-Term Preference Block)
====================================================
Hiện thực hóa đúng các công thức từ bài báo SCR:

  f_t = σ(W_f1·[e_item, e_time] + W_f2·h_{t-1} + b_f)
  i_t = σ(W_i1·[e_item, e_time] + W_i2·h_{t-1} + b_i)
  o_t = σ(W_o1·[e_item, e_time] + W_o2·h_{t-1} + b_o)

  Time Weight:     γ_{i,j} = |T_i ∩ T_j| / |T_i ∪ T_j|  (Jaccard)
  Distance Weight: d_{lt,h} = sqrt((Δlat)² + (Δlon)²)
                   w_h = 1 / (d_{lt,h} + ε)
"""

import math
import logging
import torch
import torch.nn as nn
import torch.nn.functional as F

logger = logging.getLogger(__name__)


class CustomLSTMCell(nn.Module):
    """
    LSTMCell hiện thực đúng kiến trúc SCR:
    Input = concat([e_item, e_time]) → Tách biệt với h_{t-1}
    để map chính xác W_f1·[e_l, e_t] và W_f2·h_{t-1}.
    """

    def __init__(self, input_dim: int, hidden_dim: int):
        """
        Args:
            input_dim:  Kích thước input = item_dim + time_dim
            hidden_dim: Kích thước hidden state (h_t, c_t)
        """
        super().__init__()
        self.hidden_dim = hidden_dim

        # W_f1, W_i1, W_o1 → áp dụng lên [e_item, e_time]
        self.W1_forget = nn.Linear(input_dim, hidden_dim, bias=False)
        self.W1_input  = nn.Linear(input_dim, hidden_dim, bias=False)
        self.W1_output = nn.Linear(input_dim, hidden_dim, bias=False)
        self.W1_cell   = nn.Linear(input_dim, hidden_dim, bias=False)

        # W_f2, W_i2, W_o2 → áp dụng lên h_{t-1}
        self.W2_forget = nn.Linear(hidden_dim, hidden_dim, bias=True)
        self.W2_input  = nn.Linear(hidden_dim, hidden_dim, bias=True)
        self.W2_output = nn.Linear(hidden_dim, hidden_dim, bias=True)
        self.W2_cell   = nn.Linear(hidden_dim, hidden_dim, bias=True)

    def forward(self, x_t, h_prev, c_prev):
        """
        Args:
            x_t:    (batch, input_dim)  — concat([e_item, e_time])
            h_prev: (batch, hidden_dim) — h_{t-1}
            c_prev: (batch, hidden_dim) — c_{t-1}
        Returns:
            h_t, c_t: (batch, hidden_dim)
        """
        # f_t = σ(W_f1·x_t + W_f2·h_{t-1} + b_f)
        f_t = torch.sigmoid(self.W1_forget(x_t) + self.W2_forget(h_prev))

        # i_t = σ(W_i1·x_t + W_i2·h_{t-1} + b_i)
        i_t = torch.sigmoid(self.W1_input(x_t) + self.W2_input(h_prev))

        # o_t = σ(W_o1·x_t + W_o2·h_{t-1} + b_o)
        o_t = torch.sigmoid(self.W1_output(x_t) + self.W2_output(h_prev))

        # g_t = tanh(W_g1·x_t + W_g2·h_{t-1} + b_g)  [cell candidate]
        g_t = torch.tanh(self.W1_cell(x_t) + self.W2_cell(h_prev))

        # c_t = f_t ⊙ c_{t-1} + i_t ⊙ g_t
        c_t = f_t * c_prev + i_t * g_t

        # h_t = o_t ⊙ tanh(c_t)
        h_t = o_t * torch.tanh(c_t)

        return h_t, c_t


class JaccardTimeWeighter(nn.Module):
    """
    Tính Jaccard Similarity γ_{i,j} = |T_i ∩ T_j| / |T_i ∪ T_j|
    giữa time-slot của phiên hiện tại và các phiên lịch sử.

    T: vector nhị phân (batch, seq_len, num_time_slots=48)
    """

    def __init__(self, num_time_slots: int = 48, eps: float = 1e-8):
        super().__init__()
        self.num_slots = num_time_slots
        self.eps = eps

    def forward(self, history_slots: torch.Tensor, current_slots: torch.Tensor):
        """
        Args:
            history_slots: (batch, seq_len, 48) — binary time-slot vectors lịch sử
            current_slots: (batch, 48)           — time-slot vector phiên hiện tại
        Returns:
            gamma: (batch, seq_len, 1) — Jaccard similarity scores
        """
        # Mở rộng current_slots để broadcast: (batch, 1, 48)
        current_expanded = current_slots.unsqueeze(1)

        # Intersection: |T_i ∩ T_j| — sum của AND giữa hai binary vectors
        intersection = (history_slots * current_expanded).sum(dim=-1, keepdim=True)  # (B, L, 1)

        # Union: |T_i ∪ T_j| = |T_i| + |T_j| - |T_i ∩ T_j|
        union = (
            history_slots.sum(dim=-1, keepdim=True)
            + current_slots.sum(dim=-1, keepdim=True).unsqueeze(1)
            - intersection
        )  # (B, L, 1)

        # γ_{i,j} = |T_i ∩ T_j| / (|T_i ∪ T_j| + ε)
        gamma = intersection / (union + self.eps)
        return gamma  # (B, L, 1)


class DistanceWeighter(nn.Module):
    """
    Tính trọng số khoảng cách Euclidean:
      d_{lt,h} = sqrt((Δlat)² + (Δlon)²)
      w_h = 1 / (d_{lt,h} + ε)    ← Phiên gần → trọng số cao hơn
    """

    def __init__(self, eps: float = 1e-6):
        super().__init__()
        self.eps = eps

    def forward(self, history_coords: torch.Tensor, current_coord: torch.Tensor):
        """
        Args:
            history_coords: (batch, seq_len, 2) — [lat, lon] của các phiên lịch sử
            current_coord:  (batch, 2)          — [lat, lon] vị trí hiện tại
        Returns:
            dist_weights: (batch, seq_len, 1) — w_h = 1/(d + ε)
        """
        # Mở rộng current_coord: (batch, 1, 2)
        current_expanded = current_coord.unsqueeze(1)

        # d_{lt,h} = sqrt((Δlat)² + (Δlon)²)
        diff = history_coords - current_expanded        # (B, L, 2)
        dist = torch.sqrt((diff ** 2).sum(dim=-1, keepdim=True) + self.eps)  # (B, L, 1)

        # w_h = 1 / (d + ε)
        dist_weights = 1.0 / (dist + self.eps)
        return dist_weights  # (B, L, 1)


class LongTermPreference(nn.Module):
    """
    Khối Sở Thích Dài Hạn hoàn chỉnh:
    1. Mỗi bước t: x_t = cat([e_item_t, e_time_t])
    2. Chạy CustomLSTMCell để lấy chuỗi hidden states H = {h_1,...,h_L}
    3. Tính Jaccard time-weight (γ) và Distance weight (w)
    4. U_long = Σ_t (γ_t · w_t · h_t) / Σ(γ_t · w_t)
    """

    def __init__(self, item_dim: int, time_dim: int, hidden_dim: int,
                 num_time_slots: int = 48, eps: float = 1e-6):
        super().__init__()
        self.hidden_dim = hidden_dim
        input_dim = item_dim + time_dim

        self.lstm_cell     = CustomLSTMCell(input_dim, hidden_dim)
        self.time_weighter = JaccardTimeWeighter(num_time_slots, eps)
        self.dist_weighter = DistanceWeighter(eps)

        logger.info(
            f"[LongTermPreference] input_dim={input_dim}, hidden_dim={hidden_dim}, "
            f"num_time_slots={num_time_slots}"
        )

    def forward(self,
                e_items:         torch.Tensor,
                e_times:         torch.Tensor,
                history_slots:   torch.Tensor,
                current_slots:   torch.Tensor,
                history_coords:  torch.Tensor,
                current_coord:   torch.Tensor):
        """
        Args:
            e_items:        (B, L, item_dim)   — item embeddings chuỗi dài hạn
            e_times:        (B, L, time_dim)   — time embeddings chuỗi dài hạn
            history_slots:  (B, L, 48)         — binary time-slot vectors
            current_slots:  (B, 48)            — time-slot vector hiện tại
            history_coords: (B, L, 2)          — [lat, lon] các phiên lịch sử
            current_coord:  (B, 2)             — [lat, lon] vị trí hiện tại
        Returns:
            u_long: (B, hidden_dim)
        """
        B, L, _ = e_items.shape
        device = e_items.device

        # Khởi tạo hidden và cell state
        h = torch.zeros(B, self.hidden_dim, device=device)
        c = torch.zeros(B, self.hidden_dim, device=device)

        hidden_states = []  # Lưu h_t tại mỗi bước

        # ── Bước 1: Chạy qua CustomLSTMCell từng bước t ──
        for t in range(L):
            x_t = torch.cat([e_items[:, t, :], e_times[:, t, :]], dim=-1)  # (B, item+time)
            h, c = self.lstm_cell(x_t, h, c)
            hidden_states.append(h.unsqueeze(1))  # (B, 1, H)

        H = torch.cat(hidden_states, dim=1)  # (B, L, H)

        # ── Bước 2: Tính trọng số Jaccard và Distance ──
        gamma = self.time_weighter(history_slots, current_slots)   # (B, L, 1)
        w     = self.dist_weighter(history_coords, current_coord)  # (B, L, 1)

        # ── Bước 3: Kết hợp trọng số ──
        combined_weight = gamma * w                                # (B, L, 1)
        combined_weight = combined_weight / (combined_weight.sum(dim=1, keepdim=True) + 1e-8)

        # ── Bước 4: U_long = Σ weight_t · h_t ──
        u_long = (combined_weight * H).sum(dim=1)                 # (B, H)

        logger.debug(f"[LongTermPreference] u_long.shape={u_long.shape}")
        return u_long, gamma, w


# ── Backward-compat alias (cho test.py cũ) ──────────────────────────────────
class TimeDistanceWeightedLSTM(LongTermPreference):
    """Legacy alias giữ backward compatibility với test.py."""

    def __init__(self, input_dim, hidden_dim, num_layers=1):
        # input_dim ở đây = item_dim (time_dim mặc định = 0 cho legacy)
        super().__init__(
            item_dim=input_dim,
            time_dim=0,          # không dùng time embedding riêng trong legacy
            hidden_dim=hidden_dim
        )
        self._legacy_mode = True
        logger.warning("[TimeDistanceWeightedLSTM] Running in legacy mode — time_dim=0")

    def forward(self, x, time_scores, dist_scores):
        """Legacy forward: x=(B,L,D), time_scores=(B,L,1), dist_scores=(B,L,1)"""
        B, L, D = x.shape
        device = x.device

        h = torch.zeros(B, self.hidden_dim, device=device)
        c = torch.zeros(B, self.hidden_dim, device=device)

        hidden_states = []
        for t in range(L):
            x_t = x[:, t, :]  # (B, D)
            # Legacy: không có e_time → dùng zero padding
            x_t_padded = x_t  # input_dim = item_dim, time_dim=0
            h, c = self.lstm_cell(x_t_padded, h, c)
            hidden_states.append(h.unsqueeze(1))

        H = torch.cat(hidden_states, dim=1)   # (B, L, H)

        # Dùng time_scores và dist_scores trực tiếp làm weight
        combined = time_scores * dist_scores  # (B, L, 1)
        combined = combined / (combined.sum(dim=1, keepdim=True) + 1e-8)
        u_long = (combined * H).sum(dim=1)    # (B, H)
        return u_long
