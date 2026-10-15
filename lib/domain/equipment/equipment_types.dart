import '../item_grade.dart';
import '../models.dart';

/// Độ hiếm của trang bị = phẩm cấp 1..5. Quyết định màu nền hiển thị (xem [gradeBackgroundArgb]);
/// màu nền KHÔNG thay thế hình dáng hay chất liệu riêng của từng thiết kế.
enum EquipmentRarity {
  common('Thường'),
  uncommon('Tốt'),
  rare('Hiếm'),
  epic('Sử thi'),
  legendary('Huyền thoại');

  const EquipmentRarity(this.label);
  final String label;

  int get grade => index + 1;

  /// Nền ARGB theo cấp; cấp 1 dùng nền trung tính của game ([commonBackgroundArgb]).
  int get backgroundArgb => gradeBackgroundArgb(grade) ?? commonBackgroundArgb;

  static EquipmentRarity ofGrade(int grade) =>
      values[(grade - 1).clamp(0, values.length - 1)];
}

/// Nền cấp 1 (thường, phổ thông): xám nâu trung tính.
const int commonBackgroundArgb = 0xFF4A4338;

/// Số tay cần để cầm. Vũ khí hai tay chiếm cả ô vũ khí lẫn ô tay phụ (khiên).
enum HandUse { oneHand, twoHand }

/// Phân loại vũ khí theo hình thức (hiển thị + vẽ). Cách đánh/chỉ số nền vẫn theo [WeaponType]
/// (xem `weaponProfiles`); [family] nối hai khái niệm này.
enum WeaponKind {
  sword('Kiếm', WeaponType.sword),
  saber('Đao', WeaponType.sword),
  greatsword('Kiếm hai tay', WeaponType.sword),
  dagger('Dao găm', WeaponType.dagger),
  axe('Rìu', WeaponType.axe),
  greataxe('Rìu chiến hai tay', WeaponType.axe),
  mace('Chùy', WeaponType.mace),
  flail('Liên chùy', WeaponType.mace),
  hammer('Búa', WeaponType.mace),
  spear('Giáo', WeaponType.spear),
  polearm('Thương', WeaponType.spear),
  bow('Cung', WeaponType.bow),
  crossbow('Nỏ', WeaponType.crossbow);

  const WeaponKind(this.label, this.family);
  final String label;
  final WeaponType family;
}

/// Hình dạng khiên (silhouette), mỗi thiết kế khiên thuộc đúng một hình.
enum ShieldShape {
  buckler('Khiên nhỏ tròn'),
  round('Khiên tròn'),
  oval('Khiên bầu dục'),
  square('Khiên vuông'),
  rectangle('Khiên chữ nhật'),
  kite('Khiên đuôi nhọn'),
  heater('Khiên tam giác cong'),
  hexagon('Khiên lục giác'),
  curvedTop('Khiên đầu cong'),
  tower('Khiên tháp lớn'),
  pavise('Khiên bao vây'),
  other('Khiên đặc biệt');

  const ShieldShape(this.label);
  final String label;
}

/// Lớp áo giáp (chất liệu chính) – chỉ để mô tả/lọc.
enum ArmorClass {
  cloth('Vải'),
  leather('Da'),
  mail('Giáp xích'),
  scale('Giáp vảy'),
  plate('Giáp tấm'),
  lamellar('Giáp lá'),
  ornate('Giáp lễ');

  const ArmorClass(this.label);
  final String label;
}
