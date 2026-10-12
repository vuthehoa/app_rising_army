# Dữ liệu mô phỏng kinh tế nhiều ngày (sinh tự động)

Chạy lại: `dart run tool/economy_sim.dart`. 12 phong cách x 20 seed (1..20) x tối đa 150 ngày, dùng đúng `GameRules`. Dữ liệu thô từng ngày: `long150_raw.csv`. Giá trị là trung vị trên các seed. "Game over" = hài lòng của nhà vua về 0.

## Tổng quan

| Phong cách | Game over | Sống sót đến ngày | Quân sống | Sẵn sàng | Thức ăn | Đồng xu | Gỗ | Sắt | NV nhận/xong/hỏng | Hài lòng | Chết | Tuyển | Tập | Đồ trong kho / đang dùng (giá trị) | Ngày bế tắc |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 01 Ưu tiên tuyển mộ | 0% | 151 | 10 | 10 | 511 | 2373 | 50 | 40 | 14/10/5 | 87 | 0 | 4 | 0 | 170 / 215 | 137 |
| 02 Ưu tiên huấn luyện | 0% | 151 | 8 | 6 | 972 | 1171 | 0 | 50 | 13/10/3 | 95 | 4 | 6 | 211 | 290 / 105 | 76 |
| 03 Ưu tiên trang bị | 0% | 151 | 7 | 7 | 1133 | 2862 | 50 | 30 | 12/10/2 | 94 | 0 | 1 | 0 | 165 / 650 | 140 |
| 04 Ưu tiên xây dựng | 0% | 151 | 8 | 8 | 948 | 1398 | 15 | 15 | 13/9/3 | 95 | 10 | 12 | 0 | 260 / 40 | 100 |
| 05 Ưu tiên nhiệm vụ | 100% | 71 | 8 | 8 | 195 | 1238 | 50 | 40 | 24/12/11 | 0 | 0 | 2 | 0 | 205 / 740 | 57 |
| 06 Ưu tiên khám phá/thu thập | 0% | 151 | 5 | 5 | 1313 | 172 | 1190 | 1195 | 12/9/3 | 91 | 37 | 35 | 0 | 250 / 0 | 73 |
| 07 Phát triển cân bằng | 0% | 151 | 8 | 6 | 978 | 100 | 145 | 100 | 16/14/2 | 95 | 6 | 7 | 92 | 120 / 1385 | 54 |
| 08 Liên tục thất bại | 100% | 83 | 10 | 10 | 352 | 193 | 20 | 30 | 25/5/18 | 0 | 32 | 28 | 0 | 260 / 105 | 73 |
| 09 Mất 70% quân (permadeath) | 0% | 151 | 8 | 6 | 1194 | 97 | 160 | 100 | 15/13/2 | 99 | 12 | 13 | 82 | 295 / 1005 | 58 |
| 11 Tinh nhuệ (tối ưu sức mạnh) | 0% | 151 | 7 | 5 | 1053 | 41 | 140 | 110 | 16/13/2 | 95 | 7 | 8 | 136 | 260 / 1130 | 55 |
| 12 Thu thập rồi bán (kiểm tra farm) | 0% | 151 | 6 | 6 | 110 | 4054 | 1890 | 0 | 0/0/0 | 50 | 0 | 0 | 0 | 0 / 275 | 1 |
| 10 Áp lực hạn nhiệm vụ + duy trì | 100% | 78 | 10 | 10 | 84 | 1457 | 50 | 20 | 26/11/13 | 0 | 0 | 4 | 0 | 170 / 215 | 63 |

## Tổng thu / tổng chi theo tài nguyên (trung vị, đến cuối mô phỏng)

| Phong cách | Thức ăn thu/chi | Đồng xu thu/chi | Gỗ thu/chi | Sắt thu/chi |
|---|---|---|---|---|
| 01 Ưu tiên tuyển mộ | 2080/1662 | 4079/1801 | 50/40 | 80/60 |
| 02 Ưu tiên huấn luyện | 2268/1380 | 4463/3813 | 120/160 | 110/90 |
| 03 Ưu tiên trang bị | 2174/1225 | 4290/1531 | 50/40 | 50/60 |
| 04 Ưu tiên xây dựng | 2236/1374 | 4374/3251 | 1195/1220 | 625/610 |
| 05 Ưu tiên nhiệm vụ | 883/767 | 2344/1231 | 50/40 | 80/60 |
| 06 Ưu tiên khám phá/thu thập | 2363/1125 | 4375/4156 | 1190/40 | 1235/60 |
| 07 Phát triển cân bằng | 2295/1388 | 5716/5485 | 400/280 | 262/180 |
| 08 Liên tục thất bại | 808/747 | 2365/2398 | 20/40 | 40/60 |
| 09 Mất 70% quân (permadeath) | 2207/1178 | 5001/5035 | 410/280 | 260/180 |
| 11 Tinh nhuệ (tối ưu sức mạnh) | 2289/1324 | 5278/5374 | 300/200 | 230/120 |
| 12 Thu thập rồi bán (kiểm tra farm) | 3740/3710 | 4834/900 | 1960/110 | 0/20 |
| 10 Áp lực hạn nhiệm vụ + duy trì | 1001/958 | 2484/1105 | 50/40 | 120/120 |

## Ngày đầu tiên đội mạnh nhất đủ sức hạ trại địch (nguy hiểm ≤ 0.8, tối thiểu 5 quân sẵn sàng)

| Phong cách | Tiền đồn cướp (a_outpost) | Hang ổ kẻ cướp (a_raiders) | Lính đánh thuê (m_camp) | Pháo đài (m_fort) |
|---|---|---|---|---|
| 01 Ưu tiên tuyển mộ | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) |
| 02 Ưu tiên huấn luyện | 79 (20/20) | 140 (3/20) | không bao giờ (0/20) | không bao giờ (0/20) |
| 03 Ưu tiên trang bị | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) |
| 04 Ưu tiên xây dựng | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) |
| 05 Ưu tiên nhiệm vụ | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) |
| 06 Ưu tiên khám phá/thu thập | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) |
| 07 Phát triển cân bằng | 42 (20/20) | 113 (14/20) | 124 (1/20) | không bao giờ (0/20) |
| 08 Liên tục thất bại | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) |
| 09 Mất 70% quân (permadeath) | 98 (17/20) | 136 (6/20) | không bao giờ (0/20) | không bao giờ (0/20) |
| 11 Tinh nhuệ (tối ưu sức mạnh) | 38 (20/20) | 98 (17/20) | 131 (7/20) | không bao giờ (0/20) |
| 12 Thu thập rồi bán (kiểm tra farm) | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) |
| 10 Áp lực hạn nhiệm vụ + duy trì | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) | không bao giờ (0/20) |

## Nguồn tử trận và hiệu quả thu thập (trung vị)

| Phong cách | Chuyến thu thập | Bị phục kích | Thua phục kích | Chết do phục kích | Chết do đánh trại | Tổng chết |
|---|---|---|---|---|---|---|
| 01 Ưu tiên tuyển mộ | 1 | 0 | 0 | 0 | 0 | 0 |
| 02 Ưu tiên huấn luyện | 3 | 0 | 0 | 0 | 4 | 4 |
| 03 Ưu tiên trang bị | 1 | 0 | 0 | 0 | 0 | 0 |
| 04 Ưu tiên xây dựng | 42 | 9 | 3 | 10 | 0 | 10 |
| 05 Ưu tiên nhiệm vụ | 1 | 0 | 0 | 0 | 0 | 0 |
| 06 Ưu tiên khám phá/thu thập | 69 | 15 | 11 | 37 | 0 | 37 |
| 07 Phát triển cân bằng | 13 | 3 | 0 | 0 | 6 | 6 |
| 08 Liên tục thất bại | 0 | 0 | 0 | 0 | 32 | 32 |
| 09 Mất 70% quân (permadeath) | 12 | 2 | 0 | 1 | 5 | 12 |
| 11 Tinh nhuệ (tối ưu sức mạnh) | 9 | 1 | 0 | 1 | 6 | 7 |
| 12 Thu thập rồi bán (kiểm tra farm) | 113 | 23 | 0 | 0 | 0 | 0 |
| 10 Áp lực hạn nhiệm vụ + duy trì | 2 | 0 | 0 | 0 | 0 | 0 |

## Chi phí duy trì và áp lực đồng xu (trung vị)

| Phong cách | Quân đỉnh | Duy trì đỉnh/ngày (thức ăn+xu) | Ngày đồng xu < 10 | Ngày thức ăn < 10 | Ngày không thể tiến triển |
|---|---|---|---|---|---|
| 01 Ưu tiên tuyển mộ | 10 | 20 | 0 | 0 | 137 |
| 02 Ưu tiên huấn luyện | 8 | 16 | 0 | 0 | 76 |
| 03 Ưu tiên trang bị | 7 | 14 | 0 | 0 | 140 |
| 04 Ưu tiên xây dựng | 8 | 16 | 0 | 0 | 100 |
| 05 Ưu tiên nhiệm vụ | 8 | 16 | 0 | 0 | 57 |
| 06 Ưu tiên khám phá/thu thập | 7 | 14 | 0 | 0 | 73 |
| 07 Phát triển cân bằng | 8 | 16 | 0 | 0 | 54 |
| 08 Liên tục thất bại | 10 | 20 | 0 | 0 | 73 |
| 09 Mất 70% quân (permadeath) | 8 | 16 | 0 | 0 | 58 |
| 11 Tinh nhuệ (tối ưu sức mạnh) | 8 | 16 | 0 | 0 | 55 |
| 12 Thu thập rồi bán (kiểm tra farm) | 6 | 12 | 0 | 0 | 1 |
| 10 Áp lực hạn nhiệm vụ + duy trì | 10 | 20 | 0 | 0 | 63 |

## Hiệu quả từng mẫu nhiệm vụ

"Cân bằng" = phong cách 07 (người chơi hợp lý); "Nhiệm vụ" = phong cách 05; "Tất cả" = cộng gộp mọi phong cách.

| Mẫu | Hạn (ngày) | Cân bằng: nhận → xong | Nhiệm vụ: nhận → xong | Tất cả: nhận → xong |
|---|---|---|---|---|
| clear_bandits | 8 | 17 → 17 (100%) | 18 → 18 (100%) | 197 → 197 (100%) |
| deliver_food_a | 6 | 20 → 20 (100%) | 20 → 20 (100%) | 219 → 219 (100%) |
| deliver_wood_a | 7 | 20 → 20 (100%) | 20 → 20 (100%) | 220 → 220 (100%) |
| level_a | 10 | 20 → 20 (100%) | 20 → 20 (100%) | 233 → 214 (92%) |
| explore_green | 9 | 20 → 20 (100%) | 20 → 20 (100%) | 245 → 193 (79%) |
| clear_outpost | 10 | 18 → 11 (61%) | 24 → 1 (4%) | 124 → 45 (36%) |
| clear_raiders | 12 | 11 → 6 (55%) | 24 → 0 (0%) | 119 → 15 (13%) |
| deliver_iron_b | 9 | 29 → 29 (100%) | 21 → 21 (100%) | 254 → 234 (92%) |
| level_b | 14 | 27 → 19 (70%) | 58 → 0 (0%) | 336 → 73 (22%) |
| explore_ashen | 12 | 17 → 17 (100%) | 20 → 20 (100%) | 210 → 165 (79%) |
| clear_merc | 14 | 1 → 1 (100%) | 49 → 0 (0%) | 112 → 2 (2%) |
| deliver_food_c | 10 | 22 → 20 (91%) | 21 → 20 (95%) | 180 → 169 (94%) |
| final_fort | 20 | - | 38 → 0 (0%) | 65 → 0 (0%) |
| visit_town | 8 | 20 → 20 (100%) | 19 → 19 (100%) | 242 → 195 (81%) |
| gear_a | 12 | 20 → 20 (100%) | 33 → 33 (100%) | 344 → 122 (35%) |
| visit_city | 12 | 21 → 21 (100%) | 18 → 18 (100%) | 236 → 188 (80%) |
| gear_b | 16 | 37 → 11 (30%) | 57 → 0 (0%) | 372 → 20 (5%) |

## Kịch bản softlock có chủ đích (không nhận nhiệm vụ, chỉ cố tuyển lại; 40 ngày)

| Kịch bản | Ngày có ≥3 binh sĩ sẵn sàng | Ngày có ≥6 | Quân cuối | Đồng xu cuối | Hài lòng cuối |
|---|---|---|---|---|---|
| Mất toàn bộ quân, hết tài nguyên | 8 (20/20) | 20 (20/20) | 8 | 39 | 50 |
| Mất toàn bộ quân, còn 60 đồng xu | 7 (20/20) | 19 (20/20) | 8 | 53 | 50 |
| Còn 2 binh sĩ, hết đồng xu | 4 (20/20) | 16 (20/20) | 8 | 72 | 50 |
| Còn 1 binh sĩ, hết sạch | 6 (20/20) | 18 (20/20) | 8 | 55 | 50 |

## Phục hồi sau mất 70% quân (kịch bản 09)

- Số ván hồi phục được tới ≥6 binh sĩ sẵn sàng: 20/20; trung vị số ngày hồi phục: 14.
- Ván không hồi phục: 0 (game over: 0).

## Tổng số ván mô phỏng: 320

