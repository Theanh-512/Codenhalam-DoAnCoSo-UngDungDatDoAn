import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

class FoodRecognitionScreen extends StatefulWidget {
  const FoodRecognitionScreen({super.key});

  @override
  State<FoodRecognitionScreen> createState() => _FoodRecognitionScreenState();
}

class _FoodRecognitionScreenState extends State<FoodRecognitionScreen> {
  bool _isAnalyzing = false;
  String _resultFood = '';
  double _confidence = 0.0;

  Future<void> _simulateUploadAndRecognize() async {
    setState(() {
      _isAnalyzing = true;
      _resultFood = '';
    });

    try {
      // THEO BÁO CÁO TUẦN 8: XỬ LÝ ẢNH QUÁ LỚN TỪ THIẾT BỊ DI ĐỘNG
      // 1. Chụp ảnh / Chọn ảnh từ thư viện
      // final ImagePicker picker = ImagePicker();
      // final XFile? image = await picker.pickImage(source: ImageSource.camera);
      // if (image == null) return;
      
      // 2. Nén và Resize ảnh ngay tại Client để tối ưu băng thông trước khi gửi lên API Computer Vision
      // final compressedFile = await FlutterImageCompress.compressAndGetFile(
      //   image.path, 
      //   outPath,
      //   minWidth: 800,
      //   minHeight: 800,
      //   quality: 85, // Giảm chất lượng xuống 85% để nhẹ nhưng vẫn đủ để AI nhận diện
      // );

      // 3. Gửi lên Server
      await Future.delayed(const Duration(seconds: 2)); // Giả lập độ trễ Camera & Upload (Transfer Learning xử lý)
      
      // Gọi Python Backend POST /api/ai/recognize-food
      // Note: Ở mode dev, mock dữ liệu để tránh crash nếu Python chưa chạy
      final randomFoods = ["Phở Bò", "Bún Chả", "Pizza", "Cơm Tấm", "Mì Ý"];
      final random = Random();
      
      setState(() {
        _resultFood = randomFoods[random.nextInt(randomFoods.length)];
        _confidence = 0.85 + random.nextDouble() * 0.14; // random từ 85 - 99%
        _isAnalyzing = false;
      });

    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhận diện món ăn (AI Camera)'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.deepOrange, width: 2, style: BorderStyle.solid),
                ),
                child: _isAnalyzing 
                  ? const Center(child: CircularProgressIndicator(color: Colors.deepOrange))
                  : const Icon(Icons.camera_alt, size: 100, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              
              if (_isAnalyzing)
                const Text('Hệ thống Computer Vision đang phân tích...', style: TextStyle(fontStyle: FontStyle.italic))
              else if (_resultFood.isNotEmpty)
                Column(
                  children: [
                    const Text('Kết quả nhận diện:', style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 8),
                    Text(_resultFood, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                    Text('Độ chính xác (EfficientNetB4): ${(_confidence * 100).toStringAsFixed(1)}%', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                      onPressed: () {
                        // Routing về Home kèm query tìm kiếm (MOCK)
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sẽ tìm kiếm: $_resultFood')));
                      },
                      child: const Text('Tìm quán bán món này', style: TextStyle(color: Colors.white)),
                    )
                  ],
                )
              else
                const Text('Chụp một bức ảnh món ăn để AI nhận diện', style: TextStyle(fontSize: 16)),
              
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.camera),
                  label: const Text('Chụp / Tải ảnh lên', style: TextStyle(fontSize: 18, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isAnalyzing ? null : _simulateUploadAndRecognize,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
