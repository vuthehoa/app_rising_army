import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/presentation/screens/roster_screen.dart';
import 'package:app_rising_army/presentation/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> json({Object? level = #absent}) => {
  'id': 1,
  'type': 'meleeYard',
  'x': 0.2,
  'y': 0.3,
  'assigned': <int>[],
  if (level != #absent) 'level': level,
};

void main() {
  test('mọi đường khởi tạo cho level không null và slots đúng cấp', () {
    final f = Facility(id: 1, type: FacilityType.meleeYard, x: .2, y: .3);
    expect((f.level, f.slots), (1, Facility.capacity));
    f.level = Facility.maxLevel;
    expect(f.slots, Facility.upgradedCapacity);
  });

  test(
    'save cũ thiếu level đọc được, mặc định cấp 1 (3 slot); level 2 giữ 6 slot',
    () {
      final old = Facility.fromJson(json());
      expect((old.level, old.slots), (1, 3));
      final up = Facility.fromJson(json(level: 2));
      expect((up.level, up.slots), (2, 6));
      expect(Facility.fromJson(up.toJson()).slots, 6);
      expect(() => Facility.fromJson(json(level: 'x')), throwsFormatException);
      expect(() => Facility.fromJson(json(level: 3)), throwsFormatException);
    },
  );

  testWidgets('hồ sơ Roster hiển thị số slot theo cấp công trình', (t) async {
    t.view.physicalSize = const Size(932, 430);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final c = GameController(SaveRepository(MemoryStore()));
    await c.init();
    await c.newGame(seed: 1);
    final s = c.state!;
    s.facilities
      ..add(
        Facility(
          id: s.nextFacilityId++,
          type: FacilityType.meleeYard,
          x: .2,
          y: .245,
        ),
      )
      ..add(
        Facility(
          id: s.nextFacilityId++,
          type: FacilityType.archeryRange,
          x: .4,
          y: .245,
          level: 2,
        ),
      );
    await t.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            ControllerScope(controller: c, child: child!),
        home: const Scaffold(body: RosterScreen()),
      ),
    );
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(find.text('Bãi cận chiến 0/3'), findsOneWidget);
    expect(find.text('Bãi bắn cung 0/6'), findsOneWidget);
  });
}
