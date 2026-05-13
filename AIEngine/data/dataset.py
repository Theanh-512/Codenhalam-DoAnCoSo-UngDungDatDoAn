"""
Dataset & DataLoader cho SCR-Multimodal Recommender
====================================================
SessionDataset: Tổ chức tương tác theo phiên dài hạn và ngắn hạn.
"""

import os, logging, datetime, random, time
from typing import List, Optional
import numpy as np
import torch
from torch.utils.data import Dataset, DataLoader
from PIL import Image
import torchvision.transforms as T

logger = logging.getLogger(__name__)

IMAGE_TRANSFORM = T.Compose([
    T.Resize((224, 224)),
    T.ToTensor(),
    T.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
])


def encode_time_slot(hour: int, is_weekend: bool) -> int:
    """(hour, weekend) → slot [0,47]: weekday=0-23, weekend=24-47"""
    return (24 if is_weekend else 0) + (hour % 24)


def time_slot_to_binary(slots: List[int], num_slots: int = 48) -> np.ndarray:
    """Chuyển list slot IDs → binary vector 48-chiều cho Jaccard similarity."""
    v = np.zeros(num_slots, dtype=np.float32)
    for s in slots:
        if 0 <= s < num_slots:
            v[s] = 1.0
    return v


class SessionDataset(Dataset):
    """
    Mỗi sample trả về dict với keys:
      user_id, long_item_ids, long_time_ids, history_slots, current_slots,
      history_coords, current_coord, short_item_ids, padding_mask,
      image_tensor, target_item_id
    """

    def __init__(self, records: List[dict], num_items=500, num_slots=48,
                 seq_len=50, session_len=10, image_dir=None, use_dummy_images=True):
        self.num_items   = num_items
        self.num_slots   = num_slots
        self.seq_len     = seq_len
        self.session_len = session_len
        self.image_dir   = image_dir
        self.use_dummy   = use_dummy_images

        # Group và sort theo timestamp
        self.user_history = {}
        for r in records:
            uid = r['user_id']
            self.user_history.setdefault(uid, []).append(r)
        for uid in self.user_history:
            self.user_history[uid].sort(key=lambda x: x['timestamp'])

        self.samples = []
        for uid, inters in self.user_history.items():
            for idx in range(session_len + 2, len(inters)):
                self.samples.append((uid, idx))

        logger.info(f"[SessionDataset] {len(records)} records → {len(self.samples)} samples")

    def __len__(self):
        return len(self.samples)

    def _pad_ids(self, inters, length, key='item_id'):
        ids = [r[key] for r in inters]
        if len(ids) < length:
            ids = [0] * (length - len(ids)) + ids
        return ids[-length:]

    def _pad_slots(self, inters, length):
        vecs = [time_slot_to_binary([r.get('time_slot', 0)], self.num_slots) for r in inters]
        if len(vecs) < length:
            vecs = [np.zeros(self.num_slots, dtype=np.float32)] * (length - len(vecs)) + vecs
        return np.stack(vecs[-length:])

    def _pad_coords(self, inters, length):
        cs = [[r.get('lat', 0.0), r.get('lon', 0.0)] for r in inters]
        if len(cs) < length:
            cs = [[0.0, 0.0]] * (length - len(cs)) + cs
        return np.array(cs[-length:], dtype=np.float32)

    def _pad_deltas(self, inters, length):
        deltas = []
        for i in range(len(inters)):
            if i == 0:
                deltas.append([0.0])
            else:
                try:
                    t1 = float(inters[i]['timestamp'])
                    t0 = float(inters[i-1]['timestamp'])
                    # Khoảng cách tính bằng giờ
                    dt = max(0.0, (t1 - t0) / 3600.0)
                    deltas.append([dt])
                except Exception:
                    deltas.append([0.0])
        if len(deltas) < length:
            deltas = [[0.0]] * (length - len(deltas)) + deltas
        return np.array(deltas[-length:], dtype=np.float32)

    def __getitem__(self, idx):
        uid, target_idx = self.samples[idx]
        history = self.user_history[uid]
        target  = history[target_idx]

        sess_start  = max(0, target_idx - self.session_len)
        sess_inter  = history[sess_start:target_idx]
        long_end    = sess_start
        long_start  = max(0, long_end - self.seq_len)
        long_inter  = history[long_start:long_end]

        long_item_ids  = torch.tensor(self._pad_ids(long_inter, self.seq_len, 'item_id'), dtype=torch.long)
        long_time_ids  = torch.tensor(self._pad_ids(long_inter, self.seq_len, 'time_slot'), dtype=torch.long)
        history_slots  = torch.tensor(self._pad_slots(long_inter, self.seq_len), dtype=torch.float32)
        history_coords = torch.tensor(self._pad_coords(long_inter, self.seq_len), dtype=torch.float32)
        delta_ts       = torch.tensor(self._pad_deltas(long_inter, self.seq_len), dtype=torch.float32)

        current_slots  = torch.tensor(
            time_slot_to_binary([target.get('time_slot', 0)], self.num_slots), dtype=torch.float32)
        current_coord  = torch.tensor(
            [float(target.get('lat', 0.0)), float(target.get('lon', 0.0))], dtype=torch.float32)

        short_item_ids = torch.tensor(self._pad_ids(sess_inter, self.session_len, 'item_id'), dtype=torch.long)

        actual_len   = min(len(sess_inter), self.session_len)
        padding_mask = torch.tensor([True] * (self.session_len - actual_len) + [False] * actual_len, dtype=torch.bool)

        if self.use_dummy:
            image_tensor = torch.randn(3, 224, 224)
        else:
            try:
                img_path = target.get('image_path', '')
                if self.image_dir:
                    img_path = os.path.join(self.image_dir, img_path)
                img = Image.open(img_path).convert('RGB')
                image_tensor = IMAGE_TRANSFORM(img)
            except Exception as e:
                logger.warning(f"Error loading image {img_path}: {e}")
                image_tensor = torch.randn(3, 224, 224)

        return {
            'user_id':        torch.tensor(uid, dtype=torch.long),
            'long_item_ids':  long_item_ids,
            'long_time_ids':  long_time_ids,
            'delta_ts':       delta_ts,
            'history_slots':  history_slots,
            'current_slots':  current_slots,
            'history_coords': history_coords,
            'current_coord':  current_coord,
            'short_item_ids': short_item_ids,
            'padding_mask':   padding_mask,
            'image_tensor':   image_tensor,
            'target_item_id': torch.tensor(int(target['item_id']), dtype=torch.long),
        }


def create_dummy_records(num_users=20, num_items=100, interactions_per_user=80) -> List[dict]:
    """Tạo dữ liệu giả lập để test pipeline."""
    records = []
    base_ts = int(time.time()) - 3600 * 24 * 30
    for uid in range(num_users):
        for i in range(interactions_per_user):
            ts = base_ts + i * 3600 + random.randint(0, 600)
            dt = datetime.datetime.fromtimestamp(ts)
            records.append({
                'user_id':   uid,
                'item_id':   random.randint(0, num_items - 1),
                'timestamp': ts,
                'lat':       10.0 + random.uniform(-0.5, 0.5),
                'lon':       106.0 + random.uniform(-0.5, 0.5),
                'time_slot': encode_time_slot(dt.hour, dt.weekday() >= 5),
                'is_weekend': dt.weekday() >= 5,
                'image_path': 'placeholder.jpg',
            })
    return records


def build_dataloaders(records, num_items=500, num_slots=48,
                      seq_len=50, session_len=10, batch_size=32,
                      train_ratio=0.8, val_ratio=0.1):
    dataset = SessionDataset(records, num_items=num_items, num_slots=num_slots,
                              seq_len=seq_len, session_len=session_len)
    n = len(dataset)
    n_train = int(n * train_ratio)
    n_val   = int(n * val_ratio)
    n_test  = n - n_train - n_val
    train_ds, val_ds, test_ds = torch.utils.data.random_split(dataset, [n_train, n_val, n_test])
    make = lambda ds, sh: DataLoader(ds, batch_size=batch_size, shuffle=sh, num_workers=0)
    logger.info(f"[DataLoaders] Train={n_train} Val={n_val} Test={n_test}")
    return make(train_ds, True), make(val_ds, False), make(test_ds, False)
