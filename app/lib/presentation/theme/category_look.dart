import 'package:flutter/material.dart';

class CategoryLook {
  const CategoryLook({
    required this.name,
    required this.icon,
    required this.color,
    required this.background,
  });

  final String name;
  final IconData icon;
  final Color color;
  final Color background;
}

/// Display labels/icons aligned with Demo Chi cho. Not seed transactions.
CategoryLook categoryLook(String categoryId) {
  return switch (categoryId) {
    'breakfast' => const CategoryLook(
        name: 'Ăn sáng',
        icon: Icons.free_breakfast_outlined,
        color: Color(0xFFFF8A5B),
        background: Color(0xFFFFF0EA),
      ),
    'lunch' => const CategoryLook(
        name: 'Ăn trưa',
        icon: Icons.lunch_dining_outlined,
        color: Color(0xFFFFB020),
        background: Color(0xFFFFF6E5),
      ),
    'dinner' => const CategoryLook(
        name: 'Ăn tối',
        icon: Icons.dinner_dining_outlined,
        color: Color(0xFFFF6B9D),
        background: Color(0xFFFFE8F0),
      ),
    'cafe' => const CategoryLook(
        name: 'Cafe',
        icon: Icons.local_cafe_outlined,
        color: Color(0xFFA0785A),
        background: Color(0xFFF5EDE6),
      ),
    'market' => const CategoryLook(
        name: 'Đi chợ',
        icon: Icons.local_grocery_store_outlined,
        color: Color(0xFF00B67A),
        background: Color(0xFFE6F8EF),
      ),
    'transport' => const CategoryLook(
        name: 'Di chuyển',
        icon: Icons.directions_car_outlined,
        color: Color(0xFF4DA3FF),
        background: Color(0xFFE8F3FF),
      ),
    'shopping' => const CategoryLook(
        name: 'Mua sắm',
        icon: Icons.shopping_bag_outlined,
        color: Color(0xFFB57BFF),
        background: Color(0xFFF3EBFF),
      ),
    _ => const CategoryLook(
        name: 'Khác',
        icon: Icons.more_horiz,
        color: Color(0xFF8B93A0),
        background: Color(0xFFEEF1F5),
      ),
  };
}
