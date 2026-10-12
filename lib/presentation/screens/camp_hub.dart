import 'package:flutter/material.dart';

import '../../application/game_controller.dart';
import '../widgets/art.dart';
import '../widgets/camp/camp_build_menu.dart';
import '../widgets/camp/camp_overlays.dart';
import '../widgets/common.dart';

/// Trại: cảnh nhìn từ trên xuống, binh sĩ đi lại, kéo-thả binh sĩ vào công trình có sức chứa 3,
/// nút `build` / `map` ở dưới (VERIFIED theo ảnh/clip chính thức).
///
/// Widget gốc chỉ ghép các lớp ([CampFacilitiesLayer], [CampSoldiersLayer], [CampPlacementOverlay],
/// [CampHud], [CampActionBar]) và điều phối callback tới [GameController]. Trạng thái xây dựng đang
/// chờ đặt nằm ở controller (`placing`) để menu Build và BuildingsScreen dùng chung một luồng.
class CampHub extends StatelessWidget {
  const CampHub({super.key});

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final s = c.state!;
    final d = Dims(context);
    return Padding(
      padding: EdgeInsets.all(d.pad),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LayoutBuilder(
          builder: (context, box) {
            final metrics = CampMetrics(Size(box.maxWidth, box.maxHeight));
            final placing = c.placing;
            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: CampGroundPainter()),
                ),
                Positioned.fill(
                  child: CampFacilitiesLayer(
                    state: s,
                    controller: c,
                    metrics: metrics,
                  ),
                ),
                Positioned.fill(
                  child: CampSoldiersLayer(
                    state: s,
                    controller: c,
                    metrics: metrics,
                  ),
                ),
                if (placing != null)
                  Positioned.fill(
                    child: CampPlacementOverlay(
                      state: s,
                      metrics: metrics,
                      placing: placing,
                      onPlace: (index) =>
                          toast(context, c.confirmPlacement(index)),
                      onCancel: c.cancelPlacement,
                    ),
                  ),
                Positioned.fill(child: CampHud(state: s)),
                CampActionBar(
                  placing: placing != null,
                  onBuild: () => _openBuild(context, c),
                  onCancel: c.cancelPlacement,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openBuild(BuildContext context, GameController c) async {
    final choice = await showCampBuildMenu(context, c.state!);
    if (choice == null || !context.mounted) return;
    toast(context, c.chooseCampBuilding(choice));
  }
}
