import torch
import torch.nn as nn

class SelfAttentionAggregator(nn.Module):
    def __init__(self, embed_dim, num_heads=4, dropout=0.1):
        super(SelfAttentionAggregator, self).__init__()
        # Self-attention layer
        self.multihead_attn = nn.MultiheadAttention(embed_dim=embed_dim, 
                                                    num_heads=num_heads, 
                                                    dropout=dropout,
                                                    batch_first=True)
        # Layer Normalization
        self.layer_norm = nn.LayerNorm(embed_dim)
        
        # Feed forward network
        self.ffn = nn.Sequential(
            nn.Linear(embed_dim, embed_dim * 4),
            nn.ReLU(),
            nn.Dropout(dropout),
            nn.Linear(embed_dim * 4, embed_dim)
        )
        
        self.layer_norm2 = nn.LayerNorm(embed_dim)

    def forward(self, x):
        """
        x: (batch_size, session_len, embed_dim) - Đặc trưng các món ăn trong phiên ngắn hạn (24h)
        """
        # Áp dụng Self-Attention (Q=x, K=x, V=x)
        attn_output, attn_weights = self.multihead_attn(x, x, x)
        
        # Add & Norm
        x = self.layer_norm(x + attn_output)
        
        # Feed Forward
        ffn_output = self.ffn(x)
        
        # Add & Norm
        x = self.layer_norm2(x + ffn_output)
        
        # Aggregate (Pooling trung bình theo chiều session) để ra U_short cuối cùng
        u_short = torch.mean(x, dim=1)
        
        return u_short, attn_weights
