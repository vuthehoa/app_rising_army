import 'package:flutter/material.dart';

import '../../../domain/catalog.dart';

/// Dấu địa điểm gameplay (trại địch, tài nguyên, tàn tích) trên bản đồ khám phá.
class PoiMarker extends StatelessWidget {
  const PoiMarker({
    super.key,
    required this.location,
    required this.done,
    required this.selected,
    required this.onTap,
  });

  /// Kích thước vùng chạm; tâm biểu tượng nằm ở (width/2, iconCenterY).
  static const double width = 56, height = 66, iconCenterY = 18;

  final LocationDef location;
  final bool done;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = done
        ? const Color(0xFFB9C2A0)
        : switch (location.kind) {
            LocKind.camp => const Color(0xFFD75C4C),
            LocKind.resource => const Color(0xFFB9D17C),
            LocKind.ruins => const Color(0xFFF0C66D),
            LocKind.city => const Color(0xFFB6D2D5),
          };
    final icon = switch (location.kind) {
      LocKind.camp => done ? Icons.check : Icons.shield,
      LocKind.resource => Icons.grass,
      LocKind.ruins => done ? Icons.check : Icons.account_balance,
      LocKind.city => Icons.castle,
    };
    return Semantics(
      button: true,
      label: location.name,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: width,
          height: height,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: selected ? 40 : 34,
                height: selected ? 40 : 34,
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
                  ],
                ),
                child: Icon(icon, color: color, size: selected ? 21 : 17),
              ),
              if (selected)
                Container(
                  constraints: const BoxConstraints(maxWidth: 110),
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
