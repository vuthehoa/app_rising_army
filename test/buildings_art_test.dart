import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/presentation/widgets/buildings/buildings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'mọi widget công trình vẽ được ở kích thước nhỏ/lớn, không overflow',
    (tester) async {
      final widgets = <Widget Function(double?)>[
        for (final t in FacilityType.values) (s) => FacilityArt(t, size: s),
        (s) => MeleeYardArt(size: s),
        (s) => ArcheryRangeArt(size: s),
        (s) => EnduranceYardArt(size: s),
        (s) => InfirmaryArt(size: s),
        (s) => CampfireArt(size: s),
        (s) => BarracksSceneArt(size: s),
        (s) => TrainingGroundSceneArt(size: s),
        (s) => InfirmarySceneArt(size: s),
        (s) => SmithySceneArt(size: s),
        (s) => TavernSceneArt(size: s),
        (s) => BoardSceneArt(size: s),
        (s) => GateSceneArt(size: s),
      ];

      for (final size in const [32.0, 120.0, 320.0]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Wrap(children: [for (final w in widgets) w(size)]),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(CustomPaint), findsAtLeastNWidgets(widgets.length));
      }
    },
  );
}
