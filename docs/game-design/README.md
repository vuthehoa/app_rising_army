# BỘ TÀI LIỆU THIẾT KẾ &amp; KIẾN TRÚC: RISING ARMY REMAKE

**Dự án:** Rising Army Remake (Flutter iOS - Landscape, iPhone 15 Pro Max)  
**Tập tin mục tiêu:** `docs/game-design/README.md`

---

## 1\. GIỚI THIỆU DỰ ÁN &amp; VÒNG LẶP GAMEPLAY CỐT LÕI

**Rising Army Remake** là dự án tái dựng bằng Flutter (iOS Landscape) của trò chơi *Rising Army* (Arkbits) — tựa game chiến thuật nhập vai kết hợp mô phỏng doanh trại trung cổ (Camp Sim) và chiến đấu tự động (Auto-Battler).

Vòng lặp gameplay cốt lõi tuần hoàn qua 7 giai đoạn:

$$\\text{Camp} \\longrightarrow \\text{Map} \\longrightarrow \\text{Town/Quests} \\longrightarrow \\text{Deploy} \\longrightarrow \\text{Battle} \\longrightarrow \\text{Result} \\longrightarrow \\text{Return to Camp}$$

* **Trải nghiệm chính:** Quản lý quân đoàn (lính, sức khỏe, thể lực, sĩ khí, permadeath), xây dựng/nâng cấp doanh trại, di chuyển mở rộng bản đồ, nhận nhiệm vụ phục vụ Vua và chiến đấu dàn trận tự động.

---

## 2\. DANH MỤC TÀI LIỆU TRONG `docs/game-design/`

Toàn bộ bộ tài liệu thiết kế và kiến trúc kỹ thuật được phân chia theo từng phạm vi chuyên biệt.

> **Cập nhật theo TASK-004.** Tên file tồn tại **không** có nghĩa nội dung đã hoàn chỉnh. Cột "Trạng thái nội dung" bên dưới cho biết file có nội dung hay đang rỗng (0 byte) và mức đối chiếu với source. Tài liệu thiết kế trộn tham chiếu game gốc, đề xuất và hiện trạng; khi mâu thuẫn, **source và test là căn cứ cho hiện trạng**. Nhãn: `[CURRENT]` đã xác minh trong source; `[PLANNED]` chưa triển khai; `[UNVERIFIED]` chưa đủ bằng chứng.

| STT    | Tập tin                         | Mục đích &amp; Nội dung chính                                                                                                                            | Khi nào cần đọc?                                                               |
| ------ | ------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **01** | `source-catalog.md`             | Kiểm kê danh mục nguồn gốc, URL, phân loại bằng chứng và các khoảng trống dữ liệu (`[UNKNOWN]`).                                                     | Cần xác minh nguồn gốc tính năng hoặc kiểm tra bằng chứng gốc.                 |
| **02** | `game-overview.md`              | **Đang chờ soạn (file rỗng, 0 byte).** Dự kiến: tổng quan game, thể loại, bối cảnh, chế độ chơi. Hiện chỉ có luồng Campaign trong source; Sandbox/Arena là `[PLANNED]`. | Bắt đầu tìm hiểu dự án hoặc kiểm tra bối cảnh tổng thể.                        |
| **03** | `gameplay-core-loop.md`         | Đặc tả chi tiết 7 bước trong vòng lặp gameplay cốt lõi kèm phân cấp chứng cứ (`[OFFICIAL]`, `[OBSERVED]`, `[UNKNOWN]`).                              | Lập trình hoặc kiểm thử luồng chuyển cảnh &amp; quy trình qua ngày (`End Day`).    |
| **04** | `ui-ux-specification.md`        | Đặc tả layout UI/UX 8 màn hình, chuẩn hóa Safe Area landscape iPhone 15 Pro Max (932x430 pt) và quy tắc cảm ứng (Touch Target $\\ge 44\\text{ pt}$). | Lập trình Widget, thiết kế giao diện, xử lý kéo-thả và layout responsive.      |
| **05** | `gameplay-systems.md`           | Đặc tả 9 hệ thống gameplay cốt lõi (Soldier, Camp, Economy, Map, Quest, Deploy, Combat, Progression, Modes).                                         | Triển khai logic nghiệp vụ domain, quy tắc tính toán hoặc trạng thái hệ thống. |
| **06** | `game-balance.md`               | Thông số cân bằng gameplay, phí duy trì, giới hạn lính và công thức. Số liệu game gốc (Max 20, Level 5…) chỉ là tham chiếu; **hiện trạng source** (roster `6 + 4 × cấp Doanh trại`, cấp tối đa 6, upkeep theo cấp…) nằm trong các khối "Hiện trạng source" của file.                | Cân bằng chỉ số, điều chỉnh thông số game hoặc thiết kế bài test cân bằng.     |
| **07** | `technical-architecture.md`     | Architecture 4 tầng (Presentation, Application, Domain, Data) khớp cấu trúc `lib/`; engine trận là hàm `simulateBattle` (bước 0,1 giây), không phải lớp `BattleSimulationEngine`; SHA-256/`SeededRandom` là `[PLANNED]`; các ADRs.                 | Thiết kế cấu trúc module, phân tầng code, tách biệt UI và Pure Dart Engine.    |
| **08** | `game-state-and-save-system.md` | Schema `GameState` thực tế (theo `toJson/fromJson`), phong bì save `{version, checksum, data}` với checksum FNV-1a 32-bit, khóa SharedPreferences, backup/archive, migration `migrateV1toV3`/`migrateV2toV3`. Không có `CampaignState`/`SoldierState`/`BattleState` riêng; SHA-256, `.tmp`, `.bak` là `[PLANNED]`.                      | Triển khai hoặc hiệu chỉnh hệ thống Save/Load, quản lý state persistence.      |
| **09** | `content-and-data-catalog.md`   | Bảng tra cứu dữ liệu (Data Catalog), Data Dictionary 24 trường, danh mục vũ khí, giáp, công trình, sự kiện và QA checklist.                          | Cấu hình data models, tạo mock data, seed data hoặc đối chiếu trường dữ liệu.  |
| **10** | `acceptance-criteria.md`        | Tiêu chí nghiệm thu dạng Given/When/Then, QA Test Matrix 11 kịch bản và Definition of Done (DoD) từng module.                                        | Kiểm thử QA, viết Unit/Widget tests và nghiệm thu tính năng trước khi merge.   |
| **11** | `implementation-roadmap.md`     | Hiện trạng theo Phase (đã cập nhật theo source), sơ đồ phụ thuộc module, Testing Gates và danh sách công việc đề xuất. Roadmap thực tế là file này (`docs/roadmap/implementation-roadmap.md` đang rỗng).                                              | Chọn task tiếp theo, kiểm tra thứ tự phụ thuộc và lộ trình phát triển.         |
| **12** | `agent-execution-guide.md`      | Quy chuẩn thực thi an toàn cho Coding Agent (Pre-flight audit, Git safety, workflow 6 bước, task template).                                          | **Coding Agent bắt buộc đọc trước mỗi lượt nhận task.**                        |

### Trạng thái nội dung (đối chiếu ngày TASK-004)

**Có nội dung, đã đối chiếu với source (TASK-003/004):** `gameplay-systems.md`, `game-balance.md`, `technical-architecture.md`, `game-state-and-save-system.md`, `acceptance-criteria.md`, `implementation-roadmap.md`, `deployment-and-formation.md` (mới, ngắn, dựng từ source).

**Có nội dung, chưa đối chiếu với source `[UNVERIFIED]`:** `source-catalog.md`, `gameplay-core-loop.md`, `ui-ux-specification.md`, `content-and-data-catalog.md`, `agent-execution-guide.md`. Đừng coi các số liệu hay tên lớp trong đó là hiện trạng khi chưa kiểm.

**Đang chờ soạn (file rỗng, 0 byte; không dùng làm căn cứ):** `battle-system.md`, `camp-and-buildings.md`, `campaign-and-progression.md`, `economy-and-resources.md`, `game-modes.md`, `game-overview.md`, `rewards-and-loot.md`, `soldiers-and-equipment.md`, `towns-and-quests.md`, `version-history.md`, `world-map-and-exploration.md`. Nội dung tương ứng hiện nằm rải rác trong `gameplay-systems.md` và `game-balance.md`.

**Thư mục khác (kiểm tra kích thước thực tế):** `docs/architecture/` — 6 file đều rỗng; `docs/roadmap/` — 5 file đều rỗng; `docs/qa/` — 5 báo cáo có nội dung (`ECONOMY_BALANCE_V3.md`, `ECONOMY_LOOP_V4.md`, `QUEST_DEADLINE_BALANCE.md`, `QUEST_XP_AUDIT.md`, `SOLDIER_CONDITION_BALANCE.md`) và 6 file rỗng (`README.md`, `bug-tracker.md`, `gameplay-test-cases.md`, `regression-checklist.md`, `test-strategy.md`, `verification-report.md`). Các báo cáo QA chưa được đối chiếu lại ở đây.

---

## 3\. THỨ TỰ ĐỌC ĐỀ XUẤT CHO CODING AGENT (CODEX / CLAUDE CODE)

Khi chuẩn bị bắt đầu một lượt xử lý (task) mới, Coding Agent cần đọc tài liệu theo đúng thứ tự sau:

```
[1] agent-execution-guide.md (Quy tắc an toàn &amp; Workflow)
       │
       ▼
[2] implementation-roadmap.md (Xác định Phase &amp; Task cần làm)
       │
       ▼
[3] technical-architecture.md / game-state-and-save-system.md (Hiểu kiến trúc &amp; State)
       │
       ▼
[4] gameplay-systems.md / ui-ux-specification.md (Đặc tả chi tiết tính năng đang làm)
       │
       ▼
[5] acceptance-criteria.md (Đọc tiêu chí nghiệm thu để viết test &amp; self-check)

```

---

## 4\. QUY TẮC ƯU TIÊN KHI ĐỐI CHIẾU THỰC TẾ (REPOSITORY VS DESIGN DOCS)

1. **Audit mã nguồn thực tế là ưu tiên hàng đầu:**  
  * Tài liệu thiết kế chứa cả thông tin từ game gốc (`[OFFICIAL]`, `[OBSERVED]`), định hướng kiến trúc (`[PROPOSED]`) và các điểm chưa rõ (`[UNKNOWN]`).
  * Khi tài liệu thiết kế mâu thuẫn hoặc chưa cập nhật so với mã nguồn thực tế đang hoạt động tốt trong repository, Agent **bắt buộc phải lấy code thực tế làm chuẩn** và ghi nhận lại điểm mâu thuẫn.
2. **Bảo vệ tính năng &amp; Save file hiện có:**  
  * Tuyệt đối không thay đổi schema `SaveEnvelope`, xóa trường dữ liệu cũ hoặc làm gãy luồng Save/Load đang chạy trừ khi task có yêu cầu rõ ràng.
3. **Không tự suy diễn / Không báo cáo sai sự thật:**  
  * Không giả định một class, method hoặc test case đã tồn tại nếu chưa chạy audit `find/ls/grep`.
  * Chỉ báo cáo `PASSED` cho test hoặc build khi đã thực sự chạy lệnh CLI (`flutter test`, `flutter analyze`) và trả về exit code 0.

---

## 5\. QUY TRÌNH LÀM VIỆC RÚT GỌN (AGENT WORKFLOW)

$$\\text{1\. Chọn Task} \\longrightarrow \\text{2\. Audit Repository} \\longrightarrow \\text{3\. Kế hoạch Tối thiểu} \\longrightarrow \\text{4\. Triển khai trong Phạm vi} \\longrightarrow \\text{5\. Run Format / Analyze / Test} \\longrightarrow \\text{6\. Báo cáo Bằng chứng}$$

* **Thực thi tối thiểu (Minimal Change):** Chỉ chỉnh sửa các file trong phạm vi task. Cấm tự ý refactor toàn bộ dự án hoặc thay đổi các dependency ngoài yêu cầu.