import '../../../domain/models.dart';
import 'gear_canvas.dart';

export 'gear_canvas.dart';
export 'gear_materials.dart';

/// Painter của MỘT thiết kế trang bị. Vẽ trong ô vuông chuẩn hóa [0,1]² (xem [G]); cùng một painter
/// phục vụ icon, thẻ kho đồ, bảng chi tiết và hình nhân vật.
///
/// Quy ước tư thế:
/// * Áo giáp: nhìn chính diện, vai ở trên, gấu áo ở dưới, lấp đầy ô.
/// * Khiên: nhìn chính diện, tâm ô.
/// * Vũ khí: dựng thẳng dọc trục x=0.5, đầu vũ khí ở trên (y≈0.02), đuôi ở dưới (y≈0.98).
abstract class EquipmentPainter {
  const EquipmentPainter();

  /// Id thiết kế trong `EquipmentCatalog` mà painter này vẽ.
  String get designId;

  Slot get slot;

  void paint(G g);
}

abstract class ArmorPainter extends EquipmentPainter {
  const ArmorPainter();
  @override
  Slot get slot => Slot.armor;
}

abstract class ShieldPainter extends EquipmentPainter {
  const ShieldPainter();
  @override
  Slot get slot => Slot.shield;
}

abstract class WeaponPainter extends EquipmentPainter {
  const WeaponPainter();
  @override
  Slot get slot => Slot.weapon;

  /// Điểm tay cầm (chuẩn hóa) khi vũ khí dựng thẳng; dùng để đặt vào bàn tay nhân vật.
  Offset get grip => const Offset(0.5, 0.78);
}
