import 'dart:math';

import 'catalog.dart';
import 'models.dart';
import 'movement.dart';
import 'terrain_type.dart';
import 'world_data.dart';
import 'world_map.dart';

/// Một điểm trên bản đồ có thể sinh ra cuộc giao chiến của nhiệm vụ săn.
class EncounterSite {
  const EncounterSite(this.position, this.regionId);
  final WPoint position;
  final String regionId;
}

/// Sinh nhiệm vụ săn cho vòng lặp chiến đấu vô hạn: độ khó theo sức mạnh đội quân, điểm giao chiến thật trên bản
/// đồ, đội địch tương ứng. Thuần Dart và xác định (mọi ngẫu nhiên nhận `Random` từ luật). Không có nhiệm vụ hành
/// chính: mọi nhiệm vụ được sinh ra đều là một trận chiến tại một điểm trên bản đồ.
abstract final class QuestGenerator {
  /// Số nhiệm vụ tối đa trên bảng thành trấn (KHÁC với số nhiệm vụ người chơi được nhận cùng lúc:
  /// `GameRules.maxActiveMissions`).
  static const maxOffered = 6;
  static const maxDifficulty = 5;

  /// Khoảng thời hạn (ngày game) của một nhiệm vụ săn: nguồn duy nhất cho cả luật lẫn mô phỏng.
  static const minQuestDays = 3;
  static const maxQuestDays = 7;

  /// Số ngày hạn của nhiệm vụ, random đúng một lần lúc nhận. Không bao giờ ngắn hơn thời gian đi tới điểm giao chiến
  /// ([travelDays]) + 2: một ngày hành quân vào điểm giao chiến (`LocationDef.days = 1` làm qua ngày) và còn ít nhất một
  /// ngày hạn khi đánh, nên nhiệm vụ luôn kịp làm nếu đi thẳng tới.
  static int rollDays(Random r, {int travelDays = 0}) {
    final d = minQuestDays + r.nextInt(maxQuestDays - minQuestDays + 1);
    return max(d, travelDays + 2);
  }

  /// Các điểm hợp lệ (đi được, không sát thị trấn/địa điểm sẵn có, tới được bằng đường thẳng từ một thị trấn),
  /// tính một lần theo bản đồ cố định.
  static final List<EncounterSite> sites = _buildSites();

  static List<EncounterSite> _buildSites() {
    final out = <EncounterSite>[];
    final placed = <(WPoint, String)>[
      for (final e in worldMap.placements.entries)
        if (locationById(e.key) != null)
          (e.value, locationById(e.key)!.regionId),
    ];
    for (var y = 220.0; y < worldMap.height - 200; y += 200) {
      for (var x = 220.0; x < worldMap.width - 200; x += 200) {
        final p = WPoint(x, y);
        if (!worldMap.isPassable(p)) continue;
        if (TerrainRules.multiplier(worldMap.terrainAt(p)) > 2.0) continue;
        if (worldMap.towns.any((t) => t.position.distanceTo(p) < 300)) continue;
        if (placed.any((e) => e.$1.distanceTo(p) < 250)) continue;
        final near = worldMap.towns.reduce(
          (a, b) =>
              a.position.distanceTo(p) <= b.position.distanceTo(p) ? a : b,
        );
        if (near.position.distanceTo(p) > 1100) continue;
        if (!MovementRules.estimate(worldMap, near.position, p).reachable) {
          continue;
        }
        var best = placed.first;
        for (final e in placed) {
          if (e.$1.distanceTo(p) < best.$1.distanceTo(p)) best = e;
        }
        out.add(EncounterSite(p, best.$2));
      }
    }
    return List.unmodifiable(out);
  }

  /// Độ khó cơ sở (1..5) theo sức mạnh đội quân: cấp trung bình của tối đa 6 binh sĩ mạnh nhất.
  static int band(GameState s) {
    final levels = [for (final x in s.roster) x.level]
      ..sort((a, b) => b.compareTo(a));
    if (levels.length < 3) return 1;
    final top = levels.take(6).toList();
    final avg = top.fold(0, (a, b) => a + b) / top.length;
    return avg.floor().clamp(1, maxDifficulty);
  }

  /// Ba độ khó của bảng nhiệm vụ. Người mới chỉ thấy độ khó 1. Từ bậc 2 trở lên bảng luôn có một nhiệm vụ AN TOÀN
  /// (thấp hơn đội hai bậc), một vừa sức (thấp hơn một bậc) và một ngang sức đội: đội mạnh luôn có việc tích lũy
  /// được mà không bắt buộc đánh nhiệm vụ rủi ro cao; lên cấp thì ba mức đều khó hơn.
  static List<int> offerDifficulties(int band) =>
      band <= 1 ? const [1, 1, 1] : [max(1, band - 2), band - 1, band];

  /// Bảng thành trấn hiển thị gấp đôi [offerDifficulties] (mỗi độ khó có cả nhiệm vụ vàng lẫn đỏ): tổng [maxOffered].
  static List<int> boardDifficulties(int band) => [
    ...offerDifficulties(band),
    ...offerDifficulties(band),
  ];

  /// Id ổn định của điểm giao chiến gắn với nhiệm vụ [missionId].
  static String idFor(int missionId) => 'enc_$missionId';

  /// Đội địch theo độ khó, có biến thiên nhỏ theo [r]. Cấp địch = độ khó. Số lượng đã hiệu chỉnh bằng
  /// `tool/quest_balance_sim.dart`: chiến đấu rất dốc (thắng/thua gần như nhị phân theo tương quan lực lượng), nên
  /// số địch chỉ tăng chậm và độ khó 1 co theo quân số hiện có ([squadSize]) để đội thiếu quân luôn có lựa chọn
  /// khả thi: ≥5 lính 2 giáo + 2 cung; 4 lính 2 giáo + 1 cung; 3 lính 1 giáo + 2 cung; ≤2 lính 1 giáo + 1 cung.
  static List<(Role, int, int)> enemyPlan(
    int d,
    Random r, {
    int squadSize = 6,
  }) {
    final (spear, archer, cav) = switch (d) {
      1 =>
        squadSize >= 5
            ? (2, 2, 0)
            : squadSize == 4
            ? (2, 1, 0)
            : squadSize == 3
            ? (1, 2, 0)
            : (1, 1, 0),
      2 || 3 || 4 => (2, 2, 0),
      _ => (2, 2, 1),
    };
    final shift = d >= 2 && r.nextBool()
        ? 1
        : 0; // một giáo binh đổi thành cung thủ
    return [
      (Role.spearman, d, spear - shift),
      (Role.archer, d, archer + shift),
      if (cav > 0) (Role.cavalry, d, cav),
    ];
  }

  /// Tạo điểm giao chiến cho độ khó [d]: chọn điểm trống gần nhân vật trong vùng đã mở, tránh trùng điểm của các
  /// nhiệm vụ đang làm. Null nếu không còn điểm hợp lệ.
  static Encounter? createEncounter(GameState s, int d, Random r) {
    final taken = [
      for (final m in s.missions)
        if (m.status == MissionStatus.active && m.encounter != null)
          WPoint(m.encounter!.x, m.encounter!.y),
    ];
    final free =
        [
          for (final site in sites)
            if (s.tier >= regionById(site.regionId).minTier &&
                !taken.any((t) => t.distanceTo(site.position) < 160))
              site,
        ]..sort(
          (a, b) => a.position
              .distanceTo(s.hero.position)
              .compareTo(b.position.distanceTo(s.hero.position)),
        );
    if (free.isEmpty) return null;
    final pick = free[r.nextInt(min(8, free.length))];
    return Encounter(
      x: pick.position.x,
      y: pick.position.y,
      difficulty: d,
      enemies: enemyPlan(d, r, squadSize: s.roster.length),
    );
  }

  /// Địa điểm giao chiến dưới dạng [LocationDef] để dùng chung luồng triển khai/chiến đấu hiện có.
  static LocationDef locationOf(Mission m, Encounter e) {
    final region = _nearestRegion(WPoint(e.x, e.y));
    return LocationDef(
      id: idFor(m.id),
      name: templateById(m.templateId).title,
      regionId: region,
      kind: LocKind.camp,
      days: 1,
      x: e.x,
      y: e.y,
      startsDiscovered: true,
      enemies: [for (final (r, l, c) in e.enemies) EnemySpec(r, l, c)],
      blurb: templateById(m.templateId).desc,
    );
  }

  static String _nearestRegion(WPoint p) {
    EncounterSite? best;
    for (final site in sites) {
      if (best == null ||
          site.position.distanceTo(p) < best.position.distanceTo(p)) {
        best = site;
      }
    }
    return best?.regionId ?? 'greenvale';
  }
}
