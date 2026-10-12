> **Cập nhật tái thiết:** tài liệu này mô tả prototype v1 (quân theo số lượng, 5 ải). Mô hình hiện hành: docs/game-design/GAMEPLAY_RECONSTRUCTION_PLAN.md và docs/RECONSTRUCTION_CHANGELOG.md.

# Kiến trúc game

Feature-light, phân lớp; không dùng BLoC/DI vì MVP chưa cần (tránh abstraction thừa).

```
lib/
  domain/        Luật thuần Dart, không import Flutter
    models.dart        GameState, enum, (de)serialize + validate
    game_data.dart     Toàn bộ số liệu cân bằng
    battle_engine.dart simulateBattle(player, enemy, seed) - xác định
    game_rules.dart    upgrade / recruit / research / endDay / launchBattle / quest
  data/save_repository.dart   Envelope {version, checksum, data}, bản dự phòng, migration
  application/game_controller.dart  ChangeNotifier; mọi thay đổi đi qua đây rồi tự lưu
  presentation/  Màn hình + widget; chỉ gọi controller
  core/theme.dart  Hệ thống thiết kế
```

Quy tắc đã áp dụng: công thức không nằm trong UI; widget không sửa state trực tiếp; random có seed
(`battleSeed` lưu trong save); không cần mạng. Save: ghi bản chính, bản cũ chuyển sang backup; tải
thất bại (JSON hỏng, checksum sai, version lạ, dữ liệu vô lý) thì thử backup, rồi báo `corrupted`.
Lưu bằng `shared_preferences` (ổn định, offline).

Thời gian trong game theo NGÀY, do người chơi bấm "Kết thúc ngày" (deterministic, dễ test).
