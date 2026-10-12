// =============================================================================
// HÀNG ĐIỀU KHIỂN CÓ NÚT TRÁI / PHẢI
// =============================================================================
import 'package:flutter/material.dart';

class OptionRow extends StatelessWidget {
  const OptionRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onPrevious,
    required this.onNext,
    required this.preview,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final Widget preview;

  static const Color _gold = Color(0xFFD4AF37);
  static const Color _panel = Color(0xFF22251E);
  static const Color _border = Color(0xFF414436);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border, width: 0.8),
      ),
      child: Row(
        children: [
          _arrow(icon: Icons.chevron_left_rounded, onTap: onPrevious),

          Expanded(
            child: Center(
              child: SizedBox(
                width: 30,
                height: 30,
                child: Center(child: preview),
              ),
            ),
          ),

          _arrow(
            icon: Icons.chevron_right_rounded,
            onTap: onNext,
            highlighted: true,
          ),
        ],
      ),
    );
  }

  Widget _arrow({
    required IconData icon,
    required VoidCallback onTap,
    bool highlighted = false,
  }) {
    return Material(
      color: highlighted ? _gold.withValues(alpha: 0.12) : Colors.transparent,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: SizedBox(
          width: 30,
          height: 32,
          child: Icon(icon, color: _gold, size: 22),
        ),
      ),
    );
  }
}
