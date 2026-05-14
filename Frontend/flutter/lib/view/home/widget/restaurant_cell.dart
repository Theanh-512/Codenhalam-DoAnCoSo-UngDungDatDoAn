import 'package:flutter/material.dart';
import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter_food_app/common/smart_image.dart';
import 'package:flutter_food_app/model/restaurant_model.dart';

class RestaurantCell extends StatelessWidget {
  final RestaurantModel restaurant;
  final VoidCallback onTap;

  const RestaurantCell({
    super.key,
    required this.restaurant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: SmartImage(
                restaurant.imageUrl,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: double.infinity,
                  height: 180,
                  color: Colors.grey[300],
                  child: const Icon(Icons.restaurant, color: Colors.grey, size: 50),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: TColor.primaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (restaurant.isOpen)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            "Mở cửa",
                            style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        "${restaurant.rating}",
                        style: TextStyle(
                          color: TColor.primaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "(${restaurant.reviewCount}+)",
                        style: TextStyle(color: TColor.secondaryText, fontSize: 13),
                      ),
                      const SizedBox(width: 8),
                      Text("•", style: TextStyle(color: TColor.secondaryText)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          restaurant.typeTagsDisplayLine,
                          style: TextStyle(color: TColor.secondaryText, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, color: TColor.secondaryText, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        restaurant.deliveryTime,
                        style: TextStyle(color: TColor.secondaryText, fontSize: 12),
                      ),
                      const SizedBox(width: 15),
                      Icon(Icons.delivery_dining_rounded, color: TColor.primary, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        restaurant.deliveryFee == 0 ? "Free Ship" : "${restaurant.deliveryFee.toInt()}đ",
                        style: TextStyle(color: TColor.primary, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      if (restaurant.distanceKm != null)
                        Text(
                          "${restaurant.distanceKm!.toStringAsFixed(1)} km",
                          style: TextStyle(color: TColor.secondaryText, fontSize: 12),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
