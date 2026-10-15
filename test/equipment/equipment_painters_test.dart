import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:app_rising_army/domain/equipment/equipment_catalog.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/presentation/widgets/equipment/equipment_painter.dart';
import 'package:app_rising_army/presentation/widgets/equipment/equipment_registry.dart';
import 'package:flutter_test/flutter_test.dart';

const _px = 64;

Future<Uint8List> _raster(EquipmentPainter p, {int px = _px}) async {
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  p.paint(G(canvas, Size(px.toDouble(), px.toDouble())));
  final img = await rec.endRecording().toImage(px, px);
  final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
  return data!.buffer.asUint8List();
}

double _inkRatio(Uint8List rgba) {
  var n = 0;
  for (var i = 3; i < rgba.length; i += 4) {
    if (rgba[i] > 24) n++;
  }
  return n / (rgba.length / 4);
}

/// Tỉ lệ điểm ảnh khác nhau rõ rệt giữa hai ảnh (màu hoặc độ phủ).
double _diff(Uint8List a, Uint8List b) {
  var n = 0;
  for (var i = 0; i < a.length; i += 4) {
    final da =
        (a[i] - b[i]).abs() +
        (a[i + 1] - b[i + 1]).abs() +
        (a[i + 2] - b[i + 2]).abs();
    final dalpha = (a[i + 3] - b[i + 3]).abs();
    if (dalpha > 100 || (a[i + 3] > 100 && b[i + 3] > 100 && da > 60)) n++;
  }
  return n / (a.length / 4);
}

/// Khác biệt hình bao (chỉ xét alpha).
double _silhouetteDiff(Uint8List a, Uint8List b) {
  var n = 0;
  for (var i = 3; i < a.length; i += 4) {
    if ((a[i] > 100) != (b[i] > 100)) n++;
  }
  return n / (a.length / 4);
}

void main() {
  group('Painter ↔ catalog', () {
    test(
      'mỗi thiết kế có đúng một painter đúng loại; không painter mồ côi',
      () {
        expect(EquipmentRegistry.count, 170);
        expect(EquipmentRegistry.missing(), isEmpty);
        expect(EquipmentRegistry.orphans(), isEmpty);
        expect(EquipmentRegistry.forSlot(Slot.armor).length, 50);
        expect(EquipmentRegistry.forSlot(Slot.weapon).length, 100);
        expect(EquipmentRegistry.forSlot(Slot.shield).length, 20);
        for (final d in EquipmentCatalog.all) {
          final p = EquipmentRegistry.of(d.id);
          expect(p.designId, d.id);
          expect(p.slot, d.slot, reason: d.id);
          expect(
            switch (d.slot) {
              Slot.armor => p is ArmorPainter,
              Slot.weapon => p is WeaponPainter,
              Slot.shield => p is ShieldPainter,
            },
            isTrue,
            reason: '${d.id}: lớp painter đúng loại',
          );
        }
      },
    );

    test('thiếu mapping thì báo lỗi rõ ràng, không âm thầm vẽ sai', () {
      expect(
        () => EquipmentRegistry.of('khong_co_thiet_ke'),
        throwsA(isA<EquipmentPainterMissing>()),
      );
      expect(EquipmentRegistry.maybe('khong_co_thiet_ke'), isNull);
    });

    test('mỗi painter nằm trong tệp riêng đúng thư mục và tên theo id', () {
      for (final d in EquipmentCatalog.all) {
        final dir = switch (d.slot) {
          Slot.armor => 'armor',
          Slot.weapon => 'weapons',
          _ => 'shields',
        };
        final f = File(
          'lib/presentation/widgets/equipment/painters/$dir/${d.id}.dart',
        );
        expect(f.existsSync(), isTrue, reason: f.path);
        final src = f.readAsStringSync();
        // Một tệp = một thiết kế: đúng một lớp painter, khai báo đúng id.
        expect(
          RegExp(r'class \w+Painter extends').allMatches(src).length,
          1,
          reason: d.id,
        );
        expect(
          src.contains("String get designId => '${d.id}';"),
          isTrue,
          reason: d.id,
        );
        expect(
          src.length,
          greaterThan(500),
          reason: '${d.id} không được là tệp rỗng/giữ chỗ',
        );
      }
      // Không có tệp dư.
      for (final dir in ['armor', 'weapons', 'shields']) {
        final files =
            Directory('lib/presentation/widgets/equipment/painters/$dir')
                .listSync()
                .whereType<File>()
                .map((f) => f.uri.pathSegments.last.replaceAll('.dart', ''))
                .toSet();
        final expected = {
          for (final d in EquipmentCatalog.all)
            if ((d.slot == Slot.armor && dir == 'armor') ||
                (d.slot == Slot.weapon && dir == 'weapons') ||
                (d.slot == Slot.shield && dir == 'shields'))
              d.id,
        };
        expect(files, expected, reason: dir);
      }
    });

    test(
      'painter chỉ dùng Canvas/Path (không ảnh mạng, không văn bản/emoji)',
      () {
        final emoji = RegExp(
          r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]',
          unicode: true,
        );
        for (final f
            in Directory('lib/presentation/widgets/equipment')
                .listSync(recursive: true)
                .whereType<File>()
                .where((f) => f.path.endsWith('.dart'))) {
          final src = f.readAsStringSync();
          expect(src.contains('Image.network'), isFalse, reason: f.path);
          expect(src.contains('NetworkImage'), isFalse, reason: f.path);
          expect(
            src.contains('http://') || src.contains('https://'),
            isFalse,
            reason: f.path,
          );
          expect(src.contains('TextPainter'), isFalse, reason: f.path);
          expect(emoji.hasMatch(src), isFalse, reason: f.path);
        }
      },
    );
  });

  group('Hình vẽ', () {
    testWidgets('mọi painter vẽ ra hình thật và các thiết kế khác nhau rõ rệt', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final rasters = <String, Uint8List>{};
        for (final d in EquipmentCatalog.all) {
          rasters[d.id] = await _raster(EquipmentRegistry.of(d.id));
        }
        // 1) Có nội dung, không tràn kín ô.
        for (final e in rasters.entries) {
          final ink = _inkRatio(e.value);
          expect(ink, greaterThan(0.04), reason: '${e.key} gần như trống');
          expect(ink, lessThan(0.95), reason: '${e.key} phủ kín ô');
        }
        // 2) Mọi cặp trong cùng ô trang bị đều khác nhau rõ rệt (không lặp một hình đổi màu/ID).
        var minAll = 1.0, minSil = 1.0;
        String worst = '';
        for (final slot in [Slot.armor, Slot.weapon, Slot.shield]) {
          final ids = [for (final d in EquipmentCatalog.forSlot(slot)) d.id];
          for (var i = 0; i < ids.length; i++) {
            for (var j = i + 1; j < ids.length; j++) {
              final a = rasters[ids[i]]!, b = rasters[ids[j]]!;
              final dd = _diff(a, b);
              final ss = _silhouetteDiff(a, b);
              if (dd < minAll) {
                minAll = dd;
                worst = '${ids[i]} / ${ids[j]}';
              }
              if (ss < minSil) minSil = ss;
              expect(
                dd,
                greaterThan(0.05),
                reason: '${ids[i]} và ${ids[j]} quá giống nhau',
              );
            }
          }
        }
        // ignore: avoid_print
        print(
          'Khác biệt nhỏ nhất giữa hai thiết kế: ${(minAll * 100).toStringAsFixed(1)}% ($worst); '
          'hình bao nhỏ nhất ${(minSil * 100).toStringAsFixed(1)}%',
        );
      });
    });

    testWidgets('vẽ lặp lại cho kết quả giống hệt (xác định)', (tester) async {
      await tester.runAsync(() async {
        for (final id in ['iron_spear', 'full_plate', 'tower_shield']) {
          final p = EquipmentRegistry.of(id);
          expect(await _raster(p), await _raster(p));
        }
      });
    });
  });
}
