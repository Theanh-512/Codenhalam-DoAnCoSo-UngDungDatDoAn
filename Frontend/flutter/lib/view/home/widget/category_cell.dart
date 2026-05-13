import 'package:flutter/material.dart';
import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter_food_app/common/smart_image.dart';
import 'package:flutter_food_app/model/category_model.dart';

class CategoryCell extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const CategoryCell({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 15),
        child: Column(
          children: [
            category.name == "Khuyến mãi"
                ? Container(
                    width: 85,
                    height: 85,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [Colors.orange.shade400, Colors.deepOrange.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.3),
                            blurRadius: 5,
                            offset: const Offset(0, 3)),
                      ],
                    ),
                    child: const Icon(Icons.local_offer_rounded, color: Colors.white, size: 36),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SmartImage(
                      category.imageUrl,
                      width: 85,
                      height: 85,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 85,
                        height: 85,
                        color: Colors.grey[300],
                        child: const Icon(Icons.fastfood, color: Colors.grey),
                      ),
                    ),
                  ),
            const SizedBox(height: 8),
            Text(
              category.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: TColor.primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
