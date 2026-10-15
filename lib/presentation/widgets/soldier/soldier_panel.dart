import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/core/theme.dart';
import 'package:app_rising_army/domain/building_effects.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/equipment/equipment_loadout.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/domain/stats.dart';
import 'package:app_rising_army/presentation/widgets/art/equipment/item_glyph.dart';
import 'package:app_rising_army/presentation/widgets/art/soldiers/soldier_painter.dart';
import 'package:app_rising_army/presentation/widgets/camp/soldier_info_dialog.dart';
import 'package:app_rising_army/presentation/widgets/common.dart';
import 'package:app_rising_army/presentation/widgets/equipment/equipment_widgets.dart';
import 'package:app_rising_army/presentation/widgets/item_kit.dart';
import 'package:app_rising_army/presentation/widgets/rename_dialog.dart';
import 'package:app_rising_army/presentation/widgets/soldier_condition_widgets.dart';
import 'package:app_rising_army/presentation/widgets/stat_icon.dart';
import 'package:flutter/material.dart';
import 'package:app_rising_army/domain/economy.dart';

const _label = TextStyle(color: Pal.dim, fontSize: 10);
const _value = TextStyle(
  color: Pal.text,
  fontSize: 11,
  fontWeight: FontWeight.w800,
);

class SoldierPanel extends StatelessWidget {
  const SoldierPanel({
    super.key,
    required this.state,
    required this.soldier,
    required this.controller,
    this.recruitPreview = false,
    this.onRecruit,
  });

  final GameState state;
  final Soldier soldier;
  final GameController controller;
  final VoidCallback? onRecruit;

  /// true: chỉ hiển thị thông tin nhân vật khi xem ứng viên ở Quán rượu.
  /// false: hiển thị đầy đủ giao diện lính trong doanh trại.
  final bool recruitPreview;

  @override
  Widget build(BuildContext context) {
    final so = soldier;
    final fac = GameRules.facilityOf(state, so.id);
    final base = deriveStats(so);
    final d = deriveStats(so, training: fac?.type);
    final trainStat = fac == null ? null : facilityDefs[fac.type]!.trains;
    final maxLevel = so.level >= maxSoldierLevel;
    final need = xpForNext(so.level);
    final dailyUpkeep = UpkeepEconomy.forSoldiers(state.roster);
    final dailyGold = dailyUpkeep[Res.coins] ?? 0;
    final dailyFood = dailyUpkeep[Res.food] ?? 0;
    Widget? plusFor(MainStat stat) {
      if (recruitPreview || so.statPoints <= 0) return null;

      return PlusStatButton(
        key: ValueKey('plus-${stat.name}'),
        onPressed: () => controller.allocateStat(so.id, stat),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // =========================================================
          // 1. TÊN NHÂN VẬT
          // =========================================================
          if (recruitPreview)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Pal.gold.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Pal.gold.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Text(
                      so.name,
                      key: const ValueKey('soldier-name'),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Pal.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  key: const ValueKey('soldier-recruit-button'),
                  onPressed: onRecruit,
                  icon: const Icon(Icons.person_add_alt_1, size: 18),
                  label: const Text('Chiêu mộ'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Pal.moss,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    minimumSize: const Size(0, 42),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Pal.gold.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Pal.gold.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Tooltip(
                      message: 'Đổi tên',
                      child: InkWell(
                        key: const ValueKey('soldier-rename-button'),
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _rename(context),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 38),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  so.name,
                                  key: const ValueKey('soldier-name'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Pal.text,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.edit, size: 16, color: Pal.gold),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Sa thải',
                  child: Container(
                    decoration: BoxDecoration(
                      color: Pal.blood.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Pal.blood.withValues(alpha: 0.35),
                      ),
                    ),
                    child: IconButton(
                      key: const ValueKey('soldier-dismiss-button'),
                      onPressed: () => _dismiss(context),
                      tooltip: 'Sa thải',
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(10),
                      constraints: const BoxConstraints(
                        minWidth: 42,
                        minHeight: 42,
                      ),
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: Pal.blood,
                      ),
                    ),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 8),

          // =========================================================
          // 2. TRẠNG THÁI NHÂN VẬT
          // Chế độ tuyển mộ chỉ hiển thị HP, thể lực, tinh thần.
          // =========================================================

          // =========================================================
          // 2. TRẠNG THÁI NHÂN VẬT
          // =========================================================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
            decoration: BoxDecoration(
              color: Pal.text.withValues(alpha: 0.035),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Pal.text.withValues(alpha: 0.09)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _Stat3(
                    const StatIcon(EffectStat.hp, size: 21),
                    'HP',
                    '${so.hp}/${base.maxHp}',
                    big: true,
                  ),
                ),
                Expanded(
                  child: _Stat3(
                    const StatIcon(EffectStat.speed),
                    'Thể lực',
                    '${so.energy}/${energyCap(so)}',
                  ),
                ),
                Expanded(
                  child: _Stat3(
                    const StatIcon(EffectStat.morale),
                    'Tinh thần',
                    '${so.morale}/${moraleCap(so)}',
                  ),
                ),

                if (!recruitPreview) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Pal.panel,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Pal.lineStrong),
                    ),
                    child: Row(
                      children: [
                        Icon(resIcons[Res.coins]!, size: 14, color: Pal.gold),
                        const SizedBox(width: 3),
                        Text(
                          '$dailyGold',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(resIcons[Res.food]!, size: 14, color: Pal.moss),
                        const SizedBox(width: 3),
                        Text(
                          '$dailyFood',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 10),

          // =========================================================
          // 3. CHỈ SỐ CƠ BẢN + NHÂN VẬT
          // Chế độ tuyển mộ bỏ toàn bộ khu vực trang bị.
          // =========================================================

          // =========================================================
          // 3. CHỈ SỐ CƠ BẢN + NHÂN VẬT + TRANG BỊ
          // =========================================================
          SizedBox(
            height: recruitPreview ? 148 : 132,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cột chỉ số
                Expanded(
                  flex: recruitPreview ? 3 : 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Pal.text.withValues(alpha: 0.025),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Pal.text.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _Row(
                          'Sức mạnh',
                          '${d.core.str}',
                          stat: EffectStat.strength,
                          baseValue: '${base.core.str}',
                          plus: plusFor(MainStat.strength),
                        ),
                        _Row(
                          'Tốc độ',
                          '${d.core.dex}',
                          stat: EffectStat.speed,
                          baseValue: '${base.core.dex}',
                          plus: plusFor(MainStat.speed),
                        ),
                        _Row(
                          'Thể hình',
                          '${d.core.con}',
                          stat: EffectStat.stamina,
                          baseValue: '${base.core.con}',
                          plus: plusFor(MainStat.build),
                        ),
                        _Row(
                          'Công',
                          '${d.core.atk}',
                          stat: EffectStat.attack,
                          baseValue: '${base.core.atk}',
                          plus: plusFor(MainStat.attack),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                // Cột hình nhân vật, cấp và EXP
                Expanded(
                  flex: recruitPreview ? 4 : 4,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 5),
                    decoration: BoxDecoration(
                      color: Pal.gold.withValues(alpha: 0.045),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Pal.gold.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, box) {
                              final spriteSize = box.biggest.shortestSide.clamp(
                                32.0,
                                100.0,
                              );

                              return Center(
                                child: LevelUpMark(
                                  show: !recruitPreview && so.statPoints > 0,
                                  size: 18,
                                  child: SoldierSprite.of(
                                    so,
                                    bust: false,
                                    size: spriteSize,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.military_tech,
                              size: 13,
                              color: Pal.gold,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                'CẤP ${so.level}',
                                key: const ValueKey('soldier-level'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Pal.gold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            if (!recruitPreview && so.statPoints > 0) ...[
                              const SizedBox(width: 3),
                              Text(
                                '+${so.statPoints}',
                                style: const TextStyle(
                                  color: Pal.gold,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        _SoldierExpBar(
                          key: const ValueKey('soldier-exp-bar'),
                          current: so.xp,
                          maximum: need,
                          progress: maxLevel ? 1 : so.xp / need,
                          maxLevel: maxLevel,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                // Cột trang bị: luôn hiển thị cả ba ô
                Expanded(
                  flex: recruitPreview ? 3 : 3,
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final cell = ((box.maxHeight - 8) / 3).clamp(
                        0.0,
                        box.maxWidth - 18,
                      );

                      final twoHanded =
                          so.weaponId != null &&
                          itemDefs[so.weaponId]?.twoHanded == true;

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _EquipCell(
                            1,
                            Slot.armor,
                            'armor',
                            so.armorId,
                            'Áo giáp',
                            cell,
                            soldier: so,
                            controller: controller,
                          ),
                          _EquipCell(
                            2,
                            Slot.weapon,
                            'weapon',
                            so.weaponId,
                            'Vũ khí',
                            cell,
                            soldier: so,
                            controller: controller,
                          ),
                          _EquipCell(
                            3,
                            Slot.shield,
                            'shield',
                            twoHanded ? null : so.shieldId,
                            'Khiên',
                            cell,
                            soldier: so,
                            controller: controller,
                            locked: twoHanded,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // =========================================================
          // 4. CHỈ SỐ CHIẾN ĐẤU + HIỆU ỨNG TRANG BỊ
          // =========================================================
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Pal.text.withValues(alpha: 0.035),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Pal.text.withValues(alpha: 0.09)),
                  ),
                  child: Center(
                    child: Wrap(
                      alignment: WrapAlignment.spaceAround,
                      runAlignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 10,
                      children: [
                        _Stat3(
                          const Icon(
                            Icons.gps_fixed,
                            size: 16,
                            color: Pal.text,
                          ),
                          'Trúng',
                          '${(d.accuracy * 100).round()}%',
                        ),
                        _Stat3(
                          const StatIcon(EffectStat.speed),
                          'Di chuyển',
                          '${d.speed.toStringAsFixed(1)} m/s',
                        ),
                        _Stat3(
                          const Icon(
                            Icons.hourglass_bottom,
                            size: 16,
                            color: Pal.text,
                          ),
                          'Thời gian',
                          '${d.interval.toStringAsFixed(1)} S',
                        ),
                        _Stat3(
                          const StatIcon(EffectStat.attack),
                          'Sát thương',
                          d.damageRange,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // Buff/debuff nằm cùng hàng, bên phải chỉ số chiến đấu.
              _GearEffects(soldier: soldier),
            ],
          ),

          // =========================================================
          // 5. HUẤN LUYỆN
          // Chỉ hiện với lính đang được bố trí ở công trình.
          // =========================================================
          if (!recruitPreview && fac != null && trainStat != null) ...[
            const SizedBox(height: 8),
            _TrainingLine(
              key: const ValueKey('soldier-training'),
              facility: facilityDefs[fac.type]!.name,
              stat: statNames[trainStat]!,
              percent: so.train[trainStat] ?? 0,
              ratePerDay: trainingRates(fac.type, fac.level)[trainStat] ?? 0,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _dismiss(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _DismissDialog(name: soldier.name),
    );

    if (ok != true || !context.mounted) return;

    final r = controller.dismiss(soldier.id);
    toast(context, r);

    if (r.ok) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _rename(BuildContext context) {
    return showRenameSoldierDialog(context, controller, soldier);
  }
}

/// Xác nhận sa thải. Nút xác nhận chỉ bấm được một lần (chặn bấm lặp trong lúc dialog đang đóng).
class _DismissDialog extends StatefulWidget {
  const _DismissDialog({required this.name});
  final String name;

  @override
  State<_DismissDialog> createState() => _DismissDialogState();
}

class _DismissDialogState extends State<_DismissDialog> {
  bool _done = false;

  @override
  Widget build(BuildContext context) => AlertDialog(
    key: const ValueKey('soldier-dismiss-dialog'),
    title: const Text('Sa thải binh sĩ'),
    content: Text(
      'Sa thải ${widget.name}? Binh sĩ sẽ bị loại khỏi đội quân hiện tại và '
      'có thể không hoàn tác được. Trang bị đang mang sẽ được trả về kho.',
    ),
    actions: [
      TextButton(
        key: const ValueKey('soldier-dismiss-cancel'),
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Hủy'),
      ),
      TextButton(
        key: const ValueKey('soldier-dismiss-confirm'),
        style: TextButton.styleFrom(foregroundColor: Pal.blood),
        onPressed: _done
            ? null
            : () {
                setState(() => _done = true);
                Navigator.pop(context, true);
              },
        child: const Text('Xác nhận sa thải'),
      ),
    ],
  );
}

/// Thanh EXP của nhân vật.
///
/// - Phần nền thể hiện lượng EXP còn thiếu.
/// - Phần màu vàng lấp đầy theo tiến độ EXP hiện tại.
/// - EXP hiện tại / EXP cần được đặt ngay bên trong thanh.
/// - Khi đạt cấp tối đa, hiển thị trạng thái TỐI ĐA.
class _SoldierExpBar extends StatelessWidget {
  const _SoldierExpBar({
    super.key,
    required this.current,
    required this.maximum,
    required this.progress,
    required this.maxLevel,
  });

  final int current;
  final int maximum;
  final double progress;
  final bool maxLevel;

  @override
  Widget build(BuildContext context) {
    final value = progress.clamp(0.0, 1.0).toDouble();

    return Container(
      height: 22,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF25231F),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Pal.gold.withValues(alpha: 0.55), width: 1),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!maxLevel && value > 0)
            Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: value,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF806021),
                        Pal.gold,
                        const Color(0xFFEBCB70),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          if (maxLevel)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF806021), Pal.gold, Color(0xFFEBCB70)],
                ),
              ),
            ),

          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  maxLevel ? 'TỐI ĐA' : '$current / $maximum EXP',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: value >= 0.55 || maxLevel
                        ? const Color(0xFF211A0D)
                        : Pal.text,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    shadows: value >= 0.55 || maxLevel
                        ? const []
                        : [const Shadow(color: Colors.black, blurRadius: 2)],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hộp đổi tên: chỉ đóng khi lưu thành công (luật [GameRules.rename] kiểm tra tên rỗng / độ dài).
/// Icon phía trên, nhãn nhỏ, giá trị phía dưới; co lại nếu hẹp để không tràn/xuống dòng. [big]: HP nổi bật.

class _Stat3 extends StatelessWidget {
  const _Stat3(this.icon, this.label, this.value, {this.big = false})
    : flex = 2;

  final Widget icon;
  final String label;
  final String value;
  final bool big;
  final int flex;

  @override
  Widget build(BuildContext context) {
    final valueStyle = big ? _value.copyWith(fontSize: 14) : _value;

    return Tooltip(
      message: '$label: $value',
      triggerMode: TooltipTriggerMode.tap,
      preferBelow: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            icon,
            const SizedBox(height: 3),
            Text(value, style: valueStyle, maxLines: 1, softWrap: false),
          ],
        ),
      ),
    );
  }
}

/// Một dòng chỉ số: chỉ hiển thị icon.
/// Nhấn icon để xem tên chỉ số; giá trị và buff vẫn hiển thị như cũ.
class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.stat, this.baseValue, this.plus})
    : valueKey = null;

  final Widget? plus;
  final String? valueKey;
  final String label;
  final String value;
  final EffectStat? stat;
  final String? baseValue;

  @override
  Widget build(BuildContext context) {
    final boosted = baseValue != null && baseValue != value;

    final valueText = Text(
      value,
      key: valueKey == null ? null : ValueKey<String>(valueKey!),
      style: boosted
          ? _value.copyWith(color: EffectCell.buffColorDark)
          : _value,
      maxLines: 1,
      softWrap: false,
    );

    return Row(
      children: [
        if (stat != null)
          Tooltip(
            message: label,
            triggerMode: TooltipTriggerMode.tap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: StatIcon(stat!, size: 18),
            ),
          ),

        const SizedBox(width: 6),

        const Spacer(),

        boosted
            ? Tooltip(
                message: 'Cơ bản $baseValue (buff tập luyện)',
                child: valueText,
              )
            : valueText,

        if (plus != null) ...[const SizedBox(width: 4), plus!],
      ],
    );
  }
}

/// Tiến trình tập luyện: số ngày đã tích lũy trên số ngày cần cho +1 điểm (theo [trainingRates]).
class _TrainingLine extends StatelessWidget {
  const _TrainingLine({
    super.key,
    required this.facility,
    required this.stat,
    required this.percent,
    required this.ratePerDay,
  });
  final String facility;
  final String stat;
  final int percent;

  /// Tiến độ mỗi ngày (phần trăm) của chỉ số này tại công trình ở cấp hiện tại.
  final int ratePerDay;

  @override
  Widget build(BuildContext context) {
    final rate = ratePerDay <= 0 ? 25 : ratePerDay;
    final need = (100 / rate).ceil();
    final days = (percent / rate).floor().clamp(0, need - 1);
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$facility • $stat +1: $days/$need ngày',
              style: _label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 60,
            child: Bar(value: percent / 100, color: Pal.gold, height: 5),
          ),
        ],
      ),
    );
  }
}

class _EquipCell extends StatelessWidget {
  const _EquipCell(
    this.number,
    this.slot,
    this.keyName,
    this.itemId,
    this.tooltip,
    this.cell, {
    required this.soldier,
    required this.controller,
    this.locked = false,
  });

  final double cell;
  final int number;
  final Slot slot;
  final String keyName;
  final String? itemId;
  final String tooltip;
  final Soldier soldier;
  final GameController controller;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final ref = itemId;

    final box = SizedBox(
      width: cell,
      height: cell,
      child: DecoratedBox(
        key: ValueKey('soldier-equip-$keyName'),
        decoration: BoxDecoration(
          border: Border.all(color: Pal.lineStrong, width: 1.5),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  ItemGlyph(ref, size: constraints.biggest.shortestSide),
                  if (locked)
                    const Center(
                      child: Icon(Icons.lock, size: 16, color: Pal.muted),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );

    final interactive = ref == null
        ? GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: locked ? null : () => showEmptySlotInfo(context, slot),
            child: box,
          )
        : DragItem<GearDrag>(
            data: GearDrag(ref, fromSlot: slot, soldierId: soldier.id),
            feedbackSize: Size(cell, cell),
            axis: null,
            onTap: () => showGearDetail(
              context,
              controller,
              soldier,
              ref: ref,
              slot: slot,
            ),
            child: box,
          );

    return SizedBox(
      width: double.infinity,
      height: cell,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 14,
            child: Text(
              '$number',
              textAlign: TextAlign.center,
              style: _label,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Center(
              child: Tooltip(
                message: locked
                    ? '$tooltip: đang cầm vũ khí hai tay'
                    : ref == null
                    ? '$tooltip: trống'
                    : '$tooltip: ${itemDisplayName(ref)}',
                child: ItemDropZone<GearDrag>(
                  key: ValueKey('drop-equip-$keyName'),
                  radius: 5,
                  accepts: (d) =>
                      !locked &&
                      d.fromChest &&
                      slotDropProblem(d.ref, slot) == null,
                  onDrop: (d) => toast(
                    context,
                    controller.equip(soldier.id, d.ref, slot: slot),
                  ),
                  child: interactive,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tóm tắt buff/debuff đang có từ trang bị (dữ liệu thật từ loadout). Chạm để xem danh sách trong popup.
class _GearEffects extends StatelessWidget {
  const _GearEffects({required this.soldier});
  final Soldier soldier;

  @override
  Widget build(BuildContext context) {
    final effects = EquipmentLoadout.of(soldier).effects;
    final buffs = effects.where((e) => e.isBuff).length;
    final debuffs = effects.where((e) => e.isDebuff).length;
    return Tooltip(
      message: effects.isEmpty
          ? 'Trang bị chưa có buff/debuff'
          : effects.map((e) => e.describe()).join('\n'),
      child: InkWell(
        onTap: () =>
            showItemDetail(context, info: _GearEffectsList(soldier: soldier)),
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 44,
          height: 42,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '+$buffs',
                key: const ValueKey('soldier-buff-count'),
                style: TextStyle(
                  color: buffs > 0 ? Pal.moss : Pal.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '−$debuffs',
                key: const ValueKey('soldier-debuff-count'),
                style: TextStyle(
                  color: debuffs > 0 ? Pal.blood : Pal.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Danh sách buff/debuff đang có từ trang bị (nội dung popup của [_GearEffects]).
class _GearEffectsList extends StatelessWidget {
  const _GearEffectsList({required this.soldier});
  final Soldier soldier;

  @override
  Widget build(BuildContext context) {
    final effects = EquipmentLoadout.of(soldier).effects;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Buff / Debuff từ trang bị',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
        ),
        const SizedBox(height: 6),
        if (effects.isEmpty) const Text('Trang bị chưa có buff/debuff.'),
        for (final e in effects) EffectLine(e),
      ],
    );
  }
}
