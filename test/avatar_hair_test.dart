import 'dart:io';
import 'dart:ui' as ui;

import 'package:app_rising_army/data/new_game_data.dart';
import 'package:app_rising_army/presentation/widgets/avatar/avatar_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ui.Image> _render(
  WidgetTester tester, {
  required AvatarGender gender,
  required HairStyle style,
  PortraitHeadwear headwear = PortraitHeadwear.none,
  Size size = const Size(180, 180),
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF1E2A33));
  AvatarPainter(
    gender: gender,
    hairStyle: style,
    hairColor: const Color(0xFF3A2418),
    eyeColor: const Color(0xFF4B3321),
    skinColor: const Color(0xFFE8B98F),
    seed: 1,
    headwearStyle: headwear,
  ).paint(canvas, size);
  return recorder.endRecording().toImage(
    size.width.round(),
    size.height.round(),
  );
}

void main() {
  testWidgets('every hair style paints at several sizes and headwear', (
    tester,
  ) async {
    await tester.runAsync(() async {
      for (final gender in AvatarGender.values) {
        for (final style in HairStyle.values) {
          for (final size in const [
            Size(60, 70),
            Size(180, 180),
            Size(300, 354),
          ]) {
            await _render(tester, gender: gender, style: style, size: size);
          }
          for (final hat in PortraitHeadwear.values) {
            await _render(tester, gender: gender, style: style, headwear: hat);
          }
        }
      }
    });
  });

  // Chạy với AVATAR_SHEET_DIR=<thư mục> để xuất bảng so sánh PNG.
  testWidgets('export hair contact sheet', (tester) async {
    final dir = Platform.environment['AVATAR_SHEET_DIR'];
    if (dir == null) return;

    await tester.runAsync(() async {
      Future<void> sheet(
        String name,
        AvatarGender gender,
        PortraitHeadwear hat,
      ) async {
        const cell = 180.0;
        const cols = 4;
        final rows = (HairStyle.values.length / cols).ceil();
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        for (var i = 0; i < HairStyle.values.length; i++) {
          final img = await _render(
            tester,
            gender: gender,
            style: HairStyle.values[i],
            headwear: hat,
          );
          canvas.drawImage(
            img,
            Offset((i % cols) * cell, (i ~/ cols) * cell),
            Paint(),
          );
        }
        final out = await recorder.endRecording().toImage(
          (cols * cell).round(),
          (rows * cell).round(),
        );
        final bytes = await out.toByteData(format: ui.ImageByteFormat.png);
        File('$dir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
      }

      await sheet('male', AvatarGender.male, PortraitHeadwear.none);
      await sheet('female', AvatarGender.female, PortraitHeadwear.none);
      await sheet(
        'female_helmet',
        AvatarGender.female,
        PortraitHeadwear.helmet,
      );
      await sheet(
        'male_official',
        AvatarGender.male,
        PortraitHeadwear.official,
      );
      await sheet('male_cloth', AvatarGender.male, PortraitHeadwear.cloth);
    });
  });
}
