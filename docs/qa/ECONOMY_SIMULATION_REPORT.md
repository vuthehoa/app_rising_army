# Báo cáo mô phỏng kinh tế nhiều ngày (Phase 2)

Dữ liệu thô: [generated/economy_data.md](generated/economy_data.md) (sau),
[generated/baseline_economy_data.md](generated/baseline_economy_data.md) (trước).

## Cách chạy lại

```
dart run tool/economy_sim.dart [đường_dẫn]
```
7 kịch bản x 20 seed x 60 ngày + 40 ván farm 30 ngày + 15.000 trận đo lợi nhuận đánh lại ải = **15.180 đơn vị
mô phỏng** mỗi lần chạy. Dùng đúng `GameRules`; đã chạy hai lần và so sánh, giống hệt. Người chơi tự động là
heuristic đơn giản (xem đầu file dữ liệu), nên kết quả so sánh phong cách chơi chỉ mang tính chỉ báo.

## Phát hiện

| # | Phát hiện | Bằng chứng | Mức | Xử lý |
|---|---|---|---|---|
| 1 | **Farm ải đã chiếm**: đánh lại nhận đủ thưởng, không giới hạn số trận/ngày | Ải 1 lãi ròng **+135/trận** (thưởng 180, mất ~45 giá trị quân) so với sản xuất 54/ngày. Farm 10 trận/ngày trong 30 ngày: **+45.720 tài nguyên so với +720** (gấp 63 lần) | Rất cao | **Đã sửa**: ải đã chiếm không đánh lại được. Sau sửa: 720 so với 720, 0 trận farm |
| 2 | Đầu tư công trình thắng áp đảo tuyển quân | Sau 60 ngày: sản xuất 12.070 (công trình) so với 3.240 (tuyển quân); ải 5 đạt 14/20 ván (ngày 48) so với 0/20; tuyển-quân-trước kẹt ở ~35 quân | Trung bình | Ghi nhận |
| 3 | Sắt dư thừa, vàng/gỗ thiếu | Cuối ngày 60 sắt tồn 610-1.080 ở mọi phong cách; vàng chỉ còn 25-37 ở "Công nghệ"/"Kết hợp"; gỗ còn 52-60 ở "Kết hợp"/"Quân đông" | Thấp-TB | Ghi nhận |
| 4 | Mỏ sắt và Chợ hoàn vốn rất chậm | Hoàn vốn cấp 5: Nông trại/Đốn gỗ 21,8 ngày; Mỏ 60,1; Chợ 72,1 (> 60 ngày mô phỏng) | Thấp-TB | Ghi nhận |
| 5 | Lương nuôi quân không bao giờ "cắn" khi chơi hợp lý | 0 ngày thiếu lương, 0 đào ngũ ở mọi phong cách (quân đỉnh 15-67, nông trại luôn đủ) | Thấp | Ghi nhận |
| 6 | Vỡ nợ lương tự cân bằng, không tạo vòng chết | 150 quân + 0 lương: co về 45 quân sau 11 ngày rồi ổn định, lương thực hồi dần | - | Hợp lý |
| 7 | Không có tài nguyên âm; hồi phục luôn khả thi | 0 trường hợp âm trong 140 ván và 200 ván fuzz x 120 hành động; sau khi hết quân và 0 tài nguyên vẫn tuyển lại được sau 3 ngày | - | Có test |
| 8 | Thất bại liên tiếp (đánh mù mỗi ngày) | 1 thắng/59 thua, quân đỉnh 15, nhưng không âm, không phá sản; vẫn tuyển lại mỗi ngày | - | Hợp lý |
| 9 | Phần thưởng nhiệm vụ không gây lạm phát | Tổng 730 tài nguyên, một lần (~13,5 ngày sản xuất khởi đầu); có test giới hạn | - | - |

## Đánh giá nâng cấp
Nông trại/Đốn gỗ đáng tiền sớm (hoàn vốn 5-9 ngày ở cấp 2-3). Nếu quy đổi sắt/vàng quý gấp ~2 lần lương/gỗ thì
Mỏ/Chợ cấp 5 hoàn vốn ~30-36 ngày, chấp nhận được nhưng không hấp dẫn khi sắt đang dư thừa (phát hiện 3).

## Nhịp độ chiến dịch
Với phong cách tốt nhất (công trình trước), ải 3 ở ngày 19 (20/20), ải 5 ở ngày 48 (14/20). Phong cách khác
chưa kịp ải 5 trong 60 ngày. Thưởng chiến dịch tổng 1.990, nhỏ so với sản xuất 3.240-12.070 nên tiến độ do
thời gian và đầu tư quyết định chứ không phải grind. Chưa điều chỉnh vì kết quả phụ thuộc chất lượng người
chơi tự động; cần dữ liệu người chơi thật.
