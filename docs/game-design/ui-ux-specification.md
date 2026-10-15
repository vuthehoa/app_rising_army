# ĐẶC TẢ GIAO DIỆN VÀ TRẢI NGHIỆM NGUỜI DÙNG (UI/UX SPECIFICATION)

**Dự án:** Rising Army Remake (Flutter iOS - Landscape)  
**Mục tiêu:** Chuẩn hóa toàn bộ cấu trúc giao diện, luồng thông tin, phản hồi trực quan và quy chuẩn tương tác cảm ứng cho bản Remake  
**Thiết bị tham chiếu:** iPhone 15 Pro Max (Landscape: 932 x 430 pt) &amp; Các thiết bị màn hình ngang nhỏ hơn  
**Đường dẫn tập tin:** `docs/game-design/ui-ux-specification.md`

---

## MỤC LỤC

1. NGUYÊN TẮC THIẾT KẾ UI/UX TỔNG QUAN
2. KHU VỰC HUD DÙNG CHUNG (GLOBAL TOP HUD)
3. CHI TIẾT CÁC MÀN HÌNH GAME  
  * 3.1\. Main Menu &amp; Khởi tạo Campaign
  * 3.2\. Doanh trại (Camp Screen)
  * 3.3\. Bản đồ thế giới (World Map Screen)
  * 3.4\. Thị trấn &amp; Bảng Nhiệm vụ (Town / Quests Screen)
  * 3.5\. Bố trí đội hình (Deploy Screen)
  * 3.6\. Trận chiến tự động (Battle Screen)
  * 3.7\. Kết quả trận đấu (Result Screen)
  * 3.8\. Cài đặt &amp; Lưu/Tải game (Settings / Save-Load Screen)
4. QUY CHUẨN THẢO TÁC CẢM ỨNG &amp; THÍCH ỨNG RESPONSIVE
5. PHÂN CẤP BẰNG CHỨNG XÁC MINH (EVIDENCE MATRIX)

---

## 1\. NGUYÊN TẮC THIẾT KẾ UI/UX TỔNG QUAN

* **Ưu tiên Trực quan hóa (Visual-First Approach):**  
  * Tận dụng tối đa hình ảnh 2D trung cổ, sprite lính, biểu tượng tài nguyên (*Resource Icons*) và mô hình công trình. `[OFFICIAL] [OBSERVED]`
  * Hạn chế tối đa màn hình chứa khối văn bản thuần túy hoặc danh sách cuộn dọc dài gây mỏi mắt trên thiết bị di động. `[REMAKE UI DESIGN PROPOSAL]`
* **Tương tác Cảm ứng Chuẩn Di động (Touch-Friendly Controls):**  
  * Diện tích vùng chạm (Touch Target) tối thiểu 44 x 44 pt cho mọi nút bấm, biểu tượng và ô tương tác. `[REMAKE UI DESIGN PROPOSAL]`
  * Kéo - Thả (*Drag-and-Drop*) trực quan: Có hiệu ứng bóng mờ (*Ghost Widget*) đi theo ngón tay và highlight viền ô nhận (*Snap Target Highlight*) màu xanh lá/đỏ. `[OBSERVED] [REMAKE UI DESIGN PROPOSAL]`
* **Trọng tâm Thông tin (Information Hierarchy):**  
  * Các thông số sinh tồn quan trọng: **King's Satisfaction Meter** `[OFFICIAL]`, **7 Tài nguyên** `[OBSERVED]`, **Máu/Thể lực/Morale của lính** `[OBSERVED]` phải luôn nhận biết được ngay lập tức mà không cần mở menu phụ.
* **Phân định rõ 3 Lớp Dữ liệu:**  
  1. *Thông tin Cố định:* Nhãn công trình, thuộc tính nhân vật (Strength, Dexterity, Constitution, Speed). `[OFFICIAL] [OBSERVED]`
  2. *Dữ liệu Biến đổi:* Máu hiện tại/Max HP, March Points còn lại, số Vàng hiện có, số ngày còn lại của nhiệm vụ. `[OBSERVED]`
  3. *Thao tác Khả thi:* Nút bấm active, ô nhận lính sẵn sàng, các nút bị disable/mờ do thiếu tài nguyên hoặc bị khóa. `[REMAKE UI DESIGN PROPOSAL]`

---

## 2\. KHU VỰC HUD DÙNG CHUNG (GLOBAL TOP HUD)

Top HUD xuất hiện cố định ở viền trên màn hình khi người chơi ở trong **Camp**, **World Map**, hoặc **Town**.

### Bố cục &amp; Phân vùng UI:

* **Góc Trái:** Biểu tượng Vương miện + Thanh **King's Satisfaction Meter** (Hiển thị % độ hài lòng của Vua). `[OFFICIAL] [OBSERVED]`
* **Trung tâm:** Bảng 7 Tài nguyên dạng biểu tượng + con số: Vàng (*Gold*), Thức ăn (*Food*), Công cụ (*Tools*), Sắt (*Iron*), Đá (*Stone*), Gỗ (*Wood*), Vải (*Cloth*). `[OBSERVED]`
* **Góc Phải:** Ngày chiến dịch (`Day X`) + Nút `End Day` (Hình đồng hồ/mặt trời) + Nút `Pause / Settings` (Hình bánh răng). `[OFFICIAL] [OBSERVED]`

---

## 3\. CHI TIẾT CÁC MÀN HÌNH GAME

### 3.1\. Main Menu &amp; Khởi tạo Campaign

#### 1\. Mục tiêu màn hình

Điều hướng người chơi bắt đầu Campaign mới, chọn chế độ Sandbox Mode / Arena Mode, tiếp tục file save cũ hoặc chỉnh sửa cài đặt hệ thống. `[OFFICIAL]`

#### 2\. Bố cục &amp; Các khu vực UI chính

* **Background:** Hình ảnh minh họa 2D phong cách trung cổ. `[OFFICIAL]`
* **Cột Nút Chức năng (Left/Center Menu):** Nút `New Campaign`, `Sandbox Mode`, `Arena Mode`, `Continue`, `Settings`. `[OFFICIAL]`
* **Modal Khởi tạo Campaign mới (New Campaign Overlay):**  
  * Ô nhập tên Chỉ huy (*Commander's Name*) &amp; Tên Quân đoàn (*Army's Name*). `[TRANSCRIPT]`
  * Grid chọn Chân dung (*Portrait Selector*) &amp; Grid chọn Cờ hiệu (*Banner Symbol &amp; Color*). `[TRANSCRIPT]`
  * Thẻ chọn Thân thế (*Background Selector*): `Full Hero` (Nhiều King's Pleasure, ít Vàng) vs `Plebs` (Nhiều Vàng, ít King's Pleasure). `[TRANSCRIPT]`
  * Toggle Bật/Tắt Hướng dẫn (*Tutorial Switch*). `[TRANSCRIPT]`

#### 3\. Thông tin hiển thị &amp; Thứ tự ưu tiên

1. Tên Game &amp; Nút `Continue` (Ưu tiên 1 nếu có file save cũ). `[OFFICIAL]`
2. Các chế độ chơi `New Campaign`, `Sandbox`, `Arena` (Ưu tiên 2). `[OFFICIAL]`
3. Các trường thông số khởi tạo trong Modal (Ưu tiên 3). `[TRANSCRIPT]`

#### 4\. Thao tác chính của người chơi

* **Tap:** Chọn nút màn hình chính, chọn Portrait, chọn Banner, chuyển Background. `[TRANSCRIPT]`
* **Nhập văn bản (Text Input):** Nhập tên Commander và Army. `[TRANSCRIPT]`
* **Xác nhận (Confirm):** Tap nút `Start` để bắt đầu game. `[TRANSCRIPT]`

#### 5\. Phản hồi trực quan (Visual Feedback)

* *Thành công:* Tap nút có hiệu ứng nén nút (Scale down 0.95) kèm âm thanh Click; mở Modal mượt mượt (Fade-in 200ms).
* *Chưa hoàn thành:* Nếu chưa nhập tên Commander/Army -&gt; Nút `Start` bị xám mờ (Disabled state), chạm vào hiển thị tooltip "Vui lòng nhập tên". `[REMAKE UI DESIGN PROPOSAL]`
* *Trạng thái không có Save:* Nút `Continue` mờ đi và không thể tương tác. `[REMAKE UI DESIGN PROPOSAL]`

#### 6\. Điều hướng

* **Đi vào:** Khởi động ứng dụng.
* **Đi ra / Chuyển tiếp:**  
  * Tap `Start` \-&gt; Xem bảng cốt truyện dẫn dắt (*Backstory panel*) -&gt; Chuyển cảnh nạp vào Camp / Map. `[TRANSCRIPT]`
  * Tap `Arena Mode` \-&gt; Chuyển sang màn hình chọn 10 kịch bản Đấu trường. `[OFFICIAL]`

#### 7\. Bố trí thích ứng (Responsive Layout)

* **iPhone 15 Pro Max (Landscape):** Cột Menu đặt bên trái màn hình, nhường 60% không gian bên phải thể hiện Background 2D artwork.
* **Màn hình ngang nhỏ hơn:** Cột Menu tự động căn giữa, giảm kích thước padding giữa các nút.

---

### 3.2\. Doanh trại (Camp Screen)

#### 1\. Mục tiêu màn hình

Trung tâm điều hành: Quản lý lính, phân bổ lính vào công trình để phục hồi HP/Energy/Morale, huấn luyện thuộc tính, xây dựng và nâng cấp công trình doanh trại. `[OFFICIAL] [OBSERVED]`

#### 2\. Bố cục &amp; Các khu vực UI chính

* **Top HUD:** Thanh tài nguyên và King's Satisfaction cố định ở viền trên. `[OFFICIAL] [OBSERVED]`
* **Khu vực Trại chính (Center Camp View - 70% diện tích):** Khung cảnh Doanh trại 2D chứa các mô hình công trình: Tents, Infirmary, Altar, Training Fields, Gravestone, Stash. `[OBSERVED]`
* **Thanh Danh sách Quân đoàn (Roster Drawer / Sidebar):** Thanh trượt thu gọn/mở rộng chứa danh sách các thẻ lính. `[REMAKE UI DESIGN PROPOSAL]`
* **Góc Dưới Phải:** Nút `Build Menu` (Hình cái búa) &amp; Nút `World Map` (Hình la bàn/bản đồ). `[OBSERVED]`

#### 3\. Thông tin hiển thị &amp; Thứ tự ưu tiên

1. Chỉ số HP (Đỏ), Energy (Tia sét vàng), Morale (Ngọn lửa xanh) hiển thị dạng thanh nhỏ trên đầu từng lính và trên thẻ lính. `[OBSERVED]`
2. Ô chứa lính (*Slots*) trên từng công trình (ví dụ: Infirmary có 3 ô tròn). `[OBSERVED]`
3. Icon cảnh báo lính bị thương nặng, kiệt sức hoặc hoảng sợ. `[OBSERVED]`

#### 4\. Thao tác chính của người chơi

* **Kéo - Thả (Drag-and-Drop):** Kéo thẻ lính từ Roster thả vào ô Slot của công trình mong muốn. `[OFFICIAL] [OBSERVED]`
* **Tap:**  
  * Tap vào lính -&gt; Mở bảng Hồ sơ chi tiết lính (*Soldier Detail Modal*). `[OBSERVED]`
  * Tap vào công trình -&gt; Hiển thị cấp độ, nút `Upgrade` và chi phí nguyên liệu. `[OBSERVED]`
  * Tap `End Day` \-&gt; Kích hoạt chu kỳ chuyển ngày. `[OFFICIAL] [OBSERVED]`

#### 5\. Phản hồi trực quan (Visual Feedback)

* *Kéo-Thả thành công:* Ô Slot phát sáng viền xanh nõn chuối; lính nhảy vào vị trí với âm thanh đặt quân; thanh HP/Energy/Morale bắt đầu xuất hiện icon hiệu ứng tăng điểm qua đêm. `[REMAKE UI DESIGN PROPOSAL]`
* *Thả sai / Slot đầy:* Ô Slot nhấp nháy đỏ; thẻ lính tự động dội lại (*Spring-back animation*) về Roster. `[REMAKE UI DESIGN PROPOSAL]`
* *Thiếu tài nguyên xây/nâng cấp:* Con số tài nguyên bị thiếu trong Build Menu hiển thị màu đỏ nhấp nháy; nút `Build` / `Upgrade` bị khóa mờ. `[REMAKE UI DESIGN PROPOSAL]`
* *Công trình hỏng:* Mô hình công trình xuất hiện vết nứt/khói kèm biểu tượng Cờ lê yêu cầu sửa chữa. `[COMMUNITY]`

#### 6\. Điều hướng

* **Đi vào:** Từ Main Menu (Load save) hoặc từ World Map (Nhấn nút Return to Camp).
* **Đi ra / Chuyển tiếp:** Tap nút `World Map` \-&gt; Fade chuyển sang Bản đồ thế giới.

#### 7\. Bố trí thích ứng (Responsive Layout)

* **iPhone 15 Pro Max:** Sidebar Roster mở cố định bên trái mà không che lấp khu vực trại chính.
* **Màn hình ngang nhỏ hơn:** Sidebar Roster chuyển thành dạng Drawer ẩn/hiển thị qua nút gạt trượt.

---

### 3.3\. Bản đồ thế giới (World Map Screen)

#### 1\. Mục tiêu màn hình

Khám phá thế giới mở 2D, điều khiển quân đoàn di chuyển đến Thị trấn, điểm nhặt tài nguyên, sự kiện ngẫu nhiên và các node giao tranh. `[OFFICIAL] [OBSERVED]`

#### 2\. Bố cục &amp; Các khu vực UI chính

* **Bản đồ chính:** Bản đồ vùng 2D với hiệu ứng Sương mù sương mở (*Fog of War*) xung quanh bán kính tầm nhìn tròn của quân đoàn. `[OFFICIAL] [OBSERVED]`
* **Top HUD:** Điểm di chuyển **March Points** \+ Tài nguyên + King's Satisfaction. `[OBSERVED]`
* **Bottom HUD:** Mũi tên chỉ hướng Quest đang kích hoạt + Nút `Return to Camp`. `[OBSERVED]`

#### 3\. Thông tin hiển thị &amp; Thứ tự ưu tiên

1. Vị trí quân đoàn (Sprite nhân vật cầm cờ ở trung tâm bán kính tầm nhìn). `[OBSERVED]`
2. Điểm **March Points** còn lại trong ngày. `[OBSERVED]`
3. Các biểu tượng địa điểm: Thị trấn (*Towns*), Điểm nhặt tài nguyên (*Pickups*), Dấu chấm hỏi Sự kiện (*Random Events*), Node Cướp (*Bandits*) / Quái thú (*Wild Beasts*). `[OFFICIAL] [OBSERVED]`

#### 4\. Thao tác chính của người chơi

* **Tap:** Tap chọn vị trí/node trên bản đồ để phát lệnh di chuyển. `[OBSERVED]`
* **Chạm xoay / Pan &amp; Zoom:** Vuốt 2 ngón tay để thu phóng (Zoom in/out) hoặc vuốt 1 ngón tay để di chuyển góc nhìn camera (hoặc phím WASD). `[OFFICIAL] [OBSERVED]`

#### 5\. Phản hồi trực quan (Visual Feedback)

* *Di chuyển:* Đường đứt nét màu xanh hiển thị tuyến đường di chuyển dự kiến; quân đoàn di chuyển từng bước đồng thời March Points giảm dần. `[OBSERVED]`
* *Địa hình khó:* Di chuyển qua Núi/Đầm lầy -&gt; Đường đứt nét chuyển sang màu cam, chữ "-X March Points" nổi lên chỉ rõ việc bị chậm tốc độ. `[OBSERVED]`
* *Hết March Points:* Con số March Points nhấp nháy đỏ; xuất hiện icon gợi ý nhấn `End Day` để khôi phục điểm di chuyển cho ngày hôm sau. `[OBSERVED]`
* *Va chạm Node:* Đi vào ô Sự kiện -&gt; Tự động nảy Popup thoại; Đi vào ô Cướp/Quái thú -&gt; Tự động chuyển màn hình Deploy. `[OFFICIAL] [OBSERVED]`

#### 6\. Điều hướng

* **Đi vào:** Từ Camp (Nhấn nút World Map) hoặc từ Thị trấn (Nhấn Leave Town).
* **Đi ra:** Va chạm đụng độ -&gt; Deploy Screen; Chạm ô Thị trấn -&gt; Town Screen; Bấm nút Camp -&gt; Camp Screen.

#### 7\. Bố trí thích ứng (Responsive Layout)

* **iPhone 15 Pro Max:** Mở rộng góc quan sát camera bản đồ (FOV rộng hơn).
* **Màn hình ngang nhỏ hơn:** Cố định tỷ lệ Scale nhân vật, cho phép Zoom-out linh hoạt để không bị hạn chế tầm nhìn.

---

### 3.4\. Thị trấn &amp; Bảng Nhiệm vụ (Town / Quests Screen)

#### 1\. Mục tiêu màn hình

Tuyển lính mới (Tavern), mua bán trang bị (Blacksmith), giao dịch nguyên liệu (Market) và nhận các nhiệm vụ từ Nhà vua/Thị trấn (Quest Board). `[OFFICIAL] [OBSERVED]`

#### 2\. Bố cục &amp; Các khu vực UI chính

* **Thanh Tab Công trình Thị trấn (Top Navigation Bar):** 4 Tab `Tavern`, `Blacksmith`, `Market`, `Quest Board`. `[OBSERVED]`
* **Khung Nội dung Trung tâm (Split View 2 Cột):**  
  * *Cột trái (40%):* Danh sách vật phẩm / Danh sách lính khả thi / Danh sách Nhiệm vụ. `[OBSERVED]`
  * *Cột phải (60%):* Chi tiết chỉ số lính / So sánh trang bị / Mô tả &amp; Phần thưởng Nhiệm vụ. `[OBSERVED]`
* **Viền dưới:** Số Vàng hiện có + Nút `Leave Town`. `[OBSERVED]`

#### 3\. Thông tin hiển thị &amp; Thứ tự ưu tiên

1. Chi phí Vàng thuê lính, giá vật phẩm mua/bán. `[OBSERVED]`
2. Chỉ số thuộc tính lính cần tuyển (Str/Dex/Con, Vũ khí ban đầu, Morale, Upkeep Vàng + Thức ăn/ngày). `[OBSERVED]`
3. Bảng Nhiệm vụ: Độ khó **Skull Level** (1 đến 4 Skulls), **Thời hạn ngày (Days Limit)**, Phần thưởng (Vàng, Food, XP, King's Satisfaction). `[OBSERVED]`

#### 4\. Thao tác chính của người chơi

* **Tap:** Tap chọn Tab dịch vụ; Tap chọn mặt hàng/nhiệm vụ trong danh sách; Tap nút `Buy` / `Recruit` / `Accept Quest`. `[OBSERVED]`

#### 5\. Phản hồi trực quan (Visual Feedback)

* *Đủ điều kiện mua/thuê:* Nút `Buy` / `Recruit` hiển thị màu xanh lá lục bảo phát sáng nhẹ; Tap mua -&gt; Vàng bị trừ trực tiếp với âm thanh tiếng tiền xu `clink`. `[REMAKE UI DESIGN PROPOSAL]`
* *Thiếu Vàng:* Nút mua chuyển màu xám xịt; Chạm vào hiển thị thông báo "Không đủ Vàng". `[REMAKE UI DESIGN PROPOSAL]`
* *Nhận Nhiệm vụ thành công:* Thẻ Nhiệm vụ chuyển sang trạng thái "Active"; Mũi tên chỉ hướng xuất hiện ở màn hình Map chỉ về vị trí mục tiêu. `[OBSERVED]`

#### 6\. Điều hướng

* **Đi vào:** Khi quân đoàn chạm vào ô Thị trấn trên World Map.
* **Đi ra:** Tap nút `Leave Town` \-&gt; Trở lại World Map.

#### 7\. Bố trí thích ứng (Responsive Layout)

* **iPhone 15 Pro Max:** Bố trí chuẩn 2 cột song song hiển thị đầy đủ cả danh sách và khung thông tin chi tiết.
* **Màn hình ngang nhỏ hơn:** Cột chi tiết bên phải thu gọn thành dạng Modal Popup đè lên khi tap vào 1 dòng trong danh sách bên trái.

---

### 3.5\. Bố trí đội hình (Deploy Screen)

#### 1\. Mục tiêu màn hình

Lựa chọn danh sách lính xuất trận, sắp xếp vị trí chiến thuật trên lưới đấu dựa trên tương quan cự ly và quy mô kẻ địch. `[OFFICIAL] [OBSERVED]`

#### 2\. Bố cục &amp; Các khu vực UI chính

* **Chiến trường Lưới Đấu (Center Tactical Grid):** Lưới ô chia làm 2 phe: Đồng minh (Trái) vs Địch (Phải).  
  * Lưới đồng minh gồm: Hàng trước (*Frontline*) &amp; Hàng sau (*Backline*). `[OBSERVED]`
* **Thanh Lính Dự bị (Bottom Roster Carousel):** Cuộn ngang chứa các lính chưa xếp vào lưới. `[REMAKE UI DESIGN PROPOSAL]`
* **Top Header:** Chỉ số Quân số xuất trận (ví dụ: `6/8 Deploy Limit`) + Lực lượng địch dự kiến. `[OFFICIAL] [OBSERVED]`
* **Góc Dưới Phải:** Nút `Preset` (Tự xếp) &amp; Nút `Fight / Start Battle` (Hình 2 thanh kiếm bắt chéo). `[OFFICIAL] [OBSERVED]`

#### 3\. Thông tin hiển thị &amp; Thứ tự ưu tiên

1. Giới hạn quân số xuất trận (*Deploy Limit*). `[OFFICIAL] [OBSERVED]`
2. Avatar lính, loại vũ khí, thanh HP hiện tại và Morale. `[OBSERVED]`
3. Vị trí dàn quân địch ở phía đối diện. `[OBSERVED]`

#### 4\. Thao tác chính của người chơi

* **Kéo - Thả (Drag-and-Drop):** Kéo lính từ Thanh dự bị thả vào ô lưới mong muốn, hoặc kéo đổi vị trí 2 lính trên lưới. `[OBSERVED]`
* **Tap:** Tap lính trên lưới để rút về hàng dự bị; Tap `Preset` để tự động điền quân; Tap `Fight` để xác nhận giao tranh. `[OFFICIAL] [OBSERVED]`

#### 5\. Phản hồi trực quan (Visual Feedback)

* *Chưa đạt số lượng quân tối thiểu:* Nút `Fight` bị khóa mờ. `[REMAKE UI DESIGN PROPOSAL]`
* *Đủ điều kiện xuất trận:* Nút `Fight` chuyển màu đỏ cam phát sáng nhịp thở (*Pulse Effect*). `[REMAKE UI DESIGN PROPOSAL]`
* *Cảnh báo vị trí sai:* Đặt lính Bắn cung ở Hàng trước -&gt; Xuất hiện biểu tượng Cảnh báo màu vàng "Rủi ro cao". `[REMAKE UI DESIGN PROPOSAL]`

#### 6\. Điều hướng

* **Đi vào:** Từ World Map khi xảy ra giao tranh hoặc vào node Quest.
* **Đi ra / Chuyển tiếp:** Tap `Fight` \-&gt; Chuyển mượt sang Battle Screen.

#### 7\. Bố trí thích ứng (Responsive Layout)

* **iPhone 15 Pro Max:** Lưới đấu hiển thị rộng rãi, khoảng cách giữa Frontline và Backline rõ ràng.
* **Màn hình ngang nhỏ hơn:** Giảm kích thước khung ô lưới (Grid Cell) từ 60pt xuống 48pt để đảm bảo không che lấp Roster dự bị.

---

### 3.6\. Trận chiến tự động (Battle Screen)

#### 1\. Mục tiêu màn hình

Trực quan hóa diễn biến giao tranh Autobattler tự động, hiển thị trạng thái sinh tồn và cho phép kích hoạt kỹ năng Sừng chiến (*War Horn*). `[OFFICIAL] [OBSERVED]`

#### 2\. Bố cục &amp; Các khu vực UI chính

* **Màn hình Giao tranh 2D chính:** Đội hình 2 bên tự động di chuyển và tung đòn đánh. `[OFFICIAL] [OBSERVED]`
* **Top Header:** Thanh **Tide of Battle** (Thước đo tương quan lực lượng) + Icon Thời tiết hiện tại (Phạt đòn đánh nếu có). `[OFFICIAL] [OBSERVED]`
* **Góc Dưới Trái:** Nút **War Horn** (Sừng chiến - Hình chiếc tù và). `[OFFICIAL] [OBSERVED]`
* **Góc Dưới Phải:** Nút toggle **Combat Log** (Nhật ký chiến đấu). `[OFFICIAL]`

#### 3\. Thông tin hiển thị &amp; Thứ tự ưu tiên

1. Thanh Máu (HP) + Thanh Sĩ khí (Morale) hiển thị trực tiếp trên đầu từng lính. `[OBSERVED]`
2. Chỉ số đòn đánh nổi (*Floating Combat Text*): Con số sát thương, chữ `Miss`, `Critical`. `[OBSERVED]`
3. Trạng thái thời tiết gây phạt đòn đánh trên Top Header. `[OFFICIAL]`

#### 4\. Thao tác chính của người chơi

* **Tap:** Tap nút `War Horn` để hồi phục Morale khẩn cấp; Tap nút `Combat Log` để bật/tắt bảng xem lịch sử đòn đánh. `[OFFICIAL] [OBSERVED]`

#### 5\. Phản hồi trực quan (Visual Feedback)

* *Kích hoạt War Horn:* Sóng âm lan tỏa toàn màn hình, thanh Morale đồng minh đồng loạt tăng lên, icon ngọn lửa bùng sáng kèm âm thanh tù và vang dội. `[OFFICIAL] [OBSERVED]`
* *Đòn đánh Critical:* Con số sát thương phóng to màu vàng kim kèm hiệu ứng rung màn hình nhẹ (*Screen Shake*). `[OBSERVED] [REMAKE UI DESIGN PROPOSAL]`
* *Lính bỏ chạy:* Lính vỡ Morale xuất hiện biểu tượng Mơ hồ/Hoảng sợ trên đầu và tự động chạy về mép màn hình. `[OBSERVED]`
* *Lính tử trận (Permadeath):* Lính cạn HP ngã xuống, sprite biến thành vũng máu/bia mộ. `[OFFICIAL] [OBSERVED]`

#### 6\. Điều hướng

* **Đi vào:** Từ Deploy Screen sau khi nhấn Fight.
* **Đi ra:** Trận đấu kết thúc (Thắng hoặc Thua toàn bộ) -&gt; Tự động chuyển sang Result Screen.

#### 7\. Bố trí thích ứng (Responsive Layout)

* **iPhone 15 Pro Max:** Khoảng cách cự ly giữa 2 đội hình được trải rộng mượt mà.
* **Màn hình ngang nhỏ hơn:** Thu gọn Bảng Combat Log xuống còn 3 dòng chữ ngắn ở góc dưới màn hình.

---

### 3.7\. Kết quả trận đấu (Result Screen)

#### 1\. Mục tiêu màn hình

Tổng kết trận đấu, hiển thị thống kê hiệu suất lính, trao phần thưởng XP/Tài nguyên/Rương Loot, xử lý tăng cấp và thăng hạng King's Satisfaction. `[OFFICIAL] [OBSERVED]`

#### 2\. Bố cục &amp; Các khu vực UI chính

* **Banner Tiêu đề:** `VICTORY` (Vàng kim) hoặc `DEFEAT` (Đỏ thẫm) ở trên cùng. `[OBSERVED]`
* **Bảng Thống kê Hiệu suất (Center Table - 3 Cột):** `Kills` (Mạng tiêu diệt), `Damage Dealt` (Sát thương gây ra), `Damage Taken` (Sát thương nhận vào). `[OBSERVED]`
* **Khu vực Thưởng &amp; Lên cấp (Bottom Rewards Section):**  
  * Danh sách lính kèm thanh XP + Biểu tượng `+` Lên cấp (*Level Up*). `[OFFICIAL] [OBSERVED]`
  * Biểu tượng **Rương thưởng (Loot Chest)**. `[OBSERVED]`
* **Góc Dưới Phải:** Nút `Continue`. `[OFFICIAL]`

#### 3\. Thông tin hiển thị &amp; Thứ tự ưu tiên

1. Trạng thái Thắng / Thua. `[OBSERVED]`
2. Rương Loot và Tài nguyên/Vật phẩm thu được. `[OBSERVED]`
3. Thông báo tăng điểm **King's Satisfaction**. `[OFFICIAL] [OBSERVED]`
4. Bảng thống kê chi tiết Kills / Damage. `[OBSERVED]`

#### 4\. Thao tác chính của người chơi

* **Tap:**  
  * Tap vào Rương thưởng để mở rương nhặt đồ. `[OBSERVED]`
  * Tap vào dấu `+` bên cạnh lính Level Up để mở Popup tăng điểm thuộc tính (Strength / Dexterity / Constitution). `[OBSERVED]`
  * Tap `Continue` để xác nhận kết thúc. `[OFFICIAL]`

#### 5\. Phản hồi trực quan (Visual Feedback)

* *Mở Rương Loot:* Rương nảy lên, bật nắp phát sáng kèm các icon Vàng, Food, Trang bị văng ra với âm thanh thưởng `fanfare`. `[OBSERVED] [REMAKE UI DESIGN PROPOSAL]`
* *Lên cấp (Level Up):* Biểu tượng dấu `+` nhấp nháy màu vàng rực rỡ; Tap chọn thuộc tính -&gt; Con số thuộc tính tăng lên kèm hiệu ứng sao sáng. `[OBSERVED]`

#### 6\. Điều hướng

* **Đi vào:** Tự động chuyển từ Battle Screen sau khi chiến đấu kết thúc.
* **Đi ra:** Tap `Continue` \-&gt; Chuyển cảnh trở lại World Map hoặc Doanh trại (Return to Camp). `[OFFICIAL] [OBSERVED]`

#### 7\. Bố trí thích ứng (Responsive Layout)

* **iPhone 15 Pro Max:** Bảng thống kê hiển thị đầy đủ 8-10 lính trên cùng một màn hình.
* **Màn hình ngang nhỏ hơn:** Bảng thống kê chuyển thành dạng danh sách cuộn dọc gọn gàng.

---

### 3.8\. Cài đặt &amp; Lưu/Tải game (Settings / Save-Load Screen)

#### 1\. Mục tiêu màn hình

Cho phép lưu game bất kỳ lúc nào (*Save Anytime*), tải game, tùy chỉnh âm thanh, điều khiển và ngôn ngữ. `[OFFICIAL]`

#### 2\. Bố cục &amp; Các khu vực UI chính

* **Dạng hiển thị:** Dialog Modal phủ mờ màn hình hiện tại (*Overlay Modal*).
* **Cột Tab Bên Trái:** `Game Save`, `Audio &amp; Graphics`, `Controls`, `Language`.
* **Khung Nội dung Bên Phải:**  
  * Tab `Game Save`: Nút `Save Game` (Save Anytime) `[OFFICIAL]`, Thông tin file Save hiện tại. `[UNKNOWN]`
  * Tab `Controls`: Toggle `WASD Camera Movement`, Toggle `Mouse Only Option`. `[OFFICIAL]`
  * Tab `Language`: Danh sách 10 Ngôn ngữ (Bao gồm Tiếng Việt, Tiếng Anh, Tiếng Nhật, Tiếng Trung). `[OFFICIAL]`

#### 3\. Thông tin hiển thị &amp; Thứ tự ưu tiên

1. Trạng thái Save thành công / Ngày giờ file save. `[OFFICIAL] [UNKNOWN]`
2. Danh sách tùy chọn cài đặt hệ thống. `[OFFICIAL]`

#### 4\. Thao tác chính của người chơi

* **Tap:** Tap chọn Tab, Tap nút `Save Game`, Tap chọn Ngôn ngữ, Tap nút `Close` (X). `[OFFICIAL]`
* **Kéo trượt (Slider):** Drag thanh trượt điều chỉnh âm lượng BGM và SFX. `[REMAKE UI DESIGN PROPOSAL]`

#### 5\. Phản hồi trực quan (Visual Feedback)

* *Lưu game thành công:* Xuất hiện thông báo Toast "Đã lưu game thành công!" màu xanh lá ở góc màn hình. `[REMAKE UI DESIGN PROPOSAL]`
* *Đổi ngôn ngữ:* Toàn bộ văn bản giao diện tức thì chuyển sang ngôn ngữ mới được chọn mà không cần khởi động lại. `[OFFICIAL]`

#### 6\. Điều hướng

* **Đi vào:** Tap nút Pause/Settings ở Top HUD hoặc Main Menu.
* **Đi ra:** Tap nút `Close` (X) -&gt; Đóng Modal, trở lại màn hình trước đó.

#### 7\. Bố trí thích ứng (Responsive Layout)

* Tự động căn giữa màn hình trên mọi kích thước thiết bị ngang với độ rộng fixed 80% Width / 85% Height.

---

## 4\. QUY CHUẨN THẢO TÁC CẢM ỨNG &amp; THÍCH ỨNG RESPONSIVE

### A. Quy chuẩn Thao tác Cảm ứng (Touch Interactions):

1. **Tap (Chạm ngắn):** Dùng cho chọn nút, chuyển tab, chọn lính, mở popup.
2. **Kéo - Thả (Drag-and-Drop):**  
  * Dùng cho gán lính vào công trình (Camp) và xếp đội hình trên lưới (Deploy).
  * Cần có phản hồi bóng mờ (*Ghost Widget*) hiển thị nhân vật đang được kéo theo ngón tay với Opacity 0.8.
3. **Vuốt / Pan (Swipe):** Dùng cho cuộn danh sách Roster và di chuyển góc nhìn camera trên World Map.
4. **Pinch-to-Zoom (Bóp/Mở 2 ngón):** Dùng cho thu phóng bản đồ World Map.

### B. Quy chuẩn Thích ứng Màn hình Ngang (Landscape Responsiveness):

* **Thiết bị Tham chiếu (iPhone 15 Pro Max - 932 x 430 pt):** Tận dụng tối đa không gian hiển thị rộng ngang, ưu tiên Layout 2 cột mở cố định (Side-by-Side view).
* **Thiết bị Ngang Nhỏ hơn (ví dụ: iPhone SE / Android Landscape 640 x 360 pt):**  
  * Tự động chuyển các bảng danh sách Side-by-Side thành dạng Drawer ẩn/hiển thị hoặc Modal Overlay.
  * Đảm bảo vùng an toàn (*SafeArea*) ở 2 bên thỏ ngọc / camera punch-hole không làm che lấp các nút bấm thao tác.

---

## 5\. PHÂN CẤP BẰNG CHỨNG XÁC MINH (EVIDENCE MATRIX)

| Màn hình          | Tính năng xác minh chính thức (`[OFFICIAL]`)                             | Chi tiết quan sát thực tế (`[OBSERVED]` / `[TRANSCRIPT]`)                                 | Đề xuất thiết kế bản Remake (`[REMAKE UI PROPOSAL]`) / Unknown (`[UNKNOWN]`)           |
| ----------------- | ------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| **Main Menu**     | 3 Chế độ chơi (Campaign, Sandbox, Arena)                                 | Nhập tên Commander/Army, chọn Portrait/Banner, chọn Background                            | Hiệu ứng Fade-in Modal 200ms, trạng thái Disable nút khi chưa nhập tên                 |
| **Camp**          | Kéo-thả lính, Nâng cấp trại, King's Satisfaction meter                   | 6 Công trình (Tents, Infirmary 3 slots, Altar, Training, Gravestone, Stash), 7 Tài nguyên | Roster Drawer thu gọn bên trái, bóng mờ Drag-and-drop ghost widget                     |
| **World Map**     | Bản đồ thế giới mở, Fog of War, Beasts, Thời tiết, Camera WASD           | Chỉ số March Points, các sự kiện ngẫu nhiên (Thầy bói/Con cáo), địa hình làm chậm         | Pinch-to-zoom thu phóng camera trên thiết bị di động                                   |
| **Town / Quests** | Nhiệm vụ phục vụ Vua, Hạn chót Days limit, Mua sắm &gt;50 vũ khí/giáp       | 4 Tab (Tavern, Blacksmith, Market, Quest Board), Giá thuê lính, Skull level 1-4           | Bố trí Layout 2 cột Side-by-Side trên màn hình iPhone 15 Pro Max                       |
| **Deploy**        | Xếp vị trí Autobattler, Nút Preset, Giới hạn quân số                     | Lưới Hàng trước (Frontline) / Hàng sau (Backline), Cự ly 4v4/6v6/8v8                      | Cảnh báo viền vàng khi đặt lính bắn cung ở Hàng trước                                  |
| **Battle**        | Autobattler tự động, Sừng chiến War Horn, Combat Log, Phạt thời tiết     | Thanh Tide of Battle, Máu/Morale trên đầu lính, đòn Hit/Miss/Critical, lính bỏ chạy       | Hiệu ứng Screen Shake nhẹ khi nổ đòn Critical Damage                                   |
| **Result**        | Tăng XP, Level Up, Tăng King's Satisfaction                              | Bảng thống kê Kills/Damage Dealt/Damage Taken, Rương Loot Chest, Nút `+` cộng điểm        | Hiệu ứng văng vật phẩm kèm âm thanh fanfare khi mở rương Loot                          |
| **Settings**      | Feature Save Anytime, Mouse Only, WASD Keys, 10 Ngôn ngữ (có Tiếng Việt) | Bảng Modal Popup phủ mờ màn hình                                                          | Thông báo Toast "Đã lưu game thành công!", Cấu trúc lưu save file internal `[UNKNOWN]` |