/// Phẩm cấp trang bị (Level 1–6): thuộc tính của VẬT PHẨM (`ItemDef.tier`), khác với cấp độ anh hùng.
///
/// Quy tắc dùng chung cho cửa hàng, kho đồ, trang bị đang mặc và luật mua/bán/trang bị:
/// * Điều kiện sử dụng: `hero.level >= requiredHeroLevel(grade)`; Level 1 là đồ cơ bản, không có điều kiện bổ sung.
/// * Level 6 không bán ở Lò rèn (chỉ nhận từ nhiệm vụ).
/// * Màu nền chỉ là cách thể hiện; mọi logic KHÔNG phụ thuộc màu.
///
/// Thuần Dart (màu là ARGB) để domain không phụ thuộc Flutter.
library;

const int minItemGrade = 1;
const int maxItemGrade = 6;

/// Cấp anh hùng tối thiểu để dùng trang bị phẩm cấp [grade].
int requiredHeroLevel(int grade) => grade <= 1 ? 1 : grade;

/// Lò rèn có được bán phẩm cấp [grade] không (Level 6 thì không).
bool smithySellsGrade(int grade) => grade >= 1 && grade < maxItemGrade;

/// Màu nền phẩm cấp (ARGB); null = Level 1, không có nền phẩm cấp.
int? gradeBackgroundArgb(int grade) => switch (grade) {
  2 => 0xFF3E8E41, // xanh lá
  3 => 0xFF1F3F8F, // xanh dương đậm
  4 => 0xFF7B3FA0, // tím
  5 => 0xFFD4A93A, // vàng
  6 => 0xFFB3202A, // đỏ
  _ => null,
};
