class Restaurant {
  final int id;
  final String name;
  final String description;
  final String imageUrl;
  final String info;

  Restaurant({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.info,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=500',
      info: '4.8 ⭐ (1.2km) • 30-40 phút', // Mock info for now or use fields from backend
    );
  }
}
