import 'package:app_rising_army/presentation/widgets/avatar/background_painter.dart';
import 'package:app_rising_army/presentation/widgets/flag/color_panel.dart';
import 'package:app_rising_army/presentation/widgets/flag/flag_preview_panel.dart';
import 'package:app_rising_army/presentation/widgets/flag/option_row_flag.dart';
import 'package:app_rising_army/presentation/widgets/flag/template_preview.dart';
import 'package:flutter/material.dart';

import '../../application/new_game_flow.dart';
import '../../domain/identity.dart';
import '../../domain/identity_catalog.dart';
import 'new_game_nav.dart';

class LegionFlagScreen extends StatelessWidget {
  const LegionFlagScreen({super.key, required this.flow});

  final NewGameFlow flow;

  static const Color _background = Color(0xFF151713);
  static const Color _gold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: ListenableBuilder(
        listenable: flow,
        builder: (context, _) {
          final draft = flow.draft;

          final flag = LegionFlag(
            templateId: draft.templateId ?? IdentityCatalog.defaultTemplateId,
            patternId: draft.patternId ?? IdentityCatalog.defaultPatternId,
            emblemId: draft.emblemId ?? IdentityCatalog.defaultEmblemId,
            primaryColorId:
                draft.primaryColorId ?? IdentityCatalog.defaultPrimaryColorId,
            secondaryColorId:
                draft.secondaryColorId ??
                IdentityCatalog.defaultSecondaryColorId,
            emblemColorId:
                draft.emblemColorId ?? IdentityCatalog.defaultEmblemColorId,
          );
          return SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 560;
                final horizontalPadding = compact ? 10.0 : 24.0;

                return Stack(
                  children: [
                    const Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(painter: BackgroundPainter()),
                      ),
                    ),

                    // NỘI DUNG CHÍNH: CỜ 4 PHẦN, ĐIỀU KHIỂN 5 PHẦN
                    Positioned.fill(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          46,
                          horizontalPadding,
                          64,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // CỜ: 4/9 CHIỀU NGANG
                            Expanded(
                              flex: 4,
                              child: LayoutBuilder(
                                builder: (context, box) =>
                                    SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minHeight: box.maxHeight,
                                        ),
                                        child: Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(4),
                                            child: FlagPreviewPanel(
                                              flag: flag,
                                              onRandomize: flow.randomizeFlag,
                                              legionName:
                                                  draft.legionName ?? '',
                                              onLegionNameChanged: (v) =>
                                                  flow.update(
                                                    (d) => d.copyWith(
                                                      legionName: v,
                                                    ),
                                                  ),
                                              nameError: _nameError(flow),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                              ),
                            ),

                            SizedBox(width: compact ? 8 : 16),

                            // CÁC ĐIỀU KHIỂN: 5/9 CHIỀU NGANG
                            Expanded(
                              flex: 5,
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // KHUÔN CỜ
                                    OptionRow(
                                      title: 'Khuôn cờ',
                                      subtitle: _templateLabel(flag.templateId),
                                      icon: Icons.flag_rounded,
                                      onPrevious: () =>
                                          _cycleTemplate(flow, -1),
                                      onNext: () => _cycleTemplate(flow, 1),
                                      preview: TemplatePreview(
                                        templateId: flag.templateId,
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    // MÀU SẮC
                                    ColorPanel(
                                      draft: draft,
                                      onSelectPrimary: (id) {
                                        flow.update(
                                          (d) => d.copyWith(primaryColorId: id),
                                        );
                                      },
                                      onSelectSecondary: (id) {
                                        flow.update(
                                          (d) =>
                                              d.copyWith(secondaryColorId: id),
                                        );
                                      },
                                      onSelectEmblem: (id) {
                                        flow.update(
                                          (d) => d.copyWith(emblemColorId: id),
                                        );
                                      },
                                    ),

                                    const SizedBox(height: 8),

                                    // HOA VĂN
                                    OptionRow(
                                      title: 'Hoa văn',
                                      subtitle: _patternLabel(flag.patternId),
                                      icon: Icons.auto_awesome_rounded,
                                      onPrevious: () => _cyclePattern(flow, -1),
                                      onNext: () => _cyclePattern(flow, 1),
                                      preview: PatternPreview(
                                        patternId: flag.patternId,
                                        color: _colorOf(flag.secondaryColorId),
                                        backgroundColor: _colorOf(
                                          flag.primaryColorId,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    // HUY HIỆU
                                    OptionRow(
                                      title: 'Huy hiệu',
                                      subtitle: _emblemLabel(flag.emblemId),
                                      icon: Icons.shield_rounded,
                                      onPrevious: () => _cycleEmblem(flow, -1),
                                      onNext: () => _cycleEmblem(flow, 1),
                                      preview: EmblemPreview(
                                        emblemId: flag.emblemId,
                                        color: _colorOf(flag.emblemColorId),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // NÚT QUAY LẠI
                    Positioned(
                      top: 4,
                      left: 0,
                      child: _FloatingIconButton(
                        icon: Icons.arrow_back_rounded,
                        tooltip: 'Quay lại',
                        onTap: () => NewGameNav.back(context),
                      ),
                    ),

                    // NÚT XÁC NHẬN
                    Positioned(
                      right: 0,
                      bottom: 4,
                      child: Material(
                        color: flow.submitting
                            ? const Color(0xFF414136)
                            : _gold,
                        borderRadius: BorderRadius.circular(9),
                        elevation: 6,
                        shadowColor: Colors.black.withValues(alpha: 0.4),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(9),
                          onTap: flow.submitting
                              ? null
                              : () => NewGameNav.toIntro(context, flow),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 10,
                            ),
                            child: flow.submitting
                                ? const SizedBox(
                                    width: 72,
                                    height: 17,
                                    child: Center(
                                      child: SizedBox(
                                        width: 17,
                                        height: 17,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF211C0D),
                                        ),
                                      ),
                                    ),
                                  )
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'XÁC NHẬN',
                                        style: TextStyle(
                                          color: Color(0xFF17130D),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.7,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 17,
                                        color: Color(0xFF17130D),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Chuyển lựa chọn
  // ---------------------------------------------------------------------------

  static String? _nameError(NewGameFlow flow) {
    for (final i in flow.flagIssues) {
      if (i.field != IdentityField.legionName) continue;
      return i.code == IdentityIssueCode.nameTooLong
          ? 'Tối đa $maxLegionNameLength ký tự.'
          : 'Hãy nhập tên quân đoàn.';
    }
    return null;
  }

  static void _cycleTemplate(NewGameFlow flow, int direction) {
    final items = IdentityCatalog.templates;
    if (items.isEmpty) return;

    final current = flow.draft.templateId ?? IdentityCatalog.defaultTemplateId;
    final index = items.indexWhere((item) => item.id == current);
    final next = _nextIndex(index, items.length, direction);

    flow.update((d) => d.copyWith(templateId: items[next].id));
  }

  static void _cyclePattern(NewGameFlow flow, int direction) {
    final items = IdentityCatalog.patterns;
    if (items.isEmpty) return;

    final current = flow.draft.patternId ?? IdentityCatalog.defaultPatternId;
    final index = items.indexWhere((item) => item.id == current);
    final next = _nextIndex(index, items.length, direction);

    flow.update((d) => d.copyWith(patternId: items[next].id));
  }

  static void _cycleEmblem(NewGameFlow flow, int direction) {
    final items = IdentityCatalog.emblems;
    if (items.isEmpty) return;

    final current = flow.draft.emblemId ?? IdentityCatalog.defaultEmblemId;
    final index = items.indexWhere((item) => item.id == current);
    final next = _nextIndex(index, items.length, direction);

    flow.update((d) => d.copyWith(emblemId: items[next].id));
  }

  static int _nextIndex(int current, int length, int direction) {
    if (length == 0) return 0;
    if (current < 0) return direction > 0 ? 0 : length - 1;
    return (current + direction + length) % length;
  }

  static String _templateLabel(String id) =>
      IdentityCatalog.templateById(id)?.label ?? 'Khuôn cờ';

  static String _patternLabel(String id) =>
      IdentityCatalog.patternById(id)?.label ?? 'Hoa văn';

  static String _emblemLabel(String id) =>
      IdentityCatalog.emblemById(id)?.label ?? 'Huy hiệu';

  static Color _colorOf(String id) =>
      Color(IdentityCatalog.colorById(id)?.argb ?? 0xFFD4AF37);
}

// =============================================================================
// NÚT BACK NỔI
// =============================================================================

class _FloatingIconButton extends StatelessWidget {
  const _FloatingIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF292D25),
      shape: const CircleBorder(),
      elevation: 5,
      shadowColor: Colors.black45,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF414436)),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFF5F0DF),
            size: 21,
            semanticLabel: tooltip,
          ),
        ),
      ),
    );
  }
}
