# LỘ TRÌNH TRIỂN KHAI KỸ THUẬT (IMPLEMENTATION ROADMAP)

**Dự án:** Rising Army Remake (Flutter iOS - Landscape)
**Mục tiêu:** Định hướng phân chia công việc theo Phase, quản lý phụ thuộc module, phòng ngừa hồi quy và thiết lập Testing Gates cho Codex / Claude Code.
**Đường dẫn tập tin:** `docs/game-design/implementation-roadmap.md`

> **Cập nhật theo TASK-003 (đối chiếu với source).** Bản gốc của roadmap coi gần như toàn bộ hệ thống là `[PLANNED]` hoặc `[TO VERIFY]` và nhắc tới các đường dẫn/tên lớp không có trong repository (`lib/domain/services/*`, `lib/domain/engine/battle_simulation_engine.dart`, `CampaignState`, `SaveMigrator`, `SaveEnvelope`…). Bản này ghi lại **hiện trạng đã xác minh** và chỉ giữ dưới `[PLANNED]` những mục chưa có trong source. Source và test là căn cứ; không làm lại các Phase đã có.
>
> **Ghi chú đường dẫn:** `docs/roadmap/implementation-roadmap.md` tồn tại nhưng **rỗng (0 byte)**. Roadmap thực tế là file này.
>
> **Phạm vi xác minh:** các mục `[CURRENT]` dưới đây dựa trên việc đọc source (nêu file) và kết quả `flutter analyze` (không có issue) cùng `flutter test` (781 test pass) chạy ở TASK-001 trên working tree hiện tại. Lượt cập nhật tài liệu này chỉ sửa Markdown và không chạy lại test.

---

## MỤC LỤC

1. [Trạng thái hiện tại](#1-trạng-thái-hiện-tại)
2. [Biểu đồ phụ thuộc module](#2-biểu-đồ-phụ-thuộc-module)
3. [Các Phase](#3-các-phase)
4. [Chi tiết theo Phase](#4-chi-tiết-theo-phase)
5. [Cổng kiểm thử](#5-cổng-kiểm-thử)
6. [Rủi ro và hồi quy](#6-rủi-ro-và-hồi-quy)
7. [Tiêu chuẩn hoàn thành Phase](#7-tiêu-chuẩn-hoàn-thành-phase)
8. [Danh mục công việc đề xuất](#8-danh-mục-công-việc-đề-xuất)

---

## 1. Trạng thái hiện tại

Nhãn: **`[CURRENT]`** đã có trong source; **`[PARTIAL]`** có một phần; **`[PLANNED]`** chưa triển khai; **`[UNVERIFIED]`** chưa đủ bằng chứng.

| Thành phần | Trạng thái | Căn cứ |
| --- | --- | --- |
| Nền tảng Flutter, landscape | `[CURRENT]` | `ios/Runner/Info.plist` chỉ có LandscapeLeft/Right; `lib/main.dart` |
| `GameController` + `ControllerScope` | `[CURRENT]` | `lib/application/game_controller.dart` (ChangeNotifier); `lib/main.dart:25,51` |
| Domain: models, rules, stats, economy | `[CURRENT]` | `lib/domain/models.dart`, `rules.dart`, `stats.dart`, `economy.dart`, `catalog.dart` |
| Camp, công trình, End Day | `[CURRENT]` | `GameRules.tickDay`, `Facility`, `FacilityType`, `building_effects.dart`; test `camp_*`, `construction_test` |
| World map, di chuyển, nhiệm vụ | `[CURRENT]` | `world_map.dart`, `movement.dart`, `terrain_type.dart`, `quest_generator.dart`, `hero_travel.dart`; test `hero_movement_test`, `quest_*` |
| Deploy, đội hình | `[CURRENT]` | `deploy_screen.dart`, `GameRules.maxSquad = 10`, `FormationPreset` (4 preset) |
| Battle simulation | `[CURRENT]` | `simulateBattle` (`lib/domain/battle.dart`), bước 0,1 giây, thuần Dart, theo seed |
| War Horn | `[PLANNED]` | không có trong `lib/` |
| Thời tiết trong trận | `[PLANNED]` | không có trong `lib/domain/` |
| Game modes (Sandbox/Arena) | `[PLANNED]` | `GameState` không có `gameMode` |
| Kết quả trận, thương vong, tiến trình | `[CURRENT]` | `CasualtyKind`, `Winner`, `progression.dart`, `result_screen.dart`; test `resurrection_test`, `xp_eligibility_test` |
| Save envelope v3 | `[CURRENT]` | `{version, checksum, data}` — `lib/data/save_repository.dart` |
| Checksum | `[CURRENT]` FNV-1a 32-bit; SHA-256 `[PLANNED]` | `SaveRepository.checksum` |
| Backup | `[CURRENT]` khóa `save_backup` (SharedPreferences); file `.bak` `[PLANNED]` | `SaveRepository.save/load` |
| Ghi an toàn `.tmp` | `[PLANNED]` | không có trong `lib/data/` |
| Migration | `[CURRENT]` `migrateV1toV3`, `migrateV2toV3`; lưu archive `save_archive_v{n}` | `lib/data/migration_v*_v3.dart`; test `migration_v2_v3_test.dart` |
| Autosave theo hành động | `[CURRENT]` | `GameController._persist()` |
| Autosave khi vào nền | `[PLANNED]` | không có `AppLifecycleState`/`WidgetsBindingObserver` trong `lib/` |
| Trang bị | `[CURRENT]` | `lib/domain/equipment/`, `test/equipment/` |
| Tình trạng binh sĩ (condition), gỡ bế tắc | `[CURRENT]` | `combat_condition.dart`, `GameRules.isSoftlocked`; test `soldier_condition_test`, `softlock_rescue_test` |
| UI responsive, widget test | `[PARTIAL]` | có widget test layout; chưa chạy trên thiết bị/simulator thật `[UNVERIFIED]` |

---

## 2. Biểu đồ phụ thuộc module

Thứ tự phụ thuộc từ tầng thấp lên cao vẫn là nguyên tắc: Domain → Data/Persistence → Application (Controller) → Presentation. Không viết Widget trước khi domain và controller ổn định.

```
Domain models/rules  →  Data (SaveRepository, migration)  →  GameController  →  ControllerScope  →  Presentation
```

Thứ tự này khớp cấu trúc thực tế: `lib/domain`, `lib/data`, `lib/application`, `lib/presentation`.

---

## 3. Các Phase

Các Phase gốc được giữ để đặt tên công việc, nhưng trạng thái dưới đây phản ánh source:

| Phase | Nội dung | Trạng thái |
| --- | --- | --- |
| 0 | Audit và baseline | Đã thực hiện ở TASK-001/TASK-002 (xem mục 4) |
| 1 | Domain models và tính toàn vẹn state | `[CURRENT]` phần lớn; xem mục 4 |
| 2 | Camp và kinh tế | `[CURRENT]` |
| 3 | Map, nhiệm vụ, King's Satisfaction | `[CURRENT]` |
| 4 | Deploy và battle | `[PARTIAL]` — còn War Horn, thời tiết |
| 5 | Save/Load | `[PARTIAL]` — còn SHA-256, `.tmp`, `.bak`, autosave vào nền |
| 6 | UI/UX responsive | `[PARTIAL]` |
| 7 | QA cuối và release candidate | `[PLANNED]` |

---

## 4. Chi tiết theo Phase

### PHASE 0: Audit và baseline — đã thực hiện

* TASK-001: `flutter analyze` — không có issue; `flutter test` — 781 test pass (chạy trên working tree có thay đổi chưa commit). Không chạy `integration_test` hay build iOS.
* TASK-002: đối chiếu tài liệu với source; các sai lệch đã dẫn tới các chỉnh sửa tài liệu ở TASK-003.
* File thực tế: `lib/{domain,data,application,presentation,core}`, `test/`, `tool/`, `ios/`. Dependency chỉ có `shared_preferences` và `cupertino_icons`.

### PHASE 1: Domain models và state — `[CURRENT]`

* Mô hình thực tế nằm trong `lib/domain/models.dart` (`Soldier`, `GameState`, `Facility`, `Mission`, `HeroState`, `ShopStock`), không phải `lib/domain/models/*.dart` riêng từng file. `GameState` có `toJson`/`fromJson` và kiểm tra tính hợp lệ khi đọc (id duy nhất, gán công trình hợp lệ…). Không dùng `copyWith`/immutable: state thay đổi tại chỗ qua `GameRules`.
* Cấp binh sĩ tối đa là **6** (`maxSoldierLevel`, `stats.dart:286`). Ba thuộc tính huấn luyện `Stat {str, dex, con}`; tốc độ là chỉ số dẫn xuất.
* Tài nguyên: `Res {food, coins, wood, iron, tools, stone, cloth}`.
* Công trình: `Building {barracks, smithy, tavern}` (cấp 0–3) và `FacilityType {meleeYard, archeryRange, enduranceYard, infirmary, storageChest, gravestone, barracks}`. Không có `Tents`/`Altar`. Mỗi công trình nhận lính có 3 chỗ (6 ở cấp 2).
* Test: `test/domain_v2_test.dart` (gồm bất biến qua chuỗi hành động ngẫu nhiên có seed).

### PHASE 2: Camp và kinh tế — `[CURRENT]`

* End Day: `GameRules.tickDay` (`rules.dart`), trừ upkeep **theo cấp** từng binh sĩ (`UpkeepEconomy`, `economy.dart:105`), có `paidUpkeep` khi thiếu tài nguyên.
* Sức chứa quân đoàn: `rosterCap = 6 + 4 × cấp Doanh trại` (`rules.dart:321`).
* Hồi sinh tại Bia mộ: HP = 1, `needsTreatment = true`, tốn vàng, cần chỗ trong roster (`rules.dart:639`).
* `[UNVERIFIED]` Mức hồi phục chính xác theo cấp công trình chưa được liệt kê trong tài liệu (xem `building_effects.dart`).

### PHASE 3: Map, nhiệm vụ, King's Satisfaction — `[CURRENT]`

* Di chuyển theo thể lực `HeroState.stamina` (tối đa 100) và hệ số địa hình (`terrain_type.dart`).
* Nhiệm vụ: template trong `catalog.dart`; nhiệm vụ săn (hunt) có hạn 3–7 ngày (`QuestGenerator.minQuestDays/maxQuestDays`), loại khác dùng `days` của template.
* Thua: `kingSatisfaction <= 0 && !victory`. Thắng: hoàn thành nhiệm vụ cuối (`isFinal`).
* `[PLANNED]` Sandbox (hết quân = Game Over). Campaign hiện không thua khi hết quân; có cơ chế gỡ bế tắc `isSoftlocked`/`reliefGrant`.

### PHASE 4: Deploy và battle — `[PARTIAL]`

* `[CURRENT]` Deploy: tối đa 10 binh sĩ, 4 preset (`line`, `expanded`, `wedge`, `cluster`), xếp tự động.
* `[CURRENT]` `simulateBattle(players, enemies, seed)`: bước `stepSeconds = 0.1`, trần `maxBattleSeconds = 120` (1200 nhịp), kết quả `Winner {player, enemy, draw}`; mục tiêu gần nhất, accuracy kẹp 0,40–0,95, chí mạng ×1,5, morale quân ta giảm theo sát thương và bỏ chạy khi về 0.
* `[CURRENT]` Thương vong `CasualtyKind {survived, wounded, dead, deserted}`.
* `[PLANNED]` War Horn; thời tiết; chế độ chạy headless được định nghĩa riêng `[UNVERIFIED]` (hàm thuần Dart nên chạy được trong test).
* `[UNVERIFIED]` Có bộ "100 headless battle" riêng hay không: `combat_state_invariants_test.dart` và các test sim tồn tại, chưa xác nhận số lượng trận.

### PHASE 5: Save/Load — `[PARTIAL]`

* `[CURRENT]` Phong bì `{version: 3, checksum, data}`, checksum FNV-1a 32-bit, backup `save_backup`, archive `save_archive_v{n}`, migration `migrateV1toV3`/`migrateV2toV3`, trạng thái `LoadStatus`. Chi tiết: `game-state-and-save-system.md`.
* `[PLANNED]` (cần xác nhận quyết định giữ hay bỏ): SHA-256; ghi `.tmp` rồi đổi tên; file `.bak`; `timestamp` trong phong bì; autosave khi `AppLifecycleState.paused`; checkpoint giữa trận.
* Tiêu chí nghiệm thu cho các mục `[PLANNED]` trên: test mô phỏng JSON hỏng/checksum sai khôi phục từ bản backup (phần backup đã có test); test vòng đời app.

### PHASE 6: UI/UX responsive — `[PARTIAL]`

* `[CURRENT]` Nhiều màn hình và widget test layout ngang (`landscape_flow_test`, `city_screen_layout_test`, `map_screen_test`…).
* `[UNVERIFIED]` SafeArea/Dynamic Island và vùng chạm tối thiểu 44×44 pt trên thiết bị thật; kích thước iPhone SE landscape.
* `[PLANNED]` War Horn trên `BattleView`, thanh Tide of Battle.

### PHASE 7: QA cuối và release candidate — `[PLANNED]`

* Chưa chạy `integration_test`, E2E playtest hay `flutter build ios --no-codesign`. Không tuyên bố đã đạt.

---

## 5. Cổng kiểm thử

Các cổng gốc giữ nguyên ý nghĩa, nhưng đường dẫn test thực tế là phẳng trong `test/` (và `test/equipment/`), không có `test/domain/`, `test/engine/`, `test/presentation/`.

| Cổng | Lệnh | Ghi chú |
| --- | --- | --- |
| Static | `flutter analyze` | TASK-001: không có issue |
| Toàn bộ test | `flutter test` | TASK-001: 781 test pass |
| Format | `dart format --set-exit-if-changed .` | `[UNVERIFIED]` chưa chạy |

---

## 6. Rủi ro và hồi quy

| Khu vực | Nguy cơ | Phòng ngừa |
| --- | --- | --- |
| Save/Load | Làm hỏng save cũ | Luôn qua `SaveRepository` (migration + archive + backup). Thay đổi schema phải tăng `latestVersion` và thêm bước migration cùng test. Hạn chế hiện có: FNV-1a và ghi trực tiếp không có tệp tạm |
| State | Lính bị trùng id / gán hai công trình | `GameState.fromJson` đã từ chối; test bất biến ngẫu nhiên |
| Battle | Vòng lặp vô hạn | Trần `maxBattleSeconds = 120` (kết quả `draw` khi còn quân hai bên) |
| Cân bằng | Số liệu đã hiệu chỉnh bằng `tool/*_sim.dart` | Không sửa số liệu theo tài liệu thiết kế cũ (roster 20, level 5, upkeep phẳng…) |
| UI | Tràn layout / safe area | Widget test landscape; kiểm thiết bị thật `[PLANNED]` |

---

## 7. Tiêu chuẩn hoàn thành Phase

1. `flutter analyze` không có cảnh báo; code theo format dự án.
2. Test liên quan pass; không làm hỏng test cũ.
3. Thay đổi schema save có migration và test.
4. Chỉ đánh dấu `[CURRENT]` khi có dẫn chứng source/test; mục chưa xác minh phải là `[UNVERIFIED]`, không được tự đánh dấu hoàn tất.

---

## 8. Danh mục công việc đề xuất

Danh mục `TASK-001 … TASK-011` trong bản gốc không còn phù hợp (nhiều việc đã có trong source; số hiệu trùng với các task audit đã thực hiện). Danh sách đề xuất thay thế, theo bằng chứng audit:

* [x] Audit baseline và đối chiếu tài liệu (TASK-001, TASK-002).
* [x] Đồng bộ tài liệu thiết kế với source (TASK-003).
* [ ] Bảo vệ thay đổi chưa commit: docs mới đang `??`, docs cũ đang `D` — việc git, cần chủ dự án quyết định.
* [ ] Quyết định về checksum/ghi an toàn/backup (SHA-256, `.tmp`, `.bak`): giữ hay bỏ; nếu giữ thì thêm migration/tương thích và test.
* [ ] Autosave khi app vào nền.
* [ ] Quyết định thiết kế: trần roster (20 gốc so với `6 + 4n`), Sandbox/Arena, War Horn, thời tiết.
* [ ] Kiểm thử trên simulator/thiết bị: SafeArea, vùng chạm, `integration_test`.
* [ ] Điền tài liệu rỗng còn lại khi có căn cứ.
