import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter_food_app/common/globs.dart';

/// Màn AI Camera: chụp/chọn ảnh → gửi sang FastAPI service (DenseNet201) → trả tên món.
/// Ấn "Tìm quán bán món này" sẽ pop kèm chuỗi món để search bar mở SearchView.
class FoodRecognitionScreen extends StatefulWidget {
  const FoodRecognitionScreen({super.key});

  @override
  State<FoodRecognitionScreen> createState() => _FoodRecognitionScreenState();
}

class _FoodRecognitionScreenState extends State<FoodRecognitionScreen> {
  bool _isAnalyzing = false;
  String _resultFood = '';
  double _confidence = 0.0;
  Uint8List? _imageBytes;

  Future<void> _pickAndRecognize({required ImageSource source}) async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _isAnalyzing = true;
      _resultFood = '';
      _confidence = 0.0;
      _imageBytes = bytes;
    });

    try {
      final uri = Uri.parse(Globs.recognizeFoodUrl);
      final request = http.MultipartRequest('POST', uri)
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: picked.name,
        ));
      final streamed = await request.send().timeout(
            const Duration(seconds: 30),
          );
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          _resultFood = (data['food_name'] ?? '').toString();
          _confidence = (data['confidence'] is num)
              ? (data['confidence'] as num).toDouble()
              : 0.0;
          _isAnalyzing = false;
        });
      } else {
        throw Exception('AI Service trả về ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không gọi được AI Service: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.background,
      appBar: AppBar(
        title: const Text(
          'AI nhận diện món ăn',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: TColor.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 280,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: TColor.primary.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: _isAnalyzing
                  ? Center(
                      child: CircularProgressIndicator(color: TColor.primary),
                    )
                  : _imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_enhance_rounded,
                              size: 80,
                              color: TColor.placeholder,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Chụp hoặc chọn ảnh để AI đoán món',
                              style: TextStyle(color: TColor.secondaryText),
                            ),
                          ],
                        ),
            ),
            const SizedBox(height: 24),
            if (_isAnalyzing)
              Column(
                children: [
                  Text(
                    'AI đang phân tích...',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: TColor.primaryText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(color: TColor.primary),
                ],
              )
            else if (_resultFood.isNotEmpty)
              Column(
                children: [
                  Text(
                    'AI nhận diện đây là',
                    style: TextStyle(fontSize: 14, color: TColor.secondaryText),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _resultFood,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: TColor.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Độ tin cậy: ${(_confidence * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TColor.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.search),
                    label: const Text(
                      'Tìm quán bán món này ngay',
                      style: TextStyle(fontSize: 16),
                    ),
                    onPressed: () => Navigator.of(context).pop(_resultFood),
                  ),
                ],
              ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              icon: const Icon(Icons.photo_library),
              label: const Text(
                'Chọn ảnh từ thư viện',
                style: TextStyle(fontSize: 16),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: TColor.primary,
                side: BorderSide(color: TColor.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _isAnalyzing
                  ? null
                  : () => _pickAndRecognize(source: ImageSource.gallery),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text(
                'Chụp ảnh mới',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: TColor.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _isAnalyzing
                  ? null
                  : () => _pickAndRecognize(source: ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }
}
