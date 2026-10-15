# ĐẶC TẢ TRẠNG THÁI GAME VÀ HỆ THỐNG LƯU/TẢI (GAME STATE & SAVE SYSTEM SPECIFICATION)

**Dự án:** Rising Army Remake (Flutter iOS - Landscape)
**Tập tin mục tiêu:** `docs/game-design/game-state-and-save-system.md`

> **Căn cứ và phạm vi (TASK-003).** Bản gốc của tài liệu này bị cắt giữa bảng schema (chỉ còn mục 1 và đầu mục 2); các mục về schema binh sĩ, schema trận đấu, envelope, trigger lưu, invariants và ma trận test **đã mất**. Bản này được dựng lại **chỉ từ source đã đọc**; không khôi phục nội dung cũ. Source và test là căn cứ xác định hành vi hiện có.
>
> Nhãn dùng trong tài liệu: **`[CURRENT]`** = đã xác minh trong source (có dẫn file); **`[PLANNED]`** = mục tiêu thiết kế chưa triển khai; **`[UNVERIFIED]`** = chưa đủ bằng chứng.
>
> File nguồn chính: `lib/domain/models.dart` (`GameState.toJson/fromJson`), `lib/data/save_repository.dart` (`SaveRepository`), `lib/data/migration_v1_v3.dart`, `lib/data/migration_v2_v3.dart`, `lib/application/game_controller.dart`.

---

## MỤC LỤC

1. [Phân vùng dữ liệu](#1-phân-vùng-dữ-liệu)
2. [Schema `GameState` (JSON thực tế)](#2-schema-gamestate-json-thực-tế)
3. [Schema thành phần](#3-schema-thành-phần)
4. [Battle state](#4-battle-state)
5. [Phong bì lưu trữ (Save Envelope v3)](#5-phong-bì-lưu-trữ-save-envelope-v3)
6. [Thời điểm lưu](#6-thời-điểm-lưu)
7. [Tải và migration](#7-tải-và-migration)
8. [Toàn vẹn và phục hồi](#8-toàn-vẹn-và-phục-hồi)
9. [Điều kiện nhất quán khi đọc](#9-điều-kiện-nhất-quán-khi-đọc)
10. [Test hiện có](#10-test-hiện-có)
11. [Mục tiêu chưa triển khai và câu hỏi mở](#11-mục-tiêu-chưa-triển-khai-và-câu-hỏi-mở)

---

## 1. Phân vùng dữ liệu

| Phân vùng | Nội dung | Trạng thái |
| --- | --- | --- |
| Trạng thái ván chơi (lưu đĩa) | Toàn bộ `GameState` (mục 2), được tuần tự hóa vào save | `[CURRENT]` |
| Trạng thái trận đấu | Kết quả `BattleReport` được tạo bởi `simulateBattle` rồi dùng cho UI/kết quả; **không** có trong `GameState.toJson` | `[CURRENT]` (không lưu); xem mục 4 |
| Trạng thái UI tạm | Vị trí đặt công trình, binh sĩ đang di chuyển, trạng thái đi bộ (`travel`)… nằm trong `GameController`, không lưu | `[CURRENT]` (ví dụ `_placing`, `_movingId` bị đặt lại trong `continueGame`) |
| Cấu hình toàn cục (âm lượng, ngôn ngữ, nhiều slot) | Bản gốc của tài liệu nêu `Global State` | `[UNVERIFIED]` — chưa tìm thấy trong phần source đã đọc. Hiện có đúng **một** slot save (`save_primary`) |

Không có chế độ chơi (`gameMode`) trong dữ liệu lưu: source chỉ có luồng Campaign. Sandbox/Arena là `[PLANNED]`.

---

## 2. Schema `GameState` (JSON thực tế)

Nguồn: `GameState.toJson()` và `GameState.fromJson()` trong `lib/domain/models.dart` (từ khoảng dòng 739). `data` trong phong bì là chuỗi `jsonEncode` của đối tượng này.

| Khóa JSON | Kiểu / ý nghĩa | Bắt buộc khi đọc | Ghi chú đọc (`fromJson`) |
| --- | --- | --- | --- |
| `seed` | int | Có | khoảng 0 … 2^40 |
| `day` | int, ngày hiện tại | Có | ≥ 1 |
| `res` | map tên `Res` → int | Có | `Res {food, coins, wood, iron, tools, stone, cloth}`; ghi theo thứ tự enum để JSON ổn định |
| `soldiers` | danh sách `Soldier` | Có | id phải duy nhất |
| `nextSoldierId` | int | Có | phải lớn hơn mọi id binh sĩ |
| `buildings` | map tên `Building` → cấp | Có | `Building {barracks, smithy, tavern}`; cấp 0 = chưa xây, tối đa `maxBuildingLevel = 3` |
| `facilities` | danh sách `Facility` | Có | công trình đặt trong trại; bỏ qua mục `type: campfire` của save cũ |
| `nextFacilityId` | int | Có | phải lớn hơn mọi id công trình |
| `inventory` | map id vật phẩm → số lượng | Có | |
| `candidates` | danh sách `Soldier` ứng viên của Quán rượu | Có | |
| `missions` | danh sách `Mission` | Có | |
| `nextMissionId` | int | Có | |
| `kingSatisfaction` | **int** 0–100 | Có | (là số nguyên, không phải double) |
| `missionsCompleted` | int | Có | |
| `discovered`, `cleared`, `explored` | danh sách chuỗi (sắp xếp) | Có | tập địa điểm/ô đã biết |
| `log` | danh sách chuỗi | Có | nhật ký |
| `rngCounter` | int | Có | bộ đếm cho RNG ngoài trận (xem mục 5 ghi chú) |
| `battlesWon`, `battlesLost`, `fallenTotal` | int | Có | |
| `victory` | bool | Không (mặc định false) | |
| `shops` | map id thị trấn → `ShopStock` | Không (thiếu → map rỗng) | `_readShops`; sai kiểu thì ném lỗi |
| `visiting` | chuỗi hoặc null | Không | thị trấn đang ghé |
| `tradeCount` | int | Không (mặc định 0) | |
| `reliefDay` | int | Không | chỉ ghi khi ≥ 0; thiếu → -1 |
| `nextItemSerial` | int | Không | chỉ ghi khi khác 0; thiếu → 0 |
| `identity` | đối tượng danh tính | Không (đọc lỏng) | thiếu/hỏng → mặc định |
| `hero` | đối tượng `HeroState` | Không (đọc lỏng) | thiếu → đặt tại thị trấn đang ghé hoặc điểm xuất phát |
| `legacy` | đối tượng | Không | giữ nguyên bản save v1 gốc sau migration v1 |

Getter suy ra, **không lưu**: `gameOver => kingSatisfaction <= 0 && !victory` (`models.dart:708`), `sacredWill` (bí danh của `kingSatisfaction`).

Không có trong schema thực tế (xuất hiện trong bản tài liệu cũ): `campaignId`, `campaignName`, `commanderName`, `bannerSymbol`, `bannerColor`, `currentDay`, `gameMode`, tài nguyên rời `gold/food/…`. Tên quân đoàn nằm trong `identity.legionName`; tài nguyên nằm trong `res` (vàng là `coins`).

---

## 3. Schema thành phần

Chỉ liệt kê khóa mà `toJson` thực tế ghi. Giá trị và ràng buộc đọc chưa được kiểm hết: nêu `[UNVERIFIED]` ở nơi chưa đọc.

### 3.1 `Soldier` (`models.dart`, `Soldier.toJson`, khoảng dòng 238–270)

Luôn ghi: `id`, `name`, `role` (`Role {spearman, archer, cavalry}`), `stats` (map `Stat {str, dex, con}` → int), `level`, `xp`, `trait`, `weapon`, `armor`, `accessory`, `shield`, `morale`, `energy`, `hp`, `status` (`SoldierStatus {active, dead, deserted}`), `train` (map `Stat` → int), `kills`, `battles`.

Ghi có điều kiện: `helmet`, `points` (nếu `statPoints > 0`), `atk` (nếu `atkPoints > 0`), `treat: true` (nếu `needsTreatment`), `mastery` (map `WeaponType` → giá trị), `skills`, `talents`, `campX`/`campY`.

Đọc: tên không rỗng, tối đa 40 ký tự; chỉ số `str/dex/con` ≥ 1 và ≤ 60 (`Soldier.fromJson`). Các ràng buộc còn lại: `[UNVERIFIED]`.

### 3.2 `Facility` (công trình trong trại)

`id`, `type` (`FacilityType`), `x`, `y` (tọa độ chuẩn hóa 0–1, ngoài khoảng bị từ chối), `assigned` (danh sách id binh sĩ), `level` (chỉ ghi khi > 1). Sức chứa: 3, hoặc 6 ở cấp 2 (`Facility.capacity`, `upgradedCapacity`, `maxLevel = 2`). Khi đọc `GameState`: id công trình duy nhất, nhỏ hơn `nextFacilityId`; mỗi binh sĩ chỉ được gán một công trình và phải tồn tại.

### 3.3 `Mission`

`id`, `template`, `status` (`MissionStatus {offered, active, completed, failed}`), `deadline`, `progress`; có điều kiện: `days` (nếu > 0), `giver`, `target`, `rewarded` (nếu true), `enc` (điểm giao chiến: `x`, `y`, `d`, `e`), `squad`.

### 3.4 `ShopStock`, `HeroState`, `identity`

* `ShopStock`: `items`, `resources`, `lastRestock`.
* `HeroState`: `x`, `y`, `stamina`.
* `identity`: `avatar` (`displayName`, `appearance`), `flag` (`template`, `pattern`, `emblem`, `primaryColor`, `secondaryColor`, … các khóa màu còn lại `[UNVERIFIED]`), `legionName`. Đọc không bao giờ ném lỗi: thiếu/hỏng/id không còn trong danh mục thì dùng mặc định (`PlayerIdentity.fromJsonLenient`).

### 3.5 Trang bị

Mỗi binh sĩ giữ id trang bị ở `weapon/armor/accessory/shield/helmet`. Số seri vật phẩm toàn cục là `nextItemSerial`. Sau khi giải mã, `EquipmentService.sanitize` đưa trang bị về trạng thái hợp lệ mà không xóa dữ liệu (`save_repository.dart`, `_decode`). Chi tiết hệ thống trang bị: `[UNVERIFIED]` trong tài liệu này (xem `test/equipment/equipment_save_test.dart`).

---

## 4. Battle state

`[CURRENT]` Trận đấu không có trạng thái lưu: `simulateBattle(players, enemies, seed)` (`lib/domain/battle.dart:227`) chạy thuần Dart trên bản sao `BattleUnit`, không sửa `Soldier`/`GameState`, và trả `BattleReport`. Kết quả được áp dụng vào `GameState` sau trận (thương vong, XP…). `GameState.toJson` **không** có khóa nào cho trận đang diễn ra.

`[PLANNED]` Checkpoint giữa trận / khôi phục về màn Deploy khi bị ngắt: chưa triển khai.

`[UNVERIFIED]` Nếu app bị tắt giữa trận, hành vi cụ thể khi mở lại chưa được kiểm; vì trận không được lưu, trạng thái save gần nhất là trước trận.

---

## 5. Phong bì lưu trữ (Save Envelope v3)

Nguồn: `SaveRepository.save` và `_decode` (`lib/data/save_repository.dart`).

```json
{
  "version": 3,
  "checksum": "<hex>",
  "data": "<chuỗi JSON của GameState.toJson()>"
}
```

* `version`: số nguyên; hiện hành `SaveRepository.latestVersion = 3`.
* `data`: **chuỗi** (kết quả `jsonEncode(state.toJson())`), không phải đối tượng lồng.
* `checksum`: **FNV-1a 32-bit** tính trên chuỗi `data` theo từng code unit (offset `0x811c9dc5`, prime `0x01000193`), biểu diễn hex (`SaveRepository.checksum`). Không phải SHA-256 và không dùng thư viện băm.
* Không có `timestamp` và không có `game_mode` trong phong bì.

Lưu trữ bằng giao diện `KeyValueStore` (`read/write/remove`); bản chạy thật `PrefsStore` dùng SharedPreferences (`lib/main.dart:25`), có `MemoryStore` cho test.

| Khóa SharedPreferences | Nội dung |
| --- | --- |
| `save_primary` | phong bì hiện hành |
| `save_backup` | phong bì ngay trước đó (bản `save_primary` cũ) |
| `save_archive_v{n}` | bản lưu nguyên vẹn của save phiên bản cũ `n` (v1, v2), tạo trước khi migration, không ghi đè nếu đã có |

Ghi chú RNG: ngoài trận, `GameRules.rng(state)` = `Random(seed * 7919 + rngCounter++)` (`rules.dart:165`); trong trận, `simulateBattle` dùng `Random(seed)` chuẩn của Dart. Không dùng Mersenne Twister hay Xorshift.

---

## 6. Thời điểm lưu

`[CURRENT]` `GameController` lưu qua `_persist()` (`game_controller.dart:415`), gọi:

* sau mỗi hành động làm thay đổi trạng thái qua `_afterChange()` (khoảng dòng 410–412);
* khi kết thúc ngày (khoảng dòng 374);
* khi hoàn tất di chuyển (`commitTravel`, khoảng dòng 47–50);
* khi quay về menu (`backToMenu`, khoảng dòng 146–147);
* khi tạo ván mới: `newGame` gọi `_persist()` (dòng 112); luồng có danh tính gọi `_repo.save` trực tiếp (dòng 132) và lỗi lưu trả `NewGameResult.saveFailed`, ván hiện tại được giữ;
* sau khi sửa bố cục trại khi nạp save (`continueGame`, dòng 99).

Lỗi lưu được ghi vào `GameController.saveError`.

`[PLANNED]` Lưu khi ứng dụng vào nền (`AppLifecycleState.paused`): chưa có (không tìm thấy `AppLifecycleState` hay `WidgetsBindingObserver` trong `lib/`).

`[UNVERIFIED]` Xóa save khi thua (`SaveRepository.clear()` có định nghĩa; chưa tìm thấy nơi gọi trong `lib/`).

---

## 7. Tải và migration

Luồng `SaveRepository.load()`:

1. Đọc `save_primary` và `save_backup`; không có cả hai → `LoadStatus.none`.
2. Với mỗi bản có phiên bản cũ hơn hiện hành, lưu nguyên bản vào `save_archive_v{n}` (nếu chưa có).
3. Giải mã `save_primary`; nếu không dùng được, giải mã `save_backup`.
4. Trả `LoadResult(status, state)`.

`LoadStatus {none, ok, recoveredFromBackup, migrated, corrupted, migrationFailed}`.

Điều kiện một phong bì bị coi là không dùng được (`_decode`): không phải đối tượng JSON; `version` không phải số nguyên hoặc ngoài [1, phiên bản hiện hành]; `data` không phải chuỗi; checksum không khớp; `GameState.fromJson` ném lỗi.

Migration (bảng `_steps`, `save_repository.dart`):

| Từ | Đến | Hàm | Ghi chú |
| --- | --- | --- | --- |
| v1 | v3 | `migrateV1toV3` (`migration_v1_v3.dart`) | **nhảy thẳng** v1 → v3, không qua v2. Quân theo số lượng thành từng binh sĩ có id riêng; toàn bộ save v1 gốc giữ trong `legacy`. Dữ liệu v1 thiếu/vô lý ném `FormatException` |
| v2 | v3 | `migrateV2toV3` (`migration_v2_v3.dart`) | gộp tốc độ vào DEX (còn 3 thuộc tính STR/DEX/CON); HP thay cho "ngày thương tích"; bãi tập/trạm y tế thành công trình trong trại |

Khi migration ném lỗi hoặc bước nhảy không hợp lệ, kết quả là `migrationFailed` (và nếu cả bản backup cũng không dùng được thì trả về `migrationFailed` thay vì `corrupted`). Không có lớp `SaveMigrator`.

`[CURRENT]` Sau giải mã, `EquipmentService.sanitize(state)` được gọi trước khi trả `GameState`.

---

## 8. Toàn vẹn và phục hồi

`[CURRENT]`:

* Mỗi lần lưu, bản `save_primary` hiện có được sao sang `save_backup`, rồi `save_primary` được ghi đè. Bản backup là bản lưu **trước đó**, không kiểm tra hợp lệ trước khi sao.
* Khi `save_primary` hỏng hoặc sai checksum, tải `save_backup` (`LoadStatus.recoveredFromBackup`, hoặc `migrated` nếu bản backup cần nâng cấp).
* Save cũ luôn được lưu nguyên bản vào `save_archive_v{n}` trước khi nâng cấp.
* Nếu cả hai đều không dùng được: `LoadStatus.corrupted`/`migrationFailed`.

Giới hạn hiện có (không phải lỗi được tuyên bố đã sửa): FNV-1a 32-bit chỉ phát hiện lỗi ngẫu nhiên, không chống chỉnh sửa; ghi `save_primary` không dùng file tạm/đổi tên; `KeyValueStore.write` hai khóa liên tiếp không có giao dịch.

`[PLANNED]` (cần xác nhận quyết định giữ hay bỏ): checksum SHA-256; ghi an toàn qua file `.tmp` rồi đổi tên; file `.json`/`.bak`/`campaign_backup.json`; `timestamp` trong phong bì. Hiện chưa có.

---

## 9. Điều kiện nhất quán khi đọc

`GameState.fromJson` từ chối (ném `FormatException`) khi: thiếu kho đồ hoặc danh sách bắt buộc; id binh sĩ trùng; `nextSoldierId` không lớn hơn mọi id; id công trình trùng hoặc không nhỏ hơn `nextFacilityId`; một binh sĩ được gán vào nhiều công trình hoặc id gán không tồn tại; công trình có tọa độ ngoài [0, 1]; các số nguyên ngoài khoảng cho phép. Mọi lỗi khác trong khối giải mã được bọc thành `FormatException('Save hỏng: …')`.

`[UNVERIFIED]` Các bất biến vận hành khác (tài nguyên không âm, chết là vĩnh viễn…) được kiểm bằng test ngẫu nhiên có seed trong `test/domain_v2_test.dart`; chưa liệt kê tại đây.

---

## 10. Test hiện có

Tên test dưới đây chỉ là chỉ dẫn vị trí; kết quả pass/fail không được chạy lại trong TASK-003 (lần chạy toàn bộ ở TASK-001: 781 test pass trên cùng working tree).

| Chủ đề | Vị trí |
| --- | --- |
| Save hỏng → `corrupted`, khôi phục `recoveredFromBackup`, `migrated`, `migrationFailed` | `test/domain_v2_test.dart` (khoảng dòng 1395–1527) |
| Round-trip save trong chuỗi hành động ngẫu nhiên có seed | `test/domain_v2_test.dart` |
| Migration v2 → v3 | `test/migration_v2_v3_test.dart` |
| Danh tính khi lưu/migrate | `test/identity_save_test.dart` (khoảng dòng 125, 161) |
| Trang bị khi lưu | `test/equipment/equipment_save_test.dart` |
| Migrate trong luồng thương mại | `test/city_trade_test.dart` (khoảng dòng 538) |

---

## 11. Mục tiêu chưa triển khai và câu hỏi mở

* `[PLANNED]` SHA-256, ghi `.tmp`, file `.bak` — cần chủ dự án quyết định giữ hay loại bỏ.
* `[PLANNED]` Lưu khi vào nền; checkpoint giữa trận; chế độ Sandbox/Arena và trường `gameMode` (cần migration lên phiên bản mới của schema nếu thêm).
* `[UNVERIFIED]` Nhiều slot save, cấu hình toàn cục, nơi gọi `SaveRepository.clear()`.
* `[UNVERIFIED]` Ràng buộc đọc đầy đủ của `Soldier`, `Mission`, `HeroState`.
