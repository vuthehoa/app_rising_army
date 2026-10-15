# TÀI LIỆU CÂN BẰNG GAMEPLAY (GAME BALANCE SPECIFICATION)

**Dự án:** Rising Army Remake (Flutter iOS - Landscape)  
**Tập tin mục tiêu:** `docs/game-design/game-balance.md`

---

> **Cập nhật theo TASK-003: đối chiếu với source.** Cột "Trạng thái: Đã xác minh" trong các bảng dưới đây nghĩa là *đã xác minh từ nguồn bên ngoài về game gốc* (Steam, video, cộng đồng), **không** có nghĩa là source của remake áp dụng giá trị đó. Giá trị thực tế của remake nằm trong các khối **"Hiện trạng source"** dưới mỗi mục; khi hai bên khác nhau thì source đúng với hiện trạng, còn giá trị trong bảng là tham chiếu game gốc hoặc đề xuất `[PLANNED]`. Cân bằng thực tế được hiệu chỉnh bằng `tool/*_sim.dart` và kiểm bởi `test/economy_balance_test.dart`; không sửa theo bảng này mà không có quyết định thiết kế.

---

## MỤC LỤC

1. [Tổng quan về Cân bằng Gameplay &amp; Nguyên tắc Phân cấp Chứng cứ](#1-t%E1%BB%95ng-quan-v%E1%BB%81-c%C3%A2n-b%E1%BA%B1ng-gameplay--nguy%C3%AAn-t%E1%BA%AFc-ph%C3%A2n-c%E1%BA%A5p-ch%E1%BB%A9ng-c%E1%BB%A9)
2. [Cân bằng Binh sĩ (Soldier Balance)](#2-c%C3%A2n-b%E1%BA%B1ng-binh-s%C4%A9-soldier-balance)
3. [Cân bằng Chiến đấu (Combat Balance)](#3-c%C3%A2n-b%E1%BA%B1ng-chi%E1%BA%BFn-%C4%91%E1%BA%A5u-combat-balance)
4. [Cân bằng Kinh tế &amp; Tài nguyên (Economy Balance)](#4-c%C3%A2n-b%E1%BA%B1ng-kinh-t%E1%BA%BF--t%C3%A0i-nguy%C3%AAn-economy-balance)
5. [Cân bằng Doanh trại &amp; Công trình (Camp Balance)](#5-c%C3%A2n-b%E1%BA%B1ng-doanh-tr%E1%BA%A1i--c%C3%B4ng-tr%C3%ACnh-camp-balance)
6. [Cân bằng Bản đồ &amp; Nhiệm vụ (Map &amp; Quest Balance)](#6-c%C3%A2n-b%E1%BA%B1ng-b%E1%BA%A3n-%C4%91%E1%BB%93--nhi%E1%BB%87m-v%E1%BB%A5-map--quest-balance)
7. [Cân bằng Tiến trình &amp; Độ khó (Progression &amp; Difficulty Balance)](#7-c%C3%A2n-b%E1%BA%B1ng-ti%E1%BA%BFn-tr%C3%ACnh--%C4%91%E1%BB%99-kh%C3%B3-progression--difficulty-balance)
8. [Cân bằng Khác biệt giữa các Chế độ chơi (Game Mode Balance)](#8-c%C3%A2n-b%E1%BA%B1ng-kh%C3%A1c-bi%E1%BB%87t-gi%E1%BB%AFa-c%C3%A1c-ch%E1%BA%BF-%C4%91%E1%BB%99-ch%C6%A1i-game-mode-balance)
9. [Kế hoạch Kiểm thử Cân bằng (Balance Test Plan)](#9-k%E1%BA%BF-ho%E1%BA%A1ch-ki%E1%BB%83m-th%E1%BB%AD-c%C3%A2n-b%E1%BA%B1ng-balance-test-plan)
10. [Bảng Báo cáo Tổng hợp Thông số Cân bằng](#10-b%E1%BA%A3ng-b%C3%A1o-c%C3%A1o-t%E1%BB%95ng-h%E1%BB%A3p-th%C3%B4ng-s%E1%BB%91-c%C3%A2n-b%E1%BA%B1ng)
11. [Danh sách Ưu tiên Cần Đo đạc &amp; Playtest](#11-danh-s%C3%A1ch-%C6%B0u-ti%C3%AAn-c%E1%BA%A7n-%C4%91o-%C4%91%E1%BA%A1c--playtest)

---

## 1\. Tổng quan về Cân bằng Gameplay &amp; Nguyên tắc Phân cấp Chứng cứ

Tài liệu này tổng hợp toàn bộ các chỉ số, hệ số và quy tắc cân bằng toán học thu thập được từ các nguồn về game *Rising Army* (Arkbits). Nhằm đảm bảo tính chính xác và không nhầm lẫn giữa cơ chế gốc và thiết kế thử nghiệm cho bản Flutter Remake, mọi thông số được phân loại minh bạch theo 5 nhãn bằng chứng:

* `[OFFICIAL]`: Thông số được xác nhận chính thức từ nhà phát triển Arkbits (Steam Store, Release Notes, Patch Notes).
* `[OBSERVED]` / `[TRANSCRIPT]`: Thông số quan sát trực tiếp từ các video gameplay playthrough thực tế (AboboKnows, NguyeZ Gaming) hoặc bóc tách từ phụ đề.
* `[COMMUNITY]`: Thông số tổng hợp từ bài đánh giá, diễn đàn thảo luận của cộng đồng người chơi trên Steam/Reddit.
* `[REMAKE PROPOSAL]`: Đề xuất giá trị thử nghiệm cân bằng dành riêng cho bản Flutter Remake, cần trải qua kiểm thử (playtest).
* `[UNKNOWN]`: Chỉ số ẩn trong source code Godot gốc chưa được xác minh hoặc không có dữ liệu định lượng.

---

## 2\. Cân bằng Binh sĩ (Soldier Balance)

> **Hiện trạng source (`[CURRENT]`):**
> * Sức chứa quân đoàn: `6 + 4 × cấp Doanh trại` (`GameRules.rosterCap`, `lib/domain/rules.dart:321`); trần 20 `[UNVERIFIED]`/cần quyết định.
> * Quân khởi đầu: 6 (`GameRules.startRoster`, `rules.dart:163`).
> * Cấp tối đa: **6** (`maxSoldierLevel`, `lib/domain/stats.dart:286`).
> * XP lên cấp: `{1:18, 2:30, 3:45, 4:62, 5:85}` (`xpCurve`, `stats.dart:290`), thay cho bảng 100/250/500/1000.
> * Thuộc tính huấn luyện: `Stat {str, dex, con}`; tốc độ là chỉ số dẫn xuất; có điểm Công riêng (`atkPoints`).
> * Ô trang bị: `Slot {weapon, armor, shield, helmet, accessory}` (`models.dart:22`).

| Tên thông số                                  | Giá trị xác minh / Đề xuất                                                  | Đơn vị &amp; Điều kiện áp dụng              | Nguồn &amp; Nhãn bằng chứng               | Trạng thái     | Ảnh hưởng đến Gameplay                                    |
| --------------------------------------------- | --------------------------------------------------------------------------- | --------------------------------------- | ------------------------------------- | -------------- | --------------------------------------------------------- |
| **Sức chứa Quân đoàn tối đa (Max Army Size)** | 20 binh sĩ                                                                  | Tối đa lính sở hữu trong Campaign       | Steam Store `[OFFICIAL]`              | Đã xác minh    | Giới hạn quy mô quân đội, tránh lạm phát lính.            |
| **Cấp độ Tối đa (Max Level)**                 | Level 5                                                                     | Cấp tối đa lính đạt được trong Campaign | Community Reviews `[COMMUNITY]`       | Đã xác minh    | Giới hạn trần sức mạnh binh sĩ, giữ độ thử thách.         |
| **Quân số Khởi đầu (Starting Troops)**        | 5 – 6 lính                                                                  | Khi khởi tạo New Campaign               | Video Playthrough `[OBSERVED]`        | Đã xác minh    | Đảm bảo đội hình tối thiểu để đi farm nhiệm vụ đầu.       |
| **Thuộc tính Cơ bản (Base Attributes)**       | 4 chỉ số: Strength, Dexterity, Constitution, Speed                          | Điểm cộng trực tiếp hoặc từ trang bị    | Store / Video `[OFFICIAL] [OBSERVED]` | Đã xác minh    | Định hình vai trò lính (Cận chiến / Tầm xa / Chống chịu). |
| **Thanh Sinh tồn (Vital Meters)**             | 3 thanh: HP (Máu), Energy (Thể lực), Morale (Tinh thần)                     | Giá trị 0 - 100%                        | Video Playthrough `[OBSERVED]`        | Đã xác minh    | Yêu cầu xoay tua lính vào công trình nghỉ ngơi.           |
| **Điểm thuộc tính khi Level Up**              | +1 điểm chọn thủ công (Str/Dex/Con)                                         | Mỗi khi đủ XP thăng cấp                 | Video Playthrough `[OBSERVED]`        | Đã xác minh    | Người chơi tự do build định hướng lính.                   |
| **Hệ số XP cần để thăng cấp**                 | Level 1→2: 100 XP; Level 2→3: 250 XP; Level 3→4: 500 XP; Level 4→5: 1000 XP | Tích lũy XP sau mỗi trận đấu            | `[REMAKE PROPOSAL]`                   | Đề xuất Remake | Tạo nhịp độ tăng trưởng lính hợp lý (cần playtest).       |
| **3 Ô Trang bị (Equipment Slots)**            | Ô 1: Vũ khí; Ô 2: Off-hand/Khiên; Ô 3: Giáp                                 | Áp dụng cho từng lính                   | Steam Store `[OFFICIAL]`              | Đã xác minh    | Hơn 50 vũ khí &amp; 50 giáp tạo sự đa dạng build.             |
| **Thương tật &amp; Permadeath**                   | Tử trận vĩnh viễn nếu HP = 0 và không cứu trợ                               | Khi lính ngã xuống trong trận           | Steam Store `[OFFICIAL]`              | Đã xác minh    | Tạo áp lực chiến thuật cao, mỗi mất mát là vĩnh viễn.     |

---

## 3\. Cân bằng Chiến đấu (Combat Balance)

> **Hiện trạng source (`[CURRENT]`):**
> * **War Horn:** `[PLANNED]`/`[NOT IMPLEMENTED]` (không có trong `lib/`, `test/`).
> * **Thời tiết:** `[PLANNED]`/`[NOT IMPLEMENTED]`.
> * **Trúng đòn:** accuracy của đơn vị kẹp **0,40–0,95** (`lib/domain/stats.dart:214`); trong trận, hiệu ứng điều kiện kẹp 0,05–0,97 (`battle.dart:~270`). Công thức `Base + Dex×2% − Evasion` là đề xuất, không phải source.
> * **Sát thương:** `attack × (0,85…1,15) × hệ số morale × 0,42 × (1 − giảm giáp)`, giảm giáp `d/(d+25)` với `d = defense − xuyên giáp` (≥ 0), tối thiểu 1 (`battle.dart:288-306`, `stats.dart:72`). Công thức `(Base + Str×1,5) × (1 − A/(100+A))` là đề xuất, không phải source.
> * **Chí mạng:** sát thương ×1,5 (khớp đề xuất); tỉ lệ `crit` tính theo chỉ số, vũ khí và hiệu ứng (`stats.dart:200-206`), không cố định 5%.
> * **Morale:** chỉ quân ta mất morale khi bị đánh (`moraleLossForHit`), bỏ chạy khi morale về **0** (không phải <20%); địch không bỏ chạy. Hệ số sát thương quân ta `0,85 + 0,3 × morale/100`.
> * **Tick/thời lượng:** bước 0,1 giây, tối đa 120 giây (`stepSeconds`, `maxBattleSeconds`); hết giờ mà hai bên còn quân → `Winner.draw`.
> * **RNG:** `Random(seed)` chuẩn của Dart; ngoài trận `Random(seed × 7919 + rngCounter)` (`rules.dart:165`). Không dùng Mersenne Twister hay Xorshift.
> * **Thương vong:** `CasualtyKind {survived, wounded, dead, deserted}`.

| Tên thông số                                      | Giá trị xác minh / Đề xuất                                                                                                           | Đơn vị &amp; Điều kiện áp dụng                  | Nguồn &amp; Nhãn bằng chứng               | Trạng thái                             | Ảnh hưởng đến Gameplay                                      |
| ------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------- | ------------------------------------- | -------------------------------------- | ----------------------------------------------------------- |
| **Kỹ năng Sừng chiến (War Horn)**                 | Hồi +15 đến +20 Morale toàn đội                                                                                                      | Kích hoạt thủ công giữa trận (Cooldown 15s) | Video / Store `[OFFICIAL] [OBSERVED]` | Đã xác minh (Cơ chế) / Remake (Chỉ số) | Cứu nguy khi lính vỡ sĩ khí bỏ chạy.                        |
| **Phạt do Thời tiết xấu (Weather Penalty)**       | \-10% đến -20% Accuracy / Speed                                                                                                      | Khi giao tranh trong Mưa / Tuyết            | Patch Notes `[OFFICIAL]`              | Đã xác minh (Cơ chế) / Remake (Chỉ số) | Buộc người chơi cân nhắc thời tiết trên Map trước khi đánh. |
| **Tác động của Morale (Morale Impact)**           | &lt; 20% Morale: Lính có xác suất bỏ chạy (*Flee*)                                                                                      | Tính toán trong thời gian thực giữa trận    | Video Playthrough `[OBSERVED]`        | Đã xác minh (Cơ chế) / Remake (Chỉ số) | Thua trận do vỡ sĩ khí dù còn HP.                           |
| **Công thức Sát thương Cận chiến (Melee Damage)** | $\\text{Damage} = (\\text{Base Weapon Dmg} + \\text{Strength} \\times 1.5) \\times (1 - \\frac{\\text{Armor}}{100 + \\text{Armor}})$ | Tính khi đòn đánh trúng mục tiêu            | `[REMAKE PROPOSAL]`                   | Đề xuất Remake                         | Cân bằng giữa Strength và chỉ số giáp (cần playtest).       |
| **Công thức Tỷ lệ Trúng (Accuracy Rate)**         | $\\text{Hit Rate} = \\text{Base Accuracy} + (\\text{Dexterity} \\times 2%) - \\text{Target Evasion}$                                 | Giới hạn tối thiểu 5%, tối đa 95%           | `[REMAKE PROPOSAL]`                   | Đề xuất Remake                         | Dexterity đóng vai trò quan trọng cho lính bắn cung.        |
| **Đòn Chí mạng (Critical Hit Rate &amp; Dmg)**        | Tỷ lệ 5% cơ bản; Sát thương Crit = 150% Damage                                                                                       | Áp dụng cho mọi đòn đánh                    | `[REMAKE PROPOSAL]`                   | Đề xuất Remake                         | Tạo yếu tố bất ngờ ngẫu nhiên trong trận.                   |
| **Công thức Sát thương / Né tránh gốc Godot**     | `[UNKNOWN]`                                                                                                                          | Code ẩn trong Godot Engine                  | `[UNKNOWN]`                           | Cần đo đạc                             | Chưa có dữ liệu chính thức từ Arkbits.                      |

---

## 4\. Cân bằng Kinh tế &amp; Tài nguyên (Economy Balance)

> **Hiện trạng source (`[CURRENT]`):**
> * **Upkeep theo cấp**, không phải 1 + 1 cố định: vàng và lương thực mỗi ngày `{1:1, 2:1, 3:1, 4:2, 5:2, 6:3}` (`UpkeepEconomy`, `lib/domain/economy.dart:105-130`).
> * **Giá tuyển:** giá nền `{1:10, 2:15, 3:25}` + phần theo chỉ số, trần `{1:16, 2:24, 3:120}` (`HireEconomy`, `economy.dart:~138`); ứng viên tối đa cấp 3.
> * **Tài nguyên:** `Res {food, coins, wood, iron, tools, stone, cloth}`; khởi đầu food 48, coins 50, wood 30, stone 15, iron 9, tools 5, cloth 5 (`StartingEconomy`, `economy.dart:18`).
> * Giá công cụ ~8, chi phí Sân huấn luyện, tỉ lệ bán lại 50%, lạm phát +15%: `[UNVERIFIED]`; chi phí xây thật nằm ở `ConstructionEconomy` (`economy.dart`) và chưa được liệt kê ở đây.

| Tên thông số                                          | Giá trị xác minh / Đề xuất                        | Đơn vị &amp; Điều kiện áp dụng           | Nguồn &amp; Nhãn bằng chứng        | Trạng thái     | Ảnh hưởng đến Gameplay                                      |
| ----------------------------------------------------- | ------------------------------------------------- | ------------------------------------ | ------------------------------ | -------------- | ----------------------------------------------------------- |
| **Phí Duy duy trì Hàng ngày (Daily Upkeep)**          | 1 Vàng + 1 Thức ăn / 1 lính / 1 ngày              | Tự động trừ khi nhấn `End Day`       | Video Playthrough `[OBSERVED]` | Đã xác minh    | Đặt giới hạn kinh tế, không thể nuôi quá nhiều lính vô hạn. |
| **Giá Thuê Lính mới (Recruit Cost)**                  | 14 – 20 Vàng / lính                               | Mua tại Tavern trong thị trấn        | Video Playthrough `[OBSERVED]` | Đã xác minh    | Phí tổn đầu tư lính mới ở mức vừa phải đầu game.            |
| **Giá Mua Công cụ (Tools Price)**                     | \~8 Vàng / 1 Tools                                | Mua tại Chợ (Market)                 | Video Playthrough `[OBSERVED]` | Đã xác minh    | Tools là tài nguyên quan trọng cho xây dựng/sửa chữa.       |
| **Chi phí Xây Sân huấn luyện (Training Fields Cost)** | 30 Gold, 25 Iron, 20 Stone, 8 Tools, 20 Wood      | Chi phí xây dựng công trình nâng cao | Video Playthrough `[OBSERVED]` | Đã xác minh    | Mẫu chi phí xây dựng công trình cao cấp.                    |
| **Danh mục 7 Tài nguyên**                             | Gold, Food, Tools, Iron, Stone, Wood, Cloth       | Quản lý trong Kho đồ (Stash)         | Video Playthrough `[OBSERVED]` | Đã xác minh    | Hệ thống tài nguyên đa dạng phục vụ nâng cấp.               |
| **Giá Mua / Bán Trang bị (Item Buy/Sell Ratio)**      | Bán lại = 50% Giá mua tại Blacksmith              | Áp dụng khi giao dịch                | `[REMAKE PROPOSAL]`            | Đề xuất Remake | Tránh việc người chơi mua bán đầu cơ tích trữ.              |
| **Hệ số Lạm phát Cửa hàng theo Tiến trình**           | Giá trang bị tăng 15% sau mỗi cột mốc Skull Quest | Áp dụng tại Thị trấn                 | `[REMAKE PROPOSAL]`            | Đề xuất Remake | Giữ độ cân bằng kinh tế giai đoạn giữa và cuối game.        |

---

## 5\. Cân bằng Doanh trại &amp; Công trình (Camp Balance)

> **Hiện trạng source (`[CURRENT]`):**
> * Công trình trong trại: `FacilityType {meleeYard, archeryRange, enduranceYard, infirmary, storageChest, gravestone, barracks}`; cấp: `Building {barracks, smithy, tavern}` (cấp 0–3). **Không có `Tents` và `Altar`**, nên các dòng Lều/Altar trong bảng là đề xuất `[PLANNED]`.
> * Sức chứa: 3 chỗ mỗi công trình nhận lính, 6 ở cấp 2 (`Facility.capacity/upgradedCapacity`); Lều cứu thương nhận tối đa 3 ở cấp 1.
> * Tác dụng qua đêm lấy từ `facilityEffects` (`lib/domain/building_effects.dart`); giá trị hồi cụ thể theo cấp `[UNVERIFIED]` ở đây. Các con số +30 Energy, +15 Morale, +40% HP, +1 stat/2 ngày trong bảng là đề xuất, chưa xác nhận khớp source.
> * **Hồi sinh ở Bia mộ:** trả vàng, **HP = 1**, `needsTreatment = true`, năng lượng/tinh thần giữ nguyên (`rules.dart:639`); không phải ~20%.
> * Công trình hỏng 5%/ngày: chưa thấy trong source (`[UNVERIFIED]`).

| Tên thông số                                   | Giá trị xác minh / Đề xuất                                            | Đơn vị &amp; Điều kiện áp dụng       | Nguồn &amp; Nhãn bằng chứng                            | Trạng thái              | Ảnh hưởng đến Gameplay                                          |
| ---------------------------------------------- | --------------------------------------------------------------------- | -------------------------------- | -------------------------------------------------- | ----------------------- | --------------------------------------------------------------- |
| **Sức chứa Bệnh xá (Infirmary Capacity)**      | 3 lính cố định                                                        | Tối đa 3 lính chữa trị qua đêm   | Video Playthrough `[OBSERVED]`                     | Đã xác minh             | Giới hạn tốc độ chữa thương, buộc phải luân chuyển lính.        |
| **Hồi sinh tại Mộ đá (Gravestone Revive)**     | Hồi sinh tốn Gold; Lính trở lại mất trang bị, HP/Stamina/Morale \~20% | Áp dụng cho lính vừa tử trận     | Community Reviews `[COMMUNITY]`                    | Đã xác minh (Cộng đồng) | Chi phí hồi sinh đắt đỏ, trả giá cho việc lơi lỏng chiến thuật. |
| **Hồi phục Thể lực &amp; Tinh thần ở Lều (Tents)** | Hồi +30 Energy &amp; +15 Morale qua đêm                                   | Lính gán ô Lều khi `End Day`     | `[REMAKE PROPOSAL]`                                | Đề xuất Remake          | Đảm bảo lính khôi phục sức chiến đấu sau 1-2 ngày nghỉ.         |
| **Hồi phục HP ở Bệnh xá (Infirmary Healing)**  | Hồi +40% Max HP qua đêm / lính                                        | Lính gán ô Bệnh xá khi `End Day` | `[REMAKE PROPOSAL]`                                | Đề xuất Remake          | Lính thương nặng cần nằm viện khoảng 2-3 ngày.                  |
| **Hiệu suất Sân huấn luyện (Training Rate)**   | +1 điểm Strength/Constitution sau 2 ngày huấn luyện                   | Tốn 15 Energy &amp; 10 Morale / ngày | `[REMAKE PROPOSAL]`                                | Đề xuất Remake          | Đổi thời gian và năng lượng lấy chỉ số thuộc tính.              |
| **Tỷ lệ Công trình bị Hỏng ngẫu nhiên**        | 5% xác suất mỗi công trình / ngày                                     | Tính khi nhấn `End Day`          | Community / Remake `[COMMUNITY] [REMAKE PROPOSAL]` | Đề xuất Remake          | Yêu cầu tiêu tốn Tools và Wood để bảo trì.                      |

---

## 6\. Cân bằng Bản đồ &amp; Nhiệm vụ (Map &amp; Quest Balance)

> **Hiện trạng source (`[CURRENT]`):**
> * **Di chuyển:** thể lực `HeroState.stamina` tối đa 100; chi phí = `0,05 × hệ số địa hình`: đồng bằng/bãi cỏ 1,0; rừng thưa 1,6; rừng rậm 2,3; đồi 1,8; sườn núi 3,2; ven nước 1,3; cầu 0,8 (`terrain_type.dart`). Không phải "gấp đôi đường bằng" chung cho đồi/ruộng.
> * **Hạn nhiệm vụ:** săn (hunt) 3–7 ngày, tối thiểu `ngày di chuyển + 2`; loại khác dùng `days` của template (1–3).
> * **Phạt:** quá hạn trừ `penaltySat` theo template (5–8 ở các template đã đọc); bỏ nhiệm vụ trừ một nửa (làm tròn lên). Mức −10…−25% trong bảng là đề xuất, không phải source.
> * Mức cộng theo độ khó (Skull), tần suất sự kiện ngẫu nhiên: `[UNVERIFIED]`.

| Tên thông số                                       | Giá trị xác minh / Đề xuất                  | Đơn vị &amp; Điều kiện áp dụng        | Nguồn &amp; Nhãn bằng chứng               | Trạng thái     | Ảnh hưởng đến Gameplay                                |
| -------------------------------------------------- | ------------------------------------------- | --------------------------------- | ------------------------------------- | -------------- | ----------------------------------------------------- |
| **Tốc độ Tiêu hao March Points**                   | Đồi núi / Farmland tốn gấp 2 lần đường bằng | Khi di chuyển quân đoàn trên Map  | Video Playthrough `[OBSERVED]`        | Đã xác minh    | Địa hình ảnh hưởng trực tiếp đến thời gian hành quân. |
| **Cấp độ Khó Nhiệm vụ (Skull Level)**              | 1 Đầu lâu (Dễ) đến 4 Đầu lâu (Rất khó)      | Phân loại Quest tại Bảng nhiệm vụ | Video Playthrough `[OBSERVED]`        | Đã xác minh    | Giúp người chơi chọn nhiệm vụ phù hợp với sức mạnh.   |
| **Thời hạn Nhiệm vụ (Quest Deadline)**             | 3 đến 7 ngày                                | Đếm lùi khi nhấn `End Day`        | Store / Video `[OFFICIAL] [OBSERVED]` | Đã xác minh    | Tạo áp lực thời gian, không thể chần chừ quá lâu.     |
| **Mức thưởng King's Satisfaction**                 | Quest 1 Skull: +5%; Quest 4 Skull: +20%     | Cộng vào thanh điểm Vua khi thắng | `[REMAKE PROPOSAL]`                   | Đề xuất Remake | Tăng điểm hài lòng Vua để tiến gần chiến thắng 100%.  |
| **Phạt khi Thất bại / Trễ hạn Quest**              | Trừ -10% đến -25% King's Satisfaction       | Khi trễ hạn hoặc thua trận Quest  | `[REMAKE PROPOSAL]`                   | Đề xuất Remake | Nguy cơ rỗng thanh Vua gây Game Over lập tức.         |
| **Tần suất Sự kiện Ngẫu nhiên (Event Spawn Rate)** | 1 sự kiện ngẫu nhiên mỗi 2 ngày hành quân   | Xuất hiện trên Overworld Map      | `[REMAKE PROPOSAL]`                   | Đề xuất Remake | Tạo biến số giải trí ngẫu nhiên trên đường đi.        |

---

## 7\. Cân bằng Tiến trình &amp; Độ khó (Progression &amp; Difficulty Balance)

> **Hiện trạng source (`[CURRENT]`):**
> * **Thắng:** hoàn thành nhiệm vụ cuối (`isFinal`), không phải đạt 100% King's Satisfaction. Thanh bị kẹp 0–100 và chỉ có tác dụng thua khi về 0.
> * **Khởi đầu:** `kingSatisfaction = 50` cho mọi ván (`rules.dart:229`); không thấy nền Full Hero (40%)/Plebs (20%) (`[UNVERIFIED]` trong UI).
> * **Độ khó địch:** `QuestGenerator.enemyPlan` (cấp địch = độ khó nhiệm vụ; đội 1 co theo quân số hiện có); không có hệ số +10% theo ngày `[UNVERIFIED]`.

| Tên thông số                                     | Giá trị xác minh / Đề xuất                               | Đơn vị &amp; Điều kiện áp dụng  | Nguồn &amp; Nhãn bằng chứng         | Trạng thái     | Ảnh hưởng đến Gameplay                              |
| ------------------------------------------------ | -------------------------------------------------------- | --------------------------- | ------------------------------- | -------------- | --------------------------------------------------- |
| **Mục tiêu Thắng Chiến dịch (Campaign Victory)** | Đạt **100% King's Favor / Satisfaction**                 | Tích lũy qua chuỗi nhiệm vụ | Steam Store `[OFFICIAL]`        | Đã xác minh    | Cột mốc hoàn thành chế độ Campaign.                 |
| **Mức King's Satisfaction Ban đầu**              | Background "Full Hero": 40%; Background "Plebs": 20%     | Khởi tạo Campaign mới       | Video Playthrough `[OBSERVED]`  | Đã xác minh    | Đổi King's Favor lấy Vàng khởi đầu tùy chiến thuật. |
| **Tăng trưởng Độ khó Kẻ địch**                   | Chỉ số địch tăng +10% theo số ngày chiến dịch trôi qua   | Áp dụng trên Overworld Map  | `[REMAKE PROPOSAL]`             | Đề xuất Remake | Đảm bảo game không bị quá dễ ở giai đoạn sau.       |
| **Tác động của Permadeath đến Tiến trình**       | Mất lính Cấp 5 kéo tụt \~20% sức mạnh tổng thể quân đoàn | Khi lính chủ lực tử trận    | Community Reviews `[COMMUNITY]` | Đã xác minh    | Buộc người chơi luôn phải huấn luyện lính dự bị.    |

---

## 8\. Cân bằng Khác biệt giữa các Chế độ chơi (Game Mode Balance)

> **Hiện trạng source:** chỉ có **Campaign**. `[PLANNED]` Sandbox và Arena (chưa triển khai; không có `gameMode` trong `GameState`). Trong Campaign hết quân không gây Game Over; có cơ chế gỡ bế tắc (`GameRules.isSoftlocked`, `reliefGrant`).

| Chế độ chơi       | Quy tắc Cân bằng Cốt lõi                                                                      | Điều kiện Thắng / Thua                                                            | Nguồn &amp; Nhãn bằng chứng  |
| ----------------- | --------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- | ------------------------ |
| **Campaign Mode** | Cân bằng đầy đủ giữa Quản lý Trại, Kinh tế, Khám phá Map và Autobattler.                      | **Thắng:** Đạt 100% King's Favor.**Thua:** Thanh King's Satisfaction = 0.         | Steam Store `[OFFICIAL]` |
| **Sandbox Mode**  | Chơi tự do không giới hạn thời gian kịch bản.                                                 | **Thua:** Hết sạch quân lính = Game Over lập tức (`7th King's Edict`).            | Steam News `[OFFICIAL]`  |
| **Arena Mode**    | **10 kịch bản thuần chiến đấu** (Pure Battle). Bỏ qua Camp, Kinh tế và Map. Đội hình cho sẵn. | **Thắng:** Tiêu diệt sạch địch từng kịch bản.**Thua:** Toàn bộ lính bị tiêu diệt. | Steam News `[OFFICIAL]`  |

---

## 9\. Kế hoạch Kiểm thử Cân bằng (Balance Test Plan)

Để đánh giá tính cân bằng của bản Flutter Remake, đội ngũ phát triển cần thực hiện các kịch bản kiểm thử (Playtest Scenarios) và ghi nhận chỉ số theo bảng dưới đây:

### A. Kịch bản Kiểm thử Cần Thực hiện

1. **Kịch bản 1: Sức ép Kinh tế Đầu Game (Early-game Economy Stress Test)**  
  * *Mục tiêu:* Kiểm tra xem chi phí duy trì 1 Gold + 1 Food/ngày có quá nặng làm người chơi phá sản ở 10 ngày đầu không.
  * *Thao tác:* Duy trì quân đoàn 6 lính, chỉ làm nhiệm vụ 1 Skull.
  * *Chỉ số ghi nhận:* Tổng Vàng/Thức ăn dư thừa sau ngày 10, tỷ lệ lính bị vỡ Morale do thiếu ăn.
2. **Kịch bản 2: Tác động của Permadeath ở Mid-Game**  
  * *Mục tiêu:* Đánh giá khả năng hồi phục của người chơi khi mất 1 lính chủ lực Cấp 4-5.
  * *Thao tác:* Cố tình để lính mạnh nhất tử trận ở ngày 20, kiểm tra thời gian cần thiết để huấn luyện lính thay thế.
  * *Chỉ số ghi nhận:* Số ngày cần để khôi phục sức mạnh quân đoàn, chi phí Vàng tổn thất.
3. **Kịch bản 3: Cân bằng Kỹ năng Sừng chiến (War Horn Balance Test)**  
  * *Mục tiêu:* Đảm bảo War Horn hữu ích nhưng không bị lạm dụng làm mất độ khó trận đấu.
  * *Thao tác:* Sử dụng War Horn liên tục mỗi khi hết Cooldown trong các trận đấu khó (3-4 Skulls).
  * *Chỉ số ghi nhận:* Tỷ lệ lính bỏ chạy khi có War Horn vs không có War Horn.

### B. Tiêu chí Đánh giá Mất cân bằng (Balance Warning Indicators)

* **Game quá Dễ:** Người chơi tích lũy &gt; 1000 Gold và &gt; 100 Thức ăn sau 15 ngày mà không gặp bất kỳ rủi ro tài chính nào.
* **Game quá Khó:** Tỷ lệ thất bại chiến dịch (Game Over) ở 5 ngày đầu &gt; 50% do cạn kiệt Thức ăn hoặc rỗng điểm King's Satisfaction.
* **Vũ khí / Trang bị Bị bá đạo (OP Equipment):** \&gt; 80% lính sử dụng cùng 1 loại vũ khí (ví dụ: Paladin Sword) vì vượt trội hoàn toàn về Accuracy và Damage.

---

## 10\. Bảng Báo cáo Tổng hợp Thông số Cân bằng

| Hệ thống    | Thông số                  | Giá trị                                                                              | Nhãn bằng chứng     | Trạng thái trong Remake |
| ----------- | ------------------------- | ------------------------------------------------------------------------------------ | ------------------- | ----------------------- |
| **Soldier** | Sức chứa Quân đoàn Tối đa | 20 lính                                                                              | `[OFFICIAL]`        | Tham chiếu game gốc; source: 6 + 4×cấp Doanh trại |
| **Soldier** | Cấp độ Tối đa             | Level 5                                                                              | `[COMMUNITY]`       | Tham chiếu game gốc; source: 6 |
| **Soldier** | Quân số Ban đầu           | 5 – 6 lính                                                                           | `[OBSERVED]`        | Đã xác minh             |
| **Economy** | Phí Duy trì Hàng ngày     | 1 Gold + 1 Food / lính                                                               | `[OBSERVED]`        | Tham chiếu game gốc; source: theo cấp (xem §4) |
| **Economy** | Giá Thuê Lính tại Tavern  | 14 – 20 Gold                                                                         | `[OBSERVED]`        | Tham chiếu game gốc; source: công thức (xem §4) |
| **Camp**    | Sức chứa Bệnh xá          | 3 lính cố định                                                                       | `[OBSERVED]`        | Đã xác minh             |
| **Camp**    | Hồi sinh Mộ đá            | Tốn Gold, HP/Stamina/Morale \~20%, Mất gear                                          | `[COMMUNITY]`       | Source: HP 1, cần điều trị (xem §5) |
| **Combat**  | War Horn                  | Buff Morale chống bỏ chạy                                                            | `[OFFICIAL]`        | `[PLANNED]` chưa triển khai |
| **Combat**  | Thời tiết                 | Phạt chỉ số đòn đánh                                                                 | `[OFFICIAL]`        | `[PLANNED]` chưa triển khai |
| **Combat**  | Công thức Sát thương      | $\\text{Dmg} = (\\text{Base} + \\text{Str} \\times 1.5) \\times \\text{Armor Reduc}$ | `[REMAKE PROPOSAL]` | Đề xuất; source khác (xem §3) |
| **Quest**   | Thắng Chiến dịch          | 100% King's Satisfaction / Favor                                                     | `[OFFICIAL]`        | Source: hoàn thành nhiệm vụ cuối (xem §7) |
| **Modes**   | Sandbox Game Over Rule    | Hết quân = Game Over ngay lập tức                                                    | `[OFFICIAL]`        | `[PLANNED]` chưa triển khai |

---

## 11\. Danh sách Ưu tiên Cần Đo đạc &amp; Playtest

Dưới đây là 5 hạng mục thông số quan trọng nhất thuộc nhóm `[UNKNOWN]` / `[REMAKE PROPOSAL]` cần tập trung đo đạc và cân bằng trong các đợt Playtest nội bộ của dự án Flutter Remake:

1. **[ƯU TIÊN 1] Công thức Sát thương &amp; Né tránh (Damage &amp; Evasion Formulas):** Cần chốt hệ số nhân của Strength/Dexterity và công thức giảm trừ sát thương của Armor Class để đòn đánh không bị quá ảo hoặc quá bé.
2. **[ƯU TIÊN 2] Tốc độ Hồi phục HP/Energy/Morale qua đêm tại Camp:** Cần cân chỉnh lượng HP/Energy hồi được mỗi ngày trong Tents và Infirmary để nhịp độ luân chuyển lính đạt từ 1–3 ngày nghỉ.
3. **[ƯU TIÊN 3] Đường cong XP Lên cấp của Lính (XP Curve):** Xác định chính xác lượng XP nhận được sau mỗi trận thắng để lính đạt Cấp 5 sau khoảng 15–20 trận đấu.
4. **[ƯU TIÊN 4] Tỷ lệ Rơi đồ (Drop Rates) từ Rương thưởng:** Thiết lập tỷ lệ rơi đồ Thường (70%), Hiếm (25%), Huyền thoại (5%) để giữ giá trị trải nghiệm mở rương.
5. **[ƯU TIÊN 5] Hệ số Phạt điểm King's Satisfaction khi Trễ hạn Quest:** Cân chỉnh mức phạt trừ điểm Vua khi trễ deadline sao cho người chơi bị cảnh báo nguy cơ Game Over sau 2–3 lần trễ hẹn liên tiếp.