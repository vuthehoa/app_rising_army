import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/legion_names.dart';
import '../domain/flag_randomizer.dart';
import '../domain/identity.dart';
import 'game_controller.dart';

/// Điều phối New Game: giữ bản nháp danh tính (avatar + quân kỳ) qua các bước
/// Menu → Avatar → Quân kỳ → Intro, rồi gọi [GameController.createGame] đúng một lần.
///
/// Bản nháp chỉ sống trong đối tượng này (do menu tạo khi bắt đầu luồng, bỏ đi khi luồng kết thúc
/// hoặc bị hủy). Không ghi save, không đụng state của controller cho tới [submit].
class NewGameFlow extends ChangeNotifier {
  NewGameFlow(this._controller, {IdentityDraft? initial})
    : _draft = initial ?? IdentityDraft.initial();

  final GameController _controller;

  IdentityDraft _draft;
  bool _completed = false;
  Future<NewGameResult>? _inFlight;
  NewGameResult? _lastResult;

  IdentityDraft get draft => _draft;

  /// Kết quả lần [submit] gần nhất (null nếu chưa gửi). UI đọc để hiển thị lỗi lưu/validation.
  NewGameResult? get lastResult => _lastResult;

  bool get submitting => _inFlight != null;
  bool get completed => _completed;

  static const _avatarFields = {
    IdentityField.displayName,
    IdentityField.appearance,
  };

  /// Lỗi của bước avatar (tên, ngoại hình).
  List<IdentityIssue> get avatarIssues => [
    for (final i in validateIdentityDraft(_draft))
      if (_avatarFields.contains(i.field)) i,
  ];

  /// Lỗi của bước quân kỳ (mọi trường còn lại, gồm tương phản huy hiệu).
  List<IdentityIssue> get flagIssues => [
    for (final i in validateIdentityDraft(_draft))
      if (!_avatarFields.contains(i.field)) i,
  ];

  bool get avatarValid => avatarIssues.isEmpty;
  bool get flagValid => flagIssues.isEmpty;

  /// Cập nhật bản nháp; giữ nguyên các trường không đổi. Dùng `draft.copyWith(...)`.
  void update(IdentityDraft Function(IdentityDraft current) change) {
    if (_completed || submitting) return;
    _draft = change(_draft);
    _lastResult = null;
    notifyListeners();
  }

  /// Random một lần cả quân kỳ và tên quân đoàn (cập nhật cùng một lần, một thông báo). Giữ nguyên
  /// tên nhân vật và avatar.
  void randomizeFlag({Random? random}) {
    final d = _draft;
    final previous = LegionFlag(
      templateId: d.templateId ?? LegionFlag.defaults.templateId,
      patternId: d.patternId ?? LegionFlag.defaults.patternId,
      emblemId: d.emblemId ?? LegionFlag.defaults.emblemId,
      primaryColorId: d.primaryColorId ?? LegionFlag.defaults.primaryColorId,
      secondaryColorId:
          d.secondaryColorId ?? LegionFlag.defaults.secondaryColorId,
      emblemColorId: d.emblemColorId ?? LegionFlag.defaults.emblemColorId,
    );
    final rng = random ?? Random();
    final f = randomLegionFlag(rng, previous: previous);
    final legion = LegionNameGenerator.generate(rng, avoid: d.legionName);
    update(
      (c) => c.copyWith(
        legionName: legion,
        templateId: f.templateId,
        patternId: f.patternId,
        emblemId: f.emblemId,
        primaryColorId: f.primaryColorId,
        secondaryColorId: f.secondaryColorId,
        emblemColorId: f.emblemColorId,
      ),
    );
  }

  /// Khởi tạo và lưu ván mới. Gọi lặp khi đang gửi trả về cùng một Future (không tạo thêm ván);
  /// gọi sau khi đã thành công trả về kết quả ok mà không tạo lại.
  /// Lỗi validation hoặc lỗi lưu: controller giữ nguyên state và save cũ; flow vẫn dùng lại được.
  Future<NewGameResult> submit({int? seed}) {
    if (_completed) return Future.value(const NewGameResult.ok());
    return _inFlight ??= _run(seed);
  }

  Future<NewGameResult> _run(int? seed) async {
    notifyListeners();
    try {
      final r = await _controller.createGame(seed: seed, draft: _draft);
      _lastResult = r;
      _completed = r.ok;
      return r;
    } catch (e) {
      // createGame đã bắt lỗi lưu; đây chỉ là lưới an toàn để cờ _inFlight luôn được trả.
      return _lastResult = NewGameResult.saveFailed('Không thể tạo game: $e');
    } finally {
      _inFlight = null;
      notifyListeners();
    }
  }
}
