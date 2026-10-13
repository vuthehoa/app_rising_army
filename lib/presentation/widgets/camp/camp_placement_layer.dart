import 'package:flutter/material.dart';

import '../../../domain/camp_layout.dart';
import '../../../domain/models.dart';
import '../../../domain/rules.dart';
import '../buildings/facility_art.dart';
import 'camp_overlays.dart';

/// Lớp kéo-thả xây dựng nằm TRONG thế giới Trại (bên trong phép biến đổi zoom), nên toạ độ cục bộ của con
/// trỏ chính là toạ độ thế giới: chuyển màn hình → thế giới do Transform lo, không cần tự nhân/chia zoom.
///
/// Dùng [Listener] (không vào đấu trường cử chỉ) để không tranh với nhận diện pinch của CampViewport.
/// Một ngón: ghost bám đúng ngón tay (tâm footprint = điểm chạm, không lệch), đổi xanh/đỏ liên tục theo
/// [GameRules.checkPlacement] (cùng hàm với luật xây). Thả: gọi [onDrop] một lần. Từ 2 ngón: huỷ lượt kéo
/// và không bao giờ xây cho tới khi nhấc hết ngón.
class CampPlacementLayer extends StatefulWidget {
  const CampPlacementLayer({
    super.key,
    required this.state,
    required this.metrics,
    required this.placing,
    required this.onDrop,
    this.moving,
    this.preview,
  });

  /// Công trình đang được dời (null = xây mới): vị trí ban đầu của ghost, và nó không tự chặn chính nó.
  final Facility? moving;

  /// Vị trí xem trước do thao tác nhấn giữ-kéo bên ngoài lớp này điều khiển (chuẩn hóa).
  final (double, double)? preview;

  final GameState state;
  final CampMetrics metrics;
  final FacilityType placing;

  /// Gọi khi thả một ngón trên vị trí bất kỳ; (x, y) chuẩn hóa. Bên gọi tự kiểm tra hợp lệ qua luật.
  final void Function(double x, double y) onDrop;

  @override
  State<CampPlacementLayer> createState() => _CampPlacementLayerState();
}

class _CampPlacementLayerState extends State<CampPlacementLayer> {
  final Set<int> _pointers = {};
  Offset? _ghost; // chuẩn hóa
  bool _dragging = false;
  bool _multi = false; // đã có ≥2 ngón trong lượt này

  Offset _norm(Offset local) {
    final s = widget.metrics.size;
    return Offset(local.dx / s.width, local.dy / s.height);
  }

  Offset get _initial {
    final mv = widget.moving;
    if (mv != null) return Offset(mv.x, mv.y);
    final p = GameRules.suggestPlacement(widget.state, widget.placing);
    return p == null ? const Offset(0.5, 0.2) : Offset(p.$1, p.$2);
  }

  void _down(PointerDownEvent e) {
    _pointers.add(e.pointer);
    if (_pointers.length >= 2) {
      setState(() {
        _multi = true;
        _dragging = false;
      });
      return;
    }
    if (_multi) return;
    setState(() {
      _dragging = true;
      _ghost = _norm(e.localPosition);
    });
  }

  void _move(PointerMoveEvent e) {
    if (!_dragging || _multi || _pointers.length != 1) return;
    setState(() => _ghost = _norm(e.localPosition));
  }

  void _up(PointerUpEvent e) {
    final wasDragging = _dragging && !_multi && _pointers.length == 1;
    _pointers.remove(e.pointer);
    final at = _norm(e.localPosition);
    if (_pointers.isEmpty) _multi = false;
    setState(() => _dragging = false);
    if (wasDragging) widget.onDrop(at.dx, at.dy);
  }

  void _cancel(PointerCancelEvent e) {
    _pointers.remove(e.pointer);
    if (_pointers.isEmpty) _multi = false;
    setState(() => _dragging = false);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.metrics;
    final pv = widget.preview;
    final g = _ghost ?? (pv == null ? _initial : Offset(pv.$1, pv.$2));
    final check = GameRules.checkPlacement(
      widget.state,
      widget.placing,
      g.dx,
      g.dy,
      ignoreId: widget.moving?.id,
    );
    final ok = check.ok;
    final (fw, fh) = CampLayout.footprintOf(widget.placing);
    final w = fw * m.size.width, h = fh * m.size.height;
    final color = ok ? const Color(0xFF3FBF4F) : const Color(0xFFD7392E);
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _down,
      onPointerMove: _move,
      onPointerUp: _up,
      onPointerCancel: _cancel,
      child: Stack(
        children: [
          Positioned(
            key: const ValueKey('placement-ghost'),
            left: g.dx * m.size.width - w / 2,
            top: g.dy * m.size.height - h / 2,
            width: w,
            height: h,
            child: IgnorePointer(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    key: ValueKey(ok ? 'placement-valid' : 'placement-invalid'),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: color, width: 2),
                    ),
                  ),
                  Opacity(opacity: 0.85, child: FacilityArt(widget.placing)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
