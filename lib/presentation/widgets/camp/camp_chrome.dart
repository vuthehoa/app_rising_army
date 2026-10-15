import 'package:flutter/material.dart';

import '../../../core/theme.dart';

/// Huy hiệu nhỏ trên cảnh trại (số quân, kho đồ, nhật ký).
class CampBadge extends StatelessWidget {
  const CampBadge({
    super.key,
    required this.icon,
    required this.text,
    required this.tip,
    this.onTap,
    this.warn = false,
  });

  final IconData icon;
  final String text, tip;
  final VoidCallback? onTap;

  /// Làm nổi bật khi đầy/cảnh báo (chỉ đổi màu, không đổi hành vi).
  final bool warn;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tip,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 36),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: warn ? const Color(0xFFF2B8A8) : const Color(0xFFF3DDB0),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Pal.ink, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: Pal.ink),
            const SizedBox(width: 4),
            Text(
              text,
              style: const TextStyle(
                color: Pal.ink,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Nút tròn trên thanh hành động dưới cùng của trại.
class CampBarButton extends StatelessWidget {
  const CampBarButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        constraints: const BoxConstraints(minHeight: 40, minWidth: 80),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE9C985),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Pal.ink, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Pal.ink),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Pal.ink,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
