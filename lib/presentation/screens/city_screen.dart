import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../domain/catalog.dart';
import '../../domain/models.dart';
import '../../domain/rules.dart';
import '../widgets/art.dart';
import '../widgets/common.dart';
import '../widgets/hud.dart';
import 'vendor_screen.dart';

/// Thành phố: nơi đến sau khi hành quân. Các gian hàng là điểm tương tác dẫn tới từng người bán.
class CityScreen extends StatelessWidget {
  const CityScreen({super.key, required this.cityId, this.arrival});

  final String cityId;
  final ExpeditionResult? arrival;

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final s = c.state!;
    final city = locationById(cityId)!;
    final list = vendorsIn(cityId);
    final d = Dims(context);
    final here = s.visiting == cityId;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 40,
        backgroundColor: Pal.panel,
        title: Text(
          city.name,
          style: const TextStyle(
            fontFamily: serif,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [const ResourceStrip(), const SizedBox(width: 12)],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(d.pad),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final size = Size(box.maxWidth, box.maxHeight);
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: CityPainter(stalls: list.length),
                            ),
                          ),
                          for (var i = 0; i < list.length; i++)
                            Positioned(
                              left:
                                  (CityPainter.stallCenter(
                                            i,
                                            list.length,
                                            size,
                                          ).dx -
                                          62)
                                      .clamp(2.0, box.maxWidth - 126),
                              top:
                                  (CityPainter.stallCenter(
                                            i,
                                            list.length,
                                            size,
                                          ).dy +
                                          box.maxHeight * 0.09)
                                      .clamp(2.0, box.maxHeight - 52),
                              width: 124,
                              child: _Stall(
                                vendor: list[i],
                                open: GameRules.vendorOpen(s, list[i]) && here,
                                state: s,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              SizedBox(width: d.gap),
              SizedBox(
                width: d.compact ? 230 : 280,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (arrival != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: d.gap),
                          child: Panel(
                            title: 'Hành trình',
                            highlight: true,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final l in arrival!.lines)
                                  Text(
                                    '• $l',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                if (arrival!.missionNote != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      arrival!.missionNote!,
                                      style: const TextStyle(
                                        color: Pal.gold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      Panel(
                        title: 'Thành phố',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              city.blurb,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Kho đồ: ${GameRules.inventoryCount(s)}/${GameRules.inventoryCapacity(s)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color:
                                    GameRules.inventoryCount(s) >=
                                        GameRules.inventoryCapacity(s)
                                    ? Pal.blood
                                    : Pal.text,
                              ),
                            ),
                            Text(
                              '${s.roster.length} binh sĩ • Ngày ${s.day}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (!here)
                              const Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: Text(
                                  'Bạn đã rời thành phố. Phải hành quân lại để giao dịch.',
                                  style: TextStyle(
                                    color: Pal.blood,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            GameButton(
                              label: 'Rời thành phố, về bản đồ',
                              icon: Icons.map,
                              onPressed: () {
                                if (here) c.leaveCity();
                                Navigator.of(context)
                                    .popUntil((r) => r.isFirst);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _Stall extends StatelessWidget {
  const _Stall({required this.vendor, required this.open, required this.state});

  final VendorDef vendor;
  final bool open;
  final GameState state;

  @override
  Widget build(BuildContext context) {
    final locked = !GameRules.vendorOpen(state, vendor);
    return Semantics(
      button: true,
      label: vendor.name,
      child: InkWell(
        onTap: open
            ? () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => VendorScreen(vendorId: vendor.id),
                ),
              )
            : () => toast(
                context,
                locked
                    ? ActionResult.fail(
                        '${vendor.name} chưa mở cửa với bạn (cần hoàn thành ${const [0, 3, 6, 10][vendor.unlockTier]} nhiệm vụ).',
                      )
                    : const ActionResult.fail('Bạn đã rời thành phố.'),
              ),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: Pal.bg.withValues(alpha: open ? 0.88 : 0.7),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: open ? Pal.gold : Pal.line),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                vendor.name,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: open ? Pal.gold : Pal.dim,
                ),
              ),
              Text(
                locked ? 'Đóng cửa' : vendorKindNames[vendor.kind]!,
                style: TextStyle(
                  fontSize: 10,
                  color: locked ? Pal.blood : Pal.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
