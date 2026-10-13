import 'package:flutter/material.dart';

/// Nền Trại nhận binh sĩ được kéo thả TỰ DO. Nằm DƯỚI lớp công trình nên thả lên công trình vẫn do công
/// trình xử lý (gán binh sĩ); chỉ khi không có công trình nhận thì mới tới đây.
///
/// Vị trí thả là tọa độ màn hình của ngón tay, đổi sang tọa độ chuẩn hóa của khung Trại bằng
/// `globalToLocal` của chính widget này, nên đã bao gồm phép zoom/tịnh tiến của [CampViewport].
class CampSoldierDropGround extends StatelessWidget {
  const CampSoldierDropGround({super.key, required this.onDrop});

  /// (id binh sĩ, x, y) với x, y là phân số 0..1 của khung Trại.
  final void Function(int soldierId, double x, double y) onDrop;

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (d) {
        final box = context.findRenderObject() as RenderBox;
        final local = box.globalToLocal(d.offset);
        onDrop(d.data, local.dx / box.size.width, local.dy / box.size.height);
      },
      builder: (context, _, _) => const SizedBox.expand(),
    );
  }
}
