import 'package:flutter/material.dart';

enum AvatarGender { male, female }

enum HairStyle {
  // Tóc cơ bản
  short,
  medium,
  long,

  // Tóc buộc
  tied,
  ponytail,
  twinTails,

  // Tóc búi cổ trang
  highBun,
  lowBun,
  doubleBun,
  topknot,

  // Tóc cách điệu
  halfUp,
  braided,
}

enum PortraitOutfit {
  commoner, // Áo vải thường
  official, // Quan phục
  lightArmor, // Giáp nhẹ
  royal, // Triều phục
}

enum PortraitHeadwear {
  none, // Không đội mũ
  cloth, // Khăn vấn
  official, // Mũ quan
  helmet, // Mũ trụ
}

extension HairStylePresentation on HairStyle {
  String get label => switch (this) {
    HairStyle.short => 'Tóc ngắn',
    HairStyle.medium => 'Tóc ngang vai',
    HairStyle.long => 'Tóc dài',

    HairStyle.tied => 'Tóc buộc',
    HairStyle.ponytail => 'Đuôi ngựa',
    HairStyle.twinTails => 'Song đuôi',

    HairStyle.highBun => 'Búi cao',
    HairStyle.lowBun => 'Búi thấp',
    HairStyle.doubleBun => 'Song búi',
    HairStyle.topknot => 'Búi võ sĩ',

    HairStyle.halfUp => 'Bán búi',
    HairStyle.braided => 'Tóc tết',
  };

  String get description => switch (this) {
    HairStyle.short => 'Ngắn gọn, năng động',
    HairStyle.medium => 'Dài ngang vai',
    HairStyle.long => 'Buông dài tự nhiên',

    HairStyle.tied => 'Buộc gọn phía sau',
    HairStyle.ponytail => 'Đuôi tóc buộc cao',
    HairStyle.twinTails => 'Hai đuôi tóc hai bên',

    HairStyle.highBun => 'Búi tóc trên đỉnh đầu',
    HairStyle.lowBun => 'Búi tóc sau gáy',
    HairStyle.doubleBun => 'Hai búi tóc hai bên',
    HairStyle.topknot => 'Búi tóc kiểu võ tướng',

    HairStyle.halfUp => 'Nửa trên búi gọn',
    HairStyle.braided => 'Tóc tết phía sau',
  };

  IconData get icon => switch (this) {
    HairStyle.short => Icons.face_rounded,
    HairStyle.medium => Icons.face_3_rounded,
    HairStyle.long => Icons.person_rounded,

    HairStyle.tied => Icons.person_outline_rounded,
    HairStyle.ponytail => Icons.sports_martial_arts_rounded,
    HairStyle.twinTails => Icons.waves_rounded,

    HairStyle.highBun => Icons.auto_awesome_rounded,
    HairStyle.lowBun => Icons.circle,
    HairStyle.doubleBun => Icons.bubble_chart_rounded,
    HairStyle.topknot => Icons.military_tech_rounded,

    HairStyle.halfUp => Icons.face_retouching_natural_rounded,
    HairStyle.braided => Icons.all_inclusive_rounded,
  };
}

class NewGameData {
  const NewGameData({
    required this.characterName,
    required this.legionName,
    required this.gender,
    required this.hairStyle,
    required this.hairColor,
    required this.eyeColor,
    required this.skinColor,
    required this.avatarSeed,
  });

  final String characterName;
  final String legionName;
  final AvatarGender gender;
  final HairStyle hairStyle;
  final Color hairColor;
  final Color eyeColor;
  final Color skinColor;
  final int avatarSeed;
}
