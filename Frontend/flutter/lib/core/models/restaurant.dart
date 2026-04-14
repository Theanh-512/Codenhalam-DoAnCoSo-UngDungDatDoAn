class Restaurant {
  final int id;
  final String name;
  final String description;
  final String imageUrl;
  final String address;
  final String openingHours;
  final double latitude;
  final double longitude;
  final String info;

  Restaurant({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.address,
    required this.openingHours,
    required this.latitude,
    required this.longitude,
    required this.info,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=500',
      address: json['address'] ?? 'Đang cập nhật',
      openingHours: json['openingHours'] ?? 'Mở cửa cả ngày',
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      info: '4.8 ⭐ (1.2km) • 30-40 phút', // Mock info for now or use fields from backend
    );
  }
}
