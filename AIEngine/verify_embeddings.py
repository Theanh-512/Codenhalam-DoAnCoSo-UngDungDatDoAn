"""
Script Xác Minh Chiều Vector Nhúng (Embedding Dimension Verification)
======================================================================
Giai đoạn Verification: Kiểm tra chiều của tất cả tensor trong pipeline SCR.

Chạy: python verify_embeddings.py
"""

import sys, logging
import torch
import torch.nn as nn

# Setup logging rõ ràng
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)]
)
logger = logging.getLogger(__name__)

# ─── Config test ──────────────────────────────────────────────────────────────
BATCH      = 4
NUM_USERS  = 100
NUM_ITEMS  = 200
NUM_SLOTS  = 48
SEQ_LEN    = 20       # Độ dài chuỗi dài hạn (rút gọn để test nhanh)
SESSION    = 8        # Độ dài phiên ngắn hạn
ITEM_DIM   = 128
USER_DIM   = 128
TIME_DIM   = 64
LSTM_H     = 128
IMG_DIM    = 256
NUM_HEADS  = 2


def section(title: str):
    print(f"\n{'─'*60}")
    print(f"  {title}")
    print('─'*60)


def check(name: str, tensor: torch.Tensor, expected: tuple):
    actual = tuple(tensor.shape)
    status = "✅" if actual == expected else "❌"
    print(f"  {status} {name:<40} | got={actual} | expected={expected}")
    assert actual == expected, f"DIMENSION ERROR: {name} → got {actual}, expected {expected}"


def verify_embeddings():
    section("1. Import các module")
    try:
        from models.long_term  import LongTermPreference, TimeLSTMCell, JaccardTimeWeighter, DistanceWeighter
        from models.short_term import ShortTermPreference, VanillaAttentionAggregator
        from models.multimodal import ImageFeatureExtractor
        from models.scr_model  import SCRMultimodalRecommender, SCRMultimodalRecommenderLegacy
        print("  ✅ Tất cả module import thành công")
    except ImportError as e:
        print(f"  ❌ Import lỗi: {e}")
        sys.exit(1)

    # ─── Tạo dummy tensors ────────────────────────────────────────────────
    section("2. Khởi tạo Dummy Tensors")
    user_ids        = torch.randint(0, NUM_USERS, (BATCH,))
    long_item_ids   = torch.randint(0, NUM_ITEMS, (BATCH, SEQ_LEN))
    long_time_ids   = torch.randint(0, NUM_SLOTS, (BATCH, SEQ_LEN))
    delta_ts        = torch.randn(BATCH, SEQ_LEN, 1)
    history_slots   = torch.randint(0, 2, (BATCH, SEQ_LEN, NUM_SLOTS)).float()
    current_slots   = torch.randint(0, 2, (BATCH, NUM_SLOTS)).float()
    history_coords  = torch.randn(BATCH, SEQ_LEN, 2)
    current_coord   = torch.randn(BATCH, 2)
    short_item_ids  = torch.randint(0, NUM_ITEMS, (BATCH, SESSION))
    padding_mask    = torch.zeros(BATCH, SESSION, dtype=torch.bool)
    image_tensors   = torch.randn(BATCH, 3, 224, 224)
    review_scores   = torch.randn(BATCH, 1)

    check("user_ids",       user_ids,       (BATCH,))
    check("long_item_ids",  long_item_ids,  (BATCH, SEQ_LEN))
    check("history_slots",  history_slots,  (BATCH, SEQ_LEN, NUM_SLOTS))
    check("current_slots",  current_slots,  (BATCH, NUM_SLOTS))
    check("history_coords", history_coords, (BATCH, SEQ_LEN, 2))
    check("image_tensors",  image_tensors,  (BATCH, 3, 224, 224))
    check("delta_ts",       delta_ts,       (BATCH, SEQ_LEN, 1))
    check("review_scores",  review_scores,  (BATCH, 1))

    # ─── Test JaccardTimeWeighter ─────────────────────────────────────────
    section("3. JaccardTimeWeighter — γ_{i,j}")
    jac = JaccardTimeWeighter(num_time_slots=NUM_SLOTS)
    gamma = jac(history_slots, current_slots)
    check("gamma (Jaccard)", gamma, (BATCH, SEQ_LEN, 1))
    print(f"  INFO: gamma min={gamma.min():.3f}, max={gamma.max():.3f} (phải trong [0,1])")
    assert gamma.min() >= 0.0 and gamma.max() <= 1.0, "Jaccard phải trong [0,1]!"

    # ─── Test DistanceWeighter ────────────────────────────────────────────
    section("4. DistanceWeighter — d_{lt,h} & w_h")
    dw = DistanceWeighter()
    weights = dw(history_coords, current_coord)
    check("dist_weights", weights, (BATCH, SEQ_LEN, 1))
    print(f"  INFO: dist_weights min={weights.min():.3f}, max={weights.max():.3f} (phải > 0)")
    assert weights.min() > 0, "Distance weights phải dương!"

    # ─── Test TimeLSTMCell ──────────────────────────────────────────────
    section("5. TimeLSTMCell — f_t, i_t, o_t gates")
    input_dim = ITEM_DIM + TIME_DIM
    cell  = TimeLSTMCell(input_dim=input_dim, hidden_dim=LSTM_H)
    x_t   = torch.randn(BATCH, input_dim)
    dt_t  = torch.randn(BATCH, 1)
    h_0   = torch.zeros(BATCH, LSTM_H)
    c_0   = torch.zeros(BATCH, LSTM_H)
    h1, c1 = cell(x_t, dt_t, h_0, c_0)
    check("h_t (LSTM hidden)", h1, (BATCH, LSTM_H))
    check("c_t (LSTM cell)",   c1, (BATCH, LSTM_H))

    # ─── Test LongTermPreference ──────────────────────────────────────────
    section("6. LongTermPreference → U_long")
    item_emb = nn.Embedding(NUM_ITEMS, ITEM_DIM)
    time_emb = nn.Embedding(NUM_SLOTS, TIME_DIM)
    e_long   = item_emb(long_item_ids)
    e_time_l = time_emb(long_time_ids)

    long_mod = LongTermPreference(ITEM_DIM, TIME_DIM, LSTM_H, NUM_SLOTS)
    u_long, gamma_out, dist_out = long_mod(
        e_items=e_long,
        e_times=e_time_l,
        delta_ts=delta_ts,
        history_slots=history_slots,
        current_slots=current_slots,
        history_coords=history_coords,
        current_coord=current_coord
    )
    check("U_long", u_long, (BATCH, LSTM_H))

    # ─── Test VanillaAttentionAggregator ──────────────────────────────────
    section("7. VanillaAttentionAggregator")
    H_dummy  = torch.randn(BATCH, SESSION, ITEM_DIM)
    query_d  = USER_DIM + ITEM_DIM
    query    = torch.randn(BATCH, query_d)
    va       = VanillaAttentionAggregator(hidden_dim=ITEM_DIM, query_dim=query_d)
    u_s, alpha = va(H_dummy, query)
    check("U_short (VanillaAttn)", u_s,    (BATCH, ITEM_DIM))
    check("alpha (attention)",     alpha,  (BATCH, SESSION))
    print(f"  INFO: alpha sum per sample ≈ {alpha.sum(dim=-1).mean():.4f} (phải ≈ 1.0)")

    # ─── Test ShortTermPreference ─────────────────────────────────────────
    section("8. ShortTermPreference → U_short")
    e_short  = item_emb(short_item_ids)
    u_user   = torch.randn(BATCH, USER_DIM)
    short_mod = ShortTermPreference(ITEM_DIM, USER_DIM, NUM_HEADS)
    u_short, attn_w = short_mod(e_short, u_user, padding_mask)
    check("U_short", u_short, (BATCH, ITEM_DIM))
    check("attn_weights", attn_w, (BATCH, SESSION, SESSION))

    # ─── Test ImageFeatureExtractor ───────────────────────────────────────
    section("9. ImageFeatureExtractor (DenseNet201) → e_img")
    img_mod = ImageFeatureExtractor(feature_dim=IMG_DIM)
    e_img   = img_mod(image_tensors)
    check("e_img", e_img, (BATCH, IMG_DIM))

    # ─── Test SCRMultimodalRecommender (Full Pipeline) ────────────────────
    section("10. SCRMultimodalRecommender — Full Forward Pass")
    model = SCRMultimodalRecommender(
        num_users=NUM_USERS, num_items=NUM_ITEMS,
        num_time_slots=NUM_SLOTS,
        item_dim=ITEM_DIM, user_dim=USER_DIM, time_dim=TIME_DIM,
        lstm_hidden=LSTM_H, image_dim=IMG_DIM,
        num_heads=NUM_HEADS, dropout=0.5,
    )
    model.eval()
    with torch.no_grad():
        log_probs, attn_w, fusion_w = model(
            user_ids       = user_ids,
            long_item_ids  = long_item_ids,
            long_time_ids  = long_time_ids,
            delta_ts       = delta_ts,
            history_slots  = history_slots,
            current_slots  = current_slots,
            history_coords = history_coords,
            current_coord  = current_coord,
            short_item_ids = short_item_ids,
            image_tensors  = image_tensors,
            review_scores  = review_scores,
            padding_mask   = padding_mask,
        )

    check("log_probs  (output)",    log_probs, (BATCH, NUM_ITEMS))
    check("attn_weights (short)", attn_w,    (BATCH, SESSION, SESSION))
    check("fusion_weights",       fusion_w,  (BATCH, 4, 1))

    # Kiểm tra NLL Loss
    section("11. NLL Loss Computation")
    targets  = torch.randint(0, NUM_ITEMS, (BATCH,))
    loss_fn  = nn.NLLLoss()
    loss     = loss_fn(log_probs, targets)
    print(f"  ✅ NLL Loss value = {loss.item():.4f} (phải là số hữu hạn dương)")
    assert torch.isfinite(loss), "Loss phải là số hữu hạn!"
    assert loss.item() > 0,      "NLL Loss phải dương!"

    # ─── Test Legacy Backward-Compat ─────────────────────────────────────
    section("12. Legacy API (SCRMultimodalRecommenderLegacy)")
    legacy = SCRMultimodalRecommenderLegacy(num_items=NUM_ITEMS, item_dim=ITEM_DIM,
                                             lstm_hidden=LSTM_H, image_dim=IMG_DIM)
    legacy.eval()
    with torch.no_grad():
        lp2, aw2 = legacy(
            long_item_ids,
            torch.rand(BATCH, SEQ_LEN, 1),
            torch.rand(BATCH, SEQ_LEN, 1),
            short_item_ids,
            image_tensors
        )
    check("legacy log_probs", lp2, (BATCH, NUM_ITEMS))

    # ─── Summary ─────────────────────────────────────────────────────────
    section("✅ XÁC MINH THÀNH CÔNG")
    concat_dim = ITEM_DIM + LSTM_H + IMG_DIM
    print(f"""
  Tổng kết chiều vector:
  ┌─────────────────────┬──────────────────────────────┐
  │ Thành phần          │ Shape                        │
  ├─────────────────────┼──────────────────────────────┤
  │ U_long              │ (B={BATCH}, {LSTM_H})        │
  │ U_short             │ (B={BATCH}, {ITEM_DIM})      │
  │ e_img               │ (B={BATCH}, {IMG_DIM})       │
  │ concat [U_s,U_l,e]  │ (B={BATCH}, {concat_dim})   │
  │ log_probs (output)  │ (B={BATCH}, {NUM_ITEMS})     │
  └─────────────────────┴──────────────────────────────┘
  Loss function: NLLLoss ✅
  Mô hình SCR-Multimodal hoạt động chính xác! 🎉
    """)


if __name__ == "__main__":
    verify_embeddings()
