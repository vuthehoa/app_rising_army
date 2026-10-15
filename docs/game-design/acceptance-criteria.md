# TIÊU CHÍ NGHIỆM THU TÍNH NĂNG (ACCEPTANCE CRITERIA)

**Dự án:** Rising Army Remake (Flutter iOS - Landscape)  
**Mục tiêu:** Định nghĩa tiêu chí nghiệm thu chi tiết, có thể kiểm thử (Testable AC) cho Codex/Claude Code và QA  
**Đường dẫn tập tin:** `docs/game-design/acceptance-criteria.md`

---

## MỤC LỤC

1. [Quy tắc Tiêu chí Nghiệm thu (Acceptance Criteria Rules)](#1-quy-t%E1%BA%AFc-ti%C3%AAu-ch%C3%AD-nghi%E1%BB%87m-thu-acceptance-criteria-rules)
2. [Main Menu &amp; New Game](#2-main-menu--new-game)
3. [Camp (Doanh trại)](#3-camp-doanh-tr%E1%BA%A1i)
4. [World Map (Bản đồ thế giới)](#4-world-map-b%E1%BA%A3n-%C4%91%E1%BB%93-th%E1%BA%BF-gi%E1%BB%9Bi)
5. [Town &amp; Quest (Thị trấn &amp; Nhiệm vụ)](#5-town--quest-th%E1%BB%8B-tr%E1%BA%A5n--nhi%E1%BB%87m-v%E1%BB%A5)
6. [Deployment (Bố trí đội hình)](#6-deployment-b%E1%BB%91-tr%C3%AD-%C4%91%E1%BB%99i-h%C3%ACnh)
7. [Battle &amp; Result (Chiến đấu &amp; Kết quả)](#7-battle--result-chi%E1%BA%BFn-%C4%91%E1%BA%A5u--k%E1%BA%BFt-qu%E1%BA%A3)
8. [Progression &amp; Game Modes (Tiến trình &amp; Chế độ chơi)](#8-progression--game-modes-ti%E1%BA%BFn-tr%C3%ACnh--ch%E1%BA%BF-%C4%91%E1%BB%99-ch%C6%A1i)
9. [Save / Load System](#9-save--load-system)
10. [UI/UX &amp; Responsive Layout](#10-uiux--responsive-layout)
11. [Ma trận Kiểm thử QA (QA Test Matrix)](#11-ma-tr%E1%BA%ADn-ki%E1%BB%83m-th%E1%BB%AD-qa-qa-test-matrix)
12. [Định nghĩa Hoàn thành (Definition of Done)](#12-%C4%91%E1%BB%8Bnh-ngh%C4%A9a-ho%C3%A0n-th%C3%A0nh-definition-of-done)

---

## 1\. QUY TẮC TIÊU CHÍ NGHIỆM THU (ACCEPTANCE CRITERIA RULES)

Để bảo đảm tính minh bạch giữa các tính năng đã xác minh từ game gốc và các cải tiến dành riêng cho bản Remake, toàn bộ Tiêu chí Nghiệm thu (AC) phải tuân thủ các nhãn bằng chứng bắt buộc sau:

* **`[OFFICIAL]`**: Yêu cầu dựa trên tính năng do nhà phát triển Arkbits công bố chính thức (Steam Store, News, Patch Notes).
* **`[OBSERVED]` / `[TRANSCRIPT]`**: Yêu cầu dựa trên hình ảnh/phụ đề từ video gameplay thực tế (AboboKnows, NguyeZ Gaming).
* **`[COMMUNITY]`**: Yêu cầu dựa trên ghi nhận từ cộng đồng người chơi (Steam Discussions, Reddit).
* **`[PROPOSED]` / `[REMAKE PROPOSAL]`**: Yêu cầu do đội ngũ Remake đề xuất để tối ưu hóa trải nghiệm di động/iOS.
* **`[UNKNOWN]`**: Các chi tiết chưa đủ bằng chứng, cần kiểm thử đo đạc thêm và không được coi là đã hoàn thành khi chưa chốt logic.

### Nhãn trạng thái triển khai (đối chiếu với source, cập nhật theo TASK-003)

Ngoài nhãn bằng chứng ở trên (nguồn của yêu cầu), mỗi tiêu chí có thể mang thêm nhãn **trạng thái triển khai**. Source và test hiện tại là căn cứ xác định hành vi đang tồn tại:

* **`[CURRENT]`**: hành vi đã được xác minh trong source (có dẫn file/phương thức).
* **`[PLANNED]`**: mục tiêu thiết kế, **chưa** được triển khai. Không coi là tính năng hiện có.
* **`[UNVERIFIED]`**: chưa đủ bằng chứng trong source/test để kết luận.

Quy ước: nhãn `[VERIFIED]` trong tài liệu này chỉ được dùng khi có bằng chứng source hoặc test cụ thể. Các nhãn `[VERIFIED]` cũ không kèm bằng chứng đã được thay bằng nhãn trạng thái ở trên. Tiêu chí thiết kế **không** bị đổi thành tiêu chí hiện trạng chỉ để khớp source: phần chưa có được giữ nguyên dưới nhãn `[PLANNED]`.

**Định dạng chuẩn:** Mọi Tiêu chí Nghiệm thu phải trình bày theo cấu trúc **Given / When / Then** hoặc **Các bước thực hiện $\\rightarrow$ Kết quả mong đợi**.

---

## 2\. MAIN MENU &amp; NEW GAME

### AC-MENU-01: Khởi tạo New Campaign (`[OFFICIAL]` `[TRANSCRIPT]`)

* **Given:** Người chơi đang ở Màn hình chính và nhấn nút `New Campaign`.
* **When:** Người chơi điền `Commander's Name`, `Army's Name`, chọn `Avatar`, `Banner Symbol`, `Theme Color`, chọn `Background` (Full Hero / Plebs) và bấm `Start`.
* **Then:**  
  1. System tạo một `CampaignState` mới với dữ liệu khởi tạo chính xác:  
    * Background `Full Hero`: `kingsSatisfaction` cao hơn, `gold` ít hơn `[TRANSCRIPT]`.
    * Background `Plebs`: `gold` nhiều hơn, `kingsSatisfaction` thấp hơn `[TRANSCRIPT]`.
  2. Khởi tạo đội hình 5–6 lính mặc định `[TRANSCRIPT]`.

* **Trạng thái triển khai:**
  * `[CURRENT]` Ván mới có `startRoster = 6` lính (`GameRules.startRoster`, `lib/domain/rules.dart:163`), `kingSatisfaction = 50` và tài nguyên khởi đầu cố định (`StartingEconomy.resources`, `lib/domain/economy.dart:18`; ví dụ 50 vàng). Danh tính người chơi gồm avatar, cờ và tên quân đoàn (`PlayerIdentity`, `lib/domain/identity.dart:127`).
  * `[UNVERIFIED]` Lựa chọn Background `Full Hero` / `Plebs` và việc nó đổi vàng/King's Satisfaction ban đầu: không thấy trong `PlayerIdentity` hay `GameRules.newGame`. Chưa xác nhận trong UI.
  * `[UNVERIFIED]` Màn hình giới thiệu cốt truyện (Backstory Panel): có `lib/presentation/screens/intro_screen.dart` nhưng chưa đối chiếu nội dung.
  3. Chuyển cảnh sang màn hình giới thiệu cốt truyện (*Backstory Panel*) rồi vào Doanh trại (`CampScreen`) `[TRANSCRIPT]`.

### AC-MENU-02: Lựa chọn Chế độ chơi (`[OFFICIAL]`)

* **Given:** Người chơi ở Menu chọn chế độ.
* **When:** Người chơi chọn 1 trong 3 chế độ: `Campaign`, `Sandbox`, hoặc `Arena`.
* **Then:**  
  1. `Campaign Mode`: Khởi tạo luồng chiến dịch chuẩn với King's Satisfaction meter `[OFFICIAL]`.
  2. `Sandbox Mode`: Khởi tạo chế độ chơi tự do; kích hoạt quy tắc "hết quân = Game Over lập tức" `[OFFICIAL]`.
  3. `Arena Mode`: Hiển thị danh sách 10 kịch bản thuần chiến đấu, ẩn hoàn toàn Doanh trại và Quản lý `[OFFICIAL]`.

* **Trạng thái triển khai:** `[PLANNED]` Chưa có chế độ chọn. `GameState` không có trường `gameMode` (`lib/domain/models.dart`, `GameState.toJson`); chỉ có luồng Campaign. Sandbox và Arena chưa được triển khai.

### AC-MENU-03: Tiếp tục Chiến dịch (`Continue`) (`[OFFICIAL]`)

* **Given:** Người chơi có một file Save slot hợp lệ trên thiết bị.
* **When:** Nhấn nút `Continue` từ Main Menu.
* **Then:** Hệ thống đọc `SaveEnvelope v3`, xác minh Checksum và khôi phục chính xác trạng thái tại thời điểm lưu gần nhất `[OFFICIAL]`.
* **Trạng thái triển khai:** `[CURRENT]` `SaveRepository.load()` đọc phong bì `{version, checksum, data}` (version hiện hành = 3), kiểm checksum **FNV-1a 32-bit** (không phải SHA-256) và dựng `GameState` (`lib/data/save_repository.dart`). Chi tiết ở `game-state-and-save-system.md`. Ghi chú: trạng thái là `GameState`, không có lớp `CampaignState`.

---

## 3\. CAMP (DOANH TRẠI)

### AC-CAMP-01: Phân công Lính bằng Drag-and-Drop (`[OFFICIAL]` `[OBSERVED]`)

* **Given:** Lính đang ở trạng thái Roster rảnh rỗi.
* **When:** Người người kéo thẻ lính và thả vào slot trống của một công trình trong Camp.
* **Then:**  
  1. Binh sĩ được gán vào công trình đó và cập nhật trạng thái UI ngay lập tức `[OFFICIAL]`.
  2. Thả vào `Infirmary`: Đánh dấu lính nằm viện chữa HP qua đêm (tối đa 3 slots) `[OBSERVED]`.
  2. Thả vào `Tents`: Đánh dấu lính nghỉ ngơi hồi Energy/Morale `[OBSERVED]`.
  4. Thả vào `Altar`: Đánh dấu lính cầu nguyện hồi Morale `[OBSERVED]`.
  5. Thả vào `Training Fields`: Đánh dấu lính luyện tập tăng Strength/Constitution `[OBSERVED]`.

* **Trạng thái triển khai:**
  * `[CURRENT]` Kéo-thả gán lính vào công trình có trong source. Các `FacilityType` thật: `meleeYard`, `archeryRange`, `enduranceYard`, `infirmary`, `storageChest`, `gravestone`, `barracks` (`lib/domain/models.dart:38`). Mỗi công trình nhận lính có 3 chỗ (6 ở cấp 2): `Facility.capacity = 3`, `upgradedCapacity = 6` (`models.dart`, class `Facility`).
  * `[CURRENT]` `infirmary` ("Lều cứu thương") tác dụng hồi HP và Energy; `meleeYard`, `archeryRange` huấn luyện chỉ số (`facilityEffects`, `lib/domain/building_effects.dart`). Hồi Energy/Morale qua đêm gắn với `barracks` (`facilityEffects[FacilityType.barracks]`).
  * `[PLANNED]` Công trình tên `Tents` và `Altar` **không tồn tại** trong source. Mục 3, 4 ở trên là mô tả thiết kế, không phải hiện trạng.

### AC-CAMP-02: Chuyển chu kỳ Ngày (`End Day`) (`[OFFICIAL]` `[TRANSCRIPT]`)

* **Given:** Người chơi đã hoàn tất phân công lính trong Camp.
* **When:** Nhấn nút `End Day`.
* **Then:**  
  1. `currentDay` tăng lên +1 `[TRANSCRIPT]`.
  2. Khấu trừ tự động chi phí duy trì cho quân đoàn `[TRANSCRIPT]`. *(Hiện trạng `[CURRENT]`: chi phí theo cấp từng lính, xem bên dưới; không còn là 1 Gold + 1 Food cố định.)*
  3. Cập nhật chỉ số HP/Energy/Morale/Stats cho lính dựa trên công trình được gán qua đêm `[OBSERVED]`.
  4. Nếu thiếu Thức ăn hoặc Vàng duy trì, Morale lính bị suy giảm `[TRANSCRIPT]`.
  5. Trong Campaign Mode, nếu thanh `King's Satisfaction` bị rỗng (bằng 0), kích hoạt màn hình Game Over `[OFFICIAL]`.

* **Trạng thái triển khai:**
  * `[CURRENT]` Upkeep theo cấp binh sĩ: vàng và lương mỗi ngày `{1:1, 2:1, 3:1, 4:2, 5:2, 6:3}`, cấp ≥ 6 dùng mức cấp 6 (`UpkeepEconomy`, `lib/domain/economy.dart:105`; tổng bằng `UpkeepEconomy.forSoldiers`, gọi từ `lib/domain/rules.dart:1774`). Có `paidUpkeep` khi thiếu tài nguyên (`DayReport`, `rules.dart:127-131`).
  * `[CURRENT]` Game Over khi `kingSatisfaction <= 0 && !victory` (getter `GameState.gameOver`, `models.dart:708`).
  * `[UNVERIFIED]` Mức giảm Morale chính xác khi thiếu Food/Vàng chưa được đối chiếu trong lượt này.

### AC-CAMP-03: Hồi sinh Lính tại Gravestone (`[COMMUNITY]`)

* **Given:** Binh sĩ đã tử trận trong trận đấu trước và có tên trong Gravestone.
* **When:** Người chơi chọn lính tử trận và trả chi phí Vàng để hồi sinh.
* **Then:** Binh sĩ trở lại Roster với trang bị bị xóa trống, HP/Stamina/Morale ở mức \~20% `[COMMUNITY]`.
* **Trạng thái triển khai:** `[CURRENT]` khác với mô tả trên. `GameRules.reviveSoldier` (`lib/domain/rules.dart:639`) yêu cầu đã xây Bia mộ, còn chỗ trong roster (`rosterCap`), trả vàng (`reviveCost`); binh sĩ hồi sinh với **HP = 1**, năng lượng/tinh thần **giữ nguyên**, `needsTreatment = true` và phải chữa ở Lều cứu thương. `[UNVERIFIED]` việc trang bị có bị xóa hay không.

---

## 4\. WORLD MAP (BẢN ĐỒ THẾ GIỚI)

### AC-MAP-01: Di chuyển Quân đoàn &amp; Tiêu hao March Points (`[OFFICIAL]` `[TRANSCRIPT]`)

* **Given:** Quân đoàn ở trên bản đồ thế giới với số điểm `March Points` hiện có.
* **When:** Người chơi nhấp chọn một ô/node đích trên bản đồ.
* **Then:**  
  1. Quân đoàn di chuyển theo đường dẫn, mở rộng bán kính sương mù `Fog of War` `[TRANSCRIPT]`.
  2. `March Points` bị trừ tương ứng với khoảng cách và loại địa hình (Núi/Ruộng tốn nhiều điểm hơn) `[TRANSCRIPT]`.
  3. Nếu hết `March Points` giữa đường, buộc người người nhấn `End Day` để hồi điểm di chuyển `[TRANSCRIPT]`.

* **Trạng thái triển khai:** `[CURRENT]` Cơ chế tương đương nhưng tên và số liệu khác: thể lực di chuyển (`HeroState.stamina`, tối đa `TerrainRules.maxStamina = 100`), chi phí = `baseCostPerUnit (0.05) × hệ số địa hình`; rừng thưa 1,6, rừng rậm 2,3, đồi 1,8, sườn núi 3,2, cầu 0,8; vách đá và mặt nước không đi được (`lib/domain/terrain_type.dart`). `[UNVERIFIED]` Fog of War theo nghĩa bán kính sương mù: save có `explored`, chưa đối chiếu cơ chế hiển thị.

### AC-MAP-02: Tương tác Sự kiện Dã ngoại &amp; Đụng độ (`[OFFICIAL]` `[TRANSCRIPT]`)

* **Given:** Quân đoàn đi qua ô tài nguyên, sự kiện ngẫu nhiên hoặc gặp kẻ địch.
* **When:** Đội quân va chạm vào node sự kiện.
* **Then:**  
  1. Node Tài nguyên: Cộng trực tiếp Wood/Stone/Iron/Gold vào kho `[TRANSCRIPT]`.
  2. Node Sự kiện (Thầy bói/Con cáo/Đào đá): Hiển thị Dialog lựa chọn và trao đổi tài nguyên/chỉ số `[TRANSCRIPT]`.
  3. Node Quái thú (`Wild Beasts`) / Cướp (`Bandits`): Chuyển cảnh sang Màn hình Bố trí Đội hình (`DeployScreen`) `[OFFICIAL]`.

---

## 5\. TOWN &amp; QUEST (THỊ TRẤN &amp; NHIỆM VỤ)

### AC-TOWN-01: Tuyển dụng Lính tại Tavern (`[OBSERVED]` `[TRANSCRIPT]`)

* **Given:** Người chơi ở giao diện Thị trấn, mở tab `Tavern`.
* **When:** Kiểm tra chỉ số/trang bị của lính tự do và nhấn nút Thuê (chi \~14–20 Gold).
* **Then:**  
  1. Vàng bị trừ tương ứng với giá thuê `[TRANSCRIPT]`.
  2. Binh sĩ mới được thêm vào Roster quân đoàn (không vượt quá sức chứa tối đa của quân đoàn) `[OFFICIAL]`.
  3. Nếu Roster đã đủ sức chứa hoặc thiếu Vàng, nút Thuê bị vô hiệu hóa (Disabled) `[PROPOSED]`.

* **Trạng thái triển khai:**
  * `[CURRENT]` Sức chứa quân đoàn là `rosterCap = 6 + 4 × cấp Doanh trại` (`GameRules.rosterCap`, `lib/domain/rules.dart:321`), **không phải 20 cố định**. Tuyển mộ bị chặn khi đầy ("Doanh trại đã đầy", `rules.dart:451`); hồi sinh cũng bị chặn (`rules.dart:649`). Giá thuê tính bằng công thức (`HireEconomy`, `economy.dart:~140`; ứng viên tối đa cấp 3), không phải khoảng 14–20 vàng cố định.
  * `[UNVERIFIED]` Con số 20 lính tối đa của game gốc (`[OFFICIAL]` theo Steam) không được source áp dụng; chưa xác định có phải đặt trần 20 hay không. Cần quyết định thiết kế.
  * `[UNVERIFIED]` Việc nút Thuê bị vô hiệu hóa trên UI (so với chỉ trả lỗi từ luật) chưa được kiểm trong lượt này.

### AC-TOWN-02: Nhận &amp; Hoàn thành Nhiệm vụ (`[OFFICIAL]` `[TRANSCRIPT]`)

* **Given:** Bảng nhiệm vụ (`Quest Board`) hiển thị danh sách giao kèo.
* **When:** Người chơi chọn nhận nhiệm vụ có độ khó 1–4 Skulls và thời hạn `Days limit`.
* **Then:**  
  1. Xuất hiện Mũi tên định hướng trên Map trỏ về vị trí mục tiêu `[TRANSCRIPT]`.
  2. Khi tiêu diệt mục tiêu trước deadline: Cộng Vàng, Thức ăn, Tài nguyên, XP và **tăng điểm King's Satisfaction** `[OFFICIAL]`.
  3. Khi trễ deadline mà chưa hoàn thành: Nhiệm vụ thất bại, **trừ điểm King's Satisfaction** `[OFFICIAL]`.

---

## 6\. DEPLOYMENT (BỐ TRÍ ĐỘI HÌNH)

### AC-DEP-01: Dàn xếp Ô Lưới Chiến thuật (`[OFFICIAL]` `[OBSERVED]`)

* **Given:** Người chơi bước vào Màn hình Deploy trước trận chiến.
* **When:** Kéo lính từ danh sách dự bị vào các ô lưới hàng trước (*Frontline*) hoặc hàng sau (*Backline*).
* **Then:**  
  1. Đơn vị được xếp vào đúng ô lưới đã chọn `[OBSERVED]`.
  2. Số lượng lính xuất trận bị khống chế theo giới hạn trận đấu (ví dụ: 4v4, 6v6, 8v8, tối đa 9 lính) `[OBSERVED]`.
  3. Cho phép sử dụng nút `Preset` để tự động xếp đội hình nhanh `[OFFICIAL]`.
  4. Nhấn `Start Battle`: Đồng bộ đội hình vào `BattleSimulationEngine` và bắt đầu trận đấu `[OFFICIAL]`.

* **Trạng thái triển khai:**
  * `[CURRENT]` Đội ra trận tối đa **10** binh sĩ (`GameRules.maxSquad`, `rules.dart:159`; chặn ở `rules.dart:2243`); đội rỗng và id trùng bị từ chối. Mốc 9 lính ở trên là quan sát từ game gốc, không phải giới hạn của source.
  * `[CURRENT]` Có 4 preset `FormationPreset {line, expanded, wedge, cluster}` (`lib/domain/battle.dart:423`) với `presetPlacement` và nút xếp tự động trong `lib/presentation/screens/deploy_screen.dart`. Xem `deployment-and-formation.md`.
  * `[UNVERIFIED]` Lưới hàng trước / hàng sau theo nghề và tên `BattleSimulationEngine`: source dùng hàm `simulateBattle(players, enemies, seed)` (`battle.dart:227`), không có lớp tên đó.

---

## 7\. BATTLE &amp; RESULT (CHIẾN ĐẤU &amp; KẾT QUẢ)

### AC-BAT-01: Động cơ Autobattler &amp; Sừng chiến War Horn (`[OFFICIAL]`)

* **Given:** Trận đấu Autobattler đang diễn ra tự động theo nhịp Ticks (10 Hz).
* **When:** Người người theo dõi đòn đánh (Hit/Miss/Critical) và nhấn nút **War Horn (Sừng chiến)** khi cooldown đã sẵn sàng.
* **Then:**  
  1. Đơn vị tự động di chuyển, tìm mục tiêu và tấn công theo chỉ số `[OFFICIAL]`.
  2. Nút War Horn phát hiệu ứng âm thanh/hình ảnh và tăng ngay một lượng Morale cho toàn bộ binh sĩ đồng minh `[OFFICIAL]`.
  3. Bảng `Combat Log` ghi lại chi tiết các lượt đòn đánh và sát thương `[OFFICIAL]`.
  4. Hiệu ứng Thời tiết (Mưa/Tuyết) áp dụng hình phạt trúng đòn lên đơn vị `[OFFICIAL]`.

* **Trạng thái triển khai:**
  * `[CURRENT]` Mô phỏng thời gian thực với bước 0,1 giây (`stepSeconds`, `battle.dart:19`), đơn vị tự tìm mục tiêu gần nhất và tấn công; mỗi đòn sinh `BattleEvent` có `hit`, `crit`, `damage`, `killed` (`battle.dart:144`). Trần `maxBattleSeconds = 120` (`battle.dart:21`).
  * `[PLANNED]` **War Horn (Sừng chiến)**: chưa triển khai. Không có mã tương ứng trong `lib/` hay `test/`.
  * `[PLANNED]` **Thời tiết / phạt do mưa tuyết**: chưa triển khai trong `lib/domain/`.
  * `[UNVERIFIED]` Combat Log dạng bảng có chữ: source có danh sách `BattleEvent`; chưa xác nhận UI hiển thị log như mô tả.

### AC-BAT-02: Permadeath &amp; Thương tật sau Trận (`[OFFICIAL]` `[TRANSCRIPT]`)

* **Given:** Trận đấu kết thúc (Toàn bộ địch bị tiêu diệt = Thắng; Toàn bộ lính đồng minh chết/bỏ chạy = Thua).
* **When:** Chuyển sang Màn hình Tổng kết (`ResultScreen`).
* **Then:**  
  1. Hiển thị bảng Báo cáo Kills, Damage Dealt, Damage Taken của từng lính `[TRANSCRIPT]`.
  2. Phân bổ XP và hiển thị icon `Level Up` cho lính đủ điều kiện `[OFFICIAL]`.
  3. Lính bị cạn HP trong trận: Đánh dấu `isInjured` hoặc `isDead`. Binh sĩ ngã xuống không dùng Thuốc cứu hộ sẽ bị xóa vĩnh viễn (`Permadeath`) khỏi Roster `[OFFICIAL]`.

* **Trạng thái triển khai:**
  * `[CURRENT]` Kết quả trận `Winner {player, enemy, draw}`; `draw` khi hết `maxBattleSeconds` mà hai bên còn quân (`battle.dart`, cuối `simulateBattle`). Thương vong `CasualtyKind {survived, wounded, dead, deserted}` (`rules.dart:23`) và `SoldierStatus {active, dead, deserted}` (`models.dart:30`); `deserted` là lính bỏ chạy.
  * `[CURRENT]` Binh sĩ chết có `status = dead` và nằm trong danh sách chờ Bia mộ; có thể hồi sinh bằng `reviveSoldier` nếu đã xây Bia mộ. Cơ chế "Thuốc cứu hộ" chưa được xác nhận: `[UNVERIFIED]`.
  * `[UNVERIFIED]` Ngưỡng thua khi "toàn bộ lính bỏ chạy": `Unit.alive = hp > 0 && !fled` (`battle.dart:77`) cho thấy bỏ chạy tính như rời trận.

---

## 8\. PROGRESSION &amp; GAME MODES

### AC-PROG-01: Lên cấp &amp; Phân bổ Thuộc tính (`[OFFICIAL]` `[TRANSCRIPT]`)

* **Given:** Binh sĩ đạt đủ điểm XP sau trận đấu và có biểu tượng Level Up (giới hạn tối đa Level 5).
* **When:** Người chơi nhấn dấu `+` bên cạnh thuộc tính Strength, Dexterity, hoặc Constitution.
* **Then:** Thuộc tính tương ứng tăng +1 điểm, tiêu tốn 1 điểm Skill Point và cập nhật trực tiếp vào lính `[TRANSCRIPT]`.
* **Trạng thái triển khai:** `[CURRENT]` Cấp tối đa của binh sĩ là **6** (`maxSoldierLevel`, `lib/domain/stats.dart:286`), không phải 5. XP cần lên cấp kế: `{1:18, 2:30, 3:45, 4:62, 5:85}` (`xpCurve`, `stats.dart:290`). Điểm cộng (`statPoints`, `atkPoints`) được lưu trong `Soldier.toJson` (`points`, `atk`).

### AC-PROG-02: Điều kiện Thắng/Thua Chiến dịch (`[OFFICIAL]`)

* **Given:** Người người chơi đang ở trong Campaign Mode hoặc Sandbox Mode.
* **When:** Tiến trình chơi đạt các cột mốc đặc biệt.
* **Then:**  
  1. `Campaign Thắng`: Thanh `King's Satisfaction` đạt 100% `[OFFICIAL]`.
  2. `Campaign Thua`: Thanh `King's Satisfaction` về 0% `[OFFICIAL]`.
  3. `Sandbox Thua`: Cạn kiệt toàn bộ lính trong quân đoàn $\\rightarrow$ **Game Over ngay lập tức** `[OFFICIAL]`.

* **Trạng thái triển khai:**
  * `[CURRENT]` Campaign thua khi `kingSatisfaction <= 0 && !victory` (`GameState.gameOver`, `models.dart:708`).
  * `[CURRENT]` Campaign thắng khi **hoàn thành nhiệm vụ cuối** (template có `isFinal`, `GameRules` đặt `s.victory = true`, `rules.dart:~1720`; `MissionTemplate.isFinal`, `catalog.dart:590`). Source **không** thắng khi thanh đạt 100%; thanh chỉ bị kẹp 0–100 (`_addSat`, `rules.dart:~1629`). Mục 1 ở trên là mô tả thiết kế gốc, hiện là `[PLANNED]`/chưa khớp.
  * `[PLANNED]` Sandbox Game Over: không có chế độ Sandbox trong source. Tuy vậy, hết quân không gây Game Over trong Campaign; có cơ chế gỡ bế tắc (`GameRules.isSoftlocked`, `rules.dart:~376`, và `reliefGrant`).

---

## 9\. SAVE / LOAD SYSTEM

### AC-SAVE-01: Integrity, Checksum SHA-256 &amp; Backup (`[OFFICIAL]` `[PROPOSED]`) — `[PLANNED]` (chưa đạt)

> **Trạng thái:** Các yêu cầu 1–4 dưới đây là **mục tiêu `[PLANNED]`**, source hiện **chưa đáp ứng**: checksum hiện là FNV-1a 32-bit (không phải SHA-256), lưu bằng SharedPreferences (không có file `.tmp`/`.json`/`.bak`). Việc giữ hay loại bỏ các mục tiêu này **cần xác nhận quyết định** của chủ dự án; hiện giữ nguyên dưới dạng `[PLANNED]`. Hiện trạng `[CURRENT]` xem ở cuối mục này.

* **Given:** Hệ thống thực hiện thao tác lưu game (*Save Anytime* hoặc *End Day*).
* **When:** `SaveRepository` đóng gói `SaveEnvelope v3` chứa JSON data.
* **Then:**  
  1. Tạo mã Checksum SHA-256 mã hóa chuỗi JSON data `[PROPOSED]`.
  2. Ghi dữ liệu an toàn ra file tạm `.tmp` trước khi thay thế file chính `.json` `[PROPOSED]`.
  3. Tạo file sao lưu `.bak` từ bản save hợp lệ gần nhất `[PROPOSED]`.
  4. Nếu file `.json` bị hỏng Checksum khi Load, tự động khôi phục dữ liệu từ `.bak` `[PROPOSED]`.

* **Hiện trạng `[CURRENT]`** (`lib/data/save_repository.dart`):
  1. Phong bì `{version, checksum, data}`, `data` là chuỗi JSON của `GameState.toJson()`; `version` hiện hành = 3 (`SaveRepository.latestVersion`).
  2. Checksum là FNV-1a 32-bit (`SaveRepository.checksum`).
  3. Lưu bằng `KeyValueStore` (bản chạy thật là `PrefsStore` trên SharedPreferences): ghi bản `save_primary` hiện có sang `save_backup` trước, rồi ghi `save_primary` mới. Không ghi `.tmp`, không đổi tên file.
  4. Khi tải: thử `save_primary`; hỏng hoặc sai checksum thì thử `save_backup` (`LoadStatus.recoveredFromBackup`). Cả hai hỏng cho `LoadStatus.corrupted`. Test: `test/domain_v2_test.dart` (khoảng dòng 1484–1527).

---

## 10\. UI/UX &amp; RESPONSIVE LAYOUT

### AC-UI-01: Tối ưu Màn hình Ngang iPhone 15 Pro Max (`[PROPOSED]`)

* **Given:** Ứng dụng chạy trên thiết bị iOS màn hình ngang (Kích thước chuẩn 932x430 pt, Notch Dynamic Island).
* **When:** Hiển thị các màn hình Camp, Map, Deploy, Battle.
* **Then:**  
  1. Toàn bộ UI tuân thủ vùng an toàn **SafeArea** (tránh bị Dynamic Island / Home Indicator che khuất) `[PROPOSED]`.
  2. Vùng cảm ứng (Touch Target) của tất cả nút bấm và thẻ lính đạt tối thiểu **44x44 pt** `[PROPOSED]`.
  3. Thao tác Drag-and-Drop có phản hồi trực quan (High-light vùng thả, bóng mờ thẻ lính) `[PROPOSED]`.
  4. Không xảy ra lỗi rác giao diện hoặc vỡ khung (*Layout Overflow*) trên các màn hình nhỏ hơn (ví dụ: iPhone SE landscape) `[PROPOSED]`.

---

## 11\. MA TRẬN KIỂM THỬ QA (QA TEST MATRIX)

| Mã Test Case  | Màn hình / Module | Các bước thực hiện (Test Steps)                                                                    | Kết quả mong đợi (Expected Result)                                                     | Độ ưu tiên | Trạng thái xác minh |
| ------------- | ----------------- | -------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------- | ---------- | ------------------- |
| **TC-NAV-01** | Main Menu         | Nhấn `New Campaign` $\\rightarrow$ Nhập tên $\\rightarrow$ Chọn Plebs $\\rightarrow$ Bấm Start     | Khởi tạo Campaign mới với Vàng nhiều hơn, King's Satisfaction thấp hơn, 5–6 lính       | High       | `[UNVERIFIED]` (có 6 lính; chưa thấy lựa chọn Plebs) |
| **TC-CMP-01** | Camp              | Kéo 1 lính thả vào Infirmary $\\rightarrow$ Nhấn `End Day`                                         | Lính nằm trong Infirmary, HP được hồi phục qua đêm, trừ 1 Gold + 1 Food duy trì        | High       | `[UNVERIFIED]` (gán lính và End Day có; mức hồi và upkeep xem AC-CAMP-02) |
| **TC-CMP-02** | Camp              | Chơi cạn kiệt Thức ăn $\\rightarrow$ Nhấn `End Day`                                                | Xuất hiện cảnh báo thiếu Thức ăn, Morale toàn bộ lính bị suy giảm                      | Medium     | `[UNVERIFIED]` |
| **TC-MAP-01** | World Map         | Nhấp chọn ô di chuyển xa vượt quá March Points                                                     | Đội quân di chuyển đến khi hết điểm thì dừng lại, hiện thông báo nhấn `End Day`        | High       | `[CURRENT]` (thể lực di chuyển; test `hero_movement_test.dart`, chưa kiểm assert) |
| **TC-TWN-01** | Town              | Vào Tavern khi Roster đã đủ 20 lính $\\rightarrow$ Xem nút Thuê                                    | Nút Thuê bị vô hiệu hóa (Disabled) để tránh vượt quá giới hạn 20 lính                  | Medium     | `[CURRENT]` với sức chứa `rosterCap` (không phải 20); `[UNVERIFIED]` trạng thái nút |
| **TC-DEP-01** | Deploy            | Kéo 5 lính vào lưới $\\rightarrow$ Đổi vị trí Cung thủ ra Hàng sau                                 | Cung thủ đứng hàng sau, lính cận chiến đứng hàng trước, nút Start Battle sẵn sàng      | High       | `[UNVERIFIED]` (có preset đội hình; chưa xác nhận hàng trước/sau theo nghề) |
| **TC-BAT-01** | Battle            | Vào trận Autobattler $\\rightarrow$ Chờ lính giảm Morale $\\rightarrow$ Nhấn War Horn              | Nút War Horn kích hoạt hiệu ứng, Morale lính tăng lên ngay lập tức, Combat Log ghi lại | High       | `[PLANNED]` (War Horn chưa triển khai) |
| **TC-BAT-02** | Battle / Result   | Lính cạn HP trong trận $\\rightarrow$ Kết thúc trận không dùng Thuốc cứu hộ                        | Lính bị đánh dấu chết và bị xóa vĩnh viễn khỏi Roster (`Permadeath`)                   | High       | `[CURRENT]` (chết vĩnh viễn trừ khi hồi sinh ở Bia mộ; test `resurrection_test.dart`) |
| **TC-GM-01**  | Sandbox Mode      | Vào Sandbox $\\rightarrow$ Cho toàn bộ lính tử trận trong 1 trận đấu                               | Màn hình Game Over kích hoạt ngay lập tức mà không phụ thuộc điểm Vua                  | High       | `[PLANNED]` (Sandbox chưa triển khai) |
| **TC-SAV-01** | Save / Load       | Nhấn Save Game $\\rightarrow$ Sửa hỏng 1 ký tự file `.json` $\\rightarrow$ Mở lại app bấm Continue | System phát hiện lỗi Checksum, tự động khôi phục dữ liệu từ `.bak` thành công          | High       | `[CURRENT]` với checksum FNV-1a và khôi phục từ `save_backup` (test `domain_v2_test.dart`); `[PLANNED]` với `.json`/`.bak` |
| **TC-UI-01**  | UI Responsive     | Mở app trên iPhone 15 Pro Max landscape $\\rightarrow$ Xoay góc Notch                              | UI co giãn đúng SafeArea, không bị chèn thanh Home Indicator, Touch target $\\ge 44pt$ | High       | `[UNVERIFIED]` (chưa chạy trên thiết bị/simulator) |

---

## 12\. ĐỊNH NGHĨA HOÀN THÀNH (DEFINITION OF DONE - DOD)

Một tính năng hoặc Module trong dự án **Rising Army Remake** chỉ được đánh giá là **Hoàn thành (Done)** và đủ điều kiện merge mã nguồn khi đạt đầy đủ các tiêu chuẩn sau:

1. **Tuân thủ Thiết kế &amp; Bằng chứng:**  
  * Logic xử lý đúng theo các quy tắc `[OFFICIAL]`, `[OBSERVED]`, `[TRANSCRIPT]` được đặc tả trong tài liệu này.
  * Không tự ý thêm các thông số hoặc cơ chế chưa có xác minh.
2. **Kiểm thử Tự động (Automated Testing):**  
  * Tất cả Unit Tests cho Domain Logic (Lính, Camp, Kinh tế, Map, Combat Simulation) đạt tỷ lệ Pass **100%**.
  * Controller Tests xác minh đúng chuồng luồng chuyển trạng thái và phát thông báo `notifyListeners()`.
  * Trải qua tối thiểu 100 trận Headless Battle Simulation tự động không phát sinh crash hoặc loop vô tận.
3. **An toàn Dữ liệu (Save Data Integrity):**  
  * Đã kiểm thử lưu/tải dữ liệu thành công qua `SaveEnvelope v3` có kiểm Checksum. *(Hiện trạng `[CURRENT]`: FNV-1a 32-bit. Mục tiêu SHA-256 là `[PLANNED]`, cần xác nhận quyết định.)*
  * Vượt qua test case khôi phục dữ liệu từ bản sao lưu khi bản chính bị hỏng. *(Hiện trạng `[CURRENT]`: khóa `save_backup` trong SharedPreferences. Mục tiêu file `.bak` là `[PLANNED]`.)*
4. **Trải nghiệm UI/UX Landscape:**  
  * Hiển thị chuẩn xác trên iPhone 15 Pro Max landscape (SafeArea, Dynamic Island offset).
  * Thao tác Kéo - Thả (Drag-and-Drop) cảm ứng mượt mà, kích thước vùng chạm $\\ge 44\\times 44\\text{ pt}$.
5. **Code Quality &amp; Documentation:**  
  * Mã nguồn không có cảnh báo nghiêm trọng (`dart analyze` 0 errors).
  * Không vi phạm kiến trúc 4 tầng (Pure Dart Domain không import Flutter UI package).