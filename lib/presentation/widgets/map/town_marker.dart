import 'package:flutter/material.dart';

import '../../../domain/catalog.dart';

/// Vùng chạm + nhãn tên của thị trấn (hình thị trấn do painter vẽ). Chạm chỉ CHỌN thị trấn, không đi.
class TownMarker extends StatelessWidget {
  const TownMarker({
    super.key,
    required this.town,
    required this.hitSize,
    required this.labelLift,
    required this.showLabel,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final LocationDef town;

  /// Cạnh vùng chạm vuông quanh tâm thị trấn (px màn hình).
  final double hitSize;

  /// Khoảng nhấc nhãn lên trên tâm (px màn hình).
  final double labelLift;
  final bool showLabel;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: town.name,
      child: SizedBox(
        width: hitSize,
        height: hitSize,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: const SizedBox.expand(),
            ),
            if (selected)
              IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFE29A),
                      width: 2,
                    ),
                    color: const Color(0x22FFE29A),
                  ),
                ),
              ),
            if (showLabel || selected)
              Positioned(
                top: hitSize / 2 - labelLift,
                left: -140,
                right: -140,
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xF0233025),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFFFFE29A)
                              : const Color(0xFF9C8249),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            locked ? Icons.lock_outline : Icons.castle,
                            size: 12,
                            color: const Color(0xFFF0C66D),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            town.name,
                            maxLines: 1,
                            softWrap: false,
                            style: const TextStyle(
                              color: Color(0xFFFFE9B6),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
