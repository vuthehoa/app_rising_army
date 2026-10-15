import 'package:flutter/material.dart';

/// Nhận cú vuốt dứt khoát mà KHÔNG tham gia gesture arena: chỉ quan sát sự kiện con trỏ (Listener, translucent) nên
/// không bao giờ cướp thao tác kéo lính/kéo item, cuộn danh sách, kéo bản đồ hay pinch-to-zoom bên dưới.
///
/// Điều kiện là một cú vuốt: đúng MỘT ngón trong suốt cử chỉ (có ngón thứ hai là pinch → bỏ), quãng di chuyển
/// ≥ [minDistance] theo hướng chính và hướng chính lớn hơn hướng phụ ít nhất [dominance] lần (kéo ngắn hoặc chéo
/// không tính). Chỉ có hiệu lực khi con trỏ bắt đầu trên chính vùng của widget này.
class SwipeDetector extends StatefulWidget {
  const SwipeDetector({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onSwipeUp,
    this.onSwipeDown,
    this.minDistance = 40,
    this.dominance = 2,
  });

  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onSwipeDown;
  final double minDistance;
  final double dominance;

  @override
  State<SwipeDetector> createState() => _SwipeDetectorState();
}

class _SwipeDetectorState extends State<SwipeDetector> {
  int? _pointer;
  Offset _start = Offset.zero;
  bool _multi = false;

  void _down(PointerDownEvent e) {
    if (_pointer != null) {
      _multi = true; // ngón thứ hai: pinch, không phải vuốt HUD
      return;
    }
    _pointer = e.pointer;
    _start = e.position;
    _multi = false;
  }

  void _up(PointerUpEvent e) {
    if (e.pointer != _pointer) return;
    final d = e.position - _start;
    final ok = !_multi;
    _pointer = null;
    if (!ok) return;
    final ax = d.dx.abs(), ay = d.dy.abs();
    if (ax >= widget.minDistance && ax >= widget.dominance * ay) {
      (d.dx < 0 ? widget.onSwipeLeft : widget.onSwipeRight)?.call();
    } else if (ay >= widget.minDistance && ay >= widget.dominance * ax) {
      (d.dy < 0 ? widget.onSwipeUp : widget.onSwipeDown)?.call();
    }
  }

  void _cancel(PointerCancelEvent e) {
    if (e.pointer == _pointer) _pointer = null;
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: _down,
    onPointerUp: _up,
    onPointerCancel: _cancel,
    child: widget.child,
  );
}
