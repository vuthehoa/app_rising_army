import 'package:flutter/material.dart';

import '../../../../core/theme.dart';
import '../../../../domain/catalog.dart';
import '../../../../domain/equipment/equipment_catalog.dart';
import '../../../../domain/equipment/equipment_ref.dart';
import '../../../../domain/item_grade.dart';
import '../../equipment/equipment_renderer.dart';

/// Biểu tượng vật phẩm vẽ bằng code. [itemId] là id thiết kế HOẶC mã bản sao (`thiết_kế~biến_thể`).
/// Vũ khí/giáp/khiên dùng painter riêng của từng thiết kế (nền theo độ hiếm); mũ và phụ kiện dùng
/// biểu tượng chung theo bậc.
class ItemGlyph extends StatelessWidget {
  const ItemGlyph(this.itemId, {super.key, this.size = 36});
  final String? itemId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final id = itemId;
    if (id != null && EquipmentCatalog.contains(designIdOf(id))) {
      return EquipmentIcon(id, size: size);
    }
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: ItemPainter(id)),
    );
  }
}

class ItemPainter extends CustomPainter {
  ItemPainter(this.id);
  final String? id;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final it = id == null ? null : itemDefs[id];
    // Nền phẩm cấp dùng chung (xem domain/item_grade.dart); Level 1 giữ nền mặc định.
    final gradeArgb = it == null ? null : gradeBackgroundArgb(it.grade);
    final slotBg = Paint()
      ..color = gradeArgb == null
          ? Pal.ink
          : Color.alphaBlend(Color(gradeArgb).withValues(alpha: 0.85), Pal.ink);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(w * 0.15)),
      slotBg,
    );
    if (it == null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.1, h * 0.1, w * 0.8, h * 0.8),
          Radius.circular(w * 0.1),
        ),
        Paint()
          ..color = Pal.line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      return;
    }
    // Vũ khí/giáp/khiên do [EquipmentIcon] vẽ bằng painter riêng của từng thiết kế (xem [ItemGlyph]).
  }

  @override
  bool shouldRepaint(covariant ItemPainter old) => old.id != id;
}
