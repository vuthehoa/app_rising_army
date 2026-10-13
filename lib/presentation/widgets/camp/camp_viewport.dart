import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Zoom bằng hai ngón tay cho thế giới Trại. KHÔNG có nút/thanh trượt zoom.
///
/// * Chỉ lớp thế giới ([child]: nền, hàng rào, công trình, lính, ô đặt) được biến đổi; HUD và các nút
///   nằm ngoài widget này nên giữ nguyên kích thước màn hình.
/// * Hit-test đi qua [Transform] nên mọi chạm/kéo trong thế giới dùng đúng tọa độ sau zoom.
/// * Cử chỉ do [PinchGestureRecognizer] (chỉ nhận khi có từ 2 ngón) xử lý trong đấu trường cử chỉ: khi ngón
///   thứ hai chạm xuống nó thắng, nên chạm/kéo (chọn ô, đặt công trình, kéo lính) của ngón đầu bị hủy thay vì
///   kích hoạt nhầm. Một ngón tay thì không bao giờ bị nó chặn.
/// * Zoom chỉ là trạng thái trình bày: không lưu, không đụng game state, không rebuild lớp thế giới theo khung.
class CampViewport extends StatefulWidget {
  const CampViewport({
    super.key,
    required this.size,
    required this.child,
    this.resetToken,
    this.minZoom = defaultMinZoom,
    this.maxZoom = defaultMaxZoom,
  });

  /// Zoom nhỏ nhất bằng zoom mặc định: chỉ cho phóng to, không cho thu nhỏ dưới kích thước Trại mặc định.
  static const double defaultMinZoom = 1.0;
  static const double defaultMaxZoom = 1.9;
  static const double defaultZoom = 1.0;

  /// Kích thước vùng nhìn (thế giới được vẽ vừa đúng vùng này ở zoom 1).
  final Size size;
  final Widget child;

  /// Đổi giá trị này (ví dụ seed ván mới) sẽ đưa zoom về mặc định.
  final Object? resetToken;
  final double minZoom;
  final double maxZoom;

  @override
  State<CampViewport> createState() => _CampViewportState();
}

class _ZoomView {
  const _ZoomView(this.scale, this.offset);
  final double scale;
  final Offset offset;
}

class _CampViewportState extends State<CampViewport> {
  final ValueNotifier<_ZoomView> _view = ValueNotifier(
    const _ZoomView(CampViewport.defaultZoom, Offset.zero),
  );

  // Trạng thái đầu cử chỉ.
  double _startScale = 1;
  Offset _startOffset = Offset.zero;
  Offset _startFocal = Offset.zero;

  @override
  void didUpdateWidget(CampViewport old) {
    super.didUpdateWidget(old);
    if (old.resetToken != widget.resetToken) {
      _view.value = const _ZoomView(CampViewport.defaultZoom, Offset.zero);
    }
  }

  @override
  void dispose() {
    _view.dispose();
    super.dispose();
  }

  /// Offset hợp lệ: khi phóng to (>=1) thế giới phải phủ kín vùng nhìn; khi thu nhỏ thì căn giữa.
  Offset _clamp(Offset o, double s) {
    final w = widget.size.width, h = widget.size.height;
    double axis(double v, double extent) {
      final slack = extent - extent * s; // âm khi phóng to
      return s >= 1 ? v.clamp(slack, 0.0) : slack / 2;
    }

    return Offset(axis(o.dx, w), axis(o.dy, h));
  }

  void _onStart(Offset focal) {
    final v = _view.value;
    _startScale = v.scale;
    _startOffset = v.offset;
    _startFocal = focal;
  }

  void _onUpdate(double factor, Offset focal) {
    final s = (_startScale * factor).clamp(widget.minZoom, widget.maxZoom);
    // Điểm thế giới nằm dưới tâm hai ngón lúc bắt đầu phải nằm dưới tâm hiện tại (zoom quanh giữa hai ngón).
    final world = (_startFocal - _startOffset) / _startScale;
    _view.value = _ZoomView(s, _clamp(focal - world * s, s));
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: {
        PinchGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<PinchGestureRecognizer>(
              PinchGestureRecognizer.new,
              (r) {
                r.onStart = _onStart;
                r.onUpdate = _onUpdate;
              },
            ),
      },
      child: ClipRect(
        child: ColoredBox(
          color: const Color(0xFF55672F),
          child: ValueListenableBuilder<_ZoomView>(
            valueListenable: _view,
            child: SizedBox(
              width: widget.size.width,
              height: widget.size.height,
              child: widget.child,
            ),
            builder: (context, v, child) {
              final s = v.scale;
              final o = _clamp(v.offset, s);
              return Transform(
                key: const ValueKey('camp-world-transform'),
                transform:
                    Matrix4.translationValues(o.dx, o.dy, 0) *
                    Matrix4.diagonal3Values(s, s, 1),
                child: child,
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Nhận cử chỉ khi có TỪ HAI NGÓN trở lên và thắng đấu trường cử chỉ ngay lúc ngón thứ hai chạm xuống.
/// Báo hệ số tỷ lệ (so với lúc bắt đầu) và tâm hai ngón.
class PinchGestureRecognizer extends OneSequenceGestureRecognizer {
  PinchGestureRecognizer({super.debugOwner});

  void Function(Offset focal)? onStart;
  void Function(double factor, Offset focal)? onUpdate;

  final Map<int, Offset> _pos = {};
  bool _accepted = false;
  double _startDist = 1;

  Offset get _focal {
    var sum = Offset.zero;
    for (final p in _pos.values) {
      sum += p;
    }
    return sum / _pos.length.toDouble();
  }

  double get _dist {
    final it = _pos.values.iterator..moveNext();
    final a = it.current;
    it.moveNext();
    return (a - it.current).distance;
  }

  @override
  void addAllowedPointer(PointerDownEvent event) {
    startTrackingPointer(event.pointer, event.transform);
    _pos[event.pointer] = event.position;
    if (_pos.length == 2) {
      _startDist = _dist.clamp(1, double.infinity);
      resolve(GestureDisposition.accepted);
    }
  }

  @override
  void acceptGesture(int pointer) {
    if (_accepted || _pos.length < 2) return;
    _accepted = true;
    _startDist = _dist.clamp(1, double.infinity);
    onStart?.call(_focal);
  }

  @override
  void rejectGesture(int pointer) {
    _pos.remove(pointer);
    stopTrackingPointer(pointer);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent) {
      if (!_pos.containsKey(event.pointer)) return;
      _pos[event.pointer] = event.position;
      if (_accepted && _pos.length >= 2) {
        onUpdate?.call(_dist / _startDist, _focal);
      }
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      _pos.remove(event.pointer);
      if (!_accepted) resolve(GestureDisposition.rejected);
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _accepted = false;
    _pos.clear();
  }

  @override
  String get debugDescription => 'pinch';
}
