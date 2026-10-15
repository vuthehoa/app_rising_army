# Audit XP nhiệm vụ đỏ, tốc độ lên cấp 6 và cân bằng thể trạng

Công cụ: `dart run tool/quest_xp_sim.dart` (xác định, seed 0..59; dùng ĐÚNG `GameRules.fight/applyBattle/allocateStat/addXp`).
Phương án B/C chỉ nằm trong công cụ, **không có trong game**.

## 1. Bảng nguồn XP (audit mã nguồn)

| Nguồn | Điều kiện nhận | Công thức hiện tại | Nơi chịu trách nhiệm |
|---|---|---|---|
| Sát thương trận | Có mặt trong báo cáo, gây sát thương hợp lệ, **sống và không bỏ chạy** sau trận; thua vẫn nhận | Σ `10 + 6×cấp địch` × (sát thương hợp lệ / HP tối đa địch); tổng cả trận = `round(Σ giá trị × tỉ lệ HP bị trừ)` | `distributeBattleXp` (`combat_condition.dart`), áp ở `GameRules.applyBattle` |
| Tham gia trận | Đứng trong đội mà không gây sát thương | 0 XP trận (không có XP tham gia riêng) | — |
| Nhiệm vụ đỏ | `m.squad` còn `alive` (đã loại chết/đào ngũ); **nếu không còn ai thì cả `roster`** | **Mỗi người** nhận đủ `QuestEconomy.redExp[độ khó]` = 12/16/20/26/32 (không chia: tổng = EXP × số người) | `GameRules._settle` (`rules.dart`), `QuestEconomy.redExp` (`economy.dart`) |
| Nhiệm vụ cuối | như trên | 60/người | `QuestEconomy.finalExp` |
| Nhiệm vụ vàng | — | 0 XP | `QuestEconomy.of` |
| Huấn luyện | — | **không cho XP** (chỉ chỉ số; thành thạo vũ khí tách riêng) | `GameRules.tickDay` |
| Học nhanh | — | ×1.3 cho mọi nguồn qua `xpGainFor`/`addXp` | `GameRules.addXp` |

Chống cộng lặp: `_settle` chốt `m.rewarded` trước khi thưởng; `applyBattle` chạy đúng một lần mỗi trận (mở lại màn kết quả hoặc tải save chỉ đọc);
`addXp` đặt `xp = 0` ở cấp 6 nên không tích XP thừa.

**Đính chính tài liệu cũ**: `SOLDIER_CONDITION_BALANCE.md` ghi XP nhiệm vụ đỏ "chia đều cho đội"; thực tế là **mỗi người nhận đủ**, tổng XP phát ra tăng tuyến tính theo
quy mô đội. Với các phương án so sánh, "ngân sách" được định nghĩa bằng đúng tổng hiện tại (`EXP × số người đủ điều kiện`).

Hành vi cần quyết định sản phẩm (chưa sửa): khi `m.squad` không còn ai sống, `_settle` thưởng XP cho **toàn bộ roster**, gồm cả người không tham gia.

## 2. Kết quả mô phỏng (đầu ra nguyên văn của công cụ)

### Rủi ro tử trận mỗi trận (đội 6 lính cùng cấp, HP/năng lượng đầy, 60 seed)

| Cấp đội | Nơi | Thắng | Lính tử trận / trận | Xác suất một lính chết / trận |
|---|---|---:|---:|---:|
| 1 | g_bandits | 100% | 0.82 | 13.6% |
| 1 | a_outpost | 0% | 6.00 | 100.0% |
| 1 | a_raiders | 0% | 6.00 | 100.0% |
| 1 | m_camp | 0% | 6.00 | 100.0% |
| 3 | g_bandits | 100% | 0.02 | 0.3% |
| 3 | a_outpost | 7% | 5.92 | 98.6% |
| 3 | a_raiders | 0% | 6.00 | 100.0% |
| 3 | m_camp | 0% | 6.00 | 100.0% |
| 6 | g_bandits | 100% | 0.00 | 0.0% |
| 6 | a_outpost | 100% | 1.80 | 30.0% |
| 6 | a_raiders | 50% | 4.62 | 76.9% |
| 6 | m_camp | 0% | 6.00 | 100.0% |

### Mô phỏng XP nhiệm vụ đỏ

Mỗi chiến dịch: 60 trận đánh g_bandits (đội cấp TB <5.5) hoặc a_outpost (≥5.5) — coi như luôn có địch để đánh, thực tế trại địch chỉ quét một lần nên XP trận bị giới hạn; lính chết/đào ngũ được tuyển bù cấp 1 (không theo dõi, chỉ tính vào cột Tử trận/Đào ngũ); 60 seed (0..59); mỗi trận thắng hoàn thành một nhiệm vụ đỏ độ khó 2–4 (EXP 16/20/26). Trước mỗi trận: loc.days ngày hành quân + `extraRest` ngày nghỉ (HP đầy, +12 năng lượng, +1 tinh thần mỗi ngày — mức của Doanh trại).

### Chế độ A — hao hụt thật (tử trận vĩnh viễn, tuyển bù lính cấp 1)

#### Chỉ XP trận (không có nhiệm vụ) — đội đồng đều

Trận tới cấp 6: 23 (P10 16, P90 28, min 10, max 39; n=220)
Tỉ lệ không lên cấp 6 trong 60 trận: 38.9%; tử trận 377, đào ngũ 25 (trên 360 lính được theo dõi)

#### Đội đồng đều (6 lính cấp 1)

| Phương án | Trận tới cấp 2 | Trận tới cấp 4 | Trận tới cấp 6 | Không lên cấp 6 | XP nhiệm vụ / XP trận | Chênh XP cao/thấp (trận 20) | Tử trận | Đào ngũ |
|---|---|---|---|---:|---:|---:|---:|---:|
| A hiện tại (mỗi người nhận đủ EXP) | 1 (P10 1, P90 1, min 1, max 1; n=312) | 4 (P10 3, P90 4, min 2, max 5; n=281) | 9 (P10 8, P90 10, min 6, max 11; n=267) | 25.8% | 146.3% | 4.35× | 1207 | 0 |
| B 30% đều + 70% sát thương | 1 (P10 1, P90 1, min 1, max 2; n=312) | 4 (P10 3, P90 5, min 2, max 6; n=280) | 10 (P10 7, P90 11, min 5, max 13; n=259) | 28.1% | 135.2% | 4.26× | 1135 | 2 |
| C 50% sát thương + 50% tham gia | 1 (P10 1, P90 1, min 1, max 2; n=312) | 4 (P10 3, P90 5, min 2, max 5; n=280) | 9 (P10 7, P90 11, min 5, max 13; n=259) | 28.1% | 137.8% | 4.57× | 1139 | 1 |

#### Một lính gây phần lớn sát thương

| Phương án | Trận tới cấp 2 | Trận tới cấp 4 | Trận tới cấp 6 | Không lên cấp 6 | XP nhiệm vụ / XP trận | Chênh XP cao/thấp (trận 20) | Tử trận | Đào ngũ |
|---|---|---|---|---:|---:|---:|---:|---:|
| A hiện tại (mỗi người nhận đủ EXP) | 1 (P10 1, P90 1, min 1, max 1; n=330) | 4 (P10 3, P90 5, min 2, max 5; n=305) | 9 (P10 8, P90 11, min 6, max 11; n=290) | 19.4% | 148.7% | 4.19× | 1116 | 0 |
| B 30% đều + 70% sát thương | 1 (P10 1, P90 1, min 1, max 2; n=330) | 4 (P10 3, P90 5, min 2, max 7; n=306) | 9 (P10 6, P90 12, min 5, max 14; n=283) | 21.4% | 136.3% | 4.75× | 959 | 2 |
| C 50% sát thương + 50% tham gia | 1 (P10 1, P90 1, min 1, max 2; n=330) | 4 (P10 3, P90 5, min 2, max 6; n=305) | 9 (P10 7, P90 12, min 5, max 13; n=290) | 19.4% | 140.8% | 4.70× | 1012 | 6 |

#### Lính mới tuyển ở trận 15

| Phương án | Trận tới cấp 2 | Trận tới cấp 4 | Trận tới cấp 6 | Không lên cấp 6 | XP nhiệm vụ / XP trận | Chênh XP cao/thấp (trận 20) | Tử trận | Đào ngũ |
|---|---|---|---|---:|---:|---:|---:|---:|
| A hiện tại (mỗi người nhận đủ EXP) | 1 (P10 1, P90 1, min 1, max 1; n=312) | 4 (P10 3, P90 4, min 2, max 5; n=281) | 9 (P10 8, P90 10, min 6, max 11; n=267) | 25.8% | 160.7% | 2.03× | 720 | 4 |
|   ↳ lính tuyển ở trận 15: số trận thêm để cấp 6 | 11 (P10 10, P90 11, min 8, max 12; n=60) | | | | | | | |
| B 30% đều + 70% sát thương | 1 (P10 1, P90 1, min 1, max 2; n=312) | 4 (P10 3, P90 5, min 2, max 6; n=280) | 10 (P10 7, P90 11, min 5, max 13; n=259) | 28.1% | 145.3% | 2.71× | 629 | 6 |
|   ↳ lính tuyển ở trận 15: số trận thêm để cấp 6 | 12 (P10 11, P90 14, min 9, max 16; n=60) | | | | | | | |
| C 50% sát thương + 50% tham gia | 1 (P10 1, P90 1, min 1, max 2; n=312) | 4 (P10 3, P90 5, min 2, max 5; n=280) | 9 (P10 7, P90 11, min 5, max 13; n=259) | 28.1% | 149.3% | 2.36× | 674 | 6 |
|   ↳ lính tuyển ở trận 15: số trận thêm để cấp 6 | 12 (P10 10, P90 13, min 8, max 14; n=60) | | | | | | | |

### Chế độ B — không hao hụt (lính chết được hồi sinh): cô lập tốc độ đường cong XP

#### Chỉ XP trận (không có nhiệm vụ) — đội đồng đều

Trận tới cấp 6: 23 (P10 18, P90 27, min 12, max 43; n=326)
Tỉ lệ không lên cấp 6 trong 60 trận: 9.4%; tử trận 11734, đào ngũ 197 (trên 360 lính được theo dõi)

#### Đội đồng đều (6 lính cấp 1)

| Phương án | Trận tới cấp 2 | Trận tới cấp 4 | Trận tới cấp 6 | Không lên cấp 6 | XP nhiệm vụ / XP trận | Chênh XP cao/thấp (trận 20) | Tử trận | Đào ngũ |
|---|---|---|---|---:|---:|---:|---:|---:|
| A hiện tại (mỗi người nhận đủ EXP) | 1 (P10 1, P90 2, min 1, max 2; n=360) | 4 (P10 3, P90 5, min 3, max 6; n=360) | 9 (P10 8, P90 11, min 6, max 33; n=360) | 0.0% | 144.9% | 1.00× | 16770 | 145 |
| B 30% đều + 70% sát thương | 1 (P10 1, P90 2, min 1, max 2; n=360) | 4 (P10 3, P90 5, min 2, max 7; n=360) | 9 (P10 8, P90 12, min 5, max 33; n=357) | 0.8% | 142.2% | 1.01× | 16811 | 161 |
| C 50% sát thương + 50% tham gia | 1 (P10 1, P90 2, min 1, max 3; n=360) | 4 (P10 3, P90 5, min 2, max 8; n=360) | 9 (P10 8, P90 12, min 6, max 41; n=357) | 0.8% | 143.9% | 1.02× | 16858 | 154 |

#### Một lính gây phần lớn sát thương

| Phương án | Trận tới cấp 2 | Trận tới cấp 4 | Trận tới cấp 6 | Không lên cấp 6 | XP nhiệm vụ / XP trận | Chênh XP cao/thấp (trận 20) | Tử trận | Đào ngũ |
|---|---|---|---|---:|---:|---:|---:|---:|
| A hiện tại (mỗi người nhận đủ EXP) | 1 (P10 1, P90 1, min 1, max 2; n=360) | 4 (P10 3, P90 5, min 2, max 5; n=360) | 10 (P10 8, P90 11, min 6, max 16; n=360) | 0.0% | 143.9% | 1.00× | 16040 | 224 |
| B 30% đều + 70% sát thương | 1 (P10 1, P90 2, min 1, max 2; n=360) | 4 (P10 3, P90 5, min 2, max 7; n=360) | 10 (P10 6, P90 13, min 5, max 30; n=360) | 0.0% | 140.1% | 1.00× | 15720 | 227 |
| C 50% sát thương + 50% tham gia | 1 (P10 1, P90 2, min 1, max 2; n=360) | 4 (P10 3, P90 5, min 2, max 7; n=360) | 10 (P10 7, P90 12, min 5, max 35; n=360) | 0.0% | 141.6% | 1.00× | 15858 | 217 |

#### Lính mới tuyển ở trận 15

| Phương án | Trận tới cấp 2 | Trận tới cấp 4 | Trận tới cấp 6 | Không lên cấp 6 | XP nhiệm vụ / XP trận | Chênh XP cao/thấp (trận 20) | Tử trận | Đào ngũ |
|---|---|---|---|---:|---:|---:|---:|---:|
| A hiện tại (mỗi người nhận đủ EXP) | 1 (P10 1, P90 2, min 1, max 2; n=360) | 4 (P10 3, P90 5, min 3, max 6; n=360) | 9 (P10 8, P90 11, min 6, max 16; n=360) | 0.0% | 134.7% | 1.56× | 12513 | 705 |
|   ↳ lính tuyển ở trận 15: số trận thêm để cấp 6 | 8 (P10 7, P90 8, min 6, max 10; n=60) | | | | | | | |
| B 30% đều + 70% sát thương | 1 (P10 1, P90 2, min 1, max 2; n=360) | 4 (P10 3, P90 5, min 2, max 7; n=360) | 9 (P10 8, P90 12, min 5, max 20; n=360) | 0.0% | 133.0% | 1.76× | 11771 | 743 |
|   ↳ lính tuyển ở trận 15: số trận thêm để cấp 6 | 8 (P10 7, P90 10, min 6, max 11; n=60) | | | | | | | |
| C 50% sát thương + 50% tham gia | 1 (P10 1, P90 2, min 1, max 3; n=360) | 4 (P10 3, P90 5, min 2, max 8; n=360) | 9 (P10 8, P90 12, min 6, max 18; n=360) | 0.0% | 135.8% | 1.70× | 11249 | 755 |
|   ↳ lính tuyển ở trận 15: số trận thêm để cấp 6 | 8 (P10 7, P90 10, min 6, max 11; n=60) | | | | | | | |

#### Kiểm tra bất biến của phép chia (mọi phương án)

6000 phép chia ngẫu nhiên: vi phạm bất biến = 0 (tổng ≤ ngân sách, không XP cho người không đủ điều kiện, độc lập thứ tự).


## 3. Đọc kết quả

* **Rủi ro tử trận quyết định tiến độ hơn XP**: đội cấp 1–3 gần như không thắng được `a_outpost` trở lên (0–7%), nên cột "Trận tới cấp 6 (TB) 14–25" trong
  `SOLDIER_CONDITION_BALANCE.md` (chia tổng XP cho số trận, không xét thắng/thua/chết) **không đạt được trong thực tế**. Đầu game chỉ `g_bandits` đánh được (13.6% lính chết/trận ở cấp 1), nhưng trại địch chỉ quét một lần.
* Chế độ A (thực tế nhất): chỉ XP trận cần median **23** trận để lên cấp 6 (P10 16, P90 28, min 10, max 39) và **38.9%** lính được theo dõi không lên được trong 60 trận (chủ yếu do chết).
  Có XP nhiệm vụ đỏ (giả định mỗi trận thắng hoàn thành một nhiệm vụ — cận trên lạc quan) median còn **9–10** trận: XP nhiệm vụ bằng khoảng 135–150% XP trận (cột "XP nhiệm vụ / XP trận"), tức ~57–60% tổng XP → **XP nhiệm vụ là nguồn lên cấp chính**.
* So sánh phương án (đội đồng đều, chế độ A): trận tới cấp 6 median A=9, B=10, C=9; P90 A=10, B=11, C=11; min A=6, B=5, C=5. Tỉ lệ không lên cấp 6: A 25.8%, B/C 28.1%.
  Chênh XP cao/thấp ở trận 20: A 4.35×, B 4.26×, C 4.57× — **không phương án nào thu hẹp khoảng cách**; B/C chỉ làm người đóng góp thấp chậm hơn ~1 trận và người đóng góp cao nhanh hơn ~1 trận.
* Lính tuyển ở trận 15 cần thêm median **11** (A) / **12** (B, C) trận tới cấp 6 — bám kịp đội cũ ở cả ba phương án.
* Bất biến của phép chia (6000 phép chia ngẫu nhiên): tổng ≤ ngân sách, không XP cho lính chết/đào ngũ, không phụ thuộc thứ tự lính — đạt cho cả ba phương án.

## 4. Quyết định

**Giữ nguyên công thức A (không đổi XP nhiệm vụ).** Lý do:

1. Mô phỏng không cho thấy B/C cải thiện khoảng cách XP hay tỉ lệ lính tụt lại; khác biệt tới cấp 6 chỉ ±1 trận.
2. B/C cần sát thương theo nhiệm vụ, nhưng `_settle` không nhận `BattleReport` (chỉ có danh sách id trong `m.squad`) — phải đổi luồng thưởng, có thể đổi schema save.
3. Rủi ro lạm dụng của A (đội đông = XP nhiều hơn tuyến tính; người không gây sát thương vẫn được đủ) có thật nhưng bị chặn bởi trần cấp 6 (240 XP) và `maxSquad = 10`.

Đề xuất chưa áp dụng (cần xác nhận sản phẩm):

* (a) Muốn gắn thưởng với đóng góp: phương án B đơn giản nhất — truyền sát thương hợp lệ của trận hoàn thành nhiệm vụ vào `_settle`, không lưu thêm.
* (b) Ngân sách cố định kiểu `EXP × min(n, 4)` để chặn XP tăng theo quy mô đội.
* (c) Sửa fallback "cả roster" khi squad rỗng.
* (d) Xem lại độ khó `a_outpost` trở lên so với cấp lính; điểm nghẽn là tử trận và nguồn XP hữu hạn, không phải đường cong 240 XP.

Hạn chế của mô phỏng: điểm chỉ số được xoay vòng 4 chỉ số; mỗi trận thắng đều hoàn thành một nhiệm vụ đỏ (cận trên); không có đội hình/chiến thuật; chế độ B (hồi sinh) đẩy đội cấp 6 vào
`a_outpost` nên số tử trận ở chế độ đó chỉ để cô lập đường cong XP, không đo rủi ro; đào ngũ mô phỏng chịu ảnh hưởng của mức nghỉ (Doanh trại +12 năng lượng, +1 tinh thần mỗi ngày hành quân).
