import 'dart:math';

import 'package:flutter/material.dart';

import '../../application/game_controller.dart';
import '../../core/theme.dart';
import '../../domain/catalog.dart';
import '../../domain/models.dart';
import '../../domain/rules.dart';
import '../../domain/stats.dart';
import '../widgets/art.dart';
import '../widgets/common.dart';
import 'shell.dart';

/// Trại: cảnh nhìn từ trên xuống, binh sĩ đi lại, kéo-thả binh sĩ vào công trình có sức chứa 3,
/// nút `build` / `end-day` / `map` ở dưới (VERIFIED theo ảnh/clip chính thức).
class CampHub extends StatefulWidget {
  const CampHub({super.key});

  @override
  State<CampHub> createState() => _CampHubState();
}

class _CampHubState extends State<CampHub> {
  FacilityType? _placing;

  static const _facW = 150.0, _facH = 104.0;
  static const _spriteSize = 34.0;

  /// Vị trí nghỉ của binh sĩ không được gán: xác định theo (id, ngày) nên đổi mỗi ngày, di chuyển mượt bằng AnimatedPositioned.
  Offset _idleSpot(int id, int day, Size size) {
    final r = Random(id * 7919 + day * 104729);
    return Offset(
      size.width * (0.1 + r.nextDouble() * 0.8),
      size.height * (0.62 + r.nextDouble() * 0.28),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final s = c.state!;
    final d = Dims(context);
    return Padding(
      padding: EdgeInsets.all(d.pad),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LayoutBuilder(
          builder: (context, box) {
            final size = Size(box.maxWidth, box.maxHeight);
            final scale = (size.height / 340).clamp(0.62, 1.2);
            final fw = _facW * scale, fh = _facH * scale;
            final spr = _spriteSize * scale.clamp(0.8, 1.1);
            final assignedIds = {for (final f in s.facilities) ...f.assigned};
            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: CampGroundPainter()),
                ),
                for (final f in s.facilities)
                  Positioned(
                    left: f.x * size.width - fw / 2,
                    top: f.y * size.height - fh / 2,
                    width: fw,
                    height: fh,
                    child: _FacilityView(facility: f, state: s, controller: c),
                  ),
                // Binh sĩ trong công trình: đứng quanh công trình.
                for (final f in s.facilities)
                  for (var i = 0; i < f.assigned.length; i++)
                    if (s.soldier(f.assigned[i]) != null)
                      Positioned(
                        left:
                            f.x * size.width -
                            fw / 2 +
                            fw * (0.2 + 0.3 * i) -
                            spr / 2,
                        top: f.y * size.height + fh * 0.18,
                        child: _SoldierToken(
                          soldier: s.soldier(f.assigned[i])!,
                          size: spr,
                          controller: c,
                        ),
                      ),
                // Binh sĩ nhàn rỗi đi lại trong trại.
                for (final so in s.roster)
                  if (!assignedIds.contains(so.id))
                    AnimatedPositioned(
                      key: ValueKey('idle-${so.id}'),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeInOut,
                      left: _idleSpot(so.id, s.day, size).dx - spr / 2,
                      top: _idleSpot(so.id, s.day, size).dy - spr / 2,
                      child: _SoldierToken(
                        soldier: so,
                        size: spr,
                        controller: c,
                      ),
                    ),
                // Ô đặt công trình khi đang ở chế độ Build.
                if (_placing != null)
                  for (final i in GameRules.freeSlotIndices(s))
                    Positioned(
                      left: GameRules.facilitySlots[i].$1 * size.width - fw / 2,
                      top: GameRules.facilitySlots[i].$2 * size.height - fh / 2,
                      width: fw,
                      height: fh,
                      child: GestureDetector(
                        onTap: () {
                          toast(context, c.buildFacility(_placing!, i));
                          setState(() => _placing = null);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Pal.gold.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Pal.gold, width: 2),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Đặt ${facilityDefs[_placing!]!.name}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Pal.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                // HUD của trại: số quân, kho đồ.
                Positioned(
                  left: 8,
                  top: 8,
                  child: _Badge(
                    icon: Icons.groups,
                    text: '${s.roster.length}/${GameRules.rosterCap(s)}',
                    tip: 'Số binh sĩ / sức chứa',
                  ),
                ),
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: _Badge(
                    icon: Icons.inventory_2,
                    text:
                        '${GameRules.inventoryCount(s)}/${GameRules.inventoryCapacity(s)}',
                    tip: 'Kho đồ (stash)',
                  ),
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: _Badge(
                    icon: Icons.menu_book,
                    text:
                        '${GameRules.byStatus(s, MissionStatus.active).length}',
                    tip: 'Nhật ký (journal): nhiệm vụ đang làm',
                    onTap: () => ShellNav.of(context).go(Sections.missions),
                  ),
                ),
                // Thanh dưới: build / end-day / map.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 6,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3DDB0),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Pal.ink, width: 2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _BarButton(
                            icon: Icons.hardware,
                            label: _placing == null ? 'build' : 'hủy',
                            onTap: () => _placing == null
                                ? _openBuild(context, s)
                                : setState(() => _placing = null),
                          ),
                          const SizedBox(width: 6),
                          _BarButton(
                            icon: Icons.nightlight_round,
                            label: 'end-day',
                            primary: true,
                            onTap: () {
                              final r = c.endDay();
                              showSnack(
                                context,
                                [
                                  'Bổng lộc nhà vua: ${GameRules.describeCost(r.stipend)}',
                                  'Trả công: ${r.upkeep} thức ăn + ${r.upkeep} đồng xu',
                                  ...r.lines,
                                ].join('\n'),
                                color: r.paid
                                    ? Pal.panelHi
                                    : const Color(0xFF4A2019),
                                duration: const Duration(seconds: 5),
                              );
                            },
                          ),
                          const SizedBox(width: 6),
                          _BarButton(
                            icon: Icons.map,
                            label: 'map',
                            onTap: () => ShellNav.of(context).go(Sections.map),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_placing != null)
                  Positioned(
                    top: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Pal.bg.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Pal.gold),
                        ),
                        child: Text(
                          'Chạm một ô vàng để đặt ${facilityDefs[_placing!]!.name}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openBuild(BuildContext context, GameState s) async {
    final choice = await showDialog<FacilityType>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Xây công trình (${s.facilities.length}/$maxFacilities)',
                        style: Theme.of(ctx).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (final t in buildableFacilities)
                          Builder(
                            builder: (context) {
                              final def = facilityDefs[t]!;
                              final can =
                                  GameRules.canAfford(s, def.cost) &&
                                  s.facilities.length < maxFacilities &&
                                  GameRules.freeSlotIndices(s).isNotEmpty;
                              return ListTile(
                                dense: true,
                                leading: SizedBox(
                                  width: 64,
                                  height: 44,
                                  child: CustomPaint(
                                    painter: FacilityPainter(t),
                                  ),
                                ),
                                title: Text(
                                  def.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: Text(
                                  def.blurb,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Pal.dim,
                                  ),
                                ),
                                trailing: SizedBox(
                                  width: 120,
                                  child: CostText(def.cost, state: s),
                                ),
                                enabled: can,
                                onTap: can ? () => Navigator.pop(ctx, t) : null,
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (choice != null && mounted) setState(() => _placing = choice);
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.text,
    required this.tip,
    this.onTap,
  });

  final IconData icon;
  final String text, tip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tip,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF3DDB0),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Pal.ink, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: Pal.ink),
            const SizedBox(width: 4),
            Text(
              text,
              style: const TextStyle(
                color: Pal.ink,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        constraints: const BoxConstraints(minHeight: 40, minWidth: 80),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: primary ? Pal.gold : const Color(0xFFE9C985),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Pal.ink, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Pal.ink),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Pal.ink,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _FacilityView extends StatelessWidget {
  const _FacilityView({
    required this.facility,
    required this.state,
    required this.controller,
  });

  final Facility facility;
  final GameState state;
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final def = facilityDefs[facility.type]!;
    final takes = GameRules.takesAssignment(facility.type);
    return DragTarget<int>(
      onWillAcceptWithDetails: (_) => takes,
      onAcceptWithDetails: (d) =>
          toast(context, controller.assignToFacility(d.data, facility.id)),
      builder: (context, candidates, _) {
        final hot = candidates.isNotEmpty;
        return Tooltip(
          message: '${def.name}\n${def.blurb}',
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: FacilityPainter(facility.type)),
              ),
              if (hot)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: Pal.gold, width: 3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Pal.bg.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      takes
                          ? '${def.name}  ${facility.assigned.length}/${Facility.capacity}'
                          : def.name,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Pal.text,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SoldierToken extends StatelessWidget {
  const _SoldierToken({
    required this.soldier,
    required this.size,
    required this.controller,
  });

  final Soldier soldier;
  final double size;
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final wounded = soldier.wounded;
    final sprite = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SoldierSprite.of(soldier, bust: false, size: size),
        SizedBox(
          width: size * 0.9,
          child: Bar(
            value: soldier.hpFraction,
            color: wounded ? Pal.blood : Pal.moss,
            height: 3,
          ),
        ),
      ],
    );
    return Draggable<int>(
      data: soldier.id,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.85,
          child: SoldierSprite.of(soldier, bust: false, size: size * 1.3),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: sprite),
      child: Tooltip(
        message:
            '${soldier.name} • ${roleNames[soldier.role]} cấp ${soldier.level}\nHP ${soldier.hp}/${soldier.maxHp}',
        child: GestureDetector(
          onTap: () => _card(context),
          child: Semantics(
            label: 'Binh sĩ ${soldier.name}',
            button: true,
            child: sprite,
          ),
        ),
      ),
    );
  }

  void _card(BuildContext context) {
    final d = deriveStats(soldier);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(soldier.name),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${roleNames[soldier.role]} • Cấp ${soldier.level} • Kinh nghiệm ${soldier.xp}/${xpForNext(soldier.level)}',
              ),
              const SizedBox(height: 6),
              Text('HP ${soldier.hp}/${d.maxHp} • Tinh thần ${soldier.morale}'),
              Text(
                'Sức mạnh ${d.stats[Stat.str]} • Khéo léo ${d.stats[Stat.dex]} • Thể trạng ${d.stats[Stat.con]}',
              ),
              Text(
                'Tốc độ ${d.speed.toStringAsFixed(1)} m/s • Chu kỳ đánh ${d.interval.toStringAsFixed(1)} s • Chính xác ${(d.accuracy * 100).round()}%',
              ),
              const SizedBox(height: 6),
              const Text(
                'Kéo binh sĩ thả lên công trình để huấn luyện hoặc chữa trị.',
                style: TextStyle(color: Pal.dim, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ShellNav.of(context).go(Sections.roster);
            },
            child: const Text('Chi tiết'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
