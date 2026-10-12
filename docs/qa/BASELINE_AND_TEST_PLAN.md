> **Cập nhật tái thiết:** tài liệu này mô tả prototype v1 (quân theo số lượng, 5 ải). Mô hình hiện hành: docs/game-design/GAMEPLAY_RECONSTRUCTION_PLAN.md và docs/RECONSTRUCTION_CHANGELOG.md.

# Baseline & kế hoạch kiểm thử

Baseline ban đầu: template counter mặc định, 1 file Dart, không có test; `flutter analyze` sạch.
Cấu hình iOS: bundle `com.example.appRisingArmy` (còn mặc định, cần đổi trước khi phát hành),
deployment target 15.0, Info.plist cho phép cả portrait/landscape (app khóa portrait ở runtime).
Không phải Git repo; bản sao lưu bản gốc ở `/Users/it/app_rising_army_backup`.

Test hiện có: `test/domain_test.dart` (kinh tế, tuyển quân, nghiên cứu, chiến đấu, nhiệm vụ, save/migration)
và `test/game_flow_test.dart` (luồng UI, khôi phục save, save hỏng, overflow ở 430x932, 375x667, 320x568).
Lệnh: `dart format lib test && flutter analyze && flutter test && flutter build ios --simulator --debug`.

Chưa kiểm chứng: hiệu năng 60 FPS trên thiết bị thật, build thiết bị/ký, tương tác tay trên simulator.

## Cập nhật Phase 2
Thêm `test/balance_regression_test.dart`; tổng 56 test. Công cụ mô phỏng: `dart run tool/balance_sim.dart`,
`dart run tool/economy_sim.dart` (kết quả: [BALANCE_SIMULATION_REPORT.md](BALANCE_SIMULATION_REPORT.md),
[ECONOMY_SIMULATION_REPORT.md](ECONOMY_SIMULATION_REPORT.md)).
