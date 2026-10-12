# Báo cáo mô phỏng cân bằng chiến đấu (Phase 2)

Dữ liệu thô: [generated/balance_data.md](generated/balance_data.md) (sau sửa),
[generated/baseline_balance_data.md](generated/baseline_balance_data.md) (trước sửa).

## Cách chạy lại

```
dart run tool/balance_sim.dart                 # ghi docs/qa/generated/balance_data.md
dart run tool/balance_sim.dart <đường_dẫn>     # ghi nơi khác
```

Không cần Flutter UI (domain thuần Dart). Mỗi ô bảng = 1.000 trận, seed 0..999; cùng seed => cùng kết quả
(đã chạy hai lần và so sánh, giống hệt). Một lần chạy = **298.000 trận**. Test tái lập nằm ở
`test/balance_regression_test.dart`.

## Luồng dữ liệu

```
Người chơi (widget) -> GameController (application) -> GameRules / simulateBattle (domain)
        ^                      |                              |
        +---- notifyListeners -+--> SaveRepository.save() <---+ (GameState -> JSON + checksum + backup)
```
Widget không chạm GameState; công thức chiến đấu chỉ nằm trong `battle_engine.dart`; số liệu ở `game_data.dart`.

## Công thức đang dùng (đã đọc từ source)

Mỗi hiệp, hai bên gây sát thương đồng thời dựa trên quân số đầu hiệp:
`sát thương = Σ(số quân x công x hệ số khắc chế theo tỷ lệ thành phần địch) x hệ số công x nhiễu(0.9-1.1) x hệ số nhận của đối phương`.
Sát thương chia cho các loại quân của đối phương theo tỷ lệ máu. Tối đa 6 hiệp. Địch không có hệ số phụ.

## Kiểm định hệ số khắc chế (2.0x / 0.5x)

Xác minh bằng test (`Hệ số khắc chế`): đúng chiều (giáo>kỵ>cung>giáo), hiệp 1 trận 1v1 nằm trong
[công x hệ số x 0.9, công x hệ số x 1.1]; thành phần địch hỗn hợp được lấy trung bình theo tỷ lệ (không nhân
chồng); hệ số chiến thuật/nâng cấp chỉ nhân một lần. **Không phát hiện lỗi về chiều hay nhân chồng.**

## Phát hiện

| # | Phát hiện | Bằng chứng | Mức | Xử lý |
|---|---|---|---|---|
| 1 | Hai bên cùng bị xóa sổ trong một hiệp vẫn tính là người chơi thắng (kèm thưởng, mở ải) | Đội hình gương cung thủ 10v10: thắng 60,1% -> **36,8%** sau sửa; gương 30v30: 50,1% -> 46,2%; gương ải 2-3 chiến thuật Tấn công: 83,8%/80,9% -> 66,0%/66,8%. Test biên "2 bên 0 quân" fail trước khi sửa | Cao (sai điều kiện thắng) | **Đã sửa** |
| 2 | Khắc chế gần như tuyệt đối: cùng quân số, bên khắc chế thắng 100%, bên bị khắc chế 0% (mất 49% quân ở giáo>kỵ) | Bảng 1, 2 | Trung bình | Ghi nhận, không đổi (xem dưới) |
| 3 | Kết quả rất "sắc": 20 giáo vs 20 giáo thắng 46,7%, **22 giáo thắng 100%**; 18 giáo thắng 0% | Bảng 3 | Thấp-TB | Ghi nhận |
| 4 | Chiến thuật Phòng thủ thắng nhiều hơn VÀ mất ít quân hơn Tấn công ở cả 5 ải | Bảng 4: thắng 87,5-94,9% so với 66-85%; tổn thất 62-81% so với 75-90% | Trung bình | Ghi nhận, cần quyết định thiết kế |
| 5 | Không có trận kéo dài bất thường, không có hòa, không có vi phạm bảo toàn quân | 30.000 trận kiểm tra: 0 vi phạm, 0 trận hết 6 hiệp mà chưa phân thắng | - | - |

### Vì sao không chỉnh 2.0x/0.5x
Dưới ngân sách tài nguyên bằng nhau (bảng 2) vòng giáo>kỵ>cung>giáo vẫn khép kín, và so sánh chi phí cho thấy
có đánh đổi thật: ải 5 cần ~50 kỵ (3.750 tài nguyên, nuôi 25 lương/ngày) hoặc ~100 giáo (3.000 tài nguyên, nuôi 50
lương/ngày). Chưa có bằng chứng rằng hệ số này làm hỏng chiến dịch nên giữ nguyên.

### Vì sao chưa sửa chiến thuật (phát hiện 4)
Trong mô hình này sức mạnh hiệu dụng của một bên tỷ lệ với `công / hệ số nhận`: Tấn công = 1,20/1,15 = 1,043,
Cân bằng = 1,0, Phòng thủ = 0,85/0,80 = **1,0625**. Phòng thủ vì thế mạnh hơn Tấn công về mọi mặt, trong khi UI
mô tả Tấn công là lựa chọn "mạnh". Vì sức mạnh chỉ phụ thuộc một tỷ số, mọi bộ hệ số miễn phí đều xếp hạng
tuyệt đối. Muốn có đánh đổi thật phải thêm chiều mới (chi phí lương thực/vật tư cho Tấn công, hoặc giảm
chiến lợi phẩm cho Phòng thủ, hoặc bonus theo loại quân). Đây là quyết định thiết kế nên để chủ dự án chọn.

## Độ khó chiến dịch (Cân bằng, không nâng cấp; bảng 6)

| Ải | Quân tối thiểu thắng ~100% theo thành phần |
|---|---|
| 1 | 10 giáo thắng 100% với mọi chiến thuật, mọi seed (test). Hướng dẫn đủ dễ. |
| 2 | Cần >= 20 quân hỗn hợp/cung/kỵ/khắc chế; 20 giáo thua (cung địch khắc giáo), cần 30. 10 quân khởi đầu không đủ => buộc phải tuyển. |
| 3 | 20 kỵ, 30 hỗn hợp/khắc chế, 40 giáo; 40 cung (38% ở 30). Nhiều đường thắng. |
| 4 | 30 kỵ, ~50 hỗn hợp/giáo/cung, 40 quân khắc chế (98,6%). |
| 5 | 50 kỵ, 60-80 khắc chế, ~80-100 giáo/cung/hỗn hợp. |

Có nhiều đội hình hợp lệ ở mọi ải. Kỵ binh đạt ngưỡng với ít đầu quân nhất nhưng tốn tài nguyên nhất.
Nâng cấp mạnh: Lò rèn 2 đưa trận gương ải 3 từ 48,2% lên 98,4% (bảng 5); cả ba nâng cấp tối đa giảm tổn thất
từ 92% xuống 42%. Chiến dịch không buộc grind vì thưởng chỉ nhận một lần (xem báo cáo kinh tế).
