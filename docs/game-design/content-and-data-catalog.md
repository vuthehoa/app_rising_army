# DANH MỤC DỮ LIỆU VÀ NỘI DUNG GAME (CONTENT AND DATA CATALOG)

**Dự án:** Rising Army Remake (Flutter iOS - Landscape)  
**Tập tin mục tiêu:** `docs/game-design/content-and-data-catalog.md`

---

## MỤC LỤC

1. [Soldier Catalog (Danh mục Lính &amp; Thuộc tính)](#1-soldier-catalog)
2. [Equipment Catalog (Danh mục Trang bị &amp; Quy tắc)](#2-equipment-catalog)
3. [Resource &amp; Item Catalog (Danh mục Tài nguyên &amp; Vật phẩm)](#3-resource--item-catalog)
4. [Camp Building Catalog (Danh mục Công trình Doanh trại)](#4-camp-building-catalog)
5. [Quest &amp; Event Catalog (Danh mục Nhiệm vụ &amp; Sự kiện)](#5-quest--event-catalog)
6. [World Map &amp; Encounter Catalog (Danh mục Bản đồ &amp; Va chạm)](#6-world-map--encounter-catalog)
7. [Battle Content Catalog (Danh mục Chiến đấu Autobattler)](#7-battle-content-catalog)
8. [Game Modes &amp; Progression Catalog (Chế độ chơi &amp; Tiến trình)](#8-game-modes--progression-catalog)
9. [Data Dictionary (Bảng Từ điển Dữ liệu)](#9-data-dictionary)
10. [Missing Data &amp; QA Checklist (Dữ liệu chưa xác minh &amp; Kiểm thử)](#10-missing-data--qa-checklist)

---

## 1\. SOLDIER CATALOG

### 1.1 Thông tin Cơ bản Binh sĩ

| Thông số / Trường    | Mô tả &amp; Quy tắc                                | Giá trị / Giới hạn           | Mức độ tin cậy |
| -------------------- | ---------------------------------------------- | ---------------------------- | -------------- |
| **Name (Tên)**       | Tên binh sĩ, cho phép người chơi đổi tên tự do | Chuỗi văn bản tùy chỉnh      | `[OFFICIAL]`   |
| **Level (Cấp độ)**   | Cấp độ hiện tại của binh sĩ                    | Giới hạn tối đa: **Level 5** | `[OFFICIAL]`   |
| **Initial Troops**   | Số lượng lính khởi đầu khi tạo New Campaign    | 5 – 6 lính mặc định          | `[TRANSCRIPT]` |
| **Max Roster Size**  | Sức chứa quân đoàn tối đa                      | **Tối đa 20 lính**           | `[OFFICIAL]`   |
| **Recruitment Cost** | Chi phí thuê lính mới tại Tavern               | \~14 – 20 Gold / lính        | `[TRANSCRIPT]` |

### 1.2 Các Thuộc tính Cơ bản (Attributes)

| Thuộc tính                  | Tác dụng trong gameplay                                         | Mức độ tin cậy |
| --------------------------- | --------------------------------------------------------------- | -------------- |
| **Strength (Sức mạnh)**     | Tăng sát thương cận chiến và tăng HP tối đa                     | `[TRANSCRIPT]` |
| **Dexterity (Khéo léo)**    | Tăng độ chính xác (Accuracy) và sát thương vũ khí tầm xa (Cung) | `[TRANSCRIPT]` |
| **Constitution (Thể chất)** | Tăng lượng máu tối đa (Max HP)                                  | `[TRANSCRIPT]` |
| **Speed (Tốc độ)**          | Tăng tốc độ di chuyển và tần suất đòn đánh trong trận           | `[TRANSCRIPT]` |

### 1.3 Thanh Trạng thái Sinh tồn (Vital Meters)

| Thanh trạng thái     | Biểu tượng               | Quy tắc tiêu hao &amp; Phục hồi                                                  | Mức độ tin cậy |
| -------------------- | ------------------------ | ---------------------------------------------------------------------------- | -------------- |
| **Health (HP)**      | Thanh màu đỏ / Máu       | Giảm khi nhận sát thương; hồi phục tại **Infirmary** (Bệnh xá)               | `[OBSERVED]`   |
| **Energy / Stamina** | Biểu tượng Tia sét       | Tiêu hao khi di chuyển/huấn luyện; hồi phục tại **Tents** (Túp lều)          | `[OBSERVED]`   |
| **Morale (Sĩ khí)**  | Biểu tượng Ngọn lửa xanh | Giảm khi thấy đồng đội ngã xuống/thua trận; hồi phục tại **Altar** (Bàn thờ) | `[OBSERVED]`   |

### 1.4 Trạng thái &amp; Tiến trình Binh sĩ

| Trạng thái               | Quy tắc &amp; Ảnh hưởng                                                                | Mức độ tin cậy |
| ------------------------ | ---------------------------------------------------------------------------------- | -------------- |
| **Traits (Đặc tính)**    | Mỗi binh sĩ có các đặc tính cá thể riêng ảnh hưởng đến chỉ số                      | `[OFFICIAL]`   |
| **Injured (Thương tật)** | Lính máu thấp hiển thị thương tật; cần chữa trị tại Infirmary qua đêm              | `[OFFICIAL]`   |
| **Permadeath (Tử trận)** | Lính ngã xuống trong trận đấu không cứu kịp sẽ bị **mất vĩnh viễn**                | `[OFFICIAL]`   |
| **Revived State**        | Hồi sinh tại Gravestone bằng Gold (trở lại không trang bị, HP/Energy/Morale \~20%) | `[COMMUNITY]`  |

---

## 2\. EQUIPMENT CATALOG

### 2.1 Quy tắc Ô Trang bị (Equipment Slots)

Mỗi binh sĩ có đúng **3 ô trang bị**:

1. **Slot 1 - Weapon (Vũ khí):** Quyết định loại đòn đánh (Cận chiến / Tầm xa) và sát thương gốc.
2. **Slot 2 - Off-hand (Phụ kiện / Khiên):** Tăng khả năng phòng thủ, né đòn hoặc chỉ số Accuracy.
3. **Slot 3 - Armor (Giáp):** Tăng giáp (Armor Class), giảm sát thương nhận vào.  
*Nguồn xác minh chính thức:* `[OFFICIAL]` (Game công bố hơn **50 loại vũ khí** và hơn **50 mảnh giáp**).

### 2.2 Danh mục Trang bị Quan sát được

| Tên Trang bị              | Loại                      | Chỉ số / Hiệu ứng quan sát được           | Mức độ tin cậy |
| ------------------------- | ------------------------- | ----------------------------------------- | -------------- |
| **Paladin Sword**         | Vũ khí (Kiếm)             | +15% Accuracy, sát thương cận chiến cao   | `[TRANSCRIPT]` |
| **Improvised Spear**      | Vũ khí (Giáo)             | \-5% Accuracy, đòn đánh tầm dài           | `[TRANSCRIPT]` |
| **Rough Mace**            | Vũ khí (Chùy)             | Sát thương cận chiến cơ bản               | `[TRANSCRIPT]` |
| **Pitchfork**             | Vũ khí (Phản/Đinh ba)     | Vũ khí nông dân, sát thương thấp          | `[TRANSCRIPT]` |
| **Legendary Great Saber** | Vũ khí (Đao huyền thoại)  | Phẩm chất Huyền thoại, sát thương rất cao | `[TRANSCRIPT]` |
| **Legendary Bow**         | Vũ khí (Cung huyền thoại) | Phẩm chất Huyền thoại, tấn công tầm xa    | `[TRANSCRIPT]` |
| **Peasant Tunic**         | Giáp (Áo giáp vải)        | Giáp vải cơ bản, giảm sát thương thấp     | `[TRANSCRIPT]` |
| **Studded Leather Armor** | Giáp (Giáp da)            | Giáp da trung cấp                         | `[TRANSCRIPT]` |

### 2.3 Phẩm chất &amp; Quy tắc Mất trang bị

* **Phẩm chất (Rarity):** Phân cấp từ Thường (Common) đến Huyền thoại (Legendary) `[OBSERVED]`.
* **Quy tắc Permadeath:** Khi lính tử trận trong trận đấu, toàn bộ trang bị mang trên người binh sĩ đó sẽ **mất vĩnh viễn** cùng lính `[OFFICIAL]`.

---

## 3\. RESOURCE &amp; ITEM CATALOG

### 3.1 Danh mục 7 Loại Tài nguyên Chính

| Tài nguyên | Biểu tượng / Tên | Nguồn thu chính                              | Công dụng chính                                | Mức độ tin cậy |
| ---------- | ---------------- | -------------------------------------------- | ---------------------------------------------- | -------------- |
| **Gold**   | Vàng             | Thưởng Quest, thắng trận, bán trang bị       | Trả lương daily, thuê lính, mua đồ, hồi sinh   | `[OBSERVED]`   |
| **Food**   | Thức ăn          | Nhặt trên Map, thưởng Quest, mua ở Market    | Nuôi quân daily (Trừ **1 Food/lính/ngày**)     | `[OBSERVED]`   |
| **Tools**  | Búa / Công cụ    | Mua ở Market (\~8 Gold/Tools), nhặt dã ngoại | Xây dựng, nâng cấp và sửa chữa công trình Camp | `[OBSERVED]`   |
| **Iron**   | Sắt              | Đào đá dã ngoại, thưởng Quest, nhặt trên Map | Xây dựng &amp; nâng cấp công trình cao cấp         | `[OBSERVED]`   |
| **Stone**  | Đá               | Đào đá dã ngoại, thưởng Quest, nhặt trên Map | Xây dựng &amp; nâng cấp công trình Camp            | `[OBSERVED]`   |
| **Wood**   | Gỗ               | Nhặt dã ngoại (4 Wood/node), thưởng Quest    | Xây dựng &amp; nâng cấp công trình Camp            | `[OBSERVED]`   |
| **Cloth**  | Vải              | Mua ở Market, thưởng Quest, rương Loot       | Xây dựng công trình &amp; nâng cấp Tents/Infirmary | `[OBSERVED]`   |

### 3.2 Quy tắc Phí duy trì Hàng ngày (Daily Upkeep)

* Mỗi khi người chơi nhấn **End Day**, hệ thống tự động khấu trừ: **1 Gold + 1 Food / 1 lính / 1 ngày** `[OBSERVED] [TRANSCRIPT]`.
* **Hệ quả cạn kiệt:** Nếu thiếu Thức ăn hoặc Vàng, Morale toàn quân sẽ suy giảm nặng `[TRANSCRIPT]`.

### 3.3 Vật phẩm Đặc biệt

| Vật phẩm                           | Công dụng                           | Thời điểm sử dụng                             | Mức độ tin cậy |
| ---------------------------------- | ----------------------------------- | --------------------------------------------- | -------------- |
| **Revive Medicine (Thuốc cứu hộ)** | Hồi sinh tức thì lính vừa ngã xuống | Sử dụng tại màn hình Result ngay sau trận đấu | `[TRANSCRIPT]` |

---

## 4\. CAMP BUILDING CATALOG

### 4.1 Danh mục Công trình Doanh trại

| Công trình                           | Chức năng chính                        | Quy tắc &amp; Sức chứa                                  | Chi phí xây dựng mẫu                         | Mức độ tin cậy            |
| ------------------------------------ | -------------------------------------- | --------------------------------------------------- | -------------------------------------------- | ------------------------- |
| **Tents (Túp lều)**                  | Phục hồi Energy &amp; Morale qua đêm       | Phụ thuộc vào cấp độ nâng cấp                       | Gold + Wood + Cloth                          | `[OBSERVED]`              |
| **Infirmary (Bệnh xá)**              | Chữa trị HP qua đêm cho lính bị thương | **Sức chứa cố định: 3 lính**                        | Gold + Wood + Tools                          | `[OBSERVED] [TRANSCRIPT]` |
| **Altar (Bàn thờ / Đá cầu nguyện)**  | Khôi phục chỉ số Morale (Sĩ khí)       | Phân bổ lính qua đêm                                | Gold + Stone + Tools                         | `[OBSERVED]`              |
| **Training Fields (Sân huấn luyện)** | Luyện tập tăng Strength / Constitution | Tốn Energy &amp; phí duy trì                            | 30 Gold, 25 Iron, 20 Stone, 8 Tools, 20 Wood | `[TRANSCRIPT]`            |
| **Gravestone (Mộ đá)**               | Hồi sinh lính tử trận bằng Vàng        | Lính hồi sinh mất hết gear, HP/Morale/Stamina \~20% | Tiêu tốn Vàng                                | `[COMMUNITY]`             |
| **Stash (Rương đồ)**                 | Mở rộng sức chứa kho vật phẩm          | Tăng thêm ô kho trang bị                            | Gold + Wood + Stone                          | `[THIRD-PARTY]`           |

### 4.2 Thao tác &amp; Bảo trì Công trình

* **Drag-and-Drop:** Người chơi kéo-thả lính vào các ô trống (slots) của công trình `[OFFICIAL]`.
* **Bảo trì (Wear &amp; Tear):** Công trình ngẫu nhiên bị rạn nứt/hỏng hóc qua ngày, cần dùng Tools/Gỗ/Sắt để sửa chữa `[COMMUNITY]`.

---

## 5\. QUEST &amp; EVENT CATALOG

### 5.1 Cấu trúc Nhiệm vụ (Quest System)

| Thông số                       | Giá trị / Dạng dữ liệu                                                                | Mức độ tin cậy            |
| ------------------------------ | ------------------------------------------------------------------------------------- | ------------------------- |
| **King's Satisfaction Meter**  | Thanh điểm hài lòng của Vua (0 – 100%). Tăng khi thắng Quest, giảm khi trễ/thua Quest | `[OFFICIAL]`              |
| **Quest Difficulty (Độ khó)**  | Biểu hiện bằng số Đầu lâu: **1 Skull đến 4 Skulls**                                   | `[TRANSCRIPT]`            |
| **Deadline (Thời hạn)**        | Tính theo số ngày (ví dụ: **3 ngày, 7 ngày**). Trễ hạn = Thất bại nhiệm vụ            | `[TRANSCRIPT]`            |
| **Quest Reward (Phần thưởng)** | Vàng, Thức ăn, Tài nguyên, XP lính và Điểm **King's Satisfaction**                    | `[OFFICIAL] [TRANSCRIPT]` |

### 5.2 Danh mục Sự kiện Ngẫu nhiên trên Map (Random Events)

| Tên Sự kiện                         | Hành vi &amp; Lựa chọn                 | Kết quả / Tác động                         | Mức độ tin cậy |
| ----------------------------------- | ---------------------------------- | ------------------------------------------ | -------------- |
| **Thầy bói 4 mắt (Fortune Teller)** | Đổi Vàng lấy vận may/sĩ khí        | Trừ Gold, Cộng Morale cho lính             | `[TRANSCRIPT]` |
| **Con Cáo xin ăn (Fox Encounter)**  | Cho Food để nhận trợ giúp          | Trừ Food, Cộng điểm di chuyển March Points | `[TRANSCRIPT]` |
| **Đào đá dã ngoại (Stone Quarry)**  | Tốn thời gian/thể lực để khai thác | Nhận ngẫu nhiên Đá (Stone) / Sắt (Iron)    | `[TRANSCRIPT]` |
| **Giếng ước (Wishing Well)**        | Thả Vàng xuống giếng               | Nhận ngẫu nhiên chỉ số hoặc vật phẩm       | `[TRANSCRIPT]` |

---

## 6\. WORLD MAP &amp; ENCOUNTER CATALOG

### 6.1 Cơ chế Di chuyển &amp; Bản đồ

| Cơ chế                  | Mô tả &amp; Quy tắc                                                       | Mức độ tin cậy |
| ----------------------- | --------------------------------------------------------------------- | -------------- |
| **March Points**        | Điểm di chuyển trong ngày. Tiêu hao theo khoảng cách di chuyển        | `[TRANSCRIPT]` |
| **Terrain Penalty**     | Địa hình hiểm trở (Núi, Ruộng) tốn nhiều March Points hơn và làm chậm | `[TRANSCRIPT]` |
| **Fog of War**          | Tầm nhìn tròn xoay quanh đội quân mở rộng rộng bản đồ                 | `[TRANSCRIPT]` |
| **WASD Camera Control** | Cho phép điều khiển camera bản đồ bằng phím WASD                      | `[OFFICIAL]`   |

### 6.2 Loại Địa điểm &amp; Chạm trán (Encounter Types)

* **Towns (Thị trấn):** Bản đồ gồm 5–6 thị trấn chính chứa Tavern, Blacksmith, Market, Quest Board `[COMMUNITY]`.
* **Resource Pickups:** Điểm nhặt tài nguyên cố định/ngẫu nhiên (Wood, Stone, Gold) `[TRANSCRIPT]`.
* **Bandit Ambush (Băng cướp):** Va chạm kích hoạt màn hình Deploy giao tranh `[TRANSCRIPT]`.
* **Wild Beasts Encounter (Quái thú dã ngoại):** Đụng độ thú dữ trên map `[OFFICIAL]`.
* **Weather System (Hệ thống thời tiết):** Thời tiết xấu gây phạt chỉ số lính khi vào trận `[OFFICIAL]`.

---

## 7\. BATTLE CONTENT CATALOG

### 7.1 Cơ chế Chiến đấu Autobattler

* **Tính chất:** Trận đấu diễn ra hoàn toàn tự động dựa trên vị trí dàn quân ban đầu `[OFFICIAL]`.
* **Tương tác duy nhất trong trận:** Bấm nút **War Horn (Sừng chiến)** để tăng Morale, chống lính hoảng sợ bỏ chạy (`flee/desert`) `[OFFICIAL]`.
* **Combat Log (Nhật ký chiến đấu):** Bảng hiển thị thông tin chi tiết đòn đánh thêm từ cập nhật 21/05/2026 `[OFFICIAL]`.
* **Chỉ số hiển thị đòn đánh:** Hit, Miss, Critical Damage nổi trên đầu đơn vị `[OBSERVED]`.
* **Giới hạn lính tham chiến:** Bị khống chế theo cự ly stage/địch (ví dụ: **4v4, 6v6, 8v8, tối đa 9 lính**) `[TRANSCRIPT]`.

### 7.2 Thống kê Kết quả Trận đấu (Result Screen)

Bảng kết quả hiển thị 3 cột dữ liệu cho từng binh sĩ:

1. **Kills:** Số mạng tiêu diệt.
2. **Damage Dealt:** Tổng sát thương gây ra.
3. **Damage Taken:** Tổng sát thương nhận vào `[OBSERVED]`.

---

## 8\. GAME MODES &amp; PROGRESSION CATALOG

### 8.1 Danh mục 3 Chế độ Chơi

| Chế độ            | Đặc điểm &amp; Quy tắc                                              | Điều kiện Game Over               | Mức độ tin cậy |
| ----------------- | --------------------------------------------------------------- | --------------------------------- | -------------- |
| **Campaign Mode** | Chiến dịch chuẩn, quản lý Camp, làm Quest đạt 100% King's Favor | Thanh **King's Satisfaction = 0** | `[OFFICIAL]`   |
| **Sandbox Mode**  | Quản lý tự do. **Luật mới:** Hết quân = Game Over lập tức       | **Cạn kiệt toàn bộ quân lính**    | `[OFFICIAL]`   |
| **Arena Mode**    | **10 kịch bản thuần chiến đấu**; không có Camp, không quản lý   | Thua kịch bản thử thách           | `[OFFICIAL]`   |

### 8.2 Tiến trình Chiến dịch (Campaign Progression)

* **Max Level Lính:** Level 5 `[OFFICIAL]`.
* **Max Roster Size:** 20 lính `[OFFICIAL]`.
* **Mục tiêu thắng Campaign:** Đạt điểm **100% King's Favor / Satisfaction** `[OFFICIAL]`.

---

## 9\. DATA DICTIONARY

Bảng tra cứu quy chuẩn kiểu dữ liệu dự kiến cho đội ngũ lập trình Flutter:

| Tên trường (Field Name) | Kiểu dữ liệu dự kiến | Mô tả / Giá trị mẫu                 | Mức độ xác minh |
| ----------------------- | -------------------- | ----------------------------------- | --------------- |
| `soldierId`             | `String` (UUID v4)   | Định danh duy nhất của binh sĩ      | `[PROPOSED]`    |
| `soldierName`           | `String`             | Tên binh sĩ (cho phép edit)         | `[OFFICIAL]`    |
| `level`                 | `int`                | Cấp độ lính (1 đến 5)               | `[OFFICIAL]`    |
| `strength`              | `int`                | Thuộc tính Strength                 | `[TRANSCRIPT]`  |
| `dexterity`             | `int`                | Thuộc tính Dexterity                | `[TRANSCRIPT]`  |
| `constitution`          | `int`                | Thuộc tính Constitution             | `[TRANSCRIPT]`  |
| `speed`                 | `int`                | Thuộc tính Speed                    | `[TRANSCRIPT]`  |
| `currentHp` / `maxHp`   | `double` / `double`  | Máu hiện tại / Tối đa               | `[OBSERVED]`    |
| `currentEnergy`         | `double`             | Thể lực hiện tại (0 - 100)          | `[OBSERVED]`    |
| `currentMorale`         | `double`             | Sĩ khí hiện tại (0 - 100)           | `[OBSERVED]`    |
| `equipmentWeaponId`     | `String?`            | ID vũ khí đang trang bị             | `[OFFICIAL]`    |
| `equipmentOffhandId`    | `String?`            | ID phụ kiện/khiên đang trang bị     | `[OFFICIAL]`    |
| `equipmentArmorId`      | `String?`            | ID giáp đang trang bị               | `[OFFICIAL]`    |
| `isInjured`             | `bool`               | Trạng thái bị thương nặng           | `[OFFICIAL]`    |
| `isDead`                | `bool`               | Trạng thái tử trận (Permadeath)     | `[OFFICIAL]`    |
| `gold`                  | `int`                | Số Vàng trong kho                   | `[OBSERVED]`    |
| `food`                  | `int`                | Số Thức ăn trong kho                | `[OBSERVED]`    |
| `tools`                 | `int`                | Số Công cụ/Búa trong kho            | `[OBSERVED]`    |
| `iron`                  | `int`                | Số Sắt trong kho                    | `[OBSERVED]`    |
| `stone`                 | `int`                | Số Đá trong kho                     | `[OBSERVED]`    |
| `wood`                  | `int`                | Số Gỗ trong kho                     | `[OBSERVED]`    |
| `cloth`                 | `int`                | Số Vải trong kho                    | `[OBSERVED]`    |
| `kingsSatisfaction`     | `double`             | Điểm hài lòng của Vua (0.0 - 100.0) | `[OFFICIAL]`    |
| `gameMode`              | `Enum`               | `campaign`, `sandbox`, `arena`      | `[OFFICIAL]`    |

---

## 10\. MISSING DATA &amp; QA CHECKLIST

### 10.1 Danh sách Thông số Chưa có Nguồn Xác minh (`[UNKNOWN]`)

Các thông số dưới đây **chưa có con số chính thức từ nhà phát triển**, đội ngũ Flutter cần thiết lập giá trị cấu hình linh hoạt (`config.json`) và đo đạc qua Playtest:

1. **Công thức Sát thương (Damage Formula):** Tỷ lệ ảnh hưởng chính xác của Strength/Dexterity lên đòn cận chiến/bắn xa.
2. **Công thức Né đòn (Evasion Formula):** Tỷ lệ % Miss đòn đánh theo chỉ số Speed.
3. **Tỷ lệ Phục hồi Camp (Camp Regeneration Rate):** Tỷ lệ hồi HP/Energy/Morale qua đêm theo từng cấp độ công trình Tents/Infirmary/Altar.
4. **Tỷ lệ Rớt đồ (Loot Drop Rate):** Tỷ lệ xuất hiện vật phẩm Rare/Legendary trong rương Loot Chest sau trận.
5. **Tỷ lệ Xuất hiện Sự kiện (Event Spawn Rate):** Tỷ lệ xuất hiện chướng ngại vật và nút sự kiện ngẫu nhiên trên Overworld Map.

### 10.2 QA Checklist cho Đội ngũ Kiểm thử

* [ ] **QA-01 (Max Level):** Kiểm tra binh sĩ không thể vượt quá Level 5 khi nhận XP ở Result screen.
* [ ] **QA-02 (Max Roster):** Kiểm tra nút Thuê lính ở Tavern bị khóa/vô hiệu hóa khi quân đoàn đã đủ 20 lính.
* [ ] **QA-03 (Permadeath Check):** Xác nhận lính tử trận trong trận đấu bị xóa mất vĩnh viễn cùng 3 ô trang bị mang theo.
* [ ] **QA-04 (Upkeep Deduct):** Kiểm tra đúng 1 Gold + 1 Food / lính bị trừ khỏi kho mỗi khi nhấn `End Day`.
* [ ] **QA-05 (Sandbox Game Over):** Xác nhận trong Sandbox Mode, ngay khi lính cuối cùng tử trận, màn hình Game Over xuất hiện lập tức.
* [ ] **QA-06 (King's Pleasure Game Over):** Xác nhận trong Campaign Mode, khi điểm `kingsSatisfaction` rỗng (bằng 0), game chuyển sang màn hình Game Over.
* [ ] **QA-07 (Infirmary Capacity):** Kiểm tra Bệnh xá không cho phép kéo-thả quá 3 lính cùng lúc.
* [ ] **QA-08 (Arena Mode Boundaries):** Xác nhận chế độ Arena khởi chạy trực tiếp kịch bản chiến đấu mà không tải giao diện Camp hay Market.