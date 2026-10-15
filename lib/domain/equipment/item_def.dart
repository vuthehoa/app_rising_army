import '../item_grade.dart';
import '../models.dart';
import '../progression.dart';
import 'equipment_effect.dart';
import 'equipment_stats.dart';
import 'equipment_types.dart';
import 'gear_pricing.dart';

/// Định nghĩa (thiết kế) của một vật phẩm trang bị: dữ liệu tĩnh, ổn định, tra theo [id].
/// Bản sao cụ thể mà người chơi sở hữu (có biến thể/hiệu ứng riêng) là `EquipmentItem`.
///
/// [id] là mã thiết kế ổn định, không phụ thuộc thứ tự danh sách, và không chứa ký tự `~`.
class ItemDef {
  const ItemDef({
    required this.id,
    required this.name,
    required this.slot,
    required this.tier,
    required int price,
    this.weaponType,
    this.armorPen = 0,
    this.intervalMod = 0,
    this.requiredLevel,
    this.damageMin = 0,
    this.damageMax = 0,
    this.defense = 0,
    this.reqStr = 0,
    this.weight = 0,
    this.hands = HandUse.oneHand,
    this.weaponKind,
    this.shape,
    this.armorClass,
    this.traits = const [],
    this.blurb = '',
  }) : _rawPrice = price;

  final String id;
  final String name;
  final Slot slot;
  final int tier;

  /// Giá gốc do dữ liệu thiết kế gán (phản ánh độ mạnh/độ hiếm). KHÔNG dùng trực tiếp để mua bán:
  /// mọi nơi đọc [price].
  final int _rawPrice;

  /// Giá mua chuẩn (vàng) trước hệ số của người bán. Nguồn duy nhất: [GearPricing.priceOf].
  int get price => GearPricing.priceOf(tier, _rawPrice);

  /// Nhóm vũ khí (chỉ với [Slot.weapon]); quyết định tầm đánh, nhịp đánh, chính xác, chí mạng, xuyên giáp
  /// cơ bản qua [weaponProfiles]. Không có điều kiện nghề.
  final WeaponType? weaponType;

  /// Xuyên giáp riêng của món này, cộng thêm xuyên giáp của nhóm.
  final int armorPen;

  /// Chênh lệch thời gian giữa hai đòn so với nhóm (món nặng hơn thì dương).
  final double intervalMod;

  /// Cấp binh sĩ tối thiểu; null = suy ra từ phẩm cấp ([requiredHeroLevel]). Độc lập với phẩm cấp.
  final int? requiredLevel;

  WeaponProfile? get profile =>
      weaponType == null ? null : weaponProfiles[weaponType];

  /// Sát thương vũ khí là KHOẢNG nguyên [damageMin]..[damageMax] (cả hai 0 với giáp/khiên): mỗi đòn trúng rút
  /// một số nguyên đều trong khoảng này (xem `simulateBattle`). Hiển thị `min–max` bằng [damageRange].
  final int damageMin;
  final int damageMax;
  final int defense;

  /// Chuỗi hiển thị khoảng sát thương, ví dụ `5–8`; rỗng nếu không phải vũ khí.
  String get damageRange => damageMax <= 0 ? '' : '$damageMin–$damageMax';

  /// Sát thương trung bình (để so sánh sức mạnh, không dùng để hiển thị thay khoảng).
  double get damageAvg => (damageMin + damageMax) / 2;
  final int reqStr;

  /// Cân nặng cơ bản (kg). Tổng cân nặng loadout so với sức chứa theo STR quyết định tải trọng
  /// (xem `EquipmentRules.encumbrance`).
  final double weight;

  /// Một tay hay hai tay. Vũ khí hai tay chiếm cả ô vũ khí và ô tay phụ (khiên).
  final HandUse hands;

  /// Hình thức vũ khí / hình dạng khiên / lớp giáp – phục vụ hiển thị, lọc và chọn hình vẽ.
  final WeaponKind? weaponKind;
  final ShieldShape? shape;
  final ArmorClass? armorClass;

  /// Hiệu ứng cố định của thiết kế (mọi bản sao đều có), cộng thêm hiệu ứng của biến thể.
  final List<EquipmentEffect> traits;

  /// Mô tả ngắn (một dòng) cho bảng chi tiết.
  final String blurb;

  bool get twoHanded => hands == HandUse.twoHand;

  /// Phẩm cấp trang bị: chính là [tier].
  int get grade => tier;

  EquipmentRarity get rarity => EquipmentRarity.ofGrade(tier);

  /// Cấp anh hùng tối thiểu để dùng: `hero.level >= reqLevel` (Level 1: không có điều kiện bổ sung).
  /// Suy ra từ phẩm cấp, không lưu riêng, nên không thể lệch khỏi quy tắc.
  int get reqLevel => requiredLevel ?? requiredHeroLevel(tier);

  /// Thời gian giữa hai đòn (giây) / tầm đánh / xuyên giáp tổng của món vũ khí (0 nếu không phải vũ khí).
  double get interval => (profile?.interval ?? 0) + intervalMod;
  double get range => profile?.range ?? 0;
  int get totalArmorPen => (profile?.armorPen ?? 0) + armorPen;

  EquipmentStats get stats => EquipmentStats(
    damageMin: damageMin,
    damageMax: damageMax,
    defense: defense,
    armorPen: armorPen,
    intervalMod: intervalMod,
    reqStr: reqStr,
  );
}
