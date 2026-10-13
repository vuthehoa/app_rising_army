import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../../../domain/world_map.dart';

/// Camera của bản đồ khám phá: chuyển đổi tọa độ thế giới ↔ màn hình, pan, zoom, bám theo nhân vật.
/// Luôn giữ vùng nhìn nằm trong ranh giới thế giới. Không phụ thuộc widget.
class MapCamera extends ChangeNotifier {
  MapCamera({
    required this.worldWidth,
    required this.worldHeight,
    this.minZoom = 0.45,
    this.maxZoom = 2.2,
    this._zoom = 0.9,
    this._center = const WPoint(0, 0),
  });

  final double worldWidth, worldHeight;
  final double minZoom, maxZoom;

  Size _viewport = Size.zero;
  double _zoom;
  WPoint _center;

  /// true: camera bám theo nhân vật khi đi. Kéo bản đồ bằng tay sẽ tắt; lệnh đi mới/nút về nhân vật bật lại.
  bool following = true;

  Size get viewport => _viewport;
  double get zoom => _zoom;
  WPoint get center => _center;

  /// Zoom nhỏ nhất thực sự áp dụng: không bao giờ nhìn ra ngoài thế giới.
  double get effectiveMinZoom {
    if (_viewport.isEmpty) return minZoom;
    return math.max(
      minZoom,
      math.max(_viewport.width / worldWidth, _viewport.height / worldHeight),
    );
  }

  /// Đặt kích thước vùng nhìn (gọi trong build, nên KHÔNG thông báo; painter đọc lúc vẽ).
  void setViewport(Size size) {
    if (size == _viewport || size.isEmpty) return;
    _viewport = size;
    _zoom = _zoom.clamp(effectiveMinZoom, maxZoom).toDouble();
    _center = _clampCenter(_center, _zoom);
  }

  WPoint _clampCenter(WPoint c, double zoom) {
    final hw = _viewport.width / 2 / zoom, hh = _viewport.height / 2 / zoom;
    double ax(double v, double half, double size) =>
        half * 2 >= size ? size / 2 : v.clamp(half, size - half).toDouble();
    return WPoint(ax(c.x, hw, worldWidth), ax(c.y, hh, worldHeight));
  }

  /// Rect thế giới đang nhìn thấy.
  Rect get visibleWorld {
    final hw = _viewport.width / 2 / _zoom, hh = _viewport.height / 2 / _zoom;
    return Rect.fromLTRB(
      _center.x - hw,
      _center.y - hh,
      _center.x + hw,
      _center.y + hh,
    );
  }

  Offset worldToScreen(WPoint p) => Offset(
    (p.x - _center.x) * _zoom + _viewport.width / 2,
    (p.y - _center.y) * _zoom + _viewport.height / 2,
  );

  WPoint screenToWorld(Offset s) => WPoint(
    (s.dx - _viewport.width / 2) / _zoom + _center.x,
    (s.dy - _viewport.height / 2) / _zoom + _center.y,
  );

  /// Đặt tâm camera mà không thông báo (dùng khi dựng lần đầu).
  void placeSilently(WPoint p, {double? zoom}) {
    if (zoom != null) _zoom = zoom.clamp(effectiveMinZoom, maxZoom).toDouble();
    _center = _clampCenter(p, _zoom);
  }

  void jumpTo(WPoint p, {double? zoom}) {
    if (zoom != null) _zoom = zoom.clamp(effectiveMinZoom, maxZoom).toDouble();
    _center = _clampCenter(p, _zoom);
    notifyListeners();
  }

  /// Kéo bản đồ theo độ dời màn hình [d] (nội dung đi theo ngón tay).
  void panByScreen(Offset d) {
    _center = _clampCenter(
      WPoint(_center.x - d.dx / _zoom, _center.y - d.dy / _zoom),
      _zoom,
    );
    notifyListeners();
  }

  /// Nhân zoom với [factor] và giữ nguyên điểm thế giới đang nằm dưới [focal] (tọa độ màn hình).
  void zoomAround(Offset focal, double factor) {
    final next = (_zoom * factor).clamp(effectiveMinZoom, maxZoom).toDouble();
    if (next == _zoom) return;
    final before = screenToWorld(focal);
    _zoom = next;
    final after = screenToWorld(focal);
    _center = _clampCenter(
      WPoint(_center.x + before.x - after.x, _center.y + before.y - after.y),
      _zoom,
    );
    notifyListeners();
  }

  /// Làm mượt camera về phía [target] (độc lập FPS nhờ hàm mũ theo [dt]).
  void follow(WPoint target, double dt) {
    final k = 1 - math.exp(-5.0 * dt);
    final next = _clampCenter(
      WPoint(
        _center.x + (target.x - _center.x) * k,
        _center.y + (target.y - _center.y) * k,
      ),
      _zoom,
    );
    if ((next.x - _center.x).abs() < 1e-4 &&
        (next.y - _center.y).abs() < 1e-4) {
      return;
    }
    _center = next;
    notifyListeners();
  }
}
