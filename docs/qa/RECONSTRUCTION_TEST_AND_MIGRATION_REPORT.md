# Báo cáo test, migration và xác minh thực tế

## Lệnh đã chạy và kết quả
| Lệnh | Kết quả |
|---|---|
| `flutter analyze` | Không có vấn đề |
| `flutter test` | **78 test pass** (59 domain/save/migration + 19 widget landscape) |
| `flutter build ios --simulator --debug` | Thành công |
| `flutter drive` (integration_test) trên 3 simulator, mỗi nơi chụp 12 màn hình | iPhone SE (3rd gen): pass; iPhone 15 Pro Max: pass; iPad (A16): pass |
| `dart run tool/battle_sim.dart` | 25.000 trận có seed (xem GAMEPLAY_RECONSTRUCTION_PLAN) |

Android: **không kiểm thử**. Dự án không có thư mục `android/` (chỉ có `ios/`), nên không có cấu hình orientation Android để sửa hay build.
Thiết bị thật và 60 FPS: **chưa kiểm thử, chưa đo**.

## Orientation (kiểm tra bằng chạy thực tế, không chỉ đọc cấu hình)
- Flutter: cấu hình tập trung ở `main.dart` (`landscapeOnly`), test khẳng định chỉ có hai hướng ngang.
- iOS `Info.plist`: iPhone và iPad chỉ còn LandscapeLeft/Right; thêm `UIRequiresFullScreen` cho iPad; không còn "Portrait" ở Info.plist và project.pbxproj.
- Trên simulator: ứng dụng mở thẳng ở landscape; ảnh chụp 12 màn hình đi qua toàn bộ route chính (menu, trại, binh sĩ, hộp thoại trang bị, tuyển mộ, nhiệm vụ, xây dựng, bản đồ, chuẩn bị đội hình, trận đánh, kết quả).
- Widget test ở 6 kích thước ngang (932×430, 844×390, 667×375, 1024×768, 1194×834, 1280×800), gồm 16:9, ~2.17:1, 4:3, 16:10: không overflow.
- Lỗi thật tìm thấy nhờ chạy thực tế: thông báo SnackBar che nút "Xuất quân" trên iPhone SE; đã thay bằng thông báo overlay không chặn chạm.

## Migration save v1 → v2
Thiết kế: chạy trong `SaveRepository.load()` (không ở widget). Save v1 gốc luôn được sao nguyên bản vào khóa `save_archive_v1` trước khi làm gì khác;
dữ liệu v1 còn được giữ trong trường `legacy` của save v2; lần lưu đầu tiên đẩy bản v1 vào backup. Checksum, backup, kiểm tra phiên bản được giữ nguyên.
Nếu migration lỗi: trạng thái `migrationFailed`, **không ghi đè gì**, bản gốc còn nguyên; UI báo rõ cho người chơi.
Quy tắc chuyển: mỗi đơn vị cũ (kể cả đang huấn luyện) → một binh sĩ riêng có trang bị khởi điểm; công nghệ → +chỉ số (Binh pháp +sức mạnh, Giáp trụ +thể trạng), Canh nông → +50 thức ăn mỗi cấp;
Doanh trại/Lò rèn giữ cấp (tối đa 3), Học viện → Bãi tập cấp 2; công trình sản xuất cũ bị bỏ, phần nâng cấp thêm đổi thành 40 đồng xu/cấp; 5 ải → số nhiệm vụ hoàn thành và hài lòng +4/ải.
Test: chuyển thành công (quân, tài nguyên, công trình, tiến trình), tái lập, lưu rồi tải lại, giữ bản lưu trữ, v1 hỏng dữ liệu, thiếu trường/quá nhiều quân/loại quân lạ,
checksum sai, khôi phục từ backup v1 và v2, dữ liệu v2 vô lý, phiên bản mới hơn app.
Hạn chế: v1 từng có 5 loại nhiệm vụ đã nhận thưởng; thông tin này chỉ còn trong `legacy`. Chưa thử migration trên save v1 thật từ thiết bị (chỉ có fixture trong test).

## Phạm vi test gameplay
ID/trạng thái binh sĩ, tuyển mộ, chỉ số suy ra, đặc điểm, trang bị (vai trò, cấp, sức mạnh yêu cầu, hoán đổi kho), mua đồ, huấn luyện và lên cấp, thương tích và hồi phục,
permadeath (không hồi sinh, id không tái dùng), tinh thần, lương, đào ngũ, nhiệm vụ (nhận, nộp, hạn, phạt, game over), khám phá, viễn chinh, phục kích, trại sạch một lần,
chiến thắng cuối game, đường cong độ khó, fuzz 150 ván × 150 hành động (bất biến + lưu/tải), luồng hoàn chỉnh trại→nhiệm vụ→trận→kết quả→về trại cả ở mức domain và UI.

## Test cũ đã bỏ/viết lại và lý do
Mô hình gameplay thay đổi hoàn toàn (số lượng quân → binh sĩ cá nhân; ải cố định → nhiệm vụ/bản đồ) nên các test của prototype v1
(`domain_test`, `balance_regression_test`, `game_flow_test`) và công cụ `tool/balance_sim.dart`, `tool/economy_sim.dart` không còn áp dụng.
Giá trị được giữ: kiểm tra bất biến fuzz, khôi phục backup, checksum, migration framework, kiểm tra không overflow. Bản gốc ở `/Users/it/app_rising_army_backup_phase2`.
Các báo cáo Phase 2 (BALANCE/ECONOMY) mô tả prototype v1 và chỉ còn giá trị lịch sử.
