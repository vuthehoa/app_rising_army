import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../domain/catalog.dart';
import '../../domain/models.dart';
import '../../domain/rules.dart';
import '../../domain/stats.dart';
import '../widgets/common.dart';
import 'city_screen.dart';
import 'squad_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const Size _worldSize = Size(2200, 1500);
  static const double _minZoom = 0.25;
  static const double _maxZoom = 2.2;

  final TransformationController _transform = TransformationController();

  String? _sel;
  double _zoom = 0.48;
  Size _viewportSize = Size.zero;
  bool _initialized = false;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  Matrix4 _matrixFor({required Offset worldPoint, required double scale}) {
    final dx = _viewportSize.width / 2 - worldPoint.dx * scale;
    final dy = _viewportSize.height / 2 - worldPoint.dy * scale;

    return Matrix4.identity()
      ..translate(dx, dy)
      ..scale(scale);
  }

  void _initializeView(Size viewport) {
    if (viewport.width <= 0 || viewport.height <= 0) return;

    _viewportSize = viewport;

    if (_initialized) return;
    _initialized = true;

    final scale = math
        .min(
          (viewport.width - 32) / _worldSize.width,
          (viewport.height - 32) / _worldSize.height,
        )
        .clamp(_minZoom, 0.8);

    _zoom = scale;
    _transform.value = _matrixFor(
      worldPoint: Offset(_worldSize.width / 2, _worldSize.height / 2),
      scale: scale,
    );
  }

  void _resetView() {
    if (_viewportSize.width <= 0 || _viewportSize.height <= 0) {
      return;
    }

    final scale = math
        .min(
          (_viewportSize.width - 32) / _worldSize.width,
          (_viewportSize.height - 32) / _worldSize.height,
        )
        .clamp(_minZoom, 0.8);

    setState(() {
      _zoom = scale;
      _transform.value = _matrixFor(
        worldPoint: Offset(_worldSize.width / 2, _worldSize.height / 2),
        scale: scale,
      );
    });
  }

  void _zoomBy(double factor) {
    if (_viewportSize.width <= 0 || _viewportSize.height <= 0) {
      return;
    }

    final next = (_zoom * factor).clamp(_minZoom, _maxZoom);
    final actualFactor = next / _zoom;
    final center = Offset(_viewportSize.width / 2, _viewportSize.height / 2);

    final matrix = _transform.value.clone();
    matrix.translate(center.dx, center.dy);
    matrix.scale(actualFactor);
    matrix.translate(-center.dx, -center.dy);

    setState(() {
      _zoom = next;
      _transform.value = matrix;
    });
  }

  void _focusLocation(LocationDef location) {
    if (_viewportSize.width <= 0 || _viewportSize.height <= 0) {
      return;
    }

    final point = Offset(
      location.x * _worldSize.width,
      location.y * _worldSize.height,
    );

    final scale = _zoom.clamp(0.45, 1.25);

    setState(() {
      _sel = location.id;
      _zoom = scale;
      _transform.value = _matrixFor(worldPoint: point, scale: scale);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = ControllerScope.of(context);
    final state = controller.state!;
    final compact = MediaQuery.sizeOf(context).width < 760;

    final unlocked = [
      for (final region in regions) GameRules.regionUnlocked(state, region),
    ];

    final validLocations = locations.where((location) {
      final index = regions.indexWhere(
        (region) => region.id == location.regionId,
      );
      return index >= 0 && unlocked[index];
    }).toList();

    final selected = _sel == null ? null : locationById(_sel!);

    if (compact) {
      return Padding(
        padding: const EdgeInsets.all(6),
        child: _buildMapPanel(
          state: state,
          unlocked: unlocked,
          validLocations: validLocations,
          compact: true,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
            child: _buildMapPanel(
              state: state,
              unlocked: unlocked,
              validLocations: validLocations,
              compact: false,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 310,
            child: _buildDetails(
              context: context,
              selected: selected,
              compact: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPanel({
    required GameState state,
    required List<bool> unlocked,
    required List<LocationDef> validLocations,
    required bool compact,
  }) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF243B30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Pal.goldDim, width: 1.3),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewport = Size(constraints.maxWidth, constraints.maxHeight);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _initializeView(viewport);
          });

          return Stack(
            fit: StackFit.expand,
            children: [
              InteractiveViewer(
                transformationController: _transform,
                constrained: false,
                alignment: Alignment.topLeft,
                minScale: _minZoom,
                maxScale: _maxZoom,
                boundaryMargin: const EdgeInsets.all(700),
                panEnabled: true,
                scaleEnabled: true,
                clipBehavior: Clip.none,
                onInteractionUpdate: (_) {
                  final scale = _transform.value.getMaxScaleOnAxis();

                  if ((scale - _zoom).abs() > 0.015 && mounted) {
                    setState(() => _zoom = scale);
                  }
                },
                child: SizedBox(
                  width: _worldSize.width,
                  height: _worldSize.height,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _FantasyWorldPainter(
                            seed: 37,
                            unlocked: unlocked,
                          ),
                        ),
                      ),

                      // Các địa điểm đã được mở khóa.
                      for (final location in validLocations)
                        Positioned(
                          left: location.x * _worldSize.width - 28,
                          top: location.y * _worldSize.height - 35,
                          child: _WorldLocationMarker(
                            location: location,
                            known: state.discovered.contains(location.id),
                            done:
                                state.cleared.contains(location.id) ||
                                state.explored.contains(location.id),
                            selected: _sel == location.id,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _sel = location.id);

                              if (compact) {
                                _showLocationSheet(location);
                              }
                            },
                          ),
                        ),

                      // Nhân vật minh họa tại trung tâm thế giới.
                      Positioned(
                        left: _worldSize.width * 0.47,
                        top: _worldSize.height * 0.48,
                        child: const _PlayerArmyMarker(),
                      ),
                    ],
                  ),
                ),
              ),

              // HUD phía trên.
              Positioned(
                left: 10,
                top: 10,
                right: 10,
                child: Row(
                  children: [
                    _HudPanel(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.public,
                            color: Color(0xFFF0C66D),
                            size: 19,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            compact ? 'THẾ GIỚI' : 'BẢN ĐỒ THẾ GIỚI',
                            style: const TextStyle(
                              color: Color(0xFFFFE9B6),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    _HudPanel(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.explore,
                            color: Color(0xFFF0C66D),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${validLocations.length} địa điểm',
                            style: const TextStyle(
                              color: Color(0xFFFFE9B6),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Điều khiển bên phải.
              Positioned(
                right: 10,
                bottom: 12,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MapControl(
                      icon: Icons.add,
                      tooltip: 'Phóng to',
                      onTap: () => _zoomBy(1.2),
                    ),
                    const SizedBox(height: 6),
                    _MapControl(
                      icon: Icons.remove,
                      tooltip: 'Thu nhỏ',
                      onTap: () => _zoomBy(1 / 1.2),
                    ),
                    const SizedBox(height: 6),
                    _MapControl(
                      icon: Icons.fit_screen,
                      tooltip: 'Xem toàn bản đồ',
                      onTap: _resetView,
                    ),
                    const SizedBox(height: 6),
                    _MapControl(
                      icon: Icons.center_focus_strong,
                      tooltip: 'Tập trung địa điểm',
                      onTap: () {
                        final location = _sel == null
                            ? null
                            : locationById(_sel!);

                        if (location != null) {
                          _focusLocation(location);
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Thông tin zoom.
              Positioned(
                right: 10,
                top: 58,
                child: _HudPanel(
                  child: Text(
                    '${(_zoom * 100).round()}%',
                    style: const TextStyle(
                      color: Color(0xFFF0C66D),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),

              // Gợi ý thao tác.
              Positioned(
                left: 10,
                bottom: 12,
                child: IgnorePointer(
                  child: _HudPanel(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.open_with,
                          color: Color(0xFFF0C66D),
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          compact
                              ? 'Kéo bản đồ · Chạm địa điểm'
                              : 'Kéo để di chuyển · Chụm để thu phóng',
                          style: const TextStyle(
                            color: Color(0xFFFFE9B6),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLocationSheet(LocationDef location) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.72,
            ),
            decoration: BoxDecoration(
              color: Pal.panel,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: Border.all(color: Pal.goldDim),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  decoration: BoxDecoration(
                    color: Pal.goldDim,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: _buildDetails(
                      context: context,
                      selected: location,
                      compact: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetails({
    required BuildContext context,
    required LocationDef? selected,
    required bool compact,
  }) {
    return SingleChildScrollView(
      child: _LocationDetails(
        selected: selected?.id,
        onSelect: (id) {
          if (id == null) {
            setState(() => _sel = null);
            return;
          }

          final location = locationById(id);
          if (location != null) {
            _focusLocation(location);
          }
        },
      ),
    );
  }
}

class _FantasyWorldPainter extends CustomPainter {
  const _FantasyWorldPainter({required this.seed, required this.unlocked});

  final int seed;
  final List<bool> unlocked;

  static const Color grass = Color(0xFF788E59);
  static const Color grassLight = Color(0xFF9CAB70);
  static const Color grassDark = Color(0xFF526E49);
  static const Color water = Color(0xFF548C99);
  static const Color road = Color(0xFFD3BD88);
  static const Color roadEdge = Color(0xFF806F4A);

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);

    canvas.drawRect(Offset.zero & size, Paint()..color = grass);

    // Mảng địa hình mềm, không dùng lưới ô vuông.
    for (var i = 0; i < 95; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 35 + random.nextDouble() * 125;

      final paint = Paint()
        ..color = (i % 3 == 0 ? grassLight : grassDark).withValues(
          alpha: 0.10 + random.nextDouble() * 0.15,
        );

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: radius * 1.7,
          height: radius,
        ),
        paint,
      );
    }

    _drawRiver(canvas, size);
    _drawRoads(canvas, size);
    _drawForests(canvas, size, random);
    _drawMountains(canvas, size, random);
    _drawDetails(canvas, size, random);
    _drawBorders(canvas, size);
  }

  void _drawRiver(Canvas canvas, Size size) {
    final river = Path()
      ..moveTo(size.width * 0.05, size.height * 0.34)
      ..cubicTo(
        size.width * 0.22,
        size.height * 0.29,
        size.width * 0.22,
        size.height * 0.47,
        size.width * 0.40,
        size.height * 0.43,
      )
      ..cubicTo(
        size.width * 0.57,
        size.height * 0.39,
        size.width * 0.55,
        size.height * 0.62,
        size.width * 0.72,
        size.height * 0.57,
      )
      ..cubicTo(
        size.width * 0.83,
        size.height * 0.53,
        size.width * 0.88,
        size.height * 0.70,
        size.width * 1.02,
        size.height * 0.66,
      );

    canvas.drawPath(
      river,
      Paint()
        ..color = const Color(0xFF3D6975)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 45
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawPath(
      river,
      Paint()
        ..color = water
        ..style = PaintingStyle.stroke
        ..strokeWidth = 35
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawPath(
      river,
      Paint()
        ..color = const Color(0xFF9CC2BA).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawRoads(Canvas canvas, Size size) {
    final paths = <Path>[
      Path()
        ..moveTo(size.width * 0.04, size.height * 0.78)
        ..cubicTo(
          size.width * 0.23,
          size.height * 0.70,
          size.width * 0.31,
          size.height * 0.61,
          size.width * 0.47,
          size.height * 0.48,
        )
        ..cubicTo(
          size.width * 0.60,
          size.height * 0.38,
          size.width * 0.77,
          size.height * 0.33,
          size.width * 0.96,
          size.height * 0.20,
        ),
      Path()
        ..moveTo(size.width * 0.15, size.height * 0.10)
        ..cubicTo(
          size.width * 0.25,
          size.height * 0.27,
          size.width * 0.43,
          size.height * 0.28,
          size.width * 0.53,
          size.height * 0.45,
        )
        ..cubicTo(
          size.width * 0.63,
          size.height * 0.62,
          size.width * 0.78,
          size.height * 0.72,
          size.width * 0.91,
          size.height * 0.92,
        ),
    ];

    for (final path in paths) {
      canvas.drawPath(
        path,
        Paint()
          ..color = roadEdge
          ..style = PaintingStyle.stroke
          ..strokeWidth = 15
          ..strokeCap = StrokeCap.round,
      );

      canvas.drawPath(
        path,
        Paint()
          ..color = road
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round,
      );

      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFF1DDAA).withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawForests(Canvas canvas, Size size, math.Random random) {
    final clusters = <Offset>[
      Offset(size.width * 0.12, size.height * 0.18),
      Offset(size.width * 0.78, size.height * 0.18),
      Offset(size.width * 0.18, size.height * 0.56),
      Offset(size.width * 0.79, size.height * 0.78),
      Offset(size.width * 0.58, size.height * 0.82),
      Offset(size.width * 0.91, size.height * 0.45),
    ];

    for (final center in clusters) {
      for (var i = 0; i < 45; i++) {
        final x = center.dx + (random.nextDouble() - 0.5) * 260;
        final y = center.dy + (random.nextDouble() - 0.5) * 210;
        final radius = 9 + random.nextDouble() * 12;

        _drawTree(
          canvas,
          Offset(x, y),
          radius,
          random.nextBool() ? const Color(0xFF3E5B3C) : const Color(0xFF4B6941),
        );
      }
    }
  }

  void _drawTree(Canvas canvas, Offset point, double radius, Color color) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(point.dx + 3, point.dy + radius * 0.7),
        width: radius * 1.8,
        height: radius * 0.75,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.12),
    );

    canvas.drawCircle(
      Offset(point.dx, point.dy + 4),
      radius * 0.78,
      Paint()..color = const Color(0xFF334A32),
    );

    final path = Path()
      ..moveTo(point.dx, point.dy - radius * 1.4)
      ..lineTo(point.dx - radius, point.dy + radius * 0.7)
      ..lineTo(point.dx + radius, point.dy + radius * 0.7)
      ..close();

    canvas.drawPath(path, Paint()..color = color);

    final highlight = Path()
      ..moveTo(point.dx, point.dy - radius * 1.2)
      ..lineTo(point.dx - radius * 0.55, point.dy + radius * 0.25)
      ..lineTo(point.dx, point.dy + radius * 0.05)
      ..close();

    canvas.drawPath(
      highlight,
      Paint()..color = const Color(0xFF91A46B).withValues(alpha: 0.45),
    );
  }

  void _drawMountains(Canvas canvas, Size size, math.Random random) {
    final ranges = <Offset>[
      Offset(size.width * 0.55, size.height * 0.13),
      Offset(size.width * 0.87, size.height * 0.34),
      Offset(size.width * 0.32, size.height * 0.86),
    ];

    for (final center in ranges) {
      for (var i = 0; i < 15; i++) {
        final x = center.dx + (random.nextDouble() - 0.5) * 240;
        final y = center.dy + (random.nextDouble() - 0.5) * 150;
        final w = 28 + random.nextDouble() * 35;
        final h = 28 + random.nextDouble() * 42;

        final mountain = Path()
          ..moveTo(x, y - h)
          ..lineTo(x - w, y + h * 0.55)
          ..lineTo(x + w, y + h * 0.55)
          ..close();

        canvas.drawPath(mountain, Paint()..color = const Color(0xFF626F58));

        final snow = Path()
          ..moveTo(x, y - h)
          ..lineTo(x - w * 0.30, y - h * 0.12)
          ..lineTo(x, y - h * 0.28)
          ..lineTo(x + w * 0.30, y - h * 0.12)
          ..close();

        canvas.drawPath(snow, Paint()..color = const Color(0xFFD8D5BB));

        canvas.drawPath(
          mountain,
          Paint()
            ..color = const Color(0xFF3E5040)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }
  }

  void _drawDetails(Canvas canvas, Size size, math.Random random) {
    final grassPaint = Paint()
      ..color = const Color(0xFFD2D4A0).withValues(alpha: 0.45)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 1300; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;

      canvas.drawLine(Offset(x, y), Offset(x + 2, y - 4), grassPaint);
    }

    for (var i = 0; i < 45; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;

      canvas.drawCircle(
        Offset(x, y),
        1.8 + random.nextDouble() * 2,
        Paint()..color = const Color(0xFFDDC58B).withValues(alpha: 0.6),
      );
    }
  }

  void _drawBorders(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..color = const Color(0xFF3D4F38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14,
    );

    canvas.drawRect(
      Rect.fromLTWH(10, 10, size.width - 20, size.height - 20),
      Paint()
        ..color = const Color(0xFFD3BD88).withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _FantasyWorldPainter oldDelegate) {
    return oldDelegate.seed != seed || oldDelegate.unlocked != unlocked;
  }
}

class _WorldLocationMarker extends StatelessWidget {
  const _WorldLocationMarker({
    required this.location,
    required this.known,
    required this.done,
    required this.selected,
    required this.onTap,
  });

  final LocationDef location;
  final bool known;
  final bool done;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = !known
        ? const Color(0xFF8B8C7B)
        : done
        ? const Color(0xFFB9C2A0)
        : switch (location.kind) {
            LocKind.camp => const Color(0xFFD75C4C),
            LocKind.resource => const Color(0xFFB9D17C),
            LocKind.ruins => const Color(0xFFF0C66D),
            LocKind.city => const Color(0xFFB6D2D5),
          };

    final icon = !known
        ? Icons.question_mark
        : switch (location.kind) {
            LocKind.camp => done ? Icons.check : Icons.shield,
            LocKind.resource => Icons.grass,
            LocKind.ruins => done ? Icons.check : Icons.account_balance,
            LocKind.city => Icons.castle,
          };

    return Semantics(
      button: true,
      label: known ? location.name : 'Địa điểm chưa khám phá',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 56,
          height: 66,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: selected ? 43 : 36,
                height: selected ? 43 : 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF293B2D),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? const Color(0xFFFFE29A) : color,
                    width: selected ? 3 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: selected ? 12 : 5,
                      offset: const Offset(0, 3),
                    ),
                    if (selected)
                      BoxShadow(
                        color: const Color(0xFFFFD16B).withValues(alpha: 0.3),
                        blurRadius: 18,
                        spreadRadius: 4,
                      ),
                  ],
                ),
                child: Icon(icon, color: color, size: selected ? 22 : 18),
              ),
              if (known)
                Container(
                  constraints: const BoxConstraints(maxWidth: 86),
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xE9233025),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    location.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFFFE9B6),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
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

class _PlayerArmyMarker extends StatelessWidget {
  const _PlayerArmyMarker();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF782F2C),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFFFD77B)),
          ),
          child: const Text(
            'ĐỘI QUÂN',
            style: TextStyle(
              color: Color(0xFFFFE9B6),
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF293B2D),
            border: Border.all(color: const Color(0xFFFFD77B), width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(Icons.person, color: Color(0xFFFFD77B), size: 25),
        ),
        const Icon(Icons.arrow_drop_down, color: Color(0xFFFFD77B), size: 24),
      ],
    );
  }
}

class _HudPanel extends StatelessWidget {
  const _HudPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xF0223026),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF9C8249), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 7),
        ],
      ),
      child: child,
    );
  }
}

class _MapControl extends StatelessWidget {
  const _MapControl({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0xF0223026),
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(7),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: const Color(0xFF9C8249)),
            ),
            child: Icon(icon, color: const Color(0xFFFFD77B), size: 20),
          ),
        ),
      ),
    );
  }
}

// Bảng chi tiết vẫn sử dụng hệ thống luật gameplay hiện có.
class _LocationDetails extends StatelessWidget {
  const _LocationDetails({required this.selected, required this.onSelect});

  final String? selected;
  final void Function(String?) onSelect;

  @override
  Widget build(BuildContext context) {
    final controller = ControllerScope.of(context);
    final state = controller.state!;
    final location = selected == null ? null : locationById(selected!);
    final dims = Dims(context);

    final scoutPanel = Panel(
      title: 'Trinh sát',
      child: Column(
        children: [
          for (final region in regions)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      region.name,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  SizedBox(
                    width: 112,
                    child: GameButton(
                      label: 'Trinh sát',
                      dense: true,
                      lockedReason: !GameRules.regionUnlocked(state, region)
                          ? ''
                          : null,
                      onPressed: () =>
                          toast(context, controller.scoutRegion(region.id)),
                    ),
                  ),
                ],
              ),
            ),
          Text(
            'Tốn 5 lương thực và 1 ngày để lộ thêm địa điểm. '
            'Khám phá tàn tích cũng có thể mở thêm lối đi.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );

    if (location == null) {
      return Column(
        children: [
          Panel(
            title: 'Bản đồ thế giới',
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chọn địa điểm để xem thông tin và chuẩn bị hành quân.',
                  style: TextStyle(fontSize: 12, height: 1.5),
                ),
                SizedBox(height: 12),
                _LegendRow(
                  color: Color(0xFFD75C4C),
                  icon: Icons.shield,
                  text: 'Trại địch',
                ),
                _LegendRow(
                  color: Color(0xFFB9D17C),
                  icon: Icons.grass,
                  text: 'Điểm tài nguyên',
                ),
                _LegendRow(
                  color: Color(0xFFF0C66D),
                  icon: Icons.account_balance,
                  text: 'Tàn tích',
                ),
                _LegendRow(
                  color: Color(0xFFB6D2D5),
                  icon: Icons.castle,
                  text: 'Thành phố',
                ),
              ],
            ),
          ),
          SizedBox(height: dims.gap),
          scoutPanel,
        ],
      );
    }

    final known = state.discovered.contains(location.id);

    if (!known) {
      return Column(
        children: [
          Panel(
            title: 'Chưa khám phá',
            child: Text(
              'Hãy trinh sát vùng '
              '${regionById(location.regionId).name} '
              'để tìm ra địa điểm này.',
              style: const TextStyle(fontSize: 12, height: 1.5),
            ),
          ),
          SizedBox(height: dims.gap),
          scoutPanel,
        ],
      );
    }

    final links = [
      for (final mission in GameRules.byStatus(state, MissionStatus.active))
        if (templateById(mission.templateId).locId == location.id ||
            (templateById(mission.templateId).kind == MissionKind.explore &&
                templateById(mission.templateId).regionId ==
                    location.regionId &&
                location.kind == LocKind.ruins))
          templateById(mission.templateId).title,
    ];

    final cleared = state.cleared.contains(location.id);
    final explored = state.explored.contains(location.id);

    String? lock;

    if (location.kind == LocKind.camp && cleared) {
      lock = 'Đã quét sạch';
    } else if (state.roster.where((soldier) => soldier.available).isEmpty) {
      lock = 'Không có binh sĩ sẵn sàng';
    }

    Widget enemyInfo() {
      final enemies = GameRules.previewEnemies(location.enemies);

      final ours =
          (state.roster.where((soldier) => soldier.available).toList()
                ..sort((a, b) => powerScore(b).compareTo(powerScore(a))))
              .take(8);

      final enemyPower = enemies.fold<int>(
        0,
        (sum, enemy) => sum + powerScore(enemy),
      );

      final ourPower = ours.fold<int>(
        0,
        (sum, soldier) => sum + powerScore(soldier),
      );

      final ratio = ourPower == 0 ? 0.0 : enemyPower / ourPower;

      final (label, color) = ratio < 0.6
          ? ('Dễ', Pal.moss)
          : ratio < 1.0
          ? ('Vừa sức', Pal.gold)
          : ratio < 1.6
          ? ('Khó', Pal.blood)
          : ('Rất khó', Pal.blood);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lực lượng địch',
            style: TextStyle(
              color: Pal.gold,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            location.enemies
                .map(
                  (enemy) =>
                      '${enemy.count}× ${roleNames[enemy.role]} '
                      'cấp ${enemy.level}',
                )
                .join(', '),
            style: const TextStyle(fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              const Expanded(
                child: Text('Độ nguy hiểm', style: TextStyle(fontSize: 11.5)),
              ),
              Pill(label, color: color),
            ],
          ),
        ],
      );
    }

    return Column(
      children: [
        Panel(
          title: switch (location.kind) {
            LocKind.camp => 'Trại địch',
            LocKind.resource => 'Điểm tài nguyên',
            LocKind.ruins => 'Tàn tích',
            LocKind.city => 'Thành phố',
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                location.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                '${regionById(location.regionId).name} • '
                '${location.days} ngày hành quân',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (location.blurb.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  location.blurb,
                  style: const TextStyle(fontSize: 12, height: 1.5),
                ),
              ],
              const SizedBox(height: 12),
              if (location.kind == LocKind.camp) ...[
                enemyInfo(),
                const SizedBox(height: 10),
                Text(
                  'Chiến lợi phẩm: '
                  '${GameRules.describeCost(location.loot)}'
                  '${location.lootItem != null ? ' + ${itemDefs[location.lootItem]!.name}' : ''}',
                  style: const TextStyle(fontSize: 12, color: Pal.moss),
                ),
              ],
              if (location.kind == LocKind.resource)
                Text(
                  'Thu khoảng ${location.yield} '
                  '${resNames[location.res!]} '
                  '(tăng theo quân số). '
                  '${(ambushChance * 100).round()}% bị phục kích.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Pal.moss,
                    height: 1.5,
                  ),
                ),
              if (location.kind == LocKind.city) ...[
                Text(
                  'Người bán: '
                  '${vendorsIn(location.id).map((vendor) => vendor.name).join(', ')}.',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  state.visiting == location.id
                      ? 'Bạn đang ở đây.'
                      : 'Cần hành quân ${location.days} ngày để tới.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Pal.gold,
                    height: 1.5,
                  ),
                ),
              ],
              if (location.kind == LocKind.ruins)
                Text(
                  explored
                      ? 'Đã khám phá.'
                      : 'Có thể có kho báu, bẫy và lối đi mới.',
                  style: const TextStyle(fontSize: 12, color: Pal.gold),
                ),
              if (links.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text(
                  'Nhiệm vụ liên quan',
                  style: TextStyle(
                    color: Pal.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (final title in links)
                      Pill(
                        title,
                        color: Pal.gold,
                        icon: Icons.assignment_outlined,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              if (location.kind == LocKind.city &&
                  state.visiting == location.id)
                GameButton(
                  label: 'Vào thành phố',
                  icon: Icons.storefront,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CityScreen(cityId: location.id),
                    ),
                  ),
                )
              else
                GameButton(
                  label: location.kind == LocKind.city
                      ? 'Hành quân tới thành phố'
                      : 'Chọn đội hình hành quân',
                  icon: location.kind == LocKind.city
                      ? Icons.route
                      : Icons.groups,
                  lockedReason: lock,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SquadScreen(locationId: location.id),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: dims.gap),
        scoutPanel,
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.icon,
    required this.text,
  });

  final Color color;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Pal.ink,
              border: Border.all(color: color, width: 1.5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}
