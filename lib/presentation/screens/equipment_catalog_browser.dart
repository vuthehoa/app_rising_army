import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../domain/catalog.dart';
import '../../domain/equipment/equipment_catalog.dart';
import '../../domain/equipment/equipment_generator.dart';
import '../../domain/equipment/equipment_item.dart';
import '../../domain/equipment/equipment_ref.dart';
import '../../domain/equipment/equipment_types.dart';
import '../../domain/models.dart';
import '../../domain/stats.dart';
import '../widgets/art.dart';
import '../widgets/common.dart';
import '../widgets/equipment/equipment_registry.dart';
import '../widgets/equipment/equipment_widgets.dart';
import '../dev/equipment_catalog_audit.dart';

enum DevTypeFilter { all, armor, weapon, shield }

enum DevEffectFilter { all, any, buff, debuff, conditional, none }

/// Bộ lọc thuần (không giữ state ngoài giá trị) áp lên catalog chính để duyệt 170 thiết kế.
class DevCatalogFilter {
  const DevCatalogFilter({
    this.type = DevTypeFilter.all,
    this.grade = 0,
    this.query = '',
    this.effect = DevEffectFilter.all,
  });

  final DevTypeFilter type;
  final int grade; // 0 = mọi cấp
  final String query;
  final DevEffectFilter effect;

  bool get isDefault =>
      type == DevTypeFilter.all &&
      grade == 0 &&
      query.isEmpty &&
      effect == DevEffectFilter.all;

  bool accepts(ItemDef d) {
    final okType = switch (type) {
      DevTypeFilter.all => true,
      DevTypeFilter.armor => d.slot == Slot.armor,
      DevTypeFilter.weapon => d.slot == Slot.weapon,
      DevTypeFilter.shield => d.slot == Slot.shield,
    };
    if (!okType) return false;
    if (grade != 0 && d.tier != grade) return false;
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty &&
        !d.name.toLowerCase().contains(q) &&
        !d.id.toLowerCase().contains(q)) {
      return false;
    }
    final t = d.traits;
    return switch (effect) {
      DevEffectFilter.all => true,
      DevEffectFilter.any => t.isNotEmpty,
      DevEffectFilter.none => t.isEmpty,
      DevEffectFilter.buff => t.any((e) => e.isBuff),
      DevEffectFilter.debuff => t.any((e) => e.isDebuff),
      DevEffectFilter.conditional => t.any((e) => e.isConditional),
    };
  }

  List<ItemDef> apply(Iterable<ItemDef> all) => [
    for (final d in all)
      if (accepts(d)) d,
  ];
}

/// Duyệt toàn bộ thiết kế trang bị từ [EquipmentCatalog] ngay trong Develop Mode. Chỉ ĐỌC catalog: không
/// chạm GameState/inventory/save. Biến thể và thử trang bị dùng bản sao tạm và một binh sĩ thử trong bộ nhớ.
class EquipmentCatalogBrowser extends StatefulWidget {
  const EquipmentCatalogBrowser({super.key, this.onOpenSandbox});

  /// Quay về chế độ Equipment sandbox ban đầu.
  final VoidCallback? onOpenSandbox;

  @override
  State<EquipmentCatalogBrowser> createState() => _BrowserState();
}

class _BrowserState extends State<EquipmentCatalogBrowser> {
  DevCatalogFilter _f = const DevCatalogFilter();
  bool _list = false;
  bool _variants = false;
  String? _selectedId;
  String? _variantRef; // bản sao tạm đang xem (null = bản chuẩn)
  String? _compareId;
  bool _compareMode = false;
  final _search = TextEditingController();
  final _rng = Random();

  // Binh sĩ thử trong bộ nhớ, KHÔNG thuộc GameState.
  final Soldier _dummy = Soldier(
    id: -999,
    name: 'Lính thử',
    role: Role.spearman,
    stats: {Stat.str: 16, Stat.dex: 10, Stat.con: 10},
    level: 10,
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<ItemDef> get _shown => _f.apply(EquipmentCatalog.all);

  void _select(String id) => setState(() {
    if (_compareMode && _selectedId != null && id != _selectedId) {
      _compareId = id;
      _compareMode = false;
    } else {
      _selectedId = id;
      _variantRef = null;
    }
  });

  void _step(int dir) {
    final list = _shown.isEmpty ? EquipmentCatalog.all : _shown;
    final i = list.indexWhere((d) => d.id == _selectedId);
    final n = i < 0
        ? (dir > 0 ? 0 : list.length - 1)
        : (i + dir + list.length) % list.length;
    _select(list[n].id);
  }

  void _random() {
    final all = EquipmentCatalog.all;
    final d = all[_rng.nextInt(all.length)];
    setState(() {
      if (!_f.accepts(d)) {
        _f = const DevCatalogFilter();
        _search.clear();
      }
      _selectedId = d.id;
      _variantRef = null;
    });
  }

  void _reset() => setState(() {
    _f = const DevCatalogFilter();
    _search.clear();
  });

  @override
  Widget build(BuildContext context) {
    final shown = _shown;
    final all = EquipmentCatalog.all;
    return Scaffold(
      backgroundColor: Pal.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            children: [
              _toolbar(shown),
              const SizedBox(height: 4),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Panel(
                        fill: true,
                        padding: const EdgeInsets.all(4),
                        child: shown.isEmpty
                            ? const Center(
                                child: Text(
                                  'Không có thiết kế khớp bộ lọc.',
                                  key: ValueKey('dev-eq-empty'),
                                  style: TextStyle(color: Pal.dim),
                                ),
                              )
                            : _list
                            ? _listView(shown)
                            : _gridView(shown),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(width: 300, child: _detail(all)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------ Thanh công cụ

  Widget _toolbar(List<ItemDef> shown) {
    final a = EquipmentCatalog.armors.length,
        w = EquipmentCatalog.weapons.length,
        s = EquipmentCatalog.shields.length;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 108),
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 0,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Tổng ${EquipmentCatalog.all.length} (Giáp $a • Vũ khí $w • Khiên $s) • hiện ${shown.length}',
              key: const ValueKey('dev-eq-count'),
              style: const TextStyle(
                color: Pal.gold,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 8),
            for (final t in DevTypeFilter.values)
              _chip(
                'dev-eq-type-${t.name}',
                const {
                  DevTypeFilter.all: 'Tất cả',
                  DevTypeFilter.armor: 'Giáp',
                  DevTypeFilter.weapon: 'Vũ khí',
                  DevTypeFilter.shield: 'Khiên',
                }[t]!,
                _f.type == t,
                () => setState(() => _f = _copy(type: t)),
              ),
            const SizedBox(width: 4),
            _chip(
              'dev-eq-grade-0',
              'Mọi cấp',
              _f.grade == 0,
              () => setState(() => _f = _copy(grade: 0)),
            ),
            for (final r in EquipmentRarity.values)
              _chip(
                'dev-eq-grade-${r.grade}',
                '${r.grade}',
                _f.grade == r.grade,
                () => setState(() => _f = _copy(grade: r.grade)),
                color: rarityColor(r),
              ),
            const SizedBox(width: 4),
            SizedBox(
              width: 150,
              height: 32,
              child: TextField(
                key: const ValueKey('dev-eq-search'),
                controller: _search,
                style: const TextStyle(fontSize: 12, color: Pal.text),
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'Tìm tên / ID',
                  prefixIcon: Icon(Icons.search, size: 16),
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _f = _copy(query: v)),
              ),
            ),
            const SizedBox(width: 4),
            DropdownButton<DevEffectFilter>(
              key: const ValueKey('dev-eq-effect'),
              value: _f.effect,
              isDense: true,
              dropdownColor: Pal.panelHi,
              style: const TextStyle(fontSize: 11, color: Pal.text),
              items: const [
                DropdownMenuItem(
                  value: DevEffectFilter.all,
                  child: Text('Hiệu ứng: tất cả'),
                ),
                DropdownMenuItem(
                  value: DevEffectFilter.any,
                  child: Text('Có hiệu ứng'),
                ),
                DropdownMenuItem(
                  value: DevEffectFilter.none,
                  child: Text('Không hiệu ứng'),
                ),
                DropdownMenuItem(
                  value: DevEffectFilter.buff,
                  child: Text('Có buff'),
                ),
                DropdownMenuItem(
                  value: DevEffectFilter.debuff,
                  child: Text('Có debuff'),
                ),
                DropdownMenuItem(
                  value: DevEffectFilter.conditional,
                  child: Text('Có điều kiện'),
                ),
              ],
              onChanged: (v) => setState(() => _f = _copy(effect: v)),
            ),
            const SizedBox(width: 4),
            _chip(
              'dev-eq-view',
              _list ? 'Danh sách' : 'Lưới',
              false,
              () => setState(() => _list = !_list),
            ),
            _chip(
              'dev-eq-variants',
              'Biến thể',
              _variants,
              () => setState(() => _variants = !_variants),
            ),
            _chip('dev-eq-reset', 'Reset', false, _reset),
            _chip('dev-eq-prev', '◀', false, () => _step(-1)),
            _chip('dev-eq-next', '▶', false, () => _step(1)),
            _chip('dev-eq-random', 'Random', false, _random),
            _chip('dev-eq-audit', 'Kiểm tra', false, _showAudit),
            if (widget.onOpenSandbox != null)
              _chip('dev-eq-sandbox', 'Sandbox', false, widget.onOpenSandbox!),
          ],
        ),
      ),
    );
  }

  DevCatalogFilter _copy({
    DevTypeFilter? type,
    int? grade,
    String? query,
    DevEffectFilter? effect,
  }) => DevCatalogFilter(
    type: type ?? _f.type,
    grade: grade ?? _f.grade,
    query: query ?? _f.query,
    effect: effect ?? _f.effect,
  );

  Widget _chip(
    String key,
    String label,
    bool sel,
    VoidCallback onTap, {
    Color? color,
  }) {
    final c = color ?? Pal.goldLight;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: InkWell(
        key: ValueKey(key),
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 32,
          constraints: const BoxConstraints(minWidth: 34),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: sel ? Pal.goldDeep : Pal.bgDeep,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: sel ? c : Pal.line, width: sel ? 1.6 : 1),
          ),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: TextStyle(
                color: sel ? c : (color ?? Pal.dim),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAudit() {
    final issues = EquipmentCatalogAudit.run();
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const ValueKey('dev-eq-audit-dialog'),
        title: Text(issues.isEmpty ? 'Catalog hợp lệ' : '${issues.length} lỗi'),
        content: SizedBox(
          width: 420,
          child: issues.isEmpty
              ? const Text(
                  'Đủ 50/100/20, ID duy nhất, mọi thiết kế có painter đúng loại, nền đúng cấp.',
                )
              : ListView(
                  shrinkWrap: true,
                  children: [
                    for (final i in issues)
                      Text(
                        i,
                        style: const TextStyle(color: Pal.blood, fontSize: 12),
                      ),
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ Lưới / danh sách

  Widget _gridView(List<ItemDef> shown) => GridView.builder(
    key: const ValueKey('dev-eq-grid'),
    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 96,
      mainAxisExtent: 112,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
    ),
    itemCount: shown.length,
    itemBuilder: (_, i) {
      final d = shown[i];
      final item = EquipmentItem.standard(d);
      final ok = EquipmentCatalogAudit.mapped(d.id);
      return Column(
        children: [
          Expanded(
            child: ok
                ? EquipmentCard(
                    key: ValueKey('dev-eq-card-${d.id}'),
                    item: item,
                    selected: _selectedId == d.id,
                    onTap: () => _select(d.id),
                  )
                : InkWell(
                    key: ValueKey('dev-eq-card-${d.id}'),
                    onTap: () => _select(d.id),
                    child: Container(
                      color: Pal.dangerSurface,
                      alignment: Alignment.center,
                      child: const Text(
                        'LỖI',
                        style: TextStyle(color: Pal.blood),
                      ),
                    ),
                  ),
          ),
          Text(
            '${d.name}\n${itemKindLabel(d)}',
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Pal.text, fontSize: 9, height: 1.1),
          ),
        ],
      );
    },
  );

  Widget _listView(List<ItemDef> shown) => Material(
    color: Colors.transparent,
    child: ListView.builder(
      key: const ValueKey('dev-eq-listview'),
      itemCount: shown.length,
      itemBuilder: (_, i) {
        final d = shown[i];
        return ListTile(
          key: ValueKey('dev-eq-card-${d.id}'),
          dense: true,
          selected: _selectedId == d.id,
          selectedTileColor: Pal.panelHi,
          leading: ItemGlyph(d.id, size: 40),
          title: Text(d.name, style: const TextStyle(fontSize: 12.5)),
          subtitle: Text(
            '${d.id} • ${itemKindLabel(d)} • cấp ${d.tier} • ${formatKg(d.weight)}${d.traits.isEmpty ? '' : ' • FX${d.traits.length}'}',
            style: const TextStyle(fontSize: 10.5),
          ),
          onTap: () => _select(d.id),
        );
      },
    ),
  );

  // ------------------------------------------------------------ Chi tiết

  Widget _detail(List<ItemDef> all) {
    final id = _selectedId;
    if (id == null) {
      return const Panel(
        fill: true,
        child: Center(
          child: Text(
            'Chọn một thiết kế để xem chi tiết.',
            key: ValueKey('dev-eq-hint'),
            style: TextStyle(color: Pal.dim, fontSize: 11),
          ),
        ),
      );
    }
    final d = EquipmentCatalog.byId(id)!;
    final ref = _variantRef ?? d.id;
    final item = EquipmentItem.tryParse(ref)!;
    final painter = EquipmentRegistry.maybe(d.id);
    final ok = EquipmentCatalogAudit.mapped(d.id);
    final cmp = _compareId == null ? null : EquipmentCatalog.byId(_compareId!);
    final before = deriveStats(_dummy);
    final after = deriveStats(_dummy, override: {d.slot: ref});
    // Binh sĩ thử với đồ đang xem: bản sao trong bộ nhớ, không phải GameState.
    final preview = Soldier(
      id: -998,
      name: 'preview',
      role: Role.spearman,
      stats: Map.of(_dummy.stats),
      level: 10,
      armorId: d.slot == Slot.armor ? ref : null,
      weaponId: d.slot == Slot.weapon ? ref : null,
      shieldId: d.slot == Slot.shield ? ref : null,
    );
    return Panel(
      fill: true,
      padding: const EdgeInsets.all(6),
      child: SingleChildScrollView(
        key: const ValueKey('dev-eq-detail'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ItemGlyph(ref, size: 120),
                const SizedBox(width: 6),
                SoldierSprite.of(preview, bust: false, size: 100),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              item.displayName,
              key: const ValueKey('dev-eq-name'),
              style: const TextStyle(
                color: Pal.gold,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
            SelectableText(
              'ID: ${d.id}',
              style: const TextStyle(color: Pal.dim, fontSize: 10.5),
            ),
            Text(
              '${itemKindLabel(d)} • Cấp ${d.tier} ${d.rarity.label} • ${formatKg(item.weight)}',
              style: const TextStyle(color: Pal.text, fontSize: 11),
            ),
            Text(
              'Painter: ${painter?.runtimeType ?? '—'} • ${ok ? 'đã ánh xạ' : 'CHƯA ÁNH XẠ / SAI LOẠI'}',
              key: const ValueKey('dev-eq-painter'),
              style: TextStyle(
                color: ok ? Pal.moss : Pal.blood,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (d.blurb.isNotEmpty)
              Text(
                d.blurb,
                style: const TextStyle(color: Pal.muted, fontSize: 10),
              ),
            const SizedBox(height: 4),
            _stats(d),
            const SizedBox(height: 4),
            const Text(
              'BUFF / DEBUFF',
              style: TextStyle(
                color: Pal.gold,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (item.effects.isEmpty)
              const Text(
                'Không có hiệu ứng.',
                style: TextStyle(color: Pal.muted, fontSize: 10.5),
              ),
            for (final e in item.effects) EffectLine(e),
            const SizedBox(height: 4),
            Text(
              'Trên lính thử: Sát thương ${before.damageRange}→${after.damageRange} • '
              'Giáp ${(before.reduction * 100).round()}%→${(after.reduction * 100).round()}% • '
              'Tải ${after.gearWeight.toStringAsFixed(1)} kg',
              key: const ValueKey('dev-eq-preview-stats'),
              style: const TextStyle(color: Pal.dim, fontSize: 10.5),
            ),
            if (_variants) _variantStrip(d),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: [
                _chip(
                  'dev-eq-compare',
                  _compareMode ? 'Chọn món thứ hai…' : 'So sánh',
                  _compareMode,
                  () => setState(() => _compareMode = !_compareMode),
                ),
                if (cmp != null)
                  _chip(
                    'dev-eq-compare-clear',
                    'Bỏ so sánh',
                    false,
                    () => setState(() => _compareId = null),
                  ),
              ],
            ),
            if (cmp != null) _compareBox(d, cmp),
          ],
        ),
      ),
    );
  }

  Widget _stats(ItemDef d) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(_statLine(d), style: const TextStyle(color: Pal.text, fontSize: 11)),
    ],
  );

  String _statLine(ItemDef d) => [
    if (d.damageMax > 0) 'Sát thương ${d.damageRange}',
    if (d.defense > 0) 'Phòng thủ ${d.defense}',
    if (d.weaponType != null) 'Chu kỳ ${d.interval.toStringAsFixed(1)}s',
    if (d.weaponType != null) 'Tầm ${d.range.toStringAsFixed(1)}m',
    if (d.totalArmorPen > 0) 'Xuyên ${d.totalArmorPen}',
    for (final e in d.traits) e.describe(),
    if (d.reqStr > 0) 'STR ${d.reqStr}+',
    'Cấp ${d.reqLevel}+',
    if (d.twoHanded) 'Hai tay',
  ].join(' • ');

  Widget _variantStrip(ItemDef d) {
    final refs = [
      for (var i = 1; i <= 8; i++)
        makeRef(
          d.id,
          EquipmentGenerator.variantIdFromEntropy(
            i * 7919 + d.id.hashCode.abs() % 1000,
          ),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      key: const ValueKey('dev-eq-variant-strip'),
      children: [
        const SizedBox(height: 4),
        const Text(
          'BIẾN THỂ (tạm, không lưu)',
          style: TextStyle(
            color: Pal.gold,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            InkWell(
              key: const ValueKey('dev-eq-variant-std'),
              onTap: () => setState(() => _variantRef = null),
              child: Container(
                padding: const EdgeInsets.all(4),
                color: _variantRef == null ? Pal.goldDeep : Pal.bgDeep,
                child: const Text(
                  'Chuẩn',
                  style: TextStyle(fontSize: 10, color: Pal.text),
                ),
              ),
            ),
            for (var i = 0; i < refs.length; i++)
              InkWell(
                key: ValueKey('dev-eq-variant-$i'),
                onTap: () => setState(() => _variantRef = refs[i]),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  color: _variantRef == refs[i] ? Pal.goldDeep : Pal.bgDeep,
                  child: Text(
                    '#${i + 1} • ${EquipmentItem.tryParse(refs[i])!.effects.length} hiệu ứng',
                    style: const TextStyle(fontSize: 10, color: Pal.text),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _compareBox(ItemDef a, ItemDef b) {
    Widget col(ItemDef d) => Expanded(
      child: Column(
        children: [
          ItemGlyph(d.id, size: 56),
          Text(
            d.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: Pal.text),
          ),
          Text(
            _statLine(d),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9, color: Pal.dim),
          ),
          Text(
            formatKg(d.weight),
            style: const TextStyle(fontSize: 9.5, color: Pal.dim),
          ),
          for (final e in d.traits) EffectLine(e),
        ],
      ),
    );
    return Padding(
      key: const ValueKey('dev-eq-compare-box'),
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [col(a), col(b)],
      ),
    );
  }
}
