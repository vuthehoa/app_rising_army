import 'dart:math';

import '../data/name_generator.dart';
import '../data/new_game_data.dart' show AvatarGender;
import 'battle.dart';
import 'building_effects.dart';
import 'camp_layout.dart';
import 'catalog.dart';
import 'combat_condition.dart';
import 'dev_mode.dart';
import 'economy.dart';
import 'equipment/equipment_item.dart';
import 'equipment/equipment_rules.dart';
import 'equipment/equipment_service.dart';
import 'identity.dart';
import 'item_grade.dart';
import 'models.dart';
import 'movement.dart';
import 'progression.dart';
import 'quest_generator.dart';
import 'stat_formulas.dart';
import 'stats.dart';
import 'terrain_type.dart';
import 'world_data.dart';
import 'world_map.dart';

enum CasualtyKind { survived, wounded, dead, deserted }

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
  Casualty(
    this.id,
    this.name,
    this.kind, {
    this.xp = 0,
    this.levelUps = 0,
    this.energyBefore,
    this.energyAfter,
    this.moraleBefore,
    this.moraleAfter,
    this.levelAfter,
    this.statPointsAfter,
    this.fled = false,
  });
  final int id;
  final String name;
  final CasualtyKind kind;
  final int xp;
  final int levelUps;

  /// Ảnh chụp thể trạng ngay trước/sau [GameRules.applyBattle] (không lưu vào save; chỉ phục vụ màn kết quả).
  /// null khi không có số liệu đáng tin.
  final int? energyBefore;
  final int? energyAfter;
  final int? moraleBefore;
  final int? moraleAfter;

  /// Cấp và điểm chỉ số chưa dùng sau trận.
  final int? levelAfter;
  final int? statPointsAfter;

  /// Tinh thần về 0 GIỮA trận nên bỏ chạy (khác đào ngũ do tinh thần cạn sau trận).
  final bool fled;

  int? get energySpent => energyBefore == null || energyAfter == null
      ? null
      : energyBefore! - energyAfter!;
  int? get moraleDelta => moraleBefore == null || moraleAfter == null
      ? null
      : moraleAfter! - moraleBefore!;

  Casualty copyWith({CasualtyKind? kind, int? energyAfter, int? moraleAfter}) =>
      Casualty(
        id,
        name,
        kind ?? this.kind,
        xp: xp,
        levelUps: levelUps,
        energyBefore: energyBefore,
        energyAfter: energyAfter ?? this.energyAfter,
        moraleBefore: moraleBefore,
        moraleAfter: moraleAfter ?? this.moraleAfter,
        levelAfter: levelAfter,
        statPointsAfter: statPointsAfter,
        fled: fled,
      );
}

class DayReport {
  const DayReport({
    required this.stipend,
    required this.upkeep,
    required this.paidUpkeep,
    required this.paid,
    required this.lines,
  });
  final Cost stipend;

  /// Chi phí duy trì quân của ngày (vàng + lương) theo cấp từng binh sĩ (xem [UpkeepEconomy]).
  final Cost upkeep;

  /// Phần chi phí duy trì thực sự đã trừ (bằng [upkeep] khi [paid], nhỏ hơn khi thiếu tài nguyên).
  final Cost paidUpkeep;
  final bool paid;
  final List<String> lines;
}

/// Phần thưởng THỰC SỰ đã trao khi hoàn thành một nhiệm vụ (ghi lại lúc chốt để màn kết quả hiển thị đúng thứ đã vào
/// kho, không suy đoán lại). Chỉ được tạo bởi `GameRules._settle`, nên mỗi nhiệm vụ nhiều nhất một bản ghi.
class QuestPayout {
  QuestPayout(this.title);
  final String title;
  final Cost res = {};
  final List<String> items = [];
  int exp = 0;
  int sat = 0;
  final List<String> levelUps = [];
}

class ExpeditionResult {
  ExpeditionResult(this.result, {this.location, this.days = 0});
  final ActionResult result;
  final LocationDef? location;
  final int days;
  BattleReport? battle;
  List<Casualty> casualties = [];
  Cost gained = {};

  /// Trang bị nhận được (mã tham chiếu trong kho), theo thứ tự nhận.
  final List<String> itemsGained = [];

  /// Thưởng nhiệm vụ đã trao ngay sau trận này (tách khỏi chiến lợi phẩm [gained] / [itemsGained]).
  final List<QuestPayout> payouts = [];
  String? get itemGained => itemsGained.isEmpty ? null : itemsGained.first;
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

  /// Số nhiệm vụ đang nhận (active) tối đa cùng lúc. Luật này ở domain: UI, gọi trực tiếp và tải save đều theo nó.
  static const maxActiveMissions = 3;

  /// Khoảng cách (đơn vị thế giới) tối đa tới điểm giao chiến để được bắt đầu trận. Đi bộ dừng đúng tâm điểm.
  static const encounterArriveRadius = 80.0;
  static const startRoster = 6;

  static Random rng(GameState s) => Random(s.seed * 7919 + s.rngCounter++);

  // ---------- Tạo ván mới & sinh binh sĩ ----------

  /// Tên binh sĩ lấy từ `NameData` (danh sách tên chuẩn của dự án) qua [NameGenerator], dùng đúng bộ `Random` của luật
  /// (seed + rngCounter) nên tái lập được. Giới tính chỉ để chọn kho tên; binh sĩ không lưu giới tính.
  static String _name(Random r) => NameGenerator.generate(
    r.nextBool() ? AvatarGender.male : AvatarGender.female,
    r,
  );

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
        st:
            roleBaseStats[rl]![st]! +
            r.nextInt(StatFormulas.startSpread) +
            (level - 1) * StatFormulas.perLevelBonus,
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
      atkPoints:
          roleBaseAttack[rl]! +
          r.nextInt(StatFormulas.startSpread) +
          (level - 1) * StatFormulas.perLevelBonus,
    );
    if (equip) {
      sol.weaponId = starterWeapon[rl];
      sol.armorId = 'padded_armor';
    }
    fillVitals(sol);
    return sol;
  }

  /// Đặt HP và Thể lực đầy, Tinh thần ở mức khởi đầu ([startMoraleFraction] của tối đa) theo chỉ số hiện có.
  static void fillVitals(Soldier so) {
    final d = deriveStats(so);
    so.hp = d.maxHp;
    so.energy = d.maxEnergy;
    so.morale = (d.maxMorale * startMoraleFraction).round();
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
      res: Map.of(StartingEconomy.resources),
      soldiers: [],
      nextSoldierId: 1,
      // Mọi công trình đều phải được xây (cấp 0 = chưa xây). Bếp lửa giữa trại chỉ là hình trang trí
      // (xem [campfireSpot]), không phải công trình.
      buildings: {for (final b in Building.values) b: 0},
      facilities: [],
      nextFacilityId: 1,
      inventory: {'padded_armor': 1},
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

  /// Chỉ dùng cho mô phỏng: như [dayHook] nhưng nhận cả báo cáo ngày (bổng lộc, chi phí duy trì).
  static void Function(GameState s, DayReport r)? dayReportHook;

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

  static int statCap(Soldier s) => StatFormulas.statCap(s.level);

  static Cost? upgradeCost(GameState s, Building b) {
    final l = level(s, b);
    return l >= GameState.maxBuildingLevel
        ? null
        : ConstructionEconomy.barracksUpgradeCost(l + 1);
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

  // ---------- Cứu trợ chống softlock ----------

  /// Sau một lần cứu trợ, phải qua chừng này ngày mới có thể có lần nữa (chống lạm dụng).
  static const reliefCooldownDays = 15;

  /// Quà cứu trợ: một tân binh cấp 1 (đủ để đi làm nhiệm vụ dễ) và ít vàng/lương để trả những ngày đầu.
  static const reliefGrant = <Res, int>{Res.coins: 12, Res.food: 8};

  /// Tổng vàng có thể có ngay không cần quân: vàng hiện có + bán hết trang bị trong kho + bán hết tài nguyên.
  static int _liquidGold(GameState s) {
    var gold = s.res[Res.coins] ?? 0;
    for (final e in s.inventory.entries) {
      final d = itemDefs[EquipmentItem.tryParse(e.key)?.designId ?? e.key];
      if (d != null && e.value > 0) gold += sellPrice(d.id) * e.value;
    }
    for (final r in Res.values) {
      if (r == Res.coins || !MarketEconomy.tradable(r)) continue;
      gold += s.res[r]! * resourceSellPrice(r);
    }
    return gold;
  }

  /// Bế tắc thật sự: không còn binh sĩ nào, và không có đường nào để có lại quân — không đủ vàng (kể cả khi bán hết
  /// kho/tài nguyên) để chiêu mộ ứng viên rẻ nhất, cũng không hồi sinh nổi ai. Không chỉ nhìn `vàng == 0`.
  static bool isSoftlocked(GameState s) {
    if (s.roster.isNotEmpty || s.gameOver || s.victory) return false;
    final gold = _liquidGold(s);
    final prices = [
      for (final c in s.candidates)
        if (HireEconomy.hireable(c)) hireCost(c),
    ];
    final cheapestHire = prices.isEmpty
        ? HireEconomy.levelBase[1]!
        : prices.reduce(min);
    if (gold >= cheapestHire) return false;
    if (facilityCount(s, FacilityType.gravestone) > 0 &&
        s.fallen.any((x) => reviveCost(x) <= gold)) {
      return false;
    }
    return true;
  }

  /// Gọi khi qua ngày: nếu bế tắc và đã hết thời gian chờ, tặng một tân binh cấp 1 + ít tài nguyên, đúng một lần mỗi
  /// chu kỳ. Trả về dòng báo cáo (null nếu không kích hoạt). Trạng thái dùng lưu ở [GameState.reliefDay].
  static String? _maybeRelief(GameState s) {
    if (!isSoftlocked(s)) return null;
    if (s.reliefDay >= 0 && s.day - s.reliefDay < reliefCooldownDays) {
      return null;
    }
    s.reliefDay = s.day;
    final rookie = generateSoldier(s, level: 1, equip: true);
    s.soldiers.add(rookie);
    grant(s, reliefGrant);
    s.addLog('Cứu trợ: ${rookie.name} gia nhập.');
    return 'Làng lân cận thương tình: ${rookie.name} (cấp 1) xin gia nhập cùng '
        '${describeCost(reliefGrant)} để bạn gượng dậy. Cứu trợ chỉ có khi mất sạch quân và vốn, '
        'tối thiểu $reliefCooldownDays ngày mới có lại.';
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

      final candidate = generateSoldier(s, level: lvl);

      if (!equipTavernCandidate(s, candidate)) {
        // Không thêm ứng viên thiếu áo giáp hoặc vũ khí.
        continue;
      }

      s.candidates.add(candidate);
    }
  }

  /// Giá chiêu mộ (chỉ vàng): nguồn duy nhất cho giá hiển thị và số vàng bị trừ. Xem [HireEconomy.price].
  static int hireCost(Soldier c) => HireEconomy.price(c);

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

  /// Hàm chọn trang bị khởi đầu cho một ô.
  /// Có thể thay thế trong test để kiểm tra trường hợp catalog thiếu món.
  static String? Function(Random, Slot, Soldier) hireGearPicker = HireGear.roll;

  /// Chọn áo giáp + vũ khí cho ứng viên [c].
  ///
  /// - Chỉ chọn cho các ô còn trống, không ghi đè trang bị đã có.
  /// - Không thay đổi kho đồ.
  /// - Không sử dụng hoặc tăng bộ đếm RNG của ván.
  /// - Kết quả có thể tái lập theo seed ván, ID ứng viên và ô trang bị.
  ///
  /// Trả về null nếu không thể chọn đủ trang bị hợp lệ.
  static Map<Slot, String>? starterGearFor(GameState s, Soldier c) {
    final out = <Slot, String>{};

    for (final slot in HireGear.requiredSlots) {
      // Giữ nguyên trang bị ứng viên đã có.
      final existingId = c.equipped(slot);

      if (existingId != null) {
        // Không chấp nhận ID không tồn tại hoặc sai loại ô.
        final existingItem = itemDefs[existingId];

        if (existingItem == null || existingItem.slot != slot) {
          return null;
        }

        continue;
      }

      // RNG độc lập theo seed + ID ứng viên + ô trang bị.
      // Không làm thay đổi rngCounter của GameState.
      final random = Random(
        (s.seed * 1000003 + c.id * 7919 + (slot.index + 1) * 104729 + 17) &
            0x7fffffff,
      );

      final id = hireGearPicker(random, slot, c);

      // Không chấp nhận trường hợp không có đồ hoặc sai loại trang bị.
      if (id == null) return null;

      final item = itemDefs[id];

      if (item == null || item.slot != slot) {
        return null;
      }

      out[slot] = id;
    }

    return out;
  }

  /// Cấp đủ áo giáp và vũ khí cho ứng viên Quán rượu.
  ///
  /// Chỉ sửa ứng viên sau khi đã chọn thành công toàn bộ trang bị,
  /// tránh trường hợp cấp được một món rồi thất bại ở món còn lại.
  ///
  /// Trả về false nếu không thể cấp đủ trang bị hợp lệ.
  static bool equipTavernCandidate(GameState s, Soldier candidate) {
    final gear = starterGearFor(s, candidate);

    if (gear == null) {
      return false;
    }

    // Chỉ gán sau khi đã xác nhận toàn bộ trang bị hợp lệ.
    for (final slot in HireGear.requiredSlots) {
      final id = candidate.equipped(slot) ?? gear[slot];

      if (id == null) {
        return false;
      }

      final item = itemDefs[id];

      if (item == null || item.slot != slot) {
        return false;
      }
    }

    gear.forEach(candidate.setEquipped);

    return HireGear.requiredSlots.every(
      (slot) => candidate.equipped(slot) != null,
    );
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
    if (!HireEconomy.hireable(c)) {
      return const ActionResult.fail(
        'Chỉ chiêu mộ được anh hùng cấp 1–$tavernMaxCandidateLevel.',
      );
    }
    final cost = {Res.coins: hireCost(c)};
    if (!canAfford(s, cost)) {
      return ActionResult.fail('Không đủ: ${_missing(s, cost)}.');
    }
    // Lính chiêu mộ LUÔN có áo giáp và vũ khí. Chọn xong (và hợp lệ) rồi mới trừ vàng: thiếu món hợp lệ thì thất bại
    // nguyên vẹn, không tạo lính thiếu đồ.
    final gear = starterGearFor(s, c);
    if (gear == null) {
      return const ActionResult.fail(
        'Không có trang bị phù hợp để trang bị cho ứng viên này.',
      );
    }
    spend(s, cost);
    gear.forEach(c.setEquipped);
    fillVitals(c); // trang bị đổi chỉ số gốc hiệu dụng → HP/Thể lực/Tinh thần tối đa; lính mới nên đầy
    s.candidates.removeAt(i);
    s.soldiers.add(c);
    s.addLog('Tuyển ${c.name} (${roleNames[c.role]}).');
    return ActionResult.ok('${c.name} gia nhập quân đội.');
  }

  static ActionResult rename(GameState s, int id, String name) {
    final so = s.soldier(id);
    // Chuẩn hóa như tên chỉ huy: bỏ khoảng trắng đầu/cuối và gộp khoảng trắng liên tiếp.
    final n = NameGenerator.normalize(name);
    if (so == null || !so.alive) {
      return const ActionResult.fail('Không tìm thấy binh sĩ.');
    }
    if (n.isEmpty || n.length > maxDisplayNameLength) {
      return ActionResult.fail('Tên phải dài 1-$maxDisplayNameLength ký tự.');
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

  /// Số chỗ của công trình [f]: Doanh trại theo cấp bậc ([rosterCap] = 6 + 4 mỗi cấp), còn lại theo cấp slot.
  static int slotsOf(GameState s, Facility f) =>
      f.type == FacilityType.barracks ? rosterCap(s) : f.slots;

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
    final slots = slotsOf(s, f);
    if (f.assigned.length >= slots) {
      return ActionResult.fail(
        '${facilityDefs[f.type]!.name} đã đầy ($slots/$slots).',
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
        inventoryWeightTenths(s) >
            inventoryCapacityTenths(s) - WeightEconomy.perChestKg * 10) {
      return 'Rương đang chứa quá sức chứa còn lại nếu bỏ Hòm đồ này.';
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
      slotUpgradableFacilities.contains(f.type);

  /// Nâng cấp slot 3 → 6, đúng một lần.
  static ActionResult upgradeFacility(GameState s, int id) {
    final blocked = _blocked(s);
    if (blocked != null) return blocked;
    final f = facilityById(s, id);
    if (f == null) return const ActionResult.fail('Công trình không tồn tại.');
    final cost = ConstructionEconomy.slotUpgradeCost(f.type);
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
    // Hồi sinh chỉ trả lại sự sống: HP = 1, năng lượng/tinh thần giữ nguyên, bắt buộc chữa trị trước khi ra trận.
    so.status = SoldierStatus.active;
    so.hp = 1;
    so.needsTreatment = true;
    s.addLog('${so.name} được hồi sinh với 1 HP, cần chữa trị.');
    return ActionResult.ok(
      '${so.name} đã được hồi sinh (HP 1). Hãy chữa trị ở Lều cứu thương.',
    );
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
    final price = ConstructionEconomy.buildCost(type);
    if (!canAfford(s, price)) {
      return ActionResult.fail('Không đủ: ${_missing(s, price)}.');
    }
    spend(s, price);
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
    } else if (!canAfford(s, ConstructionEconomy.buildCost(t))) {
      why = 'Không đủ tài nguyên';
    }
    return CampBuildStatus(
      def: d,
      count: count,
      level: 0,
      cost: max != null && count >= max
          ? null
          : ConstructionEconomy.buildCost(t),
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

  /// XP thực tế [so] nhận được từ [amount] XP gốc (trait Học nhanh +30%); 0 nếu đã đạt cấp tối đa.
  static int xpGainFor(Soldier so, int amount) {
    if (amount <= 0 || so.level >= maxSoldierLevel) return 0;
    return so.trait == TraitId.quickLearner ? (amount * 1.3).round() : amount;
  }

  /// Cộng XP (trait Học nhanh +30%). Mỗi lần lên cấp (tới [maxSoldierLevel]) cho đúng 1 điểm chỉ số chưa phân
  /// bổ ([Soldier.statPoints]); không tự tăng chỉ số. Đạt cấp tối đa thì không tích XP nữa. Trả về số cấp tăng.
  static int addXp(Soldier so, int amount) {
    if (amount <= 0 || so.level >= maxSoldierLevel) {
      if (so.level >= maxSoldierLevel) so.xp = 0;
      return 0;
    }
    final gain = xpGainFor(so, amount);
    so.xp += gain;
    var ups = 0;
    while (so.level < maxSoldierLevel && so.xp >= xpForNext(so.level)) {
      so.xp -= xpForNext(so.level);
      so.level++;
      so.statPoints++;
      ups++;
    }
    if (so.level >= maxSoldierLevel) so.xp = 0;
    // Lên cấp THẬT SỰ (ups > 0) → hồi đầy HP / Thể lực / Tinh thần theo chỉ số tối đa SAU KHI lên cấp (cấp và trang bị
    // cuối cùng, kể cả lên nhiều cấp một lần). Điểm DUY NHẤT: mọi nguồn EXP (trận, nhiệm vụ…) đều đi qua đây.
    // Nhận EXP chưa đủ lên cấp, hoặc đã tối đa cấp, thì không hồi gì.
    if (ups > 0) restoreVitalsFull(so);
    return ups;
  }

  /// Đặt HP, Thể lực, Tinh thần hiện tại = mức tối đa hiện tại (tính lại từ bốn chỉ số gốc hiệu dụng).
  static void restoreVitalsFull(Soldier so) {
    final d = deriveStats(so);
    so.hp = d.maxHp;
    so.energy = d.maxEnergy;
    so.morale = d.maxMorale;
  }

  /// Phân bổ 1 điểm chỉ số chưa dùng vào [stat]. Khi điểm cuối cùng được dùng hết, HP, năng lượng và tinh thần
  /// hồi đầy tới mức tối đa MỚI (không hồi sau mỗi lần bấm khi còn điểm, không hồi khi chỉ mở hồ sơ).
  static ActionResult allocateStat(GameState s, int id, MainStat stat) {
    final blocked = _blocked(s);
    if (blocked != null) return blocked;
    final so = s.soldier(id);
    if (so == null || !so.alive) {
      return const ActionResult.fail('Không tìm thấy binh sĩ.');
    }
    if (so.statPoints <= 0) {
      return const ActionResult.fail('Không còn điểm chỉ số.');
    }
    final before = vitalCaps(so);
    switch (stat) {
      case MainStat.strength:
        so.stats[Stat.str] = so.stats[Stat.str]! + 1;
      case MainStat.speed:
        so.stats[Stat.dex] = so.stats[Stat.dex]! + 1;
      case MainStat.build:
        so.stats[Stat.con] = so.stats[Stat.con]! + 1;
      case MainStat.attack:
        so.atkPoints++;
    }
    so.statPoints--;
    // Mức tối đa tính lại từ bốn chỉ số mới; giá trị hiện tại chỉ dịch theo phần chênh (không tự hồi đầy).
    rebaseVitals(so, before);
    return ActionResult.ok('${so.name} tăng ${mainStatNames[stat]}.');
  }

  /// HP / Thể lực / Tinh thần tối đa hiện tại của [so] (đã gồm trang bị). Gọi TRƯỚC khi đổi chỉ số/trang bị.
  static VitalCaps vitalCaps(Soldier so) {
    final d = deriveStats(so);
    return VitalCaps(d.maxHp, d.maxEnergy, d.maxMorale);
  }

  /// Kẹp HP / Thể lực / Tinh thần của mọi binh sĩ và ứng viên về mức tối đa hiện tại (sau khi nạp save, khi công thức
  /// hoặc trang bị làm mức tối đa thấp hơn giá trị đã lưu). Không bao giờ tăng giá trị.
  static void clampVitals(GameState s) {
    for (final so in [...s.soldiers, ...s.candidates]) {
      // Đã chết / đào ngũ: giữ nguyên dữ liệu lịch sử.
      if (so.status != SoldierStatus.active) continue;
      final d = deriveStats(so);
      if (so.hp > d.maxHp) so.hp = d.maxHp;
      if (so.energy > d.maxEnergy) so.energy = d.maxEnergy;
      if (so.morale > d.maxMorale) so.morale = d.maxMorale;
    }
  }

  /// Áp chính sách bảo toàn giá trị hiện tại sau khi mức tối đa đổi (xem [rebaseCurrent]). [before] lấy từ
  /// [vitalCaps] trước thay đổi. Tối đa tăng d thì hiện tại tăng d; tối đa giảm thì hiện tại bị kẹp.
  static void rebaseVitals(Soldier so, VitalCaps before) {
    final d = deriveStats(so);
    so.hp = rebaseCurrent(so.hp, before.hp, d.maxHp);
    so.energy = rebaseCurrent(so.energy, before.energy, d.maxEnergy);
    so.morale = rebaseCurrent(so.morale, before.morale, d.maxMorale);
  }

  /// Loại binh sĩ đào ngũ vĩnh viễn khỏi gameplay: gỡ khỏi công trình, trả trang bị về kho (như sa thải, không
  /// mất/nhân đôi), đánh dấu [SoldierStatus.deserted]. Chỉ tác động lên lính còn phục vụ nên gọi lặp vô hại.
  /// Dữ liệu lịch sử (trận, hạ gục) được giữ. Lính này không còn trong [GameState.roster] nên không tính lương.
  static bool desert(GameState s, Soldier so, {String? reason}) {
    if (!so.alive) return false;
    for (final slot in Slot.values) {
      final item = so.equipped(slot);
      if (item != null) {
        s.inventory[item] = (s.inventory[item] ?? 0) + 1;
        so.setEquipped(slot, null);
      }
    }
    for (final f in s.facilities) {
      f.assigned.remove(so.id);
    }
    so.status = SoldierStatus.deserted;
    s.addLog(reason ?? '${so.name} đã đào ngũ.');
    return true;
  }

  /// Tinh thần về 0 → đào ngũ. Trả về tên những người vừa bỏ đi.
  static List<String> sweepBrokenMorale(GameState s) => [
    for (final so in List.of(s.roster))
      if (so.morale <= 0 &&
          desert(s, so, reason: '${so.name} đào ngũ vì tinh thần cạn kiệt.'))
        so.name,
  ];

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
    final before = vitalCaps(so);
    so.skills[skillId] = cur + 1;
    rebaseVitals(so, before);
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
    final before = vitalCaps(so);
    so.talents.add(talentId);
    rebaseVitals(so, before);
    return ActionResult.ok('${so.name} có tài năng ${t.name}.');
  }

  // ---------- Trang bị ----------

  /// Trang bị [itemId] (mã tham chiếu trong kho) cho binh sĩ [id]; logic nằm ở [EquipmentService].
  /// [slot] nếu truyền thì vật phẩm phải đúng ô đó.
  static ActionResult equip(GameState s, int id, String itemId, {Slot? slot}) {
    final blocked = _blocked(s);
    if (blocked != null) return blocked;
    return EquipmentService.equip(s, id, itemId, slot: slot);
  }

  static ActionResult unequip(GameState s, int id, Slot slot) =>
      EquipmentService.unequip(s, id, slot);

  static int itemPrice(GameState s, ItemDef it) {
    final disc = 1 - 0.05 * (level(s, Building.smithy) - 1).clamp(0, 2);
    return (it.price * disc).round();
  }

  // ---------- Thành phố và giao dịch ----------

  /// Số vật phẩm trong kho đồ (đếm món, KHÔNG phải trọng lượng; dùng cho thống kê/kiểm thử).
  static int inventoryCount(GameState s) =>
      s.inventory.values.fold(0, (a, b) => a + b);

  /// Trọng lượng (1/10 kg) của MỘT mã tham chiếu vật phẩm (0 nếu không tồn tại).
  static int itemWeightTenths(String ref) =>
      (EquipmentRules.weightOf(ref) * 10).round();

  /// TRỌNG LƯỢNG RƯƠNG (1/10 kg) = Σ vật phẩm trong kho × số lượng + Σ tài nguyên vật liệu/lương thực.
  /// Vàng không có trọng lượng. Trang bị đang đeo KHÔNG nằm trong rương. Mỗi mã tham chiếu chỉ tính một lần
  /// (kho đồ là một bản đồ id → số lượng).
  static int inventoryWeightTenths(GameState s) {
    var w = 0;
    for (final e in s.inventory.entries) {
      if (e.value > 0) w += itemWeightTenths(e.key) * e.value;
    }
    for (final r in Res.values) {
      w += WeightEconomy.ofResource(r, s.res[r] ?? 0);
    }
    return w;
  }

  /// Trọng lượng rương làm tròn lên kg nguyên để hiển thị `hiện tại/tối đa`.
  static int inventoryWeightKg(GameState s) =>
      WeightEconomy.displayKg(inventoryWeightTenths(s));

  /// Sức chứa rương (1/10 kg): cơ bản + theo cấp Doanh trại + mỗi Hòm đồ thực tế đang có (tính lại từ state).
  static int inventoryCapacityTenths(GameState s) => inventoryCapacity(s) * 10;

  /// Sức chứa rương (kg nguyên).
  static int inventoryCapacity(GameState s) =>
      WeightEconomy.capacityKg(level(s, Building.barracks), chestCount(s));

  /// Lý do không thể thêm [addTenths] (1/10 kg) vào rương; null nếu được (hoặc nếu chỉ bớt đi). Phần thưởng nhiệm vụ,
  /// chiến lợi phẩm và tài nguyên sản sinh KHÔNG đi qua kiểm tra này (không bao giờ bị mất); vượt sức chứa chỉ chặn
  /// các việc tự nguyện làm nặng thêm (mua, tháo đồ).
  static String? overloadReason(GameState s, int addTenths) {
    if (addTenths <= 0) return null;
    if (inventoryWeightTenths(s) + addTenths <= inventoryCapacityTenths(s)) {
      return null;
    }
    return 'Rương quá tải (${inventoryWeightKg(s)}/${inventoryCapacity(s)} kg). '
        'Bán bớt, dùng vật liệu hoặc nâng cấp Doanh trại / xây thêm Hòm đồ.';
  }

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
    int hashOf(String key) =>
        (s.seed * 1000003 + s.day * 7919 + _stableHash('${v.id}/$key')) &
        0x7fffffff;
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
        items[id] = MarketEconomy.dailyQuantity(v.items[id]!, hashOf(id));
      }
    }
    return ShopStock(
      items: items,
      resources: v.kind == VendorKind.market
          ? {
              for (final e in v.resources.entries)
                e.key: MarketEconomy.dailyQuantity(e.value, hashOf(e.key.name)),
            }
          : {},
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

  /// Giá mua MỖI ĐƠN VỊ tài nguyên tại [v] và giá bán lại: một nguồn duy nhất ([MarketEconomy]).
  static int resourceBuyPrice(VendorDef v, Res r) =>
      MarketEconomy.buyPrice(r, v.priceMult);

  static int resourceSellPrice(Res r) => MarketEconomy.sellPrice(r);

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
    // Thành phố luôn mở: không khóa theo nhiệm vụ hay tiến độ.
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
    final over = overloadReason(s, itemWeightTenths(itemId) * qty);
    if (over != null) return ActionResult.fail(over);
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

  static ActionResult buyResource(
    GameState s,
    String vendorId,
    Res res,
    int qty,
  ) {
    final v = vendorById(vendorId);
    final gate = _gate(s, v);
    if (gate != null) return gate;
    if (v!.kind != VendorKind.market ||
        !MarketEconomy.tradable(res) ||
        !v.resources.containsKey(res)) {
      return ActionResult.fail(
        '${v.name} không bán ${resNames[res]!.toLowerCase()}.',
      );
    }
    if (qty < 1 || qty > 999) {
      return const ActionResult.fail('Số lượng không hợp lệ.');
    }
    final have = peekStock(s, v).resources[res] ?? 0;
    if (have < qty) {
      return ActionResult.fail(
        have == 0
            ? '${resNames[res]} đã hết hàng.'
            : 'Chỉ còn $have ${resNames[res]!.toLowerCase()}.',
      );
    }
    final over = overloadReason(s, WeightEconomy.ofResource(res, qty));
    if (over != null) return ActionResult.fail(over);
    final cost = {Res.coins: resourceBuyPrice(v, res) * qty};
    if (!canAfford(s, cost)) {
      return ActionResult.fail('Không đủ: ${_missing(s, cost)}.');
    }
    spend(s, cost);
    stockOf(s, v).resources[res] = have - qty;
    grant(s, {res: qty});
    s.tradeCount++;
    return ActionResult.ok(
      'Đã mua $qty ${resNames[res]!.toLowerCase()} với ${cost[Res.coins]} vàng.',
    );
  }

  static ActionResult sellResource(
    GameState s,
    String vendorId,
    Res res,
    int qty,
  ) {
    final v = vendorById(vendorId);
    final gate = _gate(s, v);
    if (gate != null) return gate;
    if (v!.kind != VendorKind.market ||
        !MarketEconomy.tradable(res) ||
        !v.resources.containsKey(res)) {
      return ActionResult.fail(
        '${v.name} không mua ${resNames[res]!.toLowerCase()}.',
      );
    }
    if (qty < 1 || qty > 999) {
      return const ActionResult.fail('Số lượng không hợp lệ.');
    }
    if ((s.res[res] ?? 0) < qty) {
      return ActionResult.fail(
        'Bạn chỉ có ${s.res[res]} ${resNames[res]!.toLowerCase()}.',
      );
    }
    final room = v.resources[res]! * 2 - (peekStock(s, v).resources[res] ?? 0);
    if (qty > room) {
      return ActionResult.fail(
        'Người bán chỉ còn chỗ chứa thêm $room ${resNames[res]!.toLowerCase()}.',
      );
    }
    final gain = resourceSellPrice(res) * qty;
    _deduct(s, {res: qty});
    final st = stockOf(s, v);
    st.resources[res] = (st.resources[res] ?? 0) + qty;
    grant(s, {Res.coins: gain});
    s.tradeCount++;
    return ActionResult.ok(
      'Đã bán $qty ${resNames[res]!.toLowerCase()}, nhận $gain vàng.',
    );
  }

  static ActionResult buy(GameState s, String itemId) {
    final blocked = _blocked(s);
    if (blocked != null) return blocked;
    final it = itemDefs[itemId];
    if (it == null) return const ActionResult.fail('Vật phẩm không tồn tại.');
    if (it.tier > level(s, Building.smithy)) {
      return ActionResult.fail('Cần Lò rèn cấp ${it.tier}.');
    }
    final over = overloadReason(s, itemWeightTenths(itemId));
    if (over != null) return ActionResult.fail(over);
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

  /// Bảng nhiệm vụ: luôn đủ [QuestGenerator.maxOffered] nhiệm vụ SĂN (chiến đấu trên bản đồ), độ khó theo sức
  /// mạnh đội quân ([QuestGenerator.band]); sinh vô hạn, không có nhiệm vụ hành chính. Nhiệm vụ đang mời không
  /// còn hợp độ khó (đội quân vừa mạnh lên) hoặc thuộc mẫu cũ bị bỏ khỏi bảng; nhiệm vụ đang làm không bị đụng.
  static void fillBoard(GameState s) {
    s.missions.removeWhere(
      (m) =>
          m.status == MissionStatus.failed ||
          (m.status == MissionStatus.completed && s.missions.length > 12),
    );
    final want = QuestGenerator.boardDifficulties(QuestGenerator.band(s));
    final need = <int, int>{};
    for (final d in want) {
      need[d] = (need[d] ?? 0) + 1;
    }
    final offered = byStatus(s, MissionStatus.offered);
    for (final m in offered) {
      final t = templateById(m.templateId);
      if (t.kind != MissionKind.hunt || (need[t.difficulty] ?? 0) <= 0) {
        s.missions.remove(m);
      } else {
        need[t.difficulty] = need[t.difficulty]! - 1;
      }
    }
    var gold = 0, red = 0;
    for (final m in byStatus(s, MissionStatus.offered)) {
      templateById(m.templateId).color == MissionColor.gold ? gold++ : red++;
    }
    for (final e in need.entries) {
      for (var i = 0; i < e.value; i++) {
        final color = gold <= red ? 'gold' : 'red';
        color == 'gold' ? gold++ : red++;
        s.missions.add(
          Mission(id: s.nextMissionId++, templateId: 'hunt_${color}_${e.key}'),
        );
      }
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
      case MissionKind.hunt:
        return null; // điểm giao chiến được tạo khi nhận nhiệm vụ (xem acceptMission)
    }
  }

  /// Chỉ nhận được khi nhân vật đang ở trong một thành trấn (đã vào thành, `visiting` khác null).
  /// Lý do KHÔNG nhận được nhiệm vụ [m] lúc này (null = nhận được). Dùng cho nút "Nhận" ở giao diện; luật thật vẫn
  /// kiểm tra lại trong [acceptMission] nên bấm khi bị khóa hay gọi trực tiếp đều không vượt giới hạn.
  static String? acceptBlockReason(GameState s, Mission m) {
    final town = s.visiting == null ? null : locationById(s.visiting!);
    if (m.status != MissionStatus.offered) {
      return m.status == MissionStatus.active
          ? 'Nhiệm vụ này đã được nhận.'
          : 'Nhiệm vụ không còn.';
    }
    if (town == null || town.kind != LocKind.city) {
      return 'Chỉ nhận nhiệm vụ khi đang ở trong thành trấn.';
    }
    if (byStatus(s, MissionStatus.active).length >= maxActiveMissions) {
      return 'Đã nhận đủ $maxActiveMissions nhiệm vụ. Hoàn thành hoặc bỏ bớt một nhiệm vụ để nhận thêm.';
    }
    return null;
  }

  /// Sau khi nạp save: không có quá [maxActiveMissions] nhiệm vụ đang làm. Phần dư (id lớn nhất) được trả về bảng
  /// nhiệm vụ ở trạng thái chưa nhận (không mất nhiệm vụ, không trao thưởng). Idempotent.
  static void sanitizeMissions(GameState s) {
    final active = byStatus(s, MissionStatus.active)
      ..sort((a, b) => a.id.compareTo(b.id));
    for (final m in active.skip(maxActiveMissions)) {
      m
        ..status = MissionStatus.offered
        ..deadline = 0
        ..days = 0
        ..progress = 0
        ..giverTown = null
        ..targetId = null
        ..encounter = null
        ..squad.clear();
    }
  }

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
    if (byStatus(s, MissionStatus.active).length >= maxActiveMissions) {
      return const ActionResult.fail(
        'Chỉ nhận tối đa $maxActiveMissions nhiệm vụ cùng lúc.',
      );
    }
    final t = templateById(m.templateId);
    String? target;
    Encounter? enc;
    if (t.kind == MissionKind.hunt) {
      // Nhận nhiệm vụ săn = tạo đúng MỘT điểm giao chiến thật trên bản đồ, gắn id ổn định với nhiệm vụ.
      enc = QuestGenerator.createEncounter(s, t.difficulty, rng(s));
      if (enc == null) {
        return const ActionResult.fail(
          'Không còn điểm giao chiến hợp lệ trên bản đồ.',
        );
      }
      target = QuestGenerator.idFor(m.id);
    } else {
      target = objectiveFor(s, t, town.id);
    }
    // Thời hạn riêng: random đúng một lần ở đây (rng của ván nên xác định theo seed), rồi chỉ đọc lại từ m.days/deadline.
    var travelDays = 0;
    if (enc != null) {
      final est = MovementRules.estimate(
        worldMap,
        s.hero.position,
        WPoint(enc.x, enc.y),
      );
      travelDays = (est.cost / TerrainRules.maxStamina).ceil();
    }
    final days = t.kind == MissionKind.hunt
        ? QuestGenerator.rollDays(rng(s), travelDays: travelDays)
        : t.days;
    m.status = MissionStatus.active;
    m.days = days;
    m.deadline = s.day + days;
    m.giverTown = town.id;
    m.encounter = enc;
    m.targetId = target;
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
      if (remainingDays(s, m) <= 0 || m.targetId == null) continue;
      if (targetPosition(s, m.targetId!) == null) continue;
      if (best == null ||
          m.deadline < best.deadline ||
          (m.deadline == best.deadline && m.id < best.id)) {
        best = m;
      }
    }
    return best;
  }

  /// Vị trí thế giới của mục tiêu [id]: thị trấn/điểm cố định của bản đồ, hoặc điểm giao chiến của nhiệm vụ săn đang làm.
  static WPoint? targetPosition(GameState s, String id) {
    final fixed = worldMap.positionOf(id);
    if (fixed != null) return fixed;
    final m = _encounterMission(s, id);
    return m == null ? null : WPoint(m.encounter!.x, m.encounter!.y);
  }

  static Mission? _encounterMission(GameState s, String id) {
    for (final m in s.missions) {
      if (m.status == MissionStatus.active &&
          m.encounter != null &&
          m.targetId == id) {
        return m;
      }
    }
    return null;
  }

  /// Địa điểm theo id: điểm cố định của catalog hoặc điểm giao chiến của nhiệm vụ săn đang làm (null nếu không có).
  static LocationDef? locationFor(GameState s, String id) {
    final fixed = locationById(id);
    if (fixed != null) return fixed;
    final m = _encounterMission(s, id);
    return m == null ? null : QuestGenerator.locationOf(m, m.encounter!);
  }

  /// Các điểm không phải thành phố hiển thị trên bản đồ, đọc từ state thật (không dựa trên icon hay biến UI):
  /// - điểm cố định đã biết, TRỪ điểm đã hoàn thành (trại đã quét sạch, tàn tích đã khám phá) — điểm xong biến mất hẳn,
  ///   không để lại vòng tròn dấu tích; ngoại lệ: còn nhiệm vụ đang làm trỏ tới nó thì vẫn hiện để báo cáo;
  /// - điểm giao chiến của mỗi nhiệm vụ săn ĐANG làm (nhiệm vụ xong/bỏ/hết hạn thì không còn điểm nào).
  static List<LocationDef> mapPoints(GameState s) {
    final targeted = <String>{
      for (final m in byStatus(s, MissionStatus.active))
        if (m.targetId != null && remainingDays(s, m) > 0) m.targetId!,
    };
    final out = <LocationDef>[];
    for (final l in visibleLocations(s)) {
      if (l.kind == LocKind.city) continue;
      final done = s.cleared.contains(l.id) || s.explored.contains(l.id);
      if (done && !targeted.contains(l.id)) continue;
      out.add(l);
    }
    for (final id in targeted) {
      if (out.any((l) => l.id == id)) continue;
      final l = locationFor(s, id);
      if (l != null && l.kind != LocKind.city) out.add(l);
    }
    return out;
  }

  /// Nhiệm vụ đang thực hiện còn hạn có mục tiêu tại địa điểm [locId].
  static List<Mission> activeAt(GameState s, String locId) => [
    for (final m in byStatus(s, MissionStatus.active))
      if (m.targetId == locId && remainingDays(s, m) > 0) m,
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
      MissionKind.visit ||
      MissionKind.hunt => m.progress,
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
    MissionKind.clear || MissionKind.visit || MissionKind.hunt => 1,
    _ => t.amount,
  };

  /// Số ngày còn lại của nhiệm vụ (<= 0: đã hết hạn). Suy ra từ `state.day`, nên chỉ đổi khi qua ngày thật sự.
  static int remainingDays(GameState s, Mission m) => m.deadline - s.day;

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
    if (remainingDays(s, m) <= 0) {
      return const ActionResult.fail('Nhiệm vụ đã hết hạn.');
    }
    if (!missionReady(s, m)) {
      return const ActionResult.fail('Chưa đạt mục tiêu.');
    }
    return _settle(s, m);
  }

  /// Chốt hoàn thành và trao thưởng ĐÚNG MỘT LẦN (chốt bằng `status` + `rewarded`). Mọi thay đổi state
  /// diễn ra sau khi mọi điều kiện đã kiểm tra, nên không có trạng thái trao dở dang.
  static ActionResult _settle(GameState s, Mission m, {QuestPayout? payout}) {
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
    // Phần thưởng: phần xác định (vàng/lương/uy tín/EXP) + phần ngẫu nhiên (tài nguyên đa dạng, trang bị)
    // rút từ rng của ván. Chốt `rewarded` ở trên bảo đảm chỉ rút/trao đúng một lần.
    final reward = QuestEconomy.of(t);
    final extras = QuestEconomy.rollExtras(rng(s), t, s.res);
    final granted = <Res, int>{...reward.res};
    for (final e in extras.res.entries) {
      granted[e.key] = (granted[e.key] ?? 0) + e.value;
    }
    grant(s, granted);
    payout?.res.addAll(granted);
    final itemRef = t.rewardItem != null
        ? EquipmentService.mint(s, t.rewardItem!)
        : (extras.itemDesign != null
              ? EquipmentService.mint(s, extras.itemDesign!)
              : null);
    if (itemRef != null) payout?.items.add(itemRef);
    if (reward.sat > 0) addSacredWill(s, reward.sat);
    payout?.sat = reward.sat;
    final exp = <String>[];
    if (reward.exp > 0) {
      final ids = [
        for (final id in m.squad)
          if (s.soldier(id)?.alive == true) id,
      ];
      // Chỉ người thật sự ở trong đội hoàn thành mục tiêu và còn phục vụ. Đội đã chết/đào ngũ hết thì KHÔNG ai nhận
      // (trước đây rơi về cả roster, thưởng cho cả quân dự bị không tham chiến).
      final who = [for (final id in ids) s.soldier(id)!];
      for (final so in who) {
        final ups = addXp(so, reward.exp);
        if (ups > 0) exp.add('${so.name} lên cấp ${so.level}');
        if (ups > 0) payout?.levelUps.add('${so.name} lên cấp ${so.level}');
      }
      payout?.exp = who.isEmpty ? 0 : reward.exp;
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
      if (granted.isNotEmpty) describeCost(granted),
      if (itemRef != null) itemDisplayName(itemRef),
      if (reward.exp > 0) '${reward.exp} EXP/người',
      if (reward.sat > 0) 'Uy tín +${reward.sat}',
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

    // Chi phí duy trì theo cấp từng binh sĩ còn phục vụ; trừ đúng một lần cho mỗi lần qua ngày.
    // Thiếu thì trả phần có thể trả, tinh thần cả quân giảm (không giết/xóa lính vì thiếu tiền).
    final upkeep = UpkeepEconomy.forSoldiers(s.roster);
    final dueFood = upkeep[Res.food]!;
    final dueCoins = upkeep[Res.coins]!;
    final paid = s.res[Res.food]! >= dueFood && s.res[Res.coins]! >= dueCoins;
    final paidFood = min(s.res[Res.food]!, dueFood);
    final paidCoins = min(s.res[Res.coins]!, dueCoins);
    s.res[Res.food] = s.res[Res.food]! - paidFood;
    s.res[Res.coins] = s.res[Res.coins]! - paidCoins;
    if (ledgerOut != null) {
      ledgerOut![Res.food] = (ledgerOut![Res.food] ?? 0) + paidFood;
      ledgerOut![Res.coins] = (ledgerOut![Res.coins] ?? 0) + paidCoins;
    }
    if (!paid) {
      lines.add('Không đủ lương thực/vàng trả cho quân đội! Tinh thần giảm.');
      for (final so in s.roster) {
        so.morale = max(0, so.morale + scaleVital(-8, moraleCap(so)));
      }
    } else if (level(s, Building.tavern) > 0) {
      // Quán rượu nâng mức Tinh thần cân bằng (70% + 5% mỗi cấp Quán rượu của mức tối đa, ±2%/ngày) cho lính đang
      // nghỉ trong Doanh trại. Lính nhàn rỗi / ở công trình khác KHÔNG hưởng; chưa xây Quán rượu thì không có.
      final pct = 0.70 + 0.05 * level(s, Building.tavern);
      for (final so in s.roster) {
        if (facilityOf(s, so.id)?.type != FacilityType.barracks) continue;
        final cap = moraleCap(so);
        final target = (cap * pct).round();
        final step = scaleVital(2, cap).abs();
        so.morale = so.morale < target
            ? min(target, so.morale + step)
            : max(target, so.morale - step);
      }
    }

    for (final name in sweepBrokenMorale(s)) {
      lines.add('$name bỏ trốn vì tinh thần cạn kiệt.');
    }
    for (final so in List.of(s.roster)) {
      if (so.morale <= desertMoraleFraction * moraleCap(so) &&
          rng(s).nextDouble() < 0.25) {
        desert(s, so);
        lines.add('${so.name} bỏ trốn vì kiệt quệ tinh thần.');
      }
    }

    // Công trình tác động binh sĩ được gán (cấu trúc VERIFIED; tốc độ hồi/huấn luyện PROPOSED) và nghỉ ngơi.
    for (final so in s.roster) {
      final f = facilityOf(s, so.id);
      final maxHp = so.maxHp;
      if (so.hp > maxHp) so.hp = maxHp;
      // HP chỉ hồi ở công trình có hiệu ứng HP (Lều cứu thương, theo cấp hiệu ứng); ngoài đó KHÔNG tự hồi.
      final heal = _infirmaryHeal(f?.type);
      if (heal != null && so.hp < maxHp) {
        so.hp = min(maxHp, so.hp + heal);
        if (so.hp >= maxHp) lines.add('${so.name} đã hồi phục hoàn toàn.');
      }
      if (so.needsTreatment && so.hp * 2 >= maxHp) {
        so.needsTreatment = false;
        lines.add('${so.name} đã được chữa trị, sẵn sàng ra trận.');
      }
      // Thể lực / Tinh thần chỉ đổi do công trình mà lính ĐƯỢC BỐ TRÍ vào, theo hiệu ứng của chính công trình đó.
      // Lính nhàn rỗi (không ở công trình nào) KHÔNG tự hồi. Mỗi lính ở tối đa một công trình nên không hồi trùng.
      _applyDailyPoints(so, f?.type);
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
      // Huấn luyện: mỗi chỉ số `++`/`+` của công trình tích tiến độ theo cấp công trình (xem [trainingRates]).
      // Tiến độ lưu nguyên (số nguyên phần trăm) trong [Soldier.train]; đạt 100 thì +1 điểm và giữ phần dư.
      if (f != null) {
        final rates = trainingRates(f.type, f.level);
        final open = [
          for (final e in rates.entries)
            if (so.stats[e.key]! < statCap(so)) e.key,
        ];
        if (rates.isNotEmpty && open.isEmpty) {
          f.assigned.remove(so.id);
          lines.add(
            '${so.name} đã đạt giới hạn chỉ số ở cấp này và rời ${facilityDefs[f.type]!.name}.',
          );
        }
        final capsBefore = vitalCaps(so);
        for (final st in open) {
          final rate =
              (rates[st]! * (so.trait == TraitId.quickLearner ? 1.3 : 1.0))
                  .round();
          so.train[st] = so.train[st]! + rate;
          while (so.train[st]! >= 100 && so.stats[st]! < statCap(so)) {
            so.train[st] = so.train[st]! - 100;
            so.stats[st] = so.stats[st]! + 1;
            lines.add('${so.name} tăng ${statNames[st]} lên ${so.stats[st]}.');
          }
          if (so.stats[st]! >= statCap(so)) {
            so.train[st] = min(so.train[st]!, 99);
          }
        }
        rebaseVitals(so, capsBefore);
      }
    }

    s.day++;
    restockShops(s);
    refreshCandidates(s); // danh sách ứng viên của Quán rượu làm mới mỗi ngày

    // Hết hạn = tự hủy, KHÔNG phạt (không trừ tài nguyên/hài lòng, không thưởng). Xóa hẳn nhiệm vụ nên điểm giao chiến
    // (suy ra từ nhiệm vụ) và slot cũng biến mất cùng lúc. Chạy sau lương/hồi phục để hết hạn không đổi các khoản đó.
    for (final m in byStatus(s, MissionStatus.active)) {
      if (!m.rewarded && remainingDays(s, m) <= 0) {
        final t = templateById(m.templateId);
        if (t.kind == MissionKind.hunt) {
          s.missions.remove(m);
          lines.add(
            'Nhiệm vụ "${t.title}" đã hết hạn và bị hủy vì quá thời gian.',
          );
          s.addLog('Nhiệm vụ ${t.title} hết hạn, tự hủy.');
        } else {
          // Mẫu hành chính cũ (không còn được sinh ra): giữ luật phạt hài lòng như trước.
          m.status = MissionStatus.failed;
          _addSat(s, -t.penaltySat);
          lines.add(
            'Quá hạn nhiệm vụ "${t.title}": nhà vua giảm ${t.penaltySat} hài lòng.',
          );
          s.addLog('Thất bại nhiệm vụ ${t.title}.');
        }
      }
    }
    fillBoard(s);
    final rescue = _maybeRelief(s);
    if (rescue != null) lines.add(rescue);
    if (s.gameOver) {
      lines.add('Nhà vua đã mất hết kiên nhẫn. Bạn bị cách chức.');
    }
    final report = DayReport(
      stipend: stipend,
      upkeep: upkeep,
      paidUpkeep: {Res.coins: paidCoins, Res.food: paidFood},
      paid: paid,
      lines: lines,
    );
    dayHook?.call(s);
    dayReportHook?.call(s, report);
    return report;
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
          final cap = energyCap(so);
          so.energy = (so.energy + scaleVital(pointsPerDay[e.level]!, cap))
              .clamp(0, cap);
        case EffectStat.morale:
          final cap = moraleCap(so);
          so.morale = (so.morale + scaleVital(moralePerDay[e.level]!, cap))
              .clamp(0, cap);
        default:
          break;
      }
    }
  }

  // ---------- Bản đồ & khám phá ----------

  static bool regionUnlocked(GameState s, RegionDef r) => s.tier >= r.minTier;

  static List<LocationDef> visibleLocations(GameState s) => [
    for (final l in locations)
      if (l.kind != LocKind.resource &&
          regionUnlocked(s, regionById(l.regionId)) &&
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

  /// Mô tả chiến lợi phẩm kỳ vọng của một trại địch, tính từ chính các kẻ địch sẽ gặp (cấp và trang bị).
  static String lootPreview(LocationDef loc) {
    final foes = previewEnemies(loc.enemies);
    final coins = LootEconomy.expectedCoins(foes).round();
    final gear = LootEconomy.expectedGearDrops(foes);
    return '~$coins vàng, tài nguyên ngẫu nhiên'
        '${gear >= 0.05 ? ', trang bị rơi theo xác suất' : ''}'
        '${loc.lootItem != null ? ' + ${itemDefs[loc.lootItem]!.name}' : ''}';
  }

  static Soldier buildEnemy(GameState s, EnemySpec spec, int index) =>
      _buildEnemy(rng(s), spec, index);

  static Soldier _buildEnemy(Random r, EnemySpec spec, int index) {
    final lvl = spec.level;
    final stats = {
      for (final st in Stat.values)
        st:
            roleBaseStats[spec.role]![st]! +
            StatFormulas.enemyLevelBonus(lvl) +
            r.nextInt(StatFormulas.startSpread),
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
      atkPoints:
          roleBaseAttack[spec.role]! +
          StatFormulas.enemyLevelBonus(lvl) +
          r.nextInt(StatFormulas.startSpread),
    );
    fillVitals(e);
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
    // XP chia theo sát thương hợp lệ đã gây (xem [distributeBattleXp]); chỉ người tham chiến có mặt trong báo cáo.
    final xpShare = distributeBattleXp(
      {
        for (final so in squad)
          if (rep.outcomes[so.id] != null) so.id: rep.outcomes[so.id]!.dealt,
      },
      {for (final u in rep.enemyUnits) u.id: (maxHp: u.maxHp, level: u.level)},
    );
    for (final so in squad) {
      final o = rep.outcomes[so.id]!;
      final energyBefore = so.energy;
      final moraleBefore = so.morale;
      so.battles++;
      so.kills += o.kills;
      var kind = CasualtyKind.survived;
      // Chỉ người tử trận rời công trình (đào ngũ đã tự gỡ trong [desert]); người sống GIỮ nguyên chỗ được gán.
      if (o.dead) {
        for (final f in s.facilities) {
          f.assigned.remove(so.id);
        }
      }
      // Thể trạng sau trận: chỉ người đã ra trận mới mất năng lượng; tinh thần theo sát thương nhận.
      so.energy = max(
        0,
        so.energy -
            battleEnergyCost(so, seconds: o.activeSeconds, swings: o.swings),
      );
      so.morale = o.finalMorale?.clamp(0, moraleCap(so)) ?? so.morale;
      var xp = 0;
      var ups = 0;
      if (o.dead) {
        so.status = SoldierStatus.dead;
        so.hp = 0;
        kind = CasualtyKind.dead;
        deaths++;
        s.fallenTotal++;
        s.addLog('${so.name} tử trận.');
      } else if (o.fled) {
        // Tinh thần về 0 giữa trận: bỏ chạy, đào ngũ vĩnh viễn; không XP.
        so.hp = o.finalHp.clamp(1, so.maxHp);
        desert(s, so, reason: '${so.name} bỏ chạy khỏi trận và đào ngũ.');
        kind = CasualtyKind.deserted;
      } else {
        so.hp = o.finalHp.clamp(1, so.maxHp);
        if (so.hp < so.maxHp * 0.5) kind = CasualtyKind.wounded;
        final base = xpShare[so.id] ?? 0;
        xp = xpGainFor(so, base); // số XP thật sự nhận (đã gồm Học nhanh), để màn kết quả hiển thị đúng
        ups = addXp(so, base);
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
        so.morale = (so.morale + scaleVital(won ? 8 : -10, moraleCap(so)))
            .clamp(0, moraleCap(so));
      }
      out.add(
        Casualty(
          so.id,
          so.name,
          kind,
          xp: xp,
          levelUps: ups,
          energyBefore: energyBefore,
          moraleBefore: moraleBefore,
          levelAfter: so.level,
          statPointsAfter: so.statPoints,
          fled: o.fled,
        ),
      );
    }
    if (deaths > 0) {
      for (final so in s.roster) {
        so.morale = max(
          0,
          so.morale +
              scaleVital(
                -(squad.contains(so) ? 6 : 4) * deaths.clamp(1, 3),
                moraleCap(so),
              ),
        );
      }
    }
    // Lính vừa lên cấp trong trận này: các khoản trừ thể trạng/tinh thần sau trận ở trên diễn ra SAU khi nhận EXP, nên
    // hồi đầy lại ở đây để ngay sau khi lên cấp cả ba chỉ số đúng bằng mức tối đa mới.
    for (var i = 0; i < out.length; i++) {
      if (out[i].levelUps <= 0) continue;
      final so = s.soldier(out[i].id);
      if (so == null || !so.alive) continue;
      restoreVitalsFull(so);
      if (out[i].kind == CasualtyKind.wounded) {
        out[i] = out[i].copyWith(kind: CasualtyKind.survived);
      }
    }
    // Tinh thần về 0 sau trận (kể cả do thương vong) → đào ngũ, đúng một lần.
    for (final so in List.of(s.roster)) {
      if (so.morale <= 0) {
        desert(s, so, reason: '${so.name} đào ngũ vì tinh thần cạn kiệt.');
        final i = out.indexWhere((c) => c.id == so.id);
        if (i >= 0) out[i] = out[i].copyWith(kind: CasualtyKind.deserted);
      }
    }
    // Chốt số liệu SAU cùng (đã gồm phạt thương vong/đào ngũ) một lần, để màn kết quả đọc ảnh chụp thay vì state sống.
    for (var i = 0; i < out.length; i++) {
      final so = s.soldier(out[i].id);
      if (so == null) continue;
      out[i] = out[i].copyWith(energyAfter: so.energy, moraleAfter: so.morale);
    }
    if (won) {
      s.battlesWon++;
    } else {
      s.battlesLost++;
    }
    return out;
  }

  // ---------- Viễn chinh ----------

  /// Xuất quân và giải quyết trận (nguyên tử). Đội xuất quân RỜI công trình trong lúc đi (không hưởng hiệu ứng công
  /// trình ở xa) và khi xong, người còn sống được TRẢ VỀ đúng công trình/thứ tự trước khi đi (kể cả khi chuyến đi thất
  /// bại hay thua trận). Vị trí đứng tự do trong trại ([Soldier.campX]/[Soldier.campY]) không bị đụng tới. Người
  /// tử trận / đào ngũ thì không được trả về.
  static ExpeditionResult sendExpedition(
    GameState s,
    String locId,
    List<int> squadIds,
    Set<int> frontIds, {
    Map<int, Pos>? placement,
  }) {
    final away = squadIds.toSet();
    final before = <int, List<int>>{
      for (final f in s.facilities) f.id: List.of(f.assigned),
    };
    for (final f in s.facilities) {
      f.assigned.removeWhere(away.contains);
    }
    try {
      return _sendExpedition(
        s,
        locId,
        squadIds,
        frontIds,
        placement: placement,
      );
    } finally {
      for (final f in s.facilities) {
        final orig = before[f.id];
        if (orig == null) continue;
        // Giữ thứ tự cũ: người không đi (nếu còn trong danh sách hiện tại) + người đi mà còn sống. Người đã đào ngũ /
        // tử trận / bị sa thải trong lúc đi không được thêm lại.
        final keep = [
          for (final id in orig)
            if (f.assigned.contains(id) ||
                (away.contains(id) && (s.soldier(id)?.alive ?? false)))
              id,
        ];
        // Người khác được gán trong lúc đi (không có luồng nào làm vậy) vẫn được giữ; tránh trùng và vượt chỗ.
        final extra = [
          for (final id in f.assigned)
            if (!keep.contains(id)) id,
        ];
        final merged = [...keep, ...extra];
        final cap = slotsOf(s, f);
        f.assigned
          ..clear()
          ..addAll(merged.take(cap));
      }
    }
  }

  static ExpeditionResult _sendExpedition(
    GameState s,
    String locId,
    List<int> squadIds,
    Set<int> frontIds, {
    Map<int, Pos>? placement,
  }) {
    ExpeditionResult fail(String m) => ExpeditionResult(ActionResult.fail(m));
    final blocked = _blocked(s);
    if (blocked != null) return fail(blocked.message);
    final loc = locationFor(s, locId);
    if (loc == null || !s.discovered.contains(locId) && !loc.startsDiscovered) {
      return fail('Địa điểm chưa được khám phá.');
    }
    // Điểm giao chiến của nhiệm vụ săn: chỉ đánh được khi nhân vật thật sự đã tới điểm đó (không tự mở trận).
    final enc = _encounterMission(s, locId)?.encounter;
    if (enc != null &&
        s.hero.position.distanceTo(WPoint(enc.x, enc.y)) >
            encounterArriveRadius) {
      return fail('Chưa tới điểm giao chiến.');
    }
    if (loc.kind == LocKind.resource) {
      return fail(
        'Nơi này không còn sản lượng thu hoạch: tài nguyên đến từ chiến đấu.',
      );
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
    // Điểm giao chiến của nhiệm vụ săn có thể hết hạn ngay trong lúc hành quân: không còn điểm thì không có trận.
    if (locationFor(s, locId) == null) {
      return fail(
        'Nhiệm vụ đã hết hạn trong lúc hành quân; điểm giao chiến không còn.',
      );
    }
    // Binh sĩ có thể đào ngũ trên đường đi.
    squad.removeWhere((x) => !x.alive);
    if (squad.isEmpty) return fail('Cả đội đã tan rã trên đường.');
    res.lines.add('Hành quân ${loc.days} ngày tới ${loc.name}.');

    /// Chiến lợi phẩm của trận THẮNG, rút từ chính kẻ địch đã đánh (cấp, trang bị). Mỗi lần gọi
    /// `sendExpedition` giải quyết đúng một trận nên chỉ trao đúng một lần; trận thua/hòa không gọi.
    void collectLoot(List<Soldier> enemies) {
      final loot = LootEconomy.roll(rng(s), enemies, s.res);
      grant(s, loot.res);
      for (final e in loot.res.entries) {
        res.gained[e.key] = (res.gained[e.key] ?? 0) + e.value;
      }
      for (final design in loot.items) {
        res.itemsGained.add(EquipmentService.mint(s, design));
      }
    }

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
        final foes = enemiesFor(s, loc.enemies);
        finishBattle(foes, ambush: false);
        if (res.battle!.winner == Winner.player) {
          // Điểm giao chiến của nhiệm vụ săn dùng một lần: nhiệm vụ hoàn thành là điểm biến mất, không cần ghi `cleared`.
          if (locationById(loc.id) != null) s.cleared.add(loc.id);
          collectLoot(foes);
          if (loc.lootItem != null) {
            // Phần thưởng đặc trưng của địa điểm (một lần vì địa điểm chỉ quét sạch một lần); là bản sao
            // riêng, có thể mang biến thể buff/debuff.
            res.itemsGained.add(EquipmentService.mint(s, loc.lootItem!));
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
        break; // đã bị chặn từ đầu hàm: không còn sản lượng thu hoạch
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
            final coins = 10 + r.nextInt(11) + 5 * s.tier;
            grant(s, {Res.coins: coins});
            res.gained[Res.coins] = (res.gained[Res.coins] ?? 0) + coins;
            res.lines.add('Tìm thấy kho báu: $coins vàng.');
            if (r.nextBool()) {
              res.itemsGained.add(
                EquipmentService.mint(s, rollGearDesign(r, 1 + s.tier)),
              );
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
                final payout = QuestPayout(t.title);
                final r = _settle(s, m, payout: payout);
                if (r.ok) {
                  res.missionNote = r.message;
                  res.payouts.add(payout);
                }
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
      if (t.kind == MissionKind.hunt && m.targetId == locId) {
        if (remainingDays(s, m) <= 0) continue;
        m.progress = 1;
        m.squad
          ..clear()
          ..addAll(squad.map((x) => x.id));
        // Thắng trận = hoàn thành: trao thưởng ngay, đúng một lần (chốt `rewarded`).
        final payout = QuestPayout(t.title);
        final r = _settle(s, m, payout: payout);
        res.missionNote = r.ok ? r.message : null;
        if (r.ok) res.payouts.add(payout);
        continue;
      }
      if (t.kind == MissionKind.clear && t.locId == locId) {
        if (remainingDays(s, m) <= 0) continue;
        if (squad.length >= t.minSoldiers) {
          m.progress = 1;
          m.squad
            ..clear()
            ..addAll(squad.map((x) => x.id));
          // Thắng trận = hoàn thành mục tiêu: trao thưởng ngay, đúng một lần.
          final payout = QuestPayout(t.title);
          final r = _settle(s, m, payout: payout);
          if (r.ok) res.payouts.add(payout);
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
