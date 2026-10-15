import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../domain/battle.dart';
import '../../domain/combat_condition.dart';
import '../../domain/models.dart';
import '../../domain/catalog.dart';
import '../../domain/rules.dart';
import '../../domain/stats.dart';
import '../widgets/art.dart';
import '../widgets/common.dart';
import '../widgets/equipment/equipment_widgets.dart';
import '../widgets/equipment/item_summary.dart';
import '../widgets/item_kit.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.result});

  final ExpeditionResult result;

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final s = c.state!;
    final d = Dims(context);
    final rep = result.battle;
    final win = rep?.winner == Winner.player;
    final title = rep == null
        ? 'Viễn chinh hoàn tất'
        : (win
              ? 'Chiến thắng'
              : (rep.winner == Winner.enemy
                    ? 'Thất bại'
                    : 'Giằng co, rút quân'));
    final dead = result.casualties
        .where((x) => x.kind == CasualtyKind.dead)
        .toList();

    // Màu/biểu tượng theo kết quả THẬT của mô phỏng (không suy từ số quân còn sống).
    final (Color accent, IconData icon, String sub) = rep == null
        ? (Pal.gold, Icons.explore, 'Chuyến đi kết thúc')
        : switch (rep.winner) {
            Winner.player => (
              Pal.gold,
              Icons.military_tech,
              'Địch đã bị đánh bại',
            ),
            Winner.enemy => (
              Pal.blood,
              Icons.heart_broken,
              'Quân ta bị đánh bại',
            ),
            Winner.draw => (
              Pal.steel,
              Icons.balance,
              'Hai bên không phân thắng bại',
            ),
          };
    final alive = result.casualties
        .where(
          (x) =>
              x.kind == CasualtyKind.survived || x.kind == CasualtyKind.wounded,
        )
        .length;
    final gone = result.casualties
        .where((x) => x.kind == CasualtyKind.deserted)
        .length;

    final banner = TweenAnimationBuilder<double>(
      key: const ValueKey('result-banner'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.85 + 0.15 * t, child: child),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accent.withValues(alpha: 0.45),
              Pal.panel.withValues(alpha: 0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, size: 46, color: accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    key: const ValueKey('result-title'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: serif,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: accent,
                    ),
                  ),
                  Text(
                    sub,
                    style: const TextStyle(fontSize: 12, color: Pal.text),
                  ),
                  Text(
                    '${result.location?.name ?? ''} • ${result.days} ngày',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    Widget chip(IconData i, String text, Color c, {String? key}) => Container(
      key: key == null ? null : ValueKey(key),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(i, size: 14, color: c),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: Pal.text,
            ),
          ),
        ],
      ),
    );

    // Thống kê: chỉ số liệu có thật trong kết quả (danh sách thương vong, thời lượng trận).
    final stats = Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (result.casualties.isNotEmpty) ...[
          chip(
            Icons.groups,
            'Còn chiến đấu $alive',
            Pal.moss,
            key: 'result-stat-alive',
          ),
          chip(
            Icons.sentiment_very_dissatisfied,
            'Hy sinh ${dead.length}',
            dead.isEmpty ? Pal.dim : Pal.blood,
            key: 'result-stat-dead',
          ),
          if (gone > 0) chip(Icons.directions_run, 'Rời quân $gone', Pal.blood),
        ],
        if (rep != null)
          chip(
            Icons.timer,
            '${rep.duration.toStringAsFixed(0)} giây',
            Pal.steel,
            key: 'result-stat-duration',
          ),
      ],
    );

    // Phần thưởng đã được áp dụng ở luật; ở đây chỉ hiển thị lại.
    final rewards = (result.gained.isEmpty && result.itemsGained.isEmpty)
        ? null
        : Wrap(
            key: const ValueKey('result-rewards'),
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final e in result.gained.entries)
                if (e.value != 0)
                  chip(
                    resIcons[e.key] ?? Icons.inventory_2,
                    '+${e.value} ${resNames[e.key]}',
                    Pal.gold,
                  ),
              for (final it in result.itemsGained) _RewardItem(ref: it),
            ],
          );

    // Thưởng nhiệm vụ đã trao ngay sau trận (ghi lại lúc chốt; tách khỏi chiến lợi phẩm).
    final payouts = result.payouts.isEmpty
        ? null
        : Column(
            key: const ValueKey('result-payouts'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final p in result.payouts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hoàn thành: ${p.title}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final e in p.res.entries)
                            if (e.value != 0)
                              chip(
                                resIcons[e.key] ?? Icons.inventory_2,
                                '+${e.value} ${resNames[e.key]}',
                                Pal.gold,
                              ),
                          for (final it in p.items) _RewardItem(ref: it),
                          if (p.exp > 0)
                            chip(Icons.star, '+${p.exp} EXP/người', Pal.steel),
                          if (p.sat > 0)
                            chip(
                              Icons.workspace_premium,
                              'Uy tín +${p.sat}',
                              Pal.gold,
                            ),
                        ],
                      ),
                      for (final l in p.levelUps)
                        Text(
                          l,
                          style: const TextStyle(color: Pal.moss, fontSize: 11),
                        ),
                    ],
                  ),
                ),
            ],
          );

    final summary = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        banner,
        const SizedBox(height: 8),
        stats,
        if (rewards != null) ...[
          const SizedBox(height: 8),
          Text(
            'Chiến lợi phẩm',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Pal.dim,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          rewards,
        ],
        if (payouts != null) ...[
          const SizedBox(height: 8),
          Text(
            'Thưởng nhiệm vụ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Pal.dim,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          payouts,
        ],
        if (result.discovered != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Địa điểm mới: ${locationById(result.discovered!)!.name}',
              style: const TextStyle(
                color: Pal.gold,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        if (result.missionNote != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              result.missionNote!,
              style: const TextStyle(color: Pal.gold, fontSize: 12),
            ),
          ),
        if (result.lines.isNotEmpty) ...[
          const SizedBox(height: 6),
          for (final l in result.lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '• $l',
                style: const TextStyle(fontSize: 11.5, color: Pal.dim),
              ),
            ),
        ],
      ],
    );

    final losses = Panel(
      title: 'Thương vong và kinh nghiệm',
      highlight: dead.isNotEmpty,
      child: result.casualties.isEmpty
          ? Text(
              'Không có giao tranh.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          : Column(
              children: [
                if (dead.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A1814),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Pal.blood, width: 2),
                    ),
                    child: Text(
                      '${dead.length} binh sĩ đã tử trận vĩnh viễn: ${dead.map((e) => e.name).join(', ')}.',
                      style: const TextStyle(
                        color: Pal.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                for (final cs in result.casualties)
                  Builder(
                    builder: (context) {
                      final so = s.soldier(cs.id);
                      final (label, color) = switch (cs.kind) {
                        CasualtyKind.dead => ('Tử trận', Pal.blood),
                        CasualtyKind.wounded => (
                          'Bị thương${so != null ? ' (HP ${so.hp}/${so.maxHp})' : ''}',
                          const Color(0xFFE08A3A),
                        ),
                        CasualtyKind.survived => ('Sống sót', Pal.moss),
                        CasualtyKind.deserted => ('Đào ngũ', Pal.blood),
                      };
                      final shownLabel =
                          cs.kind == CasualtyKind.deserted && cs.fled
                          ? 'Bỏ chạy, đào ngũ'
                          : label;
                      final gone =
                          cs.kind == CasualtyKind.dead ||
                          cs.kind == CasualtyKind.deserted;
                      return Padding(
                        key: ValueKey('result-row-${cs.id}'),
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (so != null) SoldierSprite.of(so, size: 32),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${cs.name}${cs.levelAfter != null ? ' • Cấp ${cs.levelAfter}' : ''}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      decoration: gone
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (!gone)
                                  Flexible(
                                    child: Text(
                                      '+${cs.xp} XP${cs.levelUps > 0 ? '  LÊN CẤP ${cs.levelAfter ?? so?.level}!' : ''}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: cs.levelUps > 0
                                            ? Pal.gold
                                            : Pal.dim,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                Pill(shownLabel, color: color),
                              ],
                            ),
                            if (cs.kind != CasualtyKind.dead)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 38,
                                  top: 1,
                                ),
                                child: _VitalsLine(cs: cs, soldier: so),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
    );

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 40,
        backgroundColor: Pal.panel,
        title: const Text(
          'Kết quả trận',
          style: TextStyle(
            fontFamily: serif,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(d.pad),
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) => box.maxWidth < 560
                      // Màn hẹp: một cột cuộn duy nhất thay vì hai cột bị ép.
                      ? SingleChildScrollView(
                          child: Column(
                            children: [
                              summary,
                              SizedBox(height: d.gap),
                              losses,
                            ],
                          ),
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 4,
                              child: SingleChildScrollView(child: summary),
                            ),
                            SizedBox(width: d.gap),
                            Expanded(
                              flex: 5,
                              child: SingleChildScrollView(child: losses),
                            ),
                          ],
                        ),
                ),
              ),
              SizedBox(height: d.gap),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      win ? 'Binh sĩ sống sót có thể nghỉ ngơi ở trại.' : 'Hãy nghỉ ngơi và chữa trị trước khi ra trận lần nữa.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 240,
                    child: GameButton(
                      label: 'Về trại',
                      icon: Icons.fort,
                      onPressed: () =>
                          Navigator.of(context).popUntil((r) => r.isFirst),
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

String _delta(int? from, int? to, {required String name}) {
  if (from == null || to == null) return '';
  final d = to - from;
  return '$name $from→$to (${d > 0 ? '+' : ''}$d)';
}

/// Năng lượng / tinh thần trước→sau, điểm chỉ số chưa dùng, và có cần hồi phục không. Đọc ảnh chụp trong [Casualty]
/// (chốt một lần ở `applyBattle`), nên mở lại màn kết quả không thay đổi hay cấp thêm gì.
class _VitalsLine extends StatelessWidget {
  const _VitalsLine({required this.cs, required this.soldier});
  final Casualty cs;
  final Soldier? soldier;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      _delta(cs.energyBefore, cs.energyAfter, name: 'Thể lực'),
      _delta(cs.moraleBefore, cs.moraleAfter, name: 'Tinh thần'),
      if ((cs.statPointsAfter ?? 0) > 0)
        'Điểm chỉ số chưa dùng: ${cs.statPointsAfter}',
    ].where((x) => x.isNotEmpty).toList();
    final so = soldier;
    String? ready;
    if (cs.kind != CasualtyKind.deserted &&
        so != null &&
        cs.energyAfter != null) {
      final low =
          so.hp < so.maxHp * vitalWarnBelow ||
          cs.energyAfter! < energyCap(so) * vitalWarnBelow ||
          (cs.moraleAfter ?? 100) < moraleCap(so) * vitalWarnBelow;
      ready = low ? 'Cần hồi phục' : 'Sẵn sàng chiến đấu';
      parts.add(ready);
    }
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(
      parts.join(' • '),
      key: ValueKey('result-vitals-${cs.id}'),
      style: TextStyle(
        fontSize: 10.5,
        color: ready == 'Cần hồi phục' ? const Color(0xFFE08A3A) : Pal.dim,
      ),
    );
  }
}

/// Một trang bị đã nhận: hình, tên, loại và dòng thuộc tính thật của thiết kế (sát thương / phòng thủ / buff). Chạm
/// để xem chi tiết đầy đủ trong popup dùng chung (không đổi state).
class _RewardItem extends StatelessWidget {
  const _RewardItem({required this.ref});
  final String ref;

  @override
  Widget build(BuildContext context) {
    final def = itemDefs[ref];
    if (def == null) return const SizedBox.shrink();
    return InkWell(
      key: ValueKey('result-item-$ref'),
      borderRadius: BorderRadius.circular(8),
      onTap: () => showItemDetail(context, info: ItemInfoBlock.equipment(ref)),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Pal.panelHi,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Pal.moss),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ItemGlyph(ref, size: 30),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemDisplayName(ref),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                  ),
                ),
                Text(
                  '${itemKindLabel(def)} • ${itemSummaryLine(def)}',
                  style: const TextStyle(color: Pal.dim, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
