/// Luật di chuyển liên tục và tiêu hao thể lực trên bản đồ khám phá. Thuần Dart, xác định, không phụ thuộc FPS:
/// quãng đường được chia thành bước nhỏ cố định [stepLength]; mỗi bước tính địa hình, đường mòn và thể lực.
library;

import 'dart:math' as math;

import 'terrain_type.dart';
import 'world_map.dart';

enum MoveStatus {
  /// Chưa có đích hoặc đã dừng.
  idle,

  /// Còn đang đi (hết ngân sách quãng đường của lần cập nhật này).
  moving,

  /// Đã tới đích.
  arrived,

  /// Bước kế tiếp ra ngoài ranh giới bản đồ (nước và vách đá KHÔNG còn chặn: chỉ tốn thêm thể lực).
  blocked,

  /// Thể lực về 0 giữa đường.
  exhausted,
}

class MoveOutcome {
  const MoveOutcome({
    required this.position,
    required this.stamina,
    required this.travelled,
    required this.status,
    this.blockedBy,
  });

  final WPoint position;
  final double stamina;
  final double travelled;
  final MoveStatus status;

  /// Loại địa hình chặn đường khi [status] là [MoveStatus.blocked].
  final TerrainType? blockedBy;
}

/// Ước tính cho một hành trình (không đổi state).
class TravelEstimate {
  const TravelEstimate({
    required this.distance,
    required this.cost,
    required this.reachable,
    required this.stopPoint,
    this.blockedBy,
  });

  /// Quãng đường thực đi được tới đích hoặc tới điểm bị chặn.
  final double distance;

  /// Thể lực cần cho quãng đường đó.
  final double cost;
  final bool reachable;
  final WPoint stopPoint;
  final TerrainType? blockedBy;
}

class MovementRules {
  const MovementRules._();

  /// Tốc độ đi bộ (đơn vị thế giới / giây).
  static const double walkSpeed = 150;

  /// Độ dài bước tính toán. Nhỏ hơn bề rộng mọi vật cản nên không thể "xuyên" qua sông/vách.
  static const double stepLength = 4;

  /// Sai số coi là đã tới đích.
  static const double arriveEpsilon = 0.01;

  static const double _unlimited = 1e9;

  /// Đi tối đa [maxDistance] từ [from] về phía [to] với [stamina] hiện có.
  /// Vị trí/thể lực tiến triển theo từng bước; không bao giờ tiêu quá thể lực còn lại và dừng ở đúng
  /// điểm mà thể lực cho phép.
  static MoveOutcome advance(
    WorldMap world, {
    required WPoint from,
    required WPoint to,
    required double stamina,
    required double maxDistance,
  }) {
    var pos = from;
    var left = stamina.isFinite ? math.max(0.0, stamina) : 0.0;
    var travelled = 0.0;
    final total = from.distanceTo(to);
    if (total <= arriveEpsilon) {
      return MoveOutcome(
        position: pos,
        stamina: left,
        travelled: 0,
        status: MoveStatus.arrived,
      );
    }
    if (left <= 0) {
      return MoveOutcome(
        position: pos,
        stamina: 0,
        travelled: 0,
        status: MoveStatus.exhausted,
      );
    }
    final dir = WPoint((to.x - from.x) / total, (to.y - from.y) / total);
    var budget = math.min(math.max(0.0, maxDistance), total);
    var covered = 0.0;

    while (budget > 1e-9) {
      final step = math.min(stepLength, budget);
      final next = WPoint(pos.x + dir.x * step, pos.y + dir.y * step);
      final nextTerrain = world.terrainAt(next);
      if (!TerrainRules.traversable(nextTerrain)) {
        return MoveOutcome(
          position: pos,
          stamina: left,
          travelled: travelled,
          status: MoveStatus.blocked,
          blockedBy: nextTerrain,
        );
      }
      final mid = WPoint((pos.x + next.x) / 2, (pos.y + next.y) / 2);
      final perUnit = world.costPerUnitAt(mid);
      final cost = step * perUnit;
      if (cost > left) {
        final part = left / perUnit;
        pos = WPoint(pos.x + dir.x * part, pos.y + dir.y * part);
        travelled += part;
        return MoveOutcome(
          position: pos,
          stamina: 0,
          travelled: travelled,
          status: MoveStatus.exhausted,
        );
      }
      left -= cost;
      pos = next;
      travelled += step;
      covered += step;
      budget -= step;
    }

    final arrived = covered >= total - arriveEpsilon;
    if (arrived) pos = to;
    if (arrived) {
      return MoveOutcome(
        position: pos,
        stamina: left,
        travelled: travelled,
        status: MoveStatus.arrived,
      );
    }
    if (left <= 1e-9) {
      return MoveOutcome(
        position: pos,
        stamina: 0,
        travelled: travelled,
        status: MoveStatus.exhausted,
      );
    }
    return MoveOutcome(
      position: pos,
      stamina: left,
      travelled: travelled,
      status: MoveStatus.moving,
    );
  }

  /// Ước tính hành trình thẳng tới [to] với thể lực vô hạn: tổng chi phí, điểm bị chặn (nếu có).
  static TravelEstimate estimate(WorldMap world, WPoint from, WPoint to) {
    final r = advance(
      world,
      from: from,
      to: to,
      stamina: _unlimited,
      maxDistance: from.distanceTo(to),
    );
    return TravelEstimate(
      distance: r.travelled,
      cost: _unlimited - r.stamina,
      reachable: r.status == MoveStatus.arrived,
      stopPoint: r.position,
      blockedBy: r.blockedBy,
    );
  }

  /// Lý do không thể chọn [dest] làm điểm đến, hoặc null nếu hợp lệ.
  static String? destinationProblem(WorldMap world, WPoint dest) {
    if (!world.inBounds(dest)) return 'Ngoài ranh giới bản đồ.';
    final t = world.terrainAt(dest);
    if (!TerrainRules.traversable(t)) return 'Không thể đi tới đó.';
    return null;
  }
}
