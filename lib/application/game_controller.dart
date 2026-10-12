import 'package:flutter/foundation.dart';

import '../data/save_repository.dart';
import '../domain/battle.dart';
import '../domain/identity.dart';
import '../domain/map_anchor.dart';
import '../domain/models.dart';
import '../domain/rules.dart';

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
    notifyListeners();
  }

  Future<void> newGame({int? seed}) async {
    _state = GameRules.newGame(
      seed: seed ?? DateTime.now().millisecondsSinceEpoch % 1000000,
    );
    lastDayReport = null;
    lastExpedition = null;
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
    freshGame = true;
    saveError = null;
    lastDayReport = null;
    lastExpedition = null;
    notifyListeners();
    return const NewGameResult.ok();
  }

  void backToMenu() {
    _pendingSave = _state;
    _state = null;
    freshGame = false;
    notifyListeners();
  }

  ActionResult upgradeBuilding(Building b) =>
      _apply(() => GameRules.upgradeBuilding(_state!, b));
  ActionResult hire(int id) => _apply(() => GameRules.hire(_state!, id));
  ActionResult rename(int id, String n) =>
      _apply(() => GameRules.rename(_state!, id, n));
  ActionResult assignToFacility(int soldier, int facility) =>
      _apply(() => GameRules.assignToFacility(_state!, soldier, facility));
  ActionResult unassign(int soldier) =>
      _apply(() => GameRules.unassign(_state!, soldier));
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
  ActionResult scoutRegion(String id) =>
      _apply(() => GameRules.scoutRegion(_state!, id));

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
