import 'package:flutter/material.dart';

import '../../application/game_controller.dart';
import '../../core/theme.dart';
import '../../domain/battle.dart';
import '../../domain/models.dart';
import '../../domain/rules.dart';
import '../../domain/stats.dart';
import '../widgets/art.dart';
import '../widgets/battle/battle_widgets.dart';
import '../widgets/common.dart';
import 'battle_screen.dart';

const _factionNames = [
  'Bầy Chó Bùn',
  'Huynh Đệ Hội',
  'Áo Choàng Rách',
  'Quạ Mệt Mỏi',
  'Dao Găm Xám',
];

/// Triển khai trước trận (VERIFIED theo ảnh/clip chính thức): đặt binh sĩ vào vùng triển khai bên trái,
/// 4 đội hình mẫu, `Fight!`. Nút lệnh từng đơn vị chưa làm vì chưa đủ bằng chứng về nội dung lệnh
/// (nên không hiển thị nút giả).
///
/// Bố cục: thanh tiêu đề (trận + so sánh lực lượng) / thân (chiến trường + danh sách quân: cột bên trái ở màn
/// rộng, dải ngang bên dưới ở màn hẹp) / thanh hành động cố định. Mọi vùng cuộn nằm trong phần danh sách quân
/// hoặc dải đội hình, nên nút `Fight!` luôn nằm trong tầm nhìn.
///
/// Đặt quân: chạm thẻ để chọn rồi chạm vùng triển khai, hoặc nhấn giữ thẻ để kéo thả. Quân đã đặt kéo để dời,
/// bấm đúp hoặc nút "Rút" để thu hồi.
class DeployScreen extends StatefulWidget {
  const DeployScreen({
    super.key,
    required this.locationId,
    required this.squadIds,
  });

  final String locationId;
  final List<int> squadIds;

  @override
  State<DeployScreen> createState() => _DeployScreenState();
}

class _DeployScreenState extends State<DeployScreen> {
  final Map<int, Pos> _placed = {};
  final _fieldKey = GlobalKey();
  int? _selected;
  bool _fighting = false;

  /// Đội hình mẫu vừa áp dụng (chỉ để tô sáng nút; xóa khi người chơi tự chỉnh). Không phải dữ liệu gameplay.
  FormationPreset? _preset;

  Pos _toField(Offset global, double scale) {
    final box = _fieldKey.currentContext!.findRenderObject()! as RenderBox;
    final local = box.globalToLocal(global);
    return clampToDeployZone(local.dx / scale, local.dy / scale);
  }

  /// Câu hướng dẫn bước kế tiếp, suy ra từ state thật (đã chọn ai, đã đặt đủ chưa).
  String _hint(List<Soldier> squad, Soldier? sel) {
    if (squad.isEmpty) return 'Chưa có binh sĩ để triển khai';
    if (_placed.length == squad.length) {
      return 'Sẵn sàng! Kéo để chỉnh vị trí, hoặc bấm Fight!';
    }
    if (sel != null && !_placed.containsKey(sel.id)) {
      return 'Chạm vùng xanh để đặt ${sel.name}';
    }
    return 'Chọn một binh sĩ rồi chạm vùng xanh, hoặc dùng đội hình mẫu';
  }

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final s = c.state!;
    final loc = GameRules.locationFor(s, widget.locationId)!;
    final squad = [
      for (final id in widget.squadIds)
        if (s.soldier(id) != null) s.soldier(id)!,
    ];
    final enemies = GameRules.previewEnemies(loc.enemies);
    final epos = enemyPlacement(enemies);
    final faction = _factionNames[loc.id.hashCode.abs() % _factionNames.length];
    final all = squad.isNotEmpty && _placed.length == squad.length;
    final sel = _selected == null ? null : s.soldier(_selected!);

    final allyHp = squad.fold(0, (a, b) => a + startHpOf(b));
    final foeHp = enemies.fold(0, (a, b) => a + startHpOf(b));

    return Scaffold(
      backgroundColor: const Color(0xFF8A7447),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            final wide = box.maxWidth >= 640;
            final field = _buildField(squad, enemies, epos, _hint(squad, sel));
            final list = _SquadList(
              squad: squad,
              placed: _placed,
              selected: _selected,
              horizontal: !wide,
              onSelect: (id) => setState(() => _selected = id),
            );
            return Column(
              children: [
                _Header(
                  title: loc.name,
                  faction: faction,
                  ally: squad.length,
                  allyHp: allyHp,
                  foe: enemies.length,
                  foeHp: foeHp,
                  placed: _placed.length,
                  onBack: () => Navigator.pop(context),
                ),
                Expanded(
                  child: wide
                      ? Row(
                          children: [
                            SizedBox(
                              width: (box.maxWidth * 0.28).clamp(210.0, 280.0),
                              child: _Rail(
                                list: list,
                                selected: sel,
                                placed:
                                    sel != null && _placed.containsKey(sel.id),
                                onRecall: _recallSelected,
                              ),
                            ),
                            Expanded(child: field),
                          ],
                        )
                      : Column(
                          children: [
                            Expanded(child: field),
                            if (sel != null)
                              _NarrowInfo(
                                soldier: sel,
                                placed: _placed.containsKey(sel.id),
                                onRecall: _recallSelected,
                              ),
                            SizedBox(height: 78, child: list),
                          ],
                        ),
                ),
                _ActionBar(
                  canFight: all && !_fighting,
                  lockedReason: _fighting
                      ? 'Đang xuất trận…'
                      : (all
                            ? null
                            : 'Triển khai đủ ${_placed.length}/${squad.length} binh sĩ'),
                  placed: _placed.length,
                  total: squad.length,
                  activePreset: _preset,
                  onPreset: (p) => setState(() {
                    _preset = p;
                    _placed
                      ..clear()
                      ..addAll(presetPlacement(p, squad));
                  }),
                  onAuto: () => setState(() {
                    _preset = FormationPreset.line;
                    _placed
                      ..clear()
                      ..addAll(presetPlacement(FormationPreset.line, squad));
                  }),
                  onClear: _placed.isEmpty
                      ? null
                      : () => setState(() {
                          _preset = null;
                          _placed.clear();
                          _selected = null;
                        }),
                  onFight: () => _fight(context, c, squad),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _recallSelected() {
    final id = _selected;
    if (id == null) return;
    setState(() {
      _preset = null;
      _placed.remove(id);
    });
  }

  Widget _buildField(
    List<Soldier> squad,
    List<Soldier> enemies,
    Map<int, Pos> epos,
    String hint,
  ) {
    return LayoutBuilder(
      builder: (context, box) {
        final scale = (box.maxWidth / fieldW).clamp(
          0.0,
          box.maxHeight / fieldH,
        );
        final size = Size(fieldW * scale, fieldH * scale);
        final spr = (scale * 2.4).clamp(22.0, 44.0);
        return Center(
          child: DragTarget<int>(
            onAcceptWithDetails: (d) {
              // Kéo bằng pointerDragAnchorStrategy: offset chính là vị trí ngón tay.
              final p = _toField(d.offset, scale);
              setState(() {
                _preset = null;
                _placed[d.data] = p;
                _selected = d.data;
              });
            },
            builder: (context, cand, _) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) {
                final id = _selected;
                if (id == null) return;
                final p = clampToDeployZone(
                  d.localPosition.dx / scale,
                  d.localPosition.dy / scale,
                );
                setState(() {
                  _preset = null;
                  _placed[id] = p;
                });
              },
              child: SizedBox(
                key: _fieldKey,
                width: size.width,
                height: size.height,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: FieldPainter()),
                    ),
                    Positioned(
                      left: deployMinX * scale,
                      top: deployMinY * scale,
                      width: (deployMaxX - deployMinX) * scale,
                      height: (deployMaxY - deployMinY) * scale,
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            color: (cand.isNotEmpty ? Pal.gold : Colors.white)
                                .withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: cand.isNotEmpty
                                  ? Pal.goldLight
                                  : Colors.white.withValues(alpha: 0.7),
                              width: cand.isNotEmpty ? 4 : 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 8,
                                top: 4,
                                child: Text(
                                  'VÙNG TRIỂN KHAI',
                                  style: TextStyle(
                                    fontSize: (scale * 1.3).clamp(8.0, 11.0),
                                    letterSpacing: 1,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white.withValues(alpha: 0.75),
                                  ),
                                ),
                              ),
                              Center(
                                child: Text(
                                  '${_placed.length}/${squad.length}',
                                  key: const ValueKey('deploy-field-count'),
                                  style: TextStyle(
                                    fontSize: scale * 5,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white.withValues(alpha: 0.4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    for (final e in enemies)
                      Positioned(
                        left: epos[e.id]!.x * scale - spr / 2,
                        top: epos[e.id]!.y * scale - spr / 2,
                        child: IgnorePointer(
                          child: SoldierSprite.of(
                            e,
                            bust: false,
                            size: spr,
                            enemy: true,
                          ),
                        ),
                      ),
                    for (final so in squad)
                      if (_placed.containsKey(so.id))
                        Positioned(
                          left: _placed[so.id]!.x * scale - spr / 2,
                          top: _placed[so.id]!.y * scale - spr / 2,
                          child: GestureDetector(
                            onTap: () => setState(() => _selected = so.id),
                            onPanStart: (_) =>
                                setState(() => _selected = so.id),
                            onPanUpdate: (u) => setState(() {
                              _preset = null;
                              final p = _placed[so.id]!;
                              _placed[so.id] = clampToDeployZone(
                                p.x + u.delta.dx / scale,
                                p.y + u.delta.dy / scale,
                              );
                            }),
                            onDoubleTap: () => setState(() {
                              _preset = null;
                              _placed.remove(so.id);
                            }),
                            child: Semantics(
                              label: 'Quân ta ${so.name}',
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: _selected == so.id
                                          ? [
                                              BoxShadow(
                                                color: Pal.goldLight.withValues(
                                                  alpha: 0.7,
                                                ),
                                                blurRadius: 8,
                                              ),
                                            ]
                                          : null,
                                      border: _selected == so.id
                                          ? Border.all(
                                              color: Pal.goldLight,
                                              width: 2.5,
                                            )
                                          : null,
                                    ),
                                    child: SoldierSprite.of(
                                      so,
                                      bust: false,
                                      size: spr,
                                    ),
                                  ),
                                  // Tên chỉ hiện cho người đang chọn: đủ nhận diện mà không rối khi đông quân.
                                  if (_selected == so.id)
                                    Positioned(
                                      left: -24,
                                      right: -24,
                                      top: spr + 1,
                                      child: IgnorePointer(
                                        child: Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(
                                                alpha: 0.6,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              so.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 4,
                      child: IgnorePointer(
                        child: Center(
                          child: Container(
                            key: const ValueKey('deploy-hint'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              hint,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: (scale * 1.5).clamp(10.0, 13.0),
                                fontWeight: FontWeight.w800,
                                color: _placed.length == squad.length
                                    ? Pal.goldLight
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _fight(BuildContext context, GameController c, List<Soldier> squad) {
    if (_fighting) return;
    _fighting = true;
    final ExpeditionResult r = c.sendExpedition(
      widget.locationId,
      [for (final x in squad) x.id],
      const <int>{},
      placement: Map<int, Pos>.of(_placed),
    );
    if (!r.result.ok) {
      setState(() => _fighting = false);
      toast(context, r.result);
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => BattleScreen(result: r)),
      (route) => route.isFirst,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.faction,
    required this.ally,
    required this.allyHp,
    required this.foe,
    required this.foeHp,
    required this.placed,
    required this.onBack,
  });

  final String title, faction;
  final int ally, allyHp, foe, foeHp, placed;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final ready = ally > 0 && placed == ally;
    final badge = Container(
      key: const ValueKey('deploy-placed-badge'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (ready ? Pal.moss : Pal.panelHi).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ready ? Pal.moss : Pal.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ready ? Icons.check_circle : Icons.groups,
            size: 14,
            color: Pal.text,
          ),
          const SizedBox(width: 4),
          Text(
            '$placed/$ally ra trận',
            maxLines: 1,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Pal.text,
            ),
          ),
        ],
      ),
    );
    final forces = [
      _Force(
        key: const ValueKey('deploy-ally-force'),
        label: 'Quân ta',
        count: ally,
        hp: allyHp,
        color: Pal.moss,
      ),
      _Force(
        key: const ValueKey('deploy-foe-force'),
        label: 'Địch',
        count: foe,
        hp: foeHp,
        color: Pal.blood,
      ),
    ];
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Triển khai • $title',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Pal.gold,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
        Text(
          'Đối thủ: $faction',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Pal.dim, fontSize: 11),
        ),
      ],
    );
    final back = IconButton(
      tooltip: 'Quay lại',
      visualDensity: VisualDensity.compact,
      onPressed: onBack,
      icon: const Icon(Icons.arrow_back, size: 20),
    );
    return Container(
      color: Pal.panel,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: LayoutBuilder(
        builder: (context, box) {
          // Màn hẹp: lực lượng hai phe xuống hàng riêng thay vì ép chung một hàng.
          if (box.maxWidth < 520) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    back,
                    Expanded(child: titleBlock),
                    badge,
                    const SizedBox(width: 8),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 2),
                  child: Row(
                    children: [
                      Expanded(child: forces[0]),
                      const SizedBox(width: 8),
                      Expanded(child: forces[1]),
                    ],
                  ),
                ),
              ],
            );
          }
          return Row(
            children: [
              back,
              Expanded(child: titleBlock),
              badge,
              const SizedBox(width: 10),
              forces[0],
              const SizedBox(width: 12),
              forces[1],
              const SizedBox(width: 8),
            ],
          );
        },
      ),
    );
  }
}

class _Force extends StatelessWidget {
  const _Force({
    super.key,
    required this.label,
    required this.count,
    required this.hp,
    required this.color,
  });
  final String label;
  final int count, hp;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label,
        maxLines: 1,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
      Text(
        '$count quân • $hp HP',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Pal.text, fontSize: 11),
      ),
    ],
  );
}

/// Cột bên trái ở màn rộng: danh sách quân (cuộn) + thông tin binh sĩ đang chọn.
class _Rail extends StatelessWidget {
  const _Rail({
    required this.list,
    required this.selected,
    required this.placed,
    required this.onRecall,
  });

  final Widget list;
  final Soldier? selected;
  final bool placed;
  final VoidCallback onRecall;

  @override
  Widget build(BuildContext context) => Container(
    color: Pal.panel.withValues(alpha: 0.96),
    child: Column(
      children: [
        Expanded(child: list),
        if (selected != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Pal.line)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SoldierStatLine(soldier: selected!),
                if (placed)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: onRecall,
                      icon: const Icon(Icons.undo, size: 16),
                      label: const Text('Rút'),
                    ),
                  ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _NarrowInfo extends StatelessWidget {
  const _NarrowInfo({
    required this.soldier,
    required this.placed,
    required this.onRecall,
  });
  final Soldier soldier;
  final bool placed;
  final VoidCallback onRecall;

  @override
  Widget build(BuildContext context) => Container(
    color: Pal.panel,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: Row(
      children: [
        Expanded(child: SoldierStatLine(soldier: soldier)),
        if (placed)
          IconButton(
            tooltip: 'Rút khỏi vùng triển khai',
            onPressed: onRecall,
            icon: const Icon(Icons.undo),
          ),
      ],
    ),
  );
}

class _SquadList extends StatelessWidget {
  const _SquadList({
    required this.squad,
    required this.placed,
    required this.selected,
    required this.horizontal,
    required this.onSelect,
  });

  final List<Soldier> squad;
  final Map<int, Pos> placed;
  final int? selected;
  final bool horizontal;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    if (squad.isEmpty) {
      return const Center(
        child: Text('Chưa có binh sĩ nào.', style: TextStyle(color: Pal.dim)),
      );
    }
    return ListView.separated(
      key: const ValueKey('deploy-squad-list'),
      scrollDirection: horizontal ? Axis.horizontal : Axis.vertical,
      padding: const EdgeInsets.all(6),
      itemCount: squad.length,
      separatorBuilder: (_, _) => const SizedBox(width: 6, height: 6),
      itemBuilder: (_, i) {
        final so = squad[i];
        final tile = _SoldierTile(
          soldier: so,
          placed: placed.containsKey(so.id),
          selected: selected == so.id,
          compact: horizontal,
          onTap: () => onSelect(so.id),
        );
        return LongPressDraggable<int>(
          data: so.id,
          dragAnchorStrategy: pointerDragAnchorStrategy,
          onDragStarted: () => onSelect(so.id),
          feedback: Material(
            color: Colors.transparent,
            child: Transform.translate(
              offset: const Offset(-22, -22),
              child: Opacity(
                opacity: 0.9,
                child: SoldierSprite.of(so, bust: false, size: 44),
              ),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.35, child: tile),
          child: tile,
        );
      },
    );
  }
}

class _SoldierTile extends StatelessWidget {
  const _SoldierTile({
    required this.soldier,
    required this.placed,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final Soldier soldier;
  final bool placed, selected, compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final so = soldier;
    final d = deriveStats(so);
    final hp = startHpOf(so);
    final bg = selected
        ? Pal.panelRaised
        : (placed ? Pal.panelHi : const Color(0xFFF3DDB0));
    final fg = (placed || selected) ? Pal.text : Pal.ink;
    final border = selected ? Pal.goldLight : (placed ? Pal.moss : Pal.ink);
    final sprite = Opacity(
      opacity: placed ? 0.55 : 1,
      child: SoldierSprite.of(so, size: compact ? 34 : 40),
    );
    final bar = Bar(
      value: hp / d.maxHp,
      color: hp < d.maxHp * 0.5 ? Pal.blood : Pal.moss,
      height: 4,
    );
    return Semantics(
      button: true,
      selected: selected,
      label: 'Binh sĩ ${so.name}${placed ? ', đã triển khai' : ''}',
      child: InkWell(
        key: ValueKey('deploy-tile-${so.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: compact ? 92 : null,
          height: compact ? null : 54,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border, width: selected ? 2.5 : 1.5),
          ),
          child: compact
              ? Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          sprite,
                          Text(
                            so.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: fg,
                            ),
                          ),
                          bar,
                        ],
                      ),
                    ),
                    if (placed)
                      const Positioned(
                        right: -2,
                        top: -2,
                        child: Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Pal.moss,
                        ),
                      ),
                  ],
                )
              : Row(
                  children: [
                    sprite,
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            so.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.0,
                              fontWeight: FontWeight.w900,
                              color: fg,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Cấp ${so.level} • ${d.ranged ? 'Tầm xa' : 'Cận chiến'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              height: 1.0,
                              color: placed || selected ? Pal.dim : Pal.ink,
                            ),
                          ),
                          const SizedBox(height: 3),
                          bar,
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          placed
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 16,
                          color: placed ? Pal.moss : Pal.dim,
                        ),
                        Text(
                          placed ? 'Đã đặt' : 'Chưa đặt',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 8,
                            height: 1.0,
                            fontWeight: FontWeight.w800,
                            color: placed ? Pal.moss : Pal.dim,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.canFight,
    required this.lockedReason,
    required this.placed,
    required this.total,
    required this.activePreset,
    required this.onPreset,
    required this.onAuto,
    required this.onClear,
    required this.onFight,
  });

  final bool canFight;
  final String? lockedReason;
  final int placed, total;
  final FormationPreset? activePreset;
  final ValueChanged<FormationPreset> onPreset;
  final VoidCallback onAuto;
  final VoidCallback? onClear;
  final VoidCallback onFight;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Pal.panel,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              key: const ValueKey('deploy-actions-scroll'),
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  GameButton(
                    label: 'Deploy Units',
                    dense: true,
                    icon: Icons.auto_fix_high,
                    onPressed: onAuto,
                  ),
                  const SizedBox(width: 4),
                  for (final p in FormationPreset.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Tooltip(
                        message: formationNames[p]!,
                        child: OutlinedButton(
                          key: ValueKey('formation-${p.name}'),
                          onPressed: () => onPreset(p),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(44, 40),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            foregroundColor: activePreset == p
                                ? const Color(0xFF1A1208)
                                : Pal.text,
                            backgroundColor: activePreset == p
                                ? Pal.gold
                                : null,
                            side: BorderSide(
                              color: activePreset == p
                                  ? Pal.goldLight
                                  : Pal.lineStrong,
                              width: activePreset == p ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            formationNames[p]!,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  IconButton(
                    key: const ValueKey('deploy-clear'),
                    tooltip: 'Thu hồi tất cả',
                    onPressed: onClear,
                    icon: const Icon(Icons.layers_clear),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: canFight
                      ? [
                          BoxShadow(
                            color: Pal.goldLight.withValues(alpha: 0.6),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
                child: GameButton(
                  label: 'Fight!',
                  icon: Icons.sports_martial_arts,
                  lockedReason: canFight
                      ? null
                      : (lockedReason ?? 'Chưa sẵn sàng'),
                  onPressed: onFight,
                ),
              ),
              Text(
                canFight
                    ? 'Sẵn sàng • $placed/$total'
                    : '$placed/$total đã đặt',
                style: TextStyle(
                  color: canFight ? Pal.moss : Pal.dim,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
