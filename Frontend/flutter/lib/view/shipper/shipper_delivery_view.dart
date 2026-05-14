import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_food_app/common/color_extension.dart';

class ShipperDeliveryView extends StatefulWidget {
  final Map<String, dynamic> order;

  const ShipperDeliveryView({super.key, required this.order});

  @override
  State<ShipperDeliveryView> createState() => _ShipperDeliveryViewState();
}

class _ShipperDeliveryViewState extends State<ShipperDeliveryView> {
  final MapController _mapController = MapController();
  
  // Mock positions
  final LatLng _shipperPos = const LatLng(10.7769, 106.7009);
  final LatLng _restaurantPos = const LatLng(10.7820, 106.7050);
  final LatLng _customerPos = const LatLng(10.7950, 106.7150);

  int _statusIndex = 0; // 0: Chờ lấy hàng, 1: Đang giao, 2: Đã đến nơi
  final List<String> _statuses = ["Chờ lấy hàng", "Đang giao hàng", "Đã đến nơi"];

  void _updateStatus() {
    if (_statusIndex < _statuses.length - 1) {
      setState(() {
        _statusIndex++;
      });
    } else {
      // Hoàn thành đơn hàng
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đơn hàng đã hoàn thành!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Giao hàng", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: TColor.white,
        foregroundColor: TColor.primaryText,
        elevation: 0.5,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _shipperPos,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.appfood',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [_restaurantPos, _customerPos],
                    color: TColor.primary.withValues(alpha: 0.6),
                    strokeWidth: 4,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // Shipper
                  Marker(
                    point: _shipperPos,
                    width: 40,
                    height: 40,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.delivery_dining, color: Colors.white, size: 20),
                    ),
                  ),
                  // Restaurant
                  Marker(
                    point: _restaurantPos,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.storefront, color: Colors.red, size: 35),
                  ),
                  // Customer
                  Marker(
                    point: _customerPos,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_on, color: Colors.green, size: 35),
                  ),
                ],
              ),
            ],
          ),
          
          // Bottom Info Panel
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(color: TColor.textfield, shape: BoxShape.circle),
                        child: const Icon(Icons.person),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.order['customerName'] ?? "Khách hàng", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(widget.order['address'] ?? "Địa chỉ khách hàng", style: TextStyle(color: TColor.secondaryText, fontSize: 13)),
                          ],
                        ),
                      ),
                      IconButton(onPressed: () {}, icon: const Icon(Icons.phone, color: Colors.green)),
                    ],
                  ),
                  const Divider(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Trạng thái hiện tại", style: TextStyle(color: TColor.secondaryText, fontSize: 12)),
                          Text(_statuses[_statusIndex], style: TextStyle(color: TColor.primary, fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: _updateStatus,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TColor.primary,
                          shape: RoundedRectangle_circular(20),
                          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                        ),
                        child: Text(
                          _statusIndex == 0 ? "Lấy hàng" : (_statusIndex == 1 ? "Đã đến" : "Hoàn thành"),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper to fix syntax if needed
RoundedRectangleBorder RoundedRectangle_circular(double r) => RoundedRectangleBorder(borderRadius: BorderRadius.circular(r));
