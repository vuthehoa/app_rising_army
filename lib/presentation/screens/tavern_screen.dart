import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../domain/catalog.dart';
import '../widgets/common.dart';
import '../widgets/hud.dart';
import 'recruit_screen.dart';

/// Quán rượu trong thành phố: chiêu mộ anh hùng từ danh sách ứng viên của ngày bằng vàng.
/// Mọi giao dịch đi qua `GameController.hireAtTavern` (kiểm tra quán, vị trí, giá, chỗ trong doanh trại).
class TavernScreen extends StatelessWidget {
  const TavernScreen({super.key, required this.vendorId});

  final String vendorId;

  @override
  Widget build(BuildContext context) {
    final v = vendorById(vendorId)!;
    final s = ControllerScope.of(context).state!;
    final open = s.visiting == v.cityId;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 40,
        backgroundColor: Pal.panel,
        title: Text(
          v.name,
          style: const TextStyle(
            fontFamily: serif,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: const [ResourceStrip(), SizedBox(width: 12)],
      ),
      body: SafeArea(
        child: open
            ? RecruitScreen(vendorId: vendorId)
            : const Center(child: Text('Bạn không còn ở thành phố này.')),
      ),
    );
  }
}
