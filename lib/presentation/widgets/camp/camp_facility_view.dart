import 'package:flutter/material.dart';

import '../../../application/game_controller.dart';
import '../../../core/theme.dart';
import '../../../domain/catalog.dart';
import '../../../domain/models.dart';
import '../../../domain/rules.dart';
import '../buildings/buildings.dart';
import '../common.dart';

/// Một công trình đã xây trong trại: hình, tên, sức chứa và vùng thả binh sĩ.
class CampFacilityView extends StatelessWidget {
  const CampFacilityView({
    super.key,
    required this.facility,
    required this.state,
    required this.controller,
  });

  final Facility facility;
  final GameState state;
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final def = facilityDefs[facility.type]!;
    final takes = GameRules.takesAssignment(facility.type);
    return DragTarget<int>(
      onWillAcceptWithDetails: (_) => takes,
      onAcceptWithDetails: (d) =>
          toast(context, controller.assignToFacility(d.data, facility.id)),
      builder: (context, candidates, _) {
        final hot = candidates.isNotEmpty;
        return Tooltip(
          message: '${def.name}\n${def.blurb}',
          child: Stack(
            children: [
              Positioned.fill(child: FacilityArt(facility.type)),
              if (hot)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: Pal.gold, width: 3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Pal.bg.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      takes
                          ? '${def.name}  ${facility.assigned.length}/${Facility.capacity}'
                          : (facility.type == FacilityType.barracks
                                ? '${def.name} • Cấp ${state.buildings[Building.barracks]}'
                                : def.name),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Pal.text,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Bếp lửa giữa trại: chỉ là hình trang trí, không phải công trình (không nhận gán, không chiếm ô).
class CampCampfireDecor extends StatelessWidget {
  const CampCampfireDecor({super.key});

  @override
  Widget build(BuildContext context) =>
      const IgnorePointer(child: CampfireArt());
}
