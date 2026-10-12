# Kế hoạch tái thiết gameplay

Nhãn: **VERIFIED** (nguồn đã đọc, xem ORIGINAL_GAME_GAP_ANALYSIS.md), **PROPOSED** (thiết kế chuyển thể của tôi).

## Vòng lặp (PROPOSED, bám các hệ thống VERIFIED)
Trại → quản lý từng binh sĩ → huấn luyện + trang bị → nhận nhiệm vụ của nhà vua → chọn đội hình → viễn chinh (khám phá/chiến đấu) →
thương vong + phần thưởng → về trại → phát triển → nhiệm vụ kế tiếp. Thời gian tính bằng ngày; mỗi ngày trả lương, tinh thần, hồi phục, tập luyện, đếm hạn.

## Domain (lib/domain)
| File | Trách nhiệm |
|---|---|
| models.dart | `Soldier` (id ổn định, id âm = lính địch), `Mission`, `GameState`, (de)serialize + kiểm tra hợp lệ |
| catalog.dart | Dữ liệu: vật phẩm, đặc điểm, công trình, vùng, địa điểm, mẫu nhiệm vụ, tên |
| stats.dart | Chỉ số suy ra từ binh sĩ + trang bị + đặc điểm + tinh thần; kiểm tra điều kiện trang bị |
| battle.dart | Auto-battler thuần, xác định theo seed, trả `BattleReport` (chuỗi sự kiện) |
| rules.dart | Luật: tuyển, huấn luyện, trang bị, công trình, nhiệm vụ, qua ngày, viễn chinh, áp kết quả trận |
Ngẫu nhiên đi qua `seed + rngCounter` lưu trong save nên tái lập được. UI chỉ gọi `GameController`.

## Quy tắc chính (PROPOSED trừ khi ghi khác)
- **Binh sĩ**: 3 vai trò (giáo/cung/kỵ), 4 chỉ số (VERIFIED tên chỉ số), cấp 1-20, XP `20×cấp`, đặc điểm (6).
- **Chỉ số chiến đấu**: Máu = 24 + 3×thể trạng + 4×cấp; Công = sát thương vũ khí + 0.8×chỉ số chính của vai trò; Giảm sát thương = giáp/(giáp+25).
- **Trận**: tối đa 40 hiệp, mỗi hiệp mọi đơn vị hành động theo tốc độ. Hàng trước bị đánh trước; cung và kỵ chọn mục tiêu bất kỳ; giáo +25% vs kỵ.
  Khi phe tổn thất ≥ 50% và tinh thần thấp, lính có thể bỏ chạy.
- **Hậu quả**: gục ngã → chết vĩnh viễn (xác suất 80% − 12%×cấp Trạm y tế, tối thiểu 40%) hoặc bị thương 3-6 ngày; còn <35% máu → bị thương 1-3 ngày;
  rút lui; XP cho người sống; đồng đội chết làm giảm tinh thần cả trại.
- **Kinh tế**: mỗi lính tốn 1 thức ăn + 1 đồng xu/ngày; nhà vua cấp bổng lộc 12 thức ăn + 10 đồng xu nhân (0.5 + hài lòng/100).
- **Nhà vua**: tối đa 3 nhiệm vụ cùng lúc; hoàn thành +hài lòng, quá hạn/bỏ −hài lòng; hài lòng 0 = thua (VERIFIED game over khi làm vua thất vọng).
  Tiến trình mở khóa vùng ở 3 và 6 nhiệm vụ; nhiệm vụ cuối xuất hiện ở 10 nhiệm vụ.
- **Bản đồ**: 3 vùng, 14 địa điểm, ẩn đến khi trinh sát hoặc khám phá tàn tích; trại địch quét sạch một lần (chống farm đã học từ Phase 2); điểm tài nguyên lặp lại được nhưng tốn ngày và lương, có 30% phục kích.

## Cân bằng có đo (tool/battle_sim.dart, test `Đường cong khó của chiến dịch`)
Ải đầu (6 lính khởi đầu) thắng 100%; trại bậc 2 cần ~cấp 3 + đồ bậc 2; nhiệm vụ cuối ~30-80% với 8 người cấp 6, +2 chỉ số, đồ bậc 3 và >70% với 10 người.
Đã chỉnh XP và cỡ đội tối đa (8→10) sau khi mô phỏng cho thấy nhiệm vụ cuối gần như bất khả thi với nguồn kinh nghiệm hữu hạn.

## Lộ trình tiếp theo
Kèn trận (VERIFIED có ở gốc) và thành phố/người bán; mở rộng danh mục vật phẩm; kỹ năng/đặc điểm; âm thanh và minh họa hoàn thiện;
mô phỏng kinh tế nhiều ngày cho mô hình mới (chưa làm); kiểm tra thiết bị thật và 60 FPS (chưa đo).
