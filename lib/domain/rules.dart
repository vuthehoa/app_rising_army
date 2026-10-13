import 'dart:math';

import 'battle.dart';
import 'building_effects.dart';
import 'camp_layout.dart';
import 'catalog.dart';
import 'dev_mode.dart';
import 'identity.dart';
import 'item_grade.dart';
import 'models.dart';
import 'progression.dart';
import 'stats.dart';
import 'terrain_type.dart';
import 'world_data.dart';

enum CasualtyKind { survived, wounded, dead }

/// Trạng thái hiển thị/điều kiện của một công trình trong catalog trại (xem [GameRules.campStatus]).
class CampBuildStatus {
  const CampBuildStatus({
    required this.def,
    required this.count,
    required this.level,
    required this.cost,
    required this.reason,
    required this.needsPlacement,
  });

  final CampBuildingDef def;

  /// Số công trình đã có (công trình cấp bậc: 1 nếu cấp > 0).
  final int count;

  /// Cấp hiện tại (chỉ công trình cấp bậc).
  final int level;

  /// Chi phí hành động kế tiếp; null nếu không còn hành động nào (đã xây xong/cấp tối đa).
  final Cost? cost;

  /// Lý do không thể hành động; null = có thể xây/nâng cấp ngay.
  final String? reason;

  /// true nếu hành động kế tiếp là XÂY mới và cần chọn vị trí trong trại; false nếu là nâng cấp.
  final bool needsPlacement;

  bool get canAct => reason == null;
  bool get built => count > 0;
  bool get isUpgrade => !needsPlacement;
}

class Casualty {
  Casualty(this.id, this.name, this.kind, {this.xp = 0, this.levelUps = 0});
  final int id;
  final String name;
  final CasualtyKind kind;
  final int xp;
  final int levelUps;
}

class DayReport {
  const DayReport({
    required this.stipend,
    required this.upkeep,
    required this.paid,
    required this.lines,
  });
  final Cost stipend;
  final int upkeep;
  final bool paid;
  final List<String> lines;
}

class ExpeditionResult {
  ExpeditionResult(this.result, {this.location, this.days = 0});
  final ActionResult result;
  final LocationDef? location;
  final int days;
  BattleReport? battle;
  List<Casualty> casualties = [];
  Cost gained = {};
  String? itemGained;
  String? discovered;
  bool ambush = false;
  final List<String> lines = [];
  String? missionNote;
  String? city;
}

/// Luật gameplay thuần Dart. Mọi ngẫu nhiên đi qua state.seed + state.rngCounter nên tái lập được.
class GameRules {
  GameRules._();

  static const maxSquad = 10;
  static const startRoster = 6;

  static Random rng(GameState s) => Random(s.seed * 7919 + s.rngCounter++);

  // ---------- Tạo ván mới & sinh binh sĩ ----------

  static const _base = <Role, Map<Stat, int>>{
    Role.spearman: {Stat.str: 6, Stat.dex: 5, Stat.con: 6},
    Role.archer: {Stat.str: 3, Stat.dex: 8, Stat.con: 4},
    Role.cavalry: {Stat.str: 6, Stat.dex: 6, Stat.con: 5},
  };

  static String _name(Random r) {
    final n = firstNames[r.nextInt(firstNames.length)];
    return r.nextInt(100) < 30
        ? '$n ${nickNames[r.nextInt(nickNames.length)]}'
        : n;
  }

  static Soldier generateSoldier(
    GameState s, {
    Role? role,
    int level = 1,
    bool equip = false,
  }) {
    final r = rng(s);
    final rl = role ?? Role.values[r.nextInt(Role.values.length)];
    final stats = {
      for (final st in Stat.values)
        st: _base[rl]![st]! + r.nextInt(3) + (level - 1),
    };
    final trait = r.nextInt(100) < 45
        ? TraitId.none
        : TraitId.values[1 + r.nextInt(TraitId.values.length - 1)];
    final sol = Soldier(
      id: s.nextSoldierId++,
      name: _name(r),
      role: rl,
      stats: stats,
      level: level,
      trait: trait,
    );
    if (equip) {
      sol.weaponId = starterWeapon[rl];
      sol.armorId = 'padded_armor';
    }
    sol.hp = deriveStats(sol).maxHp;
    return sol;
  }

  /// [identity] mặc định là [PlayerIdentity.defaults]. Danh tính tự đặt phải hợp lệ
  /// (xem [validateIdentity]); nếu không sẽ ném [ArgumentError] thay vì tạo ván hỏng.
  static GameState newGame({int seed = 1337, PlayerIdentity? identity}) {
    if (identity != null && validateIdentity(identity).isNotEmpty) {
      throw ArgumentError.value(identity, 'identity', 'Danh tính không hợp lệ');
    }
    final s = GameState(
      seed: seed,
      identity: identity?.trimmed() ?? PlayerIdentity.defaults,
      day: 1,
      res: {
        Res.food: 80,
        Res.coins: 120,
        Res.wood: 40,
        Res.iron: 20,
        Res.tools: 0,
        Res.stone: 0,
        Res.cloth: 0,
      },
      soldiers: [],
      nextSoldierId: 1,
      // Mọi công trình đều phải được xây (cấp 0 = chưa xây). Bếp lửa giữa trại chỉ là hình trang trí
      // (xem [campfireSpot]), không phải công trình.
      buildings: {for (final b in Building.values) b: 0},
      facilities: [],
      nextFacilityId: 1,
      inventory: {'padded_armor': 1, 'iron_ring': 1, 'lucky_charm': 1},
      candidates: [],
      missions: [],
      nextMissionId: 1,
      kingSatisfaction: 50,
      missionsCompleted: 0,
      discovered: {
        for (final l in locations)
          if (l.startsDiscovered) l.id,
      },
      cleared: {},
      explored: {},
      log: [],
    );
    final roles = [
      Role.spearman,
      Role.spearman,
      Role.spearman,
      Role.archer,
      Role.archer,
      Role.cavalry,
    ];
    for (final r in roles) {
      s.soldiers.add(generateSoldier(s, role: r, equip: true));
    }
    refreshCandidates(s);
    fillBoard(s);
    s.addLog('Bạn nhận quyền chỉ huy một trại lính nhỏ.');
    return s;
  }

  // ---------- Tài nguyên ----------

  /// Đủ tài nguyên để trả [c]? Luôn true khi Develop Mode miễn chi phí.
  static bool canAfford(GameState s, Cost c) =>
      DevMode.freeResources ||
      c.entries.every((e) => (s.res[e.key] ?? 0) >= e.value);

  /// Số vàng có thể chi: vô hạn (giá trị rất lớn) khi Develop Mode bật.
  static int spendableCoins(GameState s) =>
      DevMode.freeResources ? 1 << 30 : s.res[Res.coins]!;

  /// Chỉ dùng cho công cụ mô phỏng: sổ thu/chi tích lũy. Null trong game thật.
  static Map<Res, int>? ledgerIn;
  static Map<Res, int>? ledgerOut;

  /// Chỉ dùng cho mô phỏng: gọi sau mỗi lần qua ngày.
  static void Function(GameState s)? dayHook;

  /// Trả chi phí [c]. Không làm gì khi Develop Mode miễn chi phí.
  /// Dùng cho CHI PHÍ; việc giao ra tài nguyên thật (bán hàng) dùng [_deduct].
  static void spend(GameState s, Cost c) {
    if (DevMode.freeResources) return;
    _deduct(s, c);
  }

  static void _deduct(GameState s, Cost c) {
    for (final e in c.entries) {
      s.res[e.key] = s.res[e.key]! - e.value;
      if (ledgerOut != null) {
        ledgerOut![e.key] = (ledgerOut![e.key] ?? 0) + e.value;
      }
    }
  }

  static void grant(GameState s, Cost c) {
    for (final e in c.entries) {
      s.res[e.key] = s.res[e.key]! + e.value;
      if (ledgerIn != null) {
        ledgerIn![e.key] = (ledgerIn![e.key] ?? 0) + e.value;
      }
    }
  }

  static String describeCost(Cost c) =>
      c.entries.map((e) => '${e.value} ${resNames[e.key]}').join(', ');

  static String _missing(GameState s, Cost c) => c.entries
      .where((e) => s.res[e.key]! < e.value)
      .map((e) => '${resNames[e.key]} (thiếu ${e.value - s.res[e.key]!})')
      .join(', ');

  /// HP tối đa hiện tại của binh sĩ.
  static int fullHp(Soldier so) => deriveStats(so).maxHp;

  static ActionResult? _blocked(GameState s) => (s.gameOver || s.victory)
      ? const ActionResult.fail('Ván chơi đã kết thúc.')
      : null;

  // ---------- Công trình ----------

  static int level(GameState s, Building b) => s.buildings[b]!;

  static int rosterCap(GameState s) => 6 + 4 * level(s, Building.barracks);

  static int statCap(Soldier s) => 10 + 2 * s.level;

  static Cost? upgradeCost(GameState s, Building b) {
    final l = level(s, b);
    return l >= GameState.maxBuildingLevel ? null : upgradeCosts[l + 1];
  }

  /// Nâng cấp một công trình cấp bậc. Doanh trại cấp 0 chưa được xây nên không nâng cấp được: phải
  /// xây (đặt vào trại) bằng [buildFacility]. Quán rượu/Lò rèn (thành phố) giữ nguyên hành vi cũ.
  static ActionResult upgradeBuilding(GameState s, Building b) {
    final blocked = _blocked(s);
    if (blocked != null) return blocked;
    if (b == Building.barracks && level(s, b) == 0) {
      return const ActionResult.fail('Hãy xây Doanh trại vào trại trước.');
    }
    final cost = upgradeCost(s, b);
    if (cost == null) {
      return ActionResult.fail('${buildingNames[b]} đã đạt cấp tối đa.');
    }
    if (!canAfford(s, cost)) {
      return ActionResult.fail('Không đủ: ${_missing(s, cost)}.');
    }
    spend(s, cost);
    s.buildings[b] = level(s, b) + 1;
    s.addLog('${buildingNames[b]} lên cấp ${level(s, b)}.');
    return ActionResult.ok('${buildingNames[b]} lên cấp ${level(s, b)}.');
  }

  // ---------- Tuyển mộ ----------

  static void refreshCandidates(GameState s) {
    s.candidates.clear();
    final n = 4 + level(s, Building.barracks);
    for (var i = 0; i < n; i++) {
      final r = rng(s);
      // Quán rượu chỉ có ứng viên cấp 1–[tavernMaxCandidateLevel] (giới hạn ở nơi sinh ứng viên,
      // không phụ thuộc UI). Anh hùng cấp cao hơn chỉ đến từ cơ chế khác.
      final lvl = (1 + (s.tier > 0 ? r.nextInt(s.tier + 1) : 0)).clamp(
        1,
        tavernMaxCandidateLevel,
      );
      s.candidates.add(generateSoldier(s, level: lvl));
    }
  }

  static int hireCost(Soldier c) =>
      25 + c.stats.values.fold(0, (a, b) => a + b) * 2 + c.level * 10;

  /// Chiêu mộ tại Quán rượu [vendorId]: phải đang ở thành phố của quán, quán là loại tavern và mở cửa;
  /// sau đó dùng đúng luật [hire] (một ứng viên, trừ vàng đúng một lần, không đổi gì khi thất bại).
  static ActionResult hireAtTavern(
    GameState s,
    String vendorId,
    int candidateId,
  ) {
    final v = vendorById(vendorId);
    final gate = _gate(s, v);
    if (gate != null) return gate;
    if (v!.kind != VendorKind.tavern) {
      return ActionResult.fail('${v.name} không chiêu mộ anh hùng.');
    }
    return hire(s, candidateId);
  }

  static ActionResult hire(GameState s, int candidateId) {
    final blocked = _blocked(s);
    if (blocked != null) return blocked;
    final i = s.candidates.indexWhere((c) => c.id == candidateId);
    if (i < 0) return const ActionResult.fail('Ứng viên không còn.');
    if (s.roster.length >= rosterCap(s)) {
      return const ActionResult.fail(
        'Doanh trại đã đầy. Hãy nâng cấp Doanh trại.',
      );
    }
    final c = s.candidates[i];
    final cost = {Res.coins: hireCost(c)};
    if (!canAfford(s, cost)) {
      return ActionResult.fail('Không đủ: ${_missing(s, cost)}.');
    }
    spend(s, cost);
    s.candidates.removeAt(i);
    s.soldiers.add(c);
    s.addLog('Tuyển ${c.name} (${roleNames[c.role]}).');
    return ActionResult.ok('${c.name} gia nhập quân đội.');
  }

  static ActionResult rename(GameState s, int id, String name) {
    final so = s.soldier(id);
    final n = name.trim();
    if (so == null || !so.alive) {
      return const ActionResult.fail('Không tìm thấy binh sĩ.');
    }
    if (n.isEmpty || n.length > 24) {
      return const ActionResult.fail('Tên phải dài 1-24 ký tự.');
    }
    so.name = n;
    return ActionResult.ok('Đã đổi tên thành $n.');
  }

  /// Sa thải binh sĩ đang phục vụ: gỡ khỏi quân đội và công trình, trả trang bị về kho (như [unequip],
  /// không mất/nhân đôi). KHÔNG phải tử trận: không tính [GameState.fallenTotal], không vào [GameState.fallen].
  /// Không hoàn tiền. Trận đánh được giải quyết nguyên tử trong luật nên không có binh sĩ "đang giao chiến".
  static ActionResult dismiss(GameState s, int id) {
    final blocked = _blocked(s);
    if (blocked != null) return blocked;
    final so = s.soldier(id);
    if (so == null || !so.alive) {
      return const ActionResult.fail('Không tìm thấy binh sĩ.');
    }
    for (final slot in Slot.values) {
      final item = so.equipped(slot);
      if (item != null) s.inventory[item] = (s.inventory[item] ?? 0) + 1;
    }
    for (final f in s.facilities) {
      f.assigned.remove(id);
    }
    s.soldiers.removeWhere((x) => x.id == id);
    s.addLog('${so.name} bị sa thải khỏi quân đội.');
    return ActionResult.ok('Đã sa thải ${so.name}.');
  }

  // ---------- Công trình trong trại: gán bằng kéo-thả, huấn luyện, chữa trị ----------

  static Facility? facilityById(GameState s, int id) {
    for (final f in s.facilities) {
      if (f.id == id) return f;
    }
    return null;
  }

  static Facility? facilityOf(GameState s, int soldierId) {
    for (final f in s.facilities) {
      if (f.assigned.contains(soldierId)) return f;
    }
    return null;
  }

  static bool takesAssignment(FacilityType t) =>
      facilityDefs[t]!.takesAssignment;

  /// Gán binh sĩ vào công trình (kéo-thả). Tự rút khỏi công trình cũ. Thông báo "Unit added" ở game gốc.
  static ActionResult assignToFacility(
    GameState s,
    int soldierId,
    int facilityId,
  ) {
    final blocked = _blocked(s);
    if (blocked != null) return blocked;
    final so = s.soldier(soldierId);
    final f = facilityById(s, facilityId);
    if (so == null || !so.alive) {
      return const ActionResult.fail('Không tìm thấy binh sĩ.');
    }
    if (f == null) return const ActionResult.fail('Công trình không tồn tại.');
    if (!takesAssignment(f.type)) {
      return ActionResult.fail('${facilityDefs[f.type]!.name} không nhận gán.');
    }
    if (f.assigned.contains(soldierId)) {
      return const ActionResult.fail('Binh sĩ đã ở công trình này.');
    }
    if (f.assigned.length >= f.slots) {
      return ActionResult.fail(
        '${facilityDefs[f.type]!.name} đã đầy (${f.slots}/${f.slots}).',
      );
    }
    final st = facilityDefs[f.type]!.trains;
    if (st != null && so.stats[st]! >= statCap(so)) {
      return ActionResult.fail(
        '${statNames[st]} đã đạt giới hạn cấp này (${statCap(so)}).',
      );
    }
    for (final other in s.facilities) {
      other.assigned.remove(soldierId);
    }
    f.assigned.add(soldierId);
    return ActionResult.ok('${so.name} vào ${facilityDefs[f.type]!.name}.');
  }

  // ---------- Quản lý công trình đã đặt: di chuyển, xóa, nâng cấp slot ----------

  /// Dời công trình [id] tới (x, y). Giữ nguyên id, cấp, binh sĩ được gán; chỉ đổi tọa độ, dùng đúng
  /// [checkPlacement] (bỏ qua chính nó) như luật xây. Vị trí sai thì không đổi gì.
  static ActionResult moveFacility(GameState s, int id, double x, double y) {
    final blocked = _blocked(s);
    if (blocked != null) return blocked;
    final f = facilityById(s, id);
    if (f == null) return const ActionResult.fail('Công trình không tồn tại.');
    final check = checkPlacement(s, f.type, x, y, ignoreId: id);
    if (!check.ok) return ActionResult.fail(check.message);
    f.x = x;
    f.y = y;
    return ActionResult.ok('Đã dời ${facilityDefs[f.type]!.name}.');
  }

  /// Lý do không xóa được công trình [f]; null nếu xóa được.
  static String? removeBlockReason(GameState s, Facility f) {
    if (f.type == FacilityType.barracks) {
      return 'Doanh trại quyết định quân số tối đa nên không thể xóa.';
    }
    if (f.type == FacilityType.storageChest &&
        inventoryCount(s) > inventoryCapacity(s) - chestInventoryBonus) {
      return 'Kho đồ đang chứa quá sức chứa còn lại nếu bỏ Hòm đồ này.';
    }
    return null;
  }

  /// Xóa công trình [id]. Binh sĩ đang được gán chỉ rời công trình (trở thành nhàn rỗi), không mất/nhân đôi.
  /// Không hoàn tiền (game chưa có quy tắc hoàn tiền).
  static ActionResult removeFacility(GameState s, int id) {
    final blocked = _blocked(s);
    if (blocked != null) return blocked;
    final f = facilityById(s, id);
    if (f == null) return const ActionResult.fail('Công trình không tồn tại.');
    final why = removeBlockReason(s, f);
    if (why != null) return ActionResult.fail(why);
    s.facilities.remove(f);
    final name = facilityDefs[f.type]!.name;
    s.addLog('Dỡ bỏ $name.');
    return ActionResult.ok('Đã xóa $name.');
  }

  /// Công trình nhận binh sĩ có nâng cấp slot được không (đúng 4 loại trong [facilityUpgradeCosts]; Doanh trại
  /// đi theo [upgradeBuilding]).
  static bool facilityUpgradable(Facility f) =>
      facilityUpgradeCosts.containsKey(f.type);

  /// Nâng cấp slot 3 → 6, đúng một lần.
  static ActionResult upgradeFacility(GameState s, int id) {
    final blocked = _blocked(s);
    if (blocked != null) return blocked;
    final f = facilityById(s, id);
    if (f == null) return const ActionResult.fail('Công trình không tồn tại.');
    final cost = facilityUpgradeCosts[f.type];
    if (cost == null) {
      return const ActionResult.fail('Công trình này không có nâng cấp slot.');
    }
    final name = facilityDefs[f.type]!.name;
    if (f.level >= Facility.maxLevel) {
      return ActionResult.fail('$name đã nâng cấp tối đa.');
    }
    if (!canAfford(s, cost)) {
      return ActionResult.fail('Không đủ: ${_missing(s, cost)}.');
    }
    spend(s, cost);
    f.level = Facility.maxLevel;
    s.addLog('$name nâng cấp lên ${f.slots} slot.');
    return ActionResult.ok('$name đã nâng cấp: ${f.slots} slot.');
  }

  // ---------- Bia mộ: hồi sinh ----------

  /// Binh sĩ đã tử trận (nguồn duy nhất: [GameState.fallen]); không có danh sách chết riêng.
  static ActionResult reviveSoldier(GameState s, int id) {
    final blocked = _blocked(s);
    if (blocked != null) return blocked;
    if (facilityCount(s, FacilityType.gravestone) == 0) {
      return const ActionResult.fail('Cần xây Bia mộ để hồi sinh.');
    }
    final so = s.soldier(id);
    if (so == null || so.status != SoldierStatus.dead) {
      return const ActionResult.fail('Binh sĩ này không ở trong Bia mộ.');
    }
    if (s.roster.length >= rosterCap(s)) {
      return const ActionResult.fail(
        'Quân đội đã đủ quân số tối đa. Nâng cấp Doanh trại để hồi sinh thêm.',
      );
    }
    final cost = {Res.coins: reviveCost(so)};
    if (!canAfford(s, cost)) {
      return ActionResult.fail('Không đủ: ${_missing(s, cost)}.');
    }
    spend(s, cost);
    so.status = SoldierStatus.active;
    so.hp = so.maxHp;
    s.addLog('${so.name} được hồi sinh.');
    return ActionResult.ok('${so.name} đã được hồi sinh.');
  }

  /// Đặt binh sĩ đứng tự do tại (x, y) trong Trại. Vị trí không hợp lệ thì không đổi gì. Nếu lính đang ở
  /// trong một công trình thì rời công trình đó (đứng ngoài đất trống).
  static ActionResult moveSoldier(
    GameState s,
    int soldierId,
    double x,
    double y,
  ) {
    final so = s.soldier(soldierId);
    if (so == null || !so.alive) {
      return const ActionResult.fail('Không tìm thấy binh sĩ.');
    }
    final check = CampLayout.checkSoldierSpot(s.facilities, x, y);
    if (!check.ok) {
      return ActionResult.fail(switch (check.issue) {
        CampPlacementIssue.outOfLand => 'Không thể đứng ngoài khu trại.',
        _ => 'Vị trí này bị chặn.',
      });
    }
    for (final f in s.facilities) {
      f.assigned.remove(soldierId);
    }
    so.campX = x;
    so.campY = y;
    return ActionResult.ok('${so.name} đã di chuyển.');
  }

  static ActionResult unassign(GameState s, int soldierId) {
    final so = s.soldier(soldierId);
    if (so == null) return const ActionResult.fail('Không tìm thấy binh sĩ.');
    var found = false;
    for (final f in s.facilities) {
      found |= f.assigned.remove(soldierId);
    }
    return found
        ? ActionResult.ok('${so.name} rời công trình.')
        : const ActionResult.fail('Binh sĩ không ở công trình nào.');
  }

  /// 12 vị trí tham chiếu (lưới 4 cột × 3 hàng) để gợi ý/tương thích; công trình có thể đặt TỰ DO ở mọi
  /// vị trí hợp lệ theo [CampLayout.check] (kéo thả). Chỉ số ở đây dùng cho các lối gọi theo ô.
  static const facilitySlots = CampLayout.referenceSlots;

  /// Tâm bếp lửa trang trí (chính giữa hàng giữa của vùng đất). Không phải công trình, nhưng là vật cản.
  static const campfireSpot = CampLayout.campfire;

  /// Kiểm tra duy nhất cho vị trí đặt [type] tại (x, y) (tọa độ chuẩn hóa của khung Trại). Giao diện tô
  /// xanh/đỏ và luật xây dựng ([buildFacilityAt]) đều dùng đúng hàm này.
  static CampPlacementCheck checkPlacement(
    GameState s,
    FacilityType type,
    double x,
    double y, {
    int? ignoreId,
  }) => CampLayout.check(
    ignoreId == null
        ? s.facilities
        : s.facilities.where((f) => f.id != ignoreId),
    type,
    x,
    y,
  );

  /// Vị trí hợp lệ gợi ý cho [type] (null nếu hết chỗ).
  static (double, double)? suggestPlacement(GameState s, FacilityType type) =>
      CampLayout.suggest(s.facilities, type);

  /// Các ô tham chiếu còn trống (hợp lệ) cho công trình thường.
  static List<int> freeSlotIndices(GameState s) => [
    for (var i = 0; i < facilitySlots.length; i++)
      if (CampLayout.check(
        s.facilities,
        FacilityType.meleeYard,
        facilitySlots[i].$1,
        facilitySlots[i].$2,
      ).ok)
        i,
  ];

  /// Xây MỘT công trình mới theo ô tham chiếu [slotIndex] (-1: vị trí gợi ý đầu tiên). Xem [buildFacilityAt].
  static ActionResult buildFacility(
    GameState s,
    FacilityType type,
    int slotIndex,
  ) {
    final pos = slotIndex >= 0 && slotIndex < facilitySlots.length
        ? facilitySlots[slotIndex]
        : (slotIndex == -1 ? suggestPlacement(s, type) : null);
    if (pos == null) {
      return const ActionResult.fail('Không còn vị trí hợp lệ.');
    }
    return buildFacilityAt(s, type, pos.$1, pos.$2);
  }

  /// Xây MỘT công trình mới tại (x, y).
  ///
  /// Mọi điều kiện được kiểm tra lại ở đây (không tin UI): giới hạn số lượng, vị trí hợp lệ
  /// ([CampLayout.check]: trong vùng đất, không chồng công trình/bếp lửa/khu cổng) và tài nguyên.
  /// Chỉ khi hợp lệ mới trừ tài nguyên và thêm instance; thất bại không đổi gì.
  /// Doanh trại: instance + cấp 1 (`buildings[barracks]`) được tạo cùng lúc; các cấp sau là
  /// [upgradeBuilding]. Hòm đồ không giới hạn số lượng và không tính vào [maxFacilities].
  static ActionResult buildFacilityAt(
    GameState s,
    FacilityType type,
    double x,
    double y,
  ) {
    final blocked = _blocked(s);
    if (blocked != null) return blocked;
    if (!buildableFacilities.contains(type)) {
      return const ActionResult.fail('Không thể xây công trình này.');
    }
    final def = facilityDefs[type]!;
    final max = def.maxCount;
    if ((max != null && facilityCount(s, type) >= max) ||
        (type == FacilityType.barracks && level(s, Building.barracks) > 0)) {
      return ActionResult.fail('${def.name} đã được xây (tối đa ${max ?? 1}).');
    }
    if (def.usesSlot && slotFacilityCount(s) >= maxFacilities) {
      return const ActionResult.fail('Trại đã đạt số công trình tối đa.');
    }
    final check = checkPlacement(s, type, x, y);
    if (!check.ok) return ActionResult.fail(check.message);
    if (!canAfford(s, def.cost)) {
      return ActionResult.fail('Không đủ: ${_missing(s, def.cost)}.');
    }
    spend(s, def.cost);
    s.facilities.add(Facility(id: s.nextFacilityId++, type: type, x: x, y: y));
    if (type == FacilityType.barracks) s.buildings[Building.barracks] = 1;
    s.addLog('Xây ${def.name}.');
    return ActionResult.ok('Đã xây ${def.name}.');
  }

  /// Sửa bố cục của save cũ: công trình nằm ngoài vùng đất mới hoặc chồng lên cái khác/bếp lửa được dời tới vị
  /// trí hợp lệ gần nhất (theo thứ tự id, deterministic). Công trình đã hợp lệ giữ nguyên tọa độ. Idempotent;
  /// true nếu có thay đổi.
  static bool repairCampLayout(GameState s) {
    var changed = false;
    final accepted = <Facility>[];
    final ordered = [...s.facilities]..sort((a, b) => a.id.compareTo(b.id));
    for (final f in ordered) {
      if (CampLayout.check(accepted, f.type, f.x, f.y).ok) {
        accepted.add(f);
        continue;
      }
      final p = _nearestValid(accepted, f);
      if (p == null) {
        accepted.add(f);
        continue;
      }
      final i = s.facilities.indexOf(f);
      final moved = Facility(
        id: f.id,
        type: f.type,
        x: p.$1,
        y: p.$2,
        assigned: f.assigned,
        level: f.level,
      );
      s.facilities[i] = moved;
      accepted.add(moved);
      changed = true;
    }
    return changed;
  }

  static (double, double)? _nearestValid(List<Facility> accepted, Facility f) {
    (double, double)? best;
    var bestD = double.infinity;
    const l = CampLayout.land;
    for (var y = l.top; y <= l.bottom; y += 0.01) {
      for (var x = l.left; x <= l.right; x += 0.01) {
        if (!CampLayout.check(accepted, f.type, x, y).ok) continue;
        final dx = (x - f.x) * CampLayout.aspect, dy = y - f.y;
        final d = dx * dx + dy * dy;
        if (d < bestD) {
          bestD = d;
          best = (x, y);
        }
      }
    }
    return best;
  }

  /// Save cũ/test có Doanh trại cấp > 0 nhưng chưa có instance: tạo instance (miễn phí, không đổi cấp)
  /// ở ô trống đầu tiên để trại hiển thị đúng trạng thái. Idempotent; true nếu có thay đổi.
  static bool syncBarracksInstance(GameState s) {
    if (level(s, Building.barracks) <= 0 ||
        facilityCount(s, FacilityType.barracks) > 0) {
      return false;
    }
    final pos = suggestPlacement(s, FacilityType.barracks);
    if (pos == null) return false;
    s.facilities.add(
      Facility(
        id: s.nextFacilityId++,
        type: FacilityType.barracks,
        x: pos.$1,
        y: pos.$2,
      ),
    );
    return true;
  }

  /// Trạng thái xây dựng của một mục trong [campBuildings], dùng chung cho mọi giao diện.
  /// Doanh trại cấp 0 là hành động XÂY (cần vị trí); cấp ≥ 1 là NÂNG CẤP (không cần vị trí).
  static CampBuildStatus campStatus(GameState s, CampBuildingDef d) {
    final b = d.building;
    if (b != null && level(s, b) > 0) {
      final lvl = level(s, b);
      final cost = upgradeCost(s, b);
      String? why;
      if (cost == null) {
        why = 'Cấp tối đa';
      } else if (!canAfford(s, cost)) {
        why = 'Không đủ tài nguyên';
      }
      return CampBuildStatus(
        def: d,
        count: 1,
        level: lvl,
        cost: cost,
        reason: why,
        needsPlacement: false,
      );
    }
    final t = d.facility!;
    final def = facilityDefs[t]!;
    final count = facilityCount(s, t);
    final max = def.maxCount;
    String? why;
    if (max != null && count >= max) {
      why = 'Đã xây';
    } else if (def.usesSlot &&
        (slotFacilityCount(s) >= maxFacilities ||
            suggestPlacement(s, t) == null)) {
      why = 'Hết ô trống';
    } else if (!canAfford(s, def.cost)) {
      why = 'Không đủ tài nguyên';
    }
    return CampBuildStatus(
      def: d,
      count: count,
      level: 0,
      cost: max != null && count >= max ? null : def.cost,
      reason: why,
      needsPlacement: true,
    );
  }

  /// Hỗ trợ cho mô phỏng/test (không dùng cho UI): xây/nâng cấp một mục catalog, tự chọn vị trí đầu tiên.
  /// UI phải đi qua luồng chọn vị trí của controller (`startPlacement` → `confirmPlacement`).
  static ActionResult buildCamp(GameState s, CampBuildingDef d) {
    final st = campStatus(s, d);
    if (!st.needsPlacement) return upgradeBuilding(s, d.building!);
    return buildFacility(s, d.facility!, -1);
  }

  /// Trả về số cấp tăng.
  static int addXp(Soldier so, int amount) {
    final gain = so.trait == TraitId.quickLearner
        ? (amount * 1.3).round()
        : amount;
    so.xp += gain;
    var ups = 0;
    while (so.xp >= xpForNext(so.level) && so.level < maxSoldierLevel) {
      so.xp -= xpForNext(so.level);
      so.level++;
      ups++;
      final main = switch (so.role) {
        Role.spearman => [Stat.con, Stat.str],
        Role.archer => [Stat.dex, Stat.str],
        Role.cavalry => [Stat.str, Stat.dex],
      };
      final st = main[so.level % 2];
      so.stats[st] = so.stats[st]! + 1;
    }
    return ups;
  }

  // ---------- Kỹ năng & tài năng ----------

  /// Học (hoặc nâng) một kỹ năng bằng điểm kỹ năng. Điểm còn lại suy ra từ cấp, không lưu riêng.
  static ActionResult learnSkill(GameState s, int soldierId, String skillId) {
    final blocked = _blocked(s);
    if (blocked != null) return blocked;
    final so = s.soldier(soldierId);
    final d = skillDefs[skillId];
    if (so == null || !so.alive || d == null) {
      return const ActionResult.fail('Dữ liệu không hợp lệ.');
    }
    final cur = so.skills[skillId] ?? 0;
    if (cur >= d.maxLevel) {
      return ActionResult.fail('${d.name} đã đạt cấp tối đa.');
    }
    if (so.level < d.requiredLevel) {
      return ActionResult.fail('${d.name} cần cấp ${d.requiredLevel}.');
    }
    final cost = d.costOf(cur + 1);
    if (skillPointsLeft(so) < cost) {
      return ActionResult.fail('Không đủ điểm kỹ năng (cần $cost).');
    }
    so.skills[skillId] = cur + 1;
    so.hp = min(so.hp, so.maxHp);
    return ActionResult.ok('${so.name} học ${d.name} cấp ${cur + 1}.');
  }

  /// Chọn tài năng cho một mốc cấp. Mỗi mốc chọn một lần, không đổi được.
  static ActionResult chooseTalent(
    GameState s,
    int soldierId,
    String talentId,
  ) {
    final blocked = _blocked(s);
    if (blocked != null) return blocked;
    final so = s.soldier(soldierId);
    final t = talentDefs[talentId];
    if (so == null || !so.alive || t == null) {
      return const ActionResult.fail('Dữ liệu không hợp lệ.');
    }
    if (so.level < talentTierLevels[t.tier]) {
      return ActionResult.fail('Cần cấp ${talentTierLevels[t.tier]}.');
    }
    if (!openTalentTiers(so).contains(t.tier)) {
      return const ActionResult.fail('Mốc tài năng này đã được chọn.');
    }
    so.talents.add(talentId);
    so.hp = min(so.hp, so.maxHp);
    return ActionResult.ok('${so.name} có tài năng ${t.name}.');
  }

  // ---------- Trang bị ----------

  static ActionResult equip(GameState s, int id, String itemId) {
    final blocked = _blocked(s);
    if (blocked != null) return blocked;
    final so = s.soldier(id);
    final item = itemDefs[itemId];
    if (so == null || !so.alive || item == null) {
      return const ActionResult.fail('Dữ liệu không hợp lệ.');
    }
    if ((s.inventory[itemId] ?? 0) <= 0) {
      return const ActionResult.fail('Vật phẩm không còn trong kho.');
    }
    final problem = equipProblem(so, item);
    if (problem != null) return ActionResult.fail(problem);
    final old = so.equipped(item.slot);
    s.inventory[itemId] = s.inventory[itemId]! - 1;
    if (old != null) s.inventory[old] = (s.inventory[old] ?? 0) + 1;
    so.setEquipped(item.slot, itemId);
    so.hp = min(so.hp, so.maxHp);
    return ActionResult.ok('${so.name} trang bị ${item.name}.');
  }

  static ActionResult unequip(GameState s, int id, Slot slot) {
    final so = s.soldier(id);
    if (so == null || !so.alive) {
      return const ActionResult.fail('Không tìm thấy binh sĩ.');
    }
    final old = so.equipped(slot);
    if (old == null) return const ActionResult.fail('Ô trống.');
    so.setEquipped(slot, null);
    so.hp = min(so.hp, so.maxHp);
    s.inventory[old] = (s.inventory[old] ?? 0) + 1;
    return ActionResult.ok('Đã tháo ${itemDefs[old]!.name}.');
  }

  static int itemPrice(GameState s, ItemDef it) {
    final disc = 1 - 0.05 * (level(s, Building.smithy) - 1).clamp(0, 2);
    return (it.price * disc).round();
  }

  // ---------- Thành phố và giao dịch ----------

  static int inventoryCount(GameState s) =>
      s.inventory.values.fold(0, (a, b) => a + b);

  /// Sức chứa kho đồ: cơ bản theo Doanh trại + mỗi Hòm đồ thực tế đang có (tính lại từ state, không lưu số dư).
  static int inventoryCapacity(GameState s) =>
      inventoryCapacityFor(level(s, Building.barracks)) +
      chestCount(s) * chestInventoryBonus;

  static int facilityCount(GameState s, FacilityType t) =>
      s.facilities.where((f) => f.type == t).length;

  static int chestCount(GameState s) =>
      facilityCount(s, FacilityType.storageChest);

  /// Số công trình đang chiếm ô (không tính Hòm đồ).
  static int slotFacilityCount(GameState s) =>
      s.facilities.where((f) => facilityDefs[f.type]!.usesSlot).length;

  static bool vendorOpen(GameState s, VendorDef v) => s.tier >= v.unlockTier;

  /// Hash ổn định (không phụ thuộc `String.hashCode`, vốn có thể khác giữa các lần chạy).
  static int _stableHash(String x) {
    var h = 17;
    for (final u in x.codeUnits) {
      h = (h * 31 + u) & 0x3fffffff;
    }
    return h;
  }

  /// Hàng của người bán trong ngày hiện tại. Xác định hoàn toàn theo (seed, ngày, người bán):
  /// cùng ngày luôn ra cùng một danh sách dù mở bao nhiêu lần, load save, hay dựng lại màn hình.
  /// * Lò rèn: chọn [smithyDailyPicks] món từ kho tối đa, loại phẩm cấp 6;
  /// * Chợ: toàn bộ tồn kho cấu hình (đặt lại mỗi ngày);
  /// * Quán rượu: không có hàng.
  static ShopStock dailyStock(GameState s, VendorDef v) {
    final items = <String, int>{};
    if (v.kind == VendorKind.smithy) {
      final pool = [
        for (final id in (v.items.keys.toList()..sort()))
          if (smithySellsGrade(itemDefs[id]!.grade)) id,
      ];
      final r = Random(
        (s.seed * 1000003 + s.day * 7919 + _stableHash(v.id)) & 0x7fffffff,
      );
      pool.shuffle(r);
      for (final id in pool.take(smithyDailyPicks)) {
        items[id] = v.items[id]!;
      }
    }
    return ShopStock(
      items: items,
      resources: v.kind == VendorKind.market ? Map.of(v.resources) : {},
      lastRestock: s.day,
    );
  }

  /// Xem tồn kho mà không ghi vào state (dùng cho kiểm tra và hiển thị).
  /// Tồn kho đã lưu chỉ có hiệu lực trong đúng ngày của nó; sang ngày mới dùng [dailyStock].
  static ShopStock peekStock(GameState s, VendorDef v) {
    final saved = s.shops[v.id];
    return saved != null && saved.lastRestock == s.day
        ? saved
        : dailyStock(s, v);
  }

  /// Tồn kho để ghi (commit giao dịch); tạo từ [dailyStock] ở lần ghi đầu tiên trong ngày.
  static ShopStock stockOf(GameState s, VendorDef v) {
    final saved = s.shops[v.id];
    if (saved != null && saved.lastRestock == s.day) return saved;
    return s.shops[v.id] = dailyStock(s, v);
  }

  /// Gọi khi qua ngày: bỏ tồn kho của ngày cũ (và của người bán không còn tồn tại). Hàng mới được sinh
  /// xác định theo [dailyStock] khi cần, nên save/load không tạo lại hàng ngẫu nhiên.
  static void restockShops(GameState s) {
    s.shops.removeWhere(
      (id, st) => st.lastRestock != s.day || vendorById(id) == null,
    );
  }

  static int buyPrice(VendorDef v, String itemId) =>
      max(1, (itemDefs[itemId]!.price * v.priceMult).round());

  /// Giá người bán trả khi mua lại: không phụ thuộc người bán và luôn thấp hơn mọi giá bán ra.
  static int sellPrice(String itemId) =>
      max(1, (itemDefs[itemId]!.price * sellRatio).round());

  static int resourceBuyPrice(VendorDef v, Res r) =>
      max(1, (resourceLotPrice[r]! * v.priceMult).round());

  static int resourceSellPrice(Res r) =>
      max(1, (resourceLotPrice[r]! * sellRatio).round());

  /// Người bán mua lại loại đồ nào: chỉ Lò rèn mua trang bị (mọi loại, kể cả phụ kiện có từ trước).
  static bool buysItem(VendorDef v, ItemDef it) => v.kind == VendorKind.smithy;

  static ActionResult? _gate(GameState s, VendorDef? v) {
    final blocked = _blocked(s);
    if (blocked != null) return blocked;
    if (v == null) return const ActionResult.fail('Người bán không tồn tại.');
    if (s.visiting != v.cityId) {
      return ActionResult.fail(
        'Bạn không ở ${locationById(v.cityId)?.name ?? 'thành phố này'}.',
      );
    }
    if (!vendorOpen(s, v)) {
      return ActionResult.fail(
        '${v.name} chưa mở cửa với bạn (cần hoàn thành ${const [0, 3, 6, 10][v.unlockTier]} nhiệm vụ).',
      );
    }
    return null;
  }

  /// Vào thị trấn [townId] khi nhân vật đã đi tới đủ gần. Không dịch chuyển nhân vật.
  static ActionResult enterTown(GameState s, String townId) {
    final town = worldMap.townById(townId);
    final loc = locationById(townId);
    if (town == null || loc == null) {
      return const ActionResult.fail('Không có thị trấn này.');
    }
    if (!regionUnlocked(s, regionById(loc.regionId))) {
      return ActionResult.fail(
        '${loc.name} chưa mở cửa với bạn: hãy hoàn thành thêm nhiệm vụ.',
      );
    }
    if (town.position.distanceTo(s.hero.position) > town.enterRadius) {
      return const ActionResult.fail('Bạn còn quá xa thị trấn.');
    }
    s.visiting = townId;
    for (final m in activeAt(s, townId)) {
      final t = templateById(m.templateId);
      if (t.kind == MissionKind.visit && m.progress == 0) m.progress = 1;
    }
    final done = settleReadyAt(s, townId);
    return ActionResult.ok(
      done.isEmpty ? 'Vào ${loc.name}.' : 'Vào ${loc.name}. ${done.join(' ')}',
    );
  }

  static ActionResult leaveCity(GameState s) {
    if (s.visiting == null) {
      return const ActionResult.fail('Bạn không ở thành phố.');
    }
    final name = locationById(s.visiting!)?.name ?? '';
    s.visiting = null;
    return ActionResult.ok('Rời $name.');
  }

  static ActionResult buyFromVendor(
    GameState s,
    String vendorId,
    String itemId,
    int qty,
  ) {
    final v = vendorById(vendorId);
    final gate = _gate(s, v);
    if (gate != null) return gate;
    final it = itemDefs[itemId];
    if (v!.kind != VendorKind.smithy) {
      return ActionResult.fail('${v.name} không bán trang bị.');
    }
    if (it == null || !peekStock(s, v).items.containsKey(itemId)) {
      return const ActionResult.fail('Người bán không có mặt hàng này.');
    }
    if (!smithySellsGrade(it.grade)) {
      return ActionResult.fail(
        'Trang bị phẩm cấp ${it.grade} không bán ở Lò rèn.',
      );
    }
    if (qty < 1 || qty > 99) {
      return const ActionResult.fail('Số lượng không hợp lệ.');
    }
    final have = peekStock(s, v).items[itemId] ?? 0;
    if (have <= 0) return ActionResult.fail('${it.name} đã hết hàng.');
    if (qty > have) return ActionResult.fail('Chỉ còn $have ${it.name}.');
    if (inventoryCount(s) + qty > inventoryCapacity(s)) {
      return ActionResult.fail(
        'Kho đồ đầy (${inventoryCount(s)}/${inventoryCapacity(s)}). Nâng cấp Doanh trại hoặc bán bớt.',
      );
    }
    final cost = {Res.coins: buyPrice(v, itemId) * qty};
    if (!canAfford(s, cost)) {
      return ActionResult.fail('Không đủ: ${_missing(s, cost)}.');
    }
    spend(s, cost);
    stockOf(s, v).items[itemId] = have - qty;
    s.inventory[itemId] = (s.inventory[itemId] ?? 0) + qty;
    s.tradeCount++;
    return ActionResult.ok(
      'Đã mua $qty ${it.name} với ${cost[Res.coins]} vàng.',
    );
  }

  /// Mua rồi trang bị trong một giao dịch: nếu không trang bị được thì không mua gì.
  static ActionResult buyAndEquip(
    GameState s,
    String vendorId,
    String itemId,
    int soldierId,
  ) {
    final so = s.soldier(soldierId);
    final it = itemDefs[itemId];
    if (so == null || !so.alive || it == null) {
      return const ActionResult.fail('Dữ liệu không hợp lệ.');
    }
    final problem = equipProblem(so, it);
    if (problem != null) return ActionResult.fail(problem);
    final bought = buyFromVendor(s, vendorId, itemId, 1);
    if (!bought.ok) return bought;
    final eq = equip(s, soldierId, itemId);
    return eq.ok ? ActionResult.ok('${bought.message} ${eq.message}') : eq;
  }

  static ActionResult sellToVendor(
    GameState s,
    String vendorId,
    String itemId,
    int qty,
  ) {
    final v = vendorById(vendorId);
    final gate = _gate(s, v);
    if (gate != null) return gate;
    final it = itemDefs[itemId];
    if (it == null) return const ActionResult.fail('Vật phẩm không tồn tại.');
    if (!buysItem(v!, it)) {
      return ActionResult.fail('${v.name} không mua trang bị.');
    }
    if (qty < 1 || qty > 99) {
      return const ActionResult.fail('Số lượng không hợp lệ.');
    }
    final have = s.inventory[itemId] ?? 0;
    if (have < qty) {
      return ActionResult.fail(
        'Bạn chỉ có $have ${it.name} trong kho (đồ đang mặc không bán được).',
      );
    }
    final gain = sellPrice(itemId) * qty;
    s.inventory[itemId] = have - qty;
    grant(s, {Res.coins: gain});
    if (v.items.containsKey(itemId)) {
      final st = stockOf(s, v);
      st.items[itemId] = min(
        v.items[itemId]! * 2,
        (st.items[itemId] ?? 0) + qty,
      );
    }
    s.tradeCount++;
    return ActionResult.ok('Đã bán $qty ${it.name}, nhận $gain vàng.');
  }

  static ActionResult buyResourceLots(
    GameState s,
    String vendorId,
    Res res,
    int lots,
  ) {
    final v = vendorById(vendorId);
    final gate = _gate(s, v);
    if (gate != null) return gate;
    if (v!.kind != VendorKind.market ||
        res == Res.coins ||
        !v.resources.containsKey(res)) {
      return ActionResult.fail(
        '${v.name} không bán ${resNames[res]!.toLowerCase()}.',
      );
    }
    if (lots < 1 || lots > 99) {
      return const ActionResult.fail('Số lượng không hợp lệ.');
    }
    final have = peekStock(s, v).resources[res] ?? 0;
    if (have < lots) {
      return ActionResult.fail(
        have == 0
            ? '${resNames[res]} đã hết hàng.'
            : 'Chỉ còn $have lô ${resNames[res]!.toLowerCase()}.',
      );
    }
    final cost = {Res.coins: resourceBuyPrice(v, res) * lots};
    if (!canAfford(s, cost)) {
      return ActionResult.fail('Không đủ: ${_missing(s, cost)}.');
    }
    spend(s, cost);
    stockOf(s, v).resources[res] = have - lots;
    grant(s, {res: lots * resourceLotSize});
    s.tradeCount++;
    return ActionResult.ok(
      'Đã mua ${lots * resourceLotSize} ${resNames[res]} với ${cost[Res.coins]} vàng.',
    );
  }

  static ActionResult sellResourceLots(
    GameState s,
    String vendorId,
    Res res,
    int lots,
  ) {
    final v = vendorById(vendorId);
    final gate = _gate(s, v);
    if (gate != null) return gate;
    if (v!.kind != VendorKind.market ||
        res == Res.coins ||
        !v.resources.containsKey(res)) {
      return ActionResult.fail(
        '${v.name} không mua ${resNames[res]!.toLowerCase()}.',
      );
    }
    if (lots < 1 || lots > 99) {
      return const ActionResult.fail('Số lượng không hợp lệ.');
    }
    final units = lots * resourceLotSize;
    if (s.res[res]! < units) {
      return ActionResult.fail(
        'Bạn chỉ có ${s.res[res]} ${resNames[res]!.toLowerCase()}.',
      );
    }
    final room = v.resources[res]! * 2 - (peekStock(s, v).resources[res] ?? 0);
    if (lots > room) {
      return ActionResult.fail(
        'Người bán không còn chỗ chứa thêm ${resNames[res]!.toLowerCase()}.',
      );
    }
    final gain = resourceSellPrice(res) * lots;
    _deduct(s, {res: units});
    final st = stockOf(s, v);
    st.resources[res] = (st.resources[res] ?? 0) + lots;
    grant(s, {Res.coins: gain});
    s.tradeCount++;
    return ActionResult.ok('Đã bán $units ${resNames[res]}, nhận $gain vàng.');
  }

  static ActionResult buy(GameState s, String itemId) {
    final blocked = _blocked(s);
    if (blocked != null) return blocked;
    final it = itemDefs[itemId];
    if (it == null) return const ActionResult.fail('Vật phẩm không tồn tại.');
    if (it.tier > level(s, Building.smithy)) {
      return ActionResult.fail('Cần Lò rèn cấp ${it.tier}.');
    }
    if (inventoryCount(s) >= inventoryCapacity(s)) {
      return ActionResult.fail(
        'Kho đồ đầy (${inventoryCount(s)}/${inventoryCapacity(s)}).',
      );
    }
    final cost = {Res.coins: itemPrice(s, it)};
    if (!canAfford(s, cost)) {
      return ActionResult.fail('Không đủ: ${_missing(s, cost)}.');
    }
    spend(s, cost);
    s.inventory[itemId] = (s.inventory[itemId] ?? 0) + 1;
    return ActionResult.ok('Đã mua ${it.name}.');
  }

  // ---------- Nhiệm vụ ----------

  static List<Mission> byStatus(GameState s, MissionStatus st) => [
    for (final m in s.missions)
      if (m.status == st) m,
  ];

  static bool _available(GameState s, MissionTemplate t) {
    if (s.tier < t.tierMin || s.tier > t.tierMax) return false;
    if (s.missions.any(
      (m) => m.templateId == t.id && m.status != MissionStatus.failed,
    )) {
      return false;
    }
    if (t.kind == MissionKind.clear && s.cleared.contains(t.locId)) {
      return false;
    }
    if (t.kind == MissionKind.explore) {
      final left = locations.where(
        (l) =>
            l.regionId == t.regionId &&
            l.kind == LocKind.ruins &&
            !s.explored.contains(l.id),
      );
      if (left.isEmpty) return false;
    }
    return true;
  }

  static void fillBoard(GameState s) {
    s.missions.removeWhere(
      (m) =>
          m.status == MissionStatus.failed ||
          (m.status == MissionStatus.completed && s.missions.length > 12),
    );
    while (byStatus(s, MissionStatus.offered).length < 3) {
      final pool = missionTemplates.where((t) => _available(s, t)).toList();
      if (pool.isEmpty) break;
      final t = pool[rng(s).nextInt(pool.length)];
      s.missions.add(Mission(id: s.nextMissionId++, templateId: t.id));
    }
  }

  /// Địa điểm mục tiêu trên bản đồ của nhiệm vụ [t] vừa nhận tại [giver]:
  /// diệt trại/đến thị trấn → địa điểm của mẫu; khám phá → tàn tích chưa khám phá gần nhất trong vùng;
  /// nộp tài nguyên/luyện binh/trang bị → quay lại thành trấn đã nhận để báo cáo.
  static String? objectiveFor(GameState s, MissionTemplate t, String? giver) {
    switch (t.kind) {
      case MissionKind.clear || MissionKind.visit:
        return t.locId;
      case MissionKind.explore:
        for (final l in locations) {
          if (l.regionId == t.regionId &&
              l.kind == LocKind.ruins &&
              !s.explored.contains(l.id) &&
              worldMap.placements.containsKey(l.id)) {
            return l.id;
          }
        }
        return null;
      case MissionKind.deliver ||
          MissionKind.levelCount ||
          MissionKind.gearCount:
        return giver;
    }
  }

  /// Chỉ nhận được khi nhân vật đang ở trong một thành trấn (đã vào thành, `visiting` khác null).
  static ActionResult acceptMission(GameState s, int id) {
    final blocked = _blocked(s);
    if (blocked != null) return blocked;
    final town = s.visiting == null ? null : locationById(s.visiting!);
    if (town == null || town.kind != LocKind.city) {
      return const ActionResult.fail(
        'Chỉ nhận nhiệm vụ khi đang ở trong thành trấn.',
      );
    }
    final m = s.missions.where((m) => m.id == id).firstOrNull;
    if (m == null || m.status != MissionStatus.offered) {
      return const ActionResult.fail('Nhiệm vụ không còn.');
    }
    if (byStatus(s, MissionStatus.active).length >= 3) {
      return const ActionResult.fail('Chỉ nhận tối đa 3 nhiệm vụ cùng lúc.');
    }
    final t = templateById(m.templateId);
    m.status = MissionStatus.active;
    m.deadline = s.day + t.days;
    m.giverTown = town.id;
    m.targetId = objectiveFor(s, t, town.id);
    m.progress = (t.kind == MissionKind.clear && s.cleared.contains(t.locId))
        ? 1
        : 0;
    s.addLog('Nhận nhiệm vụ: ${t.title} (hạn ngày ${m.deadline}).');
    return ActionResult.ok('Đã nhận: ${t.title}. Hạn ngày ${m.deadline}.');
  }

  /// Nhiệm vụ đang được theo dõi (mũi tên chỉ hướng): đang làm, chưa hết hạn, có mục tiêu đặt được
  /// trên bản đồ; ưu tiên hạn gần nhất, hòa thì nhiệm vụ nhận trước (id nhỏ hơn).
  static Mission? trackedMission(GameState s) {
    Mission? best;
    for (final m in byStatus(s, MissionStatus.active)) {
      if (s.day > m.deadline || m.targetId == null) continue;
      if (worldMap.positionOf(m.targetId!) == null) continue;
      if (best == null ||
          m.deadline < best.deadline ||
          (m.deadline == best.deadline && m.id < best.id)) {
        best = m;
      }
    }
    return best;
  }

  /// Nhiệm vụ đang thực hiện còn hạn có mục tiêu tại địa điểm [locId].
  static List<Mission> activeAt(GameState s, String locId) => [
    for (final m in byStatus(s, MissionStatus.active))
      if (m.targetId == locId && s.day <= m.deadline) m,
  ];

  static ActionResult abandonMission(GameState s, int id) {
    final m = s.missions.where((m) => m.id == id).firstOrNull;
    if (m == null || m.status != MissionStatus.active) {
      return const ActionResult.fail('Nhiệm vụ không hoạt động.');
    }
    final t = templateById(m.templateId);
    final pen = (t.penaltySat / 2).ceil();
    m.status = MissionStatus.failed;
    _addSat(s, -pen);
    s.addLog('Bỏ nhiệm vụ ${t.title}: nhà vua giảm $pen hài lòng.');
    fillBoard(s);
    return ActionResult.ok('Đã bỏ nhiệm vụ. Hài lòng của nhà vua -$pen.');
  }

  /// Cộng/trừ Thánh ý (giới hạn 0..100). Điểm duy nhất thay đổi nguồn dữ liệu của thanh Thánh ý.
  static void addSacredWill(GameState s, int d) => _addSat(s, d);

  static void _addSat(GameState s, int d) =>
      s.kingSatisfaction = (s.kingSatisfaction + d).clamp(0, 100);

  static int missionCurrent(GameState s, Mission m) {
    final t = templateById(m.templateId);
    return switch (t.kind) {
      MissionKind.clear ||
      MissionKind.explore ||
      MissionKind.visit => m.progress,
      MissionKind.deliver => s.res[t.res!]!,
      MissionKind.levelCount =>
        s.roster.where((x) => x.level >= t.level).length,
      MissionKind.gearCount =>
        s.roster
            .where((x) => (itemDefs[x.armorId]?.defense ?? 0) >= t.armorDef)
            .length,
    };
  }

  static int missionTarget(MissionTemplate t) => switch (t.kind) {
    MissionKind.clear || MissionKind.visit => 1,
    _ => t.amount,
  };

  static bool missionReady(GameState s, Mission m) =>
      m.status == MissionStatus.active &&
      missionCurrent(s, m) >= missionTarget(templateById(m.templateId));

  static ActionResult completeMission(GameState s, int id) {
    final blocked = _blocked(s);
    if (blocked != null) return blocked;
    final m = s.missions.where((m) => m.id == id).firstOrNull;
    if (m == null || m.status != MissionStatus.active) {
      return const ActionResult.fail('Nhiệm vụ không hoạt động.');
    }
    if (s.day > m.deadline) {
      return const ActionResult.fail('Nhiệm vụ đã hết hạn.');
    }
    if (!missionReady(s, m)) {
      return const ActionResult.fail('Chưa đạt mục tiêu.');
    }
    return _settle(s, m);
  }

  /// Chốt hoàn thành và trao thưởng ĐÚNG MỘT LẦN (chốt bằng `status` + `rewarded`). Mọi thay đổi state
  /// diễn ra sau khi mọi điều kiện đã kiểm tra, nên không có trạng thái trao dở dang.
  static ActionResult _settle(GameState s, Mission m) {
    if (m.rewarded || m.status != MissionStatus.active) {
      return const ActionResult.fail('Nhiệm vụ đã được trao thưởng.');
    }
    final t = templateById(m.templateId);
    if (t.kind == MissionKind.deliver) {
      spend(s, {t.res!: t.amount});
    }
    m.rewarded = true;
    m.status = MissionStatus.completed;
    m.targetId = null;
    grant(s, t.rewardRes);
    if (t.rewardItem != null) {
      s.inventory[t.rewardItem!] = (s.inventory[t.rewardItem!] ?? 0) + 1;
    }
    if (t.rewardSat > 0) addSacredWill(s, t.rewardSat);
    final exp = <String>[];
    if (t.rewardExp > 0) {
      final ids = [
        for (final id in m.squad)
          if (s.soldier(id)?.alive == true) id,
      ];
      final who = ids.isEmpty
          ? s.roster
          : [for (final id in ids) s.soldier(id)!];
      for (final so in who) {
        final ups = addXp(so, t.rewardExp);
        if (ups > 0) exp.add('${so.name} lên cấp ${so.level}');
      }
    }
    s.missionsCompleted++;
    s.addLog('Hoàn thành ${t.title}.');
    if (t.isFinal) {
      s.victory = true;
      return const ActionResult.ok(
        'Cuộc nổi loạn đã bị dập tắt. Bạn chiến thắng!',
      );
    }
    fillBoard(s);
    final parts = <String>[
      if (t.rewardRes.isNotEmpty) describeCost(t.rewardRes),
      if (t.rewardItem != null) itemDefs[t.rewardItem]!.name,
      if (t.rewardExp > 0) '${t.rewardExp} EXP/người',
      if (t.rewardSat > 0) 'Thánh ý +${t.rewardSat}',
    ];
    return ActionResult.ok(
      'Hoàn thành ${t.title}. Nhận ${parts.join(', ')}.'
      '${exp.isEmpty ? '' : ' ${exp.join('; ')}.'}',
    );
  }

  /// Tự hoàn thành các nhiệm vụ đang làm đã đủ điều kiện và có mục tiêu tại [locId]
  /// (đến nơi báo cáo, thắng trận, khám phá xong). Trả về thông báo của từng nhiệm vụ đã chốt.
  static List<String> settleReadyAt(GameState s, String locId) {
    final out = <String>[];
    for (final m in activeAt(s, locId)) {
      if (!missionReady(s, m)) continue;
      final r = _settle(s, m);
      if (r.ok) out.add(r.message);
    }
    return out;
  }

  // ---------- Qua ngày ----------

  static DayReport tickDay(GameState s) {
    final lines = <String>[];
    final factor = 0.5 + s.kingSatisfaction / 100;
    final stipend = {
      Res.food: (kingStipendFood * factor).round(),
      Res.coins: (kingStipendCoins * factor).round(),
    };
    final relief = s.kingSatisfaction > 0 ? reliefFor(s.roster.length) : 0;
    if (relief > 0) {
      stipend[Res.coins] = stipend[Res.coins]! + relief;
      lines.add(
        'Trợ cấp khẩn của nhà vua: +$relief vàng để dựng lại quân đội.',
      );
    }
    grant(s, stipend);
    // Qua một ngày = nghỉ ngơi: thể lực của nhân vật hồi đầy (cơ chế hồi phục duy nhất).
    s.hero.stamina = TerrainRules.maxStamina;

    final n = s.roster.length;
    final paid = s.res[Res.food]! >= n && s.res[Res.coins]! >= n;
    final paidFood = min(s.res[Res.food]!, n);
    final paidCoins = min(s.res[Res.coins]!, n);
    s.res[Res.food] = s.res[Res.food]! - paidFood;
    s.res[Res.coins] = s.res[Res.coins]! - paidCoins;
    if (ledgerOut != null) {
      ledgerOut![Res.food] = (ledgerOut![Res.food] ?? 0) + paidFood;
      ledgerOut![Res.coins] = (ledgerOut![Res.coins] ?? 0) + paidCoins;
    }
    if (!paid) {
      lines.add('Không đủ lương thực/vàng trả cho quân đội! Tinh thần giảm.');
      for (final so in s.roster) {
        so.morale = max(0, so.morale - 8);
      }
    } else {
      final target = 70 + 5 * level(s, Building.tavern);
      for (final so in s.roster) {
        so.morale = so.morale < target
            ? min(target, so.morale + 2)
            : max(target, so.morale - 2);
      }
    }

    for (final so in s.roster) {
      if (so.morale <= 15 && rng(s).nextDouble() < 0.25) {
        so.status = SoldierStatus.deserted;
        for (final f in s.facilities) {
          f.assigned.remove(so.id);
        }
        lines.add('${so.name} bỏ trốn vì kiệt quệ tinh thần.');
        s.addLog('${so.name} đã đào ngũ.');
      }
    }

    // Công trình tác động binh sĩ được gán (cấu trúc VERIFIED; tốc độ hồi/huấn luyện PROPOSED) và nghỉ ngơi.
    for (final so in s.roster) {
      final f = facilityOf(s, so.id);
      final maxHp = so.maxHp;
      if (so.hp > maxHp) so.hp = maxHp;
      if (so.hp < maxHp) {
        final heal = _infirmaryHeal(f?.type);
        so.hp = heal != null
            ? min(maxHp, so.hp + heal)
            : min(maxHp, so.hp + max(1, (maxHp * restHealFraction).round()));
        if (so.hp >= maxHp) lines.add('${so.name} đã hồi phục hoàn toàn.');
      }
      _applyDailyPoints(
        so,
        f?.type ??
            (level(s, Building.barracks) > 0 ? FacilityType.barracks : null),
      );
      // Luyện thành thạo vũ khí tại bãi tập (chỉ nhóm vũ khí hợp bãi, và chỉ tới bậc huấn luyện tối đa).
      final fdef = f == null ? null : facilityDefs[f.type];
      final wt = so.weaponId == null ? null : itemDefs[so.weaponId]?.weaponType;
      if (fdef != null && wt != null && fdef.masteryTypes.contains(wt)) {
        if (addMastery(so, wt, masteryTrainPerDay, trainingOnly: true) > 0) {
          lines.add(
            '${so.name} đạt bậc ${masteryRankNames[masteryRank(so, wt)]} với ${weaponProfiles[wt]!.name}.',
          );
        }
      }
      final st = f == null ? null : facilityDefs[f.type]!.trains;
      if (f != null && st != null) {
        if (so.stats[st]! >= statCap(so)) {
          f.assigned.remove(so.id);
          lines.add(
            '${so.name} đã đạt giới hạn ${statNames[st]} ở cấp này và rời ${facilityDefs[f.type]!.name}.',
          );
        } else {
          final rate =
              (trainPercentPerDay *
                      (so.trait == TraitId.quickLearner ? 1.3 : 1.0))
                  .round();
          so.train[st] = so.train[st]! + rate;
          while (so.train[st]! >= 100) {
            so.train[st] = so.train[st]! - 100;
            so.stats[st] = so.stats[st]! + 1;
            final ups = addXp(so, trainingXp);
            lines.add(
              '${so.name} tăng ${statNames[st]} lên ${so.stats[st]}${ups > 0 ? ' và lên cấp ${so.level}' : ''}.',
            );
          }
        }
      }
    }

    s.day++;
    restockShops(s);
    refreshCandidates(s); // danh sách ứng viên của Quán rượu làm mới mỗi ngày

    for (final m in byStatus(s, MissionStatus.active)) {
      if (s.day > m.deadline && !missionReady(s, m)) {
        final t = templateById(m.templateId);
        m.status = MissionStatus.failed;
        _addSat(s, -t.penaltySat);
        lines.add(
          'Quá hạn nhiệm vụ "${t.title}": nhà vua giảm ${t.penaltySat} hài lòng.',
        );
        s.addLog('Thất bại nhiệm vụ ${t.title}.');
      } else if (s.day > m.deadline) {
        m.status = MissionStatus.failed;
        final t = templateById(m.templateId);
        _addSat(s, -t.penaltySat);
        lines.add(
          'Bạn không nộp "${t.title}" kịp hạn: nhà vua giảm ${t.penaltySat} hài lòng.',
        );
      }
    }
    fillBoard(s);
    if (s.gameOver) {
      lines.add('Nhà vua đã mất hết kiên nhẫn. Bạn bị cách chức.');
    }
    dayHook?.call(s);
    return DayReport(stipend: stipend, upkeep: n, paid: paid, lines: lines);
  }

  /// HP hồi mỗi ngày nếu [t] có hiệu ứng HP (Lều cứu thương); null nếu không.
  static int? _infirmaryHeal(FacilityType? t) {
    if (t == null) return null;
    for (final e in effectsOf(t)) {
      if (e.stat == EffectStat.hp) return hpHealPerDay[e.level];
    }
    return null;
  }

  /// Áp năng lượng/tinh thần mỗi ngày theo [facilityEffects] của [t] (binh sĩ nhàn rỗi dùng Doanh trại).
  static void _applyDailyPoints(Soldier so, FacilityType? t) {
    if (t == null) return;
    for (final e in effectsOf(t)) {
      switch (e.stat) {
        case EffectStat.energy:
          so.energy = (so.energy + pointsPerDay[e.level]!).clamp(0, maxEnergy);
        case EffectStat.morale:
          so.morale = (so.morale + moralePerDay[e.level]!).clamp(0, 100);
        default:
          break;
      }
    }
  }

  // ---------- Bản đồ & khám phá ----------

  static bool regionUnlocked(GameState s, RegionDef r) => s.tier >= r.minTier;

  static List<LocationDef> visibleLocations(GameState s) => [
    for (final l in locations)
      if (regionUnlocked(s, regionById(l.regionId)) &&
          (s.discovered.contains(l.id) ||
              (l.startsDiscovered &&
                  regionUnlocked(s, regionById(l.regionId)))))
        l,
  ];

  static String? _revealNext(GameState s, String regionId) {
    for (final l in locations) {
      if (l.regionId == regionId &&
          !s.discovered.contains(l.id) &&
          !l.startsDiscovered) {
        s.discovered.add(l.id);
        return l.id;
      }
    }
    return null;
  }

  static const scoutCost = {Res.food: 5};

  static ActionResult scoutRegion(GameState s, String regionId) {
    final blocked = _blocked(s);
    if (blocked != null) return blocked;
    final r = regions.where((r) => r.id == regionId).firstOrNull;
    if (r == null || !regionUnlocked(s, r)) {
      return const ActionResult.fail('Vùng chưa mở.');
    }
    if (!canAfford(s, scoutCost)) {
      return ActionResult.fail('Không đủ: ${_missing(s, scoutCost)}.');
    }
    final id = _revealNext(s, regionId);
    if (id == null) {
      return const ActionResult.fail('Không còn gì để khám phá ở vùng này.');
    }
    spend(s, scoutCost);
    tickDay(s);
    final l = locationById(id)!;
    s.addLog('Trinh sát phát hiện ${l.name}.');
    return ActionResult.ok('Trinh sát mất 1 ngày và phát hiện: ${l.name}.');
  }

  static Soldier buildEnemy(GameState s, EnemySpec spec, int index) =>
      _buildEnemy(rng(s), spec, index);

  static Soldier _buildEnemy(Random r, EnemySpec spec, int index) {
    final lvl = spec.level;
    final stats = {
      for (final st in Stat.values)
        st: _base[spec.role]![st]! + (lvl - 1) * 2 ~/ 1 + r.nextInt(2),
    };
    String weapon;
    String armor;
    if (lvl >= 4) {
      weapon = spec.role == Role.archer
          ? 'war_bow'
          : (spec.role == Role.cavalry ? 'riders_lance' : 'steel_pike');
      armor = 'chain_mail';
    } else if (lvl >= 2) {
      weapon = spec.role == Role.archer
          ? 'long_bow'
          : (spec.role == Role.cavalry ? 'riders_lance' : 'iron_spear');
      armor = lvl >= 3 ? 'chain_mail' : 'leather_armor';
    } else {
      weapon = starterWeapon[spec.role]!;
      armor = 'padded_armor';
    }
    final e = Soldier(
      id: -(index + 1),
      name: '${roleNames[spec.role]} địch',
      role: spec.role,
      stats: stats,
      level: lvl,
      weaponId: weapon,
      armorId: armor,
      morale: 60,
    );
    e.hp = deriveStats(e).maxHp;
    return e;
  }

  /// Xem trước lực lượng địch mà không đụng vào state (không tiêu hao bộ đếm ngẫu nhiên).
  static List<Soldier> previewEnemies(List<EnemySpec> specs) {
    final r = Random(0);
    final out = <Soldier>[];
    for (final spec in specs) {
      for (var i = 0; i < spec.count; i++) {
        out.add(_buildEnemy(r, spec, out.length));
      }
    }
    return out;
  }

  static List<Soldier> enemiesFor(GameState s, List<EnemySpec> specs) {
    final out = <Soldier>[];
    for (final spec in specs) {
      for (var i = 0; i < spec.count; i++) {
        out.add(buildEnemy(s, spec, out.length));
      }
    }
    return out;
  }

  /// Chạy một trận thời gian thực. [placement] là vị trí triển khai của quân ta (kéo-thả);
  /// thiếu thì dùng [defaultPlacement] theo [frontIds].
  static BattleReport fight(
    GameState s,
    List<Soldier> squad,
    Set<int> frontIds,
    List<Soldier> enemies, {
    Map<int, Pos>? placement,
  }) {
    final place = placement ?? defaultPlacement(squad, frontIds);
    final epos = enemyPlacement(enemies);
    final players = [
      for (final so in squad)
        unitFrom(so, player: true, at: place[so.id] ?? const Pos(10, 12)),
    ];
    final foes = [
      for (final e in enemies)
        unitFrom(e, player: false, at: epos[e.id] ?? const Pos(28, 12)),
    ];
    return simulateBattle(players, foes, rng(s).nextInt(1 << 30));
  }

  /// Áp kết quả trận: HP còn lại kéo dài; HP về 0 là tử trận vĩnh viễn (không có xác suất);
  /// kinh nghiệm và tinh thần cho người sống sót.
  static List<Casualty> applyBattle(
    GameState s,
    List<Soldier> squad,
    BattleReport rep,
  ) {
    final won = rep.winner == Winner.player;
    final out = <Casualty>[];
    var deaths = 0;
    for (final so in squad) {
      final o = rep.outcomes[so.id]!;
      so.battles++;
      so.kills += o.kills;
      var kind = CasualtyKind.survived;
      for (final f in s.facilities) {
        f.assigned.remove(so.id);
      }
      if (o.dead) {
        so.status = SoldierStatus.dead;
        so.hp = 0;
        kind = CasualtyKind.dead;
        deaths++;
        s.fallenTotal++;
        s.addLog('${so.name} tử trận.');
      } else {
        so.hp = o.finalHp.clamp(1, so.maxHp);
        if (so.hp < so.maxHp * 0.5) kind = CasualtyKind.wounded;
      }
      var xp = 0;
      var ups = 0;
      if (kind != CasualtyKind.dead) {
        xp = 12 + 5 * o.kills + (won ? 15 : 0);
        ups = addXp(so, xp);
        // Thành thạo nhóm vũ khí đang cầm: chỉ tăng nhờ số đòn trúng thật trong trận.
        final wt = deriveStats(so).weaponType;
        if (wt != null) {
          final hits = rep.events
              .where((e) => e.actor == so.id && e.hit)
              .length;
          final ranks = addMastery(
            so,
            wt,
            min(masteryBattleCap, masteryBattleBase + hits),
          );
          if (ranks > 0) {
            s.addLog(
              '${so.name} đạt bậc ${masteryRankNames[masteryRank(so, wt)]} với ${weaponProfiles[wt]!.name}.',
            );
          }
        }
        so.morale = (so.morale + (won ? 8 : -10)).clamp(0, 100);
      }
      out.add(Casualty(so.id, so.name, kind, xp: xp, levelUps: ups));
    }
    if (deaths > 0) {
      for (final so in s.roster) {
        so.morale = max(
          0,
          so.morale - (squad.contains(so) ? 6 : 4) * deaths.clamp(1, 3),
        );
      }
    }
    if (won) {
      s.battlesWon++;
    } else {
      s.battlesLost++;
    }
    return out;
  }

  // ---------- Viễn chinh ----------

  static ExpeditionResult sendExpedition(
    GameState s,
    String locId,
    List<int> squadIds,
    Set<int> frontIds, {
    Map<int, Pos>? placement,
  }) {
    ExpeditionResult fail(String m) => ExpeditionResult(ActionResult.fail(m));
    final blocked = _blocked(s);
    if (blocked != null) return fail(blocked.message);
    final loc = locationById(locId);
    if (loc == null || !s.discovered.contains(locId) && !loc.startsDiscovered) {
      return fail('Địa điểm chưa được khám phá.');
    }
    if (!regionUnlocked(s, regionById(loc.regionId))) {
      return fail('Vùng này chưa mở.');
    }
    if (squadIds.isEmpty) return fail('Chưa chọn binh sĩ.');
    if (squadIds.length > maxSquad) {
      return fail('Tối đa $maxSquad binh sĩ mỗi đội.');
    }
    if (squadIds.toSet().length != squadIds.length) {
      return fail('Đội hình có binh sĩ trùng.');
    }
    final squad = <Soldier>[];
    for (final id in squadIds) {
      final so = s.soldier(id);
      if (so == null || !so.available) {
        return fail('Có binh sĩ không thể xuất quân.');
      }
      squad.add(so);
    }
    if (loc.kind == LocKind.camp && s.cleared.contains(locId)) {
      return fail('Địa điểm này đã bị quét sạch.');
    }

    final res = ExpeditionResult(
      const ActionResult.ok(''),
      location: loc,
      days: loc.days,
    );
    s.visiting = null; // rời nơi đang ở (nếu đang ở thành phố)
    for (var d = 0; d < loc.days; d++) {
      tickDay(s);
      if (s.gameOver) {
        return fail('Nhà vua đã cách chức bạn trong lúc hành quân.');
      }
    }
    // Binh sĩ có thể đào ngũ trên đường đi.
    squad.removeWhere((x) => !x.alive);
    if (squad.isEmpty) return fail('Cả đội đã tan rã trên đường.');
    res.lines.add('Hành quân ${loc.days} ngày tới ${loc.name}.');

    ExpeditionResult finishBattle(
      List<Soldier> enemies, {
      required bool ambush,
    }) {
      final rep = fight(
        s,
        squad,
        frontIds,
        enemies,
        placement: ambush ? null : placement,
      );
      res.battle = rep;
      res.ambush = ambush;
      res.casualties = applyBattle(s, squad, rep);
      return res;
    }

    switch (loc.kind) {
      case LocKind.camp:
        finishBattle(enemiesFor(s, loc.enemies), ambush: false);
        if (res.battle!.winner == Winner.player) {
          s.cleared.add(loc.id);
          grant(s, loc.loot);
          res.gained = Map.of(loc.loot);
          if (loc.lootItem != null) {
            s.inventory[loc.lootItem!] = (s.inventory[loc.lootItem!] ?? 0) + 1;
            res.itemGained = loc.lootItem;
          }
          _progressClear(s, loc.id, squad, res);
          res.lines.add('Chiến thắng! ${loc.name} đã bị quét sạch.');
        } else {
          res.lines.add(
            res.battle!.winner == Winner.draw
                ? 'Hai bên giằng co và rút lui.'
                : 'Thất bại.',
          );
        }
      case LocKind.resource:
        var ok = true;
        if (rng(s).nextDouble() < ambushChance) {
          final amb = enemiesFor(s, [
            EnemySpec(Role.spearman, 1 + s.tier ~/ 2, 2),
            EnemySpec(Role.archer, 1 + s.tier ~/ 2, 1),
          ]);
          finishBattle(amb, ambush: true);
          ok = res.battle!.winner == Winner.player;
          res.lines.add(
            ok ? 'Phục kích bị đẩy lui.' : 'Bị phục kích và phải bỏ lại hàng.',
          );
        }
        if (ok) {
          final amount = (loc.yield * (0.6 + 0.1 * squad.length)).round();
          grant(s, {loc.res!: amount});
          res.gained = {loc.res!: amount};
          res.lines.add('Thu được $amount ${resNames[loc.res!]}.');
        }
      case LocKind.city:
        s.visiting = loc.id;
        final town = worldMap.townById(loc.id);
        if (town != null) s.hero.position = town.position;
        res.city = loc.id;
        res.lines.add(
          'Đến ${loc.name}. Bạn có thể giao dịch với người bán tại đây.',
        );
        for (final m in byStatus(s, MissionStatus.active)) {
          final t = templateById(m.templateId);
          if (t.kind == MissionKind.visit &&
              t.locId == loc.id &&
              m.progress == 0) {
            m.progress = 1;
            res.missionNote =
                'Mục tiêu nhiệm vụ "${t.title}" đã hoàn thành. Hãy báo cáo với nhà vua.';
          }
        }
      case LocKind.ruins:
        if (s.explored.contains(loc.id)) {
          res.lines.add('Nơi này đã được khám phá, không còn gì mới.');
        } else {
          s.explored.add(loc.id);
          final r = rng(s);
          final roll = r.nextDouble();
          if (roll < 0.5) {
            final coins = 40 + r.nextInt(41) + 20 * s.tier;
            grant(s, {Res.coins: coins});
            res.gained = {Res.coins: coins};
            res.lines.add('Tìm thấy kho báu: $coins vàng.');
            if (r.nextBool()) {
              final pool = itemDefs.values
                  .where((i) => i.tier <= 1 + s.tier)
                  .toList();
              final it = pool[r.nextInt(pool.length)];
              s.inventory[it.id] = (s.inventory[it.id] ?? 0) + 1;
              res.itemGained = it.id;
            }
          } else if (roll < 0.75) {
            final victim = squad[r.nextInt(squad.length)];
            victim.hp = max(1, victim.hp - (victim.maxHp * 0.3).round());
            res.lines.add('${victim.name} dính bẫy và mất 30% HP.');
          } else {
            res.lines.add('Không tìm thấy gì đáng giá.');
          }
          final found = _revealNext(s, loc.regionId);
          if (found != null) {
            res.discovered = found;
            res.lines.add(
              'Phát hiện địa điểm mới: ${locationById(found)!.name}.',
            );
          }
          for (final m in byStatus(s, MissionStatus.active)) {
            final t = templateById(m.templateId);
            if (t.kind == MissionKind.explore && t.regionId == loc.regionId) {
              m.progress++;
              m.squad
                ..clear()
                ..addAll(squad.map((x) => x.id));
              if (missionReady(s, m)) {
                final r = _settle(s, m);
                if (r.ok) res.missionNote = r.message;
              } else {
                m.targetId = objectiveFor(s, t, m.giverTown);
              }
            }
          }
        }
    }
    s.addLog('Viễn chinh ${loc.name}: ${res.lines.last}');
    return res;
  }

  static void _progressClear(
    GameState s,
    String locId,
    List<Soldier> squad,
    ExpeditionResult res,
  ) {
    for (final m in byStatus(s, MissionStatus.active)) {
      final t = templateById(m.templateId);
      if (t.kind == MissionKind.clear && t.locId == locId) {
        if (s.day > m.deadline) continue;
        if (squad.length >= t.minSoldiers) {
          m.progress = 1;
          m.squad
            ..clear()
            ..addAll(squad.map((x) => x.id));
          // Thắng trận = hoàn thành mục tiêu: trao thưởng ngay, đúng một lần.
          final r = _settle(s, m);
          res.missionNote = r.ok
              ? r.message
              : 'Mục tiêu nhiệm vụ "${t.title}" đã hoàn thành.';
        } else {
          res.missionNote =
              'Đội quá nhỏ (${t.minSoldiers} yêu cầu) nên không tính cho nhiệm vụ "${t.title}".';
        }
      }
    }
  }
}
