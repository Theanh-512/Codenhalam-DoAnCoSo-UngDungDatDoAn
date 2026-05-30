"""
Google Colab Training Pipeline for Upgraded Food Vision Model
============================================================
Hướng dẫn chạy trên Google Colab:
1. Mở một notebook Colab mới và kích hoạt Tăng tốc phần cứng GPU (Runtime -> Change runtime type -> T4 GPU).
2. Tải các file dataset (ví dụ: archive.zip, archive (1).zip) lên Colab.
3. Sao chép và chạy đoạn code Python dưới đây trong Colab để train model ConvNeXt-Tiny hoặc EfficientNetV2-M mới.
4. Tải file model kết quả 'upgraded_vision_model.pth' về máy và đặt vào thư mục 'Backend/AIService' của dự án.
"""

import os
import zipfile
import torch
import torch.nn as nn
import torch.optim as optim
from torch.optim import lr_scheduler
from torchvision import datasets, models, transforms
from torch.utils.data import DataLoader
import time
import copy
try:
    import timm
except ImportError:
    timm = None

# ==========================================
# Cấu hình Kiến Trúc và Dataset
# ==========================================
MODEL_ARCH = "convnext_v2"  # Tùy chọn: "convnext_v2", "convnext_tiny", "efficientnet_v2_m"
BATCH_SIZE = 32
EPOCHS = 15
LEARNING_RATE = 1e-4

# Giải nén các file dataset trong Colab
def extract_datasets():
    zips = [f for f in os.listdir('.') if f.endswith('.zip')]
    if not zips:
        print("⚠️ Không tìm thấy file .zip nào! Hãy tải các tập tin nén ảnh thức ăn lên Colab.")
        return False
        
    os.makedirs('dataset', exist_ok=True)
    for z in zips:
        print(f"📦 Đang giải nén {z}...")
        try:
            with zipfile.ZipFile(z, 'r') as zip_ref:
                zip_ref.extractall('dataset')
            print(f"✅ Giải nén xong: {z}")
        except Exception as e:
            print(f"❌ Lỗi khi giải nén {z}: {e}")
    return True

def train_model():
    if not extract_datasets():
        return

    # Định nghĩa thư mục chứa dữ liệu
    # Thường dataset sau giải nén sẽ có cấu trúc: dataset/train/class_name/img.jpg
    data_dir = 'dataset'
    
    # Tìm thư mục train hoặc ảnh thực tế
    train_dir = os.path.join(data_dir, 'train') if os.path.exists(os.path.join(data_dir, 'train')) else data_dir
    val_dir = os.path.join(data_dir, 'val') if os.path.exists(os.path.join(data_dir, 'val')) else None

    # Biến đổi ảnh nâng cao (Data Augmentation)
    data_transforms = {
        'train': transforms.Compose([
            transforms.RandomResizedCrop(224),
            transforms.RandomHorizontalFlip(),
            transforms.RandomRotation(15),
            transforms.ColorJitter(brightness=0.2, contrast=0.2),
            transforms.ToTensor(),
            transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
        ]),
        'val': transforms.Compose([
            transforms.Resize(256),
            transforms.CenterCrop(224),
            transforms.ToTensor(),
            transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
        ]),
    }

    # Load dữ liệu
    print("📂 Đang nạp dataset...")
    train_dataset = datasets.ImageFolder(train_dir, data_transforms['train'])
    class_names = train_dataset.classes
    num_classes = len(class_names)
    print(f"📚 Số lượng Class (Món ăn): {num_classes}")
    print(f"🏷️ Danh sách class: {class_names}")

    if val_dir:
        val_dataset = datasets.ImageFolder(val_dir, data_transforms['val'])
    else:
        # Nếu không có thư mục validation riêng, chia ngẫu nhiên 80/20 từ train dataset
        train_size = int(0.8 * len(train_dataset))
        val_size = len(train_dataset) - train_size
        train_dataset, val_dataset = torch.utils.data.random_split(train_dataset, [train_size, val_size])
        val_dataset.dataset.transform = data_transforms['val']

    image_datasets = {'train': train_dataset, 'val': val_dataset}
    dataloaders = {x: DataLoader(image_datasets[x], batch_size=BATCH_SIZE, shuffle=True, num_workers=2) for x in ['train', 'val']}
    dataset_sizes = {x: len(image_datasets[x]) for x in ['train', 'val']}

    device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")
    print(f"🤖 Đang sử dụng Device: {device}")

    # ==========================================
    # Khởi tạo mô hình kiến trúc mới
    # ==========================================
    print(f"🚀 Đang khởi tạo mô hình mới: {MODEL_ARCH.upper()}")
    if MODEL_ARCH == "convnext_v2":
        if timm is None:
            raise ImportError("Vui lòng cài đặt thư viện timm trên Colab bằng cách chạy: !pip install timm")
        # Khởi tạo ConvNeXt V2 phiên bản Tiny
        model = timm.create_model('convnextv2_tiny', pretrained=True, num_classes=num_classes)
    elif MODEL_ARCH == "convnext_tiny":
        model = models.convnext_tiny(pretrained=True)
        # Thay thế classifier cuối của ConvNeXt Tiny V1
        num_ftrs = model.classifier[2].in_features
        model.classifier[2] = nn.Linear(num_ftrs, num_classes)
    elif MODEL_ARCH == "efficientnet_v2_m":
        model = models.efficientnet_v2_m(pretrained=True)
        # Thay thế classifier cuối của EfficientNet
        num_ftrs = model.classifier[1].in_features
        model.classifier[1] = nn.Linear(num_ftrs, num_classes)
    else:
        model = models.efficientnet_v2_s(pretrained=True)
        num_ftrs = model.classifier[1].in_features
        model.classifier[1] = nn.Linear(num_ftrs, num_classes)

    model = model.to(device)

    # Định nghĩa Loss function và Optimizer
    criterion = nn.CrossEntropyLoss()
    optimizer = optim.AdamW(model.parameters(), lr=LEARNING_RATE, weight_decay=1e-2)
    scheduler = lr_scheduler.CosineAnnealingLR(optimizer, T_max=EPOCHS)

    # Vòng lặp huấn luyện chính
    since = time.time()
    best_model_wts = copy.deepcopy(model.state_dict())
    best_acc = 0.0

    for epoch in range(EPOCHS):
        print(f'\n--- Epoch {epoch + 1}/{EPOCHS} ---')
        print('-' * 10)

        for phase in ['train', 'val']:
            if phase == 'train':
                model.train()
            else:
                model.eval()

            running_loss = 0.0
            running_corrects = 0

            for inputs, labels in dataloaders[phase]:
                inputs = inputs.to(device)
                labels = labels.to(device)

                optimizer.zero_grad()

                with torch.set_grad_enabled(phase == 'train'):
                    outputs = model(inputs)
                    _, preds = torch.max(outputs, 1)
                    loss = criterion(outputs, labels)

                    if phase == 'train':
                        loss.backward()
                        optimizer.step()

                running_loss += loss.item() * inputs.size(0)
                running_corrects += torch.sum(preds == labels.data)

            if phase == 'train':
                scheduler.step()

            epoch_loss = running_loss / dataset_sizes[phase]
            epoch_acc = running_corrects.double() / dataset_sizes[phase]

            print(f'{phase.capitalize()} Loss: {epoch_loss:.4f} Acc: {epoch_acc:.4f}')

            if phase == 'val' and epoch_acc > best_acc:
                best_acc = epoch_acc
                best_model_wts = copy.deepcopy(model.state_dict())

    time_elapsed = time.time() - since
    print(f'\n🎉 Hoàn thành huấn luyện trong {time_elapsed // 60:.0f}m {time_elapsed % 60:.0f}s')
    print(f'🏆 Độ chính xác Validation tốt nhất: {best_acc:4f}')

    # Nạp lại bộ trọng số tối ưu nhất
    model.load_state_dict(best_model_wts)

    # Lưu checkpoint chứa đầy đủ metadata (Cực kỳ quan trọng để API tự động nhận diện)
    checkpoint = {
        'model_state_dict': model.state_dict(),
        'classes': class_names,
        'arch': MODEL_ARCH  # Lưu tên kiến trúc vào checkpoint để tự động nhận dạng
    }
    
    save_filename = 'upgraded_vision_model.pth'
    torch.save(checkpoint, save_filename)
    print(f"💾 Đã lưu file checkpoint chất lượng cao tại: {save_filename}")
    print("👉 Hãy tải file này về máy tính của bạn và đổi tên thành 'archive_1_model.pth' (hoặc cập nhật biến model_filename trong file main.py thành 'upgraded_vision_model.pth')")

if __name__ == "__main__":
    train_model()
