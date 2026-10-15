import 'package:flutter/material.dart';

import '../../application/game_controller.dart';
import '../../core/theme.dart';
import '../../domain/catalog.dart';
import '../../domain/equipment/equipment_item.dart';
import '../../domain/equipment/equipment_rules.dart';
import '../../domain/equipment/equipment_types.dart';
import '../../domain/models.dart';
import '../../domain/rules.dart';
import '../../domain/stats.dart';
import '../widgets/art.dart';
import '../widgets/common.dart';
import '../widgets/equipment/equipment_widgets.dart';

/// Mở màn quản lý trang bị của binh sĩ [soldierId]. Mọi thao tác đi qua [GameController] (trang bị, tháo)
/// nên loadout, kho đồ, chỉ số và hình nhân vật ở mọi màn hình cập nhật cùng lúc.
Future<void> showEquipmentManager(
  BuildContext context,
  GameController controller,
  int soldierId, {
  Slot? focus,
  String? select,
}) => showDialog<void>(
  context: context,
  builder: (_) => EquipmentManager(
    controller: controller,
    soldierId: soldierId,
    focus: focus,
    select: select,
  ),
);

enum _TypeFilter { all, armor, weapon, shield }

class EquipmentManager extends StatefulWidget {
  const EquipmentManager({
    super.key,
    required this.controller,
    required this.soldierId,
    this.focus,
    this.select,
  });

  final GameController controller;
  final int soldierId;

  /// Ô được chọn sẵn (lọc theo loại và chọn món đang mặc).
  final Slot? focus;

  /// Mã tham chiếu của vật phẩm trong kho được chọn sẵn.
  final String? select;

  @override
  State<EquipmentManager> createState() => _EquipmentManagerState();
}

class _EquipmentManagerState extends State<EquipmentManager> {
  late _TypeFilter _type = switch (widget.focus) {
    Slot.armor => _TypeFilter.armor,
    Slot.weapon => _TypeFilter.weapon,
    Slot.shield => _TypeFilter.shield,
    _ => _TypeFilter.all,
  };
  int _grade = 0; // 0 = mọi cấp (cấp = độ hiếm)
  bool _effectsOnly = false;
  int _sort = 0;
  String? _selected; // mã tham chiếu đang xem
  bool _fromSlot = false; // đang xem món đã mặc

  static const _sortNames = [
    'Xếp: cấp',
    'Xếp: tên',
    'Xếp: nặng',
    'Xếp: chỉ số',
  ];

  @override
  void initState() {
    super.initState();
    final pick = widget.select;
    if (pick != null) {
      final def = itemDefs[pick];
      if (def != null) {
        _type = switch (def.slot) {
          Slot.armor => _TypeFilter.armor,
          Slot.weapon => _TypeFilter.weapon,
          Slot.shield => _TypeFilter.shield,
        };
        _selected = pick;
      }
      return;
    }
    final slot = widget.focus;
    if (slot != null) {
      final so = widget.controller.state?.soldier(widget.soldierId);
      final ref = so?.equipped(slot);
      if (ref != null) {
        _selected = ref;
        _fromSlot = true;
      }
    }
  }

  bool _accepts(ItemDef d) => switch (_type) {
    _TypeFilter.all => true,
    _TypeFilter.armor => d.slot == Slot.armor,
    _TypeFilter.weapon => d.slot == Slot.weapon,
    _TypeFilter.shield => d.slot == Slot.shield,
  };

  List<(EquipmentItem, int)> _entries(GameState s) {
    final out = <(EquipmentItem, int)>[];
    for (final e in s.inventory.entries) {
      if (e.value <= 0) continue;
      final item = EquipmentItem.tryParse(e.key);
      if (item == null || !_accepts(item.design)) continue;
      if (_grade != 0 && item.design.tier != _grade) continue;
      if (_effectsOnly && item.effects.isEmpty) continue;
      out.add((item, e.value));
    }
    out.sort((a, b) {
      final x = a.$1, y = b.$1;
      switch (_sort) {
        case 1:
          return x.displayName.compareTo(y.displayName);
        case 2:
          final c = x.weight.compareTo(y.weight);
          if (c != 0) return c;
        case 3:
          final c = (y.design.damageAvg + y.design.defense).compareTo(
            x.design.damageAvg + x.design.defense,
          );
          if (c != 0) return c;
        default:
          final c = y.design.tier.compareTo(x.design.tier);
          if (c != 0) return c;
      }
      return x.displayName.compareTo(y.displayName);
    });
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final w = (mq.size.width - mq.padding.horizontal - 16).clamp(320.0, 920.0);
    final h = (mq.size.height - mq.padding.vertical - 12).clamp(240.0, 420.0);
    // Hai cột bên co theo bề rộng để cột kho đồ luôn đủ chỗ cho vài cột thẻ.
    final leftW = ((w - 24) * 0.24).clamp(150.0, 220.0);
    final detailW = ((w - 24) * 0.29).clamp(190.0, 262.0);
    return Dialog(
      key: const ValueKey('equipment-manager'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      backgroundColor: Pal.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Pal.lineStrong, width: 1.5),
      ),
      child: SizedBox(
        width: w,
        height: h,
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final s = widget.controller.state;
            final so = s?.soldier(widget.soldierId);
            if (s == null || so == null || !so.alive) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.all(6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: leftW, child: _buildLeft(s, so, leftW)),
                  const SizedBox(width: 6),
                  Expanded(child: _buildInventory(s, so)),
                  const SizedBox(width: 6),
                  SizedBox(width: detailW, child: _buildDetail(s, so)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ----------------------------------------------------------------- Trái

  Widget _buildLeft(GameState s, Soldier so, double width) {
    // Ba ô trang bị chính chia đều bề rộng cột (trừ lề), tối đa 46 px.
    final tile = ((width - 16) / 3 - 6).clamp(34.0, 46.0);
    final d = deriveStats(so);
    final enc = d.encumbrance!;
    final ratio = enc.capacity <= 0 ? 1.0 : enc.load / enc.capacity;
    final weaponDef = so.weaponId == null ? null : itemDefs[so.weaponId];
    final shieldLocked = weaponDef?.twoHanded == true;
    void focusSlot(Slot slot) {
      final ref = so.equipped(slot);
      setState(() {
        _type = switch (slot) {
          Slot.armor => _TypeFilter.armor,
          Slot.weapon => _TypeFilter.weapon,
          Slot.shield => _TypeFilter.shield,
        };
        _selected = ref;
        _fromSlot = ref != null;
      });
    }

    return Panel(
      fill: true,
      padding: const EdgeInsets.all(6),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              so.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Pal.gold,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
            Text(
              '${roleNames[so.role]} cấp ${so.level} • STR ${d.stats[Stat.str]}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Pal.dim, fontSize: 10),
            ),
            const SizedBox(height: 4),
            Center(
              child: Container(
                key: const ValueKey('equip-preview'),
                decoration: BoxDecoration(
                  color: Pal.ink,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Pal.goldDim, width: 1.5),
                ),
                child: SoldierSprite.of(so, bust: false, size: 96),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                EquipmentSlotTile(
                  key: const ValueKey('equip-slot-armor'),
                  slot: Slot.armor,
                  label: 'Giáp',
                  ref: so.armorId,
                  size: tile,
                  selected:
                      _fromSlot && _selected != null && _selected == so.armorId,
                  onTap: () => focusSlot(Slot.armor),
                ),
                EquipmentSlotTile(
                  key: const ValueKey('equip-slot-weapon'),
                  slot: Slot.weapon,
                  label: 'Vũ khí',
                  ref: so.weaponId,
                  size: tile,
                  selected:
                      _fromSlot &&
                      _selected != null &&
                      _selected == so.weaponId,
                  onTap: () => focusSlot(Slot.weapon),
                ),
                EquipmentSlotTile(
                  key: const ValueKey('equip-slot-shield'),
                  slot: Slot.shield,
                  label: 'Tay phụ',
                  ref: so.shieldId,
                  size: tile,
                  locked: shieldLocked,
                  selected:
                      _fromSlot &&
                      _selected != null &&
                      _selected == so.shieldId,
                  onTap: shieldLocked ? null : () => focusSlot(Slot.shield),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Text(
                  'Tải trọng',
                  style: TextStyle(color: Pal.dim, fontSize: 10),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${enc.load.toStringAsFixed(1)} / ${enc.capacity.toStringAsFixed(1)} kg',
                      key: const ValueKey('equip-load'),
                      maxLines: 1,
                      style: TextStyle(
                        color: enc.overloaded ? Pal.blood : Pal.text,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Bar(
              value: ratio,
              color: enc.overloaded
                  ? Pal.blood
                  : (ratio > 0.8 ? Pal.gold : Pal.moss),
              height: 6,
            ),
            if (enc.overloaded)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Quá tải ${enc.excess.toStringAsFixed(1)} kg: tốc độ −${((1 - enc.speedMult) * 100).round()}%, '
                  'chu kỳ đánh +${((enc.intervalMult - 1) * 100).round()}%',
                  key: const ValueKey('equip-overload'),
                  style: const TextStyle(color: Pal.blood, fontSize: 9.5),
                ),
              ),
            const SizedBox(height: 6),
            _kv('HP', '${d.maxHp}'),
            _kv('Công', '${d.core.atk}'),
            _kv('Sát thương', d.damageRange),
            _kv('Giảm sát thương', '${(d.reduction * 100).round()}%'),
            _kv('Di chuyển', '${d.speed.toStringAsFixed(1)} m/s'),
            _kv('Chu kỳ đánh', '${d.interval.toStringAsFixed(1)} s'),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 1),
    child: Row(
      children: [
        Expanded(
          child: Text(
            k,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Pal.dim, fontSize: 10.5),
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              v,
              maxLines: 1,
              style: const TextStyle(
                color: Pal.text,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  // ----------------------------------------------------------------- Giữa

  Widget _buildInventory(GameState s, Soldier so) {
    final entries = _entries(s);
    final used = GameRules.inventoryWeightKg(s);
    final cap = GameRules.inventoryCapacity(s);
    return Panel(
      fill: true,
      padding: const EdgeInsets.all(6),
      child: LayoutBuilder(
        builder: (context, box) =>
            _inventoryBody(box.maxWidth < 340, entries, s, so, used, cap),
      ),
    );
  }

  Widget _inventoryBody(
    bool narrow,
    List<(EquipmentItem, int)> entries,
    GameState s,
    Soldier so,
    int used,
    int cap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'KHO ĐỒ',
                      style: TextStyle(
                        color: Pal.gold,
                        fontSize: 10.5,
                        letterSpacing: 1.3,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$used/$cap kg',
                      key: const ValueKey('equip-inv-count'),
                      style: const TextStyle(color: Pal.dim, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
            ),
            _Chip(
              key: const ValueKey('equip-filter-effects'),
              label: 'Hiệu ứng',
              tooltip: 'Chỉ hiện món có buff/debuff',
              icon: Icons.auto_awesome,
              iconOnly: narrow,
              selected: _effectsOnly,
              onTap: () => setState(() => _effectsOnly = !_effectsOnly),
            ),
            _Chip(
              key: const ValueKey('equip-sort'),
              label: _sortNames[_sort],
              tooltip: 'Đổi cách sắp xếp (${_sortNames[_sort]})',
              icon: Icons.sort,
              iconOnly: narrow,
              selected: false,
              onTap: () =>
                  setState(() => _sort = (_sort + 1) % _sortNames.length),
            ),
            IconButton(
              key: const ValueKey('equip-close'),
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 32),
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, size: 20, color: Pal.dim),
            ),
          ],
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final t in _TypeFilter.values)
                _Chip(
                  key: ValueKey('equip-filter-type-${t.name}'),
                  label: switch (t) {
                    _TypeFilter.all => 'Tất cả',
                    _TypeFilter.armor => 'Giáp',
                    _TypeFilter.weapon => 'Vũ khí',
                    _TypeFilter.shield => 'Khiên',
                  },
                  selected: _type == t,
                  onTap: () => setState(() => _type = t),
                ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _Chip(
                key: const ValueKey('equip-filter-grade-0'),
                label: 'Mọi cấp',
                selected: _grade == 0,
                onTap: () => setState(() => _grade = 0),
              ),
              for (final r in EquipmentRarity.values)
                _Chip(
                  key: ValueKey('equip-filter-grade-${r.grade}'),
                  label: '${r.grade}',
                  tooltip: 'Cấp ${r.grade} · ${r.label}',
                  color: rarityColor(r),
                  selected: _grade == r.grade,
                  onTap: () =>
                      setState(() => _grade = _grade == r.grade ? 0 : r.grade),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: entries.isEmpty
              ? const Center(
                  child: Text(
                    'Không có vật phẩm phù hợp.\nMua ở Lò rèn, nhận từ nhiệm vụ hoặc chiến lợi phẩm.',
                    key: ValueKey('equip-empty'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Pal.dim, fontSize: 11),
                  ),
                )
              : GridView.builder(
                  key: const ValueKey('equip-grid'),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 66,
                    mainAxisSpacing: 5,
                    crossAxisSpacing: 5,
                  ),
                  itemCount: entries.length,
                  itemBuilder: (context, i) {
                    final (item, count) = entries[i];
                    return EquipmentCard(
                      key: ValueKey('equip-card-${item.uid}'),
                      item: item,
                      count: count,
                      selected: !_fromSlot && _selected == item.uid,
                      usable: equipProblem(so, item.design) == null,
                      onTap: () => setState(() {
                        _selected = item.uid;
                        _fromSlot = false;
                      }),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- Phải

  Widget _buildDetail(GameState s, Soldier so) {
    final ref = _selected;
    final item = ref == null ? null : EquipmentItem.tryParse(ref);
    // Món đang xem không còn (đã được trang bị cho người khác, đã bán…): bỏ chọn một cách êm.
    final stillThere =
        item != null &&
        (_fromSlot
            ? so.equipped(item.slot) == ref
            : (s.inventory[ref] ?? 0) > 0);
    if (item == null || !stillThere) {
      return const Panel(
        fill: true,
        child: Center(
          child: Text(
            'Chọn một vật phẩm trong kho hoặc một ô trang bị để xem chi tiết và so sánh.',
            key: ValueKey('equip-detail-hint'),
            textAlign: TextAlign.center,
            style: TextStyle(color: Pal.dim, fontSize: 11),
          ),
        ),
      );
    }
    final def = item.design;
    final slot = def.slot;
    final current = so.equipped(slot);
    final before = deriveStats(so);
    final Derived after;
    if (_fromSlot) {
      after = deriveStats(so, override: {slot: null});
    } else {
      after = deriveStats(so, override: {slot: item.uid});
    }
    final problem = _fromSlot ? null : equipProblem(so, def);
    final color = rarityColor(item.rarity);
    final displacedShield =
        !_fromSlot &&
        EquipmentRules.displacesShield(def) &&
        so.shieldId != null;

    Widget row(
      String k,
      num b,
      num a, {
      int digits = 0,
      bool lowerBetter = false,
      String suffix = '',
    }) {
      final c = deltaColor(b, a, lowerBetter: lowerBetter);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          children: [
            Flexible(
              flex: 2,
              child: Text(
                k,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Pal.dim, fontSize: 10.5),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 5,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${b.toStringAsFixed(digits)}$suffix',
                      style: const TextStyle(color: Pal.dim, fontSize: 10.5),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 3),
                      child: Icon(
                        Icons.arrow_right_alt,
                        size: 12,
                        color: Pal.dim,
                      ),
                    ),
                    Text(
                      '${a.toStringAsFixed(digits)}$suffix',
                      style: TextStyle(
                        color: c,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        statDelta(b, a, digits: digits),
                        textAlign: TextAlign.right,
                        style: TextStyle(color: c, fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final fixed = def.traits;
    final variant = item.variantEffects;
    return Panel(
      fill: true,
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              key: const ValueKey('equip-detail'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ItemGlyph(item.uid, size: 54),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.displayName,
                              key: const ValueKey('equip-detail-name'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: color == Pal.dim ? Pal.text : color,
                                fontWeight: FontWeight.w900,
                                fontSize: 12.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Wrap(
                              spacing: 4,
                              runSpacing: 2,
                              children: [
                                Pill(
                                  'Cấp ${item.rarity.grade} · ${item.rarity.label}',
                                  color: color,
                                ),
                                Pill(
                                  formatKg(item.weight),
                                  icon: Icons.fitness_center,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    itemKindLabel(def),
                    style: const TextStyle(color: Pal.dim, fontSize: 10.5),
                  ),
                  if (def.blurb.isNotEmpty)
                    Text(
                      def.blurb,
                      style: const TextStyle(
                        color: Pal.muted,
                        fontSize: 10,
                        height: 1.2,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'Yêu cầu: cấp ${def.reqLevel}${def.reqStr > 0 ? ' • STR ${def.reqStr}' : ''}',
                    key: const ValueKey('equip-detail-req'),
                    style: TextStyle(
                      color: equipProblem(so, def) == null || _fromSlot
                          ? Pal.dim
                          : Pal.blood,
                      fontSize: 10.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _section('Chỉ số nền'),
                  if (def.damageMax > 0) _kv('Sát thương', def.damageRange),
                  if (def.defense > 0) _kv('Phòng thủ', '${def.defense}'),
                  if (def.weaponType != null) ...[
                    _kv(
                      'Chu kỳ / tầm',
                      '${def.interval.toStringAsFixed(1)} s • ${def.range.toStringAsFixed(1)} m',
                    ),
                    if (def.totalArmorPen > 0)
                      _kv('Xuyên giáp', '${def.totalArmorPen}'),
                  ],
                  const SizedBox(height: 4),
                  _section('Buff / Debuff'),
                  if (fixed.isEmpty && variant.isEmpty)
                    const Text(
                      'Không có hiệu ứng.',
                      style: TextStyle(color: Pal.muted, fontSize: 10.5),
                    ),
                  for (final e in fixed) EffectLine(e),
                  for (final e in variant) EffectLine(e),
                  if (variant.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Text(
                        'Gồm hiệu ứng riêng của bản sao này.',
                        style: TextStyle(color: Pal.muted, fontSize: 9.5),
                      ),
                    ),
                  const SizedBox(height: 4),
                  _section(
                    _fromSlot
                        ? 'Nếu tháo ra (trước → sau)'
                        : (current == null
                              ? 'Nếu trang bị (trước → sau)'
                              : 'So với đang mặc (trước → sau)'),
                  ),
                  if (!_fromSlot && current != null)
                    Text(
                      'Đang mặc: ${itemDisplayName(current)}',
                      style: const TextStyle(color: Pal.gold, fontSize: 10),
                    ),
                  row('HP', before.maxHp, after.maxHp),
                  row('Thể lực', before.maxEnergy, after.maxEnergy),
                  row('Tinh thần', before.maxMorale, after.maxMorale),
                  row('Sức mạnh', before.core.str, after.core.str),
                  row('Tốc độ', before.core.dex, after.core.dex),
                  row('Thể hình', before.core.con, after.core.con),
                  row('Công', before.core.atk, after.core.atk),
                  row(
                    'Sát thương tối thiểu',
                    before.damageMin,
                    after.damageMin,
                  ),
                  row('Sát thương tối đa', before.damageMax, after.damageMax),
                  row(
                    'Giảm sát thương',
                    before.reduction * 100,
                    after.reduction * 100,
                    suffix: '%',
                  ),
                  row(
                    'Di chuyển',
                    before.speed,
                    after.speed,
                    digits: 1,
                    suffix: ' m/s',
                  ),
                  row(
                    'Chu kỳ đánh',
                    before.interval,
                    after.interval,
                    digits: 2,
                    lowerBetter: true,
                    suffix: ' s',
                  ),
                  row(
                    'Chính xác',
                    before.accuracy * 100,
                    after.accuracy * 100,
                    suffix: '%',
                  ),
                  row(
                    'Chí mạng',
                    before.crit * 100,
                    after.crit * 100,
                    suffix: '%',
                  ),
                  row('Xuyên giáp', before.armorPen, after.armorPen),
                  row(
                    'Tải trọng',
                    before.gearWeight,
                    after.gearWeight,
                    digits: 1,
                    lowerBetter: true,
                    suffix: ' kg',
                  ),
                  if (displacedShield)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        'Vũ khí hai tay: khiên ${itemDisplayName(so.shieldId!)} sẽ được cất vào kho.',
                        key: const ValueKey('equip-displace-note'),
                        style: const TextStyle(color: Pal.gold, fontSize: 10),
                      ),
                    ),
                  if (problem != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        problem,
                        key: const ValueKey('equip-problem'),
                        style: const TextStyle(
                          color: Pal.blood,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (_fromSlot)
                Expanded(
                  child: GameButton(
                    key: const ValueKey('equip-unequip'),
                    label: 'Tháo ra',
                    danger: true,
                    dense: true,
                    onPressed: () => _unequip(so, slot),
                  ),
                )
              else
                Expanded(
                  child: GameButton(
                    key: const ValueKey('equip-action'),
                    label: current == null ? 'Trang bị' : 'Thay thế',
                    dense: true,
                    onPressed: problem != null ? null : () => _equip(so, item),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _section(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Text(
      t.toUpperCase(),
      style: const TextStyle(
        color: Pal.gold,
        fontSize: 9.5,
        letterSpacing: 1,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  void _equip(Soldier so, EquipmentItem item) {
    final r = widget.controller.equip(so.id, item.uid, slot: item.slot);
    toast(context, r);
    if (r.ok) {
      setState(() {
        _selected = item.uid;
        _fromSlot = true;
      });
    }
  }

  void _unequip(Soldier so, Slot slot) {
    final r = widget.controller.unequip(so.id, slot);
    toast(context, r);
    if (r.ok) setState(() => _selected = null);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
    this.tooltip,
    this.icon,
    this.iconOnly = false,
  });

  /// Khi [iconOnly] (màn hẹp) chỉ hiện [icon], nhãn đưa vào tooltip.
  final IconData? icon;
  final bool iconOnly;

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Pal.goldLight;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Tooltip(
        message: tooltip ?? label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 30,
            constraints: const BoxConstraints(minWidth: 34),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? Pal.goldDeep : Pal.bgDeep,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: selected ? c : Pal.line,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: selected ? c : (color ?? Pal.dim),
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
