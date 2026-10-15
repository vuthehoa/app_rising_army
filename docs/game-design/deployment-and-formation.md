# BỐ TRÍ VÀ ĐỘI HÌNH (DEPLOYMENT & FORMATION)

**Dự án:** Rising Army Remake (Flutter iOS - Landscape)
**Tập tin:** `docs/game-design/deployment-and-formation.md`

> **Nguồn và phạm vi (TASK-003).** File này trước đó rỗng (0 byte). Bản này là mô tả **ngắn**, chỉ dựng từ source đã đọc: `lib/domain/battle.dart`, `lib/domain/rules.dart`, `lib/presentation/screens/deploy_screen.dart`. Không phải đặc tả thiết kế đầy đủ; mục nào chưa kiểm chứng ghi `[UNVERIFIED]`, mục chưa triển khai ghi `[PLANNED]`.

---

## 1. Giới hạn đội ra trận — `[CURRENT]`

* Một đội ra trận có tối đa **10** binh sĩ: `GameRules.maxSquad = 10` (`lib/domain/rules.dart:159`). Vượt quá bị từ chối với thông báo "Tối đa 10 binh sĩ mỗi đội" (`rules.dart:~2243`).
* Đội rỗng bị từ chối ("Chưa chọn binh sĩ"); id trùng trong đội bị từ chối (`rules.dart:~2241-2247`).
* Giới hạn này khác sức chứa quân đoàn (`rosterCap = 6 + 4 × cấp Doanh trại`, `rules.dart:321`).
* Con số "4v4, 6v6, 8v8, tối đa ~9" trong các tài liệu khác là quan sát từ game gốc, không phải giới hạn của source.

## 2. Triển khai trên màn hình Deploy — `[CURRENT]`

(`lib/presentation/screens/deploy_screen.dart`)

* Người chơi đặt từng binh sĩ trong khu triển khai (kéo-thả; vị trí được kẹp vào khu bằng `clampToDeployZone`, `battle.dart`).
* Nút "Fight!" chỉ bật khi **mọi** binh sĩ trong đội đã được đặt; nếu chưa, hiển thị "Triển khai đủ x/y binh sĩ" và không cho đánh (`canFight: all && !_fighting`).
* Có nút bỏ đặt toàn bộ (`onClear`, tooltip "Thu hồi tất cả") và thu hồi từng binh sĩ đang chọn.

## 3. Bốn preset đội hình — `[CURRENT]`

`enum FormationPreset { line, expanded, wedge, cluster }` (`battle.dart:423`), tên hiển thị trong `formationNames`:

| Preset | Tên hiển thị |
| --- | --- |
| `line` | Hàng ngang |
| `expanded` | Đội hình mở rộng |
| `wedge` | Mũi nhọn |
| `cluster` | Cụm |

`presetPlacement(preset, soldiers)` (`battle.dart`) chia đội thành **cận chiến** (phía trước, gần địch) và **tầm xa** (phía sau) theo `deriveStats(s).ranged`, rồi xếp mỗi nhóm thành cột với độ trải và độ lệch riêng của từng preset. Ví dụ: `line` đặt cận chiến ở x ≈ 14,5 và tầm xa ở x ≈ 10,0. Mọi vị trí đều được kẹp vào khu triển khai.

Không phải preset do người dùng tự lưu: danh sách preset là cố định trong code. Việc lưu/tải preset riêng `[PLANNED]`/`[UNVERIFIED]` (không tìm thấy trong phần source đã đọc).

## 4. Xếp tự động — `[CURRENT]`

Nút "Deploy Units" (`onAuto`, `deploy_screen.dart`) xóa vị trí hiện tại và áp `presetPlacement(FormationPreset.line, squad)`, tức là bố trí **Hàng ngang**.

Khi gọi trận mà không truyền vị trí, `GameRules.fight` dùng `defaultPlacement(squad, frontIds)` (`battle.dart`): nhóm "hàng trước" ở x ≈ 14,5 và còn lại ở x ≈ 9,0.

## 5. Quân địch — `[CURRENT]`

`enemyPlacement` (`battle.dart`) xếp địch cận chiến ở x ≈ 25,5 và tầm xa ở x ≈ 32. Thành phần đội địch do `QuestGenerator.enemyPlan` quyết định theo độ khó (xem `quest_generator.dart`).

## 6. Bắt đầu trận — `[CURRENT]`

`GameRules.fight(...)` dựng `BattleUnit` cho cả hai bên từ vị trí trên và gọi `simulateBattle(players, foes, seed)` với seed rút từ RNG của ván (`rng(s).nextInt(1 << 30)`, `rules.dart:~2077-2092`). Trận không sửa `GameState`; kết quả được áp riêng qua `GameRules.applyBattle`. Chi tiết engine: `gameplay-systems.md` mục 3.7.

## 7. Chưa triển khai hoặc chưa xác minh

* `[PLANNED]` Lưới ô "Frontline/Backline" rời rạc: source dùng tọa độ liên tục trong khu triển khai, không dùng lưới ô.
* `[UNVERIFIED]` Cảnh báo cho binh sĩ bị thương nặng khi đưa vào đội; việc cất lính dự bị theo tình trạng.
* `[UNVERIFIED]` Tiêu chí chọn binh sĩ vào đội (trước khi tới màn Deploy) và vai trò của `frontIds`.
