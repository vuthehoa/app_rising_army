import 'dart:math';

import '../../../../domain/catalog.dart';
import '../../../../domain/equipment/equipment_catalog.dart';
import '../../../../domain/equipment/equipment_ref.dart';
import '../../../../domain/equipment/equipment_types.dart';
import '../../equipment/equipment_painter.dart';
import '../../equipment/equipment_registry.dart';
import '../../equipment/equipment_renderer.dart';

/// Lớp trang bị của binh sĩ Trung cổ.
///
/// Tất cả trang bị vẫn được vẽ bằng EquipmentRenderer và painter gốc,
/// đảm bảo ngoại hình thống nhất giữa sprite, thẻ kho đồ và màn hình chi tiết.
///
/// Thứ tự lớp do SoldierPainter quản lý:
/// thân -> tay áo -> giáp -> băng bó -> khiên -> tay/vũ khí -> đầu.
///
/// Lưu ý: tọa độ được tính theo kích thước khung, không phụ thuộc pixel cố định.
class SoldierGearLayer {
  SoldierGearLayer({this.armorRef, this.weaponRef, this.shieldRef});

  final String? armorRef;
  final String? weaponRef;
  final String? shieldRef;

  ItemDef? _def(String? ref) {
    if (ref == null || ref.isEmpty) return null;
    return itemDefs[ref];
  }

  ItemDef? _valid(ItemDef? definition, String? ref) {
    if (definition == null || ref == null || ref.isEmpty) return null;

    try {
      if (!EquipmentCatalog.contains(designIdOf(ref))) return null;
      return definition;
    } catch (_) {
      return null;
    }
  }

  late final ItemDef? armor = _valid(_def(armorRef), armorRef);
  late final ItemDef? weapon = _valid(_def(weaponRef), weaponRef);
  late final ItemDef? _shield = _valid(_def(shieldRef), shieldRef);

  /// Vũ khí hai tay không thể dùng khiên cùng lúc.
  ItemDef? get shield => twoHanded ? null : _shield;

  bool get twoHanded => weapon?.twoHanded == true;

  /// Chiều dài tương đối của từng loại vũ khí.
  ///
  /// Đây là chiều dài trong khung vẽ, không phải thông số sát thương.
  static double weaponLength(WeaponKind? kind, bool twoHanded) {
    return switch (kind) {
      WeaponKind.dagger => 0.34,
      WeaponKind.sword => 0.53,
      WeaponKind.saber => 0.55,
      WeaponKind.greatsword => 0.79,
      WeaponKind.axe => 0.54,
      WeaponKind.greataxe => 0.80,
      WeaponKind.mace => 0.52,
      WeaponKind.flail => 0.57,
      WeaponKind.hammer => twoHanded ? 0.78 : 0.58,
      WeaponKind.spear => 0.88,
      WeaponKind.polearm => 0.96,
      WeaponKind.bow => 0.78,
      WeaponKind.crossbow => 0.57,
      null => 0.48,
    };
  }

  /// Kích thước khiên theo hình dạng.
  static double shieldSize(ShieldShape? shape) {
    return switch (shape) {
      ShieldShape.buckler => 0.28,
      ShieldShape.tower || ShieldShape.pavise => 0.45,
      ShieldShape.kite => 0.42,
      ShieldShape.rectangle => 0.43,
      null => 0.38,
      _ => 0.38,
    };
  }

  /// Vẽ giáp phủ lên thân.
  ///
  /// Dùng renderer gốc để giữ đúng thiết kế từng món giáp.
  /// Clip tránh giáp tràn xuống vùng chân hoặc ra ngoài thân.
  void paintArmor(
    Canvas canvas,
    double w,
    double h,
    double top,
    double bottom,
  ) {
    final ref = armorRef;
    if (armor == null || ref == null) return;

    final side = w * 0.66;
    final y0 = top - h * 0.035;

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(w * 0.14, y0, w * 0.86, bottom + h * 0.025));

    EquipmentRenderer.paintUpright(
      canvas,
      ref,
      Rect.fromLTWH((w - side) / 2, y0, side, side),
    );

    canvas.restore();
  }

  /// Vẽ khiên phía tay trái.
  ///
  /// Khiên lớn được dịch nhẹ ra ngoài để hạn chế che toàn bộ phần ngực.
  /// Trả về false nếu nhân vật không có khiên hợp lệ.
  bool paintShield(
    Canvas canvas,
    double w,
    double h,
    double top,
    double bottom,
  ) {
    final definition = shield;
    final ref = shieldRef;

    if (definition == null || ref == null) return false;

    final side = w * shieldSize(definition.shape);
    final cy = top + (bottom - top) * 0.43;

    final centerX = switch (definition.shape) {
      ShieldShape.tower || ShieldShape.pavise => w * 0.19,
      ShieldShape.kite || ShieldShape.rectangle => w * 0.20,
      _ => w * 0.205,
    };

    final rect = Rect.fromCenter(
      center: Offset(centerX, cy),
      width: side,
      height: side,
    );

    EquipmentRenderer.paintUpright(canvas, ref, rect);

    return true;
  }

  /// Điểm tay chính.
  ///
  /// Vũ khí một tay được giữ gần cạnh phải thân.
  /// Vũ khí hai tay dịch vào giữa để tư thế cầm tự nhiên hơn.
  Offset mainHand(double w, double h, double top, double armH) {
    final x = twoHanded ? 0.675 : 0.765;
    final y = top + h * 0.02 + armH * 0.90;

    return Offset(w * x, y);
  }

  /// Điểm tay phụ cho vũ khí hai tay.
  ///
  /// Trả về null khi nhân vật không dùng vũ khí hai tay.
  Offset? offHand(Offset main, double length, double angle) {
    if (!twoHanded) return null;

    final distance = length * 0.14;

    return main + Offset(sin(angle) * distance, -cos(angle) * distance);
  }

  /// Vẽ vũ khí đang cầm.
  ///
  /// Trả về vị trí tay, chiều dài và góc để SoldierPainter vẽ bàn tay
  /// đúng vị trí sau khi renderer đã vẽ vũ khí.
  ({Offset hand, double length, double angle})? paintWeapon(
    Canvas canvas,
    double w,
    double h,
    double top,
    double armH,
    bool bust,
  ) {
    final definition = weapon;
    final ref = weaponRef;

    if (definition == null || ref == null) return null;

    final painter = EquipmentRegistry.maybe(definition.id);

    final grip = painter is WeaponPainter
        ? painter.grip
        : const Offset(0.5, 0.78);

    final hand = mainHand(w, h, top, armH);

    var length =
        weaponLength(definition.weaponKind, definition.twoHanded) *
        h *
        (bust ? 1.0 : 0.84);

    // Giữ đầu vũ khí trong khung.
    final gripY = grip.dy.clamp(0.1, 1.0);
    final maxLength = (hand.dy - h * 0.035) / gripY;

    length = min(length, maxLength);
    length = max(0.0, length);

    // Góc nhẹ để tránh tư thế cầm thẳng cứng nhắc.
    final angle = twoHanded ? 0.12 : 0.18;

    EquipmentRenderer.paintHeld(canvas, ref, hand, length, angle: angle);

    return (hand: hand, length: length, angle: angle);
  }
}
