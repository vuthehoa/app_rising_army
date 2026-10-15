import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../domain/catalog.dart';
import '../../../domain/equipment/equipment_effect.dart';
import '../../../domain/equipment/equipment_item.dart';
import '../../../domain/equipment/equipment_types.dart';
import '../../../domain/models.dart';
import '../art.dart';

/// Màu chữ/viền theo độ hiếm (cấp 1 dùng màu trung tính của game).
Color rarityColor(EquipmentRarity r) => r == EquipmentRarity.common
    ? Pal.dim
    : Color.lerp(Color(r.backgroundArgb), Colors.white, 0.35)!;

/// Nhãn loại ngắn của vật phẩm: "Kiếm · Một tay", "Giáp xích", "Khiên tròn".
String itemKindLabel(ItemDef d) {
  final hands = d.twoHanded ? 'Hai tay' : 'Một tay';
  return switch (d.slot) {
    Slot.weapon => '${d.weaponKind?.label ?? 'Vũ khí'} · $hands',
    Slot.armor => d.armorClass?.label ?? 'Áo giáp',
    Slot.shield => d.shape?.label ?? 'Khiên',
  };
}

String formatKg(double kg) => '${kg.toStringAsFixed(1)} kg';

/// Một dòng hiệu ứng: buff xanh, debuff đỏ, kèm điều kiện/thời hạn.
class EffectLine extends StatelessWidget {
  const EffectLine(this.effect, {super.key});
  final EquipmentEffect effect;

  @override
  Widget build(BuildContext context) {
    final color = effect.isDebuff
        ? Pal.blood
        : effect.isBuff
        ? Pal.moss
        : Pal.dim;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            effect.isDebuff ? Icons.arrow_drop_down : Icons.arrow_drop_up,
            size: 16,
            color: color,
          ),
          Expanded(
            child: Text(
              effect.describe(),
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Thẻ vật phẩm trong lưới kho đồ: hình vẽ + nền theo cấp + cấp, cân nặng, số lượng, dấu biến thể.
class EquipmentCard extends StatelessWidget {
  const EquipmentCard({
    super.key,
    required this.item,
    this.count = 1,
    this.selected = false,
    this.usable = true,
    this.onTap,
  });

  final EquipmentItem item;
  final int count;
  final bool selected;

  /// Người đang xem có đủ điều kiện dùng không (mờ đi nếu không).
  final bool usable;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = rarityColor(item.rarity);
    return Tooltip(
      message: item.displayName,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: usable ? 1 : 0.55,
              child: ItemGlyph(item.uid, size: 64),
            ),
            if (selected)
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Pal.goldLight, width: 2.4),
                ),
              ),
            Positioned(
              left: 3,
              top: 2,
              child: _Badge('${item.rarity.grade}', color),
            ),
            if (item.variantEffects.isNotEmpty)
              const Positioned(
                right: 3,
                top: 2,
                child: Icon(Icons.auto_awesome, size: 12, color: Pal.goldLight),
              ),
            Positioned(
              left: 3,
              bottom: 1,
              child: Text(
                formatKg(item.weight),
                style: const TextStyle(
                  color: Pal.text,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                ),
              ),
            ),
            if (count > 1)
              Positioned(
                right: 3,
                bottom: 1,
                child: Text(
                  '×$count',
                  style: const TextStyle(
                    color: Pal.text,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0.5),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color, width: 1),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900),
    ),
  );
}

/// Ô trang bị trên nhân vật (giáp / vũ khí / tay phụ). [locked] = ô bị chiếm (khiên khi cầm vũ khí hai tay).
class EquipmentSlotTile extends StatelessWidget {
  const EquipmentSlotTile({
    super.key,
    required this.slot,
    required this.label,
    required this.ref,
    this.size = 54,
    this.selected = false,
    this.locked = false,
    this.onTap,
  });

  final Slot slot;
  final String label;
  final String? ref;
  final double size;
  final bool selected;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final name = ref == null ? null : itemDisplayName(ref!);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: selected ? Pal.goldLight : Colors.transparent,
                width: 2,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ItemGlyph(locked ? null : ref, size: size),
                if (locked)
                  const Center(
                    child: Icon(Icons.lock, size: 20, color: Pal.muted),
                  ),
                if (ref == null && !locked)
                  Center(
                    child: Icon(
                      switch (slot) {
                        Slot.weapon => Icons.gavel,
                        Slot.armor => Icons.shield_outlined,
                        Slot.shield => Icons.security,
                      },
                      size: size * 0.4,
                      color: Pal.line,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: size + 6,
            child: Text(
              locked ? '$label (khóa)' : (name ?? '$label: trống'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: name == null ? Pal.muted : Pal.text,
                fontSize: 9.5,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
