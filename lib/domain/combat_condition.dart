import 'dart:math';

import 'models.dart';
import 'stats.dart';

/// Công thức thể trạng sau trận: kinh nghiệm theo sát thương đóng góp, tiêu hao năng lượng theo thời gian
/// chiến đấu, tụt tinh thần theo sát thương nhận. Thuần Dart; trận đấu (`simulateBattle`) chỉ đo số liệu,
/// `GameRules.applyBattle` áp các công thức này đúng một lần.

// ---- Kinh nghiệm ----

/// XP cơ bản của một kẻ địch cấp [level] khi bị hạ HẾT máu (hạ một phần thì tính theo tỷ lệ máu đã mất).
int enemyXpValue(int level) => 10 + 6 * level;

/// Chia XP theo sát thương hợp lệ. [dealt] = {người gây → {mục tiêu → sát thương hợp lệ}} (đã chặn quá mức
/// máu còn lại của mục tiêu); [enemies] = {mục tiêu → (maxHp, cấp)}. Kết quả có TỔNG đúng bằng
/// `round(Σ enemyXpValue × tỷ lệ máu bị trừ)` (chia số dư theo phần thập phân lớn nhất, rồi theo id nhỏ nhất).
/// Người không gây sát thương không có mặt trong kết quả.
Map<int, int> distributeBattleXp(
  Map<int, Map<int, int>> dealt,
  Map<int, ({int maxHp, int level})> enemies,
) {
  final exact = <int, double>{};
  dealt.forEach((actor, perTarget) {
    var xp = 0.0;
    perTarget.forEach((target, dmg) {
      final e = enemies[target];
      if (e == null || dmg <= 0 || e.maxHp <= 0) return;
      xp += enemyXpValue(e.level) * min(dmg, e.maxHp) / e.maxHp;
    });
    if (xp > 0) exact[actor] = xp;
  });
  final total = exact.values.fold(0.0, (a, b) => a + b).round();
  final out = {for (final e in exact.entries) e.key: e.value.floor()};
  var left = total - out.values.fold(0, (a, b) => a + b);
  final order = exact.keys.toList()
    ..sort((a, b) {
      final fa = exact[a]! - exact[a]!.floor();
      final fb = exact[b]! - exact[b]!.floor();
      final c = fb.compareTo(fa);
      return c != 0 ? c : a.compareTo(b);
    });
  for (var i = 0; left > 0 && order.isNotEmpty; i++, left--) {
    out[order[i % order.length]] = out[order[i % order.length]]! + 1;
  }
  out.removeWhere((_, v) => v <= 0);
  return out;
}

// ---- Năng lượng ----

/// Năng lượng tiêu hao mỗi giây còn đứng trong trận và mỗi đòn đánh (kể cả trượt).
const energyPerSecond = 0.4;
const energyPerSwing = 0.5;

/// Tốc độ cao dùng năng lượng hiệu quả hơn: mỗi điểm Khéo léo trên mức 5 giảm tiêu hao 2% (tối đa −30%).
double energyEfficiency(int dex) =>
    (1 - 0.02 * (dex - neutralStat)).clamp(0.7, 1.0);

/// Năng lượng mất của một binh sĩ đã chiến đấu [seconds] giây với [swings] đòn. Chỉ gọi cho người tham chiến.
int battleEnergyCost(
  Soldier s, {
  required double seconds,
  required int swings,
}) =>
    // Hằng số viết cho thang 100: quy về Thể lực tối đa của từng binh sĩ (cùng tỷ lệ phần trăm).
    ((seconds * energyPerSecond + swings * energyPerSwing) *
            energyEfficiency(s.stats[Stat.dex]!) *
            energyCap(s) /
            100)
        .round();

// ---- Tinh thần ----

/// Mỗi đòn trúng làm tụt [moraleLossPerHit] + [moraleLossPerMaxHp] × (sát thương thực nhận / máu tối đa).
/// Đòn trượt (không nhận sát thương) không làm tụt tinh thần.
const moraleLossPerHit = 0.3;
const moraleLossPerMaxHp = 18.0;

double moraleLossForHit(int damage, int maxHp) => damage <= 0
    ? 0
    : moraleLossPerHit + moraleLossPerMaxHp * damage / max(1, maxHp);

// ---- Thương tích ----

/// Dưới ngưỡng này binh sĩ bị coi là trọng thương (băng bó ở hình vẽ). Suy ra từ HP hiện tại, không lưu.
const woundedBelow = 0.5;

bool isBadlyWounded(Soldier s) =>
    s.alive && s.hp > 0 && s.hp / max(1, s.maxHp) < woundedBelow;

/// Ngưỡng cảnh báo đỏ của thanh năng lượng/tinh thần ở danh sách.
const vitalWarnBelow = 0.5;
