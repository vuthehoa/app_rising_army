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
import 'deploy_screen.dart';
import 'result_screen.dart';

/// Chọn binh sĩ đi viễn chinh. Với trại địch, bước tiếp theo là màn triển khai kéo-thả (giống game gốc).
class SquadScreen extends StatefulWidget {
  const SquadScreen({super.key, required this.locationId});

  final String locationId;

  @override
  State<SquadScreen> createState() => _SquadScreenState();
}

class _SquadScreenState extends State<SquadScreen> {
  final List<int> _squad = [];

  void _toggle(Soldier so) {
    setState(() {
      if (!_squad.remove(so.id) && _squad.length < GameRules.maxSquad) {
        _squad.add(so.id);
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final s = c.state!;
    final loc = GameRules.locationFor(s, widget.locationId)!;
    final d = Dims(context);
    _squad.removeWhere((id) => s.soldier(id)?.available != true);
    final members = [for (final id in _squad) s.soldier(id)!];
    final my = members.fold(0, (a, e) => a + powerScore(e));
    final enemies = loc.kind == LocKind.camp
        ? GameRules.previewEnemies(loc.enemies)
        : <Soldier>[];
    final eP = enemies.fold(0, (a, e) => a + powerScore(e));
    final isCamp = loc.kind == LocKind.camp;

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
                final fac = GameRules.facilityOf(s, so.id);
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${so.name} • ${roleNames[so.role]} cấp ${so.level}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'HP ${so.hp}/${so.maxHp}${fac != null ? ' • ${facilityDefs[fac.type]!.name}' : ''}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: so.hpFraction < 0.5
                                        ? Pal.blood
                                        : Pal.dim,
                                  ),
                                ),
                              ],
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
            'Đã chọn: ${members.length}/${GameRules.maxSquad} • Sức mạnh $my',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (isCamp) ...[
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
            const SizedBox(height: 4),
            Text(
              'Bước sau: triển khai kéo-thả trên chiến trường, rồi "Fight!". Trận diễn ra thời gian thực, không điều khiển giữa trận.',
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
            label: isCamp ? 'Tiếp tục: triển khai' : 'Xuất quân',
            icon: isCamp ? Icons.grid_view : Icons.flag,
            lockedReason: members.isEmpty ? 'Chọn ít nhất 1 binh sĩ' : null,
            onPressed: () => isCamp
                ? Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => DeployScreen(
                        locationId: loc.id,
                        squadIds: List<int>.of(_squad),
                      ),
                    ),
                  )
                : _go(context),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 40,
        backgroundColor: Pal.panel,
        title: Text(
          'Chọn đội • ${loc.name}',
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
              Expanded(flex: 5, child: SingleChildScrollView(child: roster)),
              SizedBox(width: d.gap),
              Expanded(flex: 4, child: SingleChildScrollView(child: info)),
            ],
          ),
        ),
      ),
    );
  }

  void _go(BuildContext context) {
    final c = ControllerScope.of(context);
    final ExpeditionResult r = c.sendExpedition(
      widget.locationId,
      List<int>.of(_squad),
      const {},
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
