import 'package:flutter/material.dart';

class CategoryItem extends StatelessWidget {
  final String name;
  final bool isSelected;

  const CategoryItem({
    super.key,
    required this.name,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF81C784) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isSelected)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Center(
        child: Text(
          name,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}
