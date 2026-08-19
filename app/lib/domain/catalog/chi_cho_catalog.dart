/// Production Chi cho catalog. Labels match V3; this is not Demo JS state.
class ChiChoCategory {
  const ChiChoCategory({
    required this.id,
    required this.name,
    required this.details,
    this.visualKey = 'other',
    this.archived = false,
  });

  final String id;
  final String name;
  final List<String> details;
  final String visualKey;
  final bool archived;

  ChiChoCategory copyWith({
    String? name,
    List<String>? details,
    String? visualKey,
    bool? archived,
  }) {
    return ChiChoCategory(
      id: id,
      name: name ?? this.name,
      details: details ?? this.details,
      visualKey: visualKey ?? this.visualKey,
      archived: archived ?? this.archived,
    );
  }
}

class ChiChoCatalog {
  ChiChoCatalog._();

  static const defaultId = 'cafe';

  static const all = [
    ChiChoCategory(
      id: 'breakfast',
      name: 'Ăn sáng',
      details: ['Mì Quảng', 'Bánh mì', 'Phở', 'Xôi', 'Bún', 'Khác'],
      visualKey: 'breakfast',
    ),
    ChiChoCategory(
      id: 'lunch',
      name: 'Ăn trưa',
      details: ['Cơm', 'Bún', 'Phở', 'Cơm tấm', 'Khác'],
      visualKey: 'lunch',
    ),
    ChiChoCategory(
      id: 'dinner',
      name: 'Ăn tối',
      details: ['Cơm', 'Lẩu', 'Nướng', 'Ăn vặt', 'Khác'],
      visualKey: 'dinner',
    ),
    ChiChoCategory(
      id: 'cafe',
      name: 'Cafe',
      details: ['Highlands', 'Ô Bầu', 'The Coffee House', 'Khác'],
      visualKey: 'cafe',
    ),
    ChiChoCategory(
      id: 'market',
      name: 'Đi chợ',
      details: ['Rau', 'Thịt', 'Cá', 'Trái cây', 'Đồ khô', 'Khác'],
      visualKey: 'market',
    ),
    ChiChoCategory(
      id: 'transport',
      name: 'Di chuyển',
      details: ['Grab', 'Xăng', 'Xe buýt', 'Taxi', 'Khác'],
      visualKey: 'transport',
    ),
    ChiChoCategory(
      id: 'shopping',
      name: 'Mua sắm',
      details: ['Quần áo', 'Đồ gia dụng', 'Mỹ phẩm', 'Khác'],
      visualKey: 'shopping',
    ),
    ChiChoCategory(
      id: 'other',
      name: 'Khác',
      details: ['Khác'],
      visualKey: 'other',
    ),
  ];

  static ChiChoCategory byId(String id) {
    for (final category in all) {
      if (category.id == id) return category;
    }
    return all.last;
  }
}
