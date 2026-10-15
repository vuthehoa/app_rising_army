import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/application/hero_travel.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/movement.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/domain/terrain_type.dart';
import 'package:app_rising_army/domain/world_data.dart';
import 'package:app_rising_army/domain/world_map.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tìm điểm mà `terrainAt` thỏa [pred] bằng cách quét lưới.
WPoint find(bool Function(TerrainType t, WPoint p) pred, {double step = 10}) {
  for (var y = 0.0; y < worldMap.height; y += step) {
    for (var x = 0.0; x < worldMap.width; x += step) {
      final p = WPoint(x, y);
      if (pred(worldMap.terrainAt(p), p)) return p;
    }
  }
  throw StateError('không tìm thấy');
}

/// Đoạn ngang dài [len] bắt đầu từ [a] chỉ gồm địa hình [t] và không chạm đường mòn.
bool uniformRun(WPoint a, TerrainType t, double len) {
  for (var d = 0.0; d <= len; d += 2) {
    final p = WPoint(a.x + d, a.y);
    if (worldMap.terrainAt(p) != t || worldMap.onTrail(p)) return false;
  }
  return true;
}

WPoint runOf(TerrainType t, {double len = 120}) =>
    find((tt, p) => tt == t && uniformRun(p, t, len), step: 8);

double costFor(WPoint a, WPoint b) =>
    MovementRules.estimate(worldMap, a, b).cost;

void main() {
  group('Luật di chuyển thuần', () {
    test('đứng yên không tốn thể lực', () {
      final p = worldMap.start;
      final r = MovementRules.advance(
        worldMap,
        from: p,
        to: p,
        stamina: 50,
        maxDistance: 100,
      );
      expect(r.status, MoveStatus.arrived);
      expect(r.stamina, 50);
      expect(r.position, p);
    });

    test(
      'đi từng bước: một lần cập nhật chỉ đi tối đa quãng đường theo thời gian',
      () {
        final from = worldMap.start;
        final to = WPoint(from.x + 400, from.y);
        final r = MovementRules.advance(
          worldMap,
          from: from,
          to: to,
          stamina: 100,
          maxDistance: 10,
        );
        expect(r.status, MoveStatus.moving);
        expect(r.position.distanceTo(from), closeTo(10, 1e-6));
        expect(r.travelled, closeTo(10, 1e-6));
      },
    );

    test('đường mòn rẻ hơn đồng bằng ngoài đường với cùng quãng đường', () {
      final trail = worldMap.trails.first.path.points;
      // Đoạn đường mòn nhìn gần như thẳng ở đồng bằng/bãi cỏ: lấy hai điểm liền kề cách ~100.
      final a = WPoint(1500, 1390), b = WPoint(1600, 1395);
      expect(worldMap.onTrail(a), isTrue);
      expect(trail, isNotEmpty);
      final plain = runOf(TerrainType.meadow);
      final onTrail = costFor(a, WPoint(a.x + 60, a.y));
      final offTrail = costFor(plain, WPoint(plain.x + 60, plain.y));
      expect(onTrail, lessThan(offTrail));
      expect(b.x, greaterThan(a.x));
    });

    test('rừng, núi, đồi tốn hơn đồng bằng; rừng rậm tốn hơn rừng thưa', () {
      double per(TerrainType t) {
        final a = runOf(t, len: 80);
        return costFor(a, WPoint(a.x + 80, a.y)) / 80;
      }

      final plain = per(TerrainType.meadow);
      expect(per(TerrainType.forest), greaterThan(plain));
      expect(
        per(TerrainType.denseForest),
        greaterThan(per(TerrainType.forest)),
      );
      expect(per(TerrainType.hill), greaterThan(plain));
      expect(
        per(TerrainType.mountain),
        greaterThan(per(TerrainType.denseForest)),
      );
    });

    test('chi phí được tính theo từng đoạn: tổng hai đoạn khác địa hình', () {
      final m = runOf(TerrainType.meadow, len: 60);
      // Tìm điểm rừng liền kề đồng bằng theo trục ngang.
      final edge = find((t, p) {
        if (t != TerrainType.meadow || worldMap.onTrail(p)) return false;
        final q = WPoint(p.x + 40, p.y);
        final r = WPoint(p.x + 80, p.y);
        return worldMap.terrainAt(q) == TerrainType.forest &&
            worldMap.terrainAt(r) == TerrainType.forest &&
            !worldMap.onTrail(q) &&
            !worldMap.onTrail(r) &&
            uniformRun(WPoint(p.x - 40, p.y), TerrainType.meadow, 40);
      }, step: 4);
      expect(m, isNotNull);
      final end = WPoint(edge.x + 80, edge.y);
      final mixed = costFor(edge, end);
      final allMeadow = 80 * TerrainRules.costPerUnit(TerrainType.meadow);
      final allForest = 80 * TerrainRules.costPerUnit(TerrainType.forest);
      expect(mixed, greaterThan(allMeadow));
      expect(mixed, lessThan(allForest));
    });

    test('hết thể lực: dừng đúng điểm cho phép, thể lực không âm', () {
      final a = runOf(TerrainType.meadow, len: 300);
      final perUnit = TerrainRules.costPerUnit(TerrainType.meadow);
      final stamina = perUnit * 100; // đủ đi đúng 100 đơn vị
      final r = MovementRules.advance(
        worldMap,
        from: a,
        to: WPoint(a.x + 300, a.y),
        stamina: stamina,
        maxDistance: 1000,
      );
      expect(r.status, MoveStatus.exhausted);
      expect(r.stamina, 0);
      expect(r.travelled, closeTo(100, 0.5));
      expect(r.position.x - a.x, closeTo(100, 0.5));
      // Thể lực 0 thì không đi thêm.
      final again = MovementRules.advance(
        worldMap,
        from: r.position,
        to: WPoint(a.x + 300, a.y),
        stamina: 0,
        maxDistance: 1000,
      );
      expect(again.status, MoveStatus.exhausted);
      expect(again.position, r.position);
    });

    test('sông và vách đá đi qua được nhưng tốn thể lực gấp 2× địa hình đi bộ khó nhất', () {
      // Từ bờ tây Sông Bạc đi thẳng sang đông tại chỗ không có cầu.
      const from = WPoint(1000, 700);
      const to = WPoint(1700, 700);
      expect(worldMap.isPassable(from), isTrue);
      final est = MovementRules.estimate(worldMap, from, to);
      expect(est.reachable, isTrue, reason: 'không còn bị chặn');
      expect(est.blockedBy, isNull);
      // Đắt hơn đi cùng quãng trên đất bằng (có đoạn vượt nước).
      expect(
        est.cost,
        greaterThan(est.distance * TerrainRules.baseCostPerUnit),
      );
      final r = MovementRules.advance(
        worldMap,
        from: from,
        to: to,
        stamina: 100,
        maxDistance: 2000,
      );
      expect(r.status, MoveStatus.arrived);
      expect(r.position, to);
      // Giá thật của từng bước nước/vách đá = base × crossingMultiplier, và đường mòn không giảm giá ở đó.
      final water = find((t, p) => t == TerrainType.water);
      final perUnit = worldMap.costPerUnitAt(water);
      expect(
        perUnit,
        closeTo(
          TerrainRules.baseCostPerUnit * TerrainRules.crossingMultiplier,
          1e-12,
        ),
      );
      expect(
        TerrainRules.crossingMultiplier,
        TerrainRules.crossingFactor *
            TerrainRules.multiplier(TerrainType.mountain),
      );
      expect(
        perUnit,
        greaterThan(TerrainRules.costPerUnit(TerrainType.mountain)),
      );
      expect(
        TerrainRules.costPerUnit(TerrainType.water, onTrail: true),
        perUnit,
      );
      final cliff = find((t, p) => t == TerrainType.cliff);
      expect(worldMap.costPerUnitAt(cliff), perUnit);
      // Cầu rẻ hơn lội nước nhiều.
      expect(
        TerrainRules.costPerUnit(TerrainType.bridge),
        lessThan(perUnit / 4),
      );
    });

    test('đi ngoài đường (không có làn đường) tốn hơn đi trên đường mòn', () {
      final plain = TerrainRules.costPerUnit(TerrainType.plain);
      final trail = TerrainRules.costPerUnit(TerrainType.plain, onTrail: true);
      expect(trail, lessThan(plain));
      expect(trail, plain * TerrainRules.trailMultiplier);
    });

    test('thiếu thể lực để vượt sông: dừng đúng chỗ cạn, không vượt quá ngân sách, không nhảy sang bờ bên kia', () {
      const from = WPoint(1000, 700);
      final r = MovementRules.advance(
        worldMap,
        from: from,
        to: const WPoint(1700, 700),
        stamina: 20,
        maxDistance: 5000,
      );
      expect(r.status, MoveStatus.exhausted);
      expect(r.stamina, 0);
      expect(r.position.x, lessThan(1700));
      // Chi phí thật của đoạn đã đi đúng bằng thể lực tiêu hao.
      final spent = MovementRules.estimate(worldMap, from, r.position);
      expect(spent.cost, closeTo(20, 0.5));
    });

    test('đi qua cầu được và đi tiếp tới đích bên kia sông', () {
      final b = worldMap.bridges.first;
      final west = WPoint(b.center.x - 150, b.center.y);
      final east = WPoint(b.center.x + 150, b.center.y);
      final r = MovementRules.advance(
        worldMap,
        from: west,
        to: east,
        stamina: 100,
        maxDistance: 1000,
      );
      expect(r.status, MoveStatus.arrived);
      expect(r.position, east);
    });

    test('kết quả không phụ thuộc cách chia khung hình (FPS)', () {
      final from = WPoint(1500, 1390);
      final to = WPoint(2000, 1440);
      MoveOutcome run(double dt) {
        var pos = from;
        var st = 100.0;
        MoveOutcome? last;
        for (var i = 0; i < 100000; i++) {
          last = MovementRules.advance(
            worldMap,
            from: pos,
            to: to,
            stamina: st,
            maxDistance: MovementRules.walkSpeed * dt,
          );
          pos = last.position;
          st = last.stamina;
          if (last.status != MoveStatus.moving) break;
        }
        return last!;
      }

      final a = run(1 / 30), b = run(1 / 144), c = run(0.1);
      expect(a.status, MoveStatus.arrived);
      expect(b.status, MoveStatus.arrived);
      expect(a.stamina, closeTo(b.stamina, 0.15));
      expect(a.stamina, closeTo(c.stamina, 0.15));
    });
  });

  group('HeroTravel (nguồn sự thật = GameState.hero)', () {
    late GameController c;
    setUp(() async {
      c = GameController(SaveRepository(MemoryStore()));
      await c.newGame(seed: 3);
    });

    test(
      'nhấn điểm đến không dịch chuyển: vị trí chỉ đổi dần theo thời gian',
      () {
        final start = c.state!.hero.position;
        final dest = WPoint(start.x + 300, start.y);
        expect(c.travel.setDestination(dest), isNull);
        expect(c.state!.hero.position, start); // chưa nhúc nhích
        expect(c.state!.hero.stamina, TerrainRules.maxStamina);
        c.travel.tick(0.05);
        final p1 = c.state!.hero.position;
        expect(
          p1.distanceTo(start),
          closeTo(MovementRules.walkSpeed * 0.05, 1e-6),
        );
        expect(p1.distanceTo(dest), greaterThan(250));
        expect(c.state!.hero.stamina, lessThan(TerrainRules.maxStamina));
        expect(c.travel.moving, isTrue);
      },
    );

    test('đi tới đích thì dừng chính xác và giữ vị trí', () {
      final start = c.state!.hero.position;
      final dest = WPoint(start.x + 60, start.y);
      c.travel.setDestination(dest);
      for (var i = 0; i < 100 && c.travel.moving; i++) {
        c.travel.tick(0.05);
      }
      expect(c.travel.moving, isFalse);
      expect(c.travel.status, MoveStatus.arrived);
      expect(c.state!.hero.position, dest);
      final before = c.state!.hero.stamina;
      c.travel.tick(1);
      expect(c.state!.hero.position, dest);
      expect(c.state!.hero.stamina, before);
    });

    test('đứng yên không tiêu hao thể lực', () {
      final before = c.state!.hero.stamina;
      for (var i = 0; i < 50; i++) {
        c.travel.tick(0.1);
      }
      expect(c.state!.hero.stamina, before);
    });

    test('đổi điểm đến khi đang đi: không nhảy vị trí', () {
      final start = c.state!.hero.position;
      c.travel.setDestination(WPoint(start.x + 400, start.y));
      for (var i = 0; i < 6; i++) {
        c.travel.tick(0.05);
      }
      final mid = c.state!.hero.position;
      expect(c.travel.setDestination(WPoint(start.x, start.y + 200)), isNull);
      expect(c.state!.hero.position, mid);
      c.travel.tick(0.05);
      expect(
        c.state!.hero.position.distanceTo(mid),
        closeTo(MovementRules.walkSpeed * 0.05, 1e-6),
      );
    });

    test('khung hình quá dài bị giới hạn, không dịch chuyển tức thời', () {
      final start = c.state!.hero.position;
      c.travel.setDestination(WPoint(start.x + 800, start.y));
      c.travel.tick(30); // treo máy 30 giây
      expect(
        c.state!.hero.position.distanceTo(start),
        lessThanOrEqualTo(
          MovementRules.walkSpeed * HeroTravel.maxFrameSeconds + 1e-6,
        ),
      );
    });

    test('hết thể lực: dừng, không nhận lệnh mới tới khi hồi phục', () async {
      final h = c.state!.hero;
      final p = runOf(TerrainType.meadow, len: 400);
      h.position = p;
      h.stamina = TerrainRules.costPerUnit(TerrainType.meadow) * 50;
      c.travel.setDestination(WPoint(p.x + 400, p.y));
      for (var i = 0; i < 200 && c.travel.moving; i++) {
        c.travel.tick(0.05);
      }
      expect(c.travel.status, MoveStatus.exhausted);
      expect(h.stamina, 0);
      expect(h.position.x - p.x, closeTo(50, 0.5));
      expect(c.travel.notice, 'Đã cạn thể lực');
      final seq = c.travel.noticeSeq;
      final stop = h.position;
      for (var i = 0; i < 50; i++) {
        c.travel.tick(0.1);
      }
      expect(h.position, stop);
      expect(c.travel.noticeSeq, seq); // không lặp thông báo
      expect(c.travel.setDestination(WPoint(p.x + 100, p.y)), isNotNull);
      expect(c.travel.moving, isFalse);
      // Hệ thống hiện có (qua ngày) hồi thể lực, rồi mới đi tiếp được; không tự đi tiếp.
      GameRules.tickDay(c.state!);
      expect(h.stamina, TerrainRules.maxStamina);
      expect(h.position, stop);
      expect(c.travel.setDestination(WPoint(p.x + 100, p.y)), isNull);
    });

    test('đích là sông/vách đá nhận được (tốn thêm thể lực); ngoài bản đồ bị từ chối', () {
      expect(c.travel.setDestination(const WPoint(-10, -10)), isNotNull);
      expect(c.travel.moving, isFalse);
      final water = find((t, p) => t == TerrainType.water);
      expect(c.travel.setDestination(water), isNull);
      expect(c.travel.moving, isTrue);
      c.travel.cancel();
      final cliff = find((t, p) => t == TerrainType.cliff);
      expect(c.travel.setDestination(cliff), isNull);
      c.travel.cancel();
    });

    test('qua sông khi thiếu thể lực: dừng giữa đường kèm thông báo "cạn thể lực"; đủ thì tới nơi', () {
      final h = c.state!.hero;
      h.position = const WPoint(1000, 700);
      h.stamina = 20;
      expect(c.travel.setDestination(const WPoint(1700, 700)), isNull);
      for (var i = 0; i < 400 && c.travel.moving; i++) {
        c.travel.tick(0.05);
      }
      expect(c.travel.status, MoveStatus.exhausted);
      expect(c.travel.notice, contains('cạn'));
      expect(h.stamina, 0);
      expect(h.position.x, lessThan(1700));
      GameRules.tickDay(c.state!); // nghỉ ngơi hồi thể lực
      expect(c.travel.setDestination(const WPoint(1700, 700)), isNull);
      for (var i = 0; i < 400 && c.travel.moving; i++) {
        c.travel.tick(0.05);
      }
      expect(c.travel.status, MoveStatus.arrived);
      expect(h.position, const WPoint(1700, 700));
    });
  });

  group('Vào thị trấn và lưu game', () {
    test(
      'chỉ vào được khi đã đi tới đủ gần; không dịch chuyển nhân vật',
      () async {
        final c = GameController(SaveRepository(MemoryStore()));
        await c.newGame(seed: 5);
        final town = worldMap.townById('g_town')!;
        expect(c.enterTown('g_town').ok, isFalse);
        expect(c.state!.visiting, isNull);
        final before = c.state!.hero.position;
        expect(before.distanceTo(town.position), greaterThan(town.enterRadius));
        c.state!.hero.position = WPoint(town.position.x + 60, town.position.y);
        final r = c.enterTown('g_town');
        expect(r.ok, isTrue, reason: r.message);
        expect(c.state!.visiting, 'g_town');
        expect(c.state!.hero.position.x, town.position.x + 60);
      },
    );

    test(
      'thành phố luôn mở: thị trấn ở vùng xa vẫn vào được khi đã tới nơi',
      () async {
        final c = GameController(SaveRepository(MemoryStore()));
        await c.newGame(seed: 5);
        final town = worldMap.townById('n_keep')!;
        c.state!.hero.position = town.position;
        expect(c.enterTown('n_keep').ok, isTrue);
      },
    );

    test(
      'rời thị trấn bằng cách đi ra xa thì hết trạng thái đang ở thành phố',
      () async {
        final c = GameController(SaveRepository(MemoryStore()));
        await c.newGame(seed: 5);
        final town = worldMap.townById('g_town')!;
        c.state!.hero.position = town.position;
        expect(c.enterTown('g_town').ok, isTrue);
        c.travel.setDestination(WPoint(town.position.x + 400, town.position.y));
        for (var i = 0; i < 100 && c.travel.moving; i++) {
          c.travel.tick(0.05);
        }
        expect(c.state!.visiting, isNull);
      },
    );

    test('vị trí và thể lực được lưu và nạp lại; save cũ không có hero vẫn đọc được', () async {
      final store = MemoryStore();
      final c = GameController(SaveRepository(store));
      await c.newGame(seed: 9);
      final h = c.state!.hero;
      final p = runOf(TerrainType.meadow, len: 200);
      h.position = p;
      h.stamina = 42.5;
      c.commitTravel();
      await Future<void>.delayed(Duration.zero);
      final c2 = GameController(SaveRepository(store));
      await c2.init();
      c2.continueGame();
      expect(c2.state!.hero.x, p.x);
      expect(c2.state!.hero.y, p.y);
      expect(c2.state!.hero.stamina, 42.5);

      final json = c.state!.toJson()..remove('hero');
      final old = GameState.fromJson(json);
      expect(old.hero.position, worldMap.start);
      expect(old.hero.stamina, TerrainRules.maxStamina);
      final inTown = c.state!.toJson()
        ..remove('hero')
        ..['visiting'] = 'a_city';
      expect(
        GameState.fromJson(inTown).hero.position,
        worldMap.townById('a_city')!.position,
      );
      // Đứng giữa sông là hợp lệ (vượt sông giữa chừng rồi lưu): vị trí được giữ. Ngoài bản đồ → mặc định.
      final water = find((t, p) => t == TerrainType.water);
      final inWater = c.state!.toJson()
        ..['hero'] = {'x': water.x, 'y': water.y, 'stamina': 10.0};
      expect(GameState.fromJson(inWater).hero.position, water);
      expect(GameState.fromJson(inWater).hero.stamina, 10.0);
      final bad = c.state!.toJson()
        ..['hero'] = {'x': -50.0, 'y': 20.0, 'stamina': 10.0};
      expect(GameState.fromJson(bad).hero.position, worldMap.start);
    });
  });
}
