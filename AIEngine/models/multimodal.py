import torch
import torch.nn as nn
import torchvision.models as models

class ImageFeatureExtractor(nn.Module):
    def __init__(self, feature_dim=256):
        super(ImageFeatureExtractor, self).__init__()
        # Load pre-trained DenseNet201
        densenet = models.densenet201(weights=models.DenseNet201_Weights.DEFAULT)
        
        # Extract features (remove the final classifier layer)
        self.features = densenet.features
        
        # Global Average Pooling
        self.pool = nn.AdaptiveAvgPool2d((1, 1))
        
        # Freeze convolution layers to save memory and compute
        for param in self.features.parameters():
            param.requires_grad = False
            
        # Add a fully connected layer to map to the desired feature dimension
        # DenseNet201 outputs 1920 channels. Project to 64 as per SCR paper.
        self.classifier = nn.Sequential(
            nn.Linear(1920, 512),
            nn.ReLU(),
            nn.Dropout(0.3),
            nn.Linear(512, feature_dim)
        )

    def forward(self, x):
        """
        x: Tensor ảnh đầu vào có kích thước (batch_size, 3, 224, 224)
        """
        # Trích xuất đặc trưng
        x = self.features(x)
        x = self.pool(x)
        x = torch.flatten(x, 1)
        
        # Chạy qua lớp classifier để giảm chiều
        e_img = self.classifier(x)
        return e_img
