import 'package:flutter/foundation.dart';

import '../data/save_repository.dart';
import '../domain/models.dart';
import '../domain/rules.dart';

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

  GameState? get state => _state;
  bool get hasSave => _pendingSave != null;

  Future<void> init() async {
    final r = await _repo.load();
    loadStatus = r.status;
    _pendingSave = r.state;
    notifyListeners();
  }

  void continueGame() {
    _state = _pendingSave;
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

  void backToMenu() {
    _pendingSave = _state;
    _state = null;
    notifyListeners();
  }

  ActionResult upgradeBuilding(Building b) =>
      _apply(() => GameRules.upgradeBuilding(_state!, b));
  ActionResult hire(int id) => _apply(() => GameRules.hire(_state!, id));
  ActionResult rename(int id, String n) =>
      _apply(() => GameRules.rename(_state!, id, n));
  ActionResult startTraining(int id, Stat st) =>
      _apply(() => GameRules.startTraining(_state!, id, st));
  ActionResult cancelTraining(int id) =>
      _apply(() => GameRules.cancelTraining(_state!, id));
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

  ExpeditionResult sendExpedition(String loc, List<int> squad, Set<int> front) {
    final r = GameRules.sendExpedition(_state!, loc, squad, front);
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
