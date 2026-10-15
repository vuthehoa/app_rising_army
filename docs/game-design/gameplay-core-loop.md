# QUY TRÌNH VÒNG LẶP GAMEPLAY CỐT LÕI (GAMEPLAY CORE LOOP)

**Dự án:** Rising Army Remake (Flutter)  
**Tập tin mục tiêu:** `docs/game-design/gameplay-core-loop.md`

---

## TỔNG QUAN VÒNG LẶP (LOOP OVERVIEW)

Vòng lặp gameplay cốt lõi của **Rising Army** diễn ra theo chuỗi hành trình 7 bước tuần hoàn:

$$\\text{Camp} \\longrightarrow \\text{Map} \\longrightarrow \\text{Town/Quests} \\longrightarrow \\text{Deploy} \\longrightarrow \\text{Battle} \\longrightarrow \\text{Result} \\longrightarrow \\text{Return to Camp}$$

Mỗi bước đóng vai trò mắt xích kết nối giữa công tác chuẩn bị, quản lý kinh tế - tài nguyên và kiểm thử sức mạnh quân đoàn trên chiến trường.

---

## CHI TIẾT CÁC BƯỚC IN THE CORE LOOP

### 1\. Camp (Doanh trại)

* **Mục tiêu:** Quản lý quân đoàn, chữa trị lính bị thương, khôi phục thể lực và sĩ khí, huấn luyện thuộc tính, nâng cấp công trình và bảo đảm kinh tế duy trì trước khi xuất quân.
* **Hành động chính của người chơi:**  
  1. Sử dụng cơ chế kéo - thả (*Drag-and-Drop*) lính từ bảng quân đoàn thả vào các ô chức năng (*slots*) của công trình.
  2. Mở Bảng xây dựng (*Build Menu*) để xây mới hoặc nâng cấp công trình.
  3. Kiểm tra hồ sơ cá nhân lính (HP, Energy, Morale, thuộc tính Strength/Dexterity/Constitution) và phân bổ trang bị (Vũ khí, Khiên/Phụ kiện, Giáp).
  4. Nhấn nút `End Day` (Kết thúc ngày) để chuyển chu kỳ thời gian, kích hoạt quá trình chữa trị/nghỉ ngơi/huấn luyện qua đêm.
* **Tài nguyên, Trạng thái &amp; Hệ quả:**  
  * **Tài nguyên tiêu tốn:**  
    * Phí duy trì hàng ngày: Trừ **1 Gold + 1 Food** trên mỗi lính mỗi khi `End Day`.
    * Chi phí xây dựng/nâng cấp: Tiêu tốn Gold, Tools (Công cụ/Búa), Iron, Stone, Wood, Cloth.
  * **Trạng thái:**  
    * Lính gán vào *Infirmary* (Bệnh xá) được hồi phục HP qua đêm.
    * Lính gán vào *Tents* (Túp lều) hồi phục Energy và Morale.
    * Lính gán vào *Altar* (Bàn thờ/Đá cầu nguyện) khôi phục chỉ số Morale.
    * Lính gán vào *Training Fields* tiêu tốn Energy/Morale để tăng chỉ số Strength/Constitution.
    * Lính ở *Gravestone* (Mộ đá) có thể được hồi sinh bằng Gold (trở lại không có trang bị, HP/Stamina/Morale ở mức \~20%).
  * **Hệ quả:** Cạn kiệt Thức ăn hoặc Vàng khiến lính suy giảm sĩ khí. Nếu thước đo **King's Satisfaction** bị cạn kiệt, chiến dịch có thể kết thúc thất bại (*Game Over*). Công trình có thể bị rạn nứt/hỏng hóc ngẫu nhiên qua ngày.
* **Phân loại bằng chứng:**  
  * `[OFFICIAL]`: Kéo-thả lính vào công trình, nâng cấp công trình, thước đo King's Satisfaction meter, cơ chế Permadeath (tử trận vĩnh viễn).
  * `[OBSERVED]` / `[TRANSCRIPT]`: Tên cụ thể các công trình (Tents, Infirmary, Altar, Training Fields, Stash); 7 loại tài nguyên (Gold, Food, Tools, Iron, Stone, Wood, Cloth); Mức phí duy trì 1 Gold + 1 Food/lính/ngày; Sức chứa Bệnh xá = 3 lính.
  * `[COMMUNITY]`: Hồi sinh lính tại Gravestone bằng Gold (trở lại không có trang bị, HP/Stamina/Morale \~20%); công trình bị hỏng ngẫu nhiên qua ngày.
  * `[UNKNOWN]`: Công thức toán học chính xác của điểm hồi HP/Energy/Morale theo từng cấp độ công trình.

---

### 2\. Map (Bản đồ thế giới / Overworld)

* **Mục tiêu:** Điều khiển quân đoàn di chuyển trên bản đồ mở đến các mục tiêu nhiệm vụ, thị trấn, khám phá điểm tài nguyên dã ngoại và xử lý các sự kiện ngẫu nhiên.
* **Hành động chính của người chơi:**  
  1. Nhấp chọn vị trí đích đến trên bản đồ 2D (Thị trấn, Node sự kiện, Node cướp, Điểm nhặt tài nguyên).
  2. Điều khiển quân đoàn di chuyển mở rộng bán kính tầm nhìn (*Fog of War*).
  3. Nhặt các điểm tài nguyên dã ngoại xuất hiện trên đường đi (Gỗ, Đá, Sắt, Vàng).
  4. Tương tác với các hộp thoại sự kiện ngẫu nhiên (Thầy bói 4 mắt, Con cáo xin ăn, Đào đá ngẫu nhiên, Giếng ước).
  5. Nhấn `End Day` khi hết điểm di chuyển giữa đường.
* **Tài nguyên, Trạng thái &amp; Hệ quả:**  
  * **Tài nguyên tiêu tốn:** Tiêu tốn điểm **March Points** khi di chuyển. Địa hình khó (Mountains, Farmland) ngốn nhiều March Points hơn và làm chậm tốc độ.
  * **Trạng thái:** Tầm nhìn tròn xung quanh đội quân làm hé lộ các biểu tượng ẩn trong sương mù Fog of War.
  * **Hệ quả:** Nhặt tài nguyên bổ sung trực tiếp Wood, Stone, Iron, Gold vào kho đồ. Sự kiện ngẫu nhiên có thể đổi tài nguyên lấy chỉ số (ví dụ: mất 50 Gold nhận 15 Morale; mất 10 Food nhận 250 March Points). Trận đụng độ cướp (*Bandits*) hoặc Quái thú dã ngoại (*Wild Beasts*) kích hoạt màn hình Deploy. Thời tiết xấu gây phạt chỉ số lính khi vào chiến đấu.
* **Phân loại bằng chứng:**  
  * `[OFFICIAL]`: Khám phá bản đồ vùng/thế giới mở, đụng độ Quái thú dã ngoại (*Beasts*), Hệ thống thời tiết gây phạt đòn đánh, Điều khiển camera bằng phím WASD.
  * `[OBSERVED]` / `[TRANSCRIPT]`: Điểm di chuyển March Points; địa hình làm chậm di chuyển; các sự kiện cụ thể như Thầy bói, Con Cáo, Đào đá.
  * `[UNKNOWN]`: Tỷ lệ làm mới (Spawn rate) của các điểm nhặt tài nguyên và chướng ngại cướp trên bản đồ.

---

### 3\. Town / Quests (Thị trấn &amp; Nhiệm vụ)

* **Mục tiêu:** Tiếp nhận giao kèo/nhiệm vụ từ Nhà vua hoặc thị trấn để kiếm Vàng, Thức ăn và tăng điểm King's Satisfaction; tuyển dụng lính đánh thuê mới và mua sắm trang bị/nguyên liệu.
* **Hành động chính của người chơi:**  
  1. Di chuyển vào ô Thị trấn trên Map để mở Bảng quản lý Thị trấn.
  2. **Tavern (Quán rượu):** Xem danh sách lính khả thi (chỉ số Str/Dex/Con, vũ khí ban đầu, Morale) và chi Vàng thuê tuyển.
  3. **Blacksmith (Tiệm rèn):** Mua/bán trang bị (Vũ khí, Giáp các phẩm chất từ Thường đến Huyền thoại).
  4. **Market (Chợ):** Mua/bán nguyên liệu (Tools, Food, Wood, Stone, Cloth).
  5. **Quest Board (Bảng nhiệm vụ):** Xem danh sách nhiệm vụ (độ khó Skull, thời hạn ngày Days limit, phần thưởng) và chọn nhận.
* **Tài nguyên, Trạng thái &amp; Hệ quả:**  
  * **Tài nguyên:** Tiêu tốn Vàng khi thuê lính hoặc mua hàng hóa. Thưởng Vàng, Thức ăn, Đá, Gỗ, Tools, XP sau khi hoàn thành nhiệm vụ.
  * **Trạng thái:** Mũi tên chỉ hướng trên Map xuất hiện trỏ về vị trí mục tiêu nhiệm vụ.
  * **Hệ quả:** Hoàn thành nhiệm vụ tăng điểm **King's Satisfaction**. Thất bại hoặc trễ hạn (*Deadline* tính theo số ngày) làm giảm điểm King's Satisfaction, có thể gây Game Over nếu thanh này bị cạn kiệt.
* **Phân loại bằng chứng:**  
  * `[OFFICIAL]`: Nhiệm vụ phục vụ Vua, Thanh King's Satisfaction meter, Mua sắm trang bị (&gt;50 vũ khí, &gt;50 giáp).
  * `[OBSERVED]` / `[TRANSCRIPT]`: 3 khu vực chức năng trong thị trấn (Tavern, Blacksmith, Market); Giá thuê lính (\~14–20 Gold/lính); Mức độ khó Skull (1 Skull đến 4 Skull); Thời hạn nhiệm vụ tính theo số ngày.
  * `[UNKNOWN]`: Bảng thuật toán sinh ngẫu nhiên danh sách lính trong Tavern hoặc danh sách đồ trong Blacksmith theo tiến trình.

---

### 4\. Deploy (Bố trí đội hình xuất trận)

* **Mục tiêu:** Lựa chọn danh sách lính tối ưu, dàn xếp vị trí chiến thuật trên lưới đấu dựa trên tương quan lực lượng và đặc điểm kẻ địch.
* **Hành động chính của người chơi:**  
  1. Nhấp chọn node giao tranh trên Map để chuyển sang màn hình Deploy.
  2. Quan sát lực lượng địch và giới hạn quân số xuất trận (*Deploy limit*).
  3. Kéo-thả lính từ danh sách dự bị vào các ô lưới chiến thuật.
  4. Bố trí lính cận chiến/khiên đứng hàng trước (*Frontline*) và lính bắn cung đứng hàng sau (*Backline*).
  5. Cất lính bị thương nặng hoặc Morale thấp vào hàng dự bị nếu số lượng lính vượt quá giới hạn.
  6. Nhấn `Fight` / `Start Battle` để bắt đầu trận đấu.
* **Tài nguyên, Trạng thái &amp; Hệ quả:**  
  * **Trạng thái:** Số lượng lính tham chiến bị giới hạn bằng đúng hoặc theo tỷ lệ quy định của stage/số quân địch (ví dụ: 4v4, 6v6, 8v8, tối đa 9 lính).
  * **Hệ quả:** Xếp nhầm vị trí (để lính bắn cung đứng hàng đầu) khiến lính dễ bị tiêu diệt nhanh chóng, dẫn đến tử trận vĩnh viễn (*Permadeath*).
* **Phân loại bằng chứng:**  
  * `[OFFICIAL]`: Xếp đội hình Autobattler (*formation*), Preset đội hình.
  * `[OBSERVED]` / `[TRANSCRIPT]`: Lưới vị trí hàng trước/hàng sau; cất lính bị thương vào dự bị; giới hạn quân số tham chiến theo quy mô địch (4v4, 6v6, 8v8, tối đa 9 lính).
  * `[UNKNOWN]`: Logic xếp quân tự động của nút Preset sẵn có trong game.

---

### 5\. Battle (Tự động chiến đấu &amp; Tương tác giữa trận)

* **Mục tiêu:** Tiêu diệt toàn bộ lực lượng địch, bảo vệ binh sĩ đồng minh khỏi tử trận vĩnh viễn và giữ vững sĩ khí toàn đội.
* **Hành động chính của người chơi:**  
  1. Quan sát diễn biến giao tranh hoàn toàn tự động (*Autobattler*) của hai bên.
  2. Theo dõi các chỉ số đòn đánh nổi: Hit, Miss, Critical Damage.
  3. Theo dõi thanh cục diện trận đấu (*Tide of battle bar*) và thanh Morale lính.
  4. **Nhấn nút Sừng chiến (War Horn):** Kích hoạt kỹ năng chủ động Sừng chiến để tăng một lượng Morale nhỏ, ngăn lính hoảng sợ bỏ chạy (*flee/desert*) khi chịu áp lực.
  5. Mở Bảng Nhật ký chiến đấu (*Combat Log*) để xem chi tiết đòn đánh.
* **Tài nguyên, Trạng thái &amp; Hệ quả:**  
  * **Trạng thái:** Máu (HP) lính giảm trực tiếp; sprite lính hiển thị thương tật khi HP thấp. Morale giảm khi chịu đòn nặng hoặc thấy đồng đội tử trận. Thời tiết xấu (mưa, tuyết) gây phạt chỉ số đòn đánh.
  * **Hệ quả:**  
    * *Điều kiện Thắng:* Tiêu diệt sạch quân địch.
    * *Điều kiện Thua / Bỏ chạy:* Toàn bộ lính đồng minh bị hạ gục hoặc bỏ chạy khỏi trận do vỡ Morale. Trong chế độ Sandbox Mode, hết quân đồng nghĩa với Game Over ngay lập tức.
    * *Tử trận (Permadeath):* Binh sĩ ngã xuống không được cứu chữa sẽ bị mất vĩnh viễn cùng toàn bộ trang bị mang theo.
* **Phân loại bằng chứng:**  
  * `[OFFICIAL]`: Cơ chế Autobattler tự động, Permadeath (tử trận vĩnh viễn), Kỹ năng Sừng chiến War Horn, Combat Log, Phạt thời tiết, Sandbox Mode quy tắc hết quân = Game Over lập tức.
  * `[OBSERVED]` / `[TRANSCRIPT]`: Thanh Tide of battle bar; hiển thị chữ Critical/Miss nổi; lính bỏ chạy khi vỡ sĩ khí.
  * `[UNKNOWN]`: Công thức toán học tính sát thương chính xác và tỷ lệ né đòn (Evasion formula).

---

### 6\. Result (Màn hình tổng kết &amp; Phần thưởng)

* **Mục tiêu:** Đánh giá hiệu suất trận đấu, phân bổ điểm kinh nghiệm (XP), thu thập vật phẩm thưởng từ rương Loot và cập nhật tiến trình chiến dịch.
* **Hành động chính của người chơi:**  
  1. Xem Bảng thống kê chi tiết trận đấu: Kills (Mạng diệt), Damage Dealt (Sát thương gây ra), Damage Taken (Sát thương nhận vào).
  2. Kiểm tra XP nhận được và biểu tượng Lên cấp (*Level Up*) trên lính.
  3. Nhấn dấu `+` bên cạnh thuộc tính muốn tăng (Strength / Dexterity / Constitution) khi lính lên cấp.
  4. Mở Rương thưởng (*Loot Chest*) nhận Vàng, Thức ăn, Đá, Gỗ, Tools, Vải và Trang bị ngẫu nhiên.
  5. Dùng Thuốc cứu hộ (nếu có) để hồi sinh lính vừa ngã xuống.
  6. Nhấn `Continue` để chuyển cảnh trở lại Map / Camp.
* **Tài nguyên, Trạng thái &amp; Hệ quả:**  
  * **Tài nguyên:** Thu nhận Vàng, Thức ăn, Đá, Gỗ, Búa, Vải và Trang bị rơi ngẫu nhiên.
  * **Trạng thái:** Tăng điểm **King's Satisfaction** nếu trận đấu hoàn thành nhiệm vụ của Vua.
  * **Hệ quả:** Mức HP còn lại, thể lực tiêu hao và morale dư sau trận được cập nhật vào dữ liệu lính. Lính tử trận không được cứu sẽ bị xóa khỏi danh sách lực lượng.
* **Phân loại bằng chứng:**  
  * `[OFFICIAL]`: Tăng XP &amp; Lên cấp, Tăng điểm King's Satisfaction, Sửa lỗi đơ màn hình sau trận khi unlock Title (Patch 1.0.5).
  * `[OBSERVED]` / `[TRANSCRIPT]`: Bảng thống kê 3 cột Kills / Damage Dealt / Damage Taken; Cộng thuộc tính thủ công khi Level Up; Mở rương thưởng Loot Chest; Thuốc cứu hộ lính ngã xuống.
  * `[UNKNOWN]`: Thuật toán tỷ lệ rơi đồ (Drop Rate) của các trang bị Rare/Legendary từ Rương thưởng.

---

### 7\. Return to Camp (Phục hồi &amp; Chuẩn bị chu kỳ mới)

* **Mục tiêu:** Khắc phục thương vong sau trận, đưa lính bị thương vào Bệnh xá, tái cấu trúc đội hình, bảo trì công trình và sẵn sàng cho nhiệm vụ tiếp theo.
* **Hành động chính của người chơi:**  
  1. Đưa lính bị thương nặng vào Bệnh xá (*Infirmary*).
  2. Đưa lính hoảng sợ vào Bàn thờ (*Altar*) để khôi phục Morale.
  3. Đưa lính kiệt sức vào Túp lều (*Tents*) để hồi Energy.
  4. Đến Mộ đá (*Gravestone*) dùng Vàng hồi sinh lính tử trận (lính sống lại không còn trang bị, HP/Stamina/Morale \~20%).
  5. Dùng Tools và nguyên liệu sửa chữa các công trình bị hỏng hóc.
  6. Mua bán trang bị/nguyên liệu thừa ở Chợ/Blacksmith để cân bằng tài chính.
  7. Nhấn `End Day` để khép lại chu kỳ và chuẩn bị bước vào lượt di chuyển Map mới.
* **Tài nguyên, Trạng thái &amp; Hệ quả:**  
  * Trạng thái toàn bộ quân đoàn được đồng bộ và lưu trữ (hỗ trợ tính năng *Save Anytime*).
  * Khép kín hoàn toàn chu kỳ vòng lặp cốt lõi: `Camp → Map → Town/Quests → Deploy → Battle → Result → Return to Camp`.
* **Phân loại bằng chứng:**  
  * `[OFFICIAL]`: Vòng lặp quản lý trại và chiến đấu liên tục, Save Anytime.
  * `[OBSERVED]` / `[TRANSCRIPT]`: Quy trình chữa thương trong Infirmary; Chu kỳ End Day lặp lại.
  * `[COMMUNITY]`: Hồi sinh lính tại Gravestone (\~20% HP/Morale/Stamina, mất trang bị); sự cố hỏng hóc công trình ngẫu nhiên qua ngày.
  * `[UNKNOWN]`: Số lượng slot lưu game, cơ chế Autosave và công thức tỷ lệ sự cố hỏng hóc công trình.

---

## BẢNG TÓM TẮT PHÂN CẤP BẰNG CHỨNG HỆ THỐNG VÒNG LẶP

| Bước trong Loop        | Yếu tố xác minh chính thức (`[OFFICIAL]`)                                                                                                  | Yếu tố quan sát thực tế (`[OBSERVED]` / `[TRANSCRIPT]` / `[COMMUNITY]`)                                                                                                                                                                                      | Yếu tố chưa rõ (`[UNKNOWN]`)                                                |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------- |
| **1\. Camp**           | Kéo-thả lính vào công trình, Nâng cấp trại, King's Satisfaction meter, Permadeath (tử trận vĩnh viễn)                                      | Tents, Infirmary (3 slots), Altar, Training Fields, Stash `[OBSERVED]`; 7 loại tài nguyên `[OBSERVED]`; Phí duy trì 1 Gold + 1 Food/ngày `[OBSERVED]`; Gravestone hồi sinh (\~20% HP/Morale, mất đồ) `[COMMUNITY]`; Công trình hỏng ngẫu nhiên `[COMMUNITY]` | Công thức toán hồi HP/Energy/Morale chi tiết từng cấp công trình            |
| **2\. Map**            | Khám phá bản đồ thế giới mở, Quái thú dã ngoại (*Beasts*), Phạt thời tiết, Camera WASD                                                     | Điểm di chuyển March Points `[OBSERVED]`, Sương mù Fog of War `[OBSERVED]`, Địa hình làm chậm `[OBSERVED]`, Các sự kiện cụ thể (Thầy bói, Con cáo, Đào đá) `[TRANSCRIPT]`                                                                                    | Tỷ lệ xuất hiện ngẫu nhiên (Spawn rate) của tài nguyên/cướp dã ngoại        |
| **3\. Town/Quests**    | Nhiệm vụ phục vụ Vua, Thanh King's Satisfaction meter, Mua sắm &gt;50 vũ khí &amp; 50 giáp                                                        | 3 khu vực (Tavern, Blacksmith, Market) `[OBSERVED]`; Giá thuê lính \~14–20 Gold `[TRANSCRIPT]`; Cấp độ khó 1–4 Skulls `[TRANSCRIPT]`; Hạn chót nhiệm vụ tính theo ngày `[TRANSCRIPT]`                                                                        | Bảng công thức thuật toán sinh ngẫu nhiên danh sách lính/đồ trong cửa hàng  |
| **4\. Deploy**         | Dàn vị trí Autobattler, Preset đội hình                                                                                                    | Lưới vị trí hàng trước (cận chiến/khiên) / hàng sau (cung) `[OBSERVED]`; Cất lính bị thương vào dự bị `[OBSERVED]`; Mức quân số 4v4, 6v6, 8v8, tối đa 9 lính `[TRANSCRIPT]`                                                                                  | Logic thuật toán tự động xếp quân của nút Preset                            |
| **5\. Battle**         | Autobattler tự động, Permadeath (tử trận vĩnh viễn), Kỹ năng Sừng chiến War Horn, Combat Log, Phạt thời tiết, Sandbox hết quân = Game Over | Thanh Tide of battle `[OBSERVED]`; Chữ Critical/Miss nổi `[OBSERVED]`; Lính bỏ chạy khi vỡ Morale `[TRANSCRIPT]`                                                                                                                                             | Công thức toán tính sát thương chi tiết &amp; Tỷ lệ né đòn (Evasion formula)    |
| **6\. Result**         | Tăng XP &amp; Level Up, Tăng King's Satisfaction, Sửa lỗi đơ màn hình sau trận (Patch 1.0.5)                                                   | Bảng thống kê 3 cột Kills / Damage Dealt / Damage Taken `[OBSERVED]`; Cộng thuộc tính thủ công khi Level Up `[TRANSCRIPT]`; Rương thưởng Loot Chest `[OBSERVED]`                                                                                             | Thuật toán tỷ lệ rơi đồ (Drop Rate) của trang bị Rare/Legendary từ rương    |
| **7\. Return to Camp** | Khép kín vòng lặp quản lý &amp; chiến đấu, Save Anytime                                                                                        | Quy trình chữa thương trong Infirmary `[OBSERVED]`; Chu kỳ End Day lặp lại `[OBSERVED]`; Hồi sinh tại Gravestone `[COMMUNITY]`                                                                                                                               | Số lượng slot lưu game, cơ chế Autosave và tỷ lệ hỏng công trình ngẫu nhiên |