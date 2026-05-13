import torch
import torch.nn as nn

from .long_term import TimeDistanceWeightedLSTM
from .short_term import SelfAttentionAggregator
from .multimodal import ImageFeatureExtractor

class SCRMultimodalRecommender(nn.Module):
    def __init__(self, num_items, item_dim=128, lstm_hidden=128, image_dim=256):
        super(SCRMultimodalRecommender, self).__init__()
        
        # Embedding cho item id
        self.item_embedding = nn.Embedding(num_items, item_dim)
        
        # Modules
        self.long_term_module = TimeDistanceWeightedLSTM(input_dim=item_dim, hidden_dim=lstm_hidden)
        self.short_term_module = SelfAttentionAggregator(embed_dim=item_dim, num_heads=4)
        self.image_module = ImageFeatureExtractor(feature_dim=image_dim)
        
        # Lớp phân loại cuối cùng (Softmax prediction)
        # Kích thước = U_short + U_long + e_img
        concat_dim = item_dim + lstm_hidden + image_dim
        
        self.fc = nn.Sequential(
            nn.Linear(concat_dim, 512),
            nn.ReLU(),
            nn.Dropout(0.2),
            nn.Linear(512, num_items) # Dự đoán món ăn tiếp theo trong tổng số num_items
        )

    def forward(self, long_items, time_scores, dist_scores, short_items, image_tensors):
        """
        long_items: IDs các món ăn lịch sử dài hạn (batch_size, seq_len)
        short_items: IDs các món ăn trong phiên 24h (batch_size, session_len)
        image_tensors: Ảnh đầu vào (batch_size, 3, 224, 224)
        """
        # 1. Trích xuất U_long
        e_long = self.item_embedding(long_items)
        u_long = self.long_term_module(e_long, time_scores, dist_scores)
        
        # 2. Trích xuất U_short
        e_short = self.item_embedding(short_items)
        u_short, attn_weights = self.short_term_module(e_short)
        
        # 3. Trích xuất Image Feature (e_img)
        e_img = self.image_module(image_tensors)
        
        # 4. Fusion (Concatenation)
        final_embedding = torch.cat([u_short, u_long, e_img], dim=-1)
        
        # 5. Dự đoán
        logits = self.fc(final_embedding)
        
        # Trả về Log-Softmax để dùng hàm mất mát NLLLoss
        log_probs = nn.functional.log_softmax(logits, dim=-1)
        
        return log_probs, attn_weights
