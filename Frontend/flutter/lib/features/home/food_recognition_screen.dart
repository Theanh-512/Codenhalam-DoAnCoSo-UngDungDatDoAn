import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data'; // Để xử lý ảnh trên Web
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class FoodRecognitionScreen extends StatefulWidget {
  const FoodRecognitionScreen({super.key});

  @override
  State<FoodRecognitionScreen> createState() => _FoodRecognitionScreenState();
}

class _FoodRecognitionScreenState extends State<FoodRecognitionScreen> {
  bool _isAnalyzing = false;
  String _resultFood = '';
  double _confidence = 0.0;
  Uint8List? _imageBytes; // Lưu dữ liệu ảnh (Dùng được cho cả Mobile và Web)

  // Hàm chọn ảnh và gửi lên Server AI
  Future<void> _pickAndRecognizeImage() async {
    final imagePicker = ImagePicker();
    final XFile? pickedFile = await imagePicker.pickImage(
      source: ImageSource.camera, // Mặc định mở camera, có thể đổi thành gallery
      maxWidth: 800, // Tối ưu kích thước trước khi gửi
      maxHeight: 800,
    );

    if (pickedFile == null) return;

    final bytes = await pickedFile.readAsBytes();

    setState(() {
      _isAnalyzing = true;
      _resultFood = '';
      _imageBytes = bytes;
    });

    try {
      // 1. Chuẩn bị Request (Sử dụng IP phù hợp cho môi trường)
      // Lưu ý: Trên Chrome, localhost là 127.0.0.1. Trên Android Emulator là 10.0.2.2.
      final baseUrl = kIsWeb ? 'http://127.0.0.1:8000' : 'http://10.0.2.2:8000';
      final uri = Uri.parse('$baseUrl/api/ai/recognize-food');
      var request = http.MultipartRequest('POST', uri);
      
      // 2. Đính kèm file ảnh bằng Bytes
      request.files.add(http.MultipartFile.fromBytes(
        'file', 
        bytes, 
        filename: pickedFile.name
      ));

      // 3. Gửi và nhận phản hồi
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _resultFood = data['food_name'];
          _confidence = data['confidence'];
          _isAnalyzing = false;
        });
      } else {
        throw Exception('Server trả về lỗi: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi kết nối AI Service: $e'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Food Recognition'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hiển thị ảnh đã chụp hoặc icon camera
              Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.deepOrange.withOpacity(0.5), width: 2),
                ),
                child: _isAnalyzing 
                  ? const Center(child: CircularProgressIndicator(color: Colors.deepOrange))
                  : _imageBytes != null 
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_enhance_rounded, size: 80, color: Colors.grey),
                          SizedBox(height: 10),
                          Text('Chưa có ảnh nào được chọn', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
              ),
              const SizedBox(height: 30),
              
              if (_isAnalyzing)
                const Column(
                  children: [
                    Text('AI đang phân tích bức ảnh của bạn...', style: TextStyle(fontWeight: FontWeight.w500)),
                    SizedBox(height: 10),
                    LinearProgressIndicator(color: Colors.deepOrange),
                  ],
                )
              else if (_resultFood.isNotEmpty)
                Column(
                  children: [
                    const Text('AI nhận diện đây là món:', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 5),
                    Text(_resultFood, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Độ tin cậy: ${(_confidence * 100).toStringAsFixed(1)}%', 
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.search, color: Colors.white),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: () {
                        // Trở về và thực hiện tìm kiếm món ăn này
                        Navigator.of(context).pop(_resultFood);
                      },
                      label: const Text('Tìm quán bán món này ngay', style: TextStyle(color: Colors.white, fontSize: 16)),
                    )
                  ],
                ),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Chọn ảnh từ thư viện', style: TextStyle(fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.deepOrange,
                    side: const BorderSide(color: Colors.deepOrange),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _isAnalyzing ? null : _pickAndRecognizeImage,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Chụp ảnh mới', style: TextStyle(fontSize: 16, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                  ),
                  onPressed: _isAnalyzing ? null : _pickAndRecognizeImage,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
