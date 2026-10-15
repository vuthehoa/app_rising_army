# Nhiệm vụ săn: thời hạn, cân bằng đầu game, cứu trợ

## Thời hạn
* Mỗi nhiệm vụ săn random `QuestGenerator.minQuestDays..maxQuestDays` (3–7) ngày **một lần** lúc nhận (`acceptMission`, rng của ván), không ngắn hơn `thời gian đi + 2` ngày (1 ngày hành quân vào điểm giao chiến + 1 ngày đánh).
* Lưu `Mission.days` (ban đầu) và `Mission.deadline` (ngày tuyệt đối). Số ngày còn lại = `deadline - state.day` (`GameRules.remainingDays`) nên chỉ đổi khi `tickDay` chạy; không có bộ đếm riêng để giảm trùng.
* Thứ tự `tickDay`: lương/hồi phục/huấn luyện → `day++` → **hết hạn** → `fillBoard` → cứu trợ. Hết hạn (còn 0 ngày): xóa nhiệm vụ (điểm giao chiến suy ra từ nhiệm vụ nên biến mất cùng lúc, slot giải phóng), không phạt, không thưởng. Nhiệm vụ hành chính cũ (không còn được sinh) giữ luật phạt hài lòng.
* Hết hạn ngay trong lúc hành quân vào điểm giao chiến: `sendExpedition` trả lỗi, không có trận.
* Save cũ không có `days`: tải bình thường (`days = 0`), hạn tuyệt đối giữ nguyên; nhiệm vụ còn đúng 0 ngày hết hạn ở lần qua ngày kế tiếp. Không đổi version save.

## Cứu trợ chống softlock
`GameRules.isSoftlocked`: không còn binh sĩ, và vàng + bán hết kho + bán hết tài nguyên theo lô < giá ứng viên rẻ nhất, và không hồi sinh nổi ai. Khi qua ngày và bế tắc, tặng một tân binh cấp 1 + 12 vàng + 8 lương thực,
tối thiểu 15 ngày mới có lại (`GameState.reliefDay`, lưu trong save). Không có thu nhập thụ động.

## Cân bằng (`dart run tool/quest_balance_sim.dart`)
Thay đổi: `enemyPlan` — độ khó 1 co theo quân số (≥5: 2 giáo+2 cung; 4: 2+1; 3: 1+2; ≤2: 1+1); độ khó 2–4 còn 2 giáo+2 cung (+1 kỵ ở độ khó 5), cấp địch = độ khó.
Trước: đội 6 lính cấp 1 thắng 100% độ khó 1 nhưng **0%** độ khó 2; đội 6 lính cấp 3 thắng 12% độ khó 2 (đội 4 lính: 75% thắng, 25% xóa sổ; đội 3 lính: 2% thắng).
Sau (bảng dưới): đội 6 cấp 1 thắng 100% độ khó 2; cấp 3 thắng 98% độ khó 3; đội 3–4 lính thắng 90–100% độ khó 1.

# Cân bằng nhiệm vụ săn (seed 0..59)

Tiêu chí đặt trước khi chạy: đội mới (6 lính cấp 1) cần ít nhất một độ khó có tỉ lệ thắng >= 70% và tử vong TB <= 1 lính/trận; tỉ lệ bị xóa sổ <= 5%; thời hạn luôn >= thời gian đi + 2 ngày.

| Đội | Độ khó | Thắng | Lính chết TB | Xóa sổ |
|---|---:|---:|---:|---:|
| 6 lính cấp 1 | 1 | 100% | 0.82 | 0% |
| 6 lính cấp 1 | 2 | 100% | 1.82 | 0% |
| 6 lính cấp 1 | 3 | 40% | 4.65 | 60% |
| 6 lính cấp 1 | 4 | 0% | 6.00 | 100% |
| 6 lính cấp 1 | 5 | 0% | 6.00 | 100% |
| 4 lính cấp 1 | 1 | 100% | 1.03 | 0% |
| 4 lính cấp 1 | 2 | 0% | 4.00 | 100% |
| 4 lính cấp 1 | 3 | 0% | 4.00 | 100% |
| 4 lính cấp 1 | 4 | 0% | 4.00 | 100% |
| 4 lính cấp 1 | 5 | 0% | 4.00 | 100% |
| 3 lính cấp 1 | 1 | 90% | 1.05 | 10% |
| 3 lính cấp 1 | 2 | 0% | 3.00 | 100% |
| 3 lính cấp 1 | 3 | 0% | 3.00 | 100% |
| 3 lính cấp 1 | 4 | 0% | 3.00 | 100% |
| 3 lính cấp 1 | 5 | 0% | 3.00 | 100% |
| 6 lính cấp 2 | 1 | 100% | 0.20 | 0% |
| 6 lính cấp 2 | 2 | 100% | 0.82 | 0% |
| 6 lính cấp 2 | 3 | 80% | 2.97 | 20% |
| 6 lính cấp 2 | 4 | 7% | 5.82 | 93% |
| 6 lính cấp 2 | 5 | 0% | 6.00 | 100% |
| 6 lính cấp 3 | 1 | 100% | 0.02 | 0% |
| 6 lính cấp 3 | 2 | 100% | 0.47 | 0% |
| 6 lính cấp 3 | 3 | 98% | 1.77 | 2% |
| 6 lính cấp 3 | 4 | 47% | 4.55 | 53% |
| 6 lính cấp 3 | 5 | 0% | 6.00 | 100% |

## Thời hạn so với thời gian đi (200 seed, ván mới, nhận ở g_town)

* Số ngày hạn: min 3, median 5, max 7
* Ngày đi tới điểm giao chiến (từ vị trí nhân vật): min 1, median 1, max 1
* Ngày dư sau khi đi + hành quân vào trận: min 0, median 2, max 4
* Nhiệm vụ có hạn ngắn hơn thời gian đi + 2: 0/200

Giới hạn: chiến đấu rất dốc (thắng/thua gần nhị phân theo tương quan lực lượng); tử vong khi thắng còn cao ở rìa (độ khó 3 với đội cấp 2: ~3 lính chết/trận); mô phỏng không phân bổ điểm chỉ số, không dùng đội hình/trang bị tốt hơn khởi điểm.
Độ khó 5 chưa khả thi cho đội cấp ≤3 (hai bậc cao nhất dành cho đội mạnh hơn); đội 3 lính cấp 1 vẫn có 10% bị xóa sổ ở độ khó 1 (vượt tiêu chí 5% — chấp nhận vì đã có cứu trợ).
