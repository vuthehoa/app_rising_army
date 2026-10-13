import 'package:flutter/foundation.dart';

import '../data/save_repository.dart';
import '../domain/battle.dart';
import '../domain/catalog.dart';
import '../domain/dev_mode.dart';
import '../domain/identity.dart';
import '../domain/map_anchor.dart';
import '../domain/models.dart';
import '../domain/rules.dart';
import 'hero_travel.dart';

/// Kết quả tạo ván mới có danh tính. [issues] không rỗng: cấu hình sai, chưa có gì bị thay đổi.
/// [saveError] khác null: không lưu được, ván mới bị bỏ và ván hiện tại giữ nguyên.
class NewGameResult {
  const NewGameResult.ok() : issues = const [], saveError = null;
  const NewGameResult.invalid(this.issues) : saveError = null;
  const NewGameResult.saveFailed(this.saveError) : issues = const [];

  final List<IdentityIssue> issues;
  final String? saveError;
  bool get ok => issues.isEmpty && saveError == null;
}

/// Cầu nối UI <-> luật. Mọi thay đổi state đi qua đây và được lưu tự động.
class GameController extends ChangeNotifier {
  GameController(this._repo);

  final SaveRepository _repo;

  GameState? _state;
  LoadStatus loadStatus = LoadStatus.none;
  String? saveError;
  DayReport? lastDayReport;
  ExpeditionResult? lastExpedition;
  GameState? _pendingSave;

  /// true ngay sau khi tạo ván mới thành công; shell dùng để mở màn Xây dựng đầu tiên.
  bool freshGame = false;

  GameState? get state => _state;

  /// Điều phối đi bộ trên bản đồ khám phá. Vị trí/thể lực nằm ở [GameState.hero].
  late final HeroTravel travel = HeroTravel(() => _state, commitTravel);

  /// Lưu vị trí/thể lực sau khi nhân vật dừng và báo UI toàn game dựng lại một lần.
  void commitTravel() {
    if (_state == null) return;
    notifyListeners();
    _persist();
  }

  /// Develop Mode: miễn chi phí tài nguyên (chỉ debug). Không phải tiến trình: không vào save,
  /// không đổi GameState; chỉ báo UI dựng lại. Xem [DevMode].
  bool get devMode => DevMode.enabled;

  void setDevMode(bool value) {
    if (DevMode.enabled == value || !DevMode.available) return;
    DevMode.enabled = value;
    notifyListeners();
  }

  bool get hasSave => _pendingSave != null;

  /// Danh tính của ván đang chơi (null khi đang ở menu).
  PlayerIdentity? get identity => _state?.identity;

  /// Neo hiển thị avatar trên bản đồ, dẫn xuất từ state (null khi chưa có ván).
  MapAnchor? get avatarAnchor =>
      _state == null ? null : resolveMapAnchor(_state!);

  /// Kiểm tra bản nháp ở màn New Game; thuần, không đụng state.
  List<IdentityIssue> checkIdentityDraft(IdentityDraft draft) =>
      validateIdentityDraft(draft);

  /// Hợp thành quân kỳ để preview; thuần.
  FlagComposition previewFlag(LegionFlag flag) => composeFlag(flag);

  Future<void> init() async {
    final r = await _repo.load();
    loadStatus = r.status;
    _pendingSave = r.state;
    notifyListeners();
  }

  void continueGame() {
    _state = _pendingSave;
    freshGame = false;
    _placing = null;
    _movingId = null;
    travel.reset();
    // Save cũ có Doanh trại cấp > 0 nhưng chưa có instance trong trại: tạo để trại hiển thị đúng.
    var repaired = false;
    if (_state != null) {
      repaired |= GameRules.syncBarracksInstance(_state!);
      // Save cũ có công trình nằm ngoài vùng đất mới hoặc chồng nhau: dời tới vị trí hợp lệ gần nhất.
      repaired |= GameRules.repairCampLayout(_state!);
    }
    if (repaired) _persist();
    notifyListeners();
  }

  Future<void> newGame({int? seed}) async {
    _state = GameRules.newGame(
      seed: seed ?? DateTime.now().millisecondsSinceEpoch % 1000000,
    );
    lastDayReport = null;
    lastExpedition = null;
    _placing = null;
    _movingId = null;
    travel.reset();
    await _persist();
    notifyListeners();
  }

  /// Tạo ván mới với danh tính đã chọn, một thao tác nguyên tử:
  /// kiểm tra → dựng state → lưu → chỉ khi lưu thành công mới thay state hiện tại.
  /// Thất bại ở bước nào thì `state`, lastDayReport, lastExpedition và `hasSave` giữ nguyên.
  Future<NewGameResult> createGame({
    int? seed,
    required IdentityDraft draft,
  }) async {
    final identity = draft.toIdentity();
    if (identity == null) {
      return NewGameResult.invalid(validateIdentityDraft(draft));
    }
    final candidate = GameRules.newGame(
      seed: seed ?? DateTime.now().millisecondsSinceEpoch % 1000000,
      identity: identity,
    );
    try {
      await _repo.save(candidate);
    } catch (e) {
      return NewGameResult.saveFailed('Không thể lưu game: $e');
    }
    _state = candidate;
    travel.reset();
    freshGame = true;
    saveError = null;
    lastDayReport = null;
    lastExpedition = null;
    notifyListeners();
    return const NewGameResult.ok();
  }

  void backToMenu() {
    if (_state != null) _persist(); // lưu vị trí/thể lực hiện tại
    _pendingSave = _state;
    _state = null;
    freshGame = false;
    travel.reset();
    notifyListeners();
  }

  ActionResult upgradeBuilding(Building b) =>
      _apply(() => GameRules.upgradeBuilding(_state!, b));
  ActionResult hire(int id) => _apply(() => GameRules.hire(_state!, id));

  /// Chiêu mộ tại Quán rượu (đường dùng cho UI): xác thực vị trí/quán rồi dùng đúng luật [hire].
  ActionResult hireAtTavern(String vendorId, int candidateId) =>
      _apply(() => GameRules.hireAtTavern(_state!, vendorId, candidateId));
  ActionResult rename(int id, String n) =>
      _apply(() => GameRules.rename(_state!, id, n));
  ActionResult assignToFacility(int soldier, int facility) =>
      _apply(() => GameRules.assignToFacility(_state!, soldier, facility));
  ActionResult learnSkill(int soldier, String skill) =>
      _apply(() => GameRules.learnSkill(_state!, soldier, skill));
  ActionResult chooseTalent(int soldier, String talent) =>
      _apply(() => GameRules.chooseTalent(_state!, soldier, talent));
  ActionResult moveSoldier(int soldier, double x, double y) =>
      _apply(() => GameRules.moveSoldier(_state!, soldier, x, y));
  ActionResult dismiss(int soldier) =>
      _apply(() => GameRules.dismiss(_state!, soldier));
  ActionResult unassign(int soldier) =>
      _apply(() => GameRules.unassign(_state!, soldier));

  // ---------- Xây dựng trong trại: chọn công trình → chọn vị trí → xác nhận ----------

  FacilityType? _placing;

  /// Công trình đang chờ người chơi chọn vị trí trong trại (null = không ở chế độ đặt). Trạng thái UI,
  /// không nằm trong save; mọi giao diện (menu Build, BuildingsScreen) dùng chung để CampHub hiển thị ô đặt.
  FacilityType? get placing => _placing ?? movingFacility?.type;

  // ---------- Di chuyển công trình đã đặt (dùng chung lớp đặt với xây mới) ----------

  int? _movingId;

  /// Trạng thái UI (không lưu): công trình đang được dời. Dữ liệu chỉ đổi khi [confirmMoveAt] thành công.
  int? get movingId => _movingId;
  Facility? get movingFacility =>
      _movingId == null ? null : GameRules.facilityById(_state!, _movingId!);

  /// Vị trí xem trước (chuẩn hóa) khi kéo bằng nhấn giữ; null = chưa kéo.
  (double, double)? movePreview;

  ActionResult startMove(int facilityId) {
    final f = GameRules.facilityById(_state!, facilityId);
    if (f == null) return const ActionResult.fail('Công trình không tồn tại.');
    _placing = null;
    _movingId = facilityId;
    movePreview = null;
    notifyListeners();
    return ActionResult.ok(
      'Chọn vị trí mới cho ${facilityDefs[f.type]!.name}.',
    );
  }

  /// Xem trước vị trí khi kéo công trình MỚI từ menu Xây (cùng ghost với dời công trình).
  void updatePlacementPreview(double x, double y) {
    if (placing == null) return;
    movePreview = (x, y);
    notifyListeners();
  }

  /// Thả công trình mới kéo từ menu Xây tại (x, y): hợp lệ thì xây đúng một lần; không hợp lệ thì KHÔNG
  /// mất công trình, vẫn ở chế độ đặt (ghost đỏ) để thử lại hoặc hủy.
  ActionResult finishDragPlace(double x, double y) {
    if (_movingId != null) return finishDragMove(x, y);
    final r = confirmPlacementAt(x, y);
    if (!r.ok) notifyListeners();
    return r;
  }

  void updateMovePreview(double x, double y) {
    if (_movingId == null) return;
    movePreview = (x, y);
    notifyListeners();
  }

  /// Thả tại (x, y). Hợp lệ: đổi tọa độ, lưu, thoát chế độ. Không hợp lệ: không đổi gì, vẫn ở chế độ dời
  /// (nút Hủy trả về vị trí cũ).
  ActionResult confirmMoveAt(double x, double y) {
    final id = _movingId;
    if (id == null) {
      return const ActionResult.fail('Chưa chọn công trình để dời.');
    }
    final r = GameRules.moveFacility(_state!, id, x, y);
    if (r.ok) {
      _movingId = null;
      movePreview = null;
      _afterChange();
    } else {
      notifyListeners();
    }
    return r;
  }

  /// Kết thúc kéo-nhấn-giữ: sai vị trí thì hủy hẳn, công trình về chỗ cũ.
  ActionResult finishDragMove(double x, double y) {
    final r = confirmMoveAt(x, y);
    if (!r.ok) cancelPlacement();
    return r;
  }

  ActionResult removeFacility(int id) =>
      _apply(() => GameRules.removeFacility(_state!, id));
  ActionResult upgradeFacility(int id) =>
      _apply(() => GameRules.upgradeFacility(_state!, id));
  ActionResult reviveSoldier(int id) =>
      _apply(() => GameRules.reviveSoldier(_state!, id));

  /// Chọn một mục của catalog trại. XÂY MỚI chỉ bắt đầu chế độ đặt (chưa trừ gì, chưa đổi state);
  /// NÂNG CẤP (Doanh trại đã xây) thực hiện ngay qua luật. Trả về kết quả để UI báo.
  ActionResult chooseCampBuilding(CampBuildingDef d) {
    final s = _state!;
    final st = GameRules.campStatus(s, d);
    if (!st.canAct) {
      return ActionResult.fail(st.reason ?? 'Không thể xây.');
    }
    if (!st.needsPlacement) return upgradeBuilding(d.building!);
    _placing = d.facility;
    notifyListeners();
    return ActionResult.ok(
      'Chọn vị trí trong trại để đặt ${facilityDefs[d.facility]!.name}.',
    );
  }

  void cancelPlacement() {
    if (_placing == null && _movingId == null) return;
    _placing = null;
    _movingId = null;
    movePreview = null;
    notifyListeners();
  }

  /// Thả công trình đang chờ tại (x, y) (tọa độ chuẩn hóa của khung Trại). Luật xác thực lại vị trí bằng đúng
  /// hàm giao diện dùng để tô xanh/đỏ ([GameRules.checkPlacement]).
  /// * Vị trí không hợp lệ: không xây, không trừ phí, vẫn ở chế độ đặt để thử lại hoặc hủy.
  /// * Hợp lệ: xây đúng một lần, trừ phí và thoát chế độ đặt (chống bấm/thả lặp).
  /// * Lỗi khác (ví dụ thiếu tài nguyên): không đổi gì và thoát chế độ đặt.
  ActionResult confirmPlacementAt(double x, double y) {
    final type = _placing;
    if (type == null) {
      return const ActionResult.fail('Chưa chọn công trình để xây.');
    }
    final check = GameRules.checkPlacement(_state!, type, x, y);
    if (!check.ok) return ActionResult.fail(check.message);
    _placing = null;
    _movingId = null;
    movePreview = null;
    final r = _apply(() => GameRules.buildFacilityAt(_state!, type, x, y));
    if (!r.ok) notifyListeners();
    return r;
  }

  /// Đặt theo ô tham chiếu (lối gọi tương thích): luôn thoát chế độ đặt.
  ActionResult confirmPlacement(int index) {
    final type = _placing;
    if (type == null) {
      return const ActionResult.fail('Chưa chọn công trình để xây.');
    }
    _placing = null;
    _movingId = null;
    final r = _apply(() => GameRules.buildFacility(_state!, type, index));
    if (!r.ok) notifyListeners();
    return r;
  }

  ActionResult buildFacility(FacilityType type, int slot) =>
      _apply(() => GameRules.buildFacility(_state!, type, slot));
  ActionResult equip(int id, String item) =>
      _apply(() => GameRules.equip(_state!, id, item));
  ActionResult unequip(int id, Slot slot) =>
      _apply(() => GameRules.unequip(_state!, id, slot));
  ActionResult buy(String item) => _apply(() => GameRules.buy(_state!, item));
  ActionResult acceptMission(int id) =>
      _apply(() => GameRules.acceptMission(_state!, id));
  ActionResult abandonMission(int id) =>
      _apply(() => GameRules.abandonMission(_state!, id));
  ActionResult completeMission(int id) =>
      _apply(() => GameRules.completeMission(_state!, id));
  ActionResult enterTown(String id) =>
      _apply(() => GameRules.enterTown(_state!, id));

  ActionResult buyFromVendor(String vendor, String item, int qty) =>
      _apply(() => GameRules.buyFromVendor(_state!, vendor, item, qty));
  ActionResult buyAndEquip(String vendor, String item, int soldier) =>
      _apply(() => GameRules.buyAndEquip(_state!, vendor, item, soldier));
  ActionResult sellToVendor(String vendor, String item, int qty) =>
      _apply(() => GameRules.sellToVendor(_state!, vendor, item, qty));
  ActionResult buyResourceLots(String vendor, Res res, int lots) =>
      _apply(() => GameRules.buyResourceLots(_state!, vendor, res, lots));
  ActionResult sellResourceLots(String vendor, Res res, int lots) =>
      _apply(() => GameRules.sellResourceLots(_state!, vendor, res, lots));
  ActionResult leaveCity() => _apply(() => GameRules.leaveCity(_state!));

  /// Logic qua ngày (lương, huấn luyện, hồi phục, sự kiện). KHÔNG còn được UI gọi: người chơi không
  /// có thao tác kết thúc ngày. Giữ lại cho mô phỏng/test và để hệ thống thời gian không mất.
  DayReport endDay() {
    final r = GameRules.tickDay(_state!);
    lastDayReport = r;
    _afterChange();
    return r;
  }

  ExpeditionResult sendExpedition(
    String loc,
    List<int> squad,
    Set<int> front, {
    Map<int, Pos>? placement,
  }) {
    final r = GameRules.sendExpedition(
      _state!,
      loc,
      squad,
      front,
      placement: placement,
    );
    if (r.result.ok) {
      lastExpedition = r;
      _afterChange();
    }
    return r;
  }

  ActionResult _apply(ActionResult Function() action) {
    final r = action();
    if (r.ok) _afterChange();
    return r;
  }

  void _afterChange() {
    notifyListeners();
    _persist();
  }

  Future<void> _persist() async {
    try {
      await _repo.save(_state!);
      saveError = null;
    } catch (e) {
      saveError = 'Không thể lưu game: $e';
      notifyListeners();
    }
  }
}
