# Báo cáo mô phỏng kinh tế nhiều ngày (mô hình binh sĩ cá nhân) — Phase 3A

Dữ liệu: [generated/baseline_econ_summary.md](generated/baseline_econ_summary.md) (trước), [generated/econ_summary.md](generated/econ_summary.md) (sau, 60 ngày),
[generated/long150_summary.md](generated/long150_summary.md) (sau, 150 ngày), cùng `*_raw.csv` (từng ngày, từng seed, để phân tích lại).

## Cách chạy lại
```
dart run tool/economy_sim.dart [thư_mục] [tiền_tố]      # mặc định docs/qa/generated, tiền tố econ_
SIM_DAYS=150 dart run tool/economy_sim.dart <thư_mục> long_
```
11 phong cách x 20 seed (1..20) x 60 ngày + 4 kịch bản softlock x 20 seed = **320 ván** mỗi lần chạy. Dùng đúng `GameRules` (không nhân bản luật);
sổ thu/chi lấy từ `GameRules.ledgerIn/ledgerOut`. Đã chạy hai lần và so sánh byte-by-byte: `econ_raw.csv` **giống hệt** (test `tái lập` kiểm tra thêm ở mức trạng thái).

## 1. Audit kinh tế (đọc từ source)

| Loại | Nội dung |
|---|---|
| Tài nguyên | Thức ăn, đồng xu, gỗ, sắt. Không có giới hạn tồn kho; kho **đồ** có sức chứa 30 + 10×cấp Doanh trại (Phase 3). |
| Dùng để mua sắm | Đồng xu (tuyển ~83/người, trang bị 15–180, huấn luyện 10/buổi, công trình 30–140, thành phố). Gỗ+sắt chỉ cho công trình. |
| Tiêu hao theo ngày | 1 thức ăn + 1 đồng xu mỗi binh sĩ mỗi ngày; trinh sát tốn 5 thức ăn. |
| Chỉ thu từ hoạt động | Gỗ/sắt/thức ăn: điểm thu thập (kèm phục kích). Đồng xu: bổng lộc nhà vua, phần thưởng nhiệm vụ (hữu hạn), chiến lợi phẩm trại (một lần), kho báu tàn tích (một lần), **bán đồ/lô tài nguyên ở thành phố**. |
| Tổn thất | Tử trận vĩnh viễn (~80% số gục), thương tích nghỉ vài ngày, không hồi sinh; thất bại không mất thêm tài nguyên. |
| Thời hạn / hài lòng | Nhiệm vụ có hạn tính từ lúc nhận; quá hạn trừ điểm phạt của mẫu; hài lòng ≤ 0 = thua. Bổng lộc nhân (0.5 + hài lòng/100). |

Không thêm loại tiền mới. Tài nguyên dư (thức ăn, gỗ, sắt) được bán lấy đồng xu ở thành phố thay vì tạo tiền tệ khác.

## 2. Phát hiện ban đầu (baseline, luật Phase 2 chưa đổi)

| # | Phát hiện | Bằng chứng | Mức | Xử lý |
|---|---|---|---|---|
| 1 | Phục kích khi thu thập là "thuế tử vong": địch tăng theo bậc (cấp 1+bậc), xác suất 30% mỗi chuyến | Policy thu thập/xây dựng: 23–25 chuyến → ~7 lần phục kích, **thua 6–7**, **13–17 binh sĩ chết**; gom gỗ/sắt (cần cho công trình) không bền vững | Cao | **Đã sửa** |
| 2 | Mất quân gần như không phục hồi được: chỉ có bổng lộc ~10 đồng xu/ngày, tuyển tốn ~83 | Mất toàn bộ quân, hết tài nguyên: **28 ngày** mới có 3 người sẵn sàng; **không bao giờ** (0/20) có 6 người trong 40 ngày | Cao (gần softlock) | **Đã sửa** |
| 3 | Không có cách đổi tài nguyên dư thành đồng xu: thức ăn cuối ván 400–800, gỗ/sắt kẹt ở 10–50 hoặc dư hàng trăm tùy policy; đồng xu nghẽn | Policy 01/03/10 cuối ván (baseline) cầm 658–750 đồng xu **không tiêu** vì thiếu gỗ/sắt mở lò rèn bậc 2 | Trung bình | **Đã xử lý bằng thương nhân** (Phase 3B) |
| 4 | Tiến trình chiến dịch quá chậm: không policy nào đủ sức hạ trại bậc 2 đầu tiên (ngưỡng nguy hiểm ≤ 0.8) trong 60 ngày; nhiệm vụ "clear" bậc 2–3 hoàn thành ~0% | Ngày đầu tiên đủ sức hạ Tiền đồn cướp: không bao giờ (07), 59 (11: 1/20) | Cao | **Giảm một phần** (xem 3) |
| 5 | Mỏ sắt/gỗ không có nguồn nào ngoài viễn chinh nguy hiểm → công trình bị khóa | 3 policy kẹt ở 10 gỗ/10 sắt | Trung bình | Giảm phục kích (1) + bán/mua lô vật tư ở thành phố |
| 6 | Policy "đánh liên tục thất bại" có 25% game over; policy ép hạn nhiệm vụ hài lòng 18 | Do chủ đích (rủi ro người chơi), không phải lỗi thiết kế | - | Giữ nguyên (không loại permadeath) |

Ghi chú về thước đo: ngưỡng nguy hiểm dùng tỷ lệ `Σ powerScore(địch) / Σ powerScore(ta)`. Hiệu chuẩn bằng 300 trận/ô: tỷ lệ ≈ 1.0 ↔ thắng ~90% **nhưng mỗi trận thắng vẫn làm ~vài người gục** (tốn ~85 đồng xu/người chết),
nên policy hợp lý chỉ tấn công khi ≤ 0.8 (gục ≈ 1).

## 3. Thay đổi đã áp dụng (có số liệu trước/sau)

| Thông số | Trước | Sau | Lý do / tác động đo được |
|---|---|---|---|
| `ambushChance` | 0.30 | **0.20** | Giảm số lần bị phục kích |
| Cấp địch phục kích | `1 + bậc` | **`1 + bậc ~/ 2`** | Phục kích ở bậc 2 từ cấp 3 xuống cấp 2: đội 4 người cấp 2 thắng >80% (test thống kê có seed). Chuyến thu thập: chết do phục kích 13–17 → **4–8**, tổng chết 12–17 → **3–7** |
| Trợ cấp khẩn (`reliefCoins`/`reliefThreshold`) | không có | **+24 đồng xu/ngày khi 0 quân, giảm tuyến tính tới 0 ở 6 quân** | Không "vách đá" (không khuyến khích giữ quân ít); không hồi sinh ai. Mất toàn bộ quân: 3 người sẵn sàng **28 → 8 ngày**; 6 người **không bao giờ → 20 ngày** (20/20 seed). Còn 1 quân hết sạch: 6 người sau 18 ngày |
| `kingStipendCoins` | 10 | **16** | Đồng xu là nút thắt tăng trưởng. Tiền đồn cướp đủ sức: **không bao giờ/59 → ngày 36–38 (17/20)**; chạy 150 ngày: hang ổ ngày ~98–113 (14–17/20), lính đánh thuê ngày ~124–131 (1–7/20) |
| `kingStipendFood` | 12 | **10** | Giảm thặng dư thức ăn (cuối ván thức ăn 638–820 → 290–530 ở phong cách hợp lý) |
| Giao dịch ở thành phố | không có | bán đồ/lô, mua đồ bậc cao, lô vật tư (Phase 3B) | Có đường đổi tài nguyên dư và mua đồ vượt bậc lò rèn |

**Đã thử rồi KHÔNG giữ:** tăng kinh nghiệm huấn luyện 15 → 25/35 (đường tiến trình chỉ nhanh hơn một chút, nằm trong nhiễu mô phỏng); bổng lộc đồng xu 22 (tiến trình không nhanh hơn rõ so với 16).

## 4. Kết quả sau điều chỉnh (60 ngày, trung vị trên 20 seed)

| Phong cách | Quân sống | Chết | Nhiệm vụ nhận/xong/hỏng | Hài lòng | Đồng xu cuối |
|---|---|---|---|---|---|
| 04 Ưu tiên xây dựng | 8 (trước: 2) | 4 (trước: 12) | 13/9/3 | 96 | 775 |
| 06 Thu thập/khám phá | 7 (trước: 3) | 7 (trước: 17) | 12/9/3 | 94 | 1231 |
| 07 Phát triển cân bằng | 8 (trước: 3) | 3 (trước: 6) | 14/12/2 | 95 | 99 |
| 09 Mất 70% quân ở ngày 12 | 6 (trước: 3) | 8 | 11/10/2 | 90 | 98 |
| 11 Tinh nhuệ | 8 (trước: 3) | 3 | 13/11/2 | 94 | 47 |

Chi tiết thu/chi theo tài nguyên, chi phí duy trì, nhiệm vụ từng mẫu, phục hồi và nguồn tử trận nằm trong `econ_summary.md`.

## 5. Kiểm tra farm / exploit
- **Thu thập rồi bán ở thành phố (policy 12)**: ~+17 đồng xu/ngày (≈ bằng bổng lộc), tốn toàn bộ thời gian, 0 tử trận, không tiến triển nhiệm vụ. Phong cách cân bằng kiếm ~49 đồng xu/ngày gồm nhiệm vụ. **Không vượt trội** → không điều chỉnh.
- **Arbitrage**: giá thu mua = 40% giá gốc, giá bán ra ≥ 100% giá gốc ở mọi người bán: mua rồi bán lại luôn lỗ (test kiểm tra mọi mặt hàng).
- Các hoạt động một lần (nhiệm vụ, trại, tàn tích) không farm được.

## 6. Vấn đề còn tồn tại
| Vấn đề | Mức | Ghi chú |
|---|---|---|
| Tiến trình giữa/cuối game vẫn chậm: trong 150 ngày, policy tối ưu chỉ đủ sức hạ Hang ổ kẻ cướp ở ngày ~100 và Lính đánh thuê ở ngày ~125 (1–7/20); **Pháo đài (nhiệm vụ cuối) không bao giờ** trong 150 ngày | **Cao** | Nút thắt là sức mạnh (bậc 3 đồ + cấp) so với thu nhập hữu hạn. Cần quyết định chiều dài chiến dịch mục tiêu và dữ liệu người chơi thật; gợi ý: thêm nguồn đồng xu lặp lại có rủi ro, hoặc giảm độ khó trại bậc 2–3 |
| Ngày "không tiến triển" cao ở policy thụ động | Thông tin | Phản ánh policy không có việc cần làm, không phải softlock |
| Thức ăn vẫn dư ở quân nhỏ | Thấp | Bán được ở thành phố |
| Người chơi tự động là heuristic, không đại diện người thật | Thông tin | 11 policy khác nhau, nhưng chưa có dữ liệu người chơi thật |
| Tiêu chuẩn "tử trận ~80% số gục" và chi phí thay thế ~85 đồng xu/người | Thiết kế | Giữ (permadeath là thiết kế của game gốc); trợ cấp khẩn chỉ giúp dựng lại |
