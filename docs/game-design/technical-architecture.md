# ĐẶC TẢ KIẾN TRÚC KỸ THUẬT (TECHNICAL ARCHITECTURE SPECIFICATION)

**Dự án:** Rising Army Remake (Flutter iOS - Landscape)  
**Tập tin mục tiêu:** `docs/game-design/technical-architecture.md`  
**Độ phân giải / Định hướng:** Landscape Mode (Tối ưu iPhone 15 Pro Max 932x430 pt &amp; màn hình di động ngang)

---

> **Cập nhật theo TASK-004: đối chiếu với source.** Tài liệu này trộn hiện trạng và định hướng. Trong các mục dưới đây, khối **"Hiện trạng source"** là hành vi đã xác minh (`[CURRENT]`); nội dung thiết kế còn lại không có khối đó là định hướng `[PLANNED]` hoặc minh họa, **không** phải implementation. Các tên `CampaignRepository`, `CampaignStateNotifier`, `SaveEnvelope`, `SaveMigrator`, `SeededRandom`, `BattleSimulationEngine`, `GameState` module, `SoldierEntity`… là tên khái niệm, **không tồn tại** như lớp trong source. Nhãn: `[CURRENT]` đã xác minh; `[PLANNED]` chưa triển khai; `[UNVERIFIED]` chưa đủ bằng chứng.

---

## MỤC LỤC

1. [Tổng quan Kiến trúc (Architecture Overview)](#1-t%E1%BB%95ng-quan-ki%E1%BA%BFn-tr%C3%BAc-architecture-overview)
2. [Hiện trạng Mã nguồn vs Kiến trúc Mục tiêu (Current Implementation vs Target)](#2-hi%E1%BB%87n-tr%E1%BA%A1ng-m%C3%A3-ngu%E1%BB%93n-vs-ki%E1%BA%BFn-tr%C3%BAc-m%E1%BB%A5c-ti%C3%AAu)
3. [Đặc tả các Module Cốt lõi (Core Modules Specification)](#3-%C4%91%E1%BA%B7c-t%E1%BA%A3-c%C3%A1c-module-c%E1%BB%91t-l%C3%B5i)
4. [Kiến trúc Quản lý Trạng thái (State Management Architecture)](#4-ki%E1%BA%BFn-tr%C3%BAc-qu%E1%BA%A3n-l%C3%BD-tr%E1%BA%A1ng-th%C3%A1i)
5. [Động cơ Mô phỏng Trận đấu (Battle Simulation Engine)](#5-%C4%91%E1%BB%99ng-c%C6%A1-m%C3%B4-ph%E1%BB%8Fng-tr%E1%BA%ADn-%C4%91%E1%BA%A5u)
6. [Kiến trúc Lưu trữ &amp; Tải dữ liệu (Save/Load &amp; Persistence Architecture)](#6-ki%E1%BA%BFn-tr%C3%BAc-l%C6%B0u-tr%E1%BB%AF--t%E1%BA%A3i-d%E1%BB%AF-li%E1%BB%87u)
7. [Mô hình Dữ liệu &amp; Ranh giới Domain (Data Models &amp; Domain Boundaries)](#7-m%C3%B4-h%C3%ACnh-d%E1%BB%AF-li%E1%BB%87u--ranh-gi%E1%BB%9Bi-domain)
8. [Vòng đời Game &amp; Quản lý Chuyển cảnh (Game Loop &amp; Lifecycle Management)](#8-v%C3%B2ng-%C4%91%E1%BB%9Di-game--qu%E1%BA%A3n-l%C3%BD-chuy%E1%BB%83n-c%E1%BA%A3nh)
9. [Tính Ngẫu nhiên &amp; Khả năng Tái hiện (Randomness &amp; Determinism)](#9-t%C3%ADnh-ng%E1%BA%ABu-nhi%C3%AAn--kh%E1%BA%A3-n%C4%83ng-t%C3%A1i-hi%E1%BB%87n)
10. [Xử lý Lỗi &amp; Khôi phục Trạng thái (Error Handling &amp; Recovery)](#10-x%E1%BB%AD-l%C3%BD-l%E1%BB%97i--kh%C3%B4i-ph%E1%BB%A5c-tr%E1%BA%A1ng-th%C3%A1i)
11. [Chiến lược Kiểm thử (Testing Strategy)](#11-chi%E1%BA%BFn-l%C6%B0%E1%BB%A3c-ki%E1%BB%83m-th%E1%BB%AD)
12. [Hồ sơ Quyết định Kiến trúc (Architectural Decision Records - ADR)](#12-h%E1%BB%93-s%C6%A1-quy%E1%BA%BFt-%C4%91%E1%BB%8Bnh-ki%E1%BA%BFn-tr%C3%BAc)

---

## 1\. TỔNG QUAN KIẾN TRÚC (ARCHITECTURE OVERVIEW)

Kiến trúc kỹ thuật cho dự án **Rising Army Remake** áp dụng mô hình phân lớp chuẩn (**Clean Layered Architecture**) kết hợp với cơ chế Quản lý Trạng thái Phản ứng (*Reactive State Management*) dựa trên nền tảng **Flutter / Dart**.

Hệ thống phân tách thành 4 tầng riêng biệt với chiều phụ thuộc 1 chiều từ ngoài vào trong: `Presentation` $\\rightarrow$ `Application / Controller` $\\rightarrow$ `Domain` $\\leftarrow$ `Data`.

```
graph TD
    %% Tầng Presentation (Giao diện)
    subgraph Layer1 [1. PRESENTATION LAYER - Flutter UI]
        UI_Screens[Screens: Camp, Map, Town, Deploy, Battle, Result]
        UI_Widgets[Widgets &amp; HUD Components]
        UI_Scope[ControllerScope / InheritedWidget Binding]
    end

    %% Tầng Application / Controller
    subgraph Layer2 [2. APPLICATION / CONTROLLER LAYER]
        GC[GameController - Central Manager]
        NC[Notification &amp; Event Bus]
        CS[CampaignStateNotifier]
    end

    %% Tầng Domain (Logic Nghiệp vụ Cốt lõi)
    subgraph Layer3 [3. DOMAIN LAYER - Pure Dart Business Logic]
        SoldierDomain[Soldier System &amp; Vital Meters]
        CampDomain[Camp &amp; Building Operations]
        EconomyDomain[Resource &amp; Economy Rules]
        MapDomain[World Map &amp; March Points Engine]
        QuestDomain[Quest &amp; King's Satisfaction Logic]
        BattleEngine[Battle Simulation Engine - Decoupled Loop]
        ProgressionDomain[Progression &amp; Permadeath Manager]
    end

    %% Tầng Data (Lưu trữ &amp; Persistence)
    subgraph Layer4 [4. DATA LAYER - Persistence &amp; Adapters]
        Repo[CampaignRepository]
        SaveEnvelope[SaveEnvelope &amp; Versioning Manager]
        Storage[Local File Storage / SharedPreferences]
        JsonAdapters[JSON Serializers &amp; Schema Migrators]
    end

    %% Luồng tương tác giữa các tầng
    UI_Screens --&gt; UI_Scope
    UI_Scope --&gt; GC
    GC --&gt; CS
    GC --&gt; BattleEngine
    GC --&gt; SoldierDomain
    GC --&gt; CampDomain
    GC --&gt; EconomyDomain
    GC --&gt; MapDomain
    GC --&gt; QuestDomain
    GC --&gt; ProgressionDomain

    CS --&gt; Repo
    Repo --&gt; SaveEnvelope
    SaveEnvelope --&gt; JsonAdapters
    JsonAdapters --&gt; Storage

```

### Nguyên tắc Luồng Dữ liệu (Data Flow Principles)

1. **Luồng dữ liệu đơn hướng (Unidirectional Data Flow):** User Action $\\rightarrow$ UI Event $\\rightarrow$ `GameController` $\\rightarrow$ Domain Logic Execution $\\rightarrow$ State Mutated $\\rightarrow$ `notifyListeners()` $\\rightarrow$ UI Re-render.
2. **Phi trạng thái ở tầng UI (Stateless UI):** Các Widget hoàn toàn không chứa logic nghiệp vụ hay trực tiếp sửa đổi dữ liệu. UI chỉ lắng nghe trạng thái từ `GameController` / `ControllerScope`.
3. **Tách biệt Động cơ Mô phỏng (Decoupled Simulation):** Engine chiến đấu (`BattleEngine`) chạy vòng lặp mô phỏng thuần Dart (Pure Dart Engine), không phụ thuộc vào Frame rate của Flutter hay các Widget UI.

---

## 2\. HIỆN TRẠNG MÃ NGUỒN VS KIẾN TRÚC MỤC TIÊU

Bảng dưới đây phân định rõ ràng giữa các phần đã được xác minh/triển khai trong mã nguồn hiện tại, phần cần kiểm tra repository và các đề xuất kiến trúc cho tương lai.

| Thành phần / Subsystem      | Hiện trạng Mã nguồn (`[CURRENT]` / `[VERIFIED]`)                 | Định hướng Mục tiêu (`[PROPOSED]`)                                                              | Trạng thái Kiểm chứng |
| --------------------------- | ---------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- | --------------------- |
| **Giao diện &amp; Orientation** | Flutter Framework, iOS Landscape support (`[VERIFIED]`)          | Tối ưu hóa SafeArea cho Dynamic Island / Notch trên iPhone 15 Pro Max                           | `[VERIFIED]`          |
| **State Management**        | Sử dụng `GameController` kế thừa `ChangeNotifier` (`[VERIFIED]`) | Tùy biến `ControllerScope` kế thừa `InheritedNotifier` để truyền state không cần thư viện ngoài | `[VERIFIED]`          |
| **Battle Engine**           | Hàm thuần Dart `simulateBattle(players, enemies, seed)`, bước 0,1 giây = 10 nhịp/giây, `lib/domain/battle.dart:227` (`[CURRENT]`) | Lớp `BattleSimulationEngine` riêng: `[PLANNED]` (không tồn tại)                                 | `[CURRENT]` (hàm); lớp `[PLANNED]` |
| **Save / Load**             | `SaveRepository`: phong bì `{version, checksum, data}` (`data` là chuỗi JSON), checksum FNV-1a 32-bit, lưu qua SharedPreferences với `save_primary`/`save_backup`/`save_archive_v{n}`; migration `migrateV1toV3`, `migrateV2toV3` (`lib/data/save_repository.dart`) (`[CURRENT]`) | SHA-256, ghi `.tmp`, file `.bak`, `timestamp`: `[PLANNED]` (cần xác nhận quyết định)             | `[CURRENT]`; mục tiêu `[PLANNED]` |
| **Data Models**             | `Soldier`, `Facility`, `Mission`, `HeroState`, `GameState` trong `lib/domain/models.dart` với `toJson`/`fromJson`; state **thay đổi tại chỗ** (không `copyWith`) (`[CURRENT]`) | Immutable Entities với `copyWith()`: `[PLANNED]`                                                | `[CURRENT]`; immutable `[PLANNED]` |
| **Randomness**              | `Random(seed)` chuẩn của Dart trong trận (`simulateBattle`); ngoài trận `GameRules.rng(s) = Random(s.seed * 7919 + s.rngCounter++)` (`rules.dart:165`), cả hai theo seed nên tái lập được (`[CURRENT]`) | `SeededRandom` (Mersenne Twister / Xorshift128+): `[PLANNED]`, chưa có và chưa có quyết định    | `[CURRENT]`; thuật toán mới `[PLANNED]` |
| **Error Recovery**          | Fallback từ `save_primary` sang `save_backup` (`LoadStatus.recoveredFromBackup`), `corrupted`, `migrationFailed`; `GameState.fromJson` từ chối dữ liệu sai cấu trúc (`[CURRENT]`) | "Safe Mode" và giao diện khôi phục chuyên biệt: `[PLANNED]`/`[UNVERIFIED]`                       | `[CURRENT]`; Safe Mode `[PLANNED]` |

---

## 3\. ĐẶC TẢ CÁC MODULE CỐT LÕI (CORE MODULES SPECIFICATION)

> **Hiện trạng source:** mười một "module" dưới đây là phân chia khái niệm. Trong code, logic nghiệp vụ nằm chủ yếu trong lớp tĩnh `GameRules` (`lib/domain/rules.dart`) cùng `battle.dart`, `economy.dart`, `stats.dart`, `progression.dart`, `world_map.dart`, `movement.dart`, `quest_generator.dart`; không có lớp riêng tên `SoldierSystem`, `CampSystem`, `QuestSystem`, `DeploymentSystem`, `BattleSimulationEngine`, `ProgressionSystem` hay `GameModeManager`. Nhãn `[VERIFIED]` trong đoạn này chỉ nghĩa là chức năng tương ứng tồn tại, không phải tên lớp. Ngoài ra, mô-đun `GameModeManager` (Campaign/Sandbox/Arena) là `[PLANNED]`: source chỉ có Campaign. Các giá trị trong mô tả (ví dụ 20 lính, upkeep 1+1, Level 5, 100% King's Favor) lấy từ game gốc; số liệu thật xem `gameplay-systems.md` và `game-balance.md`.

Hệ thống được chia thành 11 Module độc lập, mỗi Module có ranh giới trách nhiệm rõ ràng (`Single Responsibility Principle`):

```
graph LR
    subgraph CoreModules [Core System Modules]
        M1[1. Game Controller]
        M2[2. Game State]
        M3[3. Soldier Module]
        M4[4. Camp / Building]
        M5[5. Resource / Economy]
        M6[6. World Map]
        M7[7. Quest Module]
        M8[8. Deployment Module]
        M9[9. Battle Simulation]
        M10[10. Progression]
        M11[11. Game Modes]
    end

    M1 --&gt; M2
    M2 --&gt; M3
    M2 --&gt; M4
    M2 --&gt; M5
    M2 --&gt; M6
    M2 --&gt; M7
    M2 --&gt; M8
    M1 --&gt; M9
    M2 --&gt; M10
    M2 --&gt; M11

```

### Chi tiết Trách nhiệm 11 Module:

1. **Game Controller Module (`GameController`):** `[CURRENT IMPLEMENTATION]`  
  * *Trách nhiệm:* Điều phối toàn bộ trạng thái game, nhận lệnh từ UI, gọi Domain Services và phát thông báo `notifyListeners()`.
2. **Game State Module (`GameState`):** `[PROPOSED]`  
  * *Trách nhiệm:* Đại diện cho toàn bộ trạng thái hiện tại của một file save chiến dịch (Camp, Soldiers, Resources, Map, Quests, Day Counter, King's Satisfaction).
3. **Soldier Module (`SoldierSystem`):** `[VERIFIED]`  
  * *Trách nhiệm:* Quản lý chỉ số lính (HP, Energy, Morale, Str, Dex, Con, Speed), kinh nghiệm, level up, 3 ô trang bị và thương tật.
4. **Camp &amp; Building Module (`CampSystem`):** `[VERIFIED]`  
  * *Trách nhiệm:* Quản lý các công trình (Tents, Infirmary, Altar, Training Fields, Gravestone, Stash), slot gán lính, nâng cấp và xử lý qua đêm (`End Day`).
5. **Resource &amp; Economy Module (`EconomySystem`):** `[VERIFIED]`  
  * *Trách nhiệm:* Quản lý 7 tài nguyên (Gold, Food, Tools, Iron, Stone, Wood, Cloth), khấu trừ Upkeep hàng ngày (1 Gold + 1 Food/lính), chi phí mua bán.
6. **World Map Module (`WorldMapSystem`):** `[VERIFIED]`  
  * *Trách nhiệm:* Quản lý di chuyển quân đoàn, trừ điểm `March Points` theo địa hình, Fog of War, điểm nhặt tài nguyên và sự kiện dã ngoại.
7. **Quest &amp; Satisfaction Module (`QuestSystem`):** `[VERIFIED]`  
  * *Trách nhiệm:* Quản lý danh sách nhiệm vụ thị trấn, tính hạn chót (*Deadline* tính theo ngày), cập nhật thanh *King's Satisfaction* và kích hoạt Game Over nếu thanh về 0 (trong Campaign).
8. **Deployment Module (`DeploymentSystem`):** `[VERIFIED]`  
  * *Trách nhiệm:* Quản lý lưới chọn quân (Frontline / Backline), giới hạn số lính tham chiến theo lượt địch, lưu preset đội hình.
9. **Battle Simulation Engine (`BattleSimulationEngine`):** `[VERIFIED]`  
  * *Trách nhiệm:* Chạy vòng lặp trận đấu tự động, xử lý di chuyển, chọn mục tiêu, tính đòn đánh (Hit/Miss/Crit), giảm Morale, War Horn và kết xuất kết quả.
10. **Progression &amp; Permadeath Module (`ProgressionSystem`):** `[VERIFIED]`  
  * *Trách nhiệm:* Quản lý cột mốc 100% King's Favor để thắng game, xóa vĩnh viễn lính tử trận (hoặc đưa vào Gravestone).
11. **Game Modes Module (`GameModeManager`):** `[OFFICIAL]`  
  * *Trách nhiệm:* Áp dụng luật riêng cho 3 chế độ: **Campaign Mode**, **Sandbox Mode** (hết quân = Game Over lập tức) và **Arena Mode** (10 kịch bản thuần chiến đấu).

---

## 4\. KIẾN TRÚC QUẢN LÝ TRẠNG THÁI (STATE MANAGEMENT ARCHITECTURE)

Dự án sử dụng cơ chế Quản lý Trạng thái chuẩn của Flutter thông qua `ChangeNotifier` kết hợp `ControllerScope` (kế thừa `InheritedNotifier`), giúp tránh lãng phí bộ nhớ và không phụ thuộc vào thư viện bên thứ ba.

```
sequenceDiagram
    autonumber
    actor User
    participant UI as Flutter UI / Screen
    participant Scope as ControllerScope (InheritedNotifier)
    participant GC as GameController (ChangeNotifier)
    participant Domain as Domain Service / Engine
    participant Repo as CampaignRepository

    User-&gt;&gt;UI: Tap nút "End Day"
    UI-&gt;&gt;Scope: Scope.of(context).processEndDay()
    Scope-&gt;&gt;GC: GC.processEndDay()
    GC-&gt;&gt;Domain: Execute Daily Upkeep &amp; Building Operations
    Domain--&gt;&gt;GC: Return Updated GameState
    GC-&gt;&gt;Repo: Save Current GameState (Autosave)
    GC-&gt;&gt;GC: notifyListeners()
    GC--&gt;&gt;Scope: Trigger State Update
    Scope--&gt;&gt;UI: Re-render UI Widgets (Animated Transition)

```

### Quy chuẩn Quản lý Trạng thái:

* **Không mutate state trực tiếp:** UI chỉ đọc trạng thái dạng `read-only` thông qua các getters của `GameController`.
* **Cập nhật nguyên tử (Atomic State Updates):** Mọi thao tác sửa đổi trạng thái (như gán lính vào công trình, mua đồ, kết thúc ngày) được đóng gói trong một phương thức duy nhất của `GameController`.
* **Cơ chế Re-render tối ưu:** Sử dụng `Selector` hoặc chia nhỏ Widget cây để chỉ Re-render đúng vùng UI thay đổi (ví dụ: chỉ cập nhật thanh tài nguyên ở TopBar khi Gold thay đổi).

---

## 5\. ĐỘNG CƠ MÔ PHỎNG TRẬN ĐẤU (BATTLE SIMULATION ENGINE)

> **Hiện trạng source (`[CURRENT]`):** engine là hàm thuần Dart `simulateBattle(players, enemies, seed)` (`lib/domain/battle.dart:227`): bước `stepSeconds = 0.1` (10 nhịp/giây), khung hình cho UI mỗi `frameSeconds = 0.2`, tối đa `maxBattleSeconds = 120`, `Random(seed)`, không sửa `GameState`. Mô phỏng không phụ thuộc Widget nên chạy được trong test. Sơ đồ nhịp dưới đây khớp ở các bước: tìm mục tiêu gần nhất, di chuyển hoặc tấn công, tính hit/crit/damage, kiểm tra morale/bỏ chạy.
> * `[PLANNED]` **War Horn** và `GameController.triggerWarHorn()`: không tồn tại trong `lib/`.
> * Công thức sát thương/chính xác ở cuối mục là `[REMAKE PROPOSAL]` và **không phải** source. Source: accuracy kẹp 0,40–0,95; sát thương = `attack × (0,85…1,15) × hệ số morale × 0,42 × (1 − d/(d+25))`, crit ×1,5 (`battle.dart:288-306`, `stats.dart:72,214`). Xem `gameplay-systems.md` mục 3.7.
> * Chế độ "Headless" không phải chế độ riêng: do là hàm thuần nên test gọi trực tiếp; số lượng trận headless `[UNVERIFIED]`.

`BattleSimulationEngine` được thiết kế hoàn toàn tách biệt khỏi Flutter Widget Tree. Động cơ nhận vào `BattleSetup` (đội hình 2 bên) và thực thi mô phỏng theo từng Ticks (ví dụ: 10 Ticks = 1 giây game).

```
graph TD
    StartBattle[Start Battle Request] --&gt; InitEngine[Initialize BattleSimulationEngine]
    InitEngine --&gt; SetupUnits[Position Units on Tactical Grid]
    SetupUnits --&gt; Loop[Simulation Loop - Tick Rate: 10 Hz]

    subgraph TickProcess [Internal Tick Process]
        Loop --&gt; CheckMorale[1. Check Morale &amp; Fleeing Units]
        CheckMorale --&gt; FindTargets[2. Acquire Nearest Target]
        FindTargets --&gt; MoveOrAttack[3. Move or Execute Attack]
        MoveOrAttack --&gt; CalcDamage[4. Calculate Hit / Miss / Crit &amp; Damage]
        CalcDamage --&gt; ApplyStats[5. Update Unit HP &amp; Trigger FX Event]
    end

    ApplyStats --&gt; CheckVictory{Check End Condition?}
    CheckVictory -- No --&gt; Loop
    CheckVictory -- Yes --&gt; EndBattle[Generate BattleResult]
    EndBattle --&gt; ReturnState[Pass Result to GameController &amp; UI]

```

### Quy tắc Kỹ thuật cho Battle Engine:

1. **Phân tách UI / Simulation (Decoupled Loop):** Engine có thể chạy ở chế độ **Headless Mode** (mô phỏng chạy ngầm 100% trong 1 ms để kiểm thử) hoặc chế độ **Real-time Mode** (phát sự kiện Ticks theo thời gian thực cho UI hiển thị animation).
2. **Kỹ năng Sừng chiến (`War Horn`):** Gọi qua `GameController.triggerWarHorn()`, lập tức bổ sung điểm Morale cho toàn bộ quân đồng minh đang tham chiến. `[OFFICIAL]`
3. **Các công thức tùy biến (`[REMAKE PROPOSAL]` / `[UNKNOWN]`):**  
  * Công thức Sát thương: $Damage = \\max(1, Attacker.Str + Weapon.Atk - Defender.Armor)$ `[REMAKE PROPOSAL]`.
  * Công thức Chính xác: $HitRate = \\text{Clamp}(80% + Attacker.Dex - Defender.Speed, 20%, 95%)$ `[REMAKE PROPOSAL]`.

---

## 6\. KIẾN TRÚC LƯU TRỮ &amp; TẢI DỮ LIỆU (SAVE/LOAD ARCHITECTURE)

> **Hiện trạng source (`[CURRENT]`, `lib/data/save_repository.dart`):**
> * Phong bì thật: `{"version": 3, "checksum": "<hex>", "data": "<chuỗi JSON của GameState.toJson()>"}`. `data` là **chuỗi**; không có `timestamp`, `game_mode`; các khóa `day`, `kings_satisfaction`, `resources`… trong ví dụ JSON bên dưới **không phải** schema thật (xem `game-state-and-save-system.md` §2).
> * Checksum: **FNV-1a 32-bit** trên chuỗi `data` (`SaveRepository.checksum`), không phải SHA-256.
> * Lưu: `KeyValueStore` (SharedPreferences qua `PrefsStore`): `save_primary`, `save_backup` (bản trước đó), `save_archive_v{n}` (bản gốc của save cũ trước migration). Không có file `.json`/`.bak`/`.tmp`, không đổi tên file.
> * Tải: thử `save_primary`, rồi `save_backup`; kết quả `LoadStatus {none, ok, recoveredFromBackup, migrated, corrupted, migrationFailed}`. Migration theo bảng bước: `migrateV1toV3` (v1 nhảy thẳng v3) và `migrateV2toV3`; không có `SaveMigrator`, không có bước v1→v2.
> * Tự động lưu: sau mỗi hành động thay đổi state, kết thúc ngày, hoàn tất di chuyển, về menu (`GameController._persist`). Lưu khi vào nền (`AppLifecycleState.paused`) là `[PLANNED]`.
> * `[PLANNED]` (cần xác nhận quyết định giữ hay bỏ): SHA-256, ghi an toàn `.tmp`, `campaign_backup.json`, checkpoint giữa trận. Các phần sơ đồ/ghi chú bên dưới mô tả mục tiêu này.

Dữ liệu file save được đóng gói dưới dạng **Save Envelope** chuẩn định dạng JSON, có tích hợp Checksum để chống gian lận và cơ chế Migration hỗ trợ tương thích ngược giữa các phiên bản game.

```
{
  "version": 1,
  "timestamp": 1776123456789,
  "game_mode": "CAMPAIGN",
  "checksum": "a8f5f167f44f4964e6c998dee827110c...",
  "data": {
    "day": 14,
    "kings_satisfaction": 72.5,
    "resources": {
      "gold": 250,
      "food": 45,
      "tools": 12,
      "iron": 10,
      "stone": 20,
      "wood": 35,
      "cloth": 8
    },
    "soldiers": [...],
    "buildings": [...],
    "map_progress": {...}
  }
}

```

```
graph TD
    LoadRequest[User Request / App Launch Load] --&gt; ReadFile[Read JSON File from Disk]
    ReadFile --&gt; ParseEnvelope[Parse SaveEnvelope &amp; Check Version]
    ParseEnvelope --&gt; VerifyChecksum{Verify SHA-256 Checksum?}

    VerifyChecksum -- Invalid --&gt; CorruptedHandler[Trigger Corrupted Save Recovery / Load Backup]
    VerifyChecksum -- Valid --&gt; CheckVersion{Schema Version &lt; Current Version?}

    CheckVersion -- Yes --&gt; MigrationManager[Run SaveMigrator V1 -&gt; V2]
    MigrationManager --&gt; InstantiateState[Instantiate GameState]
    CheckVersion -- No --&gt; InstantiateState

    InstantiateState --&gt; Success[Load Campaign Successfully]
    CorruptedHandler --&gt; BackupSuccess{Backup Valid?}
    BackupSuccess -- Yes --&gt; InstantiateState
    BackupSuccess -- No --&gt; ResetState[Prompt User: Reset Corrupted Save]

```

### Quy tắc Bảo vệ Dữ liệu File Save:

* **Autosave Triggers:** Tự động lưu game khi người chơi nhấn `End Day`, hoàn thành trận đánh hoặc rời ứng dụng (`AppLifecycleState.paused`). `[PROPOSED]`
* **Xử lý Dữ liệu Hỏng (Corrupted Save Fallback):** Nếu Checksum không khớp hoặc file JSON bị lỗi cú pháp, ứng dụng sẽ tự động tải file backup gần nhất (`campaign_backup.json`). `[PROPOSED]`

---

## 7\. MÔ HÌNH DỮ LIỆU &amp; RANH GIỚI DOMAIN (DATA MODELS &amp; BOUNDARIES)

> **Hiện trạng source (`[CURRENT]`):** sơ đồ lớp bên dưới là minh họa khái niệm. Lớp thật: `GameState`, `Soldier`, `Facility`, `Mission`, `HeroState`, `ShopStock` (`lib/domain/models.dart`); không có `SoldierEntity`, `BuildingEntity`, `ResourcesModel`, `MapProgressModel`. Tài nguyên là `Map<Res, int>` (`res`) với `Res {food, coins, wood, iron, tools, stone, cloth}`; công trình gồm `buildings` (`Building {barracks, smithy, tavern}`) và `facilities` (`FacilityType`). `GameState` thay đổi tại chỗ, không `copyWith`. Giao tiếp giữa các thành phần qua `GameController` và `GameRules`, không qua "Repository/Domain Event".

Để tránh phụ thuộc vòng (*Circular Dependency*), các Module giao tiếp với nhau qua các giao diện Repository và Domain Event.

```
classDiagram
    class GameState {
        +int currentDay
        +double kingsSatisfaction
        +GameMode gameMode
        +ResourcesModel resources
        +List~SoldierEntity~ soldiers
        +List~BuildingEntity~ buildings
        +MapProgressModel mapProgress
        +GameState copyWith()
    }

    class SoldierEntity {
        +String id
        +String name
        +int level
        +int xp
        +VitalMeters vitals
        +BaseStats stats
        +EquipmentSlots equipment
        +bool isInjured
        +bool isDead
    }

    class BuildingEntity {
        +String buildingId
        +BuildingType type
        +int level
        +List~String~ assignedSoldierIds
        +bool isDamaged
    }

    class ResourcesModel {
        +int gold
        +int food
        +int tools
        +int iron
        +int stone
        +int wood
        +int cloth
    }

    GameState *-- "1" ResourcesModel
    GameState *-- "*" SoldierEntity
    GameState *-- "*" BuildingEntity

```

---

## 8\. VÒNG ĐỜI GAME &amp; QUẢN LÝ CHUYỂN CẢNH (GAME LOOP &amp; LIFECYCLE)

Vòng đời chuyển cảnh giữa các màn hình trong ứng dụng Flutter tuân thủ đúng chuỗi Vòng lặp Cốt lõi:

$$\\text{CampScreen} \\xrightarrow{\\text{Travel}} \\text{WorldMapScreen} \\xrightarrow{\\text{Enter Town}} \\text{TownScreen} \\xrightarrow{\\text{Trigger Battle}} \\text{DeployScreen} \\xrightarrow{\\text{Start}} \\text{BattleScreen} \\xrightarrow{\\text{Victory/Defeat}} \\text{ResultScreen} \\xrightarrow{\\text{Return}} \\text{CampScreen}$$

```
stateDiagram-v2
    [*] --&gt; MainMenu
    MainMenu --&gt; Camp : New Game / Continue
    Camp --&gt; WorldMap : Exit Camp to Map
    WorldMap --&gt; Town : Enter Town Node
    Town --&gt; QuestBoard : Open Quests
    WorldMap --&gt; Deploy : Encounter Enemy / Start Quest
    Deploy --&gt; Battle : Confirm Formation
    Battle --&gt; Result : Combat Ends
    Result --&gt; Camp : Return to Camp

    Camp --&gt; MainMenu : Save &amp; Quit
    WorldMap --&gt; MainMenu : Save &amp; Quit

```

---

## 9\. TÍNH NGẪU NHIÊN &amp; KHẢ NĂNG TÁI HIỆN (RANDOMNESS &amp; DETERMINISM)

> **Hiện trạng source (`[CURRENT]`):** không có `SeededRandom`. Trong trận dùng `Random(seed)` chuẩn của Dart (`simulateBattle`), seed của trận rút từ `rng(s).nextInt(1 << 30)` (`GameRules.fight`, `rules.dart:~2092`). Ngoài trận, `GameRules.rng(s)` = `Random(s.seed * 7919 + s.rngCounter++)` (`rules.dart:165`); `seed` và `rngCounter` được lưu trong `GameState` nên kết quả xác định theo seed. Trận có thể tái hiện nếu biết seed và vị trí xếp quân; replay chính thức `[UNVERIFIED]`.
> * `[PLANNED]` `SeededRandom` (Mersenne Twister/Xorshift128+) mô tả bên dưới là định hướng, chưa có và chưa có quyết định áp dụng.

1. **Bộ tạo số ngẫu nhiên có Seed (`SeededRandom`):**  
  * Mọi yếu tố ngẫu nhiên trong trận đấu (tỷ lệ trúng, chí mạng, sát thương biến thiên) và trên bản đồ (vị trí sự kiện) được khởi tạo dựa trên một `Seed` cụ thể lưu trong `GameState`. `[PROPOSED]`
2. **Khả năng Replay &amp; Kiểm thử (Replayability):**  
  * Bằng cách lưu lại `Seed` cùng với danh sách vị trí xếp quân ban đầu, động cơ `BattleSimulationEngine` có thể tái hiện chính xác 100% diễn biến trận đấu mà không bị lệch kết quả. `[PROPOSED]`

---

## 10\. XỬ LÝ LỖI &amp; KHÔI PHỤC TRẠNG THÁI (ERROR HANDLING &amp; RECOVERY)

> **Hiện trạng source:** `[CURRENT]` fallback `save_primary` → `save_backup`; `GameState.fromJson` ném `FormatException` với dữ liệu sai (id trùng, gán công trình sai…), và các trường tùy chọn (`hero`, `identity`, `reliefDay`…) có mặc định; không có `SaveMigrator`. `[PLANNED]` khôi phục về màn Deploy khi trận bị ngắt (trận không được lưu); file `campaign_backup.json`. Dòng "Trạng thái không hợp lệ → Sanity Check" được thực hiện lúc đọc bởi `GameState.fromJson`, không phải kiểm tra riêng trong `GameController`.

| Kịch bản Lỗi                | Nguyên nhân                                        | Cơ chế Khôi phục &amp; Xử lý                                                                    |
| --------------------------- | -------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| **Save File bị hỏng**       | Ứng dụng bị tắt đột ngột khi đang ghi file JSON    | Tải file `campaign_backup.json`; nếu thất bại, hiển thị thông báo khôi phục cho người chơi. |
| **Trận đấu bị gián đoạn**   | Nhận cuộc gọi / App bị ngắt ở Background giữa trận | Tự động khôi phục về màn hình **Deploy** trước trận đấu khi mở lại app.                     |
| **Thiếu trường dữ liệu**    | Cập nhật bản Remake mới bổ sung chỉ số mới         | `SaveMigrator` bổ sung giá trị mặc định cho các trường dữ liệu thiếu (`null safety`).       |
| **Trạng thái không hợp lệ** | Lính bị gán vào 2 công trình cùng lúc              | `GameController` tự động kiểm tra quy tắc toàn vẹn (*Sanity Check*) khi load save.          |

---

## 11\. CHIẾN LƯỢC KIỂM THỬ (TESTING STRATEGY)

> **Hiện trạng source:** test nằm phẳng trong `test/` (và `test/equipment/`), không có thư mục `test/domain`, `test/engine`, `test/presentation`. Save/migration có test (`domain_v2_test.dart`, `migration_v2_v3_test.dart`, `identity_save_test.dart`). Con số "1.000 trận headless" và "migration v1→v2 lên v2" trong danh sách dưới là mục tiêu thiết kế, `[UNVERIFIED]`/`[PLANNED]`; save migration thật là v1→v3 và v2→v3.

Để đảm bảo chất lượng cho bản Remake bằng Flutter, hệ thống kiểm thử được chia thành 5 cấp độ:

```
graph BT
    T1[1. Unit Tests - Pure Dart Domain Rules &amp; Calculations] --&gt; T2[2. Controller &amp; State Tests - GameController Transitions]
    T2 --&gt; T3[3. Battle Engine Headless Tests - Deterministic Combat]
    T3 --&gt; T4[4. Save Migration Tests - Backward Compatibility]
    T4 --&gt; T5[5. Widget &amp; Layout Tests - Landscape iPhone 15 Pro Max]

```

1. **Unit Tests (Pure Dart):** Kiểm thử tính đúng đắn của logic trừ tài nguyên Upkeep, tính chỉ số lính và logic hạn chót Quest.
2. **Controller Tests:** Kiểm thử các chuỗi chuyển cảnh và gọi hàm `notifyListeners()` của `GameController`.
3. **Battle Simulation Headless Tests:** Chạy 1,000 trận đấu mô phỏng tự động không có UI để kiểm tra cân bằng và phát hiện lỗi vòng lặp vô tận (*Infinite Loop*).
4. **Save Migration Tests:** Kiểm thử khả năng đọc file save từ Schema V1 nâng cấp lên Schema V2.
5. **Widget &amp; Responsive Tests:** Kiểm thử hiển thị giao diện ở độ phân giải ngang iPhone 15 Pro Max (932x430 pt) và các thiết bị màn hình ngang nhỏ hơn, đảm bảo không bị lỗi đè chữ (*Overflow*).

---

## 12\. HỒ SƠ QUYẾT ĐỊNH KIẾN TRÚC (ARCHITECTURAL DECISION RECORDS - ADR)

### ADR 01: Sử dụng Pure Dart Engine cho Mô phỏng Trận đấu

* **Trạng thái:** `[ACCEPTED]`
* **Bối cảnh:** Cần đảm bảo trận đấu Autobattler chạy mượt mà, có thể kiểm thử đơn giản và tái hiện kết quả mà không bị phụ thuộc vào tốc độ khung hình (FPS) của Flutter UI.
* **Quyết định:** Viết `BattleSimulationEngine` hoàn toàn bằng ngôn ngữ Dart thuần (không dùng Widget hay Flutter Binding trong engine).
* **Hệ quả:** UI chỉ đóng vai trò hiển thị kết quả mô phỏng; dễ dàng viết Headless Unit Tests cho 1,000 trận đấu chỉ trong vài giây.

### ADR 02: Quản lý Trạng thái bằng `ChangeNotifier` \+ `ControllerScope`

* **Trạng thái:** `[ACCEPTED]`
* **Bối cảnh:** Tránh đưa thêm các thư viện phức tạp ngoài hệ sinh thái chuẩn của Flutter.
* **Quyết định:** Sử dụng `GameController` kế thừa `ChangeNotifier` và phân phối state qua custom `InheritedNotifier` (`ControllerScope`).
* **Hệ quả:** Mã nguồn gọn nhẹ, dễ bảo trì và hoàn toàn làm chủ kiến trúc.

### ADR 03: Đóng gói File Save dạng SaveEnvelope với Checksum SHA-256

* **Trạng thái:** `[PROPOSED]` — **chưa triển khai; chưa có quyết định chấp nhận**. Hiện trạng: phong bì `{version, checksum, data}` đã có với checksum FNV-1a 32-bit và lưu trong SharedPreferences (`lib/data/save_repository.dart`); SHA-256 và `SaveEnvelope` như lớp riêng là `[PLANNED]`.
* **Bối cảnh:** Cần bảo vệ file save của người chơi khỏi hư hỏng khi crash và tránh sửa đổi dữ liệu bất hợp lệ.
* **Quyết định:** Đóng gói JSON trong `SaveEnvelope` chứa Schema Version và chuỗi SHA-256 Checksum mã hóa.
* **Hệ quả:** An toàn dữ liệu cao, hỗ trợ Migration mượt mà giữa các phiên bản ứng dụng.

---

### MỤC CẦN KIỂM TRACẬP NHẬT MÃ NGUỒN (`[UNKNOWN]`)

1. **Kiểm tra File Schema thực tế:** *(Đã xác minh ở TASK-003/004: không có file; lưu bằng SharedPreferences với khóa `save_primary`/`save_backup`/`save_archive_v{n}`; cấu trúc JSON ở `game-state-and-save-system.md`.)*
2. **Kiểm tra Animation Frame Rate của Battle Engine:** Source dùng bước mô phỏng 10 Hz (`stepSeconds = 0.1`) và khung hình UI 5 Hz (`frameSeconds = 0.2`); tần số tối ưu cho iOS vẫn `[UNVERIFIED]`.