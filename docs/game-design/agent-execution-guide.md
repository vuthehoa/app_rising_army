# HƯỚNG DẪN THỰC THI CHO CODING AGENT (AGENT EXECUTION GUIDE)

**Dự án:** Rising Army Remake (Flutter, iOS Landscape, iPhone 15 Pro Max)  
**Tập tin mục tiêu:** `docs/game-design/agent-execution-guide.md`

---

## MỤC LỤC

1. [Pre-flight Audit (Kiểm tra tiền thực thi)](#1-pre-flight-audit-ki%E1%BB%83m-tra-ti%E1%BB%81n-th%E1%BB%B1c-thi)
2. [Evidence Rules (Quy tắc bằng chứng trạng thái)](#2-evidence-rules-quy-t%E1%BA%AFc-b%E1%BA%B1ng-ch%E1%BB%A9ng-tr%E1%BA%A1ng-th%C3%A1i)
3. [Task Scope &amp; Boundary Rules (Phạm vi công việc &amp; Ranh giới)](#3-task-scope--boundary-rules-ph%E1%BA%A1m-vi-c%C3%B4ng-vi%E1%BB%87c--ranh-gi%E1%BB%9Bi)
4. [Standard Implementation Workflow (Quy trình thực thi chuẩn)](#4-standard-implementation-workflow-quy-tr%C3%ACnh-th%E1%BB%B1c-thi-chu%E1%BA%A9n)
5. [Regression &amp; Save Integrity Safety (An toàn hồi quy &amp; Bảo vệ dữ liệu)](#5-regression--save-integrity-safety-an-to%C3%A0n-h%E1%BB%93i-quy--b%E1%BA%A3o-v%E1%BB%87-d%E1%BB%AF-li%E1%BB%87u)
6. [Testing &amp; Truthful Reporting (Kiểm thử &amp; Báo cáo trung thực)](#6-testing--truthful-reporting-ki%E1%BB%83m-th%E1%BB%AD--b%E1%BA%A3o-c%C3%A1o-trung-th%E1%BB%B1c)
7. [Git Operations &amp; Safety Constraints (An toàn Git &amp; Thao tác mã nguồn)](#7-git-operations--safety-constraints-an-to%C3%A0n-git--thao-t%C3%A1c-m%C3%A3-ngu%E1%BB%93n)
8. [Copy-Ready Task Template (Mẫu Prompt giao việc chuẩn)](#8-copy-ready-task-template-m%E1%BA%ABu-prompt-giao-vi%E1%BB%87c-chu%E1%BA%A9n)

---

### 1\. Pre-flight Audit (Kiểm tra tiền thực thi)

Trước khi chỉnh sửa bất kỳ tập tin mã nguồn hoặc tài liệu nào, Coding Agent (Codex / Claude Code) BẮT BUỘC thực hiện các bước kiểm tra tiền thực thi:

1. **Kiểm tra trạng thái Git (`git status`):** Xác định các file đang bị chỉnh sửa, uncommitted changes, hoặc mâu thuẫn branch. Không ghi đè hoặc xóa các thay đổi dở dang của lượt trước.
2. **Kiểm tra cấu trúc mã nguồn thực tế:** Chạy lệnh `list_dir` hoặc tìm kiếm tập tin để xác nhận thư mục và tập tin mục tiêu THỰC SỰ TỒN TẠI trong repository. Không giả định file nằm đúng vị trí đề xuất trong GDD.
3. **Kiểm tra trạng thái Build &amp; Test hiện tại:** Chạy `flutter analyze` và `flutter test` để xác định baseline. Nếu codebase hiện tại đang có lỗi, ghi nhận rõ lỗi baseline trước khi bắt đầu công việc mới.
4. **Đối chiếu tài liệu thiết kế:** Đọc các file đặc tả liên quan trong `docs/game-design/` (`technical-architecture.md`, `game-state-and-save-system.md`, `implementation-roadmap.md`) để nắm rõ ranh giới module.

---

### 2\. Evidence Rules (Quy tắc bằng chứng trạng thái)

Coding Agent phải tuyệt đối tuân thủ nhãn bằng chứng để tránh làm lệch trạng thái dự án:

* **`[CURRENT]`**: Các module, class, widget hoặc logic ĐÃ ĐƯỢC XÁC NHẬN TỒN TẠI trong repository qua kiểm tra file thực tế.
* **`[TO VERIFY]`**: Các thành phần nghi vấn có trong codebase nhưng chưa được chạy test hoặc audit trực tiếp.
* **`[PLANNED]`**: Các tính năng, schema, hoặc UI mới được đề xuất trong tài liệu thiết kế, CHƯA ĐƯỢC LẬP TRÌNH trong repository.

*Cấm tuyệt đối:* Không coi đề xuất trong `game-balance.md` hay `technical-architecture.md` là tính năng đã tồn tại `[CURRENT]`.

---

### 3\. Task Scope &amp; Boundary Rules (Phạm vi công việc &amp; Ranh giới)

1. **Một lượt - Một Task (Single Task Focus):** Mỗi lượt tương tác chỉ tập trung hoàn thành duy nhất 1 Task được giao trong `implementation-roadmap.md` (ví dụ: `TASK-001`).
2. **Không tự ý mở rộng phạm vi (No Scope Creep):** Không tự thêm tính năng ngoài mô tả của Task, không tự refactor các module không liên quan, không tự ý chuyển đổi package quản lý trạng thái hay cấu trúc thư mục.
3. **Sửa đổi tối thiểu (Minimal Touch Rule):** Chỉ chạm vào các file nằm trong phạm vi phụ thuộc của Task. Nếu phát hiện file ngoài bị lỗi, báo cáo lại thay vì tự ý sửa.

---

### 4\. Standard Implementation Workflow (Quy trình thực thi chuẩn)

Mọi lượt xử lý của Coding Agent phải tuân theo 6 bước nghiêm ngặt:

$$\\text{Audit Repo} \\longrightarrow \\text{Short Plan} \\longrightarrow \\text{Minimal Implementation} \\longrightarrow \\text{Format &amp; Analyze} \\longrightarrow \\text{Targeted Tests} \\longrightarrow \\text{Truthful Report}$$

1. **Step 1 - Audit:** Kiểm tra Git status, vị trí file và chạy `flutter analyze`.
2. **Step 2 - Plan:** Lập kế hoạch ngắn (3–5 dòng) nêu rõ các file sẽ tạo/sửa.
3. **Step 3 - Implement:** Viết code tối thiểu, sạch sẽ, tuân thủ Clean Layered Architecture (Domain $\\rightarrow$ Application $\\rightarrow$ Presentation).
4. **Step 4 - Format &amp; Analyze:** Chạy `dart format .` và `flutter analyze` để đảm bảo không có warning/error mới.
5. **Step 5 - Targeted Test:** Viết và chạy Unit Test/Widget Test trực tiếp cho tính năng vừa sửa.
6. **Step 6 - Report:** Báo cáo kết quả trung thực, nêu rõ lệnh đã chạy và đầu ra thực tế.

---

### 5\. Regression &amp; Save Integrity Safety (An toàn hồi quy &amp; Bảo vệ dữ liệu)

1. **Bảo vệ Save Data cũ:** Tuyệt đối không thay đổi schema JSON của `SaveEnvelope` hoặc chìa khóa `SharedPreferences` / `path_provider` nếu chưa có kế hoạch migration trong `game-state-and-save-system.md`.
2. **Bảo toàn Gameplay đang chạy:** Khi sửa đổi logic trong `GameController` hoặc `BattleSimulationEngine`, đảm bảo các luồng `End Day`, tuyển lính, tính Upkeep và chuyển cảnh không bị đứt gãy.
3. **Bảo vệ Responsive Layout Landscape:** Mọi UI mới hoặc chỉnh sửa phải kiểm tra tương thích màn hình ngang (iPhone 15 Pro Max: 932x430 pt), tuân thủ `SafeArea` để không bị đè bởi Tai thỏ/Dynamic Island, diện tích cảm ứng Touch Target $\\ge 44\\times 44\\text{ pt}$.
4. **Không tự ý thêm Dependency:** Không chạy `flutter pub add` các thư viện ngoài nếu chưa được phê duyệt.

---

### 6\. Testing &amp; Truthful Reporting (Kiểm thử &amp; Báo cáo trung thực)

1. **Quy tắc Báo cáo Thật:** CHỈ BÁO `PASSED` khi lệnh test thực sự trả về exit code 0\. Nếu không chạy được test (do thiếu môi trường hoặc build error), BẮT BUỘC ghi rõ `UNVERIFIED` hoặc `NOT RUN`.
2. **Nội dung Báo cáo chuẩn:**  
  * **Lệnh đã thực thi:** (ghi rõ lệnh, e.g., `flutter analyze`, `flutter test test/domain/soldier_test.dart`).
  * **Kết quả:** Pass/Fail (trích dẫn số test passed, warnings nếu có).
  * **File đã thay đổi:** Danh sách tập tin bị tác động.
  * **Vấn đề còn tồn đọng:** Lỗi baseline chưa sửa hoặc điểm cần kiểm tra thêm ở lượt sau.

---

### 7\. Git Operations &amp; Safety Constraints (An toàn Git &amp; Thao tác mã nguồn)

* **CẤM:** Không tự ý chạy `git commit`, `git push`, `git reset --hard`, `git stash`, hay `git clean -fd`.
* **CẤM:** Không xóa các file tài liệu thiết kế trong `docs/game-design/` hay các test file hiện có.
* Để người dùng hoặc hệ thống CI/CD tự thực hiện các thao tác Git commit/push sau khi review báo cáo.

---

### 8\. Copy-Ready Task Template (Mẫu Prompt giao việc chuẩn)

Coding Agent hoặc người dùng có thể sao chép mẫu prompt dưới đây để giao task cụ thể:

```
### TASK ASSIGNMENT: [Tên Task, e.g., TASK-001: Domain Model Soldier &amp; Validation]

**1. Mục tiêu:**
[Mô tả ngắn gọn mục tiêu cần đạt được]

**2. Phạm vi tập tin (Target Files):**
- Mới / Chỉnh sửa: `lib/domain/models/...`
- Test: `test/domain/...`

**3. Tài liệu tham chiếu:**
- GDD: `docs/game-design/gameplay-systems.md`
- Architecture: `docs/game-design/technical-architecture.md`
- State: `docs/game-design/game-state-and-save-system.md`

**4. Ràng buộc thực thi:**
- Tuân thủ Agent Execution Guide (`docs/game-design/agent-execution-guide.md`).
- Phải thực hiện Pre-flight Audit trước khi sửa code.
- Giữ nguyên các tính năng đang hoạt động `[CURRENT]`.
- Không tự thêm dependency ngoài.

**5. Kiểm thử &amp; Báo cáo:**
- Chạy `dart format .` và `flutter analyze`.
- Chạy Unit Test tương ứng: `flutter test test/...`.
- Báo cáo kết quả trung thực theo mẫu trong Execution Guide.
```