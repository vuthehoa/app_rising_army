import '../../equipment_painter.dart';

/// Thương móc: lưỡi cong như liềm có mấu nhọn gắn đầu cán dài.
class BillhookPolePainter extends WeaponPainter {
  const BillhookPolePainter();

  @override
  String get designId => 'billhook_pole';

  @override
  void paint(G g) {
    g.rod(0.5, 0.3, 0.5, 0.98, Mat.wood, 0.05);
    final hook = g.smooth([
      0.46,
      0.34,
      0.44,
      0.18,
      0.54,
      0.06,
      0.68,
      0.1,
      0.62,
      0.2,
      0.56,
      0.3,
      0.54,
      0.34,
    ], tension: 0.3);
    g.fill(hook, Mat.iron);
    g.fill(
      g.poly([0.5, 0.0, 0.54, 0.1, 0.46, 0.1]),
      Mat.steel,
      strokeScale: 0.8,
    );
    g.fill(
      g.poly([0.44, 0.2, 0.34, 0.24, 0.45, 0.28]),
      Mat.iron,
      strokeScale: 0.8,
    );
    g.fill(
      g.poly([0.44, 0.32, 0.56, 0.32, 0.55, 0.4, 0.45, 0.4]),
      Mat.iron.darker(0.2),
      strokeScale: 0.8,
    );
    g.shine(0.52, 0.1, 0.62, 0.14);
  }
}
