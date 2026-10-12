# Dữ liệu mô phỏng kinh tế nhiều ngày (sinh tự động)

Chạy lại: `dart run tool/economy_sim.dart`. 12 phong cách x 20 seed (1..20) x tối đa 60 ngày, dùng đúng `GameRules`. Dữ liệu thô từng ngày: `econ_raw.csv`. Giá trị là trung vị trên các seed. "Game over" = hài lòng của nhà vua về 0.

## Tổng quan

| Phong cách | Game over | Sống sót đến ngày | Quân sống | Sẵn sàng | Thức ăn | Đồng xu | Gỗ | Sắt | NV nhận/xong/hỏng | Hài lòng | Chết | Tuyển | Tập | Đồ trong kho / đang dùng (giá trị) | Ngày bế tắc |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 01 Ưu tiên tuyển mộ | 0% | 61 | 10 | 10 | 197 | 1145 | 50 | 40 | 12/8/3 | 89 | 0 | 4 | 0 | 170 / 215 | 49 |
| 02 Ưu tiên huấn luyện | 0% | 61 | 8 | 6 | 349 | 1050 | 0 | 30 | 13/10/3 | 95 | 0 | 2 | 78 | 260 / 215 | 29 |
| 03 Ưu tiên trang bị | 0% | 61 | 7 | 7 | 436 | 1503 | 50 | 30 | 12/10/2 | 94 | 0 | 1 | 0 | 165 / 650 | 50 |
| 04 Ưu tiên xây dựng | 0% | 62 | 8 | 8 | 332 | 775 | 50 | 80 | 13/9/3 | 96 | 4 | 6 | 0 | 260 / 140 | 27 |
| 05 Ưu tiên nhiệm vụ | 0% | 61 | 8 | 8 | 216 | 1238 | 50 | 40 | 23/12/9 | 13 | 0 | 2 | 0 | 205 / 740 | 47 |
| 06 Ưu tiên khám phá/thu thập | 0% | 61 | 7 | 7 | 492 | 1231 | 450 | 445 | 12/9/3 | 94 | 7 | 8 | 0 | 250 / 35 | 27 |
| 07 Phát triển cân bằng | 0% | 61 | 8 | 7 | 290 | 99 | 140 | 92 | 14/12/2 | 95 | 3 | 4 | 33 | 55 / 1085 | 18 |
| 08 Liên tục thất bại | 0% | 61 | 10 | 10 | 230 | 205 | 20 | 30 | 20/5/13 | 24 | 22 | 20 | 0 | 260 / 105 | 54 |
| 09 Mất 70% quân (permadeath) | 0% | 61 | 6 | 5 | 528 | 98 | 105 | 60 | 11/10/2 | 90 | 8 | 8 | 31 | 150 / 595 | 23 |
| 11 Tinh nhuệ (tối ưu sức mạnh) | 0% | 61 | 8 | 6 | 380 | 47 | 140 | 100 | 13/11/2 | 94 | 3 | 5 | 35 | 215 / 1000 | 22 |
| 12 Thu thập rồi bán (kiểm tra farm) | 0% | 61 | 6 | 6 | 120 | 1770 | 735 | 0 | 0/0/0 | 50 | 0 | 0 | 0 | 0 / 275 | 1 |
| 10 Áp lực hạn nhiệm vụ + duy trì | 0% | 61 | 10 | 10 | 119 | 1428 | 50 | 20 | 23/11/9 | 57 | 0 | 4 | 0 | 170 / 215 | 47 |

## Tổng thu / tổng chi theo tài nguyên (trung vị, đến cuối mô phỏng)

| Phong cách | Thức ăn thu/chi | Đồng xu thu/chi | Gỗ thu/chi | Sắt thu/chi |
|---|---|---|---|---|
| 01 Ưu tiên tuyển mộ | 816/655 | 1910/895 | 50/40 | 40/60 |
| 02 Ưu tiên huấn luyện | 918/656 | 2273/1513 | 120/160 | 80/90 |
| 03 Ưu tiên trang bị | 914/595 | 2292/901 | 50/40 | 50/60 |
| 04 Ưu tiên xây dựng | 898/661 | 2226/1587 | 775/800 | 395/350 |
| 05 Ưu tiên nhiệm vụ | 822/679 | 2276/1140 | 50/40 | 80/60 |
| 06 Ưu tiên khám phá/thu thập | 995/606 | 2189/1090 | 450/40 | 485/60 |
| 07 Phát triển cân bằng | 933/725 | 2956/2765 | 330/210 | 190/120 |
| 08 Liên tục thất bại | 683/609 | 2125/2152 | 20/40 | 40/60 |
| 09 Mất 70% quân (permadeath) | 912/493 | 2394/2439 | 185/120 | 90/60 |
| 11 Tinh nhuệ (tối ưu sức mạnh) | 916/634 | 2686/2780 | 250/120 | 190/90 |
| 12 Thu thập rồi bán (kiểm tra farm) | 1480/1440 | 2010/360 | 805/110 | 0/20 |
| 10 Áp lực hạn nhiệm vụ + duy trì | 840/793 | 2263/919 | 50/40 | 120/120 |

## Ngày đầu tiên đội mạnh nhất đủ sức hạ trại địch (nguy hiểm ≤ 0.8, tối thiểu 5 quân sẵn sàng)

| Phong cách | Tiền đồn cướp (a_outpost) | Hang ổ kẻ cướp (a_raiders) | Lính đánh thuê (m_camp) | Pháo đài (m_fort) |
|---|---|---|---|---|
| 01 Ưu tiên tuyển mộ | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) |
| 02 Ưu tiên huấn luyện | 56 (8/20) | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) |
| 03 Ưu tiên trang bị | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) |
| 04 Ưu tiên xây dựng | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) |
| 05 Ưu tiên nhiệm vụ | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) |
| 06 Ưu tiên khám phá/thu thập | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) |
| 07 Phát triển cân bằng | 38 (17/20) | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) |
| 08 Liên tục thất bại | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) |
| 09 Mất 70% quân (permadeath) | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) |
| 11 Tinh nhuệ (tối ưu sức mạnh) | 36 (17/20) | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) |
| 12 Thu thập rồi bán (kiểm tra farm) | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) |
| 10 Áp lực hạn nhiệm vụ + duy trì | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) |

## Nguồn tử trận và hiệu quả thu thập (trung vị)

| Phong cách | Chuyến thu thập | Bị phục kích | Thua phục kích | Chết do phục kích | Chết do đánh trại | Tổng chết |
|---|---|---|---|---|---|---|
| 01 Ưu tiên tuyển mộ | 0 | 0 | 0 | 0 | 0 | 0 |
| 02 Ưu tiên huấn luyện | 3 | 0 | 0 | 0 | 0 | 0 |
| 03 Ưu tiên trang bị | 1 | 0 | 0 | 0 | 0 | 0 |
| 04 Ưu tiên xây dựng | 27 | 5 | 1 | 4 | 0 | 4 |
| 05 Ưu tiên nhiệm vụ | 1 | 0 | 0 | 0 | 0 | 0 |
| 06 Ưu tiên khám phá/thu thập | 25 | 5 | 2 | 8 | 0 | 7 |
| 07 Phát triển cân bằng | 9 | 2 | 0 | 0 | 2 | 3 |
| 08 Liên tục thất bại | 0 | 0 | 0 | 0 | 23 | 22 |
| 09 Mất 70% quân (permadeath) | 5 | 1 | 0 | 0 | 0 | 8 |
| 11 Tinh nhuệ (tối ưu sức mạnh) | 7 | 1 | 0 | 1 | 2 | 3 |
| 12 Thu thập rồi bán (kiểm tra farm) | 46 | 10 | 0 | 0 | 0 | 0 |
| 10 Áp lực hạn nhiệm vụ + duy trì | 2 | 0 | 0 | 0 | 0 | 0 |

## Chi phí duy trì và áp lực đồng xu (trung vị)

| Phong cách | Quân đỉnh | Duy trì đỉnh/ngày (thức ăn+xu) | Ngày đồng xu < 10 | Ngày thức ăn < 10 | Ngày không thể tiến triển |
|---|---|---|---|---|---|
| 01 Ưu tiên tuyển mộ | 10 | 20 | 0 | 0 | 49 |
| 02 Ưu tiên huấn luyện | 8 | 16 | 0 | 0 | 29 |
| 03 Ưu tiên trang bị | 7 | 14 | 0 | 0 | 50 |
| 04 Ưu tiên xây dựng | 8 | 16 | 0 | 0 | 27 |
| 05 Ưu tiên nhiệm vụ | 8 | 16 | 0 | 0 | 47 |
| 06 Ưu tiên khám phá/thu thập | 7 | 14 | 0 | 0 | 27 |
| 07 Phát triển cân bằng | 8 | 16 | 0 | 0 | 18 |
| 08 Liên tục thất bại | 10 | 20 | 0 | 0 | 54 |
| 09 Mất 70% quân (permadeath) | 8 | 16 | 0 | 0 | 23 |
| 11 Tinh nhuệ (tối ưu sức mạnh) | 8 | 16 | 0 | 0 | 22 |
| 12 Thu thập rồi bán (kiểm tra farm) | 6 | 12 | 0 | 0 | 1 |
| 10 Áp lực hạn nhiệm vụ + duy trì | 10 | 20 | 0 | 0 | 47 |

## Hiệu quả từng mẫu nhiệm vụ

"Cân bằng" = phong cách 07 (người chơi hợp lý); "Nhiệm vụ" = phong cách 05; "Tất cả" = cộng gộp mọi phong cách.

| Mẫu | Hạn (ngày) | Cân bằng: nhận → xong | Nhiệm vụ: nhận → xong | Tất cả: nhận → xong |
|---|---|---|---|---|
| clear_bandits | 8 | 17 → 17 (100%) | 18 → 18 (100%) | 197 → 197 (100%) |
| deliver_food_a | 6 | 20 → 20 (100%) | 20 → 20 (100%) | 218 → 218 (100%) |
| deliver_wood_a | 7 | 20 → 20 (100%) | 20 → 20 (100%) | 220 → 220 (100%) |
| level_a | 10 | 20 → 20 (100%) | 20 → 20 (100%) | 232 → 213 (92%) |
| explore_green | 9 | 20 → 20 (100%) | 20 → 20 (100%) | 239 → 193 (81%) |
| clear_outpost | 10 | 14 → 7 (50%) | 24 → 1 (4%) | 94 → 21 (22%) |
| clear_raiders | 12 | - | 24 → 0 (0%) | 91 → 0 (0%) |
| deliver_iron_b | 9 | 22 → 22 (100%) | 21 → 21 (100%) | 217 → 201 (93%) |
| level_b | 14 | 21 → 12 (57%) | 53 → 0 (0%) | 264 → 47 (18%) |
| explore_ashen | 12 | 13 → 13 (100%) | 20 → 20 (100%) | 180 → 143 (79%) |
| clear_merc | 14 | - | 45 → 0 (0%) | 87 → 0 (0%) |
| deliver_food_c | 10 | 18 → 16 (89%) | 21 → 20 (95%) | 151 → 139 (92%) |
| final_fort | 20 | - | 31 → 0 (0%) | 47 → 0 (0%) |
| visit_town | 8 | 20 → 20 (100%) | 19 → 19 (100%) | 238 → 195 (82%) |
| gear_a | 12 | 20 → 20 (100%) | 33 → 33 (100%) | 324 → 120 (37%) |
| visit_city | 12 | 19 → 19 (100%) | 18 → 18 (100%) | 208 → 173 (83%) |
| gear_b | 16 | 25 → 3 (12%) | 53 → 0 (0%) | 287 → 5 (2%) |

## Kịch bản softlock có chủ đích (không nhận nhiệm vụ, chỉ cố tuyển lại; 40 ngày)

| Kịch bản | Ngày có ≥3 binh sĩ sẵn sàng | Ngày có ≥6 | Quân cuối | Đồng xu cuối | Hài lòng cuối |
|---|---|---|---|---|---|
| Mất toàn bộ quân, hết tài nguyên | 8 (20/20) | 20 (20/20) | 8 | 39 | 50 |
| Mất toàn bộ quân, còn 60 đồng xu | 7 (20/20) | 19 (20/20) | 8 | 53 | 50 |
| Còn 2 binh sĩ, hết đồng xu | 4 (20/20) | 16 (20/20) | 8 | 72 | 50 |
| Còn 1 binh sĩ, hết sạch | 6 (20/20) | 18 (20/20) | 8 | 55 | 50 |

## Phục hồi sau mất 70% quân (kịch bản 09)

- Số ván hồi phục được tới ≥6 binh sĩ sẵn sàng: 19/20; trung vị số ngày hồi phục: 9.
- Ván không hồi phục: 1 (game over: 0).

## Tổng số ván mô phỏng: 320

