import 'package:flutter/material.dart';

import '../../application/game_controller.dart';
import '../../core/theme.dart';
import '../../domain/battle.dart';
import '../../domain/catalog.dart';
import '../../domain/models.dart';
import '../../domain/rules.dart';
import '../../domain/stats.dart';
import '../widgets/art.dart';
import '../widgets/common.dart';
import 'battle_screen.dart';

const _factionNames = [
  'Bầy Chó Bùn',
  'Huynh Đệ Hội',
  'Áo Choàng Rách',
  'Quạ Mệt Mỏi',
  'Dao Găm Xám',
];

/// Triển khai trước trận (VERIFIED theo ảnh/clip chính thức): kéo biểu tượng binh sĩ vào vùng triển khai
/// bên trái, 4 đội hình mẫu, `Fight!`. Nút lệnh từng đơn vị chưa làm vì chưa đủ bằng chứng về nội dung lệnh.
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

  Size _fieldSize = Size.zero;

  double get _scale => _fieldSize.width / fieldW;

  Pos _toField(Offset global) {
    final box = _fieldKey.currentContext!.findRenderObject()! as RenderBox;
    final local = box.globalToLocal(global);
    return clampToDeployZone(local.dx / _scale, local.dy / _scale);
  }

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final s = c.state!;
    final loc = locationById(widget.locationId)!;
    final squad = [
      for (final id in widget.squadIds)
        if (s.soldier(id) != null) s.soldier(id)!,
    ];
    final enemies = GameRules.previewEnemies(loc.enemies);
    final epos = enemyPlacement(enemies);
    final faction = _factionNames[loc.id.hashCode.abs() % _factionNames.length];
    final all = _placed.length == squad.length;

    Widget card(Soldier so) {
      final placed = _placed.containsKey(so.id);
      final w = deriveStats(so);
      final content = Container(
        width: 60,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: placed ? Pal.panelHi : const Color(0xFFF3DDB0),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: placed ? Pal.line : Pal.ink, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: placed ? 0.4 : 1,
              child: SoldierSprite.of(so, size: 34),
            ),
            Icon(
              w.ranged ? Icons.gps_fixed : Icons.shield,
              size: 12,
              color: placed ? Pal.dim : Pal.ink,
            ),
            Text(
              so.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                color: placed ? Pal.dim : Pal.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
      return Draggable<int>(
        data: so.id,
        feedback: Material(
          color: Colors.transparent,
          child: Opacity(
            opacity: 0.9,
            child: SoldierSprite.of(so, bust: false, size: 44),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: content),
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF8A7447),
      body: SafeArea(
        child: Column(
          children: [
            // Tiêu đề hai bên.
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              color: Pal.panel,
              child: Row(
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, size: 20),
                  ),
                  const Text(
                    'Rising Army',
                    style: TextStyle(
                      color: Pal.gold,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.shield, size: 18, color: Pal.steel),
                  ),
                  Flexible(
                    child: Text(
                      faction,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Pal.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '${loc.name} • ${enemies.length} địch',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Pal.dim, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) {
                  final scale = (box.maxWidth / fieldW).clamp(
                    0.0,
                    box.maxHeight / fieldH,
                  );
                  _fieldSize = Size(fieldW * scale, fieldH * scale);
                  final spr = (scale * 2.4).clamp(22.0, 44.0);
                  return Center(
                    child: DragTarget<int>(
                      onAcceptWithDetails: (d) {
                        // Vị trí thả: tâm của bóng kéo ≈ offset + nửa kích thước.
                        final p = _toField(d.offset + const Offset(22, 40));
                        setState(() => _placed[d.data] = p);
                      },
                      builder: (context, cand, _) => SizedBox(
                        key: _fieldKey,
                        width: _fieldSize.width,
                        height: _fieldSize.height,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: CustomPaint(painter: FieldPainter()),
                            ),
                            // Vùng triển khai.
                            Positioned(
                              left: deployMinX * scale,
                              top: deployMinY * scale,
                              width: (deployMaxX - deployMinX) * scale,
                              height: (deployMaxY - deployMinY) * scale,
                              child: IgnorePointer(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color:
                                        (cand.isNotEmpty
                                                ? Pal.gold
                                                : Colors.white)
                                            .withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                      width: 2,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${_placed.length}/${squad.length}',
                                    style: TextStyle(
                                      fontSize: scale * 5,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white.withValues(
                                        alpha: 0.55,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Địch (xem trước).
                            for (final e in enemies)
                              Positioned(
                                left: (epos[e.id]!.x) * scale - spr / 2,
                                top: (epos[e.id]!.y) * scale - spr / 2,
                                child: SoldierSprite.of(
                                  e,
                                  bust: false,
                                  size: spr,
                                  enemy: true,
                                ),
                              ),
                            // Quân ta đã đặt: kéo để dời.
                            for (final so in squad)
                              if (_placed.containsKey(so.id))
                                Positioned(
                                  left: _placed[so.id]!.x * scale - spr / 2,
                                  top: _placed[so.id]!.y * scale - spr / 2,
                                  child: GestureDetector(
                                    onPanUpdate: (u) => setState(() {
                                      final p = _placed[so.id]!;
                                      _placed[so.id] = clampToDeployZone(
                                        p.x + u.delta.dx / scale,
                                        p.y + u.delta.dy / scale,
                                      );
                                    }),
                                    onDoubleTap: () =>
                                        setState(() => _placed.remove(so.id)),
                                    child: Semantics(
                                      label: 'Quân ta ${so.name}',
                                      child: SoldierSprite.of(
                                        so,
                                        bust: false,
                                        size: spr,
                                      ),
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Thanh dưới: thẻ binh sĩ, đội hình mẫu, nút.
            Container(
              color: Pal.panel.withValues(alpha: 0.96),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final so in squad)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: card(so),
                      ),
                    const SizedBox(width: 10),
                    for (final p in FormationPreset.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Tooltip(
                          message: formationNames[p]!,
                          child: InkWell(
                            onTap: () => setState(() {
                              _placed
                                ..clear()
                                ..addAll(presetPlacement(p, squad));
                            }),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3DDB0),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Pal.ink, width: 2),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.casino, size: 18, color: Pal.ink),
                                  Text(
                                    '${p.index + 3}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Pal.ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 130,
                      child: GameButton(
                        label: 'Deploy Units',
                        dense: true,
                        onPressed: () => setState(() {
                          _placed
                            ..clear()
                            ..addAll(
                              presetPlacement(FormationPreset.line, squad),
                            );
                        }),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 150,
                      child: GameButton(
                        label: 'ASSIGN_ORDERS',
                        dense: true,
                        onPressed: null,
                        lockedReason:
                            'Chưa làm: chưa đủ bằng chứng về nội dung lệnh',
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 110,
                      child: GameButton(
                        label: 'Fight!',
                        dense: true,
                        icon: Icons.sports_martial_arts,
                        lockedReason: all
                            ? null
                            : 'Triển khai đủ ${squad.length}/${squad.length} binh sĩ',
                        onPressed: () => _fight(context, c, squad),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _fight(BuildContext context, GameController c, List<Soldier> squad) {
    final ExpeditionResult r = c.sendExpedition(
      widget.locationId,
      [for (final x in squad) x.id],
      const <int>{},
      placement: Map<int, Pos>.of(_placed),
    );
    if (!r.result.ok) {
      toast(context, r.result);
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => BattleScreen(result: r)),
      (route) => route.isFirst,
    );
  }
}
