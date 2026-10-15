import '../../../domain/catalog.dart';
import '../../../domain/models.dart';
import '../../../domain/progression.dart';

/// Dòng tóm tắt một thiết kế trang bị, dùng chung cho Chợ, Lò rèn, Kho: sát thương vũ khí là KHOẢNG `min–max`,
/// buff/debuff cố định của thiết kế chỉ gồm bốn chỉ số gốc và là số nguyên.
String itemSummaryLine(ItemDef it) => [
  if (it.damageMax > 0) 'Sát thương ${it.damageRange}',
  if (it.defense > 0) 'Giáp +${it.defense}',
  for (final e in it.traits) e.describe(),
  if (it.weaponType != null)
    '${weaponProfiles[it.weaponType]!.name} • ${it.interval.toStringAsFixed(1)}s • ${it.range.toStringAsFixed(1)}m',
  if (it.totalArmorPen > 0) 'Xuyên giáp ${it.totalArmorPen}',
  if (it.reqLevel > 1) 'Cấp ${it.reqLevel}+',
  if (it.reqStr > 0) '${statNames[Stat.str]} ${it.reqStr}+',
].join(' • ');
