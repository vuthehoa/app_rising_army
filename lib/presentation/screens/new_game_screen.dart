import 'dart:math' as math;

import 'package:app_rising_army/data/new_game_data.dart';
import 'package:app_rising_army/data/skin_color.dart';
import 'package:app_rising_army/presentation/widgets/avatar/avatar_widget.dart';
import 'package:app_rising_army/presentation/widgets/avatar/background_painter.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';

class NewGameScreen extends StatefulWidget {
  const NewGameScreen({super.key, this.onStartGame, this.onBack});

  final ValueChanged<NewGameData>? onStartGame;
  final VoidCallback? onBack;

  @override
  State<NewGameScreen> createState() => _NewGameScreenState();
}

class _NewGameScreenState extends State<NewGameScreen> {
  final _nameController = TextEditingController();
  final _random = math.Random();

  AvatarGender _gender = AvatarGender.male;
  HairStyle _hairStyle = HairStyle.short;

  int _hairColorIndex = 0;
  int _eyeColorIndex = 0;
  int _skinColorIndex = 1;
  int _faceSeed = 1;
  static const _hairColors = AvatarColorPalette.hairColors;
  static const _hairNames = AvatarColorPalette.hairNames;

  static const _eyeColors = AvatarColorPalette.eyeColors;
  static const _eyeNames = AvatarColorPalette.eyeNames;

  static const _skinColors = AvatarColorPalette.skinColors;
  static const _skinNames = AvatarColorPalette.skinNames;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Đổi kiểu tóc bằng hai nút mũi tên.
  void _changeHair(int direction) {
    setState(() {
      final count = HairStyle.values.length;
      _hairStyle =
          HairStyle.values[(_hairStyle.index + direction + count) % count];
      _faceSeed++;
    });
  }

  // Xúc xắc: ngẫu nhiên toàn bộ ngoại hình.
  void _randomizeAvatar() {
    setState(() {
      _gender =
          AvatarGender.values[_random.nextInt(AvatarGender.values.length)];
      _hairStyle = HairStyle.values[_random.nextInt(HairStyle.values.length)];
      _hairColorIndex = _random.nextInt(_hairColors.length);
      _eyeColorIndex = _random.nextInt(_eyeColors.length);
      _skinColorIndex = _random.nextInt(_skinColors.length);
      _faceSeed++;
    });
  }

  void _startGame() {
    FocusScope.of(context).unfocus();

    final name = _nameController.text.trim();

    if (name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tên nhân vật phải có ít nhất 2 ký tự.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    widget.onStartGame?.call(
      NewGameData(
        characterName: name,
        legionName: 'Thiết Huyết Quân',
        gender: _gender,
        hairStyle: _hairStyle,
        hairColor: _hairColors[_hairColorIndex],
        eyeColor: _eyeColors[_eyeColorIndex],
        skinColor: _skinColors[_skinColorIndex],
        avatarSeed: _faceSeed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pal.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 560;

            final horizontalPadding = compact ? 12.0 : 24.0;
            final avatarSize = compact
                ? math.min(constraints.maxWidth * 0.34, 148.0)
                : 210.0;

            return Stack(
              children: [
                const Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(painter: BackgroundPainter()),
                  ),
                ),

                Positioned.fill(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      48,
                      horizontalPadding,
                      72,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 620),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AvatarWidget(
                                  avatarSize: avatarSize,
                                  gender: _gender,
                                  hairStyle: _hairStyle,
                                  hairColor: _hairColors[_hairColorIndex],
                                  eyeColor: _eyeColors[_eyeColorIndex],
                                  skinColor: _skinColors[_skinColorIndex],
                                  seed: _faceSeed,
                                  onRandomize: _randomizeAvatar,
                                ),
                                SizedBox(width: compact ? 10 : 18),
                                Expanded(child: _buildAppearanceControls()),
                              ],
                            ),

                            const SizedBox(height: 12),

                            Align(
                              alignment: Alignment.centerLeft,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _genderButton(
                                    'Nam',
                                    AvatarGender.male,
                                    Icons.face_rounded,
                                  ),
                                  const SizedBox(width: 7),
                                  _genderButton(
                                    'Nữ',
                                    AvatarGender.female,
                                    Icons.face_3_rounded,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            _buildNameField(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 6,
                  left: 10,
                  child: _floatingIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Quay lại',
                    onTap: () {
                      if (widget.onBack != null) {
                        widget.onBack!.call();
                      } else {
                        Navigator.of(context).maybePop();
                      }
                    },
                  ),
                ),

                Positioned(
                  right: 12,
                  bottom: 8,
                  child: Material(
                    color: Pal.gold,
                    borderRadius: BorderRadius.circular(9),
                    elevation: 6,
                    shadowColor: Colors.black.withValues(alpha: 0.4),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(9),
                      onTap: _startGame,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'TIẾP TỤC',
                              style: TextStyle(
                                color: Color(0xFF17130D),
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
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
      ),
    );
  }

  Widget _floatingIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Pal.panel,
        shape: const CircleBorder(),
        elevation: 4,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Pal.goldDim),
            ),
            child: Icon(icon, color: Pal.gold, size: 19),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TÙY CHỈNH NGOẠI HÌNH
  // ---------------------------------------------------------------------------

  Widget _buildAppearanceControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // HÀNG 1: MÀU DA + MÀU MẮT
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _colorSelector(
                title: 'MÀU DA',
                colors: _skinColors,
                names: _skinNames,
                selected: _skinColorIndex,
                onSelect: (index) {
                  setState(() {
                    _skinColorIndex = index;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _colorSelector(
                title: 'MÀU MẮT',
                colors: _eyeColors,
                names: _eyeNames,
                selected: _eyeColorIndex,
                onSelect: (index) {
                  setState(() {
                    _eyeColorIndex = index;
                  });
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // HÀNG 2: KIỂU TÓC
        _label('KIỂU TÓC'),
        const SizedBox(height: 4),
        _hairSelector(),

        const SizedBox(height: 10),

        // HÀNG 3: MÀU TÓC
        _colorSelector(
          title: 'MÀU TÓC',
          colors: _hairColors,
          names: _hairNames,
          selected: _hairColorIndex,
          onSelect: (index) {
            setState(() {
              _hairColorIndex = index;
            });
          },
        ),
      ],
    );
  }

  Widget _hairSelector() {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
      decoration: _decoration(),
      child: Row(
        children: [
          _arrowButton(
            icon: Icons.chevron_left_rounded,
            onTap: () => _changeHair(-1),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_hairStyle.icon, color: Pal.gold, size: 21),
                const SizedBox(height: 2),
                Text(
                  _hairStyle.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Pal.text,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          _arrowButton(
            icon: Icons.chevron_right_rounded,
            onTap: () => _changeHair(1),
          ),
        ],
      ),
    );
  }

  Widget _arrowButton({required IconData icon, required VoidCallback onTap}) {
    return IconButton(
      onPressed: onTap,
      tooltip: icon == Icons.chevron_left_rounded
          ? 'Kiểu tóc trước'
          : 'Kiểu tóc tiếp theo',
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 27, height: 38),
      padding: EdgeInsets.zero,
      icon: Icon(icon, color: Pal.gold, size: 23),
    );
  }

  Widget _genderButton(String title, AvatarGender gender, IconData icon) {
    final selected = _gender == gender;

    return Material(
      color: selected ? Pal.gold.withValues(alpha: 0.12) : Pal.panel,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: () {
          setState(() {
            _gender = gender;
            _faceSeed++;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 83,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: selected ? Pal.gold : Pal.line,
              width: selected ? 1.3 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? Pal.gold : Pal.dim, size: 16),
              const SizedBox(width: 5),
              Text(
                title,
                style: TextStyle(
                  color: selected ? Pal.gold : Pal.text,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _colorSelector({
    required String title,
    required List<Color> colors,
    required List<String> names,
    required int selected,
    required ValueChanged<int> onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _label(title),
        const SizedBox(height: 5),
        Wrap(
          spacing: 6,
          runSpacing: 5,
          children: List.generate(colors.length, (index) {
            final active = selected == index;

            return Tooltip(
              message: names[index],
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelect(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 23,
                  height: 23,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: active ? Pal.gold : Pal.line,
                      width: active ? 1.7 : 1,
                    ),
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors[index],
                      shape: BoxShape.circle,
                    ),
                    child: active
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 13,
                          )
                        : null,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 3),
        Text(
          names[selected],
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Pal.dim, fontSize: 10),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TÊN NHÂN VẬT
  // ---------------------------------------------------------------------------

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('TÊN NHÂN VẬT'),
        const SizedBox(height: 5),
        SizedBox(
          height: 44,
          child: TextField(
            controller: _nameController,
            maxLength: 30,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _startGame(),
            style: const TextStyle(
              color: Pal.text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Nhập tên nhân vật...',
              hintStyle: TextStyle(
                color: Pal.dim.withValues(alpha: 0.75),
                fontSize: 12,
              ),
              counterText: '',
              filled: true,
              fillColor: Pal.panel,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 10,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Pal.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Pal.gold, width: 1.3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Pal.gold,
        fontSize: 9,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  BoxDecoration _decoration() {
    return BoxDecoration(
      color: Pal.panel,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Pal.line),
    );
  }
}
