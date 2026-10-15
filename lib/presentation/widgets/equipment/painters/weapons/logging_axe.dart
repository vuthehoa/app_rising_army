import '../../equipment_painter.dart';

/// Rìu đốn cây: rìu hai tay lưỡi bản rộng, cán cong.
class LoggingAxePainter extends WeaponPainter {
  const LoggingAxePainter();

  @override
  String get designId => 'logging_axe';

  @override
  void paint(G g) {
    final haft = g.smooth(
      [0.54, 0.1, 0.48, 0.4, 0.5, 0.7, 0.46, 0.98],
      close: false,
      tension: 0.4,
    );
    g.stroke(haft, GearColors.outline, 0.07);
    g.stroke(haft, Mat.wood.base, 0.05);
    g.stroke(haft, Mat.wood.light.withValues(alpha: 0.7), 0.014);
    final head = g.smooth([
      0.52,
      0.06,
      0.2,
      0.0,
      0.1,
      0.22,
      0.14,
      0.44,
      0.52,
      0.4,
    ], tension: 0.2);
    g.fill(head, Mat.steel);
    g.fill(
      g.poly([0.5, 0.08, 0.66, 0.1, 0.66, 0.36, 0.5, 0.38]),
      Mat.iron.darker(0.2),
    );
    g.line(0.12, 0.08, 0.14, 0.42, Mat.silver.base, 0.014);
    g.shine(0.22, 0.1, 0.26, 0.34);
    g.rivets([0.58, 0.16, 0.58, 0.3], 0.012, Mat.iron);
  }
}
