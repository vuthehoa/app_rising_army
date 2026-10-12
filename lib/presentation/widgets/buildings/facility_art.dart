import 'package:app_rising_army/domain/models.dart';
import 'package:flutter/material.dart';

import 'archery_range_art.dart';
import 'campfire_art.dart';
import 'endurance_yard_art.dart';
import 'infirmary_art.dart';
import 'melee_yard_art.dart';

/// Chọn đúng widget hình công trình theo [FacilityType].
class FacilityArt extends StatelessWidget {
  const FacilityArt(this.type, {super.key, this.size});

  final FacilityType type;
  final double? size;

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case FacilityType.meleeYard:
        return MeleeYardArt(size: size);
      case FacilityType.archeryRange:
        return ArcheryRangeArt(size: size);
      case FacilityType.enduranceYard:
        return EnduranceYardArt(size: size);
      case FacilityType.infirmary:
        return InfirmaryArt(size: size);
      case FacilityType.campfire:
        return CampfireArt(size: size);
    }
  }
}
