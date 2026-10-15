import 'dart:math' as math;

import 'package:app_rising_army/presentation/widgets/buildings/camp_scene/smithy_scene_art.dart';
import 'package:app_rising_army/presentation/widgets/buildings/camp_scene/tavern_scene_art.dart';
import 'package:app_rising_army/presentation/widgets/buildings/market_placeholder_art.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../domain/catalog.dart';
import '../../domain/models.dart';
import '../../domain/rules.dart';
import '../widgets/common.dart';
import '../widgets/mission_kit.dart';
import '../widgets/game_hud.dart';
import 'tavern_screen.dart';
import 'vendor_screen.dart';

/// Thành phố trung cổ:
/// - Bên trái: tiệm rèn, quán rượu, chợ.
/// - Bên phải: nhiệm vụ vàng, nhiệm vụ đỏ và nút điều hướng.
class CityScreen extends StatelessWidget {
  const CityScreen({super.key, required this.cityId, this.arrival});

  final String cityId;
  final ExpeditionResult? arrival;

  @override
  Widget build(BuildContext context) {
    final controller = ControllerScope.of(context);
    final state = controller.state!;
    final city = locationById(cityId)!;
    final vendors = vendorsIn(cityId);
    final dims = Dims(context);

    return Scaffold(
      backgroundColor: Pal.bg,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(dims.pad),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 720;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _CityBuildings(
                          cityName: city.name,
                          vendors: vendors,
                          state: state,
                        ),
                      ),
                      SizedBox(width: dims.gap),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (arrival != null) ...[
                              _ArrivalPanel(
                                arrival: arrival!,
                                compact: compact,
                              ),
                              SizedBox(height: dims.gap),
                            ],

                            Expanded(
                              child: _QuestPanel(
                                cityId: cityId,
                                compact: compact,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          // HUD nổi: không chiếm chỗ trong layout, chỉ nút Menu nhận chạm.
          const SafeArea(
            child: Stack(
              children: [
                GameHudOverlay(
                  insets: HudInsets(topBarTop: 4, resourceTop: 48),
                  alignTopBar: Alignment.topRight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// KHU THÀNH PHỐ BÊN TRÁI
// ================================================================

class _CityBuildings extends StatelessWidget {
  const _CityBuildings({
    required this.cityName,
    required this.vendors,
    required this.state,
  });

  final String cityName;
  final List<VendorDef> vendors;
  final GameState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF64834A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF493B29), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            offset: Offset(2, 3),
            blurRadius: 5,
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Nền thành phố: cỏ, đường đá, nhà dân và cây cối.
              Positioned.fill(
                child: CustomPaint(painter: _CityGroundPainter()),
              ),

              // Tên thành phố.
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: Center(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: w * 0.72),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xF2EBD9AE),
                      border: Border.all(
                        color: const Color(0xFF755333),
                        width: 1.2,
                      ),
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x55000000),
                          offset: Offset(1, 2),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    child: Text(
                      cityName.toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: serif,
                        color: Color(0xFF49311E),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),

              // ==========================================
              // VỊ TRÍ 1: TIỆM RÈN - PHÍA TRÊN, CHÍNH GIỮA
              // ==========================================
              Positioned(
                left: w * 0.32,
                top: h * 0.19,
                width: w * 0.36,
                height: h * 0.29,
                child: _CityLocationTap(
                  label:
                      'Tiệm rèn: ${_vendorDescription(CityLocationKind.smithy)}',
                  name: 'Tiệm rèn',
                  enabled: _vendorEnabled(CityLocationKind.smithy),
                  onTap: () => _openVendor(context, CityLocationKind.smithy),
                  child: SmithySceneArt(),
                ),

                //  _BuildingCard(
                //   title: 'TIỆM RÈN',
                //   subtitle: _vendorDescription(CityLocationKind.smithy),
                //   icon: Icons.hardware,
                //   accent: const Color(0xFFB66B43),
                //   enabled: _vendorExists(CityLocationKind.smithy),
                //   onTap: () => _openVendor(context, CityLocationKind.smithy),
                //   child: const _BuildingArtSlot(
                //     child: _FallbackBuildingArt(
                //       icon: Icons.hardware,
                //       label: 'Lò rèn',
                //     ),
                //   ),
                // ),
              ),

              // ==========================================
              // VỊ TRÍ 2: QUÁN RƯỢU - BÊN TRÁI, PHÍA DƯỚI
              // ==========================================
              Positioned(
                left: w * 0.035,
                top: h * 0.57,
                width: w * 0.36,
                height: h * 0.30,
                child: _CityLocationTap(
                  label:
                      'Quán rượu: ${_vendorDescription(CityLocationKind.tavern)}',
                  name: 'Quán rượu',
                  enabled: _vendorEnabled(CityLocationKind.tavern),
                  onTap: () => _openVendor(context, CityLocationKind.tavern),
                  child: TavernSceneArt(),
                ),

                // _BuildingCard(
                //   title: 'QUÁN RƯỢU',
                //   subtitle: _vendorDescription(CityLocationKind.tavern),
                //   icon: Icons.local_bar,
                //   accent: const Color(0xFF8D5436),
                //   enabled: _vendorExists(CityLocationKind.tavern),
                //   onTap: () => _openVendor(context, CityLocationKind.tavern),
                //   child: const _BuildingArtSlot(
                //     child: _FallbackBuildingArt(
                //       icon: Icons.local_bar,
                //       label: 'Quán rượu',
                //     ),
                //   ),
                // ),
              ),

              // ==========================================
              // VỊ TRÍ 3: CHỢ - BÊN PHẢI, NỬA TRÊN
              // ==========================================
              Positioned(
                right: w * 0.035,
                top: h * 0.35,
                width: w * 0.36,
                height: h * 0.30,
                child: _CityLocationTap(
                  label: 'Chợ: ${_vendorDescription(CityLocationKind.market)}',
                  name: 'Chợ',
                  enabled: _vendorEnabled(CityLocationKind.market),
                  onTap: () => _openVendor(context, CityLocationKind.market),
                  child: MarketPlaceholderArt(),
                ),

                // _BuildingCard(
                //   title: 'CHỢ',
                //   subtitle: _vendorDescription(CityLocationKind.market),
                //   icon: Icons.storefront,
                //   accent: const Color(0xFF8C7444),
                //   enabled: _vendorExists(CityLocationKind.market),
                //   onTap: () => _openVendor(context, CityLocationKind.market),
                //   child: const _BuildingArtSlot(child: _MarketPlaceholderArt()),
                // ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _vendorExists(CityLocationKind kind) {
    return vendors.any((vendor) => vendor.location == kind);
  }

  /// Người chơi đang ở đúng thành phố của các gian hàng này.
  bool get here => vendors.isNotEmpty && state.visiting == vendors.first.cityId;

  /// Khả dụng thực tế: có gian hàng loại [kind] ở thành phố này, người chơi đang ở đây và gian hàng đã mở.
  bool _vendorEnabled(CityLocationKind kind) {
    final matches = vendors.where((vendor) => vendor.location == kind);
    return here &&
        _vendorExists(kind) &&
        GameRules.vendorOpen(state, matches.first);
  }

  String _vendorDescription(CityLocationKind kind) {
    final matches = vendors.where((vendor) => vendor.location == kind);

    if (matches.isEmpty) {
      return 'Chưa có gian hàng';
    }

    return matches.first.name;
  }

  void _openVendor(BuildContext context, CityLocationKind kind) {
    final matches = vendors.where((vendor) => vendor.location == kind);

    if (!here) {
      toast(
        context,
        const ActionResult.fail('Bạn đã rời thành phố. Hãy hành quân trở lại.'),
      );
      return;
    }

    if (matches.isEmpty) {
      toast(
        context,
        const ActionResult.fail(
          'Gian hàng này chưa được thiết lập trong thành phố.',
        ),
      );
      return;
    }

    final vendor = matches.first;

    if (!GameRules.vendorOpen(state, vendor)) {
      toast(context, ActionResult.fail('${vendor.name} chưa mở cửa với bạn.'));
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => vendor.kind == VendorKind.tavern
            ? TavernScreen(vendorId: vendor.id)
            : VendorScreen(vendorId: vendor.id),
      ),
    );
  }
}

/// Vùng chạm trong suốt phủ lên hình công trình: không đổi giao diện, chỉ thêm tương tác.
/// Việc kiểm tra khả dụng (đang ở thành phố, có gian hàng, đã mở cửa) nằm trong `_openVendor`.
class _CityLocationTap extends StatelessWidget {
  const _CityLocationTap({
    required this.label,
    required this.name,
    required this.enabled,
    required this.onTap,
    required this.child,
  });

  final String label;

  /// Tên ngắn hiện trên biển gỗ dưới công trình (chỉ để nhận diện; ngữ nghĩa vẫn lấy từ [label]).
  final String name;

  /// Chỉ ảnh hưởng ngữ nghĩa/con trỏ; khi không khả dụng, chạm vẫn gọi [onTap] để báo lý do và KHÔNG điều hướng.
  final bool enabled;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Không khả dụng: công trình mờ đi (chạm vẫn báo lý do như cũ).
              Positioned.fill(
                child: enabled
                    ? child
                    : ColorFiltered(
                        colorFilter: const ColorFilter.matrix(<double>[
                          0.45, 0.4, 0.15, 0, 0, //
                          0.45, 0.4, 0.15, 0, 0, //
                          0.45, 0.4, 0.15, 0, 0, //
                          0, 0, 0, 1, 0,
                        ]),
                        child: child,
                      ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: -4,
                child: ExcludeSemantics(
                  child: Center(
                    child: _SignPlate(name: name, enabled: enabled),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Biển gỗ nhỏ ghi tên địa điểm; có ổ khóa khi chưa dùng được.
class _SignPlate extends StatelessWidget {
  const _SignPlate({required this.name, required this.enabled});

  final String name;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('city-sign-$name'),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: enabled ? const Color(0xF2EBD9AE) : const Color(0xE6BDB59E),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF755333), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            offset: Offset(1, 2),
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!enabled) ...[
            const Icon(Icons.lock, size: 11, color: Color(0xFF49311E)),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                name,
                maxLines: 1,
                style: const TextStyle(
                  fontFamily: serif,
                  color: Color(0xFF49311E),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// NỀN THÀNH PHỐ TRUNG CỔ NHÌN TỪ TRÊN XUỐNG
// ============================================================

class _CityGroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Thảm cỏ xanh.
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF789653),
    );

    _drawGrass(canvas, size);
    _drawGardenPatches(canvas, size);
    _drawTrees(canvas, size);

    // 2. Đường đá chính chạy xuyên thành phố.
    _drawMainRoad(canvas, size);

    // 3. Các nhánh đường nối đến khu dân cư.
    _drawBranchRoad(
      canvas,
      Offset(w * 0.50, h * 0.50),
      Offset(w * 0.50, h * 0.43),
      w * 0.12,
    );

    _drawBranchRoad(
      canvas,
      Offset(w * 0.50, h * 0.69),
      Offset(w * 0.22, h * 0.69),
      w * 0.105,
    );

    _drawBranchRoad(
      canvas,
      Offset(w * 0.50, h * 0.45),
      Offset(w * 0.78, h * 0.46),
      w * 0.105,
    );

    // 4. Dãy nhà dân ở phía trên cùng.
    _drawResidentialDistrict(canvas, size);

    // 5. Viền đá nhỏ dọc theo đường.
    _drawRoadsideDetails(canvas, size);

    // 6. Các mảng cỏ, bụi hoa và sỏi trang trí cuối cùng.
    _drawGrassDetails(canvas, size);
  }

  void _drawMainRoad(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final road = Path()
      ..moveTo(w * 0.43, h * 0.30)
      ..lineTo(w * 0.57, h * 0.30)
      ..lineTo(w * 0.59, h * 0.39)
      ..lineTo(w * 0.55, h * 0.49)
      ..lineTo(w * 0.57, h * 0.60)
      ..lineTo(w * 0.54, h * 0.73)
      ..lineTo(w * 0.57, h)
      ..lineTo(w * 0.40, h)
      ..lineTo(w * 0.43, h * 0.73)
      ..lineTo(w * 0.45, h * 0.61)
      ..lineTo(w * 0.41, h * 0.49)
      ..lineTo(w * 0.44, h * 0.39)
      ..close();

    canvas.drawPath(road, Paint()..color = const Color(0xFF8A795D));

    // Viền đất chuyển tiếp giữa cỏ và đường.
    canvas.drawPath(
      road,
      Paint()
        ..color = const Color(0xFF5B503A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Mặt đường đá cuội.
    final stoneColors = <Color>[
      const Color(0xFFC2B59A),
      const Color(0xFFA99B80),
      const Color(0xFFD0C2A5),
      const Color(0xFF96866C),
      const Color(0xFFB5A58B),
    ];

    final random = math.Random(42);

    for (var row = 0; row < 60; row++) {
      final y = h * row / 60;
      final roadCenter = w * (0.50 + 0.025 * math.sin(row * 0.15));
      final roadHalf = w * (0.065 + 0.01 * math.sin(row * 0.12));

      for (var col = 0; col < 5; col++) {
        final x = roadCenter - roadHalf + col * roadHalf * 0.48;
        final jitterX = (random.nextDouble() - 0.5) * 3;
        final jitterY = (random.nextDouble() - 0.5) * 2;

        final rect = Rect.fromCenter(
          center: Offset(x + jitterX, y + jitterY),
          width: w * (0.018 + random.nextDouble() * 0.008),
          height: h * 0.010,
        );

        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(1.5)),
          Paint()..color = stoneColors[random.nextInt(stoneColors.length)],
        );
      }
    }
  }

  void _drawBranchRoad(
    Canvas canvas,
    Offset start,
    Offset end,
    double roadWidth,
  ) {
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(end.dx, end.dy);

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF5D503C)
        ..strokeWidth = roadWidth + 4
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF9C8B6D)
        ..strokeWidth = roadWidth
        ..strokeCap = StrokeCap.round,
    );

    final distanceX = end.dx - start.dx;
    final distanceY = end.dy - start.dy;
    final distance = math.sqrt(distanceX * distanceX + distanceY * distanceY);

    final count = (distance / 10).ceil().clamp(1, 100);

    for (var i = 0; i <= count; i++) {
      final t = i / count;
      final point = Offset(start.dx + distanceX * t, start.dy + distanceY * t);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: point,
            width: roadWidth * 0.35,
            height: roadWidth * 0.19,
          ),
          const Radius.circular(1),
        ),
        Paint()
          ..color = i.isEven
              ? const Color(0xFFC0B398)
              : const Color(0xFF81735A),
      );
    }
  }

  void _drawResidentialDistrict(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Nền sân của khu dân cư phía trên.
    final yard = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * 0.285)
      ..lineTo(w * 0.77, h * 0.31)
      ..lineTo(w * 0.61, h * 0.29)
      ..lineTo(w * 0.40, h * 0.31)
      ..lineTo(w * 0.22, h * 0.29)
      ..lineTo(0, h * 0.31)
      ..close();

    canvas.drawPath(yard, Paint()..color = const Color(0xFF6C854D));

    // Các căn nhà dân tạo thành dãy phố phía trên.
    _drawHouse(
      canvas,
      Rect.fromLTWH(w * 0.035, h * 0.055, w * 0.22, h * 0.20),
      wall: const Color(0xFFD0B58A),
      roof: const Color(0xFF884D39),
      roofVariant: 0,
    );

    _drawHouse(
      canvas,
      Rect.fromLTWH(w * 0.285, h * 0.025, w * 0.19, h * 0.205),
      wall: const Color(0xFFC9A87B),
      roof: const Color(0xFF6E4939),
      roofVariant: 1,
    );

    _drawHouse(
      canvas,
      Rect.fromLTWH(w * 0.515, h * 0.045, w * 0.205, h * 0.205),
      wall: const Color(0xFFD6BF96),
      roof: const Color(0xFF9A5540),
      roofVariant: 0,
    );

    _drawHouse(
      canvas,
      Rect.fromLTWH(w * 0.755, h * 0.065, w * 0.205, h * 0.19),
      wall: const Color(0xFFBE9A6E),
      roof: const Color(0xFF704332),
      roofVariant: 1,
    );

    // Hàng rào gỗ chạy trước dãy nhà.
    final fenceY = h * 0.275;
    final fencePaint = Paint()
      ..color = const Color(0xFF66452C)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(0, fenceY), Offset(w * 0.39, fenceY), fencePaint);

    canvas.drawLine(Offset(w * 0.62, fenceY), Offset(w, fenceY), fencePaint);

    for (var i = 0; i < 22; i++) {
      final x = w * i / 21;
      if (x > w * 0.39 && x < w * 0.62) continue;

      canvas.drawLine(Offset(x, fenceY - 4), Offset(x, fenceY + 5), fencePaint);
    }

    // Các bụi cây xen giữa nhà.
    _drawBush(canvas, Offset(w * 0.265, h * 0.22), w * 0.024);
    _drawBush(canvas, Offset(w * 0.49, h * 0.24), w * 0.022);
    _drawBush(canvas, Offset(w * 0.735, h * 0.22), w * 0.023);
  }

  void _drawHouse(
    Canvas canvas,
    Rect rect, {
    required Color wall,
    required Color roof,
    required int roofVariant,
  }) {
    final x = rect.left;
    final y = rect.top;
    final w = rect.width;
    final h = rect.height;

    // Bóng nhà trên mặt cỏ.
    canvas.drawOval(
      Rect.fromLTWH(x - w * 0.04, y + h * 0.72, w * 1.12, h * 0.25),
      Paint()..color = const Color(0x33000000),
    );

    // Móng đá.
    final foundation = Rect.fromLTWH(
      x + w * 0.06,
      y + h * 0.48,
      w * 0.88,
      h * 0.42,
    );

    canvas.drawRect(foundation, Paint()..color = const Color(0xFF76634B));

    for (var i = 0; i < 4; i++) {
      canvas.drawLine(
        Offset(foundation.left, foundation.top + i * h * 0.095),
        Offset(foundation.right, foundation.top + i * h * 0.095),
        Paint()
          ..color = const Color(0xFFB5A184)
          ..strokeWidth = 1,
      );
    }

    // Tường nhà.
    final wallRect = Rect.fromLTWH(
      x + w * 0.13,
      y + h * 0.31,
      w * 0.74,
      h * 0.49,
    );

    canvas.drawRect(wallRect, Paint()..color = wall);

    // Bóng ở chân tường.
    canvas.drawRect(
      Rect.fromLTWH(
        wallRect.left,
        wallRect.bottom - h * 0.045,
        wallRect.width,
        h * 0.045,
      ),
      Paint()..color = Color.lerp(wall, Colors.black, 0.2)!,
    );

    // Mái nhà hình tam giác.
    final roofPath = Path()
      ..moveTo(x, y + h * 0.36)
      ..lineTo(x + w * 0.5, y)
      ..lineTo(x + w, y + h * 0.36)
      ..lineTo(x + w * 0.92, y + h * 0.43)
      ..lineTo(x + w * 0.5, y + h * 0.14)
      ..lineTo(x + w * 0.08, y + h * 0.43)
      ..close();

    canvas.drawPath(roofPath, Paint()..color = const Color(0xFF493126));

    final innerRoof = Path()
      ..moveTo(x + w * 0.045, y + h * 0.34)
      ..lineTo(x + w * 0.5, y + h * 0.045)
      ..lineTo(x + w * 0.955, y + h * 0.34)
      ..lineTo(x + w * 0.89, y + h * 0.38)
      ..lineTo(x + w * 0.5, y + h * 0.13)
      ..lineTo(x + w * 0.11, y + h * 0.38)
      ..close();

    canvas.drawPath(innerRoof, Paint()..color = roof);

    // Đường ngói trên mái.
    final tilePaint = Paint()
      ..color = const Color(0x559D6B50)
      ..strokeWidth = 1;

    for (var i = 1; i <= 4; i++) {
      final t = i / 5;
      final yy = y + h * (0.08 + t * 0.24);

      canvas.drawLine(
        Offset(x + w * (0.15 + t * 0.18), yy),
        Offset(x + w * (0.85 - t * 0.18), yy),
        tilePaint,
      );
    }

    if (roofVariant == 1) {
      canvas.drawLine(
        Offset(x + w * 0.5, y + h * 0.08),
        Offset(x + w * 0.5, y + h * 0.34),
        Paint()
          ..color = const Color(0x66452D22)
          ..strokeWidth = 2,
      );
    }

    // Khung gỗ trên tường.
    final woodPaint = Paint()
      ..color = const Color(0xFF67452C)
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(wallRect.left, wallRect.top),
      Offset(wallRect.left, wallRect.bottom),
      woodPaint,
    );

    canvas.drawLine(
      Offset(wallRect.right, wallRect.top),
      Offset(wallRect.right, wallRect.bottom),
      woodPaint,
    );

    canvas.drawLine(
      Offset(wallRect.left, wallRect.top + h * 0.09),
      Offset(wallRect.right, wallRect.top + h * 0.09),
      woodPaint,
    );

    // Cửa gỗ.
    final door = Rect.fromLTWH(x + w * 0.41, y + h * 0.57, w * 0.19, h * 0.23);

    canvas.drawRect(door, Paint()..color = const Color(0xFF573823));

    canvas.drawRect(
      door,
      Paint()
        ..color = const Color(0xFFB28A58)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    canvas.drawLine(
      Offset(door.left + door.width * 0.5, door.top),
      Offset(door.left + door.width * 0.5, door.bottom),
      Paint()
        ..color = const Color(0xFF38271C)
        ..strokeWidth = 1,
    );

    canvas.drawCircle(
      Offset(door.right - door.width * 0.2, door.center.dy),
      1.2,
      Paint()..color = const Color(0xFFE5BF65),
    );

    // Cửa sổ.
    for (final wx in [x + w * 0.23, x + w * 0.68]) {
      final window = Rect.fromLTWH(wx, y + h * 0.46, w * 0.12, h * 0.12);

      canvas.drawRect(window, Paint()..color = const Color(0xFF493126));

      canvas.drawRect(
        window.deflate(1.5),
        Paint()..color = const Color(0xFFE2B96A),
      );

      canvas.drawLine(
        Offset(window.center.dx, window.top),
        Offset(window.center.dx, window.bottom),
        Paint()
          ..color = const Color(0xFF66452C)
          ..strokeWidth = 1.5,
      );
    }

    // Ống khói.
    final chimney = Rect.fromLTWH(
      x + w * 0.70,
      y + h * 0.08,
      w * 0.11,
      h * 0.19,
    );

    canvas.drawRect(chimney, Paint()..color = const Color(0xFF79523C));

    canvas.drawRect(
      Rect.fromLTWH(
        chimney.left - 1,
        chimney.top,
        chimney.width + 2,
        h * 0.035,
      ),
      Paint()..color = const Color(0xFF51392C),
    );

    // Bóng khói nhẹ.
    final smokePaint = Paint()..color = const Color(0x228D8B7D);

    canvas.drawCircle(
      Offset(chimney.center.dx, chimney.top - h * 0.025),
      w * 0.025,
      smokePaint,
    );
  }

  void _drawTrees(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final positions = <Offset>[
      Offset(w * 0.055, h * 0.40),
      Offset(w * 0.12, h * 0.48),
      Offset(w * 0.91, h * 0.30),
      Offset(w * 0.95, h * 0.56),
      Offset(w * 0.85, h * 0.78),
      Offset(w * 0.45, h * 0.88),
      Offset(w * 0.08, h * 0.90),
      Offset(w * 0.28, h * 0.43),
    ];

    for (var i = 0; i < positions.length; i++) {
      final p = positions[i];
      _drawTree(canvas, p, size.width * (i.isEven ? 0.036 : 0.029));
    }
  }

  void _drawTree(Canvas canvas, Offset center, double radius) {
    // Bóng cây.
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(radius * 0.25, radius * 0.55),
        width: radius * 2.4,
        height: radius * 1.15,
      ),
      Paint()..color = const Color(0x33000000),
    );

    // Thân cây.
    canvas.drawRect(
      Rect.fromCenter(
        center: center.translate(0, radius * 0.3),
        width: radius * 0.42,
        height: radius * 1.0,
      ),
      Paint()..color = const Color(0xFF65452D),
    );

    // Tán cây.
    canvas.drawCircle(
      center.translate(-radius * 0.35, -radius * 0.15),
      radius * 0.74,
      Paint()..color = const Color(0xFF41663A),
    );

    canvas.drawCircle(
      center.translate(radius * 0.36, -radius * 0.25),
      radius * 0.7,
      Paint()..color = const Color(0xFF4F783D),
    );

    canvas.drawCircle(
      center.translate(0, -radius * 0.55),
      radius * 0.75,
      Paint()..color = const Color(0xFF668B48),
    );

    canvas.drawCircle(
      center.translate(-radius * 0.18, -radius * 0.67),
      radius * 0.25,
      Paint()..color = const Color(0x557FA75D),
    );
  }

  void _drawBush(Canvas canvas, Offset center, double radius) {
    final shadowPaint = Paint()..color = const Color(0x33000000);
    final darkPaint = Paint()..color = const Color(0xFF3F6335);
    final greenPaint = Paint()..color = const Color(0xFF527A3B);
    final lightPaint = Paint()..color = const Color(0xFF769653);

    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(1, radius * 0.5),
        width: radius * 2.5,
        height: radius,
      ),
      shadowPaint,
    );

    canvas.drawCircle(
      center.translate(-radius * 0.45, 0),
      radius * 0.68,
      darkPaint,
    );

    canvas.drawCircle(
      center.translate(radius * 0.35, -radius * 0.15),
      radius * 0.72,
      greenPaint,
    );

    canvas.drawCircle(
      center.translate(-radius * 0.08, -radius * 0.45),
      radius * 0.53,
      lightPaint,
    );
  }

  void _drawGrass(Canvas canvas, Size size) {
    final random = math.Random(19);
    final paint = Paint()..strokeWidth = 1.1;

    for (var i = 0; i < 220; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;

      // Không vẽ cỏ trên khu vực nhà dân.
      if (y < size.height * 0.29) continue;

      // Hạn chế chi tiết trên đường chính.
      final roadCenter =
          size.width * (0.50 + 0.025 * math.sin(y / size.height * 9));

      if ((x - roadCenter).abs() < size.width * 0.075) continue;

      paint.color = i.isEven
          ? const Color(0x557B9B53)
          : const Color(0x55809C5A);

      canvas.drawLine(Offset(x, y), Offset(x + 2, y - 3), paint);
    }
  }

  void _drawGardenPatches(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final patches = <Offset>[
      Offset(w * 0.17, h * 0.39),
      Offset(w * 0.83, h * 0.34),
      Offset(w * 0.19, h * 0.84),
      Offset(w * 0.79, h * 0.77),
    ];

    for (var i = 0; i < patches.length; i++) {
      final p = patches[i];

      canvas.drawOval(
        Rect.fromCenter(center: p, width: w * 0.09, height: h * 0.035),
        Paint()..color = const Color(0x337D5E3D),
      );

      for (var j = 0; j < 5; j++) {
        final flowerPoint = Offset(
          p.dx + (j - 2) * w * 0.012,
          p.dy + (j.isEven ? -h * 0.004 : h * 0.004),
        );

        canvas.drawCircle(
          flowerPoint,
          1.3,
          Paint()
            ..color = j.isEven
                ? const Color(0xFFE8D49B)
                : const Color(0xFFB7C76D),
        );
      }
    }
  }

  void _drawRoadsideDetails(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Đá viền đường ở hai bên.
    for (var i = 0; i < 18; i++) {
      final y = h * (0.34 + i * 0.037);
      final center = w * (0.50 + 0.025 * math.sin(i * 0.3));
      final offset = w * (0.07 + 0.008 * math.sin(i * 0.4));

      for (final side in [-1.0, 1.0]) {
        final x = center + offset * side;

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(x, y),
              width: w * 0.014,
              height: h * 0.009,
            ),
            const Radius.circular(1.5),
          ),
          Paint()
            ..color = i.isEven
                ? const Color(0xFFB7A58A)
                : const Color(0xFF8D7B61),
        );
      }
    }
  }

  void _drawGrassDetails(Canvas canvas, Size size) {
    final random = math.Random(77);

    final grassColors = <Color>[
      const Color(0xFF4E733B),
      const Color(0xFF91A85C),
      const Color(0xFF6F8C4A),
      const Color(0xFFB3B66B),
    ];

    for (var i = 0; i < 45; i++) {
      final x = random.nextDouble() * size.width;
      final y = size.height * 0.31 + random.nextDouble() * size.height * 0.66;

      final roadCenter =
          size.width * (0.50 + 0.025 * math.sin(y / size.height * 9));

      if ((x - roadCenter).abs() < size.width * 0.08) continue;

      canvas.drawCircle(
        Offset(x, y),
        random.nextDouble() * 1.5 + 0.5,
        Paint()..color = grassColors[random.nextInt(grassColors.length)],
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CityGroundPainter oldDelegate) => false;
}

// ================================================================
// QUEST PANEL
// ================================================================

class _QuestPanel extends StatefulWidget {
  const _QuestPanel({required this.cityId, required this.compact});

  final String cityId;
  final bool compact;

  @override
  State<_QuestPanel> createState() => _QuestPanelState();
}

class _QuestPanelState extends State<_QuestPanel> {
  @override
  Widget build(BuildContext context) {
    // Nhiệm vụ khả dụng thật từ bảng nhiệm vụ của game.
    final controller = ControllerScope.of(context);
    final state = controller.state!;
    final offered = GameRules.byStatus(state, MissionStatus.offered);
    List<_QuestData> board(MissionColor color) => [
      for (final m in offered)
        if (templateById(m.templateId).color == color)
          _QuestData(
            id: m.id,
            title: templateById(m.templateId).title,
            description: templateById(m.templateId).desc,
            difficulty: templateById(m.templateId).difficulty,
            isGolden: color == MissionColor.gold,
            selected: false,
            // Chạm thẻ CHỈ mở popup chi tiết; nhiệm vụ chỉ được nhận khi bấm "Nhận nhiệm vụ" trong popup.
            onTap: () => showMissionDetail(context, controller, m.id),
            onInfo: () => showMissionDetail(context, controller, m.id),
          ),
    ];
    final goldenQuests = board(MissionColor.gold);
    final redQuests = board(MissionColor.red);
    final compact = widget.compact;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Pal.panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Pal.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'NHIỆM VỤ KHẢ DỤNG',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: serif,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  _QuestGrid(quests: goldenQuests, compact: compact),
                  const SizedBox(height: 12),
                  _QuestGrid(quests: redQuests, compact: compact),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Hai nút điều hướng luôn nằm cố định dưới cùng, không bị cuộn mất.
          _CityNavigationPanel(
            onReturnToCamp: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            onLeaveCity: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }
}

class _QuestGrid extends StatelessWidget {
  const _QuestGrid({required this.quests, required this.compact});

  final List<_QuestData> quests;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    // Luôn tối đa 3 nhiệm vụ trên mỗi hàng.
    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 3;
        const gap = 5.0;
        final itemWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: 7,
          children: [
            for (final quest in quests)
              SizedBox(
                width: itemWidth,
                child: _QuestScrollCard(quest: quest, compact: compact),
              ),
          ],
        );
      },
    );
  }
}

class _QuestScrollCard extends StatelessWidget {
  const _QuestScrollCard({required this.quest, required this.compact});

  final _QuestData quest;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ribbon = quest.isGolden
        ? const Color(0xFFC69A3D)
        : const Color(0xFF9C352E);

    final paper = quest.isGolden
        ? const Color(0xFFF3E2B9)
        : const Color(0xFFE9C9B9);

    final ink = quest.isGolden
        ? const Color(0xFF866020)
        : const Color(0xFF8F342B);

    final difficulty = quest.difficulty.clamp(1, 5);

    final card = Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('city-quest-${quest.id}'),
        borderRadius: BorderRadius.circular(8),
        onTap: quest.onTap,
        onLongPress: quest.onInfo,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: quest.selected ? Pal.gold : Colors.transparent,
              width: 2,
            ),
            color: quest.selected
                ? Pal.gold.withValues(alpha: 0.14)
                : Colors.transparent,
          ),
          child: SizedBox(
            height: compact ? 124 : 134,
            child: Column(
              children: [
                // Cuộn giấy cổ với dải ruy băng nằm chính giữa.
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 3,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Mặt giấy.
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  paper,
                                  Color.lerp(paper, ink, 0.08)!,
                                  paper,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: quest.isGolden
                                    ? const Color(0xFFB58A3B)
                                    : const Color(0xFFAA5A4A),
                                width: 1.2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x30000000),
                                  offset: Offset(1, 2),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Vân giấy cổ trang trí.
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: CustomPaint(
                              painter: _ParchmentPatternPainter(
                                color: ink.withValues(alpha: 0.12),
                              ),
                            ),
                          ),
                        ),

                        // Hai thanh cuộn giấy ở hai đầu.
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: _ScrollRoll(
                            color: paper,
                            borderColor: ink,
                            width: compact ? 9 : 11,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: _ScrollRoll(
                            color: paper,
                            borderColor: ink,
                            width: compact ? 9 : 11,
                          ),
                        ),

                        // Ruy băng màu vắt ngang chính giữa cuộn giấy.
                        Positioned(
                          left: compact ? 5 : 6,
                          right: compact ? 5 : 6,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: SizedBox(
                              height: compact ? 27 : 31,
                              child: Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.center,
                                children: [
                                  // Đuôi ruy băng.
                                  Positioned(
                                    left: 2,
                                    right: 2,
                                    top: 3,
                                    bottom: -4,
                                    child: CustomPaint(
                                      painter: _RibbonTailPainter(
                                        color: Color.lerp(
                                          ribbon,
                                          Colors.black,
                                          0.18,
                                        )!,
                                      ),
                                    ),
                                  ),

                                  // Dải ruy băng chính.
                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Color.lerp(
                                            ribbon,
                                            Colors.white,
                                            0.13,
                                          )!,
                                          ribbon,
                                          Color.lerp(
                                            ribbon,
                                            Colors.black,
                                            0.12,
                                          )!,
                                        ],
                                      ),
                                      border: Border.symmetric(
                                        horizontal: BorderSide(
                                          color: Color.lerp(
                                            ribbon,
                                            Colors.black,
                                            0.22,
                                          )!,
                                          width: 1,
                                        ),
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x30000000),
                                          offset: Offset(0, 2),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 9,
                                        height: 9,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color.lerp(
                                            ribbon,
                                            const Color(0xFFFFE8A5),
                                            0.55,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFFFE8A5),
                                            width: 1,
                                          ),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Color(0x44000000),
                                              blurRadius: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Tên nhiệm vụ (chạm thẻ để nhận).
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    quest.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: compact ? 10 : 11,
                      fontWeight: FontWeight.w800,
                      color: Pal.text,
                      height: 1.1,
                    ),
                  ),
                ),

                // Đầu lâu nằm riêng bên dưới cuộn giấy.
                Padding(
                  padding: const EdgeInsets.only(top: 1, bottom: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < difficulty; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: Text(
                            '☠',
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: compact ? 12 : 14,
                              height: 1,
                              color: i < difficulty
                                  ? const Color(0xFFC83B32)
                                  : const Color(0xFFB7A99A),
                              shadows: const [
                                Shadow(
                                  color: Color(0x30000000),
                                  offset: Offset(0, 1),
                                  blurRadius: 1,
                                ),
                              ],
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
    );
    return Stack(
      children: [
        card,
        Positioned(
          top: 0,
          right: 0,
          child: Semantics(
            button: true,
            label: 'Chi tiết nhiệm vụ ${quest.title}',
            child: InkResponse(
              key: ValueKey('city-quest-info-${quest.id}'),
              onTap: quest.onInfo,
              radius: 18,
              child: const SizedBox(
                width: 34,
                height: 34,
                child: Icon(Icons.info_outline, size: 17, color: Pal.text),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuestData {
  const _QuestData({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.isGolden,
    this.selected = false,
    this.onTap,
    this.onInfo,
  });

  final int id;
  final bool selected;
  final VoidCallback? onTap;

  /// Mở thẻ chi tiết (không nhận nhiệm vụ).
  final VoidCallback? onInfo;
  final String title;
  final String description;
  final int difficulty;
  final bool isGolden;
}

class _ScrollRoll extends StatelessWidget {
  const _ScrollRoll({
    required this.color,
    required this.borderColor,
    required this.width,
  });

  final Color color;
  final Color borderColor;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      margin: const EdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color.lerp(color, Colors.black, 0.18)!,
            color,
            Color.lerp(color, Colors.white, 0.25)!,
            color,
            Color.lerp(color, Colors.black, 0.12)!,
          ],
        ),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: borderColor.withValues(alpha: 0.65),
          width: 0.8,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            offset: Offset(1, 0),
            blurRadius: 2,
          ),
        ],
      ),
    );
  }
}

class _ParchmentPatternPainter extends CustomPainter {
  const _ParchmentPatternPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // Những đường vân mảnh gợi bề mặt giấy cũ.
    for (var i = 0; i < 4; i++) {
      final y = size.height * (0.18 + i * 0.2);
      final path = Path()
        ..moveTo(size.width * 0.17, y)
        ..quadraticBezierTo(size.width * 0.5, y - 2, size.width * 0.83, y + 1);

      canvas.drawPath(path, paint);
    }

    // Hoa văn nhỏ ở bốn góc giấy.
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (final x in [size.width * 0.2, size.width * 0.8]) {
      for (final y in [size.height * 0.16, size.height * 0.84]) {
        canvas.drawCircle(Offset(x, y), 1.4, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParchmentPatternPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _RibbonTailPainter extends CustomPainter {
  const _RibbonTailPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width * 0.92, size.height)
      ..lineTo(size.width * 0.72, size.height * 0.72)
      ..lineTo(size.width * 0.5, size.height)
      ..lineTo(size.width * 0.28, size.height * 0.72)
      ..lineTo(size.width * 0.08, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RibbonTailPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

// ================================================================
// KẾT QUẢ HÀNH TRÌNH
// ================================================================

class _ArrivalPanel extends StatelessWidget {
  const _ArrivalPanel({required this.arrival, required this.compact});

  final ExpeditionResult arrival;

  /// Màn hẹp: giới hạn thấp hơn để danh sách nhiệm vụ bên dưới còn đủ chỗ (panel cuộn được).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: compact ? 84 : 130),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Pal.panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Pal.gold),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'HÀNH TRÌNH',
              style: TextStyle(
                fontFamily: serif,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Pal.gold,
              ),
            ),
            const SizedBox(height: 4),
            for (final line in arrival.lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('• $line', style: const TextStyle(fontSize: 11)),
              ),
            if (arrival.missionNote != null)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  arrival.missionNote!,
                  style: const TextStyle(color: Pal.gold, fontSize: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// HAI NÚT LUÔN NẰM BÊN PHẢI, DƯỚI DANH SÁCH NHIỆM VỤ
// ================================================================

class _CityNavigationPanel extends StatelessWidget {
  const _CityNavigationPanel({
    required this.onReturnToCamp,
    required this.onLeaveCity,
  });

  final VoidCallback onReturnToCamp;
  final VoidCallback onLeaveCity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Pal.panel,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Pal.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GameButton(
            label: 'Về trại',
            icon: Icons.cabin,
            onPressed: onReturnToCamp,
          ),
          const SizedBox(width: 6),
          GameButton(label: 'Rời', icon: Icons.map, onPressed: onLeaveCity),
        ],
      ),
    );
  }
}
