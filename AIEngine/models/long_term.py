import torch
import torch.nn as nn
import torch.nn.functional as F

class TimeDistanceWeightedLSTM(nn.Module):
    def __init__(self, input_dim, hidden_dim, num_layers=1):
        super(TimeDistanceWeightedLSTM, self).__init__()
        self.hidden_dim = hidden_dim
        
        # LSTM để học chuỗi tương tác (Long-term)
        self.lstm = nn.LSTM(input_size=input_dim, hidden_size=hidden_dim, 
                            num_layers=num_layers, batch_first=True)
                            
        # Các layer để học trọng số Jaccard (Time) và khoảng cách Euclid (Distance)
        self.time_weight_layer = nn.Linear(1, 1) # Giả định nhận input là Jaccard similarity score
        self.dist_weight_layer = nn.Linear(1, 1) # Giả định nhận input là nghịch đảo khoảng cách

    def forward(self, x, time_scores, dist_scores):
        """
        x: (batch_size, seq_len, input_dim) - Đặc trưng chuỗi tương tác lịch sử
        time_scores: (batch_size, seq_len, 1) - Độ tương đồng thời gian Jaccard (gamma_{i,j})
        dist_scores: (batch_size, seq_len, 1) - Điểm khoảng cách (dựa trên Euclid distance d_{lt,h})
        """
        # Áp dụng trọng số thời gian và không gian
        # alpha_t = sigmoid(W * time_scores + b)
        alpha_t = torch.sigmoid(self.time_weight_layer(time_scores))
        
        # beta_d = sigmoid(W * dist_scores + b)
        beta_d = torch.sigmoid(self.dist_weight_layer(dist_scores))
        
        # Kết hợp trọng số vào input
        weighted_x = x * alpha_t * beta_d
        
        # Chạy qua LSTM
        output, (hn, cn) = self.lstm(weighted_x)
        
        # Lấy hidden state cuối cùng làm U_long
        # hn shape: (num_layers, batch_size, hidden_dim)
        u_long = hn[-1, :, :] 
        
        return u_long
