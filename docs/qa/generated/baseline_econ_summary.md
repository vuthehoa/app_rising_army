# Dữ liệu mô phỏng kinh tế nhiều ngày (sinh tự động)

Chạy lại: `dart run tool/economy_sim.dart`. 11 phong cách x 20 seed (1..20) x tối đa 60 ngày, dùng đúng `GameRules`. Dữ liệu thô từng ngày: `baseline_econ_raw.csv`. Giá trị là trung vị trên các seed. "Game over" = hài lòng của nhà vua về 0.

## Tổng quan

| Phong cách | Game over | Sống sót đến ngày | Quân sống | Sẵn sàng | Thức ăn | Đồng xu | Gỗ | Sắt | NV nhận/xong/hỏng | Hài lòng | Chết | Tuyển | Tập | Đồ trong kho / đang dùng (giá trị) | Ngày bế tắc |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 01 Ưu tiên tuyển mộ | 0% | 61 | 10 | 10 | 402 | 658 | 50 | 10 | 9/7/2 | 88 | 0 | 4 | 0 | 170 / 215 | 50 |
| 02 Ưu tiên huấn luyện | 0% | 61 | 8 | 6 | 573 | 568 | 70 | 10 | 8/8/1 | 94 | 1 | 3 | 40 | 200 / 215 | 35 |
| 03 Ưu tiên trang bị | 0% | 61 | 7 | 7 | 638 | 750 | 50 | 10 | 9/8/1 | 94 | 0 | 1 | 0 | 165 / 655 | 51 |
| 04 Ưu tiên xây dựng | 0% | 61 | 2 | 2 | 626 | 98 | 70 | 89 | 9/7/2 | 93 | 12 | 10 | 0 | 205 / 35 | 29 |
| 05 Ưu tiên nhiệm vụ | 0% | 61 | 8 | 8 | 300 | 489 | 50 | 10 | 22/8/11 | 18 | 0 | 2 | 0 | 165 / 740 | 51 |
| 06 Ưu tiên khám phá/thu thập | 0% | 61 | 3 | 3 | 700 | 92 | 320 | 299 | 8/7/1 | 93 | 17 | 14 | 0 | 170 / 35 | 31 |
| 07 Phát triển cân bằng | 0% | 61 | 3 | 3 | 668 | 80 | 100 | 50 | 8/7/1 | 93 | 6 | 4 | 30 | 150 / 300 | 29 |
| 08 Liên tục thất bại | 25% | 61 | 1 | 1 | 640 | 60 | 20 | 40 | 20/7/11 | 27 | 22 | 17 | 0 | 260 / 0 | 46 |
| 09 Mất 70% quân (permadeath) | 0% | 61 | 3 | 2 | 820 | 84 | 10 | 42 | 8/7/1 | 93 | 7 | 5 | 30 | 130 / 260 | 22 |
| 11 Tinh nhuệ (tối ưu sức mạnh) | 0% | 61 | 3 | 3 | 656 | 31 | 90 | 50 | 9/8/1 | 94 | 6 | 4 | 32 | 165 / 420 | 29 |
| 10 Áp lực hạn nhiệm vụ + duy trì | 0% | 61 | 10 | 10 | 184 | 709 | 50 | 10 | 22/8/11 | 18 | 0 | 4 | 0 | 170 / 215 | 51 |

## Tổng thu / tổng chi theo tài nguyên (trung vị, đến cuối mô phỏng)

| Phong cách | Thức ăn thu/chi | Đồng xu thu/chi | Gỗ thu/chi | Sắt thu/chi |
|---|---|---|---|---|
| 01 Ưu tiên tuyển mộ | 993/661 | 1427/913 | 50/40 | 50/60 |
| 02 Ưu tiên huấn luyện | 1046/547 | 1647/1139 | 110/80 | 50/60 |
| 03 Ưu tiên trang bị | 1050/596 | 1575/935 | 50/40 | 50/60 |
| 04 Ưu tiên xây dựng | 1029/492 | 1516/1581 | 540/520 | 271/210 |
| 05 Ưu tiên nhiệm vụ | 889/669 | 1528/1165 | 50/40 | 50/60 |
| 06 Ưu tiên khám phá/thu thập | 1042/416 | 1544/1578 | 320/40 | 339/60 |
| 07 Phát triển cân bằng | 1052/471 | 1580/1630 | 150/120 | 90/60 |
| 08 Liên tục thất bại | 892/340 | 1553/1608 | 20/40 | 80/60 |
| 09 Mất 70% quân (permadeath) | 1050/312 | 1525/1567 | 90/80 | 82/60 |
| 11 Tinh nhuệ (tối ưu sức mạnh) | 1052/503 | 1571/1672 | 100/120 | 114/90 |
| 10 Áp lực hạn nhiệm vụ + duy trì | 888/785 | 1518/923 | 50/40 | 50/60 |

## Ngày đầu tiên đội mạnh nhất đủ sức hạ trại địch (nguy hiểm ≤ 0.8, tối thiểu 5 quân sẵn sàng)

| Phong cách | Tiền đồn cướp (a_outpost) | Hang ổ kẻ cướp (a_raiders) | Lính đánh thuê (m_camp) | Pháo đài (m_fort) |
|---|---|---|---|---|
| 01 Ưu tiên tuyển mộ | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) |
| 02 Ưu tiên huấn luyện | 57 (1/20) | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) |
| 03 Ưu tiên trang bị | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) |
| 04 Ưu tiên xây dựng | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) |
| 05 Ưu tiên nhiệm vụ | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) |
| 06 Ưu tiên khám phá/thu thập | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) |
| 07 Phát triển cân bằng | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) |
| 08 Liên tục thất bại | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) |
| 09 Mất 70% quân (permadeath) | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) |
| 11 Tinh nhuệ (tối ưu sức mạnh) | 59 (1/20) | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) |
| 10 Áp lực hạn nhiệm vụ + duy trì | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) |

## Nguồn tử trận và hiệu quả thu thập (trung vị)

| Phong cách | Chuyến thu thập | Bị phục kích | Thua phục kích | Chết do phục kích | Chết do đánh trại | Tổng chết |
|---|---|---|---|---|---|---|
| 01 Ưu tiên tuyển mộ | 1 | 0 | 0 | 0 | 0 | 0 |
| 02 Ưu tiên huấn luyện | 3 | 1 | 0 | 0 | 0 | 1 |
| 03 Ưu tiên trang bị | 1 | 0 | 0 | 0 | 0 | 0 |
| 04 Ưu tiên xây dựng | 25 | 7 | 6 | 13 | 0 | 12 |
| 05 Ưu tiên nhiệm vụ | 1 | 0 | 0 | 0 | 0 | 0 |
| 06 Ưu tiên khám phá/thu thập | 23 | 7 | 7 | 17 | 0 | 17 |
| 07 Phát triển cân bằng | 6 | 2 | 2 | 4 | 0 | 6 |
| 08 Liên tục thất bại | 0 | 0 | 0 | 0 | 22 | 22 |
| 09 Mất 70% quân (permadeath) | 4 | 1 | 1 | 1 | 0 | 7 |
| 11 Tinh nhuệ (tối ưu sức mạnh) | 6 | 2 | 2 | 6 | 0 | 6 |
| 10 Áp lực hạn nhiệm vụ + duy trì | 1 | 0 | 0 | 0 | 0 | 0 |

## Chi phí duy trì và áp lực đồng xu (trung vị)

| Phong cách | Quân đỉnh | Duy trì đỉnh/ngày (thức ăn+xu) | Ngày đồng xu < 10 | Ngày thức ăn < 10 | Ngày không thể tiến triển |
|---|---|---|---|---|---|
| 01 Ưu tiên tuyển mộ | 10 | 20 | 0 | 0 | 50 |
| 02 Ưu tiên huấn luyện | 8 | 16 | 0 | 0 | 35 |
| 03 Ưu tiên trang bị | 7 | 14 | 0 | 0 | 51 |
| 04 Ưu tiên xây dựng | 8 | 16 | 0 | 0 | 29 |
| 05 Ưu tiên nhiệm vụ | 8 | 16 | 0 | 0 | 51 |
| 06 Ưu tiên khám phá/thu thập | 7 | 14 | 0 | 0 | 31 |
| 07 Phát triển cân bằng | 8 | 16 | 0 | 0 | 29 |
| 08 Liên tục thất bại | 10 | 20 | 0 | 0 | 46 |
| 09 Mất 70% quân (permadeath) | 8 | 16 | 0 | 0 | 22 |
| 11 Tinh nhuệ (tối ưu sức mạnh) | 8 | 16 | 5 | 0 | 29 |
| 10 Áp lực hạn nhiệm vụ + duy trì | 10 | 20 | 0 | 0 | 51 |

## Hiệu quả từng mẫu nhiệm vụ

"Cân bằng" = phong cách 07 (người chơi hợp lý); "Nhiệm vụ" = phong cách 05; "Tất cả" = cộng gộp mọi phong cách.

| Mẫu | Hạn (ngày) | Cân bằng: nhận → xong | Nhiệm vụ: nhận → xong | Tất cả: nhận → xong |
|---|---|---|---|---|
| clear_bandits | 8 | 20 → 20 (100%) | 20 → 20 (100%) | 219 → 216 (99%) |
| deliver_food_a | 6 | 20 → 20 (100%) | 20 → 20 (100%) | 220 → 220 (100%) |
| deliver_wood_a | 7 | 20 → 20 (100%) | 20 → 20 (100%) | 227 → 219 (96%) |
| level_a | 10 | 20 → 20 (100%) | 20 → 20 (100%) | 230 → 218 (95%) |
| explore_green | 9 | 20 → 20 (100%) | 20 → 20 (100%) | 244 → 198 (81%) |
| clear_outpost | 10 | - | 72 → 1 (1%) | 177 → 15 (8%) |
| clear_raiders | 12 | - | 68 → 0 (0%) | 203 → 0 (0%) |
| deliver_iron_b | 9 | 20 → 19 (95%) | 21 → 21 (100%) | 230 → 206 (90%) |
| level_b | 14 | 20 → 3 (15%) | 64 → 1 (2%) | 337 → 22 (7%) |
| explore_ashen | 12 | 20 → 20 (100%) | 20 → 20 (100%) | 261 → 183 (70%) |
| clear_merc | 14 | - | 61 → 0 (0%) | 157 → 0 (0%) |
| deliver_food_c | 10 | 6 → 6 (100%) | 21 → 21 (100%) | 118 → 118 (100%) |
| final_fort | 20 | - | 2 → 0 (0%) | 2 → 0 (0%) |

## Kịch bản softlock có chủ đích (không nhận nhiệm vụ, chỉ cố tuyển lại; 40 ngày)

| Kịch bản | Ngày có ≥3 binh sĩ sẵn sàng | Ngày có ≥6 | Quân cuối | Đồng xu cuối | Hài lòng cuối |
|---|---|---|---|---|---|
| Mất toàn bộ quân, hết tài nguyên | 28 (20/20) | không bao giờ (0/20) | 4 | 17 | 50 |
| Mất toàn bộ quân, còn 60 đồng xu | 22 (20/20) | không bao giờ (0/20) | 4 | 53 | 50 |
| Còn 2 binh sĩ, hết đồng xu | 11 (20/20) | không bao giờ (0/20) | 5 | 32 | 50 |
| Còn 1 binh sĩ, hết sạch | 20 (20/20) | không bao giờ (0/20) | 4 | 63 | 50 |

## Phục hồi sau mất 70% quân (kịch bản 09)

- Số ván hồi phục được tới ≥6 binh sĩ sẵn sàng: 0/20; trung vị số ngày hồi phục: 0.
- Ván không hồi phục: 20 (game over: 0).

## Tổng số ván mô phỏng: 300

