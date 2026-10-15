import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';

/// Ván mới + trại đã xây sẵn (3 bãi huấn luyện/lều cứu thương, Doanh trại và Lò rèn cấp 1).
/// Ván mới thật chỉ có bếp lửa; test cần trại đầy đủ dựng nó trực tiếp trên state, không qua
/// luật xây dựng (luật xây dựng có test riêng).
GameState newGameWithBuiltCamp({int seed = 7}) {
  final s = GameRules.newGame(seed: seed);
  addBuiltCamp(s);
  return s;
}

/// Dựng sẵn trại lên [s] (dùng được cho state của GameController đang chạy).
void addBuiltCamp(GameState s) {
  s.buildings[Building.barracks] = 1;
  s.buildings[Building.smithy] = 1;
  for (final (type, x, y) in [
    (FacilityType.meleeYard, 0.1925, 0.245),
    (FacilityType.archeryRange, 0.3975, 0.245),
    (FacilityType.infirmary, 0.6025, 0.245),
  ]) {
    s.facilities.add(Facility(id: s.nextFacilityId++, type: type, x: x, y: y));
  }
}
