import 'package:flutter/material.dart';

import '../../domain/dev_mode.dart';
import 'common.dart';

/// Nút bật/tắt Develop Mode, phủ lên mọi màn hình (giữa mép trên) (đặt ở MaterialApp.builder, ngoài MainMenuScreen).
/// Không được dựng ở bản release ([DevMode.available] là false).
class DevModeToggle extends StatelessWidget {
  const DevModeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    if (!DevMode.available) return const SizedBox.shrink();

    final c = ControllerScope.of(context);
    final on = c.devMode;

    // Đặt ở giữa mép TRÊN: góc dưới-trái từng che nút hành động đầu tiên của Deploy ("Deploy Units") và các thanh
    // nút dưới ở màn hẹp (667×375, 844×390), làm cú chạm vào nút bị nút này nuốt.
    return Align(
      alignment: Alignment.topCenter,
      child: SafeArea(
        child: Padding(
          // Dải mép trên (≈ 36px đầu) trống ở mọi màn hình: hai nút debug đứng cạnh nhau hai bên tâm, không xuống hàng dưới.
          padding: const EdgeInsets.fromLTRB(4, 4, 104, 4),
          child: Material(
            key: const ValueKey('dev-mode-toggle'),
            color: on
                ? const Color(0xFFFFB300)
                : Colors.black.withValues(alpha: 0.45),
            shape: StadiumBorder(
              side: BorderSide(
                color: on ? Colors.black87 : Colors.white24,
                width: 0.8,
              ),
            ),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => c.setDevMode(!on),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                child: Text(
                  on ? 'DEV MODE: ON' : 'DEV MODE: OFF',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: on ? Colors.black : Colors.white54,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
