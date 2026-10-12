# Phase 4 — Báo cáo tái dựng gameplay (Fidelity)

Tài liệu liên quan: `docs/game-design/RISING_ARMY_GAMEPLAY_FIDELITY_AUDIT.md` (bằng chứng + kiểm toán), `docs/game-design/RISING_ARMY_CORE_GAMEPLAY_SPEC.md` (vòng lặp chuẩn).

## 1. Kết quả kiểm tra

| Hạng mục | Kết quả |
|---|---|
| `flutter analyze` | No issues found |
| `flutter test` | 143 test đều qua (gồm 3 test migration v2→v3 mới, landscape 6 kích thước, không overflow) |
| `flutter build ios --simulator --debug` | Thành công |
| `flutter drive` (integration_test) luồng đủ: menu → trại → binh sĩ → tuyển mộ → nhiệm vụ → xây dựng → bản đồ → đội hình → triển khai → Deploy Units → Fight! → chiến đấu → kết quả → về trại | Qua trên iPhone SE (3rd gen), iPhone 15 Pro Max, iPad (A16) |
| Ảnh chụp thật | `docs/qa/generated/phase4/<UDID>/*.png` (14 ảnh mỗi thiết bị) |
| Màn hình | Tất cả landscape; không còn overflow (đã sửa tiêu đề DeployScreen ở 667×375) |

## 2. Đã tái dựng (có bằng chứng ảnh/clip chính thức = VERIFIED/CORROBORATED)
1. **Trại tương tác**: công trình đặt trong trại, kéo-thả binh sĩ vào công trình (sức chứa 3), menu Build, bếp lửa, lều cứu thương.
2. **Huấn luyện theo công trình**: 3 thuộc tính STR/DEX/CON (thay 4 thuộc tính cũ); tập theo ngày khi được gán vào bãi tập.
3. **HP bền vững**: HP giữ giữa các trận, hồi ở trại/lều cứu thương; chết vĩnh viễn khi HP về 0 (bỏ xác suất 80% cũ).
4. **Triển khai trước trận**: kéo binh sĩ vào vùng bên trái, 4 đội hình mẫu, `Deploy Units`, `Fight!`.
5. **Trận thời gian thực có seed** (mô phỏng 0,1 s), vị trí theo mét trên sân 40×24.
6. **Save v3** + migration v1→v3 và v2→v3.

## 3. Kế hoạch migration & rollback
- v2 gốc luôn được lưu nguyên văn ở `save_archive_v2` trước khi chuyển; v1 ở `save_archive_v1`.
- Migration validate qua `fromJson`; lỗi → `migrationFailed`, save gốc không bị ghi đè (có test).
- Quy tắc chuyển: tốc độ gộp vào Khéo léo (trung bình); đang bị thương → 40% HP; đang tập → gán vào cơ sở tương ứng, giữ 50% tiến độ; chết giữ nguyên.
- Rollback mã nguồn: `/Users/it/app_rising_army_backup_phase3` (tạo trước khi tái cấu trúc). Ba backup cũ không bị đụng.

## 4. Thay đổi test (giải thích)
Chỉ chỉnh khi mô hình đổi, không che lỗi: miền thắng pháo đài 0,3–0,95; policy cân bằng chỉ đảm bảo không game over và còn ≥1 binh sĩ sống (trước ≥3) vì chết khi HP về 0 làm tổn thất cao hơn; latestVersion 3; tiêu đề màn đội "Chọn đội •"; luồng chiến đấu mới thay nút "Bỏ qua".

## 5. Kiểm chứng vs giả thuyết
- **VERIFIED**: bố cục camp/map/deploy, 3 thuộc tính, công trình kéo-thả, Deploy Units/ASSIGN_ORDERS/Fight!, 4 đội hình mẫu.
- **PROPOSED (tham số tự đặt, chưa có công thức gốc)**: `damageScale 0.42`, `trainPercentPerDay 25`, `restHealFraction 0.10`, `infirmaryHealFraction 0.40`, tên "Bãi rèn thể lực", thời lượng trận.
- **Đã nêu rõ là chưa làm**: ASSIGN_ORDERS (khóa trong UI, chưa đủ bằng chứng nội dung lệnh).

## 6. Vẫn sai/lệch so với game gốc
- Chiến dịch ~3 giờ so với 100+ ngày; trận cuối pháo đài (boss) xung đột nguồn.
- Điều hướng bằng thanh bên trái (shell) khác với giao diện gốc.
- Bản đồ tự do, thời tiết, điểm hành quân, thị trấn nội cảnh, nhiệm vụ vua theo hạn, tài nguyên gốc, đặc tính, đội trưởng, glory: chưa làm.
- Kinh tế không chỉnh (đóng băng phạm vi); permadeath HP-0 làm tổn thất cao hơn rõ rệt (~11 binh sĩ chết/60 ngày ở policy cân bằng).

## 7. Giới hạn bằng chứng
Chỉ dùng ảnh/clip chính thức Steam, tin tức, review, diễn đàn; không xem được video dài (YouTube chặn), nên công thức chiến đấu, số liệu kinh tế và độ dài chiến dịch chưa xác minh. Danh sách 9 bằng chứng cần thêm nằm ở cuối Core Gameplay Spec.

## 8. Rủi ro
Permadeath làm lệch kinh tế; tham số PROPOSED có thể sai; không commit/push theo ràng buộc.
