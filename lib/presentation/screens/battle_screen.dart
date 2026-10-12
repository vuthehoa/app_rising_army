import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../domain/battle.dart';
import '../../domain/rules.dart';
import '../widgets/art.dart';
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

  @override
  Widget build(BuildContext context) {
    final d = Dims(context);
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

    int sideHp(bool player) {
      var sum = 0;
      for (final id in snaps.keys) {
        if (playerIds.contains(id) != player) continue;
        final fa = br.a.units[id]!, fb = br.b.units[id]!;
        sum += (fa.hp + (fb.hp - fa.hp) * br.k).round();
      }
      return sum;
    }

    int sideMax(bool player) => [
      for (final u in snaps.values)
        if (playerIds.contains(u.id) == player) u.maxHp,
    ].fold(0, (a, b) => a + b);

    Widget hpBar(
      String label,
      int hp,
      int max,
      Color color, {
      bool right = false,
    }) => Expanded(
      child: Container(
        height: 22,
        decoration: BoxDecoration(
          color: Pal.ink,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: Colors.white70),
        ),
        child: Stack(
          children: [
            FractionallySizedBox(
              alignment: right ? Alignment.centerRight : Alignment.centerLeft,
              widthFactor: max == 0 ? 0 : (hp / max).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
            Center(
              child: Text(
                '$label  $hp',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 3)],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Pal.bg,
      body: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) {
                  final scale = min(
                    box.maxWidth / fieldW,
                    (box.maxHeight - 30) / fieldH,
                  );
                  final fw = fieldW * scale, fh = fieldH * scale;
                  final spr = (scale * 2.4).clamp(22.0, 44.0);
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                        child: Row(
                          children: [
                            hpBar(
                              'Rising Army',
                              sideHp(true),
                              sideMax(true),
                              Pal.moss,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(Icons.shield, color: Pal.gold),
                            ),
                            hpBar(
                              'Địch',
                              sideHp(false),
                              sideMax(false),
                              Pal.blood,
                              right: true,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: SizedBox(
                            width: fw,
                            height: fh,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned.fill(
                                  child: CustomPaint(painter: FieldPainter()),
                                ),
                                for (final id in snaps.keys)
                                  Builder(
                                    builder: (context) {
                                      final fa = br.a.units[id]!,
                                          fb = br.b.units[id]!;
                                      final x = fa.x + (fb.x - fa.x) * br.k,
                                          y = fa.y + (fb.y - fa.y) * br.k;
                                      final hp =
                                          (fa.hp + (fb.hp - fa.hp) * br.k)
                                              .round();
                                      final u = snaps[id]!;
                                      final player = playerIds.contains(id);
                                      final dead = hp <= 0;
                                      final swinging =
                                          br.a.units[id]!.attacking != null ||
                                          br.b.units[id]!.attacking != null;
                                      return Positioned(
                                        left: x * scale - spr / 2,
                                        top: y * scale - spr / 2,
                                        child: Opacity(
                                          opacity: dead ? 0.5 : 1,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Transform.translate(
                                                offset: swinging && !dead
                                                    ? Offset(player ? 4 : -4, 0)
                                                    : Offset.zero,
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
                                              if (!dead)
                                                SizedBox(
                                                  width: spr * 0.8,
                                                  child: Bar(
                                                    value: hp / u.maxHp,
                                                    color: player
                                                        ? Pal.moss
                                                        : Pal.blood,
                                                    height: 3,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                // "Miss" / sát thương nổi.
                                for (final e in recent)
                                  Builder(
                                    builder: (context) {
                                      final fa = br.a.units[e.target]!;
                                      final age = (t - e.t) / 0.7;
                                      return Positioned(
                                        left: fa.x * scale - 10,
                                        top: fa.y * scale - spr - 14 * age,
                                        child: Opacity(
                                          opacity: (1 - age).clamp(0.0, 1.0),
                                          child: Text(
                                            e.hit
                                                ? '${e.crit ? '!' : ''}-${e.damage}'
                                                : 'Miss',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                              color: e.hit
                                                  ? Colors.white
                                                  : Pal.steel,
                                              shadows: const [
                                                Shadow(blurRadius: 3),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                if (showFight)
                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 30,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Pal.moss,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Pal.ink,
                                          width: 3,
                                        ),
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
                                if (done)
                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Pal.bg.withValues(alpha: 0.88),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Pal.gold,
                                          width: 2,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            banner,
                                            style: TextStyle(
                                              fontFamily: serif,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 24,
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
                                            onPressed: () =>
                                                Navigator.of(
                                                  context,
                                                ).pushReplacement(
                                                  MaterialPageRoute<void>(
                                                    builder: (_) =>
                                                        ResultScreen(
                                                          result: widget.result,
                                                        ),
                                                  ),
                                                ),
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
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                        child: Row(
                          children: [
                            Pill(
                              '${t.toStringAsFixed(0)}s',
                              color: Pal.gold,
                              icon: Icons.timer,
                            ),
                            if (widget.result.ambush)
                              const Padding(
                                padding: EdgeInsets.only(left: 6),
                                child: Pill('Phục kích!', color: Pal.blood),
                              ),
                            const Spacer(),
                            for (final v in [1, 2, 3])
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: ChoiceChip(
                                  label: Text('x$v'),
                                  selected: speed == v,
                                  visualDensity: VisualDensity.compact,
                                  onSelected: (_) => setState(() => speed = v),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Container(
              width: d.compact ? 170 : 220,
              color: Pal.panel,
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
                        final a = snaps[e.actor]!.name,
                            b = snaps[e.target]!.name;
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
                              fontWeight: e.killed
                                  ? FontWeight.w800
                                  : FontWeight.w400,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
