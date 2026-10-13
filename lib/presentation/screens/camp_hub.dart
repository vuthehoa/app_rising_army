import 'package:app_rising_army/presentation/widgets/buildings/camp_scene/camp_ground_painter.dart';
import 'package:flutter/material.dart';

import '../../application/game_controller.dart';
import '../widgets/camp/camp_build_menu.dart';
import '../widgets/camp/camp_drag_handoff.dart';
import '../widgets/camp/camp_overlays.dart';
import '../widgets/camp/camp_placement_layer.dart';
import '../widgets/camp/camp_soldier_drop_ground.dart';
import '../widgets/camp/camp_viewport.dart';
import '../widgets/common.dart';
import '../widgets/game_hud.dart';

/// Trại: cảnh nhìn từ trên xuống, binh sĩ đi lại, kéo-thả binh sĩ vào công trình có sức chứa 3,
/// nút `build` / `map` ở dưới (VERIFIED theo ảnh/clip chính thức).
///
/// Thế giới trại (nền, công trình, lính, ô đặt) nằm trong [CampViewport] để zoom bằng hai ngón tay; HUD và nút
/// ở ngoài nên không bị zoom.
///
/// Widget gốc chỉ ghép các lớp ([CampFacilitiesLayer], [CampSoldiersLayer], [CampPlacementLayer],
/// [CampHud], [CampActionBar]) và điều phối callback tới [GameController]. Trạng thái xây dựng đang
/// chờ đặt nằm ở controller (`placing`) để menu Build và BuildingsScreen dùng chung một luồng.
class CampHub extends StatefulWidget {
  const CampHub({super.key});

  @override
  State<CampHub> createState() => _CampHubState();
}

class _CampHubState extends State<CampHub> {
  /// Hộp thế giới Trại (trong phép zoom): đổi toạ độ màn hình → toạ độ Trại cho thao tác kéo từ menu Xây.
  final GlobalKey _worldKey = GlobalKey(debugLabel: 'camp-world');

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final s = c.state!;
    final d = Dims(context);
    return Padding(
      // Trại chiếm gần hết vùng khả dụng (lề mỏng, không còn thanh bên); LayoutBuilder bên dưới tính theo
      // constraints thực tế nên thích ứng mọi thiết bị.
      padding: EdgeInsets.all(d.compact ? 3 : 5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LayoutBuilder(
          builder: (context, box) {
            final viewport = Size(box.maxWidth, box.maxHeight);
            final world = CampMetrics.worldFor(viewport);
            final origin = CampMetrics.originFor(viewport, world);
            final metrics = CampMetrics(world);
            final placing = c.placing;
            return Stack(
              children: [
                // THẾ GIỚI trại: khung tỉ lệ cố định đặt giữa vùng nhìn, nằm trong CampViewport (zoom hai ngón tay).
                Positioned.fill(
                  child: CampViewport(
                    size: viewport,
                    resetToken: s.seed,
                    child: ColoredBox(
                      color: const Color(0xFF879D46),
                      child: Stack(
                        children: [
                          Positioned(
                            left: origin.dx,
                            top: origin.dy,
                            width: world.width,
                            height: world.height,
                            child: Stack(
                              key: _worldKey,
                              children: [
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: CampGroundPainter(),
                                  ),
                                ),
                                // Đang đặt: các lớp bên dưới không nhận chạm để kéo-thả không kích hoạt gì khác.
                                Positioned.fill(
                                  child: IgnorePointer(
                                    ignoring: placing != null,
                                    child: Stack(
                                      children: [
                                        // Nền nhận lính kéo thả tự do (dưới công trình).
                                        Positioned.fill(
                                          child: CampSoldierDropGround(
                                            onDrop: (id, x, y) {
                                              final r = c.moveSoldier(id, x, y);
                                              if (!r.ok) toast(context, r);
                                            },
                                          ),
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
                                      ],
                                    ),
                                  ),
                                ),
                                if (placing != null)
                                  Positioned.fill(
                                    child: CampPlacementLayer(
                                      key: ValueKey(
                                        'placement-$placing-${c.movingId}',
                                      ),
                                      state: s,
                                      metrics: metrics,
                                      placing: placing,
                                      moving: c.movingFacility,
                                      preview: c.movePreview,
                                      onDrop: (x, y) => toast(
                                        context,
                                        c.movingId != null
                                            ? c.confirmMoveAt(x, y)
                                            : c.confirmPlacementAt(x, y),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // GIAO DIỆN cố định trên màn hình (không zoom): huy hiệu, HUD, hướng dẫn, thanh nút.
                if (placing != null)
                  Positioned.fill(
                    child: CampPlacementHint(
                      placing: placing,
                      moving: c.movingId != null,
                    ),
                  ),
                Positioned.fill(child: CampHud(state: s)),
                // HUD nổi: Top HUD trên hàng rào phía trên, Resource HUD bám hàng rào bên trái.
                GameHudOverlay(
                  insets: HudInsets.camp(
                    world,
                    origin: origin,
                    viewport: viewport,
                  ),
                ),
                CampActionBar(
                  placing: placing != null,
                  onBuild: () => _openBuild(context, c),
                  onCancel: c.cancelPlacement,
                  onNextDay: () {},
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openBuild(BuildContext context, GameController c) async {
    final choice = await showCampBuildMenu(
      context,
      c.state!,
      drag: CampBuildDrag(
        worldKey: _worldKey,
        controller: c,
        onResult: (r) {
          if (mounted) toast(context, r);
        },
      ),
    );
    // Lối dự phòng (không có ngón tay để chuyển giao): chọn xong thì vào chế độ đặt như cũ.
    if (choice == null || !context.mounted) return;
    toast(context, c.chooseCampBuilding(choice));
  }
}
