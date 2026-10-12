import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../domain/battle.dart';
import '../../domain/models.dart';
import '../../domain/rules.dart';
import '../widgets/art.dart';
import '../widgets/common.dart';
import 'result_screen.dart';

/// Phát lại trận auto-battler từ BattleReport (kết quả đã được áp dụng vào state từ trước).
class BattleScreen extends StatefulWidget {
  const BattleScreen({super.key, required this.result});

  final ExpeditionResult result;

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

enum _U { alive, down, fled }

class _BattleScreenState extends State<BattleScreen> {
  late final BattleReport rep = widget.result.battle!;
  final Map<int, int> hp = {};
  final Map<int, _U> st = {};
  final Map<int, String> names = {};
  final List<String> log = [];
  int idx = 0;
  int round = 0;
  int speed = 1;
  bool playing = true;
  int? actor;
  int? target;
  Timer? _timer;

  bool get done => idx >= rep.events.length;

  @override
  void initState() {
    super.initState();
    for (final u in [...rep.playerUnits, ...rep.enemyUnits]) {
      hp[u.id] = u.maxHp;
      st[u.id] = _U.alive;
      names[u.id] = u.name;
    }
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: 600 ~/ speed), (_) {
      if (playing && !done) _step();
    });
  }

  void _apply(BattleEvent e, {bool animate = true}) {
    round = e.round;
    if (e.fled) {
      st[e.actor] = _U.fled;
      log.add('${names[e.actor]} bỏ chạy khỏi trận!');
      actor = null;
      target = null;
      return;
    }
    actor = animate ? e.actor : null;
    target = animate ? e.target : null;
    if (e.hit) {
      hp[e.target!] = (hp[e.target!]! - e.damage).clamp(0, 9999);
      log.add(
        '${names[e.actor]} đánh ${names[e.target]}: -${e.damage}${e.crit ? ' (chí mạng)' : ''}',
      );
    } else {
      log.add('${names[e.actor]} đánh trượt ${names[e.target]}');
    }
    if (e.targetDown) {
      st[e.target!] = _U.down;
      log.add('${names[e.target]} gục ngã!');
    }
  }

  void _step() {
    if (done) return;
    setState(() => _apply(rep.events[idx++]));
    if (done) _timer?.cancel();
  }

  void _skip() {
    setState(() {
      while (!done) {
        _apply(rep.events[idx++], animate: false);
      }
      actor = null;
      target = null;
    });
    _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final s = c.state!;
    final d = Dims(context);
    final win = rep.winner;
    final banner = win == Winner.player
        ? 'CHIẾN THẮNG'
        : (win == Winner.enemy ? 'THẤT BẠI' : 'GIẰNG CO — RÚT QUÂN');

    Widget unitView(
      ({int id, String name, Role role, bool front, int maxHp, int level}) u,
      bool player,
      double sprite,
    ) {
      final soldier = player ? s.soldier(u.id) : null;
      final state = st[u.id]!;
      final lunge = actor == u.id ? (player ? 14.0 : -14.0) : 0.0;
      final hit = target == u.id;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.translationValues(lunge, 0, 0),
        width: sprite + 34,
        child: Opacity(
          opacity: state == _U.alive ? 1 : (state == _U.fled ? 0.3 : 0.55),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hit
                      ? Pal.blood.withValues(alpha: 0.5)
                      : Colors.transparent,
                ),
                child: SoldierSprite(
                  role: u.role,
                  seed: u.id.abs(),
                  armorId:
                      soldier?.armorId ??
                      (player ? 'padded_armor' : 'leather_armor'),
                  weaponId:
                      soldier?.weaponId ??
                      (u.role == Role.archer ? 'hunting_bow' : 'wooden_spear'),
                  bust: false,
                  enemy: !player,
                  down: state == _U.down,
                  size: sprite,
                ),
              ),
              SizedBox(
                width: sprite,
                child: Bar(
                  value: hp[u.id]! / u.maxHp,
                  color: player ? Pal.moss : Pal.blood,
                  height: 5,
                ),
              ),
              Text(
                state == _U.down ? '†' : (state == _U.fled ? 'chạy' : u.name),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9.5,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 3)],
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget side(
      List<({int id, String name, Role role, bool front, int maxHp, int level})>
      units,
      bool player,
      double sprite,
    ) {
      final front = units.where((u) => u.front).toList();
      final back = units.where((u) => !u.front).toList();
      Widget col(
        List<
          ({int id, String name, Role role, bool front, int maxHp, int level})
        >
        l,
      ) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final u in l)
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: unitView(u, player, sprite),
              ),
            ),
        ],
      );
      final cols = player ? [col(back), col(front)] : [col(front), col(back)];
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [for (final c in cols) Expanded(child: c)],
      );
    }

    return Scaffold(
      backgroundColor: Pal.bg,
      body: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: CustomPaint(painter: FieldPainter())),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 40, 8, 48),
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final maxRows = [
                            rep.playerUnits.where((u) => u.front).length,
                            rep.playerUnits.where((u) => !u.front).length,
                            rep.enemyUnits.where((u) => u.front).length,
                            rep.enemyUnits.where((u) => !u.front).length,
                          ].reduce((a, b) => a > b ? a : b).clamp(1, 10);
                          final sprite = (box.maxHeight / maxRows - 22).clamp(
                            26.0,
                            64.0,
                          );
                          return Row(
                            children: [
                              Expanded(
                                child: side(rep.playerUnits, true, sprite),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: side(rep.enemyUnits, false, sprite),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    left: 8,
                    right: 8,
                    child: Row(
                      children: [
                        Pill(
                          'Hiệp $round',
                          color: Pal.gold,
                          icon: Icons.local_fire_department,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.result.location?.name ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            shadows: [Shadow(blurRadius: 4)],
                          ),
                        ),
                        if (widget.result.ambush)
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Pill('Phục kích!', color: Pal.blood),
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 6,
                    child: Row(
                      children: [
                        if (!done) ...[
                          IconButton.filledTonal(
                            visualDensity: VisualDensity.compact,
                            tooltip: playing ? 'Tạm dừng' : 'Tiếp tục',
                            onPressed: () => setState(() => playing = !playing),
                            icon: Icon(
                              playing ? Icons.pause : Icons.play_arrow,
                            ),
                          ),
                          const SizedBox(width: 6),
                          for (final v in [1, 2, 4])
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: ChoiceChip(
                                label: Text('×$v'),
                                selected: speed == v,
                                visualDensity: VisualDensity.compact,
                                onSelected: (_) {
                                  setState(() => speed = v);
                                  _schedule();
                                },
                              ),
                            ),
                          GameButton(
                            label: 'Bỏ qua',
                            dense: true,
                            onPressed: _skip,
                          ),
                        ] else ...[
                          Expanded(
                            child: Text(
                              banner,
                              style: TextStyle(
                                fontFamily: serif,
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                                color: win == Winner.player
                                    ? Pal.gold
                                    : Pal.blood,
                                shadows: const [Shadow(blurRadius: 6)],
                              ),
                            ),
                          ),
                          GameButton(
                            label: 'Xem kết quả',
                            dense: true,
                            icon: Icons.assignment_turned_in,
                            onPressed: () => Navigator.of(context)
                                .pushReplacement(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        ResultScreen(result: widget.result),
                                  ),
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: d.compact ? 190 : 240,
              color: Pal.panel,
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'DIỄN BIẾN',
                    style: TextStyle(
                      color: Pal.gold,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: ListView.builder(
                      reverse: true,
                      itemCount: log.length,
                      itemBuilder: (_, i) {
                        final line = log[log.length - 1 - i];
                        final bold =
                            line.contains('gục') || line.contains('chạy');
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1.5),
                          child: Text(
                            line,
                            style: TextStyle(
                              fontSize: 11,
                              color: bold ? Pal.blood : Pal.text,
                              fontWeight: bold
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
