import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../application/game_controller.dart';
import '../../../domain/models.dart';

/// Phiên kéo-thả xây dựng từ menu Xây: cung cấp những thứ giao diện Trại biết (đổi toạ độ màn hình → Trại,
/// controller, cách báo kết quả) cho ô công trình trong hộp thoại.
class CampBuildDrag {
  const CampBuildDrag({
    required this.worldKey,
    required this.controller,
    required this.onResult,
  });

  /// Hộp thế giới Trại (trong phép zoom).
  final GlobalKey worldKey;
  final GameController controller;
  final void Function(ActionResult) onResult;
}

/// Giữ NGÓN TAY đang nhấn giữ ô công trình trong menu Xây và dùng nó để kéo-thả vào Trại.
///
/// Nguyên nhân lỗi cũ: nhấn giữ ô → đóng hộp thoại → mới bật lớp đặt của Trại. Nhưng `Navigator.pop` HỦY mọi
/// con trỏ đang chạm (`_cancelActivePointers`), và sự kiện con trỏ chỉ tới các widget nằm trong hit-test lúc
/// ngón chạm xuống, nên Trại không bao giờ nhận được lúc kéo/thả: kéo vào Trại "không được".
/// Cách sửa: KHÔNG đóng hộp thoại khi ngón còn giữ. Vào chế độ đặt ngay (ghost hiện dưới hộp thoại đã ẩn),
/// rồi theo dõi chính con trỏ đó bằng route toàn cục ([PointerRouter]); chỉ đóng hộp thoại sau khi nhấc ngón.
class CampDragHandoff {
  CampDragHandoff._();

  static int? _pointer;
  static Offset _start = Offset.zero;
  static bool _down = false;

  /// Ô công trình gọi khi ngón chạm xuống / nhấc lên / bị hủy.
  static void pointerDown(int pointer, Offset position) {
    _pointer = pointer;
    _start = position;
    _down = true;
  }

  static void pointerUp(int pointer) {
    if (_pointer == pointer) _down = false;
  }

  /// Con trỏ đang giữ ô vừa được nhấn giữ (null nếu ngón đã nhấc).
  static (int, Offset)? takeActive() {
    final p = _down && _pointer != null ? (_pointer!, _start) : null;
    _pointer = null;
    _down = false;
    return p;
  }

  /// Quãng di chuyển tối thiểu (px) để một lần nhấc ngón được coi là THẢ công trình; nhấc ngón tại chỗ chỉ
  /// giữ chế độ đặt, tránh vô tình đặt ngay dưới vị trí ô trong menu.
  static const double dropThreshold = 12;

  /// Theo dõi [pointer]: mỗi lần di chuyển cập nhật bản xem trước (toạ độ chuẩn hóa của Trại tính từ hộp
  /// `drag.worldKey`); khi nhấc ngón thì gọi [onEnd] (moved = đã kéo xa hơn [dropThreshold]) và, nếu đã kéo,
  /// thả bằng [GameController.finishDragPlace] rồi báo qua `drag.onResult`. Hủy cử chỉ giữ nguyên chế độ đặt.
  static void attach({
    required int pointer,
    required Offset startGlobal,
    required CampBuildDrag drag,
    required VoidCallback onEnd,
  }) {
    final router = GestureBinding.instance.pointerRouter;
    var moved = false;
    final controller = drag.controller;

    (double, double)? toNorm(Offset global) {
      final box = drag.worldKey.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached || box.size.isEmpty) return null;
      final local = box.globalToLocal(global);
      return (local.dx / box.size.width, local.dy / box.size.height);
    }

    late void Function(PointerEvent) route;
    route = (PointerEvent e) {
      if (e is PointerMoveEvent) {
        if ((e.position - startGlobal).distance >= dropThreshold) moved = true;
        final p = toNorm(e.position);
        if (p != null && controller.placing != null) {
          controller.updatePlacementPreview(p.$1, p.$2);
        }
      } else if (e is PointerUpEvent) {
        router.removeRoute(pointer, route);
        final p = toNorm(e.position);
        ActionResult? result;
        if (moved && p != null && controller.placing != null) {
          result = controller.finishDragPlace(p.$1, p.$2);
        }
        onEnd();
        if (result != null) drag.onResult(result);
      } else if (e is PointerCancelEvent) {
        router.removeRoute(pointer, route);
        onEnd();
      }
    };
    router.addRoute(pointer, route);
  }
}
