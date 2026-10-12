import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import 'avatar_painter.dart';

class AvatarWidget extends StatelessWidget {
  const AvatarWidget({
    super.key,
    required this.avatarSize,
    required this.gender,
    required this.hairStyle,
    required this.hairColor,
    required this.eyeColor,
    required this.skinColor,
    required this.seed,
    required this.onRandomize,
  });

  final double avatarSize;
  final dynamic gender;
  final dynamic hairStyle;
  final Color hairColor;
  final Color eyeColor;
  final Color skinColor;
  final int seed;
  final VoidCallback onRandomize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: avatarSize,
      height: avatarSize * 1.18,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Pal.panel,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: Pal.gold, width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: CustomPaint(
                painter: AvatarPainter(
                  gender: gender,
                  hairStyle: hairStyle,
                  hairColor: hairColor,
                  eyeColor: eyeColor,
                  skinColor: skinColor,
                  seed: seed,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          Positioned(
            top: 7,
            left: 7,
            child: Material(
              color: Pal.panel,
              shape: const CircleBorder(),
              elevation: 4,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRandomize,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Pal.panel,
                    border: Border.all(color: Pal.gold, width: 1.2),
                  ),
                  child: const Icon(
                    Icons.casino_rounded,
                    color: Pal.gold,
                    size: 19,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
