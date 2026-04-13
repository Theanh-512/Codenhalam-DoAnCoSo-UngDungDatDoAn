import 'package:flutter/material.dart';
import '../../shared/widgets/category_item.dart';
import '../../shared/widgets/restaurant_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Giao đến',
              style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.deepOrange),
                const SizedBox(width: 4),
                Text(
                  'Đại học Bách Khoa...',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[900]),
                ),
                const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.deepOrange),
              ],
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                  child: const Text('2', style: TextStyle(color: Colors.white, fontSize: 8), textAlign: TextAlign.center),
                ),
              )
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm món ngon...',
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: Colors.grey),
                  ),
                ),
              ),
            ),

            // AI Recommendation Banner
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.orange[700]!, Colors.deepOrange[800]!],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.deepOrange.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gợi ý từ AI 🧠',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Món ngon dành riêng cho bạn lúc 12:00 này!',
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.deepOrange,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('Xem ngay', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 60),
                ],
              ),
            ),
            
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                'Danh mục',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            
            SizedBox(
              height: 110,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: const [
                  CategoryItem(name: 'Cơm', icon: Icons.rice_bowl),
                  CategoryItem(name: 'Bún/Phở', icon: Icons.soup_kitchen),
                  CategoryItem(name: 'Pizza', icon: Icons.local_pizza),
                  CategoryItem(name: 'Trà sữa', icon: Icons.local_drink),
                  CategoryItem(name: 'Ăn vặt', icon: Icons.fastfood),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quán ngon gần bạn',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Xem tất cả',
                    style: TextStyle(fontSize: 14, color: Colors.deepOrange, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            // Mock Restaurant List
            const RestaurantCard(
              name: 'Phở Thìn Lò Đúc',
              info: '4.8 ⭐ (1.2km) • 30-40 phút',
              imageUrl: 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=500',
            ),
            const RestaurantCard(
              name: 'Pizza 4P\'s',
              info: '4.9 ⭐ (2.5km) • 20-30 phút',
              imageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=500',
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
