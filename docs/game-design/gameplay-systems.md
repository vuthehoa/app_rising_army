# ĐẶC TẢ CÁC HỆ THỐNG GAMEPLAY (GAMEPLAY SYSTEMS SPECIFICATION)

**Dự án:** Rising Army Remake (Flutter iOS - Landscape)  
**Tập tin mục tiêu:** `docs/game-design/gameplay-systems.md`  
**Tài liệu tham chiếu:** `source-catalog.md`, `game-overview.md`, `gameplay-core-loop.md`, `ui-ux-specification.md`

---

## MỤC LỤC

1. [Tổng quan các hệ thống Gameplay](#1-t%E1%BB%95ng-quan-c%C3%A1c-h%E1%BB%87-th%E1%BB%91ng-gameplay)
2. [Bảng tổng hợp 9 hệ thống Gameplay](#2-b%E1%BA%A3ng-t%E1%BB%95ng-h%E1%BB%87p-9-h%E1%BB%87-th%E1%BB%91ng-gameplay)
3. [Chi tiết Đặc tả các Hệ thống Gameplay Cốt lõi](#3-chi-ti%E1%BA%BFt-%C4%91%E1%BA%B7c-t%E1%BA%A3-c%C3%A1c-h%E1%BB%87-th%E1%BB%91ng-gameplay-c%E1%BB%91t-l%C3%B5i)  
  * 3.1\. [Soldier System (Hệ thống Binh sĩ)](#31-soldier-system-h%E1%BB%87-th%E1%BB%91ng-binh-s%C4%A9)
  * 3.2\. [Camp &amp; Building System (Hệ thống Doanh trại &amp; Công trình)](#32-camp--building-system-h%E1%BB%87-th%E1%BB%91ng-doanh-tr%E1%BA%A1i--c%C3%B4ng-tr%C3%ACnh)
  * 3.3\. [Resource &amp; Economy System (Hệ thống Tài nguyên &amp; Kinh tế)](#33-resource--economy-system-h%E1%BB%87-th%E1%BB%91ng-t%C3%A0i-nguy%C3%AAn--kinh-t%E1%BA%BF)
  * 3.4\. [World Map &amp; Movement System (Hệ thống Bản đồ &amp; Di chuyển)](#34-world-map--movement-system-h%E1%BB%87-th%E1%BB%91ng-b%E1%BA%A3n-%C4%91%E1%BB%93--di-chuy%E1%BB%83n)
  * 3.5\. [Quest &amp; King's Satisfaction System (Hệ thống Nhiệm vụ &amp; Độ hài lòng của Vua)](#35-quest--kings-satisfaction-system-h%E1%BB%87-th%E1%BB%91ng-nhi%E1%BB%87m-v%E1%BB%A5--%C4%91%E1%BB%99-h%C3%A0i-l%C3%B2ng-c%E1%BB%A7a-vua)
  * 3.6\. [Deployment &amp; Formation System (Hệ thống Bố trí &amp; Đội hình)](#36-deployment--formation-system-h%E1%BB%87-th%E1%BB%91ng-b%E1%BA%A3o-tr%C3%AD--%C4%91%E1%BB%99i-h%C3%ACnh)
  * 3.7\. [Combat System (Hệ thống Chiến đấu Autobattler)](#37-combat-system-h%E1%BB%87-th%E1%BB%91ng-chi%E1%BA%BFn-%C4%91%E1%BA%A5u-autobattler)
  * 3.8\. [Progression &amp; Permadeath System (Hệ thống Tiến trình &amp; Permadeath)](#38-progression--permadeath-system-h%E1%BB%87-th%E1%BB%91ng-ti%E1%BA%BFn-tr%C3%ACnh--permadeath)
  * 3.9\. [Game Modes &amp; Game Over System (Hệ thống Chế độ chơi &amp; Kết thúc)](#39-game-modes--game-over-system-h%E1%BB%87-th%E1%BB%91ng-ch%E1%BA%BF-%C4%91%E1%BB%99-ch%C6%A1i--k%E1%BA%BFt-th%C3%BAc)
4. [Danh sách câu hỏi UNKNOWN cần xác minh trước khi chốt Logic](#4-danh-s%C3%A1ch-c%C3%A2u-h%E1%BB%8Fi-unknown-c%E1%BA%A7n-x%C3%A1c-minh-tr%C6%B0%E1%BB%9Bc-khi-ch%E1%BB%91t-logic)

---

> **Cập nhật theo TASK-003: đối chiếu với source.** Tài liệu này mô tả thiết kế (nhiều mục lấy từ game gốc Rising Army) và **không phải** mô tả hiện trạng. Dưới mỗi hệ thống có khối **"Hiện trạng source"**: nội dung trong khối là hành vi đã xác minh trong source (`[CURRENT]`); nếu mâu thuẫn với phần thiết kế phía dưới thì **source đúng với hiện trạng**, còn phần thiết kế là mục tiêu `[PLANNED]` hoặc tham chiếu game gốc. `[UNVERIFIED]` = chưa đủ bằng chứng. Các số liệu trong khối được lấy từ source, không tự đổi giá trị nào khác.

---

## 1\. TỔNG QUAN CÁC HỆ THỐNG GAMEPLAY

Tài liệu này đặc tả quy chuẩn kỹ thuật nghiệp vụ cho **9 hệ thống gameplay cốt lõi** của dự án *Rising Army Remake*. Mục tiêu giúp đội ngũ lập trình game Flutter xây dựng kiến trúc quản lý trạng thái (`State Management`), mô hình dữ liệu (`Data Models`) và xử lý sự kiện logic đồng nhất, chính xác, tránh tự ý suy diễn các thuật toán hay luật chơi ẩn của game gốc.

Mọi quy tắc được phân định minh bạch theo 6 cấp độ bằng chứng:

* `[OFFICIAL]`: Tuyên bố chính thức từ nhà phát triển Arkbits / Trang Steam.
* `[OBSERVED]`: Quan sát trực tiếp từ video trải nghiệm thực tế.
* `[TRANSCRIPT]`: Lời thoại / Phụ đề trực tiếp trong video playthrough.
* `[COMMUNITY]`: Đánh giá &amp; thảo luận của người chơi trên Steam/Reddit.
* `[REMAKE PROPOSAL]`: Đề xuất thiết kế logic dành riêng cho bản Flutter Remake.
* `[UNKNOWN]`: Thông số hoặc thuật toán chưa có dữ liệu xác minh.

---

## 2\. BẢNG TỔNG HỢP 9 HỆ THỐNG GAMEPLAY

| STT | Hệ thống Gameplay | Vai trò cốt lõi | Trạng thái chính quản lý | Mức xác minh chính | | :-: | :--- | :--- | :--- | :-: | | **1** | **Soldier System** | Quản lý cá thể binh sĩ, chỉ số, trang bị &amp; sinh tồn | Stats (Str, Dex, Con, Speed), Vitals (HP, Energy, Morale), 3 Gear Slots | `[OFFICIAL]` `[OBSERVED]` | | **2** | **Camp &amp; Building System** | Điều hành căn cứ, phân công kéo-thả, chữa thương &amp; huấn luyện | Building Levels, Slot Assignments, Overnight Recovery/Training Tick | `[OFFICIAL]` `[OBSERVED]` | | **3** | **Resource &amp; Economy System** | Quản lý thu chi 7 tài nguyên, tuyển quân, chợ &amp; upkeep | 7 Resource Balances, Daily Upkeep (1 Gold + 1 Food/lính), Town Prices | `[OFFICIAL]` `[OBSERVED]` | | **4** | **World Map &amp; Movement** | Điều khiển quân đoàn khám phá bản đồ mở &amp; sự kiện | March Points, Fog of War, Weather Penalty, Overworld Event Nodes | `[OFFICIAL]` `[OBSERVED]` | | **5** | **Quest &amp; King's Satisfaction** | Tiếp nhận giao kèo, hạn chót ngày &amp; giữ lòng tin Vua | King's Satisfaction Meter (0-100%), Active Quests, Deadline Countdown | `[OFFICIAL]` `[OBSERVED]` | | **6** | **Deployment &amp; Formation** | Bố trí lưới chiến thuật cận chiến/bắn xa trước trận | Grid Unit Positions (Frontline/Backline), Deploy Limit, Preset Formation | `[OFFICIAL]` `[OBSERVED]` | | **7** | **Combat System** | Mô phỏng giao tranh tự động, đòn đánh, morale &amp; sừng chiến | Real-time Battle Loop, Hit/Miss/Crit, Tide Bar, Morale Panic, War Horn | `[OFFICIAL]` `[OBSERVED]` | | **8** | **Progression &amp; Permadeath** | Tăng cấp lính, mất lính vĩnh viễn &amp; hồi sinh | XP, Stat Allocation (+1 per level, Max Cap 5), Permadeath, Gravestone | `[OFFICIAL]` `[COMMUNITY]` | | **9** | **Game Modes &amp; Game Over** | Quản lý 3 chế độ chơi &amp; điều kiện kết thúc | Mode Rules (Campaign, Sandbox, Arena), Save State, Game Over Triggers | `[OFFICIAL]` |

---

## 3\. CHI TIẾT ĐẶC TẢ CÁC HỆ THỐNG GAMEPLAY CỐT LÕI

### 3.1\. Soldier System (Hệ thống Binh sĩ)

> **Hiện trạng source (`[CURRENT]`):**
> * Sức chứa quân đoàn: `rosterCap = 6 + 4 × cấp Doanh trại` (`GameRules.rosterCap`, `lib/domain/rules.dart:321`), không phải 20 cố định. Mốc 20 bên dưới là tham chiếu game gốc; trần 20 trong remake `[UNVERIFIED]`/cần quyết định.
> * Cấp tối đa **6** (`maxSoldierLevel`, `lib/domain/stats.dart:286`), không phải 5.
> * Chỉ số huấn luyện: `Stat {str, dex, con}` (`models.dart:14`); tốc độ là chỉ số dẫn xuất. Ngoài ra có điểm Công (`atkPoints`) trong `MainStat {strength, speed, build, attack}`.
> * Ô trang bị: `Slot {weapon, armor, shield, helmet, accessory}` (`models.dart:22`), không phải 3 ô.
> * Thanh sinh tồn: `hp`, `energy`, `morale` (`Soldier`); trần energy và morale phụ thuộc chỉ số (`energyCap`, `moraleCap`, `stats.dart`).
> * Trạng thái: `SoldierStatus {active, dead, deserted}` (`models.dart:30`). Lính chết ở trạng thái `dead` (xếp ở danh sách Bia mộ) và có thể hồi sinh; không bị xóa dữ liệu ngay.
> * Có tình trạng chiến đấu/thương tích (`needsTreatment`, `combat_condition.dart`) và hệ thống trang bị riêng (`lib/domain/equipment/`) mà phần thiết kế dưới đây chưa mô tả.

#### A. Mục đích &amp; Vai trò

Là đơn vị thực thi trung tâm của toàn bộ game. Mỗi binh sĩ là một cá thể độc lập có tên riêng, thuộc tính, trang bị và tình trạng sinh tồn riêng biệt `[OFFICIAL]`. Người chơi điều phối lính nghỉ ngơi, huấn luyện tại Camp và ra trận đánh giặc.

#### B. Dữ liệu đầu vào, Trạng thái quản lý &amp; Kết quả đầu ra

* **Đầu vào:** Tên lính (cho phép đổi tên thủ công `[OFFICIAL]`), Đặc tính (`Traits` `[OFFICIAL]`), Trang bị được gán.
* **Trạng thái quản lý:**  
  * **Thuộc tính gốc (Base Stats):** `Strength` (Sức mạnh), `Dexterity` (Khéo léo), `Constitution` (Thể chất), `Speed` (Tốc độ) `[OBSERVED]`.
  * **Thước đo sinh tồn (Vital Meters):**  
    * `Health (HP)`: Máu hiện tại / Max HP. Thấp gây vết thương trực quan trên sprite `[OBSERVED]`.
    * `Energy / Stamina`: Thể lực hiện tại (biểu tượng tia sét). Tiêu tốn khi di chuyển/huấn luyện `[OBSERVED]`.
    * `Morale`: Sĩ khí hiện tại (biểu tượng ngọn lửa xanh). Sĩ khí thấp gây hoảng sợ/bỏ chạy `[OBSERVED]`.
  * **Trang bị (3 Slots):** Ô 1: Vũ khí (Weapon); Ô 2: Khiên/Phụ kiện (Off-hand); Ô 3: Giáp (Armor) `[OFFICIAL]`.
  * **Trạng thái hoạt động:** Idle, Resting (Tents), Healing (Infirmary), Training (Fields), Deployed (Battle), Dead (Gravestone/Permadeath) `[OBSERVED]`.
* **Đầu ra:** Chỉ số chiến đấu tổng hợp (Sát thương, Né tránh, Giáp, Tốc độ đánh), Trạng thái sinh tồn sau ngày/sau trận.

#### C. Quy tắc đã xác minh từ nguồn

* **Giới hạn số lượng:** Quân đoàn chứa tối đa **20 binh sĩ** `[OFFICIAL]`.
* **Phẩm chất &amp; Trang bị:** Có hơn **50 loại vũ khí** và **50 mảnh giáp** `[OFFICIAL]`. Trang bị cộng trực tiếp các chỉ số đòn đánh (ví dụ: Paladin Sword +15% Accuracy, Improvised Spear -5% Accuracy) `[OBSERVED]`.
* **Thương tật &amp; Permadeath:** Lính ngã xuống trong trận nếu không được cứu chữa/hồi sinh sẽ bị xóa vĩnh viễn cùng trang bị mang theo `[OFFICIAL]`.

#### D. Mối quan hệ với các hệ thống khác

* **Camp System:** Lính được kéo-thả vào công trình để hồi HP/Energy/Morale hoặc tăng thuộc tính.
* **Resource System:** Tiêu tốn 1 Gold + 1 Food/lính/ngày phí duy trì.
* **Combat System:** Lấy chỉ số lính để mô phỏng chiến đấu tự động.

#### E. Tình huống biên / Lỗi cần xử lý (Edge Cases)

* **Lính hết Energy/Morale:** Giảm hiệu suất chiến đấu hoặc tự động rời khỏi công trình huấn luyện.
* **Tháo giáp khi kho đồ đầy:** Ngăn tháo trang bị nếu Stash đã đạt sức chứa tối đa `[REMAKE PROPOSAL]`.

#### F. Điểm chưa xác minh (`[UNKNOWN]`)

* Công thức chuyển đổi chính xác: 1 điểm `Strength` \= bao nhiêu HP / Sát thương cận chiến? 1 điểm `Dexterity` \= bao nhiêu Accuracy / Sát thương tầm xa? 1 điểm `Constitution` \= bao nhiêu Max HP?

---

### 3.2\. Camp &amp; Building System (Hệ thống Doanh trại &amp; Công trình)

> **Hiện trạng source (`[CURRENT]`):**
> * Công trình cấp (`Building {barracks, smithy, tavern}`, cấp 0–3, `maxBuildingLevel = 3`, `models.dart:34,701`) và công trình đặt trong trại (`FacilityType {meleeYard, archeryRange, enduranceYard, infirmary, storageChest, gravestone, barracks}`, `models.dart:38`).
> * **Không có `Tents` và `Altar`** trong source. Tên hiển thị thực tế (`facilityDefs`, `catalog.dart:~1562`): Bãi cận chiến, Bãi bắn cung, Bãi đá (id `enduranceYard`), Lều cứu thương, Hòm đồ, Doanh trại, Bia mộ.
> * Công trình nhận lính có 3 chỗ, 6 ở cấp 2 (`Facility.capacity/upgradedCapacity`). Lều cứu thương: "Tối đa 3 người" (cấp 1).
> * Tác dụng qua đêm (`facilityEffects`, `lib/domain/building_effects.dart`): Lều cứu thương hồi HP (mạnh) và Energy; Bãi bắn cung huấn luyện STR, tốc độ (mạnh), thể lực, giảm Energy và Morale; Bãi cận chiến huấn luyện STR (mạnh), thể lực, giảm Energy và Morale; Doanh trại hồi Energy (mạnh) và Morale. Con số hồi phục theo cấp: `[UNVERIFIED]` trong tài liệu này.
> * Hòm đồ: mỗi hòm +10 sức chứa kho; kho cơ sở `30 + 10 × cấp Doanh trại` (`inventoryCapacityFor`, `catalog.dart:1062`).
> * Hồi sinh ở Bia mộ: cần đã xây Bia mộ, còn chỗ trong roster, trả vàng; binh sĩ về với **HP = 1**, năng lượng và tinh thần giữ nguyên, `needsTreatment = true` (`GameRules.reviveSoldier`, `rules.dart:639`). Mô tả "~20% và mất sạch trang bị" bên dưới chưa khớp (`[COMMUNITY]` chưa áp dụng); việc xóa trang bị `[UNVERIFIED]`.
> * Công trình hỏng ngẫu nhiên theo ngày: `[UNVERIFIED]`/chưa thấy trong phần source đã đọc.

#### A. Mục đích &amp; Vai trò

Cung cấp căn cứ điều hành cho quân đoàn. Cho phép người chơi xây dựng, nâng cấp công trình và gán lính bằng thao tác kéo-thả để hồi phục hoặc huấn luyện `[OFFICIAL]`.

#### B. Dữ liệu đầu vào, Trạng thái quản lý &amp; Kết quả đầu ra

* **Đầu vào:** Thao tác kéo-thả lính vào ô chức năng (*Slots*), Thao tác chọn Xây dựng / Nâng cấp / Sửa chữa.
* **Trạng thái quản lý:**  
  * **Danh sách công trình &amp; Cấp độ:** Tents, Infirmary, Altar, Training Fields, Gravestone, Stash `[OBSERVED]`.
  * **Danh sách Slot lính gán vào từng công trình:** Ví dụ Infirmary có 3 slots `[OBSERVED] [TRANSCRIPT]`.
  * **Trạng thái hỏng hóc công trình:** Tỷ lệ rạn nứt qua ngày `[COMMUNITY]`.
* **Đầu ra:** Chỉ số lính biến đổi sau lượt `End Day` (HP tăng, Energy tăng, Morale tăng, hoặc Stat tăng).

#### C. Quy tắc đã xác minh từ nguồn

* **Thao tác:** Kéo-thả lính trực tiếp vào ô chứa của công trình `[OFFICIAL]`.
* **Chức năng các công trình quan sát được:**  
  * `Tents (Túp lều)`: Hồi phục Energy &amp; Morale qua đêm `[OBSERVED]`.
  * `Infirmary (Bệnh xá)`: Hồi phục HP qua đêm. **Sức chứa 3 lính** `[OBSERVED] [TRANSCRIPT]`.
  * `Altar (Bàn thờ / Đá cầu nguyện)`: Khôi phục chỉ số Morale `[OBSERVED]`.
  * `Training Fields (Sân huấn luyện)`: Tiêu tốn Energy/Morale &amp; phí daily để tăng Strength/Constitution `[OBSERVED]`.
  * `Gravestone (Mộ đá)`: Hồi sinh lính tử trận bằng Gold `[COMMUNITY]`. Lính sống lại bị mất sạch trang bị và HP/Energy/Morale chỉ ở mức \~20% `[COMMUNITY]`.
  * `Stash (Rương đồ)`: Tăng sức chứa kho lưu trữ vật phẩm `[OFFICIAL] [OBSERVED]`.
* **Bảo trì công trình:** Công trình có thể bị hỏng hóc ngẫu nhiên qua ngày, yêu cầu Tools/Wood/Stone để sửa chữa `[COMMUNITY]`.

#### D. Mối quan hệ với các hệ thống khác

* **Soldier System:** Thay đổi thuộc tính và thước đo sinh tồn của lính sau mỗi `End Day`.
* **Resource System:** Tiêu tốn tài nguyên (Gold, Wood, Stone, Iron, Tools, Cloth) khi xây/nâng cấp/sửa chữa.

#### E. Tình huống biên / Lỗi cần xử lý (Edge Cases)

* **Xây đè / Gán lính quá sức chứa:** Khóa thao tác thả lính khi slot công trình đã đầy.
* **Thiếu tài nguyên khi sửa:** Công trình bị hỏng nặng dừng toàn bộ tính năng hồi phục/huấn luyện cho đến khi được sửa `[REMAKE PROPOSAL]`.

#### F. Điểm chưa xác minh (`[UNKNOWN]`)

* Công thức điểm hồi HP/Energy/Morale chính xác của từng cấp độ công trình (Level 1, Level 2, Level 3).

---

### 3.3\. Resource &amp; Economy System (Hệ thống Tài nguyên &amp; Kinh tế)

> **Hiện trạng source (`[CURRENT]`):**
> * Tài nguyên: `Res {food, coins, wood, iron, tools, stone, cloth}` (vàng là `coins`). Khởi đầu: food 48, coins 50, wood 30, stone 15, iron 9, tools 5, cloth 5 (`StartingEconomy.resources`, `lib/domain/economy.dart:18`).
> * **Upkeep theo cấp binh sĩ**, không phải 1 Gold + 1 Food cố định: vàng `{1:1, 2:1, 3:1, 4:2, 5:2, 6:3}`, lương thực `{1:1, 2:1, 3:1, 4:2, 5:2, 6:3}`; cấp ≥ 6 dùng mức cấp 6 (`UpkeepEconomy`, `economy.dart:105-130`). Khi thiếu tài nguyên, phần thực trả ghi ở `DayReport.paidUpkeep`.
> * Giá tuyển mộ theo công thức: giá nền `{1:10, 2:15, 3:25}`, cộng mỗi điểm chỉ số vượt mức trung bình, trần `{1:16, 2:24, 3:120}` (`HireEconomy`, `economy.dart:~138`); ứng viên Quán rượu tối đa cấp 3 (`tavernMaxCandidateLevel`, `catalog.dart:1057`). Khoảng 14–20 vàng bên dưới không phải giá cố định.
> * Cửa hàng/thương mại: có `ShopStock` theo thị trấn và giá mua bán theo hàm (`buyPrice`, `resourceBuyPrice`…); giá công cụ ~8 vàng `[UNVERIFIED]`.

#### A. Mục đích &amp; Vai trò

Quản lý luồng thu chi tài chính và nguyên vật liệu duy trì sự tồn tại của quân đoàn. Cân bằng giữa trả lương, nuôi quân, mua sắm trang bị và đầu tư căn cứ `[OFFICIAL]`.

#### B. Dữ liệu đầu vào, Trạng thái quản lý &amp; Kết quả đầu ra

* **Đầu vào:** Thưởng nhiệm vụ, Loot chiến lợi phẩm, Mua/bán ở Thị trấn, Trừ phí duy trì ngày `End Day`.
* **Trạng thái quản lý:**  
  * **Số dư 7 loại tài nguyên:** `Gold` (Vàng), `Food` (Thức ăn), `Tools` (Công cụ/Búa), `Iron` (Sắt), `Stone` (Đá), `Wood` (Gỗ), `Cloth` (Vải) `[OBSERVED] [TRANSCRIPT]`.
  * **Bảng giá thị trường tại Town:** Giá mua/bán ở Blacksmith (Trang bị) và Market (Nguyên liệu) `[OBSERVED]`.
* **Đầu ra:** Số dư tài nguyên cập nhật, Trạng thái vỡ nợ / cạn thức ăn.

#### C. Quy tắc đã xác minh từ nguồn

* **Phí duy trì hàng ngày (Daily Upkeep):** Mức trừ cố định khi nhấn `End Day`: **1 Gold + 1 Food / 1 lính / 1 ngày** `[OBSERVED] [TRANSCRIPT]`.
* **Tuyển quân (Tavern):** Tuyển lính tại Quán rượu tiêu tốn Vàng (\~14 – 20 Gold/lính tùy thuộc tính/trang bị ban đầu) `[OBSERVED] [TRANSCRIPT]`.
* **Giao thương:**  
  * `Blacksmith`: Mua/bán vũ khí và giáp `[OBSERVED]`.
  * `Market`: Mua/bán tài nguyên (ví dụ: \~8 Gold / 1 Tools) `[OBSERVED]`.

#### D. Mối quan hệ với các hệ thống khác

* **Soldier System:** Chi trả phí duy trì và mua trang bị cho lính.
* **Camp System:** Cung cấp nguyên liệu nâng cấp/sửa chữa công trình.
* **Quest System:** Nhận Vàng và Thức ăn từ phần thưởng giao kèo.

#### E. Tình huống biên / Lỗi cần xử lý (Edge Cases)

* **Cạn kiệt Thức ăn hoặc Vàng (`Upkeep Deficit`):** Lính bị giảm mạnh Morale, có thể dẫn đến đào ngũ giữa chừng `[OBSERVED]`.
* **Bán sạch Thức ăn trong kho:** Cảnh báo người chơi trước khi nhấn `End Day` nếu kho hết Thức ăn `[REMAKE PROPOSAL]`.

#### F. Điểm chưa xác minh (`[UNKNOWN]`)

* Thuật toán biến động giá mua/bán ở Market theo thời gian hoặc theo từng thị trấn.

---

### 3.4\. World Map &amp; Movement System (Hệ thống Bản đồ &amp; Di chuyển)

> **Hiện trạng source (`[CURRENT]`):**
> * Cơ chế `March Points` trong source là **thể lực di chuyển** `HeroState.stamina`, tối đa `TerrainRules.maxStamina = 100`; chi phí mỗi đơn vị = `0,05 × hệ số địa hình` (`lib/domain/terrain_type.dart`): đồng bằng 1,0; bãi cỏ 1,0; rừng thưa 1,6; rừng rậm 2,3; đồi 1,8; sườn núi 3,2; ven nước 1,3; cầu 0,8; vách đá, mặt nước và ngoài bản đồ không đi được. Ước lượng đường đi: `MovementRules.estimate` (`lib/domain/movement.dart`).
> * Save lưu `explored`, `discovered`, `cleared` (tập chuỗi). Cơ chế hiển thị sương mù chi tiết: `[UNVERIFIED]`.
> * Thời tiết (mưa, tuyết, bão): `[PLANNED]`, chưa có trong `lib/domain/`. Sự kiện ngẫu nhiên (thầy bói, con cáo, đào đá): `[UNVERIFIED]`.

#### A. Mục đích &amp; Vai trò

Mô phỏng trải nghiệm di chuyển tự do (*roaming band*) trên bản đồ mở thế giới trung cổ. Người chơi điều hướng quân đoàn tìm kiếm nhiệm vụ, khám phá điểm tài nguyên và xử lý biến cố `[OFFICIAL]`.

#### B. Dữ liệu đầu vào, Trạng thái quản lý &amp; Kết quả đầu ra

* **Đầu vào:** Thao tác chạm chọn vị trí đích đến trên bản đồ 2D, Phím điều khiển camera WASD `[OFFICIAL]`.
* **Trạng thái quản lý:**  
  * **Tọa độ quân đoàn &amp; Tầm nhìn:** Bán kính tròn mở rộng sương mù chiến trường (*Fog of War*) `[OBSERVED]`.
  * **Điểm di chuyển:** `March Points` hiện tại / Max `March Points` `[OBSERVED]`.
  * **Điều kiện thời tiết:** Mưa, Tuyết, Bão (gây phạt chỉ số đòn đánh khi giao tranh) `[OFFICIAL]`.
  * **Danh sách Node bản đồ:** Town, Event Node, Pickup Node, Encounter Node `[OBSERVED]`.
* **Đầu ra:** Vị trí quân đoàn mới, Kích hoạt màn hình Town, Kích hoạt Hộp thoại Sự kiện, hoặc Chuyển sang màn hình Deploy.

#### C. Quy tắc đã xác minh từ nguồn

* **Cơ chế di chuyển:** Tiêu tốn **March Points**. Nhấn `End Day` để khôi phục March Points cho ngày tiếp theo `[OBSERVED]`.
* **Ảnh hưởng địa hình:** Các dạng địa hình đồi núi, ruộng đồng làm chậm tốc độ và tiêu tốn nhiều March Points hơn đường lộ `[OBSERVED]`.
* **Nhặt tài nguyên dã ngoại:** Đi đè lên biểu tượng tài nguyên trên map để thu thập trực tiếp (ví dụ: Wood, Stone, Gold) `[OBSERVED]`.
* **Sự kiện ngẫu nhiên (Random Events):** Tiếp cận Node `?` mở hộp thoại lựa chọn (ví dụ: Thầy bói đổi Vàng lấy Morale; Con Cáo đổi Food lấy March Points; Đào đá ngẫu nhiên) `[OBSERVED]`.
* **Chạm trán:** Va chạm với băng cướp (*Bandits*) hoặc Quái thú dã ngoại (*Wild Beasts*) kích hoạt màn hình Deploy `[OFFICIAL] [OBSERVED]`.

#### D. Mối quan hệ với các hệ thống khác

* **Town / Quest System:** Mở giao diện thị trấn và hiển thị mũi tên chỉ hướng mục tiêu nhiệm vụ.
* **Combat System:** Chuyển sang chiến đấu khi va chạm kẻ địch; áp dụng hình phạt thời tiết vào trận.

#### E. Tình huống biên / Lỗi cần xử lý (Edge Cases)

* **Hết March Points khi chưa tới đích:** Buộc người chơi nhấn `End Day` giữa đường.
* **Đội quân mắc kẹt trong địa hình núi:** Thuật toán tìm đường (*Pathfinding*) tự động điều hướng tránh các điểm ô không thể đi qua `[REMAKE PROPOSAL]`.

#### F. Điểm chưa xác minh (`[UNKNOWN]`)

* Công thức tính số March Points tiêu tốn cho từng loại ô địa hình cụ thể. Tỷ lệ xuất hiện ngẫu nhiên (*Spawn rate*) của Node tài nguyên trên bản đồ.

---

### 3.5\. Quest &amp; King's Satisfaction System (Hệ thống Nhiệm vụ &amp; Độ hài lòng của Vua)

> **Hiện trạng source (`[CURRENT]`):**
> * Thanh hài lòng là **số nguyên 0–100** (`kingSatisfaction`, `models.dart:654`), khởi đầu **50** (`GameRules.newGame`, `rules.dart:229`), bị kẹp 0–100 (`_addSat`, `rules.dart:1629`).
> * **Thua** (Campaign duy nhất): `kingSatisfaction <= 0 && !victory` (`GameState.gameOver`, `models.dart:708`).
> * **Thắng**: hoàn thành nhiệm vụ cuối (template có `isFinal`; `s.victory = true`, `rules.dart:~1720`, `catalog.dart:590`). Source **không** thắng khi thanh đạt 100%; mô tả "100% King's Favor" bên dưới là thiết kế gốc, chưa khớp source.
> * Hạn nhiệm vụ: nhiệm vụ săn (hunt) có hạn ngẫu nhiên 3–7 ngày (`QuestGenerator.minQuestDays/maxQuestDays`, `rollDays`), tối thiểu `ngày di chuyển + 2`; các loại khác dùng `days` cố định của template (1–3 theo `catalog.dart`). Quá hạn trừ `penaltySat` của template (`rules.dart:~1894`, giá trị 5–8 theo các template đã đọc); bỏ nhiệm vụ trừ `ceil(penaltySat / 2)` (`rules.dart:1618`).
> * Giới hạn 3 nhiệm vụ song song, mức cộng hài lòng theo độ khó/Skull: `[UNVERIFIED]`.

#### A. Mục đích &amp; Vai trò

Đóng vai trò là trục tiến trình chiến dịch chính. Người chơi thực hiện các giao kèo của Nhà vua để duy trì sự tin tưởng và hướng tới chiến thắng `[OFFICIAL]`.

#### B. Dữ liệu đầu vào, Trạng thái quản lý &amp; Kết quả đầu ra

* **Đầu vào:** Tiếp nhận nhiệm vụ tại Quest Board ở thị trấn, Kết quả hoàn tất/thất bại nhiệm vụ.
* **Trạng thái quản lý:**  
  * **Thước đo độ hài lòng của Vua:** `King's Satisfaction Meter` (0% – 100%) `[OFFICIAL]`.
  * **Danh sách nhiệm vụ đang kích hoạt:** Tên, Độ khó (`Skull Level` 1–4), Thời hạn (`Days Limit`), Vị trí mục tiêu, Phần thưởng `[OBSERVED]`.
* **Đầu ra:** Điểm King's Satisfaction cập nhật, Thưởng Vàng/Thức ăn/Tài nguyên/XP, hoặc Trigger Game Over.

#### C. Quy tắc đã xác minh từ nguồn

* **Điều kiện thắng Campaign:** Tích lũy điểm King's Satisfaction đạt mốc tối đa **100% King's Favor** `[OFFICIAL]`.
* **Điều kiện thua Campaign:** Điểm King's Satisfaction bị giảm về **0%** do thất bại hoặc trễ hạn nhiều nhiệm vụ `[OFFICIAL]`.
* **Thời hạn nhiệm vụ:** Mỗi nhiệm vụ có đếm ngược số ngày (`Days Limit`). Nếu hết số ngày quy định mà chưa hoàn thành, nhiệm vụ thất bại và bị trừ điểm King's Satisfaction `[OFFICIAL] [OBSERVED]`.

#### D. Mối quan hệ với các hệ thống khác

* **Resource System:** Thưởng Vàng, Thức ăn, Búa, Nguyên liệu khi thắng nhiệm vụ.
* **World Map System:** Hiển thị vị trí mục tiêu giao kèo trên bản đồ.
* **Game Modes System:** Quy định điều kiện thắng/thua trực tiếp cho Campaign Mode.

#### E. Tình huống biên / Lỗi cần xử lý (Edge Cases)

* **Nhận quá nhiều nhiệm vụ cùng lúc:** Giới hạn tối đa 3 nhiệm vụ kích hoạt song song để tránh việc người chơi trễ hạn hàng loạt `[REMAKE PROPOSAL]`.

#### F. Điểm chưa xác minh (`[UNKNOWN]`)

* Công thức tính chính xác lượng điểm King's Satisfaction cộng thêm theo từng cấp độ độ khó Skull (1 Skull vs 4 Skulls).

---

### 3.6\. Deployment &amp; Formation System (Hệ thống Bố trí &amp; Đội hình)

> **Hiện trạng source (`[CURRENT]`):**
> * Đội ra trận tối đa **10** binh sĩ (`GameRules.maxSquad`, `rules.dart:159`); đội rỗng và id trùng bị từ chối (`rules.dart:~2241-2247`). Mốc ~9 bên dưới là tham chiếu game gốc.
> * Có 4 preset đội hình `FormationPreset {line, expanded, wedge, cluster}` (`lib/domain/battle.dart:423`), vị trí xuất phát do `presetPlacement`, và nút xếp tự động (`lib/presentation/screens/deploy_screen.dart`). Chi tiết ở `deployment-and-formation.md`.
> * Lưới "Frontline/Backline" theo nghề và việc lưu preset do người dùng: `[UNVERIFIED]`.

#### A. Mục đích &amp; Vai trò

Cho phép người chơi chuẩn bị chiến thuật, chọn binh sĩ xuất trận và sắp xếp vị trí hàng trước/hàng sau trên lưới đấu trước khi bước vào trận chiến tự động `[OFFICIAL]`.

#### B. Dữ liệu đầu vào, Trạng thái quản lý &amp; Kết quả đầu ra

* **Đầu vào:** Thao tác kéo-thả lính từ danh sách dự bị vào lưới vị trí, Nút chọn Preset đội hình `[OFFICIAL] [OBSERVED]`.
* **Trạng thái quản lý:**  
  * **Lưới vị trí chiến thuật:** Ô hàng trước (*Frontline*) và Ô hàng sau (*Backline*) `[OBSERVED]`.
  * **Giới hạn lính tham chiến (`Deploy Limit`):** Phụ thuộc vào quy mô trận đấu (ví dụ: 4v4, 6v6, 8v8, tối đa \~9 lính) `[OBSERVED] [TRANSCRIPT]`.
* **Đầu ra:** Danh sách binh sĩ xuất trận và tọa độ lưới khởi tạo cho Combat System.

#### C. Quy tắc đã xác minh từ nguồn

* **Bố trí chiến thuật:** Lính cận chiến và cầm khiên ưu tiên xếp hàng trước; lính bắn cung/giao chiến tầm xa xếp hàng sau `[OBSERVED]`.
* **Quản lý lính dự bị:** Cho phép cất lính bị thương nặng hoặc Morale thấp ở lại hàng dự bị nếu số lượng quân vượt quá giới hạn Deploy Limit `[OBSERVED]`.
* **Preset đội hình:** Cho phép lưu và tải lại cấu hình vị trí đội hình nhanh `[OFFICIAL]`.

#### D. Mối quan hệ với các hệ thống khác

* **Soldier System:** Lấy dữ liệu danh sách lính hiện có.
* **Combat System:** Truyền tọa độ xuất phát và danh sách đơn vị tham chiến vào trận đấu.

#### E. Tình huống biên / Lỗi cần xử lý (Edge Cases)

* **Chưa xếp lính nào vào lưới:** Khóa nút `Start Battle` cho đến khi có ít nhất 1 lính trên lưới.
* **Lính bị thương nặng vẫn bị thả vào lưới:** Hiển thị biểu tượng cảnh báo vết thương nguy hiểm trên thẻ lính `[REMAKE PROPOSAL]`.

#### F. Điểm chưa xác minh (`[UNKNOWN]`)

* Thuật toán tự động sắp xếp quân của nút Preset. Kích thước hình học chính xác của lưới Deploy (ví dụ: 3x3 hay 4x4 mỗi bên).

---

### 3.7\. Combat System (Hệ thống Chiến đấu Autobattler)

> **Hiện trạng source (`[CURRENT]`):**
> * `simulateBattle(players, enemies, seed)` (`lib/domain/battle.dart:227`): thuần Dart, **bước 0,1 giây** (`stepSeconds`), `Random(seed)`, không sửa `GameState`. Tối đa `maxBattleSeconds = 120` (1200 nhịp). Khung hình cho UI mỗi `frameSeconds = 0,2`.
> * Mỗi nhịp, đơn vị còn sống chọn **kẻ địch gần nhất** (hòa thì id nhỏ hơn). Trong tầm thì đánh khi hết hồi; ngoài tầm thì di chuyển.
> * Trúng: `rng < accuracy`; accuracy của đơn vị kẹp trong **0,40–0,95** (`stats.dart:214`; hiệu ứng điều kiện có thể kẹp 0,05–0,97). Chí mạng: `rng < crit`, sát thương ×**1,5**.
> * Sát thương: `attack × (0,85…1,15) × hệ số morale × 0,42 (damageScale)` rồi nhân `(1 − giảm giáp)`, với giảm giáp = `d/(d+25)`, `d = defense − xuyên giáp` (tối thiểu 0); sát thương tối thiểu 1 (`battle.dart:288-306`, `stats.dart:72`). Công thức "`Str×1,5`" và "`A/(100+A)`" ở tài liệu thiết kế **không** phải source.
> * Morale: chỉ **quân ta** mất morale khi bị đánh (`moraleLossForHit`, `combat_condition.dart:77`); hệ số sát thương quân ta `0,85 + 0,3 × morale/100`. Khi morale về 0 mà còn sống thì **bỏ chạy** (`fled`) và không còn bị nhắm. Quân địch giữ morale ban đầu. Ngưỡng 20% bên dưới không phải source.
> * Kết quả `Winner {player, enemy, draw}`: `player` khi địch hết còn ta còn; `enemy` khi ta hết; `draw` khi hết thời gian mà hai bên còn quân.
> * Thương vong `CasualtyKind {survived, wounded, dead, deserted}` (`rules.dart:23`).
> * `[PLANNED]`/`[NOT IMPLEMENTED]` **War Horn** (không có trong `lib/` hay `test/`), **phạt thời tiết**, thanh Tide of Battle và bảng Combat Log dạng chữ (`[UNVERIFIED]`; có danh sách `BattleEvent`).

#### A. Mục đích &amp; Vai trò

Mô phỏng trận chiến tự động theo thời gian thực dựa trên sự chuẩn bị chỉ số, trang bị và vị trí của người chơi. Tích hợp khả năng tương tác duy nhất giữa trận qua kỹ năng Sừng chiến `[OFFICIAL]`.

#### B. Dữ liệu đầu vào, Trạng thái quản lý &amp; Kết quả đầu ra

* **Đầu vào:** Danh sách lính và tọa độ lưới từ Deploy System, Thao tác bấm nút Sừng chiến (`War Horn`), Điều kiện thời tiết từ Map.
* **Trạng thái quản lý:**  
  * **Trạng thái đơn vị real-time:** Tọa độ X/Y, HP hiện tại, Morale hiện tại, Trạng thái Animation (Move, Attack, Hit, Die, Flee) `[OBSERVED]`.
  * **Thanh Cục diện trận đấu (`Tide of Battle Bar`):** Hiển thị tương quan lực lượng hai bên `[OBSERVED]`.
  * **Bảng Nhật ký chiến đấu (`Combat Log`):** Ghi nhận chi tiết từng đòn đánh `[OFFICIAL]`.
  * **Cooldown kỹ năng War Horn:** Thời gian hồi chiêu bấm sừng chiến `[OBSERVED]`.
* **Đầu ra:** Kết quả Thắng/Thua, Mức HP/Morale còn lại của sinh tồn, Danh sách lính ngã xuống (Permadeath).

#### C. Quy tắc đã xác minh từ nguồn

* **Tự động chiến đấu (Autobattler):** Đơn vị hai bên tự động di chuyển, tìm mục tiêu gần nhất và tấn công `[OFFICIAL]`.
* **Hiển thị đòn đánh:** Văn bản nổi trên đầu đơn vị báo hiệu đòn trúng (*Hit*), trượt (*Miss*), hoặc chí mạng (*Critical*) `[OBSERVED]`.
* **Sĩ khí &amp; Bỏ chạy:** Khi chịu sát thương lớn hoặc chứng kiến đồng đội chết, Morale của lính bị giảm. Khi Morale chạm đáy, lính sẽ rơi vào hoảng sợ và bỏ chạy khỏi chiến trường (*flee/desert*) `[OBSERVED]`.
* **Sừng chiến (War Horn):** Nhấn nút War Horn giúp tăng ngay một lượng Morale nhỏ cho toàn đội, ngăn lính bỏ chạy `[OFFICIAL] [OBSERVED]`.
* **Phạt thời tiết:** Mưa, tuyết làm giảm độ chính xác và chỉ số đòn đánh `[OFFICIAL]`.
* **Điều kiện thắng/thua:**  
  * *Thắng:* Tiêu diệt toàn bộ lực lượng địch `[OBSERVED]`.
  * *Thua:* Toàn bộ lính đồng minh bị tiêu diệt hoặc hoảng sợ bỏ chạy hết `[OBSERVED]`.

#### D. Mối quan hệ với các hệ thống khác

* **Soldier System:** Áp dụng thương tích và xử lý tử trận vĩnh viễn (Permadeath) lên dữ liệu lính.
* **Result System:** Truyền thống kê sát thương, số mạng diệt và vật phẩm rơi ra.

#### E. Tình huống biên / Lỗi cần xử lý (Edge Cases)

* **Hai đơn vị đánh trúng nhau cùng lúc:** Xử lý tính toán sát thương đồng thời (Simultaneous damage resolution) `[REMAKE PROPOSAL]`.
* **Tất cả lính hai bên cùng bỏ chạy:** Tính là trận đấu Hòa hoặc Thất bại cho người chơi `[REMAKE PROPOSAL]`.

#### F. Điểm chưa xác minh (`[UNKNOWN]`)

* Công thức tính sát thương chi tiết (Damage Formula) dựa trên Strength/Dexterity/Giáp. Công thức tính % chính xác đòn đánh (Hit/Miss Rate). Thuật toán AI chọn mục tiêu khi có nhiều kẻ địch ở khoảng cách bằng nhau.

---

### 3.8\. Progression &amp; Permadeath System (Hệ thống Tiến trình &amp; Permadeath)

> **Hiện trạng source (`[CURRENT]`):**
> * Cấp tối đa **6**. XP cần để lên cấp kế: `{1:18, 2:30, 3:45, 4:62, 5:85}`, cấp 6 là 0 (`xpCurve`, `xpForNext`, `lib/domain/stats.dart:290-291`). Bảng 100/250/500/1000 trong `game-balance.md` là đề xuất cũ, không phải source.
> * Điểm cộng thủ công: `statPoints` (STR/DEX/CON) và `atkPoints` (Công); lưu ở `points`, `atk` trong `Soldier.toJson`.
> * Lính chết không bị xóa ngay: `SoldierStatus.dead`, có thể hồi sinh ở Bia mộ (HP 1, cần điều trị). Lính bỏ chạy: `SoldierStatus.deserted`. Test: `resurrection_test.dart`, `xp_eligibility_test.dart`, `progression_test.dart`.
> * Có hệ thống thành thạo vũ khí (`mastery`), kỹ năng và tài năng (`skills`, `talents`) trong `Soldier`; chưa mô tả ở đây (`[UNVERIFIED]` chi tiết).

#### A. Mục đích &amp; Vai trò

Quản lý sự tăng trưởng sức mạnh của binh sĩ qua cấp độ, đồng thời duy trì áp lực sinh tồn thông qua cơ chế mất lính vĩnh viễn `[OFFICIAL]`.

#### B. Dữ liệu đầu vào, Trạng thái quản lý &amp; Kết quả đầu ra

* **Đầu vào:** Điểm kinh nghiệm (XP) thu nhận sau trận đấu, Quyết định phân bổ điểm thuộc tính của người chơi.
* **Trạng thái quản lý:**  
  * **Cấp độ lính (`Level`):** Cấp 1 đến Cấp 5 (**Max Level 5**) `[OFFICIAL]`.
  * **Điểm thuộc tính chưa phân bổ:** Nút `+` xuất hiện bên cạnh Strength, Dexterity, Constitution khi lên cấp `[OBSERVED]`.
  * **Danh sách lính đã Permadeath:** Xóa khỏi danh sách hoạt động hoặc chuyển dữ liệu sang Gravestone `[COMMUNITY]`.
* **Đầu ra:** Lính tăng chỉ số thuộc tính vĩnh viễn, hoặc Lính bị xóa hoàn toàn khỏi game.

#### C. Quy tắc đã xác minh từ nguồn

* **Giới hạn cấp độ:** Cấp độ lính tối đa trong chiến dịch là **Level 5** `[OFFICIAL]`.
* **Phân bổ thuộc tính thủ công:** Khi lính Level Up, người chơi chủ động nhấn dấu `+` để cộng điểm vào Strength, Dexterity, hoặc Constitution `[OBSERVED]`.
* **Permadeath chính thức:** Binh sĩ tử trận trong giao tranh sẽ bị mất vĩnh viễn cùng toàn bộ trang bị đang mang `[OFFICIAL]`.
* **Cơ chế Gravestone (Cộng đồng):** Cho phép bỏ Vàng để hồi sinh lính tại Gravestone trong Camp, nhưng lính sống lại bị mất sạch trang bị và các chỉ số sinh tồn (HP/Stamina/Morale) ở mức rất thấp (\~20%) `[COMMUNITY]`.

#### D. Mối quan hệ với các hệ thống khác

* **Soldier System:** Cập nhật thuộc tính và cấp độ vĩnh viễn.
* **Camp System:** Đưa lính tử trận vào Gravestone để quản lý hồi sinh.

#### E. Tình huống biên / Lỗi cần xử lý (Edge Cases)

* **Lên cấp giữa chừng nhưng chưa phân bổ điểm:** Tích lũy điểm cộng dồn cho đến khi người chơi nhấn chọn `[REMAKE PROPOSAL]`.

#### F. Điểm chưa xác minh (`[UNKNOWN]`)

* Bảng điểm XP yêu cầu để thăng cấp từ Level 1 đến Level 5.

---

### 3.9\. Game Modes &amp; Game Over System (Hệ thống Chế độ chơi &amp; Kết thúc)

> **Hiện trạng source (`[CURRENT]`):**
> * Chỉ có luồng **Campaign**. `GameState` không có trường `gameMode`.
> * `[PLANNED]` **Sandbox** (hết quân = Game Over) và **Arena** (10 kịch bản thuần chiến đấu): chưa triển khai. Trong Campaign hết quân **không** gây Game Over; có cơ chế gỡ bế tắc `GameRules.isSoftlocked` (`rules.dart:~376`) và tiền hỗ trợ `reliefGrant` (`rules.dart:359`).
> * Lưu: một slot `save_primary`, có `save_backup`; "Save Anytime" theo nghĩa autosave sau mỗi hành động (`GameController._persist`); chi tiết ở `game-state-and-save-system.md`. Số slot khác và autosave khi vào nền: `[PLANNED]`/`[UNVERIFIED]`.

#### A. Mục đích &amp; Vai trò

Định hình cấu trúc luật chơi tổng thể cho 3 chế độ trải nghiệm riêng biệt và xử lý các điều kiện kết thúc chiến dịch `[OFFICIAL]`.

#### B. Dữ liệu đầu vào, Trạng thái quản lý &amp; Kết quả đầu ra

* **Đầu vào:** Lựa chọn chế độ chơi ở Main Menu, Trạng thái King's Satisfaction và Quân số hiện tại.
* **Trạng thái quản lý:**  
  * **Chế độ chơi hiện tại:** `Campaign Mode`, `Sandbox Mode`, hoặc `Arena Mode` `[OFFICIAL]`.
  * **Trạng thái lưu game (`Save State`):** Tính năng **Save Anytime** hỗ trợ lưu tiến trình chơi `[OFFICIAL]`.
* **Đầu ra:** Kích hoạt màn hình kết thúc Game Over hoặc Victory, Xóa Save slot khi thua chiến dịch.

#### C. Quy tắc đã xác minh từ nguồn

* **Campaign Mode:** Chế độ chiến dịch chuẩn có quản lý trại, di chuyển bản đồ mở và làm nhiệm vụ cho Vua. Thắng khi đạt 100% King's Favor; **Game Over khi King's Satisfaction về 0%** `[OFFICIAL]`.
* **Sandbox Mode:** Chế độ chơi tự do. **Quy tắc đặc biệt (từ patch 21/05/2026): Ngay khi hết quân, người chơi sẽ bị Game Over lập tức** `[OFFICIAL]`.
* **Arena Mode:** Chế độ thử thách gồm **10 kịch bản thuần chiến đấu** (pure battle scenarios). Bỏ qua hoàn toàn Doanh trại và Quản lý tài nguyên `[OFFICIAL]`.
* **Tính năng Save Anytime:** Cho phép người chơi lưu game bất kỳ lúc nào `[OFFICIAL]`.

#### D. Mối quan hệ với các hệ thống khác

* Liên kết và quản lý điều kiện dừng của toàn bộ 8 hệ thống gameplay trên.

#### E. Tình huống biên / Lỗi cần xử lý (Edge Cases)

* **Người chơi thoát game giữa trận Autobattler:** Khi load lại Save, khôi phục lại trạng thái trước khi bấm Start Battle hoặc tính trận đó là Thất bại `[REMAKE PROPOSAL]`.

#### F. Điểm chưa xác minh (`[UNKNOWN]`)

* Quy định số lượng slot save chính xác (1 slot duy nhất hay nhiều slot) và các thời điểm tự động lưu (`Autosave triggers`).

---

## 4\. DANH SÁCH CÂU HỎI UNKNOWN CẦN XÁC MINH TRƯỚC KHI CHỐT LOGIC

Đội ngũ lập trình Flutter cần tiến hành kiểm thử thực tế trên game gốc hoặc thống nhất giải pháp `[REMAKE PROPOSAL]` cho các câu hỏi sau trước khi viết mã nguồn:

1. **Công thức chỉ số Binh sĩ:**  
  * *1 điểm Strength cộng chính xác bao nhiêu HP và bao nhiêu Sát thương cận chiến?*
  * *1 điểm Dexterity cộng bao nhiêu % Accuracy và Sát thương bắn cung?*
  * *1 điểm Constitution cộng chính xác bao nhiêu Max HP?*
2. **Công thức Chiến đấu Autobattler:**  
  * *Công thức tính Sát thương thực nhận = (Sát thương kẻ tấn công - Giáp mục tiêu) hay theo tỷ lệ % giảm giáp?*
  * *Tỷ lệ trúng đòn (Hit Rate) và Né đòn (Miss Rate) được tính toán theo công thức toán học nào?*
  * *Khi nhiều kẻ địch ở cự ly bằng nhau, thuật toán AI chọn mục tiêu ưu tiên theo máu thấp nhất hay theo ngẫu nhiên?*
3. **Chỉ số Hồi phục Doanh trại:**  
  * *Lượng HP/Energy/Morale hồi phục qua đêm của Tents, Infirmary, Altar cấp 1 là bao nhiêu điểm cụ thể?*
  * *Công trình nâng cấp lên Cấp 2 và Cấp 3 tăng chính xác bao nhiêu % hiệu suất hồi phục?*
4. **Tiến trình &amp; Kinh nghiệm:**  
  * *Bảng điểm XP cụ thể cần đạt để thăng từ Level 1 đến Level 5 là bao nhiêu?*
  * *Lượng XP nhận được sau mỗi trận đấu được chia đều cho tất cả lính tham chiến hay tính theo số mạng tiêu diệt (Kills)?*
5. **Cơ chế Save &amp; Map:**  
  * *Game gốc tự động lưu (`Autosave`) tại những mốc thời gian cụ thể nào?*
  * *Điểm di chuyển March Points tối đa của quân đoàn là bao nhiêu và tốn bao nhiêu điểm cho mỗi ô núi/rừng/đường lộ?*