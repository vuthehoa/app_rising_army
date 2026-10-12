# Rising Army — kiểm toán độ trung thực gameplay (Phase 4)

Ngày thu thập bằng chứng: 2026-10-12. Mục tiêu: xác định gameplay **thực sự** của Rising Army (Arkbits, Steam app 2999050, phát hành 06/03/2026, engine Godot theo ghi chú vá lỗi), rồi đối chiếu với ứng dụng này.

## 1. Bằng chứng đã thu thập và giới hạn

| Mã | Nguồn | Loại | Cách tôi xử lý |
|---|---|---|---|
| **SHOT 1-7** | 7 ảnh chụp màn hình chính thức trên trang Steam (1920×1080), tải qua API công khai `appdetails` | Quan sát trực tiếp | **Tôi đã xem từng ảnh** |
| **CLIP 1-4** | 4 clip gameplay chính thức (3.6–11.7 giây, 800×450) trong phần giới thiệu trang Steam | Quan sát trực tiếp | Tách khung hình bằng ffmpeg và xem |
| **STORE** | Văn bản trang Steam (mô tả, tính năng, thẻ) | Văn bản chính thức | Đọc |
| **NEWS** | 40 bài của nhà phát triển (devlog, "King's Edict", patch notes, 2024-06 → 2026-10) qua API tin tức Steam | Văn bản chính thức | Đọc (qua công cụ tóm tắt, trích tối đa 125 ký tự) |
| **IGD** | Bài giới thiệu/showcase trên Indie Games Developer | Văn bản do nhà phát triển cung cấp | Đọc |
| **TBL** | Bản xem trước của Turn Based Lovers (**bản demo**, 2025) | Báo chí | Đọc; có thể đã lỗi thời |
| **REV** | 35 đánh giá Steam bằng tiếng Anh (23 tích cực, 12 tiêu cực) qua API đánh giá | Người chơi | Đọc qua công cụ tóm tắt; coi là gián tiếp |
| **FORUM** | Tiêu đề 15 chủ đề thảo luận Steam và bản tóm tắt nội dung ở trang cộng đồng | Người chơi | Chỉ tiêu đề |

**Không có:** video gameplay dài (các trang YouTube không trả về mô tả/lời thoại/khung hình), game gốc để chơi, ảnh chụp các màn hình ngoài 7 ảnh trên (nhiệm vụ/nhật ký, quán rượu, thợ rèn, kết quả trận, cây tài năng, v.v.).
Hệ quả: những gì **không xuất hiện** trong 7 ảnh + 4 clip chỉ có thể là CORROBORATED (nhiều nguồn văn bản nhất quán) hoặc UNKNOWN.

**Quy ước trạng thái**
- `VERIFIED`: nhìn thấy trực tiếp trong ảnh/clip chính thức.
- `CORROBORATED`: nhiều nguồn gián tiếp nhất quán (văn bản chính thức + đánh giá/báo chí), chưa quan sát.
- `UNKNOWN`: chưa đủ bằng chứng. **Không được coi là quyết định thiết kế.**
- `CONFLICTING`: các nguồn không thống nhất.

## 2. Bảng đối chiếu theo hạng mục

### 2.1 Vòng lặp chính

| # | Nội dung | Trạng thái | Bằng chứng |
|---|---|---|---|
| 1 | Hai "không gian" chính: **Trại** (cảnh nhìn từ trên xuống) và **Bản đồ** (giấy da); chuyển bằng nút "map" ở trại và "go to camp" ở bản đồ | VERIFIED | SHOT 1, 3; CLIP 1-3 |
| 2 | Thanh dưới ở trại: `build` · `end-day` (nút tròn giữa) · `map`; góc dưới trái `stash 0/15`; góc dưới phải `journal` (có số) | VERIFIED | SHOT 1 |
| 3 | **Ngày trôi theo hành động**: bộ đếm "day N" góc trên phải; đi tới thị trấn mất 1 ngày (ngày 1 → 2) | VERIFIED (ngày 1→2 trong SHOT 3→4) | SHOT 1,3,4; IGD ("Days tick by with every action") |
| 4 | Cơ chế "Days until battle": mỗi ngày là một lượt, có đếm ngược tới trận | CORROBORATED | IGD (văn bản nhà phát triển) |
| 5 | Vòng lặp tóm tắt của người chơi: "build army, fight for quests, gather resources"; "travel, manage camp, send troops" | CORROBORATED | REV (davcri, slimsciadi), STORE |
| 6 | Game **ngắn**: hoàn thành chiến dịch trong khoảng 2.6–3 giờ, bản đồ nhỏ, băng qua bản đồ mất ~4 ngày game | CORROBORATED (4 đánh giá nhất quán) | REV (Czysio, Stillness, Spaghetti, Toothmother) |
| 7 | Hai chế độ: **Campaign** và **Sandbox** (chọn độ dài ván; hết quân là Game Over ngay ở Sandbox, không phải ở Campaign); thêm chế độ **Arena** (10 trận không có trại) | CORROBORATED | NEWS 2026-04-10, 2026-05-21, 2026-08-28 |
| 8 | Có **trùm cuối** hay không | CONFLICTING | REV: "no final boss"; FORUM: câu hỏi "sandbox or final boss?" chưa rõ |

### 2.2 Điều khiển

| # | Nội dung | Trạng thái | Bằng chứng |
|---|---|---|---|
| 9 | Ở trại: **kéo-thả binh sĩ vào công trình**; có thông báo "Unit added"; bàn tay con trỏ kéo | VERIFIED | CLIP 1 |
| 10 | Chạm/nhấp binh sĩ mở thẻ thông tin nhỏ; có gợi ý chuột phải để xem chi tiết | VERIFIED (thẻ), CORROBORATED (chuột phải) | CLIP 1 |
| 11 | Menu **Build**: hàng 7 biểu tượng; chọn công trình xem mô tả + chi phí rồi **đặt tự do lên nền trại** (bóng mờ theo con trỏ) | VERIFIED | CLIP 3 |
| 12 | Trên bản đồ: **nhấp để di chuyển** nhân vật (peon) tới điểm; có trạng thái "slowed down" kèm thanh | VERIFIED | SHOT 3; CLIP 2 |
| 13 | Trong trận: **không điều khiển giữa trận** ("no pause, no reset"); chỉ có tốc độ x1/x2/x3 và nút còi/kèn | VERIFIED (nút x1-x3, còi); CORROBORATED (không điều khiển) | SHOT 6-7; IGD; TBL (muốn có pause: chưa có) |
| 14 | Trước trận: **kéo biểu tượng binh sĩ vào vùng triển khai**; khung chọn để thả nhiều đơn vị | VERIFIED | SHOT 5; CLIP 4 |
| 15 | Có thể gán **lệnh cho từng đơn vị** ("ASSIGN_ORDERS") | VERIFIED (nút) / UNKNOWN (nội dung lệnh) | SHOT 5; NEWS 2025-12-16 |
| 16 | Có **đội hình mẫu** chọn nhanh: 4 biểu tượng xúc xắc, tooltip "Expanded formation" | VERIFIED | SHOT 5; CLIP 4; NEWS 2025-12-16 |

### 2.3 Bản đồ

| # | Nội dung | Trạng thái | Bằng chứng |
|---|---|---|---|
| 17 | Một **bản đồ lục địa lớn, liền mạch** có tên vùng (Stonewood Forest, Merchants Road, Donut's Lake, Desolate Hills, Potato County, Crystalfall County), thị trấn (Bamburgh), đường nét đứt, núi, rừng, hồ | VERIFIED | SHOT 3; CLIP 2 |
| 18 | **Thời tiết hiện trên bản đồ** (mây bão, sương mù) và làm chậm di chuyển ("slowed down") | VERIFIED (mây, trạng thái "slowed down"); UNKNOWN (cơ chế chính xác) | SHOT 3 |
| 19 | **Điểm hành quân (march points)** giới hạn đường dài; hết điểm thì quân phải nghỉ (thời gian để huấn luyện, quản lý) | CORROBORATED (văn bản nhà phát triển, bản devlog 2024) | NEWS Devlog #2 |
| 20 | Dấu ghim nhiệm vụ (cuộn giấy vàng) trên bản đồ | VERIFIED | SHOT 3 |
| 21 | Có kẻ địch di chuyển trên bản đồ (bandit pawn), thú hoang, bão; "random events" | CORROBORATED | NEWS Devlog #5, 7th Edict; IGD |
| 22 | Máy ảnh bản đồ mặc định **bám theo trại/quân**; di chuyển bằng WASD | CORROBORATED | NEWS Patch 0.1, 7th Edict |
| 23 | **Có thể dựng trại gần thị trấn**: nút "Camp near Town" | VERIFIED (nút) / UNKNOWN (cơ chế: trại di động hay chỉ quay về) | SHOT 4 |

### 2.4 Đơn vị (binh sĩ)

| # | Nội dung | Trạng thái | Bằng chứng |
|---|---|---|---|
| 24 | Mỗi binh sĩ có thẻ: **HP** (28/28), **năng lượng** (tia chớp 38/38), một chỉ số thứ ba màu lam 22/22 (ngọn lửa xanh), **chi phí/ngày** hiển thị biểu tượng xu "1" và thịt "1", cấp (Level 1), **Exp 0/25**, nút **Dismiss** | VERIFIED (hiển thị); UNKNOWN (ý nghĩa ngọn lửa xanh và biểu tượng "1/1") | SHOT 2 |
| 25 | **Thuộc tính huấn luyện = 3**: strength, dexterity, constitution; mỗi thuộc tính có thanh tiến độ phần trăm (0%) | VERIFIED | SHOT 2; IGD |
| 26 | Thẻ còn hiển thị 4 chỉ số biểu tượng (3, 4, 2, 6) và chỉ số dẫn xuất: chính xác 45%, tốc độ **3.5 m/s**, **2 s** (chu kỳ đánh), 10% | VERIFIED (giá trị hiển thị); UNKNOWN (ánh xạ 4 biểu tượng) | SHOT 2 |
| 27 | **TBL liệt kê thêm "speed" như một chỉ số**; IGD và ảnh chỉ có STR/DEX/CON huấn luyện | CONFLICTING (bản demo vs bản phát hành) | TBL vs SHOT 2/IGD |
| 28 | Binh sĩ có **tối đa 3 đặc điểm (traits) ngẫu nhiên**, nhu cầu (needs: ăn, nghỉ), tính cách | CORROBORATED | NEWS 2nd Edict; STORE; IGD |
| 29 | **3 ô trang bị**: áo giáp (mũ, giá trị 6), vũ khí (6-8, +3), ô trống (phụ kiện) | VERIFIED | SHOT 2; TBL |
| 30 | Trang bị có **cấp tối thiểu** của binh sĩ; **50+ vũ khí và 50+ giáp** (kế hoạch) | CORROBORATED | NEWS 4th Edict, STORE |
| 31 | **Không có "lớp" cố định**: biểu tượng mỗi binh sĩ cho thấy vũ khí và cận chiến/tầm xa; chuyên môn hình thành từ trang bị và huấn luyện ("archer, melee, or tank") | CORROBORATED | NEWS Devlog #8; REV (Spaghetti) |
| 32 | **Thăng chức đội trưởng (captain)** và gán vai trò đặc biệt ở trại | CORROBORATED | STORE; NEWS Update preview 1 |
| 33 | Cấp độ ít quan trọng: "level-ups barely matter, HP is all that counts" | CORROBORATED (1 đánh giá 98 giờ) | REV (Ac\|d) |
| 34 | Tuyển mộ qua **quán rượu** (tavern recruitment), **Angry Farmers** và **Wandering Merchant** trên bản đồ; có thể uống rượu ở quán để hồi HP và tinh thần (tốn tiền) | CORROBORATED | NEWS Devlog #6, 2nd Edict, Patch 0.2 |
| 35 | Binh sĩ **nói** khi trạng thái sức khỏe thay đổi; thợ cắt tóc ở mỗi thành phố tùy biến đầu | CORROBORATED | NEWS Update preview 1 |
| 36 | Bỏ trốn (desert) khi tinh thần thấp | CORROBORATED (1 đánh giá) | REV (Rijuka) |
| 37 | **HP và năng lượng kéo dài giữa các trận** (xem ô 38) | CORROBORATED | SHOT 2 (HP/năng lượng ở trại), CLIP 1/3 (công trình hồi HP và năng lượng) |

### 2.5 Doanh trại (trại)

| # | Nội dung | Trạng thái | Bằng chứng |
|---|---|---|---|
| 38 | Cảnh trại: hàng rào cọc gỗ bao quanh, **binh sĩ đi lại trong trại**, nền cỏ; công trình ban đầu: bãi bia bắn cung, bãi bù nhìn (huấn luyện cận chiến), lều cứu thương (chữ thập đỏ), đá dựng có lửa, bếp lửa trại, cụm lều lớn | VERIFIED | SHOT 1 |
| 39 | **Công trình có sức chứa** hiển thị `0/3` (Trainings' Fields, Infirmary); thả binh sĩ vào để huấn luyện/chữa trị | VERIFIED | CLIP 1 |
| 40 | Tooltip Infirmary: "Here you can heal your troops' wounds and get them ready for battle" (có biểu tượng tim + tia chớp = hồi HP và năng lượng) | VERIFIED | CLIP 3 |
| 41 | Menu Build có **7 loại công trình**; nhận diện được qua biểu tượng: bãi tập, lều, bia bắn cung, lều cứu thương (+), đá/ngọn lửa xanh, bia mộ (Graveyard), rương | VERIFIED (có 7 biểu tượng); CORROBORATED (nhận dạng Graveyard); UNKNOWN (tên và hiệu ứng từng loại) | CLIP 3; NEWS 2nd Edict |
| 42 | Mỗi công trình **cần tài nguyên để xây** (hiển thị chi phí) | VERIFIED | CLIP 3 |
| 43 | **Hư hỏng sau X ngày dùng, phải sửa trước khi dùng** | CORROBORATED | NEWS Update preview 2 |
| 44 | Công trình chiến đấu (ballista, tháp pháo) mở khóa bằng Talent | CORROBORATED | NEWS 2nd Edict |
| 45 | Có sự kiện trại gắn với binh sĩ/đặc điểm/yêu cầu nhà vua; có thể gom binh sĩ về bên lửa | CORROBORATED | NEWS Update preview 1 |
| 46 | Sức chứa quân: **x/20** (SHOT 1: 8/20; CLIP: 5/20) | VERIFIED (hiển thị); UNKNOWN (có nâng được hay không) | SHOT 1, CLIP 1 |
| 47 | Kho đồ (stash) **giới hạn theo cân nặng**: 0/15 kg | VERIFIED | SHOT 1-2 |

### 2.6 Chiến đấu

| # | Nội dung | Trạng thái | Bằng chứng |
|---|---|---|---|
| 48 | **Thời gian thực**: binh sĩ di chuyển liên tục trên chiến trường nhìn từ trên xuống, có vật cản (khúc gỗ, đá), hiện "Miss" khi đánh trượt | VERIFIED | SHOT 6-7; CLIP 4 |
| 49 | Giai đoạn **triển khai**: số đã đặt `8/8`, `7/7`, `0/4`; vùng triển khai bên trái; thẻ chân dung ở đáy (mỗi thẻ kèm biểu tượng vũ khí/tầm); nút `Deploy Units`, `Deploy Buildings`, `ASSIGN_ORDERS`, `Fight!` | VERIFIED | SHOT 5, 7; CLIP 4 |
| 50 | Tên hai bên ("Rising Army" vs "The Mud Hounds", "Lovatian" vs "The Weary Crows"), thanh sức mạnh/HP tổng của hai bên, huy hiệu mỗi bên | VERIFIED | SHOT 5-7; CLIP 4 |
| 51 | **Nút còi/kèn** và tốc độ x1/x2/x3 trong trận | VERIFIED (nút); CORROBORATED (còi tăng sức cho quân bị áp lực) | SHOT 6-7; TBL |
| 52 | Chỉ báo sức mạnh của hai quân, biểu tượng vũ khí cận/xa, cảnh kết thúc zoom-out, vật cản đá làm kẹt/chậm quân | CORROBORATED | NEWS Devlog #8 |
| 53 | Thời tiết trong trận: mọi điều kiện ngoài "Sunny" phạt quân; có nhật ký chiến đấu | CORROBORATED | NEWS 7th Edict |
| 54 | **Kỹ năng trong trận tốn tài nguyên** (cả địch cũng dùng); chữa trị trong trận mở bằng điểm vinh quang | CORROBORATED | NEWS 4th Edict; REV (Tetris) |
| 55 | **Mục tiêu trận đa dạng** (không chỉ tiêu diệt hết) | CORROBORATED (văn bản) / UNKNOWN (loại mục tiêu) | STORE ("battles with various objectives") |
| 56 | **Tử vong vĩnh viễn**; không có "bị gục rồi chết xác suất": văn bản chỉ nói chết là mất vĩnh viễn | CORROBORATED (permadeath); UNKNOWN (cơ chế gục/chết) | STORE, IGD |
| 57 | Trang bị Rare–Legendary của lính chết **về lại kho** sau trận (từ bản 0.2); trước đó mất | CORROBORATED | NEWS Patch 0.2; REV (Mitsu: cũ) |
| 58 | **Nghĩa địa (Graveyard) hồi sinh anh hùng** | CONFLICTING với "fallen lost forever" | NEWS 2nd Edict vs STORE/IGD |
| 59 | Binh sĩ trong trận đôi khi **bỏ qua đội hình đã lên kế hoạch** | CORROBORATED (1 đánh giá) | REV (RichardofYorke) |
| 60 | "Placement matters more than timing" (vị trí triển khai quan trọng hơn thời điểm) | CORROBORATED | REV (davcri) |
| 61 | Công thức sát thương/trúng/chí mạng/phòng thủ | UNKNOWN | — |

### 2.7 Tiến trình

| # | Nội dung | Trạng thái | Bằng chứng |
|---|---|---|---|
| 62 | **Thanh hài lòng của vua** ở giữa phía trên màn hình (con trỏ trượt từ đỏ sang xanh, biểu tượng vua); hai ô vương miện hai bên (0 và 10/40 trong clip) | VERIFIED (thanh); UNKNOWN (ý nghĩa 0 và 10/40) | SHOT 1,3; CLIP 1 |
| 63 | Chiến thắng tăng hài lòng của vua và cho kinh nghiệm | CORROBORATED | STORE |
| 64 | Nhiệm vụ chia **royal tasks** (cho "King's Pleasure") và **local tasks** (cho tài nguyên) | CORROBORATED | NEWS 4th Edict |
| 65 | **Điểm vinh quang (Glory Points)** sau mỗi trận mở **Talents** | CORROBORATED | NEWS 2nd Edict; IGD; REV |
| 66 | Mục tiêu thắng ván: một đánh giá nói "mục tiêu là 100 favour" | UNKNOWN (1 nguồn người chơi) | REV (Czysio) |
| 67 | Thua: hài lòng của vua cạn → thất bại; thất bại nhiệm vụ làm lộ **cướp kho** (mất tài nguyên/vật phẩm cất) | CORROBORATED | TBL (game over); NEWS Update preview 2 |
| 68 | Chế độ Sandbox chọn độ dài; chỉ Sandbox có nhiệm vụ cấp 5 | CORROBORATED | NEWS Update preview 2 |

### 2.8 Trang bị

| # | Nội dung | Trạng thái | Bằng chứng |
|---|---|---|---|
| 69 | 3 ô (áo giáp, vũ khí, phụ kiện); giá trị hiển thị (6; 6-8 và +3) | VERIFIED | SHOT 2 |
| 70 | Lọc kho "All / Armors / Weapons" | VERIFIED | SHOT 2 |
| 71 | Thợ rèn khác nhau theo thị trấn; cửa hàng **làm mới**; thương nhân lưu động; tooltip so sánh vật phẩm | CORROBORATED | REV (Tetris); NEWS (bản vá gần nhất) |
| 72 | Vũ khí truyền thống mới (cập nhật 2026-04) | CORROBORATED | NEWS |
| 73 | Vũ khí nhanh nhất luôn tốt nhất; vũ khí khác biệt ít; trang bị đạt trần nhanh | CORROBORATED (nhiều đánh giá, tiêu cực) | REV (Gruhk, Czysio, Founding Father) |
| 74 | Nâng cấp trang bị tại thợ rèn | UNKNOWN | — |

### 2.9 Nhiệm vụ

| # | Nội dung | Trạng thái | Bằng chứng |
|---|---|---|---|
| 75 | Cửa sổ **thị trấn** liệt kê "Available quests" (3 cuộn giấy), mỗi cuộn kèm **số đầu lâu = độ khó** (2, 1, 4) | VERIFIED | SHOT 4 |
| 76 | Nhiệm vụ có **hạn tính ngày**, hiển thị thông báo số ngày còn lại mỗi chu kỳ ngày/đêm | CORROBORATED | NEWS Patch 0.1; REV (slimsciadi) |
| 77 | Loại nhiệm vụ: chiến đấu, **nhiều chặng (step missions)**, **fetch and return**, **escort the caravan**; **bộ điều chỉnh (modifiers)**; cấp 1–5 | CORROBORATED | NEWS 4th, 6th Edict, Update preview 2; STORE |
| 78 | Số lượng nhiệm vụ ít, lặp lại ("a half dozen quests that get recycled") | CORROBORATED | REV (nhiều) |
| 79 | Nhận nhiệm vụ cuối ngày có thể tốn thêm một ngày | CORROBORATED (1 đánh giá) | REV (Rusty) |
| 80 | Nhận quest trùng khi mở cửa sổ thành phố hai lần liên tiếp (lỗi) | CORROBORATED | FORUM/NEWS |

### 2.10 Kinh tế

| # | Nội dung | Trạng thái | Bằng chứng |
|---|---|---|---|
| 81 | **7 loại tài nguyên** ở cột trái: biểu tượng xu, thịt (thức ăn), búa, thỏi, đá, thanh/gỗ, vải; số ban đầu 75, 300, 95, 125, 155, 135, 195 | VERIFIED (7 biểu tượng và số); UNKNOWN (tên và công dụng từng loại) | SHOT 1 |
| 82 | Thức ăn và đồng xu được phát cho từng binh sĩ **cuối ngày** | CORROBORATED (demo) + biểu tượng "1/1" trên thẻ | TBL; SHOT 2 |
| 83 | Thiếu thức ăn nhanh; thành phố không đủ nuôi 11 người gây chết đói giữa chiến dịch | CORROBORATED | REV (Founding Father), FORUM ("Food Shortages") |
| 84 | Nhà vua cấp tài nguyên | CORROBORATED (demo) | TBL |
| 85 | Chiến lợi phẩm: cướp (bandit) trả tài nguyên; điểm tham quan "loot useful items" | CORROBORATED | NEWS 0.2; STORE |
| 86 | Giá cụ thể, công thức tiền lương, bổng lộc | UNKNOWN | — |

### 2.11 Giao diện

| # | Nội dung | Trạng thái | Bằng chứng |
|---|---|---|---|
| 87 | Giao diện **ngang 16:9** trên PC, nhìn từ trên xuống, hoạt hình 2D "cute", viền mực dày, màu rực | VERIFIED | SHOT 1-7 |
| 88 | HUD thường trực: cột tài nguyên trái, thanh vua trên giữa, ngày trên phải, số quân trên trái, nút dưới giữa, `stash` dưới trái, `journal` dưới phải | VERIFIED | SHOT 1, 3 |
| 89 | Cửa sổ thị trấn: ảnh minh họa thị trấn (lò rèn, quán rượu, quầy chợ) bên trái; mô tả + danh sách nhiệm vụ + nút `Camp near Town` / `Leave Town` bên phải | VERIFIED | SHOT 4 |
| 90 | Bảng binh sĩ + bảng kho đồ mở cạnh nhau, có mũi tên chuyển sang binh sĩ khác | VERIFIED | SHOT 2 |
| 91 | Thiếu tiện ích: menu rườm rà, đánh dấu đường/địa hình kém, lưu đội hình yếu, hướng dẫn ban đầu kém | CORROBORATED | REV |

### 2.12 Kết thúc lượt chơi

| # | Nội dung | Trạng thái | Bằng chứng |
|---|---|---|---|
| 92 | Thất bại khi mất ủng hộ của vua; ở Sandbox hết quân là thua ngay | CORROBORATED | TBL, NEWS 7th Edict |
| 93 | Mục tiêu cuối cùng của Campaign | UNKNOWN / CONFLICTING (xem 8, 66) | — |
| 94 | Một ô lưu cho mỗi chế độ (Campaign và Sandbox riêng) | CORROBORATED | NEWS Update preview 2; REV (1 save) |

## 3. Kiểm toán ứng dụng hiện tại

Phân loại: **ĐÚNG** (khớp bằng chứng), **LIÊN QUAN** (có thật nhưng hành vi khác), **TỰ TẠO** (không có bằng chứng ở game gốc), **CHƯA ĐỦ DỮ LIỆU**.

| # | Hệ thống của ứng dụng | Phân loại | Đối chiếu |
|---|---|---|---|
| A1 | Chiến đấu theo vòng/hiệp, hàng trước/sau, 40 hiệp, bỏ chạy | **TỰ TẠO** (cấu trúc khác) | Gốc: thời gian thực, di chuyển liên tục, vùng triển khai, kèn trận (#48-51). Có thật ở cả hai: auto-battle, từng đơn vị, không điều khiển giữa trận, tốc độ x1-x3 |
| A2 | Chọn hàng trước/sau trước trận | **LIÊN QUAN** | Gốc: kéo-thả vị trí tự do trong vùng triển khai (#14), đội hình mẫu (#16) |
| A3 | Gục → 80% chết vĩnh viễn, còn lại bị thương vài ngày; Trạm y tế giảm xác suất chết | **TỰ TẠO** | Gốc: chết vĩnh viễn (#56) nhưng không có cơ chế xác suất; thương = mất HP kéo dài (#37, #40) |
| A4 | Thương tích tính bằng số ngày nghỉ | **TỰ TẠO** | Gốc: HP/năng lượng kéo dài, hồi ở lều cứu thương (#24, #37, #40) |
| A5 | Bỏ chạy khỏi trận (retreat) | **CHƯA ĐỦ DỮ LIỆU** | Không có bằng chứng nào về bỏ chạy trong trận; chỉ có bỏ trốn khỏi trại (#36) |
| A6 | 4 chỉ số huấn luyện được (str/dex/spd/con) | **LIÊN QUAN** | Gốc: 3 thuộc tính huấn luyện (#25); tốc độ là chỉ số dẫn xuất (#26); TBL ghi speed (CONFLICTING #27) |
| A7 | Huấn luyện: chọn chỉ số, mất 10 xu, +1 sau 1–3 ngày, tốn chỗ theo cấp Bãi tập | **TỰ TẠO** | Gốc: kéo-thả vào công trình có sức chứa 3 (#39), thanh tiến độ % cho từng thuộc tính (#25) |
| A8 | Vai trò cố định giáo/cung/kỵ gán từ khi sinh | **LIÊN QUAN** | Gốc: không có lớp, chuyên môn từ trang bị/huấn luyện (#31) |
| A9 | Tối đa 1 đặc điểm (6 loại) | **LIÊN QUAN** | Gốc: tối đa 3 đặc điểm ngẫu nhiên (#28); các loại cụ thể UNKNOWN |
| A10 | Tinh thần từng binh sĩ, lương, đào ngũ khi kiệt tinh thần | **ĐÚNG (một phần)** | Gốc có tinh thần, lương theo ngày (1 xu + 1 thức ăn mỗi người, #24, #82), bỏ trốn (#36); công thức UNKNOWN |
| A11 | 3 ô trang bị (vũ khí/áo giáp/phụ kiện), cấp tối thiểu, so sánh trước/sau | **ĐÚNG** | #29, #30, #71 |
| A12 | Kho đồ giới hạn theo số món (30 + 10×cấp Doanh trại) | **LIÊN QUAN** | Gốc: giới hạn theo cân nặng 15 kg (#47) |
| A13 | 4 loại tài nguyên (thức ăn, đồng xu, gỗ, sắt) | **LIÊN QUAN** | Gốc: 7 loại (#81); tên 5 loại vật liệu UNKNOWN |
| A14 | Bổng lộc hằng ngày của vua nhân (0.5 + hài lòng/100) | **TỰ TẠO (công thức)** | Gốc: nhà vua cấp tài nguyên (#84) nhưng không biết công thức |
| A15 | Doanh trại là cảnh có điểm chạm dẫn tới các màn quản lý | **LIÊN QUAN** | Gốc: cảnh trại là nơi quản lý trực tiếp, binh sĩ đi lại, kéo-thả (#38, #9) |
| A16 | 5 công trình cấp 0-3 (Doanh trại, Bãi tập, Trạm y tế, Lò rèn, Quán rượu) nâng cấp bằng gỗ/sắt/xu | **TỰ TẠO** | Gốc: 7 công trình đặt tự do, có sức chứa, hư hỏng và sửa (#41-43) |
| A17 | Tuyển mộ từ danh sách ứng viên làm mới mỗi 3 ngày ở Doanh trại | **TỰ TẠO** | Gốc: quán rượu, Angry Farmers, Wandering Merchant (#34) |
| A18 | Bản đồ gồm nút cố định với số ngày hành quân, chọn đội trước khi đi | **LIÊN QUAN** | Gốc: di chuyển tự do bằng con trỏ, thời tiết, march points (#12, #18, #19) |
| A19 | 3 vùng khóa theo số nhiệm vụ hoàn thành; vùng ẩn cần trinh sát | **TỰ TẠO** | Gốc: một bản đồ liền mạch, vùng có tên (#17); khóa vùng UNKNOWN |
| A20 | Trinh sát tốn 5 thức ăn + 1 ngày để lộ địa điểm | **TỰ TẠO** | Không có bằng chứng |
| A21 | Thành phố = màn hình gian hàng + người bán, đi bằng đội hộ tống | **LIÊN QUAN** | Gốc: cửa sổ thị trấn có quest + lò rèn/quán rượu/chợ (#75, #89, #71); "Camp near Town" |
| A22 | 8 người bán với tồn kho, tái cung 6 ngày, giá bán lại 40%, bán tài nguyên theo lô | **TỰ TẠO (chi tiết)** | Gốc: cửa hàng làm mới (#71) nhưng số liệu UNKNOWN |
| A23 | Nhiệm vụ: clear/deliver/level/explore/visit/gear (17 mẫu cố định), tối đa 3 đang làm | **LIÊN QUAN** | Gốc: royal/local, step, fetch & return, escort, modifiers (#64, #77); level/explore/visit/gear là TỰ TẠO |
| A24 | Hạn nhiệm vụ tính ngày, quá hạn bị phạt hài lòng | **ĐÚNG (một phần)** | #76, #67; mức phạt UNKNOWN |
| A25 | Hài lòng vua 0–100, game over khi 0 | **ĐÚNG (một phần)** | #62, #67, #92; thang số và ngưỡng UNKNOWN (hiển thị 0 và 10/40, #62) |
| A26 | Chiến dịch dài 100+ ngày, tiến trình theo số nhiệm vụ hoàn thành, **pháo đài cuối** (nhiệm vụ cuối) | **TỰ TẠO / MÂU THUẪN** | Gốc: ~3 giờ, bản đồ nhỏ, có thể không có trùm cuối (#6, #8) |
| A27 | Không có Glory Points, Talents, Graveyard, captain, needs, battle buildings | **CHƯA ĐỦ DỮ LIỆU** (đều CORROBORATED ở gốc) | Chưa làm |
| A28 | Chế độ Sandbox/Arena | Không có | Gốc có (#7) |
| A29 | Giao diện ngang | **ĐÚNG** | Gốc 16:9 ngang (#87); trình bày hoàn toàn khác (phong cách, bố cục) |
| A30 | Nghệ thuật vẽ bằng code, tông tối | **KHÁC** | Gốc: hoạt hình "cute", viền đậm, rực rỡ (#87). Không sao chép tài sản gốc, nhưng hướng nghệ thuật có thể đối chiếu |
| A31 | Không có thời tiết, kẻ địch di chuyển trên bản đồ, thú hoang, sự kiện ngẫu nhiên | **CHƯA LÀM** | #18, #21 |

## 4. Kết luận kiểm toán

**Phần khớp với game gốc:** cấu trúc HUD ngày/tài nguyên/vua; binh sĩ cá nhân; 3 ô trang bị và cấp tối thiểu; lương mỗi ngày; tinh thần; nhiệm vụ có hạn ngày; hài lòng của vua; cái chết vĩnh viễn; auto-battle không điều khiển giữa trận; giao diện ngang.

**Phần lệch đáng kể (ưu tiên cao):**
1. **Chiến đấu**: thời gian thực + triển khai tự do + đội hình mẫu (ứng dụng: vòng/hàng).
2. **Trạng thái binh sĩ**: HP/năng lượng kéo dài và hồi ở lều cứu thương; chết = HP về 0 (ứng dụng: gục → xác suất chết + ngày thương).
3. **Trại**: cảnh tương tác, binh sĩ đi lại, kéo-thả vào công trình có sức chứa 3, huấn luyện theo thanh % (ứng dụng: cảnh có nút điều hướng + màn hình riêng).
4. **Thuộc tính**: 3 thuộc tính huấn luyện str/dex/con; tốc độ dẫn xuất.
5. **Bản đồ/di chuyển**: di chuyển tự do và thời tiết/march points (ứng dụng: nút cố định).
6. **Độ dài chiến dịch**: game gốc khoảng 3 giờ; ứng dụng 100+ ngày với trùm cuối tự tạo.

**Chưa đủ bằng chứng để tái dựng chính xác** (liệt kê ở mục 5 của `RISING_ARMY_CORE_GAMEPLAY_SPEC.md` kèm nội dung cần người dùng cung cấp).
