import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../application/game_controller.dart';
import '../../application/hero_travel.dart';
import '../../core/theme.dart';
import '../../domain/catalog.dart';
import '../../domain/models.dart';
import '../../domain/movement.dart';
import '../../domain/rules.dart';
import '../../domain/world_data.dart';
import '../../domain/world_map.dart';
import '../widgets/common.dart';
import '../widgets/game_hud.dart';
import '../widgets/map/hero_marker.dart';
import '../widgets/map/location_details.dart';
import '../widgets/map/map_camera.dart';
import '../widgets/map/poi_marker.dart';
import '../widgets/map/quest_marks.dart';
import '../widgets/quest_panel.dart';
import '../../domain/stats.dart';
import 'deploy_screen.dart';
import 'squad_screen.dart';
import '../widgets/map/route_painter.dart';
import '../widgets/map/town_marker.dart';
import '../widgets/map/world_art.dart';
import '../widgets/map/world_terrain_painter.dart';
import 'city_screen.dart';
import 'shell.dart';

/// Hình học địa hình dựng một lần cho cả phiên (biến toàn cục khởi tạo lười).
final WorldArt _worldArt = WorldArt(worldMap);

/// Bản đồ khám phá: thế giới rộng (4200 × 3000) chỉ thấy một phần qua camera. Chạm đất trống để nhân vật
/// đi bộ tới đó (không dịch chuyển); kéo để xem bản đồ; chạm thị trấn/địa điểm để xem thông tin.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  final MapCamera camera = MapCamera(
    worldWidth: worldMap.width,
    worldHeight: worldMap.height,
    zoom: 0.85,
  );

  late final Ticker _ticker = createTicker(_onTick);
  Duration _last = Duration.zero;
  HeroTravel? _travel;
  int _seenNotice = 0;
  bool _placed = false;
  WPoint? _lastHero;
  double _lastScale = 1;

  String? _selPoi;

  /// Hiệu ứng phản hồi thuần giao diện (vòng sóng tại điểm chạm không hợp lệ / điểm vừa tới). Không là state
  /// gameplay: chỉ neo theo tọa độ thế giới và tự biến mất.
  final List<_Ping> _pings = [];
  int _pingSeq = 0;
  bool _wasMoving = false;

  void _ping(WPoint at, {required bool bad}) {
    if (!mounted) return;
    setState(() => _pings.add(_Ping(_pingSeq++, at, bad)));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final travel = ControllerScope.of(context).travel;
    if (!identical(travel, _travel)) {
      _travel?.removeListener(_onTravel);
      _travel = travel..addListener(_onTravel);
      _seenNotice = travel.noticeSeq;
      _wake();
    }
  }

  @override
  void dispose() {
    _travel?.removeListener(_onTravel);
    _ticker.dispose();
    camera.dispose();
    super.dispose();
  }

  GameController get _controller => ControllerScope.of(context);

  /// Chạy vòng cập nhật khi nhân vật đang đi; dừng hẳn khi đứng yên (không có ticker chạy rỗng).
  void _wake() {
    if (_travel?.moving == true && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _onTravel() {
    final travel = _travel!;
    final state = _controller.state;
    if (_wasMoving && !travel.moving && state != null) {
      if (travel.status == MoveStatus.arrived) {
        _ping(state.hero.position, bad: false);
      }
    }
    _wasMoving = travel.moving;
    _wake();
    _checkArrival();
    if (travel.noticeSeq != _seenNotice) {
      _seenNotice = travel.noticeSeq;
      final msg = travel.notice;
      if (msg != null && mounted) {
        showSnack(context, msg, color: const Color(0xFF4A2019));
      }
    }
  }

  void _onTick(Duration elapsed) {
    final travel = _travel!;
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    final state = _controller.state;
    if (state == null) {
      _ticker.stop();
      return;
    }
    travel.tick(dt);
    if (camera.following) camera.follow(state.hero.position, dt);
    final settled =
        !camera.following || camera.center.distanceTo(state.hero.position) < 1;
    if (!travel.moving && settled && _ticker.isActive) _ticker.stop();
  }

  // ------------------------------------------------------------- tương tác

  void _startWalk(WPoint dest) {
    final problem = _controller.travel.setDestination(dest);
    if (problem != null) {
      _ping(dest, bad: true);
      showSnack(context, problem, color: const Color(0xFF4A2019));
      return;
    }
    camera.following = true;
    _wake();
  }

  void _onMapTap(Offset screen) {
    if (_selPoi != null) setState(() => _selPoi = null);
    _startWalk(camera.screenToWorld(screen));
  }

  /// Chạm thị trấn: đi bộ tới tâm thị trấn (thay hành trình cũ); tới nơi sẽ tự vào, không popup.
  void _goTo(String id) {
    HapticFeedback.selectionClick();
    if (_selPoi != null) setState(() => _selPoi = null);
    final travel = _controller.travel;
    final problem = travel.walkToPlace(id);
    if (problem != null) {
      showSnack(context, problem, color: const Color(0xFF4A2019));
      return;
    }
    camera.following = true;
    _wake();
    _checkArrival();
  }

  /// Nhân vật đã tới tâm địa điểm đích (sự kiện chỉ tiêu thụ một lần): thị trấn → vào thành;
  /// mục tiêu nhiệm vụ → kiểm tra nhiệm vụ còn hợp lệ rồi bắt đầu chiến đấu bằng luồng hiện có.
  void _checkArrival() {
    final id = _travel?.takeArrivedPlace();
    if (id == null || !mounted) return;
    final nav = Navigator.of(context);
    if (worldMap.townById(id) != null) {
      final r = _controller.enterTown(id);
      if (!r.ok) {
        toast(context, r);
        return;
      }
      if (r.message.contains('Hoàn thành')) toast(context, r);
      nav.push(MaterialPageRoute<void>(builder: (_) => CityScreen(cityId: id)));
      return;
    }
    final state = _controller.state!;
    final loc = GameRules.locationFor(state, id);
    final quests = GameRules.activeAt(state, id);
    if (loc == null || quests.isEmpty) {
      showSnack(
        context,
        'Nhiệm vụ này không còn hiệu lực.',
        color: const Color(0xFF4A2019),
      );
      return;
    }
    if (loc.kind == LocKind.camp) {
      final need = quests
          .map((m) => templateById(m.templateId).minSoldiers)
          .fold(0, math.max);
      final best = state.roster.where((x) => x.available).toList()
        ..sort((a, b) => powerScore(b).compareTo(powerScore(a)));
      final squad = [for (final x in best.take(GameRules.maxSquad)) x.id];
      if (squad.isNotEmpty && squad.length >= need) {
        nav.push(
          MaterialPageRoute<void>(
            builder: (_) => DeployScreen(locationId: id, squadIds: squad),
          ),
        );
        return;
      }
    }
    // Không đủ quân tự chọn hoặc không phải trại địch: để người chơi chọn đội hình.
    nav.push(
      MaterialPageRoute<void>(builder: (_) => SquadScreen(locationId: id)),
    );
  }

  void _showLocationSheet(LocationDef location) {
    HapticFeedback.selectionClick();
    setState(() {
      _selPoi = location.id;
    });
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.72,
          ),
          decoration: BoxDecoration(
            color: Pal.panel,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                  child: LocationDetails(selected: location.id),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      if (mounted) setState(() => _selPoi = null);
    });
  }

  void _recenter(GameState state) {
    camera.following = true;
    camera.jumpTo(state.hero.position);
    _wake();
  }

  // ------------------------------------------------------------- dựng

  @override
  Widget build(BuildContext context) {
    final controller = ControllerScope.of(context);
    final state = controller.state!;
    final travel = controller.travel;

    return LayoutBuilder(
      builder: (context, box) {
        camera.setViewport(Size(box.maxWidth, box.maxHeight));
        final heroAt = state.hero.position;
        if (!_placed && camera.viewport.width > 0) {
          _placed = true;
          camera.placeSilently(heroAt);
        } else if (_lastHero != heroAt && !travel.moving && camera.following) {
          // Nhân vật bị đổi vị trí ngoài vòng đi bộ (nạp save, luật khác): đưa camera theo.
          camera.placeSilently(heroAt);
        }
        _lastHero = heroAt;
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: ClipRect(
                child: Listener(
                  onPointerSignal: (e) {
                    if (e is PointerScrollEvent) {
                      camera.following = false;
                      camera.zoomAround(
                        e.localPosition,
                        math.exp(-e.scrollDelta.dy / 400),
                      );
                    }
                  },
                  child: GestureDetector(
                    key: const ValueKey('map-surface'),
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (d) => _onMapTap(d.localPosition),
                    onScaleStart: (d) {
                      _lastScale = 1;
                      camera.following = false;
                    },
                    onScaleUpdate: (d) {
                      camera.panByScreen(d.focalPointDelta);
                      if (d.pointerCount >= 2 && d.scale != _lastScale) {
                        camera.zoomAround(
                          d.localFocalPoint,
                          d.scale / _lastScale,
                        );
                        _lastScale = d.scale;
                      }
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        SizedBox.expand(
                          child: CustomPaint(
                            painter: WorldTerrainPainter(
                              art: _worldArt,
                              camera: camera,
                            ),
                          ),
                        ),
                        SizedBox.expand(
                          child: CustomPaint(
                            painter: RoutePainter(
                              camera: camera,
                              hero: () => state.hero.position,
                              destination: () => travel.destination,
                              repaint: Listenable.merge([camera, travel]),
                            ),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: Listenable.merge([camera, travel]),
                          builder: (context, _) => _markerLayer(state),
                        ),
                        AnimatedBuilder(
                          animation: Listenable.merge([camera, travel]),
                          builder: (context, _) =>
                              _heroLayer(controller, state),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Viền tối nhẹ quanh bản đồ: dồn mắt vào giữa, HUD đọc rõ hơn (không nhận chạm).
            const Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      radius: 1.15,
                      colors: [Color(0x00000000), Color(0x66000000)],
                      stops: [0.62, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: camera,
                  builder: (context, _) => Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (final p in _pings)
                        Positioned(
                          key: ValueKey('map-ping-${p.id}'),
                          left: camera.worldToScreen(p.at).dx - 28,
                          top: camera.worldToScreen(p.at).dy - 28,
                          child: _PingRing(
                            bad: p.bad,
                            onDone: () {
                              if (mounted) setState(() => _pings.remove(p));
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const GameHudOverlay(),
            Positioned(
              left: 0,
              right: 0,
              bottom: 84 + MediaQuery.paddingOf(context).bottom,
              child: IgnorePointer(
                child: Center(
                  child: AnimatedBuilder(
                    animation: travel,
                    builder: (context, _) => _routeChip(state, travel),
                  ),
                ),
              ),
            ),
            Positioned(right: 10, bottom: 12, child: _controls(state)),
            Positioned(
              left: 0,
              right: 0,
              bottom: 8 + MediaQuery.paddingOf(context).bottom,
              child: Center(
                child: _CampButton(
                  onTap: () => context
                      .getInheritedWidgetOfExactType<ShellNav>()
                      ?.go(Sections.camp),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Thẻ nhỏ mô tả hành trình đang đi: đích và thể lực dự tính. Chỉ đọc [MovementRules.estimate]; ẩn khi đứng yên.
  Widget _routeChip(GameState state, HeroTravel travel) {
    final dest = travel.destination;
    if (dest == null) return const SizedBox.shrink();
    final est = MovementRules.estimate(worldMap, state.hero.position, dest);
    final id = travel.targetPlace;
    final name = id == null
        ? null
        : (GameRules.locationFor(state, id)?.name ?? locationById(id)?.name);
    final short = est.cost > state.hero.stamina;
    return Container(
      key: const ValueKey('map-route-chip'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xE6140F0A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: short ? const Color(0xFFC4473B) : Pal.goldDim,
        ),
      ),
      child: Text(
        '${name == null ? 'Đang đi tới điểm đã chọn' : 'Đang đi tới $name'}'
        ' · tốn ~${est.cost.round()} thể lực (quãng còn lại)'
        '${short ? ' · không đủ: còn ${state.hero.stamina.round()}, sẽ dừng giữa đường' : ''}',
        style: TextStyle(
          color: short ? const Color(0xFFFFB4A8) : Pal.goldLight,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _markerLayer(GameState state) {
    final vp = camera.viewport;
    final z = camera.zoom;
    final hero = state.hero.position;
    final children = <Widget>[];

    for (final t in worldMap.towns) {
      final loc = locationById(t.id);
      if (loc == null) continue;
      final s = camera.worldToScreen(t.position);
      final hit = (170 * z).clamp(64.0, 260.0).toDouble();
      if (s.dx < -hit - 140 ||
          s.dy < -hit ||
          s.dx > vp.width + hit + 140 ||
          s.dy > vp.height + hit) {
        continue;
      }
      final near = t.position.distanceTo(hero) < 420;
      children.add(
        Positioned(
          key: ValueKey('town-marker-${t.id}'),
          left: s.dx - hit / 2,
          top: s.dy - hit / 2,
          child: TownMarker(
            town: loc,
            hitSize: hit,
            labelLift: 108 * z + 14,
            showLabel: z >= 0.7 || near,
            selected: _controller.travel.targetPlace == t.id,
            locked: false, // thành phố luôn mở
            onTap: () => _goTo(t.id),
          ),
        ),
      );
    }

    final questAt = <String, List<Mission>>{};
    for (final m in trackedQuestList(state)) {
      if (m.targetId != null) (questAt[m.targetId!] ??= []).add(m);
    }
    // Điểm hiển thị lấy từ luật (điểm đã hoàn thành biến mất hẳn, xem GameRules.mapPoints).
    final shown = GameRules.mapPoints(state);
    for (final loc in shown) {
      if (loc.kind == LocKind.city) continue;
      final p = GameRules.targetPosition(state, loc.id);
      if (p == null) continue;
      final s = camera.worldToScreen(p);
      if (s.dx < -60 ||
          s.dy < -60 ||
          s.dx > vp.width + 60 ||
          s.dy > vp.height + 60) {
        continue;
      }
      children.add(
        Positioned(
          key: ValueKey('poi-${loc.id}'),
          left: s.dx - PoiMarker.width / 2,
          top: s.dy - PoiMarker.iconCenterY,
          child: PoiMarker(
            location: loc,
            done:
                state.cleared.contains(loc.id) ||
                state.explored.contains(loc.id),
            selected: _selPoi == loc.id,
            onTap: () => questAt.containsKey(loc.id)
                ? _goTo(loc.id)
                : _showLocationSheet(loc),
          ),
        ),
      );
    }
    questAt.forEach((id, missions) {
      final p = GameRules.targetPosition(state, id);
      if (p == null) return;
      final s = camera.worldToScreen(p);
      final isTown = worldMap.townById(id) != null;
      final lift = isTown ? 108 * z + 40 : PoiMarker.iconCenterY + 26;
      for (var i = 0; i < missions.length; i++) {
        final m = missions[i];
        children.add(
          Positioned(
            key: ValueKey('quest-target-${m.id}'),
            left:
                s.dx -
                QuestBadge.size / 2 +
                (i - (missions.length - 1) / 2) * 24,
            top: s.dy - lift,
            child: QuestBadge(
              red: templateById(m.templateId).color == MissionColor.red,
            ),
          ),
        );
      }
    });
    return Stack(clipBehavior: Clip.none, children: children);
  }

  Widget _heroLayer(GameController controller, GameState state) {
    final hero = state.hero;
    final s = camera.worldToScreen(hero.position);
    final size = (40 + 20 * camera.zoom).clamp(46.0, 64.0).toDouble();
    // Mũi tên chỉ hướng tới mục tiêu nhiệm vụ đang theo dõi (ẩn khi không có hoặc đã tới nơi).
    double? arrow;
    final tracked = GameRules.trackedMission(state);
    final targetPos = tracked == null
        ? null
        : GameRules.targetPosition(state, tracked.targetId!);
    if (targetPos != null && targetPos.distanceTo(hero.position) > 40) {
      arrow = bearing(s, camera.worldToScreen(targetPos));
    }
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (arrow != null)
              Positioned(
                key: const ValueKey('quest-arrow'),
                left:
                    s.dx +
                    math.cos(arrow) * (size * 0.5 + 12) -
                    QuestArrow.size / 2,
                top:
                    s.dy -
                    size * 0.45 +
                    math.sin(arrow) * (size * 0.5 + 12) -
                    QuestArrow.size / 2,
                child: QuestArrow(angle: arrow),
              ),
            Positioned(
              left: s.dx - 48,
              top: s.dy - HeroMarker.heightFor(size) + 4,
              child: HeroMarker(
                hero: hero,
                identity: state.identity,
                size: size,
                moving: controller.travel.moving,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controls(GameState state) {
    return AnimatedBuilder(
      animation: camera,
      builder: (context, _) {
        final heroScreen = camera.worldToScreen(state.hero.position);
        final vp = camera.viewport;
        final offscreen =
            heroScreen.dx < 0 ||
            heroScreen.dy < 0 ||
            heroScreen.dx > vp.width ||
            heroScreen.dy > vp.height;
        final mid = Offset(vp.width / 2, vp.height / 2);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MapButton(
              key: const ValueKey('map-quests'),
              icon: Icons.menu_book,
              tooltip: 'Nhiệm vụ',
              onTap: () => showQuestPanel(context),
            ),
            const SizedBox(height: 6),
            _MapButton(
              key: const ValueKey('map-zoom-in'),
              icon: Icons.add,
              tooltip: 'Phóng to',
              onTap: () => camera.zoomAround(mid, 1.25),
            ),
            const SizedBox(height: 6),
            _MapButton(
              key: const ValueKey('map-zoom-out'),
              icon: Icons.remove,
              tooltip: 'Thu nhỏ',
              onTap: () => camera.zoomAround(mid, 0.8),
            ),
            const SizedBox(height: 6),
            _MapButton(
              key: const ValueKey('map-recenter'),
              icon: Icons.my_location,
              tooltip: 'Về nhân vật',
              highlight: offscreen,
              onTap: () => _recenter(state),
            ),
          ],
        );
      },
    );
  }
}

/// Nút tròn "Trại" nổi ở giữa cạnh dưới: đường về màn hình Trại (chỉ đổi tab, không đụng GameState).
class _CampButton extends StatelessWidget {
  const _CampButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Trại',
      child: GestureDetector(
        key: const ValueKey('map-camp-button'),
        onTap: onTap,
        child: Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Pal.panelRaised, Pal.panel],
            ),
            border: Border.all(color: Pal.gold, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.holiday_village, color: Pal.goldLight, size: 28),
              Text(
                'Trại',
                style: TextStyle(
                  color: Pal.goldLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool highlight;

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
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: highlight
                    ? const Color(0xFFFFE29A)
                    : const Color(0xFF9C8249),
                width: highlight ? 2 : 1,
              ),
            ),
            child: Icon(icon, color: const Color(0xFFFFD77B), size: 20),
          ),
        ),
      ),
    );
  }
}

/// Một điểm phản hồi trên bản đồ (neo theo tọa độ thế giới).
class _Ping {
  _Ping(this.id, this.at, this.bad);
  final int id;
  final WPoint at;
  final bool bad;
}

/// Vòng sóng ngắn: đỏ khi điểm chạm không hợp lệ, vàng khi nhân vật vừa tới nơi. Tự kết thúc sau một nhịp.
class _PingRing extends StatelessWidget {
  const _PingRing({required this.bad, required this.onDone});

  final bool bad;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOut,
      onEnd: onDone,
      builder: (context, v, _) =>
          CustomPaint(size: const Size(56, 56), painter: _PingPainter(v, bad)),
    );
  }
}

class _PingPainter extends CustomPainter {
  _PingPainter(this.t, this.bad);
  final double t;
  final bool bad;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final color = bad ? const Color(0xFFE0574A) : const Color(0xFFFFE29A);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * (1 - t) + 1
      ..color = color.withValues(alpha: 1 - t);
    canvas.drawCircle(c, 6 + 22 * t, paint);
    if (bad) {
      final k = 7 * (1 - t * 0.4);
      canvas.drawLine(c + Offset(-k, -k), c + Offset(k, k), paint);
      canvas.drawLine(c + Offset(-k, k), c + Offset(k, -k), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PingPainter old) => old.t != t;
}
