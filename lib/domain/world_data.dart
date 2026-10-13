/// Dữ liệu bản đồ khám phá (thế giới 4200 × 3000 đơn vị): sông, cầu, núi, rừng, đồi, hồ, đường mòn,
/// 5 thị trấn và vị trí các địa điểm gameplay. Chỉnh/thêm địa hình ở đây; painter và luật tự theo.
library;

import 'world_map.dart';

WorldMap _build() {
  const w = 4200.0, h = 3000.0;
  const g = WPoint.new;

  // ---- Sông ----
  final rivers = [
    River(
      id: 'bac',
      name: 'Sông Bạc',
      halfWidth: 34,
      controls: [
        g(1250, -60),
        g(1130, 260),
        g(1130, 560),
        g(1300, 850),
        g(1250, 1150),
        g(1230, 1410),
        g(1330, 1720),
        g(1200, 2000),
        g(1250, 2250),
        g(1380, 2550),
        g(1260, 3060),
      ],
    ),
    River(
      id: 'den',
      name: 'Sông Đen',
      halfWidth: 38,
      controls: [
        g(3000, -60),
        g(3100, 300),
        g(2950, 650),
        g(2900, 960),
        g(3100, 1200),
        g(3020, 1460),
        g(3150, 1800),
        g(2950, 2150),
        g(3000, 2500),
        g(2880, 3060),
      ],
    ),
  ];

  // ---- Cầu / bến vượt sông (đặt trên đường mòn) ----
  const bridges = [
    Bridge(center: WPoint(1230, 1410), angle: 0.05),
    Bridge(center: WPoint(3020, 1460), angle: -0.1),
    Bridge(center: WPoint(1250, 2250), angle: 0.45),
    Bridge(center: WPoint(2905, 960), angle: 0.25),
  ];

  // ---- Mảng địa hình ----
  TerrainBlob b(
    BlobKind kind,
    double x,
    double y,
    double rx,
    double ry, {
    double rot = 0,
    double core = 0.5,
    int seed = 0,
  }) => TerrainBlob(
    kind: kind,
    center: g(x, y),
    rx: rx,
    ry: ry,
    rotation: rot,
    core: core,
    seed: seed,
  );
  const m = BlobKind.mountain,
      f = BlobKind.forest,
      hi = BlobKind.hill,
      me = BlobKind.meadow,
      lk = BlobKind.lake;

  final blobs = [
    // Núi: các dãy lệch hướng, không thẳng hàng.
    b(m, 2650, 300, 240, 150, rot: -0.25, core: 0.55, seed: 1),
    b(m, 3250, 330, 210, 150, rot: 0.3, core: 0.55, seed: 2),
    b(m, 3620, 170, 200, 130, rot: 0.1, core: 0.55, seed: 3),
    b(m, 3750, 640, 180, 140, rot: -0.4, core: 0.5, seed: 4),
    b(m, 450, 500, 240, 170, rot: 0.2, core: 0.55, seed: 5),
    b(m, 800, 220, 210, 140, rot: -0.2, core: 0.55, seed: 6),
    b(m, 350, 2400, 260, 180, rot: 0.4, core: 0.55, seed: 7),
    b(m, 700, 2760, 230, 150, rot: -0.3, core: 0.55, seed: 8),
    b(m, 2450, 2600, 250, 170, rot: 0.1, core: 0.55, seed: 9),
    b(m, 2150, 2850, 200, 130, rot: -0.35, core: 0.5, seed: 10),
    b(m, 3600, 2850, 230, 150, rot: 0.25, core: 0.55, seed: 11),
    // Đồi thấp.
    b(hi, 1700, 900, 300, 200, rot: 0.3, seed: 12),
    b(hi, 3400, 1100, 260, 190, rot: -0.2, seed: 13),
    b(hi, 900, 1050, 260, 180, rot: 0.1, seed: 14),
    b(hi, 2300, 2000, 300, 200, rot: 0.5, seed: 15),
    b(hi, 3850, 1900, 240, 200, rot: 0.2, seed: 16),
    // Rừng: lõi rậm, rìa thưa.
    b(f, 350, 1050, 380, 260, rot: 0.3, core: 0.5, seed: 17),
    b(f, 1800, 1950, 400, 250, rot: -0.3, core: 0.5, seed: 18),
    b(f, 2600, 900, 350, 250, rot: 0.2, core: 0.45, seed: 19),
    b(f, 3700, 1250, 300, 300, rot: 0.4, core: 0.5, seed: 20),
    b(f, 900, 2000, 300, 220, rot: -0.2, core: 0.5, seed: 21),
    b(f, 1550, 420, 300, 220, rot: 0.5, core: 0.5, seed: 22),
    b(f, 3250, 2200, 250, 200, rot: 0.1, core: 0.5, seed: 23),
    // Hồ.
    b(lk, 3650, 2450, 260, 180, rot: 0.2, seed: 24),
    // Ao bên cảng Đầm Đen.
    b(lk, 3700, 1810, 130, 80, rot: 0.3, seed: 32),
    // Bãi cỏ / khu đất trống.
    b(me, 1500, 1380, 400, 260, rot: 0.1, seed: 25),
    b(me, 2100, 1450, 350, 250, rot: -0.1, seed: 26),
    b(me, 700, 1500, 300, 220, rot: 0.2, seed: 27),
    b(me, 3500, 1700, 300, 200, rot: -0.3, seed: 28),
    b(me, 2000, 450, 300, 200, rot: 0.15, seed: 29),
    b(me, 1700, 2600, 300, 220, rot: 0.3, seed: 30),
    b(me, 2700, 1650, 260, 180, rot: 0.2, seed: 31),
  ];

  // ---- Đường mòn: mạng lưới 6 tuyến nối 5 thị trấn (có vòng, mỗi thị trấn ≥ 2 tuyến) ----
  final trails = [
    Trail(
      id: 't_west_center',
      fromId: 'g_town',
      toId: 'a_city',
      controls: [
        g(700, 1500),
        g(950, 1470),
        g(1230, 1410),
        g(1500, 1390),
        g(1800, 1480),
        g(2100, 1450),
      ],
    ),
    Trail(
      id: 't_center_north',
      fromId: 'a_city',
      toId: 'n_keep',
      controls: [
        g(2100, 1450),
        g(2060, 1150),
        g(1900, 850),
        g(1980, 620),
        g(2000, 450),
      ],
    ),
    Trail(
      id: 't_center_east',
      fromId: 'a_city',
      toId: 'm_port',
      controls: [
        g(2100, 1450),
        g(2450, 1540),
        g(2750, 1490),
        g(3020, 1460),
        g(3250, 1600),
        g(3500, 1700),
      ],
    ),
    Trail(
      id: 't_center_south',
      fromId: 'a_city',
      toId: 's_ford',
      controls: [
        g(2100, 1450),
        g(1950, 1750),
        g(1800, 2050),
        g(1720, 2350),
        g(1700, 2600),
      ],
    ),
    Trail(
      id: 't_west_south',
      fromId: 'g_town',
      toId: 's_ford',
      controls: [
        g(700, 1500),
        g(780, 1800),
        g(950, 2100),
        g(1100, 2190),
        g(1250, 2250),
        g(1450, 2400),
        g(1700, 2600),
      ],
    ),
    Trail(
      id: 't_north_east',
      fromId: 'n_keep',
      toId: 'm_port',
      controls: [
        g(2000, 450),
        g(2300, 600),
        g(2550, 800),
        g(2750, 920),
        g(2905, 960),
        g(3150, 1000),
        g(3350, 1300),
        g(3500, 1700),
      ],
    ),
  ];

  const towns = [
    WorldTown(
      id: 'g_town',
      position: WPoint(700, 1500),
      style: TownStyle.village,
    ),
    WorldTown(
      id: 'a_city',
      position: WPoint(2100, 1450),
      style: TownStyle.crossroads,
    ),
    WorldTown(
      id: 'm_port',
      position: WPoint(3500, 1700),
      style: TownStyle.port,
    ),
    WorldTown(
      id: 'n_keep',
      position: WPoint(2000, 450),
      style: TownStyle.fortress,
    ),
    WorldTown(
      id: 's_ford',
      position: WPoint(1700, 2600),
      style: TownStyle.hamlet,
    ),
  ];

  // Địa điểm gameplay (trại địch, tài nguyên, tàn tích) đặt trong cùng hệ tọa độ thế giới.
  const placements = <String, WPoint>{
    'g_farm': WPoint(500, 1720),
    'g_woods': WPoint(480, 930),
    'g_bandits': WPoint(1000, 2520),
    'g_mine': WPoint(700, 720),
    'g_tower': WPoint(950, 1260),
    'a_quarry': WPoint(2350, 1900),
    'a_outpost': WPoint(1750, 650),
    'a_raiders': WPoint(2450, 2250),
    'a_shrine': WPoint(2400, 520),
    'a_hunt': WPoint(2700, 1200),
    'm_reeds': WPoint(3600, 2130),
    'm_camp': WPoint(3600, 950),
    'm_ruins': WPoint(3300, 760),
    'm_fort': WPoint(3900, 1720),
  };

  return WorldMap(
    width: w,
    height: h,
    start: const WPoint(2010, 1470),
    rivers: rivers,
    bridges: bridges,
    blobs: blobs,
    trails: trails,
    towns: towns,
    placements: placements,
  );
}

/// Bản đồ thế giới duy nhất của game.
final WorldMap worldMap = _build();
