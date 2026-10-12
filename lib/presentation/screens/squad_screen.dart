import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../domain/catalog.dart';
import '../../domain/models.dart';
import '../../domain/rules.dart';
import '../../domain/stats.dart';
import '../widgets/art.dart';
import '../widgets/common.dart';
import 'battle_screen.dart';
import 'city_screen.dart';
import 'result_screen.dart';

class SquadScreen extends StatefulWidget {
  const SquadScreen({super.key, required this.locationId});

  final String locationId;

  @override
  State<SquadScreen> createState() => _SquadScreenState();
}

class _SquadScreenState extends State<SquadScreen> {
  final List<int> _squad = [];
  final Set<int> _front = {};

  void _toggle(Soldier so) {
    setState(() {
      if (_squad.remove(so.id)) {
        _front.remove(so.id);
      } else if (_squad.length < GameRules.maxSquad) {
        _squad.add(so.id);
        if (so.role != Role.archer) _front.add(so.id);
      }
    });
  }

  void _auto(GameState s) {
    final best = s.roster.where((x) => x.available).toList()
      ..sort((a, b) => powerScore(b).compareTo(powerScore(a)));
    setState(() {
      _squad
        ..clear()
        ..addAll(best.take(8).map((e) => e.id));
      _front
        ..clear()
        ..addAll(
          best.take(8).where((e) => e.role != Role.archer).map((e) => e.id),
        );
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final s = c.state!;
    final loc = locationById(widget.locationId)!;
    final d = Dims(context);
    _squad.removeWhere((id) => s.soldier(id)?.available != true);
    _front.removeWhere((id) => !_squad.contains(id));
    final members = [for (final id in _squad) s.soldier(id)!];
    final my = members.fold(0, (a, e) => a + powerScore(e));
    final enemies = loc.kind == LocKind.camp
        ? GameRules.previewEnemies(loc.enemies)
        : <Soldier>[];
    final eP = enemies.fold(0, (a, e) => a + powerScore(e));

    final notes = <String>[];
    for (final m in GameRules.byStatus(s, MissionStatus.active)) {
      final t = templateById(m.templateId);
      if (t.kind == MissionKind.clear &&
          t.locId == loc.id &&
          t.minSoldiers > 0) {
        final ok = members.length >= t.minSoldiers;
        notes.add(
          '${ok ? '✓' : '✗'} Nhiệm vụ "${t.title}" cần đội ≥ ${t.minSoldiers} người',
        );
      }
    }

    final roster = Panel(
      title: 'Binh sĩ',
      trailing: GameButton(
        label: 'Tự chọn',
        dense: true,
        onPressed: () => _auto(s),
      ),
      child: Column(
        children: [
          for (final so in s.roster)
            Builder(
              builder: (context) {
                final picked = _squad.contains(so.id);
                final reason = so.injured
                    ? 'Bị thương ${so.injuryDays}n'
                    : (so.training ? 'Đang tập' : null);
                return InkWell(
                  onTap: so.available ? () => _toggle(so) : null,
                  child: Opacity(
                    opacity: so.available ? 1 : 0.45,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 3),
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: picked ? Pal.panelHi : null,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: picked ? Pal.gold : Pal.line),
                      ),
                      child: Row(
                        children: [
                          SoldierSprite.of(so, size: 32),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              '${so.name}\n${roleNames[so.role]} Cấp ${so.level}${reason != null ? ' • $reason' : ''}',
                              style: const TextStyle(fontSize: 11),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            picked
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            size: 18,
                            color: picked ? Pal.gold : Pal.dim,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );

    Widget rowColumn(String title, bool front) {
      final list = members
          .where((m) => _front.contains(m.id) == front)
          .toList();
      return Expanded(
        child: Panel(
          title: title,
          child: list.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    'Trống',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              : Column(
                  children: [
                    for (final m in list)
                      InkWell(
                        onTap: () => setState(
                          () => front ? _front.remove(m.id) : _front.add(m.id),
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Pal.bg.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Pal.line),
                          ),
                          child: Row(
                            children: [
                              SoldierSprite.of(m, size: 34),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${m.name}\n${roleNames[m.role]} • ${powerScore(m)}',
                                  style: const TextStyle(fontSize: 10.5),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(
                                Icons.swap_horiz,
                                size: 16,
                                color: Pal.dim,
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

    final info = Panel(
      title: loc.name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${regionById(loc.regionId).name} • ${loc.days} ngày hành quân',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Đội hình: ${members.length}/${GameRules.maxSquad} • Sức mạnh $my',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (loc.kind == LocKind.camp) ...[
            Text(
              'Địch: ${loc.enemies.map((e) => '${e.count}× ${roleNames[e.role]} c${e.level}').join(', ')} • Sức mạnh $eP',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 3),
            Bar(
              value: my == 0 ? 0 : my / (my + eP),
              color: my >= eP ? Pal.moss : Pal.blood,
              height: 8,
            ),
            Text(
              my >= eP
                  ? 'Ta có ưu thế (ước lượng thô)'
                  : 'Địch có ưu thế (ước lượng thô)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (loc.kind == LocKind.resource)
            Text(
              'Điểm tài nguyên: có thể bị phục kích.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (loc.kind == LocKind.city)
            Text(
              'Đội hộ tống đi cùng; đường tới thành phố an toàn. Mua bán chỉ thực hiện được khi bạn đang ở thành phố.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: 4),
          Text(
            'Hàng trước chịu đòn trước. Cung thủ nên ở hàng sau; kỵ binh luôn đánh được hàng sau địch. Chạm một binh sĩ ở hàng để đổi hàng.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          for (final n in notes)
            Text(
              n,
              style: TextStyle(
                fontSize: 11.5,
                color: n.startsWith('✓') ? Pal.moss : Pal.blood,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            'Trong ${loc.days} ngày hành quân, cả trại vẫn tốn lương và nhiệm vụ vẫn đếm hạn.',
            style: const TextStyle(fontSize: 11, color: Pal.gold),
          ),
          const SizedBox(height: 8),
          GameButton(
            label: 'Xuất quân',
            icon: Icons.flag,
            lockedReason: members.isEmpty ? 'Chọn ít nhất 1 binh sĩ' : null,
            onPressed: () => _go(context, c),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 40,
        backgroundColor: Pal.panel,
        title: Text(
          'Chuẩn bị đội hình • ${loc.name}',
          style: const TextStyle(
            fontFamily: serif,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(d.pad),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: SingleChildScrollView(child: roster)),
              SizedBox(width: d.gap),
              Expanded(
                flex: 5,
                child: SingleChildScrollView(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      rowColumn('Hàng trước', true),
                      SizedBox(width: d.gap),
                      rowColumn('Hàng sau', false),
                    ],
                  ),
                ),
              ),
              SizedBox(width: d.gap),
              Expanded(flex: 4, child: SingleChildScrollView(child: info)),
            ],
          ),
        ),
      ),
    );
  }

  void _go(BuildContext context, dynamic c) {
    final ExpeditionResult r = c.sendExpedition(
      widget.locationId,
      List<int>.of(_squad),
      Set<int>.of(_front),
    );
    if (!r.result.ok) {
      toast(context, r.result);
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => r.city != null
            ? CityScreen(cityId: r.city!, arrival: r)
            : (r.battle != null
                  ? BattleScreen(result: r)
                  : ResultScreen(result: r)),
      ),
    );
  }
}
