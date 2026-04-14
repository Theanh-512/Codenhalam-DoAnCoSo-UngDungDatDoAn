import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';

class AdminRouteScreen extends ConsumerStatefulWidget {
  const AdminRouteScreen({super.key});

  @override
  ConsumerState<AdminRouteScreen> createState() => _AdminRouteScreenState();
}

class _AdminRouteScreenState extends ConsumerState<AdminRouteScreen> {
  Map<String, dynamic>? _optimizationResult;
  bool _isLoading = false;

  Future<void> _fetchOptimizedRoute() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/orders/optimize-route'));
      
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _optimizationResult = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      } else {
        throw Exception("Lỗi lấy dữ liệu lộ trình");
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tối ưu hóa Lộ trình (TSP/Greedy)'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.route, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 16),
              const Text(
                'Công cụ tính toán lộ trình giao hàng tối ưu cho Shipper sử dụng Thuật toán Tham lam (Greedy Algorithm)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              
              if (_isLoading)
                const CircularProgressIndicator()
              else if (_optimizationResult != null)
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Trạng thái: ${_optimizationResult!['status']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                          Text('Thuật toán: ${_optimizationResult!['algorithmUsed']}', style: const TextStyle(fontStyle: FontStyle.italic)),
                          const Divider(height: 30),
                          
                          const Text('ĐIỂM XUẤT PHÁT:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('🏠 ${_optimizationResult!['startLocation']['address']} (Lat: ${_optimizationResult!['startLocation']['lat']})'),
                          const SizedBox(height: 16),
                          
                          const Text('LỘ TRÌNH ĐIỂM GIAO TIẾP THEO:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ...((_optimizationResult!['optimizedRoute'] as List<dynamic>).asMap().entries.map((entry) {
                            int idx = entry.key;
                            var point = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                children: [
                                  CircleAvatar(radius: 12, child: Text('${idx + 1}', style: const TextStyle(fontSize: 12))),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(point['address'], style: const TextStyle(fontSize: 16))),
                                ],
                              ),
                            );
                          }).toList()),
                        ],
                      ),
                    ),
                  ),
                ),
                
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isLoading ? null : _fetchOptimizedRoute,
                  child: const Text('Chạy thuật toán Tối ưu', style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
