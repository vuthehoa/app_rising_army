# Thành phố và người bán (Phase 3B)

Nhãn: **VERIFIED** (có trong nguồn đã đọc về game gốc: bản đồ có "cities with quests and vendors", thu thập tài nguyên, encounters), **PROPOSED** (thiết kế chuyển thể của tôi).

## Giả định đã chọn (không hỏi lại vì có phương án mặc định hợp lý)
- (VERIFIED) Thành phố có người bán, nằm trên bản đồ. (PROPOSED) Nhiệm vụ gắn với thành phố là mục tiêu "đến thành phố" và "mặc giáp cho đội", không phải giao diện nhiệm vụ riêng tại thành phố.
- (PROPOSED) **Không dịch chuyển tức thời**: đến thành phố là một chuyến hành quân thật (1–3 ngày), cả trại vẫn tốn lương và nhiệm vụ vẫn đếm hạn. Đội hộ tống 1+ binh sĩ. Đường tới thành phố an toàn (không phục kích) để thành phố là điểm an toàn đổi lấy thời gian.
- (PROPOSED) Chỉ giao dịch khi **đang ở** thành phố (`visiting`); rời thành phố hoặc đi nơi khác thì phải hành quân lại. Qua đêm trong thành phố vẫn tốn lương.
- (PROPOSED) Tiền duy nhất là đồng xu; thức ăn/gỗ/sắt bán theo lô 10.

## Vị trí, mở khóa, chi phí
| Thành phố | Vùng | Ngày hành quân | Mở khóa | Người bán |
|---|---|---|---|---|
| Thị trấn Đá Xám | Thung Lũng Xanh | 1 | Có sẵn | Thợ rèn (vũ khí), Thợ may giáp, Chợ vật tư (lô tài nguyên + phụ kiện bậc 1) |
| Pháo thành Tro | Đồi Tro | 2 | Vùng mở ở 3 nhiệm vụ | Xưởng binh khí (bậc 2; bậc 3 khan hiếm), Thợ giáp (**cần 3 nhiệm vụ**), Hiệu phụ kiện (bậc 2 + vật tư) |
| Cảng Đầm Đen | Đầm Đen | 3 | Vùng mở ở 6 nhiệm vụ | Chợ đen (bậc 3, giá ×1.4), Bến vật tư |

## Quy tắc giao dịch
- Giá bán ra = giá gốc × hệ số người bán (1.0–1.4); **giá thu mua = 40% giá gốc**, không phụ thuộc người bán ⇒ mua rồi bán lại luôn lỗ.
- Người bán chỉ mua loại hàng của mình (vũ khí/giáp/phụ kiện; vật tư mua phụ kiện và tài nguyên). **Đồ đang mặc không bán được.**
- Tồn kho giới hạn từng mặt hàng; **tái cung mỗi 6 ngày** thêm ⌈tối đa/3⌉ (không vượt tối đa). Đồ người chơi bán được thêm vào kho người bán (tối đa 2×).
- Kho đồ người chơi: 30 + 10×cấp Doanh trại; mua vượt sức chứa bị từ chối (cả ở lò rèn của trại). Phần thưởng nhiệm vụ/chiến lợi phẩm vẫn được nhận dù đầy (không mất đồ).
- Người bán bậc cao khóa theo tiến trình nhiệm vụ. Giao dịch bị chặn khi game over hoặc đã thắng.
- **Giao dịch nguyên tử**: mọi điều kiện được kiểm tra trước, mua rồi mới ghi; "Mua và trang bị" nếu không trang bị được thì không mua gì. Thất bại không làm thay đổi bất cứ trạng thái nào (kể cả tồn kho khởi tạo): có test so sánh toàn bộ JSON trước/sau.
- Hai lần mua liên tiếp món cuối: lần hai báo hết hàng, không trừ tiền hai lần.

## Nhiệm vụ mới liên kết
`visit_town` (đến Đá Xám), `visit_city` (đến Pháo thành Tro), `gear_a` (4 lính mặc giáp ≥ 3), `gear_b` (5 lính mặc giáp ≥ 6) — buộc người chơi dùng thành phố/cửa hàng. Mẫu nhiệm vụ nằm trong `catalog.dart`.

## Save
Không tăng phiên bản save (vẫn v2). Thêm trường **tùy chọn** `shops` (tồn kho từng người bán), `visiting`, `tradeCount`; save v2 cũ thiếu các trường này vẫn đọc được (test). Tồn kho được tạo từ danh mục ở lần ghi giao dịch đầu tiên; việc **xem** tồn kho không ghi vào state. Migration v1→v2 giữ nguyên và có test với dữ liệu mới. Checksum, backup, trường `legacy` giữ nguyên.

## UI (landscape)
Cảnh thành phố vẽ riêng (tường, tháp, cổng, gian hàng mái che có nhãn, khóa mờ nếu chưa mở), thông tin hành trình, kho đồ, nút rời thành phố; màn người bán: danh sách mua/bán, chi tiết, **so sánh chỉ số trước/sau cho từng binh sĩ**, chọn số lượng, giá/tồn kho/số dư, xác nhận khi chi ≥ 100 hoặc > 50% số dư, "Mua và trang bị". Cấu trúc sẵn sàng thay `CityPainter`/`ItemGlyph` bằng asset đồ họa.

## Chưa làm
Nhiệm vụ riêng của thành phố (giao diện nhận nhiệm vụ tại chợ), sửa chữa trang bị, vật phẩm hỗ trợ/vật tư hành quân, giá thay đổi theo thời gian, kèn trận và kỹ năng (theo yêu cầu phase: chưa chuyển sang).
