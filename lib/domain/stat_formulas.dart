/// Bảng công thức chỉ số — NGUỒN DUY NHẤT (domain, giao diện, mô phỏng đều đọc ở đây).
///
/// Bốn chỉ số gốc: Sức mạnh (STR), Tốc độ (DEX), Thể hình (CON) và Công (ATK). Ba chỉ số dẫn xuất — HP, Thể lực
/// (năng lượng) và Tinh thần — chỉ tính từ bốn chỉ số gốc HIỆU DỤNG (đã cộng trang bị), nên đổi trang bị hay tăng
/// điểm là tính lại, không cộng thẳng từ nơi nào khác.
///
/// Mọi giá trị là số nguyên. Mỗi hệ số của HP đều >= hệ số tương ứng của Thể lực, và của Thể lực >= của Tinh thần
/// (kể cả hệ số nền), nên HP > Thể lực > Tinh thần luôn đúng với mọi bộ chỉ số không âm — không cần kẹp tay.
library;

import 'dart:math';

/// Bốn chỉ số gốc hiệu dụng của một binh sĩ (đã gồm trang bị / huấn luyện tạm thời).
class CoreStats {
  const CoreStats({
    required this.str,
    required this.dex,
    required this.con,
    required this.atk,
  });

  final int str, dex, con, atk;

  @override
  bool operator ==(Object other) =>
      other is CoreStats &&
      other.str == str &&
      other.dex == dex &&
      other.con == con &&
      other.atk == atk;

  @override
  int get hashCode => Object.hash(str, dex, con, atk);

  @override
  String toString() => 'CoreStats(str:$str dex:$dex con:$con atk:$atk)';
}

/// Hệ số một chỉ số dẫn xuất: `nền + str·a + dex·b + con·c + atk·d`.
class VitalFormula {
  const VitalFormula({
    required this.base,
    required this.str,
    required this.dex,
    required this.con,
    required this.atk,
  });

  final int base, str, dex, con, atk;

  int of(CoreStats c) =>
      max(0, base + str * c.str + dex * c.dex + con * c.con + atk * c.atk);
}

abstract final class StatFormulas {
  /// HP tối đa: lớn nhất; Thể hình đóng góp nhiều nhất.
  static const hp = VitalFormula(base: 20, str: 3, dex: 2, con: 5, atk: 2);

  /// Thể lực (năng lượng) tối đa: thấp hơn HP.
  static const energy = VitalFormula(base: 10, str: 2, dex: 2, con: 3, atk: 1);

  /// Tinh thần tối đa: thấp nhất.
  static const morale = VitalFormula(base: 5, str: 1, dex: 1, con: 2, atk: 1);

  static int maxHp(CoreStats c) => hp.of(c);
  static int maxEnergy(CoreStats c) => energy.of(c);
  static int maxMorale(CoreStats c) => morale.of(c);

  /// Dải chỉ số gốc khi sinh binh sĩ cấp 1: nền theo vai trò (xem `roleBaseStats`, `roleBaseAttack`) cộng thêm
  /// `0..startSpread-1` ngẫu nhiên mỗi chỉ số; mỗi cấp trên 1 cộng [perLevelBonus] mỗi chỉ số (lính chiêu mộ/địch).
  static const startSpread = 2;
  static const perLevelBonus = 1;

  /// Địch mạnh hơn lính cùng cấp: mỗi cấp trên 1, chỉ số gốc địch cộng `enemyGrowthNum / enemyGrowthDen` (làm tròn xuống
  /// trên tổng), trong khi lính chỉ cộng [perLevelBonus]. Hiệu chuẩn bằng các test đường cong khó (domain_v2_test).
  static const enemyGrowthNum = 3;
  static const enemyGrowthDen = 2;
  static int enemyLevelBonus(int level) =>
      (level - 1) * enemyGrowthNum ~/ enemyGrowthDen;

  /// Chỉ số gốc lớn nhất có thể có ở cấp 1 (nền lớn nhất 4 + 1 ngẫu nhiên).
  static const startMax = 5;
  static const startMin = 1;

  /// Trần chỉ số gốc cơ bản (không tính trang bị) có thể huấn luyện được ở cấp [level]: `startMax + 2 × cấp`
  /// (cấp 1 → 7, cấp 6 → 17). Mỗi cấp còn cho 1 điểm chỉ số để người chơi tự phân bổ.
  static int statCap(int level) => startMax + 2 * level;
}

/// Mức HP / Thể lực / Tinh thần tối đa tại một thời điểm, để so trước-sau khi chỉ số gốc đổi.
class VitalCaps {
  const VitalCaps(this.hp, this.energy, this.morale);
  final int hp, energy, morale;
}

/// Chính sách bảo toàn giá trị hiện tại khi mức tối đa đổi (đeo/tháo trang bị, cộng điểm, học kỹ năng): GIỮ NGUYÊN
/// TỶ LỆ `hiện tại / tối đa` (làm tròn), không bao giờ vượt tối đa mới, và còn sống (>0) thì còn ít nhất 1.
/// - Đầy thì vẫn đầy; thiếu 20% thì vẫn thiếu 20% — không tự hồi đầy, không tự tăng ngoài ý muốn.
/// - Đối xứng: đeo rồi tháo ngay (hoặc ngược lại) trả về đúng giá trị cũ (sai lệch làm tròn tối đa 1), nên không
///   thể "đổi đồ để hồi máu".
/// Giá trị <= 0 (đã gục / chưa khởi tạo) giữ nguyên.
int rebaseCurrent(int current, int oldMax, int newMax) {
  if (current <= 0 || oldMax <= 0 || newMax == oldMax) {
    return min(current, max(newMax, 0));
  }
  final scaled = (current * newMax / oldMax).round();
  return scaled.clamp(1, max(1, newMax));
}

/// Các hằng số "điểm" của luật thể trạng (mỗi ngày, mỗi trận…) vốn viết cho thang 100: quy về thang của [cap]
/// (Thể lực / Tinh thần tối đa của từng binh sĩ) để cùng một tỷ lệ phần trăm, không phụ thuộc cỡ chỉ số.
/// Khác 0 thì luôn ít nhất ±1.
int scaleVital(int pointsPer100, int cap) {
  if (pointsPer100 == 0) return 0;
  final v = (pointsPer100 * cap / 100).round();
  if (v != 0) return v;
  return pointsPer100 > 0 ? 1 : -1;
}

/// Tinh thần lúc mới sinh: [startMoraleFraction] của mức tối đa.
const startMoraleFraction = 0.7;

/// Tinh thần (và ngưỡng bỏ trốn) tính theo phần trăm mức tối đa.
const desertMoraleFraction = 0.15;
