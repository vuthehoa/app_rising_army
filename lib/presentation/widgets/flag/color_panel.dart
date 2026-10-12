// =============================================================================
// BẢNG MÀU
// =============================================================================
import 'package:app_rising_army/domain/identity.dart';
import 'package:app_rising_army/domain/identity_catalog.dart';
import 'package:flutter/material.dart';

class ColorPanel extends StatelessWidget {
  const ColorPanel({
    super.key,
    required this.draft,
    required this.onSelectPrimary,
    required this.onSelectSecondary,
    required this.onSelectEmblem,
  });

  final IdentityDraft draft;
  final ValueChanged<String> onSelectPrimary;
  final ValueChanged<String> onSelectSecondary;
  final ValueChanged<String> onSelectEmblem;

  static const Color _panel = Color(0xFF22251E);
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _muted = Color(0xFFA7A795);
  static const Color _border = Color(0xFF414436);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border, width: 0.8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _colorRow(
            label: 'CHÍNH',
            selectedId:
                draft.primaryColorId ?? IdentityCatalog.defaultPrimaryColorId,
            onSelect: onSelectPrimary,
          ),
          const SizedBox(height: 7),
          _colorRow(
            label: 'PHỤ',
            selectedId:
                draft.secondaryColorId ??
                IdentityCatalog.defaultSecondaryColorId,
            onSelect: onSelectSecondary,
          ),
          const SizedBox(height: 7),
          _colorRow(
            label: 'HUY HIỆU',
            selectedId:
                draft.emblemColorId ?? IdentityCatalog.defaultEmblemColorId,
            onSelect: onSelectEmblem,
          ),
        ],
      ),
    );
  }

  Widget _colorRow({
    required String label,
    required String selectedId,
    required ValueChanged<String> onSelect,
  }) {
    return SizedBox(
      height: 31,
      child: Row(
        children: [
          SizedBox(
            width: 59,
            child: Text(
              label,
              maxLines: 1,
              style: const TextStyle(
                color: _muted,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: IdentityCatalog.colors.map((color) {
                  final selected = color.id == selectedId;

                  return GestureDetector(
                    onTap: () => onSelect(color.id),
                    child: Container(
                      width: 25,
                      height: 25,
                      margin: const EdgeInsets.only(right: 7),
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? _gold : Colors.transparent,
                          width: 1.8,
                        ),
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(color.argb),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                            width: 0.5,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
