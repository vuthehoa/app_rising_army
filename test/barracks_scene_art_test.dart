import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'package:app_rising_army/presentation/widgets/buildings/camp_scene/barracks_scene_art.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hộp bao (tỷ lệ 0..1) của các pixel đã vẽ.
Future<ui.Rect> paintedBounds(Size size) async {
  final r = ui.PictureRecorder();
  const BarracksScenePainter().paint(ui.Canvas(r), size);
  final img = await r.endRecording().toImage(
    size.width.round(),
    size.height.round(),
  );
  final data = (await img.toByteData())!;
  var minX = img.width, minY = img.height, maxX = -1, maxY = -1;
  for (var y = 0; y < img.height; y++) {
    for (var x = 0; x < img.width; x++) {
      if (data.getUint8((y * img.width + x) * 4 + 3) > 16) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }
  return ui.Rect.fromLTRB(
    minX / img.width,
    minY / img.height,
    (maxX + 1) / img.width,
    (maxY + 1) / img.height,
  );
}

void main() {
  testWidgets(
    'doanh trại chiếm phần lớn vùng vẽ ở nhiều kích thước, không bị cắt',
    (tester) async {
      await tester.runAsync(() async {
        for (final size in const [
          Size(64, 44),
          Size(120, 120),
          Size(300, 300),
          Size(320, 200),
        ]) {
          final b = await paintedBounds(size);
          final side = size.shortestSide;
          // Ô vuông cạnh ngắn, căn giữa: hình phải phủ ≥ 85% chiều rộng ô và ≥ 80% chiều cao ô.
          expect(
            (b.width * size.width) / side,
            greaterThan(0.85),
            reason: '$size rộng',
          );
          expect(
            (b.height * size.height) / side,
            greaterThan(0.80),
            reason: '$size cao',
          );
          // Không tràn ra ngoài canvas (không bị cắt).
          expect(b.left, greaterThanOrEqualTo(0), reason: '$size');
          expect(b.top, greaterThanOrEqualTo(0), reason: '$size');
          // Căn giữa theo chiều dài hơn, không méo.
          expect((b.center.dx - 0.5).abs(), lessThan(0.06), reason: '$size');
        }
      });
    },
  );
}
