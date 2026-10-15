# Cân bằng chỉ số lính, XP, công trình, thể trạng chiến đấu

Mã nguồn: `lib/domain/stats.dart` (XP, chỉ số, trần), `lib/domain/combat_condition.dart` (XP theo sát thương, năng lượng,
tinh thần), `lib/domain/building_effects.dart` (buff/debuff và huấn luyện), `lib/domain/battle.dart` (đo số liệu trong trận),
`GameRules.applyBattle/addXp/allocateStat/desert` (áp dụng một lần). Hiệu chuẩn: `dart run tool/soldier_balance_sim.dart`.

## Ánh xạ bốn chỉ số chính (không tạo thuộc tính trùng)

| Hiển thị | Dữ liệu | Ghi chú |
|---|---|---|
| Sức mạnh | `Stat.str` | trước đây "Sức mạnh" |
| Tốc độ | `Stat.dex` | trước đây "Khéo léo" (đổi tên hiển thị) |
| Thể hình | `Stat.con` | trước đây "Thể trạng"/"Thể lực" |
| Công | `Soldier.atkPoints` | chưa từng có chỉ số cơ bản nên là trường riêng (chỉ tăng nhờ điểm cấp) |

## Audit công trình (nguồn duy nhất: `facilityEffects`)

| Công trình | Buff | Debuff | Đối tượng / điều kiện | Nơi áp dụng thật |
|---|---|---|---|---|
| Lều cứu thương | HP `++`, Năng lượng `+` | — | lính được gán, mỗi ngày | `tickDay`: hồi `hpHealPerDay` (20/10), `_applyDailyPoints` năng lượng +6 |
| Bãi bắn cung | Tốc độ `++`, Sức mạnh `+`, Thể hình `+` | Năng lượng `--`, Tinh thần `-` | lính được gán | huấn luyện `trainingRates`; năng lượng −5/ngày, tinh thần −2/ngày |
| Bãi cận chiến | Sức mạnh `++`, Thể hình `+` | Năng lượng `--`, Tinh thần `-` | lính được gán | huấn luyện; năng lượng −5, tinh thần −2 |
| Bãi đá | (đốm lửa Tinh thần `++` chỉ hiển thị) | — | lính được gán | rèn Thể hình (`_trainingFallback`: `++`) |
| Doanh trại | Năng lượng `++`, Tinh thần `+` | — | lính nhàn rỗi/được gán, mỗi ngày | `_applyDailyPoints`: năng lượng +12, tinh thần +1 |
| Hòm đồ / Bia mộ | — | — | — | không có hiệu ứng chỉ số |

Hệ số theo ký hiệu (khác nhau theo loại chỉ số, vì tác động chiến đấu khác nhau):

| Ký hiệu | HP hồi/ngày | Năng lượng/ngày | Tinh thần/ngày | Huấn luyện cấp 1 (%/ngày) | Huấn luyện cấp 2 (%/ngày) | Buff hiển thị khi đang tập |
|---|---:|---:|---:|---:|---:|---:|
| `++` | +20 | +12 | +3 | 25 (4 ngày/điểm) | 35 (3 ngày/điểm) | +50% |
| `+` | +10 | +6 | +1 | 15 (7 ngày/điểm) | 22 (5 ngày/điểm) | +25% |
| `-` | — | −3 | −2 | không huấn luyện | không huấn luyện | −15% |
| `--` | — | −5 | −4 | không huấn luyện | không huấn luyện | −30% |

Thay đổi so với trước: tiến độ huấn luyện chuyển từ "mọi công trình 25% một chỉ số" sang theo từng chỉ số `++`/`+` và theo cấp
công trình (`Facility.level`, game chỉ có 2 cấp); debuff nhẹ hơn (tinh thần `-` −3→−2, `--` −6→−4; năng lượng `--` −6→−5) vì
rút cạn tinh thần nay dẫn tới đào ngũ vĩnh viễn; `Bãi bắn cung` huấn luyện Tốc độ (`++`) thay vì Sức mạnh. Tiến độ lưu dạng số nguyên phần
trăm trong `Soldier.train` nên không mất phần lẻ. Buff % "khi đang tập" chỉ là chỉ số hiển thị trong hồ sơ (`deriveStats(training:)`); khi ra trận lính rời công
trình nên trận chỉ dùng chỉ số cơ bản — không cộng hai lần. Huấn luyện không còn cho XP (trước: +15 XP mỗi điểm), vì XP phải đến từ chiến đấu.

## Tác động chỉ số (mỗi điểm)

Sức mạnh: công qua `primary` (sẵn có) + **+1 HP**. Tốc độ: chạy +0.12 m/s, chính xác, chí mạng (sẵn có) + **chu kỳ đánh −0.8%/điểm trên 5** (kẹp 0.85–1.1) + năng lượng tối đa +2/điểm trên 5.
Thể hình: **HP +3** (lớn nhất, sẵn có) + tinh thần tối đa +2/điểm trên 5. Công: **+0.75 công, +0.4% chính xác, +0.4% chí mạng**. Kiệt sức:
dưới 50% năng lượng tối đa, chu kỳ đánh chậm dần tới +25% khi cạn. Tất cả nằm trong `deriveStats` (thứ tự: cơ bản → điểm → trang bị → đặc điểm/công trình tạm thời → kiệt sức).

### Đường cong XP

| Lên cấp | XP cần | Tổng XP |
|---|---:|---:|
| 1 → 2 | 18 | 18 |
| 2 → 3 | 30 | 48 |
| 3 → 4 | 45 | 93 |
| 4 → 5 | 62 | 155 |
| 5 → 6 | 85 | 240 |

### XP mỗi trận theo mức đóng góp (đội 6 lính cấp 1–2, địch thật)

| Địa điểm | Địch | Tổng XP/trận | Thấp (P10) | Trung bình | Cao (P90) | Thời lượng TB (s) | Trận tới cấp 6 (TB) |
|---|---:|---:|---:|---:|---:|---:|---:|
| g_bandits | 4 | 64 | 7 | 10.7 | 14 | 27 | 23 |
| a_outpost | 6 | 101 | 8 | 16.9 | 28 | 43 | 14 |
| a_raiders | 7 | 73 | 6 | 12.2 | 18 | 27 | 20 |
| m_camp | 8 | 57 | 5 | 9.6 | 15 | 23 | 25 |

### Tác động bốn chỉ số (lính giáo cấp 1 làm gốc, thêm 5 điểm vào MỘT chỉ số = lên cấp 6)

| Kịch bản | HP | Công | DPS | Chu kỳ | Tốc độ | Năng lượng tối đa | Tinh thần tối đa |
|---|---:|---:|---:|---:|---:|---:|---:|
| Cấp 1 (gốc) | 60 (100%) | 10.2 (100%) | 4.15 (100%) | 1.77 | 3.04 | 104 | 106 |
| Cấp 6, chưa phân bổ | 80 (133%) | 10.2 (100%) | 4.15 (100%) | 1.77 | 3.04 | 104 | 106 |
| +5 Sức mạnh | 85 (142%) | 13.0 (128%) | 5.30 (128%) | 1.77 | 3.04 | 104 | 106 |
| +5 Tốc độ | 80 (133%) | 11.4 (112%) | 5.24 (126%) | 1.70 | 3.64 | 114 | 106 |
| +5 Thể hình | 95 (158%) | 10.2 (100%) | 4.15 (100%) | 1.77 | 3.04 | 104 | 116 |
| +5 Công | 80 (133%) | 13.9 (137%) | 5.84 (141%) | 1.77 | 3.04 | 104 | 106 |

### Tiêu hao năng lượng / tinh thần theo thời lượng trận

| Địa điểm | Thời lượng TB (s) | Năng lượng mất TB (người sống) | Max | Tinh thần mất TB (người sống) | Max | Bỏ chạy (%) |
|---|---:|---:|---:|---:|---:|---:|
| g_bandits | 22 | 12.3 | 18 | 3.7 | 22 | 0.0 |
| a_outpost | 23 | 13.4 | 18 | 5.9 | 22 | 0.0 |
| a_raiders | 41 | 22.6 | 31 | 9.4 | 23 | 0.0 |
| m_camp | 46 | 32.8 | 34 | 11.4 | 22 | 0.0 |

## Quy tắc đã chọn

* **XP**: mỗi kẻ địch có giá trị `10 + 6×cấp`; người lính nhận `Σ giá trị × (sát thương hợp lệ của họ / HP tối đa của địch)`. Sát thương hợp lệ bị chặn ở HP còn lại của mục tiêu (không tính sát thương thừa), chỉ quân ta, chỉ đòn trúng đã áp dụng. Tổng XP của trận khớp đúng `round(Σ giá trị × tỉ lệ HP bị trừ)` (chia số dư theo phần thập phân). Thua trận vẫn nhận XP theo sát thương đã gây. Người chết hoặc bỏ chạy không nhận XP.
* **Điểm chỉ số**: +1 mỗi lần lên cấp (2→6, tối đa 5 điểm); hồi đầy HP/năng lượng/tinh thần chỉ khi dùng điểm cuối cùng.
* **Năng lượng**: mất `(0.4×giây còn đứng + 0.5×số đòn) × hiệu suất Tốc độ (−2%/điểm trên 5, tối đa −30%)`, chỉ người ra trận.
* **Tinh thần**: mỗi đòn trúng quân ta `0.3 + 18×sát thương nhận / HP tối đa`; đòn trượt không tốn. Địch không bỏ chạy. Cộng/trừ sau trận (+8 thắng, −10 thua, − thương vong) giữ nguyên.
* **Đào ngũ**: tinh thần về 0 giữa trận → lính bỏ chạy ngay (không đánh/không bị nhắm nữa); sau trận hoặc khi qua ngày, ai ≤ 0 đều đào ngũ. `GameRules.desert` đánh dấu `SoldierStatus.deserted`, gỡ khỏi công trình, trả trang bị về kho (như sa thải), không tính lương, giữ lịch sử, gọi lặp vô hại. Cơ chế cũ "≤15 tinh thần: 25%/ngày" được giữ.
* **Trần cấp 6**: save cũ có cấp > 6 bị kẹp về 6 khi nạp, không cấp điểm bù; mọi nguồn XP đi qua `addXp`.

## Còn lại / cần bạn xác nhận

1. XP thưởng nhiệm vụ đỏ (`QuestEconomy.redExp`): thực tế **mỗi người** trong đội nhận đủ (không chia), xem audit và mô phỏng ở `docs/qa/QUEST_XP_AUDIT.md`. Đã mô phỏng hai phương án gắn với sát thương; không cải thiện đáng kể nên **giữ nguyên**.
2. Cột "Trận tới cấp 6" ở bảng XP/trận phía trên là phép chia số học, không tính thắng/thua/tử trận; đội cấp 1–3 hầu như không thắng được `a_outpost` trở lên (xem `QUEST_XP_AUDIT.md`). Trại địch chỉ quét một lần nên XP trận hữu hạn; XP nhiệm vụ mới là nguồn chính.
3. Chưa kiểm tra bằng simulator/thiết bị; cảnh báo đỏ ở Roster, băng bó, nút +, dấu lên cấp được kiểm bằng test widget (667×375, 844×390, 932×430).
4. Đã sửa các test cũ phụ thuộc số cứng (XP 20×cấp, `Còn N EXP`, so sánh pixel sprite thủ công) cho khớp mô hình mới; đã audit lại: một assertion bị bỏ (`a.xp > xpA` ở `progression_test.dart`, vốn dựa vào XP-theo-đòn cũ) được thay bằng hợp đồng mới "có XP khi và chỉ khi gây sát thương hợp lệ".
