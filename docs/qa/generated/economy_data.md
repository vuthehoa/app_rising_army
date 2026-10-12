# Dữ liệu mô phỏng kinh tế (sinh tự động)

Chạy lại: `dart run tool/economy_sim.dart`. Mỗi phong cách = 20 ván (seed 1..20) x 60 ngày, dùng đúng `GameRules`. Người chơi tự động đánh ải kế tiếp khi trinh sát (seed khác) dự đoán thắng, toàn bộ quân, chiến thuật Cân bằng; nhận thưởng nhiệm vụ ngay khi đủ điều kiện.

## Tổng quan sau 60 ngày (trung vị trên 20 seed)

| Phong cách | Ải 1 (ngày) | Ải 3 | Ải 5 | Quân đỉnh | Ngày thiếu lương | Đào ngũ | Trận thắng/thua | Quân mất | Tổng sản xuất | Thưởng chiến | Thưởng NV | Âm? |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Ưu tiên tuyển quân | 1 (20/20) | 46 (13/20) | không đạt | 35 | 0 | 0 | 3/0 | 52 | 3240 | 690 | 490 | không |
| Ưu tiên công trình | 1 (20/20) | 19 (20/20) | 48 (14/20) | 67 | 0 | 0 | 5/1 | 135 | 12070 | 1990 | 650 | không |
| Ưu tiên công nghệ | 1 (20/20) | 28 (15/20) | không đạt | 35 | 0 | 0 | 3/1 | 51 | 3432 | 690 | 730 | không |
| Kết hợp | 1 (20/20) | 20 (20/20) | 56 (1/20) | 53 | 0 | 0 | 4/1 | 104 | 5751 | 1090 | 650 | không |
| Quân đông, lương cao | 1 (20/20) | 28 (15/20) | không đạt | 32 | 0 | 0 | 3/1 | 59 | 3240 | 690 | 490 | không |
| Thất bại liên tiếp (đánh mù mỗi ngày) | 1 (20/20) | không đạt | không đạt | 15 | 0 | 0 | 1/59 | 95 | 3240 | 180 | 190 | không |
| Farm ải 1 (10 trận/ngày, Phòng thủ) | 1 (20/20) | không đạt | không đạt | 42 | 0 | 0 | 1/0 | 5 | 3240 | 180 | 190 | không |

## Tài nguyên cuối ngày 60 (trung vị trên 20 seed)

| Phong cách | Lương thực | Gỗ | Sắt | Vàng |
|---|---|---|---|---|
| Ưu tiên tuyển quân | 20 | 770 | 1080 | 540 |
| Ưu tiên công trình | 81 | 172 | 1025 | 546 |
| Ưu tiên công nghệ | 26 | 380 | 610 | 25 |
| Kết hợp | 53 | 60 | 796 | 37 |
| Quân đông, lương cao | 19 | 52 | 1032 | 385 |
| Thất bại liên tiếp (đánh mù mỗi ngày) | 29 | 430 | 800 | 230 |
| Farm ải 1 (10 trận/ngày, Phòng thủ) | 16 | 920 | 800 | 230 |

## Phần thưởng một lần

- Tổng thưởng 5 nhiệm vụ: 730 tài nguyên (một lần). Sản xuất khởi đầu: 54/ngày.
- Thưởng từng ải: 180, 210, 300, 400, 900 tài nguyên mỗi lần thắng.

## Hoàn vốn nâng cấp công trình sản xuất

| Công trình | Nâng lên cấp | Chi phí (tổng) | Sản lượng thêm/ngày | Ngày hoàn vốn |
|---|---|---|---|---|
| Nông trại | 2 | 128 | 24 | 5.3 |
| Nông trại | 3 | 205 | 24 | 8.5 |
| Nông trại | 4 | 328 | 24 | 13.7 |
| Nông trại | 5 | 524 | 24 | 21.8 |
| Trại đốn gỗ | 2 | 96 | 18 | 5.3 |
| Trại đốn gỗ | 3 | 153 | 18 | 8.5 |
| Trại đốn gỗ | 4 | 246 | 18 | 13.7 |
| Trại đốn gỗ | 5 | 393 | 18 | 21.8 |
| Mỏ sắt | 2 | 176 | 12 | 14.7 |
| Mỏ sắt | 3 | 281 | 12 | 23.4 |
| Mỏ sắt | 4 | 451 | 12 | 37.6 |
| Mỏ sắt | 5 | 721 | 12 | 60.1 |
| Chợ | 2 | 176 | 10 | 17.6 |
| Chợ | 3 | 281 | 10 | 28.1 |
| Chợ | 4 | 451 | 10 | 45.1 |
| Chợ | 5 | 721 | 10 | 72.1 |

## Lương nuôi quân so với sản lượng lương thực (cấp nông trại 1..5, không Canh nông)

| Quân | Lương/ngày | Sản lượng nông trại cấp 1 | cấp 3 | cấp 5 |
|---|---|---|---|---|
| 10 | 5 | 24 | 72 | 120 |
| 30 | 15 | 24 | 72 | 120 |
| 60 | 30 | 24 | 72 | 120 |
| 100 | 50 | 24 | 72 | 120 |
| 150 | 75 | 24 | 72 | 120 |

## Lợi nhuận GIẢ ĐỊNH mỗi trận nếu cho đánh lại ải (1000 trận/ô, quân khắc chế địch; từ phase 2 luật game đã chặn đánh lại)

Giá trị = tổng tài nguyên. Lãi ròng = thưởng x tỷ lệ thắng - giá trị quân chết.

| Ải | Thưởng | Quân (khắc chế) | Thắng | Quân chết TB | Giá trị quân chết | Lãi ròng/trận | Sản xuất 1 ngày (khởi đầu) |
|---|---|---|---|---|---|---|---|
| 1 | 180 | 30 | 100.0% | 1.0 | 45 | 135 | 54 |
| 1 | 180 | 60 | 100.0% | 1.0 | 45 | 135 | 54 |
| 1 | 180 | 100 | 100.0% | 1.0 | 45 | 135 | 54 |
| 2 | 210 | 30 | 100.0% | 3.2 | 172 | 38 | 54 |
| 2 | 210 | 60 | 100.0% | 3.0 | 165 | 45 | 54 |
| 2 | 210 | 100 | 100.0% | 3.0 | 165 | 45 | 54 |
| 3 | 300 | 30 | 100.0% | 15.0 | 797 | -497 | 54 |
| 3 | 300 | 60 | 100.0% | 8.3 | 451 | -151 | 54 |
| 3 | 300 | 100 | 100.0% | 7.4 | 406 | -106 | 54 |
| 4 | 400 | 30 | 0.0% | 31.0 | 1605 | -1605 | 54 |
| 4 | 400 | 60 | 100.0% | 19.0 | 986 | -586 | 54 |
| 4 | 400 | 100 | 100.0% | 13.3 | 693 | -293 | 54 |
| 5 | 900 | 30 | 0.0% | 30.0 | 1530 | -1530 | 54 |
| 5 | 900 | 60 | 32.7% | 56.9 | 2946 | -2652 | 54 |
| 5 | 900 | 100 | 100.0% | 30.4 | 1566 | -666 | 54 |

## Farm ải 1 có tuyển bù (quân khởi đầu 60 giáo binh, 30 ngày, trung vị 20 seed)

- Trung vị thay đổi tổng tài nguyên sau 30 ngày: có farm 720, không farm 720.
- Số trận farm trung vị: 0.

## Thử vỡ nợ lương (150 quân, nông trại cấp 1, hết lương thực dự trữ)

| Ngày | Quân còn | Lương thực | Đào ngũ trong ngày |
|---|---|---|---|
| 1 | 135 | 0 | 15 |
| 2 | 121 | 0 | 14 |
| 3 | 108 | 0 | 13 |
| 4 | 97 | 0 | 11 |
| 5 | 87 | 0 | 10 |
| 6 | 78 | 0 | 9 |
| 7 | 70 | 0 | 8 |
| 8 | 63 | 0 | 7 |
| 9 | 56 | 0 | 7 |
| 10 | 50 | 0 | 6 |
| 11 | 45 | 0 | 5 |
| 12 | 45 | 1 | 0 |
| 13 | 45 | 2 | 0 |
| 14 | 45 | 3 | 0 |

Tổng số ván/trận mô phỏng: 15180 (mỗi ván 60 ngày).
