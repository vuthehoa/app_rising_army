# Kinh tế & vòng lặp nhiệm vụ săn vô hạn (V4)

Nguồn sự thật: `lib/domain/economy.dart` (`StartingEconomy`, `ConstructionEconomy`, `UpkeepEconomy`, `QuestEconomy`, `LootEconomy`),
`lib/domain/quest_generator.dart` (bảng nhiệm vụ, điểm giao chiến), `GameRules` (giao dịch). Mô phỏng: `tool/loop_sim.dart`, in bảng:
`dart run tool/balance_report.dart`.

## 1. Audit tài nguyên (`enum Res` trong `lib/domain/models.dart`)

| Key | Tên | Khởi đầu | Nguồn thu (trong code) | Nơi tiêu | Phân loại |
|---|---|---:|---|---|---|
| `food` | Lương thực | 48 | thưởng nhiệm vụ vàng; chiến lợi phẩm (pool); mua ở Chợ | **upkeep** (`tickDay`), trinh sát (5), bán ở Chợ | lương thực (KHÔNG phải vật liệu xây dựng) |
| `coins` | Vàng | 50 | thưởng nhiệm vụ; chiến lợi phẩm; kho báu tàn tích; bán đồ/tài nguyên | upkeep, chiêu mộ, trang bị, hồi sinh, **xây/nâng cấp**, mua tài nguyên | vật liệu xây dựng |
| `wood` | Gỗ | 30 | thưởng nhiệm vụ đỏ; chiến lợi phẩm; mua ở Chợ | **xây/nâng cấp**; bán | vật liệu xây dựng |
| `stone` | Đá | 15 | như gỗ | **xây/nâng cấp**; bán | vật liệu xây dựng |
| `iron` | Sắt | 9 | như gỗ | **xây/nâng cấp**; bán | vật liệu xây dựng |
| `tools` | Công cụ | 5 | như gỗ | **xây/nâng cấp**; bán | vật liệu xây dựng |
| `cloth` | Vải | 5 | như gỗ | **xây/nâng cấp**; bán | vật liệu xây dựng |

Trước đây công cụ/đá/vải chỉ giao dịch được ở chợ, không công trình nào dùng — bằng chứng: `facilityDefs[*].cost` cũ chỉ có gỗ/sắt/vàng.
Nay chợ bán đúng sáu vật liệu này nên chúng là vật liệu xây dựng. HP, XP, tinh thần, năng lượng, uy tín (`kingSatisfaction`) là chỉ số, không phải tài nguyên.
Các điểm cộng tài nguyên trong `rules.dart` (`grant(`): bán đồ (`sellToVendor`), mua lô (`buyResourceLots`), bán lô (`sellResourceLots`), thưởng nhiệm vụ
(`_settle`), bổng lộc (`tickDay`, **= 0**), chiến lợi phẩm (`collectLoot`), kho báu tàn tích. **Không có nguồn nào theo ngày/công trình/mở màn hình.**

## 2. Bảng cân bằng hiện hành
### Tài nguyên khởi đầu

| Lương thực | Vàng | Gỗ | Sắt | Công cụ | Đá | Vải |
|---:|---:|---:|---:|---:|---:|---:|
| 48 | 50 | 30 | 9 | 5 | 15 | 5 |

### Giá xây mới

| Công trình | Vàng | Gỗ | Đá | Sắt | Công cụ | Vải |
|---|---:|---:|---:|---:|---:|---:|
| Lều cứu thương | 45 | 30 | 15 | 9 | 5 | 5 |
| Bãi bắn cung | 36 | 24 | 12 | 8 | 4 | 4 |
| Bãi cận chiến | 36 | 24 | 12 | 8 | 4 | 4 |
| Hòm đồ | 30 | 20 | 10 | 6 | 3 | 3 |
| Bãi đá | 39 | 26 | 13 | 8 | 4 | 4 |
| Bia mộ | 30 | 20 | 10 | 6 | 3 | 3 |
| Doanh trại | 42 | 28 | 14 | 9 | 5 | 5 |

### Giá nâng cấp

| Nâng cấp | Vàng | Gỗ | Đá | Sắt | Công cụ | Vải |
|---|---:|---:|---:|---:|---:|---:|
| Bãi đá 3→6 slot | 71 | 47 | 24 | 15 | 8 | 8 |
| Bãi bắn cung 3→6 slot | 65 | 44 | 22 | 13 | 7 | 7 |
| Bãi cận chiến 3→6 slot | 65 | 44 | 22 | 13 | 7 | 7 |
| Lều cứu thương 3→6 slot | 81 | 54 | 27 | 17 | 9 | 9 |
| Doanh trại / Lò rèn / Quán rượu → cấp 1 | 42 | 28 | 14 | 9 | 5 | 5 |
| Doanh trại / Lò rèn / Quán rượu → cấp 2 | 84 | 56 | 28 | 17 | 9 | 9 |
| Doanh trại / Lò rèn / Quán rượu → cấp 3 | 126 | 84 | 42 | 26 | 13 | 13 |

### Thu nhập kỳ vọng của một chiến thắng (đo bằng luật thật, vàng quy đổi theo giá chợ)

| Độ khó | Vàng | Lương thực | Vật liệu (quy vàng) | Trang bị rơi TB | Tổng quy vàng |
|---:|---:|---:|---:|---:|---:|
| 1 | 81 | 9 | 37 | 0.20 | 136 |
| 2 | 118 | 14 | 52 | 0.85 | 198 |
| 3 | 172 | 17 | 70 | 1.20 | 276 |
| 4 | 264 | 18 | 89 | 1.65 | 389 |
| 5 | 364 | 16 | 138 | 1.88 | 534 |

### Mười kịch bản vòng lặp nhiệm vụ (30 ngày, seed 3)

| Kịch bản | Ngày | Thắng/Thua | Vàng đầu→cuối | Lương thực đầu→cuối | Thu vàng | Lương vàng trả | Chi vàng khác | Ngày thiếu lương | Ngày thiếu đầu tiên | Lính còn |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 Người mới (6 lính cấp 1) | 30 | 2/0 | 50→0 | 48→0 | 162 | 127 | 85 | 5 | 26 | 4 |
| 2 Đội trung bình (8 lính cấp 2–3) | 30 | 5/6 | 50→411 | 48→16 | 447 | 86 | 0 | 0 | - | 0 |
| 3 Đội mạnh (10 lính cấp 3–6) | 30 | 5/0 | 50→75 | 48→22 | 778 | 485 | 268 | 10 | 10 | 4 |
| 4 Gần hết vàng (3 vàng) | 30 | 5/0 | 3→52 | 48→17 | 392 | 166 | 177 | 1 | 1 | 3 |
| 5 Gần hết lương thực (2) | 30 | 4/0 | 50→18 | 2→14 | 323 | 135 | 220 | 0 | - | 3 |
| 6 Liên tục thắng (10 lính cấp 6) | 30 | 3/0 | 50→0 | 48→0 | 461 | 390 | 121 | 10 | 12 | 0 |
| 7 Liên tục thất bại (1 lính cấp 1 đánh nhiệm vụ) | 30 | 0/1 | 50→49 | 48→47 | 0 | 1 | 0 | 0 | - | 0 |
| 8 Không làm nhiệm vụ (8 lính cấp 2–3) | 30 | 0/0 | 50→0 | 48→0 | 0 | 123 | -73 | 10 | 7 | 0 |
| 9 Nhận 3 nhiệm vụ rồi lần lượt hoàn thành | 30 | 5/4 | 50→428 | 48→38 | 458 | 80 | 0 | 0 | - | 0 |
| 10 Vừa duy trì vừa mua đồ, xây, nâng cấp | 30 | 6/0 | 90→0 | 48→0 | 632 | 326 | 396 | 6 | 25 | 5 |


Đọc bảng kịch bản: chính sách mô phỏng là một "người chơi tự động" thận trọng (chỉ đánh khi sức mạnh vượt địch 1.3×, dưỡng quân,
mua lương thực ở chợ) nên các con số chịu ảnh hưởng mạnh của chính sách; **không** dùng một dòng để kết luận. Điểm chung đáng tin:
(a) không làm gì (8) hoặc thua liên tục (7) thì không có thu và cạn dần; (b) đội nhỏ/trung bình làm nhiệm vụ đều đặn tích lũy (2, 9) hoặc hòa vốn;
(c) đội mạnh (3, 6) hầu như chỉ hòa vốn — đúng ý "đầu tư đáng kể", nhưng thương vong và thời gian dưỡng thương rất tốn; (d) chiến đấu thua là mất cả đội
(luật tử trận vĩnh viễn sẵn có), nên rủi ro lớn hơn lợi nhuận kỳ vọng ở độ khó cao nếu đội không đủ mạnh.

## 3. Vòng lặp nhiệm vụ

`nhận (thành phố) → Encounter (điểm thật, id enc_<id>) → marker + mũi tên → đi bộ tới tâm điểm → DeployScreen → sendExpedition → thắng: _settle (rewarded) + loot → dọn điểm → ô trống`.
* Bảng luôn 3 nhiệm vụ SĂN, độ khó theo `QuestGenerator.band` (cấp trung bình tối đa 6 lính mạnh nhất, floor): `[1,1,1]` / `[1,1,2]` / `[1,2,3]` / `[2,3,4]` / `[3,4,5]`.
* Tối đa 3 đang làm (`acceptMission`); mỗi nhiệm vụ đúng một `Encounter` lưu trong `Mission.encounter` (khóa JSON `enc`, tùy chọn → không cần migration).
* `sendExpedition` từ chối khi hero cách điểm > 80 (`encounterArriveRadius`) — domain chặn, không chỉ UI; không tự mở trận khi nhận.
* Thành phố luôn mở: bỏ khóa vùng ở `enterTown` và `locked` của `TownMarker`. Giữ nguyên `vendorOpen` (cửa hàng) và khóa vùng cho địa điểm chiến đấu cố định cũ.
* Mẫu nhiệm vụ cũ (giao nộp, luyện binh, khám phá…) còn trong catalog **chỉ để đọc save cũ**, `fillBoard` không bao giờ phát ra và gỡ khỏi bảng nếu đang mời.
* Nhiệm vụ cuối (`final_fort`/thắng ván) không còn được phát: vòng lặp vô hạn nên không có "thắng ván".

## 4. Chứng minh điều kiện khởi đầu

Giá = `base × hệ số%` (base: vàng 30, gỗ 20, đá 10, sắt 6, công cụ 3, vải 3; hệ số 100–150%). Khởi đầu (vàng 50, gỗ 30, đá 15, sắt 9, công cụ 5, vải 5) **< 2× base ở cả 6 loại** và
≥ giá của công trình đắt nhất (Lều cứu thương 45/30/15/9/5/5). Nên: (1) xây được bất kỳ công trình nào lúc đầu; (2) sau khi xây bất kỳ cái nào, còn lại < 1× base ở ít nhất một loại
⇒ không đủ xây công trình thứ hai; (3) nâng cấp luôn đắt hơn xây ở từng loại ⇒ không đủ nâng cấp. Test: `test/construction_test.dart` ("sau MỖI công trình đầu tiên…" duyệt toàn catalog và mọi nâng cấp).

## 5. Hồi sinh

`reviveCost(so) = 12 + 8×cấp` (vàng). Hồi sinh: HP = 1, `needsTreatment = true` (lưu `treat`), năng lượng/tinh thần giữ nguyên. `Soldier.available` là false nên `sendExpedition` từ chối (domain). Chỉ Lều cứu thương
chữa (20 HP/ngày `++`), khi HP ≥ 50% tối đa thì cờ tắt; nghỉ ngơi thường không chữa. Lính vừa hồi sinh được tính upkeep như lính hoạt động (đang chiếm chỗ trong quân); lính đã chết thì không.
Nếu người chơi chưa có Lều cứu thương thì lính hồi sinh phải đợi đến khi xây.

## 6. Kiểm toán các thay đổi ngoài phạm vi trước đây

| Hạng mục | Phân loại | Ghi chú |
|---|---|---|
| Giá hồi sinh `50+25×cấp → 12+8×cấp` | 1 — thuộc yêu cầu (hồi sinh theo cấp bằng vàng) | giữ |
| Sản lượng thu hoạch tài nguyên (9–20/chuyến) | 3 — sai thiết kế mới (không có thu hoạch) | **gỡ**: `sendExpedition` từ chối điểm tài nguyên, ẩn khỏi bản đồ (`visibleLocations`) |
| Vàng kho báu tàn tích (`rules.dart`, `case LocKind.ruins`) | 2 — tồn tại, đạt được (POI → SquadScreen → `sendExpedition`), bị chặn một lần/tàn tích (`explored`), tối đa ~3 tàn tích ≈ 45 vàng cả ván | giữ; không phải thu nhập thụ động |
| Giá trang bị / chiêu mộ / thưởng nhiệm vụ | 1 — thuộc phạm vi kinh tế | thưởng nhiệm vụ nâng lên để kịp upkeep (xem bảng) |
| Bổng lộc & trợ cấp khẩn (4 vàng/3 lương/ngày) | 3 — là thu nhập thụ động | **đặt = 0** |
