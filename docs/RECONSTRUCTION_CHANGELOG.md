# Reconstruction Changelog

## Hệ thống cũ: giữ / đổi / bỏ
| Hệ thống v1 | Quyết định |
|---|---|
| Tách domain / application / data / presentation, `GameController` (ChangeNotifier) | **Giữ** |
| Save: phong bì có version + checksum + backup + khung migration | **Giữ**, nâng lên v2, thêm migration v1→v2 và lưu trữ bản gốc |
| Ngẫu nhiên có seed lưu trong save | **Giữ** (`seed + rngCounter`) |
| Quân theo số lượng (3 loại gộp) | **Bỏ**, thay bằng binh sĩ cá nhân; 3 loại thành vai trò |
| Engine chiến đấu tổng sức mạnh, hệ số khắc chế | **Bỏ**; engine theo từng đơn vị (giáo +25% vs kỵ giữ lại như một nét nhỏ) |
| 7 công trình sản xuất, 5 cấp, công nghệ, 5 ải, 5 nhiệm vụ đếm số, qua ngày bằng lương gộp | **Bỏ** (mô hình sai so với gốc) |
| Chống farm "ải chỉ thắng một lần" (Phase 2) | **Giữ ý tưởng**: trại địch quét sạch một lần |
| Portrait UI, icon Material mặc định | **Bỏ**; landscape-only, art vẽ riêng |

## Màn hình đã thiết kế lại (đều landscape)
Menu chính, Trại (cảnh có điểm chạm), Binh sĩ (danh sách + chi tiết cùng lúc, đài tưởng niệm), Hộp thoại trang bị (so sánh trước/sau), Tuyển mộ, Nhiệm vụ nhà vua,
Xây dựng + Lò rèn + Kho đồ, Bản đồ thế giới, Chuẩn bị đội hình (hàng trước/sau), Trận đánh (phát lại có tốc độ), Kết quả/thương vong, Màn game over/chiến thắng, Menu phụ.

## Luồng gameplay thực sự hoạt động (có test)
Tuyển mộ → trang bị → huấn luyện → nhận nhiệm vụ → trinh sát/khám phá → chọn đội hình → hành quân (tốn ngày, lương, đếm hạn) → trận auto-battler → tử trận vĩnh viễn/thương tích/rút lui/XP/lên cấp
→ thu chiến lợi phẩm → báo cáo nhà vua → hài lòng/thưởng → mở vùng mới → nhiệm vụ cuối → thắng. Hài lòng về 0 → thua. Lưu tự động, khôi phục, migration.

## File chính
Mới/viết lại: `lib/domain/*`, `lib/data/*`, `lib/application/game_controller.dart`, `lib/presentation/**`, `lib/core/theme.dart`, `lib/main.dart`,
`test/domain_v2_test.dart`, `test/landscape_flow_test.dart`, `integration_test/screens_test.dart`, `test_driver/integration_test.dart`, `tool/battle_sim.dart`.
Cấu hình: `ios/Runner/Info.plist` (landscape-only), `pubspec.yaml` (thêm `integration_test` từ SDK, không thêm package ngoài). Không đổi bundle ID/signing.
Không xóa `/Users/it/app_rising_army_backup`, `_phase1`; thêm `_phase2` (checkpoint trước tái thiết).

## Giới hạn kỹ thuật còn lại
- Chưa xác minh trực tiếp game gốc (không truy cập Steam/ảnh/video); xem ORIGINAL_GAME_GAP_ANALYSIS.md.
- Art là nguyên mẫu vẽ bằng code; chưa có âm thanh, hoạt ảnh nhân vật, minh họa hoàn thiện.
- Chưa có kèn trận, thành phố/người bán, kỹ năng; danh mục vật phẩm nhỏ (20).
- Cân bằng mới được đo cho chiến đấu (25.000 trận); kinh tế nhiều ngày của mô hình mới chưa mô phỏng; thông số là PROPOSED.
- Không có Android (dự án không có `android/`); chưa chạy trên thiết bị thật; chưa đo 60 FPS.
- `dart format` dùng kiểu mặc định của SDK hiện tại; một số file lớn (rules.dart) cần tách khi mở rộng.
