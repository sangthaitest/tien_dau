/// Production Chi cho catalog. Labels match V3; this is not Demo JS state.
class ChiChoCategory {
  const ChiChoCategory({
    required this.id,
    required this.name,
    required this.details,
  });

  final String id;
  final String name;
  final List<String> details;
}

class ChiChoCatalog {
  ChiChoCatalog._();

  static const defaultId = 'cafe';

  static const all = [
    ChiChoCategory(
      id: 'breakfast',
      name: 'Ăn sáng',
      details: ['Mì Quảng', 'Bánh mì', 'Phở', 'Xôi', 'Bún', 'Khác'],
    ),
    ChiChoCategory(
      id: 'lunch',
      name: 'Ăn trưa',
      details: ['Cơm', 'Bún', 'Phở', 'Cơm tấm', 'Khác'],
    ),
    ChiChoCategory(
      id: 'dinner',
      name: 'Ăn tối',
      details: ['Cơm', 'Lẩu', 'Nướng', 'Ăn vặt', 'Khác'],
    ),
    ChiChoCategory(
      id: 'cafe',
      name: 'Cafe',
      details: ['Highlands', 'Ô Bầu', 'The Coffee House', 'Khác'],
    ),
    ChiChoCategory(
      id: 'market',
      name: 'Đi chợ',
      details: ['Rau', 'Thịt', 'Cá', 'Trái cây', 'Đồ khô', 'Khác'],
    ),
    ChiChoCategory(
      id: 'transport',
      name: 'Di chuyển',
      details: ['Grab', 'Xăng', 'Xe buýt', 'Taxi', 'Khác'],
    ),
    ChiChoCategory(
      id: 'shopping',
      name: 'Mua sắm',
      details: ['Quần áo', 'Đồ gia dụng', 'Mỹ phẩm', 'Khác'],
    ),
    ChiChoCategory(
      id: 'other',
      name: 'Khác',
      details: ['Khác'],
    ),
  ];

  static ChiChoCategory byId(String id) {
    for (final category in all) {
      if (category.id == id) return category;
    }
    return all.last;
  }
}
