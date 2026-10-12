# Phase 2 Changelog

## Thay đổi gameplay (có bằng chứng)

| Thay đổi | Trước | Sau | Lý do |
|---|---|---|---|
| Điều kiện thắng ([battle_engine.dart](../../lib/domain/battle_engine.dart)): bên tấn công phải còn ít nhất 1 quân | Cùng bị xóa sổ vẫn thắng | Cùng bị xóa sổ = thua (hòa xử thua cho bên tấn công) | Gương cung thủ 10v10: 60,1% -> 36,8% thắng; test biên fail |
| Ải đã chiếm không đánh lại được ([game_rules.dart](../../lib/domain/game_rules.dart)); nút khóa "Đã chiếm" ([campaign_screen.dart](../../lib/presentation/screens/campaign_screen.dart)) | Đánh lại nhận đủ thưởng, vô hạn | Chặn, thưởng chỉ một lần | Farm +45.720 so với +720 tài nguyên/30 ngày |

**Không đổi:** mọi hệ số (khắc chế 2.0/0.5, chiến thuật, nâng cấp), chi phí, sản lượng, lương, save schema
(vẫn v1, checksum/backup/migration giữ nguyên), bundle ID, signing, UI ngoài nút ải đã chiếm.
Hai thay đổi trên là sửa lỗi luật, không phải chỉnh số cân bằng.

## File mới/sửa
- Mới: `tool/sim_common.dart`, `tool/balance_sim.dart`, `tool/economy_sim.dart`,
  `test/balance_regression_test.dart`, `docs/qa/*REPORT.md`, `docs/qa/generated/*`.
- Sửa: `lib/domain/battle_engine.dart`, `lib/domain/game_rules.dart`,
  `lib/presentation/screens/campaign_screen.dart`, `docs/game-design/GAMEPLAY_SYSTEMS.md`,
  `docs/architecture/FEATURE_INVENTORY.md`, `docs/qa/BASELINE_AND_TEST_PLAN.md`.
- Giữ nguyên: `/Users/it/app_rising_army_backup`. Tạo thêm checkpoint `/Users/it/app_rising_army_backup_phase1`.

## Test
Thêm `test/balance_regression_test.dart` (21 test): chiều/độ lớn khắc chế, không nhân chồng, tái lập theo seed,
biên (0 quân, 100.000 quân), 1.500 trận ngẫu nhiên có seed, chống farm, lương/đào ngũ, quest, fuzz 200 ván x 120
hành động (bất biến + save round-trip), hồi phục. Tổng: 56 test.

## Vấn đề còn tồn tại
| Vấn đề | Mức |
|---|---|
| Phòng thủ mạnh hơn Tấn công ở mọi mặt (cần quyết định thiết kế: thêm chi phí/đánh đổi) | Trung bình |
| Đầu tư công trình thống trị tuyển quân; tuyển-quân-trước không tới ải 5 trong 60 ngày | Trung bình |
| Kết quả chiến đấu rất sắc/gần tất định (22 vs 20 quân thắng 100%) | Thấp-TB |
| Sắt dư, vàng/gỗ thiếu; Mỏ/Chợ hoàn vốn 60-72 ngày | Thấp-TB |
| Lương nuôi quân không tác động khi chơi bình thường | Thấp |
| Chưa có đo 60 FPS, chưa chạy trên thiết bị thật; người chơi tự động chỉ là heuristic | Thông tin |

## Sẵn sàng cho phase Tướng lĩnh & Trang bị?
**Gần như, nhưng nên chốt chiến thuật trước.** Nền tảng ổn: luật thuần, tái lập, 56 test, không còn lỗi
nghiêm trọng đã biết về quân số/tài nguyên/thắng thua, save v1 nguyên vẹn. Tướng và trang bị sẽ cộng thêm hệ số
vào chính công thức `công / hệ số nhận`, nên nên giải quyết đánh đổi chiến thuật và cân nhắc độ sắc của kết quả
trước, nếu không các hệ số mới sẽ khuếch đại vấn đề xếp hạng tuyệt đối. Phase đó cũng cần save v2 và migration.
