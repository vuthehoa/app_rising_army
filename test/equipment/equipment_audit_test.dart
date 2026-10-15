import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/battle.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/equipment/equipment_catalog.dart';
import 'package:app_rising_army/domain/equipment/equipment_effect.dart';
import 'package:app_rising_army/domain/equipment/equipment_generator.dart';
import 'package:app_rising_army/domain/equipment/equipment_ref.dart';
import 'package:app_rising_army/domain/equipment/equipment_rules.dart';
import 'package:app_rising_army/domain/equipment/equipment_service.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/domain/stats.dart';
import 'package:app_rising_army/presentation/widgets/art/soldiers/soldier_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/built_camp.dart';

// ---------------------------------------------------------------- Tiện ích

Soldier mk(
  int id,
  Role role, {
  int str = 12,
  int dex = 10,
  int con = 10,
  String? weapon,
  String? armor,
  String? shield,
}) {
  final s = Soldier(
    id: id,
    name: 'S$id',
    role: role,
    stats: {Stat.str: str, Stat.dex: dex, Stat.con: con},
    level: 6,
    weaponId: weapon,
    armorId: armor,
    shieldId: shield,
  );
  s.hp = deriveStats(s).maxHp;
  return s;
}

String variant(String design, bool Function(List<EquipmentEffect>) test) {
  final d = itemDefs[design]!;
  for (var i = 1; i < 60000; i++) {
    final v = EquipmentGenerator.variantIdFromEntropy(i);
    if (test(EquipmentGenerator.effectsFor(d, v))) return makeRef(design, v);
  }
  throw StateError('không có biến thể phù hợp cho $design');
}

String snap(GameState s) => jsonEncode(s.toJson());

/// Mô phỏng lại ĐÚNG chuỗi số ngẫu nhiên của `simulateBattle` cho đòn đầu tiên của đơn vị id thấp nhất
/// (mọi thứ gần nhau, trong tầm): hit → crit → rút sát thương vũ khí (nguyên, đều trong min–max).
({bool hit, bool crit, int dmg, int roll}) expectedFirstHit(
  int seed, {
  required Derived d,
  required double targetDefense,
  double extraFlat = 0,
}) {
  final r = Random(seed);
  final hit = r.nextDouble() < d.accuracy;
  if (!hit) return (hit: false, crit: false, dmg: 0, roll: 0);
  final c = r.nextDouble() < d.crit;
  final roll = d.weaponMin + r.nextInt(d.weaponMax - d.weaponMin + 1);
  var raw =
      (roll + d.attackFlat + extraFlat) *
      d.attackMult *
      d.moraleMult *
      damageScale;
  if (c) raw *= 1.5;
  final dmg = max(
    1,
    (raw * (1 - Derived.reductionFor(targetDefense, d.armorPen))).round(),
  );
  return (hit: true, crit: c, dmg: dmg, roll: roll);
}

BattleReport duel(BattleUnit a, BattleUnit b, int seed) =>
    simulateBattle([a], [b], seed);

BattleUnit unit(Soldier s, bool player, double x, {double y = 10, int? hp}) {
  final u = unitFrom(s, player: player, at: Pos(x, y));
  if (hp != null) u.hp = hp;
  return u;
}

void main() {
  // ================================================================ 2. Tổ hợp vũ khí/khiên
  group('Tổ hợp vũ khí và khiên (mọi thất bại giữ nguyên trạng thái)', () {
    GameState fresh() {
      final s = newGameWithBuiltCamp();
      s.inventory.clear();
      for (final so in s.soldiers) {
        so
          ..weaponId = null
          ..armorId = null
          ..shieldId = null
          ..level = 6;
        so.stats[Stat.str] = 30;
      }
      return s;
    }

    int copies(GameState s) =>
        s.inventory.values.fold<int>(0, (a, b) => a + b) +
        s.soldiers.fold<int>(
          0,
          (a, x) =>
              a + Slot.values.where((sl) => x.equipped(sl) != null).length,
        );

    test('1 tay + khiên → 2 tay (khiên về kho) → rương quá tải → 1 tay lại → khiên lại', () {
      final s = fresh();
      final so = s.roster.first;
      s.inventory
        ..['arming_sword'] = 1
        ..['round_shield'] = 1
        ..['iron_zweihander'] = 1;
      final total = copies(s);
      expect(GameRules.equip(s, so.id, 'arming_sword').ok, isTrue);
      expect(GameRules.equip(s, so.id, 'round_shield').ok, isTrue);
      expect((so.weaponId, so.shieldId), ('arming_sword', 'round_shield'));

      // Chừa [room] (1/10 kg) trong rương bằng đá làm đối trọng.
      void setRoom(int room) {
        s.res[Res.stone] = 0;
        final foodBase = s.res[Res.food]!;
        final free =
            GameRules.inventoryCapacityTenths(s) -
            GameRules.inventoryWeightTenths(s);
        s.res[Res.stone] = (free - room) ~/ 10;
        // Phần lẻ (< 1 kg) bù bằng lương thực (0.1 kg/đơn vị) để chỗ trống đúng bằng [room].
        s.res[Res.food] = foodBase + (free - room) % 10;
        expect(
          GameRules.inventoryCapacityTenths(s) -
              GameRules.inventoryWeightTenths(s),
          room,
        );
      }

      // 2 tay nặng hơn kiếm + khiên cũ trả về kho: +1.2 kg. Chỗ trống 1.0 kg → từ chối, giữ nguyên.
      setRoom(10);
      final before = snap(s);
      final r = GameRules.equip(s, so.id, 'iron_zweihander');
      expect(r.ok, isFalse);
      expect(snap(s), before);

      // Có chỗ: thành công, khiên và kiếm cũ về kho.
      setRoom(20);
      expect(GameRules.equip(s, so.id, 'iron_zweihander').ok, isTrue);
      expect(so.weaponId, 'iron_zweihander');
      expect(so.shieldId, isNull);
      expect(s.inventory['round_shield'], 1);
      expect(s.inventory['arming_sword'], 1);
      expect(EquipmentService.audit(s), isEmpty);

      // Đổi từ 2 tay sang 1 tay làm rương nặng thêm 2.8 kg: hết chỗ thì từ chối, đủ chỗ thì được.
      setRoom(20);
      final beforeSwap = snap(s);
      expect(GameRules.equip(s, so.id, 'arming_sword').ok, isFalse);
      expect(snap(s), beforeSwap);
      setRoom(30);
      expect(GameRules.equip(s, so.id, 'arming_sword').ok, isTrue);
      expect(so.weaponId, 'arming_sword');
      expect(s.inventory['iron_zweihander'], 1);
      // Khiên đeo lại được.
      expect(GameRules.equip(s, so.id, 'round_shield').ok, isTrue);
      expect(so.shieldId, 'round_shield');
      expect(copies(s), total, reason: 'không mất/nhân đôi');
      expect(EquipmentService.audit(s), isEmpty);
    });

    test(
      'tháo + thay cùng loại; sai ô; hai tướng; mọi lỗi giữ nguyên state',
      () {
        final s = fresh();
        final a = s.roster[0], b = s.roster[1];
        final rare = variant('iron_spear', (e) => e.isNotEmpty);
        s.inventory
          ..['dagger'] = 1
          ..['short_sword'] = 1
          ..['leather_armor'] = 1
          ..[rare] = 1;
        expect(GameRules.equip(s, a.id, 'dagger').ok, isTrue);
        expect(
          GameRules.equip(s, a.id, 'short_sword').ok,
          isTrue,
        ); // thay cùng loại
        expect(s.inventory['dagger'], 1);
        expect(GameRules.unequip(s, a.id, Slot.weapon).ok, isTrue);
        expect(a.weaponId, isNull);
        expect(GameRules.equip(s, a.id, rare).ok, isTrue);

        final failures = <String, ActionResult Function()>{
          'sai ô': () =>
              GameRules.equip(s, b.id, 'leather_armor', slot: Slot.weapon),
          'biến thể đã mặc ở tướng khác': () => GameRules.equip(s, b.id, rare),
          'không có trong kho': () => GameRules.equip(s, b.id, 'plate_armor'),
          'mã lạ': () => GameRules.equip(s, b.id, 'khong_co'),
          'tướng không tồn tại': () =>
              GameRules.equip(s, 424242, 'leather_armor'),
          'ô trống': () => GameRules.unequip(s, b.id, Slot.armor),
        };
        for (final e in failures.entries) {
          final before = snap(s);
          expect(e.value().ok, isFalse, reason: e.key);
          expect(snap(s), before, reason: e.key);
        }
        // Tướng đã chết không trang bị được.
        b.status = SoldierStatus.dead;
        final before = snap(s);
        expect(GameRules.equip(s, b.id, 'leather_armor').ok, isFalse);
        expect(snap(s), before);
        expect(EquipmentService.audit(s), isEmpty);
      },
    );
  });

  // ================================================================ 3. Chỉ số trong battle engine
  group('Battle engine nhận đúng chỉ số/hiệu ứng, không áp dụng hai lần', () {
    test('đòn đầu = (rút đều min–max + phần chỉ số) × hệ số, đúng MỘT lần cộng buff Công của trang bị', () {
      final ref = variant(
        'royal_sword',
        (e) =>
            e.length == 1 &&
            e.single.stat == GearStat.attack &&
            e.single.value >= 1,
      );
      final bonus = EquipmentItemEffects.flatAttack(ref).round();
      final seenRolls = <int>{};
      var sensitive = 0;
      for (var seed = 1; seed <= 80; seed++) {
        final base = mk(1, Role.spearman, weapon: 'royal_sword');
        final withFx = mk(1, Role.spearman, weapon: ref);
        final tgt = mk(2, Role.spearman);
        final ub = unit(base, true, 10), uf = unit(withFx, true, 10);
        // Buff Công của trang bị đi qua deriveStats đúng một lần: chỉ số Công hiệu dụng tăng đúng [bonus].
        expect(uf.d.core.atk, ub.d.core.atk + bonus);
        expect(
          uf.d.attackFlat - ub.d.attackFlat,
          closeTo(bonus * atkPerPoint, 1e-9),
        );
        final t = unit(tgt, false, 11, hp: 100000);
        final rep = duel(uf, t, seed);
        final ev = rep.events.first;
        final exp = expectedFirstHit(seed, d: uf.d, targetDefense: t.d.defense);
        expect(ev.hit, exp.hit, reason: 'seed $seed');
        expect(ev.damage, exp.dmg, reason: 'seed $seed');
        if (exp.hit) seenRolls.add(exp.roll);
        final dbl = expectedFirstHit(
          seed,
          d: uf.d,
          targetDefense: t.d.defense,
          extraFlat: bonus * atkPerPoint,
        );
        if (dbl.hit && dbl.dmg != exp.dmg) sensitive++;
      }
      expect(
        sensitive,
        greaterThan(5),
        reason: 'bài kiểm tra phải đủ nhạy để bắt lỗi cộng đôi',
      );
      final w = itemDefs['royal_sword']!;
      expect(
        seenRolls.every((r) => r >= w.damageMin && r <= w.damageMax),
        isTrue,
        reason: 'mỗi đòn rút sát thương trong khoảng vũ khí',
      );
      expect(
        seenRolls.length,
        greaterThan(1),
        reason: 'sát thương vũ khí là khoảng, không phải một số cố định',
      );
    });

    test(
      'mọi hiệu ứng trang bị sinh ra chỉ là bốn chỉ số gốc, số nguyên, cố định',
      () {
        for (final d in EquipmentCatalog.all) {
          for (final e in d.traits) {
            expect(
              e.isValidForGear,
              isTrue,
              reason: '${d.id}: ${e.describe()}',
            );
          }
          for (var i = 1; i <= 400; i++) {
            final v = EquipmentGenerator.variantIdFromEntropy(i);
            for (final e in EquipmentGenerator.effectsFor(d, v)) {
              expect(
                e.isValidForGear,
                isTrue,
                reason: '${d.id}~$v: ${e.describe()}',
              );
            }
          }
        }
      },
    );

    test('tải trọng: công thức 12+1.6×STR, trần −30% tốc độ / +15% chu kỳ, và battle di chuyển/đánh theo đó', () {
      expect(EquipmentRules.carryCapacity(10), 12 + 1.6 * 10);
      Soldier mkLoad(int id, int str) => mk(
        id,
        Role.spearman,
        str: str,
        weapon: 'iron_spear',
        armor: 'titan_harness',
      );
      final strong = mkLoad(1, 40), weak = mkLoad(1, 1);
      final ds = deriveStats(strong), dw = deriveStats(weak);
      expect(ds.encumbrance!.overloaded, isFalse);
      expect(
        dw.encumbrance!.excess,
        closeTo(dw.encumbrance!.load - (12 + 1.6 * 1), 1e-9),
      );
      expect(
        dw.encumbrance!.speedMult,
        closeTo(0.70, 1e-9),
        reason: 'chạm trần −30%',
      );
      expect(
        dw.encumbrance!.intervalMult,
        closeTo(1.15, 1e-9),
        reason: 'chạm trần +15%',
      );
      expect(dw.speed / ds.speed, closeTo(0.70, 1e-9));
      expect(dw.interval / ds.interval, closeTo(1.15, 1e-9));
      // Dưới trần: phạt tỷ lệ theo kg vượt (2.5%/kg, 1%/kg).
      final mid = mk(
        1,
        Role.spearman,
        str: 8,
        weapon: 'iron_spear',
        armor: 'titan_harness',
      );
      final dm = deriveStats(mid);
      final ex = dm.encumbrance!.excess;
      expect(ex, greaterThan(0));
      expect(ex * 0.025, lessThan(0.30));
      expect(dm.encumbrance!.speedMult, closeTo(1 - 0.025 * ex, 1e-9));

      // Trong battle: quãng đường đi được sau 1 giây tỉ lệ đúng 0.70, và chu kỳ đánh của đơn vị khớp.
      double travelled(Soldier s) {
        final a = unit(s, true, 2, y: 12);
        final e = unit(
          mk(2, Role.spearman, str: 40),
          false,
          38,
          y: 12,
          hp: 1000000,
        );
        final rep = simulateBattle([a], [e], 3);
        final f = rep.frames.firstWhere((f) => f.t >= 1.0 - 1e-9);
        return f.units[1]!.x - 2;
      }

      final ratio = travelled(weak) / travelled(strong);
      expect(ratio, closeTo(0.70, 0.01));
      expect(unit(weak, true, 0).d.interval, closeTo(dw.interval, 1e-9));
    });

    test('mọi chỉ số của BattleUnit = deriveStats (một nguồn), kể cả khi mặc đồ biến thể', () {
      final armor = variant('half_plate', (e) => e.length >= 2);
      final weapon = variant('royal_sword', (e) => e.length >= 2);
      final so = mk(
        1,
        Role.spearman,
        str: 20,
        weapon: weapon,
        armor: armor,
        shield: 'round_shield',
      );
      final d = deriveStats(so);
      final u = unit(so, true, 5);
      expect(u.d.attack, d.attack);
      expect(u.d.defense, d.defense);
      expect(u.d.speed, d.speed);
      expect(u.d.interval, d.interval);
      expect(u.d.accuracy, d.accuracy);
      expect(u.d.crit, d.crit);
      expect(u.d.maxHp, d.maxHp);
      expect(u.d.armorPen, d.armorPen);
    });
  });

  // ================================================================ 4. Save/load tổng hợp
  group('Save/load tổng hợp', () {
    test('nhiều tướng, nhiều bản sao, biến thể khác nhau, 2 tay + khiên, id cũ và dữ liệu lạ', () async {
      final s = newGameWithBuiltCamp();
      s.inventory.clear();
      for (final so in s.soldiers) {
        so
          ..weaponId = null
          ..armorId = null
          ..shieldId = null
          ..level = 6;
        so.stats[Stat.str] = 30;
      }
      final r = s.roster;
      final v1 = variant('royal_sword', (e) => e.length >= 2);
      final v2 = variant(
        'royal_sword',
        (e) =>
            e.length >= 2 &&
            !e.every(
              (x) => EquipmentGenerator.effectsFor(
                itemDefs['royal_sword']!,
                variantIdOf(v1)!,
              ).contains(x),
            ),
      );
      final v3 = variant('half_plate', (e) => e.isNotEmpty);
      s.inventory
        ..['dagger'] =
            3 // tiêu chuẩn nhiều bản
        ..[v1] = 1
        ..[v2] = 1
        ..[v3] = 1
        ..['wooden_shield'] = 2
        ..['iron_zweihander'] = 1
        ..['sun_blade'] = 1
        ..['ao_la_tuong_lai'] =
            1 // dữ liệu lạ
        ..['padded_armor'] = 2;
      expect(GameRules.equip(s, r[0].id, v1).ok, isTrue);
      expect(GameRules.equip(s, r[0].id, 'wooden_shield').ok, isTrue);
      expect(GameRules.equip(s, r[1].id, 'iron_zweihander').ok, isTrue);
      expect(GameRules.equip(s, r[1].id, v3).ok, isTrue);
      expect(GameRules.equip(s, r[2].id, 'dagger').ok, isTrue);
      expect(GameRules.equip(s, r[2].id, 'wooden_shield').ok, isTrue);
      r[3].weaponId = 'thanh_kiem_la'; // ô chứa mã lạ

      final store = MemoryStore();
      await SaveRepository(store).save(s);
      final loaded = (await SaveRepository(store).load()).state!;

      for (final so in s.soldiers) {
        final lo = loaded.soldier(so.id)!;
        for (final slot in Slot.values) {
          final expected = (so.id == r[3].id && slot == Slot.weapon)
              ? null
              : so.equipped(slot);
          expect(
            lo.equipped(slot),
            expected,
            reason: '${so.name}/${slot.name}',
          );
        }
        if (so.id != r[3].id) {
          final a = deriveStats(so), b = deriveStats(lo);
          expect(
            (
              b.maxHp,
              b.attack,
              b.defense,
              b.speed,
              b.interval,
              b.accuracy,
              b.crit,
              b.armorPen,
              b.gearWeight,
            ),
            (
              a.maxHp,
              a.attack,
              a.defense,
              a.speed,
              a.interval,
              a.accuracy,
              a.crit,
              a.armorPen,
              a.gearWeight,
            ),
            reason: so.name,
          );
        }
      }
      for (final e in s.inventory.entries) {
        if (e.key == 'ao_la_tuong_lai') continue;
        expect(loaded.inventory[e.key], e.value, reason: e.key);
      }
      expect(loaded.inventory.containsKey('ao_la_tuong_lai'), isFalse);
      final q = (loaded.legacy!['quarantinedItems'] as List)
          .map((e) => (e as Map)['ref'])
          .toSet();
      expect(
        q,
        containsAll(['ao_la_tuong_lai', 'thanh_kiem_la']),
        reason: 'dữ liệu lạ được cách ly, không xóa âm thầm',
      );
      expect(EquipmentService.audit(loaded), isEmpty);
      // Lưu-tải lần nữa không đổi thêm.
      await SaveRepository(store).save(loaded);
      final again = (await SaveRepository(store).load()).state!;
      expect(snap(again), snap(loaded));
    });
  });

  // ================================================================ 5. Ngoại hình
  group('Ngoại hình', () {
    Future<Uint8List> raster(SoldierSprite sp, {double size = 120}) async {
      final rec = ui.PictureRecorder();
      SoldierPainter(sp).paint(Canvas(rec), Size(size, size));
      final img = await rec.endRecording().toImage(size.toInt(), size.toInt());
      return (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer
          .asUint8List();
    }

    /// Số điểm ảnh KHÁC nhau trong nửa dưới (mặt) của đầu.
    int faceDiff(
      Uint8List a,
      Uint8List b, {
      required bool bust,
      double size = 120,
    }) {
      final cx = size * 0.5,
          cy = size * (bust ? 0.34 : 0.24),
          hr = size * (bust ? 0.2 : 0.16);
      var n = 0;
      for (var y = cy.floor(); y < (cy + hr * 0.85).ceil(); y++) {
        for (
          var x = (cx - hr * 0.85).floor();
          x < (cx + hr * 0.85).ceil();
          x++
        ) {
          final dx = x + 0.5 - cx, dy = y + 0.5 - cy;
          if (dx * dx + dy * dy > hr * hr * 0.7 || dy < 2) continue;
          final i = (y * size.toInt() + x) * 4;
          if (a[i] != b[i] ||
              a[i + 1] != b[i + 1] ||
              a[i + 2] != b[i + 2] ||
              a[i + 3] != b[i + 3]) {
            n++;
          }
        }
      }
      return n;
    }

    testWidgets(
      'vũ khí/khiên/áo giáp không bao giờ che mặt (đầu vẽ sau cùng) — cả 170 thiết kế, bust và toàn thân',
      (t) async {
        await t.runAsync(() async {
          for (final bust in [true, false]) {
            SoldierSprite sprite({String? a, String? w, String? sh}) =>
                SoldierSprite(
                  role: Role.spearman,
                  seed: 2,
                  armorId: a,
                  weaponId: w,
                  shieldId: sh,
                  bust: bust,
                  size: 120,
                );
            final none = await raster(sprite());
            for (final d in EquipmentCatalog.all) {
              final img = await raster(
                sprite(
                  a: d.slot == Slot.armor ? d.id : null,
                  w: d.slot == Slot.weapon ? d.id : null,
                  sh: d.slot == Slot.shield ? d.id : null,
                ),
              );
              expect(
                faceDiff(none, img, bust: bust),
                0,
                reason: '${d.id} bust=$bust che mặt',
              );
            }
          }
        });
      },
    );

    testWidgets(
      'vũ khí hai tay: không có khiên trên hình; vũ khí một tay + khiên: có khiên; đổi từng món đổi hình',
      (t) async {
        await t.runAsync(() async {
          SoldierSprite sp({String? a, String? w, String? sh}) => SoldierSprite(
            role: Role.spearman,
            seed: 2,
            armorId: a,
            weaponId: w,
            shieldId: sh,
            bust: false,
            size: 120,
          );
          final twoNoShield = await raster(
            sp(a: 'chain_mail', w: 'iron_zweihander'),
          );
          final twoShield = await raster(
            sp(a: 'chain_mail', w: 'iron_zweihander', sh: 'tower_shield'),
          );
          expect(twoShield, twoNoShield);
          final oneNoShield = await raster(
            sp(a: 'chain_mail', w: 'arming_sword'),
          );
          final oneShield = await raster(
            sp(a: 'chain_mail', w: 'arming_sword', sh: 'tower_shield'),
          );
          expect(oneShield, isNot(oneNoShield));
          // Đổi từng món cho hình khác nhau.
          final seen = <String>{};
          for (final a in [
            'padded_armor',
            'chain_mail',
            'plate_armor',
            'full_plate',
          ]) {
            seen.add(
              base64.encode(
                await raster(sp(a: a, w: 'arming_sword', sh: 'round_shield')),
              ),
            );
          }
          for (final w in [
            'dagger',
            'arming_sword',
            'battle_axe',
            'iron_spear',
          ]) {
            seen.add(
              base64.encode(
                await raster(sp(a: 'chain_mail', w: w, sh: 'round_shield')),
              ),
            );
          }
          for (final sh in [
            'wooden_shield',
            'kite_shield',
            'tower_shield',
            'dragon_shield',
          ]) {
            seen.add(
              base64.encode(
                await raster(sp(a: 'chain_mail', w: 'arming_sword', sh: sh)),
              ),
            );
          }
          // 12 cấu hình, trong đó cấu hình gốc (chain_mail + arming_sword + round_shield) xuất hiện hai lần.
          expect(seen.length, 11);
        });
      },
    );
  });
}

/// Truy cập hiệu ứng của một mã tham chiếu trong test.
abstract final class EquipmentItemEffects {
  static EquipmentEffect first(String ref) =>
      EquipmentGenerator.effectsFor(itemDefs[ref]!, variantIdOf(ref)!).first;
  static double flatAttack(String ref) => first(ref).value;
}
