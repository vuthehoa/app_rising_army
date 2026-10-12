import 'package:flutter/material.dart';

/// Bảng màu dùng chung cho avatar nhân vật.
abstract final class AvatarColorPalette {
  AvatarColorPalette._();

  // ---------------------------------------------------------------------------
  // MÀU TÓC — 24 MÀU
  // ---------------------------------------------------------------------------

  static const List<Color> hairColors = [
    // Tóc tự nhiên
    Color(0xFF211B19),
    Color(0xFF3B2923),
    Color(0xFF503629),
    Color(0xFF70452E),
    Color(0xFF895D3B),
    Color(0xFFAA774B),
    Color(0xFFC6A16B),
    Color(0xFFE0C08A),

    // Tóc lạnh
    Color(0xFFB8B8BE),
    Color(0xFF85858F),
    Color(0xFF5E626B),
    Color(0xFF3B4658),

    // Tóc đỏ và tím
    Color(0xFF8D2525),
    Color(0xFFB83A3A),
    Color(0xFFD45B43),
    Color(0xFF70405F),
    Color(0xFF8A5AA5),
    Color(0xFFB58AC8),

    // Tóc xanh fantasy
    Color(0xFF245B50),
    Color(0xFF39836B),
    Color(0xFF2855A6),
    Color(0xFF76A8E8),

    // Tóc nổi bật
    Color(0xFFE5A1A8),
    Color(0xFFEF8A45),
  ];

  static const List<String> hairNames = [
    'Đen tuyền',
    'Đen nâu',
    'Nâu đậm',
    'Nâu hạt dẻ',
    'Nâu caramel',
    'Nâu mật ong',
    'Nâu vàng',
    'Vàng cát',
    'Bạc',
    'Xám khói',
    'Xám đậm',
    'Xanh đen',
    'Đỏ rượu',
    'Đỏ ruby',
    'Đỏ đồng',
    'Tím mận',
    'Tím',
    'Tím nhạt',
    'Xanh ngọc đậm',
    'Xanh ngọc',
    'Xanh lam',
    'Xanh băng',
    'Hồng phấn',
    'Cam',
  ];

  // ---------------------------------------------------------------------------
  // MÀU MẮT — 12 MÀU
  // ---------------------------------------------------------------------------

  static const List<Color> eyeColors = [
    Color(0xFF382218),
    Color(0xFF553522),
    Color(0xFF79513A),
    Color(0xFF9A7045),
    Color(0xFF285C43),
    Color(0xFF6B9B63),
    Color(0xFF477FA5),
    Color(0xFF285A8E),
    Color(0xFF79B7D4),
    Color(0xFF777777),
    Color(0xFFABB2BD),
    Color(0xFF8A5AA5),
  ];

  static const List<String> eyeNames = [
    'Nâu đen',
    'Nâu đậm',
    'Nâu hạt dẻ',
    'Hổ phách',
    'Xanh lục đậm',
    'Xanh lá',
    'Xanh lam',
    'Xanh lam đậm',
    'Xanh băng',
    'Xám',
    'Xám bạc',
    'Tím',
  ];

  // ---------------------------------------------------------------------------
  // MÀU DA — 12 MÀU
  // ---------------------------------------------------------------------------

  static const List<Color> skinColors = [
    Color(0xFFFFE8D6),
    Color(0xFFFFDFC4),
    Color(0xFFF1C9A5),
    Color(0xFFE8B995),
    Color(0xFFDCA77D),
    Color(0xFFD39A70),
    Color(0xFFC6865D),
    Color(0xFFB87952),
    Color(0xFFA66B4B),
    Color(0xFF985F43),
    Color(0xFF805039),
    Color(0xFF704631),
  ];

  static const List<String> skinNames = [
    'Trắng sứ',
    'Trắng hồng',
    'Sáng',
    'Hồng đào',
    'Trung bình sáng',
    'Vàng ấm',
    'Nâu mật ong',
    'Nâu vàng',
    'Nâu ấm',
    'Nâu',
    'Nâu đậm',
    'Nâu sẫm',
  ];
}
