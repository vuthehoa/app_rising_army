import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../domain/models.dart';
import '../domain/rules.dart';
import '../domain/movement.dart';
import '../domain/terrain_type.dart';
import '../domain/world_data.dart';
import '../domain/world_map.dart';

/// Điều phối việc nhân vật đi bộ tới điểm đến: nhận lệnh, tiến trình theo thời gian thực (dt) và báo UI.
///
/// Không có vị trí/thể lực riêng: mọi thứ nằm ở [GameState.hero] (nguồn sự thật duy nhất); đối tượng này chỉ
/// giữ ĐIỂM ĐẾN hiện tại (không lưu) và gọi [MovementRules] cho từng bước. Chỉ thông báo cho người nghe của
/// riêng nó khi đang đi (để không dựng lại cả game 60 lần/giây); [onStopped] gọi khi dừng để lưu game.
class HeroTravel extends ChangeNotifier {
  HeroTravel(this._state, this._onStopped);

  final GameState? Function() _state;
  final VoidCallback _onStopped;

  /// Một khung hình không được đi quá đoạn này: tránh nhảy vọt sau khi ứng dụng bị treo.
  static const double maxFrameSeconds = 0.1;

  WPoint? _destination;
  String? _targetPlace;
  String? _arrivedPlace;
  MoveStatus _status = MoveStatus.idle;

  /// Thông báo ngắn mới nhất (UI hiển thị khi [noticeSeq] đổi). Chỉ phát một lần cho mỗi sự kiện.
  String? notice;
  int noticeSeq = 0;

  WPoint? get destination => _destination;

  /// Địa điểm (thị trấn hoặc mục tiêu nhiệm vụ) đang là đích của hành trình hiện tại (null nếu đang đi tới điểm tự do).
  String? get targetPlace => _targetPlace;

  /// Địa điểm vừa tới nơi; trả về đúng một lần rồi xóa, để UI chỉ điều hướng một lần.
  String? takeArrivedPlace() {
    final t = _arrivedPlace;
    _arrivedPlace = null;
    return t;
  }

  /// Đi bộ tới TÂM địa điểm [id]; khi tới nơi, [takeArrivedPlace] trả về [id].
  /// Thay thế hành trình cũ (kể cả tới thị trấn khác). Trả về lý do nếu bị từ chối.
  String? walkToPlace(String id) {
    final s = _state();
    final pos = s == null ? null : GameRules.targetPosition(s, id);
    if (pos == null || s == null) return 'Không có địa điểm này.';
    if (s.hero.position.distanceTo(pos) <= MovementRules.arriveEpsilon) {
      _destination = null;
      _targetPlace = null;
      _arrivedPlace = id;
      notifyListeners();
      return null;
    }
    final problem = setDestination(pos);
    if (problem == null) _targetPlace = id;
    return problem;
  }

  MoveStatus get status => _status;
  bool get moving => _destination != null;

  WorldMap get world => worldMap;

  void _say(String m) {
    notice = m;
    noticeSeq++;
  }

  /// Đặt điểm đến mới (thay điểm đến cũ, giữ nguyên vị trí hiện tại). Trả về lý do nếu bị từ chối.
  String? setDestination(WPoint dest) {
    final s = _state();
    if (s == null) return 'Chưa có ván chơi.';
    if (s.hero.exhausted) {
      return 'Đã cạn thể lực. Hãy nghỉ ngơi (qua ngày) để hồi phục.';
    }
    final problem = MovementRules.destinationProblem(world, dest);
    if (problem != null) return problem;
    if (s.hero.position.distanceTo(dest) <= MovementRules.arriveEpsilon) {
      return null;
    }
    _destination = dest;
    _targetPlace = null;
    _status = MoveStatus.moving;
    notifyListeners();
    return null;
  }

  /// Hủy lệnh đi (không đổi vị trí).
  void cancel() {
    if (_destination == null) return;
    _finish(MoveStatus.idle, null);
  }

  /// Quên điểm đến khi đổi ván/thoát về menu.
  void reset() {
    _destination = null;
    _targetPlace = null;
    _arrivedPlace = null;
    _status = MoveStatus.idle;
  }

  /// Tiến triển [dt] giây. Vị trí logic và vị trí vẽ là một: UI chỉ đọc [GameState.hero].
  void tick(double dt) {
    final dest = _destination;
    final s = _state();
    if (dest == null || s == null) return;
    final hero = s.hero;
    final step = math.min(math.max(dt, 0.0), maxFrameSeconds);
    final out = MovementRules.advance(
      world,
      from: hero.position,
      to: dest,
      stamina: hero.stamina,
      maxDistance: MovementRules.walkSpeed * step,
    );
    hero.position = out.position;
    hero.stamina = out.stamina;

    final at = s.visiting == null ? null : world.townById(s.visiting!);
    if (at != null &&
        out.travelled > 0 &&
        at.position.distanceTo(hero.position) > at.enterRadius) {
      s.visiting = null; // đã rời thị trấn
    }

    switch (out.status) {
      case MoveStatus.moving:
        _status = MoveStatus.moving;
        notifyListeners();
      case MoveStatus.arrived:
        _finish(MoveStatus.arrived, null);
      case MoveStatus.exhausted:
        _finish(MoveStatus.exhausted, 'Đã cạn thể lực');
      case MoveStatus.blocked:
        final label = TerrainRules.of(out.blockedBy ?? TerrainType.cliff).label;
        _finish(MoveStatus.blocked, 'Đường bị chặn: $label');
      case MoveStatus.idle:
        _finish(MoveStatus.idle, null);
    }
  }

  void _finish(MoveStatus status, String? message) {
    if (status == MoveStatus.arrived) _arrivedPlace = _targetPlace;
    _destination = null;
    _targetPlace = null;
    _status = status;
    if (message != null) _say(message);
    notifyListeners();
    _onStopped();
  }
}
