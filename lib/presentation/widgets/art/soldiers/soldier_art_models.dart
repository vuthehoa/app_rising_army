import 'package:flutter/material.dart';

import '../../../../domain/catalog.dart';
import '../../../../domain/models.dart';

/// Dữ liệu trình bày dùng chung cho artwork binh sĩ (màu da, tóc, áo, bậc giáp). Chỉ phục vụ việc vẽ:
/// không tham gia tính chỉ số hay luật chiến đấu.
const soldierSkins = [
  Color(0xFFF1C9A5),
  Color(0xFFD9A57B),
  Color(0xFFB57F55),
  Color(0xFF8D5A3A),
];

const soldierHairs = [
  Color(0xFF3B2A1E),
  Color(0xFF7A4B24),
  Color(0xFFC9A24B),
  Color(0xFF1E1E1E),
  Color(0xFF8A8A8A),
];

const soldierTunics = {
  Role.spearman: Color(0xFF9A4F3C),
  Role.archer: Color(0xFF55804F),
  Role.cavalry: Color(0xFF41648F),
};

/// Màu kim loại/da theo bậc trang bị 0..3 (0 = không có).
const soldierGearTones = [
  Color(0xFF6F6454),
  Color(0xFF8A5A33),
  Color(0xFF9FA7AD),
  Color(0xFFD7DCE0),
];

/// Bậc giáp 0..3 suy từ chỉ số phòng thủ của vật phẩm (0 nếu không mặc).
int soldierArmorTier(String? id) => id == null
    ? 0
    : (itemDefs[id]?.defense ?? 0) >= 9
    ? 3
    : ((itemDefs[id]?.defense ?? 0) >= 6 ? 2 : 1);

/// Bậc khiên 1..3 (0 nếu không có), theo phẩm cấp vật phẩm.
int soldierShieldTier(String? id) => id == null
    ? 0
    : ((itemDefs[id]?.tier ?? 1) >= 4
          ? 3
          : ((itemDefs[id]?.tier ?? 1) >= 2 ? 2 : 1));
