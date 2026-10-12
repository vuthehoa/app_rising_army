import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../domain/catalog.dart';
import '../../domain/models.dart';
import '../../domain/rules.dart';
import '../../domain/stats.dart';
import '../widgets/art.dart';
import '../widgets/common.dart';
import 'city_screen.dart';
import 'squad_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String? _sel;

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final s = c.state!;
    final d = Dims(context);
    final unlocked = [for (final r in regions) GameRules.regionUnlocked(s, r)];

    return Padding(
      padding: EdgeInsets.all(d.pad),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Pal.goldDim, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: LayoutBuilder(
                  builder: (context, box) {
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: MapPainter(unlocked: unlocked),
                          ),
                        ),
                        for (var i = 0; i < regions.length; i++)
                          if (!unlocked[i])
                            Positioned(
                              left: box.maxWidth * i / 3,
                              top: 0,
                              width: box.maxWidth / 3,
                              height: box.maxHeight,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.lock,
                                      color: Pal.ink,
                                      size: 28,
                                    ),
                                    Text(
                                      'Cần ${const [0, 3, 6][i]} nhiệm vụ',
                                      style: const TextStyle(
                                        color: Pal.ink,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        for (final l in locations)
                          if (unlocked[regions.indexWhere(
                            (r) => r.id == l.regionId,
                          )])
                            Positioned(
                              left: l.x * box.maxWidth - 20,
                              top: l.y * box.maxHeight - 20,
                              child: _Marker(
                                loc: l,
                                known: s.discovered.contains(l.id),
                                done:
                                    s.cleared.contains(l.id) ||
                                    s.explored.contains(l.id),
                                selected: _sel == l.id,
                                onTap: () => setState(() => _sel = l.id),
                              ),
                            ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          SizedBox(width: d.gap),
          SizedBox(
            width: d.compact ? 250 : 300,
            child: SingleChildScrollView(
              child: _Side(
                selected: _sel,
                onSelect: (v) => setState(() => _sel = v),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({
    required this.loc,
    required this.known,
    required this.done,
    required this.selected,
    required this.onTap,
  });

  final LocationDef loc;
  final bool known;
  final bool done;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = !known
        ? Pal.dim
        : done
        ? Pal.steel
        : switch (loc.kind) {
            LocKind.camp => Pal.blood,
            LocKind.resource => Pal.moss,
            LocKind.ruins => Pal.gold,
            LocKind.city => Pal.steel,
          };
    final icon = !known
        ? Icons.help_outline
        : switch (loc.kind) {
            LocKind.camp => done ? Icons.check : Icons.flag,
            LocKind.resource => Icons.grass,
            LocKind.ruins => done ? Icons.check : Icons.account_balance,
            LocKind.city => Icons.storefront,
          };
    return Semantics(
      button: true,
      label: known ? loc.name : 'Địa điểm chưa khám phá',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Container(
            width: selected ? 36 : 30,
            height: selected ? 36 : 30,
            decoration: BoxDecoration(
              color: Pal.ink,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? Pal.text : color,
                width: selected ? 3 : 2.5,
              ),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
        ),
      ),
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({required this.selected, required this.onSelect});

  final String? selected;
  final void Function(String?) onSelect;

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final s = c.state!;
    final loc = selected == null ? null : locationById(selected!);
    final d = Dims(context);

    final scout = Panel(
      title: 'Trinh sát',
      child: Column(
        children: [
          for (final r in regions)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(r.name, style: const TextStyle(fontSize: 12)),
                  ),
                  SizedBox(
                    width: 112,
                    child: GameButton(
                      label: 'Trinh sát',
                      dense: true,
                      lockedReason: !GameRules.regionUnlocked(s, r) ? '' : null,
                      onPressed: () => toast(context, c.scoutRegion(r.id)),
                    ),
                  ),
                ],
              ),
            ),
          Text(
            'Tốn 5 lương thực và 1 ngày để lộ thêm một địa điểm. Khám phá tàn tích cũng mở thêm lối đi.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );

    if (loc == null) {
      return Column(
        children: [
          Panel(
            title: 'Bản đồ',
            child: Text(
              'Chạm một địa điểm để xem chi tiết. Dấu “?” là nơi chưa khám phá.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          SizedBox(height: d.gap),
          scout,
        ],
      );
    }

    final known = s.discovered.contains(loc.id);
    if (!known) {
      return Column(
        children: [
          Panel(
            title: 'Chưa khám phá',
            child: Text(
              'Hãy trinh sát vùng ${regionById(loc.regionId).name} hoặc khám phá tàn tích để tìm ra nơi này.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          SizedBox(height: d.gap),
          scout,
        ],
      );
    }

    final links = [
      for (final m in GameRules.byStatus(s, MissionStatus.active))
        if (templateById(m.templateId).locId == loc.id ||
            (templateById(m.templateId).kind == MissionKind.explore &&
                templateById(m.templateId).regionId == loc.regionId &&
                loc.kind == LocKind.ruins))
          templateById(m.templateId).title,
    ];
    final cleared = s.cleared.contains(loc.id);
    final explored = s.explored.contains(loc.id);
    String? lock;
    if (loc.kind == LocKind.camp && cleared) {
      lock = 'Đã quét sạch';
    } else if (s.roster.where((x) => x.available).isEmpty) {
      lock = 'Không có binh sĩ sẵn sàng';
    }

    Widget enemyInfo() {
      final en = GameRules.previewEnemies(loc.enemies);
      final ours =
          (s.roster.where((x) => x.available).toList()
                ..sort((a, b) => powerScore(b).compareTo(powerScore(a))))
              .take(8);
      final eP = en.fold(0, (a, e) => a + powerScore(e));
      final oP = ours.fold(0, (a, e) => a + powerScore(e));
      final ratio = oP == 0 ? 0.0 : eP / oP;
      final (label, color) = ratio < 0.6
          ? ('Dễ', Pal.moss)
          : (ratio < 1.0
                ? ('Vừa sức', Pal.gold)
                : (ratio < 1.6 ? ('Khó', Pal.blood) : ('Rất khó', Pal.blood)));
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quân địch: ${loc.enemies.map((e) => '${e.count}× ${roleNames[e.role]} cấp ${e.level}').join(', ')}',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Flexible(
                child: Text(
                  'Nguy hiểm so với 8 binh sĩ mạnh nhất: ',
                  style: TextStyle(fontSize: 11.5),
                ),
              ),
              Pill(label, color: color),
            ],
          ),
        ],
      );
    }

    return Column(
      children: [
        Panel(
          title: switch (loc.kind) {
            LocKind.camp => 'Trại địch',
            LocKind.resource => 'Điểm tài nguyên',
            LocKind.ruins => 'Tàn tích',
            LocKind.city => 'Thành phố',
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc.name, style: Theme.of(context).textTheme.titleLarge),
              Text(
                '${regionById(loc.regionId).name} • ${loc.days} ngày hành quân',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (loc.blurb.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(loc.blurb, style: const TextStyle(fontSize: 12)),
                ),
              const SizedBox(height: 6),
              if (loc.kind == LocKind.camp) ...[
                enemyInfo(),
                const SizedBox(height: 4),
                Text(
                  'Chiến lợi phẩm: ${GameRules.describeCost(loc.loot)}${loc.lootItem != null ? ' + ${itemDefs[loc.lootItem]!.name}' : ''}',
                  style: const TextStyle(fontSize: 12, color: Pal.moss),
                ),
              ],
              if (loc.kind == LocKind.resource)
                Text(
                  'Thu ~${loc.yield} ${resNames[loc.res!]} (tăng theo quân số). ${(ambushChance * 100).round()}% bị phục kích.',
                  style: const TextStyle(fontSize: 12, color: Pal.moss),
                ),
              if (loc.kind == LocKind.city) ...[
                Text(
                  'Người bán: ${vendorsIn(loc.id).map((v) => v.name).join(', ')}.',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  s.visiting == loc.id
                      ? 'Bạn đang ở đây.'
                      : 'Phải hành quân ${loc.days} ngày để tới; chỉ giao dịch được khi đang ở thành phố.',
                  style: const TextStyle(fontSize: 12, color: Pal.gold),
                ),
              ],
              if (loc.kind == LocKind.ruins)
                Text(
                  explored
                      ? 'Đã khám phá.'
                      : 'Có thể có kho báu, bẫy, và lộ địa điểm mới.',
                  style: const TextStyle(fontSize: 12, color: Pal.gold),
                ),
              if (links.isNotEmpty) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: [
                    for (final t in links)
                      Pill(
                        'Nhiệm vụ: $t',
                        color: Pal.gold,
                        icon: Icons.assignment,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              if (loc.kind == LocKind.city && s.visiting == loc.id)
                GameButton(
                  label: 'Vào thành phố',
                  icon: Icons.storefront,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CityScreen(cityId: loc.id),
                    ),
                  ),
                )
              else
                GameButton(
                  label: loc.kind == LocKind.city
                      ? 'Hành quân tới thành phố'
                      : 'Chuẩn bị đội hình',
                  icon: loc.kind == LocKind.city ? Icons.route : Icons.groups,
                  lockedReason: lock,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SquadScreen(locationId: loc.id),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: d.gap),
        scout,
      ],
    );
  }
}
