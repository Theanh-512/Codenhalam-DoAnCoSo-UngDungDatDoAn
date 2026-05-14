import 'package:flutter/material.dart';
import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter_food_app/view/shipper/shipper_delivery_view.dart';

class ShipperHomeView extends StatefulWidget {
  const ShipperHomeView({super.key});

  @override
  State<ShipperHomeView> createState() => _ShipperHomeViewState();
}

class _ShipperHomeViewState extends State<ShipperHomeView> {
  bool _isOnline = false;
  
  final List<Map<String, dynamic>> _mockOrders = [
    {
      "id": "ORD001",
      "customerName": "Nguyễn Văn A",
      "address": "123 Lê Lợi, Quận 1",
      "restaurant": "Phở Thìn Lò Đúc",
      "price": "120.000đ",
      "distance": "2.5 km"
    },
    {
      "id": "ORD002",
      "customerName": "Trần Thị B",
      "address": "456 Nguyễn Huệ, Quận 1",
      "restaurant": "Pizza 4P's",
      "price": "350.000đ",
      "distance": "1.2 km"
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      appBar: AppBar(
        title: const Text("Shipper Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: TColor.primaryText,
        elevation: 0.5,
        actions: [
          Switch(
            value: _isOnline,
            onChanged: (val) => setState(() => _isOnline = val),
            activeColor: Colors.green,
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 15),
              child: Text(
                _isOnline ? "Trực tuyến" : "Ngoại tuyến",
                style: TextStyle(color: _isOnline ? Colors.green : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildStats(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                children: [
                  Text("Đơn hàng khả dụng", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Spacer(),
                  Icon(Icons.refresh, size: 20, color: Colors.grey),
                ],
              ),
            ),
            if (!_isOnline)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(50),
                  child: Column(
                    children: [
                      Icon(Icons.location_off_rounded, size: 80, color: Colors.grey),
                      SizedBox(height: 15),
                      Text("Hãy bật Trực tuyến để nhận đơn!", style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _mockOrders.length,
                itemBuilder: (context, index) {
                  return _buildOrderCard(_mockOrders[index]);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TColor.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: TColor.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(label: "Đơn hàng", value: "12"),
          _StatItem(label: "Thu nhập", value: "450k"),
          _StatItem(label: "Đánh giá", value: "4.9⭐"),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: TColor.textfield, borderRadius: BorderRadius.circular(5)),
                child: Text(order['id'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const Spacer(),
              Text(order['distance'], style: TextStyle(color: TColor.primary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          _RouteInfo(restaurant: order['restaurant'], address: order['address']),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(order['price'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ShipperDeliveryView(order: order)));
                },
                style: ElevatedButton.styleFrom(backgroundColor: TColor.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text("Nhận đơn", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

class _RouteInfo extends StatelessWidget {
  final String restaurant;
  final String address;
  const _RouteInfo({required this.restaurant, required this.address});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.storefront, color: Colors.red, size: 20),
            const SizedBox(width: 10),
            Text(restaurant, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        Container(
          height: 20,
          margin: const EdgeInsets.only(left: 10),
          decoration: const BoxDecoration(border: Border(left: BorderSide(color: Colors.grey, style: BorderStyle.solid))),
        ),
        Row(
          children: [
            const Icon(Icons.location_on, color: Colors.green, size: 20),
            const SizedBox(width: 10),
            Text(address),
          ],
        ),
      ],
    );
  }
}
