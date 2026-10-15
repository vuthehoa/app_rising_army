# Cân bằng kinh tế V3 — Gameplay Economy & Resource Balancing

Nguồn sự thật duy nhất: `lib/domain/economy.dart` (lương, chiêu mộ, nhiệm vụ, chiến lợi phẩm, tài nguyên khởi đầu)
và `lib/domain/equipment/gear_pricing.dart` (giá trang bị, đọc qua `ItemDef.price`).
Mô phỏng: `tool/balance_sim.dart` (dùng đúng `GameRules`), in bảng: `dart run tool/balance_report.dart`.

Quy ước: **vàng = `Res.coins`**, **lương = `Res.food`** (lương thực). Không tạo currency mới.

## Bản đồ nơi xử lý (audit)

| Mảng | Nơi xử lý |
|---|---|
| Tài nguyên | `GameState.res` (7 loại); khởi đầu `StartingEconomy` ← `GameRules.newGame` |
| Qua ngày / lương | `GameRules.tickDay` (UI không có nút qua ngày; ngày trôi khi hành quân `sendExpedition`/trinh sát) |
| Chiêu mộ | `GameRules.hire` / `hireAtTavern`, giá `HireEconomy.price` (UI: `recruit_screen` gọi `GameRules.hireCost`) |
| Giá trang bị | `GearPricing.priceOf` → `ItemDef.price` → `buyPrice`/`sellPrice`/`itemPrice` (UI vendor_screen gọi `GameRules.buyPrice/sellPrice`) |
| Giá tài nguyên chợ | `resourceLotPrice` (catalog) → `resourceBuyPrice/SellPrice` |
| Nhiệm vụ | `GameRules._settle` (chốt `rewarded`) ← `QuestEconomy` |
| Chiến lợi phẩm | `GameRules.sendExpedition` → `LootEconomy.roll` |
| Uy tín nhà vua | `GameState.kingSatisfaction` (= `sacredWill`), HUD `GameTopHud` |
| Save/load | `GameState.toJson/fromJson` — **không đổi cấu trúc save** |

## Giá trị cũ → mới

| Hạng mục | Cũ | Mới |
|---|---|---|
| Khởi đầu (vàng/lương/gỗ/sắt) | 120 / 80 / 40 / 20 | 50 / 40 / 40 / 20 (công cụ, đá, vải = 0, chưa có công dụng) |
| Bổng lộc nhà vua/ngày (×(0.5+uy tín/100)) | 16 vàng + 10 lương | 4 vàng + 3 lương |
| Trợ cấp khẩn (quân < 6) | tới 24 vàng | tới 8 vàng |
| Lương lính | 1 vàng + 1 lương / lính mọi cấp | bảng theo cấp: 1/1/1/2/2/3 (cấp 7+ giữ mức cấp 6) |
| Giá chiêu mộ | `25 + 2×tổng chỉ số + 10×cấp` (~100+) | nền 10/15/25 + chỉ số vượt trội + ½ giá trang bị mang, trần 16/24/120 |
| Giá trang bị | thường 8–40, tốt 52–95, hiếm 110–188, sử thi 230–305, huyền thoại 380–740 | mốc 6 / 40 / 125 / 190 / 330 (xem dưới) |
| Hồi sinh | `50 + 25×cấp` | `12 + 8×cấp` |
| Thưởng nhiệm vụ | cứng trong từng mẫu (45–500 vàng) | công thức theo màu × độ khó |
| Loot trại địch | cứng trong từng địa điểm (60–400 vàng, 100% món đồ) | tính từ kẻ địch thực tế; món đặc trưng của địa điểm giữ nguyên |
| Kho báu tàn tích | 40–80 + 20×bậc vàng | 10–20 + 5×bậc vàng; trang bị rút theo `rollGearDesign` |
| Sản lượng thu hoạch | 25–55 | 9–20 |

## Giá trang bị (`GearPricing`)

`giá = mốc[phẩm cấp] × clamp(giá gốc của món / giá gốc trung bình của phẩm cấp)`. Giá gốc do người thiết kế gán trong
dữ liệu (đã phản ánh chỉ số, hiệu ứng, độ hiếm) được giữ làm thước đo độ mạnh tương đối; phép biến đổi **đơn điệu** nên món
mạnh hơn không bao giờ rẻ hơn món yếu hơn cùng phẩm cấp. Giá mua/bán/hiển thị/trừ vàng đều đọc `ItemDef.price`.

| Phẩm cấp | Mức tiền (thực đo) |
|---|---|
| 1 Thường | 3–10 (TB 6) |
| 2 Tốt | 30–51 (TB 40) |
| 3 Hiếm (xanh lam) | 94–154 (TB 123) |
| 4 Sử thi (tím) | 159–211 (TB 189) |
| 5 Huyền thoại | 248–417 (TB 329) |
| 6 (chỉ từ nhiệm vụ) | 520 |

Bán lại = 40% giá gốc (`sellRatio`), người bán có hệ số ≥ 1.0 nên mua rồi bán luôn lỗ (có test trên mọi người bán/mọi món).
Tài nguyên ở chợ tính theo đơn vị: lương thực 2, gỗ 3, đá 4, vải 5, sắt 6, công cụ 8 vàng/đơn vị (bán lại 40%).

## Chiêu mộ (`HireEconomy`)

`giá = nền[cấp] + round(điểm chỉ số vượt mức mong đợi × hệ số[cấp]) + round(0.5 × giá trị trang bị đang mang)`, kẹp trong [nền, trần].
Ứng viên Quán rượu hiện **không mang trang bị** (`generateSoldier(equip:false)`), nên khoản trang bị = 0; nếu sau này
ứng viên mang đồ thì được tính đúng một lần. Thực đo trên 300 seed: cấp 1 = 10–12, cấp 2 = 15–17, cấp 3 = 25–28.
Cấp 3 kèm bộ đồ phẩm cấp 3 tối đa chạm trần 120. Chỉ chiêu mộ cấp 1–3 (`HireEconomy.hireable` được kiểm trong `hire`).

## Thưởng nhiệm vụ (`QuestEconomy`)

Độ khó = số đầu lâu = `MissionTemplate.difficulty` (mặc định `tierMin + 1`, đúng như bảng nhiệm vụ trước đây hiển thị;
`clear_merc` đặt riêng 4). Cùng một getter cấp cho UI và cho bảng thưởng.

| Đầu lâu | Vàng (nhiệm vụ vàng) | Lương | Uy tín | Xác suất trang bị | Vàng (đỏ) | EXP/người | Ngân sách tài nguyên (đỏ) | Số loại | Xác suất trang bị (đỏ) |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 20 | 4 | +3 | 10% | 12 | 12 | 20 | 2 | 5% |
| 2 | 24 | 6 | +5 | 18% | 18 | 16 | 32 | 2 | 10% |
| 3 | 30 | 9 | +7 | 28% | 26 | 20 | 48 | 3 | 18% |
| 4 | 38 | 12 | +9 | 40% | 36 | 26 | 70 | 3 | 28% |
| 5 | 46 | 16 | +12 | 55% | 48 | 32 | 100 | 3 | 40% |

* Nhiệm vụ nộp lương thực không hoàn lại lương thực. Mẫu có `rewardItem` cố định không rút thêm trang bị ngẫu nhiên.
* Nhiệm vụ đỏ rút tài nguyên có trọng số từ `rewardResourcePool` = lương thực, gỗ, sắt (loại có công dụng thật);
  loại đang dưới 15 đơn vị được ưu tiên ×2.5 để không bị kẹt. Công cụ/đá/vải **không** được thưởng vì chưa có nơi tiêu.
* Trang bị ngẫu nhiên tối đa phẩm cấp 4 (phân bố theo độ khó trong `_gradeWeights`), mint qua `EquipmentService.mint`.
* Nhiệm vụ cuối: 120 vàng + 60 EXP cố định.
* Toàn bộ rút ngẫu nhiên dùng `GameRules.rng(s)` (seed + rngCounter) và nằm sau chốt `rewarded` nên chỉ xảy ra một lần.

## Chiến lợi phẩm (`LootEconomy`)

Mỗi kẻ địch thật: vàng = `{1:3, 2:5, 3:8, 4:12, 5:17, 6:23}[cấp] + 10% giá trang bị đang mang`, biến thiên ×0.75–1.25;
30% rơi 2+cấp đơn vị tài nguyên (cùng pool/ưu tiên khan hiếm); xác suất rơi một món mình đang mang
= `4% + 3%×cấp + 2%×(phẩm cấp cao nhất − 1)`, trần 35%, tối đa 2 món/trận. Chỉ trận **thắng** (trại địch, hoặc đẩy lui phục kích).
Mỗi địa điểm trại chỉ quét sạch một lần (`cleared`) nên không farm được; món đặc trưng của địa điểm vẫn được trao một lần.

| Trại | Địch | Vàng kỳ vọng | Số món rơi kỳ vọng |
|---|---:|---:|---:|
| g_bandits | 4 | ~16 | 0.28 |
| a_outpost | 6 | ~56 | 0.72 |
| a_raiders | 7 | ~94 | 0.96 |
| m_camp | 8 | ~131 | 1.20 |
| m_fort | 10 | ~262 | 1.94 |

## Bảng mô phỏng (sinh bởi `dart run tool/balance_report.dart`, seed 1)

Bảng liệt kê "Chi khác" = xây dựng/chiêu mộ/nộp nhiệm vụ; "Thu khác" = nhiệm vụ + chiến lợi phẩm (bổng lộc tách riêng).
Chỉ mô phỏng những cơ chế có thật trong code; không mô phỏng "chi phí sinh hoạt" nào ngoài lương.

#### A0 — Duy trì thuần túy 7 ngày (6 lính cấp 1, không làm gì)

| Ngày | Vàng đầu ngày | Lương thực đầu ngày | Lính | Lương phải trả (vàng/lương thực) | Chi khác (vàng/lương thực) | Bổng lộc (vàng/lương thực) | Thu khác (vàng/lương thực) | Vàng cuối ngày | Lương thực cuối ngày |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 50 | 40 | 6 | 6/6 | 0/0 | 4/3 | 0/0 | 48 | 37 |
| 2 | 48 | 37 | 6 | 6/6 | 0/0 | 4/3 | 0/0 | 46 | 34 |
| 3 | 46 | 34 | 6 | 6/6 | 0/0 | 4/3 | 0/0 | 44 | 31 |
| 4 | 44 | 31 | 6 | 6/6 | 0/0 | 4/3 | 0/0 | 42 | 28 |
| 5 | 42 | 28 | 6 | 6/6 | 0/0 | 4/3 | 0/0 | 40 | 25 |
| 6 | 40 | 25 | 6 | 6/6 | 0/0 | 4/3 | 0/0 | 38 | 22 |
| 7 | 38 | 22 | 6 | 6/6 | 0/0 | 4/3 | 0/0 | 36 | 19 |

#### A — Người mới 7 ngày (xây Doanh trại, chiêu mộ 1, 2 nhiệm vụ vàng)

| Ngày | Vàng đầu ngày | Lương thực đầu ngày | Lính | Lương phải trả (vàng/lương thực) | Chi khác (vàng/lương thực) | Bổng lộc (vàng/lương thực) | Thu khác (vàng/lương thực) | Vàng cuối ngày | Lương thực cuối ngày |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 50 | 40 | 7 | 7/7 | 40/0 | 4/3 | 0/0 | 7 | 36 |
| 2 | 7 | 36 | 7 | 7/7 | 0/0 | 4/3 | 0/0 | 4 | 32 |
| 3 | 4 | 32 | 7 | 7/7 | 0/0 | 4/3 | 20/4 | 21 | 32 |
| 4 | 21 | 32 | 7 | 7/7 | 0/0 | 4/3 | 0/0 | 18 | 28 |
| 5 | 18 | 28 | 7 | 7/7 | 0/15 | 4/3 | 20/0 | 35 | 9 |
| 6 | 35 | 9 | 7 | 7/7 | 0/0 | 4/3 | 0/0 | 32 | 5 |
| 7 | 32 | 5 | 7 | 7/7 | 0/0 | 4/3 | 0/0 | 29 | 1 |

#### B — Bình thường 14 ngày (8 lính cấp 1–3, nhiệm vụ vàng/đỏ)

| Ngày | Vàng đầu ngày | Lương thực đầu ngày | Lính | Lương phải trả (vàng/lương thực) | Chi khác (vàng/lương thực) | Bổng lộc (vàng/lương thực) | Thu khác (vàng/lương thực) | Vàng cuối ngày | Lương thực cuối ngày |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 50 | 40 | 8 | 8/8 | 0/0 | 4/3 | 0/0 | 46 | 35 |
| 2 | 46 | 35 | 8 | 8/8 | 0/0 | 4/3 | 0/0 | 42 | 30 |
| 3 | 42 | 30 | 8 | 8/8 | 0/0 | 4/3 | 24/6 | 62 | 31 |
| 4 | 62 | 31 | 8 | 8/8 | 0/0 | 4/3 | 18/0 | 76 | 26 |
| 5 | 76 | 26 | 8 | 8/8 | 0/0 | 4/3 | 0/0 | 72 | 21 |
| 6 | 72 | 21 | 8 | 8/8 | 0/0 | 4/3 | 0/0 | 68 | 16 |
| 7 | 68 | 16 | 8 | 8/8 | 0/0 | 4/3 | 0/0 | 64 | 11 |
| 8 | 64 | 11 | 8 | 8/8 | 0/0 | 4/3 | 18/9 | 78 | 15 |
| 9 | 78 | 15 | 8 | 8/8 | 0/0 | 4/3 | 0/0 | 74 | 10 |
| 10 | 74 | 10 | 8 | 8/8 | 0/0 | 4/3 | 0/0 | 70 | 5 |
| 11 | 70 | 5 | 8 | 8/8 | 20/0 | 4/3 | 0/10 | 46 | 10 |
| 12 | 46 | 10 | 8 | 8/8 | 0/0 | 4/3 | 42/14 | 84 | 19 |
| 13 | 84 | 19 | 8 | 8/8 | 0/0 | 4/3 | 0/0 | 80 | 14 |
| 14 | 80 | 14 | 8 | 8/8 | 0/0 | 4/3 | 0/0 | 76 | 9 |

#### C — Đội mạnh 14 ngày, CÓ nhiệm vụ khó (10 lính cấp 2–6)

| Ngày | Vàng đầu ngày | Lương thực đầu ngày | Lính | Lương phải trả (vàng/lương thực) | Chi khác (vàng/lương thực) | Bổng lộc (vàng/lương thực) | Thu khác (vàng/lương thực) | Vàng cuối ngày | Lương thực cuối ngày |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 50 | 40 | 10 | 19/19 | 0/0 | 4/3 | 24/6 | 59 | 30 |
| 2 | 59 | 30 | 10 | 19/19 | 0/0 | 4/3 | 36/13 | 80 | 27 |
| 3 | 80 | 27 | 10 | 19/19 | 0/0 | 4/3 | 0/0 | 65 | 11 |
| 4 | 65 | 11 | 10 | 19/19 | 20/0 | 4/3 | 24/16 | 54 | 11 |
| 5 | 54 | 11 | 10 | 19/19 | 0/0 | 4/3 | 18/10 | 57 | 5 |
| 6 | 57 | 5 | 10 | 19/19 | 40/0 | 4/3 | 0/20 | 2 | 9 |
| 7 | 2 | 9 | 10 | 19/19 | 20/0 | 5/3 | 24/16 | 0 | 9 |
| 8 | 0 | 9 | 10 | 19/19 | 0/0 | 5/3 | 36/13 | 22 | 6 |
| 9 | 22 | 6 | 10 | 19/19 | 0/0 | 5/3 | 0/0 | 8 | 0 |
| 10 | 8 | 0 | 10 | 19/19 | 0/0 | 5/4 | 24/6 | 18 | 0 |
| 11 | 18 | 0 | 10 | 19/19 | 0/0 | 5/4 | 18/8 | 22 | 0 |
| 12 | 22 | 0 | 10 | 19/19 | 0/0 | 5/4 | 0/0 | 8 | 0 |
| 13 | 8 | 0 | 10 | 19/19 | 0/0 | 5/4 | 24/6 | 18 | 0 |
| 14 | 18 | 0 | 10 | 22/22 | 40/0 | 5/4 | 36/31 | 0 | 13 |

#### C0 — Đội mạnh 14 ngày, KHÔNG làm nhiệm vụ

| Ngày | Vàng đầu ngày | Lương thực đầu ngày | Lính | Lương phải trả (vàng/lương thực) | Chi khác (vàng/lương thực) | Bổng lộc (vàng/lương thực) | Thu khác (vàng/lương thực) | Vàng cuối ngày | Lương thực cuối ngày |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 50 | 40 | 10 | 19/19 | 0/0 | 4/3 | 0/0 | 35 | 24 |
| 2 | 35 | 24 | 10 | 19/19 | 0/0 | 4/3 | 0/0 | 20 | 8 |
| 3 | 20 | 8 | 10 | 19/19 | 0/0 | 4/3 | 0/0 | 5 | 0 |
| 4 | 5 | 0 | 10 | 19/19 | 0/0 | 4/3 | 0/0 | 0 | 0 |
| 5 | 0 | 0 | 10 | 19/19 | 0/0 | 4/3 | 0/0 | 0 | 0 |
| 6 | 0 | 0 | 10 | 19/19 | 0/0 | 4/3 | 0/0 | 0 | 0 |
| 7 | 0 | 0 | 10 | 19/19 | 0/0 | 4/3 | 0/0 | 0 | 0 |
| 8 | 0 | 0 | 10 | 19/19 | 0/0 | 4/3 | 0/0 | 0 | 0 |
| 9 | 0 | 0 | 6 | 19/19 | 0/0 | 4/3 | 0/0 | 0 | 0 |
| 10 | 0 | 0 | 5 | 12/12 | 0/0 | 4/3 | 0/0 | 0 | 0 |
| 11 | 0 | 0 | 3 | 9/9 | 0/0 | 5/3 | 0/0 | 0 | 0 |
| 12 | 0 | 0 | 3 | 5/5 | 0/0 | 8/3 | 0/0 | 3 | 0 |
| 13 | 3 | 0 | 2 | 5/5 | 0/0 | 8/3 | 0/0 | 6 | 0 |
| 14 | 6 | 0 | 1 | 4/4 | 0/0 | 9/3 | 0/0 | 11 | 0 |


Đọc bảng: (A0) 6 lính cấp 1 sống thụ động được ~25 ngày vàng / ~13 ngày lương thực (−2 vàng, −3 lương mỗi ngày) → "đủ 7 ngày" nhưng hao đều mỗi ngày, muốn lớn
mạnh phải làm nhiệm vụ/thu hoạch. (A) người mới xây Doanh trại + chiêu mộ 1 lính rồi làm hai nhiệm vụ vàng dễ sống qua 7 ngày
nhưng chỉ còn 1 lương thực → phải đi thu hoạch. (B) 8 lính cấp 1–3 làm nhiệm vụ đều đặn có dư dần. (C) đội 10 lính cấp 2–6 tốn
19 vàng + 19 lương/ngày (gấp ~2.4 B): hai nhiệm vụ trong ba ngày và phải mua lương thực ở chợ mới hòa vốn, hầu như không dư;
(C0) không làm gì thì hết vàng sau 4 ngày, thiếu lương → tinh thần giảm → đào ngũ (cơ chế sẵn có), quân co lại về mức nền kinh tế
chịu nổi.

## Quy tắc thiếu tiền/lương (không đổi, ghi lại)

`tickDay` trả phần có thể trả (`min(có, cần)` cho từng loại). Nếu thiếu: tinh thần mọi lính −8 (cơ chế sẵn có); lính tinh thần ≤ 15
có 25%/ngày đào ngũ (cơ chế sẵn có). Không xóa/giết lính vì thiếu tiền.

## Chưa xác minh / cần bạn xác nhận

1. "Lương" được ánh xạ sang `Res.food`. Nếu bạn muốn một tài nguyên khác, chỉ cần đổi `UpkeepEconomy` + `tickDay`.
2. UI hiện **không có nút qua ngày** (`GameController.endDay` chỉ dùng cho test/mô phỏng); ngày trôi khi hành quân. Chưa thể bấm-thử nút
   qua ngày trên giao diện vì nút không tồn tại. Quy tắc trừ đúng một lần được bảo đảm vì mỗi `tickDay` tăng `day` đúng một lần.
3. Ứng viên Quán rượu không mang trang bị, nên mục tiêu "cấp 3 mạnh nhất ~100–120 vàng *khi có bộ đồ*" chỉ đạt được khi có đồ
   (công thức có trần 120, test xác nhận); lính cấp 3 trần trụi tốn 25–28. Muốn ứng viên cấp 2–3 mang đồ sẵn thì cần quyết định thiết kế.
4. Cấp lính > 6 (tối đa 20 trong luật) dùng mức cấp 6 (3/3).
5. Đa số nhiệm vụ trong dữ liệu chỉ ở mức 1–2 đầu lâu; các nấc 4–5 đầu lâu của bảng thưởng gần như chưa dùng. Mỗi mẫu nhiệm vụ chỉ làm
   được một lần, nên thu nhập lặp lại dài hạn dựa vào bổng lộc + thu hoạch + chợ. Cần chơi thử để chỉnh `kingStipend*` và `yield`.
6. Chưa chạy trên simulator/thiết bị; chỉ có test widget (HUD ở 667×375, 932×430, 1280×800) và build iOS debug (`--no-codesign`).
7. 32 test cũ vẫn đỏ y hệt trên HEAD (không phải do đợt này): các lỗi tìm text UI ("Tuyển mộ", "Thợ rèn Đá Xám", 'Ngày' vs 'NGÀY'...),
   overflow ở màn hình lớn, và new_game_flow. Tôi không sửa chúng vì thuộc phần giao diện đang thay đổi của bạn.
