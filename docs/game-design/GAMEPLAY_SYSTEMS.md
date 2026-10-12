> **Cập nhật tái thiết:** tài liệu này mô tả prototype v1 (quân theo số lượng, 5 ải). Mô hình hiện hành: docs/game-design/GAMEPLAY_RECONSTRUCTION_PLAN.md và docs/RECONSTRUCTION_CHANGELOG.md.

# Hệ thống gameplay (số liệu nằm ở lib/domain/game_data.dart)

- Khởi đầu: 200 lương, 150 gỗ, 80 sắt, 100 vàng; 10 giáo binh; Nông trại/Đốn gỗ/Mỏ/Doanh trại cấp 1.
- Sản lượng/ngày = cấp x (24 lương, 18 gỗ, 12 sắt, 10 vàng). Canh nông +15% lương/cấp.
- Lương nuôi quân: ceil(quân/2) mỗi ngày. Thiếu lương: 10% mỗi loại quân đào ngũ.
- Chi phí nâng cấp = giá gốc x 1.6^(cấp-1). Sức chứa huấn luyện = 10 x cấp Doanh trại.
- Quân: Giáo (công 6, máu 30), Cung (9, 18, cần DT cấp 2), Kỵ (12, 40, cần DT cấp 3).
  Khắc chế vòng: Giáo > Kỵ > Cung > Giáo (x2.0 khi khắc, x0.5 khi bị khắc).
- Chiến đấu: tối đa 6 hiệp, sát thương đồng thời, nhiễu 0.9-1.1 từ seed, sát thương chia theo tỷ lệ máu.
  Thắng nếu bên ta còn quân và (địch hết quân hoặc ta còn nhiều máu hơn sau hiệp cuối); cùng bị xóa sổ = thua. Chiến thuật: Tấn công (x1.2 / chịu x1.15),
  Cân bằng, Phòng thủ (x0.85 / chịu x0.8). Lò rèn +5% công/cấp; Binh pháp +8%/cấp; Giáp trụ -6% sát thương nhận/cấp.
- Thương vong là vĩnh viễn; thua trận không có thưởng và không mở ải.
- Mỗi ải chỉ đánh một lần thắng: ải đã chiếm không thể đánh lại, thưởng nhận một lần (chống farm, xem docs/qa/ECONOMY_SIMULATION_REPORT.md).
