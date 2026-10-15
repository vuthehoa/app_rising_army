import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../application/game_controller.dart';
import '../../core/theme.dart';
import '../../domain/identity.dart' show maxDisplayNameLength;
import '../../domain/models.dart';

/// Hộp thoại đổi tên binh sĩ DÙNG CHUNG (hồ sơ lính, Roster). Chỉ ghi tên khi bấm Lưu và luật chấp nhận
/// (`GameRules.rename`: bỏ khoảng trắng thừa, 1–24 ký tự); Hủy hoặc đóng giữ nguyên tên. Bố cục gọn để ở màn
/// landscape thấp (kể cả khi bàn phím mở) ô nhập và hai nút Hủy/Lưu luôn nằm trong màn hình.
Future<void> showRenameSoldierDialog(
  BuildContext context,
  GameController controller,
  Soldier soldier,
) => showDialog<void>(
  context: context,
  builder: (_) => RenameSoldierDialog(controller: controller, soldier: soldier),
);

class RenameSoldierDialog extends StatefulWidget {
  const RenameSoldierDialog({
    super.key,
    required this.controller,
    required this.soldier,
  });
  final GameController controller;
  final Soldier soldier;

  @override
  State<RenameSoldierDialog> createState() => _RenameSoldierDialogState();
}

class _RenameSoldierDialogState extends State<RenameSoldierDialog> {
  late final TextEditingController _text = TextEditingController(
    text: widget.soldier.name,
  );
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _save() {
    final r = widget.controller.rename(widget.soldier.id, _text.text);
    if (r.ok) {
      Navigator.pop(context);
    } else {
      setState(() => _error = r.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: const ValueKey('rename-dialog'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Đổi tên binh sĩ',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey('soldier-rename-field'),
                controller: _text,
                autofocus: true,
                maxLength: maxDisplayNameLength,
                maxLengthEnforcement: MaxLengthEnforcement.none,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                decoration: InputDecoration(
                  isDense: true,
                  border: const OutlineInputBorder(),
                  errorText: _error,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    key: const ValueKey('soldier-rename-cancel'),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    key: const ValueKey('soldier-rename-ok'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Pal.goldDeep,
                    ),
                    onPressed: _save,
                    child: const Text('Lưu'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
