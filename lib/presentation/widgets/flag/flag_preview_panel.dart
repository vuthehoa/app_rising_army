// =============================================================================
// KHUNG XEM TRƯỚC QUÂN KỲ
// =============================================================================

import 'package:app_rising_army/domain/identity.dart';
import 'package:flutter/services.dart';
import 'package:app_rising_army/presentation/widgets/flag/flag_view.dart';
import 'package:flutter/material.dart';

class FlagPreviewPanel extends StatefulWidget {
  const FlagPreviewPanel({
    super.key,
    required this.flag,
    required this.onRandomize,
    required this.legionName,
    required this.onLegionNameChanged,
    this.nameError,
  });

  final LegionFlag flag;
  final VoidCallback onRandomize;

  /// Tên quân đoàn hiện tại (nguồn là state của màn tạo game; panel không giữ bản riêng).
  final String legionName;
  final ValueChanged<String> onLegionNameChanged;
  final String? nameError;

  @override
  State<FlagPreviewPanel> createState() => _FlagPreviewPanelState();
}

class _FlagPreviewPanelState extends State<FlagPreviewPanel> {
  late final TextEditingController _name = TextEditingController(
    text: widget.legionName,
  );

  @override
  void didUpdateWidget(FlagPreviewPanel old) {
    super.didUpdateWidget(old);
    // Đồng bộ khi state đổi từ bên ngoài (random). Gõ tay thì giá trị đã bằng nhau nên không động tới con trỏ.
    if (widget.legionName != _name.text) {
      _name.value = TextEditingValue(
        text: widget.legionName,
        selection: TextSelection.collapsed(offset: widget.legionName.length),
      );
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  static const Color _panel = Color(0xFF22251E);
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _muted = Color(0xFFA7A795);
  static const Color _border = Color(0xFF414436);

  @override
  Widget build(BuildContext context) {
    final composition = composeFlag(widget.flag);

    return Container(
      height: 250,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flag_rounded, color: _gold, size: 15),
              SizedBox(width: 6),
              Text(
                'XEM TRƯỚC QUÂN KỲ',
                style: TextStyle(
                  color: _muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 210,
                  maxHeight: 112,
                ),
                child: AspectRatio(
                  aspectRatio: composition.aspectRatio,
                  child: FlagView(composition: composition, showBorder: true),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Tooltip(
            message: 'Tạo quân kỳ ngẫu nhiên',
            child: Material(
              color: _gold.withValues(alpha: 0.14),
              shape: StadiumBorder(
                side: BorderSide(color: _gold.withValues(alpha: 0.7)),
              ),
              child: InkWell(
                key: const ValueKey('randomize-flag'),
                customBorder: const StadiumBorder(),
                onTap: widget.onRandomize,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: 44,
                    minWidth: 44,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.casino_rounded, color: _gold, size: 19),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Ngẫu nhiên',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _gold,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 56,
            child: TextField(
              key: const ValueKey('legion-name-field'),
              controller: _name,
              onChanged: widget.onLegionNameChanged,
              maxLength: maxLegionNameLength,
              inputFormatters: [
                LengthLimitingTextInputFormatter(maxLegionNameLength),
              ],
              textInputAction: TextInputAction.done,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                counterText: '',
                labelText: 'Tên quân đoàn',
                hintText: 'Nhập tên quân đoàn...',
                errorText: widget.nameError,
                errorStyle: const TextStyle(fontSize: 9, height: 0.8),
                labelStyle: const TextStyle(color: _muted, fontSize: 12),
                hintStyle: const TextStyle(color: _muted, fontSize: 12),
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.25),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _gold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
