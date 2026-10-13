import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../domain/battle.dart';
import '../../domain/rules.dart';
import '../widgets/art.dart';
import '../widgets/battle/battle_widgets.dart';
import '../widgets/common.dart';
import 'result_screen.dart';

/// Phát lại trận thời gian thực từ BattleReport (kết quả đã áp dụng vào state từ trước).
/// Theo game gốc: không tạm dừng, không làm lại; chỉ đổi tốc độ x1/x2/x3.
class BattleScreen extends StatefulWidget {
  const BattleScreen({super.key, required this.result});

  final ExpeditionResult result;

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  late final BattleReport rep = widget.result.battle!;
  late final Map<int, UnitSnap> snaps = {
    for (final u in [...rep.playerUnits, ...rep.enemyUnits]) u.id: u,
  };
  late final Set<int> playerIds = {for (final u in rep.playerUnits) u.id};
  double t = 0;
  int speed = 1;
  Timer? _timer;
  bool showFight = true;
  int? _selectedUnit;
  bool _logOpen = false;
  bool _resultOpened = false;

  bool get done => t >= rep.duration;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (done) {
        _timer?.cancel();
        return;
      }
      setState(() {
        t = min(rep.duration, t + 0.05 * speed);
        if (t > 1.0) showFight = false;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Tìm hai khung kề thời điểm t và nội suy.
  ({BattleFrame a, BattleFrame b, double k}) _bracket() {
    final f = rep.frames;
    var lo = 0, hi = f.length - 1;
    while (hi - lo > 1) {
      final mid = (lo + hi) >> 1;
      if (f[mid].t <= t) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    final a = f[lo], b = f[hi];
    final span = b.t - a.t;
    return (
      a: a,
      b: b,
      k: span <= 0 ? 1.0 : ((t - a.t) / span).clamp(0.0, 1.0),
    );
  }

  void _openResult() {
    if (_resultOpened) return;
    _resultOpened = true;
    _timer?.cancel();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ResultScreen(result: widget.result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final win = rep.winner;
    final banner = win == Winner.player
        ? 'CHIẾN THẮNG'
        : (win == Winner.enemy ? 'THẤT BẠI' : 'HÒA — HẾT GIỜ');
    final br = _bracket();
    final recent = [
      for (final e in rep.events)
        if (e.t <= t && e.t > t - 0.7) e,
    ];
    final log = [
      for (final e in rep.events)
        if (e.t <= t) e,
    ];

    int hpOf(int id) {
      final fa = br.a.units[id]!, fb = br.b.units[id]!;
      return (fa.hp + (fb.hp - fa.hp) * br.k).round();
    }

    ({int hp, int max, int alive, int total}) side(bool player) {
      var hp = 0, max = 0, alive = 0, total = 0;
      for (final u in snaps.values) {
        if (playerIds.contains(u.id) != player) continue;
        final h = hpOf(u.id);
        total++;
        max += u.maxHp;
        if (h > 0) {
          alive++;
          hp += h;
        }
      }
      return (hp: hp, max: max, alive: alive, total: total);
    }

    final ally = side(true), foe = side(false);
    final status = done ? banner : (t < 1.0 ? 'GIAO TRANH' : 'ĐANG DIỄN RA');

    return Scaffold(
      backgroundColor: Pal.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            final wide = box.maxWidth >= 720;
            final logPanel = _LogPanel(log: log, snaps: snaps);
            return Column(
              children: [
                // HUD trên: lực lượng hai phe và trạng thái trận.
                Container(
                  color: Pal.panel,
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: ForceBar(
                          key: const ValueKey('battle-ally-bar'),
                          label: 'Quân ta',
                          hp: ally.hp,
                          maxHp: ally.max,
                          alive: ally.alive,
                          total: ally.total,
                          color: Pal.moss,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              status,
                              key: const ValueKey('battle-status'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                                color: !done
                                    ? Pal.gold
                                    : (win == Winner.player
                                          ? Pal.gold
                                          : Pal.blood),
                              ),
                            ),
                            Text(
                              '${t.toStringAsFixed(0)}s',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Pal.dim,
                              ),
                            ),
                            if (widget.result.ambush)
                              const Text(
                                'Phục kích!',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Pal.blood,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ForceBar(
                          key: const ValueKey('battle-foe-bar'),
                          label: 'Địch',
                          hp: foe.hp,
                          maxHp: foe.max,
                          alive: foe.alive,
                          total: foe.total,
                          color: Pal.blood,
                          rightToLeft: true,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: _buildField(context, br, recent, hpOf),
                            ),
                            if (_logOpen && !wide && !done)
                              Positioned(
                                top: 4,
                                right: 4,
                                bottom: 4,
                                width: 210,
                                child: Material(
                                  color: Pal.panel.withValues(alpha: 0.95),
                                  borderRadius: BorderRadius.circular(8),
                                  child: logPanel,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (wide)
                        Container(
                          width: 220,
                          color: Pal.panel,
                          child: logPanel,
                        ),
                    ],
                  ),
                ),
                // Thanh dưới: đơn vị đang chọn + điều khiển. Màn hẹp tách thành hai hàng.
                Container(
                  color: Pal.panel,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  child: wide
                      ? Row(
                          children: [
                            Expanded(child: _selectedInfo(hpOf)),
                            ..._controls(wide),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: _selectedInfo(hpOf),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: _controls(wide),
                            ),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _controls(bool wide) {
    final VoidCallback? skip = done
        ? null
        : () => setState(() {
            t = rep.duration;
            showFight = false;
          });
    return [
      if (!wide)
        IconButton(
          key: const ValueKey('battle-log-toggle'),
          tooltip: 'Nhật ký chiến đấu',
          isSelected: _logOpen,
          visualDensity: VisualDensity.compact,
          onPressed: () => setState(() => _logOpen = !_logOpen),
          icon: const Icon(Icons.list_alt),
        ),
      for (final v in [1, 2, 3])
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: ChoiceChip(
            label: Text('x$v'),
            selected: speed == v,
            visualDensity: VisualDensity.compact,
            labelPadding: const EdgeInsets.symmetric(horizontal: 2),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onSelected: (_) => setState(() => speed = v),
          ),
        ),
      const SizedBox(width: 6),
      // Màn hẹp: chỉ biểu tượng để cả hàng điều khiển vừa chiều ngang.
      if (wide)
        TextButton.icon(
          key: const ValueKey('battle-skip'),
          onPressed: skip,
          icon: const Icon(Icons.fast_forward, size: 18),
          label: const Text('Bỏ qua'),
        )
      else
        IconButton(
          key: const ValueKey('battle-skip'),
          tooltip: 'Bỏ qua',
          visualDensity: VisualDensity.compact,
          onPressed: skip,
          icon: const Icon(Icons.fast_forward),
        ),
    ];
  }

  Widget _selectedInfo(int Function(int) hpOf) {
    final id = _selectedUnit;
    final u = id == null ? null : snaps[id];
    if (u == null) {
      return const Text(
        'Chạm vào một binh sĩ để xem tình trạng.',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Pal.dim, fontSize: 11),
      );
    }
    final hp = hpOf(u.id).clamp(0, u.maxHp);
    final player = playerIds.contains(u.id);
    return Row(
      key: const ValueKey('battle-selected-info'),
      children: [
        Flexible(
          child: Text(
            '${u.name} • Cấp ${u.level} • ${player ? 'Quân ta' : 'Địch'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: player ? Pal.moss : Pal.blood,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: Bar(
            value: u.maxHp == 0 ? 0 : hp / u.maxHp,
            color: player ? Pal.moss : Pal.blood,
            height: 6,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          hp <= 0 ? 'Gục' : '$hp/${u.maxHp}',
          style: const TextStyle(fontSize: 11, color: Pal.text),
        ),
      ],
    );
  }

  Widget _buildField(
    BuildContext context,
    ({BattleFrame a, BattleFrame b, double k}) br,
    List<BattleEvent> recent,
    int Function(int) hpOf,
  ) {
    final win = rep.winner;
    final banner = win == Winner.player
        ? 'CHIẾN THẮNG'
        : (win == Winner.enemy ? 'THẤT BẠI' : 'HÒA — HẾT GIỜ');
    return LayoutBuilder(
      builder: (context, box) {
        final scale = min(box.maxWidth / fieldW, box.maxHeight / fieldH);
        final fw = fieldW * scale, fh = fieldH * scale;
        final spr = (scale * 2.4).clamp(22.0, 44.0);
        return Center(
          child: SizedBox(
            width: fw,
            height: fh,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(child: CustomPaint(painter: FieldPainter())),
                for (final id in snaps.keys)
                  Builder(
                    builder: (context) {
                      final fa = br.a.units[id]!, fb = br.b.units[id]!;
                      final x = fa.x + (fb.x - fa.x) * br.k,
                          y = fa.y + (fb.y - fa.y) * br.k;
                      final hp = hpOf(id);
                      final u = snaps[id]!;
                      final player = playerIds.contains(id);
                      final dead = hp <= 0;
                      final swinging =
                          fa.attacking != null || fb.attacking != null;
                      return Positioned(
                        left: x * scale - spr / 2,
                        top: y * scale - spr / 2,
                        child: GestureDetector(
                          key: ValueKey('battle-unit-$id'),
                          onTap: () => setState(() => _selectedUnit = id),
                          child: Opacity(
                            opacity: dead ? 0.5 : 1,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Transform.translate(
                                  offset: swinging && !dead
                                      ? Offset(player ? 4 : -4, 0)
                                      : Offset.zero,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: _selectedUnit == id
                                          ? Border.all(
                                              color: Pal.goldLight,
                                              width: 2,
                                            )
                                          : null,
                                    ),
                                    child: SoldierSprite(
                                      role: u.role,
                                      seed: id.abs(),
                                      armorId: u.armorId,
                                      weaponId: u.weaponId,
                                      bust: false,
                                      enemy: !player,
                                      down: dead,
                                      size: spr,
                                    ),
                                  ),
                                ),
                                if (!dead)
                                  SizedBox(
                                    width: spr * 0.8,
                                    child: Bar(
                                      value: hp / u.maxHp,
                                      color: player ? Pal.moss : Pal.blood,
                                      height: 3,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                for (final e in recent)
                  Builder(
                    builder: (context) {
                      final fa = br.a.units[e.target]!;
                      final age = (t - e.t) / 0.7;
                      return Positioned(
                        left: fa.x * scale - 10,
                        top: fa.y * scale - spr - 14 * age,
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: (1 - age).clamp(0.0, 1.0),
                            child: Text(
                              e.hit
                                  ? '${e.crit ? '!' : ''}-${e.damage}'
                                  : 'Miss',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: e.hit ? Colors.white : Pal.steel,
                                shadows: const [Shadow(blurRadius: 3)],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                if (showFight)
                  IgnorePointer(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Pal.moss,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Pal.ink, width: 3),
                        ),
                        child: const Text(
                          'Fight!',
                          style: TextStyle(
                            fontFamily: serif,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (done)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Pal.bg.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Pal.gold, width: 2),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            banner,
                            style: TextStyle(
                              fontFamily: serif,
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              color: win == Winner.player
                                  ? Pal.gold
                                  : Pal.blood,
                            ),
                          ),
                          const SizedBox(height: 6),
                          GameButton(
                            label: 'Xem kết quả',
                            dense: true,
                            icon: Icons.assignment_turned_in,
                            onPressed: _openResult,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LogPanel extends StatelessWidget {
  const _LogPanel({required this.log, required this.snaps});
  final List<BattleEvent> log;
  final Map<int, UnitSnap> snaps;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'NHẬT KÝ CHIẾN ĐẤU',
          style: TextStyle(
            color: Pal.gold,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView.builder(
            reverse: true,
            itemCount: log.length,
            itemBuilder: (_, i) {
              final e = log[log.length - 1 - i];
              final a = snaps[e.actor]!.name, b = snaps[e.target]!.name;
              final text = e.killed
                  ? '$b gục ngã!'
                  : (e.hit
                        ? '$a đánh $b: -${e.damage}${e.crit ? ' (chí mạng)' : ''}'
                        : '$a đánh trượt $b');
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 1.5),
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 11,
                    color: e.killed ? Pal.blood : Pal.text,
                    fontWeight: e.killed ? FontWeight.w800 : FontWeight.w400,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}
