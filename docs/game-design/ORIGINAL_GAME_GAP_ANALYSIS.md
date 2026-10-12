# Phân tích khoảng cách so với Rising Army gốc

## 1. Mức độ xác minh của nguồn tham khảo (đọc trước khi tin các kết luận)

**Giới hạn thực tế:** trang Steam, Steam Community, ảnh chụp màn hình và video gameplay **không truy cập được** từ môi trường làm việc
(kết nối tới store.steampowered.com bị từ chối). Vì vậy **không có kết luận nào dưới đây dựa trên ảnh chụp hay video**.
Nhãn dùng trong tài liệu:

- **VERIFIED**: được nêu trong ít nhất một nguồn tôi đã đọc (nội dung quảng bá của nhà phát triển được trích lại qua kết quả tìm kiếm, hoặc bài xem trước).
  Đây là xác minh gián tiếp (nguồn thứ cấp), không phải xem trực tiếp trang gốc.
- **OBSERVED**: quan sát trực tiếp từ ảnh/video. **Hiện không có mục nào** vì không truy cập được.
- **PROPOSED**: thiết kế chuyển thể của tôi, không khẳng định có trong game gốc.

Nguồn đã đọc: [Turn Based Lovers, bản xem trước theo demo](https://turnbasedlovers.com/overview/autobattler-strategy-rpg-rising-army/) (TBL);
tóm tắt nội dung cửa hàng Steam và phần giới thiệu nhà phát triển qua tìm kiếm web (STORE); bài giới thiệu của Indie Games Developer qua tìm kiếm (IGD).
Lưu ý: TBL viết về bản **demo**; nhiều chi tiết có thể đã đổi ở bản đầy đủ.

## 2. Những gì đã xác minh về game gốc

| Hệ thống | Nội dung | Nhãn | Nguồn |
|---|---|---|---|
| Thể loại | Strategy camp sim + auto-battler; quản lý và chỉ huy quân đội, huấn luyện từng binh sĩ, nâng cấp trại | VERIFIED | STORE |
| Chiến dịch | Thế giới mở (open world) | VERIFIED | STORE |
| Binh sĩ | Trang bị và chuyên môn hóa từng đơn vị; đổi tên lính; lính tích lũy kinh nghiệm; hơn 50 vũ khí và 50 áo giáp | VERIFIED | STORE |
| Chỉ số | Sức mạnh, khéo léo, tốc độ, thể trạng; kỹ năng/đặc điểm còn "dự kiến" ở bản demo | VERIFIED | TBL |
| Trang bị | 3 ô: vũ khí, áo giáp, phụ kiện; vật phẩm tăng chỉ số và đổi ngoại hình | VERIFIED | TBL |
| Trại | Trung tâm quản lý lính, kho tài nguyên, xây/nâng cấp công trình; công trình tăng hiệu quả và chất lượng sống của lính | VERIFIED | TBL |
| Trại (UI) | Kéo-thả binh sĩ vào công trình huấn luyện; có lính "thủ lĩnh bẩm sinh", "chiến binh tàn bạo", có lính nên nghỉ ở trạm y tế | VERIFIED | IGD |
| Tài nguyên | Thức ăn và đồng xu được phát cho từng lính cuối ngày; tài nguyên khác từ nhiệm vụ hoặc thu thập trên bản đồ | VERIFIED | TBL |
| Nhà vua | Cấp tài nguyên; mức hài lòng tăng khi làm tốt; làm vua thất vọng dẫn tới game over; nhiệm vụ và trận lớn để làm vua hài lòng; thanh hài lòng động có thưởng và hậu quả | VERIFIED | TBL, STORE |
| Bản đồ | Phong cách hóa; điểm đáng chú ý, thành phố có nhiệm vụ và người bán, thu thập tài nguyên, chạm trán thân thiện hoặc thù địch | VERIFIED | TBL |
| Trận đánh | Auto-battler; triển khai đội hình (cung/giáo sau hàng giáp nặng); có kèn trận hỗ trợ khi quân bị áp lực; theo dõi tinh thần; không tạm dừng, không làm lại | VERIFIED | TBL, IGD |
| Tử vong | Permadeath và thương tích ảnh hưởng chiến lược và không khí trại; tử trận là vĩnh viễn | VERIFIED | STORE, IGD |
| Phong cách | Màu sắc rực rỡ, UI gọn; nhạc nền phù hợp | VERIFIED (mô tả chung) | TBL |

## 3. Những gì KHÔNG xác minh được (không được coi là có trong game gốc)

Danh sách vùng và địa điểm cụ thể; nhiệm vụ có thời hạn tính theo ngày; cơ chế thương tích chi tiết (mức độ, thời gian hồi);
công thức chiến đấu; công thức tinh thần; kích thước/hình thái nghệ thuật chính xác (pixel hay vector); số lượng công trình và cấp độ; hệ thống đặc điểm đầy đủ;
cơ chế kinh nghiệm và lên cấp. Mọi thứ này trong bản chuyển thể là **PROPOSED**.

## 4. Ma trận sai lệch

| # | Tính năng gốc | Prototype v1 (trước) | Mức sai lệch ban đầu | Giải pháp đã làm | Test |
|---|---|---|---|---|---|
| 1 | Binh sĩ là cá thể, tên tùy chỉnh, chỉ số, kinh nghiệm | Chỉ có số lượng 3 loại quân | **Nghiêm trọng** | `Soldier` với id ổn định, tên, 4 chỉ số, cấp, XP, đặc điểm, tinh thần, thương tích | `Binh sĩ cá nhân`, `Chỉ số, trang bị` |
| 2 | Trang bị 3 ô, đổi chỉ số | Không có | Nghiêm trọng | Catalog 20 vật phẩm dữ liệu hóa, kho đồ, trang bị có kiểm tra điều kiện, so sánh trước/sau | `equip: ...`, `trước/sau trang bị` |
| 3 | Huấn luyện từng lính | Tuyển số lượng | Nghiêm trọng | Bãi tập: chọn chỉ số, tốn tiền/ngày, +1 chỉ số + XP | `Huấn luyện và kinh nghiệm` |
| 4 | Trại là trung tâm, có công trình | Danh sách nút nâng cấp, 7 công trình sản xuất | Cao | Cảnh trại có điểm chạm; 5 công trình có tác dụng lên lính (Doanh trại, Bãi tập, Trạm y tế, Lò rèn, Quán rượu) | widget tests |
| 5 | Tài nguyên phát cho từng lính mỗi ngày | Lương nuôi quân gộp | Trung bình | Thức ăn + đồng xu mỗi lính mỗi ngày; thiếu thì tinh thần giảm, kiệt thì đào ngũ | `Lương, tinh thần` |
| 6 | Nhà vua, nhiệm vụ, hài lòng, game over | 5 ải cố định, nhiệm vụ đếm số | Nghiêm trọng | Bảng nhiệm vụ nhà vua có hạn ngày, yêu cầu, thưởng, phạt; hài lòng 0 = game over; nhiệm vụ cuối = thắng | `Nhiệm vụ của nhà vua` |
| 7 | Bản đồ vùng, điểm khám phá, chạm trán | Không có | Nghiêm trọng | 3 vùng khóa theo tiến trình, 14 địa điểm (trại địch, tài nguyên, tàn tích), trinh sát, phục kích, sự kiện | `Khám phá, viễn chinh` |
| 8 | Auto-battler với lính thật, đội hình, thương vong | So sánh tổng sức mạnh | Nghiêm trọng | Engine theo từng đơn vị: hàng trước/sau, tốc độ, trúng/trượt, chí mạng, bỏ chạy; phát lại trực quan | `Chiến đấu auto-battler` |
| 9 | Permadeath và thương tích | Chết là số quân giảm | Nghiêm trọng | Gục ngã → chết vĩnh viễn hoặc bị thương (có xác suất, giảm nhờ Trạm y tế); phân biệt sống sót/bị thương/rút lui/tử trận | `Thương tích và tử trận` |
| 10 | Tinh thần quân đội | Không có | Cao | Tinh thần từng lính, ảnh hưởng sát thương, đổi theo trận/lương/đồng đội chết/quán rượu | `tinh thần`, `Lương, tinh thần` |
| 11 | Landscape / phong cách 2D riêng | Portrait, icon vector mặc định | Cao | UI landscape-only, thiết kế lại toàn bộ; nhân vật/vật phẩm/cảnh trại/bản đồ vẽ riêng bằng code | widget + simulator |
| 12 | Kèn trận, người bán ở thành phố, kỹ năng/đặc điểm đầy đủ, 50+ vật phẩm | Không có | Trung bình | **Chưa triển khai** (xem mục 5) | - |

## 5. Khác biệt còn lại với game gốc (không xác minh được hoặc chưa làm)

- **Kèn trận** (VERIFIED có ở gốc): chưa làm; trận tự chạy hoàn toàn, chỉ xem.
- **Thành phố và người bán** (VERIFIED): chưa làm; chỉ có một cửa hàng ở Lò rèn.
- **Kéo-thả lính vào công trình** (VERIFIED, IGD): thay bằng chọn lính rồi chọn chỉ số tập.
- **Nhiều vật phẩm / đặc điểm**: 20 vật phẩm (gốc 50+ vũ khí, 50+ giáp), 6 đặc điểm.
- **Ngoại hình lính đổi theo trang bị**: chỉ đổi mũ/giáp/vũ khí ở mức đơn giản (3 bậc giáp).
- **Tinh thần trong trận** (VERIFIED có theo dõi): chỉ dùng tinh thần lúc bắt đầu trận và để quyết định bỏ chạy; không đổi theo diễn biến.
- **Hình ảnh**: vẽ bằng CustomPainter, nhất quán nhưng ở mức nguyên mẫu, **không phải minh họa hoàn thiện**, và chưa có âm thanh/nhạc/hoạt ảnh nhân vật.
